--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CNotifyKick:OnUnpack( pBuffer )
	self.nNotifyType = pBuffer:ReadUint16();
end

function CNotifyKick:OnNetReply( Connecter, pBuffer )
	print( "NotifyKick : "..self.nNotifyType );
	local Config = CKickMsgConfig.Inst();
	local szErrMsg = Config:GetErrMsg( self.nNotifyType );

	if self.nNotifyType == eVRT_AccountFreeze then
		local nFreezeTime = pBuffer:ReadUint32();
		local nSecond = nFreezeTime % 60;
		local nMimute = math.floor( nFreezeTime/60 ) % 60;
		local nHour = math.floor( nFreezeTime/3600 );
		local szTime = string.format( "%d:%02d:%02d", nHour, nMimute, nSecond );
		local szPrefix = CStringConfig:Inst():GetString( "shengyushijian" );
		szErrMsg = szErrMsg .. szPrefix .. szTime
	end

	g_App:MessageBox( szErrMsg,
	{
		[CMessageBox.OK] = function( Box )
			if self.nNotifyType == eVRT_InvalidVersion then
				g_App:Reboot()
			else
				Box:HideMessageBox()
			end
			CMessageBox.HideMessageBox();
		end
	} );

	if not g_App:GetWorldConn() then
		return;
	end
	g_App:GetWorldConn():OnKick();
	g_App:GetWorldConn():ShellCmdClose();
end

function CNotifyQueueIndex:OnUnpack( pBuffer )
	self.nQueueIndex = pBuffer:ReadUint32();
end

function CNotifyQueueIndex:OnNetReply( Connecter, pBuffer )
	local szFormat = g_App:GetString( "zhengzaipaidui" );
	local szText = string.format( szFormat, self.nQueueIndex );
	g_App:WaitMsg( true, nil, szText );
end

function CNotifyPropertyChanged:OnUnpack( Buffer )
	self.m_nChunkType = Buffer:ReadUint8();
	self.m_nBlockIndex = Buffer:ReadUint16();
	self.m_nDiffCount = Buffer:ReadUint16();
end

--数据类型,对应 EChunkType
local eTrunkType_Char = 0;

function CNotifyPropertyChanged:OnNetReply( Connecter, Buffer )
	if self.m_nChunkType == eTrunkType_Char then
		g_App:GetMainPlayerData():UpdateFromServer( Buffer, self.m_nBlockIndex, self.m_nDiffCount );
	end
end

function CTeamResult:OnUnpack( pBuffer )
	self.nTeamID = pBuffer:ReadUint64();
    self.nTeamType = pBuffer:ReadUint8();
    self.nType = pBuffer:ReadUint8();
    self.nResult = pBuffer:ReadUint8();
end

function CTeamResult:OnNetReply( Connecter, pBuffer )
    if self.nType == 0 then
        if self.nResult == 0 then
	        g_App:GetGameStart():GetTeamWnd( self.nTeamType ):OnCreateTeamResult( self.nTeamID );
		elseif self.nResult == 15 then
			g_App:GetGameStart().m_pWndRace:CannotJoinTeamRace( g_App:GetString( "ziyuanbuzu" ) );
		elseif self.nResult == 16 then
			g_App:GetGameStart().m_pWndRace:CannotJoinTeamRace( g_App:GetString( "saishicishushangxian" ) );
		elseif self.nResult == 17 then
			g_App:GetGameStart().m_pWndRace:CannotJoinTeamRace( g_App:GetString( "meidaokaisaishijian" ) );
        end
    elseif self.nType == 1 then
        if self.nResult == 1 then
	        g_App:HideMsg( CStringConfig.Inst():GetString( "tuanduitishi1" ) );
        elseif self.nResult == 4 then
	        g_App:HideMsg( CStringConfig.Inst():GetString( "fangjianyiman" ) );
		elseif self.nResult == 5 then
			g_App:HideMsg( g_App:GetString( "ziyuanbuzu" ) );  
		elseif self.nResult == 6 then
			g_App:HideMsg( g_App:GetString( "saishicishushangxian" ) );
        end
    elseif self.nType == 2 then
        if self.nResult == 0 then
			CPlayerRoomMemberInfoMgr:Instance():ClearData();
			local wndGameStart = g_App.m_GameStart;
	        if wndGameStart and ( self.nTeamType == eMRT_Limit or self.nTeamType == eMRT_Team ) then
		        local wndTeam1 = wndGameStart:GetTeamWnd( eMRT_Limit );
		        local wndTeam2 = wndGameStart:GetTeamWnd( eMRT_Team );
		        if wndTeam1 then
			        wndTeam1:ShowWnd( false );
		        end
		        if wndTeam2 then
			        wndTeam2:ShowWnd( false );
		        end
	        end
        end
    end
	if self.nResult == 5 then
		if self.nTeamType == eMRT_Limit then
			local nEndlessGameScore = g_App:GetGameScore( eRT_Endless );
			local nEndlessSceneNodeTotal = g_GetSceneNodeTotal( eRT_Endless );
			local nLimitModeOpenRatio = CSnakeConstant:Inst():Getxianshijiesuomianji()/10000;
			g_App:GetGameStart().m_WndModelOpenLimit:ShowWndByType( eRT_LimitTime, nEndlessGameScore, nEndlessSceneNodeTotal * nLimitModeOpenRatio );	
		elseif self.nTeamType == eMRT_Team then
			local nLimitGameScore = g_App:GetGameScore( eRT_LimitTime );
			local nTeamOpenScore = CSnakeConstant:Inst():Gettuanzhanjiesuofenshu();
			g_App:GetGameStart().m_WndModelOpenLimit:ShowWndByType( eRT_Team, nLimitGameScore, nTeamOpenScore );
		end
	end

	if self.nResult == 3 or self.nResult == 0 then
		g_App.m_GameStart.m_wndIM:OnClose()
	end
end

function CSyncTeamInfo:OnUnpack( pBuffer )
	self.nTeamID = pBuffer:ReadUint64();
    self.nCount = pBuffer:ReadUint32();
    self.nType = pBuffer:ReadUint8();
    self.nLeftTime = pBuffer:ReadUint32();
    self.members = {};

    for i = 0, self.nCount - 1, 1 do
        self.members[i] = {};
        self.members[i].nAccountID = pBuffer:ReadUint64();
        self.members[i].szName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
        self.members[i].nCurHeadIcon = pBuffer:ReadUint16();
        self.members[i].nMusicID = pBuffer:ReadUint16();
        self.members[i].nCurLadderStar = pBuffer:ReadUint32();
        self.members[i].nSkillID = pBuffer:ReadUint16();
		self.members[i].nSkillMaxLevel = pBuffer:ReadUint8();
		self.members[i].nPos = pBuffer:ReadUint8();
		self.members[i].nMatchStartTime = pBuffer:ReadUint32();
		self.members[i].bCaptain = pBuffer:ReadBoolean();
		self.members[i].bReady = pBuffer:ReadBoolean();
		self.members[i].bDisable = pBuffer:ReadBoolean();
    end
end

function CSyncTeamInfo:OnNetReply( Connecter, pBuffer )
	print( "11111111CSyncTeamInfo:OnNetReply", self.nTeamID, self.nCount, self.nType );
	CPlayerRoomMemberInfoMgr:Instance():SetData( self );
	g_App:GetGameStart():GetTeamWnd( self.nType ):OnSyncTeamInfo( self );
end

function CNotifyNewWorldPrize:OnUnpack( pBuffer )
	local nPrizeCount = pBuffer:ReadUint32();
	self.tblPrizeList = {}
	for i = 1, nPrizeCount do
		local tblPrize = {};
		tblPrize.m_nPrizeID = pBuffer:ReadUint32();
		tblPrize.m_nStartTime = pBuffer:ReadUint32();
		tblPrize.m_nEndTime = pBuffer:ReadUint32();
		tblPrize.m_nCharCreateTimeStart = pBuffer:ReadUint32();
		tblPrize.m_nCharCreateTimeEnd = pBuffer:ReadUint32();
		tblPrize.m_nType = pBuffer:ReadUint8();
		tblPrize.m_nAccountID = pBuffer:ReadUint64();
		tblPrize.m_szName = pBuffer:ReadUTF();
		tblPrize.m_szDesc = pBuffer:ReadUTF();
		local nPropCount = pBuffer:ReadUint8();
		tblPrize.m_tblPropList = {}
		for j = 1, nPropCount do
			local tblProp = {};
			tblProp.m_nType = pBuffer:ReadUint8();
			tblProp.m_nTypeIndex = pBuffer:ReadUint32();
			tblProp.m_nCount = pBuffer:ReadUint32();
			table.insert( tblPrize.m_tblPropList, tblProp );
		end
		if g_App:GetMainPlayerData():IsPrizeValie( tblPrize ) then
			table.insert( self.tblPrizeList, tblPrize );
		end
	end
end

function CNotifyNewWorldPrize:OnNetReply( Connecter, pBuffer )
	if #self.tblPrizeList == 0 then
		return;
	end

	for i = 1, #self.tblPrizeList do
		local tblPrize = self.tblPrizeList[i];
		g_App:GetGameStart():NotifyPrize( tblPrize.m_nPrizeID, 
			tblPrize.m_szName, tblPrize.m_szDesc, tblPrize.m_tblPropList );
	end
end

function UnpackCharListInfo( Buffer, item )
	item.nAccountID = Buffer:ReadUint64();

    Buffer:SetPosition( Buffer:GetPosition() - 8 );
    local nID = Buffer:ReadUint64();
    item.szAccountID = "";
    for i = 0, 9, 1 do
        local nNum = nID % 10;
		item.szAccountID = tostring( nNum ) .. item.szAccountID;
        nID = math.floor( nID / 10 );
    end

    item.szCharName = Buffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
    item.nState = Buffer:ReadUint8();
    item.nLogoutTime = Buffer:ReadUint32();
    item.nCurHeadIcon = Buffer:ReadUint16();
    item.nCurLadderStar = Buffer:ReadUint16();
	return item;
