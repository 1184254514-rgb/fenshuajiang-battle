--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndChargeVip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndChargeVip:OnCreated()
	self.m_pWndCharges = self:GetDlgChild( "chongzhibtn" );
	self.m_pWndCharges2 = self:GetDlgChild( "chongzhibtn1" );
	self.m_pWndList = self:GetDlgChild( "list" );
	
	self.m_pWndList:SetInertiaType( eInertiaType_HScroll );
	for i = 2, g_tblTabFile.vip.nRowCount - 1 do
		local nWindow = CTableConfigMgr:Inst():GetConfigString( "vip", i, "nWindow" );
		local szName = CTableConfigMgr:Inst():GetConfigString( "vip", i, "dName" );
		local szID = CTableConfigMgr:Inst():GetConfigString( "vip", i, "sItemID" );
		local pWnd = self.m_pWndCharges:GetDlgChild( tostring( nWindow ) );
		pWnd:SetWndText( szName );
		pWnd.m_szID = szID;
		pWnd:AddClickListener( "OnClick", self );
	end

	self.m_pWndList:DeleteAllColumn();
	for i = 0, s_vip_prize_count - 1 do
		self.m_pWndList:InsertColumn( i, 100 );
	end
	self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_huiyuanitem.gui", CGWnd );
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );

	self.m_pWndCharges2:AddClickListener( "OnClickMonthDiscounts", self );

	g_App:GetMainPlayerData():AddEventListener( "m_FirstEvent", "RefreshWnd", self );
	g_App.m_EventDispatcher:AddEventListener( "LoginSucc", "RefreshWnd", self );
end

function CWndChargeVip:OnDestroy()
	g_App:GetMainPlayerData():RemoveEventListener( "m_FirstEvent", "RefreshWnd", self );
	g_App.m_EventDispatcher:RemoveEventListener( "LoginSucc", "RefreshWnd", self );
	CGWnd.OnDestroy( self );
end

function CWndChargeVip:OnWndShow( bShow )
	if not bShow then
		return;
	end
	
	self:RefreshWnd();
end

function CWndChargeVip:RefreshWnd()
	-- 如果这里的状态与服务器不一致，你还强行修改，那么会充值不成功的哦（写给非法修改游戏的人）
	local bFirst = not g_App:GetFirstEvent( eFE_MonthVIPDiscounts );
	self.m_pWndCharges:ShowWnd( true );
	self.m_pWndCharges2:ShowWnd( false );
end

function CWndChargeVip:OnListItemLoaded()
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

function CWndChargeVip:OnClick( Event )
	local pWnd = Event.m_CurrentTarget;
	g_App:Recharge( pWnd.m_szID );
end

function CWndChargeVip:OnClickMonthDiscounts()
	local bFirst = not g_App:GetFirstEvent( eFE_MonthVIPDiscounts );
	if not bFirst then
		return;
	end
	local szID = CTableConfigMgr:Inst():GetConfigString( "vip", 1, "sItemID" );
	g_App:Recharge( szID );
end

--endregion
