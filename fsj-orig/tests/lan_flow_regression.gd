extends Node
var host: LuaHost
var session: Node
var role := "host"
var checks := 0
var failures: Array[String] = []
var started_at := 0
var stage := 0
var stage_time := 0
var saw_dead := false
var saw_alive_again := false
var cast_sent := false
var input_sent := false
var peer_id := 0
var shot_prefix := ""
var shot_taken := false

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures.append(text)
		printerr("LAN FAIL ", role, ": ", text)

func lua(code: String):
	var value = host.lua.do_string(code)
	if value is LuaError:
		check(false, str(value))
		return null
	return value

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		Input.parse_input_event(event)

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=down
		event.position=point
		event.global_position=point
		Input.parse_input_event(event)

func _ready() -> void:
	if "--client" in OS.get_cmdline_user_args(): role = "client"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="): shot_prefix = argument.substr(8)
	var ui := Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	check(host.start(ui), "runtime starts")
	lua("math.randomseed(20261021); require 'start_game'")
	session = host.lan_session
	started_at = Time.get_ticks_msec()
	set_process(true)
	if role == "host": check(session.create_room("房主甲", 27867), "real ENet socket starts")
	else:
		lua("SceneSkills.SetSelected(2,1)")
		check(session.join_room("朋友乙测试", "127.0.0.1", 27867), "real ENet client connects")

func _process(_delta: float) -> void:
	if session == null: return
	var now := Time.get_ticks_msec()
	if now - started_at > 27000:
		check(false, "test deadline: stage %d phase %s errors %d" % [stage, session.phase, host._tick_errors])
		finish()
		return
	if role == "host": host_step(now)
	else: client_step(now)

func host_step(now: int) -> void:
	if stage == 0 and session.members.size() == 2 and not session._pending_login:
		peer_id = int(session.members[1].peer)
		check(session.start_match(), "host starts shared match")
		check(lua("return #g_App.__scene.__order") == 10, "fixed ten competitors")
		check(lua("local n=0;for _,p in ipairs(g_App.__scene.__order) do if p.__net_peer then n=n+1 end end;return n") == 2, "two humans replace two AI slots")
		lua("local sc=g_App.__scene; local p=sc.__order[2]; for x=2,6 do SceneSim.enter_node(sc,p,x,1) end; __lan_test_area=p.__manor.count")
		stage = 1
		stage_time = now
	elif stage == 1 and now - stage_time > 1800:
		check(lua("return g_App.__scene.__order[2].__skillID") == 2, "remote selected skill reaches server")
		check(lua("return g_App.__scene.__order[2]:GetSkillWaitTime(2)>0") == true, "remote Q input casts skill on authority")
		check(lua("return g_App:GetDirector():GetSkillWaitTime(3)==0") == true, "remote input does not control host")
		check(lua("return g_App.__scene.__order[2].__nick") == "朋友乙测试", "UTF-8 nickname preserved")
		check(lua("return g_App.__scene.__order[2].__manor.count>=__lan_test_area+5") == true, "remote concrete skill claims authoritative territory")
		lua("SceneSim.kill_player(g_App.__scene,g_App.__scene.__order[2],nil,false)")
		stage = 2
		stage_time = now
	elif stage == 2 and now - stage_time > 3400:
		check(lua("return g_App.__scene.__order[2].__alive") == true, "remote player respawns on host")
		check(lua("return g_App.__scene.__order[2].__ai==nil and g_App.__scene.__order[2].__skillID==2") == true, "remote identity and loadout survive respawn")
		lua("local sc=g_App.__scene;sc.__limit=sc.__time+1")
		stage = 3
		stage_time = now
	elif stage == 3 and now - stage_time > 900:
		check(session.phase == "finished", "host detects authoritative timeout")
		check(session.start_match(), "host rematches all peers")
		stage = 4
		stage_time = now
	elif stage == 4 and session.members.size() == 1:
		check(lua("return g_App.__scene.__order[2].__ai~=nil and g_App.__scene.__order[2].__net_peer==nil") == true, "departed player taken over by AI")
		session.game_action("leave")
		check(session.phase == "lobby", "host returns to room")
		stage = 5
		stage_time = now
	elif stage == 5 and session.members.size() == 2:
		check(session.start_match(), "rejoined guest starts next match")
		stage = 6
		stage_time = now
	elif stage == 6 and now - stage_time > 1000:
		session.leave_room()
		check(session.phase == "idle", "room shutdown cleans server")
		check(host._tick_errors == 0, "host has no Lua runtime errors")
		stage = 7
		stage_time = now
	elif stage == 7 and now - stage_time > 1200: finish()

