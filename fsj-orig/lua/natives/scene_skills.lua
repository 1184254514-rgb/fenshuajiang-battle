-- Local skill adapter using the original resource/skill and skill/skilllevel tables.
-- Proven natives: CMagicPropertyPool ctor 0x33d6e8 maps magic4/5/6 to
-- SPT32[19/20/21], magic7/8/14/20 to [9/10/12/14]. Property modifiers
-- add on entry and subtract on removal (0x33d01c/0x33d032).
-- CMPSpeedModifyer::OnAdd 0x33d084: signed HighSpeed * Param1 / 10000,
-- timed by nMagicTime; CPlayer::AddExtraSpeed 0x34143e replaces the previous slot.
-- CMPConcrete 0x33cf60 -> CManorLine::Concrete 0x33e778: claims existing line,
-- not its enclosed flood-fill region. CMPMusicID 0x33d2ac checks music kinds;
-- conditional score-property map at 0x512260 is {19,20,21,8}.
-- CMPCameraAdjust 0x33cf80: linear ramp Param2, hold Param3, symmetric ramp out.
-- PARITY LIMITS: the offline adapters for movement, AI activation cadence, head
-- contact geometry, effect display and passive loadout selection are not the
-- original server. Hidden/unpublished skills 8..11 are deliberately not offered.
-- The old native cooldown's unsigned negative-stat edge cases are not emulated.
if SceneSkills then return SceneSkills end
local S = { selected = 3, level = 1, passives = {101, 104, 105}, passive_levels = {1,1,1} }
SceneSkills = S
local pack_values,unpack_values=table.pack,table.unpack
local NODE = 16
local rows, resources, music, icons, dictionary
local active_ids, passive_ids = {}, {}
local properties = { [2]=8, [4]=19, [5]=20, [6]=21, [7]=9, [8]=10, [13]=11, [14]=12, [20]=14 }
local score_properties = {[19]=true, [20]=true, [21]=true}
local condition_properties = {[0]=19, [1]=20, [2]=21, [3]=8}
local function trunc(x) return x < 0 and math.ceil(x) or math.floor(x) end
local function signed(x) x = (tonumber(x) or 0) & 0xffffffff; return x >= 0x80000000 and x - 0x100000000 or x end
local function time(p) return p.__scene and p.__scene.__time or 0 end
local function table_rows(path)
	local text = Host:read_text(path) or ""
	text = text:gsub("^\239\187\191", ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	local header, result = nil, {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		if line ~= "" then
			local cells = {}
			for cell in (line .. "\t"):gmatch("(.-)\t") do cells[#cells+1] = cell end
			if not header then header = cells else
				local row = {}
				for i,key in ipairs(header) do row[key] = cells[i] or "" end
				result[#result+1] = row
			end
		end
	end
	return result
end
local function load_data()
	if rows then return end
	rows, resources, music, icons, dictionary = {}, {}, {}, {}, {}
	for _,r in ipairs(table_rows("config/skill/skilllevel.txt")) do
		local id,lv = tonumber(r.nID),tonumber(r.nLevel)
		if id and lv then rows[id] = rows[id] or {}; rows[id][lv] = r end
	end
	for _,r in ipairs(table_rows("config/resource/skill.txt")) do
		local id = tonumber(r.nID)
		if id then
			resources[id] = r
			if tonumber(r.nShow) == 1 and rows[id] then
				if tonumber(r.nSkillType) == 1 and id <= 7 then active_ids[#active_ids+1] = id
				elseif tonumber(r.nSkillType) == 2 then passive_ids[#passive_ids+1] = id end
			end
		end
	end
	for _,r in ipairs(table_rows("config/music.txt")) do music[tonumber(r.nID)] = r end
	for _,r in ipairs(table_rows("config/iconconfig.txt")) do icons[tonumber(r.nID)] = r end
	local dtext = (Host:read_text("config/dictionary/0.txt") or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	for line in (dtext .. "\n"):gmatch("(.-)\n") do
		local k,v = line:match("^([^\t]+)\t(.*)$"); if k then dictionary[k] = v end
	end
	table.sort(active_ids); table.sort(passive_ids)
end
local function config(id,lv)
	load_data(); return rows[id] and rows[id][math.max(1,math.min(6,tonumber(lv) or 1))]
end
local function skill_name(id)
	load_data(); local r = resources[id]; return r and (dictionary[r.dName] or r.dName) or "无"
end
local function supported(id,kind)
	load_data(); for _,n in ipairs(kind == "active" and active_ids or passive_ids) do if n == id then return true end end
	return false
end
local function local_scene(sc)
	return sc and sc.__W and sc.__owner and not sc.__match_finished
end
local function is_director(p) return p.__scene and p.__scene.m_pDirectorObj == p end
local function invalidate_motion(p)
	p.__a_request_speed, p.__a_request_base = nil,nil
end
local function magic_list(row)
	local result = {}
	for i = 1,6 do
		local prefix = "nMagic" .. i
		local id = tonumber(row[prefix .. "ID"]) or 0
		if id ~= 0 then
			local params = {}; for j = 1,4 do params[j] = tonumber(row[prefix .. "Param" .. j]) or 0 end
			result[#result+1] = { id=id, duration=tonumber(row[prefix .. "Time"]) or 0, params=params }
		end
	end
	return result
end
local function music_kind(p,kind)
	local row = music[tonumber(p.__musicID) or 0]
	if not row then return false end
	for value in tostring(row.kind or ""):gmatch("%-?%d+") do if tonumber(value) == kind then return true end end
	return false
end
local function property_base(p,id)
	local f = S.__get_property
	local ok,value = pcall(f,p,id)
	return ok and tonumber(value) or 0
end
local function apply_magic_modifier(p,magic,mods)
	local id,params = magic.id,magic.params
	local prop = properties[id]
	if prop then mods[prop] = (mods[prop] or 0) + params[1]
	elseif id == 15 and music_kind(p,params[1]) then
		prop = condition_properties[params[2]]; if prop then mods[prop] = (mods[prop] or 0) + params[3] end
	elseif id == 16 or id == 17 or id == 18 then
		local source = id == 16 and 1 or id == 17 and 3 or 2
		-- Native pool establishes death source property2 even though client enum labels property4.
		local value = source == 2 and (p.__deaths or 0) or property_base(p,source)
		if signed(value) >= params[1] then
			prop = condition_properties[params[2]]; if prop then mods[prop] = (mods[prop] or 0) + params[3] end
		end
	end
end
function S.RefreshModifiers(p)
	local mods = {}
	for i,id in ipairs(p.__skill_passives or {}) do
		local row = config(id,p.__skill_passive_levels and p.__skill_passive_levels[i] or 1)
		if row then for _,magic in ipairs(magic_list(row)) do apply_magic_modifier(p,magic,mods) end end
	end
	for _,magic in ipairs(p.__skill_effects or {}) do
		if magic.expires > time(p) then apply_magic_modifier(p,magic,mods) end
	end
	local previous = p.__skill_mods or {}
	for id in pairs(score_properties) do
		local old,new = previous[id] or 0,mods[id] or 0
		if old ~= new and SceneScore and SceneScore.Enabled(p.__scene) then
			SceneScore.SetProperty(p,id,SceneScore.GetProperty(p,id)-old+new,false)
		end
	end
	p.__skill_mods = mods
	-- Unchanged passive modifiers must not restart MoveOn every 100 ms:
	-- snapping repeatedly traps low-speed/fault movement in one cell.
	if (previous[8] or 0) ~= (mods[8] or 0) then invalidate_motion(p) end
end
function S.InitPlayer(p)
	load_data()
	if p.__skill_initialized then return end
	p.__skill_initialized = true
	p.__skill_effects, p.__skill_cooldowns, p.__skill_mods = {},{},{}
	p.__skill_level = 1
	local configured=tonumber(p.__configuredSkillID) or tonumber(p.__skillID) or 0
	if p.__ai and not supported(configured,"active") then
		p.__skillID=active_ids[((p.__objectID or 1)-1)%#active_ids+1]
	else p.__skillID=supported(configured,"active") and configured or S.selected end
	p.__skill_passives = {}
	p.__skill_passive_levels = {}
	if not p.__ai then
		for i,id in ipairs(S.passives) do p.__skill_passives[i]=id; p.__skill_passive_levels[i]=S.passive_levels[i] or 1 end
	end
	p.__skill_extra_speed, p.__skill_extra_until = 0,0
	p.m_nActiveSkillLevel = 1
	S.RefreshModifiers(p)
end
function S.ResetPlayer(p)
	if p.__skill_initialized then
		p.__skill_passives, p.__skill_effects = {},{}
		S.RefreshModifiers(p)
	end
	p.__skill_initialized = nil
	S.InitPlayer(p)
	if is_director(p) then p.__skillID=S.selected; p.__skill_level=S.level end
end
function S.ConcreteLine(p)
	local sc = p.__scene
	if not sc or not p.__manor then return 0 end
	local seen,count = {},0
	for _,idx in ipairs(p.__trail or {}) do
		if not seen[idx] and sc.__trail[idx] == p.__objectID then
			seen[idx] = true
			-- CManorLine::Concrete 0x33e778 calls AddManorUnit for each
			-- line cell, including its occupied-home-cell death condition.
			if SceneSim.claim_cell(sc,p,idx,0,"concrete") then
				p.__manor.count=p.__manor.count+1
			end
			SceneSim.set_val(sc,idx,0)
			SceneSim.set_cell(sc,idx,p.__manor.manorID,0)
			count=count+1
		end
	end
	p.__trail, p.__trailUnder, p.__segStart = {},{},1
	p.__trailRevision=(p.__trailRevision or 0)+1
	p.__maxCount=math.max(p.__maxCount or 0,p.__manor.count)
	invalidate_motion(p)
	SceneSim.sync_player(p)
	return count
end
function S.Use(p,id,level)
	if not p or not p.__alive or not local_scene(p.__scene) or not p.__scene.__started then return false,"当前无法释放技能" end
	S.InitPlayer(p)
	id=tonumber(id) or p.__skillID or S.selected
	if not supported(id,"active") then return false,"请选择已实现的主动技能" end
	level=tonumber(level); if not level or level==0 then level=p.__skill_level or 1 end
	local row=config(id,level)
	local now=time(p)
	if (p.__skill_cooldowns[id] or 0)>now then return false,"技能冷却中" end
	local cooldown=tonumber(row.nCD) or 0
	local cdModifier=signed(p:GetSimple32Property(14))
	local factor=p.__scene.__planner_cfg and p.__scene.__planner_cfg.cooldown_percent or 100
	p.__skill_cooldowns[id]=now+math.floor(math.max(0,cooldown+trunc(cooldown*cdModifier/10000))*factor/100)
	p.__skillID,p.__skill_level=id,level
	p.__skill_last_name,p.__skill_last_cast=skill_name(id),now
	-- APK CPlayerClient::OnUseSkill (0x394a50) uses szEffect + "fx/cast",
	-- named "useskill", with the maximum nonzero magic lifetime as its cap.
	-- A persisted serial lets LAN replicas deduplicate casts across snapshots.
	local cast_lifetime=0
	for _,magic in ipairs(magic_list(row)) do cast_lifetime=math.max(cast_lifetime,magic.duration) end
	p.__skill_cast_serial=(p.__skill_cast_serial or 0)+1
	p.__skill_cast_effect=row.szEffect or "0"
	p.__skill_cast_at=now
	p.__skill_cast_lifetime=cast_lifetime
	for _,magic in ipairs(magic_list(row)) do
		magic.started,magic.expires=now,now+magic.duration
		if magic.id==1 then
			local high=SceneSim.const("HighSpeed",180)
			p.__skill_extra_speed=trunc(high*magic.params[1]/10000)
			p.__skill_extra_until=magic.expires
		elseif magic.id==9 then S.ConcreteLine(p)
		else p.__skill_effects[#p.__skill_effects+1]=magic end
	end
	S.RefreshModifiers(p)
	local view=Host and Host.scene_view
	if view then
		local ok,method=pcall(function() return view.set_skill_cast end)
		if ok and (type(method)=="function" or type(method)=="userdata") then
			method(view,p.__objectID,p.__skill_cast_serial,p.__skill_cast_effect,0,cast_lifetime)
		end
	end
	if S.OnUsed then S.OnUsed(p,id,row) end
	return true,skill_name(id)
end
function S.SetSelected(id,level)
	id=tonumber(id); if not supported(id,"active") then return false end
	S.selected,S.level=id,math.max(1,math.min(6,tonumber(level) or 1)); return true
end
function S.SetPassive(slot,id,level)
	slot,id=tonumber(slot),tonumber(id)
	if not slot or slot%1~=0 or slot<1 or slot>3 or (id~=0 and not supported(id,"passive")) then return false end
	for i,value in ipairs(S.passives) do if id~=0 and i~=slot and value==id then return false end end
	S.passives[slot],S.passive_levels[slot]=id,math.max(1,math.min(6,tonumber(level) or 1)); return true
end
function S.BeforeDeath(sc,victim,_killer,_collide,reason)
	if reason=="body" and victim and signed(victim:GetSimple32Property(9))>0 then return false end
	return true
end
function S.OnKilled(_sc,victim,killer)
	if victim and victim.__skill_initialized then
		victim.__skill_effects={}; victim.__skill_extra_speed=0; victim.__skill_extra_until=0
		S.RefreshModifiers(victim)
		local view=Host and Host.scene_view
		if view then
			local ok,method=pcall(function() return view.set_player_skill_state end)
			if ok and (type(method)=="function" or type(method)=="userdata") then method(view,victim.__objectID,false,0,0) end
		end
	end
	if killer and killer.__skill_initialized then S.RefreshModifiers(killer) end
end
local function camera_bonus(p)
	local value=0
	for _,magic in ipairs(p.__skill_effects or {}) do if magic.id==3 and magic.expires>time(p) then
		local elapsed=time(p)-magic.started
		local ramp,hold=magic.params[2],magic.params[3]
		local phase=elapsed
		if phase>ramp+hold then phase=2*ramp+hold-phase end
		value=value+magic.params[1]*math.max(0,math.min(1,phase/math.max(1,ramp)))
	end end
	return value
end
function S.Tick(sc,dt)
	if not sc or not sc.__started then return end
	for _,p in ipairs(sc.__order or {}) do
		S.InitPlayer(p)
		if p.__alive then
			local changed=false
			for i=#p.__skill_effects,1,-1 do if p.__skill_effects[i].expires<=time(p) then table.remove(p.__skill_effects,i);changed=true end end
			if p.__skill_extra_speed~=0 and p.__skill_extra_until<=time(p) then p.__skill_extra_speed=0;changed=true end
			-- Refresh conditional passive bonuses after kills/music changes, not only casts.
			if changed or (p.__skill_refresh_at or 0)<=time(p) then
				S.RefreshModifiers(p);p.__skill_refresh_at=time(p)+100
			end
			if p.__ai and not sc.__planner_pause_ai and not sc.__match_finished and time(p)>2000 and #(p.__trail or {})>=2 then S.Use(p,p.__skillID,p.__skill_level) end
			local view=Host and Host.scene_view
			if view then
				local ok,method=pcall(function() return view.set_player_skill_state end)
				if ok and (type(method)=="function" or type(method)=="userdata") then
					local hidden=false
					for _,magic in ipairs(p.__skill_effects) do if magic.id==12 then hidden=true end end
					method(view,p.__objectID,hidden,signed(p:GetSimple32Property(9)),camera_bonus(p))
				end
			end
		end
	end
end
local function catalog(ids)
	local result={}
	for _,id in ipairs(ids) do
		local r=resources[id];local icon=icons[tonumber(r.nIconID)] or {}
		local row=config(id,1)
		result[#result+1]={id=id,name=skill_name(id),description=dictionary[r.dDescription] or "",icon=icon.sTextureFileName or "",
			left=tonumber(icon.nLeft) or 0,top=tonumber(icon.nTop) or 0,right=tonumber(icon.nRight) or 0,bottom=tonumber(icon.nBottom) or 0,
			cooldown_ms=tonumber(row.nCD) or 0}
	end
	return result
end
function S.OpenMenu()
	S.menu_open=true
end
function S.CloseMenu()
	S.menu_open=false
end
function S.InstallHooks()
	if S.__ui_hooks_installed or not CGameStartLua then return end
	S.__ui_hooks_installed=true
	function CGameStartLua:OnClickSkillDevelop()
		S.OpenMenu()
	end
end
function S.GetHUD()
	load_data()
	local sc=g_App and g_App.__scene
	local p=sc and sc.m_pDirectorObj
	local running=sc and sc.__started and not sc.__match_finished
	local home=false
	if g_App and not sc and g_App.GetGameStart then
		local connection=g_App:GetWorldConn()
		if connection and connection:IsConnected() then
			local w=g_App:GetGameStart();home=w and w.__node and w.__node:is_visible_in_tree() or false
		end
	end
	local id=p and p.__skillID or S.selected
	local cooldown=0;local duration=0
	if p then
		S.InitPlayer(p);cooldown=math.max(0,(p.__skill_cooldowns[id] or 0)-time(p))
		duration=math.max(0,(p.__skill_extra_until or 0)-time(p))
		for _,magic in ipairs(p.__skill_effects) do duration=math.max(duration,magic.expires-time(p)) end
	end
	if not home then S.menu_open=false end
	return {home=home,menu_open=not not S.menu_open,running=not not running,alive=p and not not p.__alive or false,selected=S.selected,selected_level=S.level,
		passives=S.passives,passive_levels=S.passive_levels,name=skill_name(id),skill_id=id,cooldown_ms=cooldown,duration_ms=duration,
		active=catalog(active_ids),passive=catalog(passive_ids)}
end
local function json(value)
	local t=type(value)
	if t=="string" then return '"'..value:gsub('[%z\1-\31\\"]',function(c)
		local map={['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
		return map[c] or string.format('\\u%04x',string.byte(c)) end)..'"'
	elseif t=="number" then return tostring(value)
	elseif t=="boolean" then return value and "true" or "false"
	elseif t~="table" then return "null" end
	local parts={}
	if #value>0 then for _,v in ipairs(value) do parts[#parts+1]=json(v) end;return "["..table.concat(parts,",").."]" end
	for k,v in pairs(value) do parts[#parts+1]=json(tostring(k))..":"..json(v) end
	return "{"..table.concat(parts,",").."}"
end
S.EncodeJSON = json
S.CameraBonus = camera_bonus
function S.GetHUDJSON() return json(S.GetHUD()) end
function NativeKeySkill()
	local sc=g_App and g_App.__scene; local p=sc and sc.m_pDirectorObj
	return S.Use(p)
end
S.__get_property=CPlayerClient.GetSimple32Property
function CPlayerClient:GetSimple32Property(id)
	local base=property_base(self,id)
	if not score_properties[id] then base=base+((self.__skill_mods or {})[id] or 0) end
	return base & 0xffffffff
end
local old_add_speed=CPlayerClient.GetAddSpeed
function CPlayerClient:GetAddSpeed()
	local ok,base=pcall(old_add_speed,self)
	base=ok and tonumber(base) or nil
	local high=SceneSim.const("HighSpeed",180)
	local raw=self:GetSimple32Property(8)
	if base==nil then base=trunc(high*signed(raw)/10000)
	elseif raw>=0x80000000 then
		-- scene_move's older adapter reads the raw u32 property. Correct only
		-- its speed term, retaining any level-based contribution.
		base=base-trunc(high*raw/10000)+trunc(high*signed(raw)/10000)
	end
	return base+((self.__skill_extra_until or 0)>time(self) and (self.__skill_extra_speed or 0) or 0)
end
function CPlayerClient:UseSkill(id,level,_force) return S.Use(self,id,level) end
function CPlayerClient:GetSkillWaitTime(id) return math.max(0,((self.__skill_cooldowns or {})[id or self.__skillID] or 0)-time(self)) end
local old_start=CPlayerClient.StartUp
function CPlayerClient:StartUp(...)
	-- Remove tracked modifiers before the native startup chain, then reapply
	-- after score/items initialization. This avoids stale cached contributions
	-- or multiplying a passive bonus on repeated respawns.
	if self.__skill_initialized then
		self.__skill_passives,self.__skill_effects={},{}
		S.RefreshModifiers(self)
	end
	self.__skill_initialized=nil
	local result=pack_values(old_start(self,...))
	S.InitPlayer(self)
	if is_director(self) then self.__skillID=S.selected;self.__skill_level=S.level end
	return unpack_values(result,1,result.n)
end
return S
