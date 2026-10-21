--region *.lua
--Date 2017-08-05

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
CInviteMsgBox = class( CGWnd );
function CInviteMsgBox:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CInviteMsgBox:OnCreated()
    self.m_pBtnOK = self:GetDlgChild( "yes" );
    self.m_pBtnCancel = self:GetDlgChild( "no" );
	self.m_pBtnOK:AddActionListener( "OnOK", self );
	self.m_pBtnCancel:AddActionListener( "OnCancel", self );
    self.m_pText = self:GetDlgChild( "W_tishi" );
end

function CInviteMsgBox:Show( nAccountID, nTeamID, szAccountName, nTeamType )
    if not g_App:GetGameStart():IsShow() then
        return;
    end
    self.m_nAccountID = nAccountID;
    self.m_nTeamID = nTeamID;
    if nTeamType == eMRT_Limit then
        self.m_pText:SetWndText( string.format( g_App:GetString( "xianshiyaoqing" ), szAccountName ) );
    elseif nTeamType == eMRT_Team then
		self.m_pText:SetWndText( string.format( g_App:GetString( "beiyaoqing" ), szAccountName ) );
	elseif nTeamType == eMRT_LimitSecret then
		self.m_pText:SetWndText( string.format( g_App:GetString( "sirenxianshiyaoqing" ), szAccountName ) );
	elseif nTeamType == eMRT_TeamSecret then
		self.m_pText:SetWndText( string.format( g_App:GetString( "sirentuanzhanyaoqing" ), szAccountName ) );
	elseif nTeamType == eMRT_TeamRaceBefore then
		self.m_pText:SetWndText( string.format( g_App:GetString( "saishituanzhanyaoqig" ), szAccountName ) );
    end

    self:ShowAndSetFocus();
end

function CInviteMsgBox:OnOK()
	local NetMsg = CJoinGame:new();
    NetMsg.nAccountID = self.m_nAccountID;
    NetMsg.nTeamID = self.m_nTeamID;
	g_App:SendShellMsg( NetMsg );
    self:ShowWnd( false );
end

function CInviteMsgBox:OnCancel()
	local NetMsg = CRefuseInvite:new();
    NetMsg.nAccountID = self.m_nAccountID;
	g_App:SendShellMsg( NetMsg );
    self:ShowWnd( false );
end

function CGameStartLua:Ctor()
    self:ShowWnd( false );
	self.bHasData = false;
	self.m_bShowTeachTip = false;
	self.m_nSerialBad = 0;		--无尽模式连续“不合格”的次数
	self.m_nEnterRoomNum = 0;	--本次登录进入房间次数  	
	self.m_tblRankData = {};
	self.m_tblRankData.szFriendName = {};
	self.m_tblRankData.nFriendScore = {};
	self.m_tblRankData.szWorldName = {};
	self.m_tblRankData.nWorldScore = {}

	self.m_tickUpdateTime = CTick:new( "OnUpdateTime", self );
end

