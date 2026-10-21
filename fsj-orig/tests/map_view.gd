extends Node3D
func _ready() -> void:
	var out := "user://map.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	RenderingServer.set_default_clear_color(Color(0.75, 0.85, 0.95))
	var doc := GLTFDocument.new(); var st := GLTFState.new()
	doc.append_from_file(ProjectSettings.globalize_path("res://assets/models/map01.glb"), st)
	var inst := doc.generate_scene(st); add_child(inst)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-60, 30, 0); add_child(light)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.8, 0.8, 0.8); env.environment = e; add_child(env)
	var aabb := AABB(); var first := true
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		aabb = mi.get_aabb() if first else aabb.merge(mi.get_aabb()); first = false
	print("map aabb ", aabb)
	var cam := Camera3D.new(); add_child(cam)
	var shots := [Vector3(0, 1.4, 0.0001), Vector3(0.0, 0.5, 0.9)]
	var imgs: Array[Image] = []
	for d in shots:
		var c := aabb.get_center()
		cam.far = 10000
		cam.position = c + d * aabb.size.length() * 0.6
		cam.look_at(c, Vector3(0, 0, -1) if d.z < 0.01 else Vector3.UP)
		for f in 3: await get_tree().process_frame
		imgs.append(get_viewport().get_texture().get_image())
	var w := imgs[0].get_width(); var h := imgs[0].get_height()
	var sheet := Image.create(w * 2, h, false, imgs[0].get_format())
	for i in 2: sheet.blit_rect(imgs[i], Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	sheet.resize(1280, 360); sheet.save_png(out); print("saved ", out)
	get_tree().quit()
