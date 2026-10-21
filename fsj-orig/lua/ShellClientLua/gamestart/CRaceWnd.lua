--region CRaceWnd.lua
--Date	2018/1/16
--此文件由[BabeLua]插件自动生成

local MaxShowItemNum = 20;
local MaxShowTeamItemNum = 20;

function CRaceWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CRaceWnd:OnCreated()	
	self.m_pBtnRank = self:GetDlgChild( "b_paihangbang" );
	self.m_pBtnRank:AddActionListener( "OnClickRank", self );
	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_pWndMoney = self:GetDlgChild( "jinbi.jinbishuliang" );
	self.m_pWndRainbowGold = self:GetDlgChild( "jinbi2.jinbishuliang" );
	self.m_BtnShare = self:GetDlgChild( "jinbi2.btn_add" );
	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new( "OnRefreshTimeTick", self );
	self.m_tickRefreshInfo = CTick:new( "OnRefreshInfo", self );
	self.m_pWndConfirmInvite = CConfirmInviteWnd:new( "gui/cfg/fsj_goumaiqueren.gui", g_App:GetGameStart(), 1 );

	self.m_list = self:GetDlgChild( "bg.list" );
	self.m_list:SetInertiaType( eInertiaType_VScroll );
	self.m_pWndShowNum = self:GetDlgChild( "bg.bg6" );

	self.m_listTeam = self:GetDlgChild( "bg.list2" );
	self.m_listTeam:SetInertiaType( eInertiaType_VScroll );
	self.m_pWndRaceTeamMember = self:GetDlgChild( "bg.tuanzhanzudui" );
	self.m_pWndTeamTips = self:GetDlgChild( "bg.tuanzhanzudui.tips" );		--团战不满足条件时的tips
	self.m_pWndTeamTips:ShowWnd( false );
	self.m_pWndTeamInvite = self:GetDlgChild( "bg.tuanzhanzudui.kuaisuyaoqing" );
	self.m_pWndTeamInvite:AddActionListener( "OnCopyTeamCode", self );

	self.m_pBtnLimit = self:GetDlgChild( "liebiao.btn_1" );
	self.m_pBtnTeam = self:GetDlgChild( "liebiao.btn_2" );
	self.m_pBtnLimit:AddActionListener( "OnClickRaceType", self );
	self.m_pBtnTeam:AddActionListener( "OnClickRaceType", self );

	self.m_tblTeamRaceMember = {};
	self.m_pMemberSkillID = {};
	for i = 1, ETEAM_PLAY_COUNT do
		local pMemberWnd = self.m_pWndRaceTeamMember:GetDlgChild( "wanjia" );
		table.insert( self.m_tblTeamRaceMember, pMemberWnd:GetDlgChild( "head"..i ) );
		self.m_pMemberSkillID[i] = CRichIconWnd:new( pMemberWnd, "head"..i..".jineng" );
        pMemberWnd:GetDlgChild( "head"..i ):AddActionListener( function( event )
			if i > CPlayerRoomMemberInfoMgr:Instance():GetCount() then
				return;
			end
            self:KickMember( self.m_tblMemberAllData[i - 1].nPos );
        end, nil );
	end
	self.m_pBtnSkill = self.m_pWndRaceTeamMember:GetDlgChild( "btn_jineng" );
	self.m_pBtnSkill:AddActionListener( "OnClickSkillDevelop", g_App:GetGameStart() );
	self.m_pBtnOK = self.m_pWndRaceTeamMember:GetDlgChild( "btn_ok" );
	self.m_pBtnOK:AddActionListener( "OnClickOK", self );
	self.m_pBtnBack = self.m_pWndRaceTeamMember:GetDlgChild( "btn_back" );
	self.m_pBtnBack:AddActionListener( "OnClickBack", self );
	
	self.m_btnIM = self:GetDlgChild("liaotian");
	self.m_descWorld = self.m_btnIM:GetDlgChild("neirong");
	self.m_descFriend = self.m_btnIM:GetDlgChild("hongdian");
	self.m_btnIM:AddEventListener( GM_WM_MOUSECLICK, "OnClickIM", g_App.m_GameStart );
	self.m_descWorld:SetInertiaType( eInertiaType_HScroll );	
	self:UpdateIMDesc();		
	g_App.m_EventDispatcher:AddEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
	
	self.m_BtnShare:AddActionListener( "OpenShareWnd", g_App:GetGameStart() );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
	g_App:GetGameStart():AddEventListener( "OnWorldRaceInfoData", "OnRefreshWorldRaceInfo", self );
	g_App:GetGameStart():AddEventListener( "OnRaceMemberInfoData", "OnRefreshRaceMemberInfo", self );	
	g_App:GetGameStart():AddEventListener( "OnReadyChange", "ChangeReady", self );
	g_App.m_EventDispatcher:AddEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
	self:InitRaceWnd();
