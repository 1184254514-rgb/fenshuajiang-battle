extends Node
# Controlled collisions inside the real original UI. These validate the local
# adapter and its feedback, not parity with an unavailable original gameplay run.
var host: LuaHost
var checks := 0
var failures: Array[String] = []
var screenshot_path := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("DEATH AUDIT FAIL: ", message)

func lua(code: String):
	var result = host.lua.do_string(code)
	if result is LuaError:
		check(false, str(result))
		return null
	return result

func frames(count: int) -> void:
	for unused in count: await get_tree().process_frame

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): screenshot_path = arg.substr(7)
	var ui := Control.new()
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	check(host.start(ui), "runtime starts")
	lua("math.randomseed(24);require 'start_game'")
	check(lua("local n=0;local t={};function t:OnTick() n=n+1;CGameAppClient.UnRegister(nil,self);CGameAppClient.Register(nil,self,3000) end;CGameAppClient.Register(nil,t,3000);NativeTickUpdate(10000);CGameAppClient.UnRegister(nil,t);return n==1") == true, "long startup frame cannot endlessly re-run a restarted timer")
	await frames(90)
	lua("g_App:GetLoginFrame():ConnectWorld()")
	await frames(150)
	lua("SceneMatch.Start()")
	await frames(35)
	host.set_process(false)
	check(lua("return g_App.__scene.__limit") == 240000, "default remains four minutes")
	lua("""
		local sc=g_App.__scene;sc.__planner_pause_ai=true
		sc.__death_report_path='user://death_audit_test.json'
		local p=sc.m_pDirectorObj;local enemy=sc.__order[2]
		enemy.__nick='切线者';enemy.__x=328;enemy.__y=328
		SceneSim.sync_player(enemy)
		local idx=20*sc.__W+20
		p.__trail={idx};p.__trailUnder={[idx]=0}
		SceneSim.set_cell(sc,idx,nil,p.__objectID)
		SceneSim.enter_node(sc,enemy,20,20)
		SceneBattleHUD.Sync()
	""")
	check(lua("return not g_App:GetDirector().__alive") == true, "actual distant-line contact kills its owner")
	check(lua("return g_App:GetDirector().__last_death.reason") == "trail", "line contact has an explicit cause")
	check(lua("return g_App:GetDirector().__last_death.headDistance>32") == true, "opponent can be far from the player's head")
	check(lua("return g_App:GetDirector().__last_death.trailContactDistance") == 0, "report proves contact with the line")
	check(lua("return g_App:GetGameMain().m_pWndTyro:IsShow()") == true, "original hint window displays death feedback")
	var text = lua("return g_App:GetGameMain().m_pWndTyro.m_wndContent:GetWndText()")
	check(str(text).contains("路线被切断") and str(text).contains("切线者") and str(text).contains("3秒后重生"), "hint identifies cause, opponent and respawn")
	var report = JSON.parse_string(FileAccess.get_file_as_string("user://death_audit_test.json"))
	check(report is Dictionary and report.get("reason") == "trail" and float(report.get("trailContactDistance", -1)) == 0, "saved event matches actual collision")
	check(lua("local sc=g_App.__scene;local p=sc.m_pDirectorObj;local n=p.__deaths;return not SceneSim.kill_player(sc,p,sc.__order[2],true,'trail') and p.__deaths==n") == true, "duplicate death is rejected")
	if not screenshot_path.is_empty() and DisplayServer.get_name() != "headless":
		# Let the authored transient death flash finish before inspecting text.
		await frames(90)
		RenderingServer.force_draw()
		var respawn_label := ui.find_child("MatchRespawn", true, false) as Control
		check(respawn_label != null and not respawn_label.is_visible_in_tree(), "original notice replaces duplicate custom respawn text")
		check(get_viewport().get_texture().get_image().save_png(screenshot_path) == OK, "captured actual original hint")
	lua("for _=1,30 do NativeTickUpdate(100) end;SceneBattleHUD.Sync()")
	check(lua("return g_App:GetDirector().__alive") == true, "normal three-second respawn completes")
	check(lua("return not g_App:GetGameMain().__death_notice") == true, "death notice clears on respawn")
	lua("SceneSim.kill_player(g_App.__scene,g_App:GetDirector(),nil,false);SceneBattleHUD.Sync()")
	check(lua("return g_App:GetDirector().__last_death.reason") == "unknown", "missing cause remains unknown")
	check(str(lua("return g_App:GetGameMain().m_pWndTyro.m_wndContent:GetWndText()")).contains("死亡原因待核对"), "unknown death does not falsely claim territory loss")
	lua("SceneMatch.Respawn(g_App.__scene,g_App:GetDirector());SceneSim.kill_player(g_App.__scene,g_App:GetDirector(),g_App.__scene.__order[2],false,'territory');SceneBattleHUD.Sync()")
	check(str(lua("return g_App:GetGameMain().m_pWndTyro.m_wndContent:GetWndText()")).contains("领地被全部占完"), "territory cause has its own feedback")
	lua("SceneMatch.Respawn(g_App.__scene,g_App:GetDirector());SceneSim.kill_player(g_App.__scene,g_App:GetDirector(),g_App.__scene.__order[2],true,'body');SceneBattleHUD.Sync()")
	check(str(lua("return g_App:GetGameMain().m_pWndTyro.m_wndContent:GetWndText()")).contains("撞到护盾"), "body cause has its own feedback")
	lua("SceneMatch.ReturnHome()")
	check(lua("return g_App.__scene==nil") == true, "return to lobby releases the scene")
	check(host._tick_errors == 0, "no Lua tick errors")
	print("DEATH AUDIT ", "PASSED" if failures.is_empty() else "FAILED", ": ", checks, " checks")
	get_tree().quit(0 if failures.is_empty() else 1)
