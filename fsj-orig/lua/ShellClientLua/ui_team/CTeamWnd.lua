--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CTeamCodeWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CTeamCodeWnd:OnCreated()
	self.m_pBtnOK = self:GetDlgChild( "B_ok" );
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pCode = self:GetDlgChild( "W_bianma" );
	self.m_pBtnOK:AddActionListener( "OnOK", self );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
	self.m_pWndTitle = self:GetDlgChild( "bg_tishi" );
end

function CTeamCodeWnd:Show( nType )
	self.nTeamType = nType;
	local str = CStringConfig:Inst():GetString( "shuruduiwu" );
	if self.nTeamType == eMRT_LimitSecret or self.nTeamType == eMRT_TeamSecret then
		str = CStringConfig:Inst():GetString( "shurusiren" );
	end
	self.m_pWndTitle:SetWndText( str );
    self:ShowAndSetFocus();
    self.m_pCode:SetWndText( "" );
end

function CTeamCodeWnd:OnClose()
	self:ShowWnd( false );
end

function CTeamCodeWnd:OnOK()
    local ID = tonumber( self.m_pCode:GetWndText() );
    if ID == nil then
        return;
    end
	local NetMsg = CJoinTeam:new();
    NetMsg.nTeamID = ID;
    NetMsg.nTeamType = self.nTeamType;
	g_App:SendShellMsg( NetMsg );
    self:ShowWnd( false );
end

function CTeamMatchingWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CTeamMatchingWnd:OnCreated()
	self.m_pBtnClose = self:GetDlgChild( "close" );
    self.m_pTime = self:GetDlgChild( "time" );
	self.m_pWndTips = self:GetDlgChild( "tishi" );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
    self.m_pMemberNames = {};
    self.m_pMemberHeads = {};
    self.m_pMemberLevels = {};
	self.m_pMemberSkills = {};
	self.m_pMemberSkillIcons = {};
	self.m_pMemberSkillNames = {};
    for i = 0, 3, 1 do
        local p = self:GetDlgChild( "head" ):GetDlgChild( "head" .. tostring( i + 1 ) );
        self.m_pMemberNames[i] = p:GetDlgChild( "name" );
        self.m_pMemberHeads[i] = p:GetDlgChild( "wanjia.touxiang" );
        self.m_pMemberLevels[i] = p:GetDlgChild( "duanwei" );
		self.m_pMemberSkills[i] = p:GetDlgChild( "jineng" );
		self.m_pMemberSkillIcons[i] = CRichIconWnd:new( p, "jineng.tietu" );
		self.m_pMemberSkillNames[i] = p:GetDlgChild( "jineng.name" );

        self.m_pMemberLevels[i].pText = self.m_pMemberLevels[i]:GetDlgChild( "W_duanwei" );
        self.m_pMemberLevels[i].pIcons = {};
        for j = 1, 8, 1 do
            self.m_pMemberLevels[i].pIcons[j] = self.m_pMemberLevels[i]:GetDlgChild( "icon_duanwei." .. tostring( j ) );
        end
    end
	self.m_tick = CTick:new( "OnTick", self );
end

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

local tblTips = {	"jinengtuanzhuantips1", 
					"jinengtuanzhuantips2",
					"jinengtuanzhuantips3" };

