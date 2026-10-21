class_name EffectUnitsTrail
extends Node
## Additional Gamma EFT units. Rendering is independent of quad packets.
##
## Public integration:
##   context_for(host, evaluation, context, blend_overrides)
##   has_tails(host)
##
## Optional runtime endpoint:
##   controller.set_chain_target(unit_index, world_position)
##
## Coordinates supplied to endpoint/attachment callbacks are Godot world
## coordinates. Serialized lengths remain engine units. Imported GLB vertices
## are multiplied by 64 exactly once.
##
## The supplied excerpts do NOT include:
## - eft_parse.py's schema for these four property classes;
## - CGeometryProp::CheckGeometryBuffer or geometry shader 7;
## - SAlphaPower's table;
## - CEffectAttachMesh's update/render/material behavior.
##
## # ASSUMPTION: The schema adapter below uses `type` (or another explicit
## class-name field) and `trail`, `chain`, `geometry`, `attach_mesh` dictionaries.
## Properties can instead be supplied by ABI offset in each dictionary's
## `abi`, e.g. {"0xc4": 4.0, "0xc8": 12.0}. These are decoded VALUES,
## never pointers into the original executable.
##
## # ASSUMPTION: Missing geometry generation and attached-mesh behavior use
## the explicitly documented fallbacks below. Exact visual parity for those
## missing routines cannot be established from this disassembly.
##
## # ASSUMPTION: Blend presets, straight-alpha textures, sRGB imports and
## unknown framebuffer effects follow EffectRender's existing conventions.
## Invalid counts, zero periods and zero lifetimes are guarded against.
##
## Not runtime-tested.

const Eval = preload("res://scripts/effect_eval.gd")

const META: StringName = &"_eft_units_u1"
const EPS: float = 0.000001
const MODEL_ENGINE_SCALE: float = 64.0
const DATA_WIDTH: int = 1024

const PROPERTY_KEYS: Dictionary = {
	"CPolyTrailProp": "trail",
	"CPolyChainProp": "chain",
	"CGeometryProp": "geometry",
	"CEffectAttachMesh": "attach_mesh",
}

static var _registry: Array = []
static var _random_state: int = 1
static var _shaders: Dictionary = {}
static var _white_texture: Texture2D

# Literal bytes reconstructed from _CalculateInterolate's literal pool.
static var _handle_denominator: float = PackedByteArray([
	0x00, 0x00, 0x00, 0x60, 0x9e, 0xa0, 0xf6, 0x3f
]).decode_double(0)
static var _handle_numerator: float = PackedByteArray([
	0x00, 0x00, 0x00, 0xc0, 0x87, 0x2b, 0xee, 0x3f
]).decode_double(0)

var _host: Node
var _evaluation: EffectEval
var _units: Dictionary = {}
var _blend_overrides: Dictionary = {}
var _last_time: float = -1.0
var _last_wall: float = -1.0


static func type_of(unit: Dictionary) -> String:
	# Dispatch only on class strings, never on another implementer's kind IDs.
	for key in ["type", "unit_type", "class_name", "class"]:
		var value: Variant = unit.get(key)
		if value is String or value is StringName:
			var parts: PackedStringArray = str(value).split("::")
			var name_value: String = parts[parts.size() - 1]
			if PROPERTY_KEYS.has(name_value):
				return name_value
	return ""


static func create(
	unit_def: Dictionary,
	evaluation: EffectEval,
	unit_index: int,
	host: Node
) -> Node:
	var type_name: String = type_of(unit_def)
	if type_name.is_empty():
		return null
	var runtime: UnitRuntime = UnitRuntime.new()
	runtime.configure(unit_def, evaluation, unit_index, host, type_name)
	return runtime


static func context_for(
	host: Node,
	evaluation: EffectEval,
	context: Dictionary,
	blend_overrides: Dictionary = {}
) -> Dictionary:
	var controller: Variant = (host.get_meta(META) if host.has_meta(META) else null)
	if not is_instance_valid(controller):
		var added: EffectUnitsTrail = EffectUnitsTrail.new()
		added.name = "EffectUnitsU1"
		added._host = host
		added._evaluation = evaluation
		added._blend_overrides = blend_overrides
		host.set_meta(META, added)
		host.add_child(added)
		for index in range(evaluation.units.size()):
			var definition: Dictionary = evaluation.units[index]
			var runtime: Node = create(definition, evaluation, index, host)
			if runtime != null:
				added._units[index] = runtime
				added.add_child(runtime)
		controller = added
	controller._blend_overrides = blend_overrides
	context["_u1_frame"] = Callable(controller, "resolve_frame")
	context["_u1_tick"] = Callable(controller, "update")
	return context


static func has_tails(host: Node) -> bool:
	var controller: Variant = (host.get_meta(META) if host.has_meta(META) else null)
	if not is_instance_valid(controller):
		return false
	for value in controller._units.values():
		var runtime: UnitRuntime = value
		if runtime.has_tail():
			return true
	return false


func set_chain_target(unit_index: int, world_position: Vector3) -> void:
	var runtime: Variant = _units.get(unit_index)
	if runtime != null and runtime.type_name == "CPolyChainProp":
		runtime.set_chain_target(world_position)


func resolve_frame(
	index: int,
	parent_matrix: Transform3D,
	matrix: Transform3D,
	percent: float,
	context: Dictionary
) -> Transform3D:
	var runtime: Variant = _units.get(index)
	if runtime == null:
		return matrix
	return runtime.resolve_frame(parent_matrix, matrix, percent, context)


func update(context: Dictionary) -> void:
	var at_ms: float = _evaluation.time_ms
	var wall_ms: float = _evaluation.wall_ms
	var previous_time: float = at_ms if _last_time < 0.0 else _last_time
	var delta_ms: float = 0.0 if _last_wall < 0.0 else maxf(0.0, wall_ms - _last_wall)
	var restarted: bool = _last_time >= 0.0 and at_ms < _last_time

	if restarted:
		for value in _units.values():
			var runtime: UnitRuntime = value
			runtime.restart(wall_ms)
		previous_time = at_ms
		delta_ms = 0.0

	# Publish every endpoint before resolving chains within this effect.
	for value in _units.values():
		var runtime: UnitRuntime = value
		runtime.publish(context, _blend_overrides)

	for value in _units.values():
		var runtime: UnitRuntime = value
		runtime.tick(at_ms, wall_ms, delta_ms, previous_time)

	_last_time = at_ms
	_last_wall = wall_ms


static func seed_random(seed_value: int) -> void:
	# # ASSUMPTION: Seed 1 is the reproducible default. The original global
	# RNG's initial seed and interleaving with other effects were not supplied.
	_random_state = seed_value & 0xffffffff


static func _random_signed(amplitude: float) -> float:
	# Exact LCG constants recovered from 0x2fda34..0x2fda3a.
	_random_state = (_random_state * 214013 + 2531011) & 0xffffffff
	var sample: int = (_random_state >> 16) & 0x7fff
	return amplitude * (2.0 * float(sample) / 32768.0 - 1.0)


static func _v3(value: Variant, fallback: Vector3 = Vector3.ZERO) -> Vector3:
	if value is Vector3:
		return value
	if value is Array or value is PackedFloat32Array or value is PackedFloat64Array:
		if value.size() >= 3:
			return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return fallback


