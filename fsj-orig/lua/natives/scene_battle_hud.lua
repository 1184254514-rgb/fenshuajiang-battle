-- APK battle GUI adapter. Rules and LAN authority stay in their existing modules.
-- Original ShellClientLua/ShellCommonLua and GUI resources are not edited.
local H={}
local pack_values,unpack_values=table.pack,table.unpack
SceneBattleHUD=H
local function timed(sc) return SceneMatch and SceneMatch.IsTimed(sc) end
local function image(w,icon)
 if not w or not icon then return end
 w:RestoreImageFromCreateParam()
 local src=CFRect:new();src:left(icon.left);src:top(icon.top);src:right(icon.right);src:bottom(icon.bottom)
 local dst=CFRect:new();dst:left(0);dst:top(0);dst:right(w:GetWndWidth());dst:bottom(w:GetWndHeight())
 for state=eST_ENABLE,eST_CLICKDOWN do
  w:AddImage(GSM_BS_BK,state,w:GetImageCount(GSM_BS_BK,state),icon.icon,src,dst,0xffffffff,LOCK_ALL,BitOr(IDF_ENABLE_ALPHA_BLEND,IDF_ZOOM_WHILE_SCALE),-1,-1,0,1,0)
 end
end
local icons
local function catalog()
 if icons then return icons end
 icons={}
 local data=SceneSkills.GetHUD()
 for _,list in ipairs({data.active,data.passive}) do
  for _,row in ipairs(list) do icons[row.id]=row end
 end
 return icons
end
function H.RequestExit()
 if not timed(g_App and g_App.__scene) then return end
 g_App:MessageBox(g_App:GetString('tuichuchangjing'),{
  [CMessageBox.Close]=function() g_App.m_pMessageBox:ShowWnd(false) end,
  [CMessageBox.OK]=function()
   g_App.m_pMessageBox:ShowWnd(false)
   SceneMatch.ReturnHome()
  end
 })
