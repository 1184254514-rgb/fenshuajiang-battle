extends Node
var checks := 0
var failures: Array[String] = []
func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)
		printerr("SKILL CAST FAIL: ", detail)
func _ready() -> void:
	var view := SceneView3D.new()
	add_child(view)
	view.begin_scene(24, 24)
	view.set_player(1, 176, 176, 0, "原包技能特效", true, true)
	view.set_follow(1)
	var serial := 0
	for stem in ["jineng_guhua", "jineng_jiasu", "jineng_fengshou", "jineng_datou", "jineng_kuangbao", "jineng_yinshen"]:
		serial += 1
		var path := "fx/cfg/%s.eft" % stem
		check(view.set_skill_cast(1, serial, path, 0, 5000), "original cast starts: " + stem)
		var effect := view.actors[1]["cast_fx"] as EffectPlayer3D
		check(effect != null and effect._stem == stem + "/fx/cast", "uses authored fx/cast")
		check(effect.attached_model == view.actors[1]["model_node"], "cast attaches to actor model")
		check(not view.set_skill_cast(1, serial, path, 0, 5000), "same snapshot does not replay cast")
		for i in 8: await get_tree().process_frame
	check(int(view.actors[1].get("cast_spawn_count", 0)) == 6, "one visual per successful unique cast")
	serial += 1
	check(not view.set_skill_cast(1, serial, "0", 0, 100), "dash has no fabricated effect when original table says zero")
	serial += 1
	check(not view.set_skill_cast(1, serial, "fx/cfg/jineng_guhua.eft", 1200, 1000), "expired snapshot is not replayed")
	serial += 1
	check(view.set_skill_cast(1, serial, "fx/cfg/jineng_guhua.eft", 150, 1000), "recent LAN cast catches up")
	var effect := view.actors[1]["cast_fx"] as EffectPlayer3D
	check(absf(effect._simulation.time_ms - 150.0) < 0.01, "replica fast-forwards authored clock")
	view.set_player_skill_state(1, true, 0)
	check((view.actors[1]["node"] as Node3D).visible, "local hidden actor retains silhouette")
	view.set_player(2, 240, 240, 3, "隐身对手", true, false)
	view.set_player_skill_state(2, true, 0)
	view.set_skill_cast(2, 1, "fx/cfg/jineng_fengshou.eft", 0, 1000)
	check(not (view.actors[2]["cast_fx"] as Node3D).is_visible_in_tree(), "cast does not reveal a hidden enemy")
	for i in 80: await get_tree().process_frame
	check(not is_instance_valid(effect), "finished one-shot releases its node")
	view.end_scene()
	check(view.actors.is_empty(), "scene cleanup releases cast owners")
	if failures.is_empty(): print("SKILL CAST PASSED: ", checks, " checks")
	get_tree().quit(0 if failures.is_empty() else 1)
