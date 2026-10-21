--region CWndBalance.lua
--Date 2017.9.1
--此文件由[BabeLua]插件自动生成

local tbl_AllType = 
{
	[eRT_Endless] = "wujin",
	[eRT_LimitTime] = "xianshi",
	[eRT_LimitSecret] = "xianshi",
	[eRT_LimitRace] = "xianshi",
	[eRT_Team] = "tuanzhan",
	[eRT_TeamSecret] = "tuanzhan",
	[eRT_TeamRace] = "tuanzhan",
};
local tbl_AllRank = 
{
	[eVal_D] = "D",
	[eVal_C] = "C",
	[eVal_B] = "B",
	[eVal_A] = "A",
	[eVal_S] = "S",
	[eVal_SS] = "SS",
	[eVal_SSS] = "SSS",
};
local Max_Move_Time = 300;
local Update_Time = 50;
local ChooseBackToMenu = 1;
local ChooseOnceAgain = 2;

function CWndBalance:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
	self.m_tickShow = CTick:new( "OnShowTick", self );
end

function CWndBalance:OnCreated()
	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	self.m_nRoomType = nRoomType;
	self.m_wndEndless = self:GetDlgChild( "wujin" );
	self.m_wndLimit = self:GetDlgChild( "xianshi" );
	self.m_wndTeam = self:GetDlgChild( "tuanzhan" );
	self.m_btnContinue = self:GetDlgChild( "btn_jixu" );
	self.m_btnContinue:AddActionListener( "OnClose", self );
	self.m_wndCur = self:GetDlgChild( tbl_AllType[self.m_nRoomType] );
	self.m_wndWin = self.m_wndCur:GetDlgChild( "win" );
	self.m_wndLose = self.m_wndCur:GetDlgChild( "lose" );
	self.m_wndOut = self.m_wndCur:GetDlgChild( "out" );
	self.m_wndVal = self.m_wndCur:GetDlgChild( "pingjia" );
	self.m_wndLadder = self.m_wndCur:GetDlgChild( "title" );
	self.m_wndFlag = self.m_wndCur:GetDlgChild( "biaoqian" );
	self.m_wndTodayNew = self.m_wndVal:GetDlgChild( "jilu.ri" );
	self.m_wndWeekNew = self.m_wndVal:GetDlgChild( "jilu.zhou" );
	self.m_wndHistoryNew = self.m_wndVal:GetDlgChild( "jilu.lishi" );
	self.m_wndTip = self:GetDlgChild( "tishi" );
	self.m_wndAgain = self:GetDlgChild( "wujin.zailaiyiju" );
	self.m_wndAgain:AddActionListener( "OnClickOnceAgain", self );
	self.m_wndBackMenu = self:GetDlgChild( "wujin.huizhujiemian" );
	self.m_wndBackMenu:AddActionListener( "OnClickBackToMenu", self );
	self.m_wndDetails = self:GetDlgChild( "wujin.pingjia.B_xiangqing" );
	self.m_wndDetails:AddActionListener( "ShowDetails", self );
	self.m_wndShare = self:GetDlgChild( "wujin.fenxiang" );
	self.m_wndShare:AddActionListener( "OnClickShare", self );

	self.m_wndTodayNew:ShowWnd( false );
	self.m_wndWeekNew:ShowWnd( false );
	self.m_wndHistoryNew:ShowWnd( false );
	self.m_wndFlag:ShowWnd( false );
	self.m_btnContinue:ShowWnd( false );
	
	self.m_pGuideButton = self.m_wndEndless:GetDlgChild( "jiaoxue" );
	self.m_pGuideButton:AddActionListener( "OnGuideButton", self );
	self.m_pWndGoldLimit = self:GetDlgChild( "bg_jinbitishi" );
	self.m_pBtnShowGold = self:GetDlgChild( "bg_jinbitishi.tips" );
	self.m_pBtnShowGold:AddActionListener( "OnShowGoldLimitWnd", self );

	self.m_pWndBalanceTip = CWndBalanceTip:new( "gui/cfg/fsj_jiesuan_tips.gui", self, 1 );
	self.m_pWndBalanceGoldLimitTip = CWndBalanceGoldLimitWnd:new( "gui/cfg/fsj_tongyongshuoming.gui", self, 1);
	self.m_pWndBalanceShare = CWndBalanceShare:new( "gui/cfg/fsj_rongyufenxiang.gui", self, 1 );

	self.m_pShareChannelWnd = CShareChannelWnd:new("gui/cfg/fsj_fenxianglianjie.gui", self, 1 );
end

