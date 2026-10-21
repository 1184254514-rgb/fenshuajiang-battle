--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CGameLogin:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CGameLogin:OnCreated()
	self.m_tblServerAddress = {};
	self.m_tickLoadServer = CTick:new( "LoadServerList", self );
	self.m_tickLoadTimeout = CTick:new( "LoadServerList", self );
	self.m_tickOnDisconnectWorld = CTick:new( "OnWorldDisConnect", self );
	self.m_pInput = self:GetDlgChild( "W_text" );
	self.m_pBtnOK = self:GetDlgChild( "B_ok" );
	self.m_pBtnLogin = self:GetDlgChild( "denglu" );

	self.m_pInput:AddEventListener( GM_WM_EDIT_RETURN, "ConnectWorld", self );
	self.m_pBtnOK:AddActionListener( "ConnectWorld", self );
	self.m_pBtnLogin:AddActionListener( "ConnectWorld", self );
	
	local bIsWithSDK = g_App:IsWithSDK();
	self.m_pInput:ShowWnd( not bIsWithSDK );
	self.m_pBtnOK:ShowWnd( not bIsWithSDK );
	self.m_pBtnLogin:ShowWnd( bIsWithSDK );
end

function CGameLogin:OnDestroy()
	GetGammaFileMgr():RemoveListener( self )
	self.m_tickLoadServer:Stop();
	self.m_tickLoadTimeout:Stop();
	self.m_tickOnDisconnectWorld:Stop();
end

function CGameLogin:OnWndShow( bShow )
	if not bShow then
		GetGammaFileMgr():RemoveListener( self )
		self.m_tickLoadTimeout:Stop();
		self.m_tickLoadServer:Stop();
		return;
	end

	local szServerListUrl = g_App:GetServerListPath();
	if not szServerListUrl or string.len( szServerListUrl ) == 0 then
		print( "CGameLogin:OnWndShow no serverlist url" );
		g_App:MessageBox( g_App:GetString( "serverlistnotfound" ), 
		{
			[CMessageBox.OK] = function()
				g_App:Quit();
			end;
		} );
		return;
	end
	
	self:LoadServerList();
end

function CGameLogin:ConnectWorld()
	print( "CGameLogin:ConnectWorld" );
	if g_App:GetWorldConn() then
		g_App:GetWorldConn():ShellCmdClose();
	end

	local tblOpenServer = {};
	local szTips = nil;
	for k, v in pairs( self.m_tblServerAddress ) do
		if v["Open"] ~= 0 then
			table.insert( tblOpenServer, v );
		else
			szTips = szTips or v["Desc"];
		end
	end
	

	local nCount = #tblOpenServer;
	if nCount == 0 then
		print( "ServerList Not Load!!!" );
		g_App:MessageBox( szTips or g_App:GetString( "serverlistloading" ) );
		return;
	end

	local nIndex = math.random( 1, nCount );
	local tblAddress = tblOpenServer[nIndex];
	local pWorldConn =  CGameAppClient.ConnectToWorldServer( g_App, tblAddress["IP"], tblAddress["Port"] );
	if not pWorldConn then
		g_App:MessageBox( g_App:GetString( "weilianwangtishi" ) );
		return;
	end
	g_App:WaitMsg( true );
end

-- world连接断开分两种情况
-- 1是网路底层连接断开，比如无网路等
-- 2逻辑层断开，比如推出游戏，kick
-- kick有自己的提示，所以这里只需要提示非正常断开提示就可
function CGameLogin:OnWorldDisConnect( bShellDisconnect )
	print( "CGameLogin:OnWorldDisConnect" );
	g_App:WaitMsg( false );

	if not self.m_tickOnDisconnectWorld:IsRegisted() then
		self.bShellDisconnect = bShellDisconnect;
		self.m_tickOnDisconnectWorld:Start( 1 );
		return;
	end

	if not self.bShellDisconnect then
		g_App:MessageBox( g_App:GetString( "weilianwangtishi" ) );
	end

	self.m_tickOnDisconnectWorld:Stop();
	if self:IsShow() then
		return;
	end

	g_App:SwitchLogin();
end

--加载serverlist策略：
--加载设置3秒超时，
--加载失败后设置3秒延时重新加载
function CGameLogin:LoadServerList()
	print( "CGameLogin:LoadServerList" );
	GetGammaFileMgr():RemoveListener( self );
	local szServerListUrl = g_App:GetServerListPath();
	if string.find( szServerListUrl, "http://" ) == 1 or string.find( szServerListUrl, "https://" ) then
		szServerListUrl = szServerListUrl.."?time"..GetGammaTime();
	end	
	print( "LoadServerList : " .. szServerListUrl );
	GetGammaFileMgr():Load( szServerListUrl, true, false, self );
	self.m_tickLoadTimeout:Start( 3000 );
	self.m_tickLoadServer:Stop();
end

function CGameLogin:OnLoadedEnd( szFileName, pBuffer, nSize )
	local tabFile = CTabFile:new();
	if tabFile:Init( pBuffer, nSize ) then
		print( "CGameLogin:OnLoadedEnd succeeded" );
		local nMaxRow = tabFile:GetHeight();
		self.m_tblServerAddress = {};
		for i = 1, nMaxRow - 1 do
			self.m_tblServerAddress[i] = {};
			self.m_tblServerAddress[i]["IP"] = tabFile:GetString( i, "IP" );
			self.m_tblServerAddress[i]["Port"] = tabFile:GetString( i, "Port" );
			self.m_tblServerAddress[i]["Open"] = tabFile:GetInteger( i, "Open" );
			self.m_tblServerAddress[i]["Desc"] = tabFile:GetString( i, "Desc" );
			g_App:PreResolveDomain( self.m_tblServerAddress[i]["IP"] );
		end
	end
	self.m_tickLoadTimeout:Stop();
	self.m_tickLoadServer:Start( 3000 );

	if g_App:IsWithSDK() 
		and #self.m_tblServerAddress ~= 0 
		and not g_App:GetWorldConn()
		and not g_App:MessageIsShow() then
		self:ConnectWorld();
	end
end

function CGameLogin:Login()
	if not g_App:GetWorldConn() then
		return;
	end

	local bIsWithSDK = g_App:IsWithSDK();
	if bIsWithSDK then
		g_App:SendSDKCmd( eLoginAndPayCmd_LOGIN, "" );
	else
		local szAccount = self.m_pInput:GetWndText();
		if string.len( szAccount ) == 0 then
			return;
		end

		local szChannel = g_App:GetChannel();
		local szSDKType = g_App:GetSDKType();
		g_App:GetWorldConn():Login( szAccount, "", szChannel, szSDKType, "", "", "", 0, false );
	end
end

--endregion
