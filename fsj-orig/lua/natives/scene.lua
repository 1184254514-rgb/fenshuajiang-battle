-- Game-world natives (CGameScene / CPlayer / CManor / scene switching) for the offline single-player build. Claude.
--
-- The original C++ runs the paper.io-like world: a grid of 16-pixel "nodes", players (painters) that move continuously,
-- draw a trail outside their own manor (territory) and capture the enclosed area when they come home; hitting a trail kills
-- its owner. The original Lua (CGameSceneClientLua, CPlayerClientLua, CWanfaEndless, CGameMainLua ...) sits on top of it.
-- Constants come from config/constant.txt, config/scene_list.xml, config/ai.txt. Rendering is done by scripts/scene_view.gd.

SceneSim = SceneSim or {}   -- shared hooks for natives/scene_move|score|items.lua (GPT modules A/B/C)
local NODE = 16                          -- pixels per grid node (constant.txt: "格子=16像素")
local DIRS = {                           -- eDF_* (Left=1 Right=2 Up=4 Bottom=8) -> dx, dy in world pixels.
	[1] = { -1, 0 }, [2] = { 1, 0 }, [4] = { 0, 1 }, [8] = { 0, -1 },   -- engine convention: "up" = +depth (away from the camera)
}
local OPPOSITE = { [1] = 2, [2] = 1, [4] = 8, [8] = 4 }

local function const(name, default)
	local c = CSnakeConstant and CSnakeConstant:Inst()
	local f = c and c["Get" .. name]
	local ok, v = pcall(function() return f and f(c) end)
	if ok and type(v) == "number" then return v end
	return default
end

-- ---------------------------------------------------------------- scene info
local SceneInfo = class()
function SceneInfo:GetWidth() return self.width end
function SceneInfo:GetDepth() return self.depth end
function SceneInfo:IsServer() return false end
function SceneInfo:RandMapID(mask) return 1 end
function SceneInfo:GetMapID() return 1 end
function SceneInfo:GetRoomType() return self.roomType end

-- ---------------------------------------------------------------- manor
function CManor:Ctor() end
function CManor:GetColorID() return self.colorID or 0 end
function CManor:GetManorID() return self.manorID or 0 end
function CManor:GetNodeCount() return self.count or 0 end

-- ---------------------------------------------------------------- scene
local PALETTE_COUNT = 10   -- config/colourtable.txt: 10 manor colours (RGB in map/colour/peise.bmp)

-- NOTE: ShellCommonLua/scene/CGameScene.lua (original Lua) wraps these natives: Ctor/Create/OnSceneCreated/OnSceneDestroy/InsertObject/
-- RemoveObject/CreateObject/DestroyObject/Start (they capture the native functions at load time and dispatch the wanfa events),
-- so the natives below must exist before the original scripts load and must not dispatch those events themselves.
CGameScene.__native_construct = function(self)
	self.__players = {}              -- object id -> player
	self.__order = {}                -- players in insertion order
	self.__nextObjectID = 1
	self.__nextManorID = 1
	self.__time = 0                  -- simulated ms
	self.__started = false
	self.__sceneTime = GetNatureTime()
end

function CGameScene:Create(pRenderer, nRoomType, nAIUseSkill)
	local nSceneID = self.__sceneID or 1
	self.__roomType = nRoomType
	self.__info = setmetatable({ width = 1920, depth = 1920, roomType = nRoomType }, SceneInfo)
	-- scene size from scene_list.xml
	local xml = Host:read_text("config/scene_list.xml")
	for attrs in xml:gmatch("<scene%s+([^>]*)>") do
		if tonumber(attrs:match("nRoomType='(%-?%d+)'")) == 0 and nRoomType == eRT_Endless then
			self.__info.width = tonumber(attrs:match("nWidth='(%d+)'")) or 1920
			self.__info.depth = tonumber(attrs:match("nDepth='(%d+)'")) or 1920
			break
		end
	end
	self.__W = self.__info.width // NODE
	self.__H = self.__info.depth // NODE
	local n = self.__W * self.__H
	self.__owner, self.__trail = {}, {}
	for i = 0, n - 1 do self.__owner[i] = 0; self.__trail[i] = 0 end
	self.__byManor = {}
	Host.scene_view:begin_scene(self.__W, self.__H)
	Host.scene_view.room_type = nRoomType or 0
end

function CGameScene:GetSceneInfo() return self.__info end
function CGameScene:GetSceneID() return self.__sceneID or 0 end
function CGameScene:GetRoomType() return self.__roomType or eRT_Endless end
function CGameScene:GetMusicID() return self.__musicID or 0 end
function CGameScene:GetNodeTotal() return self.__W * self.__H end
function CGameScene:GetSceneTime() return self.__sceneTime end
function CGameScene:GetTimeRemain()
	if self.__timed_match and SceneMatch then return SceneMatch.GetTimeRemain(self) end
	if self.__roomType == eRT_Endless then return 0x7fffffff end
	return math.max(0, (self.__limit or 240000) - self.__time)
end
function CGameScene:GetWanfa() return self.m_pWanfa end
function CGameScene:AllocObjectID(bPlayer)
	local id = self.__nextObjectID; self.__nextObjectID = id + 1
	return id
end
function CGameScene:GetCharacterByID(id) return self.__players[id] end
function CGameScene:GetPlayerByAccountID(acc)
	for _, p in ipairs(self.__order) do if p.__accountID == acc then return p end end
end
function CGameScene:GetObservedPlayerID() return 0 end
function CGameScene:GetObservedPlayer() return nil end
function CGameScene:IsObservedPlayer(p) return false end
function CGameScene:IsObserveredID(id) return false end
function CGameScene:GetAvgLadderStar() return 0 end
function CGameScene:CreateMapItem(nMapID) end        -- map decoration/items: not needed for the 2D placeholder view
function CGameScene:OnSceneCreated() end
function CGameScene:OnSceneDestroy() end
function CGameScene:CreateObject() return nil end
function CGameScene:DestroyObject() end
function CGameScene:InsertObject(pObject, posPixel) end
function CGameScene:RemoveObject(pObject) end
function CGameScene:Start() self.__started = true end

