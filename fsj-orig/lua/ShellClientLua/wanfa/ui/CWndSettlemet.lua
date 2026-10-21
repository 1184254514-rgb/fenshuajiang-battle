--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndSettlemet:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndSettlemet:OnCreated()
	self.m_nRoomType = g_App:GetScene():GetRoomType();

	self.m_pBtnRank1 = self:GetDlgChild( "btn_zuo.btn_1" );
	self.m_pBtnRank4 = self:GetDlgChild( "btn_zuo.btn4" );
	self.m_listBaseMap = self:GetDlgChild( "list" );
	self.m_pWndTips = self:GetDlgChild( "tips" );
	self.m_pBtnScore = self:GetDlgChild( "btn_zuo.btn_2" );
	self.m_pBtnRhythm = self:GetDlgChild( "btn_zuo.btn_3" );
	self.m_pBtnContinue = self:GetDlgChild( "btn_jixuyouxi" );
	self.m_pBtnBlock = self:GetDlgChild( "btn_huizhujiemian" );
	self.m_wndShare = self:GetDlgChild( "btn_jietu" );

	self.m_pWndTeamRank = CWndSettTeam:new( "gui/cfg/fsj_tuanzhan_jiesuan_duiwupaiming.gui", self.m_listBaseMap, 1 );
	self.m_pWndLimitRank = CWndSettLimit:new( "gui/cfg/fsj_xianshimoshi_benjupaiming.gui", self.m_listBaseMap, 1 );
	self.m_pWndRhythmData = CWndRhythmData:new( "gui/cfg/fsj_xianshimoshi_jiezoutongji.gui", self.m_listBaseMap, 1 );
	self.m_pWndScore = CWndSettScore:new( "gui/cfg/fsj_xianshimoshi_gerenjifen.gui", self.m_listBaseMap, 1 );
	self.m_pShareChannelWnd = CShareChannelWnd:new("gui/cfg/fsj_fenxianglianjie.gui", self, 1 );

	if self.m_nRoomType == eRT_LimitTime 
		or self.m_nRoomType == eRT_LimitSecret 
		or self.m_nRoomType == eRT_LimitRace then
		self.m_pBtnRank = self.m_pBtnRank1;
	elseif self.m_nRoomType == eRT_Team 
		or self.m_nRoomType == eRT_TeamSecret 
		or self.m_nRoomType == eRT_TeamRace then
		self.m_pBtnRank = self.m_pBtnRank4;
	end
	self.m_pBtnRank1:ShowWnd( false );
	self.m_pBtnRank4:ShowWnd( false );
	self.m_pBtnRank:ShowWnd( true );
	self.m_pBtnScore:GetDlgChild( "xinjilu" ):ShowWnd( false );
	self.m_pBtnRhythm:GetDlgChild( "xinjilu" ):ShowWnd( false );

	self.m_wndShare:AddActionListener( "OnClickShare", self );
	self.m_pWndReport = CWndReport:new( "gui/cfg/fsj_jubaowanjia.gui", self, 1 );

	self.m_pBtnRank:AddActionListener( "OnBottomClick", self );
	self.m_pBtnScore:AddActionListener( "OnBottomClick", self );
	self.m_pBtnRhythm:AddActionListener( "OnBottomClick", self );
	self.m_pBtnContinue:AddActionListener( "OnContinue", self );
	self.m_pBtnBlock:AddActionListener( "OnBlock", self );
end

function CWndSettlemet:OnBottomClick( Event )
	local pWnd = Event.m_CurrentTarget;
	if pWnd == self.m_pBtnRhythm and self.m_pBtnRhythm:GetDlgChild( "xinjilu" ):IsShow() then
		self.m_pBtnRhythm:GetDlgChild( "xinjilu" ):ShowWnd( false );
	end
	if pWnd == self.m_pBtnScore and self.m_pBtnScore:GetDlgChild( "xinjilu" ):IsShow() then
		self.m_pBtnScore:GetDlgChild( "xinjilu" ):ShowWnd( false );
	end

	self.m_pWndLimitRank:ShowWnd( pWnd == self.m_pBtnRank and ( self.m_nRoomType == eRT_LimitTime or self.m_nRoomType == eRT_LimitSecret or self.m_nRoomType == eRT_LimitRace ) );
	self.m_pWndTeamRank:ShowWnd( pWnd == self.m_pBtnRank and ( self.m_nRoomType == eRT_Team or self.m_nRoomType == eRT_TeamSecret or self.m_nRoomType == eRT_TeamRace ) );
	self.m_pWndScore:ShowWnd( pWnd == self.m_pBtnScore );
	self.m_pWndRhythmData:ShowWnd( pWnd == self.m_pBtnRhythm );
