--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local szOtherRes = "gui/cfg/fsj_liaotian_item1.gui";
local szSelfRes = "gui/cfg/fsj_liaotian_item2.gui";

local eClickType_Column		= 0;
local eClickType_Feedback	= 1;
local eClickType_Message	= 2;

function CIMFriendWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_wndParent = ParentWnd;
end

function CIMFriendWnd:OnCreated()
	self.m_listContent = ClassCast( CContentListPanel, self:GetDlgChild( "list" ) );
	self.m_listContent:InitItemRes( szOtherRes, szSelfRes );
	self.m_listContent:ShowWnd( false );

	self.m_listUser = self:GetDlgChild( "list2" );
	self.m_listUser:ShowWnd( true );
	self.m_wndEmpty = self:GetDlgChild( "kong" );

	self.m_wndBtnList = self:GetDlgChild( "xuanxiang" );
	for i = 1, g_tblTabFile.gm_type.nRowCount - 1 do
		local szName	= CTableConfigMgr:Inst():GetConfigString( "gm_type", i, "dName" );
		local nType		= CTableConfigMgr:Inst():GetConfigString( "gm_type", i, "nType" );
		local szParam	= CTableConfigMgr:Inst():GetConfigString( "gm_type", i, "sParam" );
		local pWnd = self.m_wndBtnList:GetDlgChild( "btn"..i );
		pWnd:SetWndText( szName );
		pWnd.m_nType	= tonumber( nType );
		pWnd.m_szParam	= tostring( szParam );
		pWnd:AddActionListener( "OnBtnGM", self );
	end

	self.m_wndGMService = CGMServiceWnd:new( "gui/cfg/fsj_kefufankui.gui", self:GetRootWnd(), 1 );
	self.m_pWndGMColumn = CWndGMColumn:new( "gui/cfg/fsj_faq.gui", self:GetRootWnd(), 1 );

	self.m_listUser:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectListItem", self );
	self.m_listUser:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnFriendListItemLoaded", self );
    g_App.m_EventDispatcher:AddEventListener( "AddFollower", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveFollower", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveFollowee", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:AddEventListener( "CharsInfoChanged", "OnCharsInfoUpdate", self );	
	g_App.m_EventDispatcher:AddEventListener( "RefreshIMFriendUnReadWnd", "OnRefreshUnReadWnd", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshFriendContentWnd", "OnRefreshContentWnd", self );
end

function CIMFriendWnd:OnDestroy()	
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollower", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveFollower", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveFollowee", "OnFriendUpdate", self );
    g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "OnCharsInfoUpdate", self );	
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshIMFriendUnReadWnd", "OnRefreshUnReadWnd", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshFriendContentWnd", "OnRefreshContentWnd", self );
	CGWnd.OnDestroy( self );
	self.m_wndGMService:DestroyWnd();
end

function CIMFriendWnd:GetSelectItem()
	return self.m_listUser:GetSelectItem();
end

function CIMFriendWnd:GetTargetId()
	return self.m_nSelectAccountID;
end

function CIMFriendWnd:Close()
	self:ShowWnd( false );
end

function CIMFriendWnd:OnWndShow( bShow )
	if not bShow then
		return;
	end

	self:OnFriendUpdate();	
	local bFriendExist = self.m_listUser:GetItemCount() ~= 0;
	self.m_listContent:ShowWnd( bFriendExist );
	self.m_wndEmpty:ShowWnd( not bFriendExist );
	self:UpdateContent();
end

function CIMFriendWnd:OnCharsInfoUpdate( Event )
	if not self:IsShow() then
		return;
	end
	local bFriendChanged = false;
	local FriendMgr = CFriendMgr:Inst();
	for k, v in pairs( Event.m_tblCharsInfo ) do
		if FriendMgr:IsFriends( v.nAccountID ) then
			bFriendChanged = true;
		end
	end
	if bFriendChanged then
		self:OnFriendUpdate();
	end
end

