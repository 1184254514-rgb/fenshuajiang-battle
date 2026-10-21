class_name EffectEval
extends RefCounted
## Shared, CPU-side Gamma effect simulation.
##
## Established by the supplied disassembly:
## - Engine frames are 33 milliseconds: literal 0x42040000 is 33.0.
## - Track percent = elapsed_frames / max(duration_frames, 1).
## - Start is strict: current_time > start_time.
## - IsEnded is strict: elapsed > duration. Particle death uses age >= life.
## - Byte interpolation truncates to a byte, then divides by 255.
## - Color interpolation uses integer weights summing to 256.
## - +0x18 is a parent index. There is no serialized per-unit repeat count.
##
## ASSUMPTION: Playback speed is 1. The omitted base Update and initialization
## helpers may add behavior not recoverable from these excerpts.
## ASSUMPTION: Looping uses the default frame range, preserves live particle
## tails, and restarts unit/emission state. One-shot playback continues until
## every unit and particle has ended, as required by the public API.
## ASSUMPTION: Source world axes map directly to Godot XYZ. UI projects XY
## with positive Y downward. No unestablished handedness conversion is made.
##
## Not runtime-tested in this response.

const FRAME_MS: float = 33.0
const EPSILON: float = 0.000001
const MAX_PARTICLES: int = 2001

static var _files: Dictionary = {}
static var _textures: Dictionary = {}

var units: Array = []
var states: Array = []
var duration_ms: float = 1.0
var loop_ms: float = FRAME_MS
var looping: bool = false
var time_ms: float = 0.0
var wall_ms: float = 0.0

var _requested_ms: float = 0.0
var _serial: int = 0
var _initialized: bool = false
var _visiting: PackedByteArray = PackedByteArray()
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


static func canonical(value: String) -> String:
	return value.replace("\\", "/").strip_edges().to_lower()


static func load_effect(eft_stem: String, effect_name: String) -> Dictionary:
	var stem: String = canonical(eft_stem).get_file()
	stem = stem.trim_suffix(".eft").trim_suffix(".json")
	if stem.is_empty() or stem == "." or stem == "..":
		push_error("EffectPlayer: invalid EFT stem.")
		return {}
	var path: String = "res://assets/fx/%s.json" % stem
	if not _files.has(path):
		if not FileAccess.file_exists(path):
			push_error("EffectPlayer: missing %s" % path)
			return {}
		var parser: JSON = JSON.new()
		var error: Error = parser.parse(FileAccess.get_file_as_string(path))
		if error != OK:
			push_error("EffectPlayer: %s:%d: %s" % [
				path, parser.get_error_line(), parser.get_error_message()
			])
			return {}
		var document: Variant = parser.data
		if not document is Dictionary:
			push_error("EffectPlayer: JSON root must be a dictionary: %s" % path)
			return {}
		if document.get("format", "") != "gamma-eft-godot-1":
			push_error("EffectPlayer: unsupported JSON schema: %s" % path)
			return {}
		_files[path] = document
	var file: Dictionary = _files[path]
	var effects: Dictionary = file.get("effects", {})
	var key: String = canonical(effect_name)
	if not effects.has(key):
		push_error("EffectPlayer: effect '%s' not found in %s" % [key, path])
		return {}
	var definition: Variant = effects[key]
	if not definition is Dictionary or not definition.get("units", []) is Array:
		push_error("EffectPlayer: invalid effect definition: %s" % key)
		return {}
	return definition


static func clear_caches() -> void:
	_files.clear()
	_textures.clear()