end

function UnpackCharQueryInfo( Buffer, item )
	item.nAccountID = Buffer:ReadUint64();
    item.szAccountName = Buffer:ReadUTFBytes( ACCOUNT_BYTE_SIZE + 1 );
    item.szCharName = Buffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
    item.nState = Buffer:ReadUint8();
    item.nLogoutTime = Buffer:ReadUint32();
    item.nFollowees = Buffer:ReadUint32();
    item.nFollowers = Buffer:ReadUint32();
    item.nCurHeadIcon = Buffer:ReadUint16();
end

function CAnswerSearchPlayers:OnUnpack( Buffer )
	self.nCount = Buffer:ReadUint32();
	self.tbl = {};
    for i = 0, self.nCount - 1, 1 do
	    local item = {};
		UnpackCharListInfo( Buffer, item );
        self.tbl[i] = item;
    end
end

function CAnswerSearchPlayers:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart().m_pFriendWnd:OnAnswerSearchPlayer( self.tbl, self.nCount );
end

function CFieldInfo:OnUnpack( pBuffer )
	self.m_strFieldAddress = pBuffer:ReadUTFBytes( 64 );
	self.m_nFieldPort = pBuffer:ReadUint16();
	self.m_nCheckKey = ReadUnit64String( pBuffer );
	self.m_nReconnect = pBuffer:ReadUint8();
end

function CFieldInfo:OnNetReply( Connecter, pBuffer )
	if g_App:GetFieldConn() then
		return;
	end

	local szFieldIP = self.m_strFieldAddress;
	print( "EnterField IP:"..szFieldIP.." Port:"..self.m_nFieldPort );
	local pConn = g_App:ConnectToFieldServer( szFieldIP, self.m_nFieldPort );
	pConn = ClassCast( CGameConnToFieldLua, pConn );
	pConn:SoonEnterRoom( self.m_nCheckKey );

	if self.m_nReconnect ~= 0 then
		g_App:GetWndFieldReconnectLast():ShowWnd( true );
	else
		g_App:WaitMsg( true );
	end
end

------------------CAnswerModifyCharName Begin--------------------
function CAnswerModifyCharName:Ctor()
	self.m_nResult = nil;
end

function CAnswerModifyCharName:OnPack( Buffer )

end

function CAnswerModifyCharName:OnUnpack( Buffer )
	self.m_nResult = Buffer:ReadUint8();
	self.m_szCharName =  Buffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CAnswerModifyCharName:OnNetReply( Connector, Buffer )
	if self.m_nResult == 0 then
		g_App:GetMainPlayerData().m_CharBaseData:SetNickName( self.m_szCharName );
		g_App:GetGameStart():RefreshWnd();
		local pWndAccount = g_App:GetGameStart():GetHeadWnd();
		pWndAccount:RefreshWnd();
	elseif self.m_nResult == 1 then
		g_App:HideMsg( CStringConfig.Inst():GetString( "mingzichongming" ) );
	elseif self.m_nResult == 2 then
		g_App:HideMsg( CStringConfig.Inst():GetString( "zuanshibuzu" ) );
	elseif self.m_nResult == 3 then		--第一次进入服务器本的免费改名
		g_App:HideMsg( CStringConfig.Inst():GetString( "gaimingchenggong" ) );
		g_App:GetMainPlayerData().m_CharBaseData:SetNickName( self.m_szCharName );
		g_App:GetGameStart():RefreshWnd();
	elseif self.m_nResult == 4 then		--第一次进入服务器本的免费改名重名
		g_App:HideMsg( CStringConfig.Inst():GetString( "mingzichongming" ) );
	end
	local pWndAlterName = g_App:GetGameStart():GetHeadWnd().m_pWndAlterName;
	pWndAlterName:ShowWnd( false );
	local pWndRename = g_App:GetGameStart().m_pWndRename;
	pWndRename:ShowWnd( false );
end

function CAnswerStartMatchTeam:OnUnpack( pBuffer )
end

function CAnswerStartMatchTeam:OnNetReply( Connecter, pBuffer )
    g_App:GetGameStart():GetTeamWnd( 1 ):OnStartMatch();
end

function CAnswerStopMatchTeam:OnUnpack( pBuffer )
end

function CAnswerStopMatchTeam:OnNetReply( Connecter, pBuffer )
    g_App:GetGameStart():GetTeamWnd( 1 ):OnStopMatch();
end

function CAnswerChangeHeadIcon:OnUnpack( pBuffer )
    self.m_nIndex = pBuffer:ReadUint16();
    self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerChangeHeadIcon:OnNetReply( Connecter, pBuffer )
    if self.m_nResult == 0 then
        g_App:GetMainPlayerData().m_CharBaseData:SetCurHeadIcon( self.m_nIndex );
        local Event = {};
        Event.m_Type = "ChangeHeadIcon";
        Event.m_nIndex = self.m_nIndex;
        g_App.m_EventDispatcher:DispatchEvent( Event );
    else

    end
end

---------------CAnswerBuyMusic Begin-------------
function CAnswerBuyMusic:OnUnpack( pBuffer )
	self.m_nMusicID = pBuffer:ReadUint16();
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerBuyMusic:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == 0 then
		local nMusicPlayID = math.floor( self.m_nMusicID/10 )*10 + CMusicConfig:Inst():GetMusicPlayType( self.m_nMusicID );
		g_App:HideMsg( g_App:GetString( "goumaichenggong" ) );
		g_App:SetSelectMusicID( nMusicPlayID );
		g_App:SetBGMusic( nMusicPlayID );
    else
		local nPayIndex = CMusicConfig:Inst():GetPayIndex( self.m_nMusicID );
		local str = "";
		if nPayIndex == eResourceType_Gold then
			str = "nojinbi";
		elseif nPayIndex == eResourceType_RainbowGold then
			str = "fenxiangbibuzu";
--			g_App:GetGameStart():ShortRainbowGold();
--			return;
		end
		g_App:HideMsg( g_App:GetString( str ) );
    end	
end
---------------CAnswerBuyMusic End---------------

function CSendNotice:OnUnpack( pBuffer )
    self.m_nLevel = pBuffer:ReadUint8();
    self.m_strMsg = pBuffer:ReadUTF();
end

function CSendNotice:OnNetReply( Connecter, pBuffer )
	g_App.m_NoticeBar:AddContent( self.m_strMsg, self.m_nLevel );
end


function CNotifyInvite:OnUnpack( pBuffer )
    self.nAccountID = pBuffer:ReadUint64();
    self.nTeamID = pBuffer:ReadUint64();
    self.szAccountName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
    self.nTeamType = pBuffer:ReadUint8();
	self.nRaceID = pBuffer:ReadUint8();
end

function CNotifyInvite:OnNetReply( Connecter, pBuffer )
	if self.nTeamType == eMRT_LimitRace 
		or self.nTeamType == eMRT_TeamRace
		or self.nTeamType == eMRT_TeamRaceBefore then
		g_App:GetGameStart().m_pWndRace.m_pWndConfirmInvite:InitData( self );
	else
		g_App:GetGameStart():OnInvite( self.nAccountID, self.nTeamID, self.szAccountName, self.nTeamType );
    end
end

function CAnswerInvite:OnUnpack( pBuffer )
    self.nAccountID = pBuffer:ReadUint64();
    self.nResult = pBuffer:ReadUint8();
end

function CAnswerInvite:OnNetReply( Connecter, pBuffer )
    if self.nResult > 0 then
	    g_App:HideMsg( CStringConfig.Inst():GetString( "yaoqingshibai" ) );
    else
	    g_App:HideMsg( CStringConfig.Inst():GetString( "fasongyaoqing" ) );
    end
end

function CNotifyRefuseInvite:OnUnpack( pBuffer )
    self.szAccountName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CNotifyRefuseInvite:OnNetReply( Connecter, pBuffer )
    g_App:HideMsg( string.format( CStringConfig.Inst():GetString( "jujueyaoqing" ), self.szAccountName ) );
end

function CAnswerJoinGame:OnUnpack( pBuffer )
    self.nAccountID = pBuffer:ReadUint64();
    self.nTeamID = pBuffer:ReadUint64();
    self.nResult = pBuffer:ReadUint8();
end

function CAnswerJoinGame:OnNetReply( Connecter, pBuffer )
    if self.nResult > 0 then
	    g_App:HideMsg( CStringConfig.Inst():GetString( "jiarushibai" ) );
    end
end