end

function CRaceWnd:OnDestroy()
	self.m_tickRefreshInfo:Stop();
	self.m_timeTick:Stop();
	self.m_list:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	self.m_list:RemoveEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectListItem", self );
	self.m_listTeam:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnTeamItemListLoaded", self ); 
	self.m_listTeam:RemoveEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectTeamListItem", self );
	g_App:GetGameStart():RemoveEventListener( "OnWorldRaceInfoData", "OnRefreshWorldRaceInfo", self );
	g_App:GetGameStart():RemoveEventListener( "OnRaceMemberInfoData", "OnRefreshRaceMemberInfo", self );		
	g_App:GetGameStart():RemoveEventListener( "OnReadyChange", "ChangeReady", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
	CGWnd.OnDestroy( self );
end

function CRaceWnd:OnWndShow( bShow )
	if bShow then
		local bIsInTeam = CPlayerRoomMemberInfoMgr:Instance():IsInTeam();
		local sTime = GetFormatTimeSTMFromMillisecond( GetLocalTime() );
		local nDayOfWeek = sTime:m_nDayofWeek();
		if nDayOfWeek == 0 then
			nDayOfWeek = 7;
		end
		local bShowLimit = g_tblTabFile.day_race_switch[nDayOfWeek].nLimitSwitch == 1;
		local bShowTeam = g_tblTabFile.day_race_switch[nDayOfWeek].nTeamSwitch == 1;
		self.m_pBtnLimit:SetCheck( bShowLimit );
		self.m_pBtnTeam:SetCheck( bShowTeam );
		self:OnClickRaceType();
		self.m_timeTick:Start(1000);
		self.m_tickRefreshInfo:Start(3000);
	else
		
		self.m_tickRefreshInfo:Stop();
		self.m_timeTick:Stop();
		self.m_tblRaceInfo = {};
	end
end

function CRaceWnd:OnClose()
	local NetMsg = CLeaveTeam:new();
	NetMsg.bCreateNewTeam = false;
	g_App:SendShellMsg( NetMsg );
	self:ShowWnd( false );
	CPlayerRoomMemberInfoMgr:Instance():ClearData();
end

function CRaceWnd:OnRefreshTimeTick()	
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
	local nRainbowGold = g_App:GetPropCount( eGRT_Resource, eResourceType_RainbowGold );
	self.m_pWndRainbowGold:SetWndText( nRainbowGold );
end

function CRaceWnd:OnRefreshInfo()
	if self.m_pBtnLimit:GetCheck() then
		self.m_pWndShowNum:SetWndText( g_App:GetString( "dangqianrenshu" ) );	
		local NetMsg = CQueryWorldRaceInfo:new();
		NetMsg.nType = eMRT_LimitRace;
		g_App:SendShellMsg( NetMsg );
	end
	if self.m_pBtnTeam:GetCheck() then		
		self.m_pWndShowNum:SetWndText( g_App:GetString( "dangqianduiwushu" ) );
		local NetMsgInfo = CQueryWorldRaceInfo:new();
		NetMsgInfo.nType = eMRT_TeamRace;
		g_App:SendShellMsg( NetMsgInfo );
		self:ShowRaceMemberInfo();
	end
	--队伍人数>1时隐藏返回按钮
	local nCount = CPlayerRoomMemberInfoMgr:Instance():GetCount();
	self.m_pBtnClose:ShowWnd( nCount <= 1 );
	self.m_pBtnBack:ShowWnd( nCount > 1 );
end

function CRaceWnd:OnRefreshWorldRaceInfo( Event )
	if Event.m_nRaceType == eMRT_LimitRace then
		self.m_tblRaceInfo = Event.m_tblRaceInfo;
		if #self.m_tblRaceInfo > MaxShowItemNum then
			MaxShowItemNum = MaxShowItemNum * 2;
			self:InitLimitList();
		else
			self:RefreshInfo();
		end	
	elseif Event.m_nRaceType == eMRT_TeamRace then
		self.m_tblTeamRaceInfo = Event.m_tblRaceInfo;
		if #self.m_tblTeamRaceInfo > MaxShowTeamItemNum then
			MaxShowTeamItemNum = MaxShowTeamItemNum * 2;
			self:InitTeamList();
		else
			self:RefreshTeamInfo();
		end	
	end
end

function CRaceWnd:InitRaceWnd()
	self:InitLimitList();
	self:InitTeamList();
end

function CRaceWnd:InitLimitList()
	self.m_tblRaceInfo = {};
	self.m_list:DeleteAllItem();
	self.m_list:DeleteAllColumn();

	local nItemNum = MaxShowItemNum;
	self.m_list:InsertColumn( -1, self.m_list:GetWndWidth() );
	for i = 1, nItemNum do
		self.m_list:InsertRowItemsFromRes( -1, "gui/cfg/fsj_saishi_item.gui", CRaceInfoItem );
	end	
	self.m_list:ShowWnd( false );
	self.m_list:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	self.m_list:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectListItem", self );
end

function CRaceWnd:InitTeamList()
	self.m_tblTeamRaceInfo = {};
	self.m_listTeam:DeleteAllItem();
	self.m_listTeam:DeleteAllColumn();

	local nItemNum = MaxShowTeamItemNum;
	self.m_listTeam:InsertColumn( -1, self.m_listTeam:GetWndWidth() );
	for i = 1, nItemNum do
		self.m_listTeam:InsertRowItemsFromRes( -1, "gui/cfg/fsj_saishi_item.gui", CRaceInfoItem );
	end
	self.m_listTeam:ShowWnd( false );
	self.m_listTeam:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnTeamItemListLoaded", self ); 
	self.m_listTeam:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectTeamListItem", self );
end

function CRaceWnd:OnItemListLoaded()
	self.m_list:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	if next( self.m_tblRaceInfo ) then
		self:RefreshInfo();
	end
end

function CRaceWnd:OnTeamItemListLoaded()
	self.m_listTeam:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnTeamItemListLoaded", self );
	if next( self.m_tblTeamRaceInfo ) then
		self:RefreshTeamInfo();
	end
end

function CRaceWnd:RefreshInfo()
	for i = 0, self.m_list:GetItemCount() - 1 do
		for j = 0, self.m_list:GetColumnCount() - 1 do
			local nIndex = i + 1;
			if nIndex > #self.m_tblRaceInfo then
				self.m_list:SetSubItemVisible( false, i, j );
			else
				self.m_list:SetSubItemVisible( true, i, j );
				local pRaceItem = self.m_list:GetSubItem( i, j );
				pRaceItem.m_tblRaceData = self.m_tblRaceInfo[nIndex];
				pRaceItem:RefreshRaceInfo( i );
			end
		end
	end
	self:ShowSwitchRaceWnd();
end

function CRaceWnd:RefreshTeamInfo()
	for i = 0, self.m_listTeam:GetItemCount() - 1 do
		for j = 0, self.m_listTeam:GetColumnCount() - 1 do
			local nIndex = i + 1;
			if nIndex > #self.m_tblTeamRaceInfo then
				self.m_listTeam:SetSubItemVisible( false, i, j );
			else
				self.m_listTeam:SetSubItemVisible( true, i, j );
				local pRaceItem = self.m_listTeam:GetSubItem( i, j );
				pRaceItem.m_tblRaceData = self.m_tblTeamRaceInfo[nIndex];
				pRaceItem:RefreshRaceInfo( i );
			end
		end
	end
	self:ShowSwitchRaceWnd();
end

function CRaceWnd:ShowSwitchRaceWnd()
	self.m_list:ShowWnd( self.m_pBtnLimit:GetCheck() );
	local bShowTeam = self.m_pBtnTeam:GetCheck();
	self.m_listTeam:ShowWnd( bShowTeam );
	self.m_pWndRaceTeamMember:ShowWnd( bShowTeam );
end

function CRaceWnd:OnRefreshRaceMemberInfo()	--显示赛事界面的队伍成员信息  
	self.m_pBtnTeam:SetCheck( true )
	self:ShowRaceMemberInfo();
end

function CRaceWnd:OnClickRaceType()
	local sTime = GetFormatTimeSTMFromMillisecond( GetLocalTime() );
	local nDayOfWeek = sTime:m_nDayofWeek();
	if nDayOfWeek == 0 then
		nDayOfWeek = 7;
	end
	local bShowLimit = g_tblTabFile.day_race_switch[nDayOfWeek].nLimitSwitch == 1;
	local bShowTeam = g_tblTabFile.day_race_switch[nDayOfWeek].nTeamSwitch == 1;

	if self.m_pBtnLimit:GetCheck() and not bShowLimit then
		self.m_pBtnTeam:SetCheck( true );
		g_App:HideMsg( g_App:GetString( "meiyouxianshisai" ) );
	elseif self.m_pBtnTeam:GetCheck() and not bShowTeam then
		self.m_pBtnLimit:SetCheck( true );
		g_App:HideMsg( g_App:GetString( "meiyoutuanzhansai" ) );
	end

	if self.m_pBtnLimit:GetCheck() and CPlayerRoomMemberInfoMgr:Instance():IsInTeam() then
		if CPlayerRoomMemberInfoMgr:Instance():GetCount() <= 1 then
			local NetMsg = CLeaveTeam:new();
			NetMsg.bCreateNewTeam = false;
			g_App:SendShellMsg( NetMsg );
		else			
			g_App:HideMsg( g_App:GetString( "jinzhichakanxianshi" ) );
			self.m_pBtnTeam:SetCheck( true );
			return;
		end
	end
	if self.m_pBtnTeam:GetCheck() and not CPlayerRoomMemberInfoMgr:Instance():IsInTeam() then
		local NetMsgMusic = CSetMusic:new();
        NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
		g_App:SendShellMsg( NetMsgMusic );
				
		local NetMsg = CCreateTeam:new();
		NetMsg.nType = eMRT_TeamRaceBefore;
		g_App:SendShellMsg( NetMsg );
	end
	self:OnRefreshInfo();
end

function CRaceWnd:ShowRaceMemberInfo()
	local nCount = CPlayerRoomMemberInfoMgr:Instance():GetCount();
	self.m_tblMemberAllData = CPlayerRoomMemberInfoMgr:Instance():GetMemberData();
	if not self.m_tblMemberAllData then		
		return;
	end
	self.m_pWndTeamTips:ShowWnd( false );
	self.m_pWndRaceTeamMember:GetDlgChild( "wanjia" ):ShowWnd( true );
	self.m_pWndRaceTeamMember:GetDlgChild( "btn_ok" ):ShowWnd( true );
	self.m_pWndRaceTeamMember:GetDlgChild( "btn_back" ):ShowWnd( nCount > 1 );
	self.m_pWndRaceTeamMember:GetDlgChild( "btn_jineng" ):ShowWnd( true );
	self.m_pWndTeamInvite:ShowWnd( true );
	for i = 1, ETEAM_PLAY_COUNT do
		local MemberWnd = self.m_tblTeamRaceMember[i];
		local MemberData = self.m_tblMemberAllData[i - 1];
		MemberWnd:GetDlgChild( "wanjia" ):ShowWnd( i <= nCount );
		MemberWnd:GetDlgChild( "jineng" ):ShowWnd( i <= nCount );
		MemberWnd:GetDlgChild( "name" ):ShowWnd( i <= nCount );
		MemberWnd:GetDlgChild( "zhunbei" ):ShowWnd( i <= nCount );
		MemberWnd:GetDlgChild( "duanwei" ):ShowWnd( i <= nCount );
		MemberWnd:EnableWnd( true );
		if i <= nCount then
			local bIsCaptain = MemberData.bCaptain;
			local bDirector = g_App:GetAccountID() == MemberData.nAccountID;
			CHeadIconConfig:Inst():SetIcon( MemberWnd:GetDlgChild( "wanjia.touxiang" ), MemberData.nCurHeadIcon + 1, MemberData.nAccountID );
			MemberWnd:GetDlgChild( "name" ):SetWndText( MemberData.szName );
			self.m_pMemberSkillID[i]:SetIconID( g_tblTabFile.skill[MemberData.nSkillID].nIconID );
			MemberWnd:GetDlgChild( "zhunbei" ):ShowWnd( not bIsCaptain and MemberData.bReady );
			MemberWnd:ShowWnd( true );
			MemberWnd:EnableWnd( not bDirector );
			local nLevel = CStarLevelConfig:Inst():GetBigLevel( MemberData.nCurLadderStar );
			for j = 1, 8 do
				MemberWnd:GetDlgChild( "duanwei.icon_duanwei."..j ):ShowWnd( j == nLevel );
			end
		end
	end	
	local bIsCaptain = CPlayerRoomMemberInfoMgr:Instance():IsCaptain();
	local TipEvent = {};
	TipEvent.m_Type = "ShowJoinTips";
	TipEvent.m_bShowTips = nCount == ETEAM_PLAY_COUNT and bIsCaptain;
	g_App.m_EventDispatcher:DispatchEvent( TipEvent );
	
	if bIsCaptain then
		self.m_pBtnOK:SetWndText( g_App:GetString( "zujianduiwu" ) );
	else
		local bReady = CPlayerRoomMemberInfoMgr:Instance():GetSelfReady();
		if bReady then
			self.m_pBtnOK:SetWndText( g_App:GetString( "quxiaozhunbei" ) );
		else
			self.m_pBtnOK:SetWndText( g_App:GetString( "zhunbei" ) );
		end
	end
end

function CRaceWnd:OnClickOK()
	local bIsCaptain = CPlayerRoomMemberInfoMgr:Instance():IsCaptain();
	if bIsCaptain then
		g_App:GetGameStart().m_pWndRaceTeam:ShowAndSetFocus();
		g_App:GetGameStart().m_pWndRaceTeam.m_pWndTeamRaceMember:ShowWnd( true );
	else
		local NetMsg = CChangeMatchReady:new();
		NetMsg.nTeamID = CPlayerRoomMemberInfoMgr:Instance():GetTeamID();
		g_App:SendShellMsg( NetMsg );
	end
end

function CRaceWnd:OnClickBack()
	local NetMsg = CLeaveTeam:new();
	NetMsg.bCreateNewTeam = false;
	g_App:SendShellMsg( NetMsg );

	local NetMsgMusic = CSetMusic:new();
    NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
	g_App:SendShellMsg( NetMsgMusic );
				
	local NetMsg = CCreateTeam:new();
	NetMsg.nType = eMRT_TeamRaceBefore;
	g_App:SendShellMsg( NetMsg );
end

function CRaceWnd:ShowTeamRace()
	self:ShowWnd( true );
	self.m_pBtnTeam:SetCheck( true );
	self:OnClickRaceType();
end

function CRaceWnd:ChangeReady( Event )
	local nMatchType = Event.m_nMatchType;
	if nMatchType == eMRT_TeamRaceBefore then
		self:OnRefreshRaceMemberInfo();
	end
end

function CRaceWnd:CannotJoinTeamRace( szStr )
	self.m_pWndTeamTips:SetWndText( szStr );
	self.m_pWndTeamTips:ShowWnd( true );
	self.m_pWndRaceTeamMember:GetDlgChild( "wanjia" ):ShowWnd( false );
	self.m_pWndRaceTeamMember:GetDlgChild( "btn_ok" ):ShowWnd( false );
	self.m_pWndRaceTeamMember:GetDlgChild( "btn_back" ):ShowWnd( false );
	self.m_pWndRaceTeamMember:GetDlgChild( "btn_jineng" ):ShowWnd( false );
	self.m_pWndTeamInvite:ShowWnd( false );
end

function CRaceWnd:OnClickRank()
	if CPlayerRoomMemberInfoMgr:Instance():GetCount() > 1 then
		g_App:HideMsg( g_App:GetString( "jinzhichakanxianshi" ) );
	else
		g_App:GetGameStart().m_pRankWnd:ShowAndSetFocus();
		g_App:GetGameStart().m_pRankWnd.m_BtnRaceScore:SetCheck( true );
	end
end

function CRaceWnd:UpdateIMDesc()
	local IMMgr = g_App:GetInstantMessageDataMgr();
	self.m_descWorld:SetWndText( IMMgr:GetWorldMessageContentLast() );
	
	local nCount = math.min( IMMgr:GetFriendUnReadCount(), 99 );
	self.m_descFriend:ShowWnd( nCount ~= 0 );
	self.m_descFriend:SetWndText( nCount );
end

function CRaceWnd:OnImShow( bShow )
	if bShow then
		self.m_btnIM:ShowWnd( false );
	else
		self.m_btnIM:ShowWnd( true );
	end
end

function CRaceWnd:OnWorldMsgCooldown( Event )
	if Event.m_szLeftTimeText then
		self.m_pWndTeamInvite:EnableWnd( false );		
		self.m_pWndTeamInvite:GetDlgChild( "bg" ):SetWndText( Event.m_szLeftTimeText );
	else
		self.m_pWndTeamInvite:EnableWnd( true );		
		self.m_pWndTeamInvite:GetDlgChild( "bg" ):SetWndText( CStringConfig.Inst():GetString( "yaoqingwanjia" ) );
	end
end

function CRaceWnd:OnCopyTeamCode()
	local nTeamType = eMRT_TeamRaceBefore;
	local szText = g_App:GetString( "tuanzhansaishiyaoqing" );
	local nRoomNum = CPlayerRoomMemberInfoMgr:Instance():GetTeamID();
	local szContent = string.format( szText, nRoomNum );
	local szHyplink = "joinroom "..nTeamType.." "..nRoomNum.." "..g_App:GetGameStart().m_nRaceID;
	local szMsg = "#u#c("..szHyplink..")"..szContent.."#c()";
	g_App:GetInstantMessageDataMgr():SendMsg( 0, szMsg );
end

function CRaceWnd:KickMember( nClickPos )
	if not CPlayerRoomMemberInfoMgr:Instance():IsCaptain()
		or nClickPos == CPlayerRoomMemberInfoMgr:Instance():GetSelfPos() then
		return;
	end
	g_App:MessageBox( g_App:GetString( "saishitiren" ),
	{
	[CMessageBox.Close] = function()
		g_App.m_pMessageBox:ShowWnd( false );
	end;
	[CMessageBox.OK] = function()	--踢人  
		g_App.m_pMessageBox:ShowWnd( false );
		local pConn = g_App:GetWorldConn();
		if not pConn then
			return;
		end
		local NetMsg = CMatchPosHandle:new();
		NetMsg.nTeamID = CPlayerRoomMemberInfoMgr:Instance():GetTeamID();
		NetMsg.nType = eMPH_Kick;
		NetMsg.nPos = nClickPos;
		pConn:SendShellMsg( NetMsg );
	end;
	} );
end

---------------------------------------CRaceInfoItem---------------------------------------
function CRaceInfoItem:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CRaceInfoItem:OnCreated()	
	self.m_pWndState = self:GetDlgChild( "zhuangtai" );
	self.m_pWndPlayerNum = self:GetDlgChild( "renshu" );
	self.m_pWndType = self:GetDlgChild( "leixing" );
	self.m_pWndStart = self:GetDlgChild( "kaishishijian" );
	self.m_pWndEndTime = self:GetDlgChild( "jieshushijian" );
	self.m_pWndRoomID = self:GetDlgChild( "changci" );
	self.m_pBtnObserve = self:GetDlgChild( "b_guanzhan" );
	self.m_pBtnJoin = self:GetDlgChild( "b_baoming" );
	self.m_pBtnCheck = self:GetDlgChild( "b_chakan" );
	self.m_pWndTag = self:GetDlgChild( "tag1" );
	self.m_pCostIcon = CRichIconWnd:new( self, "b_baoming.icon" );
	self.m_pWndJoinTips = self:GetDlgChild( "b_baoming.tips" );
	self.m_pWndJoinTips:ShowWnd( false );

	self.m_pBtnObserve:AddActionListener( "OnClickObServe", self );
	self.m_pBtnJoin:AddActionListener( "OnClickJoin", self );
	self.m_pBtnCheck:AddActionListener( "OnClickCheck", self );
	g_App.m_EventDispatcher:AddEventListener( "ShowJoinTips", "OnRefreshTip", self );
end

function CRankItemWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "ShowJoinTips", "OnRefreshTip", self );
	CGWnd.OnDestroy( self );