static func texture_at(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not _textures.has(path):
		var texture: Texture2D = null
		if ResourceLoader.exists(path):
			texture = ResourceLoader.load(path) as Texture2D
		if texture == null:
			push_warning("EffectPlayer: missing or invalid texture: %s" % path)
		_textures[path] = texture
	return _textures[path]


func _init(
	definition: Dictionary = {},
	repeat: bool = false,
	random_seed: int = 0
) -> void:
	units = definition.get("units", []).duplicate(true)
	duration_ms = maxf(1.0, float(definition.get("duration_ms", 1)))
	loop_ms = maxf(FRAME_MS, floor(duration_ms / FRAME_MS) * FRAME_MS)
	looping = repeat
	if random_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = random_seed
	for value in units:
		var unit: Dictionary = value
		states.append({
			"xf": Transform3D.IDENTITY,
			"old_xf": Transform3D.IDENTITY,
			"initialized": false,
			"had_frame": false,
			"frozen": false,
			"direction": Vector3.BACK,
			"size_percent": 0.0,
			"particles": [],
			"accumulator": 0.0,
			"texture": texture_at(str(unit.get("texture", ""))),
		})
	_visiting.resize(units.size())


static func f32(value: float) -> float:
	# Preserve the single-precision arithmetic preceding byte quantization.
	var storage: PackedFloat32Array = PackedFloat32Array([value])
	return float(storage[0])


static func vec3(value: Array) -> Vector3:
	if value.size() < 3:
		return Vector3.ZERO
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


static func vec2(value: Array) -> Vector2:
	if value.size() < 2:
		return Vector2.ZERO
	return Vector2(float(value[0]), float(value[1]))


static func track_at(unit: Dictionary, name: String, index: int) -> Array:
	var tracks: Array = unit.get(name, [])
	if index < 0 or index >= tracks.size():
		return []
	return tracks[index]


static func bracket(track: Array, percent: float) -> Vector2i:
	# ASSUMPTION: GetPos, omitted from the excerpt, clamps outside the key
	# range and chooses the rightmost key at duplicate timestamps.
	var count: int = track.size()
	if count <= 1:
		return Vector2i.ZERO
	if percent < float(track[0][0]):
		return Vector2i.ZERO
	if percent >= float(track[count - 1][0]):
		return Vector2i(count - 1, count - 1)
	var low: int = 0
	var high: int = count - 1
	while high - low > 1:
		var middle: int = (low + high) >> 1
		if float(track[middle][0]) <= percent:
			low = middle
		else:
			high = middle
	return Vector2i(low, high)


static func left_weight(track: Array, pair: Vector2i, percent: float) -> float:
	var start: float = float(track[pair.x][0])
	var finish: float = float(track[pair.y][0])
	if finish <= start:
		return 0.0
	return f32(f32(finish - percent) / f32(finish - start))


static func position_track(unit: Dictionary, percent: float) -> Vector3:
	var track: Array = unit.get("position", [])
	if track.is_empty():
		return Vector3.ZERO
	var pair: Vector2i = bracket(track, percent)
	var a: Array = track[pair.x]
	var first: Vector3 = Vector3(float(a[1]), float(a[2]), float(a[3]))
	if pair.x == pair.y:
		return first
	var b: Array = track[pair.y]
	var second: Vector3 = Vector3(float(b[1]), float(b[2]), float(b[3]))
	var weight: float = left_weight(track, pair, percent)
	return first * weight + second * f32(1.0 - weight)


static func byte_track(unit: Dictionary, index: int, percent: float) -> float:
	var track: Array = track_at(unit, "bytes", index)
	if track.is_empty():
		return 0.0
	var pair: Vector2i = bracket(track, percent)
	var first: int = int(track[pair.x][1]) & 255
	var result: int = first
	if pair.x != pair.y:
		var second: int = int(track[pair.y][1]) & 255
		var weight: float = left_weight(track, pair, percent)
		var mixed: float = f32(
			f32(float(second) * f32(1.0 - weight))
			+ f32(float(first) * weight)
		)
		result = int(mixed) & 255
	return f32(float(result) / 255.0)


static func packed_color_track(
	unit: Dictionary, index: int, percent: float, fallback: int = 0
) -> int:
	var track: Array = track_at(unit, "colors", index)
	if track.is_empty():
		return fallback
	if track.size() == 1:
		return int(track[0][1]) & 0xffffffff
	var pair: Vector2i
	# GetColor explicitly bypasses GetPos for exactly two colors.
	if track.size() == 2:
		pair = Vector2i(0, 1)
	else:
		pair = bracket(track, percent)
	var first: int = int(track[pair.x][1]) & 0xffffffff
	var second: int = int(track[pair.y][1]) & 0xffffffff
	if first == second or pair.x == pair.y:
		return first
	var weight: float = left_weight(track, pair, percent)
	if weight <= 0.0:
		return second
	var first_weight: int = int(weight * 256.0)
	if first_weight <= 0:
		return second
	if first_weight >= 255:
		return first
	var second_weight: int = 256 - first_weight
	var result: int = 0
	for shift in [0, 8, 16, 24]:
		var a: int = (first >> shift) & 255
		var b: int = (second >> shift) & 255
		var component: int = (a * first_weight + b * second_weight) >> 8
		result |= (component & 255) << shift
	return result


static func unpack_color(packed: int) -> Color:
	# ASSUMPTION: CColor is AARRGGBB. The excerpt establishes the alpha byte
	# and channel-wise arithmetic, but does not establish RGB byte names.
	return Color(
		float((packed >> 16) & 255) / 255.0,
		float((packed >> 8) & 255) / 255.0,
		float(packed & 255) / 255.0,
		float((packed >> 24) & 255) / 255.0
	)


static func color_track(
	unit: Dictionary, index: int, percent: float, fallback: int = 0
) -> Color:
	return unpack_color(packed_color_track(unit, index, percent, fallback))


static func texture_rect(unit: Dictionary, percent: float) -> Rect2:
	var grid: Array = unit.get("grid", [1, 1])
	var columns: int = maxi(1, int(grid[0]))
	var rows: int = maxi(1, int(grid[1]))
	var total: int = maxi(
		1, columns * rows + int(unit.get("frame_count_delta", 0))
	)
	var frame: int = clampi(int(percent * float(total)), 0, total - 1)
	var column: int = frame % columns
	var row: int = int(float(frame) / float(columns)) % rows
	var bounds: Array = unit.get("uv", [0.0, 0.0, 1.0, 1.0])
	var origin: Vector2 = Vector2(float(bounds[0]), float(bounds[1]))
	var extent: Vector2 = Vector2(
		float(bounds[2]) - origin.x, float(bounds[3]) - origin.y
	)
	var cell: Vector2 = extent / Vector2(float(columns), float(rows))
	return Rect2(origin + Vector2(float(column), float(row)) * cell, cell)


static func unit_end(unit: Dictionary) -> float:
	return float(unit.get("start_ms", 0)) + float(unit.get("duration_ms", 0))


static func percent_at(unit: Dictionary, at_ms: float) -> float:
	return (
		(at_ms - float(unit.get("start_ms", 0)))
		/ maxf(FRAME_MS, float(unit.get("duration_ms", 0)))
	)


static func lengths(basis: Basis) -> Vector3:
	return Vector3(basis.x.length(), basis.y.length(), basis.z.length())


static func scaled_columns(basis: Basis, scale_value: Vector3) -> Basis:
	return Basis(
		basis.x * scale_value.x,
		basis.y * scale_value.y,
		basis.z * scale_value.z
	)


static func safe_normal(vector: Vector3, fallback: Vector3) -> Vector3:
	if vector.length_squared() <= EPSILON * EPSILON:
		return fallback
	return vector.normalized()


static func normalized_columns(basis: Basis) -> Basis:
	return Basis(
		safe_normal(basis.x, Vector3.RIGHT),
		safe_normal(basis.y, Vector3.UP),
		safe_normal(basis.z, Vector3.BACK)
	)


static func plane_basis(direction: Vector3) -> Basis:
	var normal: Vector3 = safe_normal(direction, Vector3.BACK)
	if normal.dot(Vector3.BACK) > 0.999999:
		return Basis.IDENTITY
	if normal.dot(Vector3.BACK) < -0.999999:
		return Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)
	var horizontal: Vector3 = normal.cross(Vector3.BACK).normalized()
	var vertical: Vector3 = horizontal.cross(normal).normalized()
	return Basis(horizontal, vertical, horizontal.cross(vertical))


