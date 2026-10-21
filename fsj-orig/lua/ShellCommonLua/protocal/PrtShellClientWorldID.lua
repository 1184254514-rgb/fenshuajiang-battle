--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

g_tblPrtClient2World = 
{
	--- ShellProtocalCppClient2WorldBegin
	eC2W_ValidateClient					=	0;
	eC2W_QueryExitGame					=	1;
	eC2W_Rename							=	2;
	eC2W_LimitTimeRoom					=	3;
	eC2W_EndlessData					=	4;
	eC2W_BuySkin						=	5;
	eC2W_UsingSkin						=	6;
	eC2W_QueryActivateCode				=	7;
	eC2W_CreateTeam						=	8;
	eC2W_JoinTeam						=	9;
	eC2W_SetMusic						=	10;
	eC2W_SendMsg2CustomerService		=	11;
	eC2W_ReciveCustomerServiceAnswer	=	12;
	eC2W_AddReport						=	13;
	eC2W_SearchPlayers			    	=	14;
	eC2W_GetFirstChargePrize			=	15;
	eC2W_CreateClan						=	16;
	eC2W_UploadPicture					=	17;
	eC2W_DeletePicture					=	18;
	eC2W_StartMatchTeam					=	19;
	eC2W_StopMatchTeam					=	20;
	eC2W_LeaveTeam  					=	21;
	eC2W_ChangeHeadIcon  				=	22;
	eC2W_BuyMusic						=	23;
	eC2W_InvitePlayer  				    =	24;
	eC2W_JoinGame  		    		    =	25;
	eC2W_RefuseInvite  		    		=	26;
	eC2W_CancelFRRename					=	27;
	eC2W_SpecialOffer					=	28;
	eC2W_QueryPropellPlayer				=	29;
	eC2W_AddCommend						=	30;
	eC2W_QueryPictureData				=	31;
	eC2W_QueryPlayerBaseData			=	37;
	eC2W_GetAllRecordNew				=	41;
	eC2W_SendWorldGMCmd					=	42;
	eC2W_BuyRhythmNoticeBar				=	43;
	eC2W_UseRhythmNoticeBar				=	44;
	eC2W_BuyBattleFace					=	45;
	eC2W_UseBattleFace					=	46;
	eC2W_ObserveGame					=	47;
	eC2W_AddCommendDay					=	48;
	eC2W_QueryRainbowGold				=	49;
	eC2W_AlterUseSkill					=	50;
	eC2W_AchieveGuide					=	51;
	eC2W_UnLockTreasureBox				=	52;
	eC2W_AccelerateTreasureBox			=	53;
	eC2W_CouldOpenTreasureBox			=	54;
	eC2W_OpenTreasureBox				=	55;
	eC2W_Fusion							=	56;
	eC2W_CheckEnterRoom					=	57;
	eC2W_Reserved58						=	58;
	eC2W_Reserved59						=	59;
	eC2W_VideoGuideLog					=	61,
	eC2W_SettingLog						=	62,
	eC2W_ShareResult					=	63,
	eC2W_DiacardTreasureBox				=	64,

	eC2W_QueryChangeMatchPos			=	65;
	eC2W_AnswerChangeMatchPos			=	66;
	eC2W_ChangeMatchReady				=	67;
	eC2W_MatchPosHandle					=	68;

	eC2W_Declaration					=	69;
	eC2W_QueryActivity					=	70;
	eC2W_AlterPassiveSkill				=	71;
	eC2W_UpgradeSkill					=	72;
	eC2W_DelockSkill					=	73;
	eC2W_GuestUpgrade					=	74;
	eC2W_AlterFirstEvent				=	75;
	eC2W_QueryPrize						=	76;
	eC2W_QueryVipPrize					=	77;
	eC2W_JoinRace						=	78;
	eC2W_QueryWorldRaceInfo				=	79;
	eC2W_AlterPlayerInfo				=	80;
	eC2W_AlterSignature					=	81;
	--- ShellProtocalCppClient2WorldEnd;

	--- ShellProtocalLuaClient2WorldBegin 1000
};

