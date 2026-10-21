extends Node3D
# Renders a .glb model from 4 angles into one screenshot: Godot --path fsj-orig res://tests/model_view.tscn -- --model=res://assets/models/p_001.glb --out=C:/x.png
func _ready() -> void:
	var model := "res://assets/models/p_001.glb"; var out := "user://model.png"; var anim := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--model="): model = a.substr(8)
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--anim="): anim = a.substr(7)   # 4 poses of this animation (side view) instead of 4 angles
	RenderingServer.set_default_clear_color(Color(0.75, 0.85, 0.95))
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	var err := doc.append_from_file(ProjectSettings.globalize_path(model), st)
	if err != OK: print("load failed ", err); get_tree().quit(1); return
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-50, 30, 0); add_child(light)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.7, 0.7, 0.7); env.environment = e; add_child(env)
	var imgs: Array[Image] = []
	var cam := Camera3D.new(); add_child(cam)
	for i in 4:
		var inst := doc.generate_scene(st)
		add_child(inst)
		inst.rotation_degrees.y = i * 90.0 if anim == "" else 90.0
		if anim != "":
			var ap: AnimationPlayer = inst.find_children("*", "AnimationPlayer", true, false)[0]
			if i == 0: print("anims: ", ap.get_animation_list())
			ap.play(anim); ap.seek(ap.current_animation_length * i / 4.0, true)
		var aabb := AABB()
		var first := true
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var bb: AABB = mi.get_aabb()
			aabb = bb if first else aabb.merge(bb); first = false
		var c := aabb.get_center()
		cam.position = Vector3(c.x, c.y + aabb.size.y * 0.15, c.z + maxf(aabb.size.x, aabb.size.y) * 1.6)
		cam.look_at(c)
		for f in 3: await get_tree().process_frame
		imgs.append(get_viewport().get_texture().get_image())
		inst.queue_free()
		await get_tree().process_frame
	var w := imgs[0].get_width(); var h := imgs[0].get_height()
	var sheet := Image.create(w * 2, h * 2, false, imgs[0].get_format())
	for i in 4: sheet.blit_rect(imgs[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	sheet.resize(1280, 720)
	sheet.save_png(out); print("saved ", out)
	get_tree().quit()
