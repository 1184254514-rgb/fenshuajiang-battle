--region CSecretMatchWnd.lua
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

function CSecretMatchWnd:Ctor( szResName, wndParent, nLoadType, nTeamType )
	self.nTeamType = nTeamType;
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CSecretMatchWnd:OnExChangePos()
end

function CSecretMatchWnd:OnCreated()
	self.m_pBtnStartGame = self:GetDlgChild( "btn_zidongpipei" );
	self.m_pBtnStartGame:AddActionListener( "OnStartMatch", self );
	self.m_pBtnReady = self:GetDlgChild( "btn_zhunbei" );
	self.m_pBtnReady:AddActionListener( "ClickReady", self );
	self.m_pBtnChooseSkill = self:GetDlgChild( "btn_xuanzejineng" );
	self.m_pBtnChooseSkill:AddActionListener( "OnClickSwitchSkill", self );
	self.m_pBtnRefreshFriends = self:GetDlgChild( "b_shuaxin" );
	self.m_pBtnCopy = self:GetDlgChild( "btn_fuzhi" );
	self.m_pBtnCopy:AddActionListener( "OnCopyTeamCode", self );
    self.m_pTeamID = self:GetDlgChild( "fangjianhaoma" ):GetDlgChild( "shurukuang" );
	self.m_pBtnJoinTeam = self:GetDlgChild( "btn_jinrufangjian" );
	self.m_pBtnJoinTeam:AddActionListener( "OnJoinTeam", self );
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

    if self.nTeamType == eMRT_TeamSecret then
        self.m_nMaxMembers = 12;
    elseif self.nTeamType == eMRT_LimitSecret then
        self.m_nMaxMembers = 10;
    end
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
	
	self.m_pBtnHelp = self:GetDlgChild( "b_bangzhu" );
	self.m_pBtnHelp:AddActionListener( "OnClickHelp", self );

    self.m_inviteTicks = {};
	self.m_tickClick = CTick:new( "OnClickTick", self );
	self.m_bCanClick = true;
	g_App.m_EventDispatcher:AddEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
	g_App:GetGameStart():AddEventListener( "OnReadyChange", "ChangeReady", self );
end

function CSecretMatchWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
	g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
	g_App:GetGameStart():RemoveEventListener( "OnReadyChange", "ChangeReady", self );
	self.m_tickClick:Stop();
	CGWnd.OnDestroy( self );
end

function CSecretMatchWnd:OnWndShow( bShow )
	if bShow then
		g_App.m_EventDispatcher:AddEventListener( "CharsInfoChanged", "RefreshFriends", self );
	else
		g_App.m_EventDispatcher:RemoveEventListener( "CharsInfoChanged", "RefreshFriends", self );
	end
end

function CSecretMatchWnd:RefreshFriends()
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

function CSecretMatchWnd:OnPrev()
    self.m_nPage = self.m_nPage - 1;
    self:RefreshFriends();
end

function CSecretMatchWnd:OnNext()
    self.m_nPage = self.m_nPage + 1;
    self:RefreshFriends();
end

