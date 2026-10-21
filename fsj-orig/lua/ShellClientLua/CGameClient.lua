--region CGameClient.lua
--Date 2015-12-07

CGameClient.eEvent_AllConfigLoaded	= "AllConfigLoaded";

function CGameClient:Ctor()
	math.randomseed( GetNatureTime()/1000 )
	math.random(); math.random(); math.random();
	self.m_nSwitch = 0;
end

function CGameClient:OnStart()
	self.m_tblTreasureBox = {};
	self.m_tblFragment = {};
	self.m_CmdMgr = CClientCmdMgr:new()
	if SHOW_DEBUG_INPUT then
		self.m_CmdMgr:ShowDebugInput();
	end
	self.m_GameStart = ClassCast( CGameStartLua, CGameAppClient.GetGameStart( self ) );
	self.m_GameMain = ClassCast( CGameMainLua, CGameAppClient.GetGameMain( self ) );
	self.m_CharContext = CPlayerDBClient:new();
	
	local RootWnd = g_App:GetGUIMgr():GetRootWnd();
	self.m_pLoginFrame = CGameLogin:new( "gui/cfg/login.gui", RootWnd, 1 );
	self.m_NoticeBar = CNoticeBar:new( "gui/cfg/fsj_gonggaolan.gui", RootWnd, 1 );
	self.m_RaceNoticeBar = CNoticeBar:new( "gui/cfg/fsj_gonggaolan1.gui", RootWnd, 1 );
	self.m_HideMsg = CHideMsg:new( "gui/cfg/fsj_tongyongitem.gui", RootWnd, 1 );
	self.m_WaitMsg = CWaitMsg:new( "gui/cfg/fsj_dengdai.gui", RootWnd, 1 );
    self.m_pMessageBox = CMessageBox:new( "gui/cfg/messagebox.gui", RootWnd, 1 );
    self.m_pMessageBox3 = CMessageBox3:new( "gui/cfg/messageboxsanxuan.gui", RootWnd, 1 );
	self.m_NetDelayWnd = CNetDelayWnd:new();
	self.m_NetDelayWnd:CreateFromRes( "gui/cfg/fsj_wangluotishi.gui", RootWnd, 1 );
	self.m_pWndGuideVideo = CWndGuideVideo:new( "gui/cfg/fsj_shipin.gui", RootWnd, 2 );
	self.m_pWndFieldReconnectLast = CGWnd:new( "gui/cfg/chonglianzhong.gui", RootWnd, 2 );
	self.m_pWndFieldReconnect = CWndReconnect:new( "gui/cfg/changshichonglian.gui", RootWnd, 1 );
	self.m_pWndBeCommend = CWndBeCommend:new( "gui/cfg/fsj_dianzan.gui", RootWnd, 1 );
	self.m_pWndLoginDeclaration = CWndDeclaration:new( "gui/cfg/fsj_dengluqiangonggaobg.gui", RootWnd, 1, 0 );
	self.m_pWndGameMainDeclaration = CWndDeclaration:new( "gui/cfg/fsj_huodonggonggaobg.gui", RootWnd, 1, 1 );

	local strSettingPath = self:GetGameSettingPath();
	CTableConfigMgr:Inst():Load( strSettingPath .. "iconconfig.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "chat.txt", false, true );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/currency.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/equip.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/skill.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/battleface.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/jiezoutishiqi.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/fragment.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/treasureboxbase.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/fusion.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "guest_upgrade.txt", false, true );
	CTableConfigMgr:Inst():Load( strSettingPath .. "shop/charge.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "shop/vip.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "shop/vipitem.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "shop/yunyinglibao.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/musicbase.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "day_race/race_rankprize.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "day_race/day_race_activity.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "day_race/day_race_cost.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "playerlevel.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "constellation.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "area.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "day_roll_activity.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "head_info_rect.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "firstchargeprize.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "star_left_days.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "clan/clanIcon.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "clan/clanlevel.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "clan/clanactivity.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "day_race/day_race_switch.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "gm/gm_type.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "gm/gm_column.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "resource/equip_skill.txt", false );
	CTableConfigMgr:Inst():Load( strSettingPath .. "World2ClientTips.txt", false );

	self.m_EventDispatcher = CEventDispatcher:new();

	print("CGameClient:OnStart");

	--self:GetGameStart().m_tblRankData = {};
--	self:GetGameStart().m_tblRankData.szFriendName = {};
--	self:GetGameStart().m_tblRankData.nFriendScore = {};
--	self:GetGameStart().m_tblRankData.szWorldName = {};
--	self:GetGameStart().m_tblRankData.nWorldScore = {}

	local IconMgr = CIconManager:Instance();
		
    LoadLuaConfig( self:GetGameSettingPath() .. "iconconfig.lua", IconMgr, IconMgr.LoadIconConfig, false );
	LoadLuaConfig( self:GetGameSettingPath() .. "musiclist.lua", self, nil, false );
	LoadLuaConfig( self:GetGameSettingPath() .. "graderecordshowlevel.lua", self, nil, false );
	LoadLuaConfig( self:GetGameSettingPath() .. "treasureboxpos.lua", self, nil, false );
	if string.len( self:GetChannelShare() ) ~= 0 then
		LoadLuaConfig( self:GetChannelShare(), self, nil, false );
	end
	
	self.m_EventDispatcher:AddEventListener( "LoginSucc", "OnLoginSucc", self );

	RegisterWanfaClass( eRT_Endless, CWanfaEndless );
	RegisterWanfaClass( eRT_LimitTime, CWanfaServer );
	RegisterWanfaClass( eRT_Team, CWanfaServer );
	RegisterWanfaClass( eRT_LimitSecret, CWanfaServer );
	RegisterWanfaClass( eRT_TeamSecret, CWanfaServer );
	RegisterWanfaClass( eRT_LimitRace, CWanfaServer );
	RegisterWanfaClass( eRT_TeamRace, CWanfaServer );
end

function CGameClient:OnQuit()
	self.m_pLoginFrame:DestroyWnd();
	self.m_NoticeBar:DestroyWnd();
	self.m_HideMsg:DestroyWnd();
	self.m_WaitMsg:DestroyWnd();
    self.m_pMessageBox:DestroyWnd();
    self.m_pMessageBox3:DestroyWnd();
	self.m_NetDelayWnd:DestroyWnd();
	self.m_pWndGuideVideo:DestroyWnd();
	self.m_pWndFieldReconnectLast:DestroyWnd();
	self.m_pWndFieldReconnect:DestroyWnd();
	self.m_pWndBeCommend:DestroyWnd();
	self.m_pWndLoginDeclaration:DestroyWnd();
	self.m_pWndGameMainDeclaration:DestroyWnd();
	CHeadIconConfig:Inst():Destroy();
	CGameAppClient.OnQuit( self );
end

function CGameClient:ResetMainUI()
	self:ClearMainUI();
	self.m_GameStart = ClassCast( CGameStartLua, CGameAppClient.GetGameStart( self ) );
	self.m_GameMain = ClassCast( CGameMainLua, CGameAppClient.GetGameMain( self ) );
	self:CreateMainUI();
end

function CGameClient:HideMsg( szMsg, nTickTime )
	self.m_HideMsg:Hide( szMsg, nTickTime );
end

function CGameClient:WaitMsg( bWait, nWaitTime )
	if not nWaitTime or nWaitTime == 0 then
		nWaitTime = 1500;
	end
	return CGameAppClient.WaitMsg( self, bWait, nWaitTime );
end

function CGameClient:GetRankDataMgr()
	return self.m_GameStart and self.m_GameStart.m_mgrRankData;
end

function CGameClient:GetInstantMessageDataMgr()
	return self.m_GameStart and self.m_GameStart.m_mgrInstantMessageData;
end

function CGameClient:GetBeCommendWnd()
	return self.m_pWndBeCommend;
end

function CGameClient:GetGameStart()
	return self.m_GameStart;
end

function CGameClient:GetGameMain()
	return self.m_GameMain;
end

function CGameClient:GetGuideVideoWnd()
	return self.m_pWndGuideVideo;
end

function CGameClient:GetScene()
	return self.m_Scene;
end

function CGameClient:GetDirector()
	return self.m_pDirector;
end

function CGameClient:SetDirector( pObject )
	self.m_pDirector = ClassCast( CPlayerClientLua, pObject );
	CGameAppClient.SetDirector( self, pObject );
end

function CGameClient:GetWorldConn()
	return self.m_WorldConnect;
end

function CGameClient:OnWorldAlloc( Connect )
	self.m_WorldConnect = ClassCast( CGameConnToWorldLua, Connect );
end

function CGameClient:OnWorldFree( Connect )
	self.m_WorldConnect = nil;
end

function CGameClient:GetFieldConn()
	return self.m_FieldConnect;
end

function CGameClient:OnFieldAlloc( Connect )
	self.m_FieldConnect = ClassCast( CGameConnToFieldLua, Connect );
end

function CGameClient:OnFieldFree( Connect )
	self.m_FieldConnect = nil;
end

function CGameClient:OnSceneAlloc( Scene )
	self.m_Scene = ClassCast( CGameSceneClientLua, Scene );
end

function CGameClient:OnSceneFree( Connect )
	self.m_Scene = nil;
end

function CGameClient:OnClose()
	return true;
end

function CGameClient:GetMainPlayerData()
	return self.m_CharContext;
end

function CGameClient:SendShellMsg( PrtMsg, pExtraBuffer, nSize )
	if not self.m_WorldConnect then
		self:HideMsg( self:GetString( "noduoren" ) );
		return;
	end
	self.m_WorldConnect:SendShellMsg( PrtMsg, pExtraBuffer, nSize );
end


function CGameClient:LoadCfg()
	CGameAppClient.LoadCfg( self );

	local szDesignerPath = self:GetGameSettingPath();
	
    CHeadIconConfig:Inst():LoadConfigFile( szDesignerPath, false );
end

function CGameClient:PostAllLoaded()
	if self:IsQuit() then
		return;
	end
	CGameAppClient.PostAllLoaded( self )

	self.m_pLoginFrame:ShowWnd( true );
	self:HidePreLoadingUI();
end

function CGameClient:GetString( szKey )
	local Config = CStringConfig.Inst();
	return Config.GetString( Config, szKey );
end

function CGameClient:OnRenderBegin()
	return CGameAppClient.OnRenderBegin( self )
end

function CGameClient:OnRenderEnd()
	return CGameAppClient.OnRenderEnd( self )
end

function CGameClient:OnLowMemory()
end

function CGameClient:GetMachineInfo()
	local info = {};
	local data = CBufferStream:new( 1024 );
	CGameAppClient.GetMachineInfo( self, data, 1024 );
	info.graphicDesc = data:ReadUTF();
	info.deviceDesc = data:ReadUTF();
	info.cpuType = data:ReadUTF();
	info.osDesc = data:ReadUTF();
	info.uuid = data:ReadUTF();
	info.languageCode = data:ReadUTF();
	info.macLow = data:ReadUint32();
	info.macHight = data:ReadUint32();
	info.cpuFrequery = data:ReadUint32();
	info.cpuCount = data:ReadUint32();
	info.memSize = data:ReadUint32();
	info.screenX = data:ReadUint16();
	info.screenY = data:ReadUint16();
	return info;
end

function CGameClient:SwitchGame( nSceneID, nRoomType, nMusicID )
	print( "Switch Game: "..nSceneID.." , "..nRoomType.." , "..nMusicID );
	if nRoomType == eRT_Team then
        self.m_GameStart.m_pTeamWnd.m_pTeamMatchingWnd:ShowWnd( false );
        self.m_GameStart.m_pTeamWnd:ShowWnd( false );
	end
	return CGameAppClient.SwitchGame( self, nSceneID, nRoomType, nMusicID );
end

function CGameClient:SwitchLogin()
	if self:GetScene() then
		self:SwitchStart();
	end
	g_App:ResetMainUI();
	self:GetGameStart():ShowWnd( false );
	self.m_pLoginFrame:ShowWnd( true );
end

function CGameClient:GetLoginFrame()
	return self.m_pLoginFrame;
end

function CGameClient:OnResult( nResultID, szResult )
	print( "SDK OnResult: "..nResultID.." : "..szResult );
	if nResultID == eLoginAndPayResult_LOGIN_SUCCESS then
		self:WaitMsg( false );
		local pWorldConn = g_App:GetWorldConn();
		if not pWorldConn then
			return;
		end
		local jsonObj = json.decode( szResult );
		local szChannel = self:GetChannel();
		local szSDKType = self:GetSDKType();
		local bGuest = tonumber( jsonObj.isGuest ) == 1;
		pWorldConn:Login( jsonObj.username, jsonObj.token, szChannel,
			szSDKType, jsonObj.pid, jsonObj.gid, jsonObj.szGHomeDeviceID, jsonObj.szPushDeviceID, bGuest );
	elseif nResultID == eLoginAndPayResult_LOGIN_FAILED then
		self:WaitMsg( false );
	elseif nResultID == eLoginAndPayResult_LOGOUT_SUCCESS then
		local pWorldConn = self:GetWorldConn();
		if pWorldConn then
			local NetMsg = CQueryExitGame:new();
			pWorldConn:SendShellMsg( NetMsg );
		end
	elseif nResultID == eLoginAndPayResult_SHARE then
		local jsonObj = json.decode( szResult );
		local pWorldConn = self:GetWorldConn();
		if pWorldConn then
			local szDesName = "";
			if jsonObj.szChannel == s_channel_WeiXin then
				szDesName = self:GetString( "fenxiang_weixinhaoyou" );
			elseif jsonObj.szChannel == s_channel_WeiXinTimeline then
				szDesName = self:GetString( "fenxiang_weixinpengyouquan" );
			elseif jsonObj.szChannel == s_channel_QQ then
				szDesName = self:GetString( "fenxiang_qqhaoyou" );
			elseif jsonObj.szChannel == s_channel_QQSpace then
				szDesName = self:GetString( "fenxiang_qqkongjian" );
			end
			local tblShareConfig = self:GetShareConfig();
			local NetMsg = CShareResult:new();
			NetMsg.m_szDesName = szDesName;
			NetMsg.m_szSrcName = self.m_szShareSrcName;
			NetMsg.m_bSucc = jsonObj.bSucc;
			NetMsg.m_bShareLink = tblShareConfig["bShareLink"];
			pWorldConn:SendShellMsg( NetMsg );
		end
	elseif nResultID == eLoginAndPayResult_GUEST_UPGRADE_SUCCESS then
		local pWorldConn = self:GetWorldConn();
		pWorldConn:OnGuestUpgrade( false );
		self:GetGameStart():GetSetingWnd():RefreshAccount();
		local NetMsg = CGuestUpgrade:new();
		g_App:SendShellMsg( NetMsg );
	elseif nResultID == eLoginAndPayResult_GUEST_UPGRADE_FAILED then
		local pWorldConn = self:GetWorldConn();
		if pWorldConn then
			pWorldConn:OnGuestUpgrade( true );
			self:GetGameStart():GetSetingWnd():RefreshAccount();
		end
	elseif nResultID == eLoginAndPayResult_EXIT_GAME or nResultID == eLoginAndPayResult_EXIT_GAME_Temp then
		CGameAppClient.Quit( self );
	end

	CGameAppClient.OnResult( self, nResultID, szResult );
end

function CGameClient:ValidateResult( Buffer, nBufferLen, nBlockDataHeadSize )
	self:WaitMsg( false );
	
	-- 初始玩家数据
	self.m_CharContext:InitFromCompress( Buffer, nBufferLen, nBlockDataHeadSize );

	self.m_GameStart:ShowWnd( true );
	self.m_pLoginFrame:ShowWnd( false );
    self.m_NetDelayWnd:SetNetDelay( 0 );

	local Event = {};
    Event.m_Type = "LoginSucc";
    Event.m_nAccountID = g_App:GetAccountID();
	self.m_EventDispatcher:DispatchEvent( Event );

    CFriendMgr:Inst():Clear();

	local tblData = 
	{
		["nServerID"] = self:GetServerID();
	};
	g_App:SendSDKCmd( eLoginAndPayCmd_ENTER_GAME, json.encode( tblData ) );

	if self.m_bNewChar then
		g_App:CommitCharData( 0 );
	end
	g_App:CommitCharData( 1 );
	g_App:GetGameStart().m_pWndNewSeasonComing:ShowLeftTime();
end

function CGameClient:GetShowAccountID()
	if g_App:GetAccountID() == 0 then
		return 0;
	end

	local szPrefix = "";
	if g_App:GetWorldConn():IsGuest() then
		szPrefix = g_App:GetString( "youke" );
	end

	local szAccountID = tostring( g_App:GetAccountID() );
	while string.len( szAccountID ) < 10 do
		szAccountID = "0"..szAccountID;
	end
	return szPrefix..szAccountID;
end

function CGameClient:EnterRoom( nRoomType )
	local PlayerData = g_App:GetMainPlayerData().m_CharBaseData;
	local nCurAllGameScore = PlayerData:GetAllGameScore();
	self:GetGameStart().m_nPreEnterScore = nCurAllGameScore;
	self:GetGameStart().m_nEnterRoomNum = self:GetGameStart().m_nEnterRoomNum + 1;
	if not nRoomType then return end;
	if nRoomType >= eRT_Count then
		return;
	end
	CPlayerGradeInfoMgr:Instance():QueryAllScoreNewByAccountID( g_App:GetWorldConn(), g_App:GetAccountID() );
	local NetMsg = CQueryWorldMaxRecord:new();
	self:SendShellMsg( NetMsg );

	local pFieldConn = self:GetFieldConn();
	if pFieldConn then
		return;
	end

	if nRoomType == eRT_Endless then
		local nMusicID = self:GetSelectMusicID();
		local pScene = self:SwitchGame( 1, eRT_Endless, nMusicID );
		if pScene then
			local pSceneInfo = pScene:GetSceneInfo();
			local nMapID = pSceneInfo:RandMapID( 0xFFFF );
			pScene:CreateMapItem( nMapID );
			pScene:CreateConfigAI();
		end
	elseif nRoomType == eRT_LimitTime then
        local NetMsg = CSetMusic:new();
        NetMsg.nMusicID = g_App:GetSelectMusicID();
		self:SendShellMsg( NetMsg );
		NetMsg = CCreateTeam:new();
        NetMsg.nType = eMRT_Limit;
		self:SendShellMsg( NetMsg );
	elseif nRoomType == eRT_Team then
        local NetMsg = CSetMusic:new();
        NetMsg.nMusicID = g_App:GetSelectMusicID();
		self:SendShellMsg( NetMsg );
		NetMsg = CCreateTeam:new();
        NetMsg.nType = eMRT_Team;
		g_App:SendShellMsg( NetMsg );
	elseif nRoomType == eRT_LimitSecret then
        local NetMsgMusic = CSetMusic:new();
        NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
		self:SendShellMsg( NetMsgMusic );
		local NetMsg = CCreateTeam:new();
        NetMsg.nType = eMRT_LimitSecret;
		g_App:SendShellMsg( NetMsg );
	elseif nRoomType == eRT_TeamSecret then
        local NetMsgMusic = CSetMusic:new();
        NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
		self:SendShellMsg( NetMsgMusic );
		local NetMsg = CCreateTeam:new();
        NetMsg.nType = eMRT_TeamSecret;
		g_App:SendShellMsg( NetMsg );
	end
end

function CGameClient:MessageBox( szTips, tblButton, szOk, szCancel )
	self.m_pMessageBox:ShowWnd( true );
	return self.m_pMessageBox:SetBoxData( szTips, tblButton, szOk, szCancel );
end

function CGameClient:HideMessageBox()
	self.m_pMessageBox:HideMessageBox();
end

function CGameClient:GetCurMessageID()
	return self.m_pMessageBox.m_nMessageID;
end

function CGameClient:MessageIsShow()
	return self.m_pMessageBox:IsShow();
end

function CGameClient:MessageBox3( szTips, tblButton, szFirst, szSecond, szThird )
	self.m_pMessageBox3:SetData( szTips, tblButton, szFirst, szSecond, szThird );
	self.m_pMessageBox3:ShowWnd( true );
end

function CGameClient:GetPlayerBattleInfoCount()
	return self:GetDirector() and self:GetDirector():GetBattleInfoCount() or 0;		
end

function CGameClient:GetPlayerBattleInfo()
	local nBattleInfoCount = self:GetPlayerBattleInfoCount();
	local Buffer = self:GetDirector() and self:GetDirector():GetBattleInfoBuffer();
	local tblBattleInfo = {};
	for i = 1, nBattleInfoCount do
		local tbl = {};
		tbl["m_szKillerNickName"]	= Buffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
		tbl["m_szDeaderNickName"]	= Buffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
		tbl["m_nKillerEquipID"]		= Buffer:ReadUint16();
		tbl["m_nDeaderEquipID"]		= Buffer:ReadUint16();
		tbl["m_nCount"]				= Buffer:ReadUint16();
		tbl["m_nKillerAccountID"]	= Buffer:ReadUint64();
		tbl["m_nDeaderAccountID"]	= Buffer:ReadUint64();
		tbl["m_nKillerObjectID"]	= Buffer:ReadUint16();
		tbl["m_nDeaderObjectID"]	= Buffer:ReadUint16();
		table.insert( tblBattleInfo, tbl );
	end
	return tblBattleInfo;
end

function CGameClient:OnLoginSucc()
	self.m_bGetLimitModeOpenPrize = g_App:GetFirstEvent( eFE_GetLimitModeOpenPrize );
	self.m_bGetTeamModeOpenPrize = g_App:GetFirstEvent( eFE_GetTeamModeOpenPrize );

	--创建玩家下载音乐文件夹
	local szPath = g_App:GetLogPath().."netmusic/";
	local Buff = CBufferStream:new( 2048 );
	self.m_szNetMusicCachePath = CPathMgr.ToPhysicalPath( szPath, Buff, 2000 );
	CPathMgr.MakeDirectory( self.m_szNetMusicCachePath );

	if g_App:GetIniFile():GetInteger( "State", "Guide", 0 ) == 0 then
--		self.m_pWndGuideVideo:PlayVideo( function( bJumpOver )
			local iniFile = g_App:GetIniFile();
			iniFile:WriteInteger( "State", "Guide", 1 );
			iniFile:Save();

--			if bJumpOver then
--				CGuideMgr:Inst():Start();
--			else
--				local pGameStart = g_App:GetGameStart();
--				pGameStart.m_pWndGuideSelect:ShowWnd( true );
--			end
--		end );
		CGuideMgr:Inst():Start();
	else
		local nDefaultMusicID = CSnakeConstant:Inst():GetDefaultMusicID();
		local nCurMusicID = g_App:GetIniFile():GetInteger( "Setting", "MusicID", nDefaultMusicID );

		local nMusicPlay = nDefaultMusicID;
		if self:IsHaveMusic( nCurMusicID )  and self:CheckCurMusicInCache( nCurMusicID ) then
			nMusicPlay = nCurMusicID;
		end
		g_App:GetIniFile():WriteInteger( "Setting", "MusicID", nMusicPlay );
		g_App:SetBGMusic( nMusicPlay );

		local pWorldConn = self:GetWorldConn();
		if pWorldConn then
			local NetMsg = CDeclaration:new();
			pWorldConn:SendShellMsg( NetMsg );
		end
	end

	CPlayerGradeInfoMgr:Instance():QueryAllScoreNewByAccountID( g_App:GetWorldConn(), g_App:GetAccountID() );

	-- 游客升级提示  
	local nGuestUpgradeEndTime = self:GetIniFile():GetInteger64( "Stat", "GuestUpgradeEndTime" );
	if not self.m_bNewChar and GetNatureTime() > nGuestUpgradeEndTime then
		local nLastLogin = self:GetIniFile():GetInteger64( "Stat", "LastLogin", 0 );
		if math.floor( nLastLogin / eTimeConst_DayMiSeconds )
			~= math.floor( GetNatureTime() / eTimeConst_DayMiSeconds ) then
			self:GetIniFile():WriteInteger( "Stat", "DayLoginCount", 0 );
		end
		self:GetIniFile():WriteInteger64( "Stat", "LastLogin", GetNatureTime() );
		local nCurDayLoginCount = self:GetIniFile():GetInteger( "Stat", "DayLoginCount", 0 );
		local nValue = g_tblTabFile.guest_upgrade["nLoginCount"];
		if nCurDayLoginCount < nValue and g_App:GetWorldConn():IsGuest() then
			g_App:GetGameStart().m_WndGuestUpgrade:ShowWnd( true );
		end
		self:GetIniFile():WriteInteger( "Stat", "DayLoginCount", nCurDayLoginCount + 1 );
		self:GetIniFile():Save();
	end
	
	if not g_App:GetWorldConn():IsGuest() then
		local NetMsg = CGuestUpgrade:new();
		g_App:SendShellMsg( NetMsg );
	end

	local nCurEquipID = g_App:GetMainPlayerData().m_CharBaseData:GetCurEquipID();
	local config = CPropBaseConfigMgr:Inst():GetConfig( eGRT_Resource, nCurEquipID )
	if config.nRowIndex == -1 then
		local NetMsg = CUsingSkin:new();
		NetMsg.nSkinID = 1;
		g_App:SendShellMsg( NetMsg ); 
	end
end

function CGameClient:GetNetMusicLoadPath()
	return self.m_szNetMusicCachePath or "";
end

function CGameClient:CheckCurMusicInCache( nMusicID )
	local bNetMusic = CMusicConfig:Inst():IsNetMusic( nMusicID );
	if bNetMusic then
		local szMusicPath =  CMusicConfig:Inst():GetMusicPath( nMusicID );
		local szFileName = string.sub( szMusicPath, 10 );
		if not CPathMgr.IsFileExist( self.m_szNetMusicCachePath .. szFileName ) then
			return false;
		end
	end
	return true;
end

function CGameClient:IsHaveMusic( nMusicID )
	local PlayerData = g_App:GetMainPlayerData().m_HaveMusic;
	for i = 0, PlayerData:GetDataMaxCount() -1 do
		if math.floor(  PlayerData:GetData( i ) / 10 ) == math.floor( nMusicID / 10 ) then
			return true;
		end
	end
	return false;
end

function CGameClient:SetSelfTodayScore( nSelfScore )
	self:GetGameStart().m_tblRankData.nTodayScore = nSelfScore;
end

function CGameClient:SetFriendTodayScore( szEndlessName, nEndlessDay, szLimitName, nLimitDay, szTeamName, nTeamDay )
	self:GetGameStart().m_tblRankData.szFriendName[eGradeType_EndlessToday] = szEndlessName;
	self:GetGameStart().m_tblRankData.nFriendScore[eGradeType_EndlessToday] = nEndlessDay;
	self:GetGameStart().m_tblRankData.szFriendName[eGradeType_LimitToday] = szLimitName;
	self:GetGameStart().m_tblRankData.nFriendScore[eGradeType_LimitToday] = nLimitDay;
	self:GetGameStart().m_tblRankData.szFriendName[eGradeType_TeamToday] = szTeamName;
	self:GetGameStart().m_tblRankData.nFriendScore[eGradeType_TeamToday] = nTeamDay;
end

function CGameClient:SetWorldTodayScore( szEndlessName, nEndlessDay, szLimitName, nLimitDay, szTeamName, nTeamDay )
	print( " CGameClient:SetWorldTodayScore ", szEndlessName, nEndlessDay, szLimitName, nLimitDay, szTeamName, nTeamDay );
	self:GetGameStart().m_tblRankData.szWorldName[eGradeType_EndlessToday] = szEndlessName;
	self:GetGameStart().m_tblRankData.nWorldScore[eGradeType_EndlessToday] = nEndlessDay;
	self:GetGameStart().m_tblRankData.szWorldName[eGradeType_LimitToday] = szLimitName;
	self:GetGameStart().m_tblRankData.nWorldScore[eGradeType_LimitToday] = nLimitDay;
	self:GetGameStart().m_tblRankData.szWorldName[eGradeType_TeamToday] = szTeamName;
	self:GetGameStart().m_tblRankData.nWorldScore[eGradeType_TeamToday] = nTeamDay;
	if self:GetScene() then
		self:GetScene():UpdateRank();
	end
end

function CGameClient:GetCurRankData( nTodayType )
	local tblAllData = CPlayerGradeInfoMgr:Instance():GetAllDataNew();
	if not tblAllData then return end
	local tblRankData = {};
	self:GetGameStart().m_tblRankData.nTodayScore = tblAllData[nTodayType].nAllScore or 0;
	tblRankData.nTodayScore = self:GetGameStart().m_tblRankData.nTodayScore or 0;
	tblRankData.szFriendName = self:GetGameStart().m_tblRankData.szFriendName[nTodayType] or "";
	tblRankData.nFriendScore = self:GetGameStart().m_tblRankData.nFriendScore[nTodayType] or 0;
	tblRankData.szWorldName = self:GetGameStart().m_tblRankData.szWorldName[nTodayType] or "";
	tblRankData.nWorldScore = self:GetGameStart().m_tblRankData.nWorldScore[nTodayType] or 0;

	if nTodayType == eGradeType_EndlessToday then
		local pScene = g_App:GetScene();
		if pScene then
			self:GetGameStart().m_tblRankData.nTodayScore = CPlayerGradeInfoMgr:Instance():GetAllDataNew()[eGradeType_EndlessToday].nAreaScore;
			tblRankData.nTodayScore = self:GetGameStart().m_tblRankData.nTodayScore / pScene:GetNodeTotal();
			tblRankData.nFriendScore = tblRankData.nFriendScore / pScene:GetNodeTotal();
			tblRankData.nWorldScore = tblRankData.nWorldScore / pScene:GetNodeTotal();

			tblRankData.nTodayScore = tblRankData.nTodayScore > 1 and 1 or tblRankData.nTodayScore;
			tblRankData.nFriendScore = tblRankData.nFriendScore > 1 and 1 or tblRankData.nFriendScore;
			tblRankData.nWorldScore = tblRankData.nWorldScore > 1 and 1 or tblRankData.nWorldScore;
		end
	end

	return tblRankData;
end

function CGameClient:OnGuidePlayer()
	local pGameMain = g_App:GetGameMain();
	pGameMain:PauseSceneMusic( true );
	g_App:GetGuideVideoWnd():PlayVideo( function()
		local pGameMain = g_App:GetGameMain();
		pGameMain:PauseSceneMusic( false );
	end );
end

function CGameClient:SetEndlessResult( nArea, nMiss )
	--print( "11111111111111111111 CGameClient:SetEndlessResult", g_App:GetFirstEvent( eFE_PlayGame ) )
	local bFirstPlay = not g_App:GetFirstEvent( eFE_PlayGame );
	local nCurGameScore = g_App:GetMainPlayerData().m_CharBaseData:GetAllGameScore();
	if bFirstPlay then 
		if nArea < CSnakeConstant:Inst():GetFirstEndlessArea() or nMiss > CSnakeConstant:Inst():GetFirstEndlessMiss() then
			self:GetGameStart().m_bShowTeachTip = true;
			return;
		end
	else
		if nArea < CSnakeConstant:Inst():GetAfterEndlessArea() or nMiss > CSnakeConstant:Inst():GetAfterEndlessMiss() then
			self:GetGameStart().m_nSerialBad = self:GetGameStart().m_nSerialBad + 1;
		else
			self:GetGameStart().m_nSerialBad = 0;
		end
		if self:GetGameStart().m_nSerialBad >= 2 then
			self:GetGameStart().m_bShowTeachTip = true;
			self:GetGameStart().m_nSerialBad = 0;
		else
			self:GetGameStart().m_bShowTeachTip = false;
		end
	end
end

function CGameClient:GetEndlessResult()
	return self:GetGameStart().m_bShowTeachTip;
end

function CGameClient:GetWndFieldReconnectLast()
	return self.m_pWndFieldReconnectLast;
end

function CGameClient:GetWndFieldReconnect()
	return self.m_pWndFieldReconnect;
end

function CGameClient:GetLimitModeOpenFlag()
	return self.m_bGetLimitModeOpenPrize;
end

function CGameClient:GetTeamModeOpenFlag()
	return self.m_bGetTeamModeOpenPrize;
end

function CGameClient:SetLimitModeOpenFlagTrue()
	self.m_bGetLimitModeOpenPrize = true;
end

function CGameClient:SetTeamModeOpenFlagTrue()
	self.m_bGetTeamModeOpenPrize = true;
end

function CGameClient:PostStartCooling( nSkillID, nCooling )
	self.m_GameMain:PostStartCooling( nCooling );
end

function CGameClient:PostEndCooling( nSkillID )
	self.m_GameMain:PostEndCooling();
end

function CGameClient:GetShareConfig()
	if not g_data_channel_share then
		return nil;
	end
	local tblShare = g_data_channel_share[self:GetChannel()];
	return tblShare and tblShare or g_data_channel_share["default"];
end

function CGameClient:GetPropCount( nBigID, nSmallID )
	if nBigID == eGRT_Resource then
		if nSmallID >= eResourceType_Max_Count then
			return 0;
		end
		return g_App:GetMainPlayerData().m_Resource:GetData( nSmallID );
	end
	return 0;
end

function CGameClient:GetLadderStarBySeason( nSeason )
	return self:GetMainPlayerData().m_SeasonStarNum:GetData( nSeason % g_App:GetMainPlayerData().m_SeasonStarNum:GetDataMaxCount() );
end

function CGameClient:GetCurLadderStar()
	return self:GetLadderStarBySeason( self:GetCurLadderSeason() );
end

function CGameClient:GetCurRaceScore()
	local nCurSeason = self:GetCurLadderSeason()
	return self:GetMainPlayerData().m_RaceScore:GetData( nCurSeason % self:GetMainPlayerData().m_RaceScore:GetDataMaxCount() );
end

function CGameClient:GetFirstEvent( nIndex )
	assert( nIndex < eFE_Count );
	local nAryIndex = math.floor( nIndex / 32 );
	local nValue32 = self:GetMainPlayerData().m_FirstEvent:GetData( nAryIndex );
	return BitAnd( LeftShift( 1, ( nIndex % 32 ) ), nValue32 ) ~= 0;
end

function CGameClient:GetSeasonMaxStar()
	local nMaxStar = 0;
	for i = 0, self:GetCurLadderSeason() do
		local nCurStar = g_App:GetMainPlayerData().m_SeasonStarNum:GetData( i % g_App:GetMainPlayerData().m_SeasonStarNum:GetDataMaxCount() );
		if nCurStar > nMaxStar then
			nMaxStar = nCurStar;
		end
	end
	return nMaxStar;
end

function CGameClient:GetFragmentCount( nFragmentID )
	local nCount = 0 ;
	local PlayerData = g_App:GetMainPlayerData().m_FragmentData;
	for i = 1, PlayerData:GetDataMaxCount() do
		local nID = PlayerData:GetData( i - 1 ):GetFragmentID();
		if nID == nFragmentID then
			return PlayerData:GetData( i - 1 ):GetCount();
		end
	end
	return nCount;
end

function CGameClient:Rename( szNickName )
	local nCurNickName = self:GetMainPlayerData().m_CharBaseData:GetNickName();
	local nLen = string.len( szNickName );
	if nCurNickName == szNickName then
		return self:HideMsg( self:GetString( "mingzichongming" ) );
	elseif nLen < CHARNAME_MIN_BYTE_SIZE or nLen > CHARNAME_BYTE_SIZE then
		return self:HideMsg( self:GetString( "mingzitaichang" ) );
	elseif not CUSFilter:Inst():CheckString( szNickName, nLen + 1, eFilter_RoleName ) then
		return self:HideMsg( self:GetString( "hanyoufeifazi" ) );
	elseif not self:GetWorldConn() then
		return self:HideMsg( self:GetString( "weilianwang" ) );
	end

	local NetMsg = CRename:new();
	NetMsg.m_szCharName = szNickName;
	self:SendShellMsg( NetMsg );
end

function CGameClient:GetNickName()
	return self:GetMainPlayerData().m_CharBaseData:GetNickName();
end

function CGameClient:GetSkillInfoByID( nSkillID )
	if nSkillID == 0 then
		return nil;
	end
	for i = 1, Max_SkillDevelop_Num do
		local SkillInfo = g_App:GetMainPlayerData().m_DBSkillData:GetData( i - 1 );
		local tblSkill = {};
		tblSkill.nDBSkillID = SkillInfo:GetSkillID();
		tblSkill.nDBSkillState = SkillInfo:GetState();
		tblSkill.nDBSkillLevel = SkillInfo:GetLevel();
		if tblSkill.nDBSkillID ~= 0 then
			if tblSkill.nDBSkillID == nSkillID then
				return tblSkill;
			end
		else
			return nil;
		end
	end
end

function CGameClient:GetRaceCost( nRaceID, nRaceType )
	local nRaceNum = self:GetMainPlayerData().m_CharBaseData:GetFirstRaceNum();
	if nRaceType ~= eMRT_LimitRace then
		nRaceNum = self:GetMainPlayerData().m_CharBaseData:GetFirstTeamRaceNum();
	end
	if nRaceID == 2 then
		nRaceNum = self:GetMainPlayerData().m_CharBaseData:GetSecondRaceNum();
		if nRaceType ~= eMRT_LimitRace then
			nRaceNum = self:GetMainPlayerData().m_CharBaseData:GetSecondTeamRaceNum();
		end
	end
	local nConfigHeight = g_tblTabFile.day_race_cost.nRowCount;
	local nMaxRaceNum = g_tblTabFile.day_race_cost:GetRow(nConfigHeight - 1)["nID"];
	nRaceNum = nRaceNum >= nMaxRaceNum and nMaxRaceNum or ( nRaceNum + 1 );
	local nCostType = g_tblTabFile.day_race_cost[nRaceNum]["nEnterCostType"];
	local nCostValue = g_tblTabFile.day_race_cost[nRaceNum]["nEnterCostValue"];
	if nRaceType ~= eMRT_LimitRace then
		nCostType = g_tblTabFile.day_race_cost[nRaceNum]["nTeamEnterCostType"];
		nCostValue = g_tblTabFile.day_race_cost[nRaceNum]["nTeamEnterCostValue"];
	end
	return nCostType, nCostValue;
end

function CGameClient:Recharge( szProductID )
	-- 生成规则为(分隔符为“_”)：渠道+账号ID+当前毫秒时间+随机数（0-9999）
	local nAccountID = self:GetAccountID();
	if nAccountID == 0 then
		return;
	end
	local szChannel = self:GetChannel();
	local szCurTime = tostring( GetNatureTime() );
	local szRandom = tostring( math.random( 0, 10000 ) );
	local szOrderID = szChannel .. "_" .. tostring( nAccountID ) .. "_" .. szCurTime .. "_" .. szRandom;
	local szServerID = tostring( self:GetServerID() );
	local szProductID = tostring( szProductID );
	local szJSON = "{" 
		.. "\"nServerID\":\"" .. szServerID .. "\","
		.. "\"szAccountID\":\"" .. tostring( nAccountID ) .. "\","
		.. "\"szOrderID\":\"" .. szOrderID .. "\","
		.. "\"szChannel\":\"" .. szChannel .. "\","
		.. "\"szProductID\":\"" .. szProductID .. "\"}";
	self:SendSDKCmd( eLoginAndPayCmd_PAY, szJSON );
end

function CGameClient:GetAccountLevel()
	local nAccountExp = self:GetMainPlayerData().m_CharBaseData:GetExp();
	local nRowMax = g_tblTabFile.playerlevel.nRowCount;
	for i = 1, nRowMax do
		local nExpMin = CTableConfigMgr:Inst():GetConfigNumber( "playerlevel", i, "nExpMin" );
		local nExpMax = CTableConfigMgr:Inst():GetConfigNumber( "playerlevel", i, "nExpMax" );
		if nExpMax < 0 then
			nExpMax = 0xffffffff;
		end
		if nAccountExp >= nExpMin and nAccountExp < nExpMax then
			return i;
		end
	end
end

--判断限时模式是否可以使用技能  
function CGameClient:CouldUseSkill()
	return g_App:GetFirstEvent( eFE_GetTeamModeOpenPrize );
end

function CGameClient:GetGameScore( nRoomType )
	local MainData = self:GetMainPlayerData().m_CharBaseData;
	if nRoomType == eRT_Endless then
		return MainData:GetEndlessGameScore();
	elseif nRoomType == eRT_LimitTime then
		return MainData:GetLimitGameScore();
	elseif nRoomType == eRT_Team then
		return MainData:GetTeamGameScore();
	end
end

function CGameClient:GetAccumulateObtainGold()
	local MainData = self:GetMainPlayerData().m_CharBaseData;
	return MainData:GetAccumulateCouldObtainGold();
end

function CGameClient:GetSharePageUrl()
	local tblShareConfig = self:GetShareConfig();
	if not tblShareConfig["bShareLink"] then
		return "";
	end
	return tblShareConfig["szPageUrl"] 
	.. "?userid=" .. self:GetAccountID()
	.."&channel=" .. self:GetChannel();
end

function CGameClient:CreatePageShare( szSrcName )
	local nAccountID = self:GetAccountID();
	local szChannel = self:GetChannel();
	local szNickName = g_App:GetMainPlayerData().m_CharBaseData:GetNickName();
	local tblShareConfig = self:GetShareConfig();

	local pContext = CShareContext:new( szSrcName );
	local szTitle = g_App:GetString( "fenxiangbiaoti" );
	local szWXTimelineTitle = g_App:GetString( "pengyouquanneirong" );
	local szContent = g_App:GetString( "fenxiangneirong" );
	local szImageUrl = tblShareConfig["szImageUrl"];
	local szPageUrl = self:GetSharePageUrl();

	if string.len( szPageUrl ) == 0 then
		pContext:SetImageData( szImageUrl .. "&nickname=" .. szNickName );
	else
		pContext:SetPageData( szTitle, szWXTimelineTitle, szContent, szImageUrl, szPageUrl )
	end

	return pContext;
end

function CGameClient:CreateRecordUrl( nModeType, nScore, nRank, nHonor, nMinute, nSecond )
	local tblShareConfig = self:GetShareConfig();
	return tblShareConfig["szCreateImageUrl"] .. 
		"?nModeType=" .. nModeType .. 
		"&nScore=" .. nScore .. 
		"&nRank=" .. nRank .. 
		"&nHonor=" .. nHonor ..
		"&nMinute=" .. nMinute ..
		"&nSecond=" .. nSecond;
end

function CGameClient:CreateHonourUrl( nModeType, nScore, nRank, nHonor, nMinute, nSecond )
	local tblShareConfig = self:GetShareConfig();
	return tblShareConfig["szCreateHonourImageUrl"] .. 
		"?nModeType=" .. nModeType .. 
		"&nScore=" .. nScore .. 
		"&nRank=" .. nRank .. 
		"&nHonor=" .. nHonor ..
		"&nMinute=" .. nMinute ..
		"&nSecond=" .. nSecond;
end

function CGameClient:IsUnlockAccountLevel()
	local bChargedVIP = g_App:GetMainPlayerData().m_CharBaseData:GetVipGetTime() ~= 0;
	local bDefaultOpenAccountLevel = CSnakeConstant:Inst():GetDefaultOpenAccountLevel() ~= 0;
	local bRainbowHistoryEnough = g_App:GetFirstEvent( eFE_HistoryRainbowEnough );
	return bChargedVIP or bDefaultOpenAccountLevel or bRainbowHistoryEnough;
end

function CGameClient:GetChannelShare()
	local szUrl = CGameAppClient.GetChannelShare( self );
	if string.len( szUrl ) == 0 then
		return "";
	end

	if string.find( szUrl, "http://" ) == 1 
	or string.find( szUrl, "https://" ) == 1 then
		szUrl = szUrl .. "?time=" .. tostring( GetNatureTime() );
	end	

	return szUrl;
end

function CGameClient:Quit()
	local bIsWithSDK = g_App:IsWithSDK();
	if bIsWithSDK then
		g_App:SendSDKCmd( eLoginAndPayCmd_EXIT_GAME, "" );
	else
		CGameAppClient.Quit( self );
	end
end

function CGameClient:CommitCharData( nType )
	local MainData = self:GetMainPlayerData();
	local tblData = 
	{
		["nServerID"]			= tostring( self:GetServerID() );
		["szCharID"]			= tostring( self:GetAccountID() );
		["szCharName"]			= tostring( MainData.m_CharBaseData:GetNickName() );
		["szCharCreateTime"]	= tostring( MainData.m_CharBaseData:GetCreateTime() );
		["szServerName"]		= tostring( self:GetServerID() );
		["nGlod"]				= tostring( self:GetPropCount( eGRT_Resource, eResourceType_Gold ) );
		["nSubmitType"]			= tostring( nType );
	};
	g_App:SendSDKCmd( eLoginAndPayCmd_ROLE_DATA, json.encode( tblData ) );
end

function CGameClient:IsGameSwitch( eType )
	return BitAnd( LeftShift( 1, eType ), self.m_nSwitch ) ~= 0;
end

function CGameClient:ShowPlayerInfo( nAccountID )
	if self.m_GameStart:IsShow() then
		return self.m_GameStart:ShowPlayerInfo( nAccountID );
	end
	if self.m_GameMain:IsShow() then
		return self.m_GameMain:ShowPlayerInfo( nAccountID );
	end
end

g_App = ClassCast( CGameClient, CGameAppClient.Inst() );
g_App:OnStart();

--endregion