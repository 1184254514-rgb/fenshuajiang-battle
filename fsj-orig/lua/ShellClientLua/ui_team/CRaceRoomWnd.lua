--region CRaceRoomWnd.lua
--Date	2018/1/17
--此文件由[BabeLua]插件自动生成

local ePing_low = 100;
local ePing_high = 200;

local tblLadder = {
	[eLL_Bronze + 1] = 1;
	[eLL_Siler + 1] = 2;
	[eLL_Gold2 + 1] = 3;
	[eLL_Gold1 + 1] = 3;
	[eLL_Platinum2 + 1] = 4;
	[eLL_Platinum1 + 1] = 4;
	[eLL_Diamond3 + 1] = 5;
	[eLL_Diamond2 + 1] = 5;
	[eLL_Diamond1 + 1] = 5;
	[eLL_Master3 + 1] = 6;
	[eLL_Master2 + 1] = 6;
	[eLL_Master1 + 1] = 6;
	[eLL_King3 + 1] = 7;
	[eLL_King2 + 1] = 7;
	[eLL_King1 + 1] = 7;
	[eLL_Legend + 1] = 8;
}

function CRaceRoomWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CRaceRoomWnd:OnCreated()	
	self.m_pWndBgTitle = self:GetDlgChild( "bg" );
	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_list = self:GetDlgChild( "list" );
	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new ( "OnRefreshTimeTick", self );
	self.m_pWndLimitRace = CLimitRaceWnd:new( "gui/cfg/fsj_saishi_xianshi.gui", self.m_list, 1 );
	self.m_pWndTeamRaceMember = CTeamRaceMemberWnd:new( "gui/cfg/fsj_saishi_tuanzhan_zudui.gui", self.m_list, 1 );
	self.m_pWndTeamRace = CTeamRaceWnd:new( "gui/cfg/fsj_saishi_tuanzhan_fangjian.gui", self.m_list, 1 );
	self.m_pBtnClose:AddActionListener( "OnClickClose", self );
	
	self.m_btnIM = self:GetDlgChild("liaotian");
	self.m_descWorld = self.m_btnIM:GetDlgChild("neirong");
	self.m_descFriend = self.m_btnIM:GetDlgChild("hongdian");
	self.m_btnIM:AddEventListener( GM_WM_MOUSECLICK, "OnClickIM", g_App.m_GameStart );
	self.m_descWorld:SetInertiaType( eInertiaType_HScroll );	
	self:UpdateIMDesc();		
	g_App.m_EventDispatcher:AddEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
	
	g_App:GetGameStart():AddEventListener( "OnRaceMemberInfoData", "OnRefreshRaceMemberInfo", self );
end

function CRaceRoomWnd:OnDestroy()
	self.m_timeTick:Stop();
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
	g_App:GetGameStart():RemoveEventListener( "OnRaceMemberInfoData", "OnRefreshRaceMemberInfo", self );
	CGWnd.OnDestroy( self );
end

