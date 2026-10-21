--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndVipDesc:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndVipDesc:OnCreated()
	self.m_pWndEndTime = self:GetDlgChild( "youxiaoqi" );
	self.m_pWndVipID = self:GetDlgChild( "huiyuanid" );
	self.m_pWndHead = self:GetDlgChild( "head.touxiang" );
	self.m_pBtnPrize = self:GetDlgChild( "lingqu" );
	self.m_pChargeVip = self:GetDlgChild( "xufei" );
	self.m_pWndEffect = self:GetDlgChild( "tx" );
	self.m_pWndList = self:GetDlgChild( "list" );

	self.m_pBtnPrize:AddClickListener( "QueryVipPrize", self );
	self.m_pChargeVip:AddClickListener( "OpenChargeVip", self );

	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.VipEndTime", "RefreshVipEndTime", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.CurHeadIcon", "RefreshHeadIcon", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.VipPrizeGetTime", "RefreshPrize", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.VipGetTime", "RefreshPrize", self );
	g_App.m_EventDispatcher:AddEventListener( "LoginSucc", "OnLoginSucc", self );
	
	self.m_pWndList:SetInertiaType( eInertiaType_HScroll );
	self.m_pWndList:DeleteAllColumn();
	for i = 0, s_vip_prize_count - 1 do
		self.m_pWndList:InsertColumn( i, 100 );
	end
	self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_huiyuanitem.gui", CGWnd );
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );

	if self.m_szEffect then
		self:PlayerEffect( self.m_szEffect );
	end
end

function CWndVipDesc:OnDestroy()
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.VipEndTime", "RefreshVipEndTime", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.CurHeadIcon", "RefreshLadder", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.VipPrizeGetTime", "RefreshPrize", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.VipGetTime", "RefreshPrize", self );
	g_App.m_EventDispatcher:RemoveEventListener( "LoginSucc", "OnLoginSucc", self );
end

function CWndVipDesc:OnWndShow( bShow )
	if not bShow then
		return;
	end

	self:OnLoginSucc();
end

function CWndVipDesc:OnListItemLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	local time = STime:new();
	GetDateTime( time );
	local tblInfo = g_tblTabFile.vipitem[time:m_nMonth()];
	for nCol = 0, s_vip_prize_count - 1 do
		local subItem = self.m_pWndList:GetSubItem( 0, nCol );
		local nType = tblInfo[ "nItemType" .. nCol ];
		local nIndex = tblInfo[ "nItemID" .. nCol ];
		local nCount = tblInfo[ "nItemCount" .. nCol ];
		local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nType, nIndex ).nIconID;
		local pWndIcon = CRichIconWnd:new( subItem, "tietu" );
		local pWndCount = subItem:GetDlgChild( "name" );
		pWndIcon:SetIconID( nIconID );
		pWndCount:SetWndText( tostring( nCount ) );
	end
end

function CWndVipDesc:RefreshVipEndTime()
	local nVipEndTime = g_App:GetMainPlayerData().m_CharBaseData:GetVipEndTime();
	local time = GetFormatTimeSTMFromMillisecond( NatureTime2LocalTime( nVipEndTime * 1000 ) );
	local szTime = string.format( "%d-%d-%d %d:%d:%d", time:m_nYear(), time:m_nMonth(), 
		time:m_nDayOfMonth(), time:m_nHour(), time:m_nMinutes(), time:m_nSecond() );
	self.m_pWndEndTime:SetWndText( szTime );
end

function CWndVipDesc:RefreshHeadIcon()
	local nHeadID = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
	CHeadIconConfig:Inst():SetIcon( self.m_pWndHead, nHeadID + 1, g_App:GetAccountID() );
end

function CWndVipDesc:RefreshPrize()
	if g_App:GetMainPlayerData():IsGetVipPrize() then
		self.m_pBtnPrize:SetWndText( g_App:GetString( "yilingqu" ) );
		self.m_pBtnPrize:EnableWnd( false );
	else
		self.m_pBtnPrize:SetWndText( g_App:GetString( "lingqujiangli" ) );
		self.m_pBtnPrize:EnableWnd( true );
	end
end

function CWndVipDesc:OnLoginSucc()
	self.m_pWndVipID:SetWndText( g_App:GetShowAccountID() );

	self:RefreshVipEndTime();
	self:RefreshHeadIcon();
	self:RefreshPrize();
end

function CWndVipDesc:QueryVipPrize()
	if g_App:GetMainPlayerData():IsGetVipPrize() then
		return;
	end

	local NetMsg = CQueryVipPrize:new();
	g_App:SendShellMsg( NetMsg );
end

function CWndVipDesc:OpenChargeVip()
	g_App:GetGameStart().m_pWndVip:SwitchWnd( false );
end

function CWndVipDesc:PlayerEffect( szEffect )
	self.m_szEffect = szEffect;
	if not self:IsCreated() then
		return;
	end
	self.m_pWndEffect:AddEffect( self.m_szEffect, "fx/loop", self.m_szEffect );
	self.m_szEffect = nil;
end

--endregion
