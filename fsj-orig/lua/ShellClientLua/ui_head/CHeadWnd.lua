local s_nStarIconID = 1;
local s_nStar2IconID = 3;
local eSelect = { History = 1, Today = 2, Week = 3 };

function CHeadWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CHeadWnd:OnCreated()
	self.m_wifiIcon				= {	self:GetDlgChild("wifi.icon_3"),
									self:GetDlgChild("wifi.icon_2"),
									self:GetDlgChild("wifi.icon_1")};

	self.m_pBtnAccount			=	self:GetDlgChild( "btn_zuo.btn_1" );
	self.m_pBtnlevel			=	self:GetDlgChild( "btn_zuo.btn_2" );
	self.m_pBtnGrade			=	self:GetDlgChild( "btn_zuo.btn_3" );
	self.m_pBtnClose			=	self:GetDlgChild( "close" );
	self.m_pWndMoney			=	self:GetDlgChild( "jinbi.jinbishuliang" );
	self.m_pBtnAddMoney			=	self:GetDlgChild( "jinbi.btn_add" );

	self.m_pWndAccount			=	self:GetDlgChild( "zhanghao" );
	self.m_pWndAccountId		=	self:GetDlgChild( "zhanghao.wanjiaxinxi.w_id" );
	self.m_pWndAccountName		=	self:GetDlgChild( "zhanghao.wanjiaxinxi.name" );
	self.m_pBtnHead				=	self:GetDlgChild( "zhanghao.wanjiaxinxi.head.touxiang" );
	self.m_pBtnAlterName		=	self:GetDlgChild( "zhanghao.wanjiaxinxi.btn_gaiming" );
	self.m_pBtnSound			=	self:GetDlgChild( "zhanghao.wanjiaxinxi.btn_luyin" );
	self.m_pBtnBroadCast		=	self:GetDlgChild( "zhanghao.wanjiaxinxi.btn_guangbo" );
	self.m_pWndIDImg			=	self:GetDlgChild( "zhanghao.wanjiaxinxi.bg_id" );
	self.m_pWndFemale			=	self:GetDlgChild( "zhanghao.wanjiaxinxi.genderandage.nv" );
	self.m_pWndMale				=	self:GetDlgChild( "zhanghao.wanjiaxinxi.genderandage.nan" );
	self.m_pWndUnknownSex		=	self:GetDlgChild( "zhanghao.wanjiaxinxi.genderandage.weizhi" );
	self.m_pWndAge				=	self:GetDlgChild( "zhanghao.wanjiaxinxi.genderandage.nianling" );
	self.m_pWndAreaName			=	self:GetDlgChild( "zhanghao.wanjiaxinxi.dingwei.name" );
	self.m_pWndConstellationName=	self:GetDlgChild( "zhanghao.wanjiaxinxi.xingzuo.name" );
	self.m_pWndConstellation	=	self:GetDlgChild( "zhanghao.wanjiaxinxi.xingzuo" );
	self.m_pWndConstellationIcon=	CRichIconWnd:new( self.m_pWndConstellation, "icon" );
	self.m_pWndSignature		=	self:GetDlgChild( "zhanghao.qianming.neirong" );
	self.m_pBtnSaveSignature	=	self:GetDlgChild( "zhanghao.qianming.baocun" );
	self.m_pBtnQuery			=	self:GetDlgChild( "zhanghao.chakan" );
	self.m_pRefuseFollowers		=	self:GetDlgChild( "zhanghao.btn_ok" );
	self.m_pWndForOther			=	self:GetDlgChild( "zhanghao.qitawanjia" );
	self.m_pBtnAttention		=	self:GetDlgChild( "zhanghao.qitawanjia.guanzhu" );
	self.m_pBtnCommend			=	self:GetDlgChild( "zhanghao.qitawanjia.dianzan" );
	self.m_pBtnObserve			=	self:GetDlgChild( "zhanghao.qitawanjia.guanzhan" );
	self.m_TextBeCommend		=	self:GetDlgChild( "zhanghao.huozan.w_guanzhu" );
	self.m_pFolloweeCount		=	self:GetDlgChild( "zhanghao.guanzhu.w_guanzhu" );
	self.m_pFollowerCount		=	self:GetDlgChild( "zhanghao.fensi.w_guanzhu" );
	self.m_ListPhoto			=	self:GetDlgChild( "zhanghao.zhaopian.tupian" );
	self.m_pBtnAddPicture		=	self:GetDlgChild( "zhanghao.zhaopian.tianjia" );
	self.m_pWndNoPicture		=	self:GetDlgChild( "zhanghao.zhaopian.kong");
	self.m_tblWndLadderIcon		=	{};
	for i = 1, 8 do
		self.m_tblWndLadderIcon[i] = self:GetDlgChild( "zhanghao.icon_duanwei." .. i );
	end
	
	self.m_pWndLevel			=	self:GetDlgChild( "duanwei" );
	self.m_pBtnLeft				=	self:GetDlgChild( "duanwei.btn1" );
	self.m_pBtnRight			=	self:GetDlgChild( "duanwei.btn0" );
	self.m_pWndLegend			=	self:GetDlgChild( "duanwei.chuanshuo" );
	self.m_pWndLegendIcon		=	CRichIconWnd:new( self.m_pWndLegend, "star" );
	self.m_pWndLegendCount		=	self:GetDlgChild( "duanwei.chuanshuo.shuzi" );
	self.m_pWndLevelIcon		=	CRichIconWnd:new( self.m_pWndLevel, "duanweiicon" );
	self.m_pWndLevelName		=	self:GetDlgChild( "duanwei.duanweiname" );
	self.m_pWndLevelDesc		=	self:GetDlgChild( "duanwei.shuoming" );
	self.m_pWndCurLevel			=	self:GetDlgChild( "duanwei.dangqianduanwei" );
	self.m_tblPrize				=	{};
	for i = 1, 3 do
		self.m_tblPrize[i]		=	CRichIconWnd:new( self, "duanwei.jiangli" .. i );
	end
	self.m_tblStar = {};
	
	self.m_pWndGrade			=	self:GetDlgChild( "zhanji" );
	self.m_TextEndlessAll		=	self:GetDlgChild( "zhanji.neirong.zongfen.wujin" )
	self.m_TextEndlessArea		=	self:GetDlgChild( "zhanji.neirong.tiji.wujin" );
	self.m_TextEndlessKillCount =	self:GetDlgChild( "zhanji.neirong.jisha.wujin" );
	self.m_TextEndlessMaxCombo	=	self:GetDlgChild( "zhanji.neirong.lianji.wujin" );
	self.m_TextLimitAll			=	self:GetDlgChild( "zhanji.neirong.zongfen.xianshi" );
	self.m_TextLimitArea		=	self:GetDlgChild( "zhanji.neirong.tiji.xianshi" );
	self.m_TextLimitKillCount	=	self:GetDlgChild( "zhanji.neirong.jisha.xianshi" );
	self.m_TextLimitMaxCombo	=	self:GetDlgChild( "zhanji.neirong.lianji.xianshi" );
	self.m_TextTeamAll			=	self:GetDlgChild( "zhanji.neirong.zongfen.tuanzhan" );
	self.m_TextTeamArea			=	self:GetDlgChild( "zhanji.neirong.tiji.tuanzhan" );
	self.m_TextTeamKillCount	=	self:GetDlgChild( "zhanji.neirong.jisha.tuanzhan" );
	self.m_TextTeamMaxCombo		=	self:GetDlgChild( "zhanji.neirong.lianji.tuanzhan" );
	self.m_btnSelect = {};
	for i = 1, 3 do
		self.m_btnSelect[i]		=	self:GetDlgChild( "zhanji.btn_top.btn" .. i ); 
	end
	self.m_nSelect				=	eSelect.History;
	self.m_btnSelect[self.m_nSelect]:SetCheck( true );
	for i = 1, 3 do
		self.m_btnSelect[i].m_nSelect = i;
		self.m_btnSelect[i]:AddActionListener( "OnClickSelect", self );
	end

	self.m_pWndAlterName		=	CWndAlterName:new( "gui/cfg/fsj_zhujuexinxi_mingming.gui", self, 2 );
	self.m_pWndChangeHeadIcon	=	CWndChangeHeadIcon:new( "gui/cfg/fsj_zhujuexinxi_touxiangxiugai.gui", self, 2 );
	self.m_pwndCutPicture		=	CWndCutPicture:new( "gui/cfg/fsj_shangchuantupian.gui", self, 2 );

	self.m_pBtnAddMoney:AddActionListener( "AddMoneyAnswer",self );
	self.m_pBtnlevel:AddActionListener( "OnClickLevel", self );
	self.m_pBtnGrade:AddActionListener( "OnClickGrade", self );
	self.m_pBtnClose:AddActionListener( "OnClickClose", self );
	self.m_pBtnAccount:AddActionListener( "OnClickAccount", self );

	self.m_pBtnAlterName:AddActionListener( "OnClickAlterName", self );
	self.m_pBtnHead:AddClickListener( "OnClickAlterHead", self );
	self.m_pRefuseFollowers:AddActionListener( "OnRefuseFollowers", self );
	self.m_pBtnSaveSignature:ShowWnd( false );
	self.m_pBtnSaveSignature:AddActionListener( "OnClickSaveSignature", self );
	self.m_pWndSignature:AddClickListener( "OnClickSignature", self );

	self.m_pBtnObserve:AddActionListener( "OnObserveGame", self );
	self.m_pBtnAttention:AddActionListener( "OnAttention", self );
	self.m_pBtnCommend:AddActionListener( "OnCommend", self );

	self.m_pBtnLeft:AddActionListener( "OnClickLeft",self );
	self.m_pBtnRight:AddActionListener( "OnClickRight", self );
	self.m_pBtnAddPicture:AddActionListener( "OnAddPicture", self );
	self.m_pWndLegendIcon:SetIconID( s_nStarIconID );
	self.m_pWndAccount:ShowWnd( false );
	self.m_pWndLevel:ShowWnd( false );
	self.m_pWndGrade:ShowWnd( false );
	self.m_pWndForOther:ShowWnd( false );
	self.m_pWndSignature:SetMaxStringLength( Char_Signature_Byte_Size );
	self.m_ListPhoto:SetInertiaType( eInertiaType_HScroll );

	g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "OnAddFollowee", self );
	g_App.m_EventDispatcher:AddEventListener( "ChangeHeadIcon", "RefreshHeadIcon", self );
    g_App.m_EventDispatcher:AddEventListener( "PlayerBaseData", "RefreshBaseData", self );
    g_App.m_EventDispatcher:AddEventListener( "RelationshipCount", "RefreshFriendCount", self );
	g_App.m_EventDispatcher:AddEventListener( "PlayerGradeRecordNew", "OnPlayerGradeRecordNew", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshPhotoList", "InitPhotoList", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.NickName", "RefreshWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.Sex", "RefreshWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.Age", "RefreshWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.Constellation", "RefreshWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.Area", "RefreshWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_DayCommendData", "OnAddCommend", self );

	self.m_timeTick = CTick:new ( "OnTimeTick", self );