function CTeamMatchingWnd:Show( members, memberCount, isLeader )
	local nIndex = math.random( 1, table.count( tblTips ) );
	self.m_pWndTips:SetWndText( g_App:GetString( tblTips[nIndex] ) );
	self:ShowAndSetFocus();
    for i = 0, memberCount - 1, 1 do
        local member = members[i];
        CHeadIconConfig:Inst():SetIcon( self.m_pMemberHeads[i], member.nCurHeadIcon + 1,member.nAccountID );
        self.m_pMemberHeads[i]:ShowWnd( true );
        self.m_pMemberNames[i]:SetWndText( member.szName );

        self.m_pMemberLevels[i]:ShowWnd( true );
        self.m_pMemberLevels[i].pText:SetWndText( CStarLevelConfig:Inst():GetName( member.nCurLadderStar ) );
        local nLevel = CStarLevelConfig:Inst():GetLevel( member.nCurLadderStar );
        nLevel = tblLadder[nLevel];

		self.m_pMemberSkills[i]:ShowWnd( true );
		self.m_pMemberSkillNames[i]:SetWndText( g_tblTabFile.skill[member.nSkillID].dName );
		self.m_pMemberSkillIcons[i]:SetIconID( g_tblTabFile.skill[member.nSkillID].nIconID );

        for j = 1, 8, 1 do
            self.m_pMemberLevels[i].pIcons[j]:ShowWnd( j == nLevel );
        end
    end
    for i = memberCount, 3, 1 do
        self.m_pMemberHeads[i]:RestoreImageFromCreateParam();
        self.m_pMemberNames[i]:SetWndText( "" );
        self.m_pMemberLevels[i]:ShowWnd( false );
		self.m_pMemberSkills[i]:ShowWnd( false );
    end

    self.m_pBtnClose:ShowWnd( isLeader );

    self.m_nTime = 0;
    self:RefreshTime();
    self.m_tick:Start( 1000 );
end

function CTeamMatchingWnd:OnTick()
    self.m_nTime = self.m_nTime + 1;
    self:RefreshTime();
end

function CTeamMatchingWnd:RefreshTime()
    local sec = self.m_nTime % 60;
    local minute = math.floor( self.m_nTime / 60 );

    local str = tostring( sec % 10 );
    str = ":" .. tostring( math.floor( sec / 10 ) ) .. str;
    str = tostring( minute ) .. str;
    if minute < 10 then
        str = "0" .. str;
    end

    self.m_pTime:SetWndText( str );
end

function CTeamMatchingWnd:OnClose()
	self:ShowWnd( false );
	local NetMsg = CStopMatchTeam:new();
	g_App:SendShellMsg( NetMsg );
end

function CTeamMatchingWnd:OnWndShow( bShowWnd )
    if not bShowWnd then
        self.m_tick:Stop();
    end
end

function CTeamWnd:Ctor( szResName, wndParent, nLoadType, nTeamType )
    self.nTeamType = nTeamType;
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CTeamWnd:OnCreated()
	-- 设置wifi 
	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};
	self.m_timeTick =  CTick:new("OnTimeTick", self );
	
	self.m_wndGoldCount = self:GetDlgChild( "jinbi.jinbishuliang" );
	self.m_pBtnAddMoney = self:GetDlgChild( "jinbi.btn_add" );
	self.m_pBtnAddMoney:AddActionListener( "OnClickAddMoney", self );--增加金币

	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_pBtnTeamMatch = self:GetDlgChild( "zuobian_btn.btn_1" );
	self.m_pBtnTeamSecret = self:GetDlgChild( "zuobian_btn.btn_2" );
	self.m_pBtnTeamMatch:AddActionListener( "ChooseMatchRoom", self );
	self.m_pBtnTeamSecret:AddActionListener( "ChooseMatchRoom", self );

    self.m_pTeamCodeWnd = CTeamCodeWnd:new( "gui/cfg/fsj_tuanzhan_duiwuma.gui", self, 1 );
    self.m_pTeamCodeWnd.nTeamType = self.nTeamType;
    self.m_pTeamMatchingWnd = CTeamMatchingWnd:new( "gui/cfg/fsj_pipei.gui", self, 1 );

	self.m_pBtnClose:AddActionListener( "OnClose", self );

	self.m_btnIM = self:GetDlgChild("liaotian");
	self.m_descWorld = self.m_btnIM:GetDlgChild("neirong");
	self.m_descFriend = self.m_btnIM:GetDlgChild("hongdian");
	self.m_btnIM:AddEventListener( GM_WM_MOUSECLICK, "OnClickIM", g_App.m_GameStart );
	self.m_descWorld:SetInertiaType( eInertiaType_HScroll );

    if self.nTeamType == eMRT_Limit then
	    self.m_pTeamMatchWnd = CTeamMatchWnd:new( "gui/cfg/fsj_xianshi_zujianduiwu.gui", self, 0, eMRT_Limit );
		self.m_pTeamSecretMatchWnd = CSecretMatchWnd:new( "gui/cfg/fsj_xianshi_siren.gui", self, 0, eMRT_LimitSecret );
    elseif self.nTeamType == eMRT_Team then
	    self.m_pTeamMatchWnd = CTeamMatchWnd:new( "gui/cfg/fsj_tuanzhan_zujianduiwu.gui", self, 0, eMRT_Team );
		self.m_pTeamSecretMatchWnd = CSecretMatchWnd:new( "gui/cfg/fsj_tuanzhan_siren.gui", self, 0, eMRT_TeamSecret );
    end
	self.m_pTeamMatchWnd:ShowWnd( true );
	self.m_pTeamSecretMatchWnd:ShowWnd( false );
	self.m_pBtnTeamMatch:SetCheck( true );

	self:UpdateIMDesc();
		
	g_App.m_EventDispatcher:AddEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