function CWndBalance:OnShowGoldLimitWnd()
	self.m_pWndGoldLimit:ShowWnd( false );
	local TitleText = g_App:GetString( "jinbititle" );
	local NeiRongText = g_App:GetString( "jinbineirong" );
	self.m_pWndBalanceGoldLimitTip:SetText( TitleText,NeiRongText );
	self.m_pWndBalanceGoldLimitTip:ShowWnd( true );
end

function CWndBalance:OnWndShow( bShow )
	self.m_wndEndless:ShowWnd( false );
	self.m_wndLimit:ShowWnd( false );
	self.m_wndTeam:ShowWnd( false ); 
	self.m_pGuideButton:ShowWnd( false );
	if bShow then
		print( "-------------------- !!!!!!!!!!!!!!!!!!!! --------------------", self:GetGlobalX(), self:GetGlobalY() );
		self.m_wndCur:SetGlobalX( self:GetWndWidth() );
		self.m_wndCur:ShowWnd( true );
		self.m_pWndBalanceShare:CheckHonourAndShowShare( self.m_nRoomType, 
			self.m_structScore, self.m_nTeamRank, self.m_nRunTime, 
			self.m_tblBattleInfo, self.m_tblSettlementTeam );

		if self.m_nRoomType ~= eRT_Endless then
			self:InitOriStar();
			self:InitCurStar();
		end
		self:ShowResult();
		self.m_tickShow:Start( Update_Time );

		if self.m_nRoomType == eRT_Endless then
			self:OnGuideCheck();
		end
		local nShowType = eSGT_Loading;
		if self.m_nRoomType == eRT_Endless then
			nShowType = eSGT_Endless;
		elseif self.m_nRoomType == eRT_LimitTime then
			nShowType = eSGT_Limit;
		elseif self.m_nRoomType == eRT_Team then
			nShowType = eSGT_Team;
		end
		self.m_wndTip:SetWndText( CGameTipConfig:Inst():GetString( nShowType, g_App:GetSeasonMaxStar() ) );
	end
end

function CWndBalance:OnClose()
	self:ShowWnd( false );
	local pWanfa = g_App:GetScene():GetWanfa();
	
	if pWanfa:GetGameInsideResult() and pWanfa:GetGameInsideResult() > eGameInsideBeyondInit then
		local pWndBalanceBeyond = pWanfa.m_pWndBalanceBeyond;
		pWndBalanceBeyond:ShowWnd( true );
	elseif pWanfa:GetGameInsideResult() then
		pWanfa:ShowResult();
	end
end

function CWndBalance:Settlement( nSettlementType, nOldStar, nNewestStar, 
	structScore, nTeamRank, sRhythmData, nRunTime, tblBattleInfo, tblSettlementTeam )
	self.m_nSettlementType = nSettlementType;
	self.m_nOriStar = nOldStar;
	self.m_nNewestStar = nNewestStar;
	self.m_structScore = structScore;
	self.m_nTeamRank = nTeamRank;
	self.m_nRhyRank = nRhyRank;
	self.m_nRunTime = nRunTime;
	self.m_sRhythmData = sRhythmData;
	self.m_tblBattleInfo = tblBattleInfo;
	self.m_tblSettlementTeam = tblSettlementTeam;
end

function CWndBalance:OnShowTick()
	local nCurGlobalX = self.m_wndCur:GetGlobalX();
	--print( "CWndBalance:OnShowTick()", nCurGlobalX );
	nCurGlobalX = nCurGlobalX - self.m_wndCur:GetWndWidth() / ( Max_Move_Time / Update_Time );
	if nCurGlobalX <= 0 then
		nCurGlobalX = 0;
		self.m_tickShow:Stop();
	end
	self.m_wndCur:SetGlobalX( nCurGlobalX );
end

function CWndBalance:ShowResult()
	self:ShowRank();
	self:ShowScore();
end

