class_name LuaHost
extends Node
# Runs the original Lua client scripts inside Godot (Lua 5.4 via the lua-gdextension addon) and provides the
# engine ("Gamma" C++) API they expect. See NATIVES.md. Claude.

var lua: LuaState
var root_ui: Control
var api: LuaApi
var root_wnd: GuiRuntime.GuiWnd
var scene_view: SceneView3D
var lan_session: Node
var _tick_fn
var _item_animation_fn
var _tick_errors := 0
var _tick_ms_remainder := 0.0

class LuaApi extends RefCounted:
	var host: LuaHost
	var img := GuiImageOps.new()
	var scene_view: SceneView3D
	var audio: AudioHost
	const DATA_ROOT := "res://data/orig/"
	func _resolve(path: String) -> String:
		path = path.replace("\\", "/")
		if path.begins_with("res://") or path.begins_with("user://"):
			return path
		while path.begins_with("./"):
			path = path.substr(2)
		return DATA_ROOT + path
	func file_exists(path: String) -> bool:
		return FileAccess.file_exists(_resolve(path))
	func read_bytes(path: String) -> PackedByteArray:
		return FileAccess.get_file_as_bytes(_resolve(path))
	func read_text(path: String) -> String:
		var b := FileAccess.get_file_as_bytes(_resolve(path))
		if b.size() >= 2 and b[0] == 0xFF and b[1] == 0xFE:
			return b.slice(2).get_string_from_utf16() if b.size() > 2 else ""
		if b.size() >= 3 and b[0] == 0xEF and b[1] == 0xBB and b[2] == 0xBF:
			return b.slice(3).get_string_from_utf8()
		return b.get_string_from_utf8()
	func read_base64(path: String) -> String:
		return Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(_resolve(path)))
	func write_text(path: String, text: String) -> bool:
		var p := path
		if not (p.begins_with("user://") or p.begins_with("res://")):
			p = "user://" + p
		var f := FileAccess.open(p, FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(text)
		return true
	func start_music(music_id: int) -> void:
		# config/music.txt: nID ... MusicPath(12) RhythmPath(13); downloaded "netmusic/" tracks are not in the package -> default song
		var rows := read_text("config/music.txt").split("
")
		var found := {}
		var header: PackedStringArray = rows[0].strip_edges(false, true).split("	") if rows.size() > 0 else PackedStringArray()
		for line in rows:
			var c := line.strip_edges(false, true).split("	")
			if c.size() > 13 and c[0].is_valid_int():
				var row := {}
				for k in mini(header.size(), c.size()):
					row[header[k].strip_edges().trim_prefix("﻿")] = c[k]
				if int(c[0]) == music_id:
					found = {"m": c[12], "r": c[13], "row": row}
				if int(c[0]) == 121 and not found.has("def"):
					found["def"] = {"m": c[12], "r": c[13], "row": row}
		var pick: Dictionary = found if found.has("m") else found.get("def", {})
		if pick.has("m") and not FileAccess.file_exists("res://data/orig/" + String(pick["m"])) and found.has("def"):
			pick = found["def"]
		if pick.has("m"):
			host.scene_view.music_row = pick.get("row", {})
			host.scene_view.start_music(String(pick["m"]), String(pick["r"]))
	func parse_json(text: String):
		var parser=JSON.new()
		if parser.parse(text)!=OK: return null
		return parser.data
	func lan_input(direction: int, skill: bool, grade: int = -1) -> void:
		if is_instance_valid(host.lan_session): host.lan_session.send_input(direction, skill, grade)
	func lan_action(action: String) -> void:
		if is_instance_valid(host.lan_session): host.lan_session.game_action(action)
	func planner_restart() -> bool:
		if not is_instance_valid(host.lan_session) or host.lan_session.role != "host": return false
		host.lan_session.game_action("leave")
		host.lan_session.call_deferred("start_match")
		return true
	func planner_is_client() -> bool:
		return is_instance_valid(host.lan_session) and host.lan_session.role == "client"
	func time_ms() -> int:
		return Time.get_ticks_msec()
	func unix_ms() -> int:
		return int(Time.get_unix_time_from_system() * 1000.0)
	func log(s: String) -> void:
		print(s)
	# --- GUI ---
	func root_wnd() -> Object:
		return host.root_wnd
	func create_gui(res_name: String, parent) -> Object:
		# "gui/cfg/login.gui" -> GuiRuntime window (added under parent window node or the UI root)
		var gui_name := res_name.get_file().get_basename()
		var w := GuiRuntime.build(gui_name)
		if parent != null and parent is Control:
			parent.add_child(w)
		else:
			host.root_ui.add_child(w)
		return w

func start(ui_root: Control) -> bool:
	root_ui = ui_root
	scene_view = SceneView3D.new()
	ui_root.add_child(scene_view)
	root_wnd = GuiRuntime.GuiWnd.new()
	root_wnd.setup({"base_fields": {"this+0x10": 0, "this+0x14": 0, "this+0x18": 1280, "this+0x1c": 720}}, [], "root", GuiRuntime.GuiWidgetScript)
	ui_root.add_child(root_wnd)
	lua = LuaState.new()
	lua.open_libraries()
	api = LuaApi.new()
	api.host = self
	api.scene_view = scene_view
	var audio_host := AudioHost.new()
	add_child(audio_host)
	api.audio = audio_host
	lua.globals["Host"] = api
	_register_core()
	for f in ["res://lua/prelude.lua", "res://lua/natives_consts.lua", "res://lua/natives.lua", "res://lua/boot.lua"]:
		if not FileAccess.file_exists(f):
			printerr("Missing Lua bootstrap resource: ", f)
			return false
		var r = lua.do_file(f)
		if r is LuaError:
			printerr("LUA ERROR in ", f, ": ", r)
			return false
		if f.ends_with("natives.lua"):
			_hook_dispatch()
	lan_session = load("res://scripts/lan_session.gd").new()
	lan_session.name = "LanSession"
	lan_session.host = self
	add_child(lan_session)
	for overlay_path in ["res://scripts/skill_hud.gd", "res://scripts/match_hud.gd", "res://scripts/lan_hud.gd", "res://scripts/planner_hud.gd"]:
		if ResourceLoader.exists(overlay_path):
			var overlay_script = load(overlay_path)
			if overlay_script == null:
				return false
			var overlay = overlay_script.new()
			overlay.host = self
			ui_root.add_child(overlay)
	return true

func _hook_dispatch() -> void:
	_item_animation_fn = lua.do_string("""
		return function(id, animation_name)
			local scene = g_App and g_App.__scene
			if scene and not scene.__lan_client and SceneItemsC and SceneItemsC.OnItemAnimationEnd then
				return SceneItemsC.OnItemAnimationEnd(scene, id, animation_name)
			end
			return false
		end
	""")
	if not scene_view.item_animation_finished.is_connected(_on_item_animation_finished):
		scene_view.item_animation_finished.connect(_on_item_animation_finished)
	var skill = lua.do_string("return function() return NativeKeySkill() end")
	if skill != null:
		scene_view.on_skill = func():
			var result = skill.invoke()
			if result is LuaError:
				_tick_errors += 1
				printerr("LUA ERROR in skill input: ", result)
	# Manual trace-back stays unbound; Space now shares selected active skill input.
	var kd = lua.globals.get("NativeKeyDir")
	if kd != null:
		scene_view.on_dir = func(d: int):
			var result = kd.invoke(d)
			if result is LuaError:
				_tick_errors += 1
				printerr("LUA ERROR in direction input: ", result)
	var f = lua.globals.get("NativeWndDispatch")
	if f == null:
		push_warning("NativeWndDispatch not defined by natives")
		return
	GuiRuntime.dispatch = func(node, msg, w_param, l_param):
		var r = f.invoke(node, msg, w_param, l_param)
		if r is LuaError:
			printerr("LUA ERROR in NativeWndDispatch: ", r)
			return null
		return r

func _on_item_animation_finished(id: int, animation_name: String) -> void:
	if _item_animation_fn == null or _item_animation_fn is LuaError:
		return
	var result = _item_animation_fn.invoke(id, animation_name)
	if result is LuaError:
		_tick_errors += 1
		printerr("LUA ERROR in item animation callback: ", result)

func _exit_tree() -> void:
	# Static GUI dispatch must release its LuaFunction before GDExtension
	# shutdown. Keeping it alive until static cleanup caused an access violation.
	GuiRuntime.dispatch = Callable()
	if is_instance_valid(scene_view):
		scene_view.on_dir = Callable()
		scene_view.on_trace = Callable()
		scene_view.on_skill = Callable()
		if scene_view.item_animation_finished.is_connected(_on_item_animation_finished):
			scene_view.item_animation_finished.disconnect(_on_item_animation_finished)
	_tick_fn = null
	_item_animation_fn = null

func _process(delta: float) -> void:
	if lua == null:
		return
	if _tick_fn == null:
		_tick_fn = lua.globals.get("NativeTickUpdate")
	if _tick_fn != null:
		var _t0 := Time.get_ticks_usec()
		# Retain fractional milliseconds: truncating each 60 Hz frame to 16 ms
		# would turn a four-minute countdown into roughly four minutes ten seconds.
		_tick_ms_remainder += delta * 1000.0
		var elapsed_ms := int(floor(_tick_ms_remainder + 0.000001))
		_tick_ms_remainder -= elapsed_ms
		var r = _tick_fn.invoke(elapsed_ms)
		Prof.add("lua_tick", _t0)
		if r is LuaError:
			_tick_errors += 1
			if _tick_errors <= 3:
				printerr("LUA ERROR in NativeTickUpdate: ", r)

func call_global(fn: String, args: Array = []) -> Variant:
	var f = lua.globals.get(fn)
	if f == null:
		return null
	var r = f.invokev(args)
	if r is LuaError:
		printerr("LUA ERROR in ", fn, ": ", r)
	return r

func _register_core() -> void:
	var g: LuaTable = lua.globals
	g["GetGammaTime"] = func() -> int: return Time.get_ticks_msec()
	g["GetNatureTime"] = func() -> int: return int(Time.get_unix_time_from_system() * 1000.0)
	g["BitAnd"] = func(a: int, b: int) -> int: return a & b
	g["BitOr"] = func(a: int, b: int) -> int: return a | b
	g["BitNot"] = func(a: int) -> int: return ~a
	g["LeftShift"] = func(a: int, b: int) -> int: return a << b
	g["RightShift"] = func(a: int, b: int) -> int: return a >> b