function CNotifyBalanceFinished:OnUnpack( pBuffer )
	print( "11111111111 CNotifyBalanceFinished:OnUnpack( pBuffer )" );
	
	self.m_nSettlementType = pBuffer:ReadUint8();
	-- 加1是因为客户端table是1开头的
	self.m_nTeamRank = pBuffer:ReadUint32() + 1;
	self.m_nPlayerRank = pBuffer:ReadUint32() + 1;
	self.m_bIsObserver = pBuffer:ReadBoolean();
	self.m_nOldStar = pBuffer:ReadUint32();
	self.m_nNewestStar = pBuffer:ReadUint32();
	self.m_nMaxCoin = pBuffer:ReadUint32();
	self.m_nRunTime = pBuffer:ReadUint32();
	self.m_structScore = UnpackStruScore( pBuffer );
	self.m_sRhythmData = UnpackRhythmData( pBuffer );
	
	local nBattleInfoCount = pBuffer:ReadUint32();
	self.m_nSettlementTeamCount = pBuffer:ReadUint32();

	self.m_tblBattleInfo = {};
	for i = 1, nBattleInfoCount do
		local tbl = {};
		tbl["m_szKillerNickName"]	= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
		tbl["m_szDeaderNickName"]	= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
		tbl["m_nKillerEquipID"]		= pBuffer:ReadUint16();
		tbl["m_nDeaderEquipID"]		= pBuffer:ReadUint16();
		tbl["m_nCount"]				= pBuffer:ReadUint16();
		tbl["m_nKillerAccountID"]	= pBuffer:ReadUint64();
		tbl["m_nDeaderAccountID"]	= pBuffer:ReadUint64();
		tbl["m_nKillerObjectID"]	= pBuffer:ReadUint16();
		tbl["m_nDeaderObjectID"]	= pBuffer:ReadUint16();
		table.insert( self.m_tblBattleInfo, tbl );
	end
	
	local nRealPlayerCount = 0;
	local nRealPlayerTotalLadderStar = 0;
	self.m_tblSettlementTeam = {};
	self.m_nPlayerCount = 0;
	for i = 1, self.m_nSettlementTeamCount do
		local nCount = pBuffer:ReadUint32();
		local tblPlayers = {};
		for n = 1, nCount do
			local playerInfo = {};
			playerInfo.m_nAccountID		= pBuffer:ReadUint64();
			playerInfo.m_szNickName		= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
			playerInfo.m_nObjectID		= pBuffer:ReadUint16();
			playerInfo.m_nEquipID		= pBuffer:ReadUint16();
			playerInfo.m_nHeadIconID	= pBuffer:ReadUint16();
			playerInfo.m_nLadderStar	= pBuffer:ReadUint32();
			playerInfo.m_nAllScore		= pBuffer:ReadUint32();
			table.insert( tblPlayers, playerInfo );
			self.m_nPlayerCount = self.m_nPlayerCount + 1;

			-- 获得真实玩家的段位总数
			if playerInfo.m_nAccountID ~= 0 then
				nRealPlayerCount = nRealPlayerCount + 1;
				nRealPlayerTotalLadderStar = nRealPlayerTotalLadderStar + playerInfo.m_nLadderStar;
			end
		end
		table.insert( self.m_tblSettlementTeam, tblPlayers );
	end

	-- 给ai随机段位
	if nRealPlayerCount ~= 0 then
		local nAvgLadderStar = math.ceil( nRealPlayerTotalLadderStar / nRealPlayerCount );
		for _, tblPlayers in pairs( self.m_tblSettlementTeam ) do
			for _, playerInfo in pairs( tblPlayers ) do
				if playerInfo.m_nAccountID == 0 then
					local nVirtualLadderStar = nAvgLadderStar + math.random( -10, 10 );
					if nVirtualLadderStar < 0 then
						nVirtualLadderStar = 0;
					end
					playerInfo.m_nLadderStar = nVirtualLadderStar;
				end
			end
		end
	end
end

function CNotifyBalanceFinished:OnNetReply( Connecter, pBuffer )
	local pScene = g_App:GetScene();
	if not pScene then
		return g_App:SwitchStart();
	end

	local pGameMain = g_App:GetGameMain();
	local pWanfa = pScene:GetWanfa();
	pWanfa:MarkExitRoom();
	pScene:Close();
	pGameMain:RoomOver();

	-- 播放结算音效
	if self.m_nSettlementType == eSettlementType_CurShort then
		pGameMain:PlaySound( CGameMainLua.eSound_GameOver );
	else
		pGameMain:PlaySound( CGameMainLua.eSound_GameEnd );
	end
	
	if g_App:GetFieldConn() then
		g_App:GetFieldConn().m_pExit = true;
		g_App:GetFieldConn():ShellCmdClose();
	end
	if not pWanfa then
		return g_App:SwitchStart();
	end
	
	local pGoldMsg = pWanfa.m_pWndBalance:GetDlgChild( "bg_jinbitishi" );
	local pBtnShowTips = pWanfa.m_pWndBalance:GetDlgChild( "bg_jinbitishi.tips" );
	pBtnShowTips:ShowWnd( false );
	pGoldMsg:SetWndText( "" );
	if self.m_nMaxCoin ~= 0xffffffff then
		pGoldMsg:SetWndText( string.format( g_App:GetString( "jinbishangxianall" ), 
			self.m_nMaxCoin, g_App:GetAccumulateObtainGold() ));
		pBtnShowTips:ShowWnd( true );
	end

	-- 刷新结算界面
	pWanfa:UpdateGameInsideResult( self.m_structScore.nAllScore );
	pWanfa:Settlement(
		self.m_nSettlementType,
		self.m_bIsObserver,
		self.m_structScore,
		self.m_sRhythmData,
		self.m_nTeamRank,
		self.m_nPlayerRank,
		self.m_tblSettlementTeam,
		self.m_tblBattleInfo,
		self.m_nOldStar,
		self.m_nNewestStar,
		self.m_nRunTime
	);

	if self.m_bIsObserver then
		return;
	end

	if pScene:GetRoomType() == eRT_LimitRace then
		local nIndex = self.m_nPlayerCount * 100 + self.m_nTeamRank;
		local RankConfig = g_tblTabFile.race_rankprize[nIndex];
		local nPrizeNum = RankConfig.nPrizeNum;
		g_App:GetGameStart().m_bShowRacePrize = true;
		g_App:GetGameStart().m_tblRacePrize = {};
		for i = 1, nPrizeNum do
			local tblPrize = {};
			tblPrize.nType = RankConfig["nPrizeType"..i];
			tblPrize.nIndex = RankConfig["nPrizeIndex"..i];
			tblPrize.nCount = RankConfig["nPrizeValue"..i];
			table.insert( g_App:GetGameStart().m_tblRacePrize, tblPrize );
		end
	elseif pScene:GetRoomType() == eRT_TeamRace then
		local nIndex = self.m_nTeamRank * 10 + self.m_nPlayerRank;
		local RankConfig = g_tblTabFile.race_rankprize[nIndex];
		local nPrizeNum = RankConfig.nPrizeNum;
		g_App:GetGameStart().m_bShowRacePrize = true;
		g_App:GetGameStart().m_tblRacePrize = {};
		for i = 1, nPrizeNum do
			local tblPrize = {};
			tblPrize.nType = RankConfig["nPrizeType"..i];
			tblPrize.nIndex = RankConfig["nPrizeIndex"..i];
			tblPrize.nCount = RankConfig["nPrizeValue"..i];
			table.insert( g_App:GetGameStart().m_tblRacePrize, tblPrize );
		end
	end
end

function CAnswerActivateCode:OnUnpack( pBuffer )
    self.nError = pBuffer:ReadInt32();
    self.nItemCount = pBuffer:ReadUint32();
    self.items ={};
    for i = 1, self.nItemCount, 1 do
        local item = {};
        self.items[i] = item;
        item.m_nType = pBuffer:ReadUint32();
        item.m_nTypeIndex = pBuffer:ReadUint32();
        item.m_nCount = pBuffer:ReadUint32();
    end
end

function CAnswerActivateCode:OnNetReply( Connecter, pBuffer )
    if self.nError == 1 then
	    g_App:MessageBox( g_App:GetString( "lipinmayouwu" ) );
    elseif self.nError == 2 then
	    g_App:MessageBox( g_App:GetString( "lipinmabuzaiyouxiaoqi" ) );
    elseif self.nError == 3 then
	    g_App:MessageBox( g_App:GetString( "lipinmadaoshangxian" ) );
    elseif self.nError == 4 then
	    g_App:MessageBox( g_App:GetString( "lipinmayishiyong" ) );
    elseif self.nError == 5 then
	    g_App:MessageBox( g_App:GetString( "lipinyiman" ) );
    else
		g_App:GetGameStart():NotifyPrizeTip( self.items );
    end
end

function CRequestRoomFaild:OnUnpack( pBuffer )
	self.m_nFaildType = pBuffer:ReadUint8();
end

function CRequestRoomFaild:OnNetReply( Connecter, pBuffer )
	g_App:WaitMsg( false );

	local szBuffer = "";
	if self.m_nFaildType == eRRF_ScoreLack then
		local PlayerData = g_App:GetMainPlayerData().m_CharBaseData;
		local nCurAllGameScore = PlayerData:GetAllGameScore();
		szBuffer = g_App:GetString( "jifenbugou" ).." "..nCurAllGameScore
		.." / "..CSnakeConstant:Inst():GetStartLimitSchema();
	elseif self.m_nFaildType == eRRF_NotFindServer then
		szBuffer = g_App:GetString( "fuwuqibucunzai" );
	elseif self.m_nFaildType == eRRF_RoomExist then
		szBuffer = g_App:GetString( "fangjiancunzai" );
	end

	g_App:MessageBox( szBuffer );
end

function CEndlessDataFinish:OnUnpack( pBuffer )
	self.m_nDayLimit = pBuffer:ReadUint8();
	self.m_nMaxCoin = pBuffer:ReadUint32();
end

function CEndlessDataFinish:OnNetReply( Connecter, pBuffer )
	if not g_App:GetScene() then
		return;
	end

	local nCurGameScore = g_App:GetMainPlayerData().m_CharBaseData:GetAllGameScore();
	local pWndBalance = g_App:GetScene():GetWanfa().m_pWndBalance;
	local pGoldMsg = pWndBalance:GetDlgChild( "bg_jinbitishi" );
	local pBtnShowTips = pWndBalance:GetDlgChild( "bg_jinbitishi.tips" );
	pBtnShowTips:ShowWnd( false );
	if self.m_nDayLimit == 0 then
		pGoldMsg:SetWndText( "" );
		return;
	end

	pBtnShowTips:ShowWnd( true );
	if self.m_nDayLimit == 2 then
		pGoldMsg:SetWndText( string.format( g_App:GetString( "jinbishangxianwujin" ), 
			self.m_nMaxCoin, self.m_nMaxCoin ) );
	else
		pGoldMsg:SetWndText( string.format( g_App:GetString( "jinbishangxianall" ), 
			self.m_nMaxCoin, g_App:GetAccumulateObtainGold() ) );
	end
