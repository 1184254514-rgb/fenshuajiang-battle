--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

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

function CTeamMatchWnd:Ctor( szResName, wndParent, nLoadType, nTeamType )
    self.nTeamType = nTeamType;
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CTeamMatchWnd:OnCreated()
	self.m_pBtnStartMatch = self:GetDlgChild( "btn_zidongpipei" );
	self.m_pBtnStartMatch:AddActionListener( "OnStartMatch", self );
	self.m_pBtnJoinTeam = self:GetDlgChild( "btn_jiaruduiwu" );
	self.m_pBtnJoinTeam:AddActionListener( "OnJoinTeam", self );
	self.m_pBtnLeaveTeam = self:GetDlgChild( "btn_duiwuma" );
	self.m_pBtnLeaveTeam:AddActionListener( "OnLeaveTeam", self );
	self.m_pBtnCopy = self:GetDlgChild( "btn_fuzhi" );
	self.m_pBtnCopy:AddActionListener( "OnCopyTeamCode", self );
    self.m_pTeamID = self:GetDlgChild( "fangjianhaoma" ):GetDlgChild( "shurukuang" );
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
	self.m_pBtnHelp = self:GetDlgChild( "b_bangzhu" );
	self.m_pBtnHelp:AddActionListener( "OnClickHelp", self );
    
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

    if self.nTeamType == eMRT_Team then
        self.m_nMaxMembers = 4;
    elseif self.nTeamType == eMRT_Limit then
        self.m_nMaxMembers = 3;
    end
    self.m_pMemberNames = {};
    self.m_pMemberHeads = {};
    self.m_pMemberLevels = {};
    self.m_pMemberAdds = {};
    self.m_pMemberSkillID = {};
	self.m_pMemberSwitchSkill = {};
    for i = 0, self.m_nMaxMembers - 1, 1 do
        local p = self:GetDlgChild( "head" ):GetDlgChild( "head" .. tostring( i + 1 ) );
        self.m_pMemberNames[i] = p:GetDlgChild( "name" );
        self.m_pMemberHeads[i] = p:GetDlgChild( "wanjia.touxiang" );
        self.m_pMemberAdds[i] = p:GetDlgChild( "b_add" );
        self.m_pMemberLevels[i] = p:GetDlgChild( "duanwei" );

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
    end

    self.m_inviteTicks = {};
	g_App.m_EventDispatcher:AddEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
end

function CTeamMatchWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
	g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
	CGWnd.OnDestroy( self );
end

function CTeamMatchWnd:OnWndShow( bShow )
    if bShow then
        g_App.m_EventDispatcher:AddEventListener( "CharsInfoChanged", "RefreshFriends", self );
		self.m_pBtnStartMatch:RemoveAllEffects();
		self.m_pBtnStartMatch:AddEffect( "fx/cfg/shouzhi.eft", "fx/loop", "shouzhi", -1 );
    else
        g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
    end
end

function CTeamMatchWnd:Invite( nFriendID )
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

function CTeamMatchWnd:Observe( nFriendID )
	local NetMsg = CObserveGame:new();
    NetMsg.m_nAccountID = nFriendID;
	NetMsg.m_nRaceRoomID = 0;
	g_App:SendShellMsg( NetMsg );
end

function CTeamMatchWnd:IsLeader()
    return g_App:GetAccountID() == self.m_members[0].nAccountID;
end

function CTeamMatchWnd:RefreshTeam( pTeam )
	--self:ShowWnd( true );

	self.m_nTeamID = pTeam.nTeamID;
    self.m_pTeamID:SetWndText( tostring( pTeam.nTeamID ) );

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
    end

    self.m_pBtnJoinTeam:ShowWnd( pTeam.nCount <= 1 );
    self.m_pBtnLeaveTeam:ShowWnd( pTeam.nCount > 1 );
    self:RefreshFriends();
end

function CTeamMatchWnd:OnStartMatch()
	if not self.m_nTeamID or self.m_nTeamID == 0 then
		return;
	end
	self.m_pBtnStartMatch:RemoveAllEffects();
    if self:IsLeader() then
	    local NetMsg = CStartMatchTeam:new();
	    g_App:SendShellMsg( NetMsg );
        if self.nTeamType == eMRT_Limit then
            g_App:WaitMsg( true );
        end
    else
		g_App:HideMsg( CStringConfig.Inst():GetString( "tuanduitishi2" ) );
    end
end

function CTeamMatchWnd:OnJoinTeam()
    g_App:GetGameStart():GetTeamWnd( self.nTeamType ).m_pTeamCodeWnd:Show( self.nTeamType );
end

function CTeamMatchWnd:OnLeaveTeam()
	local NetMsg = CLeaveTeam:new();
    NetMsg.bCreateNewTeam = true;
	g_App:SendShellMsg( NetMsg );
end

function CTeamMatchWnd:RefreshFriends()
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

function CTeamMatchWnd:OnPrev()
    self.m_nPage = self.m_nPage - 1;
    self:RefreshFriends();
end

function CTeamMatchWnd:OnNext()
    self.m_nPage = self.m_nPage + 1;
    self:RefreshFriends();
end

function CTeamMatchWnd:OnClickHelp()
	local nRoomType = eRT_LimitTime;
	if self.nTeamType == eMRT_Limit then
		nRoomType = eRT_LimitTime;
	elseif self.nTeamType == eMRT_Team then
		nRoomType = eRT_Team;
	end
	g_App:GetGameStart():GetModeTips( nRoomType ):ShowAndSetFocus();
end

function CTeamMatchWnd:OnClickSwitchSkill( Event )
	local pSkillWnd = g_App:GetGameStart().m_pWndSkillDevelop;
	pSkillWnd:ShowAndSetFocus();
end

function CTeamMatchWnd:OnWorldMsgCooldown( Event )
	if Event.m_szLeftTimeText then
		self.m_pBtnCopy:EnableWnd( false );		
		self.m_pBtnCopy:SetWndText( Event.m_szLeftTimeText );
	else
		self.m_pBtnCopy:EnableWnd( true );		
		self.m_pBtnCopy:SetWndText( CStringConfig.Inst():GetString( "yaoqingwanjia" ) );
	end
end

function CTeamMatchWnd:OnCopyTeamCode()
	local bTeam = self.nTeamType == eMRT_Team;
	local szName = bTeam and "kuaisuyaoqing2" or "kuaisuyaoqing1";
	local szText = CStringConfig.Inst():GetString( szName )
	local nRoomNum = tonumber( self.m_pTeamID:GetWndText() );
	local szContent = string.format( szText, nRoomNum );
	local szHyplink = "joinroom "..self.nTeamType.." "..nRoomNum;
	local szMsg = "#u#c("..szHyplink..")"..szContent.."#c()";
	g_App:GetInstantMessageDataMgr():SendMsg( 0, szMsg );
end

--endregion