function CGameStartLua:OnCreated()
	CGameStart.OnCreated( self );
	self.m_mgrRankData = CRankDataMgr:new();
	self.m_mgrInstantMessageData = CInstantMessageDataMgr:new();

	self.m_pNickName = self:GetDlgChild("wanjiaxinxi.name");
	self.m_pHeadIcon = self:GetDlgChild("wanjiaxinxi.head.touxiang");--此3行是玩家信息
	self.m_pWndLevel = self:GetDlgChild("wanjiaxinxi.W_duanwei");
	self.m_pWndStarNum = self:GetDlgChild( "wanjiaxinxi.w_xingshu" );	--传说的星数
	self.m_pBtnVip = self:GetDlgChild( "B_huiyuan" );
	self.m_pWndDiamond = self:GetDlgChild( "zuanshi.jinbishuliang" );
	self.m_pWndPresentDiamond =  self:GetDlgChild( "zengsongzuanshi.jinbishuliang" );
	self.m_pWndDiamondAdd = self:GetDlgChild( "zuanshi.btn_add" );
	self.m_pWndCurTime = self:GetDlgChild( "shijian" );
	self.m_pBtnFristChargePrize = self:GetDlgChild( "B_shouchong" );

	self.m_pBtnSetting = self:GetDlgChild( "B_shezhi" );--界面右边的设置
	self.m_pBtnSetting:AddActionListener( "OnSetting", self );
	self.m_pBtnFriend = self:GetDlgChild( "B_shejiao" );--界面下边的社交
	self.m_pBtnFriend:AddActionListener( "OnFriend", self );
															--无尽模式就是零流量自嗨
	self.m_pBtnEndless = self:GetDlgChild( "zhangjie.wujinmoshi" ); --1主页面的无尽模式
	self.m_pBtnEndless:AddActionListener( "OnEnterEndless", self );

	self.m_pBtnLimitTime = self:GetDlgChild( "zhangjie.xianshimoshi" );--2主页面真人模式
	self.m_pBtnLimitTime:AddActionListener( "OnEnterLimitTime", self );

	self.m_pBtnTeam = self:GetDlgChild( "zhangjie.tuandui" );--3主页面的团队排名模式
	self.m_pBtnTeam:AddActionListener( "CreateEnterTeam", self );

	self.m_pBtnHead = self:GetDlgChild( "wanjiaxinxi.head" ); --左上角玩家信息
	self.m_pBtnHead:AddActionListener( "OnClickHead", self );

	self.m_pBtnShare = self:GetDlgChild( "B_fenxiang" ); --分享功能
	self.m_pBtnShare:AddActionListener( "OpenShareWnd", self );  

	self.m_pBtnSkin = self:GetDlgChild( "B_pifu" );--界面下面的皮肤
	self.m_pBtnSkin:AddActionListener( "OnClickSkin", self );

	self.m_pGuide = self:GetDlgChild( "B_zhiyin" );--界面右边的新手指引
	self.m_pGuide:AddActionListener( "OnClickGuide", self );
	self.m_pGuide:GetDlgChild( "hongdian" ):ShowWnd( false );

	self.m_btnTask = self:GetDlgChild( "B_renwu" );  --活动功能
	self.m_btnTask:AddActionListener( "OnClickTaskBtn", self );

	self.m_pBtnSkill = self:GetDlgChild( "B_jineng" );
	self.m_pBtnSkill:AddActionListener( "OnClickSkillDevelop", self );

	self.m_pBtnRace = self:GetDlgChild( "zhangjie.kaifangjian" );
	self.m_pWndRace = CRaceWnd:new( "gui/cfg/fsj_saishi.gui", self, 1 );
	self.m_pBtnRace:AddActionListener( "OnClickRace", self );
	self.m_pWndConfirmJoin = CConfirmJoinWnd:new( "gui/cfg/fsj_goumaiqueren.gui", self, 1 );

	self.m_btnRanking = self:GetDlgChild( "paihangbang" );--排行榜，玩家
	self.m_btnRanking:AddEventListener( GM_WM_MOUSECLICK ,"OnClickRanking", self );

	self.m_WndMusic = CWndMusic:new( "gui/cfg/fsj_yinyuexuanze3.gui", self, 1 );
	self.m_BtnMusic = self:GetDlgChild( "B_yinyuexuanze" ); --音乐图标
	self.m_BtnMusic:AddActionListener( "OnClickMusic", self );

	self.m_WndTreasureBox = CWndTreasureBox:new( "gui/cfg/fsj_baoxiang.gui", self, 1 );
	self.m_BtnTreasureBox = self:GetDlgChild( "B_baoxiang" );
	self.m_ImgNewTreasureBox = self:GetDlgChild( "B_baoxiang.hongdian" );
	self.m_ImgNewTreasureBox:ShowWnd( true );
	self.m_BtnTreasureBox:AddActionListener( "OnClickTreasureBox", self );
	
	self.m_wndTips = self:GetDlgChild( "tips" );
	self.m_wndTips:ShowWnd( false );

	self.m_wndTips2 = self:GetDlgChild( "tips2" );
	self.m_wndTips2:ShowWnd( false );

	self.m_wndTipsFace = self:GetDlgChild( "tips3" );
	self.m_wndTipsFace:ShowWnd( false );

	--shezhijiage
	self.m_pWndMoney = self:GetDlgChild("jinbi.jinbishuliang");
	self.m_pBtnAddMoney = self:GetDlgChild( "jinbi.btn_add" );
	self.m_pBtnAddMoney:AddActionListener( "AddMoneyAnswer", self );--增加金响应

	self.m_pWndRainbowGold = self:GetDlgChild( "jinbi2.jinbishuliang" );
	self.m_pBtnAddRainbowGold = self:GetDlgChild( "jinbi2.btn_add" );
	self.m_pBtnAddRainbowGold:AddActionListener( "OnAddRainbowGold", self );--增加彩虹币
	
	self.m_pSettingWnd = CSettingWnd:new( "gui/cfg/fsj_shezhi.gui", self, 2 );
	self.m_pLimitTimeWnd = CTeamWnd:new( "gui/cfg/fsj_xianshi.gui", self, 1, eMRT_Limit );
	self.m_pTeamWnd = CTeamWnd:new( "gui/cfg/fsj_tuanzhan.gui", self, 1, eMRT_Team );
	self.m_pWndRaceTeam = CRaceRoomWnd:new( "gui/cfg/fsj_saishi_dikuang.gui", self, 1 );

	self.m_pWndRaceOpen = self:GetDlgChild( "zhangjie.kaifangjian.kaishi" );
	self.m_pWndRaceClose = self:GetDlgChild( "zhangjie.kaifangjian.weikaishi" );
	self.m_pWndRaceOpen:ShowWnd( false );
	self.m_pWndRaceClose:ShowWnd( false );

	self.m_pFriendWnd = CFriendWnd:new( "gui/cfg/fsj_haoyou.gui", self, 1 );	
    self.m_pFriendWnd:AddCueListener( self.m_pBtnFriend );

	self.m_pHeadWnd = CHeadWnd:new("gui/cfg/fsj_zhujuexinxi.gui",self, 1 );
	self.m_pShareWnd = CShareWnd:new("gui/cfg/fsj_fenxiang.gui", self, 2 );
	self.m_pSkinWnd = CSkinWnd:new( "gui/cfg/fsj_pifu2.gui", self, 2 );

	self.m_pWndGuideSelect = CWndGuideSelect:new( "gui/cfg/fsj_jiaoxuexuanxiang0.gui", self, 2 );
	self.m_pWndVideoOrGuide = CWndVideoOrGuide:new( "gui/cfg/fsj_jiaoxuexuanxiang1.gui", self, 2 );
	
	self.m_pCharListOpr = CCharListItemOpr:new();
    self.m_pCharListOpr:CreateFromRes( "gui/cfg/fsj_haoyou_tips.gui", self, 1 );
	self.m_pCharListOpr1 = CCharListItemOpr:new();
    self.m_pCharListOpr1:CreateFromRes( "gui/cfg/fsj_haoyou_tips3.gui", self, 1 );
	self.m_pCharListTip = CCharListItemTip:new();
    self.m_pCharListTip:CreateFromRes( "gui/cfg/fsj_haoyou_tips2.gui", self, 1 );

    self.m_pInvite = CInviteMsgBox:new( "gui/cfg/fsj_msgboxyesno.gui", self, 1 );

	self.m_pWndRename = CWndRename:new( "gui/cfg/fsj_gaimingtishi.gui", self, 1 );
	self.m_pWndNewLadderSeason = CWndNewLadderSeason:new( "gui/cfg/fsj_xinsaiji.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );			--上赛季天梯奖励及天梯继承

	self.m_pWndLimitTip = CWndLimitTip:new( "gui/cfg/fsj_xianshikaifangtishi.gui", self, 1 );
	self.m_pWndTeamTip = CWndTeamTip:new( "gui/cfg/fsj_tuanzhankaifangtishi.gui", self, 1 );
	self.m_WndModelOpenLimit = CWndModeLimit:new( "gui/cfg/fsj_moshikaifang.gui", self, 1 );
	self.m_WndNewTreasureBox = CWndNewTreasureBox:new( "gui/cfg/fsj_pifu_baoxianghuode.gui", self, 1 );

	-- 游客升级提示
	self.m_WndGuestUpgrade = CWndGuestUpgrade:new( "gui/cfg/fsj_zhanghaozhuanzheng.gui", self, 2 );
	self.m_WndGuestUpgradePrize = CWndGuestUpgradePrize:new( "gui/cfg/fsj_zhanghaozhuanzhengchenggong.gui", self, 2 );

	--家族界面 
	self.m_BtnClan = self:GetDlgChild( "B_jiazu" );
	self.m_BtnClan:AddActionListener( "OnClickClan", self );
	self.m_WndClan = CWndClan:new( "gui/cfg/fsj_jiazu_dikuang.gui", self, 1 );
	self.m_WndCreateClan = CWndCreateClan:new( "gui/cfg/fsj_jiazu_chuangjian.gui", self, 1 );
	self.m_WndClanMemberOpr = CWndClanMemberOpr:new( "gui/cfg/fsj_jiazu_xuanxiang.gui", self, 1 );
	self.m_WndClanMemberOpr1 = CWndClanMemberOpr:new("gui/cfg/fsj_jiazu_xuanxiang2.gui", self, 1 );

	-- 商城
	self.m_pWndShop = CWndShop:new( "gui/cfg/fsj_chongzhi.gui", self, 2 );
	self.m_pWndVip = CWndVip:new( "gui/cfg/fsj_huiyuan.gui", self, 1 );
	self.m_pWndFirstChargetPrize = CWndFristChargePrize:new( "gui/cfg/fsj_shouchong.gui", self, 2 );

	-- 商城相关
	self.m_pBtnVip:AddClickListener( "OpenVipWnd", self );
	self.m_pWndDiamondAdd:AddClickListener( "OpenDiamondShop", self );
	self.m_pBtnFristChargePrize:AddClickListener( "OpenFirstChargePrize", self );

	--活动相关
	self.m_pWndActivity = CActivityWnd:new( "gui/cfg/fsj_huodong.gui", self, 1 );
	--self.m_pWndActivity:AddActionListener( "OnClickActivity", self );

	self.m_pWndSkillDevelop = CSkillDevelopWnd:new( "gui/cfg/fsj_jineng.gui", self, 1 );

	self.m_btnIM = self:GetDlgChild("liaotian");
	self.m_descWorld = self.m_btnIM:GetDlgChild("neirong");
	self.m_descFriend = self.m_btnIM:GetDlgChild("hongdian");
	self.m_btnIM:AddEventListener( GM_WM_MOUSECLICK, "OnClickIM", self );
	self.m_descWorld:SetInertiaType( eInertiaType_HScroll );

	self.m_wndIM = CInstantMessageWnd:new( "gui/cfg/fsj_liaotian.gui", self, 1 );
	self.m_wndIM:ShowWnd( false );

	self.m_wndRhythmGuide = CRhythmGuideWnd:new( "gui/cfg/fsj_jiaoxuexuanxiang2.gui", self, 1 );

	--设置wifi
	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new ( "OnTimeTick", self );

	self.m_tickLocalTimeMinute = CTick:new( "OnMinuteTick", self );

	-- 显示Debug框  
	self.m_pWndDebug = self:GetDlgChild( "wifi" );
	self.m_pWndDebug:AddEventListener( WM_LBUTTONDOWN, "OnClickDebug", self );

	--赛季提醒
	self.m_pWndNewSeasonComing = CNewSeasonComing:new( "gui/cfg/fsj_saijijieshutips.gui", self, 1 );

	--各界面提示框
	self.m_pWndTip = CTipWnd:new( "gui/cfg/fsj_tongyongshuoming.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	--特惠活动礼包
	self.m_pWndSpecialOffer = CWndSpecialOffer:new( "gui/cfg/fsj_yunying_cuxiao.gui", self, 1 );

	self:UpdateIMDesc();

	g_App.m_EventDispatcher:AddEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
    g_App.m_EventDispatcher:AddEventListener( "ChangeHeadIcon", "RefreshHeadIcon", self );
	g_App:GetMainPlayerData():AddEventListener( "m_SeasonStarNum", "RefreshLadder", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.LadderStarChangeTime", "RefreshLadder", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.StreakNum", "RefreshLadder", self );
	g_App:GetMainPlayerData():AddEventListener( "m_FirstEvent", "RefreshWnd", self );
    g_App.m_EventDispatcher:AddEventListener( "SocialLoginSucc", "RefreshRankData", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshRankWnd", "RefreshRankWnd", self );
	g_App:GetMainPlayerData():AddEventListener( "m_FragmentData", "RefreshSkinButtonRedPoint", self );
	g_App:GetMainPlayerData():AddEventListener( "m_HaveEquip", "RefreshSkinButtonRedPoint", self );
	g_App:GetMainPlayerData():AddEventListener( "m_TreasureBoxData", "ShowTreasureBoxRedPoint", self );
	g_App:GetMainPlayerData():AddEventListener( "m_FirstEvent", "UpdateFirstChargePrizeBtn", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.RechargeID", "UpdateFirstChargePrizeBtn", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshClanRedPoint", "RefreshClanRedPoint", self );
	g_App.m_EventDispatcher:AddEventListener( "RefreshHeadImg", "RefreshHeadImg", self );
end

function CGameStartLua:OnDestroy()
	self.m_timeTick:Stop();
	self.m_tickLocalTimeMinute:Stop();
	self.m_tickUpdateTime:Stop();
	if self.m_tickDebugClick then
		self.m_tickDebugClick:Stop();
	end
	if self.m_tickUpdateTreasureBoxTime then
		self.m_tickUpdateTreasureBoxTime:Stop();
	end
	self.m_mgrRankData:Destroy();
	self.m_mgrInstantMessageData:Destroy();
	self.m_pWndNewLadderSeason = nil;
	self.m_pWndTip = nil;
	CPlayerRoomMemberInfoMgr:Instance():ClearData();
	
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshWorldContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshFriendContentWnd", "UpdateIMDesc", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshIMFriendUnReadWnd", "UpdateIMDesc", self );
    g_App.m_EventDispatcher:RemoveEventListener( "ChangeHeadIcon", "RefreshHeadIcon", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_SeasonStarNum", "RefreshLadder", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.LadderStarChangeTime", "RefreshLadder", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.StreakNum", "RefreshLadder", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_FirstEvent", "RefreshWnd", self );
    g_App.m_EventDispatcher:RemoveEventListener( "SocialLoginSucc", "RefreshRankData", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshRankWnd", "RefreshRankWnd", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_FragmentData", "RefreshSkinButtonRedPoint", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_HaveEquip", "RefreshSkinButtonRedPoint", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_TreasureBoxData", "ShowTreasureBoxRedPoint", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_FirstEvent", "UpdateFirstChargePrizeBtn", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.RechargeID", "UpdateFirstChargePrizeBtn", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshClanRedPoint", "RefreshClanRedPoint", self );
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshHeadImg", "RefreshHeadImg", self );
	CGameStart.OnDestroy( self );
end

function CGameStartLua:RefreshClanRedPoint( Event )
	self.m_BtnClan:ShowRedPoint( Event.m_bShow );
end

function CGameStartLua:OnKeyDown( nChar, nFlags )
	CGWnd.OnKeyDown( self, nChar, nFlags );
	if nChar ~= VK_ESCAPE then
		return;
	end
	g_App:Quit();
end

function CGameStartLua:OnClickDebug()
	if not self.m_tickDebugClick then
		self.m_tickDebugClick = CTick:new( "OnClickDebugTick", self );
	end

	if not self.m_nDebugClickCount then
		self.m_tickDebugClick:Start( 3000 );
		self.m_nDebugClickCount = 0;
	end

	self.m_nDebugClickCount = self.m_nDebugClickCount + 1;
	if self.m_nDebugClickCount >= 8 then
		self:OnClickDebugTick();
		g_App.m_CmdMgr:ShowDebugInput();
	end
end

function CGameStartLua:OnClickDebugTick()
	self.m_tickDebugClick:Stop();
	self.m_nDebugClickCount = nil;
end

function CGameStartLua:OnImShow( bShow )
	self.m_btnIM:ShowWnd( not bShow );
end

function CGameStartLua:OnClickIM( Event )
	local szName = Event.m_Target:GetWndName();
	self.m_wndIM:ShowPage( szName == "hongdian" and 1 or 0 );
end

function CGameStartLua:UpdateIMDesc()
	local IMMgr = g_App:GetInstantMessageDataMgr();
	self.m_descWorld:SetWndText( IMMgr:GetWorldMessageContentLast() );

	local nCount = math.min( IMMgr:GetFriendUnReadCount(), 99 );
	self.m_descFriend:ShowWnd( nCount ~= 0 );
	self.m_descFriend:SetWndText( nCount );
end

function CGameStartLua:OnClickTaskBtn()  --活动功能
--	local worldConn = g_App:GetWorldConn();
--	if not worldConn then
		--g_App:HideMsg( g_App:GetString( "weikaifangtishi2" ) );
--	end
	local NetMsg = CQueryActivity:new();
	NetMsg.nHandleType = eHAST_Query;
	g_App:SendShellMsg( NetMsg );
	self.m_pWndActivity:ShowWnd( true );	
end

function CGameStartLua:OnClickSkillDevelop()
	--未开启团战模式，此时直接弹出提示
	local bCanUseSkill = g_App:CouldUseSkill();
	if not bCanUseSkill then
		g_App:HideMsg( g_App:GetString( "jinengtips1" ) );
		return;
	end
	self.m_pWndSkillDevelop:ShowWnd( true );
end

function CGameStartLua:OnClickRace()
	if not g_App:CouldUseSkill() then
		g_App:HideMsg( g_App:GetString( "kaiqituanzhanhoukaifang" ) );
		return;
	end

	local NetMsg = CQueryWorldRaceInfo:new();
	NetMsg.nType = eMRT_LimitRace;
	g_App:SendShellMsg( NetMsg );
	self.m_pWndRace:ShowWnd( true );
end

function CGameStartLua:OnTimeTick()
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
	self.m_pWndMoney:SetWndText( nCoinCount );

	local nRainbowGold = g_App:GetPropCount( eGRT_Resource, eResourceType_RainbowGold );
	self.m_pWndRainbowGold:SetWndText( nRainbowGold );
	
	local nDiamondCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Diamond );
	local nPreSentDiamondCount = g_App:GetPropCount( eGRT_Resource, eResourceType_PresentDiamond );
	self.m_pWndDiamond:SetWndText( nDiamondCount );
	self.m_pWndPresentDiamond:SetWndText( nPreSentDiamondCount );
end

function CGameStartLua:OnMinuteTick()
	local sTime = GetFormatTimeSTMFromMillisecond( GetLocalTime() );
	if sTime:m_nMinutes() == 0 then
		self:OnHourChange( sTime:m_nHour() );
	end
end

function CGameStartLua:OnHourChange( nHourTime )
	--抽奖时间到了
	for i = 1, g_tblTabFile.day_roll_activity.nRowCount do
		if nHourTime == g_tblTabFile.day_roll_activity:GetRow( i ).nStarthour then
			self.m_bCanRoll = true;
			break;
		elseif nHourTime == g_tblTabFile.day_roll_activity:GetRow( i ).nEndHour then
			self.m_bCanRoll = false;
			break;
		end
	end
	self.m_pWndActivity.m_pWndRoll.m_pBtnRoll:EnableWnd( self.m_bCanRoll );
	self.m_btnTask:ShowRedPoint( self.m_bCanRoll or self.m_bCanSignIn );
	if self.m_pWndActivity.m_pBtnRoll then
		self.m_pWndActivity.m_pBtnRoll:ShowRedPoint( self.m_bCanRoll );
	end

	local bShowRace = self:IsShowRace();
	self.m_pWndRaceOpen:ShowWnd( bShowRace );
	self.m_pWndRaceClose:ShowWnd( not bShowRace );
end

function CGameStartLua:IsShowRace()	
	local sTime = GetFormatTimeSTMFromMillisecond( GetLocalTime() );
	local nHourTime = sTime:m_nHour();
	for i = 1, g_tblTabFile.day_race_activity.nRowCount do
		local LineData = g_tblTabFile.day_race_activity:GetRow( i );
		if nHourTime >= LineData.nStarthour and nHourTime < LineData.nEndHour then
			self.m_nRaceID = LineData.nID;
			return true;
		end
	end
	return false;
end

function CGameStartLua:ShowTreasureBoxRedPoint()
	if not g_App:GetFirstEvent( eFE_GetLimitModeOpenPrize ) then
		self.m_ImgNewTreasureBox:ShowWnd( false );
		return;
	end

	self.m_ImgNewTreasureBox:ShowWnd( true );
	local nTreasureBoxRedDotType, nTimeRemain = self:CheckTreasureBoxRedDotState();
	local tblString = {
		g_App:GetString( "xianshibaoxiangkaiqi" ); g_App:GetString( "tuanzhanbaoxiangkaiqi" ); 
		g_App:GetString( "xianshibaoxiangjiesuo" ); g_App:GetString( "tuanzhanbaoxiangjiesuo" );
		g_App:GetString( "xianshibaoxiangkong" ); g_App:GetString( "tuanzhanbaoxiangkong" ); 
		g_App:GetString( "xianshibaoxiangdengdai" ); g_App:GetString( "tuanzhanbaoxiangdengdai" );		
	}
	self.m_nTreasureBoxRedDotType = nTreasureBoxRedDotType;
	self.m_szTreasureBoxRedDot = tblString[nTreasureBoxRedDotType];
	self.m_nTreasureBoxRemainTime = nTimeRemain;
	if nTimeRemain then
		if not self.m_tickUpdateTreasureBoxTime then
			self.m_tickUpdateTreasureBoxTime = CTick:new( "UpdateTreasureBoxTime", self );
			self.m_tickUpdateTreasureBoxTime:Start( 1000 );
		end
	else
		if self.m_tickUpdateTreasureBoxTime then
			self.m_tickUpdateTreasureBoxTime:Stop();
		end
		self.m_ImgNewTreasureBox:SetWndText( self.m_szTreasureBoxRedDot );
	end
end

function CGameStartLua:UpdateTreasureBoxTime()
	self.m_nTreasureBoxRemainTime = self.m_nTreasureBoxRemainTime - 1;
	if self.m_nTreasureBoxRemainTime <= 0 then
		self.m_tickUpdateTreasureBoxTime:Stop();
	end
	local szTreasureBoxRedDot = string.format( self.m_szTreasureBoxRedDot, math.floor( self.m_nTreasureBoxRemainTime/3600 ), math.floor( self.m_nTreasureBoxRemainTime/60%60 ) );
	self.m_ImgNewTreasureBox:SetWndText( szTreasureBoxRedDot );
end

function CGameStartLua:CheckTreasureBoxRedDotState()
	local tblAllTreasureBox = {};
	local PlayerData = g_App:GetMainPlayerData().m_TreasureBoxData;
	for i = 1, PlayerData:GetDataCount() do
		local TreasureBoxData = PlayerData:GetData( i - 1 );
		local data = {};
		data.m_nTreasureBoxID = TreasureBoxData:GetTreasureBoxID();
		data.m_nGetTime = TreasureBoxData:GetGetTime();
		data.m_nUnlockTime = TreasureBoxData:GetUnlockTime();
		data.m_nType = TreasureBoxData:GetType();
		data.m_nStatus = TreasureBoxData:GetStatus();
		if data.m_nTreasureBoxID ~= 0 and data.m_nStatus ~= eTreasureBoxStatus_Opened and data.m_nStatus ~= eTreasureBoxStatus_Discard  then
			table.insert( tblAllTreasureBox, data );
		end
	end
	local tblLimitTreasureBox = {};
	local tblTeamTreasureBox = {};
	local tblCouldOpenLimitTreasureBox = {};
	local tblCouldOpenTeamTreasureBox = {};
	local WaitingOpenLimitTreasureBoxData = nil;
	local WaitingOpenTeamTreasureBoxData = nil;
	local tblLockedLimitTreasureBox = {};
	local tblLockedTeamTreasureBox = {};
	for k, Data in pairs ( tblAllTreasureBox ) do
		if Data.m_nStatus ~= eTreasureBoxStatus_Opened and Data.m_nStatus ~= eTreasureBoxStatus_Discard then
			if Data.m_nType == 0 then
				table.insert( tblLimitTreasureBox, Data );
			elseif Data.m_nType == 1 then
				table.insert( tblTeamTreasureBox, Data );
			end
		end
		if Data.m_nStatus == eTreasureBoxStatus_CouldOpen then
			if Data.m_nType == 0 then
				table.insert( tblCouldOpenLimitTreasureBox, Data );
			elseif Data.m_nType == 1 then
				table.insert( tblCouldOpenTeamTreasureBox, Data );
			end
		end
		if Data.m_nStatus == eTreasureBoxStatus_WaitingOpen then
			if Data.m_nType == 0 then
				WaitingOpenLimitTreasureBoxData = Data;
			elseif Data.m_nType == 1 then
				WaitingOpenTeamTreasureBoxData = Data;
			end
		end
		if Data.m_nStatus == eTreasureBoxStatus_Lock then
			if Data.m_nType == 0 then
				table.insert( tblLockedLimitTreasureBox, Data );
			elseif Data.m_nType == 1 then
				table.insert( tblLockedTeamTreasureBox, Data );
			end
		end
	end 

	if table.count( tblCouldOpenLimitTreasureBox ) > 0 then
		return eTreasureBoxButtonRedDot_CouldOpenLimit;
	end
	if table.count( tblCouldOpenTeamTreasureBox ) > 0 then
		return eTreasureBoxButtonRedDot_CouldOpenTeam;
	end
	if table.count( tblLockedLimitTreasureBox ) > 0  and not WaitingOpenLimitTreasureBoxData then
		return eTreasureBoxButtonRedDot_CouldUnlockLimit;
	end
	if table.count( tblLockedTeamTreasureBox ) > 0 and not WaitingOpenTeamTreasureBoxData then
		return eTreasureBoxButtonRedDot_CouldUnLockTeam;
	end
	if table.count( tblLimitTreasureBox ) == 0 then
		return eTreasureBoxButtonRedDot_EmptyLimit;
	end
	if table.count( tblTeamTreasureBox ) == 0 then
		return eTreasureBoxButtonRedDot_EmptyTeam;
	end

	local nRemainTimeLimit = nil;
	if WaitingOpenLimitTreasureBoxData then
		local nTreasureBoxID = WaitingOpenLimitTreasureBoxData.m_nTreasureBoxID;
		local nTimeNeed = g_tblTabFile.treasureboxbase[nTreasureBoxID].nTime;
		local nUnlockTime = WaitingOpenLimitTreasureBoxData.m_nUnlockTime;
		nRemainTimeLimit = nTimeNeed - ( math.floor( (GetNatureTime()/1000 + 0.5 ) ) - nUnlockTime );
		if nRemainTimeLimit <= 0 then 
			return eTreasureBoxButtonRedDot_CouldOpenLimit;
		end
	end
	local nRemainTimeTeam = nil;
	if WaitingOpenTeamTreasureBoxData then
		local nTreasureBoxID = WaitingOpenTeamTreasureBoxData.m_nTreasureBoxID;
		local nTimeNeed = g_tblTabFile.treasureboxbase[nTreasureBoxID].nTime;
		local nUnlockTime = WaitingOpenTeamTreasureBoxData.m_nUnlockTime;
		nRemainTimeTeam = nTimeNeed - ( math.floor( (GetNatureTime()/1000 + 0.5 ) ) - nUnlockTime );
		if nRemainTimeTeam <= 0 then
			return eTreasureBoxButtonRedDot_CouldOpenTeam;
		end	
	end
	if nRemainTimeLimit and nRemainTimeTeam then
		if nRemainTimeLimit <= nRemainTimeTeam then
			return eTreasureBoxbuttonRedDot_OpeningLimit, nRemainTimeLimit;
		else
			return eTreasureBoxButtonRedDot_OpeningTeam, nRemainTimeTeam;
		end
	end
end

function CGameStartLua:AddMoneyAnswer()
	g_App:HideMsg(g_App:GetString("gongnengtips"));
end

function CGameStartLua:OnAddRainbowGold()
	self:OpenShareWnd();
end

function CGameStartLua:ShowPage( pPage )
    if m_pCurPage ~= nil then
        m_pCurPage:ShowWnd( false );
    end
    m_pCurPage = pPage;
    if m_pCurPage ~= nil then
        m_pCurPage:ShowWnd( true );
    end
end

function CGameStartLua:ShowPlayerInfo( nAccountID )
	self.m_pHeadWnd:ShowPlayerInfo( nAccountID );
end

function CGameStartLua:OnWndShow( bIsShow )
	--print( "!!!!!!!!! CGameStartLua:OnWndShow( bIsShow )", bIsShow, g_App:GetFirstEvent( eFE_PlayGame ), g_App:GetFirstEvent( eFE_Rename ) );
	if not bIsShow then
		self.bHasData = false;
		self.m_timeTick:Stop();
		self.m_pLimitTimeWnd:ShowWnd( false );
		self.m_pTeamWnd:ShowWnd( false );
		self.m_pWndRaceTeam:ShowWnd( false );
		self.m_pWndRace:ShowWnd( false );
		return;
	else
		self.m_timeTick:Start( 100 );
		self:OnMinuteTick();
		self.m_tickLocalTimeMinute:Start( 1000 * 60 );
		if (( g_App:GetGameStart().m_nPreEnterScore and g_App:GetGameStart().m_nPreEnterScore == 0 and g_App:GetGameStart().m_nEnterRoomNum == 1 ) or ( g_App:GetGameStart().m_nEnterRoomNum > 1 and not self.m_bShowRhythmGuide ))
		and not g_App:GetFirstEvent( eFE_RhythmGuidePrize ) and g_App:GetIniFile():GetInteger( "Setting", "RhythmGuideTip", 0 ) == 0 then
			self.m_wndRhythmGuide:ShowWnd( true );
		else
			self.m_wndRhythmGuide:ShowWnd( false );
		end
		local bShowRedPoint = not g_App:GetFirstEvent( eFE_VideoGuidePrize ) 
								or not g_App:GetFirstEvent( eFE_NewerGuidePrize )
								or not g_App:GetFirstEvent( eFE_RhythmGuidePrize );
		self.m_pGuide:GetDlgChild( "hongdian" ):ShowWnd( bShowRedPoint );
		self:ShowTreasureBoxRedPoint();
		self:RefreshSkinButtonRedPoint();
		if self.m_bShowRacePrize and self.m_tblRacePrize and #self.m_tblRacePrize > 0 then
			self.m_bShowRacePrize = false;
			self:NotifyOpenTreasureBox( 1, self.m_tblRacePrize, nil, nil, 1 );
		end
		local bShowRace = self:IsShowRace();
		self.m_pWndRaceOpen:ShowWnd( bShowRace );
		self.m_pWndRaceClose:ShowWnd( not bShowRace );
	end
	self:CheckTips();

	self.m_pWndNewLadderSeason:ShowAndSetFocus();
	self:RefreshWnd();
	if bIsShow then
		self:UpdateFirstChargePrizeBtn();
	end

	if not bIsShow then
		self.m_tickUpdateTime:Stop();
	else
		self.m_tickUpdateTime:Start( 1000 );
	end
end

function CGameStartLua:RefreshLadder()
	local nAllStar = g_App:GetCurLadderStar();
	local nLevelStar = CStarLevelConfig:Inst():HaveStarOnLevel( nAllStar );
	local nLevelMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( nAllStar );
	local nLadderLevel = CStarLevelConfig:Inst():GetLevel( nAllStar );
	local nMaxStar = CStarLevelConfig:Inst():GetMaxStar( nAllStar );
	print( "111111 CGameStartLua:RefreshLadder()", nAllStar, nLevelStar );
	local szName = CStarLevelConfig.Inst():GetName( nAllStar );
	self.m_pWndLevel:SetWndText( szName );
	for i = 1, 5 do		--最多5星
		local WndStar = self:GetDlgChild( "wanjiaxinxi.icon_star"..i );
		if not WndStar then return; end
		WndStar:ShowWnd( i <= nLevelMaxStar );
		WndStar:EnableWnd( i <= nLevelStar );
	end
	for i = 1, 8 do		--8种大段位
		local WndLadder = self:GetDlgChild( "wanjiaxinxi.icon_duanwei."..i );
		if not WndLadder then return; end
		WndLadder:ShowWnd( tblLadder[nLadderLevel] == i );
	end

	if nAllStar >= nMaxStar then
		self.m_pWndStarNum:ShowWnd( true );
		self.m_pWndStarNum:SetWndText( "x"..( nAllStar - nMaxStar ) );
		for i = 2, 5 do
			local WndStar = self:GetDlgChild( "wanjiaxinxi.icon_star"..i );
			WndStar:ShowWnd( false );
		end 
	else
		self.m_pWndStarNum:ShowWnd( false );
	end
end

function CGameStartLua:RefreshWnd()
	local bShowRedPoint = not g_App:GetFirstEvent( eFE_VideoGuidePrize ) 
							or not g_App:GetFirstEvent( eFE_NewerGuidePrize )
							or not g_App:GetFirstEvent( eFE_RhythmGuidePrize );
	self.m_pGuide:GetDlgChild( "hongdian" ):ShowWnd( bShowRedPoint );
	self.m_pNickName:SetWndText( g_App:GetMainPlayerData().m_CharBaseData:GetNickName() );
	self:RefreshLadder();
    CHeadIconConfig:Inst():SetIcon( self.m_pHeadIcon, g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1, g_App:GetAccountID() );
end

function CGameStartLua:RefreshHeadIcon()
    CHeadIconConfig:Inst():SetIcon( self.m_pHeadIcon, g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1, g_App:GetAccountID() );
end

function CGameStartLua:GetSetingWnd()
	return self.m_pSettingWnd;
end

function CGameStartLua:OnSetting()
	self.m_pSettingWnd:ShowAndSetFocus();
end

function CGameStartLua:OnEnterEndless()--1主页面的无尽模式
	self.m_nRoomType = eRT_Endless;
	self:EnterRoom();
end

function CGameStartLua:OnEnterLimitTime()--2主页面真人模式
	--CRhythmGuide:Inst():Start();
	self.m_nRoomType = eRT_LimitTime;
	local NetMsg = CCheckEnterRoom:new();
	NetMsg.m_nRoomType = self.m_nRoomType;
	g_App:SendShellMsg( NetMsg );
end

function CGameStartLua:CreateEnterTeam()--3主页面的团队排名模式
	self.m_nRoomType = eRT_Team;
	local NetMsg = CCheckEnterRoom:new();
	NetMsg.m_nRoomType = self.m_nRoomType;
	g_App:SendShellMsg( NetMsg );
end

function CGameStartLua:EnterRoom()	
	g_App:EnterRoom( self.m_nRoomType );
	self.m_pBtnEndless:RemoveEffect( "shouzhi" );
	self.m_pBtnLimitTime:RemoveEffect( "shouzhi" );
	self.m_pBtnTeam:RemoveEffect( "shouzhi" );
end

function CGameStartLua:OnFriend() --界面下边的社交
    self:ShowPage( self.m_pFriendWnd );
end

function CGameStartLua:GetTeamWnd( nType )
    if nType == eMRT_Limit or nType == eMRT_LimitSecret then
		self.m_pTeamWnd:ShowWnd( false );
		self.m_pWndRace:ShowWnd( false );
		self.m_pWndRaceTeam:ShowWnd( false );
        return self.m_pLimitTimeWnd;
    elseif nType == eMRT_Team or nType == eMRT_TeamSecret then
		self.m_pLimitTimeWnd:ShowWnd( false );
		self.m_pWndRace:ShowWnd( false );
		self.m_pWndRaceTeam:ShowWnd( false );
		return self.m_pTeamWnd;
	elseif nType == eMRT_LimitRace or nType == eMRT_TeamRace or nType == eMRT_TeamRaceBefore then
		self.m_pTeamWnd:ShowWnd( false );
		self.m_pLimitTimeWnd:ShowWnd( false );
		return self.m_pWndRaceTeam;
    end
end

function CGameStartLua:OnClickHead()--左上角玩家信息
    g_App:ShowPlayerInfo( g_App:GetAccountID() );
end

function CGameStartLua:OnClickRanking()		--排行榜，玩家
	if self.m_pRankWnd ~= nil then
		self.m_pRankWnd:ShowWnd( true );
	end
end

function CGameStartLua:GetHeadWnd()
	return self.m_pHeadWnd;
end

function CGameStartLua:OpenShareWnd()  --分享功能提示
	if not g_App:IsGameSwitch( eGameSwitch_Share ) then
		return g_App:HideMsg( g_App:GetString( "fenxiangweikaiqi" ) );
	end
	g_App:GetIniFile():WriteInteger( "Setting", "ShareTip", 0 );
	g_App:GetIniFile():Save();
	self.m_wndTips2:ShowWnd( false );
	self.m_pShareWnd:ShowAndSetFocus();
end

function CGameStartLua:OnClickMusic()--音乐图标
    self:ShowPage( self.m_WndMusic );
end

function CGameStartLua:OnClickTreasureBox()
	self:ShowTreasureBoxWnd();
end

function CGameStartLua:ShowTreasureBoxWnd()
	if not g_App:GetFirstEvent( eFE_GetLimitModeOpenPrize ) then
		g_App:MessageBox( g_App:GetString( "baoxiangzhanweikaifang" ) );
		return;
	end
	self:ShowPage( self.m_WndTreasureBox );	
end

function CGameStartLua:GetMusicWnd()
	return self.m_WndMusic;
end

function CGameStartLua:OnClickSkin()--界面下面的皮肤
	g_App:GetIniFile():WriteInteger( "Setting", "FaceTip", 0 );
	g_App:GetIniFile():Save();
	self.m_wndTipsFace:ShowWnd( false );
    self:ShowPage( self.m_pSkinWnd );
end

function CGameStartLua:GetSkinWnd()
	return self.m_pSkinWnd;
end

function CGameStartLua:OnClickGuide() --界面右边的新手指引
	self.m_pWndVideoOrGuide:ShowWnd( true );
end

function CGameStartLua:OnInvite( nAccountID, nTeamID, szAccountName, nTeamType )
    self.m_pInvite:Show( nAccountID, nTeamID, szAccountName, nTeamType );
end

function CGameStartLua:HintEnterGame( nRoomType )
	local pWnd = nil;

	if nRoomType == eRT_Endless then  --无尽模式
		pWnd = self.m_pBtnEndless;
	elseif nRoomType == eRT_LimitTime then --真人模式
		pWnd = self.m_pBtnLimitTime;
	elseif nRoomType == eRT_Team then  --团队排名模式
		pWnd = self.m_pBtnTeam;
	end

	pWnd:AddEffect( "fx/cfg/shouzhi.eft", "fx/loop", "shouzhi", -1, false, false, false, 1.0 );
end

function CGameStartLua:ShowNewSeason()
	self.m_pWndNewLadderSeason:ShowAndSetFocus();
end
function CGameStartLua:RefreshRankData( Event )
	if not g_App:GetWorldConn() then
		return;
	end
	self:CheckTips();
	if not self.bHasData then
		self.m_pRankWnd = CRankWnd:new( "gui/cfg/fsj_duanwei_paihangbang.gui", self, 1 );
		local NetMsg = CQueryFolloweesRank:new();
		g_App:SendShellMsg( NetMsg );
		self.bHasData = true;
	end
end

function CGameStartLua:RefreshRankWnd()		--刷新界面左侧的段位排行
	local tblCurRankData = g_App:GetRankDataMgr():GetFolloweesRankData();
	local nNum = #tblCurRankData > 3 and 3 or #tblCurRankData;
	for i = 1, 3 do
		local WndPlayer = self.m_btnRanking:GetDlgChild( tostring( i ) );
		WndPlayer:ShowWnd( i <= #tblCurRankData );
		if tblCurRankData[i] then
			CHeadIconConfig:Inst():SetIcon( WndPlayer:GetDlgChild( "head.touxiang" ), tblCurRankData[i].nCurHeadIcon + 1, tblCurRankData[i].nAccountID );
			--print( tblCurRankData[i].nAccountID, g_App:GetRankDataMgr():GetAccountInfo( tblCurRankData[i].nAccountID ).nCurHeadIcon );
		end
	end
	
	local tblSelf = nil;
	local nIndex = 0;
	for _,Data in pairs( tblCurRankData ) do
		nIndex = nIndex + 1;
		Data.nIndex = nIndex;
		if Data.nAccountID == g_App:GetAccountID() then
			tblSelf = Data;
		end
	end
	if not tblSelf then
		return;
	end
	self.m_btnRanking:GetDlgChild( "wanjia.No_1" ):ShowWnd( tblSelf.nIndex == 1 );
	self.m_btnRanking:GetDlgChild( "wanjia.No_2" ):ShowWnd( tblSelf.nIndex == 2 );
	self.m_btnRanking:GetDlgChild( "wanjia.No_3" ):ShowWnd( tblSelf.nIndex == 3 );
	self.m_btnRanking:GetDlgChild( "wanjia.non" ):SetWndText( tblSelf.nIndex );
	self.m_btnRanking:GetDlgChild( "wanjia.non" ):ShowWnd( tblSelf.nIndex > 3 );
	self.m_btnRanking:GetDlgChild( "wanjia.non" ):ShowWnd( tblSelf.nIndex > 3 );
	local icon = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1;
	CHeadIconConfig:Inst():SetIcon( self.m_btnRanking:GetDlgChild( "wanjia.head.touxiang" ), icon, g_App:GetAccountID() );
end


function CGameStartLua:CheckTips()	
	local PlayerData = g_App:GetMainPlayerData().m_CharBaseData;
	local nCurAllGameScore = PlayerData:GetAllGameScore();
	local nTargetAllGameScore = CSnakeConstant:Inst():GetTuanzhanOpenScore();
	if nCurAllGameScore < nTargetAllGameScore then
		self.m_wndTips:ShowWnd( true );
	else
		self.m_wndTips:ShowWnd( false );
	end

	if g_App:GetIniFile():GetInteger( "Setting", "ShareTip", 1 ) == 1 then
		self.m_wndTips2:ShowWnd( true );
	else
		self.m_wndTips2:ShowWnd( false );
	end
	
	if g_App:GetIniFile():GetInteger( "Setting", "FaceTip", 1 ) == 1 then
		self.m_wndTipsFace:ShowWnd( true );
	else
		self.m_wndTipsFace:ShowWnd( false );
	end
end

function CGameStartLua:GetModeTips( nRoomType )
	if nRoomType == eRT_LimitTime then
		return 	self.m_pWndLimitTip;
	elseif nRoomType == eRT_Team then
		return self.m_pWndTeamTip;
	end
end

function CGameStartLua:GetShareWnd()
	return self.m_pShareWnd;
end

function CGameStartLua:ShortRainbowGold()
	g_App:MessageBox( g_App:GetString( "fenxiangtips0" ),
		{
		[CMessageBox.Close] = function()
			g_App.m_pMessageBox:ShowWnd( false );
		end;
		[CMessageBox.OK] = function()
			g_App.m_pMessageBox:ShowWnd( false );
			self:GetShareWnd():ShowAndSetFocus();
		end;
		}, g_App:GetString( "fenxiangtips1" ), g_App:GetString( "fenxiangtips2" ) );
end

function CGameStartLua:GetNewTreasureBoxWnd()
	return self.m_WndNewTreasureBox;
end

function CGameStartLua:OnClickActivity()
	self.m_pWndActivity:ShowWnd( true );
end

function CGameStartLua:NotifyPrize( nPrizeID, szName, szDesc, tblPropList )
	local pWnd = CWndPrizeNotify:new( "gui/cfg/fsj_fajiang.gui", self, 0 );
	pWnd:SetData( nPrizeID, szName, szDesc, tblPropList );
end

function CGameStartLua:NotifyPrizeTip( tblPropList )
	local pWnd = CWndPrizePropTip:new( "gui/cfg/fsj_fajiangwancheng.gui", self, 0 );
	pWnd:SetData( tblPropList );
end

function CGameStartLua:RefreshSkinButtonRedPoint()
	if not self.m_tblAllEquip then
		self.m_tblAllEquip = {};
		local nEquipCount = g_tblTabFile.equip.nRowCount;
		for i = 1, nEquipCount do
			local nAcquireType = CTableConfigMgr:Inst():GetConfigNumber( "equip", i, "nAcquire" );
			local nEquipID = CTableConfigMgr:Inst():GetConfigNumber( "equip", i, "nID" );
			if nAcquireType == eAcquireType_FragmentFusion then
				self.m_tblAllEquip[nEquipID] = nEquipID;
			end
		end
	end

	local PlayerData = g_App:GetMainPlayerData().m_HaveEquip;
	for i = 1, PlayerData:GetDataCount() do
		local nHaveEquipID = PlayerData:GetData( i - 1 );
		if nHaveEquipID ~= 0 and self.m_tblAllEquip[nHaveEquipID] then
			self.m_tblAllEquip[nHaveEquipID] = nil;
		end
	end

	local bShowRedPoint = false;
	for k, v in pairs( self.m_tblAllEquip ) do 
		local nFragmentID = g_tblTabFile.equip[v].nFragmentID;
		local nCountNeed = g_tblTabFile.equip[v].nFragmentCount;
		local nCurCount = g_App:GetFragmentCount( nFragmentID );
		if nCurCount >= nCountNeed then
			bShowRedPoint = true;
			break;
		end
	end

	self.m_pBtnSkin:ShowRedPoint( bShowRedPoint );
end

function CGameStartLua:NotifyPropGet( tblProps )
	for _,tblProp in pairs( tblProps ) do
		CGetPropTip:new( self, tblProp );
	end
end

function CGameStartLua:NotifyOpenTreasureBox( nTreasureBoxID, tblProp, nExpAdd, nPosIndex, nMatrlIndex )
	if type( tblProp ) ~= "table" or table.count( tblProp ) == 0 then return end; 
	CWndTreasureBoxOpen:new( "gui/cfg/fsj_pifu_baoxiangkaiqi.gui", g_App:GetGUIMgr():GetRootWnd(), 0, nTreasureBoxID, tblProp, nExpAdd, nPosIndex, nMatrlIndex );
end

function CGameStartLua:OpenVipWnd()
	if not g_App:IsGameSwitch( eGameSwitch_Vip ) then
		g_App:MessageBox( g_App:GetString( "bukaifangvip" ) );
		return;
	end
	self.m_pWndVip:ShowWnd( true );
	self.m_pWndVip:SwitchWnd( g_App:GetMainPlayerData():IsVip() );
end

function CGameStartLua:OpenDiamondShop()
	if not g_App:IsGameSwitch( eGameSwitch_Charge ) then
		g_App:MessageBox( g_App:GetString( "bukaifangchongzhi" ) );
		return;
	end
	self.m_pWndShop:ShowAndSetFocus( true );
end

function CGameStartLua:OpenFirstChargePrize()
	if not g_App:IsGameSwitch( eGameSwitch_FirstChargePrize ) then
		g_App:MessageBox( g_App:GetString( "bukaifangshouchong" ) );
		return;
	end
	self.m_pWndFirstChargetPrize:ShowAndSetFocus( true );
end

function CGameStartLua:UpdateFirstChargePrizeBtn()
	self.m_pBtnFristChargePrize:RemoveAllEffects();
	if g_App:GetFirstEvent( eFE_FirstChargePrize ) then
		self.m_pBtnFristChargePrize:ShowWnd( false );
		return;
	end

	if g_App:GetMainPlayerData().m_CharBaseData:GetRechargeID() ~= 0 then
		self.m_pBtnFristChargePrize:AddEffect( "fx/cfg/shouchong01.eft", "fx/cast", nil, -1 );
	else
		self.m_pBtnFristChargePrize:AddEffect( "fx/cfg/shouchong01.eft", "fx/loop", nil, -1 );
	end
end

function CGameStartLua:OnUpdateTime()
	local sTime = GetFormatTimeSTMFromMillisecond( GetLocalTime() );
	local szCurTime = string.format( "%4d-%02d-%02d %02d:%02d:%02d", sTime:m_nYear(), sTime:m_nMonth(), sTime:m_nDayOfMonth(),
		sTime:m_nHour(), sTime:m_nMinutes(), sTime:m_nSecond() );
	self.m_pWndCurTime:SetWndText( szCurTime );
end

function CGameStartLua:ShowPropDescWnd( ParentWnd, nPropType, nPropIndex )
	CWndPropDesc:new( "gui/cfg/fsj_pifu_hecheng_cailiao.gui", ParentWnd, 0, nPropType, nPropIndex );
end

function CGameStartLua:OnClickClan()
	self.m_BtnClan:ShowRedPoint( false );
	self.m_WndClan:ShowWnd( true );
end

function CGameStartLua:OpenSpecialOffer()
	if not g_App:IsGameSwitch( eGameSwitch_SpecialOffer ) then
		g_App:MessageBox( g_App:GetString( "gongnengtips" ) );
		return;
	end
	self.m_pWndSpecialOffer:ShowAndSetFocus();
end

function CGameStartLua:RefreshHeadImg()
	self:RefreshHeadIcon();
	self:RefreshRankWnd();
end

function CWndLimitTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndLimitTip:OnCreated()
	self.m_btnContinue = self:GetDlgChild( "B_OK" );
	self.m_btnContinue:AddActionListener( "OnContinue", self );

	self.m_btnShow = self:GetDlgChild( "buzaitishi" );
end

function CWndLimitTip:OnWndShow( bShow )
	if not bShow then
		if self.m_btnShow:GetCheck() then
			g_App:GetIniFile():WriteInteger( "Setting", "LimitTip", self.m_btnShow:GetCheck() and 0 or 1 );
			g_App:GetIniFile():Save();
		end
		g_App:GetGameStart():EnterRoom();
	end
end

function CWndLimitTip:OnContinue()
	self:ShowWnd( false );
end

function CWndTeamTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndTeamTip:OnCreated()
	self.m_btnContinue = self:GetDlgChild( "B_OK" );
	self.m_btnContinue:AddActionListener( "OnContinue", self );

	self.m_btnShow = self:GetDlgChild( "buzaitishi" );
end

function CWndTeamTip:OnWndShow( bShow )
	if not bShow then
		if self.m_btnShow:GetCheck() then
			g_App:GetIniFile():WriteInteger( "Setting", "TeamTip", self.m_btnShow:GetCheck() and 0 or 1 );
			g_App:GetIniFile():Save();
		end
		g_App:GetGameStart():EnterRoom();
	end
end

function CWndTeamTip:OnContinue()
	self:ShowWnd( false );
end

function CRhythmGuideWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );	
end

function CRhythmGuideWnd:OnCreated()
	self.m_btnEnter = self:GetDlgChild( "tips.btn" );
	self.m_btnEnter:AddActionListener( "OnClickEnter", self );
	self.m_btnClose = self:GetDlgChild( "B_close" );
	self.m_btnClose:AddActionListener( "OnClose", self );
end

function CRhythmGuideWnd:OnWndShow( bShow )
	if bShow then
	
	else
	end
end

function CRhythmGuideWnd:OnClickEnter()
	self:ShowWnd( false );
	g_App:GetGameStart().m_bShowRhythmGuide = true;
	CRhythmGuide:Inst():Start();
end

function CRhythmGuideWnd:OnClose()
	g_App:GetIniFile():WriteInteger( "Setting", "RhythmGuideTip", self:GetDlgChild( "buxianshi" ):GetCheck() and 1 or 0 );
	g_App:GetIniFile():Save();
	self:ShowWnd( false );
end


function CWndPropDesc:Ctor( sResName, nParentWnd, nLoadType, nPropType, nPropIndex )
	CGWnd.Ctor( self, sResName, nParentWnd, nLoadType );
	self.m_nPropType = nPropType;
	self.m_nPropIndex = nPropIndex;
end

function CWndPropDesc:OnCreated()
	self.m_pWndIcon = CRichIconWnd:new( self, "icon" );
	self.m_pWndName = self:GetDlgChild( "name" );
	self.m_pWndDesc = self:GetDlgChild( "w_tujing" );
	self:AddEventListener( GM_WM_MOUSECLICK, "OnClick", self );
	self:SetData();
end

function CWndPropDesc:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndPropDesc:OnWndShow( bShow )
	if not bShow then
		self:DestroyWnd();
	end
end

function CWndPropDesc:SetData()
	local Config = CPropBaseConfigMgr:Inst():GetConfig( self.m_nPropType, self.m_nPropIndex );
	if Config then
		local szName = Config.dName;
		local szDesc = Config.dDescription;
		local nIconID = Config.nIconID;
		self.m_pWndIcon:SetIconID( nIconID );
		self.m_pWndName:SetWndText( szName );
		self.m_pWndDesc:SetWndText( szDesc );
		self:ShowWnd( true );
	end
end

function CWndPropDesc:OnClick( Event )
	self:ShowWnd( false );
end

--endregion