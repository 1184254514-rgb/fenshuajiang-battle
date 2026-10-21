-- GPT audit:
-- Kill modifier 19: SETTLED -- CPlayer::KilledByPlayer (0x342054): low32(base * property 19) / 10000, truncated unsigned.
-- Rhythm-level table: SETTLED (0x379ea0, 0x37a104): exact key match, last row's byte as fallback.
-- Evaluation rank codes: SETTLED (0x334440, 0x33432c): SSS, SS, S, A, B, C, D = 6, 5, 4, 3, 2, 1, 0.
-- Combo-level thresholds: SETTLED (0x333b94, 0x333df8): first unsigned >= match in file order.
-- Combo-prize thresholds: SETTLED (0x344270): previous threshold < count <= next threshold.
-- Evaluation count ceilings: SETTLED (0x33432c): first unsigned count <= ceiling; -1 becomes UINT32_MAX.
-- Manor contributions: SETTLED (0x33dfd0, 0x33e138): additions include signed property 20; removals omit it.
-- Area maximum comparison: SETTLED -- CPlayer::NotifySimple32PropertyChanged (0x342ebc): signed property 17 > property 13.
-- Death-node snapshot timing: ASSUMPTION: retain the snapshot before offline cleanup.
-- Missing: the CPlayer +0x15c cache-writer/manor-detachment function (symbol not supplied); 0x342054 does neither.
-- GetNodeCount selection: SETTLED (0x341976): attached manor +0x68, otherwise player +0x15c.
-- Kill award: SETTLED -- CPlayer::KilledByPlayer (0x342054): with a killer and false first flag, add 1 to property 1,
-- then add GetPrize(4) plus its property-19 bonus to property 16; room 0 bypasses time-based doubling.
-- Magic callbacks: ASSUMPTION: retain existing property producers; the magic-property virtual callbacks dispatched
-- by CFightCalculator::UpdateMagic (0x3349dc) are missing. UpdateMagic itself specifies no additional fixed award.
-- Settlement assembly: SETTLED -- CGameScene::GetSettlementData (0x33b74c): group by unsigned manor ID,
-- sort active teams with the supplied comparator, place cached teams at activeCount + sceneSequence - cachedSequence,
-- then sort every team's players with the supplied player comparator. Native indices are zero-based.
-- Default settlement ordering: ASSUMPTION: retain offline score/ID comparators; native caller/comparator functions are missing.
-- Settlement player selection: ASSUMPTION: __alive/__order represents the missing CGameScene virtual +0x104 enumeration function.
-- Scene settlement wire envelope: ASSUMPTION: retain the offline envelope; GetSettlementData returns a C++ vector,
-- and its Lua binding/serializer is missing.
-- HUD coin aggregation: ASSUMPTION: retain score-earned + pickup coins; CPlayerClient::NotifySimple32PropertyChanged is missing.
-- The supplied 0x342ebc is CPlayer's base implementation and contains no HUD update.
-- HUD text setter: ASSUMPTION: retain SetWndText; Gamma::CGWnd::SetWndText's Lua binding and HUD initialization are missing.
-- Capture effect targets: PARTLY SETTLED -- CGameMain::CGameMain (0x38b688) initializes +0x4c to NULL and allocates
-- a separate CFontEffectWnd at +0x68. ASSUMPTION: preserve the installed renderer/plain-text fallback;
-- the post-construction window initializer and CFontEffectWnd Lua binding are missing.
-- Player settlement/score fields: SETTLED (0x3419fc, 0x341a70); settlement padding/reserved bytes remain unwritten.
-- Settlement sequence source: ASSUMPTION: retain offline 1..N; the function writing CGameScene +0x480 is missing.
-- GetSettlementData (0x33b74c) reads that value, and PushSettlementTeam (0x33956c) copies it without incrementing it.
-- Max-score fallback: SETTLED -- CPlayer::GetMaxScore (0x341a40): properties 13, 16, 18, then their wrapping u32 sum.
-- Kill-prize fallback: SETTLED -- CRankPrizeConfig::GetKillPrize (0x345604): byte type 0 returns 0; otherwise
-- key = 10000 + min(type, 4), missing keys return/insert 0. OnLoadedEnd (0x345424) loads u32 columns 1/2, last duplicate wins.

local pack_values, unpack_values = table.pack, table.unpack   -- the original Help.lua later replaces table.pack (Claude)
-- Offline endless-mode scoring. Load after natives/scene.lua, before GameClientRequire.
-- Territory valuation, cell heights, movement and window-owned __rhythm counters
-- remain with their existing implementations.
--
-- Only __b_* fields are introduced on players/scenes. Existing __stats fields are
-- mirrored for compatibility.
--
-- Evidence:
--   CalAllScore = SPT32[16] + SPT32[17] + SPT32[18].
--   GetScoreInfo reward coins = floor(CalAllScore / CoinRatio).
--   rhythmscoreparam produces the evaluation ratio, not another additive score.

if SceneScore and SceneScore.__installed then
	return SceneScore
end

local B = { __installed = true }
SceneScore = B

local old = {
	create = CGameScene.Create,
	addPlayer = CGameScene.AddPlayer,
	update = CGameScene.Update,
	startUp = CPlayerClient.StartUp,
	rhythmSpeed = CPlayerClient.RhythmSpeed,
	notifyRhythm = CPlayerClient.NotifyRhythm,
	getProperty = CPlayerClient.GetSimple32Property,
	setProperty = CPlayerClient.SetSimple32Property,
	addProperty = CPlayerClient.AddSimple32Property,
	notifyProperty = CPlayerClient.NotifySimple32PropertyChanged,
	scoreInfo = CPlayerClient.GetScoreInfo,
	rhythmData = CPlayerClient.GetRhythmData,
	maxScore = CPlayerClient.GetMaxScore,
	allScore = CPlayerClient.CalAllScore,
	initSPT = CPlayerClient.InitSPT32Data,
	playerSettlement = CPlayerClient.GetSettlementData,
	sceneSettlement = CGameScene.GetSettlementData,
	pushTeam = CGameScene.PushSettlementTeam,
	addManorScore = CGameScene.AddManorScore,
	getManorScore = CGameScene.GetManorScore,
	updateManorScore = CGameScene.OnUpdateManorScore,
	newManorScore = CGameMain.NotifyNewManorScore,
}

-- Numeric IDs are authoritative where visible in the supplied disassembly.
local P = {
	PICKUP = 0,
	KILLS = 1,
	DEATHS = eSPT32_DeathCount or 2,
	COMBO_SUM = 3,
	MAX_COMBO = 5,
	MAX_AREA = 13,
	KILL_SCORE = 16,
	AREA_SCORE = 17,
	COMBO_SCORE = 18,
	-- CPlayer::KilledByPlayer (0x342054): property 19 modifies the kill award.
	KILL_BONUS = 19,
	AREA_BONUS = 20,
	COMBO_BONUS = 21,
}
B.SPT = P

