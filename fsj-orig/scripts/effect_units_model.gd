class_name EffectUnitsModel
extends Node
## Additional Gamma EFT units. Does not dispatch numeric kind IDs.
##
## Public interface:
##     EffectUnitsModel.prepare(owner, evaluator, context)
##     var packets = evaluator.advance(delta, context)
##     EffectUnitsModel.update(owner)
##
## See PATCH_U2.md for the evaluator hooks and property contract.
##
## ASSUMPTION: The supplied JSON schema does not document these units'
## property names. Named properties and decoded native offsets are supported.
## ASSUMPTION: Missing source shaders are approximated by the shaders below.
## ASSUMPTION: CAniControler figures are exported as named animation clips.
## The unnamed call at 0x2b75fc is treated as setting figure weight.
##
## Not runtime-tested; no filesystem or command access was used.

const E = preload("res://scripts/effect_eval.gd")
const META: StringName = &"_effect_units_model"

const TYPES: Array[String] = [
	"CModelConsoleProp",
	"CModelMaterialProp",
	"CModelAnimationProp",
	"CCameraShakeProp",
	"CCameraFilterProp",
	"CDynamicLightProp",
	"C3DAudioProp",
]

const SECTIONS: Dictionary = {
	"CModelConsoleProp": "model",
	"CModelMaterialProp": "material",
	"CModelAnimationProp": "animation",
	"CCameraShakeProp": "shake",
	"CCameraFilterProp": "filter",
	"CDynamicLightProp": "light",
	"C3DAudioProp": "audio",
}

static var _scenes: Dictionary = {}
static var _shaders: Dictionary = {}
static var _camera_mixers: Dictionary = {}

var simulation: EffectEval
var context: Dictionary = {}
var host: Node
var actors: Dictionary = {}
var rigs: Dictionary = {}

var _ui_viewport: SubViewport
var _ui_camera: Camera3D
var _ui_layer: CanvasLayer
var _ui_image: TextureRect
var _warnings: Dictionary = {}
var _hook_indices: Array[int] = []


static func unit_type(unit: Dictionary) -> String:
	for key in ["type", "type_name", "unit_type", "class", "class_name", "kind"]:
		var value: Variant = unit.get(key)
		if value is String or value is StringName:
			var result: String = str(value).get_slice("::", str(value).count("::"))
			if result in TYPES:
				return result
	return ""


static func handles(unit: Dictionary) -> bool:
	return not unit_type(unit).is_empty()


static func property(
	unit: Dictionary,
	key: String,
	fallback: Variant = null,
	offset: int = -1
) -> Variant:
	var special: Variant = unit.get("u2", {})
	if special is Dictionary and special.has(key):
		return special[key]
	var section: String = str(SECTIONS.get(unit_type(unit), ""))
	var fields: Variant = unit.get(section, {})
	if fields is Dictionary and fields.has(key):
		return fields[key]
	if unit.has(key):
		return unit[key]
	if offset >= 0:
		var offsets: Variant = unit.get("offsets", {})
		if offsets is Dictionary:
			for candidate in [offset, str(offset), "0x%x" % offset]:
				if offsets.has(candidate):
					return offsets[candidate]
	return fallback


static func prepare(
	owner: Node,
	evaluator: EffectEval,
	frame_context: Dictionary
) -> void:
	var driver: EffectUnitsModel = (owner.get_meta(META) if owner.has_meta(META) else null) as EffectUnitsModel
	if driver == null:
		driver = EffectUnitsModel.new()
		driver.name = "EffectUnitsModel"
		driver.host = owner
		driver.simulation = evaluator
		driver.context = frame_context
		owner.set_meta(META, driver)
		owner.add_child(driver)
		driver._build()
	driver.context = frame_context
	driver._prepare_canvas()


static func update(owner: Node) -> void:
	var driver: EffectUnitsModel = (owner.get_meta(META) if owner.has_meta(META) else null) as EffectUnitsModel
	if is_instance_valid(driver):
		driver._update_units()


static func active(unit: Dictionary, at_ms: float) -> bool:
	return (
		at_ms > float(unit.get("start_ms", 0.0))
		and at_ms <= E.unit_end(unit)
	)


static func model_path(value: String) -> String:
	if value.is_empty():
		return ""
	var stem: String = value.replace("\\", "/").get_file().get_basename()
	return "res://assets/models/%s.glb" % stem


static func effect_texture(value: String) -> Texture2D:
	if value.is_empty():
		return null
	if value.begins_with("res://"):
		return E.texture_at(value)
	var stem: String = value.replace("\\", "/").get_file().get_basename()
	return E.texture_at("res://assets/fx/tex/%s.png" % stem)


static func packed(color: Color) -> int:
	return (
		(clampi(int(color.a * 255.0), 0, 255) << 24)
		| (clampi(int(color.r * 255.0), 0, 255) << 16)
		| (clampi(int(color.g * 255.0), 0, 255) << 8)
		| clampi(int(color.b * 255.0), 0, 255)
	)


static func multiply_packed(first: int, second: int) -> int:
	var result: int = 0
	for shift in [0, 8, 16, 24]:
		var product: int = ((first >> shift) & 255) * ((second >> shift) & 255)
		var component: int = int(E.f32(float(product) / 255.0))
		result |= (component & 255) << shift
	return result


static func blend_name(preset: int, frame_context: Dictionary) -> String:
	var overrides: Dictionary = frame_context.get("u2_blend_overrides", {})
	var override_name: String = str(overrides.get(preset, ""))
	if override_name in ["mix", "add", "sub", "mul", "premul"]:
		return override_name
	# ASSUMPTION: Same unrecovered preset mapping as EffectRender.
	match preset:
		2, 8:
			return "add"
		3:
			return "mul"
		_:
			return "mix"


static func gain_at_distance(distance: float, near_value: float, far_value: float) -> float:
	if distance < near_value:
		return 1.0
	if distance >= far_value or far_value <= near_value:
		return 0.0
	return (far_value - distance) / (far_value - near_value)


func warn_once(key: String, message: String) -> void:
	if not _warnings.has(key):
		_warnings[key] = true
		push_warning("EffectUnitsModel: " + message)


func _build() -> void:
	_prepare_canvas()
	for index in range(simulation.units.size()):
		var definition: Dictionary = simulation.units[index]
		if not handles(definition):
			continue
		var actor: RuntimeUnit = RuntimeUnit.new()
		actor.manager = self
		actor.definition = definition
		actor.index = index
		actor.type_name = unit_type(definition)
		actor.name = "%s_%d" % [actor.type_name, index]
		actors[index] = actor
		if _ui_viewport != null:
			_ui_viewport.add_child(actor)
		else:
			add_child(actor)
		actor.top_level = true
		actor.initialize()

	for index in range(simulation.units.size()):
		var definition: Dictionary = simulation.units[index]
		var state: Dictionary = simulation.states[index]
		if unit_type(definition) == "CModelConsoleProp":
			state["u2_frame_hook"] = Callable(self, "_model_frame").bind(index)
			_hook_indices.append(index)
		if bool(definition.get("needs_bone", false)):
			# Includes sprite/particle children of a model owned by this module.
			state["u2_binding_hook"] = Callable(self, "_bone_frame").bind(index)
			if not index in _hook_indices:
				_hook_indices.append(index)


func _prepare_canvas() -> void:
	if not bool(context.get("canvas", false)):
		return
	if _ui_viewport == null:
		# ASSUMPTION: UI models use orthographic XY projection, with positive
		# Y downward, matching EffectPlayer's existing canvas convention.
		_ui_viewport = SubViewport.new()
		_ui_viewport.name = "ModelViewport"
		_ui_viewport.own_world_3d = true
		_ui_viewport.transparent_bg = true
		_ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_ui_viewport.gui_disable_input = true
		add_child(_ui_viewport)

		_ui_camera = Camera3D.new()
		_ui_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_ui_camera.keep_aspect = Camera3D.KEEP_HEIGHT
		_ui_camera.near = 0.01
		_ui_camera.far = 200000.0
		_ui_viewport.add_child(_ui_camera)
		_ui_camera.current = true

		var environment_node: WorldEnvironment = WorldEnvironment.new()
		var environment: Environment = Environment.new()
		# ASSUMPTION: Neutral ambient illumination for isolated UI models.
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color.WHITE
		environment.ambient_light_energy = 1.0
		environment_node.environment = environment
		_ui_viewport.add_child(environment_node)

		_ui_layer = CanvasLayer.new()
		_ui_layer.custom_viewport = host.get_viewport()
		_ui_layer.layer = int(context.get("u2_model_layer", 0))
		add_child(_ui_layer)
		_ui_image = TextureRect.new()
		_ui_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_ui_image.texture = _ui_viewport.get_texture()
		_ui_layer.add_child(_ui_image)

	var size: Vector2 = host.get_viewport().get_visible_rect().size
	var dimensions: Vector2i = Vector2i(maxi(1, int(size.x)), maxi(1, int(size.y)))
	_ui_viewport.size = dimensions
	_ui_image.position = Vector2.ZERO
	_ui_image.size = Vector2(dimensions)
	_ui_camera.size = float(dimensions.y)
	_ui_camera.transform = Transform3D(
		Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD),
		Vector3(float(dimensions.x) * 0.5, float(dimensions.y) * 0.5, -10000.0)
	)


