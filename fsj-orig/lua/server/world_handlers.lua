-- In-process offline World server handlers for Lua 5.4; load after fake_world.lua.
-- Assumptions: profile JSON is stored at user://profile.json; missing config data makes purchases free.
-- Handles World: CValidateClient, CQueryExitGame, CRename, CLimitTimeRoom, CEndlessData,
-- CBuySkin, CUsingSkin, CQueryActivateCode, CCreateTeam, CJoinTeam, CSetMusic,
-- CSendMsg2CustomerService, CReciveCustomerServiceAnswer, CAddReport, CSearchPlayers,
-- CGetFirstChargePrize, CCreateClan, CUploadPicture, CDeletePicture, CStartMatchTeam,
-- CStopMatchTeam, CLeaveTeam, CChangeHeadIcon, CBuyMusic, CInvitePlayer, CJoinGame,
-- CRefuseInvite, CCancelFRRename, CSpecialOffer, CQueryPropellPlayer, CAddCommend,
-- CQueryPictureData, CQueryPlayerBaseData, CGetAllRecordNew, CSendWorldGMCmd,
-- CBuyRhythmNoticeBar, CUseRhythmNoticeBar, CBuyBattleFace, CUseBattleFace,
-- CObserveGame, CAddCommendDay, CQueryRainbowGold, CAlterUseSkill, CAchieveGuide,
-- CUnLockTreasureBox, CAccelerateTreasureBox, CCouldOpenTreasureBox, COpenTreasureBox,
-- CFusion, CCheckEnterRoom, CVideoGuideLog, CSettingLog, CShareResult,
-- CDiacardTreasureBox, CQueryChangeMatchPos, CAnswerChangeMatchPos, CChangeMatchReady,
-- CMatchPosHandle, CDeclaration, CQueryActivity, CAlterPassiveSkill, CUpgradeSkill,
-- CDelockSkill, CGuestUpgrade, CAlterFirstEvent, CQueryPrize, CQueryVipPrize,
-- CJoinRace, CQueryWorldRaceInfo, CAlterPlayerInfo, CAlterSignature.
-- Handles Social: CAddFollowee, CRemoveFollowee, CAddBlacklist, CRemoveBlacklist,
-- CQueryCharInfo, CSetRefuseFollowers, CClearNewFollowers, CSendIMNewMessage,
-- CQueryRelationshipCount, CFuzzySearchClan, CJoinClan, CExitClan, CKickClan,
-- CAccurateSearchClan, CQueryPropellClan, CQueryApplyList, CClanApplyOperate,
-- CSetClanInfo, CSetClanMemberPower, CCustomSearchClan.
-- Handles Rank: CQueryFolloweesRank, CQueryWorldRecord, CQueryWorldMaxRecord.

local H = FakeWorld.handlers
local unpack_fn = table.unpack

local function safe_call(obj, method, ...)
	if obj == nil then
		return nil
	end
	local fn = obj[method]
	if type(fn) ~= "function" then
		return nil
	end
	local ok, a, b, c, d = pcall(fn, obj, ...)
	if ok then
		return a, b, c, d
	end
	return nil
end

local function call_global_method(obj, method, ...)
	return safe_call(obj, method, ...)
end

local function value(obj, ...)
	if type(obj) ~= "table" and type(obj) ~= "userdata" then
		return nil
	end
	for i = 1, select("#", ...) do
		local key = select(i, ...)
		local ok, result = pcall(function()
			return obj[key]
		end)
		if ok and result ~= nil then
			return result
		end
	end
	return nil
end

local function number(v, fallback)
	local n = tonumber(v)
	if n == nil then
		return fallback or 0
	end
	return n
end

local function constant(name, fallback)
	local v = rawget(_G, name)
	if type(v) == "number" then
		return v
	end
	return fallback
end

