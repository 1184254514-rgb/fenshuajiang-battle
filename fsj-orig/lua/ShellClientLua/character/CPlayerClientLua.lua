--region CPlayerClientLua.lua
--Date 2017-08-05

local s_tbl_PlayerClient = {};

function CPlayerClientLua:OnAlloc()
	s_tbl_PlayerClient[self] = ClassCast( CPlayerClientLua, self );
end

function CPlayerClientLua:OnFree()
	s_tbl_PlayerClient[self] = nil;
end

function CPlayerClientLua:Ctor()
	self.m_bJustDie = false;
	self.m_bEffecting = false;
	self.m_tblLevelUpEffect = {};
end

function CPlayerClientLua:OnInsertToScene()
	CPlayerClient.OnInsertToScene( self );

	local pDirector = g_App:GetDirector();
	local pScene = self:GetScene();
	local nAccountID = self:GetAccountID();
	if nAccountID == g_App:GetAccountID() then
		g_App:GetGameMain():GetGameButton():PostEndCooling();
	end
	local bAI = nAccountID == 0;
	local nRoomType = pScene:GetRoomType();
	local nHours = g_App:GetServerStartHours();
	if ( nRoomType == eRT_LimitTime or nRoomType == eRT_Team ) and bAI then
		local nAvgLadderStar = pScene:GetAvgLadderStar();
		self:SetEquipID( CAIEquipConfig:Inst():GetAIEquipID( nHours, nAvgLadderStar, self:GetObjectID(), false ) );
	elseif nRoomType == eRT_Endless and bAI then
		local nAvgLadderStar = g_App:GetCurLadderStar();
		self:SetEquipID( CAIEquipConfig:Inst():GetAIEquipID( nHours, nAvgLadderStar, self:GetObjectID(), false ) );
	end

	local nColorID = 0;
	if nRoomType == eRT_Team or nRoomType == eRT_TeamSecret then
		nColorID = self:GetManor():GetColorID();
	end
	local bShowEffect = true;
	if ( nRoomType == eRT_Team or nRoomType == eRT_TeamSecret ) 
		and pDirector ~= self and not pScene:IsObserveredID( nAccountID ) then
		bShowEffect = false;
	end

	local pReanderObject = self:GetRenderObject();
	pReanderObject:OnEquipUpdated( self:GetEquipID(), nColorID, bShowEffect );
	if self:GetEquipID() > FUSIONSKIN_ID_BEGIN then
		local szEffectAllTime = g_tblTabFile.fusion[self:GetEquipID()].szEffectAllTime;
		pReanderObject:AddFusionSkinEffect( szEffectAllTime, "fx/loop", nil, false, -1 );
	end
end

function CPlayerClientLua:OnRemoveFrScene()
	CPlayerClient.OnRemoveFrScene( self );
end

function CPlayerClientLua:OnDie( Killer, bIsCollide )
	if self == g_App:GetDirector() then
		g_App:GetGameMain().m_bIsDie = true;
	end
	CPlayerClient.OnDie( self, Killer, bIsCollide );
end

function CPlayerClientLua:OnObjectDestroy()
	if self == g_App:GetDirector() and g_App:GetGameMain() and g_App:GetGameMain().m_wndLevelUp then
		local WndLevelUp = g_App:GetGameMain().m_wndLevelUp;
		WndLevelUp:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnLevelUpEffectPlayComplete", self );
	end
	self.m_tblLevelUpEffect = {};
	CPlayerClient.OnObjectDestroy( self );
end