static func _v2(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if value is Vector2:
		return value
	if value is Array or value is PackedFloat32Array or value is PackedFloat64Array:
		if value.size() >= 2:
			return Vector2(float(value[0]), float(value[1]))
	return fallback


static func _normal(value: Vector3) -> Vector3:
	# NormalizeNoneZero leaves a zero vector unchanged.
	return Vector3.ZERO if value.length_squared() <= EPS * EPS else value.normalized()


static func _bezier(
	a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float
) -> Vector3:
	var s: float = 1.0 - t
	return a * (s * s * s) + b * (3.0 * s * s * t) \
		+ c * (3.0 * s * t * t) + d * (t * t * t)


static func _handle_factor(dot_value: float) -> float:
	# # ASSUMPTION: The unidentified double-precision import at 0x1a3f5c
	# is sqrt; this is consistent with the direction-dependent handle formula.
	return _handle_numerator / (
		sqrt(maxf(0.0, 1.0 + clampf(dot_value, -1.0, 1.0)))
		+ _handle_denominator
	)


static func _mul_color(a: int, b: int) -> int:
	var result: int = 0
	for shift in [0, 8, 16, 24]:
		var component: int = int(
			float(((a >> shift) & 255) * ((b >> shift) & 255)) / 255.0
		)
		result |= component << shift
	return result


static func _add_color(a: int, b: int) -> int:
	var result: int = 0
	for shift in [0, 8, 16, 24]:
		var component: int = mini(((a >> shift) & 255) + ((b >> shift) & 255), 255)
		result |= component << shift
	return result


static func _alpha_color(packed: int, final_alpha: float) -> int:
	var alpha: int = clampi(int(final_alpha * 255.0), 0, 255)
	var product: int = int(float(((packed >> 24) & 255) * alpha) / 255.0)
	return (packed & 0x00ffffff) | (product << 24)


static func _coefficients(hue: float, brightness: float, saturation: float) -> Color:
	var angle: float = hue * TAU
	var cosine: float = cos(angle)
	var shared: float = (1.0 - cosine) / 3.0
	var sine: float = sin(angle) / sqrt(3.0)
	# These coefficients are interpolated across vertices, as in SChainVertex.
	return Color(
		(shared + cosine) * brightness,
		(shared + sine) * brightness,
		(shared - sine) * brightness,
		saturation
	)


static func _blend_name(preset: int, overrides: Dictionary) -> String:
	var override_name: String = str(overrides.get(preset, ""))
	if override_name in ["mix", "add", "sub", "mul", "premul"]:
		return override_name
	match preset:
		2, 8:
			return "add"
		3:
			return "mul"
		_:
			return "mix"


static func _white() -> Texture2D:
	if _white_texture == null:
		var image: Image = Image.create(1, 1, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_white_texture = ImageTexture.create_from_image(image)
	return _white_texture


const COLOR_CODE: String = """
uniform sampler2D image_texture : source_color, filter_linear, repeat_enable;
uniform bool geometry_enabled = false;
uniform vec4 clip_window = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 edge_alpha = vec4(1.0);
uniform vec2 edge_power = vec2(1.0);

varying vec4 fx_tint;
varying vec4 fx_add;
varying vec4 fx_mix;
varying vec2 fx_domain;

vec3 fx_rgb(vec3 rgb) {
	// The recovered geometry matrix applies saturation before hue.
	float gray = dot(rgb, vec3(0.30, 0.59, 0.11));
	vec3 saturated = mix(vec3(gray), rgb, fx_mix.w);
	return vec3(
		dot(saturated, fx_mix.xyz),
		dot(saturated, fx_mix.zxy),
		dot(saturated, fx_mix.yzx)
	) + fx_add.rgb;
}

float fx_edge() {
	if (!geometry_enabled) {
		return 1.0;
	}
	vec2 extent = vec2(
		clip_window.y - clip_window.x,
		clip_window.w - clip_window.z
	);
	if (extent.x <= 0.000001 || extent.y <= 0.000001) {
		return 0.0;
	}
	vec2 q = (fx_domain - clip_window.xz) / extent;
	if (q.x < 0.0 || q.x > 1.0 || q.y < 0.0 || q.y > 1.0) {
		return 0.0;
	}
	q = pow(clamp(q, vec2(0.0), vec2(1.0)), edge_power);
	return mix(edge_alpha.x, edge_alpha.y, q.x)
		* mix(edge_alpha.z, edge_alpha.w, q.y);
}
"""

const DATA_VERTEX_CODE: String = """
uniform sampler2D vertex_data : filter_nearest, repeat_disable;
uniform int vertex_data_width = 1;

vec4 fx_data(int index, int row) {
	return texelFetch(
		vertex_data,
		ivec2(index % vertex_data_width, (index / vertex_data_width) * 4 + row),
		0
	);
}
"""

static func _shader(world: bool, mode: String, depth: int, model: bool) -> Shader:
	var key: String = "%s:%s:%d:%s" % [str(world), mode, depth, str(model)]
	if _shaders.has(key):
		return _shaders[key]

	var blend: String = "blend_premul_alpha" if mode == "premul" else "blend_" + mode
	var source: String
	if world:
		var modes: String = "unshaded, cull_disabled, fog_disabled, " + blend
		modes += ", depth_draw_never" if depth == 2 else ", depth_draw_always"
		if depth == 0:
			modes += ", depth_test_disabled"
		source = "shader_type spatial;\nrender_mode " + modes + ";\n"
	else:
		source = "shader_type canvas_item;\nrender_mode unshaded, " + blend + ";\n"
	source += COLOR_CODE

	if model:
		source += """
uniform vec4 effect_tint : source_color = vec4(1.0);
uniform vec4 effect_add = vec4(0.0);
uniform vec4 effect_mix = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 atlas_rect = vec4(0.0, 0.0, 1.0, 1.0);

void vertex() {
	fx_tint = effect_tint;
	fx_add = effect_add;
	fx_mix = effect_mix;
	fx_domain = UV;
	UV = atlas_rect.xy + UV * atlas_rect.zw;
}
"""
	else:
		source += DATA_VERTEX_CODE
		source += """
void vertex() {
	int index = int(round(UV.x));
	vec4 uv_data = fx_data(index, 0);
	UV = uv_data.xy;
	fx_domain = uv_data.zw;
	fx_tint = fx_data(index, 1);
	fx_add = fx_data(index, 2);
	fx_mix = fx_data(index, 3);
"""
		if not world:
			source += "\tfx_tint *= COLOR;\n"
		source += "}\n"

	if world:
		source += """
void fragment() {
	vec4 texel = texture(image_texture, UV);
	ALBEDO = fx_rgb(texel.rgb) * fx_tint.rgb;
	ALPHA = clamp(texel.a + fx_add.a, 0.0, 1.0) * fx_tint.a * fx_edge();
}
"""
	else:
		source += """
void fragment() {
	vec4 texel = texture(image_texture, UV);
	COLOR = vec4(
		fx_rgb(texel.rgb) * fx_tint.rgb,
		clamp(texel.a + fx_add.a, 0.0, 1.0) * fx_tint.a * fx_edge()
	);
}
"""
	var result: Shader = Shader.new()
	result.code = source
	_shaders[key] = result
	return result


class Batch extends RefCounted:
	var vertices: PackedVector3Array = PackedVector3Array()
	var coordinates: PackedVector2Array = PackedVector2Array()
	var domains: PackedVector2Array = PackedVector2Array()
	var tints: PackedColorArray = PackedColorArray()
	var additions: PackedColorArray = PackedColorArray()
	var coefficients: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()

	func vertex(
		point: Vector3,
		uv: Vector2,
		style: Dictionary,
		domain: Vector2 = Vector2.ZERO
	) -> int:
		var index: int = vertices.size()
		vertices.append(point)
		coordinates.append(uv)
		domains.append(domain)
		tints.append(style["tint"])
		additions.append(style["add"])
		coefficients.append(style["mix"])
		return index

	func quad(points: Array, uvs: Array, styles: Array, domain_values: Array = []) -> void:
		var base: int = vertices.size()
		for i in range(4):
			var domain: Vector2 = Vector2.ZERO
			if domain_values.size() == 4:
				domain = domain_values[i]
			vertex(points[i], uvs[i], styles[i], domain)
		indices.append_array(PackedInt32Array([
			base, base + 1, base + 2, base, base + 2, base + 3
		]))

	func data_image() -> Image:
		var width: int = mini(EffectUnitsTrail.DATA_WIDTH, maxi(1, vertices.size()))
		var groups: int = int(ceil(float(vertices.size()) / float(width)))
		var height: int = maxi(4, groups * 4)
		var values: PackedFloat32Array = PackedFloat32Array()
		values.resize(width * height * 4)
		for i in range(vertices.size()):
			var column: int = i % width
			var row: int = int(float(i) / float(width)) * 4
			var uv: Vector2 = coordinates[i]
			var domain: Vector2 = domains[i]
			var records: Array = [
				Color(uv.x, uv.y, domain.x, domain.y),
				tints[i], additions[i], coefficients[i]
			]
			for j in range(4):
				var offset: int = ((row + j) * width + column) * 4
				var color_value: Color = records[j]
				values[offset] = color_value.r
				values[offset + 1] = color_value.g
				values[offset + 2] = color_value.b
				values[offset + 3] = color_value.a
		return Image.create_from_data(
			width, height, false, Image.FORMAT_RGBAF, values.to_byte_array()
		)


class CanvasMesh extends Node2D:
	var drawing_mesh: ArrayMesh
	var drawing_texture: Texture2D

	func _draw() -> void:
		if drawing_mesh != null and drawing_texture != null:
			draw_mesh(drawing_mesh, drawing_texture)


class CanvasModel extends Node2D:
	var drawing_texture: Texture2D
	var points: PackedVector2Array = PackedVector2Array()

	func _draw() -> void:
		if drawing_texture != null and points.size() == 4:
			# Orthographic camera has Y up; the UI projection has Y down.
			draw_polygon(
				points,
				PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]),
				PackedVector2Array([
					Vector2(0, 1), Vector2(1, 1),
					Vector2(1, 0), Vector2(0, 0)
				]),
				drawing_texture
			)


