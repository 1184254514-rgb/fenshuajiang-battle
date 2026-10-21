extends Node
# Endless round -> director death -> walk through the settlement windows by clicking their buttons; screenshots each step.
# Godot --path fsj-orig res://tests/settle_test.tscn (Claude)
var host: LuaHost
var out := "C:/Users/Administrator/Desktop/gpt-collab-gamedev/mod-work/shots/settle_"
var choice := "home"   # --choice=again|home: which settlement button to press
func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--choice="): choice = a.substr(9)
	var ui := Control.new(); add_child(ui)
	host = LuaHost.new(); add_child(host)
	host.start(ui)
	host.lua.do_string("require 'start_game'")
	for i in 90: await get_tree().process_frame
	host.lua.do_string("local f = g_App:GetLoginFrame(); f:ConnectWorld()")
	for i in 150: await get_tree().process_frame
	host.lua.do_string("g_App:EnterRoom(eRT_Endless)")
	for i in 60: await get_tree().process_frame
	# walls and own trail never kill (original behaviour): end the round by killing the director directly
	for i in 120: await get_tree().process_frame
	var kr = host.lua.do_string("local d = g_App:GetDirector() SceneSim.kill_player(g_App.__scene, d, nil, false) return 'killed'")
	print("kill: ", kr)
	for step in 8:
		for i in 120: await get_tree().process_frame
		var shot := out + str(step) + ".png"
		get_viewport().get_texture().get_image().save_png(shot)
		var r = host.lua.do_string("""
			local names = {}
			local function vis(w) return w and w.__node and w.__node:is_visible_in_tree() end
			local wf = g_App.__scene and g_App.__scene:GetWanfa()
			for _, k in ipairs({'m_pWndDieTip','m_pWndBalance','m_pWndBalanceBeyond','m_pResultWnd','m_pRhythmSettWnd','m_pWndModeOpenReward'}) do
				if wf and wf[k] and vis(wf[k]) then names[#names+1] = k end
			end
			return (g_App.__scene and 'scene ' or 'noscene ') .. table.concat(names, ',') .. (vis(g_App:GetGameStart()) and ' HOME' or '')
		""")
		print("STEP ", step, ": ", r)
		# click the first visible button of the top-most settlement window (GDScript side: Lua cannot call _methods)
		for k in ["m_pWndDieTip", "m_pWndBalanceBeyond", "m_pRhythmSettWnd", "m_pResultWnd", "m_pWndBalance", "m_pWndModeOpenReward"]:
			var n = host.lua.do_string("local wf = g_App.__scene and g_App.__scene:GetWanfa() local w = wf and wf['" + k + "'] return w and w.__node")
			if n is Control and (n as Control).is_visible_in_tree():
				var btn := _find_button(n)
				if k == "m_pWndBalance":
					var want := "zailaiyiju" if choice == "again" else "huizhujiemian"
					var f: Node = (n as Node).find_child(want, true, false)
					if f is Control: btn = f
				print("CLICK ", k, " -> ", btn.name if btn else "none")
				if btn: btn.call("_finish_click", btn.size * 0.5)
				break
	get_tree().quit()

func _find_button(n: Node) -> Control:
	for c in n.get_children():
		if c is Control and (c as Control).is_visible_in_tree() and c.has_method("_is_button") and c.call("_is_button"):
			return c
		var r := _find_button(c)
		if r: return r
	return null
