-- Exercises installed skill natives against original shipped configuration.
local S=assert(SceneSkills,'scene_skills not installed')
local savedHost,savedApp=Host,g_App
local oldSelected,oldLevel,oldPassives,oldPassiveLevels=S.selected,S.level,S.passives,S.passive_levels
local checks,visuals=0,{}
local function equal(actual,expected,label)
	checks=checks+1
	assert(actual==expected,label..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function trunc(value) return value<0 and math.ceil(value) or math.floor(value) end
local view=setmetatable({
	set_player_skill_state=function(_,id,hidden,armor,camera)
		visuals[id]={hidden=hidden,armor=armor,camera=camera}
	end,
},{__index=function() return function() end end})
Host={scene_view=view,read_text=function(_,path) return savedHost:read_text(path) end}
g_App=nil
local nextID=0
local function fixture(ai)
	nextID=nextID+1
	local sc={__W=12,__H=12,__time=0,__started=true,__roomType=0,__owner={},__trail={},__val={},__players={},__order={},__byManor={}}
	function sc:GetRoomType() return 0 end
	function sc:IsServer() return false end
	function sc:GetSceneInfo() return {IsServer=function() return false end} end
	for i=0,143 do sc.__owner[i]=0;sc.__trail[i]=0;sc.__val[i]=0 end
	local p=setmetatable({__objectID=nextID,__accountID=nextID,__scene=sc,__alive=true,__configuredSkillID=0,__skillID=0,
		__manor={manorID=nextID,colorID=(nextID-1)%10,count=1},__trail={},__trailUnder={},__segStart=1,
		__stats={killCount=0,pickUpCoin=0},__deaths=0,__kills=0,__x=24,__y=24,__manorWidth=16,__dir=2,
		__equipID=0,__musicID=121,__rhythm={maxCombo=0,total=0,count={0,0,0,0},combo=0}},CPlayerClient)
	if ai then p.__ai=function() end else sc.m_pDirectorObj=p end
	sc.__players[nextID]=p;sc.__order[1]=p;sc.__byManor[nextID]=p
	SceneItemsC.InitScene(sc)
	S.InitPlayer(p)
	return sc,p
end
local ok,failure=xpcall(function()
	S.passives={0,0,0};S.passive_levels={1,1,1}
	local high=SceneSim.const('HighSpeed',180)
	local hud=S.GetHUD()
	equal(#hud.active,7,'seven published active skills exposed')
	equal(#hud.passive,8,'eight published passive skills exposed')
	equal(hud.home,false,'login never shows loadout before connection')
	for _,row in ipairs(hud.active) do
		equal(row.id<=7,true,'hidden native skills excluded')
		equal(row.name:match('^0b14')==nil,true,'original dictionary name resolved')
		equal(row.description~='',true,'original skill description resolved')
	end
	equal(S.SetSelected(8),false,'unpublished skill not selectable')
	equal(S.SetSelected(2),true,'published active selectable')
	equal(S.SetPassive(1,101),true,'passive slot set')
	equal(S.SetPassive(2,101),false,'duplicate passive rejected')
	equal(S.SetPassive(1,0),true,'passive can be unequipped')
	equal(S.SetPassive(1.5,104),false,'fractional passive slot rejected')
	S.selected=3

	local sc,p=fixture()
	local base=p:GetAddSpeed()
	equal(S.Use(p,1),true,'dash casts')
	equal(p.__skill_cast_serial,1,'successful cast receives serial')
	equal(p.__skill_cast_effect,'0','dash preserves zero original effect')
	equal(p:GetAddSpeed(),base+trunc(high*55000/10000),'dash applies original signed speed slot')
	sc.__time=99;S.Tick(sc,99)
	equal(p:GetAddSpeed(),base+trunc(high*55000/10000),'dash lasts until 100ms endpoint')
	sc.__time=100;S.Tick(sc,1)
	equal(p:GetAddSpeed(),base,'dash speed expires exactly at 100ms')
	equal(S.Use(p,1),false,'cooldown prevents recast')
	equal(p.__skill_cast_serial,1,'cooldown rejection does not create a visual event')
	sc.__time=9999;equal(S.Use(p,1),false,'cooldown not one millisecond early')
	sc.__time=10000;equal(S.Use(p,1),true,'cooldown permits cast at endpoint')

	sc,p=fixture();base=p:GetAddSpeed()
	equal(S.Use(p,3),true,'speed casts')
	equal(p.__skill_cast_effect,'fx/cfg/jineng_jiasu.eft','speed uses original effect resource')
	equal(p.__skill_cast_lifetime,4000,'effect cap comes from maximum original magic lifetime')
	equal(p:GetAddSpeed(),base+trunc(high*3300/10000),'speed uses original 3300 modifier')
	sc.__time=500;S.Tick(sc,500)
	equal(visuals[p.__objectID].camera,100,'camera expands to native 100px after ramp')
	sc.__time=3750;S.Tick(sc,3250)
	equal(visuals[p.__objectID].camera,50,'camera returns through symmetric ramp')
	sc.__time=4000;S.Tick(sc,250)
	equal(p:GetAddSpeed(),base,'speed fully expires')
	equal(visuals[p.__objectID].camera,0,'camera returns to base')

	sc,p=fixture();base=p:GetAddSpeed()
	equal(S.Use(p,7),true,'invisibility casts')
	equal(p:GetAddSpeed(),base+trunc(high*-1700/10000),'invisibility slows rather than unsigned overflows')
	sc.__time=1;S.Tick(sc,1)
	equal(visuals[p.__objectID].hidden,true,'invisibility forwarded to real renderer API')
	sc.__time=5000;S.Tick(sc,4999)
	equal(visuals[p.__objectID].hidden,false,'hidden state expires')
	equal(p:GetAddSpeed(),base,'invisibility slowdown restored')

	sc,p=fixture();base=p:GetAddSpeed()
	equal(S.Use(p,5),true,'shield casts')
	equal(p:GetSimple32Property(9),1,'shield armor property set')
	equal(p:GetAddSpeed(),base+trunc(high*-4500/10000),'shield carries original slowdown')
	equal(S.BeforeDeath(sc,p,nil,true,'body'),false,'armor prevents body contact death')
	equal(S.BeforeDeath(sc,p,nil,true,'trail'),true,'armor does not protect remote exposed trail')
	sc.__time=3000;S.Tick(sc,3000)
	equal(p:GetSimple32Property(9),0,'armor restores after 3 seconds')
	equal(S.BeforeDeath(sc,p,nil,true,'body'),true,'expired shield permits contact death')

	sc,p=fixture()
	equal(S.Use(p,4),true,'harvest casts')
	equal(p:GetSimple32Property(20),5000,'harvest adds original area bonus')
	S.RefreshModifiers(p);S.RefreshModifiers(p)
	equal(p:GetSimple32Property(20),5000,'refresh never stacks same modifier')
	sc.__time=7000;S.Tick(sc,7000)
	equal(p:GetSimple32Property(20),0,'area bonus removed on expiry')
	sc,p=fixture()
	equal(S.Use(p,6),true,'battle rage casts')
	equal(p:GetSimple32Property(19),4000,'rage adds original kill bonus')
	S.OnKilled(sc,p,nil)
	equal(p:GetSimple32Property(19),0,'death removes temporary score modifier')
	equal(p.__skill_extra_speed,0,'death removes active speed')
	equal(visuals[p.__objectID].hidden,false,'death clears renderer concealment state')
	equal(visuals[p.__objectID].camera,0,'death clears renderer camera bonus')

	sc,p=fixture()
	for _,idx in ipairs({25,26,27}) do sc.__trail[idx]=p.__objectID;p.__trail[#p.__trail+1]=idx end
	local other={__manor={manorID=999,count=2}}
	sc.__byManor[999]=other;sc.__owner[27]=999
	equal(S.Use(p,2),true,'concrete casts')
	equal(#p.__trail,0,'concrete consumes current trail')
	equal(p.__manor.count,4,'concrete claims exactly three line cells')
	equal(other.__manor.count,1,'concrete removes stolen cell from former owner')
	for _,idx in ipairs({25,26,27}) do
		equal(sc.__owner[idx],p.__manor.manorID,'line cell becomes territory')
		equal(sc.__trail[idx],0,'claimed cell clears line marker')
	end
	equal(sc.__owner[38],0,'concrete does not flood enclosed area')

	S.passives={101,104,105}
	sc,p=fixture()
	equal(p:GetSimple32Property(10),16,'pickup passive original +16 range')
	equal(p:GetSimple32Property(19),1000,'kill passive original +1000 bonus')
	equal(p:GetSimple32Property(12),1,'drop passive original +1 coin')
	p:StartUp(0);p:StartUp(0)
	equal(p:GetSimple32Property(10),16,'startup does not duplicate pickup modifier')
	equal(p:GetSimple32Property(19),1000,'startup does not duplicate score modifier')
	equal(p:GetSimple32Property(12),1,'startup does not duplicate drop modifier')
	S.passives={109,0,0}
	sc,p=fixture()
	equal(p:GetSimple32Property(20),0,'conditional passive inactive below threshold')
	SceneScore.SetProperty(p,1,16,false);S.RefreshModifiers(p)
	equal(p:GetSimple32Property(20),2000,'conditional passive activates at recovered kill threshold')
	SceneScore.SetProperty(p,1,15,false);S.RefreshModifiers(p)
	equal(p:GetSimple32Property(20),0,'conditional passive removes when condition false')

	S.passives={0,0,0}
	local aiSkills={}
	for index=1,3 do
		sc,p=fixture(true)
		aiSkills[p.__skillID]=true
		equal(#p.__skill_passives,0,'AI does not copy human loadout')
		p.__trail={25,26};sc.__time=2500;S.Tick(sc,2500)
		equal(p.__skill_last_cast,2500,'AI can activate assigned skill')
	end
	local distinct=0;for _ in pairs(aiSkills) do distinct=distinct+1 end
	equal(distinct,3,'AI identities receive varied skills')
	sc,p=fixture();sc.__match_finished=true
	equal(S.Use(p,1),false,'finished match rejects skill casts')
	p.__alive=false;sc.__match_finished=false
	equal(S.Use(p,1),false,'dead painter cannot cast')

	-- Fault-speed movement must cross cells continuously, including left/up.
	S.passives={0,0,0}
	for _,dir in ipairs({1,2,4,8}) do
	 sc,p=fixture();p.__x,p.__y=88,88;p.__dir=dir;p.__speedup=false
	 local ox,oy=p.__x,p.__y
	 for i=1,60 do
	  sc.__time=i*16
	  p:RhythmSpeed(3)
	  S.Tick(sc,16)
	  SceneSim.step_player(sc,p,16)
	 end
	 local travelled=math.abs(p.__x-ox)+math.abs(p.__y-oy)
	 equal(travelled>65,true,'continuous fault retains slow movement direction '..dir)
	 equal(p.__alive,true,'leaving own territory does not cause self death direction '..dir)
	end

	-- GDScript methods are callable userdata through lua-gdextension. A plain
	-- Lua function mock cannot catch a bridge that incorrectly rejects them.
	Host=savedHost
	sc,p=fixture()
	equal(S.Use(p,7),true,'real-host invisibility casts')
	sc.__time=1;S.Tick(sc,1)
	local realState=Host.scene_view._player_skill_states[p.__objectID]
	equal(realState~=nil,true,'actual Godot state receives skill callback')
	equal(realState.hidden,true,'actual Godot state receives invisibility')
	S.OnKilled(sc,p,nil)
	equal(Host.scene_view._player_skill_states[p.__objectID].hidden,false,'actual Godot death callback restores visibility')
	sc,p=fixture()
	equal(S.Use(p,3),true,'real-host camera skill casts')
	sc.__time=500;S.Tick(sc,500)
	equal(Host.scene_view._player_skill_states[p.__objectID].camera_bonus,100,'actual Godot receives camera pixels')
	sc,p=fixture()
	equal(S.Use(p,5),true,'real-host shield casts')
	sc.__time=1;S.Tick(sc,1)
	equal(Host.scene_view._player_skill_states[p.__objectID].armor,1,'actual Godot receives armor state')
end,debug.traceback)
Host,g_App=savedHost,savedApp
S.selected,S.level,S.passives,S.passive_levels=oldSelected,oldLevel,oldPassives,oldPassiveLevels
assert(ok,failure)
return 'SKILLS REGRESSION PASS: '..checks..' checks'
