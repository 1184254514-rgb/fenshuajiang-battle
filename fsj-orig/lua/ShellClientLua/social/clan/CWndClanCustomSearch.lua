--region CWndCustomSearch.lua
--Date 2018.04.02
--家族自定义条件查询 "gui\cfg\fsj_jiazu_shaixuan"

function CWndClanCustomSearch:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndClanCustomSearch:OnCreated()
	self.m_BtnClose					=	self:GetDlgChild( "close" );
	self.m_BtnOk					=	self:GetDlgChild( "btn_ok" );
	self.m_CBtnNeedApprove			=	self:GetDlgChild( "zhaoren.chkbtn" );
	self.m_ClanLevelMin				=	self:GetDlgChild( "dengji.xiao" );
	self.m_ClanLevelMinSub			=	self:GetDlgChild( "dengji.xiaodown" );
	self.m_ClanLevelMinAdd			=	self:GetDlgChild( "dengji.xiaoup" );
	self.m_ClanLevelMax				=	self:GetDlgChild( "dengji.da" );
	self.m_ClanLevelMaxSub			=	self:GetDlgChild( "dengji.dadown" );
	self.m_ClanLevelMaxAdd			=	self:GetDlgChild( "dengji.daup" );
	self.m_ClanMemberCountMin		=	self:GetDlgChild( "renshu.xiao" );
	self.m_ClanMemberCountMinSub	=	self:GetDlgChild( "renshu.xiaodown" );
	self.m_ClanMemberCountMinAdd	=	self:GetDlgChild( "renshu.xiaoup" );
	self.m_ClanMemberCountMax		=	self:GetDlgChild( "renshu.da" );
	self.m_ClanMemberCountMaxSub	=	self:GetDlgChild( "renshu.dadown" );
	self.m_ClanMemberCountMaxAdd	=	self:GetDlgChild( "renshu.daup" );

	self.m_BtnClose:AddActionListener( "OnClickClose", self );
	self.m_BtnOk:AddActionListener( "OnOk", self );
	self.m_ClanLevelMinSub:AddActionListener( "OnMinLevelSub", self );
	self.m_ClanLevelMinAdd:AddActionListener( "OnMinLevelAdd", self );
	self.m_ClanLevelMaxSub:AddActionListener( "OnMaxLevelSub", self );
	self.m_ClanLevelMaxAdd:AddActionListener( "OnMaxLevelAdd", self );
	self.m_ClanMemberCountMinSub:AddActionListener( "OnMinMemberCountSub", self );
	self.m_ClanMemberCountMinAdd:AddActionListener( "OnMinMemberCountAdd", self );
	self.m_ClanMemberCountMaxSub:AddActionListener( "OnMaxMemberCountSub", self );
	self.m_ClanMemberCountMaxAdd:AddActionListener( "OnMaxMemberCountAdd", self );

	self.m_nQueryPage = 0;
end

function CWndClanCustomSearch:OnWndShow( bShow )	
	if bShow then
		self.m_ClanLevelMin:SetWndText( 1 );
		self.m_ClanLevelMax:SetWndText( CClanLevelConfig:Inst():GetMaxLevel() );
		self.m_ClanMemberCountMin:SetWndText( 1 );
		self.m_ClanMemberCountMax:SetWndText( CSnakeConstant:Inst():GetClanMemberCountMax() );
	end
end

function CWndClanCustomSearch:OnDestroy()
end

function CWndClanCustomSearch:OnClickClose()
	self:ShowWnd( false );
end

function CWndClanCustomSearch:OnOk()
	self.m_nQueryPage = self.m_nQueryPage + 1;
	local NetMsg = CCustomSearchClan:new();
	NetMsg.m_nAllActivityMin = g_tblTabFile.clanlevel[tonumber( self.m_ClanLevelMin:GetWndText() )].nActivityMin;
	NetMsg.m_nAllActivityMax = g_tblTabFile.clanlevel[tonumber( self.m_ClanLevelMax:GetWndText() )].nActivityMax;
	NetMsg.m_nQueryPage = self.m_nQueryPage
	NetMsg.m_nCountMin = tonumber( self.m_ClanMemberCountMin:GetWndText() ) ;
	NetMsg.m_nCountMax = tonumber( self.m_ClanMemberCountMax:GetWndText() );
	NetMsg.m_nNeedApprove = self.m_CBtnNeedApprove:GetCheck() and 1 or 0;
	g_App:SendShellMsg( NetMsg );
	self:ShowWnd( false );
	g_App:WaitMsg( true, 1500 );
end

function CWndClanCustomSearch:OnMinLevelSub()
	local nOldMinLevel = tonumber( self.m_ClanLevelMin:GetWndText() );
	local nOldMaxLevel = tonumber( self.m_ClanLevelMax:GetWndText() );
	local nNewMinLevel = nOldMinLevel - 1;
	if nNewMinLevel > 0 then
		self.m_ClanLevelMin:SetWndText( nNewMinLevel );
	end
	self.m_ClanLevelMinSub:EnableWnd( nNewMinLevel > 1 );
	self.m_ClanLevelMinAdd:EnableWnd( nNewMinLevel < nOldMaxLevel );
	self.m_ClanLevelMaxSub:EnableWnd( nNewMinLevel < nOldMaxLevel );
end