end

function CAnswerQueryPlayerBaseData:OnUnpack( pBuffer )
	self.m_tblData = {};
	self.m_tblData["szName"]			= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	self.m_tblData["nHeadIcon"]			= pBuffer:ReadUint16();
	self.m_tblData["nBeCommendCount"]	= pBuffer:ReadUint32();
	self.m_tblData["nLadderStarCount"]	= pBuffer:ReadUint32();
	self.m_tblData["nOnLineStatus"]		= pBuffer:ReadUint8(); 
	self.m_tblData["nSex"]				= pBuffer:ReadUint8();
	self.m_tblData["nAge"]				= pBuffer:ReadUint8();
	self.m_tblData["nConstellation"]	= pBuffer:ReadUint8();
	self.m_tblData["nArea"]				= pBuffer:ReadUint8();
	self.m_tblData["szSignature"]		= pBuffer:ReadUTFBytes( Char_Signature_Byte_Size + 1 );
end

function CAnswerQueryPlayerBaseData:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "PlayerBaseData";
	Event.m_Param = self.m_tblData;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerBuySkin:OnUnpack( pBuffer )
	self.m_nSkinID = pBuffer:ReadUint16();
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerBuySkin:OnNetReply( Connecter, pBuffer )
	print( "--------------------CAnswerBuySkin:OnNetReply--------------SkinID:", self.m_nSkinID, "----Result:", self.m_nResult );
	if self.m_nResult == 1 then
		g_App:HideMsg( string.format( CStringConfig.Inst():GetString( "pifu_goumaichenggong" ), g_tblTabFile.equip[self.m_nSkinID].dName ) );
	elseif self.m_nResult == 100 then
		local nPayIndex = g_tblTabFile.equip[self.m_nSkinID].nPayIndex;
		local str = "";
		if nPayIndex == eResourceType_Gold then
			str = "nojinbi";
		elseif nPayIndex == eResourceType_RainbowGold then
			str = "fenxiangbibuzu";
--			g_App:GetGameStart():ShortRainbowGold();
--			return;
		end
		g_App:HideMsg( g_App:GetString( str ) );	
	end
end

function CNotifyBeAttention:OnUnpack( pBuffer )
	self.m_szName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CNotifyBeAttention:OnNetReply( Connecter, pBuffer )
	g_App:HideMsg( string.format( g_App:GetString( "youguanzhu" ), self.m_szName ) );
end

function CNotifyBeCommend:OnUnpack( pBuffer )
	self.m_szName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CNotifyBeCommend:OnNetReply( Connecter, pBuffer )	
	if g_App:GetGameMain():IsShow() then
        g_App:GetGameMain():OnDianzan( string.format( g_App:GetString( "youdianzan" ), self.m_szName ) );
	else
		g_App:GetBeCommendWnd():ShowInfo( string.format( g_App:GetString( "youdianzan" ), self.m_szName ) );
	end
end

function CAnswerCheckRoomExit:OnUnpack( pBuffer )
end

function CAnswerCheckRoomExit:OnNetReply( Connecter, pBuffer )
	g_App:WaitMsg( false );
end

function CAnswerGetAllRecordNew:OnUnpack( pBuffer )
	local nBeginPos = pBuffer:GetPosition();
	self.m_tblRecordNew = {};
	for i = 0, All_GRADE_RECORD_COLUMN -1 do 
		local tbl = {};
		tbl.nAllScore	= pBuffer:ReadUint32();
		tbl.nAreaScore	= pBuffer:ReadUint32();
		tbl.nKillScore	= pBuffer:ReadUint32();
		tbl.nMaxCombo	= pBuffer:ReadUint32();
		table.insert( self.m_tblRecordNew, tbl );
	end

	self.m_tblRecordNew["nEndlessTimeToday"] = pBuffer:ReadUint32();
	self.m_tblRecordNew["nEndlessTimeWeek"] = pBuffer:ReadUint32();
	self.m_tblRecordNew["nEndlessTimeHistory"] = pBuffer:ReadUint32();
	self.m_tblRecordNew["nRaceScoreDay"] = pBuffer:ReadUint32();
	self.m_tblRecordNew["nRaceScoreWeek"] = pBuffer:ReadUint32();

	pBuffer:SetPosition( nBeginPos );
	for i = 1, 3 do
		local tbl = {};
		tbl.EndlessAllScore = pBuffer:ReadUint32();
		tbl.EndlessAreaScore = pBuffer:ReadUint32();
		tbl.EndlessKillCount = pBuffer:ReadUint32();
		tbl.EndlessMaxCombo = pBuffer:ReadUint32();
		tbl.LimitAllScore = pBuffer:ReadUint32();
		tbl.LimitAreaScore = pBuffer:ReadUint32();
		tbl.LimitKillCount = pBuffer:ReadUint32();
		tbl.LimitMaxCombo = pBuffer:ReadUint32();
		tbl.TeamAllScore = pBuffer:ReadUint32();
		tbl.TeamAreaScore = pBuffer:ReadUint32();
		tbl.TeamKillCount = pBuffer:ReadUint32();
		tbl.TeamMaxCombo = pBuffer:ReadUint32();
		if i == 1 then
			self.m_tblRecordNew["TodayData"] = tbl;
		elseif i == 2 then
			self.m_tblRecordNew["WeekData"] = tbl;
		elseif i == 3 then
			self.m_tblRecordNew["HistoryData"] = tbl;
		end
	end	
end

function CAnswerGetAllRecordNew:OnNetReply( Connecter, pBuffer )
	CPlayerGradeInfoMgr:Instance():SetAllDataNew( self.m_tblRecordNew );
	local Event = {};
    Event.m_Type = "PlayerGradeRecordNew";
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerBuyrhythmNoticeBar:OnUnpack( pBuffer )
	self.m_nIndex = pBuffer:ReadUint8();
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerBuyrhythmNoticeBar:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == 100 then
		local nPayIndex = g_tblTabFile.jiezoutishiqi[self.m_nIndex].nPayIndex;
		local str = "";
		if nPayIndex == eResourceType_Gold then
			str = "nojinbi";
		elseif nPayIndex == eResourceType_RainbowGold then
			str = "fenxiangbibuzu";
		end
		g_App:HideMsg( g_App:GetString( str ) );
		return;
	end

	local szName =  g_tblTabFile.jiezoutishiqi[self.m_nIndex].dName;
	g_App:HideMsg( string.format( g_App:GetString( "jiezougoumaichenggong" ), szName ) );
	local Event = {};
	Event.m_Type = "AnswerBuyRhythmNoticeBar";
	Event.m_Param = self.m_nIndex;
	g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerBuyBattleFace:OnUnpack( pBuffer )
	self.m_nIndex = pBuffer:ReadUint8();
	self.m_nResult = pBuffer:ReadUint8();
	self.m_nCauseIndex = pBuffer:ReadUint8();
end

function CAnswerBuyBattleFace:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == 100 then
		local nPayIndex = g_tblTabFile.battleface[self.m_nIndex].nPayIndex;
		local str = "";
		if nPayIndex == eResourceType_Gold then
			str = "nojinbi";
		elseif nPayIndex == eResourceType_RainbowGold then
			str = "fenxiangbibuzu";
		end
		g_App:HideMsg( g_App:GetString( str ) );
		return;
	end

	local szName = g_tblTabFile.battleface[self.m_nIndex].dName;
	g_App:HideMsg( string.format(g_App:GetString( "biaoqinggoumaichenggong" ), szName ) );
end

function CAnswerObserveGame:OnUnpack( pBuffer )
    self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerObserveGame:OnNetReply( Connecter, pBuffer )
    if self.m_nResult > 0 then
		if self.m_nResult == 10 then	--赛事观战失败   
			g_App:HideMsg( g_App:GetString( "guanzhanshibai" ) );
		else
			g_App:HideMsg( g_App:GetString( "guanzhantips" ) );
		end
        g_App:WaitMsg( false );
    end
end

function CAnswerRainbowGold:OnUnpack( pBuffer )
end

function CAnswerRainbowGold:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "UpdateRainbowGold";
	Event.RainbowGoldDay = pBuffer:ReadUint32();
	Event.RainbowGoldHistory = pBuffer:ReadUint32();
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnwerAccelerateTreasureBox:OnUnpack( pBuffer )
	self.m_nTreasureBoxID = pBuffer:ReadUint32();
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnwerAccelerateTreasureBox:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == 100 then
		local nPayIndex = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nConsumeIndex;
		local str = "";
		if nPayIndex == eResourceType_Gold then
			str = "nojinbi";
		elseif nPayIndex == eResourceType_RainbowGold then
			str = "fenxiangbibuzu";
		elseif nPayIndex == eResourceType_Diamond or nPayIndex == eResourceType_PresentDiamond then
			str = "zuanshibuzu";
		end
		g_App:HideMsg( g_App:GetString( str ) );
	end
end

function CNotifyNewTreasureBox:OnUnpack( pBuffer )
	self.m_nNewTreasureBoxID = pBuffer:ReadUint32();
	self.m_nNewTreasureBoxType = pBuffer:ReadUint8();
end

function CNotifyNewTreasureBox:OnNetReply( Connecter, pBuffer )
	g_App.m_nNewTreasureBoxID = self.m_nNewTreasureBoxID;
	g_App.m_nNewTreasureBoxType = self.m_nNewTreasureBoxType;
end

