-- Director and AI share intersection rollback and unique live colours.
local savedHost = Host
local checks, clears = 0, {}
local function equal(actual, expected, message)
	checks = checks + 1
	assert(actual == expected, message .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end
local view = setmetatable({
	clear_trail_cell = function(_, idx) clears[idx] = true end,
}, { __index = function() return function() end end })
Host = { scene_view = view, read_text = function(_, path) return savedHost:read_text(path) end }

local function scene()
	local sc = { __W = 12, __H = 12, __time = 0, __roomType = 0, __players = {}, __order = {},
		__owner = {}, __trail = {}, __val = {}, __byManor = {}, __nextManorID = 1, __nextObjectID = 100 }
	for idx = 0, 143 do sc.__owner[idx] = 0; sc.__trail[idx] = 0; sc.__val[idx] = 0 end
	return setmetatable(sc, CGameScene)
end
local function painter(sc, id, director)
	local p = { __objectID=id, __alive=true, __trail={}, __trailUnder={}, __segStart=1,
		__manor={manorID=id,colorID=id-1,count=1}, __ai=not director }
	sc.__players[id]=p; sc.__order[#sc.__order+1]=p; sc.__byManor[id]=p
	if director then sc.m_pDirectorObj=p end
	return p
end

local ok, failure = xpcall(function()
	for _, isDirector in ipairs({true,false}) do
		local sc=scene()
		local p=painter(sc,1,isDirector)
		-- A branch crosses another owner's territory, which must be preserved.
		sc.__owner[29]=7; sc.__val[29]=2
		for _, idx in ipairs({25,26,27,28,29}) do
			SceneSim.enter_node(sc,p,idx%sc.__W,idx//sc.__W)
		end
		equal(#p.__trail,5,'route laid for '..tostring(isDirector))
		p.__segStart=6
		local before=p.__manor.count
		SceneSim.enter_node(sc,p,27%sc.__W,27//sc.__W)
		equal(#p.__trail,3,'crossing removes suffix for '..tostring(isDirector))
		equal(p.__trail[3],27,'intersection retained')
		equal(sc.__trail[27],1,'intersection remains live')
		equal(sc.__trail[28],0,'first removed cell cleared')
		equal(sc.__trail[29],0,'last removed cell cleared')
		equal(sc.__owner[29],7,'underlying enemy territory remains')
		equal(sc.__val[29],2,'underlying valuation restored')
		equal(clears[29],true,'rollback fade immediately cleared')
		equal(p.__manor.count,before,'rollback grants no area')
		equal(p.__alive,true,'own crossing never kills')
		equal(p.__segStart,4,'rhythm segment clipped to retained route')
		SceneSim.enter_node(sc,p,27%sc.__W,27//sc.__W)
		equal(#p.__trail,3,'reentering tip creates no duplicates')
		SceneSim.enter_node(sc,p,39%sc.__W,39//sc.__W)
		equal(#p.__trail,4,'can draw a new branch from intersection')
		equal(p.__trail[4],39,'new branch appended')
		SceneSim.enter_node(sc,p,25%sc.__W,25//sc.__W)
		equal(#p.__trail,1,'crossing departure retains only the first cell')
		equal(SceneSim.rollback_trail(sc,p,143),false,'missing crossing does not truncate route')
	end

	local sc=scene()
	local used={}
	for id=1,10 do
		local p=assert(sc:AddPlayer(id,{nickName='P'..id},CVector2f:new(24,24),16))
		equal(used[p.__manor.colorID],nil,'reserved player has unique colour')
		used[p.__manor.colorID]=true
		p.__alive=true; p.__colour_reserved=false
	end
	equal(sc:AddPlayer(11,{},CVector2f:new(24,24),16),nil,'roster cannot exceed ten unique colours')
	local freed=sc.__order[4].__manor.colorID
	sc.__order[4].__alive=false
	local replacement=assert(sc:AddPlayer(12,{},CVector2f:new(24,24),16))
	equal(replacement.__manor.colorID,freed,'new identity reuses departed colour')

	-- This fixture has no cross-layer departure link at a captured cell.
	-- Enclosing its foreign route middle preserves both grid layers.
	sc=scene()
	local captor=assert(sc:AddPlayer(1,{},CVector2f:new(24,24),16))
	local victim=assert(sc:AddPlayer(2,{},CVector2f:new(160,160),16))
	captor.__alive=true;victim.__alive=true
	sc.__byManor[captor.__manor.manorID]=captor
	sc.__byManor[victim.__manor.manorID]=victim
	for y=2,6 do for x=2,6 do
		if x==2 or x==6 or y==2 or y==6 then sc.__owner[y*12+x]=captor.__manor.manorID end
	end end
	local gap=2*12+4
	sc.__owner[gap]=0;sc.__trail[gap]=1;captor.__trail={gap};captor.__manor.count=15
	local enemyLine=4*12+4
	sc.__trail[enemyLine]=2;victim.__trail={enemyLine}
	sc.__owner[9*12+9]=victim.__manor.manorID;victim.__manor.count=1
	SceneSim.enter_node(sc,captor,3,2)
	equal(victim.__alive,true,'enclosing a distant route does not remotely kill its owner')
	equal(#victim.__trail,1,'enclosed live route keeps its chronological path')
	equal(sc.__trail[enemyLine],2,'enclosed route grid remains visible and collidable')
	equal(sc.__owner[enemyLine],captor.__manor.manorID,'captured interior belongs to captor')
	equal(captor.__kills,0,'enclosure does not award an unearned contact kill')
	SceneSim.enter_node(sc,captor,4,4)
	equal(victim.__alive,false,'actual contact with the enclosed live route still kills')
	equal(sc.__trail[enemyLine],0,'actual cut removes the route')
	equal(captor.__kills,1,'actual contact awards exactly one kill')
end, debug.traceback)
Host=savedHost
assert(ok,failure)
return 'TRAIL REGRESSION PASS: '..checks..' checks'