static func scale_measure(basis: Basis) -> float:
	# ASSUMPTION: The missing particle renderer normalizes the stored matrix
	# scale measure so uniform scale remains unchanged. RMS is stable under
	# rotations and nonuniform scale; the supplied updater stores a related
	# matrix-vector length.
	return sqrt(
		(basis.x.length_squared() + basis.y.length_squared()
		+ basis.z.length_squared()) / 3.0
	)


func advance(delta_seconds: float, context: Dictionary) -> Array:
	if not _initialized:
		_update_frames(context)
		_initialized = true

	_requested_ms += maxf(0.0, delta_seconds) * 1000.0
	var remaining: float = floor(_requested_ms) - wall_ms
	if remaining <= 0.0:
		_update_frames(context)
	else:
		while remaining > EPSILON:
			var step_ms: float = remaining
			if looping:
				step_ms = minf(step_ms, loop_ms - time_ms)
			_simulate(step_ms, context)
			remaining -= step_ms
			if looping and time_ms >= loop_ms - EPSILON:
				time_ms = 0.0
				for state_value in states:
					var state: Dictionary = state_value
					state["accumulator"] = 0.0
					state["frozen"] = false
					state["initialized"] = false
				_update_frames(context)
	return _draw_packets(context)


func is_finished() -> bool:
	if looping:
		return false
	for i in range(units.size()):
		var unit: Dictionary = units[i]
		if time_ms <= unit_end(unit):
			return false
		var particles: Array = states[i]["particles"]
		if not particles.is_empty():
			return false
	return true


func _simulate(delta_ms: float, context: Dictionary) -> void:
	var previous_time: float = time_ms
	time_ms += delta_ms
	wall_ms += delta_ms
	_update_frames(context)
	for i in range(units.size()):
		var unit: Dictionary = units[i]
		if int(unit.get("kind", -1)) == 0:
			_update_particles(i, previous_time, delta_ms, context)
			if time_ms > unit_end(unit):
				states[i]["frozen"] = true


func _update_frames(context: Dictionary) -> void:
	_visiting.fill(0)
	for state_value in states:
		var state: Dictionary = state_value
		state["old_xf"] = state["xf"]
		state["had_frame"] = state["initialized"]
	for i in range(units.size()):
		_resolve_frame(i, context)
	var u1_tick: Callable = context.get("_u1_tick", Callable())
	if u1_tick.is_valid():
		u1_tick.call(context)


func _binding_matrix(
	matrix: Transform3D, link: int, context: Dictionary
) -> Transform3D:
	var mode: int = link
	if mode > 6:
		mode -= 7
	var axis_scale: Vector3 = lengths(matrix.basis)
	if mode == 1 or mode == 2:
		matrix.basis = scaled_columns(Basis.IDENTITY, axis_scale)
	elif mode == 5 or mode == 6:
		# ASSUMPTION: Without skeleton attachment matrices, use the unit
		# parent's orientation for the additional normalized-parent branch.
		matrix.basis = scaled_columns(
			normalized_columns(matrix.basis), axis_scale
		)
	if link > 6:
		# ReadLength's global conversion must survive removal of parent scale.
		matrix.basis = scaled_columns(
			normalized_columns(matrix.basis),
			Vector3.ONE * float(context.get("unit_scale", 1.0))
		)
	return matrix


