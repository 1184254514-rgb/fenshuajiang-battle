extends Node2D
# Plays UI effects in a grid and screenshots at --t= ms: Godot --path fsj-orig res://tests/fx_test.tscn -- --t=200 --out=C:/x.png (Claude)
func _ready() -> void:
	var t := 200; var out := "user://fx.png"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--t="): t = int(a.substr(4))
		elif a.begins_with("--out="): out = a.substr(6)
	RenderingServer.set_default_clear_color(Color(0.3, 0.32, 0.36))
	var list := [["perfegt", "fx/perfegt"], ["perfegt", "fx/great"], ["perfegt", "fx/good"], ["perfegt", "fx/miss"],
		["perfegt", "fx/combo"], ["quandi", "fx/loop_1"], ["jiezoupengzhuang1", "fx/loop"], ["jiantoudianji_shang1", "fx/loop"]]
	for i in list.size():
		var p := Vector2(160 + (i % 4) * 320, 180 + (i / 4) * 360)
		var n = EffectPlayer.spawn_ui(self, list[i][0], list[i][1], p, 1.0, true)
		print(list[i], " -> ", n)
	await get_tree().create_timer(t / 1000.0).timeout
	get_viewport().get_texture().get_image().save_png(out)
	print("saved")
	get_tree().quit()
