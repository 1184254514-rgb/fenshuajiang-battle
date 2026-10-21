-- Local timed competition: endpoint, roster ordering, respawn and replay.
local M = require("natives.scene_match")
-- The fixture can run with or without --full; hook checks need an original-
-- shaped class, while --full exercises the genuine original class.
local savedWanfa = CWanfaEndless
if not CWanfaEndless then CWanfaEndless = { Balance = function() return "endless" end } end
local checks = 0
local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function fixture()
    local sc = { __roomType = 0, __time = 0, __started = true,
        __W = 60, __H = 60, __owner = {}, __trail = {}, __order = {} }
    for index = 0, sc.__W * sc.__H - 1 do sc.__owner[index], sc.__trail[index] = 0, 0 end
    return sc
end
local function player(sc, id, area, kills)
    local p = setmetatable({ __scene = sc, __objectID = id, __nick = "画匠" .. id,
        __alive = true, __manorWidth = 80, __manor = { manorID = id, count = area },
        __stats = { killCount = kills or 0 }, __deaths = 0, __kills = kills or 0,
        __trail = {}, __x = 168, __y = 168,
        StartUp = function(self)
            self.__alive = true
            self.__manor.count = 25
            self.__respawn_calls = (self.__respawn_calls or 0) + 1
        end,
    }, { __index = CPlayerClient })
    sc.__order[#sc.__order + 1] = p
    return p
end
local savedApp = g_App
local app = { start_calls = 0, home_calls = 0 }
function app:EnterRoom(room)
    equal(room, 0, "timed mode creates local room zero")
    self.start_calls = self.start_calls + 1
    self.__scene = fixture()
end
function app:SwitchStart()
    self.home_calls = self.home_calls + 1
    self.__scene = nil
end
function app:SetDirector(p) self.director = p end
function app:GetGameMain() return {} end
function app:GetGameStart() return { IsShow = function() return true end } end
g_App = app
local ok, problem = pcall(function()
    local sc = M.Start()
    equal(sc.__timed_match, true, "start marks explicit timed adapter")
    equal(sc.__roomType, 0, "original offline scoring remains enabled")
    equal(sc.__limit, 240000, "four minute original config default")
    equal(M.GetTimeRemain(sc), 240000, "countdown begins at full duration")
    sc.__time = 239999
    equal(M.GetTimeRemain(sc), 1, "one millisecond before endpoint")
    equal(M.IsFinished(sc), false, "not finished early")
    M.Tick(sc, 0)
    equal(sc.__started, true, "scene still running at one millisecond")

    local a = player(sc, 7, 80, 3)
    local b = player(sc, 4, 80, 3)
    local c = player(sc, 2, 80, 1)
    local d = player(sc, 1, 79, 99)
    sc.m_pDirectorObj = b
    local live = M.Results(sc)
    equal(#live, 4, "live leaderboard includes every identity")
    equal(live[1].objectID, 4, "equal area and kills uses smaller id")
    equal(live[2].objectID, 7, "same tie key shared by live leaderboard")
    equal(live[3].objectID, 2, "kill tiebreak outranks lower kill count")
    equal(live[4].objectID, 1, "area outranks kill count")
    equal(M.GetPlayerRank(sc, 4), 1, "director live placement")
    equal(M.GetPlayerRank(sc, 999), 0, "unknown identity has no rank")
    local reversed = { live[4], live[3], live[2], live[1] }
    table.sort(reversed, M.Less)
    equal(reversed[1].objectID, 4, "explicit comparator is deterministic")

    sc.__time = 240000
    equal(M.GetTimeRemain(sc), 0, "endpoint reports exactly zero")
    M.Tick(sc, 1)
    equal(M.IsFinished(sc), true, "endpoint concludes match")
    equal(sc.__started, false, "endpoint freezes world update flag")
    equal(a.__b_frozen, true, "endpoint blocks direct score notifications")
    equal(sc.__time, 240000, "endpoint is not extended")
    local final = M.Results(sc)
    equal(final[1].objectID, 4, "final and live first place agree")
    equal(final[4].objectID, 1, "final and live tie rules agree")
    a.__manor.count, b.__stats.killCount = 999, 999
    equal(M.Results(sc)[1].objectID, 4, "final standings remain a snapshot")
    equal(M.Results(sc)[2].area, 80, "snapshot area does not follow mutable players")
    equal(M.Results(sc)[1].kills, 3, "snapshot kills do not follow mutable players")
    M.Tick(sc, 1000)
    equal(sc.__time, 240000, "finished ticks cannot advance clock")
    equal(M.Respawn(sc, d), false, "no respawn after final result")
    equal(M.UIState():match("^[^|]+"), "finished", "finished UI state exposed")

    local again = M.Rematch()
    equal(app.start_calls, 2, "replay creates fresh local scene")
    equal(app.home_calls, 1, "replay disposes old scene first")
    equal(again ~= sc, true, "replay does not reuse previous world")
    equal(M.GetTimeRemain(again), 240000, "replay resets countdown")
    equal(M.IsFinished(again), false, "replay clears finished state")
    equal(#M.Results(again), 0, "replay has no stale leaderboard rows")

    -- Same-ID respawn preserves kills, color and historical score, while the
    -- old territory is already removed by the ordinary death path.
    local dead = player(again, 42, 0, 5)
    again.m_pDirectorObj = dead
    again.__match_roster_ready = true
    dead.__alive, dead.__b_frozen, dead.__b_settlement = false, true, { score = 50 }
    dead.__manor.colorID = 6
    dead.__c_inScene = false
    dead.__trailUnder = { [1] = 2 }
    local inserted = 0
    function again:InsertObject(object, pos)
        equal(object, dead, "respawn reinserts the same removed object")
        equal(pos:x() > 0, true, "reinsertion uses valid respawn coordinates")
        inserted = inserted + 1
    end
    M.OnPlayerDeath(again, dead, nil)
    equal(M.RespawnRemaining(again, dead), 3000, "three second respawn delay")
    again.__time = 2999
    M.Tick(again, 2999)
    equal(dead.__alive, false, "dead identity does not respawn early")
    equal(M.RespawnRemaining(again, dead), 1, "one millisecond respawn countdown")
    again.__time = 3000
    M.Tick(again, 1)
    equal(dead.__alive, true, "identity respawns at three seconds")
    equal(dead.__objectID, 42, "respawn keeps same object id")
    equal(dead.__manor.colorID, 6, "respawn keeps manor color")
    equal(dead.__stats.killCount, 5, "respawn preserves kills")
    equal(dead.__b_frozen, false, "respawn unfreezes score producers")
    equal(dead.__b_settlement, nil, "respawn discards prior death snapshot")
    equal(dead.__respawn_calls, 1, "startup runs once per respawn")
    equal(inserted, 1, "removed object is reinserted exactly once")
    equal(dead.__c_inScene, true, "respawn restores native scene membership")
    equal(next(dead.__trailUnder), nil, "respawn cannot retain prior trail valuations")
    equal(M.RespawnRemaining(again, dead), 0, "alive identity has no respawn timer")
    M.Tick(again, 1)
    equal(dead.__respawn_calls, 1, "following tick cannot duplicate respawn")

    -- Empty cells are insufficient when an enemy head is beside the spawn.
    local unsafe = fixture(); M.Configure(unsafe,240000)
    local reborn=player(unsafe,42,0,0);reborn.__alive=false
    local near=player(unsafe,1,25,0)
    -- The old deterministic first candidate for id 42 at time zero.
    local half,stride=2,7
    local cols=math.floor((unsafe.__W-2*half-2)/stride)+1
    local k=(42*17)%(cols*cols)
    near.__x=(half+1+k%cols*stride+0.5)*16
    near.__y=(half+1+math.floor(k/cols)*stride+0.5)*16
    equal(M.Respawn(unsafe,reborn),true,"respawn finds another free position near an enemy")
    equal((reborn.__x-near.__x)^2+(reborn.__y-near.__y)^2>=160^2,true,"respawn does not overlap or hug a living enemy")

    M.InstallHooks()
    again.__aiPlan, again.__aiTimer = {}, 42
    CGameScene.OnAddAiTick(again, 100)
    equal(again.__aiTimer, 42, "timed roster suppresses endless replenishment")
    M.ReturnHome()
    equal(app.__scene, nil, "home button releases scene")
    equal(app.director, nil, "home clears stale director")
    equal(app.home_calls, 2, "home handler runs once")
    equal(M.UIState(), "home", "home start button becomes available")
    local short = M.Start(1000)
    equal(short.__limit, 1000, "testable custom duration")
    short.__time = 1001
    equal(M.GetTimeRemain(short), 0, "late clock clamps to zero")
    M.Tick(short, 1001)
    equal(short.__time, 1000, "late frame clamps to exact finish endpoint")
    equal(M.GetTimeRemain({ __roomType = 0 }), 0, "ordinary endless is not a timed match")
    equal(M.IsFinished({ __roomType = 0 }), false, "ordinary endless stays unaffected")
end)
g_App = savedApp
CWanfaEndless = savedWanfa
if not ok then error(problem, 0) end
return "match regression ok: " .. checks .. " checks"
