-- LAN replicas never run simulation. Only the hosting process owns world rules.
-- Transport passes JSON as data through a Godot parser, never Lua source.
local L = { active=false, client=false }
SceneLAN = L
local function plain(v)
    if type(v) ~= "userdata" then return v end
    local result={}
    if Variant.is(v,Array) then
        for i=0,#v-1 do result[i+1]=plain(v[i]) end
    elseif Variant.is(v,Dictionary) then
        for k,x in pairs(v) do result[tonumber(k) or k]=plain(x) end
    end
    return result
end
local function decode(text) return plain(Host:parse_json(text)) end
local function encode(value) return SceneSkills.EncodeJSON(value) end
local function scene() return g_App and g_App.__scene end
function L.SetNick(nick)
    g_App:GetMainPlayerData().m_CharBaseData:SetNickName(nick)
end
local function loadout(p, cfg)
    p.__skillID=cfg.skill
    p.__configuredSkillID=cfg.skill
    p.__skill_level=1
    p.__skill_passives=cfg.passives or {}
    p.__skill_passive_levels={1,1,1}
    SceneSkills.RefreshModifiers(p)
end
function L.BeginHost(roster_json)
    L.active,L.client=true,false
    local roster=decode(roster_json)
    L.SetNick(roster[1].nick)
    local sc=SceneMatch.Start(240000)
    sc.__lan_host=true
    sc.m_pWanfa:OnCreateDirector()
    SceneMatch.Tick(sc,0)
    assert(#sc.__order==10,"LAN roster could not allocate ten competitors")
    for i,cfg in ipairs(roster) do
        local p=sc.__order[i]
        p.__net_peer=cfg.peer
        p.__net_loadout=cfg
        p.__ai=nil
        p.__nick=cfg.nick
        loadout(p,cfg)
        SceneSim.sync_player(p)
    end
    return true
end
function L.BeginClient()
    L.active,L.client=true,true
    local sc=SceneMatch.Start(240000)
    sc.__lan_client=true
    Host.scene_view.network_replica=true
    -- No local player creation, AI, physics or item rules on a replica.
    sc.m_pWanfa.m_tickCreateDirector:Stop()
    return true
end
function L.Input(peer, direction, skill, grade)
    local sc=scene()
    if not sc or not sc.__lan_host or sc.__match_finished then return false end
    for _,p in ipairs(sc.__order) do
        if p.__net_peer==peer and p.__alive then
            if skill then return SceneSkills.Use(p) end
            if direction==1 or direction==2 or direction==4 or direction==8 then
                if grade>=0 and grade<=3 then p:NotifyRhythm(grade) end
                return p:SetDirection(direction)
            end
        end
    end
    return false
end
function L.DropPeer(peer)
    local sc=scene()
    if not sc or not sc.__lan_host then return end
    for _,p in ipairs(sc.__order) do if p.__net_peer==peer then
        p.__net_peer=nil; p.__net_loadout=nil
        p.__nick=p.__nick.."（AI接管）"
        p.__ai=SceneAI.Think
        SceneAI.SetPlayerConfig(p,1)
        SceneSim.sync_player(p)
    end end
end
local fields={"__x","__y","__dir","__alive","__nick","__equipID","__kills","__deaths",
    "__progress_exp","__progress_level","__progress_serial","__last_death","__stats","__rhythm","__b_spt","__trail","__trailRevision","__skillID","__skill_level",
    "__skill_effects","__skill_cooldowns","__skill_mods","__skill_extra_speed","__skill_extra_until",
    "__skill_passives","__skill_passive_levels","__killedBy","__net_peer",
    "__skill_cast_serial","__skill_cast_effect","__skill_cast_at","__skill_cast_lifetime"}
function L.Snapshot()
    local sc=scene()
    if not sc or not sc.__lan_host then return "{}" end
    local data={planner_paused=sc.__planner_pause_ai,planner=sc.__planner_cfg,time=sc.__time,limit=sc.__limit,finished=sc.__match_finished,
        w=sc.__W,h=sc.__H,players={},runs={},respawns=sc.__match_respawns,items={},
        results=sc.__match_finished and SceneMatch.Results(sc) or nil}
    for _,p in ipairs(sc.__order) do
        local row={id=p.__objectID,manor=p.__manor.manorID,color=p.__manor.colorID,area=p.__manor.count}
        local actor=Host.scene_view.actors[p.__objectID]
        row.model=actor and actor["model"] or "res://assets/models/p_001.glb"
        for _,key in ipairs(fields) do
            row[key]=p[key]
            if key=="__b_spt" or key=="__skill_mods" or key=="__skill_cooldowns" then
                row[key]={}
                for k,v in pairs(p[key] or {}) do row[key][tostring(k)]=v end
            end
        end
        row.hidden=false
        for _,magic in ipairs(p.__skill_effects or {}) do if magic.id==12 then row.hidden=true end end
        row.armor=p:GetSimple32Property(9)
        row.camera=SceneSkills.CameraBonus(p)
        data.players[#data.players+1]=row
    end
    local run
    for i=0,sc.__W*sc.__H-1 do
        local o,t,v=sc.__owner[i] or 0,sc.__trail[i] or 0,(sc.__val or {})[i] or 0
        if run and run[2]==o and run[3]==t and run[4]==v then run[1]=run[1]+1
        else run={1,o,t,v};data.runs[#data.runs+1]=run end
    end
    for id,item in pairs(sc.__c_items or {}) do
        data.items[#data.items+1]={id=id,kind=item.__c_dropType==0 and "coin" or item.__c_dropType==1 and "exp" or "map",x=item.__c_targetX,y=item.__c_targetY,hint=SceneItemsC.ItemHint(item)}
    end
    return encode(data)
end
function L.Apply(text,peer)
    local data=decode(text)
    local sc=scene()
    if not sc or not sc.__lan_client or data.w~=sc.__W or data.h~=sc.__H then return false end
    sc.__time,sc.__limit=data.time,data.limit
    sc.__planner_cfg=data.planner or sc.__planner_cfg
    sc.__planner_pause_ai=data.planner_paused==true
    sc.__match_respawns=data.respawns or {}
    local director
    local retracted={}
    for _,row in ipairs(data.players) do
        local p=sc.__players[row.id]
        if not p then
            p=sc:AddPlayer(row.id,{nickName=row.__nick,skillID=row.__skillID},CPos16:new(row.__x,row.__y),80)
            assert(p,"Replica allocation failed")
        end
        if p.__alive and row.__alive and row.__trailRevision~=p.__trailRevision then
            local retained={}
            for _,idx in ipairs(row.__trail or {}) do retained[idx]=true end
            for _,idx in ipairs(p.__trail or {}) do if not retained[idx] then retracted[#retracted+1]=idx end end
        end
        for _,key in ipairs(fields) do p[key]=row[key] end
        p.__ai=nil
        p.__skill_initialized=true
        p.__manor.manorID,p.__manor.colorID,p.__manor.count=row.manor,row.color,row.area
        p.__c_inScene=p.__alive
        p.__colour_reserved=true
        Host.scene_view:set_player_model(row.id,row.model)
        sc.__byManor[row.manor]=p
        Host.scene_view:set_manor_colour(row.manor,row.color)
        if row.__net_peer==peer then director=p end
    end
    if director and sc.m_pDirectorObj~=director then g_App:SetDirector(director) end
    local index=0
    for _,run in ipairs(data.runs) do
        for i=index,index+run[1]-1 do
            if sc.__owner[i]~=run[2] or sc.__trail[i]~=run[3] then
                sc.__owner[i],sc.__trail[i]=run[2],run[3]
                Host.scene_view:set_cell(i,run[2],run[3])
            end
            if (sc.__val or {})[i]~=run[4] then SceneSim.set_val(sc,i,run[4]) end
        end
        index=index+run[1]
    end
    for _,idx in ipairs(retracted) do Host.scene_view:clear_trail_cell(idx) end
    for _,row in ipairs(data.players) do
        local p=sc.__players[row.id]
        SceneSim.sync_player(p)
        Host.scene_view:set_player_skill_state(row.id,row.hidden,row.armor,row.camera)
        if row.__skill_cast_serial then
            Host.scene_view:set_skill_cast(row.id,row.__skill_cast_serial,row.__skill_cast_effect,
                math.max(0,data.time-(row.__skill_cast_at or 0)),row.__skill_cast_lifetime or 0)
        end
    end
    local seen={}
    sc.__lan_items=sc.__lan_items or {}
    for _,item in ipairs(data.items or {}) do
        seen[item.id]=true
        local old=sc.__lan_items[item.id]
        if not old then Host.scene_view:add_item(item.id,item.kind,item.x,item.y,item.hint)
        elseif old.hint.state~=item.hint.state then Host.scene_view:_item_play(item.id,item.hint.state_animation) end
        sc.__lan_items[item.id]=item
    end
    for id in pairs(sc.__lan_items) do if not seen[id] then
        Host.scene_view:remove_item(id);sc.__lan_items[id]=nil
    end end
    if director then Host.scene_view:set_area_ratio(director.__manor.count/(sc.__W*sc.__H)) end
    if data.finished and not sc.__match_finished then SceneMatch.Finish(sc) end
    if data.finished and data.results then
        for _,row in ipairs(data.results) do row.director=director and row.objectID==director.__objectID or false end
        sc.__match_results=data.results
    end
    return true
end
function L.Leave()
    L.active,L.client=false,false
    SceneMatch.ReturnHome()
end
local function cancel_window(node)
    if node:has_meta("lua") then
        local wnd=node:get_meta("lua")
        if type(wnd)=="table" then
            wnd.__lazyCreate=nil
            for key,tick in pairs(wnd) do
                if type(key)=="string" and key:match("^m_tick") and type(tick)=="table" and tick.Stop then tick:Stop() end
            end
        end
    end
    for _,child in pairs(node:get_children()) do cancel_window(child) end
end
function L.InstallHooks()
    local update=CGameScene.Update
    function CGameScene:Update(dt)
        if self.__lan_client then return end
        return update(self,dt)
    end
    local click=CGameMain.ClickDir
    function CGameMain:ClickDir(dir)
        if not L.active then return click(self,dir) end
        local grade=self:GetRhythmWnd():ClickRhythm()
        Host:lan_input(dir,false,L.client and type(grade)=="number" and grade or -1)
    end
    local skill=NativeKeySkill
    function NativeKeySkill()
        if not L.active then return skill() end
        Host:lan_input(0,true,-1)
        return true
    end
    local notify=CPlayerClient.NotifyRhythm
    function CPlayerClient:NotifyRhythm(grade)
        if L.client then return end
        return notify(self,grade)
    end
    local use=CPlayerClient.UseSkill
    function CPlayerClient:UseSkill(...)
        if L.active and scene() and self==scene().m_pDirectorObj then
            Host:lan_input(0,true,-1)
            return true
        end
        return use(self,...)
    end
    local startup=CPlayerClient.StartUp
    function CPlayerClient:StartUp(...)
        local result=startup(self,...)
        if self.__net_loadout then loadout(self,self.__net_loadout) end
        return result
    end
    local rematch,home=SceneMatch.Rematch,SceneMatch.ReturnHome
    function SceneMatch.Rematch()
        if L.active then Host:lan_action("rematch");return true end
        return rematch()
    end
    function SceneMatch.ReturnHome()
        if L.active and not L.internal then Host:lan_action("leave");return true end
        local sc=scene()
        local windows={}
        if sc and (sc.__lan_client or sc.__lan_host) and sc.m_pWanfa then
            for _,wnd in pairs(sc.m_pWanfa) do
                if type(wnd)=="table" and rawget(wnd,"__node") then
                    cancel_window(wnd.__node)
                    windows[#windows+1]=wnd.__node
                end
            end
        end
        local result=home()
        for _,node in ipairs(windows) do node:queue_free() end
        return result
    end
    -- Starting a round tears down the previous world without disconnecting transport.
    local start=SceneMatch.Start
    function SceneMatch.Start(...)
        L.internal=true
        local result=start(...)
        L.internal=false
        return result
    end
end
return L
