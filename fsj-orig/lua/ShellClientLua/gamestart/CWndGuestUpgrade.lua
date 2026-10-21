--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndGuestUpgrade:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndGuestUpgrade:OnCreated()
	self.m_pBtnButton = self:GetDlgChild( "b_ok" );
	self.m_pWndGold = self:GetDlgChild( "jinbi.shuzi" );
	self.m_pWndRainbowGold = self:GetDlgChild( "yinfu.shuzi" );
	self.m_pBtnHead = self:GetDlgChild( "head.touxiang" );
	self.m_pWndID = self:GetDlgChild( "id.shuzi" );
	self.m_pBtnCloseTip = self:GetDlgChild( "buxianshi" );

	self:AddCloseAction( "b_close" );
	self.m_pBtnButton:AddActionListener( "OnClick", self );
	self.m_pBtnCloseTip:AddActionListener( "OnCloseTip", self );
end

function CWndGuestUpgrade:OnClick()
	if not g_App:GetWorldConn():IsGuest() then
		return;
	end

	g_App:SendSDKCmd( eLoginAndPayCmd_GUEST_UPGRADE, "" );
end

function CWndGuestUpgrade:OnCloseTip()
	local nCurTime = GetNatureTime();
	if self.m_pBtnCloseTip:GetCheck() then
		nCurTime = nCurTime + eTimeConst_DayMiSeconds * 3;
	end

	local iniFile = g_App:GetIniFile();
	iniFile:WriteInteger64( "Stat", "GuestUpgradeEndTime", nCurTime );
	iniFile:Save();
end

function CWndGuestUpgrade:OnWndShow( bShow )
	if not bShow then
		return;
	end
	
	local nRainbowGold = tostring( g_tblTabFile.guest_upgrade["nRainbowGoldCount"] );
	local szGold = tostring( g_tblTabFile.guest_upgrade["nGoldCount"] );

	self.m_pWndGold:SetWndText( szGold );
	self.m_pWndRainbowGold:SetWndText( nRainbowGold );
	self.m_pWndID:SetWndText( g_App:GetShowAccountID() );
	 CHeadIconConfig:Inst():SetIcon( self.m_pBtnHead, g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1, g_App:GetAccountID() );
end

function CWndGuestUpgradePrize:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
	self.m_nGold = 0;
	self.m_nRainbowGold = 0;
end

function CWndGuestUpgradePrize:OnCreated()
	self.m_pWndIconGold = CRichIconWnd:new( self, "jinbi" );
	self.m_pWndIconRainbowGold = CRichIconWnd:new( self, "yinfu" );
	self.m_pWndGold = self:GetDlgChild( "jinbi.shuzi" );
	self.m_pWndRainbowGold = self:GetDlgChild( "yinfu.shuzi" );

	self:AddCloseAction( "b_ok" );

	local nIconID = CPropBaseConfigMgr:Inst():GetConfig( eGRT_Resource, eResourceType_Gold ).nIconID;
	local nIconID2 = CPropBaseConfigMgr:Inst():GetConfig( eGRT_Resource, eResourceType_RainbowGold ).nIconID;
	self.m_pWndIconGold:SetIconID( nIconID );
	self.m_pWndIconRainbowGold:SetIconID( nIconID2 );

	self:UpdateWnd();
end

function CWndGuestUpgradePrize:UpdateWnd()
	self.m_pWndGold:SetWndText( tostring( self.m_nGold ) );
	self.m_pWndRainbowGold:SetWndText( tostring( self.m_nRainbowGold ) );
end

function CWndGuestUpgradePrize:RefreshWnd( nGold, nRainbowGold )
	self.m_nGold = nGold;
	self.m_nRainbowGold = nRainbowGold;
	if not self:IsCreated() then
		return;
	end
	self:UpdateWnd();
end

--endregion
