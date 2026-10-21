--region CWndClanMemberOpr.lua
--Date 2018.03.16
--家族成员操作选项窗口

function CWndClanMemberOpr:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end 

function CWndClanMemberOpr:OnCreated()
	self.m_BtnPromote = self:GetDlgChild( "btn_tisheng" );
	self.m_BtnKick = self:GetDlgChild( "btn_tiren" );
	self.m_BtnSearchInfo = self:GetDlgChild( "btn_chakan" );
	self.m_BtnDemote = self:GetDlgChild( "btn_jiangzhi" );

	self.m_BtnPromote:AddActionListener( "OnClickPromote", self );
	self.m_BtnKick:AddActionListener( "OnClickKick", self );
	self.m_BtnSearchInfo:AddActionListener( "OnClickShowInfo", self );
	if self.m_BtnDemote then
		self.m_BtnDemote:AddActionListener( "OnClickDemote", self );
	end
end

function CWndClanMemberOpr:OnWndShow( bShow )
	if bShow then
		self:ShowAndSetFocus();
	end
end

function CWndClanMemberOpr:OnActive( bActive )
	if not bActive then
	    self:ShowWnd( false );
    end
end

function CWndClanMemberOpr:ShowOperateWnd( nAccountID, nPower )
	self.m_nAccountID = nAccountID;
	self.m_nCurPower = nPower;
	self:ShowAndSetFocus();
end

function CWndClanMemberOpr:OnClickPromote()
	local nNewPower = eClan_Vice_Leader;
	if self.m_nCurPower == eClan_Vice_Leader then
		nNewPower = eClan_Leader;
	end
	self:SetPower( nNewPower );
	self:ShowWnd( false );
end

function CWndClanMemberOpr:OnClickDemote()
	self:SetPower( eClan_Member );
	self:ShowWnd( false );
end

function CWndClanMemberOpr:OnClickKick()
	g_App:MessageBox( g_App:GetString( "jiazutirentips" ), {
		[CMessageBox.Close] = function()
			g_App.m_pMessageBox:ShowWnd( false );
		end;
		[CMessageBox.OK] = function()
			g_App.m_pMessageBox:ShowWnd( false );
			local NetMsg = CKickClan:new();
			NetMsg.m_nBeKickAccountID = self.m_nAccountID;
			g_App:SendShellMsg( NetMsg );
		end;
	});
	self:ShowWnd( false );
end

function CWndClanMemberOpr:OnClickShowInfo()
	g_App:ShowPlayerInfo( self.m_nAccountID );
	self:ShowWnd( false );
end

function CWndClanMemberOpr:SetPower( nNewPower )
	local NetMsg = CSetClanMemberPower:new();
	NetMsg.m_nBeSetAccountID = self.m_nAccountID;
	NetMsg.m_nNewPower = nNewPower;
	g_App:SendShellMsg( NetMsg );
end




--endregion
