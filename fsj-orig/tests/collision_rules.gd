extends Node
# Controlled fixtures in the real offline host. Native evidence is documented in
# docs/碰撞死亡核对-2026-10-25.md; this is not a recording of the original game.
var host: LuaHost
var checks := 0
var failures: Array[String] = []
var screenshot_path := ""

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)
		printerr("COLLISION RULES FAIL: ", detail)

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

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="): screenshot_path = arg.substr(7)
	var ui := Control.new()
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	check(host.start(ui), "host starts")
	lua("math.randomseed(25);require 'start_game'")
	await frames(90)
	lua("g_App:GetLoginFrame():ConnectWorld()")
	await frames(150)
	lua("SceneMatch.Start()")
	await frames(35)
	host.set_process(false)
	check(lua("return g_App.__scene.__limit") == 240000, "four-minute default")
	lua("""
		local sc=g_App.__scene;sc.__planner_pause_ai=true
		sc.__death_report_path='user://collision_rules_death.json'
		-- Use two real player identities/callbacks and the real capture path.
		-- Reset board/roster between cases; retain the director's original UI.
		function CollisionFixture(headMode)
		 local a=sc.__order[1];local b=sc.__order[2]
		 for i=3,#sc.__order do sc.__order[i].__alive=false;SceneSim.sync_player(sc.__order[i]) end
		 sc.__order={a,b};sc.__players={[a.__objectID]=a,[b.__objectID]=b}
		 sc.__byManor={[a.__manor.manorID]=a,[b.__manor.manorID]=b}
		 sc.__match_respawns={};sc.__firstKillDone=false
		 for idx=0,sc.__W*sc.__H-1 do SceneSim.set_cell(sc,idx,0,0);SceneSim.set_val(sc,idx,0) end
		 for _,p in ipairs(sc.__order) do
		  p.__alive=true;p.__trail={};p.__trailUnder={};p.__segStart=1
		  p.__manor.count=0;p.__kills=0;p.__deaths=0;p.__battle_kills={};p.__battle_deaths={}
		  p.__skill_effects={};p.__skill_extra_speed=0;p.__skill_extra_until=0
		  p.__skill_cooldowns={};p.__last_death=nil;p.__b_frozen=false;p.__b_settlement=nil
		  p.__stats.killCount=0;p.m_bJustDie=false
		  SceneSkills.RefreshModifiers(p)
		 end
		 local function own(x,y,p)
		  SceneSim.set_cell(sc,y*sc.__W+x,p.__manor.manorID,0);p.__manor.count=p.__manor.count+1
		 end
		 for y=20,24 do for x=20,24 do
		  if x==20 or x==24 or y==20 or y==24 then own(x,y,a) end
		 end end
		 local gap=20*sc.__W+22
		 SceneSim.set_cell(sc,gap,0,a.__objectID);a.__manor.count=a.__manor.count-1
		 a.__trail={gap};a.__trailUnder={[gap]=0}
		 own(22,22,b);own(60,60,b)
		 a.__x,a.__y=21.5*16,20.5*16
		 b.__x,b.__y=60.5*16,60.5*16
		 if headMode=='home' then b.__x,b.__y=22.5*16,22.5*16 end
		 if headMode=='empty' then b.__x,b.__y=21.5*16,22.5*16 end
		 SceneSim.sync_player(a);SceneSim.sync_player(b)
		 return a,b,gap
		end
		function CollisionClose() SceneSim.enter_node(sc,sc.__order[1],21,20) end
	""")
	# Must fail on v0.7.1: stealing the occupied home cell leaves the head alive.
	lua("local a,b=CollisionFixture('home');CollisionClose()")
	check(lua("return not g_App.__scene.__order[2].__alive") == true, "capture of occupied enemy home cell kills before total territory loss")
	check(lua("local d=g_App.__scene.__order[2].__last_death;return d and d.reason") == "capture", "occupied-cell capture has its own cause")
	check(lua("return g_App.__scene.__order[1].__kills") == 1, "capture awards exactly one kill")
	check(lua("return g_App.__scene.__order[2].__manor.count") == 0, "death removes remaining remote territory")
	check(lua("local sc=g_App.__scene;return sc.__owner[22*sc.__W+22]==sc.__order[1].__manor.manorID") == true, "captured cell remains owned by captor after victim cleanup")
	check(lua("local sc=g_App.__scene;return sc.__owner[60*sc.__W+60]") == 0, "uncaptured remote territory clears on death")
	check(lua("local sc=g_App.__scene;return SceneMatch.RespawnRemaining(sc,sc.__order[2])") == 3000, "capture uses existing local three-second respawn")
	check(lua("local sc=g_App.__scene;return SceneMatch.Respawn(sc,sc.__order[2]) and sc.__order[2].__alive") == true, "captured player can respawn normally")
	# Capture is not a new blanket kill for every head or line inside a polygon.
	lua("local a,b=CollisionFixture('empty');CollisionClose()")
	check(lua("return g_App.__scene.__order[2].__alive") == true, "head on neutral enclosed cell does not trigger occupied-home condition")
	check(lua("return g_App.__scene.__order[2].__manor.count") == 1, "remote manor count remains exact")
	lua("local a,b=CollisionFixture();local sc=g_App.__scene;local idx=22*sc.__W+21;b.__trail={idx};b.__trailUnder={[idx]=0};SceneSim.set_cell(sc,idx,0,b.__objectID);CollisionClose()")
	check(lua("return g_App.__scene.__order[2].__alive") == true, "unresolved distant enclosure policy is preserved")
	check(lua("local sc=g_App.__scene;return sc.__trail[22*sc.__W+21]==sc.__order[2].__objectID") == true, "enclosed route remains collidable")
	lua("local sc=g_App.__scene;SceneSim.enter_node(sc,sc.__order[1],21,22)")
	check(lua("return g_App.__scene.__order[2].__last_death.reason") == "trail", "actual remote line contact remains a trail kill")
	check(lua("return g_App.__scene.__order[2].__deaths") == 1, "remote route cut is counted once")
	# Complete loss remains explicitly a local policy, separate from head capture.
	lua("local a,b=CollisionFixture();local sc=g_App.__scene;SceneSim.set_cell(sc,60*sc.__W+60,0,0);b.__manor.count=1;CollisionClose()")
	check(lua("return g_App.__scene.__order[2].__last_death.reason") == "territory", "full territory loss retains its distinct local cause")
	# Armor blocks body contact, not the proven non-collision capture branch.
	lua("local a,b=CollisionFixture('home');SceneSkills.Use(b,5,1);CollisionClose()")
	check(lua("return g_App.__scene.__order[2].__last_death.reason") == "capture", "shield does not grant unproven capture immunity")
	# Concrete -> CManorLine::Concrete -> AddManorUnit uses the same condition.
	lua("local a,b=CollisionFixture('home');local sc=g_App.__scene;local idx=22*sc.__W+22;a.__trail={idx};a.__trailUnder={[idx]=0};SceneSim.set_cell(sc,idx,nil,a.__objectID);SceneSkills.ConcreteLine(a)")
	check(lua("return g_App.__scene.__order[2].__last_death.reason") == "capture", "concrete uses the shared occupied-cell rule")
	check(lua("return g_App.__scene.__order[1].__kills") == 1, "concrete capture is counted once")
	lua("local a,b=CollisionFixture();local sc=g_App.__scene;b.__x,b.__y=a.__x+8,a.__y;SceneSim.sync_player(b);sc:Update(0)")
	check(lua("local sc=g_App.__scene;return sc.__order[1].__alive and sc.__order[2].__alive") == true, "plain head contact does not invent a body kill")
	lua("local sc=g_App.__scene;SceneSkills.Use(sc.__order[2],5,1);sc:Update(0)")
	check(lua("return g_App.__scene.__order[1].__last_death.reason") == "body", "existing local shield contact remains distinguishable")
	check(lua("return g_App.__scene.__order[2].__alive") == true, "shield owner survives local body contact")
	lua("local a,b=CollisionFixture();local sc=g_App.__scene;sc:Update(100)")
	check(lua("local sc=g_App.__scene;return sc.__order[1].__alive and sc.__order[2].__alive") == true, "ordinary movement without contact does not cause death")
	# Close the same gap through the actual keyboard -> original input ->
	# movement callback, instead of calling enter_node directly.
	lua("local a,b=CollisionFixture('home');a.__x,a.__y=22.5*16,20.5*16;a.__a_request_dir=nil;SceneSim.sync_player(a)")
	key(KEY_LEFT)
	await frames(1)
	check(lua("return g_App:GetDirector().__dir") == 1, "real left-arrow input reaches director")
	lua("for _=1,4 do g_App.__scene:Update(100) end")
	check(lua("local d=g_App.__scene.__order[2].__last_death;return d and d.reason") == "capture", "actual movement closing the loop triggers the proven capture branch")
	# Reverse roles to exercise real director feedback and persisted evidence.
	lua("""
		local a,b=CollisionFixture('home');local sc=g_App.__scene
		sc.m_pDirectorObj=b;g_App:SetDirector(b);b.__nick='本地玩家';a.__nick='圈地者'
		SceneSim.sync_player(a);SceneSim.sync_player(b)
		CollisionClose();SceneBattleHUD.Sync()
	""")
	check(lua("return g_App:GetDirector().__last_death.reason") == "capture", "same rule applies to human director")
	var text = str(lua("return g_App:GetGameMain().m_pWndTyro.m_wndContent:GetWndText()"))
	check(text.contains("脚下领地被圈占") and text.contains("圈地者") and text.contains("3秒后重生"), "original hint distinguishes capture from full territory loss")
	var report = JSON.parse_string(FileAccess.get_file_as_string("user://collision_rules_death.json"))
	check(report is Dictionary and report.get("reason") == "capture" and report.get("source") == "loop", "persisted capture event identifies actual source")
	check(report is Dictionary and int(report.get("contactCell", -1)) == 22 * int(lua("return g_App.__scene.__W")) + 22, "event identifies the exact captured cell")
	check(report is Dictionary and int(report.get("previousOwner", -1)) == int(lua("return g_App:GetDirector().__manor.manorID")), "event identifies previous manor owner")
	if not screenshot_path.is_empty() and DisplayServer.get_name() != "headless":
		await frames(90)
		RenderingServer.force_draw()
		check(get_viewport().get_texture().get_image().save_png(screenshot_path) == OK, "capture actual exported UI")
	check(lua("local sc=g_App.__scene;local p=sc.m_pDirectorObj;local n=p.__deaths;return not SceneSim.kill_player(sc,p,sc.__order[1],false,'capture') and p.__deaths==n") == true, "repeated event cannot award another death")
	lua("SceneMatch.ReturnHome()")
	check(lua("return g_App.__scene==nil") == true, "return to lobby")
	await frames(120) # Pending fly_die callbacks must survive scene teardown.
	check(host._tick_errors == 0, "no native tick errors")
	print("COLLISION RULES ", "PASSED" if failures.is_empty() else "FAILED", ": ", checks, " checks")
	get_tree().quit(0 if failures.is_empty() else 1)