end
function H.Sync()
 local sc=g_App and g_App.__scene
 if not timed(sc) then return end
 local gm=g_App:GetGameMain()
 local b=gm and gm.m_pGameButton
 if not b or not b.m_pBtnSkill or not gm.m_pWndGameTime then return end
 local p=sc.m_pDirectorObj
 if p and SceneProgression then
  local xp=p.__progress_exp or 0;local r=SceneProgression.Row(xp)
  local serial=p.__progress_serial or 0
  if gm.__xp_actor~=p or (sc.__match_finished and gm.__xp_effect_until) then
   gm.__xp_actor=p;gm.__xp_serial=serial;gm.__xp_effect_until=nil
   gm.m_wndLevelUp:RemoveAllEffects();gm.m_wndLevelUp:ShowWnd(false)
  end
  if serial>(gm.__xp_serial or 0) then
   gm.__xp_serial=serial
   gm.__xp_effect_until=(sc.__time or 0)+1000
   gm.m_wndLevelUp:RemoveAllEffects()
   gm.m_wndLevelUp:ShowWnd(true)
   gm.m_wndLevelUp:AddEffect('fx/cfg/shengji.eft','fx/loop','locallevelup',1000)
  end
  if gm.__xp_effect_until and (sc.__time or 0)>=gm.__xp_effect_until then
   gm.m_wndLevelUp:ShowWnd(false);gm.__xp_effect_until=nil
  end
  gm.m_wndExpProgress:ShowWnd(not sc.__match_finished)
  gm.m_wndExpProgress:SetWndText(tostring(r.level))
  gm.m_wndExpProgress:SetRange(math.max(1,r.curExp))
  gm.m_wndExpProgress:SetPos(r.curExp==0 and 1 or math.min(r.curExp,xp-r.wholeExp))
 end
 -- APK CGameMain::Start 0x38ba34 hides +0x54 (shengyushijian) and
 -- uses CStringConfig['daojishi'] for the timed clock title.
 gm:GetDlgChild('shengyushijian'):ShowWnd(false)
 gm:GetDlgChild('W_youxishijian.biaoti'):SetWndText(g_App:GetString('daojishi'))
 local network=SceneLAN and SceneLAN.active or false
 gm:GetDlgChild('W_xinhao'):ShowWnd(network)
 if network then
  gm:GetDlgChild('W_xinhao.lv'):ShowWnd(true)
  gm:GetDlgChild('W_xinhao.huang'):ShowWnd(false)
  gm:GetDlgChild('W_xinhao.hong'):ShowWnd(false)
  gm:GetDlgChild('W_xinhao.shuzi'):SetWndText('--')
 end
 if gm.m_pBtnClose and not gm.__battle_exit_bound then
  gm.__battle_exit_bound=true
  gm.m_pBtnClose:RemoveActionListener('OnExitScene',gm)
  gm.m_pBtnClose:AddActionListener(H.RequestExit)
 end
 local tip=gm.m_pWndTaskTips
 if tip then
  tip:ShowWnd(false)
  for _,key in ipairs({'m_tipTick','m_ShrinkTick'}) do
   local tick=rawget(tip,key);if tick then tick:Stop() end
  end
 end
 if gm.m_pWndTask then gm.m_pWndTask:ShowWnd(false) end
 -- Countdown occupies the exact APK W_youxishijian position and text style.
 gm:GetDlgChild('W_youxishijian'):ShowWnd(not sc.__match_finished)
 local seconds=math.ceil(SceneMatch.GetTimeRemain(sc)/1000)
 gm.m_pWndGameTime:SetWndText(string.format('%02d:%02d',math.floor(seconds/60),seconds%60))
 if not p or not sc.__started or sc.__match_finished then return end
 local deathTip=gm.m_pWndTyro
 if deathTip and deathTip.m_wndContent and not network then
  if not p.__alive then
   local death=p.__last_death or {};local who=death.killer or ''
   local reason=death.reason=='body' and '撞到护盾' or death.reason=='territory' and '领地被全部占完' or death.reason=='capture' and '脚下领地被圈占' or death.reason=='anchor' and '路线连接点被圈占' or death.reason=='trail' and '路线被切断' or '死亡原因待核对'
   deathTip.m_wndContent:SetWndText(reason..(who~='' and (' · '..who) or '')..'\n'..math.ceil(SceneMatch.RespawnRemaining(sc,p)/1000)..'秒后重生')
   deathTip:ShowWnd(true);gm.__death_notice=true
  elseif gm.__death_notice then deathTip:ShowWnd(false);gm.__death_notice=nil end
 end
 local rows=catalog()
 local id=p.__skillID or SceneSkills.selected
 local button=b.m_pBtnSkill
 if button.__hud_skill~=id then
  button.__hud_skill=id;button.m_nSkillID=id
  image(button,rows[id])
  -- Godot picks Controls by sibling order, independently of visual z_index.
  -- Native skill input must precede the full-screen steering sibling.
  b.__node:move_child(b:GetDlgChild('B_jineng').__node,b.__node:get_child_count()-1)
 end
 b:GetDlgChild('B_jineng'):ShowWnd(true)
 button:ShowWnd(true)
 local cooldown=p:GetSkillWaitTime(id)
 button:EnableWnd(p.__alive and cooldown<=0)
 button:SetWndText(cooldown>0 and tostring(math.ceil(cooldown/1000)) or '')
 b:GetDlgChild('B_jineng.dengji'):SetWndText((p.__skill_level or 1)>=6 and g_App:GetString('levelmax') or (p.__skill_level or 1))
 b:GetDlgChild('jineng'):ShowWnd(true)
 for i=1,3 do
  local slot=b.m_tblWndPassive[i]
  local pid=(p.__skill_passives or {})[i] or 0
  if slot then
   slot:ShowWnd(pid~=0)
   if pid~=0 then
    if slot.__hud_skill~=pid then slot.__hud_skill=pid;image(slot,rows[pid]) end
    local lv=(p.__skill_passive_levels or {})[i] or 1
    slot:GetDlgChild('dengji'):SetWndText(lv>=6 and g_App:GetString('levelmax') or lv)
   end
  end
 end
end
function H.InstallHooks()
 if H.installed or not CGameMainLua or type(rawget(CGameMainLua,"InitTask"))~="function" then return end
 H.installed=true
 local task=CGameMainLua.InitTask
 function CGameMainLua:InitTask(...)
  if timed(g_App and g_App.__scene) then
   -- Local timed play has no daily-task service. Original task ID 0 is an
   -- absent record, not an instruction to show its animated empty background.
   self.m_pWndTaskTips:ShowWnd(false)
   self.m_pWndTask:ShowWnd(false)
   return
  end
  return task(self,...)
 end
 local update=CGameMainLua.OnUpdateWnd
 function CGameMainLua:OnUpdateWnd(...)
  local result=update(self,...)
  H.Sync()
  return result
 end
end
local previous=NativeTickUpdate
function NativeTickUpdate(...)
 local result=pack_values(previous(...))
 H.Sync()
 return unpack_values(result,1,result.n)
end
return H
