--region CWndSetClanInfo.lua
--Date	2018.03.15
--家族信息设置界面 

function CWndSetClanInfo:Ctor( sResName, ParentWnd, nLoadType  )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndSetClanInfo:OnCreated()
	self.m_ClanSlogan		=	self:GetDlgChild( "xuanyan" );
	self.m_ClanIcon			=	CRichIconWnd:new( self, "icon" );
	self.m_CBtnNeedApprove	=	self:GetDlgChild( "checkbtn_zhaoren" )
	self.m_BtnShowIconList	=	self:GetDlgChild( "btn_switch" );
	self.m_BtnClose			=	self:GetDlgChild( "close" );

	self.m_BtnShowIconList:AddActionListener( "InitclanIconList", self );
	self.m_BtnClose:AddActionListener( "OnClickClose", self );
	self.m_WndChooseIcon	=	CWndChooseClanIcon:new( "gui/cfg/fsj_jiazu_tuteng.gui", self, 1 );
end

function CWndSetClanInfo:OnDestroy()
end

function CWndSetClanInfo:OnWndShow( bShow )
end

function CWndSetClanInfo:InitAndShowWnd( OldClanData )
	if not OldClanData or not OldClanData.nClanID then return end
	self.m_ClanSlogan:SetWndText( OldClanData.szClanSlogan );
	self.m_ClanIcon:SetIconID( OldClanData.nIconID );
	self.m_CBtnNeedApprove:SetCheck( OldClanData.nNeedApprove ~= 0 );
	self:ShowAndSetFocus();
end

function CWndSetClanInfo:OnClickClose( Event )
	local szClanSlogan = self.m_ClanSlogan:GetWndText();
	if string.len( szClanSlogan) > CLANSLOGAN_BYTE_SIZE then
		return g_App:HideMsg( "jiazu xuanyan taichang!!!" );
	elseif not CUSFilter:Inst():CheckString( szClanSlogan, CLANSLOGAN_BYTE_SIZE + 1, eFilter_Chat ) then 
		return g_App:HideMsg( "jiazu xuanyan hanyou feifazi!!!!" );
	end 
	local NetMsg = CSetClanInfo:new();
	NetMsg.m_szClanSlogan = szClanSlogan;
	NetMsg.m_nClanIconID = self.m_ClanIcon:GetIconID();
	NetMsg.m_nNeedApprove = self.m_CBtnNeedApprove:GetCheck() and 1 or 0;
	g_App:SendShellMsg( NetMsg );
	self:ShowWnd( false );
end

function CWndSetClanInfo:InitclanIconList( Event )
	self.m_WndChooseIcon:ShowAndSetFocus();
end

function CWndSetClanInfo:SetClanIcon( nIconID )
	self.m_ClanIcon:SetIconID( nIconID );
end


--endregion
