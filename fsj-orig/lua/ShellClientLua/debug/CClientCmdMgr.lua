--region CClientCmdMgr.lua
--Date 2015-12-24

CClientCmdMgr.s_CmdType = {}
CClientCmdMgr.s_CmdType["/s "] = 1;
CClientCmdMgr.s_CmdType["/sp "] = 2;
CClientCmdMgr.s_CmdType["/w "] = 3;
CClientCmdMgr.s_CmdType["/wp "] = 4;

function CClientCmdMgr:Ctor()
	CCmdMgrBase.Ctor( self );
	self.m_wndInput = CCmdInput:new();
	local RootWnd = g_App:GetGUIMgr():GetRootWnd();
	self.m_wndInput:CreateFromRes( "gui/cfg/debug_input.gui", RootWnd, 1 );
end

function CClientCmdMgr:ShowDebugInput()
	self.m_wndInput:ShowWnd( not self.m_wndInput:IsShow() );
end

function CClientCmdMgr.SubParam( szInputText )
    local pos = string.find( szInputText, " " );
    if pos ~= nil then
        local beg = string.find( szInputText, "%w",pos );
        szInputText = string.sub( szInputText,beg );
        return szInputText;
    else
        HandleOutPutText( "Illegal Command!!", ChannelType );
        return;
    end
end

function CClientCmdMgr:CheckSpecialCmd( szInputText )
    if szInputText and string.sub( szInputText, 1, 1 ) ~= "/" then
		return true;
	end

    local nCmdType;
	for sType, nCmdType in pairs( CClientCmdMgr.s_CmdType ) do
		if string.find( szInputText, sType ) then
			szInputText = CClientCmdMgr.SubParam( szInputText );
			if szInputText == nil then
				return;
			end
			if sType == "/w " then
				--发给world
				if not g_App:GetWorldConn() then
					return;
				end
				local NetMsg = CSendWorldGMCmd:new();
				NetMsg.m_scritp = szInputText;
				g_App:GetWorldConn():SendShellMsg( NetMsg );
			elseif sType == "/s " then
				if not g_App:GetFieldConn() then
					return;
				end
				local NetMsg = CSendScriptedCmd:new();
				NetMsg.m_scritp = szInputText;
				g_App:GetFieldConn():SendShellMsg( NetMsg );
			end
			return;
		end
	end

	self.m_Player = g_App:GetDirector()
    if string.find( szInputText, "/" ) ~= nil then
        szInputText = string.sub( szInputText, 2 )
        self:ParseCmd( szInputText );
    end
	self.m_Player = nil
end

function CClientCmdMgr:TriggerHyperLink( strLinkID, wndRichWnd, nUnitID )
	self.m_Player = g_App:GetDirector()
	self.m_wndRichWnd = wndRichWnd
	self.m_nUnitID = nUnitID
	self:ParseCmd( strLinkID );
	self.m_Player = nil
	self.m_wndRichWnd = nil
	self.m_nUnitID = nil
end

