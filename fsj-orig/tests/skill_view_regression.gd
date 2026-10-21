extends Node
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("SKILL VIEW TEST: " + message)
func mode(view: SceneView3D, idx: int) -> int:
	return int(round(view._block_data[idx].a)) % 8
func _ready() -> void:
	var view := SceneView3D.new()
	add_child(view)
	view.begin_scene(20, 20)
	view.set_process(false)
	view.set_manor_colour(100, 1)
	view.set_manor_colour(200, 6)
	view.set_player(1, 8.5 * 16, 8.5 * 16, 1, "LOCAL", true, true)
	view.set_player(2, 12.5 * 16, 8.5 * 16, 6, "ENEMY", true, false)
	view.set_follow(1)
	var local_line := 9 * 20 + 8
	var enemy_line := 9 * 20 + 12
	var enemy_on_land := 10 * 20 + 12
	view.set_cell(local_line, 0, 1)
	view.set_cell(enemy_line, 0, 2)
	view.set_cell(enemy_on_land, 100, 2)
	var initial_y := view.camera.position.y
	view.set_player_skill_state(2, true, 0, 0)
	check(not (view.actors[2]["node"] as Node3D).visible, "enemy character and ring must be invisible")
	check(mode(view, enemy_line) == 0, "enemy hidden trail must disappear")
	check(mode(view, enemy_on_land) == 1, "invisible enemy trail must reveal underlying territory")
	check(view.trail_cells[enemy_line] == 2, "invisibility must preserve trail collision data")
	check(view.owner_cells[enemy_on_land] == 100, "invisibility must preserve manor ownership")
	view.set_player_skill_state(1, true, 1, 100)
	check((view.actors[1]["node"] as Node3D).visible, "local silhouette must remain visible")
	check(mode(view, local_line) == 5, "local trail must use translucent coverage")
	check((view.actors[1]["armor_shell"] as MeshInstance3D).visible, "active armor shell must be visible")
	check(absf(view.camera.position.y - initial_y - 100.0 / 16.0) < 0.001, "camera bonus must be native pixels divided by NODE")
	var ghost_count := 0
	for entry in view.actors[1]["skill_materials"]:
		if (entry["ghost"] as BaseMaterial3D).albedo_color.a < 0.5: ghost_count += 1
	check(ghost_count > 0, "local original model meshes must use transparent material copies")
	# Expiry restores actors, trails, armor and camera without modifying logic.
	view.set_player_skill_state(2, false, 0, 0)
	view.set_player_skill_state(1, false, 0, 0)
	check((view.actors[2]["node"] as Node3D).visible, "enemy must reappear on expiry")
	check(mode(view, enemy_line) == 3 and mode(view, enemy_on_land) == 3, "enemy trail must reappear on expiry")
	check(mode(view, local_line) == 3, "local trail opacity must restore on expiry")
	check(not (view.actors[1]["armor_shell"] as MeshInstance3D).visible, "armor shell must hide on expiry")
	check(absf(view.camera.position.y - initial_y) < 0.001, "camera must restore on expiry")
	for entry in view.actors[1]["skill_materials"]:
		var mesh := entry["mesh"] as MeshInstance3D
		check(mesh.get_surface_override_material(int(entry["surface"])) == entry["original"], "ghost material must restore original override")
	# Model updates must not reveal a still-hidden opponent.
	view.set_player_skill_state(2, true, 1, 0)
	view.set_player(2, 13.5 * 16, 8.5 * 16, 6, "ENEMY", true, false)
	check(not (view.actors[2]["node"] as Node3D).visible, "movement sync must not reveal invisible enemy")
	for unused in range(4): await get_tree().process_frame
	view.end_scene()
	check(view._player_skill_states.is_empty(), "scene cleanup must clear all skills")
	if failures.is_empty(): print("SKILL VIEW REGRESSION PASSED: hidden actor/trail/territory, local silhouette, armor, camera pixels, expiry, reset")
	get_tree().quit(0 if failures.is_empty() else 1)