function CWndBalance:ShowRank()		--段位升星为win，否则为lose;无尽模式下S,SS,SSS为win，否则为lose
	local pWanfa = g_App:GetScene():GetWanfa();
	local nCurAllScore = self.m_structScore.nAllScore;
	local bEndlessTodayNew = false;
	local bEndlessWeekNew = false;
	local bEndlessHistoryNew = false;
	local bLimitTodayNew = false;
	local bLimitWeekNew = false;
	local bLimitHistoryNew = false;
	local bTeamTodayNew = false;
	local bTeamWeekNew = false;
	local bTeamHistoryNew = false;
	local tblAllGradeRecord = CPlayerGradeInfoMgr:Instance():GetAllDataNew();
	if not tblAllGradeRecord then return end
	if self.m_nRoomType == eRT_Endless then
		bEndlessTodayNew =  nCurAllScore >= g_data_graderecordshowlevel[1].nEndlessAllScore and 
				nCurAllScore > tblAllGradeRecord[eGradeType_EndlessToday].nAllScore;
		bEndlessWeekNew = nCurAllScore >= g_data_graderecordshowlevel[1].nEndlessAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_EndlessWeek].nAllScore;
		bEndlessHistoryNew = nCurAllScore >= g_data_graderecordshowlevel[1].nEndlessAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_EndlessHistory].nAllScore;

		if bEndlessHistoryNew or bEndlessWeekNew or bEndlessTodayNew then
			self.m_wndFlag:ShowWnd( true );
		end 

		if bEndlessHistoryNew then
			self.m_wndHistoryNew:ShowWnd( true );
		else
			if bEndlessWeekNew then
				self.m_wndWeekNew:ShowWnd( true );
			else
				if bEndlessTodayNew then
					self.m_wndTodayNew:ShowWnd( true );
				end
			end
		end

	elseif self.m_nRoomType == eRT_LimitTime then
		bLimitTodayNew = nCurAllScore >= g_data_graderecordshowlevel[1].nLimitAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_LimitToday].nAllScore;
		bLimitWeekNew = nCurAllScore >= g_data_graderecordshowlevel[1].nLimitAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_LimitWeek].nAllScore;
		bLimitHistoryNew = nCurAllScore >= g_data_graderecordshowlevel[1].nLimitAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_LimitHistory].nAllScore;

		if bLimitHistoryNew or bLimitWeekNew or bLimitTodayNew then
			self.m_wndFlag:ShowWnd( true );
		end 

		if bLimitHistoryNew then
			self.m_wndHistoryNew:ShowWnd( true );
		else
			if bLimitWeekNew then
				self.m_wndWeekNew:ShowWnd( true );
			else
				if bLimitTodayNew then
					self.m_wndTodayNew:ShowWnd( true );
				end
			end
		end

	elseif self.m_nRoomType == eRT_Team then
		bTeamTodayNew = nCurAllScore >= g_data_graderecordshowlevel[1].nTeamAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_TeamToday].nAllScore;
		bTeamWeekNew = nCurAllScore >= g_data_graderecordshowlevel[1].nTeamAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_TeamWeek].nAllScore;
		bTeamHistoryNew = nCurAllScore >=g_data_graderecordshowlevel[1].nTeamAllScore and
				nCurAllScore > tblAllGradeRecord[eGradeType_TeamHistory].nAllScore;

		if bTeamHistoryNew or bTeamWeekNew or bTeamTodayNew then
			self.m_wndFlag:ShowWnd( true );
		end 

		if bTeamHistoryNew then
			self.m_wndHistoryNew:ShowWnd( true );
		else
			if bTeamWeekNew then
				self.m_wndWeekNew:ShowWnd( true );
			else
				if bTeamWeekNew then
					self.m_wndTodayNew:ShowWnd( true );
				end
			end
		end
	end

	if self.m_nRoomType ~= eRT_Endless then
		self.m_btnContinue:ShowWnd( true );
		local nRank = self.m_nTeamRank;
		local nWorldMaxScore = 0;

		if self.m_nRoomType == eRT_LimitTime then
			nWorldMaxScore = g_App:GetGameStart().m_tblRankData.nWorldScore[eGradeType_LimitToday];
		elseif self.m_nRoomType == eRT_Team then 
			nWorldMaxScore = g_App:GetGameStart().m_tblRankData.nWorldScore[eGradeType_TeamToday];
		end		
		local bFirst = nRank == 1;
		if self.m_nChange > 0 then
			self.m_wndWin:GetDlgChild( "paiming" ):SetWndText( nRank );
		else
			self.m_wndLose:GetDlgChild( "paiming" ):SetWndText( nRank );
		end
		self.m_wndCur:GetDlgChild( "bg1" ):ShowWnd( self.m_nSettlementType == eSettlementType_RemainEnd );
		self.m_wndCur:GetDlgChild( "bg2" ):ShowWnd( bFirst and self.m_nSettlementType ~= eSettlementType_RemainEnd );
		self.m_wndCur:GetDlgChild( "bg3" ):ShowWnd( not bFirst and self.m_nSettlementType ~= eSettlementType_RemainEnd );
		
		local bOut = not bFirst and self.m_nSettlementType ~= eSettlementType_RemainEnd;
		self.m_wndWin:ShowWnd( self.m_nChange > 0 and not bOut );
		self.m_wndLose:ShowWnd( self.m_nChange <= 0 and not bOut );
		self.m_wndOut:ShowWnd( bOut );
		if nWorldMaxScore and nWorldMaxScore > 0 then
			local nAllScore = self.m_structScore.nAllScore;
			local str = CStringConfig:Inst():GetString( "wujinchaoyue" );
			nAllScore = math.min( nAllScore, nWorldMaxScore );
			str = string.format( str, string.format( "%.2f%%", nAllScore/nWorldMaxScore * 100 ) );
			self.m_wndWin:GetDlgChild( "chaoyue" ):SetWndText( str );
		end
	else
		local nAllNode = g_App:GetScene():GetNodeTotal();
		local nArea = math.floor( self.m_structScore.nNodeCount / nAllNode * 100 );
		self.m_wndWin:GetDlgChild( "mianji" ):SetWndText( string.format( "%d%%", nArea ));
		local  str = CStringConfig.Inst():GetString( "wujinchaoyue" );
		if nArea <= 1 then
			str = string.format( str, "0%" );
		else
			str = string.format( str, string.format( "%.2f%%", math.log10( nArea ) / 2 * 100 ));
		end
		self.m_wndWin:GetDlgChild( "chaoyue" ):SetWndText( str );			
		self.m_wndCur:GetDlgChild( "bg1" ):ShowWnd( true );

		local nMiss = 0;
		if self.m_sRhythmData.m_nTotle ~= 0 then
			nMiss = math.floor( self.m_sRhythmData.m_aryCount[eVal_Fault] / self.m_sRhythmData.m_nTotle );
		end
		g_App:SetEndlessResult( nArea, nMiss );
	end
