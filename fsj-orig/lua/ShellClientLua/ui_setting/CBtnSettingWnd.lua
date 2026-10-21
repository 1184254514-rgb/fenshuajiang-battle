--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local EChooseGroupTight = 2;
local EChooseGroupNormal = 3;
local EChooseGroupLoose = 4;
local nSpaceDis = 50;
local TblSubButtonName = 
{
	[1] = "shang",
	[2] = "xia",
	[3] = "zuo",
	[4] = "you"
}
local TblGroupName = 
{
	[1] = "group1",				--单个
	[2] = "group_jincou",		--紧凑
	[3] = "group",				--正常
	[4] = "group_kuansong",		--宽松
}
local TblSeparateSubPos = 
{
	[1] = { x = 140, y = 20 },
	[2] = { x = 140, y = 260 },
	[3] = { x = 20, y = 140 },
	[4] = { x = 260, y = 140 }
}

function CBtnSettingWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
	self.m_tblSubOriPos = {};
	self.m_tblSubPos = {};
	self.m_tblGroup = {};
end

function CBtnSettingWnd:OnCreated( szResName, wndParent, nLoadType )
	for i = 1, 4 do
		self.m_tblGroup[i] = self:GetDlgChild( "zidingyi."..TblGroupName[i] );
		if self.m_tblGroup[i] then
			if i == 1 then
				for j = 1, 4 do
					local SubButton = self.m_tblGroup[i]:GetDlgChild( TblSubButtonName[j] );
					SubButton:AddEventListener( GM_WM_DRAGSTART, "OnDragStart", self );
					SubButton:AddEventListener( GM_WM_DRAG, "OnDrag", self );
					SubButton:AddEventListener( GM_WM_DRAGEND, "OnDragEnd", self );
				end
			else
				self.m_tblGroup[i]:AddEventListener( GM_WM_DRAGSTART, "OnDragStart", self );
				self.m_tblGroup[i]:AddEventListener( GM_WM_DRAG, "OnDrag", self );
				self.m_tblGroup[i]:AddEventListener( GM_WM_DRAGEND, "OnDragEnd", self );
			end
		end
	end

    self.m_pBtnSkill = self:GetDlgChild( "zidingyi.B_jineng" );
    self.m_pOk = self:GetDlgChild( "baocun" );
    self.m_pReset = self:GetDlgChild( "huanyuan" );
    self.m_pClose = self:GetDlgChild( "close" );
	self.m_pOk:AddActionListener( "OnOK", self );
	self.m_pReset:AddActionListener( "OnReset", self );
	self.m_pClose:AddActionListener( "OnClose", self );	
	
	self.m_pBtnGroupConfig = self:GetDlgChild( "kongzhi.zuhe" );
	self.m_pBtnSeparateConfig = self:GetDlgChild( "kongzhi.dange" );
	self.m_pBtnGroupNormalConfig = self:GetDlgChild( "buju.zhengchang" );
	self.m_pBtnGroupLooseConfig = self:GetDlgChild( "buju.kuansong" );
	self.m_pBtnGroupTightConfig = self:GetDlgChild( "buju.jincou" );
	self.m_pBtnGroupConfig:AddActionListener( "OnClickConfig", self );
	self.m_pBtnSeparateConfig:AddActionListener( "OnClickConfig", self );
	self.m_pBtnGroupNormalConfig:AddActionListener( "OnClickConfig", self );
	self.m_pBtnGroupLooseConfig:AddActionListener( "OnClickConfig", self );
	self.m_pBtnGroupTightConfig:AddActionListener( "OnClickConfig", self );

    self.m_pBtnSkill:AddEventListener( GM_WM_DRAGSTART, "OnDragStart", self );
    self.m_pBtnSkill:AddEventListener( GM_WM_DRAG, "OnDrag", self );
    self.m_pBtnSkill:AddEventListener( GM_WM_DRAGEND, "OnDragEnd", self );

	self:InitConfigCheckButton();
	self:InitChooseBtnPos();
end

function CBtnSettingWnd:OnWndShow( bShow )
    if bShow then
        local iniFile = g_App:GetIniFile();
		self:InitChooseBtnPos();
        self.m_pBtnSkill:SetLocalX( self:GetWndWidth() - self.m_pBtnSkill:GetWndWidth() - 90 - iniFile:GetInteger( "Setting", "ButtonX1", 0 ) );
        self.m_pBtnSkill:SetLocalY( self:GetWndHeight() - self.m_pBtnSkill:GetWndHeight() - 90 - iniFile:GetInteger( "Setting", "ButtonY1", 0 ) );
    end
end

