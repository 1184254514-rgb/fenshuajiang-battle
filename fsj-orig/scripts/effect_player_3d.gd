class_name EffectPlayer3D
extends Node3D
## World-space EFT playback. The effect root inherits its parent transform.
## Particle space mode 0 stores world positions at birth; mode 1 follows
## the emitter. Both retain live particle tails after emission stops.
##
## Facing, including camera and velocity alignment, is evaluated each frame.
## No Camera3D is required to spawn: until one is available, billboards use
## world XY axes as an explicit fallback.
##
## Example:
##     EffectPlayer3D.spawn_world(
##         $World, "pengzhuang", "fx/loop", Vector3(0, 1, 0)
##     )

const Eval = preload("res://scripts/effect_eval.gd")
const Render = preload("res://scripts/effect_render.gd")

var units_per_engine: float = 1.0 / 64.0
var attached_model: Node3D = null   # character model whose Skeleton3D bones units attach to (bone_name), Claude

static var _cam_cache_frame: int = -1
static var _cam_cache_basis: Basis = Basis.IDENTITY
static var _cam_cache_pos: Vector3 = Vector3.ZERO
static var _cam_cache_valid: bool = false

var _simulation: EffectEval
var _stem := ""
var _visuals: Dictionary = {}
var _ctx_dict: Dictionary = {}


@warning_ignore("shadowed_variable_base_class")
static func spawn_world(
	parent: Node3D,
	eft_stem: String,
	effect_name: String,
	position: Vector3,
	units_per_engine := 1.0 / 64.0,
	loop := false
) -> Node3D:
	if not is_instance_valid(parent):
		push_error("EffectPlayer3D.spawn_world: parent is invalid.")
		return null
	var conversion: float = float(units_per_engine)
	if not is_finite(conversion) or conversion <= 0.0:
		push_error("EffectPlayer3D: units_per_engine must be finite and positive.")
		return null
	var definition: Dictionary = Eval.load_effect(eft_stem, effect_name)
	if definition.is_empty():
		return null
	var player: EffectPlayer3D = EffectPlayer3D.new()
	player.name = "Effect_%s" % effect_name.get_file().validate_node_name()
	player.position = position
	player.units_per_engine = conversion
	player._stem = eft_stem + "/" + effect_name
	player._simulation = Eval.new(definition, bool(loop))
	parent.add_child(player)
	return player


func _ready() -> void:
	if _simulation == null:
		set_process(false)
		return
	_update_effect(0.0)


func _process(delta: float) -> void:
	if not visible:
		if _simulation != null and not _simulation.looping:
			_simulation.wall_ms += maxf(delta, 0.0) * 1000.0
			_simulation.time_ms += maxf(delta, 0.0) * 1000.0
			if _simulation.is_finished():
				set_process(false)
				queue_free()
		return
	var _t0 := Time.get_ticks_usec()
	_update_effect(delta)
	Prof.add("eft:" + _stem, _t0)


func _is_far_offscreen() -> bool:
	if not _cam_cache_valid:
		return false
	var gp := global_position
	var dx := gp.x - _cam_cache_pos.x
	var dz := gp.z - _cam_cache_pos.z
	return dx * dx + dz * dz > 2600.0


func _context() -> Dictionary:
	var root: Transform3D = global_transform * Transform3D(
		Basis(
			Vector3(units_per_engine, 0, 0),
			Vector3(0, units_per_engine, 0),
			Vector3(0, 0, units_per_engine)
		),
		Vector3.ZERO
	)
	var frame: int = Engine.get_process_frames()
	if frame != _cam_cache_frame:
		_cam_cache_frame = frame
		var camera: Camera3D = get_viewport().get_camera_3d()
		if is_instance_valid(camera):
			_cam_cache_valid = true
			_cam_cache_basis = camera.global_transform.basis.orthonormalized()
			_cam_cache_pos = camera.global_position
		else:
			_cam_cache_valid = false
	_ctx_dict["attached_model"] = attached_model
	_ctx_dict["attached_model_units_per_engine"] = units_per_engine
	_ctx_dict["root"] = root
	_ctx_dict["camera_basis"] = _cam_cache_basis if _cam_cache_valid else Basis.IDENTITY
	_ctx_dict["camera_position"] = _cam_cache_pos if _cam_cache_valid else (root.origin + Vector3(0, 0, 10000))
	_ctx_dict["unit_scale"] = units_per_engine
	_ctx_dict["canvas"] = false
	return _ctx_dict


func _update_effect(delta: float) -> void:
	if _simulation == null:
		return
	var frame: int = Engine.get_process_frames()
	if frame != _cam_cache_frame:
		_cam_cache_frame = frame
		var camera: Camera3D = get_viewport().get_camera_3d()
		if is_instance_valid(camera):
			_cam_cache_valid = true
			_cam_cache_basis = camera.global_transform.basis.orthonormalized()
			_cam_cache_pos = camera.global_position
		else:
			_cam_cache_valid = false
	if delta > 0.0 and _is_far_offscreen():
		if not _visuals.is_empty():
			for key in _visuals:
				var visual: Node3D = _visuals[key]
				if is_instance_valid(visual):
					visual.visible = false
		if not _simulation.looping:
			_simulation.wall_ms += delta * 1000.0
			_simulation.time_ms += delta * 1000.0
			if _simulation.is_finished():
				set_process(false)
				queue_free()
		return
	var _t := Time.get_ticks_usec()
	var context: Dictionary = Render.u1_context(self, _simulation, _context())
	_t = Prof.add("p:ctx", _t)
	Render.prepare_model_units(self, _simulation, context)
	_t = Prof.add("p:prep", _t)
	var packets: Array = _simulation.advance(delta, context)
	_t = Prof.add("p:adv", _t)
	Render.update_model_units(self)
	_t = Prof.add("p:upd", _t)
	if not packets.is_empty() or not _visuals.is_empty():
		var seen: Dictionary = {}
		var invertible: bool = absf(global_transform.basis.determinant()) > 0.000000001
		if invertible and not packets.is_empty():
			var inverse: Transform3D = global_transform.affine_inverse()
			for packet_value in packets:
				var packet: Dictionary = packet_value
				var key: String = packet["id"]
				seen[key] = true
				var visual: Variant = _visuals.get(key)
				if not is_instance_valid(visual):
					visual = Render.WorldQuad.new()
					add_child(visual)
					_visuals[key] = visual
				if not (visual as Node3D).visible:
					(visual as Node3D).visible = true
				visual.update_quad(packet, inverse)

		if not _visuals.is_empty():
			var stale: Array = []
			for key in _visuals:
				if not seen.has(key):
					stale.append(key)
			for key in stale:
				var visual: Node3D = _visuals[key]
				if is_instance_valid(visual):
					visual.hide()
					visual.queue_free()
				_visuals.erase(key)

	if _simulation.is_finished() and not Render.u1_has_tails(self):
		set_process(false)
		queue_free()
