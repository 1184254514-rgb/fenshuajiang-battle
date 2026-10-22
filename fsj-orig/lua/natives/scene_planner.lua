-- Local planner settings. Only bounded numeric data crosses the UI bridge;
-- no Lua text from a settings file is evaluated and no LAN command is added.
local D={}
ScenePlanner=D
D.spec={duration_ms={240000,30000,3600000},respawn_ms={3000,1000,30000},
 exp_reward={100,1,10000},exp_count={60,0,300},start_exp={0,0,9000},cooldown_percent={100,0,300}}
D.settings={}
for key,s in pairs(D.spec) do D.settings[key]=s[1] end
function D.CanEdit()
 local ok,client=pcall(function() return Host:planner_is_client() end)
 if ok and client then return false end
 return not (SceneLAN and SceneLAN.active and SceneLAN.client)
end
function D.ApplyJSON(text)
 if not D.CanEdit() then return false,'联机客人只读，请由房主设置' end
 local ok,data=pcall(function() return Host:parse_json(text) end)
 if not ok or not data then return false,'设置文件格式无效' end
 local nextSettings={}
 for key,s in pairs(D.spec) do
  local v=tonumber(data[key])
  if not v or v~=v or math.abs(v)==math.huge then return false,'设置缺少有效参数：'..key end
  nextSettings[key]=math.floor(math.max(s[2],math.min(s[3],v)))
 end
 D.settings=nextSettings
 return true,'设置已应用；下一局生效'
end
function D.ProjectJSON() return SceneSkills.EncodeJSON(D.project_settings) end
function D.ConfigJSON() return SceneSkills.EncodeJSON(D.settings) end
function D.Configure(sc)
 sc.__planner_cfg={}
 for key,value in pairs(D.settings) do sc.__planner_cfg[key]=value end
 sc.__c_expTarget=D.settings.exp_count
 sc.__planner_pause_ai=false
end
function D.StateJSON()
 local sc=g_App and g_App.__scene
 local p=sc and sc.m_pDirectorObj
 local active=sc and sc.__timed_match and not sc.__match_finished
 local settings=sc and sc.__lan_client and sc.__planner_cfg or D.settings
 return SceneSkills.EncodeJSON({editable=D.CanEdit(),active=not not active,
  settings=settings or D.settings,round=sc and sc.__planner_cfg or {},
  xp=p and p.__progress_exp or 0,level=p and p.__progress_level or 1,
  skill=p and p.__skill_level or 1,paused=sc and sc.__planner_pause_ai or false})
end
function D.Action(action)
 if not D.CanEdit() then return false,'联机客人无法执行调试操作' end
 local sc=g_App and g_App.__scene
 if not sc or not sc.__timed_match or sc.__match_finished then return false,'请先开始一局比赛' end
 local p=sc.m_pDirectorObj
 if action=='restart' then
  if SceneLAN and SceneLAN.active then
   if Host:planner_restart() then return true,'房主已重开联机测试局' end
   return false,'当前无法重开联机局'
  end
  SceneMatch.Rematch();return true,'测试局已重开'
 end
 if action=='pause_ai' then sc.__planner_pause_ai=not sc.__planner_pause_ai;return true,'AI暂停状态已切换' end
 if not p or not p.__alive then return false,'角色重生后再执行此操作' end
 if action=='add_xp' then SceneProgression.SetExp(p,(p.__progress_exp or 0)+1000)
 elseif action=='max_xp' then SceneProgression.SetExp(p,math.max(9000,p.__progress_exp or 0))
 elseif action=='clear_cd' then p.__skill_cooldowns={}
 else return false,'未知调试操作' end
 return true,'调试操作已执行'
end
-- A project config is part of editor presets and exported game data.
if Host:file_exists('res://data/planner_settings.json') then
 D.ApplyJSON(Host:read_text('res://data/planner_settings.json'))
end
D.project_settings={}
for key,value in pairs(D.settings) do D.project_settings[key]=value end
return D