function CBtnSettingWnd:InitConfigCheckButton()
	local bChooseSub = g_App:GetIniFile():GetInteger( "Setting", "BtnConfigChooseSub", 0 ) == 1;
	local nChooseGroup = g_App:GetIniFile():GetInteger( "Setting", "BtnConfigChooseGroup", EChooseGroupNormal );
	self.m_pBtnSeparateConfig:SetCheck( bChooseSub );
	self.m_pBtnGroupConfig:SetCheck( not bChooseSub );
	self.m_pBtnGroupTightConfig:SetCheck( not bChooseSub and nChooseGroup == EChooseGroupTight );
	self.m_pBtnGroupNormalConfig:SetCheck( not bChooseSub and nChooseGroup == EChooseGroupNormal );
	self.m_pBtnGroupLooseConfig:SetCheck( not bChooseSub and nChooseGroup == EChooseGroupLoose );
	self:OnClickConfig();
end

function CBtnSettingWnd:OnClickConfig()
	if self.m_pBtnSeparateConfig:GetCheck() then
		self.m_BtnChooseGroup = self.m_tblGroup[1];		
		self.m_pBtnGroupTightConfig:SetCheck( false );
		self.m_pBtnGroupNormalConfig:SetCheck( false );
		self.m_pBtnGroupLooseConfig:SetCheck( false );
		self:GetDlgChild( "buju" ):EnableWnd( false );
	else
		local nChooseType = g_App:GetIniFile():GetInteger( "Setting", "BtnConfigChooseGroup", EChooseGroupNormal );
		if self.m_pBtnGroupTightConfig:GetCheck() then
			self.m_BtnChooseGroup = self.m_tblGroup[2];
		elseif self.m_pBtnGroupLooseConfig:GetCheck() then
			self.m_BtnChooseGroup = self.m_tblGroup[4];
		elseif self.m_pBtnGroupNormalConfig:GetCheck() then
			self.m_BtnChooseGroup = self.m_tblGroup[3];
		else				
			self.m_pBtnGroupTightConfig:SetCheck( nChooseType == EChooseGroupTight );
			self.m_pBtnGroupNormalConfig:SetCheck( nChooseType == EChooseGroupNormal );
			self.m_pBtnGroupLooseConfig:SetCheck( nChooseType == EChooseGroupLoose );
			self.m_BtnChooseGroup = self.m_tblGroup[nChooseType];
		end
		self:GetDlgChild( "buju" ):EnableWnd( true );
	end
	for i = 1, 4 do
		self.m_tblGroup[i]:ShowWnd( false );
	end
	self.m_BtnChooseGroup:ShowWnd( true );
end

function CBtnSettingWnd:InitChooseBtnPos()
	local IniFile = g_App:GetIniFile();
	self.m_BtnChooseGroup:SetLocalX( IniFile:GetInteger( "Setting", "ButtonX", 0 ) );
	local nBtnConfigGroupLocalY = self:GetWndHeight() - self.m_BtnChooseGroup:GetWndHeight();
	self.m_BtnChooseGroup:SetLocalY( IniFile:GetInteger( "Setting", "ButtonY", nBtnConfigGroupLocalY ) );
	if g_App:GetIniFile():GetInteger( "Setting", "BtnConfigChooseSub", 0 ) == 1 then
		for i = 1, 4 do
			local SubBtn = self.m_BtnChooseGroup:GetDlgChild( TblSubButtonName[i] );
			SubBtn:SetLocalX( IniFile:GetInteger( "Setting", "BtnConfigSubLocalX"..i, TblSeparateSubPos[i].x ) ); 
			SubBtn:SetLocalY( IniFile:GetInteger( "Setting", "BtnConfigSubLocalY"..i, TblSeparateSubPos[i].y ) );
		end
	end
end

