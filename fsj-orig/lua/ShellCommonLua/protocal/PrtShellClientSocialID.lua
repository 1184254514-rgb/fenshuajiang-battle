--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

eSocial_MinId					= 3000; -- 社交从3000开始
eSocial_InstantMessage_MinId	= 3100; -- 即时通讯子模块从3100开始

g_tblPrtClient2Social = 
{
	eC2S_AddFollowee				= 3000;
	eC2S_RemoveFollowee				= 3001;
	eC2S_AddBlacklist				= 3002;
	eC2S_RemoveBlacklist			= 3003;
	eC2S_QueryCharInfo				= 3004;
	eC2S_SetRefuseFollowers			= 3005;
	eC2S_ClearNewFollowers			= 3006;
	eC2S_SendIMNewMessage			= 3007;
	eC2S_QueryRelationshipCount		= 3008;
	eC2S_FuzzySearchClan			= 3009;
	eC2S_JoinClan					= 3010;
	eC2S_ExitClan					= 3011;
	eC2S_KickClan					= 3012;
	eC2S_AccurateSearchClan			= 3013;
	eC2S_QueryPropellClan			= 3014;
	eC2S_QueryApplyList				= 3015;
	eC2S_ClanApplyOperate			= 3016;
	eC2S_SetClanInfo				= 3017;
	eC2S_SetClanMemberPower			= 3018;
	eC2S_CustomSearchClan			= 3019;
};

g_tblPrtSocial2Client =
{
	eS2C_NotifyFriendChanged		= 3000;
	eS2C_NotifyFriendInitData		= 3001;

	eS2C_AnswerAddFollowee			= 3002;
	eS2C_AnswerRemoveFollowee		= 3003;
	eS2C_AnswerAddBlacklist			= 3004;
	eS2C_AnswerRemoveBlacklist		= 3005;
	eS2C_AnswerSetRefuseFollowers	= 3006;
	eS2C_NotifyNewFollower			= 3007;
	eS2C_NotifyRemoveFollower		= 3008;

	eS2C_AnswerIMNewWorldMessage	= 3009;
	eS2C_AnswerIMNewFriendMessage	= 3010;

	eS2C_AnswerBanChat				= 3011;
	eS2C_AnswerRelationshipCount	= 3012;
	eS2C_AnswerFuzzySearchClan		= 3013;
	eS2C_AnswerJoinClan				= 3014;
	eS2C_AnswerExitClan				= 3015;
	eS2C_AnswerKickClan				= 3016;
	eS2C_AnswerQueryPropellClan		= 3017;
	eS2C_AnswerClanOperate			= 3018;
	eS2C_AnswerSetClanInfo			= 3019;
	eS2C_AnswerSetClanMemberPower	= 3020;
	eS2C_AnswerClanApplyListCount	= 3021;
};

--endregion