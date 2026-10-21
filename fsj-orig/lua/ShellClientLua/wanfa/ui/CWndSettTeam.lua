--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndSettTeam:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
	self.m_pWndCheckBtn = {};
	self.m_tblHasCommended = {};
end

function CWndSettTeam:OnCreated()
	self.m_textTitle = self:GetDlgChild( "tilte" );

	local nCount = 1;
	while true do
		local pWnd = self:GetDlgChild( "btn_top.btn" .. nCount );
		if not pWnd then
			break;
		end
		pWnd.m_nRank = nCount;
		pWnd:AddActionListener( "OnCheckBtn", self );
		table.insert( self.m_pWndCheckBtn, pWnd );
		nCount = nCount + 1;
	end

	self.m_pWndList = self:GetDlgChild( "list" );
	self.m_pWndList:SetInertiaType( eInertiaType_VScroll );
	self.m_pWndList:SetItemHeight( 90 );
	
	self.m_btnContinue = self:GetDlgChild( "btn_jixuyouxi" );
	self.m_btnContinue:AddActionListener( "OnClickContinue", self );
	self.m_btnBack = self:GetDlgChild( "btn_fanhui" );
	self.m_btnBack:AddActionListener( "OnClickBack", self );
	
	self.m_wndNoDetails = self:GetDlgChild( "bg_tips" );
	self.m_wndNoDetails:ShowWnd( false );	

	self.m_BtnSwitchReport = self:GetDlgChild( "jubao" );
	self.m_BtnSwitchReport:AddActionListener( "OnClickSwitchReport", self );

	self.m_pWndScoreName = self:GetDlgChild( "bg_3" );

	if self.m_bUpdateData then
		self:ShowTeamInfo( self.m_nTeamRank );
		self.m_bUpdateData = false;
	end
end

function CWndSettTeam:OnClickContinue()
	print( "-------" );
	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	print( "-----------" .. nRoomType );
	g_App:SwitchStart();
	g_App:EnterRoom( nRoomType );
end

function CWndSettTeam:OnClickBack()
	g_App:SwitchStart();
end

function CWndSettTeam:OnCheckBtn( Event )
	local nSelectRank = Event.m_CurrentTarget.m_nRank;
	if nSelectRank == self.m_nTeamIndex then
		return;
	end
	if not self.m_tblSettlementTeam[nSelectRank] then
		self.m_pWndCheckBtn[self.m_nTeamIndex]:SetCheck( true );
		g_App:HideMsg(  CStringConfig.Inst():GetString( "meiyoucansaiduiwu" ) );
		return;
	end
	if self.m_wndNoDetails and self.m_wndNoDetails:IsShow() then
		self.m_wndNoDetails:ShowWnd( false );
	end
	self:ShowTeamInfo( nSelectRank );
end


function CWndSettTeam:OnClickSwitchReport()
	for i = 1, self.m_pWndList:GetItemCount() do
		local nItem = i - 1;
		local subItem = self.m_pWndList:GetSubItem( nItem, 0 );
		subItem:SwitchReport( self.m_BtnSwitchReport:GetCheck() );
    end 
end

function CWndSettTeam:UpdateData( nSettType, nTeamRank, nPlayerRank, tblSettlementTeam )
	self.m_nSettType = nSettType;
	self.m_nTeamRank = nTeamRank;
	self.m_nPlayerRank = nPlayerRank;
	self.m_tblSettlementTeam = tblSettlementTeam;

	if not self:IsCreated() then
		self.m_bUpdateData = true;
		return;
	end
	self:ShowTeamInfo( self.m_nTeamRank );
end

function CWndSettTeam:ShowTeamInfo( nTeamIndex )
	self.m_nTeamIndex = nTeamIndex;

	local szSettlementTypeMsg = "";
	if self.m_nSettType == eSettlementType_RemainEnd then
		szSettlementTypeMsg = CStringConfig.Inst():GetString( "jiesuantishi1" );
	elseif self.m_nSettType == eSettlementType_ManorAllUse then
		szSettlementTypeMsg = CStringConfig.Inst():GetString( "jiesuantishi2" );
	elseif self.m_nSettType == eSettlementType_OthersDie then
		szSettlementTypeMsg = CStringConfig.Inst():GetString( "jiesuantishi2" );
	elseif self.m_nSettType == eSettlementType_CurShort then
		szSettlementTypeMsg = CStringConfig.Inst():GetString( "jiesuantishi3" );
	end
	self.m_textTitle:SetWndText( szSettlementTypeMsg );
	self.m_pWndCheckBtn[self.m_nTeamIndex]:SetCheck( true );

	self.m_pWndList:DeleteAllItem();
	local nPlayerCount = #self.m_tblSettlementTeam[self.m_nTeamIndex];
	local bObserve = g_App:GetGameMain().m_bObserveGame;
	for i = 1, nPlayerCount do
		if bObserve then
			self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_tuanzhan_jiesuan_duiwupaiming_item.gui", CWndSettTeamItem );
		else
			if self.m_nTeamIndex == self.m_nTeamRank and i == self.m_nPlayerRank then
				self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_tuanzhan_jiesuan_duiwupaiming_item2.gui", CWndSettTeamItem );
			else
				self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_tuanzhan_jiesuan_duiwupaiming_item.gui", CWndSettTeamItem );
			end
		end
	end

	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self );
	local Scene = g_App:GetScene();
	if Scene then
		local nRoomType = Scene:GetRoomType();
		if nRoomType == eRT_TeamRace then
			self.m_pWndScoreName:SetWndText( g_App:GetString( "saishijifenjiangli" ) );
		end
	end
