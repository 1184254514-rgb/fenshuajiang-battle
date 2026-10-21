extends Node
# Real host + original Lua UI, item-animation bridge, death and settlement navigation.
# --fixed-fps 60 res://tests/flow_regression.tscn -- --choice=home|again [--shot=<absolute PNG>]
var host: LuaHost
var failures: Array[String] = []
var checks := 0
var choice := "home"
var screenshot_path := ""

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures.append(description)
		printerr("FLOW FAIL: ", description)

func _lua(source: String):
	var result = host.lua.do_string(source)
	if result is LuaError:
		_check(false, str(result))
		return null
	return result

func _frames(count: int) -> void:
	for index in count:
		await get_tree().process_frame

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--choice="): choice = argument.substr(9)
		elif argument.begins_with("--shot="): screenshot_path = argument.substr(7)
	var ui := Control.new()
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	if not host.start(ui):
		_check(false, "Lua host starts")
		_finish()
		return
	_lua("require 'start_game'")
	await _frames(90)
	await _test_text_focus(ui)
	_lua("g_App:GetLoginFrame():ConnectWorld()")
	await _frames(150)
	_lua("g_App:EnterRoom(eRT_Endless)")
	await _frames(90)
	_check(_lua("local d=g_App:GetDirector() return d ~= nil and d.__alive == true") == true, "endless director spawns")
	_check(_lua("return g_App.__scene.__c_expEnabled == false") == true, "offline mode does not invent experience crystals")
	if failures.is_empty():
		_test_item_animation_bridge()
		_press_key(KEY_RIGHT)
		await _frames(1)
		_check(_lua("return g_App:GetDirector().__dir") == 2, "right arrow reaches original Lua movement")
		_press_key(KEY_UP)
		await _frames(30)
		_check(_lua("return g_App:GetDirector().__dir") == 4, "up arrow turns director")
	if not screenshot_path.is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		_check(get_viewport().get_texture().get_image().save_png(screenshot_path) == OK, "gameplay screenshot saved")
	_lua("__flow_old_scene=g_App.__scene; local d=g_App:GetDirector(); SceneSim.kill_player(g_App.__scene,d,nil,false)")
	await _frames(120)
	var clicked: Array[String] = []
	for step in 8:
		if _destination_reached(): break
		for key in ["m_pWndDieTip", "m_pWndBalanceBeyond", "m_pRhythmSettWnd", "m_pResultWnd", "m_pWndBalance", "m_pWndModeOpenReward"]:
			var window = _lua("local wf=g_App.__scene and g_App.__scene:GetWanfa(); local w=wf and wf['%s']; return w and w.__node" % key)
			if window is Control and window.is_visible_in_tree():
				var button := _find_button(window)
				if key == "m_pWndBalance":
					var wanted := "zailaiyiju" if choice == "again" else "huizhujiemian"
					button = window.find_child(wanted, true, false) as Control
				_check(button != null, "settlement button exists: " + key)
				if button != null:
					clicked.append(key + ":" + str(button.name))
					button.call("_finish_click", button.size * 0.5)
				break
		await _frames(120)
	_check(not clicked.is_empty(), "settlement windows are shown and clicked")
	_check(_destination_reached(), "settlement reaches " + choice)
	_check(host._tick_errors == 0, "no Lua tick or animation callback errors")
	print("FLOW NAVIGATION: ", clicked)
	_finish()

func _test_item_animation_bridge() -> void:
	var id = _lua("""
		local sc=g_App.__scene
		local d=g_App:GetDirector()
		local id=sc:AllocObjectID(false)
		__flow_item=SceneItemsC.CreateItem(sc,id,CVector2f:new(d.__x,d.__y),
			{modelID=0,dropType=0,flags=0,x1=0,y1=0,x2=0,y2=0})
		return id
	""")
	if id == null: return
	var item: Dictionary = host.scene_view.items.get(int(id), {})
	_check(not item.is_empty(), "logical item creates render peer")
	if item.is_empty(): return
	_check(item["anim"] == "rb1", "new item uses state animation with zero flight duration")
	_check(_lua("return __flow_item:GetState()") == 1, "item remains unarmed before animation end")
	item["anim_end"] = 0.0
	host.scene_view._update_items(0.0)
	_check(_lua("return __flow_item:GetState()") == 2, "rb1 completion arms logical pickup through real host callback")
	_check(item["anim"] == "bind", "rb1 completion starts idle animation")
	_check(_lua("local d=g_App:GetDirector(); local before=d:GetSimple32Property(0); d:OnCollideDropOut(__flow_item); return d:GetSimple32Property(0) == (before+1) % 0x100000000") == true, "real pickup credits one raw coin")
	_check(_lua("return __flow_item:GetState()") == 3, "pickup keeps logical item until disappearance completes")
	_check(item["anim"] == "fly_die", "pickup starts disappearance animation")
	item["anim_end"] = 0.0
	host.scene_view._update_items(0.0)
	_check(_lua("return g_App.__scene.__c_items[__flow_item:GetObjectID()] == nil") == true, "disappearance callback removes logical item")
	_check(not host.scene_view.items.has(int(id)), "disappearance clears render peer")
	_lua("__flow_item=nil")

func _test_text_focus(ui: Control) -> void:
	var widget = GuiRuntime.GuiWidgetScript.new()
	widget.setup({"class_name": "CGEdit", "wnd_name": "AB", "base_fields": {
		"this+0x10": 20, "this+0x14": 20, "this+0x18": 160, "this+0x1c": 32,
	}}, [], "TextFocusRegression", GuiRuntime.GuiWidgetScript)
	ui.add_child(widget)
	await _frames(1)
	var edit := widget.get("_edit_control") as LineEdit
	_check(edit != null, "native edit retains a text control")
	if edit != null:
		edit.grab_focus()
		edit.caret_column = 2
		_press_key(KEY_LEFT)
		await _frames(1)
		_check(edit.caret_column == 1, "arrow keys still edit text when input is focused")
		edit.release_focus()
	widget.queue_free()
	await _frames(1)

func _destination_reached() -> bool:
	if choice == "again":
		return _lua("local d=g_App:GetDirector(); return g_App.__scene ~= nil and g_App.__scene ~= __flow_old_scene and d ~= nil and d.__alive == true") == true
	return _lua("local w=g_App:GetGameStart(); return g_App.__scene == nil and w.__node:is_visible_in_tree()") == true

func _press_key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)

func _find_button(node: Node) -> Control:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree() and child.has_method("_is_button") and child.call("_is_button"):
			return child
		var found := _find_button(child)
		if found != null: return found
	return null

func _finish() -> void:
	if failures.is_empty():
		print("FLOW PASSED: ", checks, " checks; choice=", choice)
		get_tree().quit(0)
	else:
		printerr("FLOW FAILED: ", failures.size(), " / ", checks, " checks")
		get_tree().quit(1)
