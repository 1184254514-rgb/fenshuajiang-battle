--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWanfaEndless:Ctor( pScene )
	CWanfaBase.Ctor( self, pScene );

	self.m_bBalance = false;
	self.m_tickCheck			= CTick:new( "OnTickCheck", self );
	self.m_tickUpdateRank		= CTick:new( "UpdateRank", pScene );
	self.m_tickCreateDirector	= CTick:new( "OnCreateDirector", self );

	self.m_EventDispatcher:AddEventListener( "OnSceneCreated", "OnSceneCreated", self );
	self.m_EventDispatcher:AddEventListener( "OnSceneDestroy", "OnSceneDestroy", self );
	self.m_EventDispatcher:AddEventListener( "OnRemoveObject", "OnRemoveObject", self );
	
	self.m_tickCheck:Start( 100 );
	self.m_tickUpdateRank:Start( 1500 );
end

function CWanfaEndless:OnTickCheck()
	self.m_pScene:OnAddAiTick( self.m_tickCheck:GetInteval() );

	if self.m_pScene:GetTimeRemain() == 0 then
		self:Balance( eRO_RemainEnd );
		return;
	end

	local pPlayer = g_App:GetDirector();
	if not pPlayer then
		return;
	end

	local pManor = pPlayer:GetManor();
	if not pManor or pManor:GetNodeCount() ~= self.m_pScene:GetNodeTotal() then
		return;
	end

	self:Balance( eRO_ManorAllUse );
end

function CWanfaEndless:Balance( nRoomOverType )
	self.m_tickCheck:Stop();
	if self.m_bBalance then
		return;
	end
	self.m_nRunTime = math.floor( ( GetNatureTime() - self.m_pScene:GetSceneTime() ) / 1000 );

	self.m_bBalance = true;
	local pDirector = g_App:GetDirector();

	--  获取积分相关数据
	local pScoreBuffer = CBufferStream:new( StruScoreSize );
	pDirector:GetScoreInfo( pScoreBuffer );
	self.m_structScore = UnpackStruScore( pScoreBuffer );

	-- 获取节奏相关数据
	local pRhythmDataBuffer = CBufferStream:new( SRhythmDataSize );
	pDirector:GetRhythmData( pRhythmDataBuffer );
	self.m_sRhythmData = UnpackRhythmData( pRhythmDataBuffer );

	local szKillName = nil;
	if nRoomOverType == eRO_DirectorDie then
		szKillName = pDirector:GetKillName();
	end
	
	self:CheckShowState();
	self.m_pRhythmSettWnd:GetWndRhythmData():UpdateData( self.m_sRhythmData, self.m_nRunTime );
	self.m_pResultWnd:UpdateData( nRoomOverType, self.m_structScore, szKillName );
	self.m_pWndBalance:Settlement( eSettlementType_RemainEnd, 0, 0, self.m_structScore, 0, self.m_sRhythmData, self.m_nRunTime );
	self.m_pWndBalanceBeyond:InitSettlementData( self.m_structScore );

	local pGameMain = g_App:GetGameMain();
	pGameMain:PlaySound( CGameMainLua.eSound_GameOver );
	pGameMain:RoomOver();

	if not self.m_tickDieBalance then
		self.m_tickDieBalance = CTick:new( "SecondsWait", self, nil, 1 );
	end

	local WorldConn = g_App:GetWorldConn();
	if not WorldConn then
		self.m_pWndBalance:ShowWnd( true );	
		return;
	end

	local tblTodayData = g_App:GetCurRankData( eGradeType_EndlessToday );
	if tblTodayData and tblTodayData.nWorldScore
		and self.m_structScore.nNodeCount / self.m_pScene:GetNodeTotal() > tblTodayData.nWorldScore then
		self:SetGameInsideResult( eGameInsideBeyondWorld );
	elseif tblTodayData and tblTodayData.nFriendScore 
		and self.m_structScore.nNodeCount / self.m_pScene:GetNodeTotal() > tblTodayData.nFriendScore 
		and g_App:GetNickName() ~= tblTodayData.szFriendName and tblTodayData.szFriendName ~= "" then
		self:SetGameInsideResult( eGameInsideBeyondFriend );
	elseif tblTodayData and tblTodayData.nTodayScore
		and self.m_structScore.nNodeCount / self.m_pScene:GetNodeTotal() > tblTodayData.nTodayScore then
		self:SetGameInsideResult( eGameInsideBeyondSelf );
	end
	
	local nCurGameScore = g_App:GetMainPlayerData().m_CharBaseData:GetAllGameScore();
	local pWndBalanceBeyond = self.m_pScene:GetWanfa().m_pWndBalanceBeyond;
	if nCurGameScore < CSnakeConstant:Inst():GetStartLimitSchema() then
		local pWndDieTip = self.m_pScene:GetWanfa().m_pWndDieTip;
		
		self.m_tickDieBalance:Start( 1000 );
		self.m_tickDieBalance:SetContext( pWndDieTip );
	else
		if self.m_pScene:GetWanfa():GetGameInsideResult() > eGameInsideBeyondInit  then
			self.m_tickDieBalance:Start( 1000 );
			self.m_tickDieBalance:SetContext( pWndBalanceBeyond );
		else
			self.m_pWndModeOpenReward:ShowWndByRoomType( eRT_Endless );
		end
	end

	local nCurTask = g_App:GetMainPlayerData().m_CharBaseData:GetCurTask();
	local nCurTaskScore = 0;
	if nCurTask ~= TASK_FINISHED and nCurTask < CDailyTaskConfig:Inst():GetMaxTaskCount() then
		local nTaskType = CDailyTaskConfig:Inst():GetTaskType( nCurTask );
		if nTaskType == 0 then
			nCurTaskScore = math.ceil( g_App:GetGameMain():GetMaxNodeCount()/self.m_pScene:GetNodeTotal() * 10000 );
		elseif nTaskType == 1 then
			nCurTaskScore = self.m_structScore.nKillCount;
		elseif nTaskType == 2 then
			nCurTaskScore = self.m_sRhythmData.m_nMaxCombo;
		elseif nTaskType == 3 then
			nCurTaskScore = self.m_structScore.aryMaxGrade[4];
		end
	end
	local NetMsg = CEndlessData:new();
	NetMsg.m_nRunTime = self.m_nRunTime;
	NetMsg.m_nCurTaskScore = nCurTaskScore;
	NetMsg.m_sScore = self.m_structScore;
	NetMsg.m_sRhythmData = self.m_sRhythmData;
	NetMsg.m_nStrikeOthersTipCount = g_App:GetEndlessTipCount( eMUT_StrikeOthers );
	NetMsg.m_nMakeManorTipCount = g_App:GetEndlessTipCount( eMUT_MakeManor );
	NetMsg.m_nStrikeSelfTipCount = g_App:GetEndlessTipCount( eMUT_StrikeSelf );
	NetMsg.m_nDiedTipCount = g_App:GetEndlessTipCount( eMUT_Died );
	g_App:SendShellMsg( NetMsg );