func _update_units() -> void:
	for value in actors.values():
		var actor: RuntimeUnit = value
		actor.update(simulation.time_ms)
	# Resolve external targets before applying their pose/material listeners.
	for value in actors.values():
		var actor: RuntimeUnit = value
		if actor.type_name in ["CModelAnimationProp", "CModelMaterialProp"]:
			_rig_for(actor.index)
	for value in rigs.values():
		var rig: ModelRig = value
		if is_instance_valid(rig.root):
			rig.apply_pose()
			rig.apply_materials()


func _model_frame(
	matrix: Transform3D,
	percent: float,
	frame_context: Dictionary,
	index: int
) -> Transform3D:
	context = frame_context
	var actor: RuntimeUnit = actors.get(index) as RuntimeUnit
	if actor == null:
		return matrix
	return actor.model_frame(matrix, percent)


func _rig_for(index: int) -> ModelRig:
	var visited: Dictionary = {}
	var current: int = int(simulation.units[index].get("parent", -1))
	while current >= 0 and current < simulation.units.size() and not visited.has(current):
		visited[current] = true
		var actor: RuntimeUnit = actors.get(current) as RuntimeUnit
		if actor != null and actor.type_name == "CModelConsoleProp":
			actor.ensure_model()
			return actor.rig
		current = int(simulation.units[current].get("parent", -1))

	var attached: Node3D = context.get("attached_model", null) as Node3D
	if not is_instance_valid(attached):
		return null
	var key: int = attached.get_instance_id()
	if not rigs.has(key):
		rigs[key] = ModelRig.new(self, attached, null)
	return rigs[key]


func _bone_frame(
	fallback: Transform3D,
	frame_context: Dictionary,
	index: int
) -> Transform3D:
	context = frame_context
	var state: Dictionary = simulation.states[index]
	state["u2_bone_resolved"] = false
	var rig: ModelRig = _rig_for(index)
	if rig == null:
		return fallback
	rig.apply_pose()
	var unit: Dictionary = simulation.units[index]
	var selector: Variant = unit.get("bone_name", unit.get("bone", null))
	var found: Variant = rig.bone_transform(selector)
	if found is Transform3D:
		state["u2_bone_resolved"] = true
		return found
	warn_once(
		"bone:%d" % index,
		"unit %d has no resolved model bone: %s" % [index, str(selector)]
	)
	return fallback


func target_is(rig: ModelRig, actor: RuntimeUnit) -> bool:
	return _rig_for(actor.index) == rig


func camera() -> Node:
	var explicit: Node = context.get("camera_node", null) as Node
	if is_instance_valid(explicit):
		return explicit
	var viewport: Viewport = host.get_viewport()
	if bool(context.get("canvas", false)):
		return viewport.get_camera_2d()
	return viewport.get_camera_3d()


func _exit_tree() -> void:
	for value in actors.values():
		var actor: RuntimeUnit = value
		actor.cleanup()
	for value in rigs.values():
		var rig: ModelRig = value
		rig.dispose()
	if simulation != null:
		for index in _hook_indices:
			var state: Dictionary = simulation.states[index]
			state.erase("u2_frame_hook")
			state.erase("u2_binding_hook")
			state.erase("u2_bone_resolved")
	if is_instance_valid(host) and (host.get_meta(META) if host.has_meta(META) else null) == self:
		host.remove_meta(META)