func _resolve_frame(index: int, context: Dictionary) -> Transform3D:
	var state: Dictionary = states[index]
	if _visiting[index] == 2:
		return state["xf"]
	if _visiting[index] == 1:
		# Invalid/cyclic attachment graphs degrade to the root, never recurse.
		return context["root"]
	_visiting[index] = 1
	var unit: Dictionary = units[index]
	var kind: int = int(unit.get("kind", -1))
	if kind == 0 and bool(state["frozen"]):
		_visiting[index] = 2
		return state["xf"]

	var parent_matrix: Transform3D = context["root"]
	var parent_index: int = int(unit.get("parent", -1))
	if parent_index >= 0 and parent_index < units.size() and parent_index != index:
		parent_matrix = _resolve_frame(parent_index, context)
	var u2_binding_hook: Callable = state.get("u2_binding_hook", Callable())
	if u2_binding_hook.is_valid():
		parent_matrix = u2_binding_hook.call(parent_matrix, context)
	parent_matrix = _binding_matrix(
		parent_matrix, int(unit.get("link", 0)), context
	)

	var at_ms: float = clampf(
		time_ms, float(unit.get("start_ms", 0)), unit_end(unit)
	)
	var percent: float = percent_at(unit, at_ms)
	var offset: Vector3 = position_track(unit, percent)
	var matrix: Transform3D = Transform3D(
		parent_matrix.basis, parent_matrix * offset
	)
	state["size_percent"] = percent

	if kind == 1:
		var sprite: Dictionary = unit.get("sprite", {})
		var facing: int = int(sprite.get("facing", 0))
		var camera_basis: Basis = context["camera_basis"]
		var camera_direction: Vector3 = -camera_basis.z
		var direction: Vector3 = vec3(sprite.get("normal", [0, 0, 1]))
		var incoming_scale: Vector3 = lengths(parent_matrix.basis)

		if facing == 4 or facing == 7:
			var global_unit: float = float(context.get("unit_scale", 1.0))
			matrix.basis = scaled_columns(
				Basis.IDENTITY, Vector3.ONE * global_unit
			)
			matrix.origin = parent_matrix.origin + offset * global_unit
			var old_matrix: Transform3D = state["old_xf"]
			var movement: Vector3 = matrix.origin - old_matrix.origin
			if not bool(state["had_frame"]):
				movement = (
					position_track(unit, 1.0) - position_track(unit, 0.0)
				)
			direction = safe_normal(
				movement, safe_normal(state["direction"], Vector3.BACK)
			)
			state["direction"] = direction
		elif facing == 1 or facing == 6:
			matrix.basis = scaled_columns(Basis.IDENTITY, incoming_scale)
		elif facing == 2 or facing == 3:
			matrix.basis = scaled_columns(camera_basis, incoming_scale)

		var axes: Basis = Basis.IDENTITY
		if facing >= 8 and facing <= 11:
			# ASSUMPTION: Terrain height queries are unavailable. Draw a flat
			# XZ decal; modes 9/11 discard parent yaw.
			if facing == 9 or facing == 11:
				matrix.basis = scaled_columns(Basis.IDENTITY, incoming_scale)
			axes = Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
		elif facing >= 5 and facing <= 7:
			var x_axis: Vector3 = safe_normal(direction, camera_basis.x)
			var y_axis: Vector3 = safe_normal(
				x_axis.cross(camera_direction), camera_basis.y
			)
			axes = Basis(x_axis, y_axis, x_axis.cross(y_axis))
		elif facing == 3:
			var camera_position: Vector3 = context["camera_position"]
			var ray: Vector3 = safe_normal(
				matrix.origin - camera_position, camera_direction
			)
			state["size_percent"] = clampf(
				ray.cross(camera_direction).length(), 0.0, 1.0
			)
		else:
			axes = plane_basis(direction)

		var angular_velocity: Vector3 = vec3(
			sprite.get("angular_velocity", [0, 0, 0])
		)
		var angular_speed: float = angular_velocity.length()
		var elapsed: float = maxf(
			0.0, at_ms - float(unit.get("start_ms", 0))
		) * 0.001
		var angle: float = (
			clampf(float(sprite.get("rotation", 0.0)), 0.0, TAU)
			+ angular_speed * elapsed
		)
		var rotation_axis: Vector3 = safe_normal(
			angular_velocity, safe_normal(axes.x.cross(axes.y), Vector3.BACK)
		)
		matrix.basis = matrix.basis * Basis(rotation_axis, -angle) * axes

	var u1_frame: Callable = context.get("_u1_frame", Callable())
	if u1_frame.is_valid():
		matrix = u1_frame.call(index, parent_matrix, matrix, percent, context)
	var u2_frame_hook: Callable = state.get("u2_frame_hook", Callable())
	if u2_frame_hook.is_valid():
		matrix = u2_frame_hook.call(matrix, percent, context)
	state["xf"] = matrix
	state["initialized"] = true
	_visiting[index] = 2
	return matrix