function CSecretMatchWnd:RefreshTeam( pTeam )
	--self:ShowWnd( true );
	self.m_pTeam = pTeam;
	self.m_nTeamID = pTeam.nTeamID;
    self.m_pTeamID:SetWndText( tostring( pTeam.nTeamID ) );

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
			CHeadIconConfig:Inst():SetIcon( self.m_pMemberHeads[member.nPos - 1], nHeadIcon, member.nAccountID );
			self.m_pMemberNames[member.nPos - 1]:SetWndText( member.szName );
        end

        local nLevel = CStarLevelConfig:Inst():GetLevel( member.nCurLadderStar );
        nLevel = tblLadder[nLevel];

		if self.m_pMemberSkillID[member.nPos - 1] then
			self.m_pMemberSkillID[member.nPos - 1]:ShowWnd( not member.bDisable );
			self.m_pMemberSkillID[member.nPos - 1]:GetDlgChild( "name" ):SetWndText( g_tblTabFile.skill[member.nSkillID].dName );
			self.m_pMemberSkillID[member.nPos - 1]:SetIconID( g_tblTabFile.skill[member.nSkillID].nIconID );
		end
		self.m_pMemberCaptain[member.nPos - 1]:ShowWnd( member.bCaptain );
		self.m_pMemberPC[member.nPos - 1]:ShowWnd( member.nAccountID == 0 and not member.bDisable );
		self.m_pMemberReady[member.nPos - 1]:ShowWnd( member.bReady and not member.bCaptain and not member.bDisable );
		self.m_pMemberDisable[member.nPos - 1]:ShowWnd( member.bDisable );
		local SelfInfo = self:GetSelfInfo();
		if SelfInfo then
			self.m_pMembers[member.nPos - 1]:EnableWnd( SelfInfo.nPos ~= member.nPos );
			self.m_pMemberSkillID[member.nPos - 1]:EnableWnd( true );
			self.m_pBtnStartGame:ShowWnd( SelfInfo.bCaptain );
			self.m_pBtnReady:ShowWnd( not SelfInfo.bCaptain );
			local str = SelfInfo.bReady and CStringConfig:Inst():GetString( "quxiaozhunbei" ) or CStringConfig:Inst():GetString( "zhunbei" );
			self.m_pBtnReady:SetWndText( str );
		end
    end

    self:RefreshFriends();
end

function CSecretMatchWnd:OnJoinTeam()
	g_App:GetGameStart():GetTeamWnd( self.nTeamType ).m_pTeamCodeWnd:Show( self.nTeamType );
end


function CSecretMatchWnd:Invite( nFriendID )
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

function CSecretMatchWnd:GetSelfInfo()
	if not self.m_pTeam then
		return;
	end
	for i = 0, self.m_pTeam.nCount - 1 do
		if self.m_pTeam.members[i].nAccountID == g_App:GetAccountID() then
			return self.m_pTeam.members[i];
		end
	end
end

function CSecretMatchWnd:GetPosInfo( nPos )
	if not self.m_pTeam then
		return;
	end
	for i = 0, self.m_pTeam.nCount - 1 do
		if self.m_pTeam.members[i].nPos == nPos then
			return self.m_pTeam.members[i];
		end
	end
end

function CSecretMatchWnd:OnClickPlayer( event )
	if not self.m_pTeam then
		return;
	end
	local WndName = event.m_Target:GetWndName();
	local nClickPos = tonumber( string.sub( WndName, 5, string.len( WndName )));
	local SelfInfo = self:GetSelfInfo();
	local PosInfo = self:GetPosInfo( nClickPos );
	
	if not SelfInfo.bCaptain then
		if not self.m_bCanClick then
			local nTimeCount = CSnakeConstant:Inst():GetHandlePosTime();
			local nLeftSec =  math.ceil( nTimeCount / 1000 - self.m_tickClick:GetTickCount() );
			nLeftSec = nLeftSec > 0 and nLeftSec or 1;
			local str = string.format( CStringConfig:Inst():GetString( "fangkecaozuoxianzhi" ), nLeftSec );
			g_App:HideMsg( str );
			return;
		else
			self.m_bCanClick = false;
			self.m_tickClick:Start( 1000, true );
		end
	end

	if PosInfo and PosInfo.nAccountID == g_App:GetAccountID() then	--对自己操作无效
		return;
	end
	if SelfInfo.bCaptain then		--自己是房主  
		if not PosInfo then
			self:ShowThreeChoicesWnd( nClickPos );
		else
			if PosInfo.bDisable then		--该位置已被封印
				g_App:MessageBox( g_App:GetString( "sirenfangjiantips4" ),
				{
				[CMessageBox.Close] = function()
					g_App.m_pMessageBox:ShowWnd( false );
				end;
				[CMessageBox.OK] = function()	--解除封印
					g_App.m_pMessageBox:ShowWnd( false );
					local pConn = g_App:GetWorldConn();
					if not pConn then
						return;
					end
					local NetMsg = CMatchPosHandle:new();
					NetMsg.nTeamID = self.m_pTeam.nTeamID;
					NetMsg.nType = eMPH_Kick;
					NetMsg.nPos = nClickPos;
					pConn:SendShellMsg( NetMsg );
				end;
				} );
			else
				self:ShowThreeChoicesWnd2( nClickPos );
			end
		end
	else
		if PosInfo and PosInfo.bDisable then
			return;
		end
		g_App:MessageBox( g_App:GetString( "jiaohuanweizhiqueren1" ),
		{
		[CMessageBox.Close] = function()
			g_App.m_pMessageBox:ShowWnd( false );
		end;
		[CMessageBox.OK] = function()	--请求换位置  
			g_App.m_pMessageBox:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local NetMsg = CQueryChangeMatchPos:new();
			NetMsg.nTeamID = self.m_pTeam.nTeamID;
			NetMsg.nRequestPos = SelfInfo.nPos;
			NetMsg.nResponsePos = nClickPos;
			g_App:SendShellMsg( NetMsg );
			if PosInfo and PosInfo.nAccountID ~= 0 then
				g_App:HideMsg( g_App:GetString( "jiaohuanweizhiqueren2" ) );
			end 
		end;
		} );
	end