function CIMFriendWnd:OnFriendUpdate()
	if not self:IsShow() then
		return;
	end
	local FriendMgr = CFriendMgr:Inst();
	local tblCurFriends = {};
	local nGMAccountID = eSystemAccountID_CustomerService;
	local bSelectIsFriend = self.m_nSelectAccountID == nGMAccountID;
	for k, v in pairs( FriendMgr.m_tblFriends ) do
		table.insert( tblCurFriends, FriendMgr:GetCharInfo( v ) )
		bSelectIsFriend = bSelectIsFriend or v == self.m_nSelectAccountID;
	end	
	table.insert( tblCurFriends, FriendMgr:GetCharInfo( nGMAccountID ) )

	--如果正在聊天的对象不再是朋友，也给予保留
	if( self.m_nSelectAccountID and not bSelectIsFriend ) then
		table.insert( tblCurFriends, FriendMgr:GetCharInfo( self.m_nSelectAccountID ) )
	end
	table.sort( tblCurFriends, function ( a, b ) return a.nState > b.nState; end );

	if not self.m_nSelectAccountID and tblCurFriends[1] then
		self.m_nSelectAccountID = tblCurFriends[1].nAccountID;
	end

	for i = self.m_listUser:GetItemCount() - 1, #tblCurFriends, -1 do
		self.m_listUser:DeleteItem( i );	
	end	

	local bInsertNewAccount = false;
	local szResName = "gui/cfg/fsj_liaotian_haoyou_item.gui";
	for i = self.m_listUser:GetItemCount(), #tblCurFriends - 1, 1 do
		self.m_listUser:InsertRowItemsFromRes( -1, szResName, CUserListItemWnd );
		bInsertNewAccount = true;
	end

	for i = 0, #tblCurFriends - 1, 1 do
		local wndSubItem = self.m_listUser:GetSubItem( i, 0 );
		wndSubItem:UpdateItem( tblCurFriends[i + 1] );
	end	

	if not bInsertNewAccount then
		self:OnFriendListItemLoaded();
	end
end

function CIMFriendWnd:OnFriendListItemLoaded()
	for i = 0, self.m_listUser:GetItemCount() - 1, 1 do
		local wndSubItem = self.m_listUser:GetSubItem( i, 0 );
		if( wndSubItem:GetAccountID() == self.m_nSelectAccountID ) then
			self.m_listUser:SelectItem( i, 0 );
			return;
		end
	end	
end

function CIMFriendWnd:SelectListItem( event )
    local wndSubItem = self.m_listUser:GetSubItem( event.m_wParam, event.m_lParam );
	self.m_nSelectAccountID = wndSubItem:GetAccountID();
	wndSubItem:OnSelect();
	wndSubItem:SetCheck( true );

	if( self.m_nContentAccount and 
		self.m_nContentAccount == self.m_nSelectAccountID ) then
		return;
	end
	
	self.m_wndBtnList:ShowWnd( self:GetTargetId() <= 0 );
	self.m_nContentAccount = self.m_nSelectAccountID;
	self:UpdateContent()
end

function CIMFriendWnd:OnBtnGM( Event )
	if Event.m_Target.m_nType == eClickType_Column then
		local nWndX = Event.m_Target:GetGlobalX() + Event.m_Target:GetWndWidth() / 2;
		local nWndY = Event.m_Target:GetGlobalY();
		self.m_pWndGMColumn:SetColumnID( tonumber( Event.m_Target.m_szParam ), nWndX, nWndY );
		self.m_pWndGMColumn:ShowAndSetFocus();
	elseif Event.m_Target.m_nType == eClickType_Feedback then
		self.m_wndGMService:Show( tonumber( Event.m_Target.m_szParam ), Event.m_Target:GetWndText() );
	elseif Event.m_Target.m_nType == eClickType_Message then
		local DisEvent = {};
		DisEvent.m_Type = "NewMessageFriend";
		DisEvent.m_nAccountID = eSystemAccountID_CustomerService;
		DisEvent.m_nCreateTime = 0;
		DisEvent.m_szContent = g_Dictionary:GetValueByString( Event.m_Target.m_szParam );
		g_App.m_EventDispatcher:DispatchEvent( DisEvent );
	end
end

function CIMFriendWnd:UpdateContent()
	self.m_listContent:ShowWnd( true );
	local nAccountID = self.m_nSelectAccountID;
	local tblContent = g_App:GetInstantMessageDataMgr():
		GetFriendMessageContent( nAccountID );	
	self.m_listContent:UpdateContent( tblContent );
end

function CIMFriendWnd:OnRefreshUnReadWnd( Event )
	if not self:IsShow() then
		return;
	end

	if Event.m_nAccountID == self.m_nContentAccount then
		local IMMgr = g_App:GetInstantMessageDataMgr();
		if IMMgr:GetAccountUnReadCount( Event.m_nAccountID ) ~= 0 then
			local nSelectItem = self.m_listUser:GetSelectItem();
			if nSelectItem >= 0 then
				local wndSubItem = self.m_listUser:GetSubItem( nSelectItem, 0 );
				wndSubItem:OnSelect();
			end
		end
		return;
	end
	
	local FriendMgr = CFriendMgr:Inst();
	local CharInfo = FriendMgr:GetCharInfo( Event.m_nAccountID )
	for i = 0, self.m_listUser:GetItemCount() - 1, 1 do
		local wndSubItem = self.m_listUser:GetSubItem( i, 0 );
		if( wndSubItem:GetAccountID() == Event.m_nAccountID ) then
			wndSubItem:UpdateItem( CharInfo );
			return;
		end
	end	
end

function CIMFriendWnd:OnRefreshContentWnd( Event )
	if not self:IsShow() or Event.m_nAccountID ~= self.m_nContentAccount then
		return;
	end
	self:UpdateContent()	
end


--endregion
