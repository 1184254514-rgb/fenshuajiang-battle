extends Node
# Runs the shipped UI/input, 10-colour roster, skill, respawn and timeout path.
var host: LuaHost
var checks := 0
var failures: Array[String] = []
var shot_prefix := ""

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)
		printerr("TIMED FLOW FAIL: ", detail)

func lua(source: String):
	var result = host.lua.do_string(source)
	if result is LuaError:
		check(false, str(result))
		return null
	return result

func frames(count: int) -> void:
	for unused in count: await get_tree().process_frame

func key(code: Key) -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = down
		Input.parse_input_event(event)

func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.position = point
		event.global_position = point
		Input.parse_input_event(event)

func screenshot(suffix: String) -> void:
	if shot_prefix.is_empty() or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(shot_prefix + suffix + ".png") == OK, "saved " + suffix)

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="): shot_prefix = argument.substr(8)
	var ui := Control.new()
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	if not host.start(ui):
		check(false, "host starts")
		finish()
		return
	lua("math.randomseed(20261021); require 'start_game'")
	await frames(90)
	var match_hud := ui.get_node_or_null("MatchHud")
	check(match_hud != null, "timed HUD installed")
	if match_hud == null:
		finish()
		return
	check(match_hud.find_child("TimedStartButton", true, false) == null, "extra central match entry removed")
	var skill_hud := ui.get_node("SkillHud")
	check(not skill_hud.get("_menu_layer").visible, "skill menu hidden during login")
	lua("g_App:GetLoginFrame():ConnectWorld()")
	await frames(150)
	var self_entry := lua("return g_App:GetGameStart().m_pBtnEndless.__node") as Control
	check(self_entry != null and self_entry.is_visible_in_tree(), "original self entry available")
	check(not skill_hud.get("_menu_layer").visible, "lobby skill settings hidden by default")
	await screenshot("lobby")
	click(lua("return g_App:GetGameStart().m_pBtnSkill.__node") as Control)
	await frames(12)
	check(skill_hud.get("_menu_layer").visible, "bottom skill button opens configuration")
	var active := skill_hud.find_child("ActiveSkillSelector", true, false) as OptionButton
	var skill_index := active.get_item_index(2)
	active.select(skill_index)
	active.item_selected.emit(skill_index)
	await frames(12)
	check(lua("return SceneSkills.selected") == 2, "configuration changes equipped skill")
	await screenshot("skills")
	click(skill_hud.find_child("CloseSkillMenuButton", true, false) as Button)
	await frames(12)
	check(not skill_hud.get("_menu_layer").visible, "close button dismisses configuration")
	click(self_entry)
	await frames(45)
	check(lua("return g_App.__scene.__timed_match") == true, "lobby button starts timed match")
	check(lua("return g_App.__scene.__limit") == 240000, "default round lasts four minutes")
	check(lua("return #g_App.__scene.__order") == 10, "ten fixed competitors spawn")
	check(lua("local seen={}; for _,p in ipairs(g_App.__scene.__order) do if seen[p.__manor.colorID] then return false end; seen[p.__manor.colorID]=true end; return true") == true, "all competitors have distinct colours")
	check(match_hud.get("_clock_panel").visible, "countdown displayed")
	check(lua("return g_App:GetDirector().__skillID") == 2, "lobby skill selection applied")
	lua("__timed_clock_before=g_App.__scene.__time")
	await frames(60)
	check(lua("return math.abs(g_App.__scene.__time-__timed_clock_before-1000) <= 1") == true, "four-minute clock preserves fractional frame milliseconds")
	# Lay an open route in empty edge cells without closing any region.
	lua("""
		local sc=g_App.__scene; local d=g_App:GetDirector()
		for x=2,6 do local i=sc.__W+x; if sc.__owner[i]==0 and sc.__trail[i]==0 then SceneSim.enter_node(sc,d,x,1) end end
		__timed_area_before=d.__manor.count; __timed_route_before=#d.__trail
	""")
	check(lua("return __timed_route_before >= 5") == true, "open route prepared")
	key(KEY_Q)
	await frames(1)
	check(lua("return #g_App:GetDirector().__trail") == 0, "Q triggers original concrete-line skill")
	check(lua("return g_App:GetDirector().__manor.count >= __timed_area_before + __timed_route_before") == true, "skill claims existing route without needing a loop")
	check(lua("return g_App:GetDirector():GetSkillWaitTime(2) > 0") == true, "skill cooldown starts")
	check(lua("local p=g_App:GetDirector(); return not p:UseSkill(2)") == true, "cooldown prevents repeated cast")
	await frames(8)
	await screenshot("playing")
	# Every identity should respawn rather than ending this round early.
	lua("""
		local sc=g_App.__scene; local d=g_App:GetDirector()
		__timed_id=d.__objectID; __timed_colour=d.__manor.colorID
		__timed_before_count=#sc.__order
		SceneScore.SetProperty(d,SceneScore.SPT.KILLS,7,false); d.__stats.killCount=7; d.__kills=7
		SceneSim.kill_player(sc,d,nil,false)
	""")
	check(lua("return not g_App:GetDirector().__alive") == true, "director can be eliminated")
	check(lua("return not SceneMatch.IsFinished(g_App.__scene)") == true, "death does not finish timed match")
	await frames(100)
	check(lua("return not g_App:GetDirector().__alive") == true, "respawn does not happen before three seconds")
	await frames(105)
	check(lua("return g_App:GetDirector().__alive") == true, "director respawns after three seconds")
	check(lua("return g_App:GetDirector().__objectID == __timed_id and g_App:GetDirector().__manor.colorID == __timed_colour") == true, "respawn preserves identity and colour")
	check(lua("return #g_App.__scene.__order == __timed_before_count") == true, "respawn does not duplicate roster")
	check(lua("return g_App:GetDirector().__kills == 7 and g_App:GetDirector().__stats.killCount == 7") == true, "respawn preserves kill history")
	check(lua("return g_App:GetDirector().__c_inScene") == true, "respawn restores native scene membership")
	# Shorten only this test's remaining duration, then cross the deadline.
	lua("local sc=g_App.__scene; sc.__limit=sc.__time-sc.__match_started_at+1")
	await frames(2)
	check(lua("return SceneMatch.IsFinished(g_App.__scene)") == true, "exact timeout finishes match")
	check(lua("return g_App.__scene:GetTimeRemain()") == 0, "countdown clamps to zero")
	await frames(10)
	check(match_hud.get("_finish_layer").visible, "final standings are visible")
	lua("__timed_frozen_time=g_App.__scene.__time; __timed_frozen_item_time=g_App.__scene.__c_time; __timed_x=g_App:GetDirector().__x; __timed_y=g_App:GetDirector().__y")
	key(KEY_LEFT)
	key(KEY_SPACE)
	await frames(30)
	check(lua("return g_App.__scene.__time == __timed_frozen_time and g_App.__scene.__c_time == __timed_frozen_item_time") == true, "world and item clocks freeze after timeout")
	check(lua("local p=g_App:GetDirector(); return p.__x==__timed_x and p.__y==__timed_y") == true, "post-timeout input cannot move director")
	check(lua("return #SceneMatch.Results(g_App.__scene)") == 10, "final standings include all competitors")
	await screenshot("results")
	var rematch := match_hud.find_child("RematchButton", true, false) as Button
	check(rematch != null, "rematch button exists")
	if rematch != null: click(rematch)
	await frames(35)
	check(lua("return g_App.__scene.__started and not g_App.__scene.__match_finished") == true, "rematch creates an active fresh round")
	check(lua("return #g_App.__scene.__order") == 10, "rematch roster contains no stale identities")
	check(skill_hud != null, "skill controls installed")
	if skill_hud != null:
		var cast := skill_hud.find_child("CastSkillButton", true, false) as Button
		check(cast != null and cast.visible and not cast.disabled, "fresh round skill button is available")
		if cast != null: click(cast)
		await frames(1)
		check(lua("return g_App:GetDirector():GetSkillWaitTime(2)>0") == true, "mouse click activates skill through the real UI")
	lua("SceneMatch.Finish(g_App.__scene)")
	await frames(10)
	var home := match_hud.find_child("MatchHomeButton", true, false) as Button
	check(home != null, "home button exists")
	if home != null: click(home)
	await frames(20)
	check(lua("return g_App.__scene == nil") == true, "return home releases match")
	check(self_entry.is_visible_in_tree(), "original lobby entry returns")
	check(not skill_hud.get("_menu_layer").visible, "skill menu remains closed on return home")
	check(host._tick_errors == 0, "no Lua input, tick or UI errors")
	finish()

func finish() -> void:
	if failures.is_empty(): print("TIMED FLOW PASSED: ", checks, " checks")
	else: printerr("TIMED FLOW FAILED: ", failures.size(), " / ", checks)
	get_tree().quit(0 if failures.is_empty() else 1)