local owned = {}
for _, id in pairs(P) do owned[id] = true end

local function u32(n)
	return math.floor(tonumber(n) or 0) % 4294967296
end

local function u16(n)
	return math.floor(tonumber(n) or 0) % 65536
end

local function i32(n)
	n = u32(n)
	if n >= 2147483648 then return n - 4294967296 end
	return n
end

local function f32(n)
	return (string.unpack("<f", string.pack("<f", n)))
end

local function native_u32_from_float(n)
	if n ~= n or n <= 0 then return 0 end
	if n >= 4294967295 then return 4294967295 end
	return math.floor(n)
end

local function method(obj, name)
	if obj == nil then return nil end
	local ok, fn = pcall(function() return obj[name] end)
	return ok and type(fn) == "function" and fn or nil
end

local function call(obj, name, ...)
	local fn = method(obj, name)
	if not fn then return false end
	return pcall(fn, obj, ...)
end

local function constant(name, fallback)
	local ok, value = pcall(function()
		local inst = CSnakeConstant and CSnakeConstant:Inst()
		local fn = inst and inst["Get" .. name]
		return fn and fn(inst)
	end)
	if ok and type(value) == "number" then return value end
	return fallback
end

function B.Enabled(sc)
	return sc ~= nil and sc.__roomType == 0
end

-- Defaults reproduce the supplied config. Runtime reads use the game's existing
-- Host API; failed/unavailable reads retain these defaults.
B.config = {
	volRatio = 4000,
	coinRatio = 75,
	areaPrize = { [0] = 3, [1] = 2, [2] = 1, [3] = 0 },
	killPrize = 400,
	goldCoinCount = 10, -- Exposed to module C; this module creates no items.
	-- CRankPrizeConfig::OnLoadedEnd (0x345424): u32 key/value map.
	rankPrizes = {
		[1] = 320,
		[2] = 280,
		[3] = 240,
		[4] = 220,
		[5] = 200,
		[6] = 180,
		[7] = 180,
		[8] = 180,
		[9] = 180,
		[10] = 180,
		[101] = 400,
		[102] = 320,
		[103] = 240,
		[1001] = 0,
		[1002] = 0,
		[1003] = 0,
		[1004] = 20,
		[1005] = 40,
		[1006] = 60,
		[1007] = 80,
		[10001] = 40,
		[10002] = 60,
		[10003] = 80,
		[10004] = 80,
	},
	faultParam = 0.0156,
	rhythmParam = 0.23,
	maxOneHitScore = 10000,
	comboLevels = {
		{ threshold = 101, level = 0 },
		{ threshold = 51, level = 1 },
		{ threshold = 11, level = 2 },
		{ threshold = 0, level = 3 },
	},
	comboPrizes = {
		{ threshold = 10, prize = 3 },
		{ threshold = 40, prize = 5 },
		{ threshold = 70, prize = 7 },
		{ threshold = 100, prize = 9 },
	},
	-- CRhythmLevelConfig::GetLevel (0x37a104): exact key match, then last-row fallback.
	rhythmLevels = { [0] = 0, [1] = 1, [2] = 2 },
	rhythmLevelFallback = 2,
	evaluate = {
		{ upper = 10,  values = { 2, 2, 2, 0.85, 0.75, 0.6, 0 } },
		{ upper = 50,  values = { 2, 2, 0.9, 0.85, 0.75, 0.6, 0 } },
		{ upper = 100, values = { 2, 0.925, 0.9, 0.85, 0.75, 0.6, 0 } },
		{ upper = -1,  values = { 0.95, 0.925, 0.9, 0.85, 0.75, 0.6, 0 } },
	},
	-- CEvaluateConfig::GetRank (0x33432c): scans SSS through D with codes 6 through 0.
	rankCodes = { 6, 5, 4, 3, 2, 1, 0 },
}