local function json_decode(text)
	if type(text) ~= "string" or text == "" then
		return nil
	end

	local pos = 1
	local len = #text

	local function skip_space()
		while pos <= len do
			local c = text:sub(pos, pos)
			if c == " " or c == "\t" or c == "\r" or c == "\n" then
				pos = pos + 1
			else
				break
			end
		end
	end

	local function utf8_codepoint(cp)
		if cp < 0 or cp > 0x10ffff then
			return ""
		end
		if utf8 and type(utf8.char) == "function" then
			local ok, result = pcall(utf8.char, cp)
			if ok then
				return result
			end
		end
		if cp < 0x80 then
			return string.char(cp)
		elseif cp < 0x800 then
			return string.char(0xc0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
		elseif cp < 0x10000 then
			return string.char(0xe0 + math.floor(cp / 0x1000), 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
		end
		return string.char(0xf0 + math.floor(cp / 0x40000), 0x80 + math.floor(cp / 0x1000) % 0x40, 0x80 + math.floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40)
	end

	local parse_value

	local function parse_string()
		if text:sub(pos, pos) ~= '"' then
			return nil
		end
		pos = pos + 1
		local out = {}
		while pos <= len do
			local c = text:sub(pos, pos)
			pos = pos + 1
			if c == '"' then
				return table.concat(out)
			elseif c == "\\" then
				local esc = text:sub(pos, pos)
				pos = pos + 1
				if esc == '"' or esc == "\\" or esc == "/" then
					out[#out + 1] = esc
				elseif esc == "b" then
					out[#out + 1] = "\b"
				elseif esc == "f" then
					out[#out + 1] = "\f"
				elseif esc == "n" then
					out[#out + 1] = "\n"
				elseif esc == "r" then
					out[#out + 1] = "\r"
				elseif esc == "t" then
					out[#out + 1] = "\t"
				elseif esc == "u" then
					local hex = text:sub(pos, pos + 3)
					local cp = tonumber(hex, 16)
					pos = pos + 4
					if cp then
						if cp >= 0xd800 and cp <= 0xdbff and text:sub(pos, pos + 1) == "\\u" then
							local low = tonumber(text:sub(pos + 2, pos + 5), 16)
							if low and low >= 0xdc00 and low <= 0xdfff then
								cp = 0x10000 + (cp - 0xd800) * 0x400 + (low - 0xdc00)
								pos = pos + 6
							end
						end
						out[#out + 1] = utf8_codepoint(cp)
					end
				else
					out[#out + 1] = esc
				end
			else
				out[#out + 1] = c
			end
		end
		return nil
	end

	local function parse_array()
		pos = pos + 1
		local out = {}
		skip_space()
		if text:sub(pos, pos) == "]" then
			pos = pos + 1
			return out
		end
		while pos <= len do
			local item = parse_value()
			if item == nil then
				return nil
			end
			out[#out + 1] = item
			skip_space()
			local c = text:sub(pos, pos)
			if c == "]" then
				pos = pos + 1
				return out
			elseif c == "," then
				pos = pos + 1
				skip_space()
			else
				return nil
			end
		end
		return nil
	end

	local function parse_object()
		pos = pos + 1
		local out = {}
		skip_space()
		if text:sub(pos, pos) == "}" then
			pos = pos + 1
			return out
		end
		while pos <= len do
			skip_space()
			local key = parse_string()
			if key == nil then
				return nil
			end
			skip_space()
			if text:sub(pos, pos) ~= ":" then
				return nil
			end
			pos = pos + 1
			skip_space()
			local item = parse_value()
			if item == nil then
				return nil
			end
			out[key] = item
			skip_space()
			local c = text:sub(pos, pos)
			if c == "}" then
				pos = pos + 1
				return out
			elseif c == "," then
				pos = pos + 1
			else
				return nil
			end
		end
		return nil
	end

	parse_value = function()
		skip_space()
		local c = text:sub(pos, pos)
		if c == '"' then
			return parse_string()
		elseif c == "{" then
			return parse_object()
		elseif c == "[" then
			return parse_array()
		elseif text:sub(pos, pos + 3) == "true" then
			pos = pos + 4
			return true
		elseif text:sub(pos, pos + 4) == "false" then
			pos = pos + 5
			return false
		elseif text:sub(pos, pos + 3) == "null" then
			pos = pos + 4
			return false
		end
		local tail = text:sub(pos)
		local token = tail:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*")
		if token and token ~= "" and tonumber(token) ~= nil then
			pos = pos + #token
			return tonumber(token)
		end
		return nil
	end

	local ok, result = pcall(parse_value)
	if not ok then
		return nil
	end
	return result
end

local function json_encode(root)
	local seen = {}

	local function quote(s)
		local out = { '"' }
		for i = 1, #s do
			local b = s:byte(i)
			if b == 34 then
				out[#out + 1] = '\\"'
			elseif b == 92 then
				out[#out + 1] = "\\\\"
			elseif b == 8 then
				out[#out + 1] = "\\b"
			elseif b == 12 then
				out[#out + 1] = "\\f"
			elseif b == 10 then
				out[#out + 1] = "\\n"
			elseif b == 13 then
				out[#out + 1] = "\\r"
			elseif b == 9 then
				out[#out + 1] = "\\t"
			elseif b < 32 then
				out[#out + 1] = string.format("\\u%04x", b)
			else
				out[#out + 1] = string.char(b)
			end
		end
		out[#out + 1] = '"'
		return table.concat(out)
	end

	local encode_value
	encode_value = function(v)
		local t = type(v)
		if t == "nil" then
			return "null"
		elseif t == "boolean" then
			return v and "true" or "false"
		elseif t == "number" then
			if v ~= v or v == math.huge or v == -math.huge then
				return "0"
			end
			return string.format("%.17g", v)
		elseif t == "string" then
			return quote(v)
		elseif t ~= "table" then
			return "null"
		end

		if seen[v] then
			return "null"
		end
		seen[v] = true

		local count, max_index, is_array = 0, 0, true
		for k in pairs(v) do
			count = count + 1
			if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
				is_array = false
			elseif k > max_index then
				max_index = k
			end
		end
		if count == 0 then
			is_array = false
		elseif max_index ~= count then
			is_array = false
		end

		local out = {}
		if is_array then
			for i = 1, max_index do
				out[#out + 1] = encode_value(v[i])
			end
			seen[v] = nil
			return "[" .. table.concat(out, ",") .. "]"
		end

		for k, item in pairs(v) do
			if type(k) == "string" then
				out[#out + 1] = quote(k) .. ":" .. encode_value(item)
			end
		end
		seen[v] = nil
		return "{" .. table.concat(out, ",") .. "}"
	end

	local ok, result = pcall(encode_value, root)
	if ok then
		return result
	end
	return "{}"
end

local function defaults()
	local now = os.time()
	local day_key = os.date("%Y-%m-%d", now)
	local music_id = 1
	if g_App then
		local selected = safe_call(g_App, "GetSelectMusicID")
		if type(selected) == "number" and selected > 0 then
			music_id = selected
		end
	end
	return {
		account = "",
		accountID = 10001,
		nickname = "Player",
		headIcon = 1,
		exp = 0,
		level = 1,
		stars = 0,
		curSkin = 1,
		curMusic = music_id,
		curSkill = 0,
		renameNum = 0,
		resources = {
			gold = 5000,
			diamond = 100,
			rainbowGold = 20,
			presentDiamond = 0,
			fragment = 0,
		},
		owned = {
			equipment = { 1 },
			music = { music_id },
			skins = { 1 },
			battleFaces = {},
			rhythmNoticeBars = {},
		},
		skillLevels = {},
		passiveSkills = {},
		treasureBoxes = {},
		settings = {},
		scores = {
			endless = 0,
			limit = 0,
			team = 0,
			race = 0,
		},
		-- offline: team mode counts as unlocked (eFE_GetTeamModeOpenPrize = 3) so the skill page opens; the original
		-- unlock needs limit-mode points, and limit mode is not playable yet (Claude, user request 2026-10-19)
		firstEvents = { ["3"] = 1 },
		daily = {
			dayKey = day_key,
			signIn = false,
			signInDays = 0,
			rolls = 0,
			firstLogin = true,
		},
		createTime = now,
	}
end

local function merge_defaults(dst, src)
	if type(dst) ~= "table" or type(src) ~= "table" then
		return
	end
	for k, v in pairs(src) do
		if type(v) == "table" then
			if type(dst[k]) ~= "table" then
				dst[k] = {}
			end
			merge_defaults(dst[k], v)
		elseif dst[k] == nil then
			dst[k] = v
		end
	end
end

local loaded_profile
if Host and type(Host.read_text) == "function" then
	local ok, text = pcall(function()
		return Host:read_text("user://profile.json")
	end)
	if ok and type(text) == "string" then
		loaded_profile = json_decode(text)
	end
end
if type(loaded_profile) ~= "table" then
	loaded_profile = {}
end
merge_defaults(loaded_profile, defaults())
FakeWorld.profile = loaded_profile

local function ensure_profile()
	local p = FakeWorld.profile
	if type(p) ~= "table" then
		p = defaults()
		FakeWorld.profile = p
	end
	merge_defaults(p, defaults())
	for _, key in ipairs({ "resources", "owned", "skillLevels", "passiveSkills", "treasureBoxes", "settings", "scores", "firstEvents", "daily" }) do
		if type(p[key]) ~= "table" then
			p[key] = {}
		end
	end
	if p.firstEvents["3"] == nil and p.firstEvents[3] == nil then p.firstEvents["3"] = 1 end   -- see default profile
	for _, key in ipairs({ "equipment", "music", "skins", "battleFaces", "rhythmNoticeBars" }) do
		if type(p.owned[key]) ~= "table" then
			p.owned[key] = {}
		end
	end
	local today = os.date("%Y-%m-%d", os.time())
	if p.daily.dayKey ~= today then
		p.daily.dayKey = today
		p.daily.signIn = false
		p.daily.rolls = 0
		p.daily.firstLogin = false
	end
	return p
end

function FakeWorld.Save()
	local profile = ensure_profile()
	if Host and type(Host.write_text) == "function" then
		local text = json_encode(profile)
		pcall(function()
			Host:write_text("user://profile.json", text)
		end)
	end
end

local function class_named(name)
	local cls = rawget(_G, name)
	if type(cls) == "table" and type(cls.new) == "function" then
		return cls
	end
	return nil
end

local function respond(conn, class_name, fields)
	local cls = type(class_name) == "string" and class_named(class_name) or class_name
	if cls == nil or type(FakeWorld.reply) ~= "function" then
		return nil
	end
	local ok, result = pcall(FakeWorld.reply, conn, cls, fields or {})
	if ok then
		return result
	end
	return nil
end

local function respond_u32(conn, class_name, fields, values)
	local cls = class_named(class_name)
	if cls == nil then
		return nil
	end
	local ok, msg = pcall(function()
		local answer = cls:new()
		for k, v in pairs(fields or {}) do
			answer[k] = v
		end
		local index = 0
		local buffer = {
			ReadUint32 = function()
				index = index + 1
				return number(values and values[index], 0)
			end,
		}
		answer:OnNetReply(conn, buffer)
		return answer
	end)
	if ok then
		return msg
	end
	return nil
end

local function get_main_db()
	if not g_App then
		return nil
	end
	return value(g_App, "m_CharContext")
end

local function dispatch_event(db, name, params)
	if not db or type(db.CreateEvent) ~= "function" or type(db.DispatchEvent) ~= "function" then
		return
	end
	local ok, event = pcall(db.CreateEvent, db, name, db, params or {})
	if ok and event then
		pcall(db.DispatchEvent, db, event)
	end
end

local function block_name(db, block, fallback)
	if not db or not block then
		return fallback
	end
	local id = value(block, "m_nID")
	if id ~= nil and type(db.m_nameTable) == "table" and db.m_nameTable[id] then
		return db.m_nameTable[id]
	end
	return fallback
end

local function notify_block(db, block, fallback, changed_indices)
	local name = block_name(db, block, fallback)
	if not db or not block or not name then
		return
	end
	local indexes = changed_indices or {}
	dispatch_event(db, name, { block, indexes, indexes })
	for _, info in ipairs(value(block, "m_aryMemberInfo") or {}) do
		local member_name = info[3]
		if type(member_name) == "string" then
			if info[4] then
				for _, idx in ipairs(indexes) do
					dispatch_event(db, name .. "." .. member_name .. "." .. tostring(idx), { block })
				end
			else
				dispatch_event(db, name .. "." .. member_name, { block })
			end
		end
	end
end

local function set_member(db, block_name_value, member, new_value)
	local block = value(db, block_name_value)
	if not block then
		return false
	end
	local setter = block["Set" .. member]
	if type(setter) ~= "function" then
		return false
	end
	local ok = pcall(setter, block, new_value)
	if ok then
		notify_block(db, block, block_name_value, {})
		return true
	end
	return false
end

local function set_data(block, index, new_value)
	if not block or type(block.SetData) ~= "function" then
		return false
	end
	local ok = pcall(block.SetData, block, index, new_value)
	return ok
end

local function get_data_max(block, fallback)
	if block and type(block.GetDataMaxCount) == "function" then
		local ok, n = pcall(block.GetDataMaxCount, block)
		if ok and tonumber(n) then
			return math.max(0, tonumber(n))
		end
	end
	return fallback or 0
end

local function set_data_block(db, block_name_value, index, new_value)
	local block = value(db, block_name_value)
	if set_data(block, index, new_value) then
		notify_block(db, block, block_name_value, { index })
		return true
	end
	return false
end

local function clean_id_list(list)
	local out, seen = {}, {}
	if type(list) == "table" then
		for _, v in ipairs(list) do
			local id = tonumber(v)
			if id and id > 0 and not seen[id] then
				seen[id] = true
				out[#out + 1] = math.floor(id)
			end
		end
	end
	return out
end

local function fill_list_block(db, block_name_value, list, fallback_count)
	local block = value(db, block_name_value)
	if not block or type(block.SetData) ~= "function" then
		return
	end
	local count = get_data_max(block, fallback_count)
	for i = 0, count - 1 do
		set_data(block, i, 0)
	end
	for i, id in ipairs(clean_id_list(list)) do
		local slot = i - 1
		if slot < count then
			set_data(block, slot, id)
		end
	end
end

local resource_defs = {
	{ "Gold", "gold", 0 },
	{ "Diamond", "diamond", 1 },
	{ "RainbowGold", "rainbowGold", 2 },
	{ "PresentDiamond", "presentDiamond", 3 },
	{ "Fragment", "fragment", 4 },
}

local function resource_index_by_name(resource_name)
	local name = tostring(resource_name or "")
	if name:match("^%d+$") then
		return tonumber(name)
	end
	for _, def in ipairs(resource_defs) do
		if def[2] == name then
			local enum = rawget(_G, "eResourceType_" .. def[1])
			return type(enum) == "number" and enum or def[3]
		end
	end
	local maybe = rawget(_G, "eResourceType_" .. name)
	if type(maybe) == "number" then
		return maybe
	end
	return nil
end

local function resource_key(index)
	for _, def in ipairs(resource_defs) do
		local enum = rawget(_G, "eResourceType_" .. def[1])
		if type(index) == "number" and ((type(enum) == "number" and index == enum) or index == def[3]) then
			return def[2]
		end
	end
	return tostring(index)
end

local function set_resource(db, profile, index, amount)
	local idx = tonumber(index)
	local key = resource_key(idx)
	profile.resources[key] = math.max(0, number(amount, 0))
	local block = value(db, "m_Resource")
	if block and idx ~= nil and set_data(block, idx, profile.resources[key]) then
		notify_block(db, block, "m_Resource", { idx })
	end
end

local function get_resource(profile, index)
	local key = resource_key(tonumber(index))
	return number(profile.resources[key], 0)
end

local function get_resource_config_index(name)
	return resource_index_by_name(name)
end

local function fill_resource_block(db, profile)
	local block = value(db, "m_Resource")
	if not block then
		return
	end
	for _, def in ipairs(resource_defs) do
		local enum = rawget(_G, "eResourceType_" .. def[1])
		local idx = type(enum) == "number" and enum or def[3]
		local amount = number(profile.resources[def[2]], 0)
		if set_data(block, idx, amount) then
			notify_block(db, block, "m_Resource", { idx })
		end
	end
end

local function set_treasure_box_block(db, profile)
	local block = value(db, "m_TreasureBoxData")
	if not block or type(block.SetData) ~= "function" then
		return
	end
	local max_count = get_data_max(block, 6)
	for i = 0, max_count - 1 do
		local box = profile.treasureBoxes[i + 1]
		if box then
			local record = {
				m_nTreasureBoxID = number(box.id, 0),
				m_nTreasureBoxGetTime = number(box.getTime, 0),
				m_nGetTime = number(box.getTime, 0),
				m_nPosIndex = number(box.posIndex, i),
				m_nTreasureBoxUnlockTime = number(box.unlockTime, 0),
			}
			set_data(block, i, record)
		else
			set_data(block, i, {})
		end
	end
end

-- Skill development (主界面 技能). States: 0 lock, 1 can-unlock, 2 unlocked (upgrading), 3 max level
-- (ClientConstValueDefine eSDST_*). A locked skill becomes unlockable by nDelockType2: 0 init, 1 ladder star >=
-- nDelockValue2, 2 skill nDelockValue2 already unlocked. Unlock costs nDelockValue1 of currency nDelockType1 (音符);
-- an upgrade at level L costs nCurLV<L> of currency nUpgradeType (乐能量). Offline reconstruction, Claude.
local function skill_rows()
	local t = g_tblTabFile and g_tblTabFile.skill
	local ids = {}
	-- g_tblTabFile views are lazy (no pairs over rows): take the IDs from the table file itself
	local ok, text = pcall(function() return Host:read_text("config/resource/skill.txt") end)
	if ok and type(text) == "string" then
		local first = true
		for line in text:gmatch("[^\r\n]+") do
			if first then first = false else
				local id = tonumber(line:match("^%s*(%d+)"))
				if id and t and t[id] then ids[#ids + 1] = id end
			end
		end
	end
	table.sort(ids)
	return ids, t
end

local function skill_state(profile, id, row, states)
	local key = tostring(id)
	local level = number(profile.skillLevels[key], 0)
	local st = profile.skillStates and profile.skillStates[key]
	if st == nil then st = number(row.nInitState, 0) end
	st = number(st, 0)
	if st >= 2 then
		if level < 1 then level = 1 end
		if level >= number(row.nMaxLevel, 1) then st = 3 end
		return st, level
	end
	local kind, val = number(row.nDelockType2, 0), number(row.nDelockValue2, 0)
	local can = false
	if kind == 0 then
		can = true
	elseif kind == 1 then
		local star = 0
		pcall(function() star = g_App:GetMainPlayerData().m_CharBaseData:GetAllStar() end)
		can = number(star, 0) >= val
	elseif kind == 2 then
		can = (states[val] or 0) >= 2
	end
	return can and 1 or 0, 0
end

local function skill_table(profile)
	local ids, t = skill_rows()
	local states, out = {}, {}
	-- prerequisites first: resolve repeatedly until stable (tables are small)
	for _ = 1, 3 do
		for _, id in ipairs(ids) do
			local st, lv = skill_state(profile, id, t[id], states)
			states[id] = st
			out[id] = { st, lv }
		end
	end
	return ids, out
end

local function set_skill_block(db, profile)
	local block = value(db, "m_DBSkillData")
	if not block or type(block.GetData) ~= "function" then
		return
	end
	local ids, info = skill_table(profile)
	for i, id in ipairs(ids) do
		local rec = block:GetData(i - 1)
		pcall(rec.SetSkillID, rec, id)
		pcall(rec.SetLevel, rec, info[id][2])
		pcall(rec.SetState, rec, info[id][1])
	end
	pcall(block.SetDataCount, block, #ids)
	local idx = {}
	for i = 1, #ids do idx[i] = i - 1 end
	notify_block(db, block, "m_DBSkillData", idx)
end

function FakeWorld.FillPlayerDB(db, profile)
	profile = profile or ensure_profile()
	if not db then
		return
	end

	local base = value(db, "m_CharBaseData")
	local now = os.time()
	if base then
		local setters = {
			{ "Account", profile.account or "player" },
			{ "NickName", profile.nickname or "Player" },
			{ "CreateTime", number(profile.createTime, now) },
			{ "LoginTime", now },
			{ "LogoutTime", 0 },
			{ "CurEquipID", number(profile.curSkin, 1) },
			{ "CurTask", 0 },
			{ "AllGameTime", 0 },
			{ "AllGameScore", number(profile.scores.endless, 0) },
			{ "AllStar", number(profile.stars, 0) },
			{ "RenameNum", number(profile.renameNum, 0) },
			{ "CurHeadIcon", number(profile.headIcon, 1) },
			{ "LadderStarChangeTime", now },
			{ "StreakNum", 0 },
			{ "ProtectScore", 0 },
			{ "InitData", 1 },
			{ "CurRhythmNoticeBarID", 0 },
			{ "SkillID", number(profile.curSkill, 0) },
			{ "RechargeID", 0 },
			{ "BeCommendCount", 0 },
			{ "Exp", number(profile.exp, 0) },
			{ "EndlessGameScore", number(profile.scores.endless, 0) },
			{ "LimitGameScore", number(profile.scores.limit, 0) },
			{ "TeamGameScore", number(profile.scores.team, 0) },
			{ "AccumulateCouldObtainGold", 0 },
			{ "VipGetTime", 0 },
			{ "VipEndTime", 0 },
			{ "VipPrizeGetTime", 0 },
			{ "FirstRaceNum", 0 },
			{ "SecondRaceNum", 0 },
			{ "Sex", 0 },
			{ "Age", 0 },
			{ "Constellation", 0 },
			{ "Area", 0 },
			{ "Signature", "" },
			{ "TodayReportNum", 0 },
			{ "FirstTeamRaceNum", 0 },
			{ "SecondTeamRaceNum", 0 },
		}
		for _, item in ipairs(setters) do
			local fn = base["Set" .. item[1]]
			if type(fn) == "function" then
				pcall(fn, base, item[2])
			end
		end
	end

	fill_list_block(db, "m_HaveEquip", profile.owned.equipment, 256)
	fill_list_block(db, "m_HaveMusic", profile.owned.music, 1024)
	fill_list_block(db, "m_BattleFaceData", profile.owned.battleFaces, 150)
	fill_list_block(db, "m_RhythmNoticeBar", profile.owned.rhythmNoticeBars, 100)

	local season = value(db, "m_SeasonStarNum")
	if season then
		local count = get_data_max(season, 36)
		for i = 0, count - 1 do
			set_data(season, i, i == 0 and number(profile.stars, 0) or 0)
		end
	end

	local first_event = value(db, "m_FirstEvent")
	if first_event then
		local count = get_data_max(first_event, 32)
		for i = 0, count - 1 do
			set_data(first_event, i, number(profile.firstEvents[tostring(i)] or profile.firstEvents[i], 0))
		end
	end

	local race = value(db, "m_RaceScore")
	if race then
		local count = get_data_max(race, 36)
		for i = 0, count - 1 do
			set_data(race, i, 0)
		end
	end

	local world_prize = value(db, "m_WorldPrizeID")
	if world_prize then
		local count = get_data_max(world_prize, 256)
		for i = 0, count - 1 do
			set_data(world_prize, i, 0)
		end
	end

	local passive = value(db, "m_PassiveSkill")
	if passive then
		for skill_id, unlocked in pairs(profile.passiveSkills) do
			if unlocked then
				local id = tonumber(skill_id)
				if id then
					set_data(passive, math.max(0, math.floor(id) - 1), math.floor(id))
				end
			end
		end
	end

	fill_resource_block(db, profile)
	set_treasure_box_block(db, profile)
	set_skill_block(db, profile)
end

local function account_id()
	if g_App then
		local id = safe_call(g_App, "GetAccountID")
		if id ~= nil and tonumber(id) then
			return tonumber(id)
		end
	end
	return number(ensure_profile().accountID, 10001)
end

H.CValidateClient = function(conn, msg)
	local profile = ensure_profile()
	local account = value(msg, "m_szAccountName")
	if account == nil or account == "" then
		account = profile.account
	end
	if account == nil or account == "" then
		account = "player"
	end
	profile.account = tostring(account)
	if not profile.nickname or profile.nickname == "" or profile.nickname == "Player" then
		profile.nickname = tostring(account)
	end
	profile.accountID = number(profile.accountID, 10001)
	local db = get_main_db()
	if db then
		db.InitFromCompress = function() end
		FakeWorld.FillPlayerDB(db, profile)
		local size = safe_call(db, "GetSBlockDataSize")
		g_App.__accountID = profile.accountID
		g_App.m_bNewChar = false
		if type(g_App.ValidateResult) == "function" then
			pcall(g_App.ValidateResult, g_App, nil, 0, size)
		end
	end
	FakeWorld.Save()
end

local function find_config_row(category, id)
	local names = {
		music = { "music", "musicinfo", "musiclist", "musicconfig" },
		skin = { "equip", "skin", "skins" },
		battleFace = { "battleface", "battle_face" },
		rhythm = { "jiezoutishiqi", "rhythmnoticebar", "rhythm_notice_bar" },
		treasure = { "treasureboxbase", "treasurebox", "treasure_box" },
	}
	local root = value(_G, "g_tblTabFile")
	if root then
		for _, name in ipairs(names[category] or {}) do
			local tab = value(root, name)
			if type(tab) == "table" then
				local row = tab[id] or tab[tostring(id)]
				if row then
					return row
				end
			end
		end
	end
	if category == "music" and CMusicConfig and type(CMusicConfig.Inst) == "function" then
		local cfg = safe_call(CMusicConfig, "Inst")
		for _, method in ipairs({ "GetMusicData", "GetConfig", "GetMusicInfo" }) do
			local row = safe_call(cfg, method, id)
			if row then
				return row
			end
		end
	end
	return nil
end

local function config_number(row, methods, fields)
	if row then
		for _, field in ipairs(fields or {}) do
			local n = tonumber(value(row, field))
			if n ~= nil then
				return n
			end
		end
		for _, method in ipairs(methods or {}) do
			local n = tonumber(safe_call(row, method))
			if n ~= nil then
				return n
			end
		end
	end
	return nil
end

local function purchase_cost(category, id)
	local row = find_config_row(category, id)
	local pay_index = config_number(row,
		{ "GetPayIndex", "GetConsumeIndex", "GetResourceType" },
		{ "nPayIndex", "nConsumeIndex", "nResourceType", "payIndex", "consumeIndex" })

	if category == "music" and CMusicConfig and type(CMusicConfig.Inst) == "function" then
		local cfg = safe_call(CMusicConfig, "Inst")
		pay_index = pay_index or tonumber(safe_call(cfg, "GetPayIndex", id))
	end

	local amount = config_number(row,
		{ "GetPayValue", "GetPayCount", "GetConsumeCount", "GetPrice", "GetCost" },
		{ "nPayValue", "nPayCount", "nConsumeValue", "nConsumeCount", "nPrice", "nCost", "nNeedCount", "nBuyPrice" })

	if amount == nil and pay_index ~= nil then
		amount = 1
	end
	return pay_index, math.max(0, number(amount, 0))
end

local function pay_for(profile, db, category, id)
	local index, cost = purchase_cost(category, id)
	if index == nil or cost <= 0 then
		return true
	end
	local balance = get_resource(profile, index)
	if balance < cost then
		return false
	end
	set_resource(db, profile, index, balance - cost)
	return true
end

local function add_owned(profile, db, key, id, block_name_value, max_count)
	profile.owned[key] = clean_id_list(profile.owned[key])
	local list = profile.owned[key]
	for _, existing in ipairs(list) do
		if existing == id then
			return true
		end
	end
	list[#list + 1] = id
	local block = value(db, block_name_value)
	if block then
		local slot = #list - 1
		if slot < get_data_max(block, max_count) then
			set_data(block, slot, id)
			notify_block(db, block, block_name_value, { slot })
		end
	end
	return true
end

local function message_id(msg, ...)
	return number(value(msg, ...), 0)
end

H.CQueryExitGame = function(conn)
	respond(conn, "CAnswerCheckRoomExit", {})
end

H.CDeclaration = function(conn)
	respond(conn, "CAnswerDeclaration", { m_tblDeclaration = {} })
end

H.CRename = function(conn, msg)
	local profile = ensure_profile()
	local nickname = value(msg, "m_szCharName")
	if type(nickname) ~= "string" or nickname == "" then
		nickname = profile.nickname
	end
	profile.nickname = nickname
	profile.renameNum = number(profile.renameNum, 0) + 1
	local db = get_main_db()
	set_member(db, "m_CharBaseData", "NickName", nickname)
	set_member(db, "m_CharBaseData", "RenameNum", profile.renameNum)
	FakeWorld.Save()
	respond(conn, "CAnswerModifyCharName", { m_nResult = 0, m_szCharName = nickname })
end

H.CChangeHeadIcon = function(conn, msg)
	local profile = ensure_profile()
	local index = message_id(msg, "m_nIndex", "nIndex")
	profile.headIcon = index
	set_member(get_main_db(), "m_CharBaseData", "CurHeadIcon", index)
	FakeWorld.Save()
	respond(conn, "CAnswerChangeHeadIcon", { m_nIndex = index, m_nResult = 0 })
end

H.CSetMusic = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "nMusicID", "m_nMusicID")
	if id > 0 then
		profile.curMusic = id
		local gapp = g_App
		if gapp then
			pcall(function() gapp:SetSelectMusicID(id) end)
		end
		FakeWorld.Save()
	end
end

H.CUsingSkin = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "nSkinID", "m_nSkinID")
	if id > 0 then
		profile.curSkin = id
		local db = get_main_db()
		set_member(db, "m_CharBaseData", "CurEquipID", id)
		FakeWorld.Save()
	end
end

H.CBuySkin = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "m_nSkinID", "nSkinID")
	local db = get_main_db()
	local success = id > 0 and pay_for(profile, db, "skin", id)
	if success then
		add_owned(profile, db, "skins", id, "m_HaveEquip", 256)
		add_owned(profile, db, "equipment", id, "m_HaveEquip", 256)
		FakeWorld.Save()
	end
	respond(conn, "CAnswerBuySkin", { m_nSkinID = id, m_nResult = success and 1 or 100 })
end

H.CBuyMusic = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "m_nMusicID", "nMusicID")
	local db = get_main_db()
	local success = id > 0 and pay_for(profile, db, "music", id)
	if success then
		add_owned(profile, db, "music", id, "m_HaveMusic", 1024)
		profile.curMusic = id
		FakeWorld.Save()
	end
	respond(conn, "CAnswerBuyMusic", { m_nMusicID = id, m_nResult = success and 0 or 1 })
end

H.CBuyBattleFace = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "m_nIndex", "nIndex")
	local db = get_main_db()
	local success = id > 0 and pay_for(profile, db, "battleFace", id)
	if success then
		add_owned(profile, db, "battleFaces", id, "m_BattleFaceData", 150)
		FakeWorld.Save()
	end
	respond(conn, "CAnswerBuyBattleFace", { m_nIndex = id, m_nResult = success and 0 or 100, m_nCauseIndex = 0 })
end

H.CBuyRhythmNoticeBar = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "m_nIndex", "nIndex")
	local db = get_main_db()
	local success = id > 0 and pay_for(profile, db, "rhythm", id)
	if success then
		add_owned(profile, db, "rhythmNoticeBars", id, "m_RhythmNoticeBar", 100)
		FakeWorld.Save()
	end
	respond(conn, "CAnswerBuyrhythmNoticeBar", { m_nIndex = id, m_nResult = success and 0 or 100 })
end

H.CUseRhythmNoticeBar = function(conn, msg)
	local profile = ensure_profile()
	local id = message_id(msg, "m_nIndex", "nIndex")
	profile.settings.rhythmNoticeBar = id
	set_member(get_main_db(), "m_CharBaseData", "CurRhythmNoticeBarID", id)
	FakeWorld.Save()
end

H.CUseBattleFace = function(conn, msg)
	local profile = ensure_profile()
	local index = message_id(msg, "m_nIndex", "nIndex")
	local kind = message_id(msg, "m_nType", "nType")
	local used = message_id(msg, "m_bUsed", "bUsed")
	profile.settings.battleFaces = type(profile.settings.battleFaces) == "table" and profile.settings.battleFaces or {}
	profile.settings.battleFaces[tostring(kind)] = used ~= 0 and index or 0
	local db = get_main_db()
	set_data_block(db, "m_BattleFaceData", math.max(0, index), used ~= 0 and index or 0)
	FakeWorld.Save()
end

H.CQueryRainbowGold = function(conn)
	local p = ensure_profile()
	local day = number(p.daily.rainbowGoldDay, 0)
	local history = number(p.resources.rainbowGold, 0)
	respond_u32(conn, "CAnswerRainbowGold", {}, { day, history })
end

H.CQueryPlayerBaseData = function(conn)
	local p = ensure_profile()
	respond(conn, "CAnswerQueryPlayerBaseData", {
		m_tblData = {
			szName = p.nickname,
			nHeadIcon = number(p.headIcon, 1),
			nBeCommendCount = 0,
			nLadderStarCount = number(p.stars, 0),
			nOnLineStatus = 1,
			nSex = 0,
			nAge = 0,
			nConstellation = 0,
			nArea = 0,
			szSignature = "",
		},
	})
end

H.CGetAllRecordNew = function(conn)
	local p = ensure_profile()
	local column_count = math.max(1, number(rawget(_G, "All_GRADE_RECORD_COLUMN"), 8))
	local records = {}
	for i = 1, column_count do
		records[i] = { nAllScore = 0, nAreaScore = 0, nKillScore = 0, nMaxCombo = 0 }
	end
	local function period()
		return {
			EndlessAllScore = number(p.scores.endless, 0),
			EndlessAreaScore = 0,
			EndlessKillCount = 0,
			EndlessMaxCombo = 0,
			LimitAllScore = number(p.scores.limit, 0),
			LimitAreaScore = 0,
			LimitKillCount = 0,
			LimitMaxCombo = 0,
			TeamAllScore = number(p.scores.team, 0),
			TeamAreaScore = 0,
			TeamKillCount = 0,
			TeamMaxCombo = 0,
		}
	end
	records.nEndlessTimeToday = 0
	records.nEndlessTimeWeek = 0
	records.nEndlessTimeHistory = 0
	records.nRaceScoreDay = number(p.scores.race, 0)
	records.nRaceScoreWeek = number(p.scores.race, 0)
	records.TodayData = period()
	records.WeekData = period()
	records.HistoryData = period()
	respond(conn, "CAnswerGetAllRecordNew", { m_tblRecordNew = records })
end

H.CQueryWorldMaxRecord = function(conn)
	local p = ensure_profile()
	respond(conn, "CAnswerWorldMaxRecord", {
		szEndlessName = p.nickname,
		nEndlessDay = number(p.scores.endless, 0),
		szLimitName = p.nickname,
		nLimitDay = number(p.scores.limit, 0),
		szTeamName = p.nickname,
		nTeamDay = number(p.scores.team, 0),
	})
end

H.CQueryWorldRecord = function(conn, msg)
	respond(conn, "CAnswerWorldRecord", {
		nRankType = message_id(msg, "nRankType", "m_nRankType"),
		tblAllRegion = {},
	})
end

H.CQueryFolloweesRank = function(conn)
	respond(conn, "CAnswerFolloweesRank", { tblFollowees = {} })
end

H.CEndlessData = function(conn, msg)
	local profile = ensure_profile()
	local score = number(value(msg, "m_nCurTaskScore"), 0)
	local score_data = value(msg, "m_sScore")
	if score == 0 and score_data then
		score = number(value(score_data, "nAllScore", "m_nAllScore"), 0)
	end
	if score > number(profile.scores.endless, 0) then
		profile.scores.endless = score
		set_member(get_main_db(), "m_CharBaseData", "EndlessGameScore", score)
		FakeWorld.Save()
	end
	respond(conn, "CEndlessDataFinish", { m_nDayLimit = 0, m_nMaxCoin = 0 })
end

H.CLimitTimeRoom = function(conn)
	respond(conn, "CRequestRoomFaild", { m_nFaildType = constant("eRRF_NotFindServer", 1) })
end

H.CCheckEnterRoom = function(conn, msg)
	respond(conn, "CAnswerCheckEnterRoom", {
		m_nRoomType = message_id(msg, "m_nRoomType"),
		m_nResult = 1,
	})
end

H.CQueryActivateCode = function(conn)
	respond(conn, "CAnswerActivateCode", { nError = 1, nItemCount = 0, items = {} })
end

H.CSearchPlayers = function(conn)
	respond(conn, "CAnswerSearchPlayers", { nCount = 0, tbl = {} })
end

H.CQueryPropellPlayer = function(conn)
	respond(conn, "CAnswerPropellPlayer", { m_nCount = 0, m_tblAccount = {} })
end

H.CQueryPictureData = function(conn)
	respond(conn, "CAnswerPictureData", { m_nPictureCount = 0, m_tblPictureStatus = {} })
end

H.CGetFirstChargePrize = function(conn)
	respond(conn, "CAnswerPrize", { m_tblPropList = {} })
end

H.CQueryPrize = function(conn)
	respond(conn, "CAnswerPrize", { m_tblPropList = {} })
end

H.CQueryVipPrize = function(conn)
	respond(conn, "CAnswerVipPrize", { m_tblPropList = {} })
end

H.CGuestUpgrade = function(conn)
	respond(conn, "CAnswerGuestUpgradePrize", { m_nGold = 0, m_nRainbowGold = 0 })
end

H.CSpecialOffer = function(conn)
	respond(conn, "CAnswerDeclaration", { m_tblDeclaration = {} })
end

H.CSendWorldGMCmd = function()
end

H.CVideoGuideLog = function()
end

H.CShareResult = function()
end

H.CSettingLog = function(_, msg)
	local p = ensure_profile()
	local n = message_id(msg, "nSettingNum")
	local name = value(msg, "szSettingName")
	p.settings[tostring(n)] = type(name) == "string" and name or ""
	FakeWorld.Save()
end

H.CAlterFirstEvent = function(_, msg)
	local p = ensure_profile()
	local kind = message_id(msg, "nFirstEventType")
	p.firstEvents[tostring(kind)] = 1
	local db = get_main_db()
	set_data_block(db, "m_FirstEvent", math.max(0, kind), 1)
	FakeWorld.Save()
end

H.CAlterPlayerInfo = function(_, msg)
	local p = ensure_profile()
	local db = get_main_db()
	local fields = {
		{ "Sex", "m_nNewSex" },
		{ "Age", "m_nNewAge" },
		{ "Constellation", "m_nNewConstellation" },
		{ "Area", "m_nNewArea" },
	}
	for _, item in ipairs(fields) do
		local n = value(msg, item[2])
		if n ~= nil then
			p.settings[item[1]] = number(n, 0)
			set_member(db, "m_CharBaseData", item[1], number(n, 0))
		end
	end
	FakeWorld.Save()
end

H.CAlterSignature = function(_, msg)
	local p = ensure_profile()
	local signature = value(msg, "m_szNewSignature")
	if type(signature) ~= "string" then
		signature = ""
	end
	p.settings.signature = signature
	set_member(get_main_db(), "m_CharBaseData", "Signature", signature)
	FakeWorld.Save()
end

H.CAlterUseSkill = function(_, msg)
	local p = ensure_profile()
	local id = message_id(msg, "nSkillID")
	p.curSkill = id
	set_member(get_main_db(), "m_CharBaseData", "SkillID", id)
	FakeWorld.Save()
end

H.CAlterPassiveSkill = function(_, msg)
	local p = ensure_profile()
	local id = message_id(msg, "nSkillID")
	if id > 0 then
		p.passiveSkills[tostring(id)] = true
		set_data_block(get_main_db(), "m_PassiveSkill", math.max(0, id - 1), id)
		FakeWorld.Save()
	end
	respond(_, "CNotifyDelockResult", { m_nType = id > 0 and 3 or 1 })
end

H.CDelockSkill = function(conn, msg)
	local p = ensure_profile()
	p.skillStates = p.skillStates or {}
	local id = message_id(msg, "nSkillID")
	local row = g_tblTabFile and g_tblTabFile.skill and g_tblTabFile.skill[id]
	local _, info = skill_table(p)
	local ok = false
	if row and info[id] and info[id][1] == 1 then
		local cur, cost = number(row.nDelockType1, 1), number(row.nDelockValue1, 0)
		if get_resource(p, cur) >= cost then
			set_resource(get_main_db(), p, cur, get_resource(p, cur) - cost)
			p.skillStates[tostring(id)] = 2
			p.skillLevels[tostring(id)] = 1
			ok = true
		end
	end
	if ok then
		set_skill_block(get_main_db(), p)
		FakeWorld.Save()
	end
	respond(conn, "CNotifyDelockResult", { m_nType = ok and 3 or 1 })
end

H.CUpgradeSkill = function(conn, msg)
	local p = ensure_profile()
	p.skillStates = p.skillStates or {}
	local id = message_id(msg, "nSkillID")
	local row = g_tblTabFile and g_tblTabFile.skill and g_tblTabFile.skill[id]
	local _, info = skill_table(p)
	local ok = false
	if row and info[id] and info[id][1] == 2 then
		local level = info[id][2]
		local cur, cost = number(row.nUpgradeType, 2), number(row["nCurLV" .. level], 0)
		if level < number(row.nMaxLevel, 1) and get_resource(p, cur) >= cost then
			set_resource(get_main_db(), p, cur, get_resource(p, cur) - cost)
			p.skillLevels[tostring(id)] = level + 1
			p.skillStates[tostring(id)] = 2
			ok = true
		end
	end
	if ok then
		set_skill_block(get_main_db(), p)
		FakeWorld.Save()
	end
	respond(conn, "CNotifyUpgradeSkillResult", { m_bSucc = ok })
end

local function send_activity_state(conn, activity_type, profile)
	local now = os.time()
	local stamp = math.floor(now / 86400)
	local is_signin = activity_type == constant("eDAT_SignIn", 1)
	if is_signin then
		respond(conn, "CAnswerSignInActivityState", {
			nCurDayStamp = stamp,
			nSignInValue = number(profile.daily.signInDays, 0),
			nSignInFlag = profile.daily.signIn and 1 or 0,
			bFirstLogin = profile.daily.firstLogin == true,
		})
		profile.daily.firstLogin = false
	else
		local can_roll = number(profile.daily.rolls, 0) < 1
		respond(conn, "CAnswerRollActivityState", {
			nRollIndex = number(profile.daily.rollIndex, 0),
			bCanRoll = can_roll,
			nLeftTimes = can_roll and 1 or 0,
		})
	end
end

H.CQueryActivity = function(conn, msg)
	local p = ensure_profile()
	local activity_type = message_id(msg, "nActivityType")
	local action = message_id(msg, "nHandleType")
	local query_action = constant("eHAST_Query", 0)
	local sign_type = constant("eDAT_SignIn", 1)
	local roll_type = constant("eDAT_Roll", 2)

	if activity_type == 0 then
		send_activity_state(conn, sign_type, p)
		send_activity_state(conn, roll_type, p)
	elseif activity_type == sign_type then
		if action ~= query_action then
			local success = not p.daily.signIn
			if success then
				p.daily.signIn = true
				p.daily.signInDays = number(p.daily.signInDays, 0) + 1
				FakeWorld.Save()
			end
			respond(conn, "CSignInActivityResult", {
				nCurDayStamp = math.floor(os.time() / 86400),
				bSucc = success,
			})
		else
			send_activity_state(conn, sign_type, p)
		end
	elseif activity_type == roll_type then
		if action ~= query_action then
			local can_roll = number(p.daily.rolls, 0) < 1
			local success = can_roll
			if success then
				p.daily.rolls = number(p.daily.rolls, 0) + 1
				p.daily.rollIndex = number(p.daily.rollIndex, 0) + 1
				FakeWorld.Save()
			end
			respond(conn, "CRollActivityResult", {
				bCanRollTime = success,
				bCanRollNum = success,
				nPrizePos = success and 1 or 0,
				nPrizeIndex = number(p.daily.rollIndex, 0),
				nLeftTimes = success and 0 or 0,
			})
		else
			send_activity_state(conn, roll_type, p)
		end
	else
		send_activity_state(conn, sign_type, p)
		send_activity_state(conn, roll_type, p)
	end
	FakeWorld.Save()
end

local function find_box(profile, box_id, get_time, position)
	for i, box in ipairs(profile.treasureBoxes) do
		if number(box.id, 0) == box_id
			and (get_time == nil or number(box.getTime, 0) == get_time)
			and (position == nil or number(box.posIndex, i - 1) == position) then
			return i, box
		end
	end
	return nil, nil
end

local function write_box_rows(db, profile)
	set_treasure_box_block(db, profile)
	local block = value(db, "m_TreasureBoxData")
	if block then
		local all = {}
		for i = 0, get_data_max(block, 6) - 1 do
			all[#all + 1] = i
		end
		notify_block(db, block, "m_TreasureBoxData", all)
	end
end

H.CUnLockTreasureBox = function(conn, msg)
	local p = ensure_profile()
	local id = message_id(msg, "m_nTreasureBoxID")
	local get_time = message_id(msg, "m_nGetTime")
	local pos = message_id(msg, "m_nPosIndex")
	local _, box = find_box(p, id, get_time, pos)
	if box then
		box.unlockTime = os.time()
		write_box_rows(get_main_db(), p)
		FakeWorld.Save()
	end
	respond(conn, "CAnswerUnlockTreasureBox", {
		m_tblData = {
			m_nTreasureBoxID = id,
			m_nTreasureBoxGetTime = get_time,
			m_nPosIndex = pos,
		},
	})
end

H.CAccelerateTreasureBox = function(conn, msg)
	local p = ensure_profile()
	local id = message_id(msg, "m_nTreasureBoxID")
	local get_time = message_id(msg, "m_nGetTime")
	local _, box = find_box(p, id, get_time)
	local result = 1
	if box then
		box.unlockTime = os.time()
		write_box_rows(get_main_db(), p)
		FakeWorld.Save()
		result = 0
	end
	respond(conn, "CAnwerAccelerateTreasureBox", { m_nTreasureBoxID = id, m_nResult = result })
end

H.CCouldOpenTreasureBox = function()
end

H.COpenTreasureBox = function(conn, msg)
	local p = ensure_profile()
	local id = message_id(msg, "m_nTreasureBoxID")
	local get_time = message_id(msg, "m_nGetTime")
	local pos = message_id(msg, "m_nPosIndex")
	local index = find_box(p, id, get_time, pos)
	if index then
		table.remove(p.treasureBoxes, index)
		write_box_rows(get_main_db(), p)
		FakeWorld.Save()
	end
	respond(conn, "CGetFragment", {
		m_nTreasureBoxID = id,
		m_nExpAdd = 0,
		m_nPosIndex = pos,
		m_nDataCount = 0,
		m_tblProp = {},
	})
end

H.CDiacardTreasureBox = function(_, msg)
	local p = ensure_profile()
	local id = message_id(msg, "m_nTreasureBoxID")
	local get_time = message_id(msg, "m_nGetTime")
	local index = find_box(p, id, get_time)
	if index then
		table.remove(p.treasureBoxes, index)
		write_box_rows(get_main_db(), p)
		FakeWorld.Save()
	end
end

H.CFusion = function(conn, msg)
	local id = message_id(msg, "m_nFusionID")
	respond(conn, "CAnswerFusion", { m_nFusionID = id, m_nResult = 2 })
end

H.CQueryWorldRaceInfo = function(conn, msg)
	local kind = message_id(msg, "nType")
	respond(conn, "CNotifyWorldRaceInfo", { m_nRaceType = kind, m_nRaceInfoSize = 0, m_tblRaceInfo = {} })
end

H.CJoinRace = function(conn)
	respond(conn, "CAnswerJoinRace", { m_nType = 1 })
end

H.CObserveGame = function(conn)
	respond(conn, "CAnswerObserveGame", { m_nResult = 10 })
end

H.CInvitePlayer = function(conn, msg)
	respond(conn, "CAnswerInvite", { nAccountID = message_id(msg, "nAccountID"), nResult = 1 })
end

H.CJoinGame = function(conn, msg)
	respond(conn, "CAnswerJoinGame", {
		nAccountID = message_id(msg, "nAccountID"),
		nTeamID = message_id(msg, "nTeamID"),
		nResult = 1,
	})
end

H.CRefuseInvite = function()
end

H.CAddCommend = function()
end

H.CAddCommendDay = function()
end

H.CCancelFRRename = function()
end

H.CSendMsg2CustomerService = function(conn)
	respond(conn, "CAnsertCustomerServiceMsg", { nResult = 1, szMsg = "" })
end

H.CReciveCustomerServiceAnswer = function()
end

H.CAddReport = function()
end

H.CAlterPlayerInfo = H.CAlterPlayerInfo or function()
end

H.CCreateTeam = function()
end

H.CJoinTeam = function()
end

H.CStartMatchTeam = function()
end

H.CStopMatchTeam = function()
end

H.CLeaveTeam = function()
end

H.CQueryChangeMatchPos = function()
end

H.CAnswerChangeMatchPos = function()
end

H.CChangeMatchReady = function()
end

H.CMatchPosHandle = function()
end

H.CAchieveGuide = function()
end

H.CGetAllRecord = H.CGetAllRecordNew

H.CCreateClan = function(conn)
	respond(conn, "CAnswerCreateClan", {
		m_nResult = constant("eCreateClan_Failed_NoSocial", 2),
	})
end

H.CUploadPicture = function(conn)
	respond(conn, "CAnswerUploadJpgImage", { m_nResult = 2 })
end

H.CDeletePicture = function(conn)
	respond(conn, "CAnswerDeletePicture", { m_nResult = 1 })
end

H.CQueryActivityState = H.CQueryActivity

local function social_empty_friends(conn, msg)
	respond(conn, "CNotifyFriendChanged", {
		m_nContext = message_id(msg, "nContext"),
		m_aryCharsInfo = {},
	})
end

H.CQueryCharInfo = social_empty_friends

H.CAddFollowee = function(conn, msg)
	respond(conn, "CAnswerAddFollowee", {
		nAccountID = message_id(msg, "nAccountID"),
		nResult = 5,
		bFriend = false,
	})
end

H.CRemoveFollowee = function(conn, msg)
	respond(conn, "CAnswerRemoveFollowee", {
		nAccountID = message_id(msg, "nAccountID"),
		bSuccess = true,
	})
end

H.CAddBlacklist = function(conn, msg)
	respond(conn, "CAnswerAddBlacklist", {
		nAccountID = message_id(msg, "nAccountID"),
		nResult = 0,
	})
end

H.CRemoveBlacklist = function(conn, msg)
	respond(conn, "CAnswerRemoveBlacklist", {
		nAccountID = message_id(msg, "nAccountID"),
		bSuccess = true,
	})
end

H.CSetRefuseFollowers = function(conn, msg)
	local refuse = value(msg, "bRefuse")
	respond(conn, "CAnswerSetRefuseFollowers", { bRefuse = refuse == true or number(refuse, 0) ~= 0 })
end

H.CClearNewFollowers = function()
end

H.CSendIMNewMessage = function()
end

H.CQueryRelationshipCount = function(conn)
	respond(conn, "CAnswerRelationshipCount", { nAttentionCount = 0, nFansCount = 0 })
end

H.CFuzzySearchClan = function(conn)
	respond(conn, "CAnswerFuzzySearchClan", { m_nCount = 0, m_tblClanInfo = {} })
end

H.CCustomSearchClan = function(conn)
	respond(conn, "CAnswerQueryPropellClan", { m_nCount = 0, m_tblClanInfo = {} })
end

H.CAccurateSearchClan = function(conn)
	respond(conn, "CAnswerClanAndMemberInfo", {
		m_nResult = constant("eAccurateSearchClan_NoClan", 1),
		m_ClanInfo = {},
		m_ClanMemberInfo = {},
		m_MyClanInfo = {},
	})
end

H.CJoinClan = function(conn)
	respond(conn, "CAnswerJoinClan", {
		m_nResult = constant("eJoinClan_Failed_NoClan", 2),
	})
end

H.CExitClan = function(conn)
	respond(conn, "CAnswerExitClan", { m_nResult = constant("eExitClan_Failed_NoInClan", 1) })
end

H.CKickClan = function(conn, msg)
	respond(conn, "CAnswerKickClan", {
		m_nOperateAccountID = account_id(),
		m_nBeKickAccountID = message_id(msg, "m_nBeKickAccountID"),
		m_nResult = constant("eOperate_Failed_NoInfo", 2),
	})
end

H.CQueryPropellClan = function(conn)
	respond(conn, "CAnswerQueryPropellClan", { m_nCount = 0, m_tblClanInfo = {} })
end

H.CQueryApplyList = function(conn)
	respond(conn, "CAnswerClanApplyInfo", {
		m_nResult = constant("eOperate_Ok", 0),
		m_nCount = 0,
		m_tblClanApplyList = {},
	})
	respond(conn, "CAnswerClanApplyListCount", { m_nCount = 0 })
end

H.CClanApplyOperate = function(conn, msg)
	respond(conn, "CAnswerClanOperate", {
		m_nAccountID = account_id(),
		m_nApplyAccountID = message_id(msg, "m_nApplyAccountID"),
		m_nResult = constant("eOperate_Failed_NoInfo", 2),
		m_nOperateType = message_id(msg, "m_nOperateType"),
	})
end

H.CSetClanInfo = function(conn)
	respond(conn, "CAnswerSetClanInfo", {
		m_nResult = constant("eOperate_Failed_NoInfo", 2),
	})
end

H.CSetClanMemberPower = function(conn)
	respond(conn, "CAnswerSetClanMemberPower", {
		m_nResult = constant("eOperate_Failed_NoInfo", 2),
	})
end

H.CQueryFolloweesRank = H.CQueryFolloweesRank
H.CQueryWorldRecord = H.CQueryWorldRecord
H.CQueryWorldMaxRecord = H.CQueryWorldMaxRecord

local logged_unhandled = {}
FakeWorld.Handle = function(conn, msg)
	local name = value(msg, "m_sName")
	if not name then
		local mt = getmetatable(msg)
		name = mt and mt.m_sName or "?"
	end
	name = tostring(name)
	local handler = H[name]
	if type(handler) == "function" then
		local ok, err = pcall(handler, conn, msg)
		if not ok then
			print("[FakeWorld] handler error " .. name .. ": " .. tostring(err))
		end
	elseif not logged_unhandled[name] then
		logged_unhandled[name] = true
		print("[FakeWorld] unhandled client message: " .. name)
	end
end

FakeWorld.Save()