end

function CWndSettlemet:OnClickShare()
	if not g_App:IsGameSwitch( eGameSwitch_HonorShare ) then
		return g_App:HideMsg( g_App:GetString( "fenxiangweikaiqi" ) );
	end
	local pScene = g_App:GetScene();
	local pWanfa = pScene:GetWanfa();

	local nModeType = 0;
	local nScore = 0;

	if self.m_nRoomType == eRT_LimitTime then
		nModeType = 2;

		for _, Data in pairs( self.m_tblBattleInfo ) do
			if Data.m_szKillerNickName == szSelfNickName then
				nScore = nScore + Data.m_nCount;
			end
		end
	elseif self.m_nRoomType == eRT_Team then
		nModeType = 3;

		local nTeamScore = 0;
		local nSelfScore = self.m_tblSettlementTeam[self.m_nTeamRank][self.m_nPlayerRank].m_nAllScore;
		for _,info in pairs( self.m_tblSettlementTeam[self.m_nTeamRank] ) do
			nTeamScore = nTeamScore + info.m_nAllScore;
		end
		nScore = math.floor( nSelfScore / nTeamScore * 100 );
	end
	
	local szImgUrl = g_App:CreateHonourUrl( nModeType, nScore, self.m_nTeamRank, 0, 0, 0 );
	print( "------------------" );
	print( nModeType, nScore, "333333333333333333333", szImgUrl );
	local szSrcName = g_App:GetString( "jiesuanfenshujiemian" );
	local pContext = CShareContext:new( szSrcName );
	pContext:SetImageData( szImgUrl );
	self.m_pShareChannelWnd:SetSDK( pContext );
	self.m_pShareChannelWnd:ShowWnd( true );
end

function CWndSettlemet:OnContinue()
	g_App:SwitchStart();
	g_App:EnterRoom( self.m_nRoomType );
end

function CWndSettlemet:OnBlock()
	local wndGameStart = g_App.m_GameStart;
	if wndGameStart then
		local wndTeam1 = wndGameStart:GetTeamWnd( 0 );
		local wndTeam2 = wndGameStart:GetTeamWnd( 1 );
		if wndTeam1 then
			wndTeam1:ShowWnd( false );
		end
		if wndTeam2 then
			wndTeam2:ShowWnd( false );
		end
	end
	g_App:SwitchStart();
	if( g_App.m_nNewTreasureBoxID ) then
		wndGameStart:GetNewTreasureBoxWnd():SetData( g_App.m_nNewTreasureBoxID );
	end
end

