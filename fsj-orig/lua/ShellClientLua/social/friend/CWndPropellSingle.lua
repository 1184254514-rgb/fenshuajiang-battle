--region CWndPropellSingle.lua
--Date 2018.03.27
--单个推荐玩家界面( "gui\cfg\fsj_haoyou_tuijian")

function CWndPropellSingle:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndPropellSingle:OnCreated()
	self.m_ListPhoto			= self:GetDlgChild( "zhaopian.tupian" );
	self.m_WndNoPhoto			= self:GetDlgChild( "zhaopian.kong" );
	self.m_pWndConstellation	= self:GetDlgChild( "wanjiaxinxi.xingzuo" );
	self.m_WndConstellationName	= self:GetDlgChild( "wanjiaxinxi.xingzuo.name" );
	self.m_WndConstellationIcon = CRichIconWnd:new( self.m_pWndConstellation, "icon" );
	self.m_WndID				= self:GetDlgChild( "wanjiaxinxi.w_id" );
	self.m_WndName				= self:GetDlgChild( "wanjiaxinxi.name" );
	self.m_WndHead				= self:GetDlgChild( "wanjiaxinxi.head.touxiang" );
	self.m_WndAge				= self:GetDlgChild( "wanjiaxinxi.genderandage.nianling" );
	self.m_IconUnknownSex		= self:GetDlgChild( "wanjiaxinxi.genderandage.weizhi.icon" );
	self.m_IconMale				= self:GetDlgChild( "wanjiaxinxi.genderandage.nan.icon" );
	self.m_IconFemale			= self:GetDlgChild( "wanjiaxinxi.genderandage.nv.icon" );
	self.m_WndAreaName			= self:GetDlgChild( "wanjiaxinxi.dingwei.name" );
	self.m_BtnAttention			= self:GetDlgChild( "qitawanjia.guanzhu" );
	self.m_BtnObserve			= self:GetDlgChild( "qitawanjia.guanzhan" );
	self.m_BtnCommend			= self:GetDlgChild( "qitawanjia.dianzan" );
	self.m_WndSignature			= self:GetDlgChild( "qianming.neirong" );
	self.m_BtnSwitch			= self:GetDlgChild( "btn_switch" );
	self.m_tblWndLadderLevel	= {};
	for i = 1, 8 do
		local Wnd				= self:GetDlgChild( "icon_duanwei." .. i );
		table.insert( self.m_tblWndLadderLevel, Wnd );
	end
	self.m_WndBeCommenedCount	= self:GetDlgChild( "huozan.w_guanzhu" );
	self.m_WndAttentionCount	= self:GetDlgChild( "guanzhu.w_guanzhu" );
	self.m_WndFansCount			= self:GetDlgChild( "fensi.w_guanzhu" );

	self.m_ListPhoto:SetInertiaType( eInertiaType_HScroll );

	self.m_BtnAttention:AddActionListener( "OnClickAttention", self );
	self.m_BtnCommend:AddActionListener( "OnClickCommend", self );
	self.m_BtnObserve:AddActionListener( "OnClickObserve", self );
	self.m_BtnSwitch:AddActionListener( "OnSwitch", self );

	g_App.m_EventDispatcher:AddEventListener( "OnAnswerPropellPlayer", "OnAnswerPropellPlayer", self );
    g_App.m_EventDispatcher:AddEventListener( "RelationshipCount", "RefreshFriendCount", self );
	g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "OnAddFollowee", self );
	g_App:GetMainPlayerData():AddEventListener( "m_DayCommendData", "OnAddCommend", self );
end

function CWndPropellSingle:OnWndShow( bShow )

end

function CWndPropellSingle:OnDestroy()
	CGWnd.OnDestroy( self );
	g_App.m_EventDispatcher:RemoveEventListener( "OnAnswerPropellPlayer", "OnAnswerPropellPlayer", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RelationshipCount", "RefreshFriendCount", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_DayCommendData", "OnAddCommend", self );
end

function CWndPropellSingle:QueryPropellPlayer()
	if not self.m_nPage then
		self.m_nPage = 0;
	end
	local NetMsg = CQueryPropellPlayer:new();
	NetMsg.m_nQueryPage = self.m_nPage;
	g_App:SendShellMsg( NetMsg );
	g_App:WaitMsg( true, 1500 );
end

function CWndPropellSingle:OnAnswerPropellPlayer( Event )
	g_App:WaitMsg( false );
	self:ShowWnd( true );
	self.m_tblAccountList = Event.m_tblAccountList;
	if #self.m_tblAccountList > 0 then
		self.m_nAccountIndex = 1;
		self:InitWndData( self.m_tblAccountList[self.m_nAccountIndex] );
	end
end