end

function CWndBalance:ShowScore()
	local pWanfa = g_App:GetScene():GetWanfa();
	local nRhyRank = self.m_nRhyRank;
	local nRhyGold = CRankPrizeConfig:Inst():GetRhythmLevelPrize( nRhyRank );
	local nMaxKillCoin = self.m_structScore.nMaxKillCoin;
	local nAllScore = self.m_structScore.nAllScore;
	local nPickUpCoin = self.m_structScore.nPickUpCoin;
	local nPrizeCoin = self.m_structScore.nAllCoin;
	local nSerialKillType = self.m_structScore.nSerialKillType;
	local nSerialKillCoin = self.m_structScore.nSerialKillCoin;
	if self.m_nRoomType ~= eRT_Endless then
		self.m_wndVal:GetDlgChild( "w_pingjia" ):SetWndText( tbl_AllRank[nRhyRank] );

		self.m_wndVal:GetDlgChild( "w_defen" ):SetWndText( nAllScore );
		self.m_wndVal:GetDlgChild( "jinbi1" ):SetWndText( nPickUpCoin );
		self.m_wndVal:GetDlgChild( "jinbi2" ):SetWndText( nPrizeCoin );
		self.m_wndVal:GetDlgChild( "jinbi3" ):SetWndText( tostring( nRhyGold ) );
		self.m_wndVal:GetDlgChild( "jinbi4" ):SetWndText( nSerialKillCoin );
		self.m_wndVal:GetDlgChild( "jinbi5" ):SetWndText( nMaxKillCoin );

		if nSerialKillCoin == 0 then
			self.m_wndVal:GetDlgChild( "jinbi4" ):ShowWnd( false );
			self.m_wndVal:GetDlgChild( "bg_liansha" ):ShowWnd( false );
		else
			self.m_wndVal:GetDlgChild( "bg_liansha.sansha" ):ShowWnd( nSerialKillType == eKCT_Three );
			self.m_wndVal:GetDlgChild( "bg_liansha.sisha" ):ShowWnd( nSerialKillType == eKCT_Four );
			self.m_wndVal:GetDlgChild( "bg_liansha.wusha" ):ShowWnd( nSerialKillType == eKCT_Five );
		end
		if nMaxKillCoin == 0 then
			self.m_wndVal:GetDlgChild( "jinbi5" ):ShowWnd( false );
			self.m_wndVal:GetDlgChild( "bg_chaoshen" ):ShowWnd( false );
		end
	else
		local nGameTime = self.m_nRunTime;
		local nAllNode = g_App:GetScene():GetNodeTotal();
		local nArea = self.m_structScore.nNodeCount / nAllNode * 100;
		local szTime = string.format( "%d:%02d:%02d", math.floor( nGameTime/3600 ), math.floor( ( nGameTime%3600 )/60 ), nGameTime%60 );
		self.m_wndVal:GetDlgChild( "w_time" ):SetWndText( szTime );
		self.m_wndVal:GetDlgChild( "w_zongfen" ):SetWndText( string.format( "%.2f%%", nArea ) );
		local nAllCoin = nPrizeCoin + nPickUpCoin + nRhyGold + nSerialKillCoin + nMaxKillCoin;
		self.m_wndVal:GetDlgChild( "w_jiangli" ):SetWndText( nAllCoin );
		
	end