function CBtnSettingWnd:OnOK()
    local iniFile = g_App:GetIniFile();
    iniFile:WriteInteger( "Setting", "ButtonX", self.m_BtnChooseGroup:GetLocalX() );
    iniFile:WriteInteger( "Setting", "ButtonY", self.m_BtnChooseGroup:GetLocalY() );
	iniFile:WriteInteger( "Setting", "BtnConfigChooseSub", self.m_pBtnSeparateConfig:GetCheck() and 1 or 0 );
	local nChooseGroupType = EChooseGroupNormal;
	if self.m_pBtnGroupTightConfig:GetCheck() then
		nChooseGroupType = EChooseGroupTight;
	elseif self.m_pBtnGroupLooseConfig:GetCheck() then
		nChooseGroupType = EChooseGroupLoose;
	else
		nChooseGroupType = EChooseGroupNormal;
	end 
	iniFile:WriteInteger( "Setting", "BtnConfigChooseGroup", nChooseGroupType );

	for i = 1, 4 do
		local SubBtn = self.m_BtnChooseGroup:GetDlgChild( TblSubButtonName[i] );
		iniFile:WriteInteger( "Setting", "BtnConfigSubLocalX"..i, SubBtn:GetLocalX() );
		iniFile:WriteInteger( "Setting", "BtnConfigSubLocalY"..i, SubBtn:GetLocalY() );
	end
    iniFile:WriteInteger( "Setting", "ButtonX1", self:GetWndWidth() - self.m_pBtnSkill:GetWndWidth() - 90 - self.m_pBtnSkill:GetLocalX() );
    iniFile:WriteInteger( "Setting", "ButtonY1", self:GetWndHeight() - self.m_pBtnSkill:GetWndHeight() - 90 - self.m_pBtnSkill:GetLocalY() );
	iniFile:Save();
    g_App:HideMsg( g_App:GetString( "anjianshezhi" ) );
	self:ShowWnd( false );
end

function CBtnSettingWnd:OnReset()
    self.m_BtnChooseGroup:SetLocalX( 0 );
    self.m_BtnChooseGroup:SetLocalY( self:GetWndHeight() - self.m_BtnChooseGroup:GetWndHeight() );
	if self.m_pBtnSeparateConfig:GetCheck() then
		for i = 1, 4 do
			local SubBtn = self.m_BtnChooseGroup:GetDlgChild( TblSubButtonName[i] );
			SubBtn:SetLocalX( TblSeparateSubPos[i].x );
			SubBtn:SetLocalY( TblSeparateSubPos[i].y );
		end
	end
	self.m_pBtnSkill:SetLocalX( 1010 );
	self.m_pBtnSkill:SetLocalY( 425 );
end

function CBtnSettingWnd:OnClose()
	self:ShowWnd( false );
end

function CBtnSettingWnd:OnDragStart( Event )
	if type( Event ) == "number"  then return end
	if Event.m_CurrentTarget == self.m_pBtnSkill then
		self.m_nDragSkillStartX = Event.m_GlobalX;
		self.m_nDragSkillStartY = Event.m_GlobalY;
		self.m_nBtnSkillX = self.m_pBtnSkill:GetLocalX();
		self.m_nBtnSkillY = self.m_pBtnSkill:GetLocalY();
	else
		self.m_nChooseBtnStartX = Event.m_GlobalX;
		self.m_nChooseBtnStartY = Event.m_GlobalY;
		self.m_nChooseBtnX = Event.m_CurrentTarget:GetLocalX();
		self.m_nChooseBtnY = Event.m_CurrentTarget:GetLocalY();
	end
end

function CBtnSettingWnd:OnDrag( Event )
	if type( Event ) == "number"  then return end
	if Event.m_CurrentTarget == self.m_pBtnSkill then
		self.m_pBtnSkill:SetLocalX( Event.m_GlobalX - self.m_nDragSkillStartX + self.m_nBtnSkillX );
		self.m_pBtnSkill:SetLocalY( Event.m_GlobalY - self.m_nDragSkillStartY + self.m_nBtnSkillY );
	else
		Event.m_CurrentTarget:SetLocalX( Event.m_GlobalX - self.m_nChooseBtnStartX + self.m_nChooseBtnX );
		Event.m_CurrentTarget:SetLocalY( Event.m_GlobalY - self.m_nChooseBtnStartY + self.m_nChooseBtnY );
	end
end

function CBtnSettingWnd:OnDragEnd( Event )
	if Event.m_CurrentTarget:GetGlobalX() < 0 then
		Event.m_CurrentTarget:SetGlobalX( 0 );
	elseif Event.m_CurrentTarget:GetGlobalX() + Event.m_CurrentTarget:GetWndWidth() > self:GetWndWidth() then
		Event.m_CurrentTarget:SetGlobalX( self:GetWndWidth() - Event.m_CurrentTarget:GetWndWidth() );
	end
	if Event.m_CurrentTarget:GetGlobalY() < nSpaceDis then	--主界面上会空出nSpaceDis距离，与其对应
		Event.m_CurrentTarget:SetGlobalY( nSpaceDis );
	elseif Event.m_CurrentTarget:GetGlobalY() + Event.m_CurrentTarget:GetWndHeight() > self:GetWndHeight() then
		Event.m_CurrentTarget:SetGlobalY( self:GetWndHeight() - Event.m_CurrentTarget:GetWndHeight() );
	end
end
--endregion