function CAnswerFusion:OnUnpack( pBuffer )
	self.m_nFusionID = pBuffer:ReadUint32();
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerFusion:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == 1 then --合成成功
		print( "-----------Fusion Skin Success----------------------" );  
		local Event = {};
		Event.m_Type = "FusionSuccess";
		Event.m_nFusionID = self.m_nFusionID
		g_App.m_EventDispatcher:DispatchEvent( Event );
		return;
	end

	local str = "";
	if self.m_nResult == 2  then --碎片不足 
		str = "cailiaobuzu";
	elseif self.m_nResult == 3 then --金币不足  
		str = "nojinbi";
	elseif self.m_nResult == 4 then --分享币不足
		str = "fenxiangbibuzu";
	end
	g_App:HideMsg( g_App:GetString( str ) );
end

function CGetFragment:OnUnpack( pBuffer )
	self.m_nTreasureBoxID = pBuffer:ReadUint32();
	self.m_nExpAdd = pBuffer:ReadUint32();
	self.m_nPosIndex = pBuffer:ReadUint32();
	self.m_nDataCount = pBuffer:ReadUint8();

	self.m_tblProp = {};
    for i = 1, self.m_nDataCount do
        local Prop = {};
		Prop.nType = pBuffer:ReadUint8();
		Prop.nIndex = pBuffer:ReadUint32();
		Prop.nCount = pBuffer:ReadUint32();
		table.insert( self.m_tblProp, Prop );
    end
end

function CGetFragment:OnNetReply( Connecter, pBuffer )
	print( "-------------Get Fragment By OpenTreasureBox!!------,Fragment KindCount is", self.m_nDataCount );
	local Event = {};
    Event.m_Type = "TreasureBoxOpened";
	Event.m_Data = self.m_tblProp;
	Event.m_nTreasureBoxID = self.m_nTreasureBoxID;
	Event.m_nExpAdd = self.m_nExpAdd;
	Event.m_nPosIndex = self.m_nPosIndex;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerCheckEnterRoom:OnUnpack( pBuffer )
	self.m_nRoomType = pBuffer:ReadUint8();
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerCheckEnterRoom:OnNetReply( Connecter, pBuffer )
	if self.m_nRoomType == eRT_LimitTime then
		local nEndlessGameScore = g_App:GetGameScore( eRT_Endless );
		local nEndlessSceneNodeTotal = g_GetSceneNodeTotal( eRT_Endless );
		local nLimitModeOpenRatio = CSnakeConstant:Inst():Getxianshijiesuomianji()/10000;
		if self.m_nResult == 1 then
			g_App:GetGameStart().m_WndModelOpenLimit:ShowWndByType( self.m_nRoomType, nEndlessGameScore, nEndlessSceneNodeTotal * nLimitModeOpenRatio );
			return
		else
			if g_App:IsGameSwitch( eGameSwitch_Rename ) and not g_App:GetFirstEvent( eFE_Rename ) then
				g_App:GetGameStart().m_pWndRename:ShowWnd( true );
			elseif g_App:GetIniFile():GetInteger( "Setting", "LimitTip", 1 ) == 1 
				and g_App:GetGameScore( eRT_LimitTime ) < CSnakeConstant:Inst():Gettuanzhanjiesuofenshu() then
				g_App:GetGameStart().m_pWndLimitTip:ShowWnd( true );
			else
				g_App:GetGameStart():EnterRoom();
			end
		end

	elseif self.m_nRoomType == eRT_Team then
		local nLimitGameScore = g_App:GetGameScore( eRT_LimitTime );
		local nTeamOpenScore = CSnakeConstant:Inst():Gettuanzhanjiesuofenshu();
		if self.m_nResult == 1 then
			g_App:GetGameStart().m_WndModelOpenLimit:ShowWndByType( eRT_Team, nLimitGameScore, nTeamOpenScore );
			return
		else 
			if g_App:IsGameSwitch( eGameSwitch_Rename ) and not g_App:GetFirstEvent( eFE_Rename ) then
				g_App:GetGameStart().m_pWndRename:ShowWnd( true );
			elseif g_App:GetIniFile():GetInteger( "Setting", "TeamTip", 1 ) == 1 
				and g_App:GetGameScore( eRT_Team ) < CSnakeConstant:Inst():Gettuanzhantishifenshu() then
				g_App:GetGameStart().m_pWndTeamTip:ShowWnd( true );
			else
				g_App:GetGameStart():EnterRoom();
			end
		end
	end
end

function CAnswerUnlockTreasureBox:OnUnpack( pBuffer )
	self.m_tblData = {};
	self.m_tblData.m_nTreasureBoxID = pBuffer:ReadUint32();
	self.m_tblData.m_nTreasureBoxGetTime = pBuffer:ReadUint32();
	self.m_tblData.m_nPosIndex = pBuffer:ReadUint32();
--	self.m_tblData.m_nTreasureBoxUnlockTime = pBuffer:ReadUint32();
end

function CAnswerUnlockTreasureBox:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "DuringAccelerateTreasureBox";
    Event.m_Data = self.m_tblData;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CNotifyQueryChangeMatchPos:OnUnpack( pBuffer )
	self.nTeamID = pBuffer:ReadUint64();
    self.nRequestAccountID = pBuffer:ReadUint64();
    self.nRequestPos = pBuffer:ReadUint8();
    self.nResponsePos = pBuffer:ReadUint8();
	self.szRequestName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 ); 
end

function CNotifyQueryChangeMatchPos:OnNetReply( Connecter, pBuffer )	
	g_App:MessageBox( string.format( g_App:GetString( "sirenfangjiantips1" ), self.szRequestName ),
		{
		[CMessageBox.Close] = function()
	        g_App.m_pMessageBox:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local NetMsg = CAnswerChangeMatchPos:new();
			NetMsg.nTeamID = self.nTeamID;
			NetMsg.nRequestAccountID = self.nRequestAccountID;
			NetMsg.nRequestPos = self.nRequestPos;
			NetMsg.nResponsePos = self.nResponsePos;
			NetMsg.bAgree = false;
			pConn:SendShellMsg( NetMsg );
		end;
		[CMessageBox.OK] = function()
	        g_App.m_pMessageBox:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local NetMsg = CAnswerChangeMatchPos:new();
			NetMsg.nTeamID = self.nTeamID;
			NetMsg.nRequestAccountID = self.nRequestAccountID;
			NetMsg.nRequestPos = self.nRequestPos;
			NetMsg.nResponsePos = self.nResponsePos;
			NetMsg.bAgree = true;
			pConn:SendShellMsg( NetMsg );
		end;
		} );
end

function CNotifyAnswerChangeMatchPos:OnUnpack( pBuffer )
	self.bAgree = pBuffer:ReadBoolean();
	self.szResponseName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 ); 
end

function CNotifyAnswerChangeMatchPos:OnNetReply( Connecter, pBuffer )
	if not self.bAgree then
		g_App:HideMsg( string.format( g_App:GetString( "sirenfangjiantips2" ), self.szResponseName) );
	end
end

function CNotifyChangeMatchPos:OnUnpack( pBuffer )
	self.nTeamID = pBuffer:ReadUint64();
    self.nType = pBuffer:ReadUint8();
    self.nRequestPos = pBuffer:ReadUint8();
    self.nResponsePos = pBuffer:ReadUint8();
end

function CNotifyChangeMatchPos:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart():GetTeamWnd( self.nType ).m_pTeamSecretMatchWnd:ChangePos( self.nRequestPos, self.nResponsePos );
end

function CNotifyRoomMatchMsg:OnUnpack( pBuffer )
	self.nType = pBuffer:ReadUint8();
	self.nRoomType = pBuffer:ReadUint8();
end

function CNotifyRoomMatchMsg:OnNetReply( Connecter, pBuffer )
	if self.nType == eRMM_BeKicked then
		g_App:SwitchStart();
		g_App:HideMsg( CStringConfig.Inst():GetString( "beitichufangjian" ) );
		if self.nRoomType == eMRT_TeamRaceBefore then
			local NetMsgMusic = CSetMusic:new();
			NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
			g_App:SendShellMsg( NetMsgMusic );
				
			local NetMsg = CCreateTeam:new();
			NetMsg.nType = eMRT_TeamRaceBefore;
			g_App:SendShellMsg( NetMsg );
		end
	elseif self.nType == eRMM_ShouldReady then
		g_App:HideMsg( CStringConfig.Inst():GetString( "cuicuzhunbei" ) );
	end
end

function CNotAllReady:OnUnpack( pBuffer )
	self.nType = pBuffer:ReadUint8();
end

function CNotAllReady:OnNetReply( Connecter, pBuffer )
	local str = "";
	if self.nType == eMRFS_NotReady then
		str = CStringConfig.Inst():GetString( "sirenfangjiantips5" );  
	elseif self.nType == eMRFS_NumLess then
		str = CStringConfig.Inst():GetString( "sirenfangjiantips0" );
	end
	g_App:WaitMsg( false );
	g_App:HideMsg( str );
end

function COnWorldConnect:OnUnpack( pBuffer )
	self.m_tblDeclaration = {};

	local nDeclaration = pBuffer:ReadUint8();
	for i = 1, nDeclaration do
		local tblDeclaration = {};
		local nTitleSize = pBuffer:ReadUint16();
		local nContentSize = pBuffer:ReadUint16();
		local nImageUrlSize = pBuffer:ReadUint16();
		local nImageMD5Size = pBuffer:ReadUint16();

		tblDeclaration.szTitle = pBuffer:ReadUTFBytes( nTitleSize );
		tblDeclaration.szContent = pBuffer:ReadUTFBytes( nContentSize );
		tblDeclaration.szImageUrl = pBuffer:ReadUTFBytes( nImageUrlSize );
		tblDeclaration.szImageMD5 = pBuffer:ReadUTFBytes( nImageMD5Size );
		table.insert( self.m_tblDeclaration, tblDeclaration );
	end