func client_step(now: int) -> void:
	if stage == 0 and session.phase == "playing":
		check(session.members.size() == 2, "shared room roster")
		check(lua("return g_App.__scene.m_pDirectorObj.__net_peer") == session.my_id, "camera and local director assigned to own peer")
		check(lua("return g_App:GetDirector().__nick") == "朋友乙测试", "local nickname correct")
		check(lua("return g_App.__scene.__limit") == 240000, "same four-minute duration")
		check(lua("return #g_App.__scene.__order") == 10, "all competitors replicated")
		check(lua("return g_App.__scene.__lan_client") == true, "client uses replica world")
		stage = 1
		stage_time = now
	elif stage == 1:
		if not shot_taken and now - stage_time > 700 and not shot_prefix.is_empty():
			get_viewport().get_texture().get_image().save_png(shot_prefix + "client-playing.png")
			shot_taken = true
		if not input_sent:
			key(KEY_LEFT)
			input_sent = true
		if not cast_sent and now - stage_time > 300:
			var cast := lua("return g_App:GetGameMain().m_pGameButton.m_pBtnSkill.__node") as Control
			check(cast != null and cast.is_visible_in_tree(),"guest sees original APK skill button")
			check(lua("return g_App:GetGameMain().m_pGameButton.m_pBtnSkill.__hud_skill") == 2,"guest APK button uses its own authoritative loadout")
			if cast != null: click(cast)
			cast_sent = true
		var alive = lua("return g_App:GetDirector().__alive")
		if alive == false: saw_dead = true
		elif saw_dead: saw_alive_again = true
		if session.phase == "finished":
			check(saw_dead and saw_alive_again, "remote death and three-second respawn replicated")
			check(lua("return #SceneMatch.Results(g_App.__scene)") == 10, "final results replicated")
			check(lua("return SceneMatch.GetTimeRemain(g_App.__scene)") == 0, "replica countdown ends at zero")
			var snapshot = JSON.parse_string(session.last_snapshot)
			var expected_score := 0
			for result in snapshot.get("results", []):
				if str(result.name) == "朋友乙测试": expected_score = int(result.score)
			check(lua("for _,row in ipairs(SceneMatch.Results(g_App.__scene)) do if row.director then return row.score end end") == expected_score, "final score uses host result snapshot")
			check(session.snapshots_received > 20, "receives continuing world snapshots")
			var director_id := int(lua("return g_App:GetDirector().__objectID"))
			check(int(host.scene_view.actors[director_id].get("cast_spawn_count", 0)) >= 1, "authoritative cast visual reaches guest")
			check(lua("local sc=g_App.__scene;local n=0;for _,p in ipairs(sc.__order) do n=n+p.__manor.count end;local c=0;for _,o in pairs(sc.__owner) do if o~=0 then c=c+1 end end;return n==c") == true, "replica grid matches authoritative territory counts")
			stage = 2
	elif stage == 2 and session.phase == "playing" and session.round_id == 2:
		check(lua("return g_App.__scene.__time<2000 and not g_App.__scene.__match_finished") == true, "rematch resets replica world")
		click(lua("return g_App:GetGameMain().m_pBtnClose.__node") as Control)
		stage=22
		stage_time=now
	elif stage == 22 and now-stage_time>200:
		check(lua("return g_App.m_pMessageBox:IsShow()") == true,"guest APK exit opens original confirmation")
		click(lua("return g_App.m_pMessageBox.m_tblButton[CMessageBox.OK].__node") as Control)
		stage=23
		stage_time=now
	elif stage == 23 and now-stage_time>200:
		check(lua("return g_App.__scene==nil") == true, "guest original exit releases replica")
		stage=3
		stage_time=now
	elif stage == 3 and now - stage_time > 1200:
		check(session.join_room("重返朋友", "127.0.0.1", 27867), "guest can rejoin waiting room")
		stage = 4
	elif stage == 4 and session.phase == "playing":
		check(lua("return g_App:GetDirector().__nick") == "重返朋友", "rejoining uses fresh nickname")
		stage = 5
	elif stage == 5 and session.phase == "idle":
		check(lua("return g_App.__scene==nil") == true, "host shutdown returns guest to lobby")
		check(host._tick_errors == 0, "guest has no Lua runtime errors")
		finish()

func finish() -> void:
	if session.peer != null: session.leave_room()
	if failures.is_empty(): print("LAN FLOW PASSED ", role, ": ", checks, " checks, snapshots ", session.snapshots_received)
	else: printerr("LAN FLOW FAILED ", role, ": ", failures.size(), " / ", checks)
	set_process(false)
	get_tree().quit(0 if failures.is_empty() else 1)