end

function CWndSettTeam:OnItemListLoaded()
	self.m_pWndList:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self );

	local tblPlayers = self.m_tblSettlementTeam[self.m_nTeamIndex];
	local nTeamScore = 0;
	for _, playerInfo in pairs( tblPlayers ) do
		nTeamScore = nTeamScore + playerInfo.m_nAllScore;
	end
	
	for i = 1, self.m_pWndList:GetItemCount() do
		local nItem = i - 1;
		local subItem = self.m_pWndList:GetSubItem( nItem, 0 );
		local tblData = tblPlayers[i];
		subItem:SetSettData( i, nTeamScore, tblData, self.m_BtnSwitchReport:GetCheck(), self.m_nTeamIndex, #self.m_tblSettlementTeam );
    end 
end

local eLadderStarTypeCount = 16;
function CWndSettTeamItem:Ctor()
end

function CWndSettTeamItem:OnCreated()
	self.m_pWndRank			= self:GetDlgChild( "paiming" );
	self.m_pWndName			= self:GetDlgChild( "name" );
	self.m_pWndScore		= self:GetDlgChild( "defen" );
	self.m_pTeamProgress	= self:GetDlgChild( "jindutiao" );
	self.m_pTeamScore		= self:GetDlgChild( "jindutiao.defen" );
	self.m_pBtnAttention	= self:GetDlgChild( "b_guanzhu" );
	self.m_pBtnZERO			= self:GetDlgChild( "bg_kong" );
	self.m_pText			= self:GetDlgChild( "b_zhuangtai" );
	self.m_iconHead			= self:GetDlgChild( "head.touxiang" );
	self.m_pBtncommend		= self:GetDlgChild( "zan" );
	self.m_pBtnShowInfo		= self:GetDlgChild( "wanjiaxinxi" );
	self.m_pBtnReport		= self:GetDlgChild( "jubao" );

	self.m_iconLadderStar	= {};
	for i = 0, eLadderStarTypeCount - 1 do 
		self.m_iconLadderStar[i] = self:GetDlgChild( "icon_duanwei.".. i );
		self.m_iconLadderStar[i]:ShowWnd( false );
	end
	
	self.m_pBtnAttention:AddActionListener( "OnAttention", self );
	self.m_pBtncommend:AddActionListener( "OnCommend", self );
	self.m_pBtnShowInfo:AddActionListener( "OnShowInfo", self );
	self.m_pBtnReport:AddActionListener( "OnClickReport", self );

	if not self.m_bUpdateData then
		return;
	end
	self:UpdateData();
end

function CWndSettTeamItem:OnDestroy()
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
	CGWnd.OnDestroy( self );
end

function CWndSettTeamItem:OnAttention()
	if not g_App:GetWorldConn() or not self.m_pSettData.m_nAccountID or
		self.m_pSettData.m_nAccountID == 0 then
		g_App:HideMsg( g_App:GetString("fb_guanzhutips1") );
		return;
	end
	g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "OnAddFollowee", self );
	local NetMsg = CAddFollowee:new();
    NetMsg.nAccountID = self.m_pSettData.m_nAccountID;
	g_App:GetWorldConn():SendShellMsg( NetMsg );
end

function CWndSettTeamItem:OnCommend()
	if not g_App:GetWorldConn() then
		g_App:HideMsg( g_App:GetString( "noduoren" ) );
		return;
	end
	self.m_pBtncommend:EnableWnd( false );
	self:GetParent():GetParent().m_tblHasCommended[self.m_pSettData.m_nObjectID] = true;
	local NetMsg = CAddCommend:new();
	NetMsg.m_nBeCommendID = self.m_pSettData.m_nAccountID;
	g_App:GetWorldConn():SendShellMsg( NetMsg );
