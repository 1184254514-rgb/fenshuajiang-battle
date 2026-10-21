extends Node
var host: LuaHost
var failures: Array[String] = []
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("LAN UI FAIL: ", message)
func frames(count: int) -> void:
	for i in count: await get_tree().process_frame
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = down
		Input.parse_input_event(event)
func _ready() -> void:
	var ui := Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	check(host.start(ui), "runtime boots")
	host.lua.do_string("require 'start_game'")
	await frames(90)
	var hud := ui.get_node("LanHud")
	check(hud.layer.visible, "LAN launch opens connection panel")
	hud.nick.text = "随便取的名字"
	click(hud.host_button)
	await frames(90)
	check(host.lan_session.role == "host", "create room via real mouse")
	check(host.lua.do_string("return SceneSkills.GetHUD().home") == true, "LAN entry logs in without password")
	check(host.lan_session.members[0].nick == "随便取的名字", "nickname comes from field")
	await RenderingServer.frame_post_draw
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):
			get_viewport().get_texture().get_image().save_png(argument.substr(8) + "room.png")
	click(hud.leave_button)
	await frames(15)
	check(host.lan_session.phase == "idle", "leave room via real mouse")
	check(host._tick_errors == 0, "no Lua errors")
	if failures.is_empty(): print("LAN UI PASSED: ", checks, " checks")
	get_tree().quit(0 if failures.is_empty() else 1)