function CWndSettlemet:Settlement( nSettType, bIsObserver, structScore, sRhythmData, 
		nTeamRank, nPlayerRank, tblSettlementTeam, tblBattleInfo, nRunTime )
	self.m_nTeamRank = nTeamRank;
	self.m_nPlayerRank = nPlayerRank;
	self.m_tblSettlementTeam = tblSettlementTeam;
	self.m_tblBattleInfo = tblBattleInfo;
	self.m_tblHasReport = {};

	self.m_pWndRhythmData:UpdateData( sRhythmData, nRunTime );
	if self.m_nRoomType == eRT_LimitTime 
		or self.m_nRoomType == eRT_LimitSecret 
		or self.m_nRoomType == eRT_LimitRace then
		self.m_pWndTips:SetWndText( g_App:GetString( "xianshichujutips1" ) );
		self.m_pWndLimitRank:UpdateData( nTeamRank, nPlayerRank, tblSettlementTeam );
	elseif self.m_nRoomType == eRT_Team 
		or self.m_nRoomType == eRT_TeamSecret 
		or self.m_nRoomType == eRT_TeamRace then
		self.m_pWndTips:SetWndText( g_App:GetString( "tuanzhanchujutips1" ) );
		self.m_pWndTeamRank:UpdateData( nSettType, nTeamRank, nPlayerRank, tblSettlementTeam );
	end
	
	local selfInfo = tblSettlementTeam[nTeamRank][nPlayerRank];
	self.m_pWndScore:UpdateWndData( structScore, self.m_tblBattleInfo, selfInfo.m_szNickName );

	local bNewToday, bNewWeek, bNewHistory = 
		self:GetNewRecord( self.m_nRoomType, sRhythmData.m_nMaxCombo );
	self.m_pWndRhythmData:ShowNewRecord( bNewToday, bNewWeek, bNewHistory );
	self.m_pWndRhythmData:ShowWnd( false );
	if bNewToday or bNewWeek or bNewHistory then
		self.m_pBtnRhythm:GetDlgChild( "xinjilu" ):ShowWnd( true );
	end

	self.m_pWndTips:ShowWnd( nSettType == eSettlementType_CurShort );
    self.m_wndShare:ShowWnd( not bIsObserver );

	self:CheckScoreButtonTag(
		structScore.nAllScore, 
		structScore.nAreaScore, 
		structScore.nKillScore, 
		structScore.nComboScore );
end

function CWndSettlemet:ShowScore()
	self.m_pWndLimitRank:ShowWnd( self.m_nRoomType == eRT_LimitTime or self.m_nRoomType == eRT_LimitSecret or self.m_nRoomType == eRT_LimitRace );
	self.m_pWndTeamRank:ShowWnd( self.m_nRoomType == eRT_Team or self.m_nRoomType == eRT_TeamSecret or self.m_nRoomType == eRT_TeamRace );
	self.m_pWndScore:ShowWnd( false );
	self.m_pBtnRank:SetCheck( true );
end

function CWndSettlemet:GetNewRecord( nRoomType, nCurComboCount )
	local tblAllGradeRecord = CPlayerGradeInfoMgr:Instance():GetAllDataNew();

	local bNewToday = false;
	local bNewWeek = false;
	local bNewHistory = false;
	if not tblAllGradeRecord or not next( tblAllGradeRecord ) then 
		return bNewToday, bNewWeek, bNewHistory;
	end;

	local nMaxComboRecordToday = 0;
	local nMaxComboRecordWeek = 0;
	local nMaxComboRecordHistory = 0;
	local nMaxComboStandard = 0;

	if nRoomType == eRT_LimitTime then
		nMaxComboRecordToday = tblAllGradeRecord[eGradeType_LimitToday].nMaxCombo;
		nMaxComboRecordWeek = tblAllGradeRecord[eGradeType_LimitWeek].nMaxCombo;
		nMaxComboRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nMaxCombo;
		nMaxComboStandard = g_data_graderecordshowlevel[1].nLimitMaxCombo;
		bNewToday = nCurComboCount >= nMaxComboStandard and nCurComboCount > nMaxComboRecordToday;
		bNewWeek = nCurComboCount >= nMaxComboStandard and nCurComboCount > nMaxComboRecordWeek;
		bNewHistory = nCurComboCount >= nMaxComboStandard and nCurComboCount > nMaxComboRecordHistory;
	elseif nRoomType == eRT_Team then
		nMaxComboRecordToday = tblAllGradeRecord[eGradeType_TeamToday].nMaxCombo;
		nMaxComboRecordWeek = tblAllGradeRecord[eGradeType_TeamWeek].nMaxCombo;
		nMaxComboRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nMaxCombo;
		nMaxComboStandard = g_data_graderecordshowlevel[1].nTeamMaxCombo;
		bNewToday = nCurComboCount >= nMaxComboStandard and nCurComboCount > nMaxComboRecordToday;
		bNewWeek = nCurComboCount >= nMaxComboStandard and nCurComboCount > nMaxComboRecordWeek;
		bNewHistory = nCurComboCount >= nMaxComboStandard and nCurComboCount > nMaxComboRecordHistory;
	end	

	return bNewToday, bNewWeek, bNewHistory;
