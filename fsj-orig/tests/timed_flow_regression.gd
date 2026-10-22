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
	# The release deliberately opens its LAN lobby. Close it through the same
	# button a single-player user uses before testing the offline lobby clicks.
	var lan_hud := ui.get_node_or_null("LanHud")
	if lan_hud != null and bool(lan_hud.get("opened")):
		click(lan_hud.get("close_button") as Control)
		await frames(12)
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
	# The original calendar can show a season reminder on particular dates.
	var season_close := lua("return g_App:GetGameStart().m_pWndNewSeasonComing.m_pBtnOK.__node") as Control
	if season_close != null and season_close.is_visible_in_tree():
		click(season_close)
		await frames(5)
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
	check(lua("return g_App:GetGameMain():GetDlgChild('W_youxishijian'):IsShow()") == true, "APK countdown displayed")
	check(lua("return g_App:GetDirector().__skillID") == 2, "lobby skill selection applied")
	lua("__timed_clock_before=g_App.__scene.__time")
	await frames(60)
	check(lua("return math.abs(g_App.__scene.__time-__timed_clock_before-1000) <= 1") == true, "four-minute clock preserves fractional frame milliseconds")
	# The real pickup handler must consume a crystal once and increase both
	# level properties and the actual skill row, not only its label.
	check(lua("return g_App.__scene.__c_expLive>0") == true,"timed round spawns experience crystals")
	lua("""
		local p=g_App:GetDirector();local sc=g_App.__scene
		SceneItemsC.SetExp(p,199)
		__xp_item=SceneItemsC.CreatExpUnit(sc,sc:AllocObjectID(false),{x=p.__x,y=p.__y})
		__xp_item:SetState(2)
		SceneItemsC.CheckItem(p,{left=p.__x,top=p.__y,right=p.__x+1,bottom=p.__y+1})
	""")
	check(lua("return g_App:GetDirector():GetSimple32Property(eSPT32_Exp)>=299") == true,"crystal pickup credits experience")
	check(lua("local p=g_App:GetDirector();local before=p.__progress_exp;__xp_item:OnCircle(nil,p);return p.__progress_exp==before") == true,"removed crystal cannot grant duplicate XP")
	check(lua("return __xp_item.__c_removeReason=='pickup'") == true,"picked crystal is removed exactly once")
	check(lua("return g_App:GetDirector():GetSimple32Property(eSPT32_Level)") == 2,"200 XP boundary raises character to level two")
	check(lua("return g_App:GetDirector().__skill_level") == 2,"active skill follows original match-level map")
	check(lua("return g_App:GetDirector().__skill_passive_levels[1]") == 1,"passive retains original slower level map")
	lua("SceneItemsC.SetExp(g_App:GetDirector(),600)")
	await frames(2)
	check(lua("return g_App:GetDirector().__skill_passive_levels[1]") == 2,"passive upgrades at its own threshold")
	check(lua("return g_App:GetGameMain().m_wndExpProgress:IsShow()") == true,"original XP progress control is visible")
	check(lua("return g_App:GetGameMain().m_wndExpProgress:GetWndText()") == "3","original XP control displays actual character level")
	lua("SceneItemsC.SetExp(g_App:GetDirector(),9000)")
	await frames(2)
	check(lua("return g_App:GetDirector().__skill_level==6 and g_App:GetDirector().__skill_passive_levels[1]==6") == true,"maximum XP activates original level-six rows")
	check(lua("return g_App:GetGameMain().m_pGameButton:GetDlgChild('B_jineng.dengji'):GetWndText()==g_App:GetString('levelmax')") == true,"original skill label displays MAX")
	await screenshot("upgraded")
	check(lua("return (g_App:GetDirector().__skill_mods or {})[19]") == 6000,"level-six killer passive applies original 6000 modifier")
	lua("local p=g_App:GetDirector();p.__skillID=1;SceneProgression.Refresh(p);__upgrade_base=p:GetAddSpeed();SceneSkills.Use(p,1)")
	check(lua("return g_App:GetDirector().__skill_extra_speed") == 1800,"upgraded dash uses original level-six effect strength")
	lua("g_App:GetDirector().__skillID=2;SceneItemsC.SetExp(g_App:GetDirector(),0)")
	await frames(8)
	check(lua("return (g_App:GetDirector().__skill_mods or {})[19]") == 1000,"new match-level one passive restores base modifier")
	check(lua("local c=CPlayerLevelConfig:Inst();return c:GetLevel(199)==1 and c:GetLevel(200)==2 and c:GetLevel(599)==2 and c:GetLevel(600)==3 and c:GetLevel(9000)==10 and c:GetLevel(999999)==10") == true,"XP thresholds are inclusive and clamp at ten")
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
	check(match_hud.find_child("MatchClockPanel",true,false)==null, "custom clock panel is replaced by the APK clock")
	check(lua("return g_App:GetGameMain().m_pGameButton.m_pBtnSkill.__hud_skill") == 2, "APK active button uses selected skill")
	check(lua("return g_App:GetGameMain().m_pGameButton.m_tblWndPassive[1].__hud_skill") == 101, "APK passive slot shows equipped skill")
	check(lua("return g_App:GetGameMain().m_pWndTaskTips:IsShow()") == false, "absent daily task cannot show giant empty banner")
	check(lua("return g_App:GetGameMain():GetDlgChild('shengyushijian'):IsShow()") == false,"APK Start hides unused remaining-time banner")
	check(lua("return g_App:GetGameMain():GetDlgChild('W_xinhao'):IsShow()") == false,"offline play shows no fake network signal")
	var original_clock := lua("return g_App:GetGameMain().m_pWndGameTime.__node") as Control
	check(original_clock != null and original_clock.get_global_rect().position == Vector2(886,0), "countdown uses exact APK position")
	check(str(lua("return g_App:GetGameMain().m_pWndGameTime:GetWndText()")).begins_with("03:"), "APK countdown displays four-minute remaining time")
	await screenshot("playing")
	# Every identity should respawn rather than ending this round early.
	lua("""
		local sc=g_App.__scene; local d=g_App:GetDirector()
		__timed_id=d.__objectID; __timed_colour=d.__manor.colorID
		__timed_before_count=#sc.__order
		SceneScore.SetProperty(d,SceneScore.SPT.KILLS,7,false); d.__stats.killCount=7; d.__kills=7
		SceneItemsC.SetExp(d,600);SceneSim.kill_player(sc,d,nil,false)
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
	check(lua("return g_App:GetDirector().__progress_exp>=600 and g_App:GetDirector().__skill_level==2 and g_App:GetDirector().__skill_passive_levels[1]==2") == true,"low-level respawn keeps XP and recomputes skills")
	check(lua("local p=g_App:GetDirector();SceneItemsC.SetExp(p,9000);SceneProgression.OnRespawn(p);return p.__progress_exp==4500 and p.__progress_level==7 and p.__skill_level==5") == true,"higher-level rebirth follows original XP ratio")
	check(lua("return g_App:GetDirector().__c_inScene") == true, "respawn restores native scene membership")
	lua("""
		local sc=g_App.__scene;local d=sc.m_pDirectorObj
		local a,b=sc.__order[2],sc.__order[3]
		a.__nick='同名画匠';b.__nick='同名画匠'
		__details_before=#(d.__battle_kills or {})
		SceneSim.kill_player(sc,a,d,true,'trail')
		__details_first=a.__objectID
	""")
	check(lua("local sc=g_App.__scene;local d=sc.m_pDirectorObj;local a=sc.__order[2];local n=d.__battle_kills[#d.__battle_kills].count;return not SceneSim.kill_player(sc,a,d,true,'trail') and d.__battle_kills[#d.__battle_kills].count==n") == true,"duplicate death cannot inflate battle history")
	lua("local sc=g_App.__scene;local a=sc.__order[2];SceneMatch.Respawn(sc,a);SceneSim.kill_player(sc,a,sc.m_pDirectorObj,true,'trail');SceneSim.kill_player(sc,sc.__order[3],sc.m_pDirectorObj,true,'trail')")
	check(lua("local d=g_App:GetDirector();local rows=d.__battle_kills;return #rows==__details_before+2 and rows[#rows-1].count==2 and rows[#rows].count==1 and rows[#rows-1].id~=rows[#rows].id") == true,"same-name opponents remain separate and repeated kills aggregate")
	check(lua("local d=g_App:GetDirector();return d.__battle_deaths[1].id==0 and d.__battle_deaths[1].count>=1") == true,"environment death is recorded without inventing a killer")
	lua("local sc=g_App.__scene;for i=4,7 do SceneSim.kill_player(sc,sc.__order[i],sc.m_pDirectorObj,true,'trail') end")
	# Shorten only this test's remaining duration, then cross the deadline.
	lua("local sc=g_App.__scene; sc.__limit=sc.__time-sc.__match_started_at+1")
	await frames(2)
	check(lua("return SceneMatch.IsFinished(g_App.__scene)") == true, "exact timeout finishes match")
	check(lua("return SceneProgression.SetExp(g_App:GetDirector(),999999)") == false,"finished match rejects further XP grants")
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
	check(match_hud.get("_rows").get_child_count()==10, "APK ranking contains all ten rows")
	check(match_hud.get("_pages")[0].get_node("list").position==Vector2(1,47), "APK ranking uses authored list position")
	click(match_hud.get("_tabs")[1])
	await frames(3)
	check(match_hud.get("_pages")[1].visible and not match_hud.get("_pages")[0].visible, "original personal score tab works")
	check(int(match_hud.get("_pages")[1].get_node("E_benju").get_wnd_text())==int(lua("local d=SceneMatch.SettlementDataJSON();return Host:parse_json(d)['total']")), "score tab reads authoritative totals")
	check(match_hud.get("_detail_rows")[0].get_child_count()>=2,"original kill detail rows are visible")
	check(not match_hud.get("_pages")[1].get_node("kong1").visible,"nonempty kills hide original empty hint")
	check(match_hud.get("_detail_rows")[1].get_child_count()>=1,"original death detail rows include environment cause")
	var detail_scroll: ScrollContainer = match_hud.get("_detail_rows")[0].get_parent()
	detail_scroll.scroll_vertical=10000
	await frames(3)
	check(detail_scroll.scroll_vertical>0,"kill details scroll beyond the first opponents")
	detail_scroll.scroll_vertical=0
	await frames(2)
	await screenshot("score")
	click(match_hud.get("_tabs")[2])
	await frames(3)
	check(match_hud.get("_pages")[2].visible, "original rhythm tab works")
	await screenshot("rhythm")
	click(match_hud.get("_tabs")[0])
	await frames(3)
	check(match_hud.get("_rows").get_child(0).get_node("head/touxiang/EquippedAvatar")!=null,"ranking displays equipped avatar from original atlas")
	await screenshot("results")
	var scroll: ScrollContainer = match_hud.get("_scroll")
	scroll.scroll_vertical=10000
	await frames(3)
	check(scroll.scroll_vertical>0,"all ten ranking rows can be scrolled")
	check(match_hud.get("_rows").get_child(9).get_global_rect().intersects(scroll.get_global_rect()),"last rank is reachable")
	await screenshot("results-bottom")
	var rematch := match_hud.find_child("RematchButton", true, false) as Control
	check(rematch != null, "rematch button exists")
	if rematch != null: click(rematch)
	await frames(35)
	check(lua("return g_App.__scene.__started and not g_App.__scene.__match_finished") == true, "rematch creates an active fresh round")
	check(lua("return #g_App.__scene.__order") == 10, "rematch roster contains no stale identities")
	check(lua("return g_App:GetDirector().__battle_kills==nil and g_App:GetDirector().__battle_deaths==nil") == true,"rematch clears battle detail history")
	check(skill_hud != null, "skill controls installed")
	if skill_hud != null:
		var cast := lua("return g_App:GetGameMain().m_pGameButton.m_pBtnSkill.__node") as Control
		check(cast != null and cast.is_visible_in_tree() and cast.get("enabled"), "fresh round skill button is available")
		if cast != null: click(cast)
		await frames(1)
		check(lua("return g_App:GetDirector():GetSkillWaitTime(2)>0") == true, "mouse click activates skill through the real UI")
		lua("g_App:GetDirector().__skill_cooldowns[2]=nil")
		await frames(2)
		if cast != null:
			for down in [true,false]:
				var touch := InputEventScreenTouch.new()
				touch.index=0
				touch.pressed=down
				touch.position=cast.get_global_rect().get_center()
				Input.parse_input_event(touch)
		await frames(1)
		check(lua("return g_App:GetDirector():GetSkillWaitTime(2)>0") == true,"touch activates original skill button")
	lua("SceneMatch.Finish(g_App.__scene)")
	await frames(10)
	var home := match_hud.find_child("MatchHomeButton", true, false) as Control
	check(home != null, "home button exists")
	if home != null: click(home)
	await frames(20)
	check(lua("return g_App.__scene == nil") == true, "return home releases match")
	check(self_entry.is_visible_in_tree(), "original lobby entry returns")
	check(not skill_hud.get("_menu_layer").visible, "skill menu remains closed on return home")
	# Exercise the original native exit control instead of the removed LAN strip.
	lua("SceneMatch.Start()")
	await frames(35)
	click(lua("return g_App:GetGameMain().m_pBtnClose.__node") as Control)
	await frames(5)
	check(lua("return g_App.m_pMessageBox:IsShow()") == true,"APK exit opens original confirmation")
	click(lua("return g_App.m_pMessageBox.m_tblButton[CMessageBox.OK].__node") as Control)
	await frames(15)
	check(lua("return g_App.__scene==nil") == true,"APK confirmed exit releases timed match")
	check(host._tick_errors == 0, "no Lua input, tick or UI errors")
	finish()

func finish() -> void:
	if failures.is_empty(): print("TIMED FLOW PASSED: ", checks, " checks")
	else: printerr("TIMED FLOW FAILED: ", failures.size(), " / ", checks)
	get_tree().quit(0 if failures.is_empty() else 1)