func _random_vector(minimum: Vector3, maximum: Vector3) -> Vector3:
	return Vector3(
		lerpf(minimum.x, maximum.x, _rng.randf()),
		lerpf(minimum.y, maximum.y, _rng.randf()),
		lerpf(minimum.z, maximum.z, _rng.randf())
	)


static func _mix_matrix(a: Transform3D, b: Transform3D, weight: float) -> Transform3D:
	return Transform3D(
		Basis(
			a.basis.x.lerp(b.basis.x, weight),
			a.basis.y.lerp(b.basis.y, weight),
			a.basis.z.lerp(b.basis.z, weight)
		),
		a.origin.lerp(b.origin, weight)
	)


func _birth(
	unit: Dictionary,
	properties: Dictionary,
	emitter: Transform3D,
	inherited_velocity: Vector3,
	born_ms: float,
	born_percent: float
) -> Dictionary:
	var direction: Vector3 = safe_normal(
		vec3(properties.get("direction", [0, 0, 1])), Vector3.BACK
	)
	var shape: int = int(properties.get("shape", 0))
	var random_direction: Vector3 = _random_vector(-Vector3.ONE, Vector3.ONE)
	if shape == 1:
		random_direction -= direction * random_direction.dot(direction)
	random_direction = safe_normal(random_direction, Vector3.RIGHT)

	var minimum_velocity: Vector3 = vec3(properties.get("velocity_min", [0, 0, 0]))
	var maximum_velocity: Vector3 = vec3(properties.get("velocity_max", [0, 0, 0]))
	var velocity_mode: int = int(properties.get("velocity_mode", 0))
	var velocity: Vector3 = Vector3.ZERO
	if velocity_mode != 2:
		var components: Vector3 = _random_vector(minimum_velocity, maximum_velocity)
		if velocity_mode == 0:
			velocity = components
		else:
			var side: Vector3 = random_direction.cross(direction)
			if side.length_squared() <= EPSILON * EPSILON:
				side = Vector3(2.0, random_direction.y, random_direction.z).normalized()
			var across: Vector3 = side.cross(random_direction)
			velocity = (
				across * components.x + random_direction * components.y
				+ side * components.z
			)

	var lifetime: Array = properties.get("lifetime_ms", [1, 1])
	var life: float = maxf(
		1.0, lerpf(float(lifetime[0]), float(lifetime[1]), _rng.randf())
	)
	var angular: Array = properties.get("angular_velocity", [0, 0])
	var spin: float = lerpf(float(angular[0]), float(angular[1]), _rng.randf())
	var radius: Array = properties.get("radius", [0, 0])
	var inner: float = float(radius[0])
	var outer: float = float(radius[1])
	var location: Vector3 = Vector3.ZERO

	match shape:
		0, 1:
			location = random_direction * lerpf(inner, outer, _rng.randf())
		2:
			# Reproduction of the two-axis rectangular emission branch.
			var first_axis: Vector3 = safe_normal(
				direction.cross(Vector3(0.001, 1.0, 0.0)), Vector3.RIGHT
			)
			var second_axis: Vector3 = safe_normal(
				first_axis.cross(direction), Vector3.UP
			)
			var choice: float = _rng.randf() * 2.0
			var polarity: float = 1.0
			if choice >= 1.0:
				polarity = -1.0
				choice -= 1.0
			var span_sample: float = (outer - inner) * _rng.randf()
			var aspect: float = float(properties.get("rectangle_aspect", 1))
			var edge_weight: float = float(properties.get("rectangle_weight", 1))
			var threshold: float = edge_weight / maxf(aspect + edge_weight, 1.0)
			var first_distance: float
			var second_distance: float
			if choice > threshold:
				first_distance = polarity * (inner + span_sample)
				second_distance = (
					(outer - inner + inner * aspect) * _rng.randf_range(-1.0, 1.0)
				)
			else:
				first_distance = inner * _rng.randf_range(-1.0, 1.0)
				second_distance = polarity * (span_sample + inner * aspect)
			location = (
				first_axis * first_distance + second_axis * second_distance
			)
		3:
			var radius_value: float = lerpf(inner, outer, _rng.randf())
			var ray_count: float = maxf(1.0, float(properties.get("ray_count", 1)))
			var ray_angle: float = (
				TAU / ray_count * floor(_rng.randf() * ray_count)
			)
			location = Basis(direction, ray_angle) * Vector3(radius_value, 0, 0)
		_:
			# ASSUMPTION: Unidentified shapes use spherical emission.
			location = random_direction * lerpf(inner, outer, _rng.randf())

	if velocity_mode == 2:
		# Established for shape 2. ASSUMPTION: Extend the same radial rule
		# to other shapes instead of retaining an uninitialized velocity.
		velocity = safe_normal(location, random_direction) * lerpf(
			minimum_velocity.x, maximum_velocity.x, _rng.randf()
		)

	var local_space: bool = int(properties.get("space", 0)) == 1
	if not local_space:
		location = emitter * location
		velocity = emitter.basis * velocity
	velocity += inherited_velocity

	_serial += 1
	var flags: int = int(properties.get("flags", 0))
	return {
		"id": _serial,
		"born": born_ms,
		"life": life,
		"age": 0.0,
		"position": location,
		"velocity": velocity,
		"angle": 0.0,
		"spin": spin,
		"birth_basis": emitter.basis,
		"birth_scale": scale_measure(emitter.basis),
		"tint": (
			color_track(unit, 2, born_percent, 0xffffffff)
			if (flags & 2) != 0 else Color.WHITE
		),
		"add": (
			color_track(unit, 3, born_percent)
			if (flags & 1) != 0 else Color(0, 0, 0, 0)
		),
	}