end

function CWndSettlemet:CheckScoreButtonTag( nAllScore, nAreaScore, nKillScore, nComboScore )
	local nCurAllScore = nAllScore;
	local nCurAreaScore = nAreaScore;
	local nCurKillScore = nKillScore;
	local nCurRhythmScore = nComboScore;

	local nAllScoreRecordToday = 0;
	local nAllScoreRecordWeek = 0;
	local nAllScoreRecordHistory = 0;
	local nAreaScoreRecordToday = 0;
	local nAreaScoreRecordWeek = 0;
	local nAreaScoreRecordHistory = 0;
	local nKillScoreRecordToday = 0;
	local nKillScoreRecordWeek = 0;
	local nKillScoreRecordHistory = 0;
	local nRhythmScoreRecordToday = 0;
	local nRhythmScoreRecordWeek = 0;
	local nRhythmScoreRecordHistory = 0;

	local nStandardAllScore = 0;
	local nStandardAreaScore = 0;
	local nStandardKillScore = 0;
	local nStandardRhyScore = 0;

	local tblAllGradeRecord = CPlayerGradeInfoMgr:Instance():GetAllDataNew();
	if not tblAllGradeRecord then return end;	

	if self.m_nRoomType == eRT_LimitSecret 
		or self.m_nRoomType == eRT_TeamSecret
		or self.m_nRoomType == eRT_LimitRace 
		or self.m_nRoomType == eRT_TeamRace then
		return;
	end

	if self.m_nRoomType == eRT_LimitTime then
		nAllScoreRecordToday = tblAllGradeRecord[eGradeType_LimitToday].nAllScore;
		nAllScoreRecordWeek = tblAllGradeRecord[eGradeType_LimitWeek].nAllScore;
		nAllScoreRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nAllScore;
		nAreaScoreRecordToday = tblAllGradeRecord[eGradeType_LimitToday].nAreaScore;
		nAreaScoreRecordWeek = tblAllGradeRecord[eGradeType_LimitWeek].nAreaScore;
		nAreaScoreRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nAreaScore;
		nKillScoreRecordToday = tblAllGradeRecord[eGradeType_LimitToday].nKillScore;
		nKillScoreRecordWeek = tblAllGradeRecord[eGradeType_LimitWeek].nKillScore;
		nKillScoreRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nKillScore;
		nRhythmScoreRecordToday = tblAllGradeRecord[eGradeType_LimitToday].nMaxCombo;
		nRhythmScoreRecordWeek = tblAllGradeRecord[eGradeType_LimitWeek].nMaxCombo;
		nRhythmScoreRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nMaxCombo;
		nStandardAllScore = g_data_graderecordshowlevel[1].nLimitAllScore;
		nStandardAreaScore = g_data_graderecordshowlevel[1].nLimitAreaScore;
		nStandardKillScore = g_data_graderecordshowlevel[1].nLimitKillScore;
		nStandardRhyScore = g_data_graderecordshowlevel[1].nLimitRhythmScore;
	elseif self.m_nRoomType == eRT_Team then
		nAllScoreRecordToday = tblAllGradeRecord[eGradeType_TeamToday].nAllScore;
		nAllScoreRecordWeek = tblAllGradeRecord[eGradeType_TeamWeek].nAllScore;
		nAllScoreRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nAllScore;
		nAreaScoreRecordToday = tblAllGradeRecord[eGradeType_TeamToday].nAreaScore;
		nAreaScoreRecordWeek = tblAllGradeRecord[eGradeType_TeamWeek].nAreaScore;
		nAreaScoreRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nAreaScore;
		nKillScoreRecordToday = tblAllGradeRecord[eGradeType_TeamToday].nKillScore;
		nKillScoreRecordWeek = tblAllGradeRecord[eGradeType_TeamWeek].nKillScore;
		nKillScoreRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nKillScore;
		nRhythmScoreRecordToday = tblAllGradeRecord[eGradeType_TeamToday].nMaxCombo;
		nRhythmScoreRecordWeek = tblAllGradeRecord[eGradeType_TeamWeek].nMaxCombo;
		nRhythmScoreRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nMaxCombo;
		nStandardAllScore = g_data_graderecordshowlevel[1].nTeamAllScore;
		nStandardAreaScore = g_data_graderecordshowlevel[1].nTeamAreaScore;
		nStandardKillScore = g_data_graderecordshowlevel[1].nTeamKillScore;
		nStandardRhyScore = g_data_graderecordshowlevel[1].nTeamRhythmScore;	
	end	

	local tblBool = {};

	local bNewAllToday = nCurAllScore >= nStandardAllScore and nCurAllScore > nAllScoreRecordToday; 
	tblBool[1] = bNewAllToday;
	local bNewAllWeek = nCurAllScore >= nStandardAllScore and nCurAllScore > nAllScoreRecordWeek;
	tblBool[2] = bNewAllWeek;
	local bNewAllHistory = nCurAllScore >= nStandardAllScore and nCurAllScore > nAllScoreRecordHistory;
	tblBool[3] = bNewAllHistory;
	local bNewAreaToday = nCurAreaScore >= nStandardAreaScore and nCurAreaScore > nAreaScoreRecordToday;
	tblBool[4] = bNewAreaToday;
	local bNewAreaWeek = nCurAreaScore >= nStandardAreaScore and nCurAreaScore > nAreaScoreRecordWeek;
	tblBool[5] = bNewAreaWeek;
	local bNewAreaHistory = nCurAreaScore >= nStandardAreaScore and nCurAreaScore > nAreaScoreRecordHistory;
	tblBool[6] = bNewAreaHistory;
	local bNewKillToday = nCurKillScore > nStandardKillScore and nCurKillScore > nKillScoreRecordToday;
	tblBool[7] = bNewKillToday;
	local bNewKillWeek = nCurKillScore > nStandardKillScore and nCurKillScore > nKillScoreRecordWeek;
	tblBool[8] = bNewKillWeek;
	local bNewKillHistory = nCurKillScore > nStandardAllScore and nCurKillScore > nKillScoreRecordHistory;
	tblBool[9] = bNewKillHistory;
	local bNewRhyToday = nCurRhythmScore > nStandardRhyScore and nCurRhythmScore > nRhythmScoreRecordToday;
	tblBool[10] = bNewRhyToday;
	local bNewRhyWeek = nCurRhythmScore > nStandardRhyScore and nCurRhythmScore > nRhythmScoreRecordWeek;
	tblBool[11] = bNewRhyWeek;
	local bNewRhyHistory = nCurRhythmScore > nStandardRhyScore and nCurRhythmScore > nRhythmScoreRecordHistory;
	tblBool[12] = bNewRhyHistory;

	local bShow = false;
	for k, v in pairs( tblBool ) do
		if v == true then
			bShow = true;
			break;
		end
	end
	
	self.m_pBtnScore:GetDlgChild( "xinjilu" ):ShowWnd( bShow );