end

function CWndBalance:InitOriStar()
	self.m_nOriLevel = CStarLevelConfig:Inst():GetLevel( self.m_nOriStar );
	self.m_nOriLevelHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_nOriStar );
	self.m_nOriLevelMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nOriStar );
	print( "CWndBalance:InitOriStar() ", self.m_nOriStar );
end

function CWndBalance:InitCurStar()
	self.m_nCurLadderLevel = CStarLevelConfig:Inst():GetLevel( self.m_nNewestStar );
	self.m_nCurLevelHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_nNewestStar );
	self.m_nCurLevelMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nNewestStar );
	self.m_nCurLadderStr = CStarLevelConfig:Inst():GetName( self.m_nNewestStar );
	print( "CWndBalance:InitCurStar()", self.m_nNewestStar, self.m_nOriStar );
	self.m_nChange = self.m_nNewestStar - self.m_nOriStar;
end

function CWndBalance:OnGuideCheck()
	local PlayerData = g_App:GetMainPlayerData().m_CharBaseData;
	local nCurAllGameScore = PlayerData:GetAllGameScore();
	local nTargetAllGameScore = CSnakeConstant:Inst():GetTuanzhanOpenScore();
	local nGameScore = CSnakeConstant:Inst():GetGuideScore();
	if nCurAllGameScore > nTargetAllGameScore or self.m_structScore.nAllScore > nGameScore then
		return;
	end
	
	self.m_pGuideButton:ShowWnd( true );
end

function CWndBalance:OnGuideButton()
	local pGameMain = g_App:GetGameMain();
	pGameMain:PauseSceneMusic( true );
	g_App:GetGuideVideoWnd():PlayVideo( function()
		local pGameMain = g_App:GetGameMain();
		pGameMain:PauseSceneMusic( false );
	end );
end

function CWndBalance:OnClickShare()
	if not g_App:IsGameSwitch( eGameSwitch_HonorShare ) then
		return g_App:HideMsg( g_App:GetString( "fenxiangweikaiqi" ) );
	end
	local pScene = g_App:GetScene();
	local pWanfa = pScene:GetWanfa();
	local nAllNode = pScene:GetNodeTotal();
	local nArea = self.m_structScore.nNodeCount;

	local nScoref = nArea / nAllNode * 100;
	local nScore = math.floor( nScoref );
	local nRank = nArea <= 1 and 0 or math.floor( math.log10( nScoref ) / 2 * 100 );

	local szImgUrl = g_App:CreateRecordUrl( eShareMode_Endless, nScore, nRank, 0, 0, 0 );
	local szSrcName = g_App:GetString( "jiesuanjiemian" );
	local pContext = CShareContext:new( szSrcName );
	pContext:SetImageData( szImgUrl );
	self.m_pShareChannelWnd:SetSDK( pContext );
	self.m_pShareChannelWnd:ShowWnd( true );
end

function CWndBalance:OnClickOnceAgain()
	if not g_App:GetEndlessResult() or g_App:GetIniFile():GetInteger( "Setting", "EndlessBalanceTip", 0 ) ~= 0 then
		self:OnceAgain();
	else
		self.m_pWndBalanceTip.m_nClickFlag = ChooseOnceAgain;
		self.m_pWndBalanceTip:ShowWnd( true );
	end
end

function CWndBalance:OnceAgain()
	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	g_App:SwitchStart();
	g_App:EnterRoom( nRoomType );
end

function CWndBalance:OnClickBackToMenu()
	if not g_App:GetEndlessResult() or g_App:GetIniFile():GetInteger( "Setting", "EndlessBalanceTip", 0 ) ~= 0 then
		self:BackToMenu();
	else
		self.m_pWndBalanceTip.m_nClickFlag = ChooseBackToMenu;
		self.m_pWndBalanceTip:ShowWnd( true );
	end
end

function CWndBalance:BackToMenu()
	g_App:SwitchStart();
end

function CWndBalance:ShowDetails()
	self:ShowWnd( false );
	local pWanfa = g_App:GetScene():GetWanfa();
	pWanfa:ShowResult();
end

function CWndBalanceTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndBalanceTip:OnCreated()
	self.m_btnTeach = self:GetDlgChild( "tips.b1" );
	self.m_btnTeach:AddActionListener( "ShowTeaching", self );
	self.m_btnContinue = self:GetDlgChild( "tips.b2" );
	self.m_btnContinue:AddActionListener( "ContinueChoose", self );
	self.m_btnBack = self:GetDlgChild( "tips.b3" );
	self.m_btnBack:AddActionListener( "BackToMenu", self );
	self.m_nClickFlag = ChooseBackToMenu;
end

function CWndBalanceTip:OnWndShow( bShow )
end

function CWndBalanceTip:ShowTeaching()
	self:ShowWnd( false );
	g_App:GetIniFile():WriteInteger( "Setting", "EndlessBalanceTip", self:GetDlgChild( "buxianshi" ):GetCheck() and 1 or 0 );
	g_App:GetIniFile():Save();
	local pGameMain = g_App:GetGameMain();
	pGameMain:PauseSceneMusic( true );
	g_App:GetGuideVideoWnd():PlayVideo( function()
		local pGameMain = g_App:GetGameMain();
		pGameMain:PauseSceneMusic( false );
	end );
end

function CWndBalanceTip:ContinueChoose()
	g_App:GetIniFile():WriteInteger( "Setting", "EndlessBalanceTip", self:GetDlgChild( "buxianshi" ):GetCheck() and 1 or 0 );
	g_App:GetIniFile():Save();
	self:GetParent():OnceAgain();
----	if self.m_nClickFlag == ChooseBackToMenu then
----		self:GetParent():BackToMenu();
----	elseif self.m_nClickFlag == ChooseOnceAgain then
----		self:GetParent():OnceAgain();
----	end	
end

function CWndBalanceTip:BackToMenu()
	g_App:GetIniFile():WriteInteger( "Setting", "EndlessBalanceTip", self:GetDlgChild( "buxianshi" ):GetCheck() and 1 or 0 );
	g_App:GetIniFile():Save();
	g_App:SwitchStart();
end


function CWndBalanceDieTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndBalanceDieTip:OnCreated()
	self.m_btnTeach = self:GetDlgChild( "B_OK" );
	self.m_btnTeach:AddActionListener( "OnClickOK", self );
end

function CWndBalanceDieTip:OnClickOK()
	self:ShowWnd( false );
	local pWanfa = g_App:GetScene():GetWanfa();	
	if pWanfa:GetGameInsideResult() > eGameInsideBeyondInit then
		local pWndBalanceBeyond = pWanfa.m_pWndBalanceBeyond;
		pWndBalanceBeyond:ShowWnd( true );
	else
		local wndReward = pWanfa.m_pWndModeOpenReward;
		wndReward:ShowWndByRoomType( eRT_Endless );
--		local pWndBalance = pWanfa.m_pWndBalance;
--		pWndBalance:ShowWnd( true );
	end
end

function CWndBalanceBeyond:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndBalanceBeyond:OnCreated()
	self.m_wndEffect = self:GetDlgChild( "tx" );
	self.m_wndSelf = self:GetDlgChild( "ziji" );
	self.m_wndFriend = self:GetDlgChild( "haoyou" );
	self.m_wndWorld = self:GetDlgChild( "shijie" );
	self.m_btbContinue = self:GetDlgChild( "btn_jixu" );
	self.m_btbContinue:AddActionListener( "OnContinue", self );

	self.m_wndServerScore = self:GetDlgChild( "xianshituanzhan" );
	self.m_wndEndlessArea = self:GetDlgChild( "wujin" );
	self.m_wndServerScore:ShowWnd( false );
	self.m_wndEndlessArea:ShowWnd( false );

	self.m_wndEndlessTitle = self:GetDlgChild( "wujintitle" );
	self.m_wndLimitTitle = self:GetDlgChild( "xianshititle" );
	self.m_wndTeamTitle = self:GetDlgChild( "tuanzhantitle" );

	self.m_pBtnShare = self:GetDlgChild( "btn_fenxiang" );
	self.m_pBtnShare:AddActionListener( "OnClickBeyondShare", self );
	
	self.m_pShareChannelWnd = CShareChannelWnd:new("gui/cfg/fsj_fenxianglianjie.gui", self, 1 );
	self.m_wndSelf:ShowWnd( false );
	self.m_wndFriend:ShowWnd( false );
	self.m_wndWorld:ShowWnd( false );
	self.m_tblEffect = 
	{
		{ cast = "fx/cfg/jm_chaoyue_wode_c.eft", loop = "fx/cfg/jm_chaoyue_wode.eft" },
		{ cast = "fx/cfg/jm_chaoyue_haoyou_c.eft", loop = "fx/cfg/jm_chaoyue_haoyou.eft" },
		{ cast = "fx/cfg/jm_chaoyue_shijie_c.eft", loop = "fx/cfg/jm_chaoyue_shijie.eft" },
	};
