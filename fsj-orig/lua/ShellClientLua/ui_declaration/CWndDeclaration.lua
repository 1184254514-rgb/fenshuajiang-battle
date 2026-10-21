--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndDeclaration:Ctor( sResName, ParentWnd, nLoadType, nDeclarationType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );

	self.m_funcCallback = nil;
	self.m_tblData = {};
	self.m_nDeclarationType = nDeclarationType;
end

function CWndDeclaration:OnCreated()
	self.m_pWndButton = self:GetDlgChild( "btn_ok" );
	self.m_pWndTitle = self:GetDlgChild( "title" );
	self.m_pWndContent = self:GetDlgChild( "neirong" );
	self.m_pWndContent:SetInertiaType( eInertiaType_VScroll );
	self.m_pWndButton:AddClickListener( "OnClick", self );
end

function CWndDeclaration:RefreshWnd( tblData, funcCallback )
	if #tblData == 0 then
		return;
	end
	self.m_funcCallback = funcCallback;
	self.m_tblData = tblData;
	self:ShowDeclaration( 1 );
end

function CWndDeclaration:OnClick()
	if self.m_nCurIndex ~= #self.m_tblData then
		self:ShowDeclaration( self.m_nCurIndex + 1 );
		return;
	end
	if self.m_funcCallback then
		self.m_funcCallback();
	end
	self:ShowWnd( false );
end

function CWndDeclaration:ShowDeclaration( nIndex )
	self.m_nCurIndex = nIndex;

	local Data = self.m_tblData[self.m_nCurIndex];

	self.m_pWndTitle:SetWndText( Data.szTitle );

	self.m_pWndContent:DeleteAllItem();
	local pHandler = ITableItemCreateHandler:new();
	pHandler.m_listCtrl = self.m_pWndContent;
	pHandler.GetClassName = function( this )
		return this.m_szClassName;
	end;

	pHandler.OnCreateItem = function( this, wndItem, nItem, nCol )
		wndItem:CreatAsEmptyContain( this.m_listCtrl );
		local newName = wndItem:GetWndName() .. "_" .. nItem .. "_" .. nCol + 1;
		wndItem:SetWndName( newName );
		wndItem:Invalidate();
		this.m_listCtrl.___allItemRef = this.m_listCtrl.___allItemRef or {}
		local tblItemList = this.m_listCtrl.___allItemRef;
		tblItemList[wndItem] = { m_wndItem = wndItem };
		tblItemList[wndItem].OnItemDestroy = function( this, Event )
			if Event.m_Target == this.m_wndItem then
				this.m_wndItem:RemoveEventListener( WM_DESTROY, "OnItemDestroy", this );	
				this.m_wndItem:GetParent().___allItemRef[this.m_wndItem] = nil;
			end
		end
		wndItem:AddEventListener( WM_DESTROY, "OnItemDestroy", tblItemList[wndItem] );
	end;

	local bExistImage = string.len( Data.szImageUrl ) ~= 0;
	pHandler.m_szClassName = "CGWnd";
	if bExistImage then
		self.m_pWndContent:InsertItemFromHandler( 0, pHandler );
		local pImageItem = self.m_pWndContent:GetSubItem( 0, 0 );
		local szFileName = Data.szImageUrl.."?"..Data.szImageMD5;
		local rtWnd = CFRect:new();
		rtWnd:right( pImageItem:GetWndWidth() );
		rtWnd:bottom( pImageItem:GetWndHeight() );
		pImageItem:AddImage( GSM_BS_BK, eST_ENABLE, 0, szFileName, nil, 
			rtWnd, 0xffffffff, LOCK_ZALL, IDF_ZOOM_WHILE_SCALE, -1, -1, 0, 1, 0 );
		self.m_pWndContent:SetItemHeight( pImageItem:GetWndHeight(), 0 );
	end

	pHandler.m_szClassName = "CGRichWnd";
	self.m_pWndContent:InsertItemFromHandler( self.m_pWndContent:GetItemCount(), pHandler );
	local pContentItem = self.m_pWndContent:GetSubItem( self.m_pWndContent:GetItemCount() - 1, 0 );
	pContentItem = ClassCast( CGRichWnd, pContentItem );
	pContentItem:SetWndTextColor( GSM_BS_BK, eST_ENABLE, 0xffcc902f );
	pContentItem:SetWndTextBcColor( GSM_BS_BK, eST_ENABLE, 0x9000000 );
	pContentItem:SetFontSize( 26 );
	pContentItem:SetStyle( BitOr( pContentItem:GetStyle(), eRCHW_AUTORESETH ) );
	pContentItem:AddWndText( Data.szContent );
	self.m_pWndContent:SetItemHeight( pContentItem:GetCurHeight(), self.m_pWndContent:GetItemCount() - 1 );
end
--endregion