end

function CHeadWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
	g_App.m_EventDispatcher:RemoveEventListener( "ChangeHeadIcon", "RefreshHeadIcon", self );
    g_App.m_EventDispatcher:RemoveEventListener( "PlayerBaseData", "RefreshBaseData", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RelationshipCount", "RefreshFriendCount", self );
	g_App.m_EventDispatcher:RemoveEventListener( "PlayerGradeRecordNew", "OnPlayerGradeRecordNew", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshPhotoList", "InitPhotoList", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.NickName", "RefreshWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.Sex", "RefreshWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.Age", "RefreshWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.Constellation", "RefreshWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.Area", "RefreshWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_DayCommendData", "OnAddCommend", self );
	self.m_timeTick:Stop();
	if self.m_tickCheckPicture then
		self.m_tickCheckPicture:Stop();
	end
	CGWnd.OnDestroy( self );
	self.m_pPictureData = nil;
end

function CHeadWnd:OnWndShow( bShow )
	if bShow then
		self.m_timeTick:Start( 33 );
	else
		self.m_timeTick:Stop();
	end
end

function CHeadWnd:OnClickClose()
	self:ShowWnd( false );
end

function CHeadWnd:OnTimeTick( )
   if not g_App or not g_App:GetWorldConn() then
		return;
	end
	local wifi = g_App:GetWorldConn():GetPingDelay();
	if not wifi then return end

	local nIconShowed = wifi < ePing_low and 3 or ( wifi > ePing_high and 1 or 2 );
	for k, v in pairs( self.m_wifiIcon ) do
		self.m_wifiIcon[k]:ShowWnd( k == nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild( "wangsu" ):SetWndText( wifi );
	end
	local nCoinCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Gold );
	self.m_pWndMoney:SetWndText( nCoinCount );
end

function CHeadWnd:ShowPlayerInfo( nAccountID )
	self:ShowWnd( true );
	self.m_nAccountID = nAccountID;
	self:OnClickAccount();
end

function CHeadWnd:AddMoneyAnswer()
	g_App:HideMsg( g_App:GetString( "gongnengtips" ) );
end

function CHeadWnd:OnRefuseFollowers()
	local NetMsg = CSetRefuseFollowers:new();
    NetMsg.bRefuse = self.m_pRefuseFollowers:GetCheck() and 1 or 0;
	g_App:SendShellMsg( NetMsg );
end

function CHeadWnd:OnClickAccount()
	if not self.m_nAccountID then return end
	g_App:WaitMsg( true );
	local worldConn = g_App:GetWorldConn();
	if not worldConn then return end;
	self.m_pWndAccount:ShowWnd( false );
	self.m_pWndLevel:ShowWnd( false );
	self.m_pWndGrade:ShowWnd( false );
	local NetMsg = CQueryPlayerBaseData:new();
	NetMsg.m_nAccountID = self.m_nAccountID;
	worldConn:SendShellMsg( NetMsg );
	self.m_pBtnAccount:SetCheck( true );
	local NetMsg1 = CQueryRelationshipCount:new();
	NetMsg1.m_nAccountID = self.m_nAccountID;
	g_App:SendShellMsg( NetMsg1 );
	self:CheckBeSelf( self.m_nAccountID == g_App:GetAccountID() );
end

function CHeadWnd:CheckBeSelf( bSelf )
	self.m_pWndAccountId:ShowWnd( bSelf );
	self.m_pWndIDImg:ShowWnd( bSelf );
	self.m_pWndForOther:ShowWnd( not bSelf );
	self.m_pBtnQuery:ShowWnd( bSelf );
	self.m_pRefuseFollowers:ShowWnd( bSelf );
	self.m_pBtnAlterName:ShowWnd( bSelf );
	self.m_pBtnHead:EnableWnd( bSelf );
	self.m_pBtnAddPicture:ShowWnd( bSelf );
	self.m_pBtnSaveSignature:ShowWnd( bSelf );
	self.m_pWndSignature:EnableWnd( bSelf );
	if not bSelf then
		self.m_pWndSignature:SetStyle( eES_READONLY );
	end
end

function CHeadWnd:RefreshBaseData( Event )
	g_App:WaitMsg( false );
	self.m_pWndAccount:ShowAndSetFocus();
	self.m_pWndLevel:ShowWnd( false );
	self.m_pWndGrade:ShowWnd( false );
	self.m_pBtnAccount:SetCheck( true );
	self.m_tblBaseData = Event.m_Param;
	self.m_TextBeCommend:SetWndText( self.m_tblBaseData.nBeCommendCount );
	self.m_pWndMale:ShowWnd( self.m_tblBaseData.nSex == eSexType_Male );
	self.m_pWndFemale:ShowWnd( self.m_tblBaseData.nSex == eSexType_Female );
	self.m_pWndUnknownSex:ShowWnd( self.m_tblBaseData.nSex == eSexType_UnKnown );
	self.m_pWndAge:SetWndText( self.m_tblBaseData.nAge );
	self.m_pWndConstellationName:SetWndText( g_tblTabFile.constellation[self.m_tblBaseData.nConstellation].dName );
	self.m_pWndConstellationIcon:SetIconID( g_tblTabFile.constellation[self.m_tblBaseData.nConstellation].nIconID );
	self.m_pWndAreaName:SetWndText( g_tblTabFile.area[self.m_tblBaseData.nArea].dName  );
	self.m_pWndSignature:SetWndText( self.m_tblBaseData.szSignature );
	self:RefreshWnd();
end

function CHeadWnd:RefreshHeadIcon()
    CHeadIconConfig:Inst():SetIcon( self.m_pBtnHead, g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1, g_App:GetAccountID() );
end

function CHeadWnd:RefreshWnd()
	if not self.m_tblBaseData then return end
	local szShowID = g_App:GetShowAccountID();
	if tonumber( szShowID ) == 0 then
		szShowID = g_App:GetString( "weilianwang" );
	end
	self.m_pWndAccountId:SetWndText( szShowID );
	if self.m_nAccountID == g_App:GetAccountID() then
		self.m_tblBaseData["szName"]			= g_App:GetNickName();
		self.m_tblBaseData["nHeadIcon"]			= g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
		self.m_tblBaseData["nLadderStarCount"]	= g_App:GetCurLadderStar();
		self.m_tblBaseData["nSex"]				= g_App:GetMainPlayerData().m_CharBaseData:GetSex();
		self.m_tblBaseData["nAge"]				= g_App:GetMainPlayerData().m_CharBaseData:GetAge();
		self.m_tblBaseData["nConstellation"]	= g_App:GetMainPlayerData().m_CharBaseData:GetConstellation();
		self.m_tblBaseData["nArea"]				= g_App:GetMainPlayerData().m_CharBaseData:GetArea();
		self.m_tblBaseData["szSignature"]		= g_App:GetMainPlayerData().m_CharBaseData:GetSignature();
	else
		self:SetButtonText();
	end

	if self.m_tblBaseData["szSignature"] == "" then
		self.m_tblBaseData["szSignature"] = g_App:GetString( "morenqianming" );
	end

	self.m_pWndAccountName:SetWndText( self.m_tblBaseData.szName );
	CHeadIconConfig:Inst():SetIcon( self.m_pBtnHead, self.m_tblBaseData.nHeadIcon + 1, self.m_nAccountID );
	self.m_pWndMale:ShowWnd( self.m_tblBaseData.nSex == eSexType_Male );
	self.m_pWndFemale:ShowWnd( self.m_tblBaseData.nSex == eSexType_Female );
	self.m_pWndUnknownSex:ShowWnd( self.m_tblBaseData.nSex == eSexType_UnKnown );
	self.m_pWndAge:SetWndText( self.m_tblBaseData.nAge );
	self.m_pWndConstellationIcon:SetIconID( g_tblTabFile.constellation[self.m_tblBaseData.nConstellation].nIconID );
	self.m_pWndConstellationName:SetWndText( g_tblTabFile.constellation[self.m_tblBaseData.nConstellation].dName );
	self.m_pWndAreaName:SetWndText( g_tblTabFile.area[self.m_tblBaseData.nArea].dName );
	self.m_pWndSignature:SetWndText( self.m_tblBaseData.szSignature );
	local nCurLadderLevel =  CStarLevelConfig.Inst():GetBigLevel(self.m_tblBaseData.nLadderStarCount );
	for i = 1, 8 do
		self.m_tblWndLadderIcon[i]:ShowWnd( i == nCurLadderLevel );
	end
	self.m_pRefuseFollowers:SetCheck( CFriendMgr:Inst().m_bRefuseFollowers );
	self:InitPhotoList();
end

function CHeadWnd:InitPhotoList()
	if not self.m_nAccountID then return end;
	self.m_nPhotoCount = 0;
	self.m_ListPhoto:DeleteAllColumn();
	self.m_ListPhoto:DeleteAllItem();
	for i = 1, ePhoto_Max_Count_VIP do
		self.m_ListPhoto:InsertColumn( i - 1, 520 );
	end

	self.m_ListPhoto:InsertRowItemsFromRes( -1, "gui/cfg/fsj_zhaopianitem.gui", CPhotoItem );
	self.m_ListPhoto:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnPhotoListItemLoaded", self );
end

function CHeadWnd:OnPhotoListItemLoaded()
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
	if self.m_nAccountID == g_App:GetAccountID() then
		local NetMsg = CQueryPictureData:new();
		g_App:SendShellMsg( NetMsg );
	end
end

function CHeadWnd:HaveCommend( nAccountID )
	local PlayerData = g_App:GetMainPlayerData().m_DayCommendData;
	for i = 1, PlayerData:GetDataCount() do
		if PlayerData:GetData( i - 1 ) == nAccountID then
			return true;
		end
	end
	return false;
end

function CHeadWnd:SetButtonText()
	if CFriendMgr:Inst():IsFollowee( self.m_nAccountID ) then
		self.m_pBtnAttention:SetWndText(  g_App:GetString( "yiguanzhu" ) );
		self.m_pBtnAttention:EnableWnd( false );
	else
		self.m_pBtnAttention:SetWndText(  g_App:GetString( "guanzhu" ) );
		self.m_pBtnAttention:EnableWnd( true );
	end
	if self:HaveCommend( self.m_nAccountID ) then
		self.m_pBtnCommend:SetWndText( g_App:GetString( "yidianzan" ) );
		self.m_pBtnCommend:EnableWnd( false );
	else
		self.m_pBtnCommend:SetWndText( g_App:GetString( "dianzan" ) );
		self.m_pBtnCommend:EnableWnd( true );
	end
end

function CHeadWnd:RefreshFriendCount( Event )
    self.m_pFolloweeCount:SetWndText( Event.m_nAttentionCount );
    self.m_pFollowerCount:SetWndText( Event.m_nFansCount );
end

function CHeadWnd:OnClickLevel()
	self.m_pWndAccount:ShowWnd( false );
	self.m_pWndLevel:ShowAndSetFocus();
	self.m_pWndGrade:ShowWnd( false );
	self.m_pBtnlevel:SetCheck( true );
	self.m_nLadderLevel = CStarLevelConfig.Inst():GetLevel( self.m_tblBaseData.nLadderStarCount );
	self.m_nLevelHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_tblBaseData.nLadderStarCount );
	self.m_nCurIndex = self.m_nLadderLevel;
	self:UpdateLevelWnd( self.m_nCurIndex, self.m_nLadderLevel, self.m_nLevelHaveStar );
