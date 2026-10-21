--region CWndChooseClanIcon.lua
--Date 2018.03.14
--家族图腾选择界面

local nColumn	=	5;

function CWndChooseClanIcon:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndChooseClanIcon:OnCreated()
	self.m_ListIcon		=	self:GetDlgChild( "list" );
	self.m_BtnClose		=	self:GetDlgChild( "close" );
	self.m_BtnClose:AddActionListener( "OnClickClose", self );
	self.m_ListIcon:SetInertiaType( eInertiaType_VScroll );
end

function CWndChooseClanIcon:OnDestroy()
end

function CWndChooseClanIcon:OnWndShow( bShow )
	if bShow then
		self:InitList();
	end
end

function CWndChooseClanIcon:OnClickClose()
	local nSelectCol = self.m_ListIcon:GetSelectColumn();
	local nSelectItem = self.m_ListIcon:GetSelectItem();
	local nSelectIndex = nSelectItem * nColumn + nSelectCol + 1;
	self:GetParent():SetClanIcon( self.m_tblAllClanIcon[nSelectIndex] );
	self:ShowWnd( false );
end

function CWndChooseClanIcon:InitList()
	self.m_ListIcon:DeleteAllColumn();
	self.m_ListIcon:DeleteAllItem();
	for i = 1, nColumn do
		self.m_ListIcon:InsertColumn( i - 1, 200 );
	end

	self.m_nIconCount = g_tblTabFile.clanIcon.nRowCount - 1;
	local nRowCount = math.ceil( self.m_nIconCount/nColumn );
	if not self.m_tblAllClanIcon then
		self.m_tblAllClanIcon = {};
		for i = 1, self.m_nIconCount do
			table.insert( self.m_tblAllClanIcon, g_tblTabFile.clanIcon:GetRow( i ).nClanIconID );
		end
	end
	
	for i = 1, nRowCount do
		self.m_ListIcon:InsertRowItemsFromRes( -1, "gui/cfg/fsj_jiazu_tutengitem.gui", CWndClanIconItem );
	end
	self.m_ListIcon:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemLoaded", self );	
end

function CWndChooseClanIcon:OnItemLoaded()
	self.m_ListIcon:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemLoaded", self );
	local nItem = self.m_ListIcon:GetItemCount();
	local nCol  = self.m_ListIcon:GetColumnCount();
	for i = 0, nItem - 1 do
		for j = 0, nCol - 1 do
			local listItem = self.m_ListIcon:GetSubItem( i, j );
			local nindex = i * nColumn + j + 1;
			listItem:SetIcon( self.m_tblAllClanIcon[nindex] );		
			if nindex > self.m_nIconCount then
				self.m_ListIcon:SetSubItemVisible( false, i, j );
			end
		end 
	end
end


------------------------------------------------------------
--家族图腾列表Item  
------------------------------------------------------------
function CWndClanIconItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndClanIconItem:OnCreated()
	self.m_Icon		=	CRichIconWnd:new( self, "icon");
end

function CWndClanIconItem:SetIcon( nIconID )
	self.m_Icon:SetIconID( nIconID );
	if nIconID == CSnakeConstant:Inst():GetDefaultClanIconID() then
		self:SetCheck( true );
	end
end

--endregion
