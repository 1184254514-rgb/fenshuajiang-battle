--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


function CWndSettLimit:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndSettLimit:OnCreated()
	self.m_pWndList = self:GetDlgChild( "list" );
	self.m_pWndList:SetInertiaType( eInertiaType_VScroll );
	self.m_pWndList:SetItemHeight( 50 );	
	self.m_btnContinue = self:GetDlgChild( "btn_jixuyouxi" );
	self.m_btnContinue:AddActionListener( "OnClickContinue", self );
	self.m_btnBack = self:GetDlgChild( "btn_fanhui" );
	self.m_btnBack:AddActionListener( "OnClickBack", self );
	self.m_pWndCoin = self:GetDlgChild( "jinbi" );
	
	if self.m_bUpdateData  then
		self:UpdateData( self.m_nTeamRank, self.m_nPlayerRank, self.m_tblSettlementTeam );
	end
end

function CWndSettLimit:OnClickContinue()
	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	g_App:SwitchStart();
	g_App:EnterRoom( nRoomType );
end

function CWndSettLimit:OnClickBack()
	g_App:SwitchStart();
end

function CWndSettLimit:UpdateData( nTeamRank, nPlayerRank, tblSettlementTeam )
	self.m_nTeamRank = nTeamRank;
	self.m_nPlayerRank = nPlayerRank;
	self.m_tblSettlementTeam = tblSettlementTeam;
	if not self:IsCreated() then
		self.m_bUpdateData = true;
		return;
	end
	self.m_bUpdateData = false;

	self.m_pWndList:DeleteAllItem();
	local bObserve = g_App:GetGameMain().m_bObserveGame;
	for i = 1, #self.m_tblSettlementTeam do
		if bObserve then
			self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_xianshimoshi_benjupaiming_item1.gui", CWndSettRandItem );
		else
			if i == self.m_nTeamRank then
				self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_xianshimoshi_benjupaiming_item2.gui", CWndSettRandItem );
			else
				self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_xianshimoshi_benjupaiming_item1.gui", CWndSettRandItem );
			end
		end
	end
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self );
end

function CWndSettLimit:OnItemListLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self );

	local nPlayerCount = 0;
	for _,tblPlayers in pairs( self.m_tblSettlementTeam ) do
		for _,info in pairs( tblPlayers ) do
			nPlayerCount = nPlayerCount + 1;
		end
	end

	local pSettlemet = g_App:GetScene():GetWanfa().m_pWndSettlemet;
	for i = 1, self.m_pWndList:GetItemCount() do
		local nItem = i - 1;
		local subItem = self.m_pWndList:GetSubItem( nItem, 0 );
		local tblData = self.m_tblSettlementTeam[i][1];
		subItem:SetSettData( i, tblData, nPlayerCount );
    end

	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	if Scene and nRoomType and nRoomType == eRT_LimitRace then
		self.m_pWndCoin:SetWndText( g_App:GetString( "saishijifenjiangli" ) );
	else
		self.m_pWndCoin:SetWndText( g_App:GetString( "jianglijinbi" ) );
	end
	self.m_pWndCoin:ShowWnd( not ( Scene and nRoomType and nRoomType == eRT_LimitSecret ) );
end


local eLadderStarTypeCount = 16;
function CWndSettRandItem:Ctor()

end

function CWndSettRandItem:OnCreated()
	self.m_pWndIndex		= self:GetDlgChild( "paiming" );
	self.m_pWndName			= self:GetDlgChild( "name" );
	self.m_pWndScore		= self:GetDlgChild( "defen" );
	self.m_pWndCoin			= self:GetDlgChild( "jinbi" );
	self.m_pWndHeadIcon		= self:GetDlgChild( "head.touxiang" );
	self.m_pBtnAttention	= self:GetDlgChild( "b_guanzhu" );

	self.m_iconFirst		= self:GetDlgChild( "No_1" );
	self.m_iconSecond		= self:GetDlgChild( "No_2" );
	self.m_iconThird		= self:GetDlgChild( "No_3" );

	self.m_BtnCommend		= self:GetDlgChild( "zan" );
	self.m_BtnReport		= self:GetDlgChild( "jubao" );

	self.m_btnShowInfo		= self:GetDlgChild( "wanjiaxinxi" );
	self.m_btnShowInfo:AddActionListener( "OnShowInfo", self );

	self.m_iconLadderStar	= {};
	for i = 0, eLadderStarTypeCount - 1 do 
		self.m_iconLadderStar[i] = self:GetDlgChild( "icon_duanwei.".. i );
		self.m_iconLadderStar[i]:ShowWnd( false );
	end

	self.m_iconFirst:ShowWnd( false );
	self.m_iconSecond:ShowWnd( false );
	self.m_iconThird:ShowWnd( true );
	self.m_pText			= self:GetDlgChild( "b_zhuangtai" );
	self.m_pBtnAttention:AddActionListener( "OnClickAddAttention", self );
	self.m_BtnCommend:AddActionListener( "OnClickCommend", self );

	if self.m_BtnReport then
		self.m_BtnReport:AddActionListener( "OnClickReport", self );
	end

	if not self.m_bUpdateData then
		return;
	end
	self:UpdateData();
end

function CWndSettRandItem:OnDestroy()
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
	CGWnd.OnDestroy( self );
end