func _acceleration(
	properties: Dictionary, emitter: Transform3D, context: Dictionary
) -> Vector3:
	var acceleration: Vector3 = vec3(
		properties.get("acceleration", [0, 0, 0])
	)
	var relative: bool = int(properties.get("acceleration_space", 0)) == 1
	var local_space: bool = int(properties.get("space", 0)) == 1
	if local_space:
		# ASSUMPTION: For local particles, world acceleration is converted
		# back into emitter coordinates. The renderer's local-space path
		# is absent from the supplied excerpt.
		if relative:
			return acceleration
		if absf(emitter.basis.determinant()) <= EPSILON:
			return Vector3.ZERO
		return emitter.basis.inverse() * (
			acceleration * float(context.get("unit_scale", 1.0))
		)
	if relative:
		return emitter.basis * acceleration
	return acceleration * float(context.get("unit_scale", 1.0))


func _update_particles(
	index: int, previous_time: float, delta_ms: float, context: Dictionary
) -> void:
	var unit: Dictionary = units[index]
	var state: Dictionary = states[index]
	var properties: Dictionary = unit.get("particle", {})
	var particles: Array = state["particles"]
	var emitter: Transform3D = state["xf"]
	var old_emitter: Transform3D = state["old_xf"]
	var start: float = float(unit.get("start_ms", 0))
	var finish: float = unit_end(unit)
	var lifetime: Array = properties.get("lifetime_ms", [1, 1])
	var maximum_life: int = maxi(1, int(lifetime[1]))

	# _UpdateParticle takes the remainder of elapsed milliseconds divided
	# by maximum lifetime. Reproduce that hitch behavior instead of
	# introducing a different fixed-step integrator.
	var update_ms: float = fmod(maxf(delta_ms, 0.0), float(maximum_life))
	var seconds: float = update_ms * 0.001
	var acceleration: Vector3 = _acceleration(properties, emitter, context)
	var damping: float = 1.0 - minf(
		seconds * float(properties.get("drag", 0.0)), 1.0
	)
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		var age: float = (
			(wall_ms - float(particle["born"])) / float(particle["life"])
		)
		if age >= 1.0:
			particles.remove_at(i)
			continue
		particle["age"] = maxf(age, 0.0)
		particle["angle"] = float(particle["angle"]) + float(particle["spin"]) * seconds
		var velocity: Vector3 = particle["velocity"]
		var location: Vector3 = particle["position"]
		# Explicit Euler: position first, acceleration second, drag last.
		particle["position"] = location + velocity * seconds
		particle["velocity"] = (velocity + acceleration * seconds) * damping

	if (
		bool(unit.get("needs_bone", false))
		and not bool(state.get("u2_bone_resolved", false))
	):
		# TODO: Resolve named skeletal attachments. With no resolved bone,
		# the supplied OnUpdate skips units having this flag.
		state["accumulator"] = 0.0
		return
	if time_ms <= start:
		return
	if previous_time >= finish:
		state["accumulator"] = 0.0
		return

	var active_ms: float = maxf(
		0.0, minf(time_ms, finish) - maxf(previous_time, start)
	)
	active_ms = minf(active_ms, update_ms)

	# CParticleSystem::Update's explicit initial 33 ms update.
	if (
		particles.is_empty() and start == 0.0
		and float(unit.get("duration_ms", 0)) == duration_ms
		and time_ms <= finish
	):
		active_ms = minf(FRAME_MS, maxf(0.0, finish - previous_time))

	if active_ms <= 0.0:
		return

	var interval_range: Array = properties.get("interval_ms", [1, 1])
	var interval_min: int = int(interval_range[0])
	var interval_max: int = int(interval_range[1])
	var interval: int = interval_min
	if interval_min != interval_max:
		var factor: float = _rng.randf()
		var flags: int = int(properties.get("flags", 0))
		# The listing tests channel 1's presence before evaluating channel 4.
		if (flags & 4) != 0 and not track_at(unit, "bytes", 1).is_empty():
			factor = byte_track(unit, 4, percent_at(unit, time_ms))
		interval += int(float(interval_max - interval_min) * factor)
	interval = maxi(1, interval)

	var inherited: Vector3 = Vector3.ZERO
	if bool(state["had_frame"]) and delta_ms > 0.0:
		inherited = (
			(emitter.origin - old_emitter.origin)
			* (1000.0 / delta_ms)
			* float(properties.get("inherit_velocity", 0.0))
		)
	if int(properties.get("space", 0)) == 1:
		if absf(emitter.basis.determinant()) > EPSILON:
			inherited = emitter.basis.inverse() * inherited
		else:
			inherited = Vector3.ZERO

	var accumulated: float = float(state["accumulator"]) + active_ms
	var total_accumulated: float = accumulated
	var emission_index: int = 0
	var burst: int = int(properties.get("burst", 0))
	# First batch is stamped at the beginning of the update interval,
	# matching r7 = current_time - update_delta in _UpdateParticle.
	var birth_time: float = (
		wall_ms - active_ms - maxf(0.0, time_ms - finish)
	)
	while int(accumulated) >= interval:
		var weight: float = clampf(
			float(emission_index * interval) / maxf(total_accumulated, 1.0),
			0.0, 1.0
		)
		var birth_matrix: Transform3D = _mix_matrix(old_emitter, emitter, weight)
		var born_percent: float = clampf(
			percent_at(unit, time_ms + birth_time - wall_ms), 0.0, 1.0
		)
		for unused in range(mini(burst, MAX_PARTICLES - particles.size())):
			particles.append(_birth(
				unit, properties, birth_matrix, inherited,
				birth_time, born_percent
			))
		accumulated -= float(interval)
		birth_time += float(interval)
		emission_index += 1
	state["accumulator"] = accumulated


