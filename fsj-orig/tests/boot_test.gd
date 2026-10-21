extends Node
# Loads the original scripts (OnStart runs at load), lets frames pass, optionally saves a screenshot:
#   Godot --path fsj-orig res://tests/boot_test.tscn -- --shot=C:/path/out.png [--frames=60]
func _ready() -> void:
	var shot := ""; var frames := 60; var login := ""; var enter := false; var enter_after := 150; var autopilot := false; var dump_ui := false; var eval_lua := ""
	var timed := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="): shot = a.substr(7)
		elif a.begins_with("--frames="): frames = int(a.substr(9))
		elif a.begins_with("--login="): login = a.substr(8)
		elif a == "--enter": enter = true
		elif a == "--timed": timed = true; enter = true
		elif a == "--dump": dump_ui = true   # print the visible GUI window tree
		elif a.begins_with("--eval="): eval_lua = a.substr(7)   # Lua expression printed at the end
		elif a == "--autopilot": autopilot = true   # the director is driven by SceneAI (for screenshots / soak tests)
	RenderingServer.set_default_clear_color(Color(0.2, 0.2, 0.2))
	var ui := Control.new()
	add_child(ui)
	var host := LuaHost.new()
	add_child(host)
	if not host.start(ui):
		get_tree().quit(1); return
	var r = host.lua.do_string("require 'start_game'")
	if r is LuaError:
		print("REQUIRE FAILED: ", r); _dump(host); get_tree().quit(1); return
	print("REQUIRE OK")
	if login != "":
		for i in 90: await get_tree().process_frame
		r = host.lua.do_string("local f = g_App:GetLoginFrame(); f.m_pInput:SetWndText('" + login + "'); f:ConnectWorld()")
		if r is LuaError: print("LOGIN FAILED: ", r)
	if enter:
		for i in 150: await get_tree().process_frame
		r = host.lua.do_string("SceneMatch.Start()" if timed else "g_App:EnterRoom(eRT_Endless)")
		if r is LuaError: print("ENTER FAILED: ", r)
		if autopilot:
			for i in 5: await get_tree().process_frame
			r = host.lua.do_string("local d = g_App:GetDirector() if d then SceneAI.SetPlayerConfig(d, 1) d.__ai = SceneAI.Think end")
			if r is LuaError: print("AUTOPILOT FAILED: ", r)
	for i in frames: await get_tree().process_frame
	_dump(host)
	var info = host.lua.do_string("local sc = g_App.__scene if not sc then return 'no scene' end local alive, n = 0, 0 for _, p in ipairs(sc.__order) do n = n + 1 if p.__alive then alive = alive + 1 end end local d = g_App:GetDirector() return string.format('players=%d alive=%d time=%d director=%s dpos=%s,%s mycount=%s', n, alive, sc.__time, tostring(d ~= nil), d and d.__x or '-', d and d.__y or '-', d and d.__manor.count or '-')")
	if dump_ui: _dump_tree(ui, 0)
	if eval_lua != "":
		print("EVAL: ", host.lua.do_string("return tostring(" + eval_lua + ")"))
		for i in 40: await get_tree().process_frame   # let the change render before the screenshot
	Prof.totals.clear(); Prof.counts.clear()
	for i in 100: await get_tree().process_frame
	print("PROF(ms/frame): ", Prof.totals.keys().map(func(k): return "%s=%.2f/%d" % [k, Prof.totals[k] / 100000.0, Prof.counts[k] / 100]))
	print("SCENE: ", info, " fps=", Engine.get_frames_per_second())
	print("PERF: draws=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " objs=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		" prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " process_ms=", Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		" nodes=", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var stats = host.lua.do_string("local sc = g_App.__scene if not sc then return '' end local t = {} for _, p in ipairs(sc.__order) do t[#t+1] = string.format('%s:%s n=%d k=%d d=%d', p.__nick or p.__objectID, p.__alive and 'A' or 'x', p.__manor and p.__manor.count or -1, p.__kills or 0, p.__deaths or 0) end return table.concat(t, ' | ')")
	print("PLAYERS: ", stats)
	if shot != "":
		get_viewport().get_texture().get_image().save_png(shot)
		print("saved ", shot)
	get_tree().quit()

func _dump(host: LuaHost) -> void:
	var lst = host.lua.do_string("local t={} for k in pairs(MISSING_NATIVE) do t[#t+1]=k end table.sort(t) return table.concat(t, string.char(10))")
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../mod-work/re/missing_natives.txt"), FileAccess.WRITE)
	f.store_string(str(lst)); f.close()
	print("missing natives: ", str(lst).count(char(10)) + 1)

func _dump_tree(n: Node, d: int) -> void:
	if n is Control:
		var c := n as Control
		if not c.is_visible_in_tree():
			return
		print("  ".repeat(d), c.name, " ", Rect2(c.global_position, c.size), " z=", c.z_index)
	for ch in n.get_children():
		_dump_tree(ch, d + 1)
