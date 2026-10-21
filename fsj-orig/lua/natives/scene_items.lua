-- GPT audit:
-- Local endless: the supplied client code has no local exp-crystal creation
-- path. The only supplied/direct CreatExpUnit caller is the field notification
-- handler (0x3882c0). Server-exp injection is retained behind
-- ENABLE_SERVER_EXP_ITEMS=false. Unrecovered local seeding/refill and rewards
-- have separate flags, both false by default.
--
-- Local death drops DO run: CPlayerClient::KilledByPlayer (0x3965ac) calls
-- CPlayer::KilledByPlayer (0x342054), which dispatches scene virtual +0xec.
-- CGameSceneClient::DropOut (0x38fe1e) calls the generator (0x3398d4).
-- The generator dispatches virtual +0xf0 to the array overload (0x337c80).
-- Extra drops come from the KILLER's property 0x0c, truncated to u8.
--
-- Every former ASSUMPTION:
-- I01 SETTLED (0x3413a4): pickup uses property ID 0; no guessed gold enum.
-- I02 STILL OPEN: CPlayer constructor/OnObjectCreated/StartUp bodies assigning
--     InitGold are missing. Preserve the inherited property value; do not
--     assign InitGold to property 0.
-- I03 SETTLED (0x3413a4): PickUpCoin ignores roomType and forwards the raw count
--     to property-adder virtual +0xcc, with property ID 0. No prize.txt factor.
-- I04 STILL OPEN: CItem::OnCircle (0x33c8d2) and server exp-property updates are
--     missing. The client override (0x391ca4) contains no explicit exp grant.
--     The former cumulative ExpManorGainExp fallback is retained only opt-in.
-- I05 SETTLED (0x337370, 0x3882c0): CreatExpUnit does not test WhetherShowExp;
--     autonomous local creation is not established by these client paths.
-- I06 STILL OPEN: CGameScene constructor/Create initialization of
--     +0x258/+0x25c/+0x260/+0x268/+0x26c is missing. Interior-grid initialization
--     below remains a fallback, not recovered native initialization.
-- I07 STILL OPEN: CCharacter::OnInsertToScene (0x3336f0), OnSetPosition
--     (0x33373c), and cell-list insertion bodies are missing. Newest-ID-first
--     item enumeration remains the previous fallback.
-- I08 STILL OPEN: callers selecting between GetManorEdgeExpGrid (0x337a08)
--     and GetFreeExpGrid (0x337978) are missing. The former respawn preference
--     remains confined to the opt-in local refill fallback.
-- I09 SETTLED (0x391aba, 0x391b24): state 1 becomes 2 on rb1 animation end,
--     independently of MoveTo. There is no recovered 10 ms arming timer.
-- I10 STILL OPEN: CCharacter::MoveTo wrappers (0x333b58, 0x333974) and movement
--     tick are missing. The old flight_ms/interpolation interpretation remains
--     a presentation/movement fallback; it is not used to change item state.
-- I11 SETTLED (0x3398d4): drop bounds use unsigned, inclusive comparisons against
--     GetWidth/GetDepth. Do not replace them with logical-grid bounds or cap
--     the native expanding-ring search.
-- I12 SETTLED (0x342054, 0x3965ac, 0x38fe1e): recovered death-drop call chain;
--     use victim property 7 and killer property 0x0c, with no property-0 debit.
-- I13 SETTLED (0x341b44; supplied constant-offset table): +0x148 is PickExpRange;
--     expansion is its unsigned value * 16 plus signed property 0x0a.
-- I14 SETTLED (0x343488): CheckItem receives the old/new centre bounding
--     rectangle, before the remaining collision/manor processing.
-- I15 STILL OPEN: CManor::OnAddUnit (0x33dfd0) and OnRemoveUnit (0x33e138) are
--     missing. Their item dispatch remains the previous cell-change fallback.
-- I16 SETTLED (0x33f5fc, 0x339ca0): NONZERO Tongxing sets bit 1; NONZERO Quandi
--     sets bit 2. The supplied map rows therefore have flags 0.
-- I17 STILL OPEN: object-map insertion/comparator and CCharacter::IsValid
--     (0x333378) are missing. EnumObject (0x336c66) walks the native tree;
--     ascending IDs and __c_inScene remain the adapter's ordering/validity.
-- I18 STILL OPEN: the field-side function reading ExpManorCount and maintaining
--     a live target is absent, with no symbol supplied. Target refill is opt-in.
-- I19 STILL OPEN: the CItem lifetime callback stored at item+0x6c by constructor
--     (0x33c8e0) is missing. Calling Die on expiry remains the previous fallback.
-- I20 STILL OPEN: the field-side refill scheduler/callers are absent, with no
--     symbol supplied. Following-update refill remains opt-in.
-- I21 SETTLED (CGameClient.lua caller supplied by user; 0x339ca0): map creation
--     is explicit after SwitchGame. No automatic Create-time map creation or
--     invented idempotence.
--
-- Additional parity limits in the supplied input:
-- STILL OPEN: property-adder virtual +0xcc and property-setter +0xc8 targets;
-- use inherited Add/SetSimple32Property when available, otherwise shadow only
-- the known raw property value. No invented settlement/stat-field writes.
-- STILL OPEN: SetExpUnidle (0x337104), FindItemType (0x33706c), CItem::Die,
-- CItem::OnCircle (0x33c8d2), and OnFreeCircle (0x33c8d8) bodies are absent.
-- Their existing algorithms remain fallbacks.
-- STILL OPEN: AddUnitFlag (0x33702a)/ClearUnitFlag (0x337050) bodies; overlapping
-- flag reference counting below is retained, not proven native behavior.
-- STILL OPEN: GetFreeGrid cache initialization and UpdateIdleGrid (0x336796);
-- free-placement geometry is recovered, native cache/permutation history is not.
-- STILL OPEN: GetWidth (0x33660c), GetDepth (0x336614), GetCharacterList
-- (0x336734), FormatToLogic (0x32f84c), and Gamma Rand bodies. Existing grid,
-- coordinate, out-of-bounds, and RNG adapters are not bit-exact native bodies.
-- STILL OPEN: HUD virtual +0x11c, base CCharacter removal/movement, SceneSim hook
-- timing. The Godot host delivers the recovered Item:OnAniPlayEnd event via
-- SceneView3D.item_animation_finished; Tick does not fabricate animation endings.

local pack_values, unpack_values = table.pack, table.unpack   -- the original Help.lua later replaces table.pack (Claude)

local C = {}
SceneItemsC = C

C.ENABLE_SERVER_EXP_ITEMS = false
C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL = false
C.ENABLE_UNVERIFIED_LOCAL_EXP_REWARDS = false

local NODE = 16
local floor, min, max = math.floor, math.min, math.max

C.FLAG_NO_MOVE = 1
C.FLAG_NO_CIRCLE = 2

local Item = {}
Item.__index = Item

local function trunc(n)
	return n < 0 and math.ceil(n) or floor(n)
end

local function integer(v, default)
	return trunc(tonumber(v) or default or 0)
end

local function u32(v)
	return integer(v) & 0xffffffff
end

local function s32(v)
	v = u32(v)
	return v >= 0x80000000 and v - 0x100000000 or v
end

local function s16(v)
	v = integer(v) & 0xffff
	return v >= 0x8000 and v - 0x10000 or v
end

local function boolean(v)
	return v == true or (type(v) == "number" and v ~= 0)
end

local function constant(name, default)
	local inst = CSnakeConstant and CSnakeConstant:Inst()
	local f = inst and inst["Get" .. name]
	if type(f) == "function" then
		local ok, value = pcall(f, inst)
		if ok and type(value) == "number" then return value end
	end
	return default
end

local function component(v, name, index)
	if v == nil then return 0 end
	local value = v[name]
	if type(value) == "function" then value = value(v) end
	if value == nil then value = v[index] end
	return tonumber(value) or 0
end

local function xy(v)
	return component(v, "x", 1), component(v, "y", 2)
end

