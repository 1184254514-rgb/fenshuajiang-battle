extends Node
var host: LuaHost
var checks:=0
var failures: Array[String]=[]
var shot_prefix:=""
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures.append(message)
		printerr("PLANNER FAIL: ",message)
func lua(source: String):
	var result=host.lua.do_string(source)
	if result is LuaError:
		check(false,str(result))
		return null
	return result
func frames(count: int) -> void:
	for i in count: await get_tree().process_frame
func key(code: Key) -> void:
	for down in [true,false]:
		var event=InputEventKey.new()
		event.keycode=code
		event.pressed=down
		Input.parse_input_event(event)
func click(control: Control) -> void:
	for down in [true,false]:
		var event=InputEventMouseButton.new()
		event.button_index=MOUSE_BUTTON_LEFT
		event.position=control.get_global_rect().get_center()
		event.global_position=event.position
		event.pressed=down
		Input.parse_input_event(event)
func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="): shot_prefix=argument.substr(8)
	var ui=Control.new()
	add_child(ui)
	host=LuaHost.new()
	add_child(host)
	check(host.start(ui),"runtime starts")
	lua("math.randomseed(20261022);require 'start_game'")
	await frames(90)
	var hud=ui.get_node("PlannerHud")
	check(not hud.layer.visible,"planner hidden by default")
	check(hud._settings_path=="user://planner-test-settings.json","tests isolate planner save file")
	key(KEY_F8)
	await frames(3)
	check(hud.layer.visible,"F8 opens planner")
	key(KEY_ESCAPE)
	await frames(3)
	check(not hud.layer.visible,"Escape closes planner")
	key(KEY_F8)
	await frames(3)
	for pair in [["duration_ms",90],["respawn_ms",2],["exp_count",20],["exp_reward",250],["start_exp",600],["cooldown_percent",0]]:
		hud.fields[pair[0]].value=pair[1]
	click(hud.save_button)
	await frames(3)
	check(lua("return ScenePlanner.settings.duration_ms")==90000,"save converts UI seconds to match milliseconds")
	check(FileAccess.file_exists(hud._settings_path),"settings saved on disk")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(hud._settings_path))
	check(saved is Dictionary and saved.exp_reward==250,"saved file contains edited values")
	check(hud._load_settings(),"saved settings can be loaded")
	lua("g_App:GetLoginFrame():ConnectWorld()")
	await frames(150)
	lua("SceneMatch.Start()")
	await frames(35)
	check(lua("return g_App.__scene.__limit")==90000,"next match uses planner duration")
	check(lua("return g_App.__scene.__planner_cfg.respawn_ms")==2000,"next match uses planner respawn delay")
	check(lua("return g_App.__scene.__c_expTarget")==20,"experience target uses planner count")
	check(lua("return g_App:GetDirector().__progress_exp>=600 and g_App:GetDirector().__progress_level>=3")==true,"initial experience upgrades skills at match start")
	check(lua("local p=g_App:GetDirector();local sc=g_App.__scene;local before=p.__progress_exp;local item=SceneItemsC.CreatExpUnit(sc,sc:AllocObjectID(false),{x=p.__x,y=p.__y});item:SetState(2);item:OnCircle(nil,p);return p.__progress_exp==before+250")==true,"crystal rewards use planner value")
	check(lua("local p=g_App:GetDirector();p.__skill_cooldowns={};return SceneSkills.Use(p) and p:GetSkillWaitTime()==0")==true,"zero-percent cooldown is effective")
	hud._refresh(true)
	var before=int(lua("return g_App:GetDirector().__progress_exp"))
	click(hud.actions.add_xp)
	await frames(3)
	check(int(lua("return g_App:GetDirector().__progress_exp"))>=before+1000,"real add-experience button works")
	click(hud.actions.max_xp)
	await frames(3)
	check(lua("return g_App:GetDirector().__skill_level==6")==true,"real max-level button works")
	lua("local p=g_App:GetDirector();p.__skill_cooldowns[p.__skillID]=g_App.__scene.__time+10000")
	click(hud.actions.clear_cd)
	await frames(3)
	check(lua("return g_App:GetDirector():GetSkillWaitTime()==0")==true,"real cooldown reset button works")
	click(hud.actions.pause_ai)
	await frames(3)
	check(lua("return g_App.__scene.__planner_pause_ai")==true,"pause-AI action enabled")
	lua("__planner_ai_pos={};for _,p in ipairs(g_App.__scene.__order) do if p.__ai then __planner_ai_pos[p.__objectID]={p.__x,p.__y} end end")
	await frames(15)
	check(lua("for _,p in ipairs(g_App.__scene.__order) do local pos=__planner_ai_pos[p.__objectID];if pos and (p.__x~=pos[1] or p.__y~=pos[2]) then return false end end;return true")==true,"AI characters actually stop moving")
	click(hud.actions.pause_ai)
	await frames(15)
	check(lua("return not g_App.__scene.__planner_pause_ai")==true,"AI can resume")
	hud.fields.duration_ms.value=120
	click(hud.save_button)
	await frames(3)
	check(lua("return g_App.__scene.__limit")==90000,"saving cannot change current round duration")
	click(hud.actions.restart)
	await frames(35)
	check(lua("return g_App.__scene.__limit")==120000,"restart applies saved duration")
	if not shot_prefix.is_empty() and DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		check(get_viewport().get_texture().get_image().save_png(shot_prefix+"planner.png")==OK,"planner screenshot saved")
	check(lua("local ok=ScenePlanner.ApplyJSON('{}');return ok")==false,"incomplete settings rejected")
	check(lua("local old=ScenePlanner.settings.duration_ms;ScenePlanner.ApplyJSON('{bad');return ScenePlanner.settings.duration_ms==old")==true,"invalid JSON preserves settings")
	click(hud.defaults_button)
	await frames(3)
	check(lua("return ScenePlanner.settings.duration_ms==240000 and ScenePlanner.settings.exp_reward==100 and ScenePlanner.settings.cooldown_percent==100")==true,"default values restored")
	lua("SceneMatch.Finish(g_App.__scene)")
	hud._refresh(false)
	check(hud.actions.add_xp.disabled,"instant actions disabled after match")
	check(host._tick_errors==0,"no Lua UI or simulation errors")
	# Keep test persistence isolated and default-valued for repeatable runs.
	if failures.is_empty(): print("PLANNER FLOW PASSED: ",checks," checks")
	else: printerr("PLANNER FLOW FAILED: ",failures.size()," / ",checks)
	get_tree().quit(0 if failures.is_empty() else 1)
