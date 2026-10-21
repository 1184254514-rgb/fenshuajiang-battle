--region CGameClient.lua
--Date 2015-12-07

require "CommonInc"
require "GameClientInc"
require "Common"

--以下包含本工程引入的文件
require "ui_frame/CGWnd"
require "ui_frame/CGListCtrl"
require "ui_frame/CGRichWnd"
require "ui_frame/CGEdit"

require "ui_message/CMessageBox"
require "ui_message/CMessageBox3"
require "ui_message/CHideMsg"
require "ui_message/CWaitMsg"

require "debug/CCmdInput"
require "debug/CClientCmdMgr"

require "connect/CGameConnToWorldLua"
require "connect/CGameConnToFieldLua"

require "playerdata/CPlayerDBClient"

require "gamelogin/CGameLogin"
require "gamestart/CGameStartLua"
require "gamestart/CActivityWnd"
require "gamemain/CGameMainLua"
require "gamemain/CNetDelayWnd"
require "gamemain/CKillInfoWnd"
require "gamestart/CWndGuestUpgrade"
require "gamestart/CGetPropTip"
require "gamestart/CRaceWnd"
require "gamestart/CGameStartMisc"
require "gamestart/CTipWnd"
require "gamestart/CWndSpecialOffer"

require "scene/CGameSceneClientLua"
require "character/CPlayerClientLua"

require "misc/CHeadIcon"
require "misc/CPropBaseConfigMgr"
require "misc/CClanLevelConfig"

require "ui_icon/CIconManager"
require "ui_icon/CRichIconWnd"

require "ui_head/CHeadWnd"
require "ui_head/CLevelTipWnd"
require "ui_head/CWndAlterName"
require "ui_head/CWndChangeHeadIcon"
require "ui_head/CHeadBar3DUnit"

require "ui_setting/CSettingWnd"
require "ui_setting/CBtnSettingWnd"

require "chat/CNoticeBar"
require "chat/CSortInfo"

require "ui_team/CTeamWnd"
require "ui_team/CTeamMatchWnd"
require "ui_team/CSecretMatchWnd"
require "ui_team/CRaceRoomWnd"

require "wanfa/CWanfaEndless"
require "wanfa/CWanfaServer"
require "wanfa/ui/CWndSettlemet"
require "wanfa/ui/CWndSettLimit"
require "wanfa/ui/CWndSettTeam"
require "wanfa/ui/CWndSettScore"
require "wanfa/ui/CWndResultEndless"
require "wanfa/ui/CWndRhythmSett"
require "wanfa/ui/CWndLadder"
require "wanfa/ui/CWndBalance"
require "wanfa/ui/CWndRhythmData"
require "wanfa/ui/CWndBalanceShare"

require "ui_music/CWndMusic"
require "ui_music/CWndLoadMusicTips"
require "ui_music/CWndMusicLoadPro"

require "ui_share/CShareWnd"
require "ui_share/CShareChannelWnd"
require "ui_share/CShareContext"

require "ui_other/CSkinWnd"
require "ui_other/CWndRename"
require "ui_other/CWndNewLadderSeason"
require "ui_other/CWndBeCommend"
require "ui_other/CRhythmNoticeBarItem"
require "ui_other/CWndBuyRhythmNoticeBar"

require "gamemain/COutInfoWnd"
require "gamemain/CObserveWnd"

require "rank/CRankDataMgr"
require "rank/CRankWnd"

require "misc/CPlayerGradeInfoMgr"
require "misc/ClientConstValueDefine"
require "misc/CPlayerRoomMemberInfoMgr"

require "ui_guide/CWndGuideVideo"
require "ui_guide/CWndGuideSelect"
require "ui_guide/CWndVideoOrGuide"

require "gamemain/CGameButton"
require "ui_modeopenlimit/CWndModeLimit"
require "ui_modeopenlimit/CWndModeOpenReward"

require "ui_battleface/CWndBattleFaceItem"
require "ui_battleface/CWndBuyBattleFace"

require "social/CFriendMgr"
require "social/friend/CCharListItem"
require "social/friend/CFindFriendPage"
require "social/friend/CFriendInfoPage"
require "social/friend/CFriendWnd"
require "social/friend/CWndPropellPlayer"
require "social/friend/CWndPropellSingle"
require "social/chat/CInstantMessageDataMgr"
require "social/chat/CInstantMessageWnd"
require "social/chat/CUserListItemWnd"
require "social/chat/CContentListPanel"
require "social/chat/CContentListItemWnd"
require "social/chat/CIMFriendWnd"
require "social/chat/CIMWorldWnd"
require "social/chat/CGMServiceWnd"
require "social/chat/CWndGMColumn"

require "ui_treasurebox/CWndTreasureBoxItem"
require "ui_treasurebox/CWndNewTreasureBox"
require "ui_treasurebox/CWndFusionSkinItem"
require "ui_treasurebox/CWndTreasureBoxOpen"
require "ui_treasurebox/CWndFusion"
require "ui_treasurebox/CWndCollectPro"
require "ui_treasurebox/CWndFusionSuccess"
require "ui_treasurebox/CWndTreasureBoxOpretionTips"
require "ui_treasurebox/CWndTreasureBox"
require "ui_treasurebox/CWndAccountLevel"

require "ui_declaration/CWndDeclaration"

require "ui_skill/CSkillDevelopWnd"

require "ui_shop/CWndShop"
require "ui_shop/CWndShopDiamond"
require "ui_shop/CWndFristChargePrize"
require "ui_shop/vip/CWndVip"
require "ui_shop/vip/CWndChargeVip"
require "ui_shop/vip/CWndVipDesc"

require "ui_task/CTaskTipWnd"
require "ui_frame/CWndPropItem"
require "ui_prize/CWndPrizeNotify"
require "ui_prize/CWndPrizePropTip"

require "social/clan/CWndClan"
require "social/clan/CWndClanItem"
require "social/clan/CWndCreateClan"
require "social/clan/CClanMemberItem"
require "social/clan/CWndChooseClanIcon"
require "social/clan/CWndClanApplyList"
require "social/clan/CWndSetClanInfo"
require "social/clan/CWndClanMemberOpr"
require "social/clan/CWndClanCustomSearch"

--所有的require必须放在require "CGameClient"之前   
--否则后果自负，blame之。   
require "CGameClient"

--endregion