end

function CWndSettTeamItem:OnClickReport()
	g_App:GetScene():GetWanfa().m_pWndSettlemet.m_pWndReport:ShowData( self.m_pSettData.m_nAccountID, self.m_pSettData.m_nObjectID, self.m_pSettData.m_szNickName, self.m_pBtnReport );
end

function CWndSettTeamItem:UpdateData()
	self.m_pWndRank:SetWndText( tostring( self.m_nIndex ) );
	self.m_pWndName:SetWndText( self.m_pSettData.m_szNickName );
	self.m_pWndScore:SetWndText( tostring( self.m_pSettData.m_nAllScore ) );
	self.m_pTeamProgress:SetRange( self.m_nTeamScore );
	self.m_pTeamProgress:SetPos( self.m_pSettData.m_nAllScore );
	local nRatio = math.floor( self.m_pSettData.m_nAllScore / self.m_nTeamScore * 100 );
	if self.m_nTeamScore == 0 then
		nRatio = 0;
	end
	self.m_pTeamScore:SetWndText( nRatio.."%" );
	local bAttention = self.m_pSettData.m_nAccountID ~= g_App:GetAccountID() and not self.isFollowee and not self.isBlacklist;
	self.m_pBtnAttention:ShowWnd( bAttention );
	self.m_pBtnZERO:ShowWnd( not bAttention );

    if self.m_pText ~= nil then
	    self.m_pText:ShowWnd( not bAttention );
    
        if self.isFollowee then
            self.m_pText:SetWndText( g_App:GetString( "yiguanzhu" ) );
        elseif self.isBlacklist then
            self.m_pText:SetWndText( g_App:GetString( "heimingdan" ) );
        end
    end

	local nHeadIconID = 0;
	if self.m_pSettData.m_nAccountID == 0 then
		nHeadIconID = self.m_pSettData.m_nEquipID;
	else
		nHeadIconID = self.m_pSettData.m_nHeadIconID + 1;
	end
	local nStarLevel = CStarLevelConfig:Inst():GetLevel( self.m_pSettData.m_nLadderStar );
	self.m_iconLadderStar[nStarLevel - 1]:ShowWnd( true );
	CHeadIconConfig:Inst():SetIcon( self.m_iconHead, nHeadIconID, self.m_pSettData.m_nAccountID );

	local Scene = g_App:GetScene();
	if Scene then
		local nRoomType = Scene:GetRoomType();
		if nRoomType == eRT_TeamRace then
			local nIndex = self.m_nTeamRank * 10 + self.m_nIndex;
			local nRaceScore = g_tblTabFile.race_rankprize[nIndex]["nRaceScore"];
			self.m_pWndScore:SetWndText( nRaceScore );
		end
	end
end

function CWndSettTeamItem:SetSettData( nItem, nTeamScore, tblData, bShowReport, nTeamRank, nTeamCount )
	self.m_nIndex = nItem;
	self.m_nTeamScore = nTeamScore;
	self.m_pSettData = tblData;
	self.m_nTeamRank = nTeamRank;
	self.m_nTeamCount = nTeamCount;
	
    self.isFollowee = CFriendMgr:Inst():IsFollowee( self.m_pSettData.m_nAccountID );
    self.isBlacklist = CFriendMgr:Inst():IsBlacklist( self.m_pSettData.m_nAccountID );

	local HasCommend = self:GetParent():GetParent().m_tblHasCommended[self.m_pSettData.m_nObjectID];
	if HasCommend then
		self.m_pBtncommend:SetCheck( true );
	end

	local HasReport = g_App:GetScene():GetWanfa().m_pWndSettlemet.m_tblHasReport[self.m_pSettData.m_nObjectID];
	if HasReport then
		self.m_pBtnReport:EnableWnd( false );
	end

	if not self:IsCreated() then
		self.m_bUpdateData = true;
		return;
	end
	self:UpdateData();
	self:SwitchReport( bShowReport );
end

function CWndSettTeamItem:OnAddFollowee( event )
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
    if event.nAccountID == self.m_pSettData.m_nAccountID then
        self.isFollowee = true;
	    self:UpdateData();
    end
end

function CWndSettTeamItem:OnShowInfo()
	if self.m_pSettData.m_nAccountID == 0 then
		g_App:HideMsg( g_App:GetString( "buxuchakan" ) );
		return;
	end
	g_App:ShowPlayerInfo( self.m_pSettData.m_nAccountID );
end

function CWndSettTeamItem:SwitchReport( bShowReport )
	self.m_pBtncommend:ShowWnd( not bShowReport );
	self.m_pBtnReport:ShowWnd( bShowReport );
end
--endregion