end

function CWanfaEndless:SecondsWait()
	self.m_tickDieBalance:Stop();
	self.m_tickDieBalance:GetContext():ShowWnd( true );
end

function CWanfaEndless:ShowResult()
	local nGameTime = GetNatureTime() - self.m_pScene:GetSceneTime();

	if nGameTime > CSnakeConstant:Inst():GetRhythmWndTime() * 1000 then
		self.m_pRhythmSettWnd:ShowWnd( true );
	else
		self.m_pResultWnd:ShowWnd( true );
	end
end

function CWanfaEndless:OnCreateDirector()
	self.m_tickCreateDirector:Stop();
	if not self.m_pScene then
		return;
	end

	local tblFaceID = {};
	for i = 0, MAX_BattleFace_Count - 1 do
		local BattleFaceData = g_App:GetMainPlayerData().m_BattleFaceData:GetData( i );
		if BattleFaceData:GetUsed() == 1 then
			tblFaceID[i] = BattleFaceData:GetBattleFaceID();
		else
			tblFaceID[i] = 0;
		end
	end	

	local nCurLadderSeason = g_App:GetCurLadderSeason();
	local nAccountID = g_App:GetAccountID();
	local nManorID = 0;
	local nHeadID = 0;
	local nEquipID = g_App:GetMainPlayerData().m_CharBaseData:GetCurEquipID();
	local nMusicID = 0;
	local nSkillID = 0;
	local nStarNum = g_App:GetMainPlayerData().m_SeasonStarNum:GetData( nCurLadderSeason % g_App:GetMainPlayerData().m_SeasonStarNum:GetDataMaxCount() );
	local szNickName = g_App:GetMainPlayerData().m_CharBaseData:GetNickName();
	local nPlayerID = self.m_pScene:AllocObjectID( true );
	local nManorWidth = CSnakeConstant:Inst():GetInitWidth();
	local nSceneWidth = self.m_pScene:GetSceneInfo():GetWidth();
	local nSceneDepth = self.m_pScene:GetSceneInfo():GetDepth();
	local vPos = CPos16:new();
	vPos:x( math.random( nManorWidth, nSceneWidth - nManorWidth ) );
	vPos:y( math.random( nManorWidth, nSceneDepth - nManorWidth ) );
	
	local tblDBSkillInfo = g_App:GetSkillInfoByID( g_App:GetMainPlayerData().m_CharBaseData:GetSkillID() );
	local nSkillMaxLevel = tblDBSkillInfo and tblDBSkillInfo.nDBSkillLevel or 1;
	local tblPassiveKillID = {};
	local tblPassiveKillTopLevel = {};
	for j = 1, Max_Passive_Skill_Num do
		local nPassiveKillID = g_App:GetMainPlayerData().m_PassiveSkill:GetData( j - 1 );
		table.insert( tblPassiveKillID, nPassiveKillID );
		local tblDBSkillInfo = g_App:GetSkillInfoByID( nPassiveKillID );
		if nPassiveKillID ~= 0 and tblDBSkillInfo then
			table.insert( tblPassiveKillTopLevel, tblDBSkillInfo.nDBSkillLevel );
		else
			table.insert( tblPassiveKillTopLevel, 1 );
		end
	end
	local nEquipPassiveSkillTopLevel = 1;	--mikechange

	local pContext = self.m_pScene:CreatePlayerContex( nAccountID, nManorID, nHeadID, nEquipID, 
		nMusicID, nSkillID, tblFaceID, nStarNum, nSkillMaxLevel, tblPassiveKillID, 
		tblPassiveKillTopLevel, szNickName, 0, nEquipPassiveSkillTopLevel )

	local pPlayer = self.m_pScene:AddPlayer( nPlayerID, pContext, vPos, nManorWidth );
	pPlayer:StartUp( nEquipID );
	g_App:SetDirector( pPlayer );