end

function CRankItemWnd:OnWndShow( bShow )
	if not bShow then
		
	end
end

function CRaceInfoItem:OnClickJoin()
	if self.m_nRaceType == eMRT_TeamRace then
		local NetMsgMusic = CSetMusic:new();
		NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
		g_App:SendShellMsg( NetMsgMusic );
		local NetMsg = CJoinRace:new();
		NetMsg.nRaceRoomID = self.m_tblRaceData.m_nRaceRoomID;
		g_App:SendShellMsg( NetMsg );
		return;
	end
	--g_App:GetGameStart().m_pWndRace.m_pWndConfirmJoin:SetJoinData( self.m_tblRaceData );
	--g_App:GetGameStart().m_pWndRace.m_pWndConfirmJoin:ShowAndSetFocus();
	g_App:GetGameStart().m_pWndConfirmJoin:SetJoinData( self.m_tblRaceData );
	g_App:GetGameStart().m_pWndConfirmJoin:ShowAndSetFocus();
end

function CRaceInfoItem:OnClickObServe()
	local NetMsg = CObserveGame:new();
    NetMsg.m_nAccountID = 0;
	NetMsg.m_nRaceRoomID = self.m_tblRaceData.m_nRaceRoomID;
	g_App:SendShellMsg( NetMsg );
