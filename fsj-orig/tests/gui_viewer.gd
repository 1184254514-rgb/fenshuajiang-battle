extends Node
# Renders original .gui layouts and saves screenshots. Usage:
#   Godot --path fsj-orig -- --gui=messagebox --out=C:/path/shot.png
#   Godot --path fsj-orig -- --all --outdir=C:/path/dir          (every layout, 640x360 thumbnails)
func _ready() -> void:
	var gui := "messagebox"; var out := "user://shot.png"; var all := false; var outdir := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--gui="): gui = a.substr(6)
		elif a.begins_with("--out="): out = a.substr(6)
		elif a == "--all": all = true
		elif a.begins_with("--outdir="): outdir = a.substr(9)
	RenderingServer.set_default_clear_color(Color(0.5, 0.5, 0.5))
	if all:
		DirAccess.make_dir_recursive_absolute(outdir)
		var names: Array[String] = []
		for f in DirAccess.get_files_at(GuiRuntime.GUI_DIR):
			if f.ends_with(".json"): names.append(f.get_basename())
		names.sort()
		for n in names:
			var root := GuiRuntime.build(n)
			add_child(root)
			for i in 3: await get_tree().process_frame
			var img := get_viewport().get_texture().get_image()
			img.resize(640, 360, Image.INTERPOLATE_BILINEAR)
			img.save_png(outdir.path_join(n + ".png"))
			root.queue_free()
			await get_tree().process_frame
		print("saved ", names.size())
		get_tree().quit()
		return
	var root := GuiRuntime.build(gui)
	add_child(root)
	for i in 5: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out, " children=", root.get_child_count())
	get_tree().quit()