static func _aspect(
	value: float, texture: Texture2D, rectangle: Rect2
) -> float:
	if value > 0.0:
		return value
	# ASSUMPTION: Zero means automatic frame aspect. Several supplied
	# sprites have zero here; using it literally collapses all their quads.
	# Texture-dependent initialization is missing from the excerpt.
	var width: float = float(texture.get_width()) * absf(rectangle.size.x)
	var height: float = float(texture.get_height()) * absf(rectangle.size.y)
	return height / maxf(width, EPSILON)


static func _sized_matrix(matrix: Transform3D, half_size: Vector2) -> Transform3D:
	return Transform3D(
		Basis(
			matrix.basis.x * half_size.x,
			matrix.basis.y * half_size.y,
			matrix.basis.z
		),
		matrix.origin
	)


func _sprite_packet(index: int, context: Dictionary) -> Dictionary:
	var unit: Dictionary = units[index]
	var state: Dictionary = states[index]
	var texture: Texture2D = state["texture"]
	if texture == null:
		return {}
	var sprite: Dictionary = unit.get("sprite", {})
	var percent: float = percent_at(unit, time_ms)
	var size_percent: float = float(state["size_percent"])
	var limits: Array = sprite.get("half_size", [0, 0])
	var rectangle: Rect2 = texture_rect(unit, percent)
	var half_size: Vector2 = Vector2(
		lerpf(float(limits[0]), float(limits[1]), byte_track(unit, 3, size_percent)),
		lerpf(float(limits[0]), float(limits[1]), byte_track(unit, 4, size_percent))
	)
	half_size.y *= _aspect(float(sprite.get("aspect", 1)), texture, rectangle)
	if half_size.x <= EPSILON or half_size.y <= EPSILON:
		return {}

	var matrix: Transform3D = state["xf"]
	if not bool(context.get("canvas", false)):
		# ASSUMPTION: Approximate PrepareMaterial's depth offset by moving
		# along camera Z. Its exact projection-space bias is not supplied.
		var camera_basis: Basis = context["camera_basis"]
		matrix.origin += (
			camera_basis.z * float(sprite.get("depth_offset", 0.0))
			* float(context.get("unit_scale", 1.0))
		)
	var edge_size: Vector2 = vec2(sprite.get("edge_size", [0, 0]))
	var fade: Vector2 = Vector2(
		maxf(0.0, edge_size.x / (2.0 * half_size.x)),
		maxf(0.0, edge_size.y / (2.0 * half_size.y))
	)
	return {
		"id": "s:%d" % index,
		"order": index,
		"xf": _sized_matrix(matrix, half_size),
		"texture": texture,
		"uv": rectangle,
		"tint": color_track(unit, 0, percent),
		"add": color_track(unit, 1, percent),
		"hue": byte_track(unit, 0, percent),
		"brightness": byte_track(unit, 1, percent) * float(sprite.get("brightness", 1)),
		"saturation": byte_track(unit, 2, percent),
		"blend": int(sprite.get("blend", 1)),
		"depth": int(sprite.get("depth", 2)),
		"strips": int(sprite.get("strips", 1)),
		"fade": fade,
		"fade_center": vec2(sprite.get("edge_offset", [0, 0])),
	}