end

function COnWorldConnect:OnNetReply( Connecter, pBuffer )
	g_App:WaitMsg( false );

	local funcLogin = function() 
		g_App:GetLoginFrame():Login(); 
		g_App.m_pWndLoginDeclaration:ShowWnd( false );
	end;

	if #self.m_tblDeclaration == 0 then
		funcLogin();
	else
		g_App.m_pWndLoginDeclaration:RefreshWnd( self.m_tblDeclaration, funcLogin );
		g_App.m_pWndLoginDeclaration:ShowWnd( true );
		print( "Declaration : "..#self.m_tblDeclaration );
	end
end

function CAnswerDeclaration:OnUnpack( pBuffer )
	self.m_tblDeclaration = {};

	local nDeclaration = pBuffer:ReadUint8();
	for i = 1, nDeclaration do
		local tblDeclaration = {};
		local nTitleSize = pBuffer:ReadUint16();
		local nContentSize = pBuffer:ReadUint16();
		local nImageUrlSize = pBuffer:ReadUint16();
		local nImageMD5Size = pBuffer:ReadUint16();

		tblDeclaration.szTitle = pBuffer:ReadUTFBytes( nTitleSize );
		tblDeclaration.szContent = pBuffer:ReadUTFBytes( nContentSize );
		tblDeclaration.szImageUrl = pBuffer:ReadUTFBytes( nImageUrlSize );
		tblDeclaration.szImageMD5 = pBuffer:ReadUTFBytes( nImageMD5Size );
		table.insert( self.m_tblDeclaration, tblDeclaration );
	end
end

function CAnswerDeclaration:OnNetReply( Connecter, pBuffer )
	local func =  function()
		-- 不需要提示，所以先判断返回
		if not g_App:IsGameSwitch( eGameSwitch_SpecialOffer ) then
			return;
		end
		g_App:GetGameStart():OpenSpecialOffer();
	end;

	if #self.m_tblDeclaration == 0 then
		func();
		return;
	end
	g_App.m_pWndGameMainDeclaration:RefreshWnd( self.m_tblDeclaration, func );
	g_App.m_pWndGameMainDeclaration:ShowWnd( true );
end

function CAnswerSignInActivityState:OnUnpack( pBuffer )
	self.nCurDayStamp = pBuffer:ReadUint32();
	self.nSignInValue = pBuffer:ReadUint32();
	self.nSignInFlag = pBuffer:ReadUint8();
	self.bFirstLogin = pBuffer:ReadBoolean();
end

function CAnswerSignInActivityState:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart().m_bCanSignIn = self.nSignInFlag == 0;
	g_App:GetGameStart().m_pWndActivity.m_pWndSignIn:SetSignInData( self.nSignInFlag, self.nSignInValue, self.nCurDayStamp );
	g_App:GetGameStart().m_pWndActivity.m_pWndSignIn:ReFreshWnd();
	g_App:GetGameStart().m_pWndActivity.m_pWndSignIn.m_pBtnSignIn:EnableWnd( g_App:GetGameStart().m_bCanSignIn );
	print( "1111111111111 CAnswerActivityState:", "self.nCurDayStamp "..self.nCurDayStamp, "self.nSignInValue "..self.nSignInValue, "self.nSignInFlag "..self.nSignInFlag, "self.bFirstLogin ", self.bFirstLogin );
	
	print( "44444444 CAnswerSignInActivityState:OnNetReply", g_App:GetGameStart().m_bCanRoll, g_App:GetGameStart().m_bCanSignIn, g_App:GetGameStart().m_bCanRoll or g_App:GetGameStart().m_bCanSignIn, self.nSignInFlag );
	g_App:GetGameStart().m_btnTask:ShowRedPoint( g_App:GetGameStart().m_bCanRoll or g_App:GetGameStart().m_bCanSignIn );
	if g_App:GetGameStart().m_pWndActivity.m_pWndSignInRed then
		g_App:GetGameStart().m_pWndActivity.m_pWndSignInRed:ShowWnd( g_App:GetGameStart().m_bCanSignIn );
	end
	if self.bFirstLogin then
		g_App:GetGameStart().m_pWndActivity:ShowWnd( true );
	end
end

function CAnswerRollActivityState:OnUnpack( pBuffer )
	self.nRollIndex = pBuffer:ReadUint8();
	self.bCanRoll = pBuffer:ReadBoolean();
	self.nLeftTimes = pBuffer:ReadUint8();
end

function CAnswerRollActivityState:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart().m_bCanRoll = self.bCanRoll;
	print( "3333333 CAnswerRollActivityState:OnNetReply", g_App:GetGameStart().m_bCanRoll, g_App:GetGameStart().m_bCanSignIn, g_App:GetGameStart().m_bCanRoll or g_App:GetGameStart().m_bCanSignIn, self.bCanRoll, self.nRollIndex );
	g_App:GetGameStart().m_pWndActivity.m_pWndRoll:SetRollPrizeIndex( self.nRollIndex, self.nLeftTimes );
	g_App:GetGameStart().m_pWndActivity.m_pWndRoll.m_pBtnRoll:EnableWnd( self.bCanRoll );
	g_App:GetGameStart().m_btnTask:ShowRedPoint( g_App:GetGameStart().m_bCanRoll or g_App:GetGameStart().m_bCanSignIn );
	if g_App:GetGameStart().m_pWndActivity.m_pWndRollRed then
		g_App:GetGameStart().m_pWndActivity.m_pWndRollRed:ShowWnd( g_App:GetGameStart().m_bCanRoll );
	end
end


function CSignInActivityResult:OnUnpack( pBuffer )
	self.nCurDayStamp = pBuffer:ReadUint32();
	self.bSucc = pBuffer:ReadBoolean();
end

function CSignInActivityResult:OnNetReply( Connecter, pBuffer )
	if self.bSucc then		--签到成功
		g_App:GetGameStart().m_pWndActivity.m_pWndSignIn:ShowSignInPrize();
	else
		g_App:HideMsg( CStringConfig:Inst():GetString( "qiandaotips" ) );
	end
end

function CRollActivityResult:OnUnpack( pBuffer )
	self.bCanRollTime = pBuffer:ReadBoolean();
	self.bCanRollNum = pBuffer:ReadBoolean();
	self.nPrizePos = pBuffer:ReadUint16();
	self.nPrizeIndex = pBuffer:ReadUint8();
	self.nLeftTimes = pBuffer:ReadUint8();
end

function CRollActivityResult:OnNetReply( Connecter, pBuffer )
	print( "2222222222 CRollActivityResult", self.bCanRollTime, self.bCanRollNum, self.nPrizePos, self.nPrizeIndex, self.nLeftTimes );
	if not self.bCanRollTime then
		g_App:HideMsg( CStringConfig:Inst():GetString( "choujiangtips1" ) );
		return;
	end
	if not self.bCanRollNum then
		g_App:HideMsg( CStringConfig:Inst():GetString( "choujiangtips2" ) );
		return;
	end
	g_App:GetGameStart().m_pWndActivity.m_pWndRoll:SetRollPrize( self.nPrizeIndex, self.nPrizePos, self.nLeftTimes );
end

function CAnswerGMAddProp:OnUnpack( pBuffer )
	self.m_nBigID	= pBuffer:ReadUint8();
	self.m_nSmallID	= pBuffer:ReadUint32();
	self.m_nCount	= pBuffer:ReadUint32();
end

function CAnswerGMAddProp:OnNetReply( Connecter, pBuffer )
	local str = g_App:GetString( "lipinmatishi1" );
	if self.m_nBigID == 0 then
		str = str .. " " .. tostring( self.m_nCount ) .. g_tblTabFile.currency[self.m_nSmallID].dName
	elseif self.m_nBigID == 1 then
		if self.m_nSmallID < 1000 then
			str = str .. " " .. g_tblTabFile.equip[self.m_nSmallID].dName .. g_App:GetString( "lipinmatishi3" );
		else
			str = str .. " " .. g_tblTabFile.fusion[self.m_nSmallID].dName .. g_App:GetString( "lipinmatishi3" );
		end
	elseif self.m_nBigID == 2 then
		str = str .. " " .. CMusicConfig:Inst():GetMusicName( self.m_nSmallID ) .. g_App:GetString( "lipinmatishi4" );
	elseif self.m_nBigID == 3 then
		str = str .. " " ..  g_tblTabFile.jiezoutishiqi[self.m_nSmallID].dName .. g_App:GetString( "lipinmatishi5" );
	elseif self.m_nBigID == 4 then
		str = str .. " " .. g_tblTabFile.battleface[self.m_nSmallID].dName .. g_App:GetString( "lipinmatishi6" );
	elseif self.m_nBigID == 6 then
		str = str .. " " .. g_tblTabFile.fragment[self.m_nSmallID].dName .. g_App:GetString( "lipinmatishi7" ) .. "X" .. self.m_nCount;
	end
	g_App:MessageBox( str );
end

function CNotifySkillStateChange:OnUnpack( pBuffer )
	self.m_bShowRedPoint = pBuffer:ReadBoolean();
end

function CNotifySkillStateChange:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart().m_pBtnSkill:ShowRedPoint( self.m_bShowRedPoint );
end

function CAnswerGuestUpgradePrize:OnUnpack( pBuffer )
	self.m_nGold = pBuffer:ReadUint32();
	self.m_nRainbowGold = pBuffer:ReadUint32();
end

function CAnswerGuestUpgradePrize:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart().m_WndGuestUpgradePrize:RefreshWnd( self.m_nGold, self.m_nRainbowGold );
	g_App:GetGameStart().m_WndGuestUpgradePrize:ShowWnd( true );
end

function CNotifyDelockResult:OnUnpack( pBuffer )
	self.m_nType = pBuffer:ReadUint8();
end

function CNotifyDelockResult:OnNetReply( Connecter, pBuffer )
	if self.m_nType ~= 3 then
		g_App:HideMsg( CStringConfig:Inst():GetString( "fenxiangbibuzu" ) );
	else
		g_App:GetGameStart().m_pWndSkillDevelop.m_pWndEffect:AddEffect( "fx/cfg/jineng_jscg.eft", "fx/loop", "jiesuo", 0 );
	end
end

function CNotifyUpgradeSkillResult:OnUnpack( pBuffer )
	self.m_bSucc = pBuffer:ReadBoolean();
end

function CNotifyUpgradeSkillResult:OnNetReply( Connecter, pBuffer )
	if self.m_bSucc then
		g_App:GetGameStart().m_pWndSkillDevelop.m_pWndEffect:AddEffect( "fx/cfg/jineng_sjcg.eft", "fx/loop", "shengji", 0 );		
	else
		g_App:HideMsg( CStringConfig:Inst():GetString( "cailiaobuzu" ) );
	end
end

function CAnswerPrize:OnUnpack( pBuffer )
	local nCount = pBuffer:ReadUint32();
	self.m_tblPropList = {};
	for i = 1, nCount do
		local tblProp = {};
		tblProp.m_nType = pBuffer:ReadUint8();
		tblProp.m_nTypeIndex = pBuffer:ReadUint32();
		tblProp.m_nCount = pBuffer:ReadUint32();
		table.insert( self.m_tblPropList, tblProp );
	end
end

function CAnswerPrize:OnNetReply( Connecter, pBuffer )
	g_App:GetGameStart():NotifyPrizeTip( self.m_tblPropList );
end

function CAnswerVipPrize:OnUnpack( pBuffer )
	local nCount = pBuffer:ReadUint32();
	self.m_tblPropList = {};
	for i = 1, nCount do
		local tblProp = {};
		tblProp.m_nType = pBuffer:ReadUint8();
		tblProp.m_nIndex = pBuffer:ReadUint32();
		tblProp.m_nCount = pBuffer:ReadUint32();
		table.insert( self.m_tblPropList, tblProp );
	end
end

function CAnswerVipPrize:OnNetReply( Connecter, pBuffer )
	if #self.m_tblPropList == 0 then
		return;
	end

	local tblProps = {};
	for i = 1, #self.m_tblPropList do
		local tblProp = 
		{
			["nType"] = self.m_tblPropList[i].m_nType,
			["nIndex"] = self.m_tblPropList[i].m_nIndex,
			["nCount"] = self.m_tblPropList[i].m_nCount,
		};
		table.insert( tblProps, tblProp );
	end
	g_App:GetGameStart():NotifyOpenTreasureBox( 1, tblProps );
end

function CAnswerRaceState:OnUnpack( pBuffer )
	self.m_nState = pBuffer:ReadUint8();
end

function CAnswerRaceState:OnNetReply( Connecter, pBuffer )
	
end

function CNotifyWorldRaceInfo:OnUnpack( pBuffer )
	self.m_nRaceType = pBuffer:ReadUint8();
	self.m_nRaceInfoSize = pBuffer:ReadUint32();
	self.m_tblRaceInfo = {};
	for i = 1, self.m_nRaceInfoSize do
		local tblRaceData = {};
		tblRaceData.m_tblMemberID = {};
		tblRaceData.m_nGlobalTeamID = pBuffer:ReadUint64();
		tblRaceData.m_nRaceRoomID = pBuffer:ReadUint64();
		tblRaceData.m_nCreateTime = pBuffer:ReadUint64();
		tblRaceData.m_nDestroyTime = pBuffer:ReadUint64();
		tblRaceData.m_nLeftTime = pBuffer:ReadUint32();
		tblRaceData.m_nRoomMemberCount = pBuffer:ReadUint32();
		tblRaceData.m_nRoomType = pBuffer:ReadUint8();
		tblRaceData.m_nRoomState = pBuffer:ReadUint8();
		tblRaceData.m_nRaceID = pBuffer:ReadUint8();
		table.insert( self.m_tblRaceInfo, tblRaceData );
	end
	--print( "CNotifyWorldRaceInfo", self.m_nRaceType, self.m_nRaceInfoSize, #self.m_tblRaceInfo );
end

function CNotifyWorldRaceInfo:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "OnWorldRaceInfoData";
	Event.m_nRaceType = self.m_nRaceType;
	Event.m_tblRaceInfo = self.m_tblRaceInfo;
	g_App:GetGameStart():DispatchEvent( Event );
end

function CNotifyCloseRaceRoom:OnUnpack( pBuffer )
end

function CNotifyCloseRaceRoom:OnNetReply( Connecter, pBuffer )
	if g_App:GetGameStart().m_pWndRaceTeam:IsShow() then		   
		g_App:GetGameStart().m_pWndRaceTeam:ShowWnd( false );
		g_App:HideMsg( g_App:GetString( "fangjianjiesan" ) );
	end
end

function CAnswerJoinRace:OnUnpack( pBuffer )
	self.m_nType = pBuffer:ReadUint8();
end

function CAnswerJoinRace:OnNetReply( Connecter, pBuffer )
	if self.m_nType == 0 then
		g_App:GetGameStart().m_pWndRaceTeam:ShowWnd( true );
	elseif self.m_nType == 1 or self.m_nType == 3 then
		g_App:HideMsg( g_App:GetString( "fangjianbucunzai" ) );
	elseif self.m_nType == 2 then
		g_App:HideMsg( g_App:GetString( "ziyuanbuzu" ) );  
	elseif self.m_nType == 4 then
		g_App:HideMsg( g_App:GetString( "fangjianyiman" ) );
	elseif self.m_nType == 5 then
		g_App:HideMsg( g_App:GetString( "saishicishushangxian" ) );
	elseif self.m_nType == 6 then
		g_App:HideMsg( g_App:GetString( "renbugou" ) );
	elseif self.m_nType == 7 then
		g_App:HideMsg( g_App:GetString( "duizhangcaozuo" ) );
	elseif self.m_nType == 8 then
		g_App:HideMsg( g_App:GetString( "renbugou" ) );
	elseif self.m_nType == 9 then
		g_App:HideMsg( g_App:GetString( "sirenfangjiantips5" ) );
	end
end

function CSendRaceNotice:OnUnpack( pBuffer )
	self.m_nAccountID = pBuffer:ReadUint64();
	self.m_szNickName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CSendRaceNotice:OnNetReply( Connecter, pBuffer )
	local str = string.format( g_App:GetString( "saishiguangbotips1"), self.m_szNickName );
	local szHyplink = "showplayerinfo ".. self.m_nAccountID;
	local szMsg = "#c("..szHyplink..")"..str.."#c()"; 
	g_App.m_RaceNoticeBar:AddContent( szMsg, 0 );
end

function CAnswerGMCmd:OnUnpack( pBuffer )
	self.m_strMsg = pBuffer:ReadUTF();
end

function CAnswerGMCmd:OnNetReply( Connecter, pBuffer )
	if string.len( self.m_strMsg ) == 0 then
		g_App:MessageBox( g_App:GetString( "gm_success" ) );
	else
		g_App:MessageBox( self.m_strMsg );
	end
end

function CAnswerNewChar:OnUnpack( pBuffer )
end

function CAnswerNewChar:OnNetReply( Connecter, pBuffer )
	g_App.m_bNewChar = true;
end

function CNotifyGameSwitch:OnUnpack( pBuffer )
	self.m_nSwitch = pBuffer:ReadUint32();
end

function CNotifyGameSwitch:OnNetReply( Connecter, pBuffer )
	g_App.m_nSwitch = self.m_nSwitch;
end

function CNotifyBeyondWorldRank:OnUnpack( pBuffer )
	self.m_szCharNameOld	= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	self.m_szCharNameNew	= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	self.m_nRankType		= pBuffer:ReadUint8();
	self.m_nNewCharAccountID= pBuffer:ReadUint64(); 		  
end

function CNotifyBeyondWorldRank:OnNetReply( Connecter, pBuffer )
	local str = "";
	if self.m_szCharNameOld == "" then
		str = string.format( g_App:GetString( "shouweishangbang" .. ( self.m_nRankType + 1 ) ), self.m_szCharNameNew );
	elseif self.m_szCharNameOld == self.m_szCharNameNew then
		str = string.format( g_App:GetString( "chaoyueziji" .. ( self.m_nRankType + 1 ) ), self.m_szCharNameNew );
	else
		str = string.format( g_App:GetString( "saishijilu" .. ( self.m_nRankType + 1 ) ), self.m_szCharNameNew, self.m_szCharNameOld );
	end

	local szHyplink = "showplayerinfo "..self.m_nNewCharAccountID;
	local szMsg = "#c("..szHyplink..")"..str.."#c()"; 
	g_App.m_RaceNoticeBar:AddContent( szMsg, 0 );
end

function CAnsertCustomerServiceMsg:OnUnpack( pBuffer )
	self.nResult = pBuffer:ReadUint8();	
	self.szMsg = pBuffer:ReadUTFBytes( pBuffer:ReadUint8() );	
end

function CAnsertCustomerServiceMsg:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "NewMessageFriend";
    Event.m_nAccountID = eSystemAccountID_CustomerService;
    Event.m_nCreateTime = 0;
	if self.nResult == 0 then
		Event.m_szContent = g_App:GetString( "kefutips5" );	
	elseif self.nResult == 1 then
		Event.m_szContent = g_App:GetString( "kefutips4" );	
	elseif self.nResult == 2 then
		Event.m_szContent = g_App:GetString( "kefutips11" );	
	else	
		Event.m_szContent = self.szMsg;	
	end
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CNotifyCustomerServiceMsg:OnUnpack( pBuffer )
	self.nID = pBuffer:ReadUint32();	
	self.szContent = pBuffer:ReadUTFBytes( pBuffer:ReadUint16() );	
end

function CNotifyCustomerServiceMsg:OnNetReply( Connecter, pBuffer )
	local NetMsg = CReciveCustomerServiceAnswer:new();
	NetMsg.nID = self.nID;
	Connecter:SendShellMsg( NetMsg );
	
	local Event = {};
    Event.m_Type = "NewMessageFriend";
    Event.m_nAccountID = eSystemAccountID_CustomerService;
    Event.m_nCreateTime = 0;
	Event.m_szContent = self.szContent;	
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CRaceRoomNumbering:OnUnpack( pBuffer )
	
end

function CRaceRoomNumbering:OnNetReply( Connecter, pBuffer )	
	local Event = {};
    Event.m_Type = "RaceRoomNumbering";
    g_App:GetGameStart():DispatchEvent( Event );
end

function CAnswerClanAndMemberInfo:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
	self.m_ClanInfo = {};
	self.m_ClanMemberInfo = {};
	self.m_MyClanInfo = {};
	if self.m_nResult == eAccurateSearchClan_Ok then
		self.m_ClanInfo["nClanID"]			= pBuffer:ReadUint64();
		self.m_ClanInfo["nIconID"]			= pBuffer:ReadUint16();
		self.m_ClanInfo["szClanName"]		= pBuffer:ReadUTFBytes( CLANNAME_BYTE_SIZE + 1 );
		self.m_ClanInfo["szClanSlogan"]		= pBuffer:ReadUTFBytes( CLANSLOGAN_BYTE_SIZE + 1 );
		self.m_ClanInfo["nMemberCount"]		= pBuffer:ReadUint8();
		self.m_ClanInfo["nNeedApprove"]		= pBuffer:ReadUint8();
		self.m_ClanInfo["nDayActivity"]		= pBuffer:ReadUint16();
		self.m_ClanInfo["nWeekActivity"]	= pBuffer:ReadUint32();
		self.m_ClanInfo["nMonthActivity"]	= pBuffer:ReadUint32();
		self.m_ClanInfo["nAllActivity"]		= pBuffer:ReadUint32();

		local nMemberCount = pBuffer:ReadUint8();
		for i = 1, nMemberCount do
			local tblClanMemberInfo = {};
			tblClanMemberInfo["nAccountID"]		= pBuffer:ReadUint64();
			tblClanMemberInfo["szCharName"]		= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
			tblClanMemberInfo["nState"]			= pBuffer:ReadUint8();
			tblClanMemberInfo["nLogoutTime"]	= pBuffer:ReadUint32();
			tblClanMemberInfo["nCurHeadIcon"]	= pBuffer:ReadUint16();
			tblClanMemberInfo["nCurLadderStar"] = pBuffer:ReadUint16();
			tblClanMemberInfo["nPower"]			= pBuffer:ReadUint8();
			tblClanMemberInfo["nDayActivity"]	= pBuffer:ReadUint16();
			tblClanMemberInfo["nWeekActivity"]	= pBuffer:ReadUint16();
			table.insert( self.m_ClanMemberInfo, tblClanMemberInfo );
			if tblClanMemberInfo["nAccountID"]	== g_App:GetAccountID() then
				self.m_MyClanInfo = tblClanMemberInfo;
			end
		end
	end
	table.sort( self.m_ClanMemberInfo, function( a, b )
		if a.nPower == b.nPower then
			if a.nState == b.nState then
				return a.nWeekActivity > b.nWeekActivity;
			else
				return a.nState > b.nState;
			end
		else
			return a.nPower > b.nPower;
		end
	end)
end

function CAnswerClanAndMemberInfo:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "RefreshClanAndMemberInfo";
    Event.m_tblClanInfo = self.m_ClanInfo;
    Event.m_tblClanMemberInfo = self.m_ClanMemberInfo;
	Event.m_tblMyClanInfo = self.m_MyClanInfo;
    g_App.m_EventDispatcher:DispatchEvent( Event );	
end

function CAnswerCreateClan:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerCreateClan:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == eCreateClan_Ok then
		g_App:HideMsg( g_App:GetString( "chuangjianchenggong" ) );
		local Event = {};
		Event.m_Type = "AnswerCreateClan";
		g_App.m_EventDispatcher:DispatchEvent( Event );		
	elseif self.m_nResult == eCreateClan_Failed_LackResource then
		g_App:HideMsg( g_App:GetString( "chuangjianshibai1" ) );
	elseif self.m_nResult == eCreateClan_Failed_NoSocial then
		g_App:HideMsg( g_App:GetString( "chuangjianshibai3" ) );
	elseif self.m_nResult == eCreateClan_Failed_NameExist then
		g_App:HideMsg( g_App:GetString( "chuangjianshibai2" ) );
	elseif self.m_nResult == eCreateClan_Failed_InClan then
		g_App:HideMsg( g_App:GetString( "chuangjianshibai4" ) );
	end
end

function CAnswerClanApplyInfo:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
	self.m_nCount = pBuffer:ReadUint32();
	self.m_tblClanApplyList = {};
	for i = 1, self.m_nCount do
		local tbl = {};
		tbl["nAccountID"]		= pBuffer:ReadUint64();
		tbl["szCharName"]		= pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
		tbl["nCurHeadIcon"]		= pBuffer:ReadUint16();
		tbl["nSex"]				= pBuffer:ReadUint8();
		tbl["nAge"]				= pBuffer:ReadUint8();
		tbl["nCurLadderCount"]	= pBuffer:ReadUint32();
		table.insert( self.m_tblClanApplyList, tbl );
	end	
end

function CAnswerClanApplyInfo:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == eOperate_Ok then
		local Event = {};
		Event.m_Type = "OnAnswerApplyList";
		Event.m_nResult = self.m_nResult;
		Event.m_tblClanApplyList = self.m_tblClanApplyList;
		g_App.m_EventDispatcher:DispatchEvent( Event );
	elseif self.m_nResult == eOperate_Failed_NoPower then
		g_App:HideMsg( g_App:GetString( "meiyouquanxian" ) );
	end	
end

function CAnswerUploadJpgImage:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerUploadJpgImage:OnNetReply( Connecter, pBuffer )
	local tblString = { "tupianshangchuanchenggong", 
						"tupianshuliangshangxian", 
						"tupianshujuchucuo", 
						"fuwuqiqingqiushibai", 
						"fuwuqicunchushibai" };
	g_App:HideMsg( g_App:GetString( tblString[self.m_nResult+1] ) );
	if self.m_nResult == 0 then
		local Event = {};
		Event.m_Type = "RefreshPhotoList";
		g_App.m_EventDispatcher:DispatchEvent( Event );	
	end
end

function CAnswerDeletePicture:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerDeletePicture:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == 0 then
		g_App:HideMsg( g_App:GetString( "shanchutupianchenggong" ) );
		local Event = {};
		Event.m_Type = "RefreshPhotoList";
		g_App.m_EventDispatcher:DispatchEvent( Event );	
	else
		g_App:HideMsg( g_App:GetString( "shanchutupianshibai" ) );
	end
end

function CWorld2ClientTips:OnUnpack( pBuffer )
	self.m_nID = pBuffer:ReadUint32();
end

function CWorld2ClientTips:OnNetReply( Connecter, pBuffer )
	local szDescribe = g_tblTabFile.World2ClientTips[ tonumber( self.m_nID ) ].dDescribe;
	g_App:MessageBox( szDescribe );
end

function CAnswerPropellPlayer:OnUnpack( pBuffer )
	self.m_nCount = pBuffer:ReadUint32();
	self.m_tblAccount = {};
	for i = 1, self.m_nCount do
		local tbl = {}
		tbl["nAge"] = pBuffer:ReadUint8();
		tbl["nSex"] = pBuffer:ReadUint8();
		tbl["nArea"] = pBuffer:ReadUint8();
		tbl["nConstellation"] = pBuffer:ReadUint8();
		tbl["nHeadIcon"] = pBuffer:ReadUint16();
		tbl["nLadderStarCount"] = pBuffer:ReadUint32();
		tbl["nBeCommendCount"] = pBuffer:ReadUint32();
		tbl["nAccountID"] = pBuffer:ReadUint64();
		tbl["szNickName"] = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
		tbl["szSignature"] = pBuffer:ReadUTFBytes( Char_Signature_Byte_Size+1 );
		table.insert( self.m_tblAccount, tbl );
	end	
end

function CAnswerPropellPlayer:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "OnAnswerPropellPlayer";
	Event.m_tblAccountList = self.m_tblAccount;
	g_App.m_EventDispatcher:DispatchEvent( Event );	
end

function CNotifyRefreshHeadImg:OnUnpack( pBuffer )
end

function CNotifyRefreshHeadImg:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "RefreshHeadImg";
	g_App.m_EventDispatcher:DispatchEvent( Event );	
end

function CAnswerPictureData:OnUnpack( pBuffer )
	self.m_nPictureCount = pBuffer:ReadUint8();
	self.m_tblPictureStatus = {};
	for i = 1, self.m_nPictureCount do
		local tbl = {};
		tbl["nIndex"] = pBuffer:ReadUint8();
		tbl["nStatus"] = pBuffer:ReadUint8();
		self.m_tblPictureStatus[tbl.nIndex] = tbl;
	end
end

function CAnswerPictureData:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "AnswerPictureData";
	Event.m_tblPictureStatus = self.m_tblPictureStatus;
	g_App.m_EventDispatcher:DispatchEvent( Event );
end