end


-------------------------------------CWndReport----------------------------------
function CWndReport:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndReport:OnCreated()
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pBtnReport = self:GetDlgChild( "btn_ok" );
	self.m_pBtnReportType1 = self:GetDlgChild( "yuanyin.btn_1" );
	self.m_pBtnReportType2 = self:GetDlgChild( "yuanyin.btn_2" );
	self.m_pBtnReportType3 = self:GetDlgChild( "yuanyin.btn_3" );
	self.m_pTextContent = self:GetDlgChild( "miaoshu.shuru" );
	self.m_pTextContent:SetMaxCharLength( Report_Byte_Size );
	self.m_pTextTitle = self:GetDlgChild( "miaoshu.bg" );
	self.m_pWndTitle = self:GetDlgChild( "title" );

	self.m_pTextContent:EnableWnd( false );
	self.m_pBtnReport:EnableWnd( false );

	self.m_pBtnClose:AddActionListener( "OnClose", self );
	self.m_pBtnReport:AddActionListener( "OnClickReport", self );
	self.m_pBtnReportType1:AddActionListener( "OnChooseType", self );
	self.m_pBtnReportType2:AddActionListener( "OnChooseType", self );
	self.m_pBtnReportType3:AddActionListener( "OnChooseType", self );
	self.m_pTextContent:AddEventListener( WM_SETFOCUS, "OnContentChange", self );
	self.m_pTextContent:AddEventListener( WM_KILLFOCUS, "OnContentChange", self );
	self.m_pTextContent:AddEventListener( WM_CHAR, "OnContentSet", self );
