--region CContentListPanel.lua
--Date

function CContentListPanel:Ctor()
	CGListCtrl.Ctor( self )
	self.m_nNewMsgCount = 0;
	self.m_listNeedUpdate = {}
	self.m_mapContentToItem = {}
end

function CContentListPanel:InitItemRes( szOtherRes, szSelfRes )
	self.m_szOtherRes = szOtherRes;
	self.m_szSelfRes = szSelfRes;
	self.m_wndNewMsg = self:GetDlgChild( "xinxiaoxi" );
	self:SetInertiaType( eInertiaType_VScroll );
	self:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemLoaded", self );
	self:AddEventListener( GM_WM_VERTICAL_SCROLL, "OnVerticalScroll", self );	
	self.m_wndNewMsg:AddEventListener( GM_WM_MOUSECLICK, "ScrollToBottom", self );	
end

function CContentListPanel:OnDestroy()
	self:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemLoaded", self );
	self:RemoveEventListener( GM_WM_VERTICAL_SCROLL, "OnVerticalScroll", self );
	self.m_wndNewMsg:RemoveEventListener( GM_WM_MOUSECLICK, "ScrollToBottom", self );	
end

function CContentListPanel:UpdateContent( tblContent )
	local nSelfID = g_App:GetAccountID();
	local nInsertNewItem = 0;
	local LastContent = nil;

	local nMinKeepIndex = self:GetItemCount();
	if self.m_mapContentToItem[tblContent[1]] then
		local Item = self.m_mapContentToItem[tblContent[1]];
		nMinKeepIndex = self:GetItemIndex( Item );
	end

	local nMinInsertIndex = #tblContent + 1;
	for nIndex, Data in pairs( tblContent ) do
		if not self.m_mapContentToItem[Data] then
			nMinInsertIndex = nIndex;
			break;
		end
	end	
	
	for i = nMinKeepIndex - 1, 0, -1 do
		local Item = self:GetSubItem( i, 0 );
		self.m_listNeedUpdate[Item] = nil;
		self.m_mapContentToItem[Item.m_ContentData] = nil;
		self:DeleteItem( i );	
	end	

	local LastContent = nil;
	for i = nMinInsertIndex, #tblContent, 1 do	
		LastContent = tblContent[i];
		local bIsSelf = LastContent.nAccountID == nSelfID;
		local szResName = bIsSelf and self.m_szSelfRes or self.m_szOtherRes;
		local nIndex = self:InsertRowItemsFromRes( -1, szResName, CContentListItemWnd );
		local Item = self:GetSubItem( nIndex, 0 );
		Item:UpdateItem( LastContent );
		self.m_mapContentToItem[LastContent] = Item;
		self.m_listNeedUpdate[Item] = LastContent;
		nInsertNewItem = nInsertNewItem + 1;
	end

	if( LastContent and nSelfID == LastContent.nAccountID ) then
		self.m_bScrollToBottom = true;
		self.m_nNewMsgCount = 0;
		self.m_wndNewMsg:ShowWnd( false );
		return;
	end

	local nPos = self:GetScrollVerticalPos();
	local nPage = self:GetVerticalPageSize();
	local nMax = self:GetVerticalScrollMax();
	if nPos >= nMax - nPage - 1 then
		self.m_bScrollToBottom = true;
		self.m_nNewMsgCount = 0;
		self.m_wndNewMsg:ShowWnd( false );
		return;
	end
	
	self.m_nNewMsgCount = self.m_nNewMsgCount + nInsertNewItem;
	local szFormat = CStringConfig:Inst():GetString( "xinxiaoxi" );
	local szNewMsgText = string.format( szFormat, self.m_nNewMsgCount );
	self.m_wndNewMsg:SetWndText( szNewMsgText );
	self.m_wndNewMsg:ShowWnd( true );
end

function CContentListPanel:OnItemLoaded()	
	for k, v in pairs( self.m_listNeedUpdate ) do
		k:UpdateItem( v );
	end	
	self.m_listNeedUpdate = {}

	if self.m_bScrollToBottom then
		self:ScrollToBottom();
	end
end

function CContentListPanel:ScrollToBottom()
	self:ScrollToBottomLeft();
	self.m_nNewMsgCount = 0;
	self.m_wndNewMsg:ShowWnd( false );
	self.m_bScrollToBottom = nil;
end

function CContentListPanel:OnVerticalScroll()
	local nItemCount = self:GetItemCount();
	if nItemCount ~= 0 and self:GetSubItem( nItemCount - 1, 0 ):IsShow() then
		self.m_nNewMsgCount = 0;
		self.m_wndNewMsg:ShowWnd( false );
		self.m_bScrollToBottom = nil;
	end
end
--endregion
