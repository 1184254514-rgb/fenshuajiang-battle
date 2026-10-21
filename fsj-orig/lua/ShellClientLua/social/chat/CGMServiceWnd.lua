--region CGMServiceWnd.lua
--Date 2018-02-05

function CGMServiceWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_szSelectType = "";
end

function CGMServiceWnd:OnCreated()
	self.m_wndTitle = self:GetDlgChild( "title" );
	self.m_wndTips = self:GetDlgChild( "tips" );
	self.m_wndDesc = self:GetDlgChild( "miaoshu" );
	self.m_wndPhone = self:GetDlgChild( "shouji.haoma" );
	self.m_wndQQ = self:GetDlgChild( "qq.haoma" );
	self.m_wndCharge = self:GetDlgChild( "chongzhi" );
	self.m_wndYear = self:GetDlgChild( "chongzhi.shijian.nian" );
	self.m_wndMonth = self:GetDlgChild( "chongzhi.shijian.yue" );
	self.m_wndDay = self:GetDlgChild( "chongzhi.shijian.ri" );
	self.m_listCombo = self:GetDlgChild( "chongzhi.leixing.xuanxiang" );
	self.m_pBtnCommit = self:GetDlgChild( "btn_ok" );
	self.m_pBtnCancel = self:GetDlgChild( "close" );
	self.m_pBtnCommit:AddActionListener( "OnClickCommit", self );
	self.m_pBtnCancel:AddActionListener( "OnClickCancel", self );
	self.m_listCombo:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnItemSelect", self );
	self.m_wndDesc:AddEventListener( WM_SETFOCUS, "OnDescFocus", self );
	self.m_wndDesc:AddEventListener( WM_KILLFOCUS, "OnDescFocus", self );

	self.m_wndQQ:SetWndText( g_App:GetIniFile():GetString( "Contact", "QQ", "" ) );
	self.m_wndPhone:SetWndText( g_App:GetIniFile():GetString( "Contact", "Phone", "" ) );
	self.m_listCombo:GetListBox():SetInertiaType( eInertiaType_VScroll );
end

function CGMServiceWnd:OnDestroy()	
	CGWnd.OnDestroy( self );
end

function CGMServiceWnd:Show( nType, szTitle )
	self.m_nType = nType;
	self.m_wndTitle:SetWndText( szTitle );
	self:ShowAndSetFocus();
	self.m_wndCharge:ShowWnd( false );
	local time = STime:new();
	GetDateTime( time );
	self.m_wndYear:SetWndText( time:m_nYear() );
	self.m_wndMonth:SetWndText( time:m_nMonth() );
	self.m_wndDay:SetWndText( time:m_nDayOfMonth() );
	if nType == eCustomerServiceType_ChargeQuesion then
		self.m_wndCharge:ShowWnd( true );
		local nChargeCount = g_tblTabFile.charge.nRowCount - 1;
		local nVipCount = g_tblTabFile.vip.nRowCount - 1;
		local szRes = "gui/cfg/fsj_kefufankui_item.gui";
		local wndList = self.m_listCombo:GetListBox()
		for i = 1, nChargeCount + nVipCount do
			wndList:InsertRowItemsFromRes( -1, szRes, CGButton );
		end
		wndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnCreatedItem", self );
	end
end

function CGMServiceWnd:OnCreatedItem( Event )
	local tblCharge = g_tblTabFile.charge;
	local nChargeCount = g_tblTabFile.charge.nRowCount - 1;
	for i = 1, nChargeCount do
		local line = tblCharge:GetRow( i );
		local wndItem = self.m_listCombo:GetItem( i - 1 );
		local wndText = wndItem:GetDlgChild( "neirong" );
		wndText:SetWndText( line.dName );
		wndItem.m_szItemID = line.sItemID;
	end

	local tblVip = g_tblTabFile.vip;
	local nVipCount = g_tblTabFile.vip.nRowCount - 1;
	for i = 1, nVipCount do
		local line = tblVip:GetRow( i );
		local wndItem = self.m_listCombo:GetItem( i - 1 + nChargeCount );
		local wndText = wndItem:GetDlgChild( "neirong" );
		wndText:SetWndText( line.dName );
		wndItem.m_szItemID = line.sItemID;
	end
end

function CGMServiceWnd:OnItemSelect( Event )
	local wndItem = self.m_listCombo:GetItem( Event.m_wParam );
	local wndItemText = wndItem:GetDlgChild( "neirong" );
	local wndBoxText = self.m_listCombo:GetDlgChild( "neirong" );
	wndBoxText:SetWndText( wndItemText:GetWndText() );
	self.m_szSelectType = wndItem.m_szItemID;
end

function CGMServiceWnd:OnDescFocus()
	local szContent = self.m_wndDesc:GetWndText();
	self.m_wndTips:ShowWnd( not self.m_wndDesc:IsFocus() and szContent == "" );
end

function CGMServiceWnd:OnClickCancel()
	self:ShowWnd( false );
end

function CGMServiceWnd:OnClickCommit()
	local nYear = tonumber( self.m_wndYear:GetWndText() );
	local nMonth = tonumber( self.m_wndMonth:GetWndText() );
	local nDay = tonumber( self.m_wndDay:GetWndText() );
	
	local szContent = self.m_wndDesc:GetWndText();
	local nTargetID = eSystemAccountID_CustomerService;
	local Info = {};
	Info.nType = self.m_nType;
	Info.nQQ = self.m_wndQQ:GetWndText();
	Info.nPhone = self.m_wndPhone:GetWndText();
	Info.nChargeTime = Format2NatureTime( nYear, nMonth, nDay )/1000;
	Info.szChargeName = self.m_szSelectType;

	if szContent == "" then
		return g_App:HideMsg( g_App:GetString( "kefutips7" ) );
	end

	if Info.nPhone ~= "" and string.len( Info.nPhone ) ~= 11 then
		return g_App:HideMsg( g_App:GetString( "kefutips8" ) );
	end

	local nMin = LocalTime2NatureTime( g_App:GetOpenDate()*1000 )/1000;
	local nMax = GetNatureTime()/1000;
	if Info.nChargeTime < nMin or Info.nChargeTime > nMax then
		return g_App:HideMsg( g_App:GetString( "kefutips9" ) );
	end

	if( Info.szChargeName == "" and 
		self.m_nType == eCustomerServiceType_ChargeQuesion ) then
		return g_App:HideMsg( g_App:GetString( "kefutips10" ) );
	end

	if( string.len( szContent ) > 1000 ) then
		return g_App:HideMsg( g_App:GetString( "kefutips2" ) );
	end

	if( string.len( szContent ) < 30 ) then
		return g_App:HideMsg( g_App:GetString( "kefutips3" ) );
	end

	g_App:GetInstantMessageDataMgr():SendMsg( nTargetID, szContent, Info );
	self:ShowWnd( false );

	g_App:GetIniFile():WriteString( "Contact", "QQ", Info.nQQ );
	g_App:GetIniFile():WriteString( "Contact", "Phone", Info.nPhone );
	g_App:GetIniFile():Save();
	self.m_wndDesc:SetWndText( "" );
	self:OnDescFocus();
end
--endregion