function CWndPropellSingle:InitWndData( tblAccountData )
	self.m_nAccountID = tblAccountData.nAccountID;
	self.m_WndName:SetWndText( tblAccountData.szNickName );
	self.m_WndAge:SetWndText( tblAccountData.nAge );
	CHeadIconConfig:Inst():SetIcon( self.m_WndHead, tblAccountData.nHeadIcon + 1, self.m_nAccountID );
	self.m_IconUnknownSex:ShowWnd( tblAccountData.nSex == eSexType_UnKnown );	
	self.m_IconMale:ShowWnd( tblAccountData.nSex == eSexType_Male );			
	self.m_IconFemale:ShowWnd( tblAccountData.nSex == eSexType_Female );
	local strID = "%09d";
	self.m_WndID:SetWndText( string.format( strID, self.m_nAccountID ) );
	self.m_WndConstellationName:SetWndText( g_tblTabFile.constellation[tblAccountData.nConstellation].dName );
	self.m_WndConstellationIcon:SetIconID( g_tblTabFile.constellation[tblAccountData.nConstellation].nIconID);
	self.m_WndAreaName:SetWndText( g_tblTabFile.area[tblAccountData.nArea].dName);
	if tblAccountData.szSignature == "" then
		tblAccountData.szSignature = g_App:GetString( "morenqianming" );
	end
	self.m_WndSignature:SetWndText( tblAccountData.szSignature );
	self.m_WndBeCommenedCount:SetWndText( tblAccountData.nBeCommendCount );
	local nCurLadderLevel =  CStarLevelConfig.Inst():GetBigLevel( tblAccountData.nLadderStarCount );
	for i = 1, 8 do
		self.m_tblWndLadderLevel[i]:ShowWnd( i == nCurLadderLevel );
	end
	self:SetButtonState();
	local NetMsg1 = CQueryRelationshipCount:new();
	NetMsg1.m_nAccountID = self.m_nAccountID;
	g_App:SendShellMsg( NetMsg1 );
	self:InitPhotoList();	
end

function CWndPropellSingle:HaveCommend()
	local PlayerData = g_App:GetMainPlayerData().m_DayCommendData;
	for i = 1, PlayerData:GetDataCount() do
		if PlayerData:GetData( i - 1 ) == self.m_nAccountID then
			return true;
		end
	end
	return false;
end

function CWndPropellSingle:SetButtonState()
	if CFriendMgr:Inst():IsFollowee( self.m_nAccountID ) then
		self.m_BtnAttention:SetWndText(  g_App:GetString( "yiguanzhu" ) );
		self.m_BtnAttention:EnableWnd( false );
	else
		self.m_BtnAttention:SetWndText(  g_App:GetString( "guanzhu" ) );
		self.m_BtnAttention:EnableWnd( true );
	end
	if self:HaveCommend( nAccountID ) then
		self.m_BtnCommend:SetWndText( g_App:GetString( "yidianzan" ) );
		self.m_BtnCommend:EnableWnd( false );
	else
		self.m_BtnCommend:SetWndText( g_App:GetString( "dianzan" ) );
		self.m_BtnCommend:EnableWnd( true );
	end	
end

function CWndPropellSingle:RefreshFriendCount( Event )
    self.m_WndAttentionCount:SetWndText( Event.m_nAttentionCount );
    self.m_WndFansCount:SetWndText( Event.m_nFansCount );
end

function CWndPropellSingle:OnClickAttention()
	local NetMsg = CAddFollowee:new();
    NetMsg.nAccountID = self.m_nAccountID;
	g_App:GetWorldConn():SendShellMsg( NetMsg );
end

function CWndPropellSingle:OnClickCommend()
	local worldConn = g_App:GetWorldConn();
	if not worldConn then
        return;
    end
	if self:HaveCommend() then
		g_App:HideMsg( g_App:GetString( "yidianzantips" ) );
		return;
	end
	local NetMsg = CAddCommendDay:new();
	NetMsg.nAccountIDTo	  = self.m_nAccountID;
	worldConn:SendShellMsg( NetMsg );
end

function CWndPropellSingle:OnClickObserve()
	local worldConn = g_App:GetWorldConn();
	if not worldConn then
        return;
    end
	local NetMsg = CObserveGame:new();
	NetMsg.m_nAccountID = self.m_nAccountID;
	NetMsg.m_nRaceRoomID = 0;
	worldConn:SendShellMsg( NetMsg );
end

function CWndPropellSingle:OnAddFollowee()
	self.m_BtnAttention:SetWndText( g_App:GetString( "yiguanzhu" ) );
	self.m_BtnAttention:EnableWnd( false );
	self.m_WndFansCount:SetWndText( tonumber( self.m_WndFansCount:GetWndText() ) + 1 );
end

function CWndPropellSingle:OnAddCommend()
	self.m_BtnCommend:SetWndText( g_App:GetString( "yidianzan" ) );
	self.m_BtnCommend:EnableWnd( false );
	self.m_WndBeCommenedCount:SetWndText( tonumber( self.m_WndBeCommenedCount:GetWndText() ) + 1 );
end

function CWndPropellSingle:InitPhotoList()
	if not self.m_nAccountID then return end;
	self.m_ListPhoto:DeleteAllColumn();
	self.m_ListPhoto:DeleteAllItem();
	for i = 1, ePhoto_Max_Count_VIP do
		self.m_ListPhoto:InsertColumn( i - 1, 520 );
	end

	self.m_ListPhoto:InsertRowItemsFromRes( -1, "gui/cfg/fsj_zhaopianitem.gui", CPhotoItem );
	self.m_ListPhoto:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnPhotoListItemLoaded", self );
end

function CWndPropellSingle:OnPhotoListItemLoaded()
	self.m_ListPhoto:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnPhotoListItemLoaded", self );
	local nItem = self.m_ListPhoto:GetItemCount();
	local nCol  = self.m_ListPhoto:GetColumnCount();
	for i = 0, nItem - 1 do
		for j = 0, nCol - 1 do
			local listItem = self.m_ListPhoto:GetSubItem( i, j )
			local nindex = i * ePhoto_Max_Count_VIP + j;
			listItem:DownloadPicture( self.m_nAccountID, nindex );
		end 
	end
end

function CWndPropellSingle:OnSwitch()
	if not self.m_nAccountID then
		return;
	end
	self.m_nAccountIndex = self.m_nAccountIndex + 1;
	if not self.m_tblAccountList[self.m_nAccountIndex] then
		self.m_nPage = self.m_nPage + 1;
		self:QueryPropellPlayer();
	else
		self:InitWndData( self.m_tblAccountList[self.m_nAccountIndex] );
	end
end

--endregion