local function read_tsv(path)
	local ok, text = call(Host, "read_text", path)
	if not ok or type(text) ~= "string" then return {} end
	text = text:gsub("^\239\187\191", "")
	local rows = {}
	for line in text:gmatch("[^\r\n]+") do
		if line:match("%S") then
			local row = {}
			for value in (line .. "\t"):gmatch("([^\t]*)\t") do
				row[#row + 1] = value:match("^%s*(.-)%s*$")
			end
			rows[#rows + 1] = row
		end
	end
	return rows
end

function B.ReloadConfig()
	local c = B.config
	c.volRatio = constant("VolRatio", c.volRatio)
	c.coinRatio = constant("CoinRatio", c.coinRatio)

	for _, row in ipairs(read_tsv("config/rhythmscoreparam.txt")) do
		local a, b, m = tonumber(row[1]), tonumber(row[2]), tonumber(row[3])
		if a and b and m then
			c.faultParam, c.rhythmParam, c.maxOneHitScore = a, b, u16(m)
			break
		end
	end

	-- CComboLevelConfig::OnLoadedEnd (0x333b94): columns 2/3 are u32 threshold/u8 level.
	-- Entries are appended in file order without sorting.
	local levels = {}
	for _, row in ipairs(read_tsv("config/combolevel.txt")) do
		local threshold, level = tonumber(row[2]), tonumber(row[3])
		if threshold and level then
			levels[#levels + 1] = {
				threshold = u32(threshold), level = u32(level) % 256,
			}
		end
	end
	if #levels > 0 then
		c.comboLevels = levels
	end

	-- CRhythmLevelConfig::OnLoadedEnd (0x379ea0): columns 2/3 are u32 key/u8 level.
	-- GetLevel returns the first matching row, or the last row's level.
	local rhythms, lastRhythmLevel = {}, nil
	for _, row in ipairs(read_tsv("config/rhythmlevel.txt")) do
		local rhythm, level = tonumber(row[2]), tonumber(row[3])
		if rhythm and level then
			rhythm, level = u32(rhythm), u32(level) % 256
			if rhythms[rhythm] == nil then rhythms[rhythm] = level end
			lastRhythmLevel = level
		end
	end
	if lastRhythmLevel ~= nil then
		c.rhythmLevels = rhythms
		c.rhythmLevelFallback = lastRhythmLevel
	end

	local prizes = {}
	local areaNames = {
		Perfect_Area = 0, Excellent_Area = 1,
		Ordinary_Area = 2, Fault_Area = 3,
	}
	for _, row in ipairs(read_tsv("config/prize.txt")) do
		local key, value = row[2], tonumber(row[3])
		if value then
			if areaNames[key] ~= nil then
				c.areaPrize[areaNames[key]] = value
			elseif key == "BitAim_Count" then
				c.killPrize = value
			elseif key == "GoldCoin_Count" then
				c.goldCoinCount = value
			elseif tonumber(key) then
				prizes[#prizes + 1] = {
					threshold = u32(tonumber(key)), prize = u16(value),
				}
			end
		end
	end
	if #prizes > 0 then
		table.sort(prizes, function(a, b) return a.threshold < b.threshold end)
		c.comboPrizes = prizes
	end

	-- CRankPrizeConfig::OnLoadedEnd (0x345424): skip the header, then assign
	-- columns 1/2 to a u32/u32 map. GetInteger defaults to zero; assignments
	-- overwrite duplicate keys, and the native loader does not clear the map.
	local rankRows = read_tsv("config/rankprize.txt")
	for index = 2, #rankRows do
		local row = rankRows[index]
		c.rankPrizes[u32(tonumber(row[1]) or 0)] = u32(tonumber(row[2]) or 0)
	end

	-- CEvaluateConfig::OnLoadedEnd (0x334440): indices <= 10 enter the rank vector;
	-- larger indices enter the separate color vector. Rank rows retain file order.
	local evaluations = {}
	for _, row in ipairs(read_tsv("config/evaluate.txt")) do
		local index, upper = tonumber(row[1]), tonumber(row[2])
		if index and u32(index) <= 10 and upper then
			local values, valid = {}, true
			for i = 1, 7 do
				local value = tonumber(row[i + 2])
				if value == nil then
					valid = false
				else
					values[i] = f32(value)
				end
			end
			if valid then
				evaluations[#evaluations + 1] = { upper = u32(upper), values = values }
			end
		end
	end
	if #evaluations > 0 then
		c.evaluate = evaluations
	end
	B.__configLoaded = true
	return c
end

function B.GetConfig()
	if not B.__configLoaded then return B.ReloadConfig() end
	return B.config
end

local function init_scene(sc)
	if sc.__b_manorScore then return end
	sc.__b_manorScore = {}
	sc.__b_cellScore = {}
	sc.__b_settledTeams = {}
	sc.__b_eliminationCount = 0
	sc.__b_manorDue = nil
	sc.__b_hudDue = 0
	sc.__b_hudKey = nil
end

local function init_player(p)
	if p.__b_spt then return end
	local st = p.__stats or {}
	p.__stats = st
	st.killCount = st.killCount or 0
	st.pickUpCoin = st.pickUpCoin or 0
	st.areaScore = st.areaScore or 0
	st.killScore = st.killScore or 0
	st.comboScore = st.comboScore or 0
	st.maxGrade = st.maxGrade or { 0, 0, 0, 0 }
	st.serialKillType = st.serialKillType or 0
	st.serialKillCoin = st.serialKillCoin or 0
	st.maxKillCoin = st.maxKillCoin or 0

	p.__b_spt = {
		[P.COMBO_SUM] = 0,
		[P.MAX_COMBO] = 0,
		[P.MAX_AREA] = math.max(st.maxGrade[1] or 0, st.areaScore),
		[P.KILL_SCORE] = st.killScore,
		[P.AREA_SCORE] = st.areaScore,
		[P.COMBO_SCORE] = st.comboScore,
	}
	for _, id in ipairs({ P.KILL_BONUS, P.AREA_BONUS, P.COMBO_BONUS }) do
		local ok, value
		if type(old.getProperty) == "function" then
			ok, value = pcall(old.getProperty, p, id)
		end
		p.__b_spt[id] = ok and type(value) == "number" and u32(value) or 0
	end

	-- Ordered history is needed for combo-level-dependent quality. These fields
	-- never increment or reset the rhythm window's existing p.__rhythm counters.
	p.__b_judgements = {}
	p.__b_combo = 0
	p.__b_maxCombo = 0
	p.__b_rhythmScore = 0
	p.__b_frozen = false
end

local function dirty(p)
	local sc = p.__scene
	if sc then sc.__b_hudKey = nil end
end

function B.GetProperty(p, id)
	init_player(p)
	if id == P.PICKUP then return u32(p.__stats.pickUpCoin) end
	if id == P.KILLS then return u32(p.__stats.killCount) end
	if id == P.DEATHS then return u32(p.__deaths) end
	if p.__b_spt[id] ~= nil then return p.__b_spt[id] end
	if type(old.getProperty) == "function" then
		return old.getProperty(p, id)
	end
	return 0
end

local function store_property(p, id, value)
	init_player(p)
	value = u32(value)
	p.__b_spt[id] = value
	local st = p.__stats
	if id == P.PICKUP then st.pickUpCoin = value
	elseif id == P.KILLS then st.killCount = value
	elseif id == P.DEATHS then p.__deaths = value
	elseif id == P.AREA_SCORE then st.areaScore = value
	elseif id == P.KILL_SCORE then st.killScore = value
	elseif id == P.COMBO_SCORE then st.comboScore = value
	end
	dirty(p)
	return value
end

function B.SetProperty(p, id, value, notify)
	local pre = B.GetProperty(p, id)
	value = store_property(p, id, value)
	-- CPlayer::NotifySimple32PropertyChanged (0x342ebc): signed strict comparison.
	if id == P.AREA_SCORE and i32(value) > i32(B.GetProperty(p, P.MAX_AREA)) then
		B.SetProperty(p, P.MAX_AREA, value, notify)
	end
	if notify ~= false and pre ~= value then
		p:NotifySimple32PropertyChanged(id, value, pre)
	end
	return value
end

function B.AddProperty(p, id, delta)
	return B.SetProperty(p, id, u32(B.GetProperty(p, id) + delta))
end

-- Module C may use this, or Set/AddSimple32Property(0, ...), or its existing
-- __stats.pickUpCoin producer plus NotifySimple32PropertyChanged(0, new, old).
function B.AddPickupCoin(p, amount)
	return B.AddProperty(p, P.PICKUP, amount)
end

local function combo_level(combo)
	local levels = B.GetConfig().comboLevels
	combo = u32(combo)
	for _, row in ipairs(levels) do
		-- CComboLevelConfig::GetLevel (0x333df8): first unsigned inclusive match.
		if combo >= row.threshold then return row.level end
	end
	return levels[#levels].level
end

local function rhythm_level(grade)
	local c = B.GetConfig()
	-- CRhythmLevelConfig::GetLevel (0x37a104): equality, then last-row fallback.
	local level = c.rhythmLevels[u32(grade)]
	if level ~= nil then return level end
	return c.rhythmLevelFallback
end

local function combo_prize(combo)
	local prizes = B.GetConfig().comboPrizes
	combo = u32(combo)
	-- CPrizeConfig::GetRatioByCount (0x344270): count <= first threshold gives zero;
	-- each interval is (current threshold, next threshold], returning current u16.
	if combo <= prizes[1].threshold then return 0 end
	for i = 1, #prizes - 1 do
		if prizes[i].threshold < combo and combo <= prizes[i + 1].threshold then
			return u16(prizes[i].prize)
		end
	end
	return u16(prizes[#prizes].prize)
end

local function rhythm_ratio(p)
	init_player(p)
	local n = #p.__b_judgements
	local denominator = u32(n * B.GetConfig().maxOneHitScore)
	if denominator == 0 then return 0 end
	return f32(f32(p.__b_rhythmScore) / f32(denominator))
end

function B.GetAccuracy(p)
	return rhythm_ratio(p)
end

function B.OnRhythm(p, grade)
	if not B.Enabled(p.__scene) or p.__b_frozen then return end
	if type(grade) ~= "number" or grade % 1 ~= 0 or grade < 0 or grade > 3 then return end
	init_player(p)
	local c = B.GetConfig()
	p.__b_judgements[#p.__b_judgements + 1] = grade
	p.__b_combo = grade == 3 and 0 or u32(p.__b_combo + 1)
	p.__b_maxCombo = math.max(p.__b_maxCombo, p.__b_combo)

	if grade ~= 3 then
		-- Match the separate ARM single-precision VMLS/VMUL operations.
		local factor = f32(1 - f32(f32(c.faultParam) * f32(combo_level(p.__b_combo))))
		factor = f32(factor - f32(f32(c.rhythmParam) * f32(rhythm_level(grade))))
		local hit = native_u32_from_float(f32(f32(c.maxOneHitScore) * factor))
		p.__b_rhythmScore = u32(p.__b_rhythmScore + hit)
	end

	if p.__b_maxCombo > B.GetProperty(p, P.MAX_COMBO) then
		B.SetProperty(p, P.MAX_COMBO, p.__b_maxCombo)
	end

	-- Vtable +0xcc is the additive property operation: property 3 accumulates
	-- each current streak length, rather than storing the current streak.
	B.AddProperty(p, P.COMBO_SUM, p.__b_combo)

	local prize = combo_prize(p.__b_combo)
	if prize ~= 0 then
		local product = u32(prize * B.GetProperty(p, P.COMBO_BONUS))
		B.AddProperty(p, P.COMBO_SCORE, prize + math.floor(product / 10000))
	end
	p.__b_accuracy = rhythm_ratio(p)
end

local function evaluation_rank(ratio, total)
	local c = B.GetConfig()
	total = u32(total)
	for _, row in ipairs(c.evaluate) do
		-- CEvaluateConfig::GetRank (0x33432c): first unsigned inclusive ceiling.
		if total <= u32(row.upper) then
			-- OnLoadedEnd (0x334440) stores D..SSS at +4..+0x1c.
			-- GetRank scans backward from +0x1c with codes 6..0 and accepts equality.
			for index, threshold in ipairs(row.values) do
				if ratio >= f32(threshold) then return c.rankCodes[index] end
			end
			-- Native has no lower bound on this scan. Supplied D=0 and nonnegative
			-- rhythm ratios always match before it would read outside the array.
			error("CEvaluateConfig::GetRank would read before its threshold array")
		end
	end
	return 0
end

local function rhythm_stats(p)
	init_player(p)
	local n = #p.__b_judgements
	local r = p.__rhythm

	-- Reuse the existing window counters when synchronized. AI currently calls
	-- RhythmSpeed without a window, so its ordered history supplies the fallback.
	if r and r.total == n and r.count then
		return r.maxCombo or 0, n, r.count
	end

	p.__b_rhythmStatsMismatch = r ~= nil and (r.total or 0) ~= n
	local counts = { 0, 0, 0, 0 }
	for _, grade in ipairs(p.__b_judgements) do
		counts[grade + 1] = counts[grade + 1] + 1
	end
	return p.__b_maxCombo, n, counts
end

local function total_score(p)
	return u32(B.GetProperty(p, P.KILL_SCORE)
		+ B.GetProperty(p, P.AREA_SCORE)
		+ B.GetProperty(p, P.COMBO_SCORE))
end

local function max_scores(p)
	-- CPlayer::GetMaxScore (0x341a40): properties 13, 16, 18, then their
	-- wrapping u32 sum. Only the area component is a separate maximum property.
	local area = B.GetProperty(p, P.MAX_AREA)
	local kill = B.GetProperty(p, P.KILL_SCORE)
	local combo = B.GetProperty(p, P.COMBO_SCORE)
	return { area, kill, combo, u32(area + kill + combo) }
end

local function reward_coins(score)
	local divisor = u32(B.GetConfig().coinRatio)
	if divisor <= 0 then return 0 end
	return math.floor(score / divisor)
end

local function kill_prize(kind)
	-- CRankPrizeConfig::GetKillPrize (0x345604): the argument is a byte.
	-- Zero returns immediately; every nonzero type >= 4 uses key 10004.
	kind = u32(kind) % 256
	if kind == 0 then return 0 end
	kind = math.min(kind, 4)


	-- CRankPrizeConfig::GetKillPrize (0x345604): std::map::operator[]
	-- inserts a zero value when 10000 + clamped type is absent.
	local prizes = B.GetConfig().rankPrizes
	local key = 10000 + kind
	if prizes[key] == nil then prizes[key] = 0 end
	return u32(prizes[key])
end

-- config.lua's generic Get* adapter would read a nonexistent KillPrize
-- column and silently return zero, so expose the recovered native explicitly.
function CRankPrizeConfig:GetKillPrize(kind)
	return kill_prize(kind)
end

function B.SetKillPrizeTypes(p, currentType, maximumType)
	init_player(p)
	p.__b_killPrizeType = math.floor(currentType or 0) % 256
	p.__b_maxKillPrizeType = math.floor(maximumType or currentType or 0) % 256
	dirty(p)
end

local function sync_legacy(p)
	init_player(p)
	local st = p.__stats
	st.allScore = total_score(p)
	st.allCoin = reward_coins(st.allScore)
	st.maxGrade = max_scores(p)
	st.serialKillType = p.__b_killPrizeType or st.serialKillType or 0
	-- CPlayer::GetScoreInfo (0x341a70): independently look up the bytes
	-- at +0x175 and +0x176; neither prize falls back to a previous coin value.
	st.serialKillCoin = kill_prize(st.serialKillType)
	st.maxKillCoin = kill_prize(p.__b_maxKillPrizeType or 0)
	return st
end

local function node_count(p)
	-- CPlayer::GetNodeCount (0x341976): manor +0x68 takes precedence over cache +0x15c.
	if p.__manor then return u32(p.__manor.count or 0) end
	return u32(p.__b_deathNodes or 0)
end

local function write_score_info(p, buf)
	-- CPlayer::GetScoreInfo (0x341a70): packed offsets +0/+4 totals, +8 area,
	-- +0xc combo, +0x10 kill, +0x14 u8 kills, +0x15 nodes, +0x19 pickup,
	-- +0x1d four max-score words, +0x2d type, +0x2e/+0x32 kill prizes.
	local st = sync_legacy(p)
	buf:SetPosition(0)
	buf:WriteUint32(st.allScore)
	buf:WriteUint32(st.allCoin)
	buf:WriteUint32(B.GetProperty(p, P.AREA_SCORE))
	buf:WriteUint32(B.GetProperty(p, P.COMBO_SCORE))
	buf:WriteUint32(B.GetProperty(p, P.KILL_SCORE))
	buf:WriteUint8(B.GetProperty(p, P.KILLS) % 256)
	buf:WriteUint32(u32(node_count(p)))
	buf:WriteUint32(B.GetProperty(p, P.PICKUP))
	for i = 1, 4 do buf:WriteUint32(st.maxGrade[i]) end
	buf:WriteUint8(st.serialKillType % 256)
	buf:WriteUint32(st.serialKillCoin)
	buf:WriteUint32(st.maxKillCoin)
	buf:SetPosition(0)
end

local function write_rhythm_data(p, buf)
	local maximum, total, counts = rhythm_stats(p)
	local rank = evaluation_rank(rhythm_ratio(p), total)
	buf:SetPosition(0)
	buf:WriteUint32(u32(maximum))
	buf:WriteUint32(u32(total))
	buf:WriteUint8(rank)
	for i = 1, 4 do buf:WriteUint32(u32(counts[i])) end
	buf:SetPosition(0)
end

local function player_data(p)
	if p.__b_settlement then return p.__b_settlement end
	-- CPlayer::GetSettlementData (0x3419fc): account +0x48/+0x4c, nickname +0x10b,
	-- object +0x1c, appearance words +0x56 then +0x54, followed by CalAllScore.
	return {
		accountID = p.__accountID or 0,
		nickName = p.__nick or "",
		objectID = p.__objectID or 0,
		equipID = p.__equipID or 0,
		headID = p.__b_headID or 0,
		score = total_score(p),
	}
end

local function copy_player_data(data)
	return {
		accountID = data.accountID,
		nickName = data.nickName,
		objectID = data.objectID,
		equipID = data.equipID,
		headID = data.headID,
		score = data.score,
	}
end

local function write_player_data(buf, data, recordOffset)
	recordOffset = recordOffset or 0
	buf:SetPosition(recordOffset)
	local write64 = method(buf, "WriteUint64")
	if write64 then
		write64(buf, data.accountID)
	else
		-- Lua 5.4 integer account IDs retain their complete 64-bit bit pattern.
		local account = assert(math.tointeger(data.accountID), "accountID must be a 64-bit integer")
		buf:WriteUint32(account & 0xffffffff)
		buf:WriteUint32((account >> 32) & 0xffffffff)
	end

	-- CPlayer::GetSettlementData (0x3419fc): at most 21 raw nickname bytes,
	-- one terminating NUL, and no writes to the remaining nickname padding.
	local nick = (data.nickName or ""):gsub("%z.*", ""):sub(1, 21)
	for i = 1, #nick do buf:WriteUint8(nick:byte(i)) end
	buf:WriteUint8(0)
	buf:SetPosition(recordOffset + 0x1e)
	buf:WriteUint16(u16(data.objectID))
	buf:WriteUint16(u16(data.equipID))
	buf:WriteUint16(u16(data.headID))
	-- +0x24..+0x27 are unwritten; the score is at +0x28 in a 44-byte record.
	buf:SetPosition(recordOffset + 0x28)
	buf:WriteUint32(u32(data.score))
end

local function manor_player(sc, mid)
	local p = sc.__byManor and sc.__byManor[mid]
	if p then return p end
	for _, candidate in ipairs(sc.__order or {}) do
		if candidate.__manor and candidate.__manor.manorID == mid then return candidate end
	end
end

local function manor_members(sc, mid)
	local count = 0
	for _, p in ipairs(sc.__order or {}) do
		if p.__alive and p.__manor and p.__manor.manorID == mid then
			count = count + 1
		end
	end
	return math.max(1, count)
end

local function unit_area_prize(sc, idx)
	local grade = u32(sc.__val and sc.__val[idx] or constant("InitRhythmID", 0)) % 256
	-- CManor::OnAddUnit/OnRemoveUnit (0x33dfd0/0x33e138): only valuation bytes 0..3 score.
	if grade > 3 then return 0, false end
	return u32(B.GetConfig().areaPrize[grade] or 0), true
end

-- CManor::OnAddUnit (0x33dfd0): room 0 starts with multiplier 1, adds
-- multiplier * signed owner property 20 / 10000, multiplies by GetPrize(valuation),
-- then by signed VolRatio, then divides by 10000. All operations use f64.
-- Rendering Height1..5 is deliberately not used to rescore territory.
function B.AreaValue(sc, idx, mid)
	local base, scored = unit_area_prize(sc, idx)
	if not scored then return 0 end
	local c = B.GetConfig()
	local p = manor_player(sc, mid)
	local factor = 1
	if p then
		factor = factor + (factor * i32(B.GetProperty(p, P.AREA_BONUS))) / 10000
	end
	return ((base * factor) * i32(c.volRatio)) / 10000
end

function B.AddManorScore(sc, mid, delta)
	if not B.Enabled(sc) then return end
	init_scene(sc)
	local value = (sc.__b_manorScore[mid] or 0) + delta
	sc.__b_manorScore[mid] = value > 0 and value or 0
	if sc.__b_manorDue == nil then
		sc.__b_manorDue = (sc.__time or 0) + 1000
	end
end

function B.GetManorScore(sc, mid)
	init_scene(sc)
	-- CGameScene::GetManorScore (0x337448): add f64 0.5, then saturating u32 conversion.
	return native_u32_from_float((sc.__b_manorScore[mid] or 0) + 0.5)
end

function B.OnOwnerChanged(sc, idx, previousOwner, newOwner)
	if not B.Enabled(sc) or previousOwner == newOwner then return end
	init_scene(sc)
	local base, scored = unit_area_prize(sc, idx)

	if previousOwner ~= 0 and scored then
		-- CManor::OnRemoveUnit (0x33e138): current valuation prize * signed VolRatio
		-- / 10000, negated. Removal omits the owner bonus, so bonus residue is literal.
		local removed = (base * i32(B.GetConfig().volRatio)) / 10000
		B.AddManorScore(sc, previousOwner, -removed)
	end

	if newOwner ~= 0 then
		local value = B.AreaValue(sc, idx, newOwner)
		sc.__b_cellScore[idx] = value
		if scored then B.AddManorScore(sc, newOwner, value) end
	else
		sc.__b_cellScore[idx] = nil
	end
	sc.__b_hudKey = nil
end

function B.OnUpdateManorScore(sc)
	if not B.Enabled(sc) then return end
	init_scene(sc)
	sc.__b_manorDue = nil
	for _, p in ipairs(sc.__order or {}) do
		if p.__alive and not p.__b_frozen then
			local mid = p.__manor.manorID
			local score = math.floor(B.GetManorScore(sc, mid) / manor_members(sc, mid))
			B.SetProperty(p, P.AREA_SCORE, score)
		end
	end
end

function B.InitSPT32Data(p, memberCount)
	if not B.Enabled(p.__scene) then return end
	init_player(p)
	local sc = p.__scene
	local count = math.max(1, math.floor(memberCount or manor_members(sc, p.__manor.manorID)))
	B.SetProperty(p, P.AREA_SCORE,
		math.floor(B.GetManorScore(sc, p.__manor.manorID) / count))
end

function B.BeginCapture(sc, p)
	if not B.Enabled(sc) then return end
	init_player(p)
	p.__b_captureBefore = B.GetManorScore(sc, p.__manor.manorID)
end

function B.EndCapture(sc, p, gained)
	if not B.Enabled(sc) then return end
	local now = B.GetManorScore(sc, p.__manor.manorID)
	local added = math.max(0, now - (p.__b_captureBefore or now))
	p.__b_captureBefore = nil
	if gained > 0 and p == sc.m_pDirectorObj then
		local ok, gm = call(g_App, "GetGameMain")
		if ok and gm then gm:NotifyNewManorScore(added, gained) end
	end
	B.RefreshHUD(sc, true)
end

function B.BeforeKill(sc, victim)
	if not B.Enabled(sc) then return end
	init_player(victim)
	if victim.__b_frozen then return end
	-- CPlayer::KilledByPlayer (0x342054): no write to +0x15c and no manor
	-- detachment appears in this body.
	-- ASSUMPTION: retain the snapshot before simulated territory cleanup.
	-- Missing: the +0x15c cache-writer/manor-detachment function (symbol not supplied).
	-- CPlayer::GetNodeCount (0x341976) still reads an attached manor first.
	victim.__b_deathNodes = victim.__manor and victim.__manor.count or 0
	victim.__b_endTime = sc.__time or 0
	victim.__b_frozen = true
	-- Do not force the pending manor tick: native GetScoreInfo also reads the
	-- currently published properties without calling OnUpdateManorScore.
	sync_legacy(victim)
end

function B.OnKill(sc, killer, victim)
	if not B.Enabled(sc) or not killer then return end
	init_player(killer)
	-- scene.lua has already incremented __kills and __stats.killCount.
	killer:NotifySimple32PropertyChanged(
		P.KILLS, killer.__stats.killCount, killer.__stats.killCount - 1)

	-- CPlayer::KilledByPlayer (0x342054): invoke the killer's virtual +0x60
	-- with the victim before the award path. With a false first flag, obtain
	-- GetPrize(4), add 1 to killer property 1, then read property 19 and add
	-- base + floor(low32(base * property 19) / 10000) to property 16.
	-- Room 0 bypasses the nonzero-room time-based doubling branch.
	-- CPlayerClient::KilledByPlayer (0x3965ac): the base tail-call passes
	-- both flags as false. This hook handles that ordinary kill award.
	--
	-- CFightCalculator::OnKilling (0x334b04): update calculator property 2
	-- for a one-member victim manor, then call UpdateMagic.
	-- CFightCalculator::UpdateMagic (0x3349dc): expire or dispatch magic
	-- nodes through virtual callbacks; it contains no additional fixed award.
	-- ASSUMPTION: magic-specific changes remain with existing property producers;
	-- the dispatched magic-property virtual callback bodies are missing.
	local base = u32(B.GetConfig().killPrize)
	local extra = math.floor(u32(base * B.GetProperty(killer, P.KILL_BONUS)) / 10000)
	B.AddProperty(killer, P.KILL_SCORE, base + extra)
end

function B.PushSettlementTeam(sc, players, count, mid)
	if not B.Enabled(sc) then return end
	init_scene(sc)
	if sc.__b_settledTeams[mid] then return sc.__b_settledTeams[mid] end

	local members = {}
	for i = 1, count do
		local p = players[i]
		if p and p.__manor and p.__manor.manorID == mid then
			members[#members + 1] = copy_player_data(player_data(p))
		end
	end
	if #members == 0 then return nil end

	-- CGameScene::PushSettlementTeam (0x33956c): copy scene +0x480 into
	-- the cached team, without modifying that scene field.
	-- CGameScene::GetSettlementData (0x33b74c): use that copied sequence
	-- to place the cached team relative to the current scene sequence.
	-- ASSUMPTION: retain offline sequences 1..N. Missing: the function
	-- writing CGameScene +0x480 (symbol not supplied).
	sc.__b_eliminationCount = sc.__b_eliminationCount + 1
	local team = {
		manorID = mid,
		players = members,
		eliminationOrder = sc.__b_eliminationCount,
	}
	sc.__b_settledTeams[mid] = team
	return team
end

function B.AfterKill(sc, victim)
	if not B.Enabled(sc) then return end
	victim:NotifySimple32PropertyChanged(
		P.DEATHS, victim.__deaths, math.max(0, victim.__deaths - 1))
	victim.__b_settlement = copy_player_data(player_data(victim))

	local mid = victim.__manor.manorID
	local survivor = false
	for _, p in ipairs(sc.__order or {}) do
		if p.__alive and p.__manor and p.__manor.manorID == mid then
			survivor = true
			break
		end
	end
	if not survivor then
		B.PushSettlementTeam(sc, sc.__order, #sc.__order, mid)
	end
	B.RefreshHUD(sc, true)
end

-- ASSUMPTION: retain these offline defaults. Missing: the native settlement
-- caller and its comparator functions. CGameScene::GetSettlementData (0x33b74c)
-- uses the supplied function pointers and specifies no default or ID tie-break.
local function default_player_less(a, b)
	if a.score ~= b.score then return a.score > b.score end
	return a.objectID < b.objectID
end

local function default_team_less(a, b)
	if a.score ~= b.score then return a.score > b.score end
	return a.manorID < b.manorID
end

function B.GetSettlementTeams(sc, teamLess, playerLess)
	init_scene(sc)
	local active, byManor = {}, {}
	-- ASSUMPTION: the existing __alive/__order selection represents the
	-- missing CGameScene virtual +0x104 player-enumeration function.
	for _, p in ipairs(sc.__order or {}) do
		local mid = p.__manor and p.__manor.manorID
		if p.__alive and mid and not sc.__b_settledTeams[mid] then
			local team = byManor[mid]
			if not team then
				team = { manorID = mid, players = {}, score = 0 }
				byManor[mid] = team
				active[#active + 1] = team
			end
			local data = copy_player_data(player_data(p))
			team.players[#team.players + 1] = data
			team.score = u32(team.score + data.score)
		end
	end

	-- CGameScene::GetSettlementData (0x33b74c): first sort enumerated
	-- players by unsigned manor ID, group them, and omit already cached teams.
	-- Thus newly assembled active teams enter their comparator sort in manor order.
	table.sort(active, function(a, b)
		return u32(a.manorID) < u32(b.manorID)
	end)
	-- The native team comparator applies before cached teams are inserted.
	table.sort(active, teamLess or default_team_less)

	-- CGameScene::GetSettlementData (0x33b74c): resize to activeCount +
	-- scene +0x480, then copy each cached team to the zero-based index
	-- activeCount + sceneSequence - cachedSequence. No team comparator is
	-- applied to the cached teams. The offline 1..N sequence assumption above
	-- makes these slots contiguous and places later eliminations first.
	local activeCount = #active
	local sceneSequence = u32(sc.__b_eliminationCount)
	local finalCount = u32(activeCount + sceneSequence)
	for i = #active, finalCount + 1, -1 do active[i] = nil end
	for i = activeCount + 1, finalCount do
		active[i] = { manorID = 0, players = {}, score = 0 }
	end

	for _, cached in pairs(sc.__b_settledTeams) do
		local team = {
			manorID = cached.manorID,
			eliminationOrder = cached.eliminationOrder,
			players = {},
			score = 0,
		}
		for _, data in ipairs(cached.players) do
			local copy = copy_player_data(data)
			team.players[#team.players + 1] = copy
			team.score = u32(team.score + copy.score)
		end
		local slot = u32(activeCount + sceneSequence - u32(cached.eliminationOrder)) + 1
		active[slot] = team
	end

	-- CGameScene::GetSettlementData (0x33b74c): sort every team's player
	-- vector only after active sorting and cached-team placement are complete.
	for rank, team in ipairs(active) do
		team.rank = rank
		table.sort(team.players, playerLess or default_player_less)
	end
	return active
end

-- CGameScene::GetSettlementData (0x33b74c): outputs a C++ vector of
-- SSettTeamData; each ARM team object is a u32 manor ID followed by a
-- three-word player vector. This in-memory layout does not establish a wire format.
-- ASSUMPTION: retain this explicit OFFLINE envelope:
-- u32 teamCount; repeated {u32 manorID, u32 playerCount, playerCount * 44 bytes}.
-- Missing: CGameScene::GetSettlementData's Lua binding/serializer.
-- CPlayer::GetSettlementData (0x3419fc) establishes the 44-byte player layout.
function B.WriteSettlementTeams(buf, teams)
	buf:SetPosition(0)
	buf:WriteUint32(#teams)
	local position = 4
	for _, team in ipairs(teams) do
		buf:WriteUint32(u32(team.manorID))
		buf:WriteUint32(#team.players)
		position = position + 8
		for _, data in ipairs(team.players) do
			write_player_data(buf, data, position)
			position = position + 44
		end
	end
	buf:SetPosition(0)
end

local function find_child(root, path)
	local wnd = root
	for component in path:gmatch("[^.]+") do
		local ok, child = call(wnd, "GetDlgChild", component)
		if not ok or child == nil then return nil end
		wnd = child
	end
	return wnd
end

function B.RefreshHUD(sc, force)
	if not B.Enabled(sc) then return end
	init_scene(sc)
	local now = sc.__time or 0
	if not force and now < sc.__b_hudDue then return end
	sc.__b_hudDue = now + 100

	local p = sc.m_pDirectorObj
	if not p then return end
	local ok, gm = call(g_App, "GetGameMain")
	if not ok or not gm then return end

	local st = sync_legacy(p)
	local total = math.max(1, (sc.__W or 0) * (sc.__H or 0))
	local nodes = node_count(p)
	local kills = B.GetProperty(p, P.KILLS)
	local pickup = p:GetSimple32Property(P.PICKUP)
	-- CPlayer::NotifySimple32PropertyChanged (0x342ebc): this is the base
	-- property handler, covering property 17's signed maximum and properties
	-- 6/7's level/skill changes. It contains no HUD coin update.
	-- ASSUMPTION: the HUD gold label displays score-earned + picked-up rewards.
	-- Missing: CPlayerClient::NotifySimple32PropertyChanged's HUD update path
	-- for "jinbi.E-jinbishuliang". GetScoreInfo (0x341a70) keeps the fields separate.
	local coins = u32(st.allCoin + (tonumber(pickup) or 0))
	local key = table.concat({ p.__objectID or 0, nodes, kills, coins }, ":")
	if sc.__b_hudKey == key then return end
	sc.__b_hudKey = key

	-- ASSUMPTION: these GUI controls expose SetWndText. Missing:
	-- Gamma::CGWnd::SetWndText's Lua binding and CGameMain's HUD control
	-- initialization. CGameMain::CGameMain (0x38b688) does not bind these controls.
	call(find_child(gm, "gerenchengji.E_changdu"), "SetWndText",
		string.format("%0.1f%%", nodes * 100 / total))
	call(find_child(gm, "gerenchengji.E_jisha"), "SetWndText", tostring(kills))
	call(find_child(gm, "jinbi.E-jinbishuliang"), "SetWndText", tostring(coins))
end

function B.NotifyNewManorScore(gm, score, nodes)
	local ok, sc = call(g_App, "GetScene")
	if not ok or not B.Enabled(sc) then return end
	if not nodes or nodes <= 0 then return end   -- nothing captured: no "+0.0%" popup (Claude)
	local total = math.max(1, sc.__W * sc.__H)
	local percentage = f32(f32(f32(nodes) * f32(100)) / f32(total))
	local text = string.format("+%0.1f%%", percentage)
	gm.__b_lastCapture = { score = score, nodes = nodes, text = text }

	-- Preferred renderer bridge. Neither this nor the fallback changes heights.
	local shown = call(Host and Host.scene_view, "show_capture_popup",
		text, 1000, "fx/cfg/quandi.eft", "fx/cfg/jisha.eft")
	if shown then return end

	-- ASSUMPTION: retain W_quandi as the offline fallback for both operations.
	-- NotifyNewManorScore (0x38bff4) uses separate cached windows at +0x4c
	-- (AddEffect) and +0x68 (SetEffectText). Its constructor (0x38b688) initializes
	-- +0x4c to NULL and allocates +0x68, but the later initializer is missing. AddScoreEffectFly (0x38b7fc) names
	-- W_quandi.W_NumEffect as its flight anchor, without identifying either field.
	local wnd = find_child(gm, "W_quandi")
	call(wnd, "RemoveAllEffects")
	call(wnd, "AddEffect", "fx/cfg/jisha.eft", "fx/quandi", "quandi",
		1000, false, false, false, 1)
	-- CGameMain::NotifyNewManorScore (0x38bff4): text color literal at 0x38c294.
	local setEffect = call(wnd, "SetEffectText",
		"fx/cfg/quandi.eft", text, 0x00fefbea, 1000)
	if not setEffect then call(wnd, "SetText", text) end
end

function B.Tick(sc)
	if not B.Enabled(sc) or not sc.__started then return end
	init_scene(sc)
	if sc.__b_manorDue and (sc.__time or 0) >= sc.__b_manorDue then
		B.OnUpdateManorScore(sc)
	end
	B.RefreshHUD(sc, false)
end

-- Install native wrappers before the original Lua captures native functions.

function CGameScene:Create(renderer, roomType, ...)
	if roomType == 0 then
		self.__b_manorScore = nil
		init_scene(self)
	end
	return old.create(self, renderer, roomType, ...)
end

function CGameScene:AddPlayer(...)
	local p = old.addPlayer(self, ...)
	if B.Enabled(self) and p then init_player(p) end
	return p
end

function CPlayerClient:StartUp(...)
	local result = pack_values(old.startUp(self, ...))
	if B.Enabled(self.__scene) and self.__alive then
		init_player(self)
		B.InitSPT32Data(self)
		self.__maxCount = math.max(self.__maxCount or 0, self.__manor.count)
		B.RefreshHUD(self.__scene, true)
	end
	return unpack_values(result, 1, result.n)
end

function CGameScene:Update(...)
	local result = pack_values(old.update(self, ...))
	B.Tick(self)
	return unpack_values(result, 1, result.n)
end

function CPlayerClient:RhythmSpeed(grade, ...)
	local result = pack_values(old.rhythmSpeed(self, grade, ...))
	if B.Enabled(self.__scene) then B.OnRhythm(self, grade) end
	return unpack_values(result, 1, result.n)
end

function CPlayerClient:NotifyRhythm(grade)
	if not B.Enabled(self.__scene) then
		if type(old.notifyRhythm) == "function" then
			return old.notifyRhythm(self, grade)
		end
		return
	end
	if type(grade) ~= "number" or grade % 1 ~= 0 or grade < 0 or grade > 3 then return end
	-- Current scene.lua has no concrete NotifyRhythm. Route through the existing
	-- speed/valuation implementation; its wrapper records exactly one event.
	-- A caller must use NotifyRhythm OR RhythmSpeed once per judgement.
	return self:RhythmSpeed(grade)
end

function CPlayerClient:GetSimple32Property(id)
	if B.Enabled(self.__scene) and owned[id] then return B.GetProperty(self, id) end
	if type(old.getProperty) == "function" then return old.getProperty(self, id) end
	return 0
end

function CPlayerClient:SetSimple32Property(id, value)
	if B.Enabled(self.__scene) and owned[id] then return B.SetProperty(self, id, value) end
	if type(old.setProperty) == "function" then return old.setProperty(self, id, value) end
end

function CPlayerClient:AddSimple32Property(id, value)
	if B.Enabled(self.__scene) and owned[id] then return B.AddProperty(self, id, value) end
	if type(old.addProperty) == "function" then return old.addProperty(self, id, value) end
end

function CPlayerClient:NotifySimple32PropertyChanged(id, value, pre)
	if B.Enabled(self.__scene) and owned[id] then
		store_property(self, id, value)
		-- CPlayer::NotifySimple32PropertyChanged (0x342ebc): signed strict comparison.
		if id == P.AREA_SCORE and i32(value) > i32(B.GetProperty(self, P.MAX_AREA)) then
			B.SetProperty(self, P.MAX_AREA, value)
		end
	end
	if type(old.notifyProperty) == "function" then
		return old.notifyProperty(self, id, value, pre)
	end
end

function CPlayerClient:CalAllScore()
	if B.Enabled(self.__scene) then return total_score(self) end
	if type(old.allScore) == "function" then return old.allScore(self) end
	return 0
end

function CPlayerClient:GetMaxScore(buf)
	if not B.Enabled(self.__scene) then
		if type(old.maxScore) == "function" then return old.maxScore(self, buf) end
		return
	end
	local values = max_scores(self)
	if not buf then return unpack_values(values) end
	buf:SetPosition(0)
	for i = 1, 4 do buf:WriteUint32(values[i]) end
	buf:SetPosition(0)
end

function CPlayerClient:GetScoreInfo(buf)
	if B.Enabled(self.__scene) then return write_score_info(self, buf) end
	return old.scoreInfo(self, buf)
end

function CPlayerClient:GetRhythmData(buf)
	if B.Enabled(self.__scene) then return write_rhythm_data(self, buf) end
	return old.rhythmData(self, buf)
end

function CPlayerClient:InitSPT32Data(memberCount)
	if B.Enabled(self.__scene) then return B.InitSPT32Data(self, memberCount) end
	if type(old.initSPT) == "function" then return old.initSPT(self, memberCount) end
end

function CPlayerClient:GetSettlementData(buf)
	if not B.Enabled(self.__scene) then
		if type(old.playerSettlement) == "function" then
			return old.playerSettlement(self, buf)
		end
		return
	end
	local data = copy_player_data(player_data(self))
	if not buf then return data end
	buf:SetPosition(0)
	write_player_data(buf, data)
	buf:SetPosition(0)
	return data
end

function CGameScene:AddManorScore(mid, delta)
	if B.Enabled(self) then return B.AddManorScore(self, mid, delta) end
	if type(old.addManorScore) == "function" then return old.addManorScore(self, mid, delta) end
end

function CGameScene:GetManorScore(mid)
	if B.Enabled(self) then return B.GetManorScore(self, mid) end
	if type(old.getManorScore) == "function" then return old.getManorScore(self, mid) end
	return 0
end

function CGameScene:OnUpdateManorScore()
	if B.Enabled(self) then return B.OnUpdateManorScore(self) end
	if type(old.updateManorScore) == "function" then return old.updateManorScore(self) end
end

function CGameScene:PushSettlementTeam(players, count, mid)
	if B.Enabled(self) then return B.PushSettlementTeam(self, players, count, mid) end
	if type(old.pushTeam) == "function" then return old.pushTeam(self, players, count, mid) end
end

function CGameScene:GetSettlementData(out, teamLess, playerLess)
	if not B.Enabled(self) then
		if type(old.sceneSettlement) == "function" then
			return old.sceneSettlement(self, out, teamLess, playerLess)
		end
		return
	end
	local teams = B.GetSettlementTeams(self, teamLess, playerLess)
	if out and method(out, "WriteUint32") then
		B.WriteSettlementTeams(out, teams)
	elseif out then
		for key in pairs(out) do
			if type(key) == "number" then out[key] = nil end
		end
		for i, team in ipairs(teams) do out[i] = team end
	end
	return teams
end

function CGameMain:NotifyNewManorScore(score, nodes)
	local ok, sc = call(g_App, "GetScene")
	if ok and B.Enabled(sc) then return B.NotifyNewManorScore(self, score, nodes) end
	if type(old.newManorScore) == "function" then
		return old.newManorScore(self, score, nodes)
	end
end

return B