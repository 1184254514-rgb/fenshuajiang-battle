--region ClientConstValueDefine.lua
--Date 2017.09.26
--客户端常量定义


-------------------------------------玩家成绩记录类型
eGradeType_Begin						=		0;
eGradeType_EndlessToday					=		1;				--无尽、单日
eGradeType_LimitToday					=		2;				--限时、单日
eGradeType_TeamToday					=		3;				--团队、单日
eGradeType_EndlessWeek					=		4;				--无尽、本周
eGradeType_LimitWeek					=		5;				--限时、本周
eGradeType_TeamWeek						=		6;				--团队、本周
eGradeType_EndlessHistory				=		7;				--无尽、历史
eGradeType_LimitHistory					=		8;				--限时、历史
eGradeType_TeamHistory					=		9;				--团战、历史
eGradeType_End							=		10;

------------------------------------ 游戏功能开关(MAX 64) ----------------------
eGameSwitch_Share						=		0;
eGameSwitch_Vip							=		1;
eGameSwitch_Charge						=		2;
eGameSwitch_Rename						=		3;
eGameSwitch_FirstChargePrize			=		4;
eGameSwitch_Picture						=		5;
eGameSwitch_SpecialOffer				=		6;
eGameSwitch_HonorShare					=		7;

------------------------------------音乐下载类型----------------------
eLoadMusicType_Begin					=		0;
eLoadMusicType_Shiting					=		1;				--试听下载
eLoadMusicType_Buy						=		2;				--购买下载
eLoadMusicType_End						=		3;

---------------------------------同一首音乐按速度划分种类
eMusicCount_BySpeed						=		3;

eGameInsideBeyondInit = 0;
eGameInsideBeyondSelf = 1;		--局内排行超越自己
eGameInsideBeyondFriend = 2;		--局内排行超越好友
eGameInsideBeyondWorld = 3;		--局内排行超越世界



-----------------------------------资源获取类型------------------------------
eAcquireType							=		0;
eAcquireType_NoLimit					=		1;					--无限制
eAcquireType_Buy						=		2;					--购买
eAcquireType_FragmentFusion				=		3;					--碎片合成  
eAcquireType_LimitModeUnlock			=		4;					--限时模式解锁奖励  
eAcquireType_TeamModeUnlock				=		5;					--团战模式解锁奖励  
eAcquireType_LimitBattle				=		6;					--限时对战  
eAcquireType_TeamBattle					=		7;					--团战对战  
eAcquireType_Exchange					=		8;					--兑换  
eAcquireType_SeasonPrize				=		9;					--赛季奖励 
eAcquireType_Signature					=		10;					--签到  
eAcquireType_Lottery					=		11;					--转盘抽奖  
eAcquireType_Charge						=		12;					--充值  
eAcquireType_Share						=		13;					--分享
eAcquireType_AccumulateSignature		=		14;					--累计签到  
eAcquireType_OpenTreasureBox			=		15;					--开宝箱  
eAcquireType_Login						=		16;					--登录
eAcquireType_Operation					=		17;					--运营活动获取  

------------------------------主界面宝箱红点显示类型---------------------------
eTreasureBoxButtonRedDot_Begin				=		0;				
eTreasureBoxButtonRedDot_CouldOpenLimit		=		1;				--可开启限时宝箱
eTreasureBoxButtonRedDot_CouldOpenTeam		=		2;				--可开启团战宝箱
eTreasureBoxButtonRedDot_CouldUnlockLimit	=		3;				--可解锁限时宝箱
eTreasureBoxButtonRedDot_CouldUnLockTeam	=		4;				--可解锁团战宝箱
eTreasureBoxButtonRedDot_EmptyLimit			=		5;				--限时宝箱为空
eTreasureBoxButtonRedDot_EmptyTeam			=		6;				--团战宝箱为空
eTreasureBoxbuttonRedDot_OpeningLimit		=		7;				--限时宝箱开启中
eTreasureBoxButtonRedDot_OpeningTeam		=		8;				--团战宝箱开启中

------------------------------技能解锁类型ESkillDevelopDelockType---------------------------
eSDDT_Init				=	0;				--解锁初始化  
eSDDT_LadderStar		=	1;				--角色等级解锁  
eSDDT_PreSkill			=	2;				--前置技能解锁  

------------------------------技能解锁类型ESkillDevelopStateType---------------------------
eSDST_Lock				=	0;				--未解锁，锁定状态
eSDST_CanDeblock		=	1;				--可解锁  
eSDST_Unlock			=	2;				--已解锁，升级中  
eSDST_LevelMax			=	3;				--满级  
eSDST_Count				=	4;			

Max_SkillDevelop_Num	=	128;			--技能养成系统最大技能个数  
Max_Passive_Skill_Num	=	5;				--最大被动技能个数
VIP_Activity_Mul		=	3;				--vip获得签到奖励的资源倍数  


-----------------------------------排行榜相关数值---------------------------
eRankRange_Followees	= 1;			--好友排行  			
eRankRange_AllRegion	= 2;			--世界排行

eRankMode_Ladder		= 1;			--段位排行  
eRankMode_Endless		= 2;			--无尽模式  
eRankMode_Limit			= 3;			--限时模式 
eRankMode_Team			= 4;			--团战模式  
eRankMode_Endless_Area	= 5;			--无尽面积  
eRankMode_Race			= 6;			--赛事模式
eRankMode_Max			= 7;			

eRankCycle_Day			= 1;			--日排行  
eRankCycle_Week			= 2;			--周排行  
eRankCycle_Season		= 3;			--赛季排行  
eRankCycle_History		= 4;			--历史排行 
eRankCycle_Month		= 5;			--月排行  
eRankCycle_Max			= 6;

----------------------------------网络延迟相关数值----------------------------
ePing_low				= 100;
ePing_high				= 200;

----------------------------------图片相关数值--------------------------------
eHeadIconSize			= 128;  
ePhotoSize				= 512;  

--endregion