end

function CHeadWnd:OnClickLeft()
	self.m_nCurIndex = self.m_nCurIndex - 1;
	self:UpdateLevelWnd( self.m_nCurIndex, self.m_nLadderLevel, self.m_nLevelHaveStar );
end

function CHeadWnd:OnClickRight()
	self.m_nCurIndex = self.m_nCurIndex + 1;
	self:UpdateLevelWnd( self.m_nCurIndex, self.m_nLadderLevel, self.m_nLevelHaveStar );
end

function CHeadWnd:OnCreatedStarRich( Event )
	local pWnd = Event.m_CurrentTarget;
	local tblInit = pWnd.m_tblInit;

	pWnd:SetWndSize( tblInit.nWidth, tblInit.nHeight );
	pWnd:SetLocalY( tblInit.nGlobalY );
	pWnd:SetLocalX( tblInit.nGlobalX );
end

function CHeadWnd:UpdateLevelWnd( nCurIndex, nLadderLevel, nLevelHaveStar )
	local nMaxLevel = CStarLevelConfig:Inst():GetMaxLevel();
	nCurIndex = math.min( nMaxLevel, math.max( 1, nCurIndex ) );
	local bCurLevel = nCurIndex == nLadderLevel
	for _,pWnd in pairs( self.m_tblStar ) do
		pWnd:DestroyWnd();
	end
	self.m_tblStar = {};
	
	self.m_pBtnLeft:ShowWnd( nCurIndex > 1 );
	self.m_pBtnRight:ShowWnd( nCurIndex < nMaxLevel );
	self.m_pWndLegend:ShowWnd( nCurIndex == nMaxLevel );
	self.m_pWndCurLevel:ShowWnd( bCurLevel );
	local nAllStar = CStarLevelConfig.Inst():GetStarCount( nCurIndex );
	if nCurIndex == nMaxLevel then
		nCurHaveStar = 0;
	else
		nCurHaveStar = CStarLevelConfig.Inst():GetStarOnLevel( nAllStar );
	end

	-- 计算显示星数
	if nCurIndex == nMaxLevel then
		self.m_pWndLegendCount:SetWndText( bCurLevel and nLevelHaveStar or 0 );
	elseif nCurHaveStar ~= 0 then
		local nY = self.m_pWndLegend:GetLocalY();
		local nX = self.m_pWndLevel:GetWndWidth() / 2;
		nX = nX - nCurHaveStar * 65 / 2;
		for i = 1, nCurHaveStar do
			local pWnd = CRichIconWnd:new( self.m_pWndLevel );
			pWnd:AddEventListener( WM_CREATE, "OnCreatedStarRich", self );
			pWnd.m_tblInit =
			{
				["nWidth"] = 65;
				["nHeight"] = 65;
				["nGlobalX"] = nX + 65 * ( i - 1 ) ;
				["nGlobalY"] = nY;
			};
			if bCurLevel then
				pWnd:SetIconID( i > nLevelHaveStar and s_nStar2IconID or s_nStarIconID );
			else
				pWnd:SetIconID( nCurIndex > nLadderLevel and s_nStar2IconID or s_nStarIconID );
			end
			table.insert( self.m_tblStar, pWnd );
		end
	end

	local nIconID = CStarLevelConfig.Inst():GetIconID( nAllStar );
	local szName = CStarLevelConfig.Inst():GetName( nAllStar );
	local szDesc = CStarLevelConfig.Inst():GetDescription( nAllStar );
	self.m_pWndLevelIcon:SetIconID( nIconID );
	self.m_pWndLevelName:SetWndText( szName );
	self.m_pWndLevelDesc:SetWndText( szDesc );

	--奖励
	local tblPrize = SplitStr( CStarLevelConfig:Inst():GetSeasonPrizeStrByLevel( nCurIndex ), "," );
	for i = 1, #self.m_tblPrize do
		self.m_tblPrize[i]:ShowWnd( false );
	end
	for i = 1, #tblPrize do
		local pWnd = self.m_tblPrize[i];
		pWnd:ShowWnd( true );
		local nPrizeID = tblPrize[i];
		local nType = CRewardConfig:Inst():GetType( tonumber( nPrizeID ) );
		local nItemID = CRewardConfig:Inst():GetItemID( tonumber( nPrizeID ) );
		local nCount = CRewardConfig:Inst():GetCount( tonumber( nPrizeID ) );
		local szName = CRewardConfig:Inst():GetName( tonumber( nPrizeID ) );
		local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).nIconID;
		local szName = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).dName;
		pWnd:SetIconID( nIconID );
		pWnd:GetDlgChild("e_cout"):SetWndText( tostring( nCount ) );
		pWnd:GetDlgChild("e_name"):SetWndText( szName );
	end