func _particle_packet(
	index: int, particle: Dictionary, context: Dictionary
) -> Dictionary:
	var unit: Dictionary = units[index]
	var state: Dictionary = states[index]
	var texture: Texture2D = state["texture"]
	if texture == null:
		return {}
	var properties: Dictionary = unit.get("particle", {})
	var age: float = float(particle["age"])
	var emitter_percent: float = clampf(
		percent_at(unit, minf(time_ms, unit_end(unit))), 0.0, 1.0
	)
	var emitter: Transform3D = state["xf"]
	var local_space: bool = int(properties.get("space", 0)) == 1
	var location: Vector3 = particle["position"]
	var velocity: Vector3 = particle["velocity"]
	var particle_scale: float = float(particle["birth_scale"])
	var birth_basis: Basis = particle["birth_basis"]
	if local_space:
		location = emitter * location
		velocity = emitter.basis * velocity
		particle_scale = scale_measure(emitter.basis)
		birth_basis = emitter.basis

	# ASSUMPTION: RenderImp is absent. Channels 0..3 are evaluated over
	# particle lifetime; emitter channels 2/3 multiply/add to life colors.
	# Flag bits 1/0 freeze those emitter colors at birth, as _InitParticle
	# explicitly shows. Render modes 0/1/other use camera/velocity/normal.
	var flags: int = int(properties.get("flags", 0))
	var emitter_tint: Color = particle["tint"]
	var emitter_add: Color = particle["add"]
	if (flags & 2) == 0:
		emitter_tint = color_track(unit, 2, emitter_percent, 0xffffffff)
	if (flags & 1) == 0:
		emitter_add = color_track(unit, 3, emitter_percent)
	var tint: Color = color_track(unit, 0, age) * emitter_tint
	var additive: Color = color_track(unit, 1, age) + emitter_add

	var rectangle: Rect2 = texture_rect(unit, age)
	var limits: Array = properties.get("half_size", [0, 0])
	var extent: float = lerpf(
		float(limits[0]), float(limits[1]), byte_track(unit, 3, age)
	)
	var half_size: Vector2 = Vector2.ONE * extent * particle_scale
	half_size.y *= _aspect(
		float(properties.get("aspect", 1.0)), texture, rectangle
	)
	var camera_basis: Basis = context["camera_basis"]
	var axes: Basis = camera_basis
	var facing: int = int(properties.get("facing", 0))
	if facing == 1 and velocity.length_squared() > EPSILON * EPSILON:
		var x_axis: Vector3 = velocity.normalized()
		var y_axis: Vector3 = safe_normal(
			x_axis.cross(-camera_basis.z), camera_basis.y
		)
		axes = Basis(x_axis, y_axis, x_axis.cross(y_axis))
		half_size.x += (
			velocity.length() * maxf(0.0, float(properties.get("stretch", 0.0))) * 0.5
		)
	elif facing > 1:
		axes = normalized_columns(birth_basis) * plane_basis(
			vec3(properties.get("direction", [0, 0, 1]))
		)
	if half_size.x <= EPSILON or half_size.y <= EPSILON:
		return {}

	var angle: float = float(particle["angle"])
	var old_x: Vector3 = axes.x
	var old_y: Vector3 = axes.y
	axes = Basis(
		old_x * cos(angle) - old_y * sin(angle),
		old_x * sin(angle) + old_y * cos(angle),
		axes.z
	)
	return {
		"id": "p:%d" % int(particle["id"]),
		"order": index,
		"xf": _sized_matrix(Transform3D(axes, location), half_size),
		"texture": texture,
		"uv": rectangle,
		"tint": tint,
		"add": additive,
		"hue": byte_track(unit, 0, age),
		"brightness": byte_track(unit, 1, age) * float(properties.get("brightness", 1)),
		"saturation": byte_track(unit, 2, age),
		"blend": int(properties.get("blend", 1)),
		"depth": int(properties.get("depth", 2)),
		"strips": 1,
		"fade": Vector2.ZERO,
		"fade_center": Vector2.ZERO,
	}


func _draw_packets(context: Dictionary) -> Array:
	var packets: Array = []
	for i in range(units.size()):
		var unit: Dictionary = units[i]
		if (
			bool(unit.get("needs_bone", false))
			and not bool(states[i].get("u2_bone_resolved", false))
		):
			continue
		var kind: int = int(unit.get("kind", -1))
		if kind == 1:
			if time_ms <= float(unit.get("start_ms", 0)) or time_ms > unit_end(unit):
				continue
			var packet: Dictionary = _sprite_packet(i, context)
			if not packet.is_empty():
				packets.append(packet)
		elif kind == 0:
			var particles: Array = states[i]["particles"]
			for j in range(particles.size() - 1, -1, -1):
				var packet: Dictionary = _particle_packet(i, particles[j], context)
				if not packet.is_empty():
					packets.append(packet)
		# TODO: Other unit classes retain timing/attachment proxies only.
	return packets