-- SPlayerContex layout written by the original CGameScene:CreatePlayerContex (ShellCommonLua/scene/CGameScene.lua)
local function decode_ctx(buf)
	if type(buf) ~= "table" or not buf.ReadUint64 then return buf or {} end
	buf:SetPosition(0)
	local c = {}
	c.accountID = buf:ReadUint64(); c.manorID = buf:ReadInt32(); c.headID = buf:ReadInt16(); c.equipID = buf:ReadInt16()
	c.musicID = buf:ReadInt16(); c.skillID = buf:ReadInt16()
	for _ = 1, MAX_BattleFace_Count or 0 do buf:ReadInt8() end
	c.starNum = buf:ReadInt32(); c.skillMaxLevel = buf:ReadInt8()
	for _ = 1, Max_Passive_Skill_Num or 0 do buf:ReadInt16() end
	for _ = 1, Max_Passive_Skill_Num or 0 do buf:ReadInt8() end
	c.matchTime = buf:ReadInt32(); c.equipPassiveTop = buf:ReadInt8()
	local nick = buf:ReadUTFBytes((CHARNAME_BYTE_SIZE or 21) + 1) or ""
	c.nickName = (nick:gsub("%z.*", ""))
	return c
end

local function model_for_equip(id)
	local path
	pcall(function()
		local row = g_tblTabFile.equip[id]
		if row and row.szModel and row.szModel ~= "" then path = row.szModel end
	end)
	path = path or "role/mod/p_001.ams"
	return "res://assets/models/" .. (path:match("([^/]+)%.ams$") or "p_001") .. ".glb"
end

-- ---------------------------------------------------------------- players
local COLOUR_ORDER = { 0, 3, 5, 7, 2, 9, 4, 6, 1, 8 }
local function free_player_colour(scene)
	local used = {}
	for _, player in ipairs(scene.__order) do
		if (player.__alive or player.__colour_reserved) and player.__manor then
			used[player.__manor.colorID] = true
		end
	end
	for _, colour in ipairs(COLOUR_ORDER) do
		if not used[colour] then return colour end
	end
end

local function cell(scene, x, y)
	if x < 0 or y < 0 or x >= scene.__W or y >= scene.__H then return nil end
	return y * scene.__W + x
end

local function set_cell(scene, idx, owner, trail)
	local o, t = scene.__owner[idx], scene.__trail[idx]
	if owner ~= nil then scene.__owner[idx] = owner end
	if trail ~= nil then scene.__trail[idx] = trail end
	if SceneScore and SceneScore.Enabled(scene) and o ~= scene.__owner[idx] then
		SceneScore.OnOwnerChanged(scene, idx, o, scene.__owner[idx])
	end
	if o ~= scene.__owner[idx] or t ~= scene.__trail[idx] then
		Host.scene_view:set_cell(idx, scene.__owner[idx], scene.__trail[idx])
		if SceneItemsC then
			SceneItemsC.OnCellChanged(scene, idx, o, t, scene.__owner[idx], scene.__trail[idx])
		end
	end
end

-- rhythm valuation per cell (0 perfect, 1 excellent, 2 ordinary, 3 fault): decides the cell's HEIGHT (music.txt Height1..5)
-- and whether it bounces to the beat (IsJump1..5). New trail cells start at constant InitLineRhythmID; each judged click
-- re-values the newest trail cell (CPlayerClient::UpdateNodeValuation); the initial manor uses InitRhythmID.
local function set_val(scene, idx, grade)
	scene.__val = scene.__val or {}
	scene.__val[idx] = grade
	Host.scene_view:set_cell_valuation(idx, grade)
end

local function sync_player(p)
	local sc = p.__scene
	Host.scene_view:set_player(p.__objectID, p.__x, p.__y, p.__manor.colorID, p.__nick, p.__alive, sc.m_pDirectorObj == p)
end

