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

var _simulation: EffectEval
var _stem := ""
var _visuals: Dictionary = {}


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
	var _t0 := Time.get_ticks_usec()
	_update_effect(delta)
	Prof.add("eft:" + _stem, _t0)


func _context() -> Dictionary:
	var root: Transform3D = global_transform * Transform3D(
		Basis(
			Vector3(units_per_engine, 0, 0),
			Vector3(0, units_per_engine, 0),
			Vector3(0, 0, units_per_engine)
		),
		Vector3.ZERO
	)
	var camera: Camera3D = get_viewport().get_camera_3d()
	var camera_basis: Basis = Basis.IDENTITY
	var camera_position: Vector3 = root.origin + Vector3(0, 0, 10000)
	if is_instance_valid(camera):
		camera_basis = camera.global_transform.basis.orthonormalized()
		camera_position = camera.global_position
	return {
		"attached_model": attached_model,
		"attached_model_units_per_engine": units_per_engine,
		"root": root,
		"camera_basis": camera_basis,
		"camera_position": camera_position,
		"unit_scale": units_per_engine,
		"canvas": false,
	}


func _update_effect(delta: float) -> void:
	if _simulation == null:
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
	var seen: Dictionary = {}
	var invertible: bool = absf(global_transform.basis.determinant()) > 0.000000001
	var inverse: Transform3D = Transform3D.IDENTITY
	if invertible:
		inverse = global_transform.affine_inverse()
		for packet_value in packets:
			var packet: Dictionary = packet_value
			var key: String = packet["id"]
			seen[key] = true
			var visual: Variant = _visuals.get(key)
			if not is_instance_valid(visual):
				visual = Render.WorldQuad.new()
				add_child(visual)
				_visuals[key] = visual
			visual.update_quad(packet, inverse)

	for key in _visuals.keys():
		if not seen.has(key):
			var visual: Node3D = _visuals[key]
			if is_instance_valid(visual):
				visual.hide()
				visual.queue_free()
			_visuals.erase(key)

	if _simulation.is_finished() and not Render.u1_has_tails(self):
		set_process(false)
		queue_free()
