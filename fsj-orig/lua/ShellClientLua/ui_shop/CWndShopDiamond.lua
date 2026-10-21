--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndShopDiamond:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
	self.m_nColCount = 3;
	self.m_tblDiamondRowID = {};
end

function CWndShopDiamond:OnCreated()
	self.m_pWndList = self:GetDlgChild( "list" );

	self.m_pWndList:SetInertiaType( eInertiaType_VScroll );
	self.m_pWndList:DeleteAllColumn();
	for i = 0, self.m_nColCount - 1 do
		self.m_pWndList:InsertColumn( i, 325 );
	end
	local nRowCount = g_tblTabFile.charge.nRowCount - 1;
	for i = 1, nRowCount do
		table.insert( self.m_tblDiamondRowID, i );
	end

	local nInsertRowCount =  math.ceil( #self.m_tblDiamondRowID / self.m_nColCount );
	for i = 1, nInsertRowCount do
		self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_chongzhi_zuanshi_item.gui", CWndShopDiamondItem );
	end
	
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
end

function CWndShopDiamond:OnListItemLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	local nCurIndex = 1;
	local nRowCount = self.m_pWndList:GetItemCount();
	local nColumnCount = self.m_pWndList:GetColumnCount();
	for nRow = 0, nRowCount - 1 do
		for nCol = 0, nColumnCount - 1 do
			local subItem = self.m_pWndList:GetSubItem( nRow, nCol );
			if nCurIndex > #self.m_tblDiamondRowID then
				self.m_pWndList:SetSubItemVisible( false, nRow, nCol );
			else
				local nRowID = self.m_tblDiamondRowID[nCurIndex];
				local szItemID = CTableConfigMgr:Inst():GetConfigString( "charge", nRowID, "sItemID" );
				local szName = CTableConfigMgr:Inst():GetConfigString( "charge", nRowID, "dName" );
				local nIconID = CTableConfigMgr:Inst():GetConfigString( "charge", nRowID, "nIconID" );
				local fPrice = CTableConfigMgr:Inst():GetConfigString( "charge", nRowID, "fPrice" );
				subItem:RefreshWnd( szItemID, szName, tonumber( nIconID ), fPrice );
			end
			nCurIndex = nCurIndex + 1;
		end
	end
end

function CWndShopDiamondItem:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
	self.m_szProductID = "";
end

function CWndShopDiamondItem:OnCreated()
	self.m_pWndName = self:GetDlgChild( "name" );
	self.m_pWndIcon = CRichIconWnd:new( self, "icon" );
	self.m_pWndPrice = self:GetDlgChild( "jiage" );

	self:AddClickListener( "OnClick", self );
end

function CWndShopDiamondItem:OnClick()
	g_App:Recharge( self.m_szProductID );
end

function CWndShopDiamondItem:RefreshWnd( szProductID, szName, nIconID, fPrice )
	self.m_szProductID = szProductID;
	self.m_pWndName:SetWndText( szName );
	self.m_pWndIcon:SetIconID( nIconID );
	self.m_pWndPrice:SetWndText( tostring( fPrice ) );
end

--endregion