function CGameScene:AddPlayer(nObjectID, ctxBuf, posPixel, manorWidth)
	-- Ten native colours: reserve on allocation, release on death. Object/manor
	-- IDs can keep growing without making two live opponents share a colour.
	local colour = free_player_colour(self)
	if colour == nil then return nil end
	local ctx = decode_ctx(ctxBuf)
	local p = CPlayerClientLua and CPlayerClientLua:new() or CPlayerClient:new()
	p.__scene = self
	p.__objectID = nObjectID
	p.__accountID = ctx.accountID or 0
	p.__nick = ctx.nickName or ""
	p.__equipID = ctx.equipID or 0
	p.__b_headID = ctx.headID or 0
	p.__musicID = ctx.musicID or 0
	p.__skillID = ctx.skillID or 0
	p.__configuredSkillID = ctx.skillID or 0
	p.__alive = false
	p.__kills, p.__deaths = 0, 0
	p.__dir = 2
	p.__trail = {}
	p.__trailUnder = {}
	p.__trailRevision = 0
	p.__colour_reserved = true
	p.__stats = { allScore = 0, allCoin = 0, areaScore = 0, comboScore = 0, killScore = 0, killCount = 0, pickUpCoin = 0,
		maxGrade = { 0, 0, 0, 0 }, serialKillType = 0, serialKillCoin = 0, maxKillCoin = 0 }
	p.__rhythm = { maxCombo = 0, total = 0, count = { 0, 0, 0, 0 }, combo = 0 }
	local manorID = self.__nextManorID; self.__nextManorID = manorID + 1
	p.__manor = setmetatable({ manorID = manorID, colorID = colour, count = 0 }, CManor)
	Host.scene_view:set_manor_colour(manorID, colour)
	p.__x, p.__y = posPixel:x() + 0.0, posPixel:y() + 0.0
	p.__manorWidth = manorWidth or 80
	self.__players[nObjectID] = p
	self.__order[#self.__order + 1] = p
	if p.OnAlloc then p:OnAlloc() end
	self:InsertObject(p, posPixel)   -- (the original Lua wrapper dispatches the wanfa "OnInsertObject" event)
	if SceneSkills then SceneSkills.InitPlayer(p) end
	return p
end

-- claim the initial square manor around the player and start moving
function CPlayerClient:StartUp(nEquipID)
	local sc = self.__scene
	local half = math.max(1, (self.__manorWidth // NODE) // 2)
	local cx, cy = math.floor(self.__x / NODE), math.floor(self.__y / NODE)
	cx = math.max(half, math.min(sc.__W - half - 1, cx)); cy = math.max(half, math.min(sc.__H - half - 1, cy))
	self.__x, self.__y = (cx + 0.5) * NODE, (cy + 0.5) * NODE
	for yy = cy - half, cy + half do
		for xx = cx - half, cx + half do
			local idx = cell(sc, xx, yy)
			if idx and sc.__owner[idx] == 0 then
				set_val(sc, idx, const("InitRhythmID", 0))
				set_cell(sc, idx, self.__manor.manorID, 0)
				self.__manor.count = self.__manor.count + 1
			end
		end
	end
	self.__alive = true
	self.__colour_reserved = false
	self.__dir = ({ 1, 2, 4, 8 })[math.random(1, 4)]
	Host.scene_view:set_player_model(self.__objectID, model_for_equip(self.__equipID))
	sync_player(self)
	if sc.OnInsertPlayer then sc:OnInsertPlayer(self, CPos16:new(math.floor(self.__x), math.floor(self.__y))) end
	self:OnInsertToScene()
end

function CPlayerClient:OnInsertToScene() end
function CPlayerClient:OnRemoveFrScene() end
function CPlayerClient:OnObjectDestroy() end
function CPlayerClient:OnAlloc() end
function CPlayerClient:OnFree() end
function CPlayerClient:OnDie(killer, bCollide) end
function CPlayerClient:NotifySimple32PropertyChanged(t, v, pre) end
function CPlayerClient:GetScene() return self.__scene end
function CPlayerClient:GetManor() return self.__manor end
function CPlayerClient:GetObjectID() return self.__objectID end
function CPlayerClient:GetAccountID() return self.__accountID end
function CPlayerClient:GetNickName() return self.__nick end
function CPlayerClient:GetEquipID() return self.__equipID end
function CPlayerClient:SetEquipID(id)
	self.__equipID = id
	if self.__objectID then Host.scene_view:set_player_model(self.__objectID, model_for_equip(id)) end
end
function CPlayerClient:GetMusicID() return self.__musicID end
function CPlayerClient:IsAlive() return self.__alive end
function CPlayerClient:GetKillName() return self.__killedBy or "" end
function CPlayerClient:GetSceneSkillTopLevel(id, lv) return 1 end
function CPlayerClient:UseSkill(id) end
function CPlayerClient:GetRenderObject() self.__ro = self.__ro or NullObject() return self.__ro end
function CPlayerClient:GetSimple32Property(t)
	if t == eSPT32_KillCount then return self.__stats.killCount end
	if t == eSPT32_DeathCount then return self.__deaths end
	if t == eSPT32_Level then return 1 end
	if t == eSPT32_Exp then return 0 end
	return 0
end
function CPlayerClient:GetPassiveSkill(i) return 0 end

function CPlayerClient:GetScoreInfo(buf)
	local st = self.__stats
	buf:WriteUint32(st.areaScore + st.comboScore + st.killScore); buf:WriteUint32(st.allCoin)
	buf:WriteUint32(st.areaScore); buf:WriteUint32(st.comboScore); buf:WriteUint32(st.killScore)
	buf:WriteUint8(math.min(255, st.killCount)); buf:WriteUint32(self.__manor.count); buf:WriteUint32(st.pickUpCoin)
	for n = 1, eHG_Count or 4 do buf:WriteUint32(st.maxGrade[n] or 0) end
	buf:WriteUint8(st.serialKillType); buf:WriteUint32(st.serialKillCoin); buf:WriteUint32(st.maxKillCoin)
	buf:SetPosition(0)
end
function CPlayerClient:GetRhythmData(buf)
	local r = self.__rhythm
	buf:WriteUint32(r.maxCombo); buf:WriteUint32(r.total); buf:WriteUint8(0)
	for n = 1, eVal_Count or 4 do buf:WriteUint32(r.count[n] or 0) end
	buf:SetPosition(0)
end

-- ---------------------------------------------------------------- simulation
-- sounds the native scene plays itself (paths are hard-coded in libShellClient.so)
local function scene_sound(path, volume)
	local a = NativeAudio and NativeAudio()
	if a then pcall(a.PlaySound, a, path, volume or 1) end
end

local function kill_player(sc, victim, killer, collide, reason)
	if not victim.__alive or sc.__match_finished then return false end
	if SceneSkills and SceneSkills.BeforeDeath(sc, victim, killer, collide, reason or "trail") == false then return false end
	if SceneScore then SceneScore.BeforeKill(sc, victim) end
	victim.__alive = false
	if SceneSim.a_on_die then SceneSim.a_on_die(sc, victim) end
	victim.__deaths = victim.__deaths + 1
	victim.__killedBy = killer and killer.__nick or ""
	-- remove trail and territory
	for _, idx in ipairs(victim.__trail) do
		if sc.__trail[idx] == victim.__objectID then set_cell(sc, idx, nil, 0) end
	end
	victim.__trail = {}
	victim.__trailUnder = {}
	victim.__trailRevision = (victim.__trailRevision or 0) + 1
	victim.__segStart = 1
	local mid = victim.__manor.manorID
	for idx = 0, sc.__W * sc.__H - 1 do
		if sc.__owner[idx] == mid then set_cell(sc, idx, 0, nil) end
	end
	victim.__manor.count = 0
	if SceneItemsC then SceneItemsC.OnPlayerDeath(sc, victim, killer, collide) end
	sync_player(victim)
	local firstKill = false
	if killer and killer ~= victim then
		killer.__kills = killer.__kills + 1
		killer.__stats.killCount = killer.__stats.killCount + 1
		if SceneScore and SceneScore.Enabled(sc) then
			SceneScore.OnKill(sc, killer, victim)
		else
			killer.__stats.killScore = killer.__stats.killScore + 300
		end
		if not sc.__firstKillDone then sc.__firstKillDone = true; firstKill = true end
		if sc.OnPlayerKill then
			sc:OnPlayerKill(killer.__objectID, victim.__objectID, killer.__stats.killCount, victim.__deaths, firstKill)
		end
		if not (SceneScore and SceneScore.Enabled(sc)) then
			killer:NotifySimple32PropertyChanged(eSPT32_KillCount, killer.__stats.killCount, killer.__stats.killCount - 1)
		end
	end
	if victim == sc.m_pDirectorObj then
		scene_sound("sound/selfdeath.mp3", 1)
	elseif killer == sc.m_pDirectorObj then
		scene_sound("music/otherdeath_01.mp3", 0.8)
	end
	victim:OnDie(killer, collide)
	if SceneScore and SceneScore.Enabled(sc) then
		SceneScore.AfterKill(sc, victim)
	else
		victim:NotifySimple32PropertyChanged(eSPT32_DeathCount, victim.__deaths, victim.__deaths - 1)
	end
	sc:RemoveObject(victim)
	if SceneSkills then SceneSkills.OnKilled(sc, victim, killer) end
	if SceneMatch then SceneMatch.OnPlayerDeath(sc, victim, killer) end
	return true
end

local function close_loop(sc, p)
	local W, H = sc.__W, sc.__H
	local mid = p.__manor.manorID
	if SceneScore then SceneScore.BeginCapture(sc, p) end
	-- Everything that the own territory + this trail cut off from the map border becomes ours (also pockets that were
	-- already enclosed by older territory). Flood "outside" from every map-edge cell over the whole board.
	local function blocked(idx) return sc.__trail[idx] == p.__objectID or sc.__owner[idx] == mid end
	local outside = {}
	local stack = {}
	local function push(x, y)
		local idx = y * W + x
		if not outside[idx] and not blocked(idx) then outside[idx] = true; stack[#stack + 1] = idx end
	end
	for x = 0, W - 1 do push(x, 0); push(x, H - 1) end
	for y = 0, H - 1 do push(0, y); push(W - 1, y) end
	while #stack > 0 do
		local idx = stack[#stack]; stack[#stack] = nil
		local x, y = idx % W, idx // W
		if x > 0 then push(x - 1, y) end
		if x < W - 1 then push(x + 1, y) end
		if y > 0 then push(x, y - 1) end
		if y < H - 1 then push(x, y + 1) end
	end
	-- Capturing a region can cut an opponent's live route just as stepping on
	-- that route does. Resolve those cuts before overwriting cells, so the
	-- opponent cannot keep a chronological path containing missing line units.
	local cut_players = {}
	for idx = 0, W * H - 1 do
		local id = sc.__trail[idx]
		if not outside[idx] and id ~= 0 and id ~= p.__objectID then
			cut_players[id] = true
		end
	end
	local cut_order = {}
	for id in pairs(cut_players) do cut_order[#cut_order + 1] = id end
	table.sort(cut_order)
	for _, id in ipairs(cut_order) do
		local victim = sc.__players[id]
		if victim and victim.__alive then kill_player(sc, victim, p, true, "trail") end
	end
	local bx0, by0, bx1, by1 = 0, 0, W - 1, H - 1
	-- CManorLine::GetValuation (0x33dd4c): the enclosed area takes the most frequent judged grade 0..3 of the closing
	-- line, cells still at InitLineRhythmID not counted; ties favour the better (lower) grade
	local initLine = const("InitLineRhythmID", 3)
	local counts = { [0] = 0, 0, 0, 0 }
	for _, idx in ipairs(p.__trail) do
		local g = sc.__val and sc.__val[idx]
		if g and g ~= initLine and counts[g] then counts[g] = counts[g] + 1 end
	end
	local lineVal, best = initLine, 0
	for g = 0, 3 do if counts[g] > best then best = counts[g]; lineVal = g end end
	local gained = 0
	for y = by0, by1 do
		for x = bx0, bx1 do
			local idx = y * W + x
			if not outside[idx] and sc.__owner[idx] ~= mid then
				local prev = sc.__owner[idx]
				if prev ~= 0 then
					local victim = sc.__byManor[prev]
					if victim then victim.__manor.count = victim.__manor.count - 1 end
				end
				set_val(sc, idx, lineVal)
				set_cell(sc, idx, mid, 0)
				gained = gained + 1
			end
		end
	end
	for _, idx in ipairs(p.__trail) do
		if sc.__owner[idx] ~= mid then
			local prev = sc.__owner[idx]
			if prev ~= 0 then
				local victim = sc.__byManor[prev]
				if victim then victim.__manor.count = victim.__manor.count - 1 end
			end
			set_cell(sc, idx, mid, 0); gained = gained + 1
		else
			set_cell(sc, idx, nil, 0)
		end
	end
	p.__trail = {}
	p.__trailUnder = {}
	p.__trailRevision = (p.__trailRevision or 0) + 1
	p.__segStart = 1
	if gained > 0 and p == sc.m_pDirectorObj then scene_sound("sound/lingdi.mp3", 1) end
	p.__manor.count = p.__manor.count + gained
	if p.__manor.count > (p.__maxCount or 0) then p.__maxCount = p.__manor.count end
	if SceneScore and SceneScore.Enabled(sc) then
		SceneScore.EndCapture(sc, p, gained)
	else
		p.__stats.areaScore = p.__stats.areaScore + gained
	end
	-- players that lost everything die
	for _, o in ipairs(sc.__order) do
		if o ~= p and o.__alive and o.__manor.count <= 0 then kill_player(sc, o, p, false) end
	end
end

local function rollback_trail(sc, p, crossing)
	local trail = p.__trail or {}
	local keep
	for index = #trail, 1, -1 do
		if trail[index] == crossing then keep = index; break end
	end
	if not keep then return false end
	local under = p.__trailUnder or {}
	for index = #trail, keep + 1, -1 do
		local idx = trail[index]
		if sc.__trail[idx] == p.__objectID then
			set_cell(sc, idx, nil, 0)
			set_val(sc, idx, under[idx] or 0)
			Host.scene_view:clear_trail_cell(idx)
		end
		under[idx] = nil
		trail[index] = nil
	end
	p.__trailUnder = under
	p.__segStart = math.min(p.__segStart or 1, keep + 1)
	p.__trailRevision = (p.__trailRevision or 0) + 1
	-- Discard optional manual trace-back caches after the route topology changes.
	p.__a_path, p.__a_cells, p.__a_visits, p.__a_home = nil, nil, nil, nil
	p.__a_under = {}
	return true
end

local function enter_node(sc, p, x, y)
	local idx = cell(sc, x, y)
	if not idx then return end
	local t = sc.__trail[idx]
	if t ~= 0 then
		local owner = sc.__players[t]
		-- Applies identically to the director and every AI: retain the route to
		-- the crossing, erase only the suffix, and award no enclosed territory.
		if owner == p then
			rollback_trail(sc, p, idx)
			return
		end
		if owner and owner.__alive then kill_player(sc, owner, p, true, "trail") end
	end
	if sc.__owner[idx] == p.__manor.manorID then
		if #p.__trail > 0 then close_loop(sc, p) end
	else
		if sc.__trail[idx] ~= p.__objectID then
			p.__trailUnder = p.__trailUnder or {}
			p.__trailUnder[idx] = sc.__val and sc.__val[idx] or 0
			p.__trail[#p.__trail + 1] = idx
			set_val(sc, idx, const("InitLineRhythmID", 3))
			set_cell(sc, idx, nil, p.__objectID)
		end
	end
end

-- called by the rhythm window (natives/rhythm_wnd.lua) for every judgement of this player's clicks / missed beats
function CPlayerClient:RhythmSpeed(grade)
	self.__speedup = (grade ~= 3)
	local sc = self.__scene
	-- the judgement belongs to the line unit laid since the previous click (CManorNode::GetLast -> CManorUnit::SetValuation)
	local trail = self.__trail or {}
	local from = math.min(self.__segStart or 1, #trail + 1)
	if sc then
		for k = from, #trail do
			local idx = trail[k]
			if sc.__trail[idx] == self.__objectID then set_val(sc, idx, grade) end
		end
	end
	self.__segStart = #trail + 1
	self.__lastGrade = grade
end

function CPlayerClient:SetDirection(dir)
	if DIRS[dir] and dir ~= OPPOSITE[self.__dir] then self.__dir = dir end
end

local function step_player(sc, p, dtMs)
	if not p.__alive then return end
	-- CPlayerClient::RhythmSpeed -> SpeedUp: on-beat clicks run at HighSpeed, a fault/missed beat drops back to MoveSpeed
	local speed = SceneSim.a_move_speed and SceneSim.a_move_speed(p)
		or (p.__speedup and const("HighSpeed", 180) or const("MoveSpeed", 80))
	local dist = speed * dtMs / 1000.0
	local dx, dy = DIRS[p.__dir][1], DIRS[p.__dir][2]
	while dist > 0 and p.__alive do
		local s = math.min(dist, 4.0)
		dist = dist - s
		local ox, oy = math.floor(p.__x / NODE), math.floor(p.__y / NODE)
		local tx, ty = p.__x + dx * s, p.__y + dy * s
		local nx, ny = math.floor(tx / NODE), math.floor(ty / NODE)
		-- the map border is a wall: the painter stops in front of it (no death) until it turns
		if (nx ~= ox or ny ~= oy) and not cell(sc, nx, ny) then break end
		p.__x, p.__y = tx, ty
		if nx ~= ox or ny ~= oy then SceneSim.enter_node(sc, p, nx, ny) end
		if SceneSim.a_after_position then
			SceneSim.a_after_position(sc, p, tx - dx * s, ty - dy * s, tx, ty)
		end
		if p.__alive and SceneItemsC then
			SceneItemsC.OnPlayerMoved(sc, p, tx - dx * s, ty - dy * s, tx, ty)
		end
	end
	if p.__alive then sync_player(p) end
end

function CGameScene:Update(dtMs)
	if not self.__started or self.__match_finished then return end
	if self.__timed_match and SceneMatch then dtMs = math.min(dtMs, SceneMatch.GetTimeRemain(self)) end
	self.__time = self.__time + dtMs
	if SceneSkills then SceneSkills.Tick(self, dtMs) end
	if self.__byManor == nil then self.__byManor = {} end
	for _, p in ipairs(self.__order) do self.__byManor[p.__manor.manorID] = p end
	-- AI "clicks" on every beat of the song: a random judgement (mostly on-beat) drives its speed and cell heights
	local view = Host.scene_view
	local now = view:music_ms()
	local n = view:beat_count()
	self.__beatIdx = self.__beatIdx or 0
	if n > 0 then
		local fired = false
		while self.__beatIdx < n and view:beat_at(self.__beatIdx) <= now do self.__beatIdx = self.__beatIdx + 1; fired = true end
		if self.__beatIdx >= n and now < view:beat_at(0) then self.__beatIdx = 0 end   -- looped song
		if fired then
			for _, p in ipairs(self.__order) do
				if p.__ai and p.__alive then
					-- CAIBase::OnRhythm (0x3309e4): grade = round(GaussRand(mean, sigma)) from ai.txt RhythmGaussian,
					-- redrawn until 0..3; then speed (non-fault -> HighSpeed) and line valuation like a player's click
					local cfg = p.__aiCfg or {}
					local mean, sigma = cfg.rhythmMean or 1, cfg.rhythmSigma or 1
					local g
					for _ = 1, 32 do
						local u1, u2 = math.max(1e-9, math.random()), math.random()
						local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
						g = math.floor(mean + z * sigma + 0.5)
						if g >= 0 and g <= 3 then break end
					end
					if g < 0 or g > 3 then g = math.max(0, math.min(3, g)) end
					p:RhythmSpeed(g)
				end
			end
		end
	end
	for _, p in ipairs(self.__order) do
		if p.__ai then p.__ai(p, dtMs) end
		SceneSim.step_player(self, p, dtMs)
	end
	-- The shield's original description permits head contact kills. Plain
	-- unshielded bodies do not acquire a new collision rule here.
	for i = 1, #self.__order do
		local a = self.__order[i]
		if a.__alive then
			for j = i + 1, #self.__order do
				local b = self.__order[j]
				if a.__alive and b.__alive and (a.__x - b.__x)^2 + (a.__y - b.__y)^2 < NODE^2 then
					local aa, ba = a:GetSimple32Property(9), b:GetSimple32Property(9)
					if aa > ba and aa > 0 then kill_player(self, b, a, true, "body")
					elseif ba > aa and ba > 0 then kill_player(self, a, b, true, "body") end
				end
			end
		end
	end
	-- camera height follows the director's share of the board (constant.txt Min/MaxAreaRatio -> Min/MaxCameraY)
	local d = self.m_pDirectorObj
	if d and d.__manor and self.__W then
		Host.scene_view:set_area_ratio(d.__manor.count / (self.__W * self.__H))
	end
	if SceneMatch then SceneMatch.Tick(self, dtMs) end
end

-- score list for the HUD: 6 bytes per player (objectID u16, score u32)
function CGameScene:UpdateRank()
	local gm = g_App and g_App:GetGameMain()
	if not gm or not self.m_pDirectorObj then return end
	local list = {}
	for _, p in ipairs(self.__order) do if p.__alive then list[#list + 1] = p end end
	local buf = CBufferStream:new()
	for _, p in ipairs(list) do
		buf:WriteUint16(p.__objectID)
		buf:WriteUint32(p.__manor.count)
	end
	buf:SetPosition(0)
	gm:UpdateRank(self.m_pDirectorObj.__objectID, buf, #list, true)
end

-- ---------------------------------------------------------------- AI
local AI_TABLE
local function load_ai()
	if AI_TABLE then return end
	AI_TABLE = {}
	local text = Host:read_text("config/ai.txt")
	local first = true
	for line in text:gmatch("[^\r\n]+") do
		if first then first = false else
			local c = {}
			for cellv in (line .. "\t"):gmatch("([^\t]*)\t") do c[#c + 1] = cellv end
			local function num(i) return tonumber((c[i] or ""):match("^[^;]+")) or 0 end
			local rg1, rg2 = (c[11] or ""):match("^%s*([%d%.%-]+)%s*;%s*([%d%.%-]+)")
			AI_TABLE[tonumber(c[1])] = { think = num(3), changeDir = num(4), enclose = num(5), expand = num(6), attack = num(7),
				rhythmMean = tonumber(rg1) or 1, rhythmSigma = tonumber(rg2) or 1 }
		end
	end
end

local function ai_think(p, dtMs)
	local sc = p.__scene
	local cfg = p.__aiCfg
	p.__aiTimer = (p.__aiTimer or 0) + dtMs
	if p.__aiTimer < math.max(100, cfg.changeDir * 0.5) then return end
	p.__aiTimer = 0
	local cx, cy = math.floor(p.__x / NODE), math.floor(p.__y / NODE)
	local dx, dy = DIRS[p.__dir][1], DIRS[p.__dir][2]
	local function free(x, y)
		local idx = cell(sc, x, y)
		return idx ~= nil and sc.__trail[idx] ~= p.__objectID
	end
	local home = p.__manor.count > 0
	local inside = sc.__owner[cell(sc, cx, cy) or 0] == p.__manor.manorID
	p.__leg = p.__leg or 0
	if inside and #p.__trail == 0 then
		-- start an excursion: pick a direction away from walls
		local choices = {}
		for d, v in pairs(DIRS) do
			if d ~= OPPOSITE[p.__dir] or true then
				local ok = true
				for k = 1, 4 do if not free(cx + v[1] * k, cy + v[2] * k) then ok = false break end end
				if ok then choices[#choices + 1] = d end
			end
		end
		if #choices > 0 then p.__dir = choices[math.random(1, #choices)] end
		local span = math.max(3, (cfg.expand // NODE) * (0.6 + math.random() * 0.9))
		p.__plan = { out = math.floor(span), side = math.floor(span * (0.6 + math.random() * 0.8)), stage = 0, count = 0, dir0 = p.__dir }
		p.__aiTimer = 0
		return
	end
	local plan = p.__plan
	if plan and not inside then
		plan.count = plan.count + 1
		local function turn(left)
			local d = p.__dir
			local map = left and { [1] = 8, [8] = 2, [2] = 4, [4] = 1 } or { [1] = 4, [4] = 2, [2] = 8, [8] = 1 }
			p.__dir = map[d]
		end
		local limit = plan.stage == 0 and plan.out or plan.stage == 1 and plan.side or plan.out + 2
		if plan.count >= limit and plan.stage < 3 then
			plan.stage = plan.stage + 1; plan.count = 0
			turn(plan.left == nil and (math.random() < 0.5) or plan.left)
			if plan.left == nil then plan.left = (math.random() < 0.5) end
		end
		-- avoid walls / own trail directly ahead
		local nx, ny = cx + DIRS[p.__dir][1] * 2, cy + DIRS[p.__dir][2] * 2
		if not free(nx, ny) then
			p.__dir = ({ 1, 2, 4, 8 })[math.random(1, 4)]
			if p.__dir == OPPOSITE[dir] then p.__dir = OPPOSITE[p.__dir] end
		end
		if plan.stage >= 3 then
			-- head back toward the manor centre
			local mx, my
			for _, idx in ipairs(p.__trail) do end
			p.__dir = math.abs(p.__homeX - cx) > math.abs(p.__homeY - cy) and ((p.__homeX > cx) and 2 or 1) or ((p.__homeY > cy) and 4 or 8)
		end
	elseif not inside and not plan then
		p.__dir = ({ 1, 2, 4, 8 })[math.random(1, 4)]
	end
end

function CGameScene:SpawnAI(nAIID)
	if free_player_colour(self) == nil then return nil end
	load_ai()
	local cfg = AI_TABLE[nAIID] or AI_TABLE[1]
	local W, H = self.__W, self.__H
	for _ = 1, 30 do
		local x, y = math.random(6, W - 7), math.random(6, H - 7)
		local ok = true
		for yy = y - 4, y + 4 do for xx = x - 4, x + 4 do
			if self.__owner[yy * W + xx] ~= 0 or self.__trail[yy * W + xx] ~= 0 then ok = false end
		end end
		if ok then
			local id = self:AllocObjectID(true)
			local names = { "小粉刷", "油漆匠", "涂鸦王", "刷刷刷", "彩虹侠", "大漆桶", "墙绘师", "喷漆手", "调色盘", "滚筒哥" }
			local ctx = self:CreatePlayerContex(0, 0, 0, 0, 0, 0, {}, 0, 1, {}, {}, names[(id % #names) + 1] .. id, 0, 1)
			local p = self:AddPlayer(id, ctx, CPos16:new(x * NODE + 8, y * NODE + 8), 80)
			if SceneAI then
				p.__aiCfg = cfg; p.__homeX, p.__homeY = x, y
				SceneAI.SetPlayerConfig(p, nAIID)
				p.__ai = SceneAI.Think
			else
				p.__ai = ai_think; p.__aiCfg = cfg; p.__homeX, p.__homeY = x, y
			end
			p:StartUp(0)
			return p
		end
	end
end

function CGameScene:CreateConfigAI()
	local xml = Host:read_text("config/scene_list.xml")
	self.__aiPlan = {}
	for attrs, body in xml:gmatch("<scene%s+([^>]*)>(.-)</scene>") do
		if tonumber(attrs:match("nRoomType='(%-?%d+)'")) == 0 then
			local cfg = body:match("<aiconfig>(.-)</aiconfig>") or ""
			for t, blk in cfg:gmatch("<time%s+nGameTime='(%d+)'>(.-)</time>") do
				local entry = { time = tonumber(t), ais = {} }
				for id, cnt in blk:gmatch("<AI%s+nID='(%d+)'%s+nCount='(%d+)'") do
					entry.ais[#entry.ais + 1] = { id = tonumber(id), count = tonumber(cnt) }
				end
				self.__aiPlan[#self.__aiPlan + 1] = entry
			end
			self.__maxCount = tonumber(body:match("nMaxCount='(%d+)'")) or 10
			self.__addAiInterval = tonumber(body:match("nAddAiInterval='(%d+)'")) or 2000
			break
		end
	end
	self.__aiTimer = self.__addAiInterval or 2000
end

-- called by CWanfaEndless every 100 ms: keep the number of AI up with the plan for the elapsed game time
function CGameScene:OnAddAiTick(interval)
	if not self.__aiPlan then return end
	self.__aiTimer = (self.__aiTimer or 0) + interval
	if self.__aiTimer < (self.__addAiInterval or 2000) then return end
	self.__aiTimer = 0
	local alive = 0
	for _, p in ipairs(self.__order) do if p.__alive then alive = alive + 1 end end
	if alive >= (self.__maxCount or 10) then return end
	local want = 0
	local plan
	for _, e in ipairs(self.__aiPlan) do if e.time <= self.__time then plan = e end end
	if not plan then return end
	local ai_alive = 0
	for _, p in ipairs(self.__order) do if p.__alive and p.__ai then ai_alive = ai_alive + 1 end end
	local total = 0
	local firstID = 1
	for i, a in ipairs(plan.ais) do total = total + a.count; if i == 1 then firstID = a.id end end
	if ai_alive < total then
		local pick = plan.ais[math.random(1, #plan.ais)]
		self:SpawnAI(pick.id or firstID)
	end
end

-- ---------------------------------------------------------------- app: scene switching, director, input
function CGameAppClient:SwitchGame(nSceneID, nRoomType, nMusicID)
	local scene = CGameSceneClientLua:new()
	scene.__sceneID = nSceneID
	scene.__musicID = nMusicID
	self.__scene = scene
	self:OnSceneAlloc(scene)
	scene:Create(nil, nRoomType, false)       -- original wrapper creates the wanfa, then the native part
	self:GetGameStart():ShowWnd(false)
	local gm = self:GetGameMain()
	gm:ShowWnd(true)
	scene:OnSceneCreated()                    -- Lua override -> wrapper dispatches "OnSceneCreated" to the wanfa
	scene:Start()                             -- wrapper dispatches "OnSceneStart"
	gm:Start()
	Host:start_music(nMusicID)
	return scene
end

function CGameAppClient:SwitchStart()
	local scene = self.__scene
	if scene then
		scene:OnSceneDestroy()
		Host.scene_view:end_scene()
		if self.OnSceneFree then self:OnSceneFree(scene) end
		self.__scene = nil
		self.m_Scene = nil
	end
	local gm = self:GetGameMain()
	if gm then gm:ShowWnd(false) end
	self:GetGameStart():ShowWnd(true)
end

function CGameAppClient:GetScene() return self.__scene end
function CGameAppClient:GetManorColor(id)
	local c = Host.scene_view:palette_argb(id or 0)
	return c
end

-- hooks that need the ORIGINAL scripts to be loaded (called from lua/start_game.lua after GameClientRequire)
function SceneInstallHooks()
	-- the original CGameClient:SetDirector stores the director on the Lua side; we also tell the scene (for HUD/camera)
	local orig_set_director = CGameClient.SetDirector
	function CGameClient:SetDirector(pObject)
		if orig_set_director then orig_set_director(self, pObject) end
		if pObject and pObject.__scene then
			pObject.__scene.m_pDirectorObj = pObject
			Host.scene_view:set_follow(pObject.__objectID)
			sync_player(pObject)
		end
	end
end

-- ---------------------------------------------------------------- game main (HUD) natives: input + rhythm
local function director() return g_App and g_App:GetDirector() end

local GRADE = { PERFECT = 1, EXCELLENT = 2, ORDINARY = 3, FAULT = 4 }
function CGameMain:ClickDir(dir)
	if not g_App or not g_App.__scene or g_App.__scene.__match_finished then return false end
	local p = director()
	if not p or not p.__alive then return end
	-- judgement, combo and feedback belong to the original rhythm window (natives/rhythm_wnd.lua)
	local rhythm = self:GetRhythmWnd()
	if rhythm.EnableRhythm then rhythm:EnableRhythm(true) end
	local grade, notified = rhythm:ClickRhythm()
	p:SetDirection(dir)
	return grade, notified
end
function CGameMain:GetCamera() return self.__camera end
function CGameMain:OnKeyDownEvent(Event) end

local Rhythm = class()
function Rhythm:Start(noticeBarID) end
function Rhythm:ShowWnd(b) end
function Rhythm:IsShow() return true end
local Camera = class()
function Camera:GetScale() return 1 end
function Camera:ScenePosToUIPos(x, y, vOut) return vOut end
function Camera:GetRadian() return 0 end
CGameMain.__native_construct = (function(prev)
	return function(self, ...)
		if prev then prev(self, ...) end
		self.__rhythmWnd = nil   -- natives/rhythm_wnd.lua creates the original CRhythmWnd on demand
		self.__camera = setmetatable({}, Camera)
	end
end)(CGameMain.__native_construct)
function CGameAppClient:GetCamera() return CGameMain.__cameraObj or setmetatable({}, Camera) end
function CGameMain:PlaySound(t) end
function CGameMain:DestoryAllSound() end

-- per-frame simulation driver
local _tick_scene = NativeTickUpdate
function NativeTickUpdate(dt)
	local sc = g_App and g_App.__scene
	if sc then
		local step = math.min(dt, 100)
		sc:Update(step)
	end
	if _tick_scene then _tick_scene(dt) end
end

-- keyboard direction keys (SceneView._unhandled_key_input) -> the same path as the on-screen direction buttons
function NativeKeyDir(dir)
	local gm = g_App and g_App:GetGameMain()
	if gm and g_App.__scene and not g_App.__scene.__match_finished then gm:ClickDir(dir) end
end

function CPlayerClient:GetWaypointListCount() return #(self.__trail or {}) end

-- positions / camera used by the HUD (track tips, kill info ...)
function CPlayerClient:GetPixelPos() return CVector2f:new(self.__x, self.__y) end
local SceneCamera = class()
function SceneCamera:GetScene() return g_App and g_App.__scene end
function SceneCamera:GetScale() return 1 end
function SceneCamera:GetRadian() return 0 end
local sceneCamera = setmetatable({}, SceneCamera)
function CGameAppClient:GetCamera() return sceneCamera end
function CGameMain:GetCamera() return sceneCamera end
-- world position (x, *, z) -> UI pixel position
function CGameAppClient:ScenePosToUIPos(v3, pCamera, vOut)
	local p = Host.scene_view:world_to_screen(v3:x(), v3:z())
	if vOut then vOut:x(p.x); vOut:y(p.y) end
	return vOut
end

-- native part of CGameMain:Start (the Lua override calls CGameMain.Start(self) first): hide the engine's debug FPS readout
function CGameMain:Start()
	local w = self:GetDlgChild("W_fps")
	if w then w:ShowWnd(false) end
end

-- largest territory the director reached this match (used by the daily-task scoring in CWanfaEndless:Balance)
function CGameMain:GetMaxNodeCount()
	local d = g_App and g_App:GetDirector()
	return d and math.max(d.__maxCount or 0, d.__manor and d.__manor.count or 0) or 0
end

-- exports + extension modules (GPT A: movement/trace-back, B: score/settlement, C: coins/exp crystals); Claude
SceneSim.const = const
SceneSim.cell = cell
SceneSim.set_cell = set_cell
SceneSim.set_val = set_val
SceneSim.sync_player = sync_player
SceneSim.enter_node = enter_node
SceneSim.kill_player = kill_player
SceneSim.rollback_trail = rollback_trail
SceneSim.step_player = step_player
require("natives.scene_move")
require("natives.scene_score")
SceneItemsC = require("natives.scene_items")