end

function CWanfaEndless:OnRemoveObject( Event )
	if Event.m_Object ~= g_App:GetDirector() then
		return;
	end

	-- 判断是否是被击杀死亡  
	if Event.m_Object:IsAlive() then
		return;
	end

	self:Balance( eRO_DirectorDie );
end

function CWanfaEndless:OnSceneCreated()
	local pGameMain = g_App:GetGameMain();
	self.m_pResultWnd = CWndResultEndless:new( "gui/cfg/fsj_youxijieshu.gui", pGameMain, 1 );
	self.m_pRhythmSettWnd = CWndRhythmSett:new( "gui/cfg/fsj_jztongji.gui", pGameMain, 1 );
	self.m_pWndBalance = CWndBalance:new( "gui/cfg/fsj_jiesuan.gui", pGameMain, 1 );
	self.m_pWndDieTip = CWndBalanceDieTip:new( "gui/cfg/fsj_siwangtishi.gui", pGameMain, 1 );
	self.m_pWndBalanceBeyond = CWndBalanceBeyond:new( "gui/cfg/fsj_chaoyuejilu.gui", pGameMain, 1 );
	self.m_pWndModeOpenReward = CWndModeOpenReward:new( "gui/cfg/fsj_huodewupin.gui", pGameMain, 1 );
	self.m_nGameInsideResult = eGameInsideBeyondInit;

	self.m_tickCreateDirector:Start( 1 );
end

function CWanfaEndless:OnSceneDestroy()	
	self.m_tickCheck:Stop();
	self.m_tickUpdateRank:Stop();

	self.m_pResultWnd:ShowWnd( false );
	self.m_pRhythmSettWnd:ShowWnd( false );
	self.m_pWndBalance:ShowWnd( false );
end

function CWanfaEndless:RhythmSettClickCon()
	self.m_pResultWnd:ShowWnd( true );
	self.m_pRhythmSettWnd:ShowWnd( false );
end

function CWanfaEndless:CheckShowState()
	local nCurMaxCombo = self.m_sRhythmData.m_nMaxCombo;
	local tblAllGradeRecord = CPlayerGradeInfoMgr:Instance():GetAllDataNew();
	if not tblAllGradeRecord then return end;
	local nMaxComboRecordToday = tblAllGradeRecord[eGradeType_EndlessToday].nMaxCombo;
	local nMaxComboRecordWeek = tblAllGradeRecord[eGradeType_EndlessWeek].nMaxCombo;
	local nMaxComboRecordHistory = tblAllGradeRecord[eGradeType_EndlessHistory].nMaxCombo;
	local nMaxComboStandard = g_data_graderecordshowlevel[1].nEndlessMaxCombo;
	local bNewToday = nCurMaxCombo >= nMaxComboStandard and nCurMaxCombo > nMaxComboRecordToday;
	local bNewWeek = nCurMaxCombo >= nMaxComboStandard and nCurMaxCombo > nMaxComboRecordWeek;
	local bNewHistory = nCurMaxCombo >= nMaxComboStandard and nCurMaxCombo > nMaxComboRecordHistory;
	self.m_pRhythmSettWnd:GetWndRhythmData():ShowNewRecord( bNewToday, bNewWeek, bNewHistory );
end

function CWanfaEndless:SetGameInsideResult( nValue )
	self.m_nGameInsideResult = nValue;
end

function CWanfaEndless:GetGameInsideResult()
	return self.m_nGameInsideResult;
end
--endregion
