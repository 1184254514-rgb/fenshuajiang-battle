--region CWndClan.lua
--Date	2018.03.12
--家族页面  

function CWndClan:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndClan:OnCreated()
	self.m_tblWifiIcon		=	{	self:GetDlgChild("wifi.icon_3"), 
									self:GetDlgChild("wifi.icon_2"),
									self:GetDlgChild("wifi.icon_1") };
	self.m_BtnClose			=	self:GetDlgChild( "B_close" );
	self.m_BtnPropelClan	=	self:GetDlgChild( "bg.btn_zuo.btn_1" );
	self.m_BtnClanRank		=	self:GetDlgChild( "bg.btn_zuo.btn_2" );
	self.m_BtnMyClan		=	self:GetDlgChild( "bg.btn_zuo.btn_3" );

	self.m_WndJoinClan		=	self:GetDlgChild( "bg.jiarujiazu" );
	self.m_BtnSearchClan	=	self:GetDlgChild( "bg.jiarujiazu.sousuo.b_sousuo" );
	self.m_WndSearchTips	=	self:GetDlgChild( "bg.jiarujiazu.sousuo.bg_tishi" );
	self.m_BtnClearInput	=	self:GetDlgChild( "bg.jiarujiazu.sousuo.close" );
	self.m_EditClanName		=	self:GetDlgChild( "bg.jiarujiazu.sousuo.w_yonghu" );
	self.m_ListClan			=	self:GetDlgChild( "bg.jiarujiazu.list" );
	self.m_BtnCreateClan	=	self:GetDlgChild( "bg.jiarujiazu.chuangjian" );
	self.m_BtnCustomSearch	=	self:GetDlgChild(  "bg.jiarujiazu.shaixuan" );

	self.m_WndMyClan		=	self:GetDlgChild( "bg.wodejiazu" );
	self.m_BtnApply			=	self:GetDlgChild( "bg.wodejiazu.shenqing" );
	self.m_BtnSet			=	self:GetDlgChild( "bg.wodejiazu.shezhi" );
	self.m_BtnExit			=	self:GetDlgChild( "bg.wodejiazu.tuichu" );
	self.m_WndMyDayActivity =	self:GetDlgChild( "bg.wodejiazu.huoyuedu" );
	self.m_WndMyDayPro		=	self:GetDlgChild( "bg.wodejiazu.huoyuedu.jindutiao" );
	self.m_WndMyDayProText	=	self:GetDlgChild( "bg.wodejiazu.huoyuedu.jindutiao.shuzi" );
	self.m_WndMyDayProFx	=	self:GetDlgChild( "bg.wodejiazu.huoyuedu.tx" );
	self.m_WndClanRank		=	self:GetDlgChild( "bg.wodejiazu.paiming.shuzi" );
	self.m_ClanIcon			=	CRichIconWnd:new ( self.m_WndMyClan, "icon" );
	self.m_WndClanName		=	self:GetDlgChild( "bg.wodejiazu.name" );
	self.m_ClanLevelPro		=	self:GetDlgChild( "bg.wodejiazu.dengjijindutiao" );
	self.m_ClanLevelValue	=	self:GetDlgChild( "bg.wodejiazu.dengjijindutiao.shuzi" );
	self.m_ClanLevel		=	self:GetDlgChild( "bg.wodejiazu.dengji.shuzi" );
	self.m_ClanMemberCount	=	self:GetDlgChild( "bg.wodejiazu.chengyuan.shuzi" );
	self.m_ClanSlogan		=	self:GetDlgChild( "bg.wodejiazu.xuanyan.neirong" );
	self.m_ListMember		=	self:GetDlgChild( "bg.wodejiazu.list" );


	self.m_WndJoinClan:ShowWnd( false );
	self.m_WndMyClan:ShowWnd( false );
	self.m_BtnPropelClan:ShowWnd( false );
	self.m_BtnMyClan:ShowWnd( false );
	self.m_ListClan:SetInertiaType( eInertiaType_VScroll );
	self.m_ListMember:SetInertiaType( eInertiaType_VScroll );

	self.m_WndClanApplyList = CWndClanApplyList:new( "gui/cfg/fsj_jiazu_shenqing.gui", self, 1 );
	self.m_WndSetClanInfo = CWndSetClanInfo:new( "gui/cfg/fsj_jiazu_shezhi.gui", self, 1 );
	self.m_WndClanCustomSearch = CWndClanCustomSearch:new( "gui/cfg/fsj_jiazu_shaixuan.gui", self, 1 );

	self.m_BtnClose:AddActionListener( "OnClickClose", self );
	self.m_BtnPropelClan:AddActionListener( "OnClickPropelClan", self );
	self.m_BtnClanRank:AddActionListener( "OnClickClanRank", self );
	self.m_BtnSearchClan:AddActionListener( "OnClickSearchClan", self );
	self.m_BtnClearInput:AddActionListener( "OnClickClearInput", self );
	self.m_BtnCreateClan:AddActionListener( "OnClickCreateClan", self );
	self.m_BtnApply:AddActionListener( "OnShowApplyList", self );
	self.m_BtnSet:AddActionListener( "OnSetClanData", self );
	self.m_BtnExit:AddActionListener( "OnExitClan", self );
	self.m_BtnMyClan:AddActionListener( "OnClickMyClan", self );
	self.m_BtnCustomSearch:AddActionListener( "OnClickCustomSearch", self );

	self.m_EditClanName:AddEventListener( GM_WM_STATE_CHANGED, "OnTextChanged", self );
    self.m_EditClanName:AddEventListener( WM_SETFOCUS, "OnTextChanged", self );
    self.m_EditClanName:AddEventListener( WM_KILLFOCUS, "OnTextChanged", self );

	self.m_tickWifi			=	CTick:new( "OnTickRefreshWifi", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshClanAndMemberInfo", "RefreshClanAndMemberInfoWnd", self );
	g_App.m_EventDispatcher:AddEventListener( "AnswerFuzzySearchClan", "RefreshList", self );
	g_App.m_EventDispatcher:AddEventListener( "AnswerQueryPropellClan", "RefreshList", self );
	g_App.m_EventDispatcher:AddEventListener( "JoinClanSuccess", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "ExitClanSuccess", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "SetClanInfoSuccess", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "AnswerKickFromClan", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "AnswerClanOperate", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "AnswerCreateClan", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "SetClanMemberPowerSuccess", "Init", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshClanRedPoint", "RefreshRedPoint", self );
end

function CWndClan:OnDestroy(args)
	CGWnd.OnDestroy( self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshClanAndMemberInfo", "RefreshClanAndMemberInfoWnd", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerFuzzySearchClan", "RefreshList", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerQueryPropellClan", "RefreshList", self );
	g_App.m_EventDispatcher:RemoveEventListener( "JoinClanSuccess", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "ExitClanSuccess", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "SetClanInfoSuccess", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerKickFromClan", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerClanOperate", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerCreateClan", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "SetClanMemberPowerSuccess", "Init", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshClanRedPoint", "RefreshRedPoint", self );
end

function CWndClan:OnWndShow( bShow )
	if bShow then
		self:Init();	
	else
		self.m_tickWifi:Stop();
	end
end

function CWndClan:OnTickRefreshWifi()
	if not g_App or not g_App:GetWorldConn() then
		return;
	end
	local nPingDelay = g_App:GetWorldConn():GetPingDelay();
	if not nPingDelay then return end
	local nIconShowed = nPingDelay < ePing_low and 3 or ( nPingDelay > ePing_high and 1 or 2 );
	for k, v in pairs( self.m_tblWifiIcon ) do
		self.m_tblWifiIcon[k]:ShowWnd( k == nIconShowed );
		self.m_tblWifiIcon[k]:GetDlgChild( "wangsu" ):SetWndText( wifi );
	end
end

function CWndClan:OnClickClose( Event )
	self:ShowWnd( false );
end

function CWndClan:OnClickPropelClan()
	if self.m_BtnPropelClan:GetCheck() then
		return;
	end
end

function CWndClan:OnClickClanRank()
	
end

function CWndClan:OnClickSearchClan()
	g_App:WaitMsg( true, 1500 );
	local szClanName = self.m_EditClanName:GetWndText();
	if string.len( szClanName ) > CLANNAME_BYTE_SIZE then
		return g_App:HideMsg( g_App:GetString( "mingzitaichang" ) );
	elseif not CUSFilter:Inst():CheckString( szClanName, CLANNAME_BYTE_SIZE + 1, eFilter_Chat ) then
		return g_App:HideMsg( g_App:GetString( "hanyoufeifazi" ) );
	end

	local NetMsg = CFuzzySearchClan:new();
	NetMsg.m_szClanName = szClanName;
	g_App:SendShellMsg( NetMsg );
end

function CWndClan:OnClickClearInput()
    self.m_EditClanName:SetWndText( "" );
    self.m_WndSearchTips:ShowWnd( true );
end

function CWndClan:OnClickCreateClan()
	g_App:GetGameStart().m_WndCreateClan:ShowAndSetFocus();
end

function CWndClan:Init()
	self.m_tickWifi:Start( 33 );
	self.m_tblClanInfo = nil;
	self.m_tblClanMemberInfo = nil;
	self.m_BtnPropelClan:SetCheck( true );
	local NetMsg = CAccurateSearchClan:new();
	g_App:SendShellMsg( NetMsg );
end

function CWndClan:OnTextChanged()
    self.m_WndSearchTips:ShowWnd( self.m_EditClanName:GetWndText() == "" and not self.m_EditClanName:IsFocus() );
    self.m_BtnClearInput:ShowWnd( self.m_EditClanName ~= "" );
end

function CWndClan:RefreshClanAndMemberInfoWnd( Event )
    self.m_tblClanInfo = Event.m_tblClanInfo;
    self.m_tblClanMemberInfo = Event.m_tblClanMemberInfo;
	self.m_tblMyClanInfo = Event.m_tblMyClanInfo;
    if self.m_tblClanInfo["nClanID"] then
		self:ShowMyClan();
	else
		local NetMsg = CQueryPropellClan:new();
		g_App:SendShellMsg( NetMsg );			
	end
end

function CWndClan:RefreshList( Event )
	g_App:WaitMsg( false );
	self.m_tblClanInfo = Event.m_tblClanInfo;
	self:ShowJoinClanWnd();
end

function CWndClan:OnListItemLoaded()
	self.m_ListClan:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	for i = 1, #self.m_tblClanInfo do 
		local subItem = self.m_ListClan:GetSubItem( i - 1, 0 );
		subItem:SetData( self.m_tblClanInfo[i] );
	end
end

function CWndClan:ShowMyClan()
	self.m_BtnMyClan:ShowWnd( true );
	self.m_BtnMyClan:SetCheck( true );
	self.m_BtnPropelClan:ShowWnd( false );
	self.m_WndJoinClan:ShowWnd( false );
	self.m_WndClanName:SetWndText( self.m_tblClanInfo.szClanName );
	self.m_ClanIcon:SetIconID( self.m_tblClanInfo.nIconID );
	self.m_ClanSlogan:SetWndText( self.m_tblClanInfo.szClanSlogan );
	self.m_ClanMemberCount:SetWndText( self.m_tblClanInfo.nMemberCount .. "/" .. CSnakeConstant:Inst():GetClanMemberCountMax() );
	local nLevel = CClanLevelConfig:Inst():GetLevel( self.m_tblClanInfo.nAllActivity );
	local nActivityMin = g_tblTabFile.clanlevel[nLevel].nActivityMin;
	local nActivityMax = g_tblTabFile.clanlevel[nLevel].nActivityMax;
	local nRange = nActivityMax - nActivityMin;
	local nCur = self.m_tblClanInfo.nAllActivity - nActivityMin; 
	self.m_ClanLevelPro:SetRange( nRange );
	self.m_ClanLevelPro:SetPos( nCur );
	self.m_ClanLevelValue:SetWndText( nCur .. "/" .. nRange );
	self.m_ClanLevel:SetWndText( nLevel );
	self:InitClanMemberList();
	self.m_WndMyClan:ShowWnd( true );
	self.m_nPower = self:GetAccountAccess( g_App:GetAccountID() );
	self.m_BtnSet:ShowWnd( self.m_nPower == eClan_Leader );
	self.m_BtnApply:ShowWnd( self.m_nPower ~= eClan_Member );
	local nDayActivityMax = CSnakeConstant:Inst():GetClanActivityDayLimit();
	local nDayActivityCur = self.m_tblMyClanInfo.nDayActivity;
	nDayActivityCur = nDayActivityCur >= nDayActivityMax and nDayActivityMax or nDayActivityCur;
	self.m_WndMyDayPro:SetRange( nDayActivityMax );
	self.m_WndMyDayPro:SetPos( nDayActivityCur );
	self.m_WndMyDayProText:SetWndText( nDayActivityCur .. "/" .. nDayActivityMax );
	self.m_WndMyDayProFx:ShowWnd( nDayActivityCur == nDayActivityMax );	
end

function CWndClan:InitClanMemberList()
	self.m_ListMember:DeleteAllItem();
	for i = 1, #self.m_tblClanMemberInfo do 
		self.m_ListMember:InsertRowItemsFromRes( -1, "gui/cfg/fsj_jiazu_chengyuanitem.gui", CClanMemberItem );	
	end
	self.m_ListMember:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnMemberListItemLoaded", self );
end

function CWndClan:OnMemberListItemLoaded()
	self.m_ListMember:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnMemberListItemLoaded", self );
	for i = 1, #self.m_tblClanMemberInfo do 
		local subItem = self.m_ListMember:GetSubItem( i - 1, 0 );
		subItem:SetData( self.m_tblClanMemberInfo[i] );
	end		
end

function CWndClan:ShowJoinClanWnd()
	self.m_BtnPropelClan:ShowWnd( true );
	self.m_BtnPropelClan:SetCheck( true );
	self.m_BtnMyClan:ShowWnd( false );
	self.m_WndMyClan:ShowWnd( false );
	self.m_ListClan:DeleteAllItem();
	for i = 1, #self.m_tblClanInfo do
		self.m_ListClan:InsertRowItemsFromRes( -1, "gui/cfg/fsj_jiazu_jiazuitem.gui", CWndClanItem );
	end
	self.m_ListClan:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	self.m_WndJoinClan:ShowWnd( true );	
end

function CWndClan:OnSetClanData()
	if self.m_nPower ~= eClan_Leader then
		g_App:HideMsg( g_App:GetString( "meiyouquanxian" ) );
		return;
	end
	self.m_WndSetClanInfo:InitAndShowWnd( self.m_tblClanInfo );	
end

function CWndClan:OnExitClan()
	g_App:MessageBox( g_App:GetString( "querentuichujiazu" ), {
		[CMessageBox.Close] = function()
			g_App.m_pMessageBox:ShowWnd( false );
		end;
		[CMessageBox.OK] = function()
			g_App.m_pMessageBox:ShowWnd( false );
			local NetMsg = CExitClan:new();
			g_App:SendShellMsg( NetMsg );
		end;
	});
end

function CWndClan:GetAccountAccess( nAccountID )
	for i = 1, #self.m_tblClanMemberInfo do
		local info = self.m_tblClanMemberInfo[i];
		if info.nAccountID == nAccountID then
			return info.nPower;
		end
	end
	return eClan_Member;
end

function CWndClan:RefreshRedPoint( Event )
	self:ShowRedPoint( Event.m_bShow );
end

function CWndClan:ShowRedPoint( bShow )
	self.m_BtnMyClan:ShowRedPoint( bShow );
	self.m_BtnApply:ShowRedPoint( bShow );
end

function CWndClan:OnClickMyClan()
	self:ShowRedPoint( false );
end

function CWndClan:OnShowApplyList()
	self:ShowRedPoint( false );
	if self.m_nPower == eClan_Member then
		g_App:HideMsg( g_App:GetString( "meiyouquanxian" ) );
		return;
	end
	local NetMsg = CQueryApplyList:new();
	g_App:SendShellMsg( NetMsg );
end

function CWndClan:OnClickCustomSearch()
	self.m_WndClanCustomSearch:ShowAndSetFocus();
end

--endregion
