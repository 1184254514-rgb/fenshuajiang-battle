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
local function set_show(w, v)
 if not w then return end
 v = v and true or false
 if w.__bh_show ~= v then w.__bh_show = v; w:ShowWnd(v) end
end
local function set_text(w, v)
 if not w then return end
 v = tostring(v)
 if w.__bh_text ~= v then w.__bh_text = v; w:SetWndText(v) end
end
local function set_enable(w, v)
 if not w then return end
 v = v and true or false
 if w.__bh_enable ~= v then w.__bh_enable = v; w:EnableWnd(v) end
end
local function set_range(w, v)
 if not w then return end
 if w.__bh_range ~= v then w.__bh_range = v; w:SetRange(v) end
end
local function set_pos(w, v)
 if not w then return end
 if w.__bh_pos ~= v then w.__bh_pos = v; w:SetPos(v) end
end
function H.Sync()
 local sc=g_App and g_App.__scene
 if not timed(sc) then return end
 local gm=g_App:GetGameMain()
 local b=gm and gm.m_pGameButton
 if not b or not b.m_pBtnSkill or not gm.m_pWndGameTime then return end
 local p=sc.m_pDirectorObj
 if gm.__bh_scene ~= sc then
  gm.__bh_scene = sc
  gm.__bh_refs = {
   shengyushijian = gm:GetDlgChild('shengyushijian'),
   clock_title = gm:GetDlgChild('W_youxishijian.biaoti'),
   clock_box = gm:GetDlgChild('W_youxishijian'),
   xinhao = gm:GetDlgChild('W_xinhao'),
   xinhao_lv = gm:GetDlgChild('W_xinhao.lv'),
   xinhao_huang = gm:GetDlgChild('W_xinhao.huang'),
   xinhao_hong = gm:GetDlgChild('W_xinhao.hong'),
   xinhao_shuzi = gm:GetDlgChild('W_xinhao.shuzi'),
   b_jineng = b:GetDlgChild('B_jineng'),
   b_jineng_lv = b:GetDlgChild('B_jineng.dengji'),
   jineng_box = b:GetDlgChild('jineng'),
   rank1_self = gm.m_pWndRank1 and gm.m_pWndRank1:GetDlgChild('xinxi.zhujue'),
   passive_lv = {
    b.m_tblWndPassive[1] and b.m_tblWndPassive[1]:GetDlgChild('dengji'),
    b.m_tblWndPassive[2] and b.m_tblWndPassive[2]:GetDlgChild('dengji'),
    b.m_tblWndPassive[3] and b.m_tblWndPassive[3]:GetDlgChild('dengji'),
   },
  }
  for _, w in pairs(gm.__bh_refs) do
   if type(w) == 'table' and w.__node then w.__bh_show, w.__bh_text, w.__bh_enable, w.__bh_range, w.__bh_pos = nil, nil, nil, nil, nil end
  end
  for _, w in ipairs({gm.m_wndExpProgress, gm.m_pWndGameTime, b.m_pBtnSkill, gm.m_pWndTaskTips, gm.m_pWndTask}) do
   if w then w.__bh_show, w.__bh_text, w.__bh_enable, w.__bh_range, w.__bh_pos, w.__bh_tip_sig = nil, nil, nil, nil, nil, nil end
  end
  gm.__bh_tooltips_active = false
  for i = 1, 3 do
   local s = b.m_tblWndPassive[i]
   if s then s.__bh_show, s.__bh_text, s.__bh_tip_sig = nil, nil, nil end
   local plv = gm.__bh_refs.passive_lv[i]
   if plv then plv.__bh_text = nil end
  end
  local refs = gm.__bh_refs
  set_show(refs.shengyushijian, false)
  set_text(refs.clock_title, g_App:GetString('daojishi'))
  local tip=gm.m_pWndTaskTips
  if tip then
   set_show(tip, false)
   for _,key in ipairs({'m_tipTick','m_ShrinkTick'}) do
    local tick=rawget(tip,key);if tick then tick:Stop() end
   end
  end
  set_show(gm.m_pWndTask, false)
 end
 local refs = gm.__bh_refs
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
  set_show(gm.m_wndExpProgress, not sc.__match_finished)
  set_text(gm.m_wndExpProgress, r.level)
  set_range(gm.m_wndExpProgress, math.max(1,r.curExp))
  set_pos(gm.m_wndExpProgress, r.curExp==0 and 1 or math.min(r.curExp,xp-r.wholeExp))
 end
 local network=SceneLAN and SceneLAN.active or false
 set_show(refs.xinhao, network)
 if network then
  set_show(refs.xinhao_lv, true)
  set_show(refs.xinhao_huang, false)
  set_show(refs.xinhao_hong, false)
  set_text(refs.xinhao_shuzi, '--')
 end
 if gm.m_pBtnClose and not gm.__battle_exit_bound then
  gm.__battle_exit_bound=true
  gm.m_pBtnClose:RemoveActionListener('OnExitScene',gm)
  gm.m_pBtnClose:AddActionListener(H.RequestExit)
 end
 -- Countdown occupies the exact APK W_youxishijian position and text style.
 set_show(refs.clock_box, not sc.__match_finished)
 local seconds=math.ceil(SceneMatch.GetTimeRemain(sc)/1000)
 if gm.__bh_clock_sec ~= seconds then
  gm.__bh_clock_sec = seconds
  set_text(gm.m_pWndGameTime, string.format('%02d:%02d',math.floor(seconds/60),seconds%60))
 end
 local hud_fx = Host and Host.scene_view and Host.scene_view.hud_fx
 if not p or not sc.__started or sc.__match_finished then
  if hud_fx and hud_fx.clear_skill_tooltips and gm.__bh_tooltips_active then
   gm.__bh_tooltips_active = false
   hud_fx:clear_skill_tooltips()
  end
  return
 end
 local deathTip=gm.m_pWndTyro
 if deathTip and deathTip.m_wndContent and not network then
  if not p.__alive then
   local death=p.__last_death or {};local who=death.killer or ''
   local reason=death.reason=='body' and '撞到护盾' or death.reason=='territory' and '领地被全部占完' or death.reason=='capture' and '脚下领地被圈占' or death.reason=='anchor' and '路线连接点被圈占' or death.reason=='trail' and '路线被切断' or '死亡原因待核对'
   set_text(deathTip.m_wndContent, reason..(who~='' and (' · '..who) or '')..'\n'..math.ceil(SceneMatch.RespawnRemaining(sc,p)/1000)..'秒后重生')
   if not gm.__death_notice then deathTip:ShowWnd(true);gm.__death_notice=true end
  elseif gm.__death_notice then deathTip:ShowWnd(false);gm.__death_notice=nil end
 end
 local rows=catalog()
 local id=p.__skillID or SceneSkills.selected
 local button=b.m_pBtnSkill
 if not button.__bh_longpress_bound then
  button.__bh_longpress_bound = true
  b.__bh_on_skill_up = function(self)
   local fx = Host and Host.scene_view and Host.scene_view.hud_fx
   if fx and fx.consume_active_long_press and fx:consume_active_long_press() then return end
   self:OnSkillClick()
  end
  button:RemoveEventListener(WM_LBUTTONDOWN, 'OnSkillClick', b)
  button:AddEventListener(WM_LBUTTONUP, '__bh_on_skill_up', b)
 end
 if button.__hud_skill~=id then
  button.__hud_skill=id;button.m_nSkillID=id
  image(button,rows[id])
  -- Godot picks Controls by sibling order, independently of visual z_index.
  -- Native skill input must precede the full-screen steering sibling.
  b.__node:move_child(refs.b_jineng.__node,b.__node:get_child_count()-1)
  if refs.jineng_box and refs.jineng_box.__node then
   b.__node:move_child(refs.jineng_box.__node,b.__node:get_child_count()-1)
  end
 end
 set_show(refs.b_jineng, true)
 set_show(button, true)
 local cooldown=p:GetSkillWaitTime(id)
 local now_ms = sc.__time or 0
 local is_cd = cooldown > 0
 if is_cd then
  local recorded = tonumber(p.__skill_cd_total) or 0
  if recorded <= 0 or cooldown > recorded then
   button.__bh_cd_total = math.max(button.__bh_cd_total or 0, cooldown)
  else
   button.__bh_cd_total = recorded
  end
 else
  button.__bh_cd_total = 0
 end
 local cd_total = math.max(1, button.__bh_cd_total or 1)
 local cd_ratio = is_cd and math.min(1, cooldown / cd_total) or 0
 local cd_sec = is_cd and math.ceil(cooldown / 1000) or 0
 set_enable(button, p.__alive and cooldown<=0)
 -- Let SkillFuseOverlay draw the 1:1 cooldown-synchronized burning fuse + countdown cleanly;
 -- keep native button text empty so digits never double-draw.
 if hud_fx and button.__node then
  set_text(button, '')
  hud_fx:set_skill_fuse(button.__node, cd_ratio, cd_ratio, is_cd, is_cd, cd_sec, tonumber(p.__skill_cast_serial) or 0)
  if button.__bh_was_cd and not is_cd and p.__alive then
   button:AddEffect('fx/cfg/cf_cd.eft', 'fx/loop', 'cf_cd', 0)
  end
  button.__bh_was_cd = is_cd
 else
  set_text(button, is_cd and tostring(cd_sec) or '')
 end
 local active_lv = p.__skill_level or 1
 set_text(refs.b_jineng_lv, active_lv>=6 and g_App:GetString('levelmax') or active_lv)
 set_show(refs.jineng_box, true)
 if hud_fx and hud_fx.set_skill_tooltip_slot and button.__node and SceneSkills and SceneSkills.GetSkillTooltip then
  local tip_sig = tostring(id) .. ':' .. tostring(active_lv)
  if button.__bh_tip_sig ~= tip_sig or not gm.__bh_tooltips_active then
   button.__bh_tip_sig = tip_sig
   gm.__bh_tooltips_active = true
   local info = SceneSkills.GetSkillTooltip(id, active_lv)
   if info then
    hud_fx:set_skill_tooltip_slot('active', button.__node, info.title, info.tag, info.effect, info.desc)
   end
  end
 end
 -- Hide duplicate bottom self-rank row when director is already shown in the top-5 list (checked every 250ms).
 if refs.rank1_self and SceneMatch and SceneMatch.GetPlayerRank then
  if not gm.__bh_rank_at or now_ms - gm.__bh_rank_at >= 250 then
   gm.__bh_rank_at = now_ms
   local my_rank = SceneMatch.GetPlayerRank(sc, p.__objectID)
   set_show(refs.rank1_self, my_rank == 0 or my_rank > 5)
  end
 end
 -- Keep off-screen 1st/2nd/3rd track arrows from overlapping the bottom-right skill button.
 local tips = gm.m_aryTrackTip
 if tips and refs.b_jineng and refs.b_jineng.__node then
  local sk = refs.b_jineng.__node
  local sk_x0 = sk.global_position.x - 16
  local sk_y0 = sk.global_position.y - 16
  for ti = 1, 3 do
   local tip = tips[ti]
   if tip and tip.__node and tip.__node.visible then
    local tn = tip.__node
    local gp = tn.global_position
    local tw = tn.size.x > 0 and tn.size.x or 64
    local th = tn.size.y > 0 and tn.size.y or 64
    if gp.x + tw > sk_x0 and gp.y + th > sk_y0 then
     local push_left = (gp.x + tw) - sk_x0
     local push_up = (gp.y + th) - sk_y0
     if push_up <= push_left then
      tn:set_pos(tn.position.x, tn.position.y - push_up - 8)
     else
      tn:set_pos(tn.position.x - push_left - 8, tn.position.y)
     end
    end
   end
  end
 end
 for i=1,3 do
  local slot=b.m_tblWndPassive[i]
  local pid=(p.__skill_passives or {})[i] or 0
  if slot then
   set_show(slot, pid~=0)
   if pid~=0 then
    if slot.__hud_skill~=pid then slot.__hud_skill=pid;image(slot,rows[pid]) end
    local lv=(p.__skill_passive_levels or {})[i] or 1
    set_text(refs.passive_lv[i], lv>=6 and g_App:GetString('levelmax') or lv)
    if hud_fx and hud_fx.set_skill_tooltip_slot and slot.__node and SceneSkills and SceneSkills.GetSkillTooltip then
     local psig = tostring(pid) .. ':' .. tostring(lv)
     if slot.__bh_tip_sig ~= psig then
      slot.__bh_tip_sig = psig
      local info = SceneSkills.GetSkillTooltip(pid, lv)
      if info then
       hud_fx:set_skill_tooltip_slot('passive_' .. tostring(i), slot.__node, info.title, info.tag, info.effect, info.desc)
      end
     end
    end
   elseif slot.__bh_tip_sig ~= '' then
    slot.__bh_tip_sig = ''
    if hud_fx and hud_fx.set_skill_tooltip_slot then
     hud_fx:set_skill_tooltip_slot('passive_' .. tostring(i), nil, '', '', '', '')
    end
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
