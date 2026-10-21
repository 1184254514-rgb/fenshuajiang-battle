-- Run with tests/lua_unit.tscn -- --test=res://lua/tests/items_regression_test.lua.
-- Exercises the real native modules against deterministic scene/view adapters.
local C = assert(SceneItemsC)
local Move = assert(SceneSim.__a_module)
local originalHost = Host
local originalApp = g_App
local oldServerExp = C.ENABLE_SERVER_EXP_ITEMS
local checks = 0
local hints = {}
local function eq(actual, expected, label)
	assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
	checks = checks + 1
end
local view = setmetatable({
	add_item = function(_, id, _, _, _, hint) hints[id] = hint end,
}, { __index = function() return function() end end })
Host = { scene_view = view, read_text = function(_, path) return originalHost:read_text(path) end }
g_App = nil

local function scene()
	local sc = { __W = 12, __H = 12, __roomType = 0, __owner = {}, __trail = {}, __players = {}, __order = {}, __time = 0, __started = true }
	function sc:GetRoomType() return 0 end
	function sc:GetWidth() return nil end -- the prelude returns nil from missing-native stubs
	function sc:GetDepth() return nil end
	function sc:GetSceneInfo() return { IsServer = function() return false end } end
	function sc:IsServer() return false end
	function sc:AllocObjectID() self.nextID = (self.nextID or 100) + 1; return self.nextID end
	function sc:CheckBarrier(from, to) return C.CheckBarrier(self, from, to) end
	function sc:RemoveObject(item) return C.RemoveItem(item, nil, "animation_end") end
	for i = 0, sc.__W * sc.__H - 1 do sc.__owner[i] = 1; sc.__trail[i] = 0 end
	C.InitScene(sc)
	return sc
end
local function player(sc, id)
	return setmetatable({ __scene = sc, __objectID = id, __accountID = id, __alive = true,
		__x = 24, __y = 24, __dir = 2, __manor = { manorID = 1, colorID = 1, count = 144 },
		__trail = {}, __segStart = 1, __nick = "test", __stats = {}, __deaths = 0,
		GetAddSpeed = function() return 0 end }, CPlayerClient)
end