end

function CWndBalanceBeyond:InitSettlementData( structScore )
	self.m_structScore = structScore;
end

function CWndBalanceBeyond:OnWndShow( bShow )
	local pScene = g_App:GetScene();
	local pWanfa = pScene:GetWanfa();
	if bShow then
		self.m_wndEffect:RemoveAllEffects();
		self.m_wndEffect:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnEffectPlayComplete", self );
		local nIndex = pWanfa:GetGameInsideResult();
		self.m_wndEffect:AddEffect( self.m_tblEffect[nIndex].cast, "fx/loop", "beyond", 0 );
		
		self.m_wndEndlessTitle:ShowWnd( pScene:GetRoomType() == eRT_Endless );
		self.m_wndLimitTitle:ShowWnd( pScene:GetRoomType() == eRT_LimitTime );
		self.m_wndTeamTitle:ShowWnd( pScene:GetRoomType() == eRT_Team );
		self.m_pBtnShare:ShowWnd( false );

		if pScene:GetRoomType() == eRT_Endless then
			local nAllNode = pScene:GetNodeTotal();
			local nArea = self.m_structScore.nNodeCount / nAllNode * 100;
			self.m_wndEndlessArea:GetDlgChild( "ziji" ):SetWndText( string.format( "%.2f%%", nArea ) );

			local tblRankData = g_App:GetCurRankData( eGradeType_EndlessToday );
			if pWanfa:GetGameInsideResult() == eGameInsideBeyondSelf then
				self.m_wndEndlessArea:GetDlgChild( "wodebg" ):ShowWnd( true );
				self.m_wndEndlessArea:GetDlgChild( "haoyoubg" ):ShowWnd( false );
				self.m_wndEndlessArea:GetDlgChild( "shijiebg" ):ShowWnd( false );
				self.m_wndEndlessArea:GetDlgChild( "wode" ):SetWndText( string.format( "%.2f%%", tblRankData.nTodayScore * 100 ) );
			elseif pWanfa:GetGameInsideResult() == eGameInsideBeyondFriend then
				self.m_wndEndlessArea:GetDlgChild( "wodebg" ):ShowWnd( false );
				self.m_wndEndlessArea:GetDlgChild( "haoyoubg" ):ShowWnd( true );
				self.m_wndEndlessArea:GetDlgChild( "shijiebg" ):ShowWnd( false );
				self.m_wndEndlessArea:GetDlgChild( "haoyou" ):SetWndText( string.format( "%.2f%%", tblRankData.nFriendScore * 100 ) );
			elseif pWanfa:GetGameInsideResult() == eGameInsideBeyondWorld then
				self.m_wndEndlessArea:GetDlgChild( "wodebg" ):ShowWnd( false );
				self.m_wndEndlessArea:GetDlgChild( "haoyoubg" ):ShowWnd( false );
				self.m_wndEndlessArea:GetDlgChild( "shijiebg" ):ShowWnd( true );
					self.m_pBtnShare:ShowWnd( g_App:IsGameSwitch( eGameSwitch_HonorShare ) );
				self.m_wndEndlessArea:GetDlgChild( "shijie" ):SetWndText( string.format( "%.2f%%", tblRankData.nWorldScore * 100 ) );
			end			

			self.m_wndEndlessArea:ShowWnd( true );
		else
			local nAllScore = self.m_structScore.nAllScore;
			self.m_wndServerScore:GetDlgChild( "ziji" ):SetWndText( nAllScore );

			local tblRankData = {};
			if pScene:GetRoomType() == eRT_LimitTime then
				tblRankData = g_App:GetCurRankData( eGradeType_LimitToday );
			elseif pScene:GetRoomType() == eRT_Team then
				tblRankData = g_App:GetCurRankData( eGradeType_TeamToday );
			end			
			
			if pWanfa:GetGameInsideResult() == eGameInsideBeyondSelf then
				self.m_wndServerScore:GetDlgChild( "wodebg" ):ShowWnd( true );
				self.m_wndServerScore:GetDlgChild( "haoyoubg" ):ShowWnd( false );
				self.m_wndServerScore:GetDlgChild( "shijiebg" ):ShowWnd( false );
				self.m_wndServerScore:GetDlgChild( "wode" ):SetWndText( tblRankData.nTodayScore );
			elseif pWanfa:GetGameInsideResult() == eGameInsideBeyondFriend then
				self.m_wndServerScore:GetDlgChild( "wodebg" ):ShowWnd( false );
				self.m_wndServerScore:GetDlgChild( "haoyoubg" ):ShowWnd( true );
				self.m_wndServerScore:GetDlgChild( "shijiebg" ):ShowWnd( false );
				self.m_wndServerScore:GetDlgChild( "haoyou" ):SetWndText( tblRankData.nFriendScore );
			elseif pWanfa:GetGameInsideResult() == eGameInsideBeyondWorld then
				self.m_wndServerScore:GetDlgChild( "wodebg" ):ShowWnd( false );
				self.m_wndServerScore:GetDlgChild( "haoyoubg" ):ShowWnd( false );
				self.m_wndServerScore:GetDlgChild( "shijiebg" ):ShowWnd( true );
					self.m_pBtnShare:ShowWnd( g_App:IsGameSwitch( eGameSwitch_HonorShare ) );
				self.m_wndServerScore:GetDlgChild( "shijie" ):SetWndText( tblRankData.nWorldScore );
			end

			self.m_wndServerScore:ShowWnd( true );
		end

	else
		pWanfa:SetGameInsideResult( g_eGameInsideBeyondInit );
		if pScene:GetRoomType() == eRT_Endless then
			pScene:GetWanfa().m_pWndModeOpenReward:ShowWndByRoomType( eRT_Endless );
		elseif pScene:GetRoomType() == eRT_LimitTime then
			pWanfa:ShowLadder();
		elseif pScene:GetRoomType() == eRT_Team then
			pWanfa:ShowResult();
		end
	end
