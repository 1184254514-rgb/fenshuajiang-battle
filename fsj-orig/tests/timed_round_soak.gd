extends Node
# A complete 240000ms match through the normal native tick, accelerated in
# 100ms simulation steps. Rendering still gets a frame after every simulated second.
var host: LuaHost
var failed := false

func evaluate(source: String):
	var result = host.lua.do_string(source)
	if result is LuaError:
		failed = true
		printerr("ROUND SOAK ERROR: ", result)
	return result

func _ready() -> void:
	var ui := Control.new()
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	if not host.start(ui): get_tree().quit(1); return
	evaluate("math.randomseed(20261021); require 'start_game'")
	for unused in 90: await get_tree().process_frame
	evaluate("g_App:GetLoginFrame():ConnectWorld()")
	for unused in 150: await get_tree().process_frame
	evaluate("SceneSkills.SetSelected(2,1); SceneMatch.Start()")
	for unused in 30: await get_tree().process_frame
	evaluate("local d=g_App:GetDirector(); SceneAI.SetPlayerConfig(d,1); d.__ai=SceneAI.Think")
	host.set_process(false)
	var iterations := 0
	while not failed and iterations < 2500:
		var remaining = evaluate("return SceneMatch.GetTimeRemain(g_App.__scene)")
		if remaining is LuaError or remaining == null or int(remaining) <= 0: break
		evaluate("NativeTickUpdate(100)")
		iterations += 1
		if iterations % 50 == 0:
			evaluate("""
				local sc=g_App.__scene; assert(#sc.__order==10,'fixed roster changed')
				local colours={}
				for _,p in ipairs(sc.__order) do
					assert(not colours[p.__manor.colorID],'duplicate colour'); colours[p.__manor.colorID]=true
					if p.__alive then
						local visited={}
						for _,idx in ipairs(p.__trail) do
							assert(not visited[idx],'repeated trail node after crossing'); visited[idx]=true
							assert(sc.__trail[idx]==p.__objectID,'trail ownership drift: player='..p.__objectID..' cell='..idx..' trail='..tostring(sc.__trail[idx])..' owner='..tostring(sc.__owner[idx])..' manor='..p.__manor.manorID..' time='..sc.__time)
						end
					end
				end
			""")
		if iterations % 10 == 0: await get_tree().process_frame
	if not failed:
		evaluate("""
			local sc=g_App.__scene
			assert(SceneMatch.IsFinished(sc),'round did not finish')
			assert(sc.__time-sc.__match_started_at==240000,'round duration drift')
			assert(sc:GetTimeRemain()==0,'negative or positive final countdown')
			assert(#SceneMatch.Results(sc)==10,'final roster incomplete')
			local deaths=0;local skills=0
			for _,p in ipairs(sc.__order) do deaths=deaths+p.__deaths; if p.__skill_last_cast then skills=skills+1 end end
			print('ROUND SOAK SUMMARY: duration=240000 roster='..#sc.__order..' deaths='..deaths..' skill_users='..skills)
			assert(deaths>0,'soak did not exercise death/respawn')
			assert(skills>=5,'bots did not exercise varied skills')
		""")
	if host._tick_errors > 0: failed = true
	print("ROUND SOAK FAILED" if failed else "ROUND SOAK PASSED: full four-minute simulation, fixed roster, colours, route ownership, skills and respawns")
	get_tree().quit(1 if failed else 0)