class RuntimeUnit extends Node3D:
	var manager: EffectUnitsModel
	var definition: Dictionary = {}
	var index: int = -1
	var type_name: String = ""
	var rig: ModelRig

	var _model: Node3D
	var _model_key: String = ""
	var _angle: float = 0.0
	var _last_wall: float = -1.0
	var _model_started: bool = false
	var _animation_started: bool = false
	var _animation_weight: float = 1.0

	var _filter_layer: CanvasLayer
	var _filter_copy: BackBufferCopy
	var _filter_rect: ColorRect
	var _filter_material: ShaderMaterial
	var _light: OmniLight3D

	var _audio: AudioStreamPlayer3D
	var _audio_started: bool = false
	var _audio_finished: bool = false
	var _audio_selected: bool = true
	var _audio_revision: Variant
	var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

	var _shake_live: bool = false
	var _shake_override: bool = true
	var _mixer: CameraMixer

	func p(key: String, fallback: Variant = null, offset: int = -1) -> Variant:
		return EffectUnitsModel.property(definition, key, fallback, offset)

	func pair(
		key: String, fallback: Array, first_offset: int, second_offset: int
	) -> Vector2:
		var value: Variant = p(key)
		if value is Array and value.size() >= 2:
			return Vector2(float(value[0]), float(value[1]))
		return Vector2(
			float(p("", fallback[0], first_offset)),
			float(p("", fallback[1], second_offset))
		)

	func vector(key: String, fallback: Vector3, offset: int = -1) -> Vector3:
		var value: Variant = p(key)
		if value is Array and value.size() >= 3:
			return E.vec3(value)
		if value is Vector3:
			return value
		if offset >= 0:
			return Vector3(
				float(p("", fallback.x, offset)),
				float(p("", fallback.y, offset + 4)),
				float(p("", fallback.z, offset + 8))
			)
		return fallback

	func initialize() -> void:
		var seed_value: int = int(p("random_seed", 0))
		if seed_value == 0:
			_rng.randomize()
		else:
			_rng.seed = seed_value
		if type_name == "CModelConsoleProp":
			ensure_model()

	func is_active(at_ms: float) -> bool:
		if not EffectUnitsModel.active(definition, at_ms):
			return false
		if bool(definition.get("needs_bone", false)):
			return bool(manager.simulation.states[index].get("u2_bone_resolved", false))
		return true

	func update(at_ms: float) -> void:
		var state: Dictionary = manager.simulation.states[index]
		if type_name != "CModelConsoleProp":
			global_transform = state["xf"]
		var enabled: bool = is_active(at_ms)
		match type_name:
			"CModelConsoleProp":
				visible = enabled and not bool(p("render_disabled", false))
			"CModelMaterialProp", "CModelAnimationProp":
				if enabled and manager._rig_for(index) == null:
					manager.warn_once(
						"target:%d" % index,
						"%s unit %d has no attached model." % [type_name, index]
					)
			"CCameraShakeProp":
				_update_shake(enabled)
			"CCameraFilterProp":
				_update_filter(enabled)
			"CDynamicLightProp":
				_update_light(enabled)
			"C3DAudioProp":
				_update_audio(enabled, at_ms)

	func ensure_model() -> void:
		var path: String = EffectUnitsModel.model_path(str(p("path", "")))
		var key: String = "%s:%s" % [path, str(p("revision", 0, 0x124))]
		if key == _model_key:
			return
		_model_key = key
		if rig != null:
			manager.rigs.erase(rig.root.get_instance_id())
			rig.dispose()
			rig = null
		if is_instance_valid(_model):
			remove_child(_model)
			_model.queue_free()
			_model = null
		if path.is_empty():
			# an empty CModelConsoleProp path drives the host's own mesh (item/character), no extra model (Claude)
			return
		if not EffectUnitsModel._scenes.has(path):
			var scene: PackedScene
			if ResourceLoader.exists(path):
				scene = ResourceLoader.load(path) as PackedScene
			EffectUnitsModel._scenes[path] = scene
		var scene: PackedScene = EffectUnitsModel._scenes[path] as PackedScene
		if scene == null:
			manager.warn_once(path, "missing model: " + path)
			return
		var instance: Node = scene.instantiate()
		_model = instance as Node3D
		if _model == null:
			instance.free()
			manager.warn_once(path, "GLB root is not Node3D: " + path)
			return
		add_child(_model)
		# One imported glTF unit is 64 original engine units. The evaluator
		# already applies units_per_engine, so this conversion occurs once.
		_model.transform = Transform3D(
			Basis.IDENTITY.scaled(Vector3.ONE * 64.0), Vector3.ZERO
		) * _model.transform
		rig = ModelRig.new(manager, _model, self)
		manager.rigs[_model.get_instance_id()] = rig
		visible = false

	func model_frame(matrix: Transform3D, percent: float) -> Transform3D:
		ensure_model()
		var now: float = manager.simulation.time_ms
		if now > E.unit_end(definition):
			visible = false
			_model_started = false
			_last_wall = -1.0
			# CModelConsole::Update resets its matrix after ending.
			return Transform3D.IDENTITY
		if not is_active(now):
			visible = false
			_model_started = false
			_last_wall = -1.0
			return matrix

		var frame_sync: bool = bool(p("frame_sync", false, 0xe6))
		if not _model_started:
			_model_started = true
			if frame_sync:
				_angle = float(p("rotation", 0.0, 0xc0))
			_last_wall = manager.simulation.wall_ms - maxf(
				0.0, now - float(definition.get("start_ms", 0.0))
			)

		var angular: Vector3 = vector("angular_velocity", Vector3.ZERO, 0xb4)
		# CModelConsoleProp::MakeResValid (0x2e102e): +0xcc = |angular_velocity| (Claude)
		var speed: float = angular.length()
		var delta_ms: float = maxf(0.0, manager.simulation.wall_ms - _last_wall)
		_last_wall = manager.simulation.wall_ms
		if speed > 0.00001:
			_angle += (
				delta_ms * float(manager.context.get("frame_scale", 1.0))
				* speed * 0.001
			)
			# Recovered literal is 6.283, and the source resets overshoot.
			if _angle > 6.283:
				_angle = 0.0
			if _angle < 0.0:
				_angle = 6.283

		var size_curve: float = 1.0
		if not E.track_at(definition, "bytes", 0).is_empty():
			size_curve = E.byte_track(definition, 0, percent)
		var limits: Vector2 = pair("scale", [1.0, 1.0], 0xc8, 0xc4)
		var size_value: float = lerpf(limits.x, limits.y, size_curve)
		size_value = maxf(size_value, 0.00001)
		if not is_zero_approx(_angle) and not is_zero_approx(speed):
			matrix.basis = matrix.basis * Basis(
				E.safe_normal(angular, Vector3.BACK), -_angle
			)
		matrix.basis = matrix.basis.scaled(Vector3.ONE * size_value)
		global_transform = matrix
		visible = not bool(p("render_disabled", false))
		if rig != null:
			rig.apply_pose()
		return matrix

	func animation_weight(at_ms: float) -> float:
		if not is_active(at_ms) or bool(p("disabled", false, 0xb1)):
			_animation_started = false
			return 0.0
		if not _animation_started:
			_animation_started = true
			_animation_weight = 1.0  # AddFigure(..., 1.0) at link time.
		var percent: float = E.percent_at(definition, at_ms)
		if percent < 1.0:
			var limits: Vector2 = pair("weight", [0.0, 1.0], 0xb8, 0xbc)
			_animation_weight = lerpf(
				limits.x, limits.y, E.byte_track(definition, 0, percent)
			)
		# OnUpdate deliberately does not change the weight at percent == 1.
		return _animation_weight

	func set_unit_prop_value(property_id: int, value: Variant) -> void:
		if property_id == 100 and type_name == "CCameraShakeProp":
			_shake_override = bool(value)

	func get_unit_prop_value(property_id: int) -> Variant:
		if property_id == 100 and type_name == "CCameraShakeProp":
			return _shake_override
		return null

	func _update_shake(enabled: bool) -> void:
		_shake_live = (
			enabled and _shake_override and bool(p("enabled", true))
			and not bool(manager.context.get("disable_camera_shake", false))
		)
		if _shake_live and _mixer == null:
			var viewport: Viewport = manager.host.get_viewport()
			var key: int = viewport.get_instance_id()
			if not EffectUnitsModel._camera_mixers.has(key):
				EffectUnitsModel._camera_mixers[key] = CameraMixer.new(key)
			_mixer = EffectUnitsModel._camera_mixers[key] as CameraMixer
			_mixer.sources[get_instance_id()] = weakref(self)
		elif not _shake_live and _mixer != null:
			_mixer.remove(get_instance_id())
			_mixer = null

	func shake_offset(camera_position: Vector3) -> Vector3:
		if not _shake_live:
			return Vector3.ZERO
		var conversion: float = maxf(
			0.000001, absf(float(manager.context.get("unit_scale", 1.0)))
		)
		var effect_root: Transform3D = manager.context["root"]
		# The entity measures distance from the EFFECT origin, not GetOffset.
		var distance: float = camera_position.distance_to(effect_root.origin) / conversion
		var distance_gain: float = EffectUnitsModel.gain_at_distance(
			distance, float(p("near", 0.0, 0xbc)),
			float(p("far", 1000000000.0, 0xc0))
		) * float(p("gain", 1.0, 0xb8))
		var percent: float = E.percent_at(definition, manager.simulation.time_ms)
		var amplitude: float = E.byte_track(definition, 0, percent)
		# ASSUMPTION: Use the simulation's continuous clock unless the caller
		# supplies the original application's unsigned millisecond clock.
		var clock_ms: int = int(manager.context.get(
			"gamma_clock_ms", manager.simulation.wall_ms
		)) & 0xffffffff
		var phase: float = E.f32(
			E.f32(float(clock_ms)) * float(p("frequency", 1.0, 0xb4)) / 1000.0
		)
		var mode: int = int(p("mode", 0, 0xc4)) % 4
		var result: Vector3 = Vector3.ZERO
		# ASSUMPTION: sin replaces the omitted GammaSin lookup implementation.
		match mode:
			0:
				result = Vector3(
					sin((phase - int(phase)) * 6.283),
					cos((phase * 1.1 - int(phase * 1.1)) * 6.283),
					cos((phase * 0.9 - int(phase * 0.9)) * 2.683)
				)
			1:
				result.x = sin((phase - int(phase)) * 6.283)
			2:
				result.y = cos((phase - int(phase)) * 6.283)
			3:
				result.z = cos((phase - int(phase)) * 6.283)
		return result * amplitude * distance_gain * conversion

	func _update_filter(enabled: bool) -> void:
		if _filter_layer == null:
			_filter_layer = CanvasLayer.new()
			_filter_layer.custom_viewport = manager.host.get_viewport()
			# ASSUMPTION: Full-screen filters composite above ordinary canvas.
			_filter_layer.layer = int(manager.context.get("u2_filter_layer", 100))
			add_child(_filter_layer)
			_filter_copy = BackBufferCopy.new()
			_filter_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
			_filter_layer.add_child(_filter_copy)
			_filter_rect = ColorRect.new()
			_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_filter_layer.add_child(_filter_rect)
			_filter_material = ShaderMaterial.new()
			_filter_rect.material = _filter_material

		var bounds: Vector3 = vector(
			"bounds", Vector3(INF, INF, INF), 0xc4
		)
		var camera_position: Vector3 = manager.context["camera_position"]
		var difference: Vector3 = (camera_position - global_position).abs()
		var conversion: float = absf(float(manager.context.get("unit_scale", 1.0)))
		enabled = (
			enabled and difference.x <= bounds.x * conversion
			and difference.y <= bounds.y * conversion
			and difference.z <= bounds.z * conversion
			and not bool(p("render_disabled", false))
		)
		var mode: int = int(p("mode", 0, 0xbc))
		enabled = enabled and mode >= 0 and mode <= 2
		var texture: Texture2D = EffectUnitsModel.effect_texture(
			str(definition.get("texture", ""))
		)
		# Mode zero's source renderer requires a texture.
		if mode == 0 and texture == null:
			enabled = false
		_filter_rect.visible = enabled
		_filter_copy.visible = enabled and (
			mode != 0 or int(p("blend", 1, 0xb4)) == 11
		)
		if not enabled:
			return

		var preset: int = int(p("blend", 1, 0xb4))
		var blend: String = EffectUnitsModel.blend_name(preset, manager.context)
		if mode == 1:
			blend = "mix"
		elif mode == 2:
			blend = "disabled" if preset == 0 else "premul"
		_filter_material.shader = EffectUnitsModel.filter_shader(mode, blend, preset == 11)
		var percent: float = E.percent_at(definition, manager.simulation.time_ms)
		var color: Color = E.color_track(definition, 0, percent)
		var rectangle: Rect2 = E.texture_rect(definition, percent)
		var size: Vector2 = manager.host.get_viewport().get_visible_rect().size
		_filter_rect.position = Vector2.ZERO
		_filter_rect.size = size
		_filter_material.set_shader_parameter("diffuse", color)
		_filter_material.set_shader_parameter("image", texture)
		_filter_material.set_shader_parameter("atlas", Vector4(
			rectangle.position.x, rectangle.position.y,
			rectangle.size.x, rectangle.size.y
		))
		_filter_material.set_shader_parameter("viewport_px", size)
		_filter_material.set_shader_parameter(
			"downsample", float(2 << clampi(int(p("downsample", 0, 0xd0)), 0, 10))
		)
		_filter_material.set_shader_parameter("radius", float(p("radius", 1.0, 0xc0)))
		_filter_material.set_shader_parameter(
			"distortion_pixels", float(p("distortion_pixels", 8.0))
		)

	func _update_light(enabled: bool) -> void:
		if _light == null:
			_light = OmniLight3D.new()
			add_child(_light)
			_light.top_level = true
			_light.shadow_enabled = false
		_light.visible = enabled and not bool(p("render_disabled", false))
		if not enabled:
			return
		var percent: float = E.percent_at(definition, manager.simulation.time_ms)
		var color: Color = E.color_track(definition, 0, percent)
		var limits: Vector2 = pair("range", [1.0, 1.0], 0xbc, 0xb8)
		var radius: float = lerpf(
			limits.x, limits.y, E.byte_track(definition, 0, percent)
		)
		# The native updater stores 1 / radius, not radius squared.
		var conversion: float = absf(float(manager.context.get("unit_scale", 1.0)))
		_light.global_transform = Transform3D(Basis.IDENTITY, global_position)
		_light.omni_range = maxf(0.00001, radius * conversion)
		_light.light_color = Color(color.r, color.g, color.b, 1.0)
		# ASSUMPTION: SSceneLight's unchanged +0xb4 parameter is intensity.
		# ASSUMPTION: Packed light alpha multiplies intensity; Godot's native
		# OmniLight falloff approximates the original reciprocal-radius shader.
		_light.light_energy = maxf(0.0, float(p("energy", 1.0, 0xb4)) * color.a)
		_light.omni_attenuation = float(p("attenuation", 1.0))

	func _update_audio(enabled: bool, at_ms: float) -> void:
		if not enabled:
			if _audio_started:
				_stop_audio(
					at_ms > E.unit_end(definition)
					and (int(p("flags", 0, 0xd0)) & 1) != 0
				)
			_audio_started = false
			_audio_finished = false
			return
		if not _audio_started:
			_audio_started = true
			_audio_finished = false
			# ASSUMPTION: Godot's PRNG replaces the omitted original LCG.
			var probability: float = float(p("probability", 1.0, 0xcc))
			_audio_selected = _rng.randf() < probability
			_audio_revision = p("revision", 0, 0xd4)
		var revision: Variant = p("revision", 0, 0xd4)
		if revision != _audio_revision:
			_audio_revision = revision
			_stop_audio(false)
			_audio_finished = false
		if not _audio_selected or _audio_finished:
			return
		if _audio == null:
			_start_audio()
		if _audio == null:
			return

		var percent: float = E.percent_at(definition, at_ms)
		var volume: float = E.byte_track(definition, 0, percent)
		var limits: Vector2 = pair("distance", [0.0, 1000000000.0], 0xc4, 0xc8)
		var conversion: float = maxf(
			0.000001, absf(float(manager.context.get("unit_scale", 1.0)))
		)
		var listener: Vector3 = manager.context["camera_position"]
		# ASSUMPTION: The unidentified SetDistance(min,max) call uses linear
		# attenuation. Native attenuation is disabled to avoid applying it twice.
		volume *= EffectUnitsModel.gain_at_distance(
			listener.distance_to(global_position) / conversion, limits.x, limits.y
		)
		_audio.global_transform = Transform3D(Basis.IDENTITY, global_position)
		_audio.volume_db = linear_to_db(maxf(volume, 0.000001))
		# The bit-1 audio virtual call is unidentified in the disassembly.
		# Preserve it for an AudioHost adapter without inventing its meaning.
		_audio.set_meta("gamma_audio_flag_1", (int(p("flags", 0, 0xd0)) & 2) != 0)

	func _start_audio() -> void:
		var paths: PackedStringArray = str(p("path", "", 0xc0)).replace("\\", "/").split(
			";", true
		)
		if paths.is_empty():
			_audio_finished = true
			return
		var path: String = paths[_rng.randi_range(0, paths.size() - 1)].strip_edges()
		if path.is_empty():
			_audio_finished = true
			return
		if not path.begins_with("res://"):
			path = "res://data/orig/" + path.trim_prefix("/")
		var stream: AudioStream
		if ResourceLoader.exists(path):
			stream = ResourceLoader.load(path) as AudioStream
		if stream == null:
			manager.warn_once(path, "missing or unimported audio: " + path)
			_audio_finished = true
			return
		# Flag bit 0 is leaving-effect ownership, not a proven loop flag.
		# ASSUMPTION: Effect audio is a one-shot even when an imported stream
		# was accidentally configured to loop. Duplicate before changing it.
		stream = stream.duplicate() as AudioStream
		if stream is AudioStreamWAV:
			(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
		elif stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = false
		elif stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = false
		_audio = AudioStreamPlayer3D.new()
		_audio.stream = stream
		_audio.bus = str(p("bus", "Master"))
		_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
		_audio.max_distance = 0.0
		add_child(_audio)
		_audio.top_level = true
		_audio.global_transform = Transform3D(Basis.IDENTITY, global_position)
		_audio.volume_db = -120.0
		_audio.finished.connect(_on_audio_finished)
		_audio.play()

	func _on_audio_finished() -> void:
		_audio_finished = true
		if is_instance_valid(_audio):
			_audio.queue_free()
		_audio = null

	func _stop_audio(leave_tail: bool) -> void:
		if not is_instance_valid(_audio):
			_audio = null
			return
		if _audio.finished.is_connected(_on_audio_finished):
			_audio.finished.disconnect(_on_audio_finished)
		if leave_tail and _audio.playing:
			# Leaving units retain the last position, volume and attenuation.
			var leaving: AudioStreamPlayer3D = _audio
			leaving.reparent(manager.host.get_tree().root, true)
			leaving.finished.connect(Callable(leaving, "queue_free"), CONNECT_ONE_SHOT)
		else:
			_audio.stop()
			_audio.queue_free()
		_audio = null

	func cleanup() -> void:
		_shake_live = false
		if _mixer != null:
			_mixer.remove(get_instance_id())
			_mixer = null
		# Explicitly freeing the effect stops its remaining owned playback.
		_stop_audio(false)


class ModelRig extends RefCounted:
	var manager: EffectUnitsModel
	var root: Node3D
	var console: RuntimeUnit
	var player: AnimationPlayer
	var skeletons: Array[Skeleton3D] = []
	var surfaces: Array[Dictionary] = []

	var _tree: AnimationTree
	var _layout: String = ""
	var _saved_player: Dictionary = {}
	var _pose_stamp: Vector2 = Vector2(-1.0, -1.0)
	var _materials_live: bool = false

	func _init(
		driver: EffectUnitsModel, model_root: Node3D, console_unit: RuntimeUnit
	) -> void:
		manager = driver
		root = model_root
		console = console_unit
		_collect(root)
		if console != null:
			_apply_pieces()

	func _collect(node: Node) -> void:
		if node is AnimationPlayer and player == null:
			player = node as AnimationPlayer
		if node is Skeleton3D:
			skeletons.append(node as Skeleton3D)
		if node is MeshInstance3D:
			var instance: MeshInstance3D = node as MeshInstance3D
			if instance.mesh != null:
				var original_overrides: Array[Material] = []
				var bases: Array[Material] = []
				for surface in range(instance.mesh.get_surface_count()):
					original_overrides.append(instance.get_surface_override_material(surface))
					bases.append(instance.get_active_material(surface))
				surfaces.append({
					"mesh": instance,
					"override": instance.material_override,
					"surface_overrides": original_overrides,
					"bases": bases,
					"runtime": {},
				})
		for child in node.get_children():
			_collect(child)

	func _apply_pieces() -> void:
		var selection: Variant = console.p("pieces", [])
		if not selection is Array or selection.is_empty():
			return
		# ASSUMPTION: Exported nodes retain piece class / variant metadata.
		# Numeric native class IDs require the converter's class-name mapping.
		for record in surfaces:
			var instance: MeshInstance3D = record["mesh"]
			var class_name_value: String = str(instance.get_meta(
				"gamma_piece_class", instance.name
			))
			var variant: int = int(instance.get_meta("gamma_piece_variant", 0))
			var selected: bool = false
			for value in selection:
				if value is String and value == class_name_value:
					selected = true
				elif value is Dictionary:
					if (
						str(value.get("class", "")) == class_name_value
						and int(value.get("variant", variant)) == variant
					):
						selected = true
			instance.visible = selected

	func clip_name(selector: Variant, figure: bool = false) -> StringName:
		if player == null or selector == null:
			return &""
		var names: PackedStringArray = player.get_animation_list()
		if selector is String or selector is StringName:
			var requested: StringName = StringName(str(selector))
			if player.has_animation(requested):
				return requested
			manager.warn_once(
				"clip:%d:%s" % [root.get_instance_id(), str(selector)],
				"animation '%s' is absent from %s." % [str(selector), str(root.name)]
			)
			return &""
		var number: int = int(selector)
		if number < 0 or number == 65535:
			return &""
		var mapping: Variant = manager.context.get(
			"figure_names" if figure else "animation_names", {}
		)
		if console != null:
			mapping = console.p("figure_names" if figure else "animation_names", mapping)
		var mapped: Variant
		if mapping is Array and number < mapping.size():
			mapped = mapping[number]
		elif mapping is Dictionary:
			mapped = mapping.get(number, mapping.get(str(number)))
		if mapped != null:
			return clip_name(str(mapped), false)
		var candidates: Array[StringName] = []
		for name_value in names:
			if name_value != "RESET":
				candidates.append(StringName(name_value))
		# ASSUMPTION: Without the original ID map, numeric IDs use the
		# AnimationPlayer's non-RESET order. Explicit names/maps are preferred.
		manager.warn_once(
			"clip_ids:%d" % root.get_instance_id(),
			"numeric animation/figure IDs use imported order; supply the original name map."
		)
		return candidates[number] if number < candidates.size() else &""

	func _elapsed(unit: RuntimeUnit) -> float:
		return maxf(
			0.0, manager.simulation.time_ms - float(unit.definition.get("start_ms", 0.0))
		) * 0.001 * float(unit.p("speed", 1.0))

	func apply_pose() -> void:
		if player == null or not is_instance_valid(root):
			return
		var stamp: Vector2 = Vector2(manager.simulation.wall_ms, manager.simulation.time_ms)
		if stamp == _pose_stamp:
			return
		_pose_stamp = stamp
		var layers: Array[Dictionary] = []
		var base: StringName = &""
		var base_time: float = 0.0
		if console != null and console.is_active(manager.simulation.time_ms):
			base = clip_name(console.p("animation", 0, 0xea))
			base_time = _elapsed(console)
			var percent: float = E.percent_at(console.definition, manager.simulation.time_ms)
			var weight: float = 1.0
			if not E.track_at(console.definition, "colors", 0).is_empty():
				weight = E.color_track(console.definition, 0, percent).a
			var first: StringName = clip_name(console.p("figure_a", 65535, 0xf4), true)
			var second: StringName = clip_name(console.p("figure_b", 65535, 0xf6), true)
			if first != &"" and weight != 0.0:
				layers.append({"name": first, "time": base_time, "weight": weight})
			if second != &"" and weight != 1.0:
				layers.append({"name": second, "time": base_time, "weight": 1.0 - weight})

		for value in manager.actors.values():
			var actor: RuntimeUnit = value
			if actor.type_name != "CModelAnimationProp" or not manager.target_is(self, actor):
				continue
			var enabled: bool = (
				actor.is_active(manager.simulation.time_ms)
				and not bool(actor.p("disabled", false, 0xb1))
			)
			var weight: float = actor.animation_weight(manager.simulation.time_ms)
			if not enabled:
				continue
			var name_value: StringName = clip_name(actor.p("name", actor.p("clip", 0, 0xb4)), true)
			if name_value != &"":
				layers.append({
					"name": name_value, "time": _elapsed(actor), "weight": weight
				})

		if base == &"" and layers.is_empty():
			_release_tree()
			return
		if base == &"" and player.has_animation(&"RESET"):
			base = &"RESET"
		var clips: Array[Dictionary] = [{"name": base, "time": base_time, "weight": 1.0}]
		clips.append_array(layers)
		var layout_parts: PackedStringArray = PackedStringArray()
		for clip in clips:
			layout_parts.append(str(clip["name"]))
		var layout: String = "\n".join(layout_parts)
		if _tree == null or layout != _layout:
			_build_tree(clips)
			_layout = layout
		for index in range(clips.size()):
			var clip: Dictionary = clips[index]
			var time_value: float = float(clip["time"])
			var animation: Animation = player.get_animation(clip["name"])
			if animation != null:
				if animation.loop_mode == Animation.LOOP_NONE:
					time_value = clampf(time_value, 0.0, animation.length)
				elif animation.length > 0.0:
					time_value = fposmod(time_value, animation.length)
			_tree.set("parameters/seek%d/seek_request" % index, time_value)
			if index > 0:
				_tree.set("parameters/add%d/add_amount" % index, float(clip["weight"]))
		_tree.advance(0.0)
		for skeleton in skeletons:
			if skeleton.has_method("force_update_all_bone_transforms"):
				skeleton.call("force_update_all_bone_transforms")

	func _build_tree(clips: Array[Dictionary]) -> void:
		if _saved_player.is_empty():
			_saved_player = {
				"mode": player.callback_mode_process,
				"animation": player.current_animation,
				"position": player.current_animation_position if player.current_animation != "" else 0.0,
				"playing": player.is_playing(),
				"speed": player.speed_scale,
			}
			player.pause()
			player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		if is_instance_valid(_tree):
			root.remove_child(_tree)
			_tree.queue_free()
		_tree = AnimationTree.new()
		root.add_child(_tree)
		_tree.anim_player = _tree.get_path_to(player)
		var animation_root: Node = player.get_node_or_null(player.root_node)
		if animation_root != null:
			_tree.root_node = _tree.get_path_to(animation_root)
		_tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		_tree.deterministic = true
		var blend: AnimationNodeBlendTree = AnimationNodeBlendTree.new()
		_tree.tree_root = blend
		var previous: StringName = &""
		for index in range(clips.size()):
			var clip: AnimationNodeAnimation = AnimationNodeAnimation.new()
			clip.animation = clips[index]["name"]
			var seek: AnimationNodeTimeSeek = AnimationNodeTimeSeek.new()
			var clip_key: StringName = StringName("clip%d" % index)
			var seek_key: StringName = StringName("seek%d" % index)
			blend.add_node(clip_key, clip)
			blend.add_node(seek_key, seek)
			blend.connect_node(seek_key, 0, clip_key)
			if index == 0:
				previous = seek_key
			else:
				# ASSUMPTION: Figures add to the base pose. The supplied
				# controller implementation does not establish its blend rule.
				var add_key: StringName = StringName("add%d" % index)
				blend.add_node(add_key, AnimationNodeAdd2.new())
				blend.connect_node(add_key, 0, previous)
				blend.connect_node(add_key, 1, seek_key)
				previous = add_key
		blend.connect_node(&"output", 0, previous)
		_tree.active = true

	func _release_tree() -> void:
		if is_instance_valid(_tree):
			_tree.active = false
			if _tree.get_parent() != null:
				_tree.get_parent().remove_child(_tree)
			_tree.queue_free()
		_tree = null
		_layout = ""
		if is_instance_valid(player) and not _saved_player.is_empty():
			player.callback_mode_process = int(_saved_player["mode"])
			player.speed_scale = float(_saved_player["speed"])
			var previous: StringName = StringName(str(_saved_player["animation"]))
			if previous != &"" and player.has_animation(previous):
				player.play(previous)
				player.seek(float(_saved_player["position"]), true)
				if not bool(_saved_player["playing"]):
					player.pause()
		_saved_player.clear()

	func bone_transform(selector: Variant) -> Variant:
		if selector == null:
			return null
		for skeleton in skeletons:
			var bone: int = -1
			if selector is String or selector is StringName:
				bone = skeleton.find_bone(str(selector))
			elif selector is int or selector is float:
				bone = int(selector)
			if bone < 0 or bone >= skeleton.get_bone_count():
				continue
			var result: Transform3D = skeleton.global_transform * skeleton.get_bone_global_pose(bone)
			var factor: float = 1.0 / 64.0
			if console == null:
				# ASSUMPTION: Externally attached models are already in world
				# units; their bone axes need engine-to-world conversion.
				factor = float(manager.context.get(
					"attached_model_units_per_engine",
					manager.context.get("unit_scale", 1.0)
				))
			# Preserve translated bone positions, but do not apply GLB's
			# 64x geometry conversion again to a child's engine-unit offset.
			result.basis = result.basis.scaled(Vector3.ONE * factor)
			return result
		return null

	func apply_materials() -> void:
		var listeners: Array[RuntimeUnit] = []
		for value in manager.actors.values():
			var actor: RuntimeUnit = value
			if (
				actor.type_name == "CModelMaterialProp"
				and actor.is_active(manager.simulation.time_ms)
				and not bool(actor.p("render_disabled", false))
				and manager.target_is(self, actor)
			):
				listeners.append(actor)
		if listeners.is_empty():
			_restore_materials()
			return
		_materials_live = true
		for record in surfaces:
			var mesh: MeshInstance3D = record["mesh"]
			if not is_instance_valid(mesh):
				continue
			mesh.material_override = null
			var bases: Array = record["bases"]
			for surface in range(bases.size()):
				var base: Material = bases[surface] as Material
				var settings: Dictionary = EffectUnitsModel.material_settings(base)
				for actor in listeners:
					var names: Variant = actor.p("submeshes", [])
					if names is Array and not names.is_empty():
						var source_name: String = str(mesh.get_meta("gamma_submesh", mesh.name))
						if not source_name in names:
							continue
					EffectUnitsModel.apply_material_unit(settings, actor)
				var shader: Shader = EffectUnitsModel.model_shader(settings)
				var cache: Dictionary = record["runtime"]
				var key: String = "%d:%d" % [surface, shader.get_instance_id()]
				if not cache.has(key):
					var material: ShaderMaterial = ShaderMaterial.new()
					material.shader = shader
					if base != null:
						material.render_priority = base.render_priority
					cache[key] = material
				var material: ShaderMaterial = cache[key]
				EffectUnitsModel.set_model_uniforms(material, settings)
				mesh.set_surface_override_material(surface, material)

	func _restore_materials() -> void:
		if not _materials_live:
			return
		_materials_live = false
		for record in surfaces:
			var mesh: MeshInstance3D = record["mesh"]
			if not is_instance_valid(mesh):
				continue
			mesh.material_override = record["override"]
			var overrides: Array = record["surface_overrides"]
			for surface in range(overrides.size()):
				mesh.set_surface_override_material(surface, overrides[surface])

	func dispose() -> void:
		_restore_materials()
		_release_tree()


static func material_settings(base: Material) -> Dictionary:
	var standard: BaseMaterial3D = base as BaseMaterial3D
	var diffuse: Color = Color.WHITE
	var texture: Texture2D
	var uv: Transform2D = Transform2D.IDENTITY
	var blend: String = "mix"
	var cull: int = BaseMaterial3D.CULL_BACK
	var depth_test: bool = true
	var depth_write: bool = true
	var unshaded: bool = false
	var cutoff: float = -1.0
	var roughness: float = 1.0
	var metallic: float = 0.0
	var normal_texture: Texture2D
	var normal_scale: float = 1.0
	var emission: Color = Color.BLACK
	var vertex_color: bool = false
	if standard != null:
		diffuse = standard.albedo_color
		texture = standard.albedo_texture
		uv = Transform2D(
			Vector2(standard.uv1_scale.x, 0),
			Vector2(0, standard.uv1_scale.y),
			Vector2(standard.uv1_offset.x, standard.uv1_offset.y)
		)
		cull = standard.cull_mode
		depth_test = not standard.no_depth_test
		depth_write = standard.depth_draw_mode != BaseMaterial3D.DEPTH_DRAW_DISABLED
		unshaded = standard.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
		roughness = standard.roughness
		metallic = standard.metallic
		vertex_color = standard.vertex_color_use_as_albedo
		if standard.normal_enabled:
			normal_texture = standard.normal_texture
			normal_scale = standard.normal_scale
		if standard.emission_enabled:
			emission = standard.emission * standard.emission_energy_multiplier
		if standard.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
			cutoff = standard.alpha_scissor_threshold
		match standard.blend_mode:
			BaseMaterial3D.BLEND_MODE_ADD:
				blend = "add"
			BaseMaterial3D.BLEND_MODE_SUB:
				blend = "sub"
			BaseMaterial3D.BLEND_MODE_MUL:
				blend = "mul"
			BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA:
				blend = "premul"

	# ASSUMPTION: Converted GLBs use BaseMaterial3D. Arbitrary custom shader
	# code, layered PBR maps and original native shaders cannot be reconstructed
	# from SMaterial's disassembly; retain the common imported PBR parameters.
	var result: Dictionary = {
		"diffuse": packed(diffuse),
		"blend": blend,
		"cull": cull,
		"depth_test": depth_test,
		"depth_write": depth_write,
		"unshaded": unshaded,
		"cutoff": cutoff,
		"roughness": roughness,
		"metallic": metallic,
		"normal": normal_texture,
		"normal_scale": normal_scale,
		"emission": emission,
		"vertex_color": vertex_color,
		"textures": [],
		"uv": [],
		"rect": [],
		"clip": [],
		"rgb": [],
		"add": [],
		"native_bytes": {},
	}
	for stage in range(8):
		result["textures"].append(texture if stage == 0 else null)
		result["uv"].append(uv if stage == 0 else Transform2D.IDENTITY)
		result["rect"].append(Rect2(0, 0, 1, 1))
		result["clip"].append(0)
		result["rgb"].append(Basis.IDENTITY)
		result["add"].append(Vector3.ZERO)
	return result


static func apply_material_unit(settings: Dictionary, actor: RuntimeUnit) -> void:
	var unit: Dictionary = actor.definition
	var percent: float = E.percent_at(unit, actor.manager.simulation.time_ms)
	var mode: int = int(actor.p("mode", 0, 0xb1))
	var color_packed: int = E.packed_color_track(unit, 0, percent)
	var color: Color = E.unpack_color(color_packed)
	var native: Dictionary = settings["native_bytes"]

	match mode:
		0:
			settings["diffuse"] = multiply_packed(int(settings["diffuse"]), color_packed)
			var alpha_mode: int = int(actor.p("alpha_mode", 0, 0xb2))
			var blend_mode: int = int(actor.p("blend_mode", 0, 0xb3))
			if alpha_mode == 1:
				settings["cutoff"] = -1.0
			elif alpha_mode == 2:
				var reference: int = int(E.f32(
					E.f32(float(int(settings["diffuse"])))
					* E.byte_track(unit, 0, percent)
				)) & 255
				native[0x2a] = reference
				# ASSUMPTION: Native byte +0x2a maps to alpha reference.
				settings["cutoff"] = float(reference) / 255.0
			if blend_mode == 1:
				settings["blend"] = "disabled"
			elif blend_mode == 2:
				var source: int = int(actor.p("source_blend", 5, 0xb4))
				var destination: int = int(actor.p("destination_blend", 6, 0xb5))
				native[0x28] = source
				native[0x29] = destination
				# ASSUMPTION: Recovered factor pairs use the usual Gamma
				# ONE=2, SRC_ALPHA=5, INV_SRC_ALPHA=6 numbering.
				match Vector2i(source, destination):
					Vector2i(5, 6):
						settings["blend"] = "mix"
					Vector2i(2, 6):
						settings["blend"] = "premul"
					Vector2i(5, 2), Vector2i(2, 2):
						settings["blend"] = "add"
					_:
						settings["blend"] = "mix"
						actor.manager.warn_once(
							"blend:%d:%d" % [source, destination],
							"unrecovered blend factor pair %d/%d uses alpha blending."
							% [source, destination]
						)
		1, 3:
			for stage in range(8):
				settings["rgb"][stage] = Basis.IDENTITY
				settings["add"][stage] = Vector3(color.r, color.g, color.b)
		2:
			native[0x31] = (color_packed >> 24) & 255
			# ASSUMPTION: Native byte +0x31 is represented as alpha cutoff.
			settings["cutoff"] = color.a
		4, 5:
			var stage: int = clampi(int(actor.p("stage", 0, 0xba)), 0, 7)
			var limits: Vector2 = actor.pair("uv_scale", [1.0, 1.0], 0xb2, 0xb6)
			var size_value: float = lerpf(
				limits.x, limits.y, E.byte_track(unit, 0, percent)
			)
			# Source uses (255 - alpha) / 256, not /255 and not elapsed time.
			var angle: float = float(255 - ((color_packed >> 24) & 255)) / 256.0 * TAU
			var offset: Vector3 = E.position_track(unit, percent)
			settings["uv"][stage] = Transform2D(
				Vector2(cos(angle), sin(angle)) * size_value,
				Vector2(-sin(angle), cos(angle)) * size_value,
				Vector2(offset.x, offset.y)
			)
			settings["clip"][stage] = 1 if bool(actor.p("clip", false, 0xbb)) else 2
			var texture: Texture2D = effect_texture(str(unit.get("texture", "")))
			if texture != null:
				settings["textures"][stage] = texture
				settings["rect"][stage] = E.texture_rect(unit, percent)
		6:
			var limits: Vector2 = actor.pair("value", [0.0, 1.0], 0xb2, 0xb6)
			var reference: int = clampi(int(lerpf(limits.x, limits.y, color.a) * 255.0), 0, 255)
			native[0x2f] = reference
			# ASSUMPTION: Native byte +0x2f is represented as alpha cutoff.
			settings["cutoff"] = float(reference) / 255.0
		7:
			var limits: Vector2 = actor.pair("brightness", [0.0, 1.0], 0xb2, 0xb6)
			var hue: float = E.byte_track(unit, 0, percent) + float(actor.p(
				"parent_hue", actor.manager.context.get("parent_hue", 0.0)
			))
			var brightness: float = lerpf(limits.x, limits.y, E.byte_track(unit, 1, percent))
			var saturation: float = E.byte_track(unit, 2, percent)
			var rotation: Basis = Basis(Vector3.ONE.normalized(), hue * TAU)
			var inverse_saturation: float = 1.0 - saturation
			var luminance: Vector3 = Vector3(0.3, 0.59, 0.11)
			var gray: Basis = Basis(
				Vector3.ONE * luminance.x,
				Vector3.ONE * luminance.y,
				Vector3.ONE * luminance.z
			)
			var saturation_matrix: Basis = Basis(
				Vector3.RIGHT * saturation + gray.x * inverse_saturation,
				Vector3.UP * saturation + gray.y * inverse_saturation,
				Vector3.BACK * saturation + gray.z * inverse_saturation
			)
			var modulation: Basis = Basis(
				Vector3(color.r, 0, 0), Vector3(0, color.g, 0), Vector3(0, 0, color.b)
			)
			var transform: Basis = modulation * saturation_matrix * rotation
			transform = transform.scaled(Vector3.ONE * brightness)
			var additive: Color = E.color_track(unit, 1, percent)
			var stage: int = int(actor.p("stage", -1, 0xba))
			for candidate in range(8):
				if stage < 0 or candidate == stage:
					settings["rgb"][candidate] = transform
					settings["add"][candidate] = Vector3(additive.r, additive.g, additive.b)
			var current: int = int(settings["diffuse"])
			var alpha: int = int(float((current >> 24) & 255) * color.a)
			settings["diffuse"] = (current & 0x00ffffff) | (clampi(alpha, 0, 255) << 24)
		8:
			var first: int = int(actor.p("depth_write", 1, 0xb2))
			var second: int = int(actor.p("depth_test", 1, 0xb3))
			var third: int = clampi(int(actor.p("cull", 0, 0xb4)), 0, 2)
			native[0x2c] = first
			native[0x2b] = second
			native[0x2e] = [1, 2, 3][third]
			# ASSUMPTION: Native state-byte meanings / cull winding are not
			# identified by the excerpt; expose their retained values as metadata.
			settings["depth_write"] = first != 0
			settings["depth_test"] = second != 0
			settings["cull"] = [
				BaseMaterial3D.CULL_DISABLED,
				BaseMaterial3D.CULL_FRONT,
				BaseMaterial3D.CULL_BACK,
			][third]
		_:
			actor.manager.warn_once("material_mode:%d" % mode, "invalid material mode %d." % mode)


static func model_shader(settings: Dictionary) -> Shader:
	var blend: String = str(settings["blend"])
	var cull: int = int(settings["cull"])
	var key: String = "model:%s:%d:%s:%s:%s" % [
		blend, cull, str(settings["depth_test"]),
		str(settings["depth_write"]), str(settings["unshaded"])
	]
	if _shaders.has(key):
		return _shaders[key]
	var modes: PackedStringArray = PackedStringArray()
	modes.append("blend_premul_alpha" if blend == "premul" else (
		"blend_mix" if blend == "disabled" else "blend_" + blend
	))
	modes.append("depth_draw_always" if bool(settings["depth_write"]) else "depth_draw_never")
	match cull:
		BaseMaterial3D.CULL_DISABLED:
			modes.append("cull_disabled")
		BaseMaterial3D.CULL_FRONT:
			modes.append("cull_front")
		_:
			modes.append("cull_back")
	if not bool(settings["depth_test"]):
		modes.append("depth_test_disabled")
	if bool(settings["unshaded"]):
		modes.append("unshaded")
	var source: String = "shader_type spatial;\nrender_mode %s;\n" % ", ".join(modes)
	source += """
uniform vec4 diffuse : source_color = vec4(1.0);
uniform float cutoff = -1.0;
uniform float material_roughness = 1.0;
uniform float material_metallic = 0.0;
uniform vec4 emission_color : source_color = vec4(0.0);
uniform bool use_vertex_color = false;
uniform bool normal_enabled = false;
uniform sampler2D normal_image : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale = 1.0;
"""
	for stage in range(8):
		source += """
uniform sampler2D image%d : source_color, filter_linear_mipmap, repeat_enable;
uniform bool enabled%d = false;
uniform mat3 uv%d = mat3(1.0);
uniform mat3 rgb%d = mat3(1.0);
uniform vec3 add%d = vec3(0.0);
uniform vec4 rect%d = vec4(0.0, 0.0, 1.0, 1.0);
uniform int clip%d = 0;
""" % [stage, stage, stage, stage, stage, stage, stage]
	source += "\nvoid fragment() {\n vec4 value = diffuse;\n"
	for stage in range(8):
		# ASSUMPTION: Additional texture stages use the mesh's first UV set
		# and multiply. Original stage combiners / UV semantics are absent.
		source += """
 if (enabled%d) {
	vec2 coordinate = (uv%d * vec3(UV, 1.0)).xy;
	if (clip%d == 1 && (
		coordinate.x < 0.0 || coordinate.y < 0.0 ||
		coordinate.x > 1.0 || coordinate.y > 1.0)) { discard; }
	if (clip%d == 2 && (
		abs(coordinate.x) > 128.0 || abs(coordinate.y) > 128.0)) { discard; }
	vec4 texel = texture(image%d, rect%d.xy + coordinate * rect%d.zw);
	texel.rgb = rgb%d * texel.rgb + add%d;
	value *= texel;
 }
""" % [stage, stage, stage, stage, stage, stage, stage, stage, stage]
	source += """
 if (use_vertex_color) { value *= COLOR; }
 if (cutoff >= 0.0 && value.a < cutoff) { discard; }
 ALBEDO = value.rgb;
 METALLIC = material_metallic;
 ROUGHNESS = material_roughness;
 EMISSION = emission_color.rgb;
 if (normal_enabled) {
	NORMAL_MAP = texture(normal_image, UV).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
 }
"""
	if blend != "disabled":
		source += " ALPHA = clamp(value.a, 0.0, 1.0);\n"
		if blend == "premul":
			source += " ALBEDO *= ALPHA;\n"
	source += "}\n"
	var shader: Shader = Shader.new()
	shader.code = source
	_shaders[key] = shader
	return shader


static func set_model_uniforms(material: ShaderMaterial, settings: Dictionary) -> void:
	material.set_shader_parameter("diffuse", E.unpack_color(int(settings["diffuse"])))
	material.set_shader_parameter("cutoff", float(settings["cutoff"]))
	material.set_shader_parameter("material_roughness", float(settings["roughness"]))
	material.set_shader_parameter("material_metallic", float(settings["metallic"]))
	material.set_shader_parameter("emission_color", settings["emission"])
	material.set_shader_parameter("use_vertex_color", bool(settings["vertex_color"]))
	material.set_shader_parameter("normal_enabled", settings["normal"] != null)
	material.set_shader_parameter("normal_image", settings["normal"])
	material.set_shader_parameter("normal_scale", float(settings["normal_scale"]))
	for stage in range(8):
		var uv: Transform2D = settings["uv"][stage]
		var rectangle: Rect2 = settings["rect"][stage]
		material.set_shader_parameter("enabled%d" % stage, settings["textures"][stage] != null)
		material.set_shader_parameter("image%d" % stage, settings["textures"][stage])
		material.set_shader_parameter("uv%d" % stage, Basis(
			Vector3(uv.x.x, uv.x.y, 0),
			Vector3(uv.y.x, uv.y.y, 0),
			Vector3(uv.origin.x, uv.origin.y, 1)
		))
		material.set_shader_parameter("rgb%d" % stage, settings["rgb"][stage])
		material.set_shader_parameter("add%d" % stage, settings["add"][stage])
		material.set_shader_parameter("rect%d" % stage, Vector4(
			rectangle.position.x, rectangle.position.y,
			rectangle.size.x, rectangle.size.y
		))
		material.set_shader_parameter("clip%d" % stage, int(settings["clip"][stage]))
	material.set_meta("gamma_native_bytes", settings["native_bytes"].duplicate())


static func filter_shader(mode: int, blend: String, distortion: bool) -> Shader:
	var key: String = "filter:%d:%s:%s" % [mode, blend, str(distortion)]
	if _shaders.has(key):
		return _shaders[key]
	var blend_mode: String = "blend_" + blend
	if blend == "premul":
		blend_mode = "blend_premul_alpha"
	var source: String = (
		"shader_type canvas_item;\nrender_mode unshaded, " + blend_mode + ";\n"
	)
	source += """
uniform sampler2D scene_image : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D image : source_color, filter_linear, repeat_enable;
uniform vec4 diffuse : source_color = vec4(1.0);
uniform vec4 atlas = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 viewport_px = vec2(1.0);
uniform float downsample = 2.0;
uniform float radius = 1.0;
uniform float distortion_pixels = 8.0;
void fragment() {
"""
	if mode == 0:
		source += " vec4 texel = texture(image, atlas.xy + UV * atlas.zw);\n"
		if distortion:
			# ASSUMPTION: Preset 11's absent shader uses RG displacement.
			source += """
 vec2 displacement = (texel.rg * 2.0 - 1.0) *
	distortion_pixels / max(viewport_px, vec2(1.0));
 COLOR = vec4(texture(scene_image, SCREEN_UV + displacement).rgb *
	diffuse.rgb, texel.a * diffuse.a);
"""
		else:
			source += " COLOR = texel * diffuse;\n"
	elif mode == 1:
		# The source explicitly complements the high alpha byte.
		source += """
 COLOR = vec4(texture(scene_image, SCREEN_UV).rgb * diffuse.rgb,
	1.0 - diffuse.a);
"""
	else:
		# ASSUMPTION: Shader-file 6's four passes are represented by a
		# downsampled separable binomial blur evaluated in one pass. Its actual
		# kernels are not supplied. Composition samples the original scene.
		source += """
 vec2 dimensions = max(floor(viewport_px / downsample), vec2(1.0));
 vec2 center = (floor(SCREEN_UV * dimensions) + vec2(0.5)) / dimensions;
 vec2 step_uv = vec2(max(radius, 0.0)) / dimensions;
 vec4 blurred = vec4(0.0);
 for (int y = -2; y <= 2; y++) {
	for (int x = -2; x <= 2; x++) {
		float wx = x == 0 ? 6.0 : (abs(x) == 1 ? 4.0 : 1.0);
		float wy = y == 0 ? 6.0 : (abs(y) == 1 ? 4.0 : 1.0);
		blurred += texture(scene_image, center + vec2(float(x), float(y)) *
			step_uv) * wx * wy / 256.0;
	}
 }
 COLOR = blurred * diffuse;
"""
	if blend == "premul":
		source += " COLOR.rgb *= COLOR.a;\n"
	source += "}\n"
	var shader: Shader = Shader.new()
	shader.code = source
	_shaders[key] = shader
	return shader


class CameraMixer extends RefCounted:
	var viewport_id: int
	var sources: Dictionary = {}
	var _applied: Array[Dictionary] = []

	func _init(id: int) -> void:
		viewport_id = id
		RenderingServer.frame_pre_draw.connect(_pre_draw)
		RenderingServer.frame_post_draw.connect(_post_draw)

	func remove(id: int) -> void:
		sources.erase(id)
		if sources.is_empty():
			_shutdown()

	func _shutdown() -> void:
		_post_draw()
		if RenderingServer.frame_pre_draw.is_connected(_pre_draw):
			RenderingServer.frame_pre_draw.disconnect(_pre_draw)
		if RenderingServer.frame_post_draw.is_connected(_post_draw):
			RenderingServer.frame_post_draw.disconnect(_post_draw)
		EffectUnitsModel._camera_mixers.erase(viewport_id)

	func _pre_draw() -> void:
		_post_draw()
		var groups: Dictionary = {}
		for id in sources.keys():
			var reference: WeakRef = sources[id]
			var actor: RuntimeUnit = reference.get_ref() as RuntimeUnit
			if not is_instance_valid(actor) or not actor._shake_live:
				sources.erase(id)
				continue
			var camera_node: Node = actor.manager.camera()
			if not is_instance_valid(camera_node):
				continue
			var key: int = camera_node.get_instance_id()
			if not groups.has(key):
				groups[key] = {"camera": camera_node, "actors": []}
			groups[key]["actors"].append(actor)
		if sources.is_empty():
			_shutdown()
			return

		for group in groups.values():
			var camera_node: Node = group["camera"]
			var position: Vector3 = Vector3.ZERO
			if camera_node is Camera3D:
				position = (camera_node as Camera3D).global_position
			elif camera_node is Camera2D:
				var xy: Vector2 = (camera_node as Camera2D).global_position
				position = Vector3(xy.x, xy.y, 0)
			else:
				continue
			var total: Vector3 = Vector3.ZERO
			var destination: Variant
			for actor_value in group["actors"]:
				var actor: RuntimeUnit = actor_value
				total += actor.shake_offset(position)
				if int(actor.p("mode", 0, 0xc4)) > 3:
					destination = actor.manager.context.get("camera_destination")
			if camera_node is Camera3D:
				var camera_3d: Camera3D = camera_node as Camera3D
				var original: Transform3D = camera_3d.global_transform
				var changed: Transform3D = original
				changed.origin += total
				if destination is Vector3:
					# ASSUMPTION: Around-destination mode keeps the camera
					# aimed at the supplied destination while moving its eye.
					var old_forward: Vector3 = -original.basis.z.normalized()
					var new_forward: Vector3 = (
						Vector3(destination) - changed.origin
					).normalized()
					if new_forward.length_squared() > 0.0:
						changed.basis = Basis(
							Quaternion(old_forward, new_forward)
						) * original.basis
				camera_3d.global_transform = changed
				_applied.append({
					"camera": weakref(camera_3d), "original": original, "changed": changed,
				})
			else:
				var camera_2d: Camera2D = camera_node as Camera2D
				var original: Transform2D = camera_2d.global_transform
				var changed: Transform2D = original
				changed.origin += Vector2(total.x, total.y)
				camera_2d.global_transform = changed
				_applied.append({
					"camera": weakref(camera_2d), "original": original, "changed": changed,
				})

	func _post_draw() -> void:
		for record in _applied:
			var reference: WeakRef = record["camera"]
			var camera_node: Node = reference.get_ref() as Node
			if camera_node is Camera3D:
				var camera_3d: Camera3D = camera_node as Camera3D
				var changed: Transform3D = record["changed"]
				if camera_3d.global_transform.is_equal_approx(changed):
					camera_3d.global_transform = record["original"]
			elif camera_node is Camera2D:
				var camera_2d: Camera2D = camera_node as Camera2D
				var changed: Transform2D = record["changed"]
				if camera_2d.global_transform.is_equal_approx(changed):
					camera_2d.global_transform = record["original"]
		_applied.clear()
