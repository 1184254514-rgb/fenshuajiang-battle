--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndPrizeNotify:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndPrizeNotify:OnCreated()
	CGWnd.OnCreated( self );
	self.m_pWndName = self:GetDlgChild( "title" );
	self.m_pWndDesc = self:GetDlgChild( "content" );
	self.m_pWndList = self:GetDlgChild( "list" );
	self.m_pWndButton = self:GetDlgChild( "b_ok" );

	self.m_pWndList:SetInertiaType( eInertiaType_HScroll );
	self.m_pWndDesc:SetInertiaType( eInertiaType_VScroll );
	self:UpdateWnd();
	
	self.m_pWndButton:AddClickListener( "OnClick", self );
end

function CWndPrizeNotify:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndPrizeNotify:SetData( nPrizeID, szName, szDesc, tblPropList )
	self.m_nPrizeID = nPrizeID;
	self.m_szName = szName;
	self.m_szDesc = szDesc;
	self.m_tblPropList = tblPropList;
	
	if not self:IsCreated() then
		return;
	end

	self:UpdateWnd();
end

function CWndPrizeNotify:UpdateWnd()
	self.m_pWndName:SetWndText( self.m_szName );
	self.m_pWndDesc:SetWndText( self.m_szDesc );
	
	self.m_pWndList:DeleteAllColumn();
	for i = 1, #self.m_tblPropList do
		self.m_pWndList:InsertColumn( i, 102 );
	end
	
	self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_prop.gui", CWndPropItem );
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
end

function CWndPrizeNotify:OnListItemLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );

	local nColumnCount = self.m_pWndList:GetColumnCount();
	for i = 1, nColumnCount do
		local subItem = self.m_pWndList:GetSubItem( 0, i - 1 );
		subItem:SetProp( self.m_tblPropList[i].m_nType, 
			self.m_tblPropList[i].m_nTypeIndex, self.m_tblPropList[i].m_nCount );
	end
end

function CWndPrizeNotify:OnClick( Event )
	Event.m_StopImmediately = true;
	local NetMsg = CQueryPrize:new();
	NetMsg.m_nPrizeID = self.m_nPrizeID;
	g_App:SendShellMsg( NetMsg );
	self:DestroyWnd();
end

--endregion