function CWndSettRandItem:OnClickAddAttention()
	if self.m_tblData.m_nAccountID == 0 then
		g_App:HideMsg( g_App:GetString("fb_guanzhutips1") );
	else
	    g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "OnAddFollowee", self );
		local NetMsg = CAddFollowee:new();
		NetMsg.nAccountID = self.m_tblData.m_nAccountID;
		g_App.m_WorldConnect:SendShellMsg( NetMsg );
	end
end

function CWndSettRandItem:UpdateData()
	if self.m_nIndex > 3 then
		self.m_pWndIndex:SetWndText( tostring( self.m_nIndex ) );
	else
		self.m_pWndIndex:ShowWnd( false );
	end

	local nStarLevel = CStarLevelConfig:Inst():GetLevel( self.m_tblData.m_nLadderStar );
	self.m_iconLadderStar[nStarLevel -1]:ShowWnd( true );

	self.m_pWndName:SetWndText( self.m_tblData.m_szNickName );
	self.m_pWndScore:SetWndText( tostring( self.m_tblData.m_nAllScore ) );

	local nRankPrizeGold = CRankPrizeConfig:Inst():GetPrize( self.m_nIndex - 1, eRT_LimitTime );
	self.m_pWndCoin:SetWndText( nRankPrizeGold );
	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	self.m_pWndCoin:GetDlgChild( "icon" ):ShowWnd( true );
	if Scene and nRoomType and nRoomType == eRT_LimitRace then
		local nIndex = self.m_nPlayerCount * 100 + self.m_nIndex;
		local nRaceScore = g_tblTabFile.race_rankprize[nIndex]["nRaceScore"];
		self.m_pWndCoin:SetWndText( nRaceScore );
		self.m_pWndCoin:GetDlgChild( "icon" ):ShowWnd( false );
	end
	self.m_pWndCoin:ShowWnd( not ( Scene and nRoomType and nRoomType == eRT_LimitSecret ) );

	self.m_iconFirst:ShowWnd( self.m_nIndex == 1 );
	self.m_iconSecond:ShowWnd( self.m_nIndex == 2 );
	self.m_iconThird:ShowWnd( self.m_nIndex == 3 );
	local nAccountID = self.m_tblData.m_nAccountID;
	local nHeadIconID = 0;
	if nAccountID == 0 then
		nHeadIconID = self.m_tblData.m_nEquipID;
	else
		nHeadIconID = self.m_tblData.m_nHeadIconID + 1;
	end
    
	local bAttention = nAccountID ~= g_App:GetAccountID() and not self.isFollowee and not self.isBlacklist;
	if self.m_pBtnAttention then
        self.m_pBtnAttention:ShowWnd( bAttention );
    end
    if self.m_pText ~= nil then
	    self.m_pText:ShowWnd( not bAttention );
    
        if self.isFollowee then
            self.m_pText:SetWndText( g_App:GetString( "yiguanzhu" ) );
        elseif self.isBlacklist then
            self.m_pText:SetWndText( g_App:GetString( "heimingdan" ) );
        end
    end

	CHeadIconConfig:Inst():SetIcon( self.m_pWndHeadIcon, nHeadIconID, nAccountID );
	local HasReport = g_App:GetScene():GetWanfa().m_pWndSettlemet.m_tblHasReport[self.m_tblData.m_nObjectID];
	if HasReport then
		self.m_pBtnReport:EnableWnd( false );
	end
end

function CWndSettRandItem:SetSettData( nIndex, tblData, nPlayerCount )
	self.m_nIndex = nIndex;
	self.m_tblData = tblData;
	self.m_nPlayerCount = nPlayerCount;

    self.isFollowee = CFriendMgr:Inst():IsFollowee( self.m_tblData.m_nAccountID );
    self.isBlacklist = CFriendMgr:Inst():IsBlacklist( self.m_tblData.m_nAccountID );

	if not self:IsCreated() then
		self.m_bUpdateData = true;
		return;
	end
	self:UpdateData();
end

function CWndSettRandItem:OnAddFollowee( event )
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
    if event.nAccountID == self.m_tblData.m_nAccountID then
        self.isFollowee = true;
	    self:UpdateData();
    end
end

function CWndSettRandItem:OnShowInfo()
	if self.m_tblData.m_nAccountID == 0 then
		g_App:HideMsg( g_App:GetString( "buxuchakan" ) )
		return;
	end
	g_App:ShowPlayerInfo( self.m_tblData.m_nAccountID );
end

function CWndSettRandItem:OnClickCommend()
	if not g_App:GetWorldConn() then
		g_App:HideMsg( g_App:GetString( "noduoren" ) );
		return;
	end
	self.m_BtnCommend:EnableWnd( false );
	if self.m_tblData.m_nAccountID == 0  then
		return;
	end
	local NetMsg = CAddCommend:new();
	NetMsg.m_nBeCommendID = self.m_tblData.m_nAccountID;
	g_App:GetWorldConn():SendShellMsg( NetMsg );
end

function CWndSettRandItem:OnClickReport()
	g_App:GetScene():GetWanfa().m_pWndSettlemet.m_pWndReport:ShowData( self.m_tblData.m_nAccountID, self.m_pSettData.m_nObjectID, self.m_tblData.m_szNickName, self.m_pBtnReport );
end
--endregion
