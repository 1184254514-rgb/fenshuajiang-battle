-- Local timed competition adapter. It deliberately reuses the offline room-0
-- world, not the unavailable field server. Duration comes from the original
-- timed scene (nLimitTime=240000); respawn and tie rules below are explicit
-- local-mode rules, not claims about the original server implementation.
local M = { DEFAULT_DURATION_MS = 240000, RESPAWN_MS = 3000, BOT_COUNT = 9 }
SceneMatch = M

local function scene(sc)
    return sc or (g_App and g_App.__scene)
end
local function number(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or math.abs(value) == math.huge then return fallback end
    return value
end
local function current_time(sc)
    return math.max(0, number(sc and sc.__time, 0))
end
local function invoke(obj, name, ...)
    if not obj then return false end
    local fn = obj[name]
    -- Godot methods are callable userdata in lua-gdextension, while Lua
    -- instance methods are functions. Both use the same colon-call arguments.
    if type(fn) ~= "function" and type(fn) ~= "userdata" then return false end
    return pcall(fn, obj, ...)
end
local function stop_tick(tick)
    if tick then invoke(tick, "Stop") end
end
local function hide_old_results(sc)
    local wf = sc and sc.m_pWanfa
    if not wf then return end
    for _, key in ipairs({ "m_pWndDieTip", "m_pWndBalance", "m_pWndBalanceBeyond",
        "m_pResultWnd", "m_pRhythmSettWnd", "m_pWndModeOpenReward" }) do
        invoke(wf[key], "ShowWnd", false)
    end
end
local function stop_endless_checks(sc)
    local wf = sc and sc.m_pWanfa
    if not wf then return end
    stop_tick(wf.m_tickCheck)
    stop_tick(wf.m_tickDieBalance)
end

local function show_original_clock(show)
    local ok, gm = invoke(g_App, "GetGameMain")
    if not ok or not gm then return end
    local found, clock = invoke(gm, "GetDlgChild", "W_youxishijian")
    if found and clock then invoke(clock, "ShowWnd", show) end
end

function M.IsTimed(sc)
    sc = scene(sc)
    return sc ~= nil and sc.__timed_match == true
end
function M.IsFinished(sc)
    sc = scene(sc)
    return M.IsTimed(sc) and sc.__match_finished == true
end
function M.GetTimeRemain(sc)
    sc = scene(sc)
    if not M.IsTimed(sc) then return 0 end
    if sc.__match_finished then return 0 end
    return math.max(0, math.floor((sc.__limit or M.DEFAULT_DURATION_MS)
        - (current_time(sc) - (sc.__match_started_at or 0))))
end

-- Primary key: CURRENT owned cells. Equal area is resolved by kills, then the
-- smaller object ID. Live and final boards use this exact same comparator.
function M.Less(a, b)
    if a.area ~= b.area then return a.area > b.area end
    if a.kills ~= b.kills then return a.kills > b.kills end
    return a.objectID < b.objectID
end
local function player_score(p)
    if SceneScore then
        return SceneScore.GetProperty(p, SceneScore.SPT.AREA_SCORE)
            + SceneScore.GetProperty(p, SceneScore.SPT.KILL_SCORE)
            + SceneScore.GetProperty(p, SceneScore.SPT.COMBO_SCORE)
    end
    local st = p.__stats or {}
    return (st.areaScore or 0) + (st.killScore or 0) + (st.comboScore or 0)
end
local function standings(sc)
    local rows = {}
    local total = math.max(1, (sc.__W or 1) * (sc.__H or 1))
    for _, p in ipairs(sc.__order or {}) do
        local area = p.__alive and p.__manor and p.__manor.count or 0
        rows[#rows + 1] = {
            objectID = number(p.__objectID, 0), name = tostring(p.__nick or "画匠"),
            area = math.max(0, number(area, 0)), percent = area * 100 / total,
            kills = number(p.__stats and p.__stats.killCount or p.__kills, 0),
            score = player_score(p), alive = p.__alive == true,
            director = p == sc.m_pDirectorObj,
        }
    end
    table.sort(rows, M.Less)
    for index, row in ipairs(rows) do row.rank = index end
    return rows
end
function M.Results(sc)
    sc = scene(sc)
    if not M.IsTimed(sc) then return {} end
    return sc.__match_results or standings(sc)
end
function M.GetPlayerRank(sc, objectID)
    for index, row in ipairs(M.Results(sc)) do
        if row.objectID == objectID then return index end
    end
    return 0
end

function M.Configure(sc, duration_ms)
    assert(sc and sc.__roomType == 0, "Timed competition requires the local room-0 world")
    sc.__timed_match = true
    sc.__limit = math.max(1, math.floor(number(duration_ms, M.DEFAULT_DURATION_MS)))
    sc.__match_started_at = current_time(sc)
    sc.__match_finished, sc.__match_results = false, nil
    sc.__match_respawns, sc.__match_roster_ready = {}, false
    sc.__match_seed_attempts = 0
    stop_endless_checks(sc)
    hide_old_results(sc)
    show_original_clock(false)
    return sc
end
function M.Start(duration_ms)
    if not g_App or type(g_App.EnterRoom) ~= "function" then return false, "尚未进入游戏" end
    if g_App.__scene then M.ReturnHome() end
    g_App:EnterRoom(eRT_Endless or 0)
    local sc = g_App.__scene
    if not sc then return false, "创建本地对局失败" end
    M.Configure(sc, duration_ms)
    return sc
end
function M.Rematch()
    local sc = scene()
    local duration = sc and sc.__limit or M.DEFAULT_DURATION_MS
    return M.Start(duration)
end
function M.ReturnHome()
    if not g_App then return false end
    local sc = g_App.__scene
    if sc then
        sc.__started = false
        stop_endless_checks(sc)
        if sc.m_pWanfa then stop_tick(sc.m_pWanfa.m_tickCreateDirector) end
        hide_old_results(sc)
        show_original_clock(true)
    end
    invoke(g_App, "SetDirector", nil)
    local ok = invoke(g_App, "SwitchStart")
    return ok
end

local function free_position(sc, p)
    local half = math.max(1, math.floor((p.__manorWidth or 80) / 16 / 2))
    local stride = 2 * half + 3
    local cols = math.floor((sc.__W - 2 * half - 2) / stride) + 1
    local rows = math.floor((sc.__H - 2 * half - 2) / stride) + 1
    if cols <= 0 or rows <= 0 then return nil end
    local total = cols * rows
    local start = (math.floor(p.__objectID or 0) * 17 + math.floor(current_time(sc) / 1000)) % total
    for offset = 0, total - 1 do
        local k = (start + offset) % total
        local x, y = half + 1 + k % cols * stride, half + 1 + math.floor(k / cols) * stride
        local free = true
        -- Local timed respawns need room to leave the initial manor. An empty
        -- 5x5 square alone can put the head directly beside a live enemy route.
        local clearance = half + 2
        for yy = y - clearance, y + clearance do
            for xx = x - clearance, x + clearance do
                local idx = yy * sc.__W + xx
                if xx < 0 or yy < 0 or xx >= sc.__W or yy >= sc.__H
                    or (sc.__owner[idx] or 0) ~= 0 or (sc.__trail[idx] or 0) ~= 0
                    or ((sc.__c_itemFlags and sc.__c_itemFlags[idx] or 0) & 1) ~= 0 then
                    free = false; break
                end
            end
            if not free then break end
        end
        if free then
            local px,py=(x+0.5)*16,(y+0.5)*16
            for _,other in ipairs(sc.__order or {}) do
                if other~=p and other.__alive and other.__x and other.__y
                    and (px-other.__x)^2+(py-other.__y)^2 < ((half+8)*16)^2 then
                    free=false;break
                end
            end
            if free then return px,py end
        end
    end
end
function M.Respawn(sc, p)
    if not M.IsTimed(sc) or M.IsFinished(sc) or not p or p.__alive then return false end
    local x, y = free_position(sc, p)
    if not x then return false end
    p.__x, p.__y = x, y
    p.__trail, p.__segStart = {}, 1
    p.__trailUnder = {}
    p.__trailRevision = (p.__trailRevision or 0) + 1
    p.__manor.count = 0
    p.__b_frozen, p.__b_settlement, p.__b_deathNodes = false, nil, nil
    p.__b_endTime = nil
    p.__killedBy, p.__speedup, p.m_bJustDie = "", false, false
    p.__aiPlan, p.__a_path, p.__a_cells, p.__a_visits, p.__a_home = nil, nil, nil, nil, nil
    p.__a_tracing = false
    -- The death path removes the object from scene membership without
    -- destroying its fixed-roster identity. Reinsert through the same native
    -- hook before StartUp dispatches the original OnInsertToScene callbacks.
    if p.__c_inScene == false then
        invoke(sc, "InsertObject", p, CPos16:new(x, y))
    end
    p.__c_inScene = true
    p:StartUp(p.__equipID or 0)
    if p == sc.m_pDirectorObj and g_App then
        invoke(g_App, "SetDirector", p)
        local ok, gm = invoke(g_App, "GetGameMain")
        if ok and gm then gm.m_bIsDie = false end
    end
    if p.__ai then
        p.__homeX, p.__homeY = math.floor(x / 16), math.floor(y / 16)
    end
    sc.__match_respawns[p.__objectID] = nil
    return p.__alive == true
end
function M.OnPlayerDeath(sc, victim, _killer)
    if not M.IsTimed(sc) or M.IsFinished(sc) or not victim then return end
    sc.__match_respawns[victim.__objectID] = current_time(sc) + M.RESPAWN_MS
end
function M.RespawnRemaining(sc, p)
    if not M.IsTimed(sc) or not p or p.__alive or M.IsFinished(sc) then return 0 end
    local due = sc.__match_respawns and sc.__match_respawns[p.__objectID]
    return due and math.max(0, due - current_time(sc)) or M.RESPAWN_MS
end

function M.Finish(sc)
    sc = scene(sc)
    if not M.IsTimed(sc) then return false end
    if sc.__match_finished then return sc.__match_results end
    sc.__time = (sc.__match_started_at or 0) + sc.__limit
    if SceneScore then SceneScore.OnUpdateManorScore(sc) end
    sc.__match_results = standings(sc)
    sc.__match_finished, sc.__started = true, false
    stop_endless_checks(sc)
    local wf = sc.m_pWanfa
    if wf then
        stop_tick(wf.m_tickUpdateRank)
        stop_tick(wf.m_tickCreateDirector)
        wf.m_bBalance = true
    end
    hide_old_results(sc)
    for _, p in ipairs(sc.__order or {}) do
        p.__speedup = false
        -- Also reject direct rhythm notifications from original UI callbacks
        -- while the result snapshot is displayed.
        p.__b_frozen = true
    end
    if g_App then
        local ok, gm = invoke(g_App, "GetGameMain")
        if ok and gm then
            local got, buttons = invoke(gm, "GetGameButton")
            if got and buttons then invoke(buttons, "ShowWnd", false) end
        end
    end
    if Host and Host.scene_view then invoke(Host.scene_view, "set_music_paused", true) end
    return sc.__match_results
end

function M.Tick(sc, _dt)
    if not M.IsTimed(sc) or M.IsFinished(sc) then return end
    if M.GetTimeRemain(sc) == 0 then M.Finish(sc); return end
    stop_endless_checks(sc)
    if sc.m_pDirectorObj and not sc.__match_roster_ready then
        local bots = 0
        for _, p in ipairs(sc.__order or {}) do if p.__ai then bots = bots + 1 end end
        local target = math.min(M.BOT_COUNT, math.max(1, (sc.__maxCount or 10) - 1))
        while bots < target and type(sc.SpawnAI) == "function" do
            local ai = sc:SpawnAI(1)
            if not ai then break end
            bots = bots + 1
        end
        sc.__match_seed_attempts = (sc.__match_seed_attempts or 0) + 1
        if bots >= target or sc.__match_seed_attempts >= 10 then sc.__match_roster_ready = true end
    end
    for _, p in ipairs(sc.__order or {}) do
        if not p.__alive then
            local due = sc.__match_respawns[p.__objectID]
            if not due then
                sc.__match_respawns[p.__objectID] = current_time(sc) + M.RESPAWN_MS
            elseif current_time(sc) >= due and not M.Respawn(sc, p) then
                sc.__match_respawns[p.__objectID] = current_time(sc) + 500
            end
        else
            sc.__match_respawns[p.__objectID] = nil
        end
    end
end

-- Installed after GameClientRequire; original scripts remain untouched.
function M.InstallHooks()
    if M.__hooks_installed or not CWanfaEndless then return end
    M.__hooks_installed = true
    local addAI = CGameScene.OnAddAiTick
    function CGameScene:OnAddAiTick(interval)
        if M.IsTimed(self) then return end
        return addAI(self, interval)
    end
    if CGameStartLua then
        function CGameStartLua:OnEnterEndless()
            return M.Start(240000)
        end
        function CGameStartLua:OnEnterLimitTime()
            return M.Start()
        end
    end
    local balance = CWanfaEndless.Balance
    function CWanfaEndless:Balance(reason)
        if M.IsTimed(self.m_pScene) then
            if M.GetTimeRemain(self.m_pScene) == 0 then return M.Finish(self.m_pScene) end
            return -- a death or a full board does not end a timed match early.
        end
        return balance(self, reason)
    end
end

local function clean(value)
    return tostring(value or ""):gsub("[|\r\n\t]", " ")
end
function M.UIState()
    if not g_App then return "none" end
    local sc = g_App.__scene
    if not M.IsTimed(sc) then
        if sc then return "none" end
        local ok, home = invoke(g_App, "GetGameStart")
        local visible = false
        if ok and home then
            if home.__node then
                local vok, v = invoke(home.__node, "is_visible_in_tree")
                visible = vok and v == true
            else
                local vok, v = invoke(home, "IsShow")
                visible = vok and v == true
            end
        end
        return visible and "home" or "none"
    end
    local board = M.Results(sc)
    local director = sc.m_pDirectorObj
    local mine, rank = nil, 0
    for i, row in ipairs(board) do if row.director then mine, rank = row, i; break end end
    mine = mine or { percent = 0, kills = 0, score = 0 }
    local state = { table.concat({ M.IsFinished(sc) and "finished" or "playing",
        M.GetTimeRemain(sc), rank, #board, string.format("%.2f", mine.percent),
        mine.kills, mine.score, M.RespawnRemaining(sc, director),
        clean(board[1] and board[1].name), board[1] and board[1].objectID or 0,
        clean(director and director.__last_death and director.__last_death.reason),
        clean(director and director.__last_death and director.__last_death.killer) }, "|") }
    for i = 1, math.min(#board, 10) do
        local row = board[i]
        state[#state + 1] = table.concat({ i, row.objectID, clean(row.name), row.area,
            string.format("%.2f", row.percent), row.kills, row.score, row.director and 1 or 0,
            row.alive and 1 or 0 }, "|")
    end
    return table.concat(state, "\n")
end
return M
