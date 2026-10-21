--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CFriendInfoPage:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
	self.m_eRelation = CFriendMgr.eRelationType_Followee;
	self.m_nPage = 0;
end

function CFriendInfoPage:OnCreated()
    self.m_pList = self:GetDlgChild( "list" );
    self.m_pBtnRefresh = self:GetDlgChild( "b_shuaxin" );
    self.m_pPage = self:GetDlgChild( "next" ):GetDlgChild( "yeshu" );
    self.m_pBtnLeft = self:GetDlgChild( "next" ):GetDlgChild( "b_zuo" );
    self.m_pBtnRight = self:GetDlgChild( "next" ):GetDlgChild( "b_you" );
    self.m_pSearch = self:GetDlgChild( "sousuo" );
    self.m_pBtnSearch = self.m_pSearch:GetDlgChild( "b_sousuo" );
    self.m_pSearchName = self.m_pSearch:GetDlgChild( "w_yonghu" );
    self.m_pSearchTip = self.m_pSearch:GetDlgChild( "bg_shuoming" );

    self.m_pNoFriend = self:GetDlgChild( "wuhaoyou" );
    self.m_pNoFriendText = self.m_pNoFriend:GetDlgChild( "neirong" );
    
	self.m_pBtnRefresh:AddActionListener( "OnRefresh", self );
	self.m_pBtnSearch:AddActionListener( "OnSearch", self );
	self.m_pBtnLeft:AddActionListener( "OnLeft", self );
	self.m_pBtnRight:AddActionListener( "OnRight", self );
    self:OnResult( 0, 0 );
	
    g_App.m_EventDispatcher:AddEventListener( "AddFollower", "RefreshCurPage", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveFollower", "RefreshCurPage", self );
    g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "RefreshCurPage", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveFollowee", "RefreshCurPage", self );
    g_App.m_EventDispatcher:AddEventListener( "AddBlacklist", "RefreshCurPage", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveBlacklist", "RefreshCurPage", self );
end

function CFriendInfoPage:OnDestroy()
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollower", "RefreshCurPage", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveFollower", "RefreshCurPage", self );
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "RefreshCurPage", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveFollowee", "RefreshCurPage", self );
    g_App.m_EventDispatcher:RemoveEventListener( "AddBlacklist", "RefreshCurPage", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveBlacklist", "RefreshCurPage", self );
	CGWnd.OnDestroy( self );
end

function CFriendInfoPage:RefreshCurPage()
    if self:IsShow() then
        self:OnRefresh()
    end
end

function CFriendInfoPage:OnRefresh()
    if g_App.m_WorldConnect == nil then
        return;
    end
	g_App.m_GameStart.m_pFriendWnd:QueryCharsInfo( self.m_eRelation, self.m_nPage );
end

function CFriendInfoPage:OnSearch()
end

function CFriendInfoPage:OnLeft()
    if g_App.m_WorldConnect == nil then
        return;
    end
	if self.m_nPage == 0 then
		return;
	end
	self.m_nPage = self.m_nPage - 1;
	self:OnRefresh();
end

function CFriendInfoPage:OnRight()
    if g_App.m_WorldConnect == nil then
        return;
    end
	
	local FriendMgr = CFriendMgr:Inst();
	local nCount = FriendMgr:GetCharInfoDataCount( self.m_eRelation );
	if ( self.m_nPage + 1 )*FRIEND_INFO_SHOW_PAGE_SIZE >= nCount then
		return;
	end
	self.m_nPage = self.m_nPage + 1;
	self:OnRefresh();
end

function CFriendInfoPage:OnResult( eRelation, nPage )
	self.m_eRelation = eRelation;
	self.m_nPage = nPage;
    self.m_pList:DeleteAllItem();

	local FriendMgr = CFriendMgr:Inst();
	local nTotalCount = FriendMgr:GetCharInfoTotalCount( self.m_eRelation );
	local nTotalPage = math.ceil( nTotalCount / FRIEND_INFO_SHOW_PAGE_SIZE );
    if nTotalCount ~= 0 then
        self.m_pPage:SetWndText( ( self.m_nPage + 1 ) .. " / " .. nTotalPage );
        self.m_pBtnLeft:ShowWnd( self.m_nPage > 0 );
        self.m_pBtnRight:ShowWnd( self.m_nPage < nTotalPage - 1 );
        self.m_pNoFriend:ShowWnd( false );
        self.m_pSearch:ShowWnd( true );
        self:GetDlgChild( "next" ):ShowWnd( true );
    else
        self.m_pPage:SetWndText( "0 / 0" );
        self.m_pNoFriend:ShowWnd( true );
        self.m_pSearch:ShowWnd( false );
        self:GetDlgChild( "next" ):ShowWnd( false );

        if self.m_eRelation == CFriendMgr.eRelationType_Followee then
            self.m_pNoFriendText:SetWndText( g_App:GetString( "wuguanzhu" ) );
        elseif self.m_eRelation == CFriendMgr.eRelationType_Follower then
            self.m_pNoFriendText:SetWndText( g_App:GetString( "wufensi" ) );
        elseif self.m_eRelation == CFriendMgr.eRelationType_Blacklist then
            self.m_pNoFriendText:SetWndText( g_App:GetString( "wuheimingdan" ) );
        else
            self.m_pNoFriendText:SetWndText( g_App:GetString( "wuxinfensi" ) );
        end
    end
	
	local nStart = self.m_nPage*FRIEND_INFO_SHOW_PAGE_SIZE;
	local nEnd = ( self.m_nPage + 1 )*FRIEND_INFO_SHOW_PAGE_SIZE;
	local tblCharInfo = FriendMgr:GetCharsInfo( self.m_eRelation, nStart, nEnd );
    for k, Item in pairs( tblCharInfo ) do
		if Item.szCharName then
			local szResName;
			if self.m_eRelation ~= CFriendMgr.eRelationType_Blacklist then
			    szResName = "gui/cfg/fsj_haoyou_guanzhu_item.gui";
			else
			    szResName = "gui/cfg/fsj_haoyou_heimingdan_item.gui";
			end
			self.m_pList:InsertRowItemsFromRes( -1, szResName, CCharListItem, 
				function ( ctrl, nItem, nCol )
				    local listItem = ctrl:GetSubItemByIndex( nItem );
				    listItem:Set( Item );
				    listItem.nList = self.m_eRelation;
				end,
				nil, nil );
		end
    end
end

--endregion