end

function CTeamWnd:OnDestroy()
	self.m_timeTick:Stop();
	self.m_timeTick = nil;
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
	CGWnd.OnDestroy( self );
end

function CTeamWnd:UpdateIMDesc()
	local IMMgr = g_App:GetInstantMessageDataMgr();
	self.m_descWorld:SetWndText( IMMgr:GetWorldMessageContentLast() );
	
	local nCount = math.min( IMMgr:GetFriendUnReadCount(), 99 );
	self.m_descFriend:ShowWnd( nCount ~= 0 );
	self.m_descFriend:SetWndText( nCount );
end

function CTeamWnd:OnImShow( bShow )
	if bShow then
		self.m_btnIM:ShowWnd( false );
	else
		self.m_btnIM:ShowWnd( true );
	end
end

function CTeamWnd:OnTimeTick()
	if not g_App or not g_App:GetWorldConn() then 
		return ;
	end  
	--wifi 由弱到强
	local wifi = g_App:GetWorldConn():GetPingDelay();

	local nIconShowed = wifi <ePing_low and 3 or (wifi >ePing_high and 1 or 2)
	for k, v in pairs ( self.m_wifiIcon ) do 
		self.m_wifiIcon[k]:ShowWnd (k==nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild("wangsu"):SetWndText(wifi);
	end 

	local nCoinCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Gold );
	self.m_wndGoldCount:SetWndText( tostring( nCoinCount ) );
end 

function CTeamWnd:OnClickAddMoney()
	g_App:HideMsg(g_App:GetString( "gongnengtips" ));
end 

function  CTeamWnd:OnWndShow(bshow)
	if 	bshow then 
		self.m_timeTick:Start(100);
		self:ShowMatchRoom();
	else 
		self.m_timeTick:Stop();
	end 
end 

function CTeamWnd:OnClose()
	self:ShowWnd( false );
    
	local NetMsg = CLeaveTeam:new();
    NetMsg.bCreateNewTeam = false;
	g_App:SendShellMsg( NetMsg );
end

function CTeamWnd:OnCreateTeamResult( nTeamID )
    g_App:GetGameStart():ShowPage( self );
end

function CTeamWnd:OnSyncTeamInfo( pTeam )
    g_App:GetGameStart():ShowPage( self );
	self.m_pTeam = pTeam;
	if self.m_pTeam.nType == eMRT_Limit or self.m_pTeam.nType == eMRT_Team then		
		self.m_pBtnTeamMatch:SetCheck( true );
		self.m_pTeamMatchWnd:RefreshTeam( self.m_pTeam );
	elseif self.m_pTeam.nType == eMRT_LimitSecret or self.m_pTeam.nType == eMRT_TeamSecret then
		self.m_pBtnTeamSecret:SetCheck( true );
		self.m_pTeamSecretMatchWnd:RefreshTeam( self.m_pTeam );
	end
	self:ShowMatchRoom();
end

function CTeamWnd:OnStartMatch()
    self.m_pTeamMatchingWnd:Show( self.m_pTeamMatchWnd.m_members, self.m_pTeamMatchWnd.m_nMemberCount, self.m_pTeamMatchWnd:IsLeader() );
