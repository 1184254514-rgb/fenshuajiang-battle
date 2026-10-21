--region CWndClanItem.lua
--Date 2018.03.13

function CWndClanItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self );
end

function CWndClanItem:OnCreated()
	self.m_WndClanID		=	self:GetDlgChild( "ID" );
	self.m_Icon				=	CRichIconWnd:new( self, "icon" );
	self.m_WndName			=	self:GetDlgChild( "name" );
	self.m_WndLevel			=	self:GetDlgChild( "dengji" );
	self.m_WndActivity		=	self:GetDlgChild( "huoyuedu" );
	self.m_WndMemberCount	=	self:GetDlgChild( "renshu" );
	self.m_WndStatus		=	self:GetDlgChild( "zhuangtai" );
	self.m_BtnJoinClan		=	self:GetDlgChild( "b_jiaru" );
	self.m_TextNeedCheck	=	self:GetDlgChild( "b_jiaru.tips" );

	self.m_BtnJoinClan:AddActionListener( "OnClickJoinClan", self );
end

function CWndClanItem:SetData( ClanData )
	self.m_nClanID = ClanData.nClanID;
	self.m_WndClanID:SetWndText( ClanData.nClanID );
	self.m_Icon:SetIconID( ClanData.nIconID );
	self.m_WndName:SetWndText( ClanData.szClanName );
	self.m_WndLevel:SetWndText( CClanLevelConfig:Inst():GetLevel( ClanData.nAllActivity ) );
	self.m_WndActivity:SetWndText( ClanData.nAllActivity );
	self.m_WndMemberCount:SetWndText( ClanData.nMemcount .. "/" .. CSnakeConstant:Inst():GetClanMemberCountMax() );
	self.m_WndStatus:ShowWnd( ClanData.nMemcount >= CSnakeConstant:Inst():GetClanMemberCountMax() );
	self.m_BtnJoinClan:ShowWnd( ClanData.nMemcount < CSnakeConstant:Inst():GetClanMemberCountMax() );
	local string = ClanData.nNeedApprove == 1 and "shenqingjiaru" or "shenqingjiaruwuxupizhun";
	self.m_TextNeedCheck:SetWndText( g_App:GetString( string ) );
end

function CWndClanItem:OnClickJoinClan()
	if not self.m_nClanID then
		return;
	end

	local NetMsg = CJoinClan:new();
	NetMsg.m_nClanID = self.m_nClanID;
	g_App:SendShellMsg( NetMsg );
end


--endregion