function CClientCmdMgr:RegisterAll()
	CCmdMgrBase.RegisterAll( self );

    self:Register( "chat", 
		function()
            self:ShowDebugInput();
		end );

    self:Register( "dumpwnd",
        function ( strName )
			local Wnd = g_App.m_wndGameMainState:GetDlgChild( strName )
				 or g_App.m_wndGameMainState;
			if Wnd then 
				Wnd:Dump( 0 );
				print( "---class obj----" );
				for k, v in pairs( Wnd ) do
					print( k,"=", v );
				end
            end
        end);

	self:Register( "setgasdelay", 
        function( min, max ) 
            local GasConnect = g_App:GetFieldConn();
            if GasConnect then
				GasConnect:SetNetDelay( min, max )
            end
        end );

	self:Register( "setworlddelay", 
        function( min, max ) 
            local WorldConnect = g_App:GetWorldConn()
            if WorldConnect then
				WorldConnect:SetNetDelay( min, max )
            end
        end );

	self:Register( "debug", 
		function( nLevel )
			g_App:SetDebugFlag( nLevel, true );
		end );

	self:Register( "framelimit", 
		function( nLimit )
			g_App:GetRenderer():SetBoolOption( 0, nLimit and nLimit ~= 0 )
		end );

	self:Register( "boolopt", 
		function( nType, nValue )
			g_App:GetRenderer():SetBoolOption( nType, nValue and nValue ~= 0 )
		end );

	self:Register( "intopt", 
		function( nType, nValue )
			g_App:GetRenderer():SetIntOption( nType, nValue )
		end );

	self:Register( "gui_debug", 
		function()
			g_App:GetGUIMgr():SetDebugMode( not g_App:GetGUIMgr():IsDebugMode() );
		end );

	self:Register( "profile", 
		function( nDelayTime )
		    g_App:EnableProfile( nDelayTime );
		end );		

	self:Register( "resolv", 
		function( nValue )
		    g_App:SetMaxResolution( nValue );
		end );	
			
	self:Register( "help", 
		function( nValue )
			g_App:GetRenderer():SetBoolOption( 0, false );
			g_App:SetDebugFlag( 1, true );
		end );		
			
	self:Register( "timescale",
		function( scale )
			local Renderer = g_App:GetRenderer();
			Renderer:SetRenderTimeScale( tonumber( scale or 1 ) );
		end );
		
	self:Register( "dumpres",
		function( n )
			local ResMgr = g_App:GetRenderer():GetResourceMgr();
			ResMgr:DumpResource();
		end );

	self:Register( "show",
		function( szWndName )
			g_App:GetWnd( szWndName ):ShowAndSetFocus();
		end );

	self:Register( "reloadshader",
		function( szWndName )
			local Renderer = g_App:GetRenderer();
			Renderer:ReloadShader();
		end );

	self:Register( "add_item",
		function( nLevel )
			local Scene = g_App:GetScene();
			local Player = g_App:GetDirector();
			if( Scene and Player ) then
				Scene:DropOut( Player:GetPixelPos(), tonumber( nLevel ) );
			end
		end );

	self:Register( "playvideo",
		function( szH264File, szAudio, nFrameInterval )
			if not szH264File or not szAudio then
				return;
			end

			if not g_App.m_VideoPlayer then
				g_App.m_VideoPlayer = CVideoWnd:new();
				g_App.m_VideoPlayer:CreatAsEmptyContain( g_App:GetGUIMgr():GetRootWnd() );
			end
			
			g_App.m_VideoPlayer:ShowWnd( true );
			g_App.m_VideoPlayer:SetFocus();
			g_App.m_VideoPlayer:Play( szH264File, szAudio, nFrameInterval )
		end );

	self:Register( "guide",
		function()
			CGuideMgr:Inst():Start();
		end );

	self:Register( "addnotice",
		function( szMsg, nGrade )
			g_App.m_NoticeBar:AddContent( szMsg, tonumber( nGrade or 0 ) );
		end );

	self:Register( "profile",
		function( nGrade )
			g_App:EnableProfile( tonumber( nGrade or 0 ) );
		end );
	
	self:Register( "balance",
		function( nRoomOverType )
			local pScene = g_App:GetScene();
			if not pScene then
				return;
			end

			local pWanfa = pScene:GetWanfa();
			if not pWanfa.Balance then
				print( "/balance only client!!!" );
				return;
			end
			pWanfa:Balance( nRoomOverType );
		end );

	self:Register( "getallmusic", 
		function()
			g_App:GetGameStart().m_WndMusic:GetAllMusicByGM();
		end );

	self:Register( "replay",
		function( szFileName )
			local nMusicID = g_App:GetSelectMusicID();
			local pScene = g_App:SwitchGame( 1, eRT_RecordTest, nMusicID );
			if not pScene then
				return;
			end
			pScene:ReplayFromFile( szFileName or "F:/client.record" );
		end );
		
	self:Register( "ForceCloseField",
		function()
			g_App:GetFieldConn():ForceClose();
		end );

	self:Register( "hide", 
		function ()
			self.m_wndInput:ShowWnd( false );
		end);

	self:Register( "InitSkill",
		function ( nID )
			g_App:GetGameMain():InitSkillButton( tonumber( nID ) );
		end )

	self:Register( "setmusicvolume",
		function( fMusicNum, fSoundNum )
			local pAudio = g_App:GetAudio();
			if not pAudio then
				return;
			end
			pAudio:SetMusicVolume( fMusicNum );
			pAudio:SetSoundVolume( fSoundNum );
		end )

	self:Register( "setdirectorai",
		function ( nID )
			local pDirector = g_App:GetDirector();
			if not pDirector then
				return;
			end
			pDirector:SetAI( nID );
		end )

	self:Register( "recharge", 
		function( szProductID )
			g_App:Recharge( szProductID );
		end );

	self:Register( "shop",
		function()
			g_App:GetGameStart():OpenDiamondShop();
		end );

	self:Register( "vip",
		function()
			g_App:GetGameStart():OpenVipWnd();
		end );

	self:Register( "sdkresult",
		function( nType, szInfo )
			g_App:OnResult( tonumber( nType ), szInfo );
		end );

	self:Register( "show",
		function( szWndName )
			local RootWnd = g_App:GetGUIMgr():GetRootWnd();
			local pWnd = RootWnd:GetDlgChild( szWndName );
			if not pWnd then	
				return;
			end
			pWnd:ShowWnd( not pWnd:IsShow() );
		end );

	self:Register( "joinroom",
		function( nTeamType, nRoomNum, nRaceID )
			if not g_App:GetFirstEvent( eFE_GetTeamModeOpenPrize ) then
				g_App:HideMsg( g_App:GetString( "kuaisuyaoqing5" ) );
				return;
			end
			nRoomNum = tonumber( nRoomNum );
			nTeamType = tonumber( nTeamType );
			nRaceID = tonumber( nRaceID );
			if nTeamType == eMRT_TeamRace
				or nTeamType == eMRT_TeamRaceBefore then
				local tblRaceData = {};
				tblRaceData.m_nRaceID = nRaceID;
				tblRaceData.m_nTeamID = nRoomNum;
				tblRaceData.m_nRoomType = nTeamType;
				--g_App:GetGameStart().m_pWndRace.m_pWndConfirmJoin:SetJoinData( tblRaceData );
				--g_App:GetGameStart().m_pWndRace.m_pWndConfirmJoin:ShowAndSetFocus();
				g_App:GetGameStart().m_pWndRace.m_pBtnTeam:SetCheck( true );
				g_App:GetGameStart().m_pWndConfirmJoin:SetJoinData( tblRaceData );
				g_App:GetGameStart().m_pWndConfirmJoin:ShowAndSetFocus();				
			else
				local NetMsg = CJoinTeam:new();
				NetMsg.nTeamID = nRoomNum;
				NetMsg.nTeamType = nTeamType;
				g_App:SendShellMsg( NetMsg );
			end
		end );

	self:Register( "show_time",
		function()
			local pWnd = g_App:GetGameStart().m_pWndCurTime;
			pWnd:ShowWnd( not pWnd:IsShow() );
		end );

	self:Register( "test_prize_show",
		function( ... )
			local tblItems = {};
			local tblItem = {};
			for n, value in ipairs{...} do
				if n % 3 == 1 then
					tblItem.m_nType = value;
				elseif n % 3 == 2 then
					tblItem.m_nTypeIndex = value;
				elseif n % 3 == 0 then
					tblItem.m_nCount = value;
					table.insert( tblItems, tblItem );
				end
			end
			local pGetStart = g_App:GetGameStart();
			pGetStart:NotifyPrizeTip( tblItems );
		end );

	self:Register( "showplayerinfo",
		function( nShowAccountID )
			g_App:ShowPlayerInfo( tonumber( nShowAccountID ) );
		end );

	self:Register( "playabs",
		function()
			g_App:SendSDKCmd( eLoginAndPayCmd_ABS, "" );
		end );

	self:Register( "listfile",
		function( nType )
			g_App:TestSystemFileList( nType );
		end );
end


--endregion