function CWndClanCustomSearch:OnMinLevelAdd()
	local nOldMinLevel = tonumber( self.m_ClanLevelMin:GetWndText() );
	local nOldMaxLevel = tonumber( self.m_ClanLevelMax:GetWndText() );
	local nNewMinLevel = nOldMinLevel + 1;
	if nNewMinLevel <= nOldMaxLevel  then
		self.m_ClanLevelMin:SetWndText( nNewMinLevel );	
	end
	self.m_ClanLevelMinSub:EnableWnd( nNewMinLevel > 1 );
	self.m_ClanLevelMinAdd:EnableWnd( nNewMinLevel < nOldMaxLevel );
	self.m_ClanLevelMaxSub:EnableWnd( nNewMinLevel < nOldMaxLevel );
end

function CWndClanCustomSearch:OnMaxLevelSub()
	local nOldMinLevel = tonumber( self.m_ClanLevelMin:GetWndText() );
	local nOldMaxLevel = tonumber( self.m_ClanLevelMax:GetWndText() );
	local nMaxLevel = CClanLevelConfig:Inst():GetMaxLevel();
	local nNewMaxLevel = nOldMaxLevel - 1;
	if nNewMaxLevel >= nOldMinLevel then
		self.m_ClanLevelMax:SetWndText( nNewMaxLevel );
	end
	self.m_ClanLevelMinAdd:EnableWnd( nOldMinLevel < nNewMaxLevel );
	self.m_ClanLevelMaxSub:EnableWnd( nOldMinLevel < nNewMaxLevel );
	self.m_ClanLevelMaxAdd:EnableWnd( nNewMaxLevel < nMaxLevel );
end

function CWndClanCustomSearch:OnMaxLevelAdd()
	local nOldMinLevel = tonumber( self.m_ClanLevelMin:GetWndText() );
	local nOldMaxLevel = tonumber( self.m_ClanLevelMax:GetWndText() );
	local nMaxLevel = CClanLevelConfig:Inst():GetMaxLevel();
	local nNewMaxLevel = nOldMaxLevel + 1;
	if nNewMaxLevel <= nMaxLevel then
		self.m_ClanLevelMax:SetWndText( nNewMaxLevel );
	end
	self.m_ClanLevelMinAdd:EnableWnd( nOldMinLevel < nNewMaxLevel );
	self.m_ClanLevelMaxSub:EnableWnd( nOldMinLevel < nNewMaxLevel );
	self.m_ClanLevelMaxAdd:EnableWnd( nNewMaxLevel < nMaxLevel );
end

function CWndClanCustomSearch:OnMinMemberCountSub()
	local nOldMinCount = tonumber( self.m_ClanMemberCountMin:GetWndText() );
	local nOldMaxCount = tonumber( self.m_ClanMemberCountMax:GetWndText() );
	local nNewMinCount = nOldMinCount - 1;
	if nNewMinCount > 0 then
		self.m_ClanMemberCountMin:SetWndText( nNewMinCount );
	end
	self.m_ClanMemberCountMinSub:EnableWnd( nNewMinCount > 1 );
	self.m_ClanMemberCountMinAdd:EnableWnd( nNewMinCount < nOldMaxCount );
	self.m_ClanMemberCountMaxSub:EnableWnd( nNewMinCount < nOldMaxCount );
end

function CWndClanCustomSearch:OnMinMemberCountAdd()
	local nOldMinCount = tonumber( self.m_ClanMemberCountMin:GetWndText() );
	local nOldMaxCount = tonumber( self.m_ClanMemberCountMax:GetWndText() );
	local nNewMinCount = nOldMinCount + 1;
	if nNewMinCount <= nOldMaxCount  then
		self.m_ClanMemberCountMin:SetWndText( nNewMinCount );	
	end
	self.m_ClanMemberCountMinSub:EnableWnd( nNewMinCount > 1 );
	self.m_ClanMemberCountMinAdd:EnableWnd( nNewMinCount < nOldMaxCount );
	self.m_ClanMemberCountMaxSub:EnableWnd( nNewMinCount < nOldMaxCount );
end

function CWndClanCustomSearch:OnMaxMemberCountSub()
	local nOldMinCount = tonumber( self.m_ClanMemberCountMin:GetWndText() );
	local nOldMaxCount = tonumber( self.m_ClanMemberCountMax:GetWndText() );
	local nMaxCount = CSnakeConstant:Inst():GetClanMemberCountMax();
	local nNewMaxCount = nOldMaxCount - 1;
	if nNewMaxCount >= nOldMinCount then
		self.m_ClanMemberCountMax:SetWndText( nNewMaxCount );
	end
	self.m_ClanMemberCountMinAdd:EnableWnd( nOldMinCount < nNewMaxCount );
	self.m_ClanMemberCountMaxSub:EnableWnd( nOldMinCount < nNewMaxCount );
	self.m_ClanMemberCountMaxAdd:EnableWnd( nNewMaxCount < nMaxCount );
end

function CWndClanCustomSearch:OnMaxMemberCountAdd()
	local nOldMinCount = tonumber( self.m_ClanMemberCountMin:GetWndText() );
	local nOldMaxCount = tonumber( self.m_ClanMemberCountMax:GetWndText() );
	local nMaxCount = CSnakeConstant:Inst():GetClanMemberCountMax();
	local nNewMaxCount = nOldMaxCount + 1;
	if nNewMaxCount <= nMaxCount then
		self.m_ClanMemberCountMax:SetWndText( nNewMaxCount );
	end
	self.m_ClanMemberCountMinAdd:EnableWnd( nOldMinCount < nNewMaxCount );
	self.m_ClanMemberCountMaxSub:EnableWnd( nOldMinCount < nNewMaxCount );
	self.m_ClanMemberCountMaxAdd:EnableWnd( nNewMaxCount < nMaxCount );
end

--endregion