local function write_xy(v, x, y)
	if type(v.x) == "function" then v:x(x) else v.x = x end
	if type(v.y) == "function" then v:y(y) else v.y = y end
end

local function endless(sc)
	return sc ~= nil and sc.__W ~= nil and sc.__owner ~= nil
		and sc:GetRoomType() == 0
end

local function server(sc)
	if type(sc.IsServer) == "function" then return sc:IsServer() end
	local info = sc:GetSceneInfo()
	return info and type(info.IsServer) == "function" and info:IsServer() or false
end

local function scene_width(sc)
	if type(sc.GetWidth) == "function" then
		local value = sc:GetWidth()
		if type(value) == "number" then return u32(value) end
	end
	return sc.__W * NODE
end

local function scene_depth(sc)
	if type(sc.GetDepth) == "function" then
		local value = sc:GetDepth()
		if type(value) == "number" then return u32(value) end
	end
	return sc.__H * NODE
end

local function cell_index(sc, gx, gy)
	if gx < 0 or gy < 0 or gx >= sc.__W or gy >= sc.__H then return nil end
	return gy * sc.__W + gx
end

local function position_index(sc, x, y)
	return cell_index(sc, s16(trunc(x / NODE)), s16(trunc(y / NODE)))
end

local function logic_centre(g)
	return s16(s16(g) * NODE + 8)
end

local function director(sc)
	local p = sc.m_pDirectorObj
	if not p and g_App and type(g_App.GetDirector) == "function" then
		p = g_App:GetDirector()
	end
	return p and p.__scene == sc and p or nil
end

local function manor_player(sc, mid)
	local p = sc.__byManor and sc.__byManor[mid]
	if p then return p end
	for _, candidate in ipairs(sc.__order or {}) do
		if candidate.__manor and candidate.__manor.manorID == mid then
			return candidate
		end
	end
end

-- Properties.

C.__c_propertyNames = {
	gold = { "eSPT32_Gold", "eSPT32_Coin" },
	exp = { "eSPT32_Exp" },
}
C.__c_propertyIDs = { gold = 0 }

function C.BindProperty(name, id)
	assert(C.__c_propertyNames[name], "unknown item property: " .. tostring(name))
	assert(type(id) == "number", "SPT32 property ID must be numeric")
	if name == "gold" then
		assert(id == 0, "CPlayer::PickUpCoin uses property 0")
	end
	C.__c_propertyIDs[name] = id
end

local function property_id(name)
	local cached = C.__c_propertyIDs[name]
	if cached ~= nil then return cached end

	for _, symbol in ipairs(C.__c_propertyNames[name]) do
		local value = rawget(_G, symbol)
		if type(value) ~= "number" then
			local enum = rawget(_G, "ESimple32PropertyType")
			if type(enum) == "table" then
				value = enum[symbol] or enum[symbol:gsub("^eSPT32_", "")]
			end
		end
		if type(value) == "number" then
			C.__c_propertyIDs[name] = value
			return value
		end
	end
end

local function prior_property(p, id)
	if id == nil then return nil end
	local f = C.__c_priorGetSimple
	if type(f) ~= "function" then return nil end
	local ok, value = pcall(f, p, id)
	if ok and type(value) == "number" then return u32(value) end
end

local function notify(p, name, value, previous, force)
	local id = property_id(name)
	if id ~= nil and (force or value ~= previous)
		and type(p.NotifySimple32PropertyChanged) == "function" then
		p:NotifySimple32PropertyChanged(id, value, previous)
	end
end

function C.InitPlayer(p)
	if p.__c_initialized then return end
	p.__c_initialized = true
	p.__c_gold, p.__c_exp = 0, 0

	-- I02: native initialization is missing. Preserve the inherited values.
	p.__c_gold = prior_property(p, 0) or 0
	p.__c_exp = prior_property(p, property_id("exp")) or 0
	p.__c_goldOverride = false
	p.__c_expOverride = false
	p.__c_coinItems = 0
	p.__c_pickUpGold = 0
	p.__c_deathDropped = false
	p.__c_extraDeathCoins = 0
end

function C.SetGold(p, value)
	C.InitPlayer(p)
	local previous = p.__c_gold
	value = u32(value)

	if type(p.SetSimple32Property) == "function" then
		p:SetSimple32Property(0, value)
		local reported = prior_property(p, 0)
		p.__c_gold = reported or value
		p.__c_goldOverride = reported == nil
	else
		p.__c_gold = value
		p.__c_goldOverride = true
		notify(p, "gold", value, previous)
	end
	return p.__c_gold
end

function C.SetExp(p, value)
	C.InitPlayer(p)
	local previous = p.__c_exp
	local id = property_id("exp")
	value = u32(value)

	if id ~= nil and type(p.SetSimple32Property) == "function" then
		p:SetSimple32Property(id, value)
		local reported = prior_property(p, id)
		p.__c_exp = reported or value
		p.__c_expOverride = reported == nil
	else
		p.__c_exp = value
		p.__c_expOverride = true
		notify(p, "exp", value, previous)
	end
	return p.__c_exp
end

function C.SetObservedAccountID(sc, accountID)
	sc.__c_observedAccountID = accountID
end

function C.CanCreditCoin(p)
	local sc = p.__scene
	if not sc then return false end
	if director(sc) == p then return true end

	local account = sc.__c_observedAccountID
	if account == nil and type(sc.GetObservedPlayer) == "function" then
		local observed = sc:GetObservedPlayer()
		account = observed and observed:GetAccountID()
	end
	return account ~= nil and account ~= 0 and account ~= "0"
		and account == p.__accountID
end

function C.RefreshDirector(sc)
	local p = director(sc)
	if p == sc.__c_lastDirector then return end
	sc.__c_lastDirector = p
	if not p then return end
	C.InitPlayer(p)
	if not p.__c_goldOverride then
		p.__c_gold = prior_property(p, 0) or p.__c_gold
	end
	notify(p, "gold", p.__c_gold, 0, true)
	if p.__c_expOverride then notify(p, "exp", p.__c_exp, 0, true) end
end

-- Configuration.

local models, maps

local function read_text(path)
	local ok, text = pcall(function() return Host:read_text(path) end)
	if ok and type(text) == "string" then
		return (text:gsub("^\239\187\191", ""))
	end
	return ""
end