end

function CWndBalanceBeyond:OnClickBeyondShare()
	local pScene = g_App:GetScene();
	if not pScene then
		self.m_pBtnShare:ShowWnd( false );
		return;
	end
	local pWanfa = pScene:GetWanfa();
	if not pWanfa then
		self.m_pBtnShare:ShowWnd( false );
		return;
	end
	local nRoomType = pScene:GetRoomType();
	if pWanfa:GetGameInsideResult() ~= eGameInsideBeyondWorld then
		self.m_pBtnShare:ShowWnd( false );
		return;
	end
	
	local nModeType = 1;	--无尽
	if nRoomType == eRT_LimitTime then
		nModeType = 2;
	elseif nRoomType == eRT_Team then
		nModeType = 3;
	end

	local szImgUrl = g_App:CreateHonourUrl( nModeType, self.m_structScore.nAllScore, 0, eHornorShareType_BeyondWorld, 0, 0 );
	print( "------------------" );
	print( nModeType, self.m_structScore.nAllScore, "11111111111111111", szImgUrl );
	local szSrcName = g_App:GetString( "jiesuanjiemian" );
	local pContext = CShareContext:new( szSrcName );
	pContext:SetImageData( szImgUrl );
	self.m_pShareChannelWnd:SetSDK( pContext );
	self.m_pShareChannelWnd:ShowWnd( true );
end

function CWndBalanceBeyond:OnContinue()
	self:ShowWnd( false );
end

function CWndBalanceBeyond:OnEffectPlayComplete()
	local pScene = g_App:GetScene();
	local pWanfa = pScene:GetWanfa();
	local nIndex = pWanfa:GetGameInsideResult();
	self.m_wndEffect:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnEffectPlayComplete", self );
	self.m_wndSelf:ShowWnd( pWanfa:GetGameInsideResult() == eGameInsideBeyondSelf );
	self.m_wndFriend:ShowWnd( pWanfa:GetGameInsideResult() == eGameInsideBeyondFriend );
	self.m_wndWorld:ShowWnd( pWanfa:GetGameInsideResult() == eGameInsideBeyondWorld );
	self.m_wndEffect:AddEffect( self.m_tblEffect[nIndex].loop, "fx/loop", "beyond", -1 );
end


function CWndBalanceGoldLimitWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndBalanceGoldLimitWnd:OnCreated()
	self.m_pBtnOk = self:GetDlgChild( "close" );
	self.m_pWndTitle = self:GetDlgChild( "title" );
	self.m_pWndNeirong = self:GetDlgChild( "neirong" );
	self.m_pBtnOk:AddActionListener( "OnClickClose", self );
	
end

function CWndBalanceGoldLimitWnd:SetText( TitleText,NeiRongText )
	self.m_pWndTitle:SetWndText( TitleText );
	self.m_pWndNeirong:SetWndText( NeiRongText );
end

function CWndBalanceGoldLimitWnd:OnClickClose()
	self:ShowWnd( false );
	self:GetParent().m_pWndGoldLimit:ShowWnd( true );
end
--endregion