end

function CSecretMatchWnd:ChangePos( nRequestPos, nResponsePos )
	for i = 0, self.m_nMemberCount - 1 do
		if self.m_pTeam.members[i].nPos == nRequestPos then
			self.m_pTeam.members[i].nPos = nResponsePos;
		elseif self.m_pTeam.members[i].nPos == nResponsePos then
			self.m_pTeam.members[i].nPos = nRequestPos;
		end
	end
	self:RefreshTeam( self.m_pTeam );
end

function CSecretMatchWnd:ClickReady()
	local NetMsg = CChangeMatchReady:new();
	NetMsg.nTeamID = self.m_pTeam.nTeamID;
	g_App:SendShellMsg( NetMsg );
end

function CSecretMatchWnd:ShowThreeChoicesWnd2( nClickPos )
	g_App:MessageBox3( g_App:GetString( "sirenfangjiantips3" ),
		{
		[CMessageBox3.First] = function()	--换位子
	        g_App.m_pMessageBox3:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local SelfInfo = self:GetSelfInfo();
			local NetMsg = CQueryChangeMatchPos:new();
			NetMsg.nTeamID = self.m_pTeam.nTeamID;
			NetMsg.nRequestPos = SelfInfo.nPos;
			NetMsg.nResponsePos = nClickPos;
			g_App:SendShellMsg( NetMsg );
		end;
		[CMessageBox3.Second] = function()		--踢人
	        g_App.m_pMessageBox3:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local NetMsg = CMatchPosHandle:new();
			NetMsg.nTeamID = self.m_pTeam.nTeamID;
			NetMsg.nType = eMPH_Kick;
			NetMsg.nPos = nClickPos;
			pConn:SendShellMsg( NetMsg );
		end;
		[CMessageBox3.Third] = function()		--什么也不做
	        g_App.m_pMessageBox3:ShowWnd( false );
		end;
		}, g_App:GetString( "huanweizhi" ), g_App:GetString( "tiren" ), g_App:GetString( "sirenfangjiantips6" ) );
end