end

function CRaceInfoItem:OnClickCheck()
	g_App:HideMsg( g_App:GetString( "paihangbangtishi" ) );
end

function CRaceInfoItem:RefreshRaceInfo( nIndex )
	self.m_nRoomType = tonumber( string.sub( self.m_tblRaceData.m_nRaceRoomID, 7, 7 ) );
	self.m_nRaceType = eMRT_LimitRace;
	local strState = g_App:GetString( "zuduizhong" );
	local strType = g_App:GetString( "xianshisai" );
	local nWholeNum = 10;
	if self.m_nRoomType == 2 then	--团战赛事模式
		strType = g_App:GetString( "tuanzhansaishi" );
		nWholeNum = 3;
		self.m_nRaceType = eMRT_TeamRace;
		self.m_nIndex = nIndex;
	end
	local pStartSTime = GetFormatTimeSTMFromMillisecond( self.m_tblRaceData.m_nCreateTime );
	local pEndSTime = GetFormatTimeSTMFromMillisecond( self.m_tblRaceData.m_nDestroyTime );
	local strStartTime = string.format( "%02d:%02d", pStartSTime:m_nHour(), pStartSTime:m_nMinutes() );
	local strEndTime = string.format( "%02d:%02d", pEndSTime:m_nHour(), pEndSTime:m_nMinutes() );
	if self.m_tblRaceData.m_nRoomState == eRaceRoomState_Gaming then
		strState = g_App:GetString( "youxizhong" );
	elseif self.m_tblRaceData.m_nRoomState == eRaceRoomState_End then
		strState = g_App:GetString( "yijieshu" );
	elseif self.m_tblRaceData.m_nRoomState == eRaceRoomState_Close then
		strState = g_App:GetString( "yiguanbi" );
	end
	self.m_pWndState:SetWndText( strState );
	self.m_pWndType:SetWndText( strType );
	self.m_pWndPlayerNum:SetWndText( tostring( self.m_tblRaceData.m_nRoomMemberCount ).."/"..nWholeNum );
	self.m_pWndStart:SetWndText( strStartTime );
	self.m_pWndEndTime:SetWndText( strEndTime );
	self.m_pWndRoomID:SetWndText( self.m_tblRaceData.m_nRaceRoomID );
	self.m_pBtnJoin:ShowWnd( self.m_tblRaceData.m_nRoomState <= eRaceRoomState_Numbering );
	self.m_pBtnObserve:ShowWnd( self.m_tblRaceData.m_nRoomState == eRaceRoomState_Gaming );
	self.m_pWndTag:ShowWnd( self.m_tblRaceData.m_nRoomState <= eRaceRoomState_Numbering );
	self.m_pBtnCheck:ShowWnd( self.m_tblRaceData.m_nRoomState == eRaceRoomState_End );
	
	local RaceConfig = g_tblTabFile.day_race_activity[self.m_tblRaceData.m_nRaceID];
	local nCostType = RaceConfig.nEnterCostType;
	local nCostValue = RaceConfig.nEnterCostValue;		
	nCostType, nCostValue = g_App:GetRaceCost( self.m_tblRaceData.m_nRaceID, self.m_nRaceType );
	self.m_pCostIcon:SetIconID( g_tblTabFile.currency[nCostType].nIconID );
	self.m_pBtnJoin:GetDlgChild( "jiage" ):SetWndText( nCostValue );
