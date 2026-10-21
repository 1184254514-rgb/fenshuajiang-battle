extends Node
# Renders a 320x320 thumbnail for every .glb in a folder: Godot --path fsj-orig res://tests/thumbs.tscn -- --dir=C:/x --out=C:/x/thumbs (Claude)
func _ready() -> void:
	var dir := ""; var out := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--dir="): dir = a.substr(6)
		elif a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new(); vp.size = Vector2i(320, 320); vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.86, 0.9, 0.96)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.75, 0.75, 0.75)
	env.environment = e; vp.add_child(env)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-45, 35, 0); vp.add_child(light)
	var cam := Camera3D.new(); cam.fov = 35; vp.add_child(cam)
	var n := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".glb"): continue
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		if doc.append_from_file(dir.path_join(f), st) != OK: print("fail ", f); continue
		var inst := doc.generate_scene(st)
		vp.add_child(inst)
		inst.rotation_degrees.y = 25.0
		var aps := inst.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty():
			var ap: AnimationPlayer = aps[0]
			for nm in ["stand", "bind"]:
				if ap.has_animation(nm): ap.play(nm); ap.seek(0.0, true); break
		await get_tree().process_frame
		var aabb := AABB(); var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			aabb = bb if first else aabb.merge(bb); first = false
		var c := aabb.get_center(); var r := maxf(aabb.size.length() * 0.5, 0.01)
		cam.position = c + Vector3(0, r * 0.35, r * 2.9)
		cam.look_at(c)
		for i in 3: await get_tree().process_frame
		vp.get_texture().get_image().save_png(out.path_join(f.get_basename() + ".png"))
		inst.queue_free(); n += 1
	print("thumbs ", n)
	get_tree().quit()
