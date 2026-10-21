--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndGMColumn:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_nColumnID = nil;
end

function CWndGMColumn:OnCreated()
	self.m_pWndList = self:GetDlgChild( "list" );

	self:AddEventListener( GM_WM_MOUSECLICK, "OnClose", self );
end

function CWndGMColumn:OnDestroy()	
	CGWnd.OnDestroy( self );
end

function CWndGMColumn:OnWndShow( bShow )
	if not bShow then
		return;
	end

	self:RefreshWnd();
end

function CWndGMColumn:SetColumnID( nColumnID, nWndX, nWndY )
	if nColumnID == self.m_nColumnID then
		return;
	end
	self.m_nColumnID	= nColumnID;
	self.nWndX			= nWndX;
	self.nWndY			= nWndY;

	if not self:IsShow() then
		return;
	end
	
	self:RefreshWnd();
end

function CWndGMColumn:RefreshWnd()
	if not self.m_nColumnID then
		return;
	end

	self.m_tblColumn = {};
	for i = 1, g_tblTabFile.gm_column.nRowCount - 1 do
		local nID	= tonumber( CTableConfigMgr:Inst():GetConfigString( "gm_column", i, "nID" ) );
		if self.m_nColumnID == nID then
			local _temp = {};
			_temp.szName = CTableConfigMgr:Inst():GetConfigString( "gm_column", i, "dName" );
			_temp.szMessage = CTableConfigMgr:Inst():GetConfigString( "gm_column", i, "dMessage" );
			table.insert( self.m_tblColumn, _temp  );
		end
	end

	local nWndX = math.max( 0, self.nWndX - self.m_pWndList:GetWndWidth() / 2 );
	local nWndY = math.max( 0, self.nWndY - self.m_pWndList:GetWndHeight() - 20 );
	self.m_pWndList:SetGlobalX( nWndX );
	self.m_pWndList:SetGlobalY( nWndY );

	self.m_pWndList:DeleteAllColumn();
	self.m_pWndList:DeleteAllItem();
	for i = 1, 2 do
		self.m_pWndList:InsertColumn( i, 207 );
	end
	local nRowCount = math.ceil( #self.m_tblColumn / self.m_pWndList:GetColumnCount() );
	for i = 1, nRowCount do
		self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_faq_item.gui", CGWnd );
	end
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
end

function CWndGMColumn:OnListItemLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	local nRowCount = self.m_pWndList:GetItemCount();
	local nColumnCount = self.m_pWndList:GetColumnCount();
	local nCurIndex = 1;
	for nCol = 0, nColumnCount - 1 do
		for nRow = 0, nRowCount - 1 do
			local subItem = self.m_pWndList:GetSubItem( nRow, nCol );
			if nCurIndex > #self.m_tblColumn then
				self.m_pWndList:SetSubItemVisible( false, nRow, nCol );
				break;
			end
			subItem:GetDlgChild( "bg" ):SetWndText( self.m_tblColumn[nCurIndex].szName );
			subItem.m_szMessage = self.m_tblColumn[nCurIndex].szMessage;
			subItem:AddClickListener( "OnClickColumn", self );

			nCurIndex = nCurIndex + 1;
		end
	end
end

function CWndGMColumn:OnClickColumn( Event )
	local DisEvent = {};
	DisEvent.m_Type = "NewMessageFriend";
	DisEvent.m_nAccountID = eSystemAccountID_CustomerService;
	DisEvent.m_nCreateTime = 0;
	DisEvent.m_szContent = tostring( Event.m_Target.m_szMessage );
	g_App.m_EventDispatcher:DispatchEvent( DisEvent );

	self:ShowWnd( false );
end

--endregion
