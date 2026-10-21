--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndPrizePropTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndPrizePropTip:OnCreated()
	CGWnd.OnCreated( self );
	self.m_pWndList = self:GetDlgChild( "list" );
	self.m_pButton = self:GetDlgChild( "b_ok" );
	
	self.m_pWndList:SetInertiaType( eInertiaType_HScroll );
	self:UpdateWnd();
	
	self.m_pButton:AddClickListener( "OnClick", self );
end

function CWndPrizePropTip:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndPrizePropTip:UpdateWnd()
	if not self.m_tblPropList then
		return;
	end

	local nWndPorpWidth = 102;
	self.m_pWndList:SetWndSize( nWndPorpWidth * math.min( 6, #self.m_tblPropList ), self.m_pWndList:GetWndHeight() );
	self.m_pWndList:SetGlobalX( ( self:GetWndWidth() - self.m_pWndList:GetWndWidth() )  / 2 );

	self.m_pWndList:DeleteAllColumn();
	for i = 1, #self.m_tblPropList do
		self.m_pWndList:InsertColumn( i, nWndPorpWidth );
	end
	
	self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_prop.gui", CWndPropItem );
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
end

function CWndPrizePropTip:OnListItemLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );

	local nColumnCount = self.m_pWndList:GetColumnCount();
	for i = 1, nColumnCount do
		local subItem = self.m_pWndList:GetSubItem( 0, i - 1 );
		subItem:SetProp( self.m_tblPropList[i].m_nType, 
			self.m_tblPropList[i].m_nTypeIndex, self.m_tblPropList[i].m_nCount );
	end
end

function CWndPrizePropTip:SetData( tblPropList )
	self.m_tblPropList = tblPropList;

	if not self:IsCreated() then
		return;
	end
	self:UpdateWnd();
end

function CWndPrizePropTip:OnClick( Event )
	Event.m_StopImmediately = true;
	self:DestroyWnd();
end

--endregion