end

function CHeadWnd:OnClickGrade()
	g_App:WaitMsg( true );
	local worldConn = g_App:GetWorldConn();
	if not worldConn then return end;
	self.m_pWndAccount:ShowWnd( false );
	self.m_pWndLevel:ShowWnd( false );
	self.m_pWndGrade:ShowWnd( false );
	local nAccountID = self.m_nAccountID;
	CPlayerGradeInfoMgr:Instance():QueryAllScoreNewByAccountID( worldConn, nAccountID );
	self.m_pBtnGrade:SetCheck( true );
end

function CHeadWnd:OnPlayerGradeRecordNew()
	g_App:WaitMsg( false );
	self.m_tblDataToday = {};
	self.m_tblDataWeek = {};
	self.m_tblDataHistory = {};
	local tblData = CPlayerGradeInfoMgr:Instance():GetAllDataNew();
	if not tblData then return end;

	self.m_pWndGrade:ShowAndSetFocus();
	self.m_pBtnGrade:SetCheck( true );
	self.m_tblDataToday = tblData.TodayData;
	self.m_tblDataWeek = tblData.WeekData;
	self.m_tblDataHistory = tblData.HistoryData;
	local tblData = self:GetShowData( self.m_nSelect )
	self:SetData( tblData )
end

function CHeadWnd:OnClickSelect( Event )
	self.m_nSelect = Event.m_CurrentTarget.m_nSelect;
	local tblData = self:GetShowData( self.m_nSelect )
	self:SetData( tblData );