function CRaceRoomWnd:OnRefreshTimeTick()	
	if not g_App or not g_App:GetWorldConn() then
		return;
	end
	local wifi = g_App:GetWorldConn():GetPingDelay();
	local nIconShowed = wifi < ePing_low and 3 or ( wifi > ePing_high and 1 or 2 );
	for k, v in pairs( self.m_wifiIcon ) do
		self.m_wifiIcon[k]:ShowWnd( k == nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild( "wangsu" ):SetWndText( wifi );
	end
end

function CRaceRoomWnd:OnWndShow( bShow )
	if bShow then
		self.m_timeTick:Start(1000);
		local nRoomType = CPlayerRoomMemberInfoMgr:Instance():GetRoomType();
		if nRoomType == eMRT_LimitRace then
			self.m_pWndBgTitle:SetWndText( g_App:GetString( "saishifangji" ) );
		else
			self.m_pWndBgTitle:SetWndText( g_App:GetString( "zujianduiwu" ) );
		end
		self.m_pBtnClose:ShowWnd( nRoomType ~= eMRT_TeamRace );
	else
		--print( "6666666666666CRaceRoomWnd:OnWndShow" );
		self.m_timeTick:Stop();
	end
end

function CRaceRoomWnd:OnClickClose()
	local nRoomType = CPlayerRoomMemberInfoMgr:Instance():GetRoomType();
	if nRoomType == eMRT_LimitRace then
		local pConn = g_App:GetWorldConn();
		if not pConn then
			return;
		end
		local NetMsg = CLeaveTeam:new();
		NetMsg.bCreateNewTeam = false;
		g_App:SendShellMsg( NetMsg );
		self:ShowWnd( false );	
	elseif nRoomType == eMRT_TeamRaceBefore then
		self:ShowWnd( false );
	end
end

function CRaceRoomWnd:OnSyncTeamInfo( pTeam )
	if pTeam.nType == eMRT_LimitRace then
		self:ShowWnd( true );
		self.m_pWndTeamRaceMember:ShowWnd( false );
		self.m_pWndTeamRace:ShowWnd( false );
		g_App:GetGameStart().m_pWndRace:ShowWnd( false );
		self.m_pWndLimitRace:RefreshTeam( pTeam );
	elseif pTeam.nType == eMRT_TeamRace then
		self:ShowWnd( true );
		self.m_pWndTeamRaceMember:ShowWnd( false );
		self.m_pWndLimitRace:ShowWnd( false );
		g_App:GetGameStart().m_pWndRace:ShowWnd( false );
		self.m_pWndTeamRace:RefreshTeam();
	elseif pTeam.nType == eMRT_TeamRaceBefore then
		self.m_pWndTeamRace:ShowWnd( false );
		self.m_pWndLimitRace:ShowWnd( false );
		local Event = {};
		Event.m_Type = "OnRaceMemberInfoData";
		Event.m_tblMemberInfo = pTeam;
		g_App:GetGameStart():DispatchEvent( Event );
	end
end

function CRaceRoomWnd:OnRefreshRaceMemberInfo()
	if CPlayerRoomMemberInfoMgr:Instance():GetRoomType() == eMRT_TeamRaceBefore then
		local pMemberInfo = CPlayerRoomMemberInfoMgr:Instance():GetAllData();
		self.m_pWndTeamRaceMember:RefreshTeam( pMemberInfo );	
		--if not CPlayerRoomMemberInfoMgr:Instance():IsCaptain() then
			--g_App:GetGameStart().m_pWndRace:ShowTeamRace();
			g_App:GetGameStart().m_pWndRace:ShowWnd( true );
		--end
	end
end

function CRaceRoomWnd:UpdateIMDesc()
	local IMMgr = g_App:GetInstantMessageDataMgr();
	self.m_descWorld:SetWndText( IMMgr:GetWorldMessageContentLast() );
	
	local nCount = math.min( IMMgr:GetFriendUnReadCount(), 99 );
	self.m_descFriend:ShowWnd( nCount ~= 0 );
	self.m_descFriend:SetWndText( nCount );
end

function CRaceRoomWnd:OnImShow( bShow )
	if bShow then
		self.m_btnIM:ShowWnd( false );
	else
		self.m_btnIM:ShowWnd( true );
	end
end

-------------------------------------CLimitRaceWnd-------------------------------------
function CLimitRaceWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CLimitRaceWnd:OnCreated()	
	self.m_pBtnChooseSkill = self:GetDlgChild( "btn_xuanzejineng" );
	self.m_pBtnRefreshFriends = self:GetDlgChild( "b_shuaxin" );
	self.m_pBtnReady = self:GetDlgChild( "btn_zhunbei" );
    self.m_pBtnShowFriend1 = self:GetDlgChild( "youbian_btn.btn1" );
    self.m_pBtnShowFriend2 = self:GetDlgChild( "youbian_btn.btb2" );
    self.m_pBtnShowFriend1:SetCheck( true );
    self.m_nPage = 1;
    self.m_pPage = self:GetDlgChild( "next.yeshu" );
    self.m_pBtnPrev = self:GetDlgChild( "next.b_zuo" );
    self.m_pBtnNext = self:GetDlgChild( "next.b_you" );
    self.m_pNoFriends = self:GetDlgChild( "kong" );
		
    self.m_nFriendItems = {};
    self.m_nFriendIDs = {};
    self.m_pFriendHeads = {};
    self.m_pFriendNames = {};
    self.m_pFriendBtns = {};
    self.m_pFriendBtns1 = {};
    self.m_pFriendTexts = {};
    self.m_pFriendLevels = {};
    for i = 1, 4, 1 do
        self.m_nFriendItems[i] = self:GetDlgChild( "wanjia.wanjia" .. i );
        self.m_pFriendHeads[i] = self.m_nFriendItems[i]:GetDlgChild( "head.touxiang" );
        self.m_pFriendNames[i] = self.m_nFriendItems[i]:GetDlgChild( "name" );
        self.m_pFriendTexts[i] = self.m_nFriendItems[i]:GetDlgChild( "yiyaoqing" );
        self.m_pFriendLevels[i] = self.m_nFriendItems[i]:GetDlgChild( "duanwei" );

        self.m_pFriendLevels[i].pText = self.m_pFriendLevels[i]:GetDlgChild( "W_duanwei" );
        self.m_pFriendLevels[i].pIcons = {};
        for j = 1, 8, 1 do
            self.m_pFriendLevels[i].pIcons[j] = self.m_pFriendLevels[i]:GetDlgChild( "icon_duanwei." .. tostring( j ) );
        end

        local btn = self.m_nFriendItems[i]:GetDlgChild( "B_ok" );
        self.m_pFriendBtns[i] = btn;
        local friendIDs = self.m_nFriendIDs;
        btn:AddActionListener( function( event )
            self:Invite( friendIDs[i] );
        end, nil );

        local btn1 = self.m_nFriendItems[i]:GetDlgChild( "guanzhan" );
        self.m_pFriendBtns1[i] = btn1;
        btn1:AddActionListener( function( event )
            self:Observe( friendIDs[i] );
        end, nil );
    end

	self.m_nMaxMembers = 10;
	self.m_pMembers = {};
    self.m_pMemberNames = {};
    self.m_pMemberHeads = {};
    self.m_pMemberSkillID = {};
    self.m_pMemberCaptain = {};
    self.m_pMemberPC = {};
    self.m_pMemberReady = {};
	self.m_pMemberDisable = {};
    for i = 0, self.m_nMaxMembers - 1, 1 do
        local head = self:GetDlgChild( "head" ):GetDlgChild( "head" .. tostring( i + 1 ) );
		head:AddActionListener( "OnClickPlayer", self );
		self.m_pMembers[i] = head;
        self.m_pMemberNames[i] = head:GetDlgChild( "name" );
        self.m_pMemberHeads[i] = head:GetDlgChild( "wanjia.touxiang" );
        self.m_pMemberCaptain[i] = head:GetDlgChild( "fangzhu" );
        self.m_pMemberPC[i] = head:GetDlgChild( "diannao" );
		self.m_pMemberReady[i] = head:GetDlgChild( "zhunbei" );
		self.m_pMemberDisable[i] = head:GetDlgChild( "fengyin" );
		
		self.m_pMemberSkillID[i] = CRichIconWnd:new( head, "jineng" );
    end
	
	self.m_tickSeconds = CTick:new( "OnOneSecondTick", self );
	self.m_nInitSecond = -1;
    self.m_inviteTicks = {};

	self.m_pBtnChooseSkill:AddActionListener( "OnClickSwitchSkill", self );
    self.m_pBtnShowFriend1:AddActionListener( "RefreshFriends", self );
    self.m_pBtnShowFriend2:AddActionListener( "RefreshFriends", self );
    self.m_pBtnRefreshFriends:AddActionListener( "RefreshFriends", self );
    self.m_pBtnPrev:AddActionListener( "OnPrev", self );
    self.m_pBtnNext:AddActionListener( "OnNext", self );
	self.m_pBtnChooseSkill:AddActionListener( "OnClickSwitchSkill", self );
	g_App:GetGameStart():AddEventListener( "RaceRoomNumbering", "OnRaceRoomNumbering", self );
end

function CLimitRaceWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
	g_App:GetGameStart():RemoveEventListener( "RaceRoomNumbering", "OnRaceRoomNumbering", self );
	CGWnd.OnDestroy( self );
end

function CLimitRaceWnd:OnWndShow( bShow )
	if not bShow then
		self.m_nInitSecond = -1;
		 g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
	else
        g_App.m_EventDispatcher:AddEventListener( "CharsInfoChanged", "RefreshFriends", self );
	end
end


function CLimitRaceWnd:OnOneSecondTick()
	if self.m_nInitSecond >= 1 then
		self.m_nInitSecond = self.m_nInitSecond - 1;
		self.m_pBtnReady:SetWndText( self.m_nInitSecond );
		
	end
	if self.m_nInitSecond <= 0 then
		self.m_tickSeconds:Stop();
	end
end

function CLimitRaceWnd:RefreshFriends()
    if not self:IsShow() then
        return;
    end
	
    local b = self.m_pBtnShowFriend2:GetCheck();
	local FriendMgr = CFriendMgr:Inst();
    local allFriends = b and FriendMgr.m_tblFollowee or FriendMgr.m_tblFriends;
    local nTotalCount = #allFriends;
    self:GetDlgChild( "next" ):ShowWnd( nTotalCount > 4 );

    local nPageCount = math.ceil( nTotalCount / 4 );
    self.m_nPage = math.min( nPageCount, math.max( 1, self.m_nPage ) );
    self.m_pPage:SetWndText( tostring( self.m_nPage ) .. " / " .. tostring( nPageCount ) );
    local nStartIndex = math.max( ( self.m_nPage - 1 ) * 4, 0 );
	local nEndIndex = math.min( nStartIndex + 4, nTotalCount );
	local nLoopCount = nEndIndex - nStartIndex;

    for i = 1, nLoopCount, 1 do
		local nFriendID = allFriends[i + nStartIndex];
		local CharInfo = FriendMgr:GetCharInfo( nFriendID )
        local CanInvite = CharInfo.nState == 1;
        local CanObserve = CharInfo.nState == 3;
        self.m_nFriendItems[i]:ShowWnd( true );
        self.m_pFriendNames[i]:SetWndText( CharInfo.szCharName );
        self.m_pFriendBtns[i]:ShowWnd( CanInvite );
        self.m_pFriendBtns1[i]:ShowWnd( CanObserve );

        local bShowText = not CanInvite and not CanObserve;
        self.m_pFriendTexts[i]:ShowWnd( bShowText );

        if CharInfo.nState == 0 then
            self.m_pFriendTexts[i]:SetWndText( CStringConfig.Inst():GetString( "offline" ) );
        elseif CharInfo.nState == 2 then
            self.m_pFriendTexts[i]:SetWndText( CStringConfig.Inst():GetString( "zuduizhong" ) );
        elseif CharInfo.nState == 4 then
            self.m_pFriendTexts[i]:SetWndText( CStringConfig.Inst():GetString( "guanzhanzhong" ) );
        end

        CHeadIconConfig:Inst():SetIcon( self.m_pFriendHeads[i], CharInfo.nCurHeadIcon + 1, CharInfo.nAccountID );
        self.m_nFriendIDs[i] = CharInfo.nAccountID;

        self.m_pFriendLevels[i].pText:SetWndText( CStarLevelConfig:Inst():GetName( CharInfo.nCurLadderStar ) );
        local nLevel = CStarLevelConfig:Inst():GetLevel( CharInfo.nCurLadderStar );
        nLevel = tblLadder[nLevel];

        for j = 1, 8, 1 do
            self.m_pFriendLevels[i].pIcons[j]:ShowWnd( j == nLevel );
        end
    end    

    if nTotalCount <= 1 then
        self.m_pNoFriends:SetWndText( g_App:GetString( "wuguanzhu" ) );
    else
        self.m_pNoFriends:SetWndText( "" );
    end

	local nShowCount = nEndIndex - nStartIndex;
	for i = nShowCount + 1, 4, 1 do
        self.m_nFriendIDs[i] = nil;
        self.m_nFriendItems[i]:ShowWnd( false );
    end
end

function CLimitRaceWnd:OnPrev()
    self.m_nPage = self.m_nPage - 1;
    self:RefreshFriends();
end

function CLimitRaceWnd:OnNext()
    self.m_nPage = self.m_nPage + 1;
    self:RefreshFriends();
end

function CLimitRaceWnd:RefreshTeam( pTeam )
	self:ShowWnd( true );
	self.m_pTeam = pTeam;
	self.m_nTeamID = pTeam.nTeamID;
	if self.m_nInitSecond < 0 then
		self.m_nInitSecond = pTeam.nLeftTime;
		self.m_pBtnReady:SetWndText( self.m_nInitSecond );
		self.m_tickSeconds:Start( 1000 );
	end
    self.m_nMemberCount = pTeam.nCount;
    self.m_members = pTeam.members;
		
    for i = 0, self.m_nMaxMembers - 1, 1 do
        self.m_pMemberHeads[i]:RestoreImageFromCreateParam();
        self.m_pMemberNames[i]:SetWndText( "" );
		if self.m_pMemberSkillID[i] then
			self.m_pMemberSkillID[i]:ShowWnd( false );
		end
		self.m_pMembers[i]:EnableWnd( true );
		self.m_pMemberCaptain[i]:ShowWnd( false );
		self.m_pMemberPC[i]:ShowWnd( false );
		self.m_pMemberReady[i]:ShowWnd( false );
		self.m_pMemberDisable[i]:ShowWnd( false );
    end

    for i = 0, self.m_nMemberCount - 1, 1 do
        local member = self.m_members[i];
		if not member.bDisable then
			local nHeadIcon = member.nCurHeadIcon + 1;
			if member.nAccountID == 0 then
				nHeadIcon = nHeadIcon - 1;
			end
			CHeadIconConfig:Inst():SetIcon( self.m_pMemberHeads[i], nHeadIcon, member.nAccountID );
			self.m_pMemberNames[i]:SetWndText( member.szName );
        end

		if self.m_pMemberSkillID[i] then
			self.m_pMemberSkillID[i]:ShowWnd( not member.bDisable );
			self.m_pMemberSkillID[i]:GetDlgChild( "name" ):SetWndText( g_tblTabFile.skill[member.nSkillID].dName );
			self.m_pMemberSkillID[i]:SetIconID( g_tblTabFile.skill[member.nSkillID].nIconID );
		end
		self.m_pMemberCaptain[i]:ShowWnd( member.bCaptain );
		self.m_pMemberPC[i]:ShowWnd( member.nAccountID == 0 and not member.bDisable );
		self.m_pMemberReady[i]:ShowWnd( member.bReady and not member.bCaptain and not member.bDisable );
		self.m_pMemberDisable[i]:ShowWnd( member.bDisable );		
    end

    self:RefreshFriends();
end

function CLimitRaceWnd:Invite( nFriendID )
    if self.m_inviteTicks[nFriendID] ~= nil then
        g_App:MessageBox( g_App:GetString( "yaoqingdengdai" ) );
        return;
    end
    if self.m_nMemberCount >= self.m_nMaxMembers then
        g_App:HideMsg( g_App:GetString( "fangjianyimanwufayaoqing" ) );
        return;
    end
	local NetMsg = CInvitePlayer:new();
    NetMsg.nAccountID = nFriendID;
	g_App:SendShellMsg( NetMsg );

    local tick = CTick:new( function() self.m_inviteTicks[nFriendID] = nil; end, nil, nil, 1 );
    self.m_inviteTicks[nFriendID] = tick;
    tick:Start( 15000 );
end

function CLimitRaceWnd:OnClickSwitchSkill( Event )
	local pSkillWnd = g_App:GetGameStart().m_pWndSkillDevelop;
	pSkillWnd:ShowAndSetFocus();
end

function CLimitRaceWnd:OnRaceRoomNumbering()
	if not self:IsShow() then
		return;
	end	
	self.m_tickSeconds:Stop();
	self.m_nInitSecond = CSnakeConstant:Inst():GetRaceNumberingSeconds();
	self.m_pBtnReady:SetWndText( self.m_nInitSecond );
	self.m_tickSeconds:Start( 1000 );
end

------------------------------------CTeamRaceMemberWnd------------------------------------
function CTeamRaceMemberWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
	self.m_nMaxMembers = ETEAM_PLAY_COUNT;
end

function CTeamRaceMemberWnd:OnCreated()	
	self.m_pBtnCopy = self:GetDlgChild( "btn_fuzhi" );
	self.m_pBtnCopy:AddActionListener( "OnCopyTeamCode", self );
	self.m_pBtnRefreshFriends = self:GetDlgChild( "b_shuaxin" );

    self.m_pBtnShowFriend1 = self:GetDlgChild( "youbian_btn.btn1" );
    self.m_pBtnShowFriend2 = self:GetDlgChild( "youbian_btn.btb2" );
    self.m_pBtnShowFriend1:SetCheck( true );
    self.m_pBtnShowFriend1:AddActionListener( "RefreshFriends", self );
    self.m_pBtnShowFriend2:AddActionListener( "RefreshFriends", self );
    self.m_pBtnRefreshFriends:AddActionListener( "RefreshFriends", self );

    self.m_nPage = 1;
    self.m_pPage = self:GetDlgChild( "next.yeshu" );
    self.m_pBtnPrev = self:GetDlgChild( "next.b_zuo" );
    self.m_pBtnNext = self:GetDlgChild( "next.b_you" );
    self.m_pBtnPrev:AddActionListener( "OnPrev", self );
    self.m_pBtnNext:AddActionListener( "OnNext", self );
    self.m_pNoFriends = self:GetDlgChild( "kong" );
	
    self.m_nFriendItems = {};
    self.m_nFriendIDs = {};
    self.m_pFriendHeads = {};
    self.m_pFriendNames = {};
    self.m_pFriendBtns = {};
    self.m_pFriendBtns1 = {};
    self.m_pFriendTexts = {};
    self.m_pFriendLevels = {};
    for i = 1, ETEAM_PLAY_COUNT, 1 do
        self.m_nFriendItems[i] = self:GetDlgChild( "wanjia.wanjia" .. i );
        self.m_pFriendHeads[i] = self.m_nFriendItems[i]:GetDlgChild( "head.touxiang" );
        self.m_pFriendNames[i] = self.m_nFriendItems[i]:GetDlgChild( "name" );
        self.m_pFriendTexts[i] = self.m_nFriendItems[i]:GetDlgChild( "yiyaoqing" );
        self.m_pFriendLevels[i] = self.m_nFriendItems[i]:GetDlgChild( "duanwei" );

        self.m_pFriendLevels[i].pText = self.m_pFriendLevels[i]:GetDlgChild( "W_duanwei" );
        self.m_pFriendLevels[i].pIcons = {};
        for j = 1, 8, 1 do
            self.m_pFriendLevels[i].pIcons[j] = self.m_pFriendLevels[i]:GetDlgChild( "icon_duanwei." .. tostring( j ) );
        end

        local btn = self.m_nFriendItems[i]:GetDlgChild( "B_ok" );
        self.m_pFriendBtns[i] = btn;
        local friendIDs = self.m_nFriendIDs;
        btn:AddActionListener( function( event )
            self:Invite( friendIDs[i] );
        end, nil );

        local btn1 = self.m_nFriendItems[i]:GetDlgChild( "guanzhan" );
        self.m_pFriendBtns1[i] = btn1;
        btn1:AddActionListener( function( event )
            self:Observe( friendIDs[i] );
        end, nil );
    end
	    
	self.m_pMembers = {};
    self.m_pMemberNames = {};
    self.m_pMemberHeads = {};
    self.m_pMemberLevels = {};
    self.m_pMemberAdds = {};
    self.m_pMemberSkillID = {};
	self.m_pMemberSwitchSkill = {};
	self.m_pMemberReady = {};
    for i = 0, self.m_nMaxMembers - 1, 1 do
        local p = self:GetDlgChild( "head" ):GetDlgChild( "head" .. tostring( i + 1 ) );
		self.m_pMembers[i] = p;
        self.m_pMemberNames[i] = p:GetDlgChild( "name" );
        self.m_pMemberHeads[i] = p:GetDlgChild( "wanjia.touxiang" );
        self.m_pMemberAdds[i] = p:GetDlgChild( "b_add" );
        self.m_pMemberLevels[i] = p:GetDlgChild( "duanwei" );
		self.m_pMemberReady[i] = p:GetDlgChild( "zhunbei" );

        self.m_pMemberLevels[i].pText = self.m_pMemberLevels[i]:GetDlgChild( "W_duanwei" );
        self.m_pMemberLevels[i].pIcons = {};
        for j = 1, 8, 1 do
            self.m_pMemberLevels[i].pIcons[j] = self.m_pMemberLevels[i]:GetDlgChild( "icon_duanwei." .. tostring( j ) );
        end

		self.m_pMemberSkillID[i] = CRichIconWnd:new( p, "jineng" );
		self.m_pMemberSwitchSkill[i] = p:GetDlgChild( "b_change" );
		if self.m_pMemberSwitchSkill[i] then
			self.m_pMemberSwitchSkill[i]:AddActionListener( "OnClickSwitchSkill", self );
		end
        p:AddActionListener( function( event )
            self:KickMember( self.m_members[i].nPos );
        end, nil );
    end

    self.m_inviteTicks = {};
	g_App.m_EventDispatcher:AddEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
end

function CTeamRaceMemberWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
	g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
	CGWnd.OnDestroy( self );
end

function CTeamRaceMemberWnd:OnWndShow( bShow )
    if bShow then
        g_App.m_EventDispatcher:AddEventListener( "CharsInfoChanged", "RefreshFriends", self );
		self:RefreshFriends();
    else
        g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
    end
end

function CTeamRaceMemberWnd:RefreshTeam( pTeam )
	self.m_nTeamID = pTeam.nTeamID;

    self.m_nMemberCount = pTeam.nCount;
    self.m_members = pTeam.members;
    for i = 0, self.m_nMemberCount - 1, 1 do
        local member = self.m_members[i];
        CHeadIconConfig:Inst():SetIcon( self.m_pMemberHeads[i], member.nCurHeadIcon + 1, member.nAccountID );
        self.m_pMemberNames[i]:SetWndText( member.szName );
        if self.m_pMemberAdds[i] then
            self.m_pMemberAdds[i]:ShowWnd( false );
        end

        self.m_pMemberLevels[i]:ShowWnd( true );
        self.m_pMemberLevels[i].pText:SetWndText( CStarLevelConfig:Inst():GetName( member.nCurLadderStar ) );
        local nLevel = CStarLevelConfig:Inst():GetLevel( member.nCurLadderStar );
        nLevel = tblLadder[nLevel];

        for j = 1, 8, 1 do
            self.m_pMemberLevels[i].pIcons[j]:ShowWnd( j == nLevel );
        end
		local bDirector = g_App:GetAccountID() == member.nAccountID;
		local bCouldUseSkill = g_App:CouldUseSkill();
		if self.m_pMemberSkillID[i] then
			if bDirector then
				self.m_pMemberSkillID[i]:ShowWnd( bCouldUseSkill );
			else
				self.m_pMemberSkillID[i]:ShowWnd( true );
			end
			self.m_pMemberSkillID[i]:SetIconID( g_tblTabFile.skill[member.nSkillID].nIconID );
		end
		if self.m_pMemberSwitchSkill[i] then
			self.m_pMemberSwitchSkill[i]:ShowWnd( bDirector );
			if bDirector then
				self.m_pMemberSwitchSkill[i]:EnableWnd( bCouldUseSkill );
				local szShowText = g_App:GetString( bCouldUseSkill and "genghuanjineng" or "gongnengweikaifang" );
				self.m_pMemberSwitchSkill[i]:SetWndText( szShowText );
			end
		end
		self.m_pMembers[i]:EnableWnd( not bDirector );
		self.m_pMemberReady[i]:ShowWnd( i ~= 0 and member.bReady );
    end
    for i = self.m_nMemberCount, self.m_nMaxMembers - 1, 1 do
        self.m_pMemberHeads[i]:RestoreImageFromCreateParam();
        self.m_pMemberNames[i]:SetWndText( "" );
        if self.m_pMemberAdds[i] then
            self.m_pMemberAdds[i]:ShowWnd( true );
        end
        self.m_pMemberLevels[i]:ShowWnd( false );
		if self.m_pMemberSkillID[i] then
			self.m_pMemberSkillID[i]:ShowWnd( false );
		end
		if self.m_pMemberSwitchSkill[i] then
			self.m_pMemberSwitchSkill[i]:ShowWnd( false );
		end
		self.m_pMemberReady[i]:ShowWnd( false );
		self.m_pMembers[i]:EnableWnd( true );
    end

    self:RefreshFriends();
end

function CTeamRaceMemberWnd:RefreshFriends()
    if not self:IsShow() then
        return;
    end
	
    local b = self.m_pBtnShowFriend2:GetCheck();
	local FriendMgr = CFriendMgr:Inst();
    local allFriends = b and FriendMgr.m_tblFollowee or FriendMgr.m_tblFriends;
    local nTotalCount = #allFriends;
    self:GetDlgChild( "next" ):ShowWnd( nTotalCount > 4 );

    local nPageCount = math.ceil( nTotalCount / 4 );
    self.m_nPage = math.min( nPageCount, math.max( 1, self.m_nPage ) );
    self.m_pPage:SetWndText( tostring( self.m_nPage ) .. " / " .. tostring( nPageCount ) );
    local nStartIndex = math.max( ( self.m_nPage - 1 ) * 4, 0 );
	local nEndIndex = math.min( nStartIndex + 4, nTotalCount );
	local nLoopCount = nEndIndex - nStartIndex;

    for i = 1, nLoopCount, 1 do
		local nFriendID = allFriends[i + nStartIndex];
		local CharInfo = FriendMgr:GetCharInfo( nFriendID )
        local CanInvite = CharInfo.nState == 1;
        local CanObserve = CharInfo.nState == 3;
        self.m_nFriendItems[i]:ShowWnd( true );
        self.m_pFriendNames[i]:SetWndText( CharInfo.szCharName );
        self.m_pFriendBtns[i]:ShowWnd( CanInvite );
        self.m_pFriendBtns1[i]:ShowWnd( CanObserve );

        local bShowText = not CanInvite and not CanObserve;
        self.m_pFriendTexts[i]:ShowWnd( bShowText );

        if CharInfo.nState == 0 then
            self.m_pFriendTexts[i]:SetWndText( CStringConfig.Inst():GetString( "offline" ) );
        elseif CharInfo.nState == 2 then
            self.m_pFriendTexts[i]:SetWndText( CStringConfig.Inst():GetString( "zuduizhong" ) );
        elseif CharInfo.nState == 4 then
            self.m_pFriendTexts[i]:SetWndText( CStringConfig.Inst():GetString( "guanzhanzhong" ) );
        end

        CHeadIconConfig:Inst():SetIcon( self.m_pFriendHeads[i], CharInfo.nCurHeadIcon + 1, CharInfo.nAccountID );
        self.m_nFriendIDs[i] = CharInfo.nAccountID;

        self.m_pFriendLevels[i].pText:SetWndText( CStarLevelConfig:Inst():GetName( CharInfo.nCurLadderStar ) );
        local nLevel = CStarLevelConfig:Inst():GetLevel( CharInfo.nCurLadderStar );
        nLevel = tblLadder[nLevel];

        for j = 1, 8, 1 do
            self.m_pFriendLevels[i].pIcons[j]:ShowWnd( j == nLevel );
        end
    end    

    if nTotalCount <= 1 then
        self.m_pNoFriends:SetWndText( g_App:GetString( "wuguanzhu" ) );
    else
        self.m_pNoFriends:SetWndText( "" );
    end

	local nShowCount = nEndIndex - nStartIndex;
	for i = nShowCount + 1, 4, 1 do
        self.m_nFriendIDs[i] = nil;
        self.m_nFriendItems[i]:ShowWnd( false );
    end
end

function CTeamRaceMemberWnd:Invite( nFriendID )
    if self.m_inviteTicks[nFriendID] ~= nil then
        g_App:MessageBox( g_App:GetString( "yaoqingdengdai" ) );
        return;
    end
    if self.m_nMemberCount >= 4 then
        g_App:HideMsg( g_App:GetString( "fangjianyimanwufayaoqing" ) );
        return;
    end
	local NetMsg = CInvitePlayer:new();
    NetMsg.nAccountID = nFriendID;
	g_App:SendShellMsg( NetMsg );

    local tick = CTick:new( function() self.m_inviteTicks[nFriendID] = nil; end, nil, nil, 1 );
    self.m_inviteTicks[nFriendID] = tick;
    tick:Start( 15000 );
end

function CTeamRaceMemberWnd:Observe( nFriendID )
	local NetMsg = CObserveGame:new();
    NetMsg.m_nAccountID = nFriendID;
	NetMsg.m_nRaceRoomID = 0;
	g_App:SendShellMsg( NetMsg );
end

function CTeamRaceMemberWnd:OnPrev()
    self.m_nPage = self.m_nPage - 1;
    self:RefreshFriends();
end

function CTeamRaceMemberWnd:OnNext()
    self.m_nPage = self.m_nPage + 1;
    self:RefreshFriends();
end

function CTeamRaceMemberWnd:OnClickSwitchSkill( Event )
	local pSkillWnd = g_App:GetGameStart().m_pWndSkillDevelop;
	pSkillWnd:ShowAndSetFocus();
end

function CTeamRaceMemberWnd:OnWorldMsgCooldown( Event )
	if Event.m_szLeftTimeText then
		self.m_pBtnCopy:EnableWnd( false );		
		self.m_pBtnCopy:SetWndText( Event.m_szLeftTimeText );
	else
		self.m_pBtnCopy:EnableWnd( true );		
		self.m_pBtnCopy:SetWndText( CStringConfig.Inst():GetString( "yaoqingwanjia" ) );
	end
end

function CTeamRaceMemberWnd:KickMember( nClickPos )
	if not CPlayerRoomMemberInfoMgr:Instance():IsCaptain() then
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

function CTeamRaceMemberWnd:OnCopyTeamCode()
	local nTeamType = eMRT_TeamRaceBefore;
	local szText = g_App:GetString( "tuanzhansaishiyaoqing" );
	local nRoomNum = CPlayerRoomMemberInfoMgr:Instance():GetTeamID();
	local szContent = string.format( szText, nRoomNum );
	local szHyplink = "joinroom "..nTeamType.." "..nRoomNum.." "..g_App:GetGameStart().m_nRaceID;
	local szMsg = "#u#c("..szHyplink..")"..szContent.."#c()";
	g_App:GetInstantMessageDataMgr():SendMsg( 0, szMsg );
end

--------------------------------------CTeamRaceWnd--------------------------------------
function CTeamRaceWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
	self.m_nMaxMembers = ETEAM_PLAY_COUNT * ETEAM_MATCH_COUNT;
end

function CTeamRaceWnd:OnCreated()
	self.m_pWndSecondsName = self:GetDlgChild( "tips0" );
	self.m_pWndLeftSeconds = self:GetDlgChild( "tips1" );
	self.m_tickSeconds = CTick:new( "OnOneSecondTick", self );
	self.m_nInitSecond = -1;

	self.m_pMembers = {};
    self.m_pMemberNames = {};
    self.m_pMemberHeads = {};
    self.m_pMemberSkill = {};
    self.m_pMemberCaptain = {};
	self.m_pMemberLadder = {};
    for i = 1, self.m_nMaxMembers do
        local head = self:GetDlgChild( "head" ):GetDlgChild( "head" .. tostring( i ) );
		self.m_pMembers[i] = head;
        self.m_pMemberNames[i] = head:GetDlgChild( "name" );
        self.m_pMemberHeads[i] = head:GetDlgChild( "wanjia.touxiang" );		
		self.m_pMemberSkill[i] = CRichIconWnd:new( head, "jineng" );
		self.m_pMemberLadder[i] = head:GetDlgChild( "duanwei.icon_duanwei" );		
    end
	g_App:GetGameStart():AddEventListener( "RaceRoomNumbering", "OnRaceRoomNumbering", self );
end

function CTeamRaceWnd:OnDestroy()
	self.m_tickSeconds:Stop();
	g_App:GetGameStart():RemoveEventListener( "RaceRoomNumbering", "OnRaceRoomNumbering", self );
	CGWnd.OnDestroy( self );
end

function CTeamRaceWnd:OnWndShow( bShow )
	if not bShow then
		self.m_tickSeconds:Stop();
		self.m_nInitSecond = -1;
	end
end

function CTeamRaceWnd:RefreshTeam()
	self:ShowWnd( true );	

	--让自己的队伍处于中间位置
	local nSelfPos = CPlayerRoomMemberInfoMgr:Instance():GetSelfPos() - 1;
	if nSelfPos >= 0 then
		local nNum = 0;
		if math.floor( nSelfPos / 4 ) == 0 then
			nNum = 4;
		elseif math.floor( nSelfPos / 4 ) == 2 then
			nNum = 8;
		end
		CPlayerRoomMemberInfoMgr:Instance():ReSeat( nNum );
	end

	self.m_pTeam = CPlayerRoomMemberInfoMgr:Instance():GetAllData();
	self.m_nTeamID = self.m_pTeam.nTeamID;

    self.m_nMemberCount = self.m_pTeam.nCount;
    self.m_members = self.m_pTeam.members;
	

	if self.m_nInitSecond < 0 then
		self.m_nInitSecond = self.m_pTeam.nLeftTime;
		self.m_pWndSecondsName:SetWndText( g_App:GetString( "dengdaiqitaduiwujinru" ) );
		self.m_pWndLeftSeconds:SetWndText( self.m_nInitSecond );
		self.m_tickSeconds:Start( 1000 );
	end

    for i = 1, self.m_nMaxMembers do
        self.m_pMemberHeads[i]:RestoreImageFromCreateParam();
        self.m_pMemberNames[i]:SetWndText( "" );
		if self.m_pMemberSkill[i] then
			self.m_pMemberSkill[i]:ShowWnd( false );
		end
		self.m_pMembers[i]:EnableWnd( true );
		self.m_pMembers[i]:ShowWnd( false );
    end

    for i = 1, self.m_nMemberCount do
		local member = self.m_members[i - 1];
		self.m_pMembers[member.nPos]:ShowWnd( true );
		if not member.bDisable then
			local nHeadIcon = member.nCurHeadIcon + 1;
			if member.nAccountID == 0 then
				nHeadIcon = nHeadIcon - 1;
			end
			CHeadIconConfig:Inst():SetIcon( self.m_pMemberHeads[member.nPos], nHeadIcon, member.nAccountID );
			self.m_pMemberNames[member.nPos]:SetWndText( member.szName );
		end

		local nLevel = CStarLevelConfig:Inst():GetBigLevel( member.nCurLadderStar );
        for j = 1, 8 do
			self.m_pMemberLadder[member.nPos]:GetDlgChild( j ):ShowWnd( j == nLevel );
		end
		if self.m_pMemberSkill[member.nPos] then
			self.m_pMemberSkill[member.nPos]:ShowWnd( not member.bDisable );
			self.m_pMemberSkill[member.nPos]:GetDlgChild( "name" ):SetWndText( g_tblTabFile.skill[member.nSkillID].dName );
			self.m_pMemberSkill[member.nPos]:SetIconID( g_tblTabFile.skill[member.nSkillID].nIconID );			
		end
	end
end

function CTeamRaceWnd:OnOneSecondTick()
	if self.m_nInitSecond >= 1 then
		self.m_nInitSecond = self.m_nInitSecond - 1;
		self.m_pWndLeftSeconds:SetWndText( self.m_nInitSecond );
		
	end
	if self.m_nInitSecond <= 0 then
		self.m_tickSeconds:Stop();
	end
end

function CTeamRaceWnd:OnRaceRoomNumbering()
	if not self:IsShow() then
		return;
	end
	self.m_tickSeconds:Stop();
	self.m_nInitSecond = CSnakeConstant:Inst():GetRaceNumberingSeconds();
	self.m_pWndSecondsName:SetWndText( g_App:GetString( "bisaimashangkaishi" ) );
	self.m_pWndLeftSeconds:SetWndText( self.m_nInitSecond );
	self.m_tickSeconds:Start( 1000 );
end
--endregion