class UnitRuntime extends Node:
	var type_name: String = ""
	var unit: Dictionary = {}
	var properties: Dictionary = {}
	var evaluation: EffectEval
	var index: int = -1
	var host: Node

	var _context: Dictionary = {}
	var _overrides: Dictionary = {}
	var _xf: Transform3D = Transform3D.IDENTITY
	var _percent: float = 0.0
	var _bone_resolved: bool = true
	var _texture: Texture2D
	var _warnings: Dictionary = {}

	var _world_surface: MeshInstance3D
	var _canvas_surface: CanvasMesh
	var _batch_material: ShaderMaterial
	var _data_texture: ImageTexture

	var _samples: Array = []
	var _retired: Array = []
	var _anchor: Dictionary = {}
	var _tail: Dictionary = {}
	var _control_out: Array = [Vector3.ZERO, Vector3.ZERO]
	var _sample_serial: int = 0

	var _registered: bool = false
	var _target_pending: bool = false
	var _target: Vector3 = Vector3.ZERO
	var _chain_pairs: Array = []
	var _chain_epoch: float = 0.0
	var _chain_scroll: float = 0.0

	var _uv_angle: float = 0.0
	var _uv_zoom: float = 1.0
	var _uv_offset: Vector2 = Vector2.ZERO

	var _model_attempted: bool = false
	var _model_root: Node3D
	var _model_surfaces: Array = []
	var _animation_players: Array = []
	var _model_viewport: SubViewport
	var _model_camera: Camera3D
	var _model_canvas: CanvasModel

	func configure(
		definition: Dictionary,
		simulation: EffectEval,
		unit_index: int,
		visual_host: Node,
		class_string: String
	) -> void:
		unit = definition
		evaluation = simulation
		index = unit_index
		host = visual_host
		type_name = class_string
		name = "U1_%d" % index
		var value: Variant = unit.get(EffectUnitsTrail.PROPERTY_KEYS[type_name], {})
		properties = value if value is Dictionary else {}
		_texture = EffectUnitsTrail.Eval.texture_at(str(
			unit.get("texture", properties.get("texture", ""))
		))
		_bone_resolved = not bool(unit.get("needs_bone", false))

	func _exit_tree() -> void:
		for visual in [
			_world_surface, _canvas_surface, _model_root,
			_model_viewport, _model_canvas
		]:
			if is_instance_valid(visual) and not visual.is_queued_for_deletion():
				visual.queue_free()

	func _warn(key: String, message: String) -> void:
		if not _warnings.has(key):
			_warnings[key] = true
			push_warning("EffectUnitsTrail[%d]: %s" % [index, message])

	func _raw(offset: int, fallback: Variant) -> Variant:
		var values: Variant = properties.get("abi", unit.get("abi", {}))
		if not values is Dictionary:
			return fallback
		return values.get("0x%x" % offset, fallback)

	func _prop(key: String, offset: int, fallback: Variant) -> Variant:
		if not key.is_empty() and properties.has(key):
			return properties[key]
		return _raw(offset, fallback)

	func _pair(key: String, offset: int, a: float, b: float) -> Vector2:
		if properties.has(key):
			var value: Variant = properties[key]
			if value is Vector2:
				return value
			if value is Array and value.size() >= 2:
				return Vector2(float(value[0]), float(value[1]))
			if value is float or value is int:
				return Vector2(float(value), float(value))
		return Vector2(float(_raw(offset, a)), float(_raw(offset + 4, b)))

	func _range_value(key: String, offset: int, channel: int, q: float,
			a: float, b: float) -> float:
		var limits: Vector2 = _pair(key, offset, a, b)
		return lerpf(
			limits.x, limits.y,
			EffectUnitsTrail.Eval.byte_track(unit, channel, q)
		)

	func _scale() -> float:
		return float(_context.get("unit_scale", 1.0))

	func _final_alpha() -> float:
		return clampf(float(_context.get("final_alpha", 1.0)), 0.0, 1.0)

	func _is_canvas() -> bool:
		return bool(_context.get("canvas", host is Node2D))

	func _active(at_ms: float) -> bool:
		return (
			at_ms > float(unit.get("start_ms", 0))
			and at_ms <= EffectUnitsTrail.Eval.unit_end(unit)
			and _bone_resolved
		)

	func _blend() -> int:
		match type_name:
			"CPolyTrailProp":
				return int(_prop("blend", 0xd4, 1))
			"CPolyChainProp":
				return int(_prop("blend", 0xec, 1))
			"CGeometryProp":
				return int(_prop("blend", 0xb8, 1))
			_:
				# # ASSUMPTION: AttachMesh material fields are semantic only;
				# no AttachMesh material layout was supplied.
				return int(properties.get("blend", 1))

	func _depth() -> int:
		match type_name:
			"CPolyTrailProp":
				return int(_prop("depth", 0xd8, 2))
			"CPolyChainProp":
				return int(_prop("depth", 0xf0, 2))
			"CGeometryProp":
				return int(_prop("depth", 0xbc, 2))
			_:
				return int(properties.get("depth", 2))

	func _brightness() -> float:
		match type_name:
			"CPolyTrailProp":
				return float(_prop("brightness", 0xcc, 1.0))
			"CPolyChainProp":
				return float(_prop("brightness", 0xe8, 1.0))
			"CGeometryProp":
				return float(_prop("brightness", 0x114, 1.0))
			_:
				return float(properties.get("brightness", 1.0))

	func _style(
		q: float,
		tint_value: int,
		add_value: int,
		neutral_missing: bool = false
	) -> Dictionary:
		var brightness_track: float = EffectUnitsTrail.Eval.byte_track(unit, 1, q)
		var saturation_track: float = EffectUnitsTrail.Eval.byte_track(unit, 2, q)
		if neutral_missing:
			if EffectUnitsTrail.Eval.track_at(unit, "bytes", 1).is_empty():
				brightness_track = 1.0
			if EffectUnitsTrail.Eval.track_at(unit, "bytes", 2).is_empty():
				saturation_track = 1.0
		var hue: float = (
			EffectUnitsTrail.Eval.byte_track(unit, 0, q)
			+ float(_context.get("parent_hue", 0.0))
		)
		return {
			"tint": EffectUnitsTrail.Eval.unpack_color(tint_value),
			"add": EffectUnitsTrail.Eval.unpack_color(add_value),
			"mix": EffectUnitsTrail._coefficients(
				hue, brightness_track * _brightness(), saturation_track
			),
		}

	func _unit_style(q: float, neutral_missing: bool = false) -> Dictionary:
		var fallback: int = 0xffffffff if neutral_missing else 0
		var tint_value: int = EffectUnitsTrail.Eval.packed_color_track(unit, 0, q, fallback)
		tint_value = EffectUnitsTrail._alpha_color(tint_value, _final_alpha())
		var additive: int = EffectUnitsTrail.Eval.packed_color_track(unit, 1, q)
		return _style(q, tint_value, additive, neutral_missing)

	func resolve_frame(
		parent_matrix: Transform3D,
		matrix: Transform3D,
		q: float,
		context: Dictionary
	) -> Transform3D:
		var bone_name: String = str(properties.get("bone", unit.get("bone", "")))
		var needs_bone: bool = bool(unit.get("needs_bone", false)) or not bone_name.is_empty()
		_bone_resolved = true
		if needs_bone:
			var binding: Variant = null
			var resolver: Callable = context.get("u1_attachment", Callable())
			if resolver.is_valid():
				binding = resolver.call(unit, index, parent_matrix, q, context)
			elif not bone_name.is_empty():
				# # ASSUMPTION: A named bone is searched below attachment_root,
				# or below the effect host's parent when no resolver is provided.
				var root: Variant = context.get("attachment_root", host.get_parent())
				if is_instance_valid(root):
					var candidates: Array = root.find_children("*", "Skeleton3D", true, false)
					if root is Skeleton3D:
						candidates.push_front(root)
					for candidate in candidates:
						var skeleton: Skeleton3D = candidate as Skeleton3D
						var bone_index: int = skeleton.find_bone(bone_name)
						if bone_index >= 0:
							binding = skeleton.global_transform \
								* skeleton.get_bone_global_pose(bone_index)
							break
			if binding is Transform3D:
				parent_matrix = evaluation._binding_matrix(
					binding, int(unit.get("link", 0)), context
				)
				matrix = Transform3D(
					parent_matrix.basis,
					parent_matrix * EffectUnitsTrail.Eval.position_track(unit, q)
				)
			else:
				_bone_resolved = false

		if type_name == "CGeometryProp":
			var normal: Vector3 = EffectUnitsTrail._v3(
				_prop("normal", 0xd8, [0, 1, 0]), Vector3.UP
			)
			if normal.x != 0.0 or normal.z != 0.0:
				var z_axis: Vector3 = EffectUnitsTrail._normal(normal.cross(Vector3.UP))
				var x_axis: Vector3 = EffectUnitsTrail._normal(normal.cross(z_axis))
				# The source stores the supplied, unnormalized Y column.
				matrix.basis = parent_matrix.basis * Basis(x_axis, normal, z_axis)
		elif type_name == "CPolyChainProp":
			# CPolyChain stores an identity output basis after transforming
			# its offset. Preserve the engine-to-world conversion for children.
			matrix.basis = Basis.IDENTITY.scaled(
				Vector3.ONE * float(context.get("unit_scale", 1.0))
			)
		return matrix

	func publish(context: Dictionary, overrides: Dictionary) -> void:
		_context = context
		_overrides = overrides
		_xf = evaluation.states[index]["xf"]
		_percent = clampf(
			EffectUnitsTrail.Eval.percent_at(unit, evaluation.time_ms), 0.0, 1.0
		)
		if type_name == "CPolyChainProp" and _active(evaluation.time_ms):
			if not _registered and not _chain_name().is_empty():
				EffectUnitsTrail._registry.append(weakref(self))
				_registered = true

	func restart(wall_ms: float) -> void:
		if type_name == "CPolyTrailProp" and not _samples.is_empty():
			# CPolyTrail::IsNeedCreateLeavingEffect returns true.
			_retired.append({"samples": _samples, "percent": _percent})
		_samples = []
		_anchor = {}
		_tail = {}
		_control_out = [Vector3.ZERO, Vector3.ZERO]
		_chain_pairs = []
		_chain_epoch = wall_ms
		_chain_scroll = 0.0
		_uv_angle = 0.0
		_uv_zoom = 1.0
		_uv_offset = Vector2.ZERO
		_target_pending = false

	func tick(
		at_ms: float,
		wall_ms: float,
		delta_ms: float,
		previous_time: float
	) -> void:
		var active_delta: float = maxf(
			0.0,
			minf(at_ms, EffectUnitsTrail.Eval.unit_end(unit))
			- maxf(previous_time, float(unit.get("start_ms", 0)))
		)
		active_delta = minf(active_delta, delta_ms)
		match type_name:
			"CPolyTrailProp":
				_update_trail(at_ms, wall_ms, active_delta)
				_draw_trail(wall_ms)
			"CPolyChainProp":
				_update_chain(at_ms, wall_ms, active_delta)
			"CGeometryProp":
				if _active(at_ms):
					_update_geometry_uv(active_delta)
					_draw_geometry()
				else:
					_hide_surfaces()
			"CEffectAttachMesh":
				_update_model(at_ms)

	func has_tail() -> bool:
		if type_name != "CPolyTrailProp":
			return false
		if not _samples.is_empty():
			return true
		for history in _retired:
			if not history["samples"].is_empty():
				return true
		return false

	func _hide_surfaces() -> void:
		if is_instance_valid(_world_surface):
			_world_surface.hide()
		if is_instance_valid(_canvas_surface):
			_canvas_surface.hide()

	func _draw_batch(batch: Batch, geometry_parameters: Dictionary = {}) -> void:
		if batch.vertices.is_empty() or batch.indices.is_empty() or _texture == null:
			_hide_surfaces()
			return

		var positions: PackedVector3Array = batch.vertices
		var encoded_uvs: PackedVector2Array = PackedVector2Array()
		encoded_uvs.resize(positions.size())
		for i in range(positions.size()):
			encoded_uvs[i] = Vector2(float(i), 0)

		var world: bool = not _is_canvas()
		if world:
			if not host is Node3D or absf(host.global_transform.basis.determinant()) <= 0.000000001:
				_hide_surfaces()
				return
			if _world_surface == null:
				_world_surface = MeshInstance3D.new()
				_world_surface.name = "U1Mesh_%d" % index
				_world_surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				host.add_child(_world_surface)
			_world_surface.transform = host.global_transform.affine_inverse()
		else:
			if not host is Node2D or absf(host.global_transform.determinant()) <= 0.000000001:
				_hide_surfaces()
				return
			if _canvas_surface == null:
				_canvas_surface = CanvasMesh.new()
				_canvas_surface.name = "U1Canvas_%d" % index
				_canvas_surface.z_index = clampi(index, -4096, 4095)
				host.add_child(_canvas_surface)
			var inverse: Transform2D = host.global_transform.affine_inverse()
			positions = PackedVector3Array()
			for point in batch.vertices:
				var projected: Vector2 = inverse * Vector2(point.x, point.y)
				positions.append(Vector3(projected.x, projected.y, 0))

		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = positions
		arrays[Mesh.ARRAY_TEX_UV] = encoded_uvs
		arrays[Mesh.ARRAY_INDEX] = batch.indices
		var mesh: ArrayMesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

		var image: Image = batch.data_image()
		if _data_texture == null:
			_data_texture = ImageTexture.create_from_image(image)
		elif (
			_data_texture.get_width() != image.get_width()
			or _data_texture.get_height() != image.get_height()
		):
			_data_texture.set_image(image)
		else:
			_data_texture.update(image)

		if _batch_material == null:
			_batch_material = ShaderMaterial.new()
		_batch_material.shader = EffectUnitsTrail._shader(
			world, EffectUnitsTrail._blend_name(_blend(), _overrides), _depth(), false
		)
		_batch_material.render_priority = clampi(index, -128, 127)
		_batch_material.set_shader_parameter("vertex_data", _data_texture)
		_batch_material.set_shader_parameter("vertex_data_width", image.get_width())
		_batch_material.set_shader_parameter("image_texture", _texture)
		_batch_material.set_shader_parameter("geometry_enabled", not geometry_parameters.is_empty())
		if not geometry_parameters.is_empty():
			_batch_material.set_shader_parameter("clip_window", geometry_parameters["clip"])
			_batch_material.set_shader_parameter("edge_alpha", geometry_parameters["alpha"])
			_batch_material.set_shader_parameter("edge_power", geometry_parameters["power"])

		if world:
			_world_surface.mesh = mesh
			_world_surface.material_override = _batch_material
			_world_surface.show()
		else:
			_canvas_surface.drawing_mesh = mesh
			_canvas_surface.drawing_texture = _texture
			_canvas_surface.material = _batch_material
			_canvas_surface.show()
			_canvas_surface.queue_redraw()

	# ------------------------------------------------------------------
	# CPolyTrail
	# ------------------------------------------------------------------

	func _trail_life() -> float:
		return maxf(1.0, float(_prop("lifetime_ms", 0xd0, 1)))

	func _one_sided() -> bool:
		return bool(_prop("one_sided", 0xb1, false))

	func _trail_mode() -> int:
		return int(_prop("uv_mode", 0xb2, 1))

	func _trail_subdivisions() -> int:
		var subdivisions: int = maxi(1, int(_prop("subdivisions", 0x58, 1)))
		return subdivisions if _trail_mode() == 0 else subdivisions * 4

	func _sample(time_value: float, position_value: Vector3, direction: Vector3) -> Dictionary:
		_sample_serial += 1
		return {
			"id": _sample_serial,
			"time": time_value,
			"position": position_value,
			"direction": direction,
		}

	func _sample_index(sample: Dictionary) -> int:
		if sample.is_empty():
			return -1
		for i in range(_samples.size()):
			if int(_samples[i]["id"]) == int(sample["id"]):
				return i
		return -1

	func _edges(sample: Dictionary) -> Array:
		var limits: Vector2 = _pair("half_width", 0xc4, 0.0, 0.0)
		var width_vector: Vector3 = sample["direction"] * limits.y * _scale()
		var position_value: Vector3 = sample["position"]
		return [
			position_value + width_vector,
			position_value if _one_sided() else position_value - width_vector
		]

	func _write_edges(
		sample: Dictionary,
		time_value: float,
		upper: Vector3,
		lower: Vector3
	) -> void:
		sample["time"] = floor(time_value)
		sample["position"] = lower if _one_sided() else (upper + lower) * 0.5
		sample["direction"] = EffectUnitsTrail._normal(upper - lower)

	func _prune(samples: Array, wall_ms: float, protected_id: int = -1) -> void:
		while not samples.is_empty():
			var first: Dictionary = samples[0]
			if int(first["id"]) == protected_id:
				break
			if wall_ms - float(first["time"]) < _trail_life():
				break
			samples.pop_front()

	func _update_trail(at_ms: float, wall_ms: float, active_delta: float) -> void:
		var leaving: bool = (
			bool(_context.get("leaving", false))
			or at_ms > EffectUnitsTrail.Eval.unit_end(unit)
		)
		var protected_id: int = -1
		if not leaving and not _anchor.is_empty():
			protected_id = int(_anchor["id"])
		_prune(_samples, wall_ms, protected_id)
		for i in range(_retired.size() - 1, -1, -1):
			var history: Dictionary = _retired[i]
			_prune(history["samples"], wall_ms)
			if history["samples"].is_empty():
				_retired.remove_at(i)

		if leaving or not _active(at_ms) or _percent >= 1.0 or active_delta <= 0.0:
			return

		var local_direction: Vector3 = EffectUnitsTrail._v3(
			_prop("direction", 0xb8, [0, 1, 0]), Vector3.UP
		)
		var direction: Vector3 = EffectUnitsTrail._normal(_xf.basis * local_direction)
		if direction == Vector3.ZERO:
			# # ASSUMPTION: Invalid zero directions retain the previous direction.
			direction = Vector3.UP if _tail.is_empty() else _tail["direction"]

		if not _tail.is_empty():
			if _tail["position"] == _xf.origin and _tail["direction"] == direction:
				# A stationary emitter refreshes the final sample timestamp.
				_tail["time"] = wall_ms
				return

		var next_sample: Dictionary = _sample(wall_ms, _xf.origin, direction)
		if _tail.is_empty():
			var first: Dictionary = _sample(wall_ms, _xf.origin, direction)
			var second: Dictionary = _sample(wall_ms, _xf.origin, direction)
			_samples.append(first)
			_samples.append(second)
			_anchor = first
			_tail = second

		_append_trail_pose(next_sample)

	func _append_trail_pose(next_sample: Dictionary) -> void:
		var first_edges: Array = _edges(_anchor)
		var middle_edges: Array = _edges(_tail)
		var last_edges: Array = _edges(next_sample)
		var incoming: Array = []
		var outgoing: Array = []
		var first_factor: float = EffectUnitsTrail._handle_factor(
			Vector3(_anchor["direction"]).dot(_tail["direction"])
		)
		var second_factor: float = EffectUnitsTrail._handle_factor(
			Vector3(_tail["direction"]).dot(next_sample["direction"])
		)
		for edge in range(2):
			var backwards: Vector3 = EffectUnitsTrail._normal(
				first_edges[edge] - last_edges[edge]
			)
			incoming.append(
				middle_edges[edge] + backwards
				* Vector3(middle_edges[edge]).distance_to(first_edges[edge])
				* first_factor
			)
			outgoing.append(
				middle_edges[edge] - backwards
				* Vector3(last_edges[edge]).distance_to(middle_edges[edge])
				* second_factor
			)

		var subdivisions: int = _trail_subdivisions()
		var anchor_index: int = _sample_index(_anchor)
		var tail_index: int = _sample_index(_tail)
		for i in range(anchor_index + 1, tail_index):
			var fraction: float = float(i - anchor_index) / float(subdivisions)
			var upper: Vector3 = EffectUnitsTrail._bezier(
				first_edges[0], _control_out[0], incoming[0], middle_edges[0], fraction
			)
			var lower: Vector3 = EffectUnitsTrail._bezier(
				first_edges[1], _control_out[1], incoming[1], middle_edges[1], fraction
			)
			_write_edges(
				_samples[i],
				lerpf(float(_anchor["time"]), float(_tail["time"]), fraction),
				upper, lower
			)

		_anchor = _tail
		_control_out = outgoing

		var end_control: Array = []
		var end_direction: Vector3 = next_sample["direction"]
		for edge in range(2):
			var difference: Vector3 = middle_edges[edge] - last_edges[edge]
			var perpendicular: Vector3 = end_direction.cross(
				difference.cross(end_direction)
			)
			end_control.append(
				last_edges[edge] + EffectUnitsTrail._normal(perpendicular)
				* Vector3(outgoing[edge]).distance_to(last_edges[edge])
			)

		for i in range(1, subdivisions):
			var fraction: float = float(i) / float(subdivisions)
			var upper: Vector3 = EffectUnitsTrail._bezier(
				middle_edges[0], outgoing[0], end_control[0], last_edges[0], fraction
			)
			var lower: Vector3 = EffectUnitsTrail._bezier(
				middle_edges[1], outgoing[1], end_control[1], last_edges[1], fraction
			)
			var interpolated: Dictionary = _sample(0.0, Vector3.ZERO, Vector3.ZERO)
			_write_edges(
				interpolated,
				lerpf(float(_tail["time"]), float(next_sample["time"]), fraction),
				upper, lower
			)
			_samples.append(interpolated)
		_samples.append(next_sample)
		_tail = next_sample

	func _trail_uv(uv: Vector2) -> Vector2:
		var table_index: int = 0
		if bool(_prop("uv_swap", 0xb3, false)):
			table_index |= 4
		if bool(_prop("uv_positive_u", 0xb4, false)):
			table_index |= 1
		if bool(_prop("uv_positive_v", 0xb5, false)):
			table_index |= 2
		if _trail_mode() == 0:
			table_index = 7 - table_index
		var result: Vector2 = Vector2(uv.y, uv.x) if (table_index & 4) != 0 else uv
		result.x *= 1.0 if (table_index & 1) != 0 else -1.0
		result.y *= 1.0 if (table_index & 2) != 0 else -1.0
		return result

	func _trail_style(age: float, emitter_percent: float) -> Dictionary:
		var emitter_tint: int = EffectUnitsTrail.Eval.packed_color_track(
			unit, 2, emitter_percent
		)
		emitter_tint = EffectUnitsTrail._alpha_color(emitter_tint, _final_alpha())
		var tint_value: int = EffectUnitsTrail._mul_color(
			EffectUnitsTrail.Eval.packed_color_track(unit, 0, age), emitter_tint
		)
		var additive: int = EffectUnitsTrail._add_color(
			EffectUnitsTrail.Eval.packed_color_track(unit, 1, age),
			EffectUnitsTrail.Eval.packed_color_track(unit, 3, emitter_percent)
		)
		return _style(age, tint_value, additive)

	func _draw_trail(wall_ms: float) -> void:
		var batch: Batch = Batch.new()
		for history in _retired:
			_append_trail_drawing(batch, history["samples"], wall_ms, float(history["percent"]))
		_append_trail_drawing(batch, _samples, wall_ms, _percent)
		_draw_batch(batch)

	func _append_trail_drawing(
		batch: Batch,
		samples: Array,
		wall_ms: float,
		emitter_percent: float
	) -> void:
		if samples.size() < 2 or _texture == null:
			return
		var aspect: float = float(_texture.get_height()) / maxf(1.0, _texture.get_width())
		var along: float = aspect
		var increment: float = (
			1.0 / float(samples.size() - 1) if _trail_mode() == 2 else 0.25
		)
		var previous_pair: Vector2i = Vector2i(-1, -1)

		for i in range(samples.size()):
			var sample: Dictionary = samples[i]
			var age: float = clampf(
				(wall_ms - float(sample["time"])) / _trail_life(), 0.0, 1.0
			)
			var width: float = _range_value("half_width", 0xc4, 3, age, 0.0, 0.0) * _scale()
			var side: Vector3 = sample["direction"] * width
			var position_value: Vector3 = sample["position"]
			var style: Dictionary = _trail_style(age, emitter_percent)

			if _trail_mode() == 0:
				if i == 0:
					continue
				var previous: Dictionary = samples[i - 1]
				var backwards: Vector3 = EffectUnitsTrail._normal(
					position_value - Vector3(previous["position"])
				) * aspect * width
				var positive_side: Vector3 = Vector3.ZERO if _one_sided() else side
				batch.quad(
					[
						position_value - backwards - side,
						position_value - backwards + positive_side,
						position_value + backwards + positive_side,
						position_value + backwards - side
					],
					[
						_trail_uv(Vector2(0, 0)), _trail_uv(Vector2(1, 0)),
						_trail_uv(Vector2(1, 1)), _trail_uv(Vector2(0, 1))
					],
					[style, style, style, style]
				)
			else:
				var first: int = batch.vertex(
					position_value if _one_sided() else position_value + side,
					_trail_uv(Vector2(along, 0)), style
				)
				var second: int = batch.vertex(
					position_value - side, _trail_uv(Vector2(along, 1)), style
				)
				if previous_pair.x >= 0:
					batch.indices.append_array(PackedInt32Array([
						previous_pair.x, previous_pair.y, second,
						previous_pair.x, second, first
					]))
				previous_pair = Vector2i(first, second)
				along += increment

	# ------------------------------------------------------------------
	# CPolyChain
	# ------------------------------------------------------------------

	func _chain_name() -> String:
		return str(_prop("name", 0x40, unit.get("name", "")))

	func set_chain_target(world_position: Vector3) -> void:
		_target = world_position
		_target_pending = true

	func _chain_targets() -> Array:
		var result: Array = []
		var external: Variant = _context.get("u1_chain_targets", {})
		if external is Dictionary and external.has(index):
			var values: Variant = external[index]
			if values is Vector3:
				result.append(values)
			elif values is Array:
				for value in values:
					result.append(EffectUnitsTrail._v3(value))
			return result.slice(0, 20)

		if _target_pending:
			result.append(_target)
			_target_pending = false
			return result

		var group: String = str(_prop("target_group", 0xb4, ""))
		if group.is_empty():
			return result
		var radius: float = float(_prop("target_radius", 0xe0, 0.0)) * _scale()
		var radius_squared: float = radius * radius
		var scope: int = int(_prop("target_scope", 0xb8, 0))
		var scene_id: int = host.get_tree().root.get_instance_id()

		for i in range(EffectUnitsTrail._registry.size() - 1, -1, -1):
			var candidate: Variant = EffectUnitsTrail._registry[i].get_ref()
			if not is_instance_valid(candidate):
				EffectUnitsTrail._registry.remove_at(i)

		for reference in EffectUnitsTrail._registry:
			var candidate: Variant = reference.get_ref()
			if candidate == self or not candidate.is_inside_tree():
				continue
			if candidate._chain_name() != group:
				continue
			if candidate.host.get_tree().root.get_instance_id() != scene_id:
				continue
			if scope == 1 and candidate.host.get_parent() != host.get_parent():
				continue
			if scope == 2 and candidate.evaluation != evaluation:
				continue
			var endpoint: Vector3 = candidate._xf.origin
			if endpoint.distance_squared_to(_xf.origin) >= radius_squared:
				continue
			result.append(endpoint)
			if result.size() == 20:
				break
		return result

	func _update_chain(at_ms: float, wall_ms: float, active_delta: float) -> void:
		if not _active(at_ms):
			_target_pending = false
			_hide_surfaces()
			return
		var ribbon_count: int = maxi(0, int(_prop("ribbons", 0xc8, 1)))
		var segments: int = maxi(1, int(_prop("segments", 0xcc, 1)))
		if ribbon_count == 0:
			_hide_surfaces()
			return

		var speed: float = float(_prop("uv_speed", 0xdc, 0.0))
		if speed == 0.0:
			_chain_scroll = 0.0
		else:
			_chain_scroll += speed * active_delta * 0.001 \
				* float(_context.get("frame_scale", 1.0))

		var period: float = maxf(1.0, float(_prop("jitter_period_ms", 0xd8, 1)))
		var changed: bool = _chain_pairs.size() != ribbon_count
		while _chain_pairs.size() < ribbon_count:
			_chain_pairs.append([])
		while _chain_pairs.size() > ribbon_count:
			_chain_pairs.pop_back()
		for ribbon in range(ribbon_count):
			var pairs: Array = _chain_pairs[ribbon]
			changed = changed or pairs.size() != segments + 1
			while pairs.size() < segments + 1:
				pairs.append(Vector2.ZERO)
			while pairs.size() > segments + 1:
				pairs.pop_back()

		var time_tracks: bool = bool(_prop("time_tracks", 0xf9, false))
		if changed or wall_ms - _chain_epoch >= period:
			# A hitch regenerates once; the source does not catch up in a loop.
			_chain_epoch = wall_ms
			var minimum: float = float(_prop("amplitude_min", 0xd4, 0.0))
			var maximum: float = float(_prop("amplitude_max", 0xd0, 0.0))
			for ribbon in range(ribbon_count):
				var pairs: Array = _chain_pairs[ribbon]
				for j in range(segments + 1):
					var q: float = _percent if time_tracks else float(j) / float(segments)
					var amplitude: float = lerpf(
						minimum, maximum,
						EffectUnitsTrail.Eval.byte_track(unit, 3, q)
					)
					var old_pair: Vector2 = pairs[j]
					pairs[j] = Vector2(old_pair.y, EffectUnitsTrail._random_signed(amplitude))

		var weight: float = (wall_ms - _chain_epoch) / period
		var batch: Batch = Batch.new()
		var targets: Array = _chain_targets()
		var half_width: float = float(_prop("half_width", 0xc4, 0.0))
		var amplitude_max: float = float(_prop("amplitude_max", 0xd0, 0.0))
		var proportional: bool = bool(_prop("proportional_width", 0xfa, false))
		var directions: Variant = _prop("ribbon_directions", 0x10c, [])
		var mode: int = int(_prop("uv_mode", 0xf4, 0))

		for endpoint_value in targets:
			var endpoint: Vector3 = endpoint_value
			var delta: Vector3 = endpoint - _xf.origin
			var u_axis: Vector3
			var v_axis: Vector3
			if delta.x != 0.0 or delta.z != 0.0:
				u_axis = EffectUnitsTrail._normal(Vector3(delta.z, 0, -delta.x))
				v_axis = EffectUnitsTrail._normal(delta.cross(u_axis))
			else:
				# Exact vertical/zero-delta fallback in RenderImp.
				u_axis = Vector3.FORWARD
				v_axis = Vector3.LEFT

			for ribbon in range(ribbon_count):
				var radial: Vector2
				if directions is Array and ribbon < directions.size():
					radial = EffectUnitsTrail._v2(directions[ribbon])
				else:
					# # ASSUMPTION: The omitted property initializer distributes
					# ribbon planes evenly over a half turn.
					var angle: float = PI * float(ribbon) / float(ribbon_count)
					radial = Vector2(cos(angle), sin(angle))
				var direction: Vector3 = u_axis * radial.x + v_axis * radial.y
				var previous_pair: Vector2i = Vector2i(-1, -1)
				var pairs: Array = _chain_pairs[ribbon]

				for j in range(segments + 1):
					var fraction: float = float(j) / float(segments)
					var pair: Vector2 = pairs[j]
					var displacement: float = lerpf(pair.x, pair.y, weight)
					var width: float = half_width
					if proportional:
						width = displacement * (
							half_width / amplitude_max if amplitude_max != 0.0 else 0.0
						)
					var position_value: Vector3 = _xf.origin + delta * fraction
					var q: float = _percent if time_tracks else fraction
					var style: Dictionary = _unit_style(q)
					var along: float = fraction if mode == 0 else float(j)
					if mode == 2:
						# RenderImp uses this value without multiplying by j.
						along = float(_prop("uv_length_scale", 0xe4, 1.0)) \
							* delta.length() / maxf(absf(_scale()), EffectUnitsTrail.EPS)
					along += _chain_scroll
					var first: int = batch.vertex(
						position_value + direction * (displacement + width) * _scale(),
						_chain_uv(along, false), style
					)
					var second: int = batch.vertex(
						position_value + direction * (displacement - width) * _scale(),
						_chain_uv(along, true), style
					)
					if previous_pair.x >= 0:
						batch.indices.append_array(PackedInt32Array([
							previous_pair.x, previous_pair.y, second,
							previous_pair.x, second, first
						]))
					previous_pair = Vector2i(first, second)

		# Original strip separator/cap triangles are degenerate and have no area.
		_draw_batch(batch)

	func _chain_uv(along: float, second: bool) -> Vector2:
		var across: float = 1.0 if second else 0.0
		var uv: Vector2 = Vector2(across, along) \
			if bool(_prop("uv_swap", 0xfb, false)) else Vector2(along, across)
		if bool(_prop("uv_flip_u", 0xfc, false)):
			uv.x = 1.0 - uv.x
		if bool(_prop("uv_flip_v", 0xfd, false)):
			uv.y = 1.0 - uv.y
		return uv

	# ------------------------------------------------------------------
	# CGeometry
	# ------------------------------------------------------------------

	func _update_geometry_uv(delta_ms: float) -> void:
		var seconds: float = delta_ms * 0.001
		var angular_speed: float = float(_prop("uv_rotation_speed", 0xc8, 0.0))
		var zoom_speed: float = float(_prop("uv_zoom_speed", 0xcc, 0.0))
		var u_speed: float = float(_prop("uv_speed_u", 0xd0, 0.0))
		var v_speed: float = float(_prop("uv_speed_v", 0xd4, 0.0))
		_uv_angle = 0.0 if angular_speed == 0.0 else _uv_angle + angular_speed * seconds
		_uv_zoom = 1.0 if zoom_speed == 0.0 else _uv_zoom + zoom_speed * seconds
		_uv_offset.x = 0.0 if u_speed == 0.0 else _uv_offset.x + u_speed * seconds
		_uv_offset.y = 0.0 if v_speed == 0.0 else _uv_offset.y + v_speed * seconds

	func _geometry_bounds(key: String, offset: int, channel: int) -> Vector2:
		var limits: Vector2 = _pair(key, offset, 0.0, 1.0)
		var current: float = lerpf(
			limits.x, limits.y,
			EffectUnitsTrail.Eval.byte_track(unit, channel, _percent)
		)
		return Vector2(minf(limits.x, current), maxf(limits.x, current))

	func _geometry_uv(domain: Vector2, u_bounds: Vector2, v_bounds: Vector2) -> Vector2:
		var uv: Vector2 = domain
		if not bool(_prop("crop_texture", 0xc3, false)):
			uv = Vector2(
				(domain.x - u_bounds.x) / maxf(EffectUnitsTrail.EPS, u_bounds.y - u_bounds.x),
				(domain.y - v_bounds.x) / maxf(EffectUnitsTrail.EPS, v_bounds.y - v_bounds.x)
			)

		var rectangle: Rect2 = EffectUnitsTrail.Eval.texture_rect(unit, _percent)
		var columns: float = float(_prop("uv_columns", 0x58, 1))
		var rows: float = float(_prop("uv_rows", 0xc7, 1))
		var cosine: float = cos(_uv_angle) * _uv_zoom
		var sine: float = sin(_uv_angle) * _uv_zoom

		var v_base: float = 0.5 - 0.5 * (sine * columns + cosine * rows) + _uv_offset.y
		if int(_prop("uv_mode", 0xc4, 0)) == 1:
			# Preserve the distinct source branch, including its dependent V base.
			var base_u: float = rectangle.position.x + v_base * rectangle.size.x
			var du_x: float = sine * columns * rectangle.size.x
			var du_y: float = cosine * rows * rectangle.size.x
			return Vector2(
				base_u + uv.x * du_x + uv.y * du_y,
				rectangle.position.y + base_u * rectangle.size.y
				+ (uv.x * du_x + uv.y * du_y) * rectangle.size.y
			)

		var u_base: float = 0.5 - 0.5 * (cosine * columns - sine * rows) + _uv_offset.x
		return rectangle.position + Vector2(
			u_base + uv.x * cosine * columns - uv.y * sine * rows,
			v_base + uv.x * sine * columns + uv.y * cosine * rows
		) * rectangle.size

	func _geometry_parameters(u_bounds: Vector2, v_bounds: Vector2) -> Dictionary:
		var endpoints: Variant = properties.get("edge_alpha", [])
		var alpha: Vector4 = Vector4.ONE
		if endpoints is Array and endpoints.size() >= 4:
			alpha = Vector4(
				float(endpoints[0]), float(endpoints[1]),
				float(endpoints[2]), float(endpoints[3])
			) / 255.0
		else:
			alpha = Vector4(
				float(_raw(0x110, 255)), float(_raw(0x111, 255)),
				float(_raw(0x112, 255)), float(_raw(0x113, 255))
			) / 255.0

		var powers: Dictionary = _context.get("u1_alpha_powers", {})
		var u_index: int = int(_prop("alpha_index_u", 0xc5, 0))
		var v_index: int = int(_prop("alpha_index_v", 0xc6, 0))
		# # ASSUMPTION: SAlphaPower and shader 7 are absent. Use a monotone
		# endpoint ramp with exponent 1 unless a recovered exponent is supplied.
		return {
			"clip": Vector4(u_bounds.x, u_bounds.y, v_bounds.x, v_bounds.y),
			"alpha": alpha,
			"power": Vector2(
				maxf(EffectUnitsTrail.EPS, float(powers.get(u_index, 1.0))),
				maxf(EffectUnitsTrail.EPS, float(powers.get(v_index, 1.0)))
			),
		}

	func _draw_geometry() -> void:
		var u_bounds: Vector2 = _geometry_bounds("u_range", 0x100, 6)
		var v_bounds: Vector2 = _geometry_bounds("v_range", 0x108, 7)
		var batch: Batch = Batch.new()
		if u_bounds.y - u_bounds.x <= EffectUnitsTrail.EPS \
				or v_bounds.y - v_bounds.x <= EffectUnitsTrail.EPS:
			_draw_batch(batch)
			return

		var style: Dictionary = _unit_style(_percent)
		var mesh_data: Variant = properties.get("mesh", {})
		var sampler: Callable = _context.get("u1_geometry", Callable())
		if sampler.is_valid():
			mesh_data = sampler.call(unit, index, _percent, _context)

		if mesh_data is Dictionary and not mesh_data.get("vertices", []).is_empty():
			_append_geometry_mesh(batch, mesh_data, style, u_bounds, v_bounds)
		else:
			_append_geometry_primitive(batch, style, u_bounds, v_bounds)
		_draw_batch(batch, _geometry_parameters(u_bounds, v_bounds))

	func _append_geometry_mesh(
		batch: Batch,
		data: Dictionary,
		style: Dictionary,
		u_bounds: Vector2,
		v_bounds: Vector2
	) -> void:
		# `vertices` are already-deformed local engine coordinates.
		var vertices: Variant = data.get("vertices", [])
		var uvs: Variant = data.get("uvs", [])
		for i in range(vertices.size()):
			var value: Variant = vertices[i]
			var domain: Vector2 = Vector2.ZERO
			if i < uvs.size():
				domain = EffectUnitsTrail._v2(uvs[i])
			elif value is Array and value.size() >= 5:
				domain = Vector2(float(value[3]), float(value[4]))
			var uv: Vector2 = domain if bool(data.get("uv_final", false)) \
				else _geometry_uv(domain, u_bounds, v_bounds)
			batch.vertex(_xf * EffectUnitsTrail._v3(value), uv, style, domain)

		var supplied_indices: Variant = data.get("indices", [])
		if supplied_indices.is_empty():
			for i in range(vertices.size()):
				batch.indices.append(i)
		else:
			for value in supplied_indices:
				var vertex_index: int = int(value)
				if vertex_index < 0 or vertex_index >= vertices.size():
					_warn("indices", "Geometry contains an out-of-range vertex index.")
					batch.indices.clear()
					return
				batch.indices.append(vertex_index)
		if batch.indices.size() % 3 != 0:
			_warn("triangles", "Geometry indices must describe complete triangles.")
			batch.indices.clear()

	func _append_geometry_primitive(
		batch: Batch,
		style: Dictionary,
		u_bounds: Vector2,
		v_bounds: Vector2
	) -> void:
		# # ASSUMPTION: CheckGeometryBuffer and shader 7 were not supplied.
		# Fallback shape names are explicit strings: plane/cylinder/ring.
		# Channel 3 (+f4/+f8) is outer radius or plane half-width;
		# channel 4 (+e4/+e8) is height or plane half-depth;
		# channel 5 (+ec/+f0) is top radius or ring inner radius.
		# Supplying `mesh` or u1_geometry bypasses these shape assumptions.
		var shape: String = str(properties.get("shape", "plane")).to_lower()
		if shape not in ["plane", "cylinder", "ring"]:
			_warn("shape", "Unknown geometry shape; supply a named shape or decoded mesh.")
			return
		var a: float = _range_value("radius", 0xf4, 3, _percent, 1.0, 1.0)
		var b: float = _range_value("height", 0xe4, 4, _percent, 1.0, 1.0)
		var c: float = _range_value("inner_radius", 0xec, 5, _percent, 1.0, 1.0)
		var columns: int = maxi(1, int(properties.get("segments", 64 if shape != "plane" else 1)))
		var rows: int = maxi(1, int(properties.get("rows", 1)))

		for row in range(rows + 1):
			var v: float = lerpf(v_bounds.x, v_bounds.y, float(row) / float(rows))
			for column in range(columns + 1):
				var u: float = lerpf(u_bounds.x, u_bounds.y, float(column) / float(columns))
				var point: Vector3
				match shape:
					"cylinder":
						var radius: float = lerpf(a, c, v)
						point = Vector3(cos(TAU * u) * radius, (v - 0.5) * b, sin(TAU * u) * radius)
					"ring":
						var radius: float = lerpf(c, a, v)
						point = Vector3(cos(TAU * u) * radius, 0, sin(TAU * u) * radius)
					_:
						point = Vector3((2.0 * u - 1.0) * a, 0, (2.0 * v - 1.0) * b)
				var domain: Vector2 = Vector2(u, v)
				batch.vertex(_xf * point, _geometry_uv(domain, u_bounds, v_bounds), style, domain)

		for row in range(rows):
			for column in range(columns):
				var first: int = row * (columns + 1) + column
				var next_row: int = first + columns + 1
				batch.indices.append_array(PackedInt32Array([
					first, first + 1, next_row + 1,
					first, next_row + 1, next_row
				]))

	# ------------------------------------------------------------------
	# CEffectAttachMesh
	# ------------------------------------------------------------------

	func _model_path() -> String:
		var value: String = str(properties.get("model", unit.get("model", "")))
		if value.begins_with("res://") and value.ends_with(".glb"):
			return value
		var stem: String = EffectUnitsTrail.Eval.canonical(value).get_file()
		stem = stem.trim_suffix(".ams").trim_suffix(".glb")
		return "" if stem.is_empty() else "res://assets/models/%s.glb" % stem

	func _ensure_model() -> void:
		if _model_attempted:
			return
		_model_attempted = true
		var path: String = _model_path()
		if path.is_empty() or not ResourceLoader.exists(path):
			_warn("model", "Missing attached model: %s" % path)
			return
		var packed: PackedScene = ResourceLoader.load(path) as PackedScene
		if packed == null:
			_warn("model_scene", "Attached GLB did not load as a PackedScene.")
			return
		var instance: Node = packed.instantiate()
		if not instance is Node3D:
			instance.free()
			_warn("model_root", "Attached model root must be Node3D.")
			return

		_model_root = Node3D.new()
		_model_root.name = "U1Model_%d" % index
		_model_root.add_child(instance)

		if _is_canvas():
			# # ASSUMPTION: UI attached meshes use an orthographic offscreen
			# projection. Framebuffer-dependent blend passes are not recoverable.
			_model_viewport = SubViewport.new()
			_model_viewport.name = "U1ModelViewport_%d" % index
			_model_viewport.transparent_bg = true
			_model_viewport.own_world_3d = true
			_model_viewport.size = Vector2i(64, 64)
			_model_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			host.add_child(_model_viewport)
			_model_viewport.add_child(_model_root)
			_model_camera = Camera3D.new()
			_model_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			_model_viewport.add_child(_model_camera)
			_model_camera.current = true
			_model_canvas = CanvasModel.new()
			_model_canvas.name = "U1ModelCanvas_%d" % index
			_model_canvas.z_index = clampi(index, -4096, 4095)
			host.add_child(_model_canvas)
		else:
			host.add_child(_model_root)

		# Preserve imported meshes, Skin resources, bone indices and hierarchy.
		for value in _model_root.find_children("*", "MeshInstance3D", true, false):
			var mesh_node: MeshInstance3D = value as MeshInstance3D
			if mesh_node.mesh == null:
				continue
			mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var records: Array = []
			for surface in range(mesh_node.mesh.get_surface_count()):
				records.append({
					"node": mesh_node,
					"surface": surface,
					"original": mesh_node.get_active_material(surface),
					"material": ShaderMaterial.new(),
				})
			mesh_node.material_override = null
			_model_surfaces.append_array(records)

		for value in _model_root.find_children("*", "AnimationPlayer", true, false):
			var player: AnimationPlayer = value as AnimationPlayer
			player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
			var animation_name: String = str(properties.get("animation", ""))
			if animation_name.is_empty():
				# # ASSUMPTION: Without a serialized selection, use the first
				# imported animation other than RESET.
				for candidate in player.get_animation_list():
					if candidate != &"RESET":
						animation_name = str(candidate)
						break
			if not animation_name.is_empty() and player.has_animation(animation_name):
				player.play(animation_name)
				_animation_players.append({"player": player, "animation": animation_name})

	func _model_scale() -> Vector3:
		# # ASSUMPTION: AttachMesh scale/rotation track assignments are absent.
		# Static `scale`, `rotation_degrees`, and explicitly supplied
		# `scale_ranges`/`scale_channels` control the fallback.
		var value: Variant = properties.get("scale", [1, 1, 1])
		var result: Vector3 = Vector3.ONE * float(value) \
			if value is float or value is int else EffectUnitsTrail._v3(value, Vector3.ONE)
		var ranges: Variant = properties.get("scale_ranges", [])
		var channels: Variant = properties.get("scale_channels", [3, 4, 5])
		if ranges is Array and channels is Array:
			for axis in range(mini(3, mini(ranges.size(), channels.size()))):
				var limits: Vector2 = EffectUnitsTrail._v2(ranges[axis], Vector2.ONE)
				result[axis] *= lerpf(
					limits.x, limits.y,
					EffectUnitsTrail.Eval.byte_track(unit, int(channels[axis]), _percent)
				)
		return result * EffectUnitsTrail.MODEL_ENGINE_SCALE

	func _update_model(at_ms: float) -> void:
		if not _active(at_ms):
			if is_instance_valid(_model_root):
				_model_root.hide()
			if is_instance_valid(_model_canvas):
				_model_canvas.hide()
			if is_instance_valid(_model_viewport):
				_model_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
			return
		_ensure_model()
		if _model_root == null:
			return

		var rotation_degrees: Vector3 = EffectUnitsTrail._v3(
			properties.get("rotation_degrees", [0, 0, 0])
		)
		var local_basis: Basis = Basis.from_euler(rotation_degrees * (PI / 180.0))
		local_basis = local_basis.scaled(_model_scale())
		var matrix: Transform3D = _xf * Transform3D(local_basis, Vector3.ZERO)

		if _is_canvas():
			_model_root.transform = matrix
		else:
			if absf(host.global_transform.basis.determinant()) <= 0.000000001:
				_model_root.hide()
				return
			_model_root.transform = host.global_transform.affine_inverse() * matrix
		_model_root.show()

		var elapsed_seconds: float = maxf(
			0.0, at_ms - float(unit.get("start_ms", 0))
		) * 0.001
		elapsed_seconds = (
			elapsed_seconds * float(properties.get("animation_speed", 1.0))
			+ float(properties.get("animation_offset_seconds", 0.0))
		)
		for record in _animation_players:
			var player: AnimationPlayer = record["player"]
			var animation: Animation = player.get_animation(record["animation"])
			var sample_time: float = elapsed_seconds
			# # ASSUMPTION: Animation looping is explicit; animation timing is
			# seconds, independent of the EFT's 33 ms track-percent denominator.
			if bool(properties.get("animation_loop", false)) and animation.length > 0.0:
				sample_time = fposmod(sample_time, animation.length)
			else:
				sample_time = clampf(sample_time, 0.0, animation.length)
			player.seek(sample_time, true)

		# # ASSUMPTION: AttachMesh's effect material modulates the imported
		# albedo with channels 0/1 and uses channels 0..2 for color transforms.
		# Missing AttachMesh tracks are neutral. A recovered material callback
		# overrides this fallback without modifying the imported skeleton.
		var style: Dictionary = _unit_style(_percent, true)
		var rectangle: Rect2 = EffectUnitsTrail.Eval.texture_rect(unit, _percent)
		var resolver: Callable = _context.get("u1_mesh_material", Callable())
		for record in _model_surfaces:
			var mesh_node: MeshInstance3D = record["node"]
			var surface: int = int(record["surface"])
			var recovered: Variant = null
			if resolver.is_valid():
				recovered = resolver.call(
					unit, mesh_node, surface, record["original"], style, _context
				)
			if recovered is Material:
				mesh_node.set_surface_override_material(surface, recovered)
				continue

			var material: ShaderMaterial = record["material"]
			var mode: String = EffectUnitsTrail._blend_name(_blend(), _overrides)
			material.shader = EffectUnitsTrail._shader(
				true, "mix" if _is_canvas() else mode, _depth(), true
			)
			material.render_priority = clampi(index, -128, 127)
			var texture: Texture2D = _texture
			var base_color: Color = Color.WHITE
			var original: Variant = record["original"]
			if original is BaseMaterial3D:
				base_color = original.albedo_color
				if texture == null:
					texture = original.albedo_texture
			elif original is ShaderMaterial:
				_warn("imported_shader", "Use u1_mesh_material to preserve an imported custom shader.")
			material.set_shader_parameter(
				"image_texture", EffectUnitsTrail._white() if texture == null else texture
			)
			material.set_shader_parameter("effect_tint", Color(style["tint"]) * base_color)
			material.set_shader_parameter("effect_add", style["add"])
			material.set_shader_parameter("effect_mix", style["mix"])
			material.set_shader_parameter("geometry_enabled", false)
			material.set_shader_parameter("atlas_rect", Vector4(
				rectangle.position.x, rectangle.position.y,
				rectangle.size.x, rectangle.size.y
			))
			mesh_node.set_surface_override_material(surface, material)

		if _is_canvas():
			_update_model_canvas()

	func _update_model_canvas() -> void:
		if absf(host.global_transform.determinant()) <= 0.000000001:
			_model_canvas.hide()
			return
		var bounds: AABB = AABB()
		var have_bounds: bool = false
		var explicit_bounds: Variant = properties.get("bounds", [])
		if explicit_bounds is Array and explicit_bounds.size() >= 6:
			bounds = _model_root.global_transform * AABB(
				Vector3(float(explicit_bounds[0]), float(explicit_bounds[1]), float(explicit_bounds[2])),
				Vector3(float(explicit_bounds[3]), float(explicit_bounds[4]), float(explicit_bounds[5]))
			)
			have_bounds = true
		else:
			for record in _model_surfaces:
				var mesh_node: MeshInstance3D = record["node"]
				var mesh_bounds: AABB = mesh_node.global_transform * mesh_node.get_aabb()
				bounds = bounds.merge(mesh_bounds) if have_bounds else mesh_bounds
				have_bounds = true
		if not have_bounds:
			_model_canvas.hide()
			return

		# # ASSUMPTION: Imported bind bounds plus padding cover animated poses.
		# Supply local GLB `bounds: [x,y,z,width,height,depth]` for authoritative
		# animation bounds; no CPU reskinning or bone-index rewriting occurs.
		var padding: float = float(properties.get(
			"bounds_padding",
			maxf(1.0, maxf(bounds.size.x, bounds.size.y) * 0.25)
		))
		bounds = bounds.grow(maxf(0.0, padding))
		var width: float = maxf(bounds.size.x, 1.0)
		var height: float = maxf(bounds.size.y, 1.0)
		var pixel_scale: float = minf(1.0, 2048.0 / maxf(width, height))
		var viewport_size: Vector2i = Vector2i(
			maxi(1, int(ceil(width * pixel_scale))),
			maxi(1, int(ceil(height * pixel_scale)))
		)
		# Match the camera aspect to the rounded viewport dimensions.
		width = height * float(viewport_size.x) / float(viewport_size.y)
		var center: Vector3 = bounds.get_center()
		var left: float = center.x - width * 0.5
		var top: float = center.y - height * 0.5
		_model_viewport.size = viewport_size
		_model_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_model_camera.keep_aspect = Camera3D.KEEP_HEIGHT
		_model_camera.size = height
		_model_camera.near = 0.01
		_model_camera.far = maxf(2.0, bounds.size.z + padding + 2.0)
		_model_camera.position = Vector3(center.x, center.y, bounds.end.z + 1.0)
		_model_camera.rotation = Vector3.ZERO

		var inverse: Transform2D = host.global_transform.affine_inverse()
		_model_canvas.points = PackedVector2Array([
			inverse * Vector2(left, top),
			inverse * Vector2(left + width, top),
			inverse * Vector2(left + width, top + height),
			inverse * Vector2(left, top + height)
		])
		_model_canvas.drawing_texture = _model_viewport.get_texture()
		var material: CanvasItemMaterial = _model_canvas.material as CanvasItemMaterial
		if material == null:
			material = CanvasItemMaterial.new()
			material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		match EffectUnitsTrail._blend_name(_blend(), _overrides):
			"add":
				material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			"sub":
				material.blend_mode = CanvasItemMaterial.BLEND_MODE_SUB
			"mul":
				material.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
			"premul":
				material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
			_:
				material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
		_model_canvas.material = material
		_model_canvas.show()
		_model_canvas.queue_redraw()