end

function CWndReport:OnDestroy()
	self.m_pTextContent:RemoveEventListener( WM_SETFOCUS, "OnContentChange", self );
	self.m_pTextContent:RemoveEventListener( WM_KILLFOCUS, "OnContentChange", self );
	self.m_pTextContent:RemoveEventListener( WM_CHAR, "OnContentSet", self );
end

function CWndReport:ShowData( nBRAccountID, nObjectID, szBRName, wndReport )
	if g_App:GetMainPlayerData().m_CharBaseData:GetTodayReportNum() >= CSnakeConstant:Inst():GetTodayReportNum() then
		g_App:MessageBox( g_App:GetString( "jubaotips3" ),
		{
		[CMessageBox.OK] = function()	
			g_App.m_pMessageBox:ShowWnd( false );
		end;
		} );
		return;
	end
	self.m_nBRAccountID = nBRAccountID;
	self.m_nObjectID = nObjectID;
	self.m_szBRName = szBRName;
	self.m_wndReport = wndReport;
	self.m_pWndTitle:SetWndText( string.format( g_App:GetString( "jubaotips4" ), self.m_szBRName ) );
	self:ShowWnd( true );
end

function CWndReport:OnClickReport()
	local pScene = g_App:GetScene();
	if not pScene then
		return;
	end
		
	local nReportType = Report_Type3;
	if self.m_pBtnReportType1:GetCheck() then
		nReportType = Report_Type1;
	elseif self.m_pBtnReportType2:GetCheck() then
		nReportType = Report_Type2;
	end

	if self.m_nBRAccountID ~= 0 then
		local NetMsg = CAddReport:new();
		NetMsg.m_nBRAccountID = self.m_nBRAccountID;
		NetMsg.m_nReportType = nReportType;
		NetMsg.m_nRoomType = pScene:GetRoomType();
		NetMsg.m_szReportContent = self.m_szTextContent;
		g_App:SendShellMsg( NetMsg );
	end
	g_App:GetScene():GetWanfa().m_pWndSettlemet.m_tblHasReport[self.m_nObjectID] = true;
	self.m_wndReport:EnableWnd( false );
	self:OnClose();
	g_App:MessageBox( g_App:GetString( "jubaotips2" ),
	{
	[CMessageBox.OK] = function()	
		g_App.m_pMessageBox:ShowWnd( false );
	end;
	} );
end

function CWndReport:OnClose()
	self.m_pBtnReportType1:SetCheck( false );
	self.m_pBtnReportType2:SetCheck( false );
	self.m_pBtnReportType3:SetCheck( false );
	self.m_pTextContent:SetWndText( "" );
	self.m_szTextContent = "";
	self.m_pTextContent:EnableWnd( false );
	self.m_pBtnReport:EnableWnd( false );
	self.m_pTextTitle:ShowWnd( true );
	self:ShowWnd( false );
end

function CWndReport:OnChooseType()
	self.m_pTextContent:EnableWnd( true );
	self.m_pBtnReport:EnableWnd( true );
end

function CWndReport:OnContentChange()
	if self.m_pTextContent:IsFocus() then
		self.m_pTextContent:SetWndText( self.m_szTextContent );
		self.m_pTextTitle:ShowWnd( false );
	else
		self.m_pTextContent:SetWndText( self.m_szTextContent );		
		self.m_pTextTitle:ShowWnd( self.m_pTextContent:GetWndText() == "" );
	end
end

function CWndReport:OnContentSet()
	self.m_szTextContent = string.sub( self.m_pTextContent:GetWndText(), 1 ,Report_Byte_Size );
	self:OnContentChange();
end
--endregion