end

function CHeadWnd:SetData( Data )
	local nSceneWidthEndless = CSceneList:Inst():GetInfo( eRT_Endless ):GetWidth();
	local nSceneDeepthEndless = CSceneList:Inst():GetInfo( eRT_Endless ):GetDepth();
	local nSceneWidthLimit = CSceneList:Inst():GetInfo( eRT_LimitTime ):GetWidth();
	local nSceneDeepthLimit = CSceneList:Inst():GetInfo( eRT_LimitTime ):GetDepth();
	local nSceneWidthTeam = CSceneList:Inst():GetInfo( eRT_Team ):GetWidth();
	local nSceneDeepthTeam = CSceneList:Inst():GetInfo( eRT_Team ):GetDepth();
	local nEndlessSceneNode = nSceneWidthEndless/16 * nSceneDeepthEndless/16;
	local nLimitSceneNode = nSceneWidthLimit/16 * nSceneDeepthLimit/16;
	local nTeamSceneNode = nSceneWidthTeam/16 * nSceneWidthTeam/16;

	self.m_TextEndlessAll:SetWndText( Data.EndlessAllScore );
	self.m_TextEndlessArea:SetWndText( string.format( "%0.2f%%", Data.EndlessAreaScore * 100/nEndlessSceneNode ) );
	self.m_TextEndlessKillCount:SetWndText( Data.EndlessKillCount );
	self.m_TextEndlessMaxCombo:SetWndText( Data.EndlessMaxCombo );
	self.m_TextLimitAll:SetWndText( Data.LimitAllScore );
	self.m_TextLimitArea:SetWndText( string.format( "%0.2f%%", Data.LimitAreaScore * 100/nLimitSceneNode ) );
	self.m_TextLimitKillCount:SetWndText( Data.LimitKillCount );
	self.m_TextLimitMaxCombo:SetWndText( Data.LimitMaxCombo );
	self.m_TextTeamAll:SetWndText( Data.TeamAllScore );
	self.m_TextTeamArea:SetWndText( string.format( "%0.2f%%", Data.TeamAreaScore * 100/nTeamSceneNode ) );
	self.m_TextTeamKillCount:SetWndText( Data.TeamKillCount );
	self.m_TextTeamMaxCombo:SetWndText( Data.TeamMaxCombo );

end

function CHeadWnd:GetShowData( nSelect )
	local tbl = {};
	if nSelect == eSelect.History then
		tbl = self.m_tblDataHistory;
	elseif nSelect == eSelect.Today then
		tbl = self.m_tblDataToday;
	elseif nSelect == eSelect.Week then
		tbl = self.m_tblDataWeek;
	end	
	return tbl;
end

function CHeadWnd:OnClickAlterName()
	if not g_App:IsGameSwitch( eGameSwitch_Rename ) then
		return g_App:HideMsg( g_App:GetString( "buyunxugaiming" ) );
	end
	self.m_pWndAlterName:ShowWnd( true );
end

function CHeadWnd:OnClickAlterHead()
	self.m_pWndChangeHeadIcon:ShowWnd( true );
end