function CPlayerClientLua:NotifySimple32PropertyChanged( eDataType, nValue, nPreValue )
	CPlayerClient.NotifySimple32PropertyChanged( self, eDataType, nValue, nPreValue );
	local pScene = g_App:GetScene();
    if self:GetAccountID() ~= 0 and pScene:GetObservedPlayerID() ~= 0 then
        if eDataType == eSPT32_KillCount or eDataType == eSPT32_DeathCount or eDataType == eSPT32_Level then
            g_App:GetGameMain().m_pObserve:RefreshPlayer( self:GetAccountID() );
        end
        return;
    end

	if self ~= g_App:GetDirector() then
		return;
	end

	local WndProgress = g_App:GetGameMain().m_wndExpProgress;
	if eDataType == eSPT32_Exp then
		if pScene:GetRoomType() == eRT_Endless
			or CSnakeConstant:Inst():GetWhetherShowExp() == 0 then
			WndProgress:ShowWnd( false );
			return;
		end
		local WndProgress = g_App:GetGameMain().m_wndExpProgress;
		WndProgress:ShowWnd( true );
		local nLevel = CPlayerLevelConfig:Inst():GetLevel( nValue );
		local nCurLevelExp = CPlayerLevelConfig:Inst():GetCurLevelExp( nValue );
		local nMaxLevelExp = CPlayerLevelConfig:Inst():GetLevelExp( nValue );
		nCurLevelExp = nCurLevelExp > nMaxLevelExp and 0 or nCurLevelExp;
		WndProgress:SetWndText( nLevel );
		WndProgress:SetRange( nMaxLevelExp );
		WndProgress:SetPos( nCurLevelExp );		
		--print( "11111111111 CPlayerClientLua:NotifySimple32PropertyChanged", nLevel, nMaxLevelExp, nCurLevelExp );
	elseif eDataType == eSPT32_Level and nValue > nPreValue then
		if g_App:GetGameMain().m_bIsDie then	--避免重生时显示特效  
			g_App:GetGameMain().m_bIsDie = false;
			return;
		end
		local WndLevelUp = g_App:GetGameMain().m_wndLevelUp;
		if pScene:GetRoomType() == eRT_Endless
			or CSnakeConstant:Inst():GetWhetherShowExp() == 0 
			or self ~= g_App:GetDirector() then
			WndLevelUp:ShowWnd( false );
			return;
		end
		WndLevelUp:ShowWnd( true );
		local LevelUpEffect = {};
		LevelUpEffect.szFile = "fx/cfg/shengji.eft";
		LevelUpEffect.szName = "fx/loop";
		LevelUpEffect.szAttach = "leveluploop";
		LevelUpEffect.nTime = 0;
		table.insert( self.m_tblLevelUpEffect, LevelUpEffect );
		local LevelUpEffect1 = {};
		LevelUpEffect1.szFile = "fx/cfg/shengji.eft";
		LevelUpEffect1.szName = "fx/end";
		LevelUpEffect1.szAttach = "levelupend";
		LevelUpEffect1.nTime = 0;
		table.insert( self.m_tblLevelUpEffect, LevelUpEffect1 );
		self:StartLevelUpTbl();

		--特效必须放这里，否则放在on事件内则顺序错误  
		local nActiveSkillID = g_App:GetMainPlayerData().m_CharBaseData:GetSkillID();
		local nActiveLevel = self:GetSceneSkillTopLevel( nActiveSkillID, nValue );
		local nActivePreLevel = self:GetSceneSkillTopLevel( nActiveSkillID, nPreValue );
		if nActiveLevel > nActivePreLevel then			
			local LevelUpEffect = {};
			LevelUpEffect.szFile = "fx/cfg/jineng_zdts.eft";
			LevelUpEffect.szName = "fx/loop";
			LevelUpEffect.szAttach = "activeup";
			LevelUpEffect.nTime = 0;
			table.insert( self.m_tblLevelUpEffect, LevelUpEffect );
			--print( "CPlayerClientLua:OnSetActiveSkill", nSkillID, nLevel, nPreLevel );
			self:StartLevelUpTbl();
		end
		
		for i = 1, CSnakeConstant:Inst():GetPassvieSkillNum() do
			local nPassiveSkillID = g_App:GetMainPlayerData().m_PassiveSkill:GetData( i - 1 );
			if nPassiveSkillID ~= 0 then
				local nPassiveLevel = self:GetSceneSkillTopLevel( nPassiveSkillID, nValue );
				local nPassivePreLevel = self:GetSceneSkillTopLevel( nPassiveSkillID, nPreValue );
				if nPassiveLevel > nPassivePreLevel then
					local bHave = false;
					local LevelUpEffect = {};
					LevelUpEffect.szFile = "fx/cfg/jineng_bdts.eft";
					LevelUpEffect.szName = "fx/loop";
					LevelUpEffect.szAttach = "passiveup";
					LevelUpEffect.nTime = 0;
					for i = 1, #self.m_tblLevelUpEffect do
						if self.m_tblLevelUpEffect[i].szAttach == LevelUpEffect.szAttach then
							bHave = true;
						end
					end
					if not bHave then
						table.insert( self.m_tblLevelUpEffect, LevelUpEffect );
					end
					self:StartLevelUpTbl();
				end
			end
		end
	elseif eDataType == eSPT32_DeathCount and nValue > 0 then
		self.m_bJustDie = true;
	end
end

function CPlayerClientLua:OnSetActiveSkill( nSkillID, nLevel, nPreLevel )
	if self ~= g_App:GetDirector() then
		return;
	end
	self.m_nActiveSkillLevel = nLevel;
	g_App:GetGameMain():GetGameButton():RefreshActiveSkill( nSkillID, nLevel );
end

function CPlayerClientLua:OnAddPassiveSkill( nSkillID, nLevel, nPreLevel )
	if self ~= g_App:GetDirector() then
		return;
	end
	g_App:GetGameMain():GetGameButton():RefreshPassiveSkill( nSkillID, nLevel );
end

function CPlayerClientLua:OnAddEquipPassiveSkill( nSkillID, nLevel, nPreLevel )
	if self ~= g_App:GetDirector() then
		return;
	end
	g_App:GetGameMain():GetGameButton():RefreshEquipPassiveSkill( nSkillID, nLevel );
end

function CPlayerClientLua:StartLevelUpTbl()
	local WndLevelUp = g_App:GetGameMain().m_wndLevelUp;
	--print( "------------------------------", #self.m_tblLevelUpEffect, not WndLevelUp, self.m_bEffecting );
	if #self.m_tblLevelUpEffect <= 0 or not WndLevelUp or self.m_bEffecting then
		return;
	end
	local LevelUpEffect = self.m_tblLevelUpEffect[1];
	print( LevelUpEffect.szFile, LevelUpEffect.szName, LevelUpEffect.szAttach, LevelUpEffect.nTime );
	WndLevelUp:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnLevelUpEffectPlayComplete", self );
	WndLevelUp:AddEffect( LevelUpEffect.szFile, LevelUpEffect.szName, LevelUpEffect.szAttach, LevelUpEffect.nTime );
	self.m_bEffecting = true;
end

function CPlayerClientLua:OnLevelUpEffectPlayComplete()
	local WndLevelUp = g_App:GetGameMain().m_wndLevelUp;
	WndLevelUp:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnLevelUpEffectPlayComplete", self );
	table.remove( self.m_tblLevelUpEffect, 1 );
	self.m_bEffecting = false;
	self:StartLevelUpTbl();
end
--endregion