end

function CRaceInfoItem:OnRefreshTip( Event )
	if self.m_nRoomType == 2 and self.m_nIndex == 0 and Event.m_bShowTips
		and self.m_tblRaceData.m_nRoomState < eRaceRoomState_Numbering then
		self.m_pWndJoinTips:ShowAndSetFocus();
	else
		self.m_pWndJoinTips:ShowWnd( false );
	end
end
------------------------------------CConfirmJoinWnd------------------------------------
function CConfirmJoinWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CConfirmJoinWnd:OnCreated()	
	self.m_pBtnConfirm = self:GetDlgChild( "btn_ok" );
	self.m_pBtnCancel = self:GetDlgChild( "close" );
	self.m_pWndTitle = self:GetDlgChild( "title" );
	self.m_pWndContent = self:GetDlgChild( "W_shuoming" );
	self.m_pCostIcon = CRichIconWnd:new( self, "btn_ok.icon" );
	self.m_pBtnConfirm:AddActionListener( "OnClickJoin", self );
	self.m_pBtnCancel:AddActionListener( "OnClickCancel", self );
end

function CConfirmJoinWnd:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CConfirmJoinWnd:OnWndShow( bShow )
	if bShow then
		local RaceConfig = g_tblTabFile.day_race_activity[self.m_tblRaceData.m_nRaceID];
		local nCostType = RaceConfig.nEnterCostType;
		local nCostValue = RaceConfig.nEnterCostValue;		
		nCostType, nCostValue = g_App:GetRaceCost( self.m_tblRaceData.m_nRaceID, self.m_tblRaceData.m_nRoomType );
		self.m_pCostIcon:SetIconID( g_tblTabFile.currency[nCostType].nIconID );
		self.m_pBtnConfirm:GetDlgChild( "jiage" ):SetWndText( nCostValue );
		if self.m_tblRaceData.m_nRoomType == eMRT_LimitRace then
			self.m_pWndTitle:SetWndText( g_App:GetString( "goumaiqueren" ) );
			self.m_pWndContent:SetWndText( g_App:GetString( "querenbaoming" ) );
		elseif self.m_tblRaceData.m_nRoomType == eMRT_TeamRace
			or self.m_tblRaceData.m_nRoomType == eMRT_TeamRaceBefore then
			self.m_pWndTitle:SetWndText( g_App:GetString( "querenbaoming" ) );
			self.m_pWndContent:SetWndText( g_App:GetString( "tuanzhansaishiqueren" ) );
		end
	end
