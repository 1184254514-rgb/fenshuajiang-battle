-- Match XP uses APK explevel.txt, not the account playerlevel.txt table.
-- Thresholds/skill mapping are recovered. Timed-room crystal refill/reward
-- timing is a local host adaptation because the original field server is absent.
local pack,unpack_values=table.pack,table.unpack
local P={}
SceneProgression=P
local levels,skills
local function read(path)
 local lines={};local header
 for line in ((Host:read_text(path) or ''):gsub('\r','')..'\n'):gmatch('(.-)\n') do
  if line~='' then
   local cells={};for cell in (line..'\t'):gmatch('(.-)\t') do cells[#cells+1]=cell end
   if not header then header=cells else
    local row={};for i,key in ipairs(header) do row[key]=tonumber(cells[i]) or cells[i] end
    lines[#lines+1]=row
   end
  end
 end
 return lines
end
local function load()
 if levels then return end
 levels=read('config/explevel.txt');skills={}
 for _,r in ipairs(read('config/resource/skill.txt')) do skills[r.nID]=r end
end
local function enabled(p) return p and p.__scene and p.__scene.__timed_match end
local function authority(p) return enabled(p) and not p.__scene.__lan_client end
function P.Row(exp)
 load();local row=levels[1]
 for _,r in ipairs(levels) do if exp>=r.wholeExp then row=r else break end end
 return row
end
function P.SkillLevel(id,level)
 load();local r=skills[id]
 if not r then return 1 end
 -- Local unlocked loadouts have the original maximum cap. No account
 -- training service is fabricated; the round still starts from skill Lv.1.
 return math.max(1,math.min(r.nMaxLevel or 6,r['nExpMatchLevel'..level] or 1))
end
function P.Refresh(p)
 if not enabled(p) then return end
 if authority(p) and not p.__planner_initial_applied then
  p.__planner_initial_applied=true
  if p.__progress_exp==nil then p.__progress_exp=p.__scene.__planner_cfg and p.__scene.__planner_cfg.start_exp or 0 end
 end
 local before=p.__progress_level or 1
 p.__progress_exp=math.max(0,math.floor(p.__progress_exp or 0))
 p.__progress_level=P.Row(p.__progress_exp).level
 p.__c_exp,p.__c_expOverride=p.__progress_exp,false
 local active=P.SkillLevel(p.__skillID,p.__progress_level)
 local changed=p.__skill_level~=active
 p.__skill_level,p.m_nActiveSkillLevel=active,active
 for i,id in ipairs(p.__skill_passives or {}) do
  local lv=P.SkillLevel(id,p.__progress_level)
  if p.__skill_passive_levels[i]~=lv then changed=true end
  p.__skill_passive_levels[i]=lv
 end
 if changed then SceneSkills.RefreshModifiers(p) end
 if before~=p.__progress_level then
  p.__a_request_speed,p.__a_request_base=nil,nil
  if p.__progress_level>before then p.__progress_serial=(p.__progress_serial or 0)+1 end
 end
end
function P.SetExp(p,exp)
 if not authority(p) or p.__scene.__match_finished then return false end
 local old=p.__progress_exp or 0
 p.__progress_exp=math.max(0,math.min(4294967295,math.floor(tonumber(exp) or 0)))
 P.Refresh(p)
 return p.__progress_exp,old
end
function P.Configure(sc)
 sc.__c_localExp=true;sc.__c_expEnabled=true
end
function P.OnRespawn(p)
 if not authority(p) then return end
 local exp=p.__progress_exp or 0
 p.__progress_exp=math.floor(exp*P.Row(exp).rebirthExpRatio/10000)
 P.Refresh(p)
end
function P.Tick(sc)
 if not sc.__timed_match or sc.__lan_client or sc.__match_finished then return end
 P.Configure(sc)
 SceneItemsC.SeedExp(sc)
 for _,p in ipairs(sc.__order or {}) do P.Refresh(p) end
end
-- ARM 0x343e68: last wholeExp <= XP. GetLevelExp returns curExp,
-- GetAddSpeed (0x343eb0) looks up LEVEL, not total experience.
function CPlayerLevelConfig:GetLevel(exp) return P.Row(exp or 0).level end
function CPlayerLevelConfig:GetCurLevelExp(exp) local r=P.Row(exp or 0);return (exp or 0)-r.wholeExp end
function CPlayerLevelConfig:GetLevelExp(exp) return P.Row(exp or 0).curExp end
function CPlayerLevelConfig:GetMaxLevel() load();return levels[#levels].level end
function CPlayerLevelConfig:GetRebirthRatio(exp) return P.Row(exp or 0).rebirthExpRatio end
local function bylevel(lv) load();for _,r in ipairs(levels) do if r.level==lv then return r end end;return {} end
function CPlayerLevelConfig:GetAddSpeed(lv) return bylevel(lv).addSpeed or 0 end
function CPlayerLevelConfig:GetDropItemMin(lv) return bylevel(lv).dropitemmin or 0 end
function CPlayerLevelConfig:GetDropItemMax(lv) return bylevel(lv).dropitemmax or 0 end
local get,set,add=CPlayerClient.GetSimple32Property,CPlayerClient.SetSimple32Property,CPlayerClient.AddSimple32Property
function CPlayerClient:GetSimple32Property(id)
 if enabled(self) then
  if id==eSPT32_Exp then return self.__progress_exp or 0 end
  if id==eSPT32_Level then return self.__progress_level or 1 end
 end
 return get(self,id)
end
function CPlayerClient:SetSimple32Property(id,value)
 if enabled(self) and id==eSPT32_Exp then return P.SetExp(self,value) end
 return set(self,id,value)
end
function CPlayerClient:AddSimple32Property(id,value)
 if enabled(self) and id==eSPT32_Exp then return P.SetExp(self,(self.__progress_exp or 0)+value) end
 return add(self,id,value)
end
local top=CPlayerClient.GetSceneSkillTopLevel
function CPlayerClient:GetSceneSkillTopLevel(id,lv)
 if enabled(self) then return P.SkillLevel(id,lv or self.__progress_level or 1) end
 return top(self,id,lv)
end
local setItemExp=SceneItemsC.SetExp
function SceneItemsC.SetExp(p,value)
 if enabled(p) then return P.SetExp(p,value) end
 return setItemExp(p,value)
end
local grant=SceneItemsC.GrantExp
function SceneItemsC.GrantExp(p,item,reason)
 if not enabled(p) then return grant(p,item,reason) end
 if not authority(p) or not p.__alive or p.__scene.__match_finished then return 0 end
 local amount=p.__scene.__planner_cfg and p.__scene.__planner_cfg.exp_reward or math.max(0,CSnakeConstant:Inst():GetExpManorGainExp())
 P.SetExp(p,(p.__progress_exp or 0)+amount)
 return amount
end
local tick=SceneSkills.Tick
function SceneSkills.Tick(sc,dt) P.Tick(sc);return tick(sc,dt) end
local startup=CPlayerClient.StartUp
function CPlayerClient:StartUp(...)
 local result=pack(startup(self,...))
 P.Refresh(self)
 return unpack_values(result,1,result.n)
end
return P