end

function CTeamWnd:OnStopMatch()
    self.m_pTeamMatchingWnd:ShowWnd( false );
end

function CTeamWnd:ChooseMatchRoom()
	if not g_App:CouldUseSkill() then
		self.m_pBtnTeamMatch:SetCheck( true );
		g_App:HideMsg( g_App:GetString( "kaiqituanzhanhoukaifang" ) );
		return;
	end

	if self.m_pBtnTeamMatch:GetCheck() and self.m_pTeam then
		self.nTeamType = (( self.nTeamType == eMRT_LimitSecret or self.nTeamType == eMRT_Limit ) and eMRT_Limit or eMRT_Team );
		local Type = (( self.nTeamType == eMRT_LimitSecret or self.nTeamType == eMRT_Limit ) and eRT_LimitTime or eRT_Team );
		if not self.m_pTeamMatchWnd:IsShow() then
			local NetMsg = CLeaveTeam:new();
			NetMsg.bCreateNewTeam = false;
			g_App:SendShellMsg( NetMsg );

			g_App:EnterRoom( Type );
		end
		self.m_pTeamMatchWnd:ShowWnd( true );
		self.m_pTeamSecretMatchWnd:ShowWnd( false );
		self.m_pTeamMatchWnd:RefreshTeam( self.m_pTeam );
	elseif self.m_pBtnTeamSecret:GetCheck() and self.m_pTeam then		--选择进入私密房间
		self.nTeamType = (( self.nTeamType == eMRT_Limit or self.nTeamType == eMRT_LimitSecret ) and eMRT_LimitSecret or eMRT_TeamSecret );
		local Type = (( self.nTeamType == eMRT_Limit or self.nTeamType == eMRT_LimitSecret ) and eRT_LimitSecret or eRT_TeamSecret );
		if not self.m_pTeamSecretMatchWnd:IsShow() then
			local NetMsg = CLeaveTeam:new();
			NetMsg.bCreateNewTeam = false;
			g_App:SendShellMsg( NetMsg );

			g_App:EnterRoom( Type );
		end
		self.m_pTeamMatchWnd:ShowWnd( false );
		self.m_pTeamSecretMatchWnd:ShowWnd( true );
		local nShowTipType = eShowTipType_LimitSecret;
		if self.nTeamType == eMRT_TeamSecret then
			nShowTipType = eShowTipType_TeamSecret;
		end
		if g_App:GetIniFile():GetInteger( "Setting", "GameStartTipWnd"..nShowTipType, 1 ) == 1  then
			g_App:GetGameStart().m_pWndTip:ShowTipWnd( nShowTipType );
		end
		self.m_pTeamSecretMatchWnd:RefreshTeam( self.m_pTeam );
	end
end

function CTeamWnd:ShowMatchRoom()
	if not self.m_pTeam then
		return;
	end
	if self.m_pTeam.nType == eMRT_Limit or self.m_pTeam.nType == eMRT_Team then
		self.m_pTeamMatchWnd:ShowWnd( true );
		self.m_pTeamSecretMatchWnd:ShowWnd( false );
		self.m_pBtnTeamMatch:SetCheck( true );
		self.m_pTeamMatchWnd:RefreshTeam( self.m_pTeam );
	elseif self.m_pTeam.nType == eMRT_LimitSecret or self.m_pTeam.nType == eMRT_TeamSecret then
		self.m_pTeamMatchWnd:ShowWnd( false );
		self.m_pTeamSecretMatchWnd:ShowWnd( true );
		self.m_pBtnTeamSecret:SetCheck( true );
		self.m_pTeamSecretMatchWnd:RefreshTeam( self.m_pTeam );
	end
end

function CTeamWnd:ChangeReady( nType, nAccountID, bReady )
	if nType == eMRT_LimitSecret or nType == eMRT_TeamSecret then
		self.m_pTeamSecretMatchWnd:ChangeReady( self.nAccountID, self.bReady );
	end
end
--endregion