end

function CConfirmJoinWnd:OnClickJoin()
	if self.m_tblRaceData.m_nRoomType == eMRT_LimitRace then
		local NetMsgMusic = CSetMusic:new();
		NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
		g_App:SendShellMsg( NetMsgMusic );
		local NetMsg = CJoinRace:new();
		--NetMsg.nRaceType = self.m_tblRaceData.m_nRoomType;
		NetMsg.nRaceRoomID = self.m_tblRaceData.m_nRaceRoomID;
		g_App:SendShellMsg( NetMsg );
	elseif self.m_tblRaceData.m_nRoomType == eMRT_TeamRace
		or self.m_tblRaceData.m_nRoomType == eMRT_TeamRaceBefore then
		local NetMsg = CJoinTeam:new();
		NetMsg.nTeamID = self.m_tblRaceData.m_nTeamID;
		NetMsg.nTeamType = self.m_tblRaceData.m_nRoomType;
		g_App:SendShellMsg( NetMsg );
	end
	self:ShowWnd( false );
end

function CConfirmJoinWnd:OnClickCancel()
	self:ShowWnd( false );
end

function CConfirmJoinWnd:SetJoinData( tblRaceData )
	self.m_tblRaceData = tblRaceData;
end

-------------------------------------CConfirmInviteWnd----------------------------------
function CConfirmInviteWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CConfirmInviteWnd:OnCreated()	
	self.m_pBtnConfirm = self:GetDlgChild( "btn_ok" );
	self.m_pBtnCancel = self:GetDlgChild( "close" );
	self.m_pWndTitle = self:GetDlgChild( "title" );
	self.m_pWndContent = self:GetDlgChild( "W_shuoming" );
	self.m_pCostIcon = CRichIconWnd:new( self, "btn_ok.icon" );
	self.m_pBtnConfirm:AddActionListener( "OnClickJoin", self );
	self.m_pBtnCancel:AddActionListener( "OnClickCancel", self );
