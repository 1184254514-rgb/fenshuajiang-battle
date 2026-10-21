--region CGListCtrl.lua
--Date 2015/12/14

function CGListCtrl:Ctor()
end

function CGListCtrl:InsertRowItemsFromRes( index, guiResName, itemGUIClass, onItemCreatedCallback, Handler, constructContext )
	assert( type( onItemCreatedCallback ) ~= "string" or ( Handler and Handler[onItemCreatedCallback] ) );
    return self:InsertItemFromHandler( index,CItemCreateHandler:new( self, itemGUIClass, guiResName, onItemCreatedCallback, Handler, constructContext ) );
end

function CGListCtrl:MeetItemCount( nMeetCount, guiResName, itemGUIClass, nWidth )
	local nMaxColCount = self:GetColumnCount();
	local nMaxRowCount = self:GetItemCount();
	local nMaxAllCount = nMaxRowCount * nMaxColCount;
	local bCreate = nMaxAllCount < nMeetCount;
	if bCreate then
	--不够需要创建
		local nCreateCount = nMeetCount - nMaxAllCount;
		if nWidth then
			local nInsertColCount = math.ceil( nCreateCount / nMaxRowCount );
			for i = 1, nInsertCount do
				self:InsertColumn( -1, nWidth );
			end
		else
			local nInertRowCount = math.ceil( nCreateCount / nMaxColCount );
			for i = 1, nInertRowCount do
				self:InsertRowItemsFromRes( -1, guiResName, itemGUIClass );
			end
		end
	end
	nMaxColCount = self:GetColumnCount();
	nMaxRowCount = self:GetItemCount();
	nMaxAllCount = nMaxRowCount * nMaxColCount;
	for i = 1, nMaxAllCount do
		self:SetSubItemVisibleByIndex( i <= nMeetCount, i - 1 );
	end
end

function CGListCtrl:GetSubItemByIndex( nIndex )
	local nListColumnCount = self:GetColumnCount();
	local nRow = math.floor( nIndex / nListColumnCount );
	local nColumn = math.floor( nIndex % nListColumnCount );
	return self:GetSubItem( nRow, nColumn );
end

function CGListCtrl:SetSubItemVisibleByIndex( v, nIndex )
	local nListColumnCount = self:GetColumnCount();
	local nRow = math.floor( nIndex / nListColumnCount );
	local nColumn = math.floor( nIndex % nListColumnCount );
	self:SetSubItemVisible( v, nRow, nColumn );
end

function CGListCtrl:GetCheckItem()
	local nRow = math.max( self:GetSelectItem(), 0 );
	local nColumn = math.max( self:GetSelectColumn(), 0 );
	local Item = self:GetSubItem( nRow, nColumn );
	if not Item:IsShow() then
		Item = self:GetSubItem( 0, 0 );
	end
	return Item;
end

function CGListCtrl:ScrollPreRender( evt )
	if not self.m_bLeftOrRight then
		self:ScrollToRight( evt.m_lParam );
	else
		self:ScrollToLeft( evt.m_lParam );
	end
end

local eMoveSpeed = 5;

function CGListCtrl:ScrollToLeft( nDeltaTime )
	if self:GetScrollHorizonPos() > self.m_fDestPos then
		local fSpeed = self.m_fSpeed or eMoveSpeed;
		local fCurPos = self:GetScrollHorizonPos() - nDeltaTime * fSpeed;
		if fCurPos < self.m_fDestPos then
			fCurPos = self.m_fDestPos;
		end
		self:SetScrollHorizonPos( fCurPos );
	else
		self:EnablePreRender( false );
		self:RemoveEventListener( GM_WM_PRERENDER, "ScrollPreRender", self );
	end
end

function CGListCtrl:ScrollToRight( nDeltaTime )
	if self:GetScrollHorizonPos() < self.m_fDestPos then
		local fSpeed = self.m_fSpeed or eMoveSpeed;
		local fCurPos = self:GetScrollHorizonPos() + nDeltaTime * fSpeed;
		if fCurPos > self.m_fDestPos then
			fCurPos = self.m_fDestPos;
		end
		self:SetScrollHorizonPos( fCurPos );
	else
		self:EnablePreRender( false );
		self:RemoveEventListener( GM_WM_PRERENDER, "ScrollPreRender", self );
	end
end