function CSecretMatchWnd:ShowThreeChoicesWnd( nClickPos )
	g_App:MessageBox3( g_App:GetString( "sirenfangjiantips3" ),
		{
		[CMessageBox3.First] = function()		--换位子
	        g_App.m_pMessageBox3:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local SelfInfo = self:GetSelfInfo();
			local NetMsg = CQueryChangeMatchPos:new();
			NetMsg.nTeamID = self.m_pTeam.nTeamID;
			NetMsg.nRequestPos = SelfInfo.nPos;
			NetMsg.nResponsePos = nClickPos;
			g_App:SendShellMsg( NetMsg );
		end;
		[CMessageBox3.Second] = function()		--添加AI
	        g_App.m_pMessageBox3:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local NetMsg = CMatchPosHandle:new();
			NetMsg.nTeamID = self.m_pTeam.nTeamID;
			NetMsg.nType = eMPH_AddPC;
			NetMsg.nPos = nClickPos;
			pConn:SendShellMsg( NetMsg );
		end;
		[CMessageBox3.Third] = function()		--封印座位
	        g_App.m_pMessageBox3:ShowWnd( false );
			local pConn = g_App:GetWorldConn();
			if not pConn then
				return;
			end
			local NetMsg = CMatchPosHandle:new();
			NetMsg.nTeamID = self.m_pTeam.nTeamID;
			NetMsg.nType = eMPH_Disable;
			NetMsg.nPos = nClickPos;
			pConn:SendShellMsg( NetMsg );
		end;
		}, g_App:GetString( "huanweizhi" ), g_App:GetString( "tianjiaai" ), g_App:GetString( "fengyin" ) );
end

function CSecretMatchWnd:OnStartMatch()
	if not self.m_nTeamID or self.m_nTeamID == 0 then
		return;
	end
    if self:GetSelfInfo().bCaptain then
	    local NetMsg = CStartMatchTeam:new();
	    g_App:SendShellMsg( NetMsg );
        if self.nTeamType == eMRT_LimitSecret then
            g_App:WaitMsg( true );
        end
    else
		g_App:HideMsg( CStringConfig.Inst():GetString( "tuanduitishi2" ) );
    end
end

function CSecretMatchWnd:OnClickSwitchSkill( Event )
	local pSkillWnd = g_App:GetGameStart().m_pWndSkillDevelop;
	pSkillWnd:ShowAndSetFocus();
end

function CSecretMatchWnd:Observe( nFriendID )
	local NetMsg = CObserveGame:new();
    NetMsg.m_nAccountID = nFriendID;
	NetMsg.m_nRaceRoomID = 0;
	g_App:SendShellMsg( NetMsg );
end

function CSecretMatchWnd:OnClickHelp()
	local nRoomType = eRT_LimitSecret;
	if self.nTeamType == eMRT_LimitSecret then
		g_App:GetGameStart().m_pWndTip:ShowTipWnd( eShowTipType_LimitSecret );
	elseif self.nTeamType == eMRT_TeamSecret then
		g_App:GetGameStart().m_pWndTip:ShowTipWnd( eShowTipType_TeamSecret );
	end
end

function CSecretMatchWnd:OnClickTick()
	local SelfInfo = self:GetSelfInfo();
	local nTimeCount = CSnakeConstant:Inst():GetHandlePosTime();
	if SelfInfo.bCaptain then
		self.m_bCanClick = true;
		self.m_tickClick:Stop();
	end
	if self.m_tickClick:GetTickCount() >= nTimeCount / 1000 then
		self.m_bCanClick = true;
		self.m_tickClick:Stop();
	end
end

function CSecretMatchWnd:OnWorldMsgCooldown( Event )
	if Event.m_szLeftTimeText then
		self.m_pBtnCopy:EnableWnd( false );		
		self.m_pBtnCopy:SetWndText( Event.m_szLeftTimeText );
	else
		self.m_pBtnCopy:EnableWnd( true );		
		self.m_pBtnCopy:SetWndText( CStringConfig.Inst():GetString( "yaoqingwanjia" ) );
	end
end

function CSecretMatchWnd:OnCopyTeamCode()
	local bTeam = self.nTeamType == eMRT_TeamSecret;
	local szName = bTeam and "kuaisuyaoqing4" or "kuaisuyaoqing3";
	local szText = CStringConfig.Inst():GetString( szName )
	local nRoomNum = tonumber( self.m_pTeamID:GetWndText() );
	local szContent = string.format( szText, nRoomNum );
	local szHyplink = "joinroom "..self.nTeamType.." "..nRoomNum;
	local szMsg = "#u#c("..szHyplink..")"..szContent.."#c()";
	g_App:GetInstantMessageDataMgr():SendMsg( 0, szMsg );
end

--endregion