function CHeadWnd:OnAddPicture()
	if not g_App:IsGameSwitch( eGameSwitch_Picture ) then
		return g_App:HideMsg( g_App:GetString( "gongnengtips" ) );
	end

	if self.m_nPhotoCount then
		local bVip = g_App:GetMainPlayerData():IsVip();
		local nCountMax = bVip and ePhoto_Max_Count_VIP or ePhoto_Max_Count_NO_VIP;
		if self.m_nPhotoCount >= nCountMax then
			return g_App:HideMsg( g_App:GetString( "tupianshuliangshangxian" ) );
		end
		self.m_pPictureData = self.m_pPictureData or CPicture:new();
		self.m_pPictureData:LoadPicture( ePhotoSize );
		if not self.m_tickCheckPicture then
			self.m_tickCheckPicture = CTick:new( "OnCheckPictureLoaded", self );
		end
		self.m_tickCheckPicture:Start( 100 );
	end
end

function CHeadWnd:OnCheckPictureLoaded()
	if self.m_pPictureData:GetShowTexture() then
		self.m_tickCheckPicture:Stop();
		self.m_pwndCutPicture:ShowWndWithType( ePictureType_Photo );
	end
end

function CHeadWnd:IsDispatchPlayerDBEvent()
	return true;
end

function CHeadWnd:OnClickSignature()
	self.m_pBtnSaveSignature:ShowWnd( true );
end

function CHeadWnd:OnClickSaveSignature()
	local szNewSignature = self.m_pWndSignature:GetWndText();
	local szOldSignature =  g_App:GetMainPlayerData().m_CharBaseData:GetSignature();
	if string.len( szNewSignature ) > Char_Signature_Byte_Size then
		return g_App:HideMsg( g_App:GetString( "mingzitaichang" ) );
	elseif not CUSFilter:Inst():CheckString( szNewSignature, Char_Signature_Byte_Size + 1, eFilter_Chat ) then
		return g_App:HideMsg( g_App:GetString( "hanyoufeifazi" ) );
	elseif not g_App:GetWorldConn() then
		return g_App:HideMsg( g_App:GetString( "weilianwang" ) );
	end

	if szNewSignature ~= szOldSignature then
		local NetMsg = CAlterSignature:new();
		NetMsg.m_szNewSignature = szNewSignature;
		g_App:GetWorldConn():SendShellMsg( NetMsg );
	end
	self.m_pBtnSaveSignature:ShowWnd( false );
end


function CHeadWnd:OnObserveGame( bShow )
	local worldConn = g_App:GetWorldConn();
	if not worldConn then
        return;
    end
	local NetMsg = CObserveGame:new();
	NetMsg.m_nAccountID = self.m_nAccountID;
	NetMsg.m_nRaceRoomID = 0;
	worldConn:SendShellMsg( NetMsg );
end

function CHeadWnd:OnAttention()
	local NetMsg = CAddFollowee:new();
    NetMsg.nAccountID = self.m_nAccountID;
	g_App:GetWorldConn():SendShellMsg( NetMsg );
end

function CHeadWnd:OnCommend()
	local worldConn = g_App:GetWorldConn();
	if not worldConn then
        return;
    end
	if self:HaveCommend( self.m_nAccountID ) then
		g_App:HideMsg( g_App:GetString( "yidianzantips" ) );
		return;
	end
	local NetMsg = CAddCommendDay:new();
	NetMsg.nAccountIDTo	  = self.m_nAccountID;
	worldConn:SendShellMsg( NetMsg );
end

function CHeadWnd:OnAddFollowee()
	self.m_pBtnAttention:SetWndText( g_App:GetString( "yiguanzhu" ) );
	self.m_pBtnAttention:EnableWnd( false );
	self.m_pFollowerCount:SetWndText( tonumber( self.m_pFollowerCount:GetWndText() ) + 1 );
end

function CHeadWnd:OnAddCommend()
	self.m_pBtnCommend:SetWndText( g_App:GetString( "yidianzan" ) );
	self.m_pBtnCommend:EnableWnd( false );
	self.m_TextBeCommend:SetWndText( tonumber( self.m_TextBeCommend:GetWndText() ) + 1 );
end

-------------------------------------------------------------------------------
--CWndCutPicture
-------------------------------------------------------------------------------
function CWndCutPicture:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndCutPicture:OnCreated()
	self.m_BtnClose		= self:GetDlgChild( "close" );
	self.m_BtnUpload	= self:GetDlgChild( "btn_ok" );
	self.m_WndPicture	= self:GetDlgChild( "heidi.youxiaoqu.zhaopian" );
	self.m_WndValidZone = self:GetDlgChild( "heidi.youxiaoqu" );
	self.m_nInitWidth	= self.m_WndPicture:GetWndWidth();
	self.m_nInitHeight	= self.m_WndPicture:GetWndHeight();	
	self.m_BtnClose:AddActionListener( "OnClickClose", self );
	self.m_BtnUpload:AddActionListener( "OnClickUpload", self );
    self.m_WndPicture:AddEventListener( GM_WM_DRAGSTART, "OnDragStartEvent", self );
    self.m_WndPicture:AddEventListener( GM_WM_DRAG, "OnDragEvent", self );
    self.m_WndPicture:AddEventListener( GM_WM_DRAGEND, "OnDragEndEvent", self );
    self.m_WndPicture:AddEventListener( WM_MOUSEWHEEL, "OnMouseWheelEvent", self );
end

function CWndCutPicture:OnWndShow( bShow )
	if bShow then
		self:SetFocus();
		self.m_nTouchPoint = 0;
		self.m_tblBeginPos = {};
		self.m_WndPicture:SetFocus();
		self.m_WndPicture:SetLocalX( 0 );
		self.m_WndPicture:SetLocalY( 0 );
		self.m_WndPicture:SetWndSize( self.m_nInitWidth, self.m_nInitHeight );
		local rtImg = CFRect:new( 0, 0, self.m_nInitWidth, self.m_nInitHeight );
		local rtWnd  = CFRect:new( 0, 0, self.m_nInitWidth, self.m_nInitWidth );
		local nFlag = BitOr( IDF_ZOOM_WHILE_SCALE, IDF_ENABLE_ALPHA_BLEND )
		self.m_WndPicture:RestoreImageFromCreateParam();
		self.m_WndPicture:AddImageByTexture( GSM_BS_BK, eST_ENABLE, 0, 
			self:GetParent().m_pPictureData:GetShowTexture(), rtImg, rtWnd, 
			0xffffffff, LOCK_ALL, nFlag, -1, -1, 0, 1, 0 ); 
	else
		self:GetParent().m_pPictureData = nil;
	end