function CItemCreateHandler:Ctor( listCtrl, itemGUIClass, itemResource, onItemCreatedCallback, Handler , constructContext)
    self.m_listCtrl = listCtrl;
    self.m_itemGUIClass = itemGUIClass;
    self.m_itemResource = itemResource;
    self.m_onItemCreatedCallback = onItemCreatedCallback;
    self.m_Handler = Handler;
    self.m_constructContext = constructContext;
end

function CItemCreateHandler:GetClassName( nItem, nCol )
    local superClass;
    if type( self.m_itemResource ) == "table" then
        superClass = self.m_itemGUIClass[nCol + 1];
    else
        superClass = self.m_itemGUIClass;
    end

    if( superClass:IsInheritFrom( CGTreeCtrl ) )then
        return "CGTreeCtrl";
    elseif ( superClass:IsInheritFrom( CGListCtrl ) )then
        return "CGListCtrl";
    elseif ( superClass:IsInheritFrom( CGRichWnd ) )then
        return "CGRichWnd";
    elseif ( superClass:IsInheritFrom( CGComboBox ) )then
        return "CGComboBox";
    elseif ( superClass:IsInheritFrom( CGScrollPane ) )then
        return "CGScrollPane";
    elseif ( superClass:IsInheritFrom( CGScrollBar ) )then
        return "CGScrollBar";
    elseif ( superClass:IsInheritFrom( CGProgress ) )then
        return "CGProgress";
    elseif ( superClass:IsInheritFrom( CGCheckButton ) )then
        return "CGCheckButton";
    elseif ( superClass:IsInheritFrom( CGButton ) )then
        return "CGButton";
    elseif ( superClass:IsInheritFrom( CGWnd ) )then
        return "CGWnd";
    else
        assert( "error SearchClassNode" );
    end
end

function CItemCreateHandler:OnCreateItem( wndItem, nItem, nCol )
    local wndClass;
    if type( self.m_itemResource ) == "table" then
        wndClass = self.m_itemGUIClass[nCol + 1];
    else
        wndClass = self.m_itemGUIClass;
    end

    local param;
    if type( self.m_itemResource ) == "table" then
        if self.m_constructContext ~= nil then
            param = self.m_constructContext[nCol + 1];
        else
            param = nil;
        end
    else
        param = self.m_constructContext;
    end

	wndItem = ClassCast( wndClass, wndItem, param );
    if type( self.m_itemResource ) == "table" then   
        wndItem:CreateFromRes( self.m_itemResource[nCol + 1], self.m_listCtrl, 0 );
    else
        wndItem:CreateFromRes( self.m_itemResource, self.m_listCtrl, 0 );
    end

    local newName = wndItem:GetWndName() .. "_" .. nItem .. "_" .. nCol + 1;
    wndItem:SetWndName( newName );
	wndItem:Invalidate();

	self.m_listCtrl.___allItemRef = self.m_listCtrl.___allItemRef or {}
	local tblItemList = self.m_listCtrl.___allItemRef;
	tblItemList[wndItem] = { m_wndItem = wndItem };
	tblItemList[wndItem].OnItemDestroy = function( this, Event )
		if Event.m_Target == this.m_wndItem then
			this.m_wndItem:RemoveEventListener( WM_DESTROY, "OnItemDestroy", this );	
			this.m_wndItem:GetParent().___allItemRef[this.m_wndItem] = nil;
		end
	end
	wndItem:AddEventListener( WM_DESTROY, "OnItemDestroy", tblItemList[wndItem] );	

    if self.m_onItemCreatedCallback == nil then
        return;
    end
    
    local function OnCreate( this, event )
		if event.m_Target ~= wndItem then
			return;
		end
        wndItem:RemoveEventListener( WM_CREATE, OnCreate, self );
		local nIndex = self.m_listCtrl:GetItemIndex( wndItem );
		local nItem = nIndex/self.m_listCtrl:GetColumnCount();
		local nCol = nIndex%self.m_listCtrl:GetColumnCount();
		if self.m_Handler == nil then
			self.m_onItemCreatedCallback( self.m_listCtrl, nItem, nCol )
		elseif type( self.m_onItemCreatedCallback ) == "string" then
			self.m_Handler[self.m_onItemCreatedCallback]( self.m_Handler, self.m_listCtrl, nItem, nCol )
		else
			self.m_onItemCreatedCallback( self.m_Handler, self.m_listCtrl, nItem, nCol )
		end
    end
    wndItem:AddEventListener( WM_CREATE, OnCreate, wndItem );
end
--endregion