local function tab_lines(path)
	local result = {}
	for line in read_text(path):gmatch("[^\r\n]+") do
		if not line:match("^%s*$") then
			local fields = {}
			for value in (line .. "\t"):gmatch("([^\t]*)\t") do
				fields[#fields + 1] = value
			end
			result[#result + 1] = fields
		end
	end
	return result
end

local function tsv_rows(path)
	local lines = tab_lines(path)
	local header, result = lines[1], {}
	if not header then return result end
	for i = 2, #lines do
		local row = {}
		for j, name in ipairs(header) do
			if name ~= "" then row[name] = lines[i][j] or "" end
		end
		result[#result + 1] = row
	end
	return result
end

local function nonempty(s)
	return s ~= nil and s ~= "" and s or nil
end

local function load_tables()
	if models then return end

	models = {
		[0] = {
			model = "role/mod/obj_001.ams",
			animation = "role/ani/obj_001.ans",
			effect = "fx/cfg/obj_001jinbi.eft", direction = 0, scale = 5000,
		},
		[1] = { model = "role/mod/obj_01.ams", direction = 0, scale = 2500 },
		[2] = { model = "role/mod/obj_01.ams", direction = 192, scale = 2500 },
		[3] = { model = "role/mod/obj_02.ams", direction = 0, scale = 2500 },
		[4] = { model = "role/mod/obj_03.ams", direction = 0, scale = 2500 },
		[5] = { model = "role/mod/obj_04.ams", direction = 0, scale = 2500 },
		[6] = { model = "role/mod/map01.ams", direction = 0, scale = 2500 },
		[7] = { model = "role/mod/obj_03.ams", direction = 64, scale = 2500 },
		[8] = { model = "role/mod/obj_03.ams", direction = 128, scale = 2500 },
		[9] = { model = "role/mod/obj_03.ams", direction = 192, scale = 2500 },
		[10] = { model = "role/mod/map01.ams", direction = 0, scale = 2000 },
		[11] = { model = "role/mod/obj_03.ams", direction = 0, scale = 2000 },
		[12] = { model = "role/mod/obj_03.ams", direction = 64, scale = 2000 },
		[13] = { model = "role/mod/obj_03.ams", direction = 128, scale = 2000 },
		[14] = { model = "role/mod/obj_03.ams", direction = 192, scale = 2000 },
		[15] = {
			animation = "role/ani/jingyanhezi.ans",
			effect = "fx/cfg/exp.eft", direction = 0, scale = 2500,
		},
	}

	for _, row in ipairs(tsv_rows("config/map/mapitem.txt")) do
		local id = tonumber(row.nModID)
		if id then
			models[integer(id) & 0xffff] = {
				model = nonempty(row.sModPath),
				animation = nonempty(row.sActPath),
				effect = nonempty(row.sFxPath),
				direction = integer(row.nDir) & 0xff,
				scale = integer(row.nFangdabeilv),
			}
		end
	end

	maps = {}
	local rows = tsv_rows("config/map/map.txt")
	if #rows == 0 then
		local template = {
			{ 1, 1, 0, 2, 1, 6, 1, 0 },
			{ 2, 0, 0, 1, 1, 4, 0, 0 },
			{ 3, 0, 119, 1, 120, 7, 0, 119 },
			{ 4, 119, 119, 120, 120, 8, 119, 119 },
			{ 5, 119, 0, 120, 1, 9, 119, 0 },
		}
		for mapID = 1, 3 do
			for _, r in ipairs(template) do
				rows[#rows + 1] = {
					nMapID = mapID, nAreaID = r[1],
					nX1 = r[2], nY1 = r[3], nX2 = r[4], nY2 = r[5],
					nModID = r[6], nX3 = r[7], nY3 = r[8],
					nTongxing = 0, nQuandi = 0,
				}
			end
		end
	end

	for _, row in ipairs(rows) do
		local mapID = tonumber(row.nMapID)
		if mapID then
			mapID = integer(mapID) & 0xffff
			maps[mapID] = maps[mapID] or {}
			maps[mapID][#maps[mapID] + 1] = row
		end
	end
end

function C.CoinUnitValue()
	-- CPlayer::PickUpCoin (0x3413a4): one raw property unit per input unit.
	return 1
end

function C.BasePickUpCoin(p, roomType, count)
	C.InitPlayer(p)
	count = u32(count)

	-- CPlayer::PickUpCoin (0x3413a4):
	-- return virtual +0xcc(this, 0, count); roomType is discarded.
	local previous = p.__c_gold
	if not p.__c_goldOverride then
		previous = prior_property(p, 0) or previous
		p.__c_gold = previous
	end

	if type(p.AddSimple32Property) == "function" then
		p:AddSimple32Property(0, count)
		local reported = prior_property(p, 0)
		p.__c_gold = reported or ((previous + count) & 0xffffffff)
		p.__c_goldOverride = reported == nil
	else
		-- Missing virtual +0xcc target: retain only the raw-value fallback.
		p.__c_gold = (previous + count) & 0xffffffff
		p.__c_goldOverride = true
		notify(p, "gold", p.__c_gold, previous)
	end

	p.__c_coinItems = p.__c_coinItems + count
	p.__c_pickUpGold = p.__c_pickUpGold + count

	if type(C.OnCoinPickedUp) == "function" then
		C.OnCoinPickedUp(p, count, count)
	end
	return count
end

function C.GrantExp(p, item, reason)
	-- I04: no recovered local reward body. This is the old opt-in fallback.
	if not C.ENABLE_UNVERIFIED_LOCAL_EXP_REWARDS then return 0 end
	C.InitPlayer(p)
	local amount = max(0, integer(constant("ExpManorGainExp", 100)))
	C.SetExp(p, p.__c_exp + amount)
	if type(C.OnExpGained) == "function" then
		C.OnExpGained(p, amount, item, reason)
	end
	return amount
end

-- Scene state.

function C.InitScene(sc)
	sc.__c_items = {}
	sc.__c_buckets = {}
	sc.__c_itemFlags = {}
	sc.__c_flagRefs = {}
	sc.__c_mapIDs = {}
	sc.__c_time = 0
	sc.__c_destroying = false
	sc.__c_lastDirector = nil

	sc.__c_expState = {}
	sc.__c_expRefs = {}
	sc.__c_expIdle = 0
	sc.__c_expLive = 0
	sc.__c_expSeeded = false
	sc.__c_expTarget = max(0, integer(constant("ExpManorCount", 60)))
	sc.__c_expEnabled = boolean(C.ENABLE_SERVER_EXP_ITEMS)
		or boolean(C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL)

	-- I06: retained fallback; native bounds/stride initialization is missing.
	sc.__c_expX0, sc.__c_expX1 = 1, sc.__W - 2
	sc.__c_expY0, sc.__c_expY1 = 1, sc.__H - 2

	for gy = sc.__c_expY0, sc.__c_expY1 do
		for gx = sc.__c_expX0, sc.__c_expX1 do
			local idx = gy * sc.__W + gx
			local occupied = (sc.__owner[idx] or 0) ~= 0
				or (sc.__trail[idx] or 0) ~= 0
			sc.__c_expState[idx] = occupied and 1 or 0
			sc.__c_expRefs[idx] = 0
			if not occupied then sc.__c_expIdle = sc.__c_expIdle + 1 end
		end
	end
end

local function ensure_scene(sc)
	if not endless(sc) then return false end
	if not sc.__c_items then C.InitScene(sc) end
	return true
end

local function exp_index(sc, gx, gy)
	if gx < sc.__c_expX0 or gx > sc.__c_expX1
		or gy < sc.__c_expY0 or gy > sc.__c_expY1 then return nil end
	return gy * sc.__W + gx
end

local function move_bucket(item, x, y)
	local sc = item.__c_scene
	local previous = item.__c_bucket
	local next_idx = position_index(sc, x, y)
	item.__c_x, item.__c_y = x, y
	if previous == next_idx then return end

	if previous ~= nil then
		local bucket = sc.__c_buckets[previous]
		if bucket then
			bucket[item.__c_id] = nil
			if next(bucket) == nil then sc.__c_buckets[previous] = nil end
		end
	end

	item.__c_bucket = next_idx
	if next_idx ~= nil then
		local bucket = sc.__c_buckets[next_idx]
		if not bucket then
			bucket = {}
			sc.__c_buckets[next_idx] = bucket
		end
		bucket[item.__c_id] = item
	end
end

local function items_at(sc, idx)
	local list = {}
	for _, item in pairs(sc.__c_buckets[idx] or {}) do
		list[#list + 1] = item
	end
	-- I07: cell-list insertion body is missing.
	table.sort(list, function(a, b) return a.__c_id > b.__c_id end)
	return list
end

local function change_flags(item, delta)
	local sc, ctx = item.__c_scene, item.__c_context
	local flags = ctx.flags
	if flags == 0 then return end

	-- CItem::OnInsertToScene (0x33c9b4) /
	-- CItem::OnRemoveFrScene (0x33ca48): exclusive upper bounds.
	-- AddUnitFlag/ClearUnitFlag bodies are missing; retain reference counting.
	for gx = ctx.x1, ctx.x2 - 1 do
		for gy = ctx.y1, ctx.y2 - 1 do
			local idx = cell_index(sc, s16(gx), s16(gy))
			if idx then
				local refs = sc.__c_flagRefs[idx]
				if not refs then
					refs = {}
					sc.__c_flagRefs[idx] = refs
				end
				for bit = 0, 7 do
					local mask = 1 << bit
					if (flags & mask) ~= 0 then
						refs[mask] = max(0, (refs[mask] or 0) + delta)
					end
				end
				local combined = 0
				for mask, count in pairs(refs) do
					if count > 0 then combined = combined | mask end
				end
				sc.__c_itemFlags[idx] = combined ~= 0 and combined or nil
			end
		end
	end
end

function C.GetItemUnitFlags(sc, gx, gy)
	if not ensure_scene(sc) then return 0 end
	local idx = cell_index(sc, s16(gx), s16(gy))
	return idx and sc.__c_itemFlags[idx] or 0
end

function C.CheckBarrier(sc, fromPixel, toPixel)
	if not ensure_scene(sc) then return end
	local ox, oy = xy(fromPixel)
	local tx, ty = xy(toPixel)
	local gx, gy = s16(trunc(ox / NODE)), s16(trunc(oy / NODE))
	local ex, ey = s16(trunc(tx / NODE)), s16(trunc(ty / NODE))

	-- CGameScene::CheckBarrier (0x337d78):
	-- diagonal logical displacement is left untouched.
	if gx ~= ex and gy ~= ey then return end

	-- Same logical cell, or blocked starting cell: restore the original pixel
	-- position, not its centre.
	if gx == ex and gy == ey
		or (C.GetItemUnitFlags(sc, gx, gy) & 1) ~= 0 then
		write_xy(toPixel, ox, oy)
		return
	end

	local dx, dy = s16(ex - gx), s16(ey - gy)
	local length = s16(trunc(math.sqrt(dx * dx + dy * dy)))
	if length > 0 then
		dx, dy = s16(trunc(dx / length)), s16(trunc(dy / length))
	end

	local x, y = gx, gy
	while x ~= ex or y ~= ey do
		local nx, ny = s16(x + dx), s16(y + dy)
		if (C.GetItemUnitFlags(sc, nx, ny) & 1) ~= 0 then
			write_xy(toPixel, logic_centre(x), logic_centre(y))
			return
		end
		x, y = nx, ny
	end

	-- Even an unobstructed axis-aligned request ends at the destination centre.
	write_xy(toPixel, logic_centre(x), logic_centre(y))
end

-- Crystal idle grid.
-- States established by UpdateIdleExpGrid:
-- 0 free; 1 manor/line occupied; 2 crystal centre; 3 spacing reserved.

local function set_exp_unidle(sc, gx, gy, removing)
	-- Retained fallback: SetExpUnidle (0x337104) body is not supplied.
	local radius = max(0, integer(constant("ExpManorSpace", 3)))
	local x0, x1 = max(sc.__c_expX0, gx - radius), min(sc.__c_expX1, gx + radius)
	local y0, y1 = max(sc.__c_expY0, gy - radius), min(sc.__c_expY1, gy + radius)

	for y = y0, y1 do
		for x = x0, x1 do
			if x ~= gx or y ~= gy then
				local idx = y * sc.__W + x
				local state = sc.__c_expState[idx]
				local refs = sc.__c_expRefs[idx] or 0
				if removing then
					if state ~= 0 and state ~= 2 then
						if refs > 0 then refs = refs - 1 end
						sc.__c_expRefs[idx] = refs
						if state == 3 and refs == 0 then
							sc.__c_expState[idx] = 0
							sc.__c_expIdle = sc.__c_expIdle + 1
						end
					end
				else
					if state == 0 then
						sc.__c_expState[idx] = 3
						sc.__c_expIdle = sc.__c_expIdle - 1
					end
					sc.__c_expRefs[idx] = (refs + 1) & 0xff
				end
			end
		end
	end
end

function C.SetExpUnidle(sc, posLogic, removing)
	if not ensure_scene(sc) then return end
	local gx, gy = xy(posLogic)
	set_exp_unidle(sc, s16(gx), s16(gy), boolean(removing))
end

local function update_idle_exp(sc, gx, gy, unitType, removing, occupiedAtCall)
	local idx = exp_index(sc, gx, gy)
	if not idx then return end

	-- CGameScene::UpdateIdleExpGrid (0x337266).
	if unitType == 2 then
		set_exp_unidle(sc, gx, gy, removing)
		if sc.__c_expState[idx] == 1 then return end
		if removing then
			sc.__c_expState[idx] = 0
			sc.__c_expRefs[idx] = 0
			sc.__c_expIdle = sc.__c_expIdle + 1
		else
			sc.__c_expState[idx] = 2
			sc.__c_expRefs[idx] = 0
			sc.__c_expIdle = sc.__c_expIdle - 1
		end
	elseif unitType == 1 then
		local state = sc.__c_expState[idx]
		if removing then
			if state ~= 1 then return end
			local occupied = occupiedAtCall
			if occupied == nil then
				occupied = (sc.__owner[idx] or 0) ~= 0
					or (sc.__trail[idx] or 0) ~= 0
			end
			if occupied then return end
			if (sc.__c_expRefs[idx] or 0) == 0 then
				sc.__c_expState[idx] = 0
				sc.__c_expIdle = sc.__c_expIdle + 1
			else
				sc.__c_expState[idx] = 3
			end
		elseif state ~= 1 then
			if state == 0 then sc.__c_expIdle = sc.__c_expIdle - 1 end
			sc.__c_expState[idx] = 1
		end
	end
end

function C.UpdateIdleExpGrid(sc, posLogic, unitType, removing)
	if not ensure_scene(sc) then return end
	local gx, gy = xy(posLogic)
	update_idle_exp(sc, s16(gx), s16(gy), integer(unitType) & 0xff,
		boolean(removing))
end

function C.GetFreeExpPosition(sc)
	if not ensure_scene(sc) or sc.__c_expIdle <= 0 then return nil end

	-- CGameScene::GetFreeExpGrid (0x337978): row-major free-cell ordinal.
	local ordinal = math.random(0, sc.__c_expIdle - 1)
	for gy = sc.__c_expY0, sc.__c_expY1 do
		for gx = sc.__c_expX0, sc.__c_expX1 do
			if sc.__c_expState[gy * sc.__W + gx] == 0 then
				if ordinal == 0 then return logic_centre(gx), logic_centre(gy) end
				ordinal = ordinal - 1
			end
		end
	end
	return nil
end

function C.FindItemType(sc, posLogic, unusedType)
	if not ensure_scene(sc) then return nil end
	local gx, gy = xy(posLogic)
	local idx = cell_index(sc, s16(gx), s16(gy))
	if not idx then return nil end

	-- Retained fallback: FindItemType (0x33706c) body is missing.
	for _, item in ipairs(items_at(sc, idx)) do
		if item.__c_dropType == 1 then return item end
	end
end

function C.GetManorEdgeExpPosition(sc, excludeExistingCrystal)
	if not ensure_scene(sc) then return nil end
	local candidates = {}

	-- CGameScene::GetManorEdgeExpGrid (0x337a08):
	-- occupied, zero spacing references, an unlike cardinal neighbour.
	-- excludeExistingCrystal belongs only to the retained refill fallback.
	for gy = sc.__c_expY0, sc.__c_expY1 do
		for gx = sc.__c_expX0, sc.__c_expX1 do
			local idx = gy * sc.__W + gx
			local mid = sc.__owner[idx] or 0
			if mid ~= 0 and (sc.__c_expRefs[idx] or 0) == 0 then
				local edge = (sc.__owner[idx - 1] or 0) ~= mid
					or (sc.__owner[idx + 1] or 0) ~= mid
					or (sc.__owner[idx - sc.__W] or 0) ~= mid
					or (sc.__owner[idx + sc.__W] or 0) ~= mid
				if edge and (not excludeExistingCrystal
					or not C.FindItemType(sc, { x = gx, y = gy }, 1)) then
					candidates[#candidates + 1] = idx
				end
			end
		end
	end

	if #candidates == 0 then return nil end
	local idx = candidates[math.random(1, #candidates)]
	return logic_centre(idx % sc.__W), logic_centre(idx // sc.__W)
end

function C.FindRespawnPosition(sc)
	-- I08: selector call sites are missing.
	local x, y = C.GetManorEdgeExpPosition(sc, true)
	if x ~= nil then return x, y end
	return C.GetFreeExpPosition(sc)
end

-- Item objects.

local function decode_item_context(ctx)
	if type(ctx) == "table" and type(ctx.ReadInt32) == "function" then
		local previous = type(ctx.GetPosition) == "function" and ctx:GetPosition() or nil
		ctx:SetPosition(0)
		local read16 = ctx.ReadUint16 or ctx.ReadInt16
		local read8 = ctx.ReadUint8 or ctx.ReadInt8
		local result = { modelID = read16(ctx) & 0xffff }
		ctx:ReadInt16()
		result.x1, result.y1 = ctx:ReadInt32(), ctx:ReadInt32()
		result.x2, result.y2 = ctx:ReadInt32(), ctx:ReadInt32()
		result.flags, result.dropType = read8(ctx) & 0xff, read8(ctx) & 0xff
		if previous ~= nil then ctx:SetPosition(previous) end
		return result
	end

	ctx = ctx or {}
	return {
		modelID = integer(ctx.modelID or ctx.nModID) & 0xffff,
		x1 = s32(ctx.x1 or ctx.nX1),
		y1 = s32(ctx.y1 or ctx.nY1),
		x2 = s32(ctx.x2 or ctx.nX2),
		y2 = s32(ctx.y2 or ctx.nY2),
		flags = integer(ctx.flags or ctx.unitFlags) & 0xff,
		dropType = integer(ctx.dropType) & 0xff,
		areaID = ctx.areaID,
		mapID = ctx.mapID,
	}
end

function C.ItemHint(item)
	load_tables()
	local ctx = item.__c_context
	local row = models[ctx.modelID] or {}
	return {
		model_id = ctx.modelID,
		model = row.model,
		animation = row.animation,
		effect = row.effect,
		direction_raw = row.direction,
		scale_raw = row.scale,
		drop_type = ctx.dropType,
		unit_flags = ctx.flags,
		x1 = ctx.x1, y1 = ctx.y1, x2 = ctx.x2, y2 = ctx.y2,
		map_id = ctx.mapID, area_id = ctx.areaID,
		from_x_px = item.__c_fromX,
		from_y_px = item.__c_fromY,
		flight_ms = item.__c_moveMs or 0,
		move_parameter_raw = item.__c_moveParameter,
		state = item.__c_state,
		state_animation = item.__c_state == 1 and "rb1"
			or item.__c_state == 2 and "bind"
			or item.__c_state == 3 and "fly_die" or nil,
		lifetime_ms = item.__c_expireAt
			and max(0, item.__c_expireAt - item.__c_scene.__c_time) or nil,
	}
end

local function request_view_removal(item, pickedByID)
	if item.__c_viewRemovalRequested then return end
	item.__c_viewRemovalRequested = true
	Host.scene_view:remove_item(item.__c_id, pickedByID)
end

local function new_item(sc, id, x, y, context, targetX, targetY, moveParameter)
	if not ensure_scene(sc) or sc.__c_destroying then return nil end
	id = integer(id)
	if id <= 0 or id > 0xffff or sc.__c_items[id]
		or (sc.__players and sc.__players[id]) then return nil end

	local ctx = decode_item_context(context)
	if ctx.dropType == 1 and not sc.__c_expEnabled then return nil end
	targetX, targetY = targetX or x, targetY or y

	-- I10: preserve the previous timing fallback, independently of animation.
	local moveMs = moveParameter ~= nil and (integer(moveParameter) & 0xffff) or nil
	local item = setmetatable({
		__c_id = id, __c_scene = sc, __c_context = ctx,
		__c_dropType = ctx.dropType,
		__c_state = 1,
		__c_x = x, __c_y = y,
		__c_fromX = x, __c_fromY = y,
		__c_targetX = targetX, __c_targetY = targetY,
		__c_bornAt = sc.__c_time,
		__c_moveParameter = moveParameter,
		__c_moveMs = moveMs,
		__c_landAt = moveMs ~= nil and (sc.__c_time + moveMs) or nil,
		__c_gx = s16(trunc(targetX / NODE)),
		__c_gy = s16(trunc(targetY / NODE)),
	}, Item)

	-- CItem::OnInsertToScene (0x33c9b4): ALL type-0 items register the timer.
	-- A nonzero flags byte runs the flag loop and then reaches the same test.
	if ctx.dropType == 0 then
		item.__c_expireAt = sc.__c_time + u32(constant("ItemLimitTime", 15000))
	end

	sc.__c_items[id] = item
	move_bucket(item, x, y)
	change_flags(item, 1)

	if moveMs == 0 then
		move_bucket(item, targetX, targetY)
		item.__c_landAt = nil
	end

	local kind = ctx.dropType == 0 and "coin"
		or ctx.dropType == 1 and "exp" or "map"
	Host.scene_view:add_item(id, kind, targetX, targetY, C.ItemHint(item))
	return item
end

function C.RemoveItem(item, pickedByID, reason)
	local sc = item.__c_scene
	if not sc or sc.__c_items[item.__c_id] ~= item then return false end

	sc.__c_items[item.__c_id] = nil
	if item.__c_bucket ~= nil then
		local bucket = sc.__c_buckets[item.__c_bucket]
		if bucket then
			bucket[item.__c_id] = nil
			if next(bucket) == nil then sc.__c_buckets[item.__c_bucket] = nil end
		end
		item.__c_bucket = nil
	end
	change_flags(item, -1)

	-- Crystal-removal bookkeeping depends on the omitted base Die/OnCircle.
	-- Preserve the previous bookkeeping fallback for tracked injected units.
	if item.__c_expTracked then
		item.__c_expTracked = false
		C.UpdateIdleExpGrid(sc, { x = item.__c_gx, y = item.__c_gy }, 2, true)
		sc.__c_expLive = sc.__c_expLive - 1
	end

	if item.__c_state ~= 4 then item.__c_state = 3 end
	item.__c_removeReason = reason
	request_view_removal(item, pickedByID)
	return true
end

function C.CircleItem(item, manor, player)
	local sc = item.__c_scene

	-- CItemClient::OnCircle (0x391ca4): no action on a server-driven scene.
	if not sc or server(sc) then return false end
	local pickedBy = player and player.__objectID or nil

	-- I04/I15: immediate base destruction remains unrecovered.
	if not C.RemoveItem(item, pickedBy, manor and "circle" or "pickup") then
		return false
	end
	if item.__c_dropType == 1 and player then
		C.GrantExp(player, item, manor and "circle" or "pickup")
	end
	return true
end

function Item:GetObjectID() return self.__c_id end
function Item:GetScene() return self.__c_scene end
function Item:GetState() return self.__c_state end
function Item:GetItemType() return self.__c_dropType end
function Item:GetModelID() return self.__c_context.modelID end
function Item:GetPixelPos() return CVector2f:new(self.__c_x, self.__c_y) end
function Item:IsAlive() return self.__c_state < 3 end

function Item:SetState(state)
	-- CItem::SetState (0x33c878): store the byte, then dispatch OnSetState.
	state = integer(state) & 0xff
	self.__c_state = state

	-- CItemClient::OnSetState (0x391b24): 1=rb1, 2=bind, 3=fly_die.
	-- State 3 stays in the scene until its animation completes.
	if state == 3 then request_view_removal(self, self.__c_pickedByID) end
	if type(C.OnItemStateChanged) == "function" then
		C.OnItemStateChanged(self, state,
			state == 1 and "rb1" or state == 2 and "bind"
			or state == 3 and "fly_die" or nil)
	end
end

function Item:OnAniPlayEnd()
	-- CItemClient::OnAniPlayEnd (0x391aba).
	if self.__c_state == 1 then self:SetState(2) end
	if self.__c_state == 3 then
		return self.__c_scene:RemoveObject(self)
	end
	return true
end

function C.OnItemAnimationEnd(sc, id, animationName)
	local item = sc and sc.__c_items and sc.__c_items[id]
	if not item then return false end
	-- A queued spawn callback can arrive after pickup changed the state.
	-- Only the currently playing non-looping state may advance/remove it.
	local expected = item.__c_state == 1 and "rb1"
		or item.__c_state == 3 and "fly_die" or nil
	if expected == nil or animationName ~= expected then return false end
	return item:OnAniPlayEnd()
end

function Item:Die()
	-- Missing CItem::Die body: retained immediate-removal fallback.
	return C.RemoveItem(self, nil, "die")
end

function Item:OnCircle(manor, player)
	return C.CircleItem(self, manor, player)
end

function Item:OnFreeCircle(manor)
	-- CItemClient::OnFreeCircle (0x391cda); base 0x33c8d8 is missing.
	if not self.__c_scene or server(self.__c_scene) then return false end
	return C.RemoveItem(self, nil, "free_circle")
end

function C.CreateItem(sc, id, posPixel, context)
	local x, y = xy(posPixel)
	return new_item(sc, id, x, y, context)
end

function C.CreatExpUnit(sc, id, posPixel)
	if not ensure_scene(sc) or not sc.__c_expEnabled then return nil end
	local x, y = xy(posPixel)
	x, y = s16(x), s16(y)
	local gx, gy = s16(trunc(x / NODE)), s16(trunc(y / NODE))

	-- CGameScene::CreatExpUnit (0x337370).
	local item = new_item(sc, id, x, y, {
		modelID = 15, dropType = 1, flags = 0,
		x1 = gx > 0 and gx - 1 or gx,
		y1 = gy > 0 and gy - 1 or gy,
		x2 = gx, y2 = gy,
	}, x, y, 10)

	if item then
		-- The native call is explicit here, not in generic CreateItem.
		item.__c_expTracked = true
		sc.__c_expLive = sc.__c_expLive + 1
		C.UpdateIdleExpGrid(sc, { x = gx, y = gy }, 2, false)
	end
	return item
end

-- Death drops.

local function array_value(array, index)
	if array[0] ~= nil then return array[index - 1] end
	return array[index]
end

function C.DropAt(sc, posPixel, count, ids, positionsLogic)
	if not ensure_scene(sc) then return 0 end
	local x, y = xy(posPixel)
	local made = 0

	-- CGameScene::DropOut(pos,count,ids,cells) (0x337c80).
	for i = 1, integer(count) & 0xff do
		local id = array_value(ids, i)
		local pos = array_value(positionsLogic, i)
		if id and pos then
			local gx, gy = xy(pos)
			local tx, ty = logic_centre(gx), logic_centre(gy)
			local distance = math.sqrt((tx - x) ^ 2 + (ty - y) ^ 2)
			local moveParameter = trunc(distance) & 0xffff
			local item = new_item(sc, id, x, y, {
				modelID = 0, flags = 0, dropType = 0,
				x1 = 0, y1 = 0, x2 = 0, y2 = 0,
			}, tx, ty, moveParameter)
			if item then made = made + 1 end
		end
	end
	return made
end

local function contains_coin(sc, gx, gy)
	local idx = cell_index(sc, s16(gx), s16(gy))
	if not idx then return false end
	for _, item in pairs(sc.__c_buckets[idx] or {}) do
		if item.__c_dropType == 0 then return true end
	end
	return false
end

function C.DropCoins(sc, posPixel, unusedLevel, extraCount)
	if not ensure_scene(sc) then return 0 end

	-- CGameScene::DropOut(pos,level,extra) (0x3398d4):
	-- room 0 uses Rand(MinItemCount, MaxItemCount+1), with exclusive upper bound.
	local low = s32(constant("MinItemCount", 7))
	local high = s32(constant("MaxItemCount", 11))
	local extra = integer(extraCount) & 0xff
	local remaining = min(30, max(0, math.random(low, high) + extra))

	local x, y = xy(posPixel)
	local cx, cy = s16(trunc(x / NODE)), s16(trunc(y / NODE))
	local ids, positions, pending = {}, {}, {}
	local width, depth = scene_width(sc), scene_depth(sc)
	local radius = 1

	-- Native search is unbounded. In particular, AllocObjectID returning zero
	-- retries through later candidates rather than terminating the generator.
	while remaining > 0 do
		for gx = cx - radius, cx + radius do
			if remaining == 0 then break end
			for gy = cy - radius, cy + radius do
				if remaining == 0 then break end
				if gx == cx - radius or gx == cx + radius
					or gy == cy - radius or gy == cy + radius then

					-- Preserve the native unsigned, inclusive comparisons.
					if u32(gx) <= width and u32(gy) <= depth
						and math.random(0, 2) ~= 0 then
						local lx, ly = s16(gx), s16(gy)
						local key = (lx & 0xffff) | ((ly & 0xffff) << 16)
						if not pending[key] and not contains_coin(sc, lx, ly) then
							local id = sc:AllocObjectID(false)
							if id and (integer(id) & 0xffff) ~= 0 then
								ids[#ids + 1] = integer(id) & 0xffff
								positions[#positions + 1] = { x = lx, y = ly }
								pending[key] = true
								remaining = remaining - 1
							end
						end
					end
				end
			end
		end
		radius = radius + 1
	end

	return C.DropAt(sc, posPixel, #ids, ids, positions)
end

function C.OnPlayerDeath(sc, victim, killer, collide)
	if not ensure_scene(sc) then return end
	C.InitPlayer(victim)
	if victim.__c_deathDropped then return end
	victim.__c_deathDropped = true

	-- CPlayer::KilledByPlayer (0x342054), final virtual +0xec dispatch.
	-- This hook implements that dispatch only; property-6 rebirth/statistics
	-- belong to the surrounding death implementation.
	local level = 0
	if type(victim.GetSimple32Property) == "function" then
		level = u32(victim:GetSimple32Property(7))
	end
	local extra = 0
	if killer and type(killer.GetSimple32Property) == "function" then
		extra = integer(killer:GetSimple32Property(0x0c)) & 0xff
	end
	return sc:DropOut({ x = victim.__x, y = victim.__y }, level, extra)
end

-- Pickup.

function C.CheckItemExpansion(p)
	-- CPlayer::CheckItem (0x341b44).
	return u32(constant("PickExpRange", 3)) * NODE
		+ s32(p:GetSimple32Property(0x0a))
end

local function check_rect(sc, p, left, top, right, bottom)
	if not ensure_scene(sc) then return end
	local range = C.CheckItemExpansion(p)
	local x0, y0 = trunc((left - range) / NODE), trunc((top - range) / NODE)
	local x1, y1 = trunc((right + range) / NODE), trunc((bottom + range) / NODE)

	-- CPlayer::CheckItem (0x341b44): x outer, y inner, exclusive upper bounds.
	-- GetCharacterList's missing out-of-bounds behavior is represented by the
	-- existing empty-outside-grid adapter.
	for gx = x0, x1 - 1 do
		for gy = y0, y1 - 1 do
			local idx = cell_index(sc, s16(gx), s16(gy))
			if idx then
				for _, item in ipairs(items_at(sc, idx)) do
					if sc.__c_items[item.__c_id] == item and item.__c_state == 2 then
						if item.__c_dropType == 1 then
							item:OnCircle(nil, p)
						elseif item.__c_dropType == 0 then
							p:OnCollideDropOut(item)
						end
					end
				end
			end
		end
	end
end

function C.CheckItem(p, rect, sc)
	sc = sc or p.__scene
	check_rect(sc, p,
		component(rect, "left", 1), component(rect, "top", 2),
		component(rect, "right", 3), component(rect, "bottom", 4))
end

function C.OnPlayerMoved(sc, p, oldX, oldY, newX, newY)
	-- CPlayer::OnSetPosition (0x343488): swept centre bounding rectangle.
	check_rect(sc, p, min(oldX, newX), min(oldY, newY),
		max(oldX, newX), max(oldY, newY))
end

-- Cell changes / circles.

function C.OnCellChanged(sc, idx, oldOwner, oldTrail, newOwner, newTrail)
	if not ensure_scene(sc) then return end
	local gx, gy = idx % sc.__W, idx // sc.__W

	if oldOwner ~= newOwner then
		if oldOwner ~= 0 then
			-- CManor::RemoveUnit (0x33e2dc) / RemoveAllUnit (0x33e314):
			-- UpdateIdleExpGrid is called BEFORE the manor unit is unlinked.
			update_idle_exp(sc, gx, gy, 1, true, true)
		end
		if newOwner ~= 0 then
			-- CManor::AddManorUnit (0x33e424): occupancy update precedes OnAddUnit.
			update_idle_exp(sc, gx, gy, 1, false)
		end
	end

	if oldTrail ~= newTrail then
		if oldTrail ~= 0 then
			-- CManorLine::RemoveUnit (0x33e254): unlink precedes this update.
			update_idle_exp(sc, gx, gy, 1, true)
		end
		if newTrail ~= 0 then
			-- CManorLine::AddUnit (0x33e38a): update precedes PushBack.
			update_idle_exp(sc, gx, gy, 1, false)
		end
	end

	if oldOwner ~= newOwner then
		local p = newOwner ~= 0 and manor_player(sc, newOwner) or nil
		local manor = p and p.__manor or nil

		-- I15: OnAddUnit/OnRemoveUnit item dispatch bodies are missing.
		for _, item in ipairs(items_at(sc, idx)) do
			if sc.__c_items[item.__c_id] == item then
				if newOwner ~= 0 then
					item:OnCircle(manor, p)
				else
					item:OnFreeCircle(nil)
				end
			end
		end
	end
end

-- Map items / free placement.

function C.CreateMapItems(sc, mapID)
	if not ensure_scene(sc) then return 0 end
	load_tables()
	mapID = integer(mapID) & 0xffff
	sc.__c_mapIDs[mapID] = (sc.__c_mapIDs[mapID] or 0) + 1

	local count = 0
	for _, row in ipairs(maps[mapID] or {}) do
		-- CMapConfig::OnLoadedEnd (0x33f5fc):
		-- Tongxing != 0 -> 1; Quandi != 0 -> OR 2.
		local flags = 0
		if integer(row.nTongxing) ~= 0 then flags = flags | 1 end
		if integer(row.nQuandi) ~= 0 then flags = flags | 2 end

		-- CGameScene::CreateMapItem (0x339ca0): no per-scene idempotence check.
		local id = sc:AllocObjectID(false)
		local item = new_item(sc, id,
			logic_centre(row.nX3), logic_centre(row.nY3), {
				modelID = integer(row.nModID) & 0xffff,
				x1 = s32(row.nX1), y1 = s32(row.nY1),
				x2 = s32(row.nX2), y2 = s32(row.nY2),
				flags = flags, dropType = 2,
				mapID = mapID, areaID = integer(row.nAreaID),
			})
		if item then count = count + 1 end
	end
	return count
end

function C.GetFreeGrid(sc, out, safeDistance, unusedFlags)
	if not ensure_scene(sc) then return false end

	-- CGameScene::GetFreeGrid (0x3376f8).
	-- Geometry is recovered; rebuilding candidates retains the old fallback
	-- because native cache initialization/UpdateIdleGrid are missing.
	local cols, rows = scene_width(sc) >> 6, scene_depth(sc) >> 6
	local distance = s32(safeDistance)
	local signedSpan = trunc(distance / 64)
	local span = u32(distance) >> 6
	if cols <= 0 or rows <= 0 then return false end

	local candidates = {}
	for i = 0, cols * rows - 1 do candidates[#candidates + 1] = i end

	while #candidates > 0 do
		local pick = math.random(1, #candidates)
		local block = candidates[pick]
		candidates[pick] = candidates[#candidates]
		candidates[#candidates] = nil

		local bx, by = block % cols, block // cols
		if bx <= u32(cols - signedSpan) and by <= u32(rows - signedSpan) then
			local ex, ey = min(bx + span, cols - 1), min(by + span, rows - 1)
			local free = true
			for cy = by, ey do
				for cx = bx, ex do
					for gy = cy * 4, cy * 4 + 3 do
						for gx = cx * 4, cx * 4 + 3 do
							local idx = gy * sc.__W + gx
							if (sc.__owner[idx] or 0) ~= 0
								or (sc.__trail[idx] or 0) ~= 0 then
								free = false
								break
							end
						end
						if not free then break end
					end
					if not free then break end
				end
				if not free then break end
			end

			if free then
				write_xy(out, s16((bx + ex) * 32 + 8), s16((by + ey) * 32 + 8))
				return true
			end
		end
	end
	return false
end

function C.GetAllItem(sc, out, capacity)
	if not ensure_scene(sc) then return out and 0 or {} end
	capacity = integer(capacity, 0xffff) & 0xffff

	local objects = {}
	for id, p in pairs(sc.__players or {}) do
		if p.__c_inScene ~= false then
			objects[#objects + 1] = { id = id, player = p }
		end
	end
	for id, item in pairs(sc.__c_items) do
		objects[#objects + 1] = { id = id, item = item }
	end

	-- I17: native tree ordering/validity initialization is not supplied.
	table.sort(objects, function(a, b) return a.id < b.id end)
	local result = {}
	for ordinal, object in ipairs(objects) do
		-- CGameScene::GetAllItem (0x336cac), comparison at 0x336d2a:
		-- capacity limits the all-character ordinal, not the item count.
		if ordinal > 0xffff then break end
		if ordinal - 1 < capacity and object.item then
			result[#result + 1] = object.item
		end
	end

	if not out then return result end
	for i = #out, 1, -1 do out[i] = nil end
	for i, item in ipairs(result) do out[i] = item end
	return #result
end

-- Timers / optional unrecovered local replenishment.

function C.RefillExp(sc, initial)
	if not ensure_scene(sc)
		or not C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL
		or not sc.__c_expEnabled or sc.__c_destroying then return 0 end

	local made = 0
	local missing = max(0, sc.__c_expTarget - sc.__c_expLive)
	for _ = 1, missing do
		local x, y
		if initial then x, y = C.GetFreeExpPosition(sc)
		else x, y = C.FindRespawnPosition(sc) end
		if x == nil then break end

		local id = sc:AllocObjectID(false)
		if not id or id <= 0 or id > 0xffff then break end
		if not C.CreatExpUnit(sc, id, { x = x, y = y }) then break end
		made = made + 1
	end
	return made
end

function C.SeedExp(sc)
	if not ensure_scene(sc)
		or not C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL
		or sc.__c_expSeeded then return end
	sc.__c_expSeeded = true
	C.RefillExp(sc, true)
end

function C.Tick(sc, dtMs)
	if not ensure_scene(sc) or sc.__c_destroying then return end
	sc.__c_time = sc.__c_time + max(0, tonumber(dtMs) or 0)
	C.RefreshDirector(sc)

	local list = {}
	for _, item in pairs(sc.__c_items) do list[#list + 1] = item end
	table.sort(list, function(a, b) return a.__c_id < b.__c_id end)

	for _, item in ipairs(list) do
		if sc.__c_items[item.__c_id] == item then
			if item.__c_expireAt and sc.__c_time >= item.__c_expireAt then
				-- I19: the registered callback body is missing.
				item:Die()
			elseif item.__c_landAt then
				-- I10: retained movement fallback, never an animation callback.
				local elapsed = sc.__c_time - item.__c_bornAt
				local ratio = item.__c_moveMs > 0
					and min(1, elapsed / item.__c_moveMs) or 1
				move_bucket(item,
					item.__c_fromX + (item.__c_targetX - item.__c_fromX) * ratio,
					item.__c_fromY + (item.__c_targetY - item.__c_fromY) * ratio)
				if sc.__c_time >= item.__c_landAt then
					item.__c_landAt = nil
				end
			end
		end
	end

	if C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL and sc.__c_expSeeded then
		C.RefillExp(sc, false)
	end
end

function C.DestroyScene(sc)
	if not sc.__c_items then return end
	sc.__c_destroying = true
	sc.__c_expSeeded = false
	local list = {}
	for _, item in pairs(sc.__c_items) do list[#list + 1] = item end
	for _, item in ipairs(list) do C.RemoveItem(item, nil, "scene_destroy") end
end

-- Installation.

function C.Install()
	if C.__c_installed then return C end
	assert(CGameScene and CPlayerClient, "load scene_items after scene.lua")
	C.__c_installed = true
	C.__c_priorGetSimple = CPlayerClient.GetSimple32Property

	local oldCreateMapItem = CGameScene.CreateMapItem
	function CGameScene:CreateMapItem(mapID)
		if not endless(self) then
			if oldCreateMapItem then return oldCreateMapItem(self, mapID) end
			return
		end
		return C.CreateMapItems(self, mapID)
	end

	local oldCreate = CGameScene.Create
	function CGameScene:Create(...)
		local result = pack_values(oldCreate(self, ...))
		if endless(self) then
			if self.__c_items then C.DestroyScene(self) end
			C.InitScene(self)
			-- CGameClient.lua explicitly calls CreateMapItem after SwitchGame.
		end
		return unpack_values(result, 1, result.n)
	end

	local oldStart = CGameScene.Start
	function CGameScene:Start(...)
		local result = pack_values(oldStart(self, ...))
		if endless(self) and C.ENABLE_UNVERIFIED_LOCAL_EXP_REFILL then
			C.SeedExp(self)
		end
		return unpack_values(result, 1, result.n)
	end

	local oldDestroy = CGameScene.OnSceneDestroy
	function CGameScene:OnSceneDestroy(...)
		C.DestroyScene(self)
		if oldDestroy then return oldDestroy(self, ...) end
	end

	local oldAddPlayer = CGameScene.AddPlayer
	function CGameScene:AddPlayer(...)
		local result = pack_values(oldAddPlayer(self, ...))
		local p = result[1]
		if p and endless(self) then
			C.InitPlayer(p)
			p.__c_inScene = true
		end
		return unpack_values(result, 1, result.n)
	end

	local oldRemoveObject = CGameScene.RemoveObject
	function CGameScene:RemoveObject(object, ...)
		if object and object.__c_scene == self and self.__c_items
			and self.__c_items[object.__c_id] == object then
			return C.RemoveItem(object, object.__c_pickedByID,
				object.__c_removeReason or "animation_end")
		end
		if object and object.__scene == self then object.__c_inScene = false end
		if oldRemoveObject then return oldRemoveObject(self, object, ...) end
	end

	local oldGetCharacter = CGameScene.GetCharacterByID
	function CGameScene:GetCharacterByID(id)
		local object = oldGetCharacter and oldGetCharacter(self, id)
		if object then return object end
		return self.__c_items and self.__c_items[id] or nil
	end

	local oldCreateItem = CGameScene.CreateItem
	function CGameScene:CreateItem(id, posPixel, context)
		if not endless(self) then
			if oldCreateItem then return oldCreateItem(self, id, posPixel, context) end
			return nil
		end
		return C.CreateItem(self, id, posPixel, context)
	end

	local oldDropOut = CGameScene.DropOut
	function CGameScene:DropOut(posPixel, a, b, cells)
		if not endless(self) then
			if oldDropOut then return oldDropOut(self, posPixel, a, b, cells) end
			return 0
		end

		-- The array overload is the base operation (0x337c80).
		if cells ~= nil then return C.DropAt(self, posPixel, a, b, cells) end

		-- CGameSceneClient::DropOut (0x38fe1e).
		if self:GetRoomType() == 4 or server(self) then return 0 end
		return C.DropCoins(self, posPixel, a, b)
	end

	function CGameScene:CreatExpUnit(id, posPixel)
		return C.CreatExpUnit(self, id, posPixel)
	end

	function CGameScene:SetExpUnidle(posLogic, removing)
		return C.SetExpUnidle(self, posLogic, removing)
	end

	function CGameScene:UpdateIdleExpGrid(posLogic, unitType, removing)
		return C.UpdateIdleExpGrid(self, posLogic, unitType, removing)
	end

	function CGameScene:GetFreeExpGrid(out)
		local x, y = C.GetFreeExpPosition(self)
		if x == nil then return false end
		write_xy(out, x, y)
		return true
	end

	function CGameScene:GetManorEdgeExpGrid(out)
		local x, y = C.GetManorEdgeExpPosition(self, false)
		if x == nil then return false end
		write_xy(out, x, y)
		return true
	end

	function CGameScene:FindItemType(posLogic, itemType)
		return C.FindItemType(self, posLogic, itemType)
	end

	function CGameScene:GetAllItem(out, capacity)
		return C.GetAllItem(self, out, capacity)
	end

	function CGameScene:GetFreeGrid(out, safeDistance, flags)
		return C.GetFreeGrid(self, out, safeDistance, flags)
	end

	function CGameScene:GetItemUnitFlags(posLogic)
		local gx, gy = xy(posLogic)
		return C.GetItemUnitFlags(self, gx, gy)
	end

	local oldCheckBarrier = CGameScene.CheckBarrier
	function CGameScene:CheckBarrier(fromPixel, toPixel)
		if not endless(self) then
			if oldCheckBarrier then return oldCheckBarrier(self, fromPixel, toPixel) end
			return
		end
		return C.CheckBarrier(self, fromPixel, toPixel)
	end

	local oldStartUp = CPlayerClient.StartUp
	function CPlayerClient:StartUp(...)
		if endless(self.__scene) then
			C.InitPlayer(self)
			self.__c_deathDropped = false
			self.__c_inScene = true
		end
		return oldStartUp(self, ...)
	end

	local oldGetSimple = C.__c_priorGetSimple
	function CPlayerClient:GetSimple32Property(t)
		if endless(self.__scene) then
			C.InitPlayer(self)
			if t == 0 then
				if self.__c_goldOverride then return self.__c_gold end
				local value = prior_property(self, 0)
				if value ~= nil then
					self.__c_gold = value
					return value
				end
				return self.__c_gold
			end
			local expID = property_id("exp")
			if expID ~= nil and t == expID and self.__c_expOverride then
				return self.__c_exp
			end
		end
		return oldGetSimple(self, t)
	end

	local oldPickUpCoin = CPlayerClient.PickUpCoin
	function CPlayerClient:PickUpCoin(roomType, count)
		if not endless(self.__scene) then
			if oldPickUpCoin then return oldPickUpCoin(self, roomType, count) end
			return 0
		end

		-- CPlayerClient::PickUpCoin (0x396418).
		if not C.CanCreditCoin(self) then return 0 end
		local credited = C.BasePickUpCoin(self, roomType, count)
		if type(C.OnCoinHUDChanged) == "function" then
			C.OnCoinHUDChanged(self, self.__c_gold)
		end
		return credited
	end

	local oldCollideDropOut = CPlayerClient.OnCollideDropOut
	function CPlayerClient:OnCollideDropOut(item)
		local sc = self.__scene
		if not endless(sc) then
			if oldCollideDropOut then return oldCollideDropOut(self, item) end
			return false
		end
		if server(sc) or not item or not sc.__c_items
			or sc.__c_items[item.__c_id] ~= item then return false end

		-- CPlayerClient::OnCollideDropOut (0x396490) /
		-- CPlayer::OnCollideDropOut (0x3414ba).
		-- State filtering belongs to CheckItem, not this method.
		self:PickUpCoin(sc:GetRoomType(), 1)
		item.__c_pickedByID = self.__objectID
		item.__c_removeReason = "coin_pickup"
		item:SetState(3)
		return true
	end

	local oldCheckItem = CPlayerClient.CheckItem
	function CPlayerClient:CheckItem(rect, sc)
		sc = sc or self.__scene
		if not endless(sc) then
			if oldCheckItem then return oldCheckItem(self, rect, sc) end
			return
		end
		return C.CheckItem(self, rect, sc)
	end

	local oldUpdate = CGameScene.Update
	function CGameScene:Update(dtMs)
		if self.__match_finished then return end
		if self.__timed_match and SceneMatch then
			dtMs = min(dtMs, SceneMatch.GetTimeRemain(self))
		end
		local active = endless(self) and self.__started
		if active then C.Tick(self, dtMs) end
		local result = pack_values(oldUpdate(self, dtMs))
		if active and not self.__c_destroying then C.RefreshDirector(self) end
		-- CheckItem is called by OnSetPosition, not by an invented per-frame
		-- stationary-player scan.
		return unpack_values(result, 1, result.n)
	end

	return C
end

C.Install()
return C