end

function CWndCutPicture:OnDestroy()
end

function CWndCutPicture:ShowWndWithType( nType )
	self.m_nType = nType;
	self:ShowWnd( true );
end

function CWndCutPicture:OnClickClose()
	self:ShowWnd( false );
end

function CWndCutPicture:OnClickUpload()
	--计算图片在有效区域内的边界
	local nPictureWidth = self.m_WndPicture:GetWndWidth();
	local nPictureHeight = self.m_WndPicture:GetWndHeight();
	local nTargetX = self.m_WndPicture:GetLocalX();
	local nTargetY = self.m_WndPicture:GetLocalY();
	local nJpegWidth = self.m_WndValidZone:GetWndWidth();
	local nJpegHeight = self.m_WndValidZone:GetWndHeight();
	local CompressJpeg = CBufferStream:new( nJpegWidth*nJpegHeight*4 );
	local nBufferSize = self:GetParent().m_pPictureData:BuildJpeg( 
		CompressJpeg, nJpegWidth, nJpegHeight,
		nTargetX, nTargetY, nPictureWidth, nPictureHeight );
	if nBufferSize > ePictureType_Max_Size then
		g_App:HideMsg( g_App:GetString( "tupiantaida" ) );
		self:ShowWnd( false );
		return;
	end 
	local NetMsg = CUploadPicture:new();
	NetMsg.m_nPictureType = self.m_nType;
	NetMsg.m_nBufferSize = nBufferSize;
	NetMsg.m_buffer = CompressJpeg;
	g_App:SendShellMsg( NetMsg );
	self:ShowWnd( false );
end

function CWndCutPicture:OnMouseWheelEvent( Event )
	local nCoff = Event.m_wParam/65536 > 32767 and 0.9 or 1.1111111111;
	local nWidth = self.m_WndPicture:GetWndWidth()*nCoff;
	local nHeight = self.m_WndPicture:GetWndHeight()*nCoff;
	if nWidth / self.m_nInitWidth > 2.0 or nWidth / self.m_nInitWidth < 0.5 or 
		nHeight/self.m_nInitHeight > 2.0 or nHeight / self.m_nInitHeight < 0.5 then
			return
	end
	self.m_WndPicture:SetWndSize( nWidth, nHeight )
end

function CWndCutPicture:OnDragStartEvent( Event )
	self.m_nTouchPoint = self.m_nTouchPoint + 1;
	local nInputID = Event.m_Param;
	local Pos = {};
	Pos["nX"] = Event.m_GlobalX;
	Pos["nY"] = Event.m_GlobalY;
	self.m_tblBeginPos[nInputID] = Pos;
	self.m_nDragStartX	= Event.m_GlobalX;
	self.m_nDragStartY	= Event.m_GlobalY;
	self.m_nPictureX	= self.m_WndPicture:GetLocalX();
	self.m_nPictureY	= self.m_WndPicture:GetLocalY();
end

function CWndCutPicture:OnDragEvent( Event )
	if self.m_nTouchPoint == 1 then 
		local nCurX = Event.m_GlobalX - self.m_nDragStartX + self.m_nPictureX;
		local nCurY = Event.m_GlobalY - self.m_nDragStartY + self.m_nPictureY;
		local nLeftBorder = -3 / 4 * self.m_WndPicture:GetWndWidth();
		local nRightBorder = self.m_WndValidZone:GetWndWidth() - 1/4*self.m_WndPicture:GetWndWidth();
		local nTopBorder = -3 / 4 * self.m_WndPicture:GetWndHeight();
		local nBottomBorder = self.m_WndValidZone:GetWndHeight() -  1 / 4 * self.m_WndPicture:GetWndHeight();
		nCurX = nCurX < nLeftBorder and nLeftBorder or nCurX;
		nCurX = nCurX > nRightBorder and nRightBorder or nCurX;
		nCurY = nCurY < nTopBorder and nTopBorder or nCurY;
		nCurY = nCurY > nBottomBorder and nBottomBorder or nCurY;
		self.m_WndPicture:SetLocalX( nCurX );
		self.m_WndPicture:SetLocalY( nCurY );
	elseif self.m_nTouchPoint == 2 then
		local Pos = {};
		Pos["nX"] = Event.m_GlobalX;
		Pos["nY"] = Event.m_GlobalY;
		local AnotherBeginPos = self:GetAnotherPoint( Event.m_Param );
		local nCurDistance = self:CalcDistanceBetweenTowPos( Pos, AnotherBeginPos );
		local nBeginDistance = self:CalcDistanceBetweenTowPos( self.m_tblBeginPos[Event.m_Param], AnotherBeginPos );
		local nCoff = nCurDistance > nBeginDistance and 1.1111111111 or 0.9;
		local nWidth = self.m_WndPicture:GetWndWidth() * nCoff;
		local nHeight = self.m_WndPicture:GetWndHeight() * nCoff;
		if nWidth / self.m_nInitWidth > 2.0 or nWidth / self.m_nInitWidth < 0.5 or 
			nHeight / self.m_nInitHeight > 2.0 or nHeight / self.m_nInitHeight < 0.5 then
				return;
		end
		self.m_WndPicture:SetWndSize( nWidth, nHeight );
	else
		return;
	end
end

function CWndCutPicture:GetAnotherPoint( nInputID )
	for k, v in pairs( self.m_tblBeginPos ) do
		if k ~= nInputID then
			return v;
		end
	end
end

function CWndCutPicture:CalcDistanceBetweenTowPos( Pos1, Pos2 )
	local nDeltaX = Pos1.nX - Pos2.nX;
	local nDeltaY = Pos2.nY - Pos2.nY;
	return math.sqrt( nDeltaX * nDeltaX + nDeltaY * nDeltaY );
end

function CWndCutPicture:OnDragEndEvent( Event )
	self.m_nTouchPoint = self.m_nTouchPoint - 1;
	self.m_tblBeginPos[Event.m_Param] = nil;
end



