--region CGameClientInc.lua
--Date 2015-12-07

--框架
CGameClient = class( CGameAppClient, CEventDispatcher );
CItemCreateHandler = class ( ITableItemCreateHandler );
CGammaResListener = class( IGammaResListener );
CGameMainState = class( CGWnd );
CSceneLoading = class( CGWnd );
CClientCmdMgr = class( CCmdMgrBase );
CCmdInput = class( CGWnd );

CPlayerDBClient = class( CPlayerDB, CEventDispatcher );
CGameLogin = class( CGWnd, IResListener );
CGameStartLua = class( CGameStart );
CGameMainLua = class( CGameMain );
CGameConnToWorldLua = class( CGameConnToWorld );
CGameConnToFieldLua = class( CGameConnToField );
CActivityWnd = class( CGWnd );
CSignInWnd = class( CGWnd );
CWndSignInItem = class( CGButton );
CRollWnd = class( CGWnd );
CWndPrizeitemTip = class( CGWnd );
CRollPrizeTip = class( CGWnd );
CWndGuestUpgrade = class( CGWnd );
CWndGuestUpgradePrize = class( CGWnd );
CGetPropTip = class( CGWnd );
CWndReport = class( CGWnd );
CNewSeasonComing = class( CGWnd );
CTipWnd = class( CGWnd );
CWndSpecialOffer = class( CGWnd );

CGameSceneClientLua = class( CGameSceneClient );
CPlayerClientLua = class( CPlayerClient );

CIconManager = class();
CRichIconWnd = class( CGButton );

CFriendMgr = class();
CHeadIcon = class( CGWnd );
CNetDelayWnd = class( CGWnd );
CKillInfoWnd = class( CGWnd );
COutInfoWnd = class( CGWnd );
CObserveWnd = class( CGWnd );

CCharListItem = class( CGWnd );
CSettingWnd = class( CGWnd );

CTeamWnd = class( CGWnd );
CTeamMatchWnd = class( CGWnd );
CFriendWnd = class( CGWnd );
CFindFriendPage = class( CGWnd );
CFriendInfoPage = class( CGWnd );
CWndPropellPlayer = class( CGWnd );
CWndPropellSingle = class( CGWnd );
CHeadWnd = class( CGWnd );
CLevelTipWnd = class( CGWnd );
CWndAlterName = class( CGWnd );
CWndChangeHeadIcon = class( CGWnd );
CWndAccountForOther = class( CGWnd );
CWndCutPicture = class( CGWnd );
CSecretMatchWnd = class( CGWnd );

CNoticeBar = class( CGWnd );
CSortInfo = class();

CWanfaEndless = class( CWanfaBase );
CWanfaServer = class( CWanfaBase );
CWndSettlemet = class( CGWnd );
CWndSettLimit = class( CGWnd );
CWndSettRandItem = class( CGWnd );
CWndSettTeam = class( CGWnd );
CWndSettTeamItem = class( CGWnd );
CWndSettScore = class( CGWnd );
CWndResultEndless = class( CGWnd );
CWndRhythmSett = class( CGWnd );
CWndLadder = class( CGWnd );
CWndBalance = class( CGWnd );
CWndRename = class( CGWnd );
CWndNewLadderSeason = class( CGWnd );
CWndLadderPrizeItem = class( CGWnd );
CWndBalanceShare = class( CGWnd );

CWndBalanceTip = class( CGWnd );
CWndBalanceDieTip = class( CGWnd );
CTyroWnd = class( CGWnd );
CWndBalanceBeyond = class( CGWnd );
CWndLimitTip = class( CGWnd );
CWndTeamTip = class( CGWnd );
CHeadBar3DUnit = class();

CWndRhythmData = class( CGWnd );
CWndSettlementGuide = class( CGWnd );

CWndMusic = class( CGWnd );
CWndMusicItemHave = class( CGCheckButton );
CWndMusicItemNo = class( CGCheckButton );
CWndBuyMusic = class( CGWnd );
CWndLoadMusicTips = class( CGWnd );
CWndMusicLoadPro = class( CGWnd );
CWndMusicButton = class( CGCheckButton );

CShareWnd = class( CGWnd );
CShareChannelWnd = class( CGWnd );
CShareContext = class();

CWndMainRank1 = class( CGWnd );
CWndMainRank2 = class( CGWnd );
CWndMainRank3 = class( CGWnd );

CSkinWnd = class( CGWnd );
CSkinItemWnd = class( CGCheckButton );
CWndClickBuy = class( CGWnd );
CSkinLingQu = class( CGWnd );

