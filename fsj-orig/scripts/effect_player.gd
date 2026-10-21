class_name EffectPlayer
extends Node2D
## UI/screen-space EFT playback.
##
## Place the GDScript files in the Godot project's res://scripts directory.
## Run tools/eft2json.py first; JSON is loaded from res://assets/fx.
## Include "*.json" in the Godot export preset's non-resource file filter.
##
## Example:
##     EffectPlayer.spawn_ui($UI, "perfegt", "fx/perfegt", Vector2(320, 160))
##
## For world playback:
##     EffectPlayer.spawn_world($World, "pengzhuang", "fx/loop", Vector3.ZERO)
##
## A returned node owns its visuals and frees itself after all units and
## particle tails end. With loop=true, free the returned node to stop it.

const Eval = preload("res://scripts/effect_eval.gd")
const Render = preload("res://scripts/effect_render.gd")
const WorldPlayer = preload("res://scripts/effect_player_3d.gd")

var _simulation: EffectEval
var _visuals: Dictionary = {}


@warning_ignore("shadowed_variable_base_class")
static func spawn_ui(
	parent: CanvasItem,
	eft_stem: String,
	effect_name: String,
	position: Vector2,
	scale := 1.0,
	loop := false
) -> Node:
	if not is_instance_valid(parent):
		push_error("EffectPlayer.spawn_ui: parent is invalid.")
		return null
	var definition: Dictionary = Eval.load_effect(eft_stem, effect_name)
	if definition.is_empty():
		return null
	var player: EffectPlayer = EffectPlayer.new()
	player.name = "Effect_%s" % effect_name.get_file().validate_node_name()
	player.position = position
	player.scale = Vector2.ONE * float(scale)
	player._simulation = Eval.new(definition, bool(loop))
	parent.add_child(player)
	return player


@warning_ignore("shadowed_variable_base_class")
static func spawn_world(
	parent: Node3D,
	eft_stem: String,
	effect_name: String,
	position: Vector3,
	units_per_engine := 1.0 / 64.0,
	loop := false
) -> Node3D:
	return WorldPlayer.spawn_world(
		parent, eft_stem, effect_name, position, units_per_engine, loop
	)


func _ready() -> void:
	if _simulation == null:
		set_process(false)
		return
	_update_effect(0.0)


func _process(delta: float) -> void:
	_update_effect(delta)


func _context() -> Dictionary:
	var canvas_transform: Transform2D = global_transform
	var depth_scale: float = sqrt(absf(canvas_transform.determinant()))
	var root: Transform3D = Transform3D(
		Basis(
			Vector3(canvas_transform.x.x, canvas_transform.x.y, 0),
			Vector3(canvas_transform.y.x, canvas_transform.y.y, 0),
			Vector3(0, 0, depth_scale)
		),
		Vector3(canvas_transform.origin.x, canvas_transform.origin.y, 0)
	)
	return {
		"root": root,
		"camera_basis": Basis.IDENTITY,
		"camera_position": root.origin + Vector3(0, 0, 10000),
		"unit_scale": 1.0,
		"canvas": true,
	}


func _update_effect(delta: float) -> void:
	if _simulation == null:
		return
	var context: Dictionary = Render.u1_context(self, _simulation, _context())
	Render.prepare_model_units(self, _simulation, context)
	var packets: Array = _simulation.advance(delta, context)
	Render.update_model_units(self)
	var seen: Dictionary = {}
	var invertible: bool = absf(global_transform.determinant()) > 0.000000001
	var inverse: Transform2D = Transform2D.IDENTITY
	if invertible:
		inverse = global_transform.affine_inverse()
		for packet_value in packets:
			var packet: Dictionary = packet_value
			var key: String = packet["id"]
			seen[key] = true
			var visual: Variant = _visuals.get(key)
			if not is_instance_valid(visual):
				visual = Render.CanvasQuad.new()
				add_child(visual)
				_visuals[key] = visual
			visual.update_quad(packet, inverse)
			# Keep the source packet order within each unit's CanvasItem layer.
			move_child(visual, get_child_count() - 1)

	for key in _visuals.keys():
		if not seen.has(key):
			var visual: Node2D = _visuals[key]
			if is_instance_valid(visual):
				visual.hide()
				visual.queue_free()
			_visuals.erase(key)

	if _simulation.is_finished() and not Render.u1_has_tails(self):
		set_process(false)
		queue_free()
