--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local CSettingWnd_Button_Left = 1;
local CSettingWnd_Button_Right = 2;
local CSettingWnd_Button_Custom = 3;
local CSettingWnd_FightSound_Small = 4;
local CSettingWnd_FightSound_Off = 5;
local CSettingWnd_FightSound_Middle = 6;
local CSettingWnd_FightSound_Big = 7;

function CSettingWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CSettingWnd:OnCreated()
	self.m_pBtnMusic = self:GetDlgChild( "B_yinyue" );
	self.m_pBtnSound = self:GetDlgChild( "B_yinxiao" );
	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_pWndAccount = self:GetDlgChild( "E_id" );
	self.m_pBtnWeChat = self:GetDlgChild( "B_weixin" );
	self.m_pBtnQQ = self:GetDlgChild( "B_qq" );
	self.m_pBtnPrize = self:GetDlgChild( "B_lingqu" );
	self.m_pInputPrizeCode = self:GetDlgChild( "W_lipinma" );
	self.m_pBtnSwitch = self:GetDlgChild( "B_qiehuan" );
	self.m_pBtnGuestUpgrade = self:GetDlgChild( "B_zhuanzheng" );
	self.m_pBtnShowBtnSetting = self:GetDlgChild( "yulan" );
	self.m_pBtnFightSoundSmall = self:GetDlgChild( "B_zdyinxiao0" );
	self.m_pBtnFightSoundClose = self:GetDlgChild( "B_zdyinxiao1" );
	self.m_pBtnFightSoundMiddle = self:GetDlgChild( "B_zdyinxiao2" );
	self.m_pBtnFightSoundBig = self:GetDlgChild( "B_zdyinxiao3" );
	self.m_pBtnProtocol = self:GetDlgChild( "B_xieyi" );
	
	self.m_pBtnSettingWnd = CBtnSettingWnd:new( "gui/cfg/fsj_anjian.gui", self, 1 );

	local IniFile =	g_App:GetIniFile();
	self.m_pBtnFightSoundSmall:SetCheck( IniFile:GetInteger( "Setting", "FightSound", 0 ) == 1 );
	self.m_pBtnFightSoundClose:SetCheck( IniFile:GetInteger( "Setting", "FightSound", 0 ) == 0 );
	self.m_pBtnFightSoundMiddle:SetCheck( IniFile:GetInteger( "Setting", "FightSound", 0 ) == 2 );
	self.m_pBtnFightSoundBig:SetCheck( IniFile:GetInteger( "Setting", "FightSound", 0 ) == 3 );
	self:UpdateConfig( nil );
	
	self:AddCloseAction( "B_close" );
	self.m_pBtnPrize:AddActionListener( "OnPrize", self );
	self.m_pBtnShowBtnSetting:AddActionListener( "OnShowBtnSetting", self );
	self.m_pBtnSwitch:AddActionListener( "OnClickSwitch", self );
	self.m_pBtnGuestUpgrade:AddActionListener( "OnClientGuestUpgrade", self );
	self.m_pBtnProtocol:AddClickListener( "OnClickProtocol", self );

	self.m_pBtnFightSoundSmall:AddActionListener( "UpdateConfig", self );
	self.m_pBtnFightSoundClose:AddActionListener( "UpdateConfig", self );
	self.m_pBtnFightSoundMiddle:AddActionListener( "UpdateConfig", self );
	self.m_pBtnFightSoundBig:AddActionListener( "UpdateConfig", self );
	
	self.m_pBtnFightSoundSmall.m_nSettingNum = CSettingWnd_FightSound_Small;
	self.m_pBtnFightSoundClose.m_nSettingNum = CSettingWnd_FightSound_Off;
	self.m_pBtnFightSoundMiddle.m_nSettingNum = CSettingWnd_FightSound_Middle;
	self.m_pBtnFightSoundBig.m_nSettingNum = CSettingWnd_FightSound_Big;
    
	g_App.m_EventDispatcher:AddEventListener( "LoginSucc", "RefreshAccount", self );
	self:RefreshAccount();
end

function CSettingWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "LoginSucc", "RefreshAccount", self );
end

function CSettingWnd:RefreshAccount()
	local bGuest = g_App:GetWorldConn():IsGuest();
	self.m_pBtnSwitch:ShowWnd( not bGuest );
	self.m_pBtnGuestUpgrade:ShowWnd( bGuest );
	self.m_pWndAccount:SetWndText( g_App:GetShowAccountID() );
end

function CSettingWnd:OnClose()
	self:ShowWnd( false );
end

function CSettingWnd:OnClickSwitch()
	local bIsWithSDK = g_App:IsWithSDK();
	if bIsWithSDK then
		g_App:SendSDKCmd( eLoginAndPayCmd_LOGOUT, "" );
	else
		g_App:OnResult( eLoginAndPayResult_LOGOUT_SUCCESS, "" );
	end
end

function CSettingWnd:OnClientGuestUpgrade()
	if not g_App:GetWorldConn():IsGuest() then
		self:RefreshAccount();
		return;
	end

	g_App:SendSDKCmd( eLoginAndPayCmd_GUEST_UPGRADE, "" );
end

function CSettingWnd:UpdateConfig( Event )
	local IniFile =	g_App:GetIniFile();
	local nFightsound = 0;
	if self.m_pBtnFightSoundClose:GetCheck() then 
		nFightsound = 0;
	elseif self.m_pBtnFightSoundSmall:GetCheck() then
		nFightsound = 1;
	elseif self.m_pBtnFightSoundMiddle:GetCheck() then
		nFightsound = 2;
	elseif self.m_pBtnFightSoundBig:GetCheck() then
		nFightsound = 3;
	end

	IniFile:WriteInteger( "Setting", "FightSound", nFightsound );
	IniFile:Save();

	local pWorldConn = g_App:GetWorldConn();
	if not Event or not Event.m_Target or not pWorldConn then
		return;
	end

	local NetMsg = CSettingLog:new();
	NetMsg.nSettingNum = Event.m_Target.m_nSettingNum;
	NetMsg.szSettingName = g_App:GetString( "setting_num"..tostring( Event.m_Target.m_nSettingNum ) );
	pWorldConn:SendShellMsg( NetMsg );
end

function CSettingWnd:OnPrize()
	local NetMsg = CQueryActivateCode:new();
	NetMsg.szKey = self.m_pInputPrizeCode:GetWndText();
	g_App:SendShellMsg( NetMsg );
end

function CSettingWnd:OnShowBtnSetting()
    self.m_pBtnSettingWnd:ShowAndSetFocus();
end

function CSettingWnd:OnClickProtocol()
	g_App:GetGameStart().m_pWndTip:ShowTipWnd( eShowTipType_Setting );
end

--endregion