end

function CConfirmInviteWnd:OnDestroy()	
	CGWnd.OnDestroy( self );
end

function CConfirmInviteWnd:OnWndShow( bShow )
	if bShow then
		self:ShowInviteInfo();
	end
end

function CConfirmInviteWnd:InitData( InviteInfo )
	self.m_nAccountID = InviteInfo.nAccountID;
	self.m_nTeamID = InviteInfo.nTeamID;
	self.m_szAccountName = InviteInfo.szAccountName;
	self.m_nTeamType = InviteInfo.nTeamType;
	self.m_nRaceID = InviteInfo.nRaceID;
	self:ShowWnd( true );
end

function CConfirmInviteWnd:ShowInviteInfo()
	local RaceConfig = g_tblTabFile.day_race_activity[self.m_nRaceID];
	local nCostType = RaceConfig.nEnterCostType;
	local nCostValue = RaceConfig.nEnterCostValue;		
	nCostType, nCostValue = g_App:GetRaceCost( self.m_nRaceID, self.m_nTeamType );
	self.m_pCostIcon:SetIconID( g_tblTabFile.currency[nCostType].nIconID );
	self.m_pBtnConfirm:GetDlgChild( "jiage" ):SetWndText( nCostValue );
	self.m_pWndTitle:SetWndText( g_App:GetString( "saishiyaoqing" ) );
	local InviteStr = g_App:GetString( "saishixianshiyaoqing" );
	if self.m_nTeamType == eMRT_TeamRace or self.m_nTeamType == eMRT_TeamRaceBefore then
		InviteStr = g_App:GetString( "saishituanzhanyaoqig" );
	end
	self.m_pWndContent:SetWndText( string.format( InviteStr, self.m_szAccountName ) );
end

function CConfirmInviteWnd:OnClickJoin()
    local NetMsgMusic = CSetMusic:new();
    NetMsgMusic.nMusicID = g_App:GetSelectMusicID();
	g_App:SendShellMsg( NetMsgMusic );
	if self.m_nTeamType == eMRT_LimitRace then
		local NetMsg = CJoinRace:new();
		NetMsg.nRaceRoomID = self.m_nTeamID;
		g_App:SendShellMsg( NetMsg );
		self:ShowWnd( false );
	elseif self.m_nTeamType == eMRT_TeamRaceBefore then
		local NetMsg = CJoinTeam:new();
		NetMsg.nTeamID = self.m_nTeamID;
		NetMsg.nTeamType = self.m_nTeamType;
		g_App:SendShellMsg( NetMsg );
		self:ShowWnd( false );
	end
end

function CConfirmInviteWnd:OnClickCancel()
	local NetMsg = CRefuseInvite:new();
    NetMsg.nAccountID = self.m_nAccountID;
	g_App:SendShellMsg( NetMsg );
    self:ShowWnd( false );
end
--endregion
