-- Recovered score native rules, exercised against the installed game stack.
-- Godot --headless --path fsj-orig res://tests/lua_unit.tscn -- --test=res://lua/tests/score_regression_test.lua
local B = assert(SceneScore, "scene_score native not installed")
local P = B.SPT
local checks = 0
local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function scene()
    return { __roomType = 0, __time = 100, __order = {} }
end
local function player(sc, id, manorID)
    local p = setmetatable({
        __scene = sc, __objectID = id, __accountID = id + 100,
        __nick = "score-test-" .. tostring(id), __equipID = 1, __b_headID = 2,
        __alive = true, __deaths = 0, __kills = 0,
        __manor = { manorID = manorID or id, count = 3 },
        __stats = { killCount = 0, pickUpCoin = 0 },
    }, { __index = CPlayerClient })
    sc.__order[#sc.__order + 1] = p
    return p
end

-- The original signed BLE must not treat a negative signed score as a new max.
local sc = scene()
local p = player(sc, 1)
B.SetProperty(p, P.AREA_SCORE, 100)
B.SetProperty(p, P.AREA_SCORE, 50)
equal(B.GetProperty(p, P.MAX_AREA), 100, "area maximum survives loss")
B.SetProperty(p, P.AREA_SCORE, 0x80000000)
equal(B.GetProperty(p, P.MAX_AREA), 100, "signed minimum cannot replace positive maximum")
p:NotifySimple32PropertyChanged(P.AREA_SCORE, 0xffffffff, 0x80000000)
equal(B.GetProperty(p, P.MAX_AREA), 100, "notification uses signed comparison")
B.SetProperty(p, P.MAX_AREA, 0xffffffff, false)
B.SetProperty(p, P.AREA_SCORE, 1)
equal(B.GetProperty(p, P.MAX_AREA), 1, "positive score exceeds signed negative maximum")

-- Max score uses peak area but CURRENT kill/combo scores; the sum wraps at u32.
B.SetProperty(p, P.MAX_AREA, 100, false)
B.SetProperty(p, P.AREA_SCORE, 50, false)
B.SetProperty(p, P.KILL_SCORE, 20, false)
B.SetProperty(p, P.COMBO_SCORE, 30, false)
local area, kills, combo, total = p:GetMaxScore()
equal(area, 100, "max-score area")
equal(kills, 20, "max-score kill")
equal(combo, 30, "max-score combo")
equal(total, 150, "max-score total")
equal(p:CalAllScore(), 100, "live total uses current area")
local buf = CBufferStream:new()
p:GetMaxScore(buf)
equal(buf:ReadUint32(), 100, "max-score wire area")
equal(buf:ReadUint32(), 20, "max-score wire kill")
equal(buf:ReadUint32(), 30, "max-score wire combo")
equal(buf:ReadUint32(), 150, "max-score wire total")
B.SetProperty(p, P.MAX_AREA, 0xfffffffe, false)
B.SetProperty(p, P.KILL_SCORE, 5, false)
B.SetProperty(p, P.COMBO_SCORE, 7, false)
local _, _, _, wrapped = p:GetMaxScore()
equal(wrapped, 10, "max-score sum wraps at 32 bits")

-- The explicit native getter must bypass config.lua's generic Get* adapter:
-- native rankprize keys are 10000 + the byte kill type, not a KillPrize column.
local prizes = CRankPrizeConfig:Inst()
for _, pair in ipairs({ {0, 0}, {1, 40}, {2, 60}, {3, 80}, {4, 80}, {255, 80}, {256, 0}, {257, 40} }) do
    equal(prizes:GetKillPrize(pair[1]), pair[2], "kill prize type " .. pair[1])
end
local config = B.GetConfig()
local savedPrize = config.rankPrizes[10002]
config.rankPrizes[10002] = nil
equal(prizes:GetKillPrize(2), 0, "missing prize inserts zero")
equal(config.rankPrizes[10002], 0, "missing prize is retained in map")
config.rankPrizes[10002] = savedPrize
B.SetKillPrizeTypes(p, 2, 255)
p:GetScoreInfo(buf)
buf:SetPosition(0x2d)
equal(buf:ReadUint8(), 2, "score info type byte")
equal(buf:ReadUint32(), 60, "score info current kill prize")
equal(buf:ReadUint32(), 80, "score info maximum kill prize")
B.SetKillPrizeTypes(p, 0, 0)
p:GetScoreInfo(buf)
buf:SetPosition(0x2d)
equal(buf:ReadUint8(), 0, "zero prize type")
equal(buf:ReadUint32(), 0, "zero type clears previous current prize")
equal(buf:ReadUint32(), 0, "zero type clears previous maximum prize")

-- KilledByPlayer's MULS discards high product bits BEFORE dividing by 10000.
local killer = player(sc, 2)
local victim = player(sc, 3)
local savedBase = config.killPrize
config.killPrize = 400
killer.__stats.killCount = 1 -- scene.lua increments before the score hook.
B.SetProperty(killer, P.KILL_BONUS, 2500, false)
B.OnKill(sc, killer, victim)
equal(B.GetProperty(killer, P.KILL_SCORE), 500, "25 percent kill bonus")
equal(B.GetProperty(killer, P.KILLS), 1, "score hook does not double-count kill")
B.SetProperty(killer, P.KILL_SCORE, 0, false)
B.SetProperty(killer, P.KILL_BONUS, 10737419, false)
B.OnKill(sc, killer, victim)
equal(B.GetProperty(killer, P.KILL_SCORE), 400, "overflow discarded before bonus division")
B.SetProperty(killer, P.KILL_SCORE, 0, false)
B.SetProperty(killer, P.KILL_BONUS, 0xffffffff, false)
B.OnKill(sc, killer, victim)
equal(B.GetProperty(killer, P.KILL_SCORE), 429896, "unsigned wrapped modifier")
B.OnKill(sc, nil, victim) -- ownerless deaths have no killer award.
equal(B.GetProperty(killer, P.KILL_SCORE), 429896, "ownerless death leaves score unchanged")
config.killPrize = savedBase

-- Active teams are compared independently of cached eliminations. Later
-- eliminations outrank earlier ones regardless of their cached score; each
-- team's players are sorted only after cached placement.
local standings = scene()
local a = player(standings, 11, 10)
local b = player(standings, 12, 10)
local c = player(standings, 13, 20)
local early = player(standings, 14, 30)
local late1 = player(standings, 15, 40)
local late2 = player(standings, 16, 40)
for _, pair in ipairs({ {a, 20}, {b, 30}, {c, 5}, {early, 5000}, {late1, 90}, {late2, 10} }) do
    B.SetProperty(pair[1], P.KILL_SCORE, pair[2], false)
end
B.PushSettlementTeam(standings, standings.__order, #standings.__order, 30)
early.__alive = false
B.PushSettlementTeam(standings, standings.__order, #standings.__order, 40)
late1.__alive, late2.__alive = false, false
B.PushSettlementTeam(standings, standings.__order, #standings.__order, 40)
equal(standings.__b_eliminationCount, 2, "cached teams are not counted twice")
-- A cached snapshot must not change if a dead player is later mutated.
B.SetProperty(early, P.KILL_SCORE, 0, false)
local teams = B.GetSettlementTeams(standings)
equal(#teams, 4, "all active and eliminated teams returned")
equal(teams[1].manorID, 10, "highest active team first")
equal(teams[2].manorID, 20, "lower active team still outranks eliminated team")
equal(teams[3].manorID, 40, "most recently eliminated team next")
equal(teams[4].manorID, 30, "earliest elimination last despite score")
equal(teams[1].players[1].objectID, 12, "active player default score sort")
equal(teams[3].players[1].objectID, 15, "cached player default score sort")
equal(teams[4].score, 5000, "cached score remains frozen")
equal(teams[4].rank, 4, "one-based adapter rank preserved")
local custom = B.GetSettlementTeams(standings,
    function(x, y) return x.score < y.score end,
    function(x, y) return x.objectID > y.objectID end)
equal(custom[1].manorID, 20, "custom comparator only reorders active teams")
equal(custom[2].manorID, 10, "custom active order")
equal(custom[3].manorID, 40, "custom comparator leaves cached slots intact")
equal(custom[3].players[1].objectID, 16, "custom comparator sorts cached players too")
local out = { [1] = "old", [7] = "stale", metadata = "keep" }
local returned = CGameScene.GetSettlementData(standings, out)
equal(returned[1].manorID, out[1].manorID, "scene settlement table API preserved")
equal(out[7], nil, "scene settlement clears obsolete numeric slots")
equal(out.metadata, "keep", "scene settlement preserves unrelated metadata")
CGameScene.GetSettlementData(standings, buf)
equal(buf:ReadUint32(), 4, "scene settlement envelope team count")
equal(buf:ReadUint32(), 10, "scene settlement envelope first manor")
equal(buf:ReadUint32(), 2, "scene settlement envelope first member count")
return "score regression ok: " .. checks .. " checks"
