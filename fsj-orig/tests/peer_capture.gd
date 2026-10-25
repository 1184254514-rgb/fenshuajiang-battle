extends Node
# Real offline host, controlled geometry. This is not original-game footage.
var host: LuaHost
var checks := 0
var failures: Array[String] = []
var screenshot_path := ""

func check(ok: bool, detail: String) -> void:
	checks += 1
	if not ok:
		failures.append(detail)
		printerr("PEER CAPTURE FAIL: ", detail)

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
	lua("math.randomseed(73);require 'start_game'")
	await frames(90)
	lua("g_App:GetLoginFrame():ConnectWorld()")
	await frames(150)
	lua("SceneMatch.Start()")
	await frames(35)
	host.set_process(false)
	lua("""
		local sc=g_App.__scene;sc.__planner_pause_ai=true
		sc.__death_report_path='user://peer_capture_test.json'
		PeerPlayers={sc.__order[1],sc.__order[2],sc.__order[3],sc.__order[4]}
		for i=5,#sc.__order do SceneSim.connections.Clear(sc,sc.__order[i]);sc.__order[i].__alive=false;SceneSim.sync_player(sc.__order[i]) end
		function PeerFixture()
		 sc.__order=PeerPlayers;sc.__players={};sc.__byManor={};sc.__match_respawns={}
		 sc.__firstKillDone=false
		 for _,p in ipairs(sc.__order) do SceneSim.connections.Clear(sc,p) end
		 for idx=0,sc.__W*sc.__H-1 do SceneSim.set_cell(sc,idx,0,0);SceneSim.set_val(sc,idx,0) end
		 for i,p in ipairs(sc.__order) do
		  sc.__players[p.__objectID]=p;sc.__byManor[p.__manor.manorID]=p
		  p.__alive=true;p.__trail={};p.__trailUnder={};p.__segStart=1;p.__manor.count=0
		  p.__kills=0;p.__deaths=0;p.__battle_kills={};p.__battle_deaths={};p.__last_death=nil
		  p.__stats.killCount=0;p.__skill_effects={};p.__skill_cooldowns={}
		  p.__skill_extra_speed=0;p.__skill_extra_until=0;p.__b_frozen=false;p.__b_settlement=nil
		  p.__a_request_dir=nil;p.__a_motion_target_x=nil;p.__a_motion_target_y=nil
		  p.__x,p.__y=(60+i*3+.5)*16,60.5*16;p.__dir=1
		  p.__nick=i==1 and '圈地者' or ('路线玩家'..i)
		  SceneSkills.RefreshModifiers(p)
		 end
		 local a=sc.__order[1];sc.m_pDirectorObj=a;g_App:SetDirector(a)
		 for y=20,28 do for x=20,28 do
		  if x==20 or x==28 or y==20 or y==28 then PeerOwn(a,x,y) end
		 end end
		 local gap=20*sc.__W+24;SceneSim.set_cell(sc,gap,0,a.__objectID)
		 a.__manor.count=a.__manor.count-1;a.__trail={gap};a.__trailUnder={[gap]=0}
		 a.__x,a.__y=24.5*16,20.5*16
		 for i=2,4 do PeerOwn(sc.__order[i],60+i*3,60) end
		 for _,p in ipairs(sc.__order) do SceneSim.sync_player(p) end
		end
		function PeerOwn(p,x,y)
		 local idx=y*sc.__W+x;SceneSim.set_cell(sc,idx,p.__manor.manorID,0)
		 p.__manor.count=p.__manor.count+1
		end
		function PeerRoute(i,homeX,homeY,dx,dy,length)
		 local p=sc.__order[i];PeerOwn(p,homeX,homeY)
		 for step=1,length do
		  local x,y=homeX+dx*step,homeY+dy*step
		  p.__x,p.__y=(x+.5)*16,(y+.5)*16
		  SceneSim.enter_node(sc,p,x,y,(y-dy)*sc.__W+x-dx)
		 end
		 SceneSim.sync_player(p)
		end
		function PeerClose() SceneSim.enter_node(sc,sc.__order[1],23,20) end
		function PeerAreaMatches()
		 local counts={};for idx=0,sc.__W*sc.__H-1 do
		  local id=sc.__owner[idx];counts[id]=(counts[id] or 0)+1
		 end
		 for _,p in ipairs(sc.__order) do
		  if p.__manor.count~=(counts[p.__manor.manorID] or 0) then return false end
		 end
		 return true
		end
	""")
	check(lua("return g_App.__scene.__limit") == 240000, "four-minute default")
	# All four reciprocal direction flags; each route lies wholly inside.
	for d in [[-1,0,1,2],[1,0,2,1],[0,1,4,8],[0,-1,8,4]]:
		lua("PeerFixture();PeerRoute(2,24,24,%s,%s,2)" % [d[0], d[1]])
		check(lua("return PeerPlayers[2].__linePeer.direction") == d[2], "departure direction " + str(d[2]))
		check(lua("return PeerPlayers[2].__linePeer.reverse") == d[3], "reciprocal direction " + str(d[3]))
		lua("PeerClose()")
		check(lua("local p=PeerPlayers[2];return not p.__alive and p.__last_death.reason=='anchor'") == true, "capturing actual departure kills connected player " + str(d[2]))
		check(lua("return PeerPlayers[1].__kills==1 and PeerPlayers[2].__deaths==1") == true, "one kill/death " + str(d[2]))
		check(lua("local a,b=PeerPlayers[1],PeerPlayers[2];return a.__stats.killCount==1 and a.__battle_kills[1].id==b.__objectID and a.__battle_kills[1].count==1 and b.__battle_deaths[1].id==a.__objectID") == true, "settlement statistics retain actual killer " + str(d[2]))
		check(lua("return PeerPlayers[2].__linePeer==nil and next(g_App.__scene.__manorPeers or {})==nil") == true, "both connection ends clear " + str(d[2]))
		check(lua("return PeerAreaMatches()") == true, "area counts survive peer cleanup " + str(d[2]))
	# A route crosses the whole captured region, but its departure stays outside.
	lua("PeerFixture();PeerRoute(2,30,24,-1,0,8);PeerClose()")
	check(lua("return PeerPlayers[2].__alive and #PeerPlayers[2].__trail==8") == true, "crossing route survives when departure is not claimed")
	check(lua("local sc=g_App.__scene;return sc.__owner[24*sc.__W+24]==PeerPlayers[1].__manor.manorID and sc.__trail[24*sc.__W+24]==PeerPlayers[2].__objectID") == true, "interior route and new territory remain separate layers")
	check(lua("return SceneSim.connections.IsLive(g_App.__scene,PeerPlayers[2].__linePeer)") == true, "unclaimed departure remains connected")
	lua("local sc=g_App.__scene;SceneSim.enter_node(sc,PeerPlayers[1],24,24)")
	check(lua("return PeerPlayers[2].__last_death.reason") == "trail", "actual later contact is a direct trail cut")
	check(lua("local sc=g_App.__scene;return sc.__owner[24*sc.__W+24]==PeerPlayers[1].__manor.manorID") == true, "cut cleanup preserves captor's underlying territory")
	# Adjacent has no implicit link; no flags may be invented from geometry.
	lua("PeerFixture();PeerRoute(2,30,24,-1,0,1);PeerClose()")
	check(lua("return PeerPlayers[2].__alive and PeerPlayers[1].__kills==0") == true, "route beside the boundary does not imply a connection")
	lua("PeerFixture();local sc=g_App.__scene;local b=PeerPlayers[2];local idx=24*sc.__W+24;b.__trail={idx};b.__trailUnder={[idx]=0};SceneSim.set_cell(sc,idx,0,b.__objectID);PeerClose()")
	check(lua("return PeerPlayers[2].__alive") == true, "unlinked injected interior route does not become a fabricated departure")
	# The important distant-head case: departure inside, head and tail outside.
	lua("PeerFixture();PeerRoute(2,24,24,1,0,11);PeerClose()")
	check(lua("local d=PeerPlayers[2].__last_death;return d and d.reason=='anchor' and d.x>28*16") == true, "claimed departure kills even with head outside the polygon")
	check(lua("return PeerPlayers[2].__trail[1]==nil and PeerPlayers[2].__manor.count==0") == true, "outside trail and remote manor clear on peer death")
	check(lua("return PeerAreaMatches()") == true, "distant-head cleanup leaves exact territory counts")
	lua("PeerFixture();PeerRoute(2,24,24,1,0,11);local sc=g_App.__scene;SceneSim.claim_cell(sc,PeerPlayers[2],24*sc.__W+24,0,'loop')")
	check(lua("return PeerPlayers[2].__alive and PeerPlayers[2].__linePeer~=nil") == true, "claiming an already-owned anchor is an early no-op")
	lua("SceneSkills.Use(PeerPlayers[2],5,1);PeerClose()")
	check(lua("return PeerPlayers[2].__last_death.reason") == "anchor", "shield does not invent immunity to native non-collision peer loss")
	# Different connections in one fill must each be processed exactly once.
	lua("PeerFixture();PeerRoute(2,22,24,0,-1,2);PeerRoute(3,26,24,0,-1,2);PeerClose()")
	check(lua("return PeerPlayers[1].__kills==2 and PeerPlayers[2].__deaths==1 and PeerPlayers[3].__deaths==1") == true, "multiple connected players each die once")
	check(lua("return PeerAreaMatches()") == true, "multi-victim cleanup preserves counts")
	lua("local sc=g_App.__scene;local p=PeerPlayers[2];assert(not SceneSim.kill_player(sc,p,PeerPlayers[1],false,'anchor'));SceneSim.claim_cell(sc,PeerPlayers[1],24*sc.__W+22,0,'loop')")
	check(lua("return PeerPlayers[1].__kills==2") == true, "reclaiming/death replay cannot duplicate rewards")
	# Self-intersection retains the prefix and its original departure.
	lua("PeerFixture();PeerRoute(2,24,24,1,0,3);local sc=g_App.__scene;SceneSim.enter_node(sc,PeerPlayers[2],25,24)")
	check(lua("return PeerPlayers[2].__alive and #PeerPlayers[2].__trail==1 and SceneSim.connections.IsLive(g_App.__scene,PeerPlayers[2].__linePeer)") == true, "self rollback keeps prefix connection and does not kill")
	lua("PeerClose()")
	check(lua("return PeerPlayers[2].__last_death.reason") == "anchor", "retained departure can still be captured after rollback")
	# Closing/concretizing a route removes connections before any later claim.
	lua("PeerFixture();PeerRoute(2,24,24,1,0,1);local sc=g_App.__scene;SceneSim.enter_node(sc,PeerPlayers[2],24,24);PeerPlayers[2].__x,PeerPlayers[2].__y=63.5*16,60.5*16;PeerClose()")
	check(lua("return PeerPlayers[2].__alive and PeerPlayers[2].__linePeer==nil") == true, "returned route leaves no stale departure")
	lua("PeerFixture();PeerRoute(2,24,24,1,0,2);SceneSkills.ConcreteLine(PeerPlayers[2]);PeerPlayers[2].__x,PeerPlayers[2].__y=63.5*16,60.5*16;PeerClose()")
	check(lua("return PeerPlayers[2].__alive and PeerPlayers[2].__linePeer==nil") == true, "concrete removes departure without later phantom death")
	lua("PeerFixture();PeerRoute(2,24,24,1,0,11);local sc=g_App.__scene;local a=PeerPlayers[1];SceneSim.set_cell(sc,20*sc.__W+24,0,0);a.__trail={24*sc.__W+24};a.__trailUnder={};SceneSim.set_cell(sc,a.__trail[1],nil,a.__objectID);SceneSkills.ConcreteLine(a)")
	check(lua("local d=PeerPlayers[2].__last_death;return d and d.reason=='anchor' and d.source=='concrete'") == true, "concrete claiming another departure uses native peer condition")
	check(lua("return PeerAreaMatches()") == true, "concrete peer death leaves exact counts")
	lua("local sc=g_App.__scene;assert(SceneMatch.Respawn(sc,PeerPlayers[2]))")
	check(lua("return PeerPlayers[2].__alive and PeerPlayers[2].__linePeer==nil and next(g_App.__scene.__manorPeers or {})==nil") == true, "respawn cannot retain old-life peer flags")
	# Record a real observed-player peer death before switching to the input case.
	lua("PeerFixture();PeerRoute(2,24,24,1,0,11);local sc=g_App.__scene;sc.m_pDirectorObj=PeerPlayers[2];g_App:SetDirector(PeerPlayers[2]);PeerClose()")
	var report = JSON.parse_string(FileAccess.get_file_as_string("user://peer_capture_test.json"))
	check(report is Dictionary and report.get("reason") == "anchor" and report.get("source") == "loop", "observed peer death is persisted with the actual source")
	check(report is Dictionary and int(report.get("contactCell", -1)) == 24 * int(lua("return g_App.__scene.__W")) + 24 and int(report.get("peerDirection", 0)) == 2, "saved report identifies the captured connection")
	check(report is Dictionary and float(report.get("headDistance", 0)) > 100, "saved event preserves the distant head position")
	# Real keyboard input closes the captor's loop, then show the victim's UI.
	lua("PeerFixture();PeerRoute(2,24,24,1,0,11)")
	key(KEY_LEFT)
	await frames(1)
	check(lua("return PeerPlayers[1].__dir") == 1, "actual direction key reaches the original input adapter")
	lua("for _=1,4 do g_App.__scene:Update(100) end")
	check(lua("local d=PeerPlayers[2].__last_death;return d and d.reason=='anchor'") == true, "normal movement closes loop and captures the departure")
	lua("local sc=g_App.__scene;sc.m_pDirectorObj=PeerPlayers[2];g_App:SetDirector(PeerPlayers[2]);SceneBattleHUD.Sync()")
	# Save the same event for verification: the original death happened before
	# the test switched the observed director, so its in-memory report is used.
	check(str(lua("return g_App:GetGameMain().m_pWndTyro.m_wndContent:GetWndText()")).contains("路线连接点被圈占"), "original hint distinguishes peer loss from a direct line cut")
	check(lua("local d=PeerPlayers[2].__last_death;local sc=g_App.__scene;return d.contactCell==24*sc.__W+24 and d.peerLineCell==24*sc.__W+25 and d.peerDirection==2") == true, "death event identifies the exact reciprocal connection")
	if not screenshot_path.is_empty() and DisplayServer.get_name() != "headless":
		await frames(90)
		RenderingServer.force_draw()
		check(get_viewport().get_texture().get_image().save_png(screenshot_path) == OK, "capture actual offline runtime")
	lua("SceneMatch.ReturnHome()")
	await frames(120)
	check(host._tick_errors == 0, "no Lua tick errors through teardown")
	print("PEER CAPTURE ", "PASSED" if failures.is_empty() else "FAILED", ": ", checks, " checks")
	get_tree().quit(0 if failures.is_empty() else 1)
