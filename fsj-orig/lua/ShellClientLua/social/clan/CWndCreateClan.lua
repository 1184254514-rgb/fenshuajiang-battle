--region CWndCreateClan.lua
--Date 2018.03.13

function CWndCreateClan:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndCreateClan:OnCreated()
	self.m_WndTitle			=	self:GetDlgChild( "title" );
	self.m_WndClanName		=	self:GetDlgChild( "name" );
	self.m_WndClanSlogan	=	self:GetDlgChild( "xuanyan" );
	self.m_IconClan			=	CRichIconWnd:new( self, "icon" );
	self.m_BtnClose			=	self:GetDlgChild( "close" );
	self.m_CBtnNeedApprove	=	self:GetDlgChild( "checkbtn_zhaoren" );
	self.m_BtnChooseIcon	=	self:GetDlgChild( "btn_switch" );
	self.m_BtnCreateClan	=	self:GetDlgChild( "btn_ok" );
	self.m_WndCost			=	self:GetDlgChild( "btn_ok.jiage" );
	self.m_IconResource		=	CRichIconWnd:new( self, "btn_ok.icon" );

	self.m_WndChooseIcon	=	CWndChooseClanIcon:new( "gui/cfg/fsj_jiazu_tuteng.gui", self, 1 );

	self.m_BtnChooseIcon:AddActionListener( "ChooseIcon", self );
	self.m_BtnCreateClan:AddActionListener( "CreateClan", self );
	self.m_BtnClose:AddActionListener( "OnClickClose", self );
end

function CWndCreateClan:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndCreateClan:OnWndShow( bShow )
	if bShow then
		self:InitData();
	end
end

function CWndCreateClan:OnClickClose()
	self:ShowWnd( false );
end

function CWndCreateClan:CreateClan()
	local szClanName = self.m_WndClanName:GetWndText();
	local szClanSlogan = self.m_WndClanSlogan:GetWndText();
	local nClanIconID = self.m_IconClan:GetIconID();
	local nNeedApprove = self.m_CBtnNeedApprove:GetCheck() and 1 or 0;

	if szClanSlogan == "" then
		self.m_WndClanSlogan:SetWndText( g_App:GetString( "morenxuanyan" ) );
		return g_App:HideMsg( g_App:GetString( "jiazuxuanyanbuweikong" ) );
	end
	
	if string.len( szClanName ) > CLANNAME_BYTE_SIZE then
		return g_App:HideMsg( g_App:GetString( "jiazumingzitaichang" ) );
	elseif not CUSFilter:Inst():CheckString( szClanName, CLANNAME_BYTE_SIZE + 1, eFilter_Chat ) then
		return g_App:HideMsg( g_App:GetString( "jiazumingzifeifa" ) );
	elseif string.len( szClanSlogan) > CLANSLOGAN_BYTE_SIZE then
		return g_App:HideMsg( g_App:GetString( "jiazuxuanyantaichang" ) );
	elseif not CUSFilter:Inst():CheckString( szClanSlogan, CLANSLOGAN_BYTE_SIZE + 1, eFilter_Chat ) then 
		return g_App:HideMsg( g_App:GetString( "jiazuxuanyanfeifa" ) );
	end 

	local NetMsg = CCreateClan:new();
	NetMsg.m_nClanIcon = nClanIconID;
	NetMsg.m_szClanName = szClanName;
	NetMsg.m_szClanSlogan = szClanSlogan;
	NetMsg.m_nNeedApprove = nNeedApprove;
	g_App:SendShellMsg( NetMsg );
	self:ShowWnd( false );
end

function CWndCreateClan:ChooseIcon()
	self.m_WndChooseIcon:ShowWnd( true );
end

function CWndCreateClan:InitData()
	self:SetClanIcon( CSnakeConstant:Inst():GetDefaultClanIconID() );
	self.m_WndClanSlogan:SetWndText( g_App:GetString( "morenxuanyan" ) );
	self.m_WndCost:SetWndText( CSnakeConstant:Inst():GetCreateClanCostCount() );
	self.m_IconResource:SetIconID( g_tblTabFile.currency[CSnakeConstant:Inst():GetCreateClanCostIndex()].nIconID );
end

function CWndCreateClan:SetClanIcon( nIconID )
	self.m_IconClan:SetIconID( nIconID );
end

--endregion