CMessageBox = class( CGWnd );
CMessageBox3 = class( CGWnd );
CHideMsg = class( CGWnd );
CWaitMsg = class( CGWnd );

CWndSettScoreKillItem = class( CGWnd );
CWndSettScoreBeKilledItem = class( CGWnd );

CRankDataMgr = class();
CRankWnd = class( CGWnd );
CRankItemWnd = class( CGButton );

CBtnSettingWnd = class( CGWnd );
CPlayerGradeInfoMgr = class();
CPlayerRoomMemberInfoMgr = class();

CWndGuideVideo = class( CGWnd );
CWndGuideSelect = class( CGWnd );
CWndVideoOrGuide = class( CGWnd );
CRhythmGuideWnd = class( CGWnd );

CWndReconnect = class( CGWnd );

CWndBeCommend = class( CGWnd );

CWndBalanceGoldLimitWnd = class( CGWnd );
CGameButton = class( CGWnd );
CWndModeLimit = class( CGWnd );
CWndModeOpenReward = class( CGWnd );

CRhythmNoticeBarItem = class( CGWnd );
CWndBuyRhythmNoticeBar = class( CGWnd );

CWndBattleFaceItem = class( CGCheckButton );
CWndBuyBattleFace = class( CGWnd );

CInstantMessageDataMgr = class();
CUserListItemWnd = class( CGCheckButton );
CContentListPanel = class( CGListCtrl )
CContentListItemWnd = class( CGWnd );
CIMFriendWnd = class( CGWnd );
CIMWorldWnd = class( CGWnd );
CInstantMessageWnd = class( CGWnd );
CGMServiceWnd = class( CGWnd );
CWndGMColumn = class( CGWnd );

CWndTreasureBoxItem = class( CGWnd );
CWndNewTreasureBox = class( CGWnd );
CWndFusionSkinItem = class( CGCheckButton );
CWndTreasureBoxOpen = class( CGWnd );
CWndTreasureBoxOpretionTips = class( CGWnd );
CWndFusion = class( CGWnd );
CWndCollectPro = class( CGWnd );
CWndFusionSuccess = class( CGWnd );
CWndFragmentDesc = class( CGWnd );
CWndTreasureBox = class( CGWnd );
CWndAccountLevel = class( CGWnd );
CWndAccountLevelItem = class( CGWnd );
CWndAccountLevelLockTips = class( CGWnd );

CTeamCodeWnd = class( CGWnd );
CTeamMatchingWnd = class( CGWnd );

CSkillDevelopWnd = class( CGWnd );
CSkillDevelopItem = class( CGCheckButton );
CSkillDevelopActiveItem = class( CSkillDevelopItem );
CSkillDevelopPassiveItem = class( CSkillDevelopItem );
CLockTipWnd = class( CGWnd );
CRaceWnd = class( CGWnd );
CRaceInfoItem = class( CGWnd );
CRaceRoomWnd = class( CGWnd );
CLimitRaceWnd = class( CGWnd );
CConfirmJoinWnd = class( CGWnd );
CConfirmInviteWnd = class( CGWnd );
CTeamRaceMemberWnd = class( CGWnd );
CTeamRaceWnd = class( CGWnd );

CWndDeclaration = class( CGWnd );

CTaskTipWnd = class( CGWnd )

CWndShop = class( CGWnd );
CWndShopDiamond = class( CGWnd );
CWndShopDiamondItem = class( CGWnd );
CWndPropItem = class( CGWnd );
CWndPrizeNotify = class( CGWnd );
CWndPrizePropTip = class( CGWnd );
CWndVip = class( CGWnd );
CWndChargeVip = class( CGWnd );
CWndVipDesc = class( CGWnd );
CWndFristChargePrize = class( CGWnd );

CWndPropDesc = class( CGWnd );

CWndClan = class( CGWnd );
CWndClanItem = class( CGButton);
CWndCreateClan = class( CGWnd );
CClanLevelConfig = class( CGWnd );
CClanMemberItem = class( CGButton );
CWndChooseClanIcon = class( CGWnd );
CWndClanApplyList = class( CGWnd );
CWndClanApplyListItem = class( CGButton );
CWndClanIconItem = class( CGCheckButton );
CWndSetClanInfo = class( CGWnd );
CWndClanMemberOpr = class( CGWnd );
CWndClanCustomSearch = class( CGWnd );

CPhotoItem = class( CGWnd );
CHeadImage = class( CGCheckButton );