------------------------------------------------------------------------------
------------- 照片ListItem
------------------------------------------------------------------------------
function CPhotoItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CPhotoItem:OnCreated()
	self.m_WndTips = self:GetDlgChild( "tips" );
	self.m_pBtnDelete = self:GetDlgChild( "b_shanchu" );
	self.m_pBtnDelete:AddActionListener( "DeletePicture", self );
	self.m_PublicPhotoLoadListener = IResListener:new();
	self.m_PublicPhotoLoadListener.m_Wnd = self;
	self.m_PublicPhotoLoadListener.OnLoadedEnd = function( this, szFileName, pBuffer, nSize )
		if this.m_Wnd.OnPublicPhotoLoadedEnd then
			this.m_Wnd:OnPublicPhotoLoadedEnd( this, szFileName, pBuffer, nSize );
		end
	end
	self.m_PrivatePhotoLoadListener = IResListener:new();
	self.m_PrivatePhotoLoadListener.m_Wnd = self;
	self.m_PrivatePhotoLoadListener.OnLoadedEnd = function( this, szFileName, pBuffer, nSize )
		if this.m_Wnd.OnPrivatePhotoLoadedEnd then
			this.m_Wnd:OnPrivatePhotoLoadedEnd( this, szFileName, pBuffer, nSize );
		end
	end
	g_App.m_EventDispatcher:AddEventListener( "AnswerPictureData", "RefreshPictureStatus", self );
end

function CPhotoItem:OnDestroy()
	CGWnd.OnDestroy( self );
	GetGammaFileMgr():RemoveListener( self.m_PublicPhotoLoadListener );
	GetGammaFileMgr():RemoveListener( self.m_PrivatePhotoLoadListener );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerPictureData", "RefreshPictureStatus", self );
end

function CPhotoItem:DownloadPicture( nAccountID, nIndex )
	if not nAccountID then return end;
	self.m_nPictureIndex = nIndex;
	self.m_nAccountID = nAccountID;
	if self.m_nAccountID == g_App:GetAccountID() then
		self.m_pBtnDelete:ShowWnd( true );
	else
		self.m_pBtnDelete:ShowWnd( false );
	end

	local szPictureLoadPath = g_App:GetImgCDN() .. "uploads/user_image/" .. g_App:GetServerID() .. "/";
	local szPhotoLoadPath = szPictureLoadPath .. "public/" .. nAccountID .. "/Photo_" .. nIndex .. ".jpg";	--先下载已审核图片   
	GetGammaFileMgr():Load( szPhotoLoadPath, true, false, self.m_PublicPhotoLoadListener );
end

function CPhotoItem:OnPublicPhotoLoadedEnd( this, szFileName, pBuffer, nSize )
	if nSize == 0 then
		--若已审核图片不存在，先隐藏该列 
		self:GetParent():SetSubItemVisible( false, 0, self.m_nPictureIndex );
		self:GetParent():SetColumnWidth( self.m_nPictureIndex, 0 );
		if g_App:GetAccountID() == self.m_nAccountID then 
			local szPictureLoadPath = g_App:GetImgCDN() .. "uploads/user_image/" .. g_App:GetServerID() .. "/";
			local szPhotoNotCheckPath = szPictureLoadPath .. "private/" .. g_App:GetPictureKey() .. "/Photo_" .. self.m_nPictureIndex .. ".jpg";
			GetGammaFileMgr():Load( szPhotoNotCheckPath, true, false, self.m_PrivatePhotoLoadListener );
		end
		return;
	end
	self:DecodePictureDataAndShowWnd( pBuffer, nSize );
end

function CPhotoItem:OnPrivatePhotoLoadedEnd( this, szFileName, pBuffer, nSize )
	if nSize == 0 then
		return
	end
	self:DecodePictureDataAndShowWnd( pBuffer, nSize );
end

function CPhotoItem:DecodePictureDataAndShowWnd( pBuffer, nSize )
	local HeadWnd = g_App:GetGameStart().m_pHeadWnd;
	if HeadWnd.m_nPhotoCount then
		HeadWnd.m_nPhotoCount = HeadWnd.m_nPhotoCount + 1;
	end
	self:GetParent():SetSubItemVisible( true, 0, self.m_nPictureIndex );
	self:GetParent():SetColumnWidth( self.m_nPictureIndex, 520 );
	local Renderer = g_App:GetRenderer();
	local Texture = Renderer:GetGraphic():CreateTexture( ePhotoSize, ePhotoSize, 0, eTF_ARGB32, 1, true );
	local nColorSize = ePhotoSize * ePhotoSize * 4;
	local ColorData = CBufferStream:new( nColorSize );
	local JpegDecoder = CImageDecoder.GetDecoder( "jpg" );
	local bSuccess = JpegDecoder:FillToARGB32( pBuffer, nSize, ColorData, nColorSize );
	Texture:FillFromMemory( ColorData, eTF_ARGB32, nil, 0 );
	local rtImg = CFRect:new( 0, 0, ePhotoSize, ePhotoSize );
	local rtWnd = CFRect:new( 0, 0, self:GetWndWidth(), self:GetWndHeight() );
	local nFlag = BitOr( IDF_ZOOM_WHILE_SCALE, IDF_ENABLE_ALPHA_BLEND )
	for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
		self:ClearWndBkImage( GSM_BS_BK, i )
		self:AddImageByTexture( GSM_BS_BK, i, 0, Texture, rtImg,
			rtWnd, 0xffffffff, LOCK_ALL, nFlag, -1, -1, 0, 1, 0 );
	end
end

function CPhotoItem:RefreshPictureStatus( Event )
	if Event.m_tblPictureStatus[self.m_nPictureIndex] then
		if Event.m_tblPictureStatus[self.m_nPictureIndex].nStatus == 0 then
			self.m_WndTips:SetWndText( g_App:GetString( "zhaopianweishenhe" ) );
		elseif Event.m_tblPictureStatus[self.m_nPictureIndex].nStatus == 2 then
			self.m_WndTips:SetWndText( g_App:GetString( "shenheweitongguo" ) );
		end
	end		
end

function CPhotoItem:DeletePicture()
	g_App:MessageBox( g_App:GetString( "shanchutupian" ),
		{
		[CMessageBox.Close] = function()
			g_App.m_pMessageBox:ShowWnd( false );
		end;
		[CMessageBox.OK] = function()
			g_App.m_pMessageBox:ShowWnd( false );
			local NetMsg = CDeletePicture:new();
			NetMsg.m_nPictureType = ePictureType_Photo;
			NetMsg.m_nPictureIndex = self.m_nPictureIndex;
			g_App:SendShellMsg( NetMsg );
		end;
		} );
end