local ok, failure = xpcall(function()
	eq(C.ENABLE_SERVER_EXP_ITEMS, false, "server exp injection defaults off")
	eq(C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL, false, "invented local refill defaults off")
	eq(C.ENABLE_UNVERIFIED_LOCAL_EXP_REWARDS, false, "invented local exp rewards default off")
	eq(Move.ENABLE_UNVERIFIED_TRACE_BACK, false, "unverified trace-back defaults off")
	local sc = scene()
	C.SeedExp(sc)
	C.Tick(sc, 100)
	eq(next(sc.__c_items), nil, "offline startup creates no crystals")
	eq(C.CreatExpUnit(sc, 101, { x = 56, y = 56 }), nil, "server injection requires opt-in")
	local freeScene = scene()
	for i = 0, freeScene.__W * freeScene.__H - 1 do freeScene.__owner[i] = 0 end
	eq(C.GetFreeGrid(freeScene, {}, 64, 0), true, "missing native dimension stubs fall back to scene pixels")

	local p = player(sc, 700)
	sc.m_pDirectorObj = p
	C.SetGold(p, 13)
	eq(C.BasePickUpCoin(p, 7, 3), 3, "base coin pickup ignores room argument")
	eq(p:GetSimple32Property(0), 16, "coin pickup adds raw units rather than tenfold prize")
	C.SetGold(p, 0xffffffff)
	C.BasePickUpCoin(p, 0, 2)
	eq(p:GetSimple32Property(0), 1, "coin property wraps as uint32")
	eq(C.CheckItemExpansion({ GetSimple32Property = function() return 0xffffffff end }), 47,
		"negative signed pickup bonus reduces the 48-pixel base range")

	local calls, dropLevel, dropExtra = 0
	function sc:DropOut(_, level, extra) calls = calls + 1; dropLevel = level; dropExtra = extra; return 9 end
	local victim = { __scene = sc, __x = 40, __y = 56, GetSimple32Property = function(_, id) return id == 7 and 9 or 1000 end }
	local killer = { GetSimple32Property = function(_, id) return id == 12 and 260 or 0 end }
	C.OnPlayerDeath(sc, victim, killer, false)
	eq(dropLevel, 9, "death drop forwards victim property 7")
	eq(dropExtra, 4, "death drop truncates killer property 12 to a byte")
	C.OnPlayerDeath(sc, victim, killer, false)
	eq(calls, 1, "duplicate death callback does not drop twice")

	local from, to = { x = 24, y = 24 }, { x = 100, y = 24 }
	sc.__c_itemFlags[1 * sc.__W + 4] = C.FLAG_NO_MOVE
	C.CheckBarrier(sc, from, to)
	eq(to.x, 56, "barrier stops at last free cell centre")
	eq(to.y, 24, "horizontal barrier preserves row")
	to = { x = 100, y = 100 }
	C.CheckBarrier(sc, from, to)
	eq(to.x, 100, "native diagonal barrier request is left untouched")
	to = { x = 31, y = 25 }
	C.CheckBarrier(sc, from, to)
	eq(to.x, 24, "same-cell request restores exact origin")
	eq(to.y, 24, "same-cell request restores both coordinates")
	sc.__c_itemFlags[1 * sc.__W + 1] = C.FLAG_NO_MOVE
	to = { x = 100, y = 24 }
	C.CheckBarrier(sc, { x = 25, y = 26 }, to)
	eq(to.x, 25, "blocked origin restores fractional origin")
	eq(to.y, 26, "blocked origin restores exact vertical coordinate")
	sc.__c_itemFlags[1 * sc.__W + 1] = nil

	p:MoveOn(1, 0, 80, 1000)
	SceneSim.step_player(sc, p, 1000)
	eq(p.__x, 56, "movement integration cannot cross item barrier")
	eq(p.__a_motion_speed, 0, "movement stops at barrier target")
	p:MoveOn(-1, 0, 80, 1000)
	eq(p.__dir, 1, "native movement accepts reversal")
	p:MoveOn(1, 1, 80, 1000)
	eq(p.__dir, 4, "equal input magnitudes choose Y axis")
	local accepted, reason = p:MoveOn(0.001, 0.001, 80, 1000)
	eq(accepted, false, "tiny input rejected")
	eq(reason, "zero-direction", "tiny input rejection reason")

	local mapScene = scene()
	eq(C.CreateMapItems(mapScene, 1), 5, "original map creates exactly five entries")
	for _, item in pairs(mapScene.__c_items) do
		eq(item.__c_context.flags, 0, "zero Tongxing/Quandi rows do not become barriers")
	end
	eq(C.CreateMapItems(mapScene, 1), 5, "explicit native map creation is not silently idempotent")

	local coin = assert(C.CreateItem(sc, 102, { x = 56, y = 24 }, { modelID = 0, dropType = 0 }))
	eq(hints[102].state, 1, "view receives actual spawn state")
	eq(hints[102].state_animation, "rb1", "view receives native spawn clip")
	C.Tick(sc, 100)
	eq(coin:GetState(), 1, "timer does not invent animation completion")
	eq(C.OnItemAnimationEnd(sc, 102, "bind"), false, "wrong animation cannot arm coin")
	C.OnItemAnimationEnd(sc, 102, "rb1")
	eq(coin:GetState(), 2, "spawn animation completion arms coin")
	p:OnCollideDropOut(coin)
	eq(coin:GetState(), 3, "coin pickup begins native fly_die state")
	eq(coin.__c_pickedByID, p.__objectID, "pickup animation targets the collector")
	eq(p:GetSimple32Property(0), 2, "physical coin pickup credits one raw unit")
	C.CheckItem(p, { left = 56, top = 24, right = 56, bottom = 24 }, sc)
	eq(p:GetSimple32Property(0), 2, "pickup scan does not credit state-3 coin twice")
	eq(C.OnItemAnimationEnd(sc, 102, "rb1"), false, "stale spawn callback cannot remove picked coin")
	eq(sc.__c_items[102], coin, "picked coin remains until fly_die ends")
	C.OnItemAnimationEnd(sc, 102, "fly_die")
	eq(sc.__c_items[102], nil, "fly_die completion removes private item")
	eq(C.OnItemAnimationEnd(sc, 102, "fly_die"), false, "late duplicate animation callback is harmless")
end, debug.traceback)

Host = originalHost
g_App = originalApp
C.ENABLE_SERVER_EXP_ITEMS = oldServerExp
if not ok then error(failure) end
return "ITEMS REGRESSION PASS: " .. checks .. " checks"