g_tblPrtWorld2Client =
{
	eW2C_NotifyPropertyChanged			=	1;
	eW2C_NotifyKick						=	2;
	eW2C_RequestRoomFaild				=	3;
	eW2C_FieldInfo						=	4;
	eW2C_TeamResult				        =	5;
	eW2C_SyncTeamInfo		    		=	6;
	eW2C_NotifyNewWorldPrize			=   7;
	eW2C_NotifyQueueIndex				=	8;
	eW2C_AnsertCustomerServiceMsg		=	9;
	eW2C_NotifyCustomerServiceMsg		=	10;
	eW2C_AnswerSearchPlayers			=	11;
	eW2C_AnswerClanAndMemberInfo		=	12;
	eW2C_AnswerCreateClan				=	13;
	eW2C_AnswerClanApplyInfo			=	14;
	eW2C_AnswerUploadJpgImage			=	15;
	eW2C_AnswerModifyCharName			=	16;
	eW2C_AnswerStartMatchTeam		    =	17;
	eW2C_AnswerStopMatchTeam     	    =	18;
	eW2C_AnswerChangeHeadIcon     	    =	19;
	eW2C_RaceRoomNumbering				=	20;
	eW2C_SendNotice     				=	21;
	eW2C_NotifyInvite            	    =	22;
	eW2C_AnswerBuyMusic					=	23;
    eW2C_AnswerInvite                   =   24;
    eW2C_NotifyRefuseInvite             =   25;
    eW2C_AnswerJoinGame                 =   26;
	eW2C_NotifyBalanceFinished			=	27;
	eW2C_AnswerActivateCode 			=	28;
	eW2C_EndlessDataFinish				=	29;
	eW2C_AnswerDeletePicture			=	30;
	eW2C_World2ClientTips				=	31;
	eW2C_AnswerPropellPlayer			=	32;
	eW2C_NotifyRefreshHeadImg			=	33;
	eW2C_AnswerPictureData				=	34;
--	eW2C_AnswerGetEndlessRecord			=	35;
--	eW2C_AnswerGetLimitRecord			=	36;
--	eW2C_AnswerGetTeamRecord			=	37;
--	eW2C_AnswerGetAllRecord				=	38;
	eW2C_AnswerQueryPlayerBaseData		=	40;
	eW2C_AnswerBuySkin					=	42;
	eW2C_NotifyBeAttention				=	45;
	eW2C_NotifyBeCommend				=	46;
	eW2C_AnswerCheckRoomExit			=	47;
	eW2C_AnswerGetAllRecordNew			=	48;
	eW2C_AnswerBuyrhythmNoticeBar		=	49; 
	eW2C_AnswerBuyBattleFace			=	50;
	eW2C_AnswerObserveGame			    =	51;
	eW2C_AnswerRainbowGold				=	52;
	eW2C_AnwerAccelerateTreasureBox		=	54;
	eW2C_NotifyNewTreasureBox			=	55;
	eW2C_AnswerFusion					=	56;
	eW2C_GetFragment					=	57;
	eW2C_AnswerCheckEnterRoom			=	58;
	eW2C_Resvered67						=	59;
	eW2C_Resvered68						=	60;
	eW2C_AnswerUnlockTreasureBox		=	61;
	eW2C_NotifyQueryChangeMatchPos		=	62;
	eW2C_NotifyAnswerChangeMatchPos		=	63;
	eW2C_NotifyChangeMatchPos			=	64;
	eW2C_NotifyRoomMatchMsg				=	66;
	eW2C_NotAllReady					=	67;
	eW2C_OnWorldConnect					=	68;
	eW2C_AnswerDeclaration				=	69;
	eW2C_AnswerSignInActivityState		=	70;
	eW2C_AnswerRollActivityState		=	71;
	eW2C_SignInActivityResult			=	72;
	eW2C_RollActivityResult				=	73;
	eW2C_AnswerGMAddProp				=	74;
	eW2C_NotifySkillStateChange			=	75;
	eW2C_AnswerGuestUpgradePrize		=	77;
	eW2C_NotifyDelockResult				=	78;
	eW2C_NotifyUpgradeSkillResult		=	79;
	eW2C_AnswerPrize					=	80;
	eW2C_AnswerVipPrize					=	81;
	eW2C_AnswerRaceState				=	83;
	eW2C_NotifyWorldRaceInfo			=	84;
	eW2C_NotifyCloseRaceRoom			=	85;
	eW2C_AnswerJoinRace					=	86;
	eW2C_SendRaceNotice					=	87;
	eW2C_AnswerGMCmd					=	88;
	eW2C_AnswerNewChar					=	89;
	eW2C_NotifyGameSwitch				=	90;
	eW2C_NotifyBeyondWorldRank			=	91;
};

--endregion