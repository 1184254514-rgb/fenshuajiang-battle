--region CFriendWnd.lua
--Date
--此文件由[BabeLua]插件自动生成

function CFriendWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CFriendWnd:OnCreated()
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pBtnFindFriend = self:GetDlgChild( "btn_zuo" ):GetDlgChild( "btn_1" );
	self.m_pBtnQueryFollowee = self:GetDlgChild( "btn_zuo" ):GetDlgChild( "btn_2" );
	self.m_pBtnQueryFollower = self:GetDlgChild( "btn_zuo" ):GetDlgChild( "btn_3" );
	self.m_pBtnQueryBlacklist = self:GetDlgChild( "btn_zuo" ):GetDlgChild( "btn_4" );
	self.m_pBtnQueryNewFollowers = self:GetDlgChild( "btn_zuo" ):GetDlgChild( "btn_5" );
	self.m_pBtnQueryPropellSingle = self:GetDlgChild( "btn_zuo" ):GetDlgChild( "btn_6" );
	self.m_pList = self:GetDlgChild( "list" );
	self.m_pBtnQueryNewFollowers:AddCueListener( self );

    self.m_pPageFindFriend = CFindFriendPage:new( "gui/cfg/fsj_haoyou_chazhao2.gui", self.m_pList, 0 );
    self.m_pPageQueryInfo = CFriendInfoPage:new( "gui/cfg/fsj_haoyou_guanzhu.gui", self.m_pList, 1 );
	self.m_pPagePropellSingle = CWndPropellSingle:new( "gui/cfg/fsj_haoyou_tuijian.gui", self.m_pList, 1 );

	self.m_pBtnClose:AddActionListener( "OnClose", self );
	self.m_pBtnFindFriend:AddActionListener( "OnFindFriend", self );
	self.m_pBtnQueryFollowee:AddActionListener( "OnQueryFollowee", self );
	self.m_pBtnQueryFollower:AddActionListener( "OnQueryFollower", self );
	self.m_pBtnQueryBlacklist:AddActionListener( "OnQueryBlacklist", self );
	self.m_pBtnQueryNewFollowers:AddActionListener( "OnQueryNewFollowers", self );
	self.m_pBtnQueryPropellSingle:AddActionListener( "OnQueryPropellSingle", self );

	self.m_pWndMoney	= self:GetDlgChild( "jinbi.jinbishuliang" ); 
	self.m_pBtnAddMoney = self:GetDlgChild( "jinbi.btn_add" );
	self.m_pBtnAddMoney:AddActionListener( "OnClickAddMoney", self );

	self.m_pWndRainbowGold = self:GetDlgChild( "jinbi2.jinbishuliang" );

	--设置wifi
	self.m_wifiIcon = { self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1") };--弱到强
	self.m_timeTick = CTick:new ( "OnTimeTick", self );
	self.m_timeTick:Start( 100 );

    g_App.m_EventDispatcher:AddEventListener( "AddFollower", "RefreshRedpoint", self );
    g_App.m_EventDispatcher:AddEventListener( "ClearNewFollower", "RefreshRedpoint", self );
end

function CFriendWnd:OnDestroy()
	self.m_timeTick:Stop();
	g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "OnAnswerQueryChar", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AddFollower", "RefreshRedpoint", self );
	g_App.m_EventDispatcher:RemoveEventListener( "ClearNewFollower", "RefreshRedpoint", self );
	CGWnd.OnDestroy( self );
end

function CFriendWnd:OnWndShow( bShowWnd )
	if not bShowWnd then
		local nNewFollowerType = CFriendMgr.eRelationType_NewFollower;
		local nNewFollowCount = CFriendMgr:Inst():GetCharInfoDataCount( nNewFollowerType )
        if self.m_nShowNewFollowerCount == nNewFollowCount and g_App.m_WorldConnect then
			self.m_nShowNewFollowerCount = 0;
			local NetMsg = CClearNewFollowers:new();
			g_App.m_WorldConnect:SendShellMsg( NetMsg );
			CFriendMgr:Inst():ClearNewFollower();
			local Event = {};
			Event.m_Type = "ClearNewFollower";
			Event.nAccountID = self.nAccountID;
			g_App.m_EventDispatcher:DispatchEvent( Event );
		end
		g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "OnAnswerQueryChar", self );
		return;
	end
	self.m_timeTick:Start(1000);
    self.m_pBtnFindFriend:SetCheck( false );
    self.m_pBtnQueryFollowee:SetCheck( false );
    self.m_pBtnQueryFollower:SetCheck( false );
    self.m_pBtnQueryBlacklist:SetCheck( false );
	self.m_pBtnQueryPropellSingle:SetCheck( true );
    self.m_pPageFindFriend:ShowWnd( false );
    self.m_pPageQueryInfo:ShowWnd( false );

	local nRainbowGold = g_App:GetPropCount( eGRT_Resource, eResourceType_RainbowGold );
	self.m_pWndRainbowGold:SetWndText( nRainbowGold );
	self.m_nShowNewFollowerCount = 0;
	g_App.m_EventDispatcher:AddEventListener( "CharsInfoChanged", "OnAnswerQueryChar", self );
	self:RefreshRedpoint();
	if not self.m_pPagePropellSingle.m_nAccountID then
		self.m_pPagePropellSingle:QueryPropellPlayer();
	else
		self.m_pPagePropellSingle:ShowWnd( true );
	end
end

function CFriendWnd:RefreshRedpoint()
	local nNewFollowerType = CFriendMgr.eRelationType_NewFollower;
	local nNewFollowCount = CFriendMgr:Inst():GetCharInfoDataCount( nNewFollowerType )
	local bNewFollow = nNewFollowCount ~= 0 and self.m_nShowNewFollowerCount~= nNewFollowCount;
	self.m_pBtnQueryNewFollowers:ShowRedPoint( bNewFollow );
end

function CFriendWnd:OnClose()
	self.m_timeTick:Stop();
	self:ShowWnd( false );
end

function CFriendWnd:OnClickAddMoney() 
	g_App:HideMsg(g_App:GetString("gongnengtips"));
end

function CFriendWnd:OnTimeTick()  
	if not g_App or not g_App:GetWorldConn() then
		return;
	end
	local wifi = g_App:GetWorldConn():GetPingDelay();

	local nIconShowed = wifi < ePing_low and 3 or ( wifi > ePing_high and 1 or 2 );
	for k, v in pairs( self.m_wifiIcon ) do
		self.m_wifiIcon[k]:ShowWnd( k == nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild( "wangsu" ):SetWndText( wifi );
	end
	local nCoinCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Gold );
	self.m_pWndMoney:SetWndText( tostring( nCoinCount ) );

end

function CFriendWnd:OnFindFriend()
    self.m_pPageFindFriend:ShowWnd( true );
    self.m_pPageQueryInfo:ShowWnd( false );
    self.m_pBtnQueryFollowee:SetCheck( false );
    self.m_pBtnQueryFollower:SetCheck( false );
    self.m_pBtnQueryBlacklist:SetCheck( false );
	self.m_pPagePropellSingle:ShowWnd( false );
end

function CFriendWnd:OnAnswerSearchPlayer( tblItems, nCount )
    self.m_pPageFindFriend:ShowWnd( true );
    self.m_pPageQueryInfo:ShowWnd( false );
    self.m_pPageFindFriend:OnResult( tblItems, nCount );
    g_App:WaitMsg( false );
end

function CFriendWnd:QueryCharsInfo( eRelation, nCurPage )
    if g_App.m_WorldConnect == nil then
        return;
    end
	self.m_eQueryRelation = eRelation;
	self.m_eQueryPage = nCurPage;
	local NetMsg = CQueryCharInfo:new();
	local FriendMgr = CFriendMgr:Inst();
	local nStart = nCurPage*FRIEND_INFO_SHOW_PAGE_SIZE;
	local nEnd = ( nCurPage + 1 )*FRIEND_INFO_SHOW_PAGE_SIZE;
	NetMsg.tblCharsID = FriendMgr:GetUncacheCharIDs( eRelation, nStart, nEnd );
	NetMsg.nContext = 1;
	if not NetMsg.tblCharsID[1] then
		return self:OnAnswerQueryChar()
	end
	g_App.m_WorldConnect:SendShellMsg( NetMsg );
    g_App:WaitMsg( true, 1500 );
end

function CFriendWnd:OnAnswerQueryChar( Event )
	if Event and Event.m_nContext == 0 then
		return;
	end

	self:RefreshRedpoint()
    self.m_pPageFindFriend:ShowWnd( false );
    self.m_pPageQueryInfo:ShowWnd( true );
	self.m_pPagePropellSingle:ShowWnd( false );
    self.m_pPageQueryInfo:OnResult( self.m_eQueryRelation, self.m_eQueryPage );
    g_App:WaitMsg( false );
end

function CFriendWnd:OnQueryFollowee()
	self:QueryCharsInfo( CFriendMgr.eRelationType_Followee, 0 );
end

function CFriendWnd:OnQueryFollower()
	self:QueryCharsInfo( CFriendMgr.eRelationType_Follower, 0 );
end

function CFriendWnd:OnQueryBlacklist()
	self:QueryCharsInfo( CFriendMgr.eRelationType_Blacklist, 0 );
end

function CFriendWnd:OnQueryNewFollowers()
	local nNewFollowerType = CFriendMgr.eRelationType_NewFollower;
	self.m_nShowNewFollowerCount = CFriendMgr:Inst():GetCharInfoDataCount( nNewFollowerType )
	self:QueryCharsInfo( CFriendMgr.eRelationType_NewFollower, 0 );
end

function CFriendWnd:OnQueryPropellSingle()
	if self.m_pPagePropellSingle:IsShow() then
		return;
	end
    self.m_pPageFindFriend:ShowWnd( false );
    self.m_pPageQueryInfo:ShowWnd( false );
	if self.m_pPagePropellSingle.m_nAccountID then
		self.m_pPagePropellSingle:ShowWnd( true );
	else
		self.m_pPagePropellSingle:QueryPropellPlayer();
	end
end

--endregion
