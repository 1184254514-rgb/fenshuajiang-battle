--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWanfaServer:Ctor( pScene )
	CWanfaBase.Ctor( self, pScene );
	self.m_bSettlement = false;
	self.m_tickRebirth = CTick:new( "OnRebirth", self );
	local pGameMain = g_App:GetGameMain();
	self.m_pWndRebirthEff = CGWnd:new( "gui/cfg/fsj_chongshengdaojishi.gui", pGameMain, 1 );
	self.m_pWndSettlemet = CWndSettlemet:new( "gui/cfg/fsj_xianshimoshi.gui", pGameMain, 1 );
	self.m_pWndLadder = CWndLadder:new( "gui/cfg/fsj_duanweijiesuan.gui", pGameMain, 1 );
	self.m_pWndBalance = CWndBalance:new( "gui/cfg/fsj_jiesuan.gui", pGameMain, 1 );
	self.m_pWndBalanceBeyond = CWndBalanceBeyond:new( "gui/cfg/fsj_chaoyuejilu.gui", pGameMain, 1 );
	self.m_pWndModeOpenReward = CWndModeOpenReward:new( "gui/cfg/fsj_huodewupin.gui", pGameMain, 1 );

	self.m_EventDispatcher:AddEventListener( "OnSceneCreated", "OnSceneCreated", self );
	self.m_EventDispatcher:AddEventListener( "OnSceneDestroy", "OnSceneDestroy", self );
	self.m_EventDispatcher:AddEventListener( "OnDestroyObject", "OnDestroyObject", self );
end

function CWanfaServer:OnSceneDestroy()
	local pGameMain = g_App:GetGameMain();
	self.m_pWndSettlemet:ShowWnd( false );
	self.m_pWndLadder:ShowWnd( false );
	self.m_pWndBalance:ShowWnd( false );
end

function CWanfaServer:OnDestroyObject( Event )
	if Event.m_Object ~= g_App:GetDirector() then
		return;
	end

	if self.m_bSettlement or self.m_pScene:IsClosed() then
		return;
	end
	if g_App:GetGameMain() and g_App:GetGameMain().m_pWndRank1 and g_App:GetGameMain().m_pWndRank1.pWndSelfRank then
		g_App:GetGameMain().m_pWndRank1.pWndSelfRank:InitValue();
	elseif g_App:GetGameMain() and g_App:GetGameMain().m_pWndRank2 and g_App:GetGameMain().m_pWndRank2.pWndSelfRank then
		g_App:GetGameMain().m_pWndRank2.pWndSelfRank:InitValue();
	end

	self.m_nRebirthSec = math.floor( CSnakeConstant:Inst():GetRebirth() / 1000.0 );
	self:OnRebirth();
	self.m_tickRebirth:Start( 1000 );
end

function CWanfaServer:OnSceneCreated()
	self.m_nGameInsideResult = eGameInsideBeyondInit;
end

function CWanfaServer:OnRebirth()
	self.m_pWndRebirthEff:ShowWnd( false );
	if self.m_nRebirthSec == 0 then
		self.m_tickRebirth:Stop();
		return;
	end
	self.m_pWndRebirthEff:ShowWnd( true );
	local pWnd = self.m_pWndRebirthEff:GetDlgChild( "tishi.texiao" );
	if pWnd then
		pWnd:RemoveAllEffects();
		pWnd:AddEffect( "fx/cfg/daojishi.eft", "fx/"..self.m_nRebirthSec, "daojishi", 1000 );
	end
	self.m_nRebirthSec = self.m_nRebirthSec - 1;
end

function CWanfaServer:Settlement( 
	nSettlementType, 
	bIsObserver, 
	structScore,
	sRhythmData, 
	nTeamRank, 
	nPlayerRank,
	tblSettlementTeam,
	tblBattleInfo,
	nOldStar,
	nNewestStar,
	nRunTime )

	self.m_pWndSettlemet:Settlement( nSettlementType, bIsObserver, structScore, sRhythmData,
		nTeamRank, nPlayerRank, tblSettlementTeam, tblBattleInfo, nRunTime );
	self.m_pWndBalance:Settlement( nSettlementType, nOldStar, nNewestStar, 
		structScore, nTeamRank, sRhythmData, nRunTime, tblBattleInfo, tblSettlementTeam );
	self.m_pWndLadder:InitSettlementData( nSettlementType, nOldStar, nNewestStar, nTeamRank );
	self.m_pWndBalanceBeyond:InitSettlementData( structScore );

	if bIsObserver 
		or self.m_pScene:GetRoomType() == eRT_LimitSecret 
		or self.m_pScene:GetRoomType() == eRT_TeamSecret
		or self.m_pScene:GetRoomType() == eRT_LimitRace 
		or self.m_pScene:GetRoomType() == eRT_TeamRace then
	    self.m_pWndSettlemet:ShowScore();
	    self.m_pWndSettlemet:ShowAndSetFocus();
    else
		self.m_pWndBalance:ShowWnd( true );
    end
end

function CWanfaServer:UpdateGameInsideResult( nAllScore )
	local tblTodayData = g_App:GetCurRankData( eGradeType_EndlessToday );
	if g_App:GetScene():GetRoomType() == eRT_LimitTime then
		tblTodayData = g_App:GetCurRankData( eGradeType_LimitToday );
	elseif g_App:GetScene():GetRoomType() == eRT_Team then
		tblTodayData = g_App:GetCurRankData( eGradeType_TeamToday );
	end
	if tblTodayData and tblTodayData.nWorldScore 
		and nAllScore > tblTodayData.nWorldScore then
		self:SetGameInsideResult( eGameInsideBeyondWorld );
	elseif tblTodayData and tblTodayData.nWorldScore 
		and nAllScore > tblTodayData.nFriendScore 
		and g_App:GetNickName() ~= tblTodayData.szFriendName 
		and tblTodayData.szFriendName ~= "" then
		self:SetGameInsideResult( eGameInsideBeyondFriend );
	elseif tblTodayData and tblTodayData.nWorldScore 
		and nAllScore > tblTodayData.nTodayScore then
		self:SetGameInsideResult( eGameInsideBeyondSelf );
	end	
end

function CWanfaServer:ShowResult()
	self.m_pWndSettlemet:ShowScore();
	self.m_pWndSettlemet:ShowWnd( true );
	self.m_pWndLadder:ShowWnd( true );
end

function CWanfaServer:ShowLadder()
	self.m_pWndLadder:ShowWnd( true );
end

function CWanfaServer:ShowResultLimit()
	self.m_pWndSettlemet:ShowScore();
	self.m_pWndSettlemet:ShowWnd( true );
end

function CWanfaServer:MarkExitRoom()
	self.m_bSettlement = true;
end

function CWanfaServer:SetGameInsideResult( nValue )
	self.m_nGameInsideResult = nValue;
end

function CWanfaServer:GetGameInsideResult()
	return self.m_nGameInsideResult;
end
--endregion
