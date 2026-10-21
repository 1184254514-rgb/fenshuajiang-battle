--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndSettScore:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndSettScore:OnCreated()
	self.m_pWndAreaScore		= self:GetDlgChild( "E_tiji" );
	self.m_pWndKillScore		= self:GetDlgChild( "E_jisha" );
	self.m_pWndComboScore		= self:GetDlgChild( "E_lianji" );
	self.m_pWndAllScore			= self:GetDlgChild( "E_benju" );
	self.m_pListBattleInfoKill	= self:GetDlgChild( "list1" );
	self.m_pListBattleInfoDead	= self:GetDlgChild( "list2" );
	self.m_wndNoKill			= self:GetDlgChild( "kong1" );
	self.m_wndNoDead			= self:GetDlgChild( "kong2" );
	self.m_wndKillCount			= self:GetDlgChild( "jishacishu" );
	self.m_wndDeadCount			= self:GetDlgChild( "beijishacishu" );

	self.m_wndAllNewDay		= self:GetDlgChild( "bg_benjudefen.jilu.ri" );
	self.m_wndAllNewWeek	= self:GetDlgChild( "bg_benjudefen.jilu.zhou" );
	self.m_wndAllNewHistory = self:GetDlgChild( "bg_benjudefen.jilu.lishi" );

	self.m_wndAreaNewToday	= self:GetDlgChild( "bg_tijidefen.jilu.ri" );
	self.m_wndAreaNewWeek	= self:GetDlgChild( "bg_tijidefen.jilu.zhou" );
	self.m_wndAreaNewHistory= self:GetDlgChild( "bg_tijidefen.jilu.lishi" );

	self.m_wndKillNewToday	= self:GetDlgChild( "bg_jishadefen.jilu.ri" );
	self.m_wndKillNewWeek	= self:GetDlgChild( "bg_jishadefen.jilu.zhou" );
	self.m_wnbKillNewHistory= self:GetDlgChild( "bg_jishadefen.jilu.lishi" );

	self.m_wndRhyNewToday	= self:GetDlgChild( "bg_lianjidefen.jilu.ri" );
	self.m_wndRhyNewWeek	= self:GetDlgChild( "bg_lianjidefen.jilu.zhou" );
	self.m_wndRhyNewHistory	= self:GetDlgChild( "bg_lianjidefen.jilu.lishi" );

	self:SetInitShowState( false );

	self.m_wndNoKill:ShowWnd( false );
	self.m_wndNoDead:ShowWnd( false );

	self.m_pListBattleInfoKill:SetInertiaType( eInertiaType_VScroll );
	self.m_pListBattleInfoDead:SetInertiaType( eInertiaType_VScroll );
end

function CWndSettScore:SetInitShowState( bShow )
	self.m_wndAllNewDay:ShowWnd( bShow );		
	self.m_wndAllNewWeek:ShowWnd( bShow );
	self.m_wndAllNewHistory:ShowWnd( bShow ); 
	
	self.m_wndAreaNewToday:ShowWnd( bShow );	
	self.m_wndAreaNewWeek:ShowWnd( bShow );	
	self.m_wndAreaNewHistory:ShowWnd( bShow );
	
	self.m_wndKillNewToday:ShowWnd( bShow );	
	self.m_wndKillNewWeek:ShowWnd( bShow );	
	self.m_wnbKillNewHistory:ShowWnd( bShow );
	
	self.m_wndRhyNewToday:ShowWnd( bShow );	
	self.m_wndRhyNewWeek:ShowWnd( bShow );	
	self.m_wndRhyNewHistory:ShowWnd( bShow );	
end

function CWndSettScore:UpdateWndData( structScore, tblBattleInfo, szNickName )
	self:CheckShowState( structScore );

	self.m_pListBattleInfoKill:DeleteAllItem();
	self.m_pListBattleInfoDead:DeleteAllItem();
	self.m_tblKillInfo = {};
	self.m_tblDeadInfo = {};
	local nKillCount = 0;
	local nDeadCount = 0;
	for k, v in pairs( tblBattleInfo ) do
		local bKiller = v.m_szKillerNickName == szNickName;
		local bDeader = v.m_szDeaderNickName == szNickName;
		if bKiller then
			table.insert( self.m_tblKillInfo, v );
			self.m_pListBattleInfoKill:InsertRowItemsFromRes( -1, "gui/cfg/fsj_xianshimoshi_gerenjifen_item.gui", CWndSettScoreKillItem );
			nKillCount = nKillCount + v.m_nCount;
		elseif bDeader then
			table.insert( self.m_tblDeadInfo, v );
			self.m_pListBattleInfoDead:InsertRowItemsFromRes( -1, "gui/cfg/fsj_xianshimoshi_gerenjifen_item2.gui", CWndSettScoreBeKilledItem );
			nDeadCount = nDeadCount + v.m_nCount;	
		end
	end

	if table.count( self.m_tblKillInfo ) == 0 then 
		self.m_wndNoKill:ShowWnd( true );
	end

	if table.count( self.m_tblDeadInfo ) == 0 then 
		self.m_wndNoDead:ShowWnd( true );
	end

	self.m_wndKillCount:SetWndText( string.format( g_App:GetString( "jishacishu" ), nKillCount ) );
	self.m_wndDeadCount:SetWndText( string.format( g_App:GetString( "beijishacishu" ), nDeadCount ) );

	self.m_pListBattleInfoKill:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self );
	self.m_pListBattleInfoDead:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListDeadLoaded", self );

	self.m_pWndAreaScore:SetWndText( tostring( structScore.nAreaScore ) );
	self.m_pWndKillScore:SetWndText( tostring( structScore.nKillScore ) );
	self.m_pWndComboScore:SetWndText( tostring( structScore.nComboScore ) );
	self.m_pWndAllScore:SetWndText( tostring( structScore.nAllScore ) );
end

function CWndSettScore:OnItemListLoaded()
 	self.m_pListBattleInfoKill:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self );
	local nRoomType = g_App:GetScene():GetRoomType();
	local tbl = {};

	for i = 1, self.m_pListBattleInfoKill:GetItemCount() do
		local nItem = i - 1;
		local subItem = self.m_pListBattleInfoKill:GetSubItem( nItem, 0 );
		local nRoomType = g_App:GetScene():GetRoomType();
		local tbl = {};
		tbl = self.m_tblKillInfo[i];
		subItem:SetData( tbl );
	end
end

function CWndSettScore:OnItemListDeadLoaded()
 	self.m_pListBattleInfoDead:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListDeadLoaded", self );

	for i = 1, self.m_pListBattleInfoDead:GetItemCount() do
		local nItem = i - 1;
		local subItem = self.m_pListBattleInfoDead:GetSubItem( nItem, 0 );
		local nRoomType = g_App:GetScene():GetRoomType();
		local tbl = {};
		tbl = self.m_tblDeadInfo[i];
		subItem:SetData( tbl );
	end
end

function CWndSettScore:CheckShowState( SettData )
	local nCurAllScore	= SettData.nAllScore;
	local nCurAreaScore	= SettData.nAreaScore;
	local nCurKillScore = SettData.nKillScore;
	local nCurRhyScore	= SettData.nComboScore;

	local Scene = g_App:GetScene();
	if not Scene then
		print( "---------Warning------------:Scene not Exist!!!" );
		return;
	end

	local nAllGradeRecordToday		= 0;
	local nAllGradeRecordWeek		= 0;
	local nAllGradeRecordHistory	= 0;
	local nAreaGradeRecordToday		= 0;
	local nAreaGradeRecordWeek		= 0;
	local nAreaGradeRecordHistory	= 0;
	local nKillGradeRecordToday 	= 0;
	local nKillGradeRecordWeek		= 0;
	local nKillGradeRecordHistory	= 0;
	local nRhyGradeRecordToday		= 0;
	local nRhyGradeRecordWeek		= 0;
	local nRhyGradeRecordHistory	= 0;

	local nAllScoreStandard		= 0;
	local nAreaScoreStandard	= 0;
	local nKillScoreStandard	= 0;
	local nRhyScoreStandard		= 0;

	local tblAllGradeRecord = CPlayerGradeInfoMgr:Instance():GetAllDataNew();
	if not tblAllGradeRecord then return end

	local nRoomType = Scene.m_nRoomType;
	if nRoomType == eRT_Endless then
		nAllGradeRecordToday	= tblAllGradeRecord[eGradeType_EndlessToday].nAllScore;
		nAllGradeRecordWeek		= tblAllGradeRecord[eGradeType_EndlessWeek].nAllScore;
		nAllGradeRecordHistory	= tblAllGradeRecord[eGradeType_EndlessHistory].nAllScore;
		nAreaGradeRecordToday	= tblAllGradeRecord[eGradeType_EndlessToday].nAreaScore;
		nAreaGradeRecordWeek	= tblAllGradeRecord[eGradeType_EndlessWeek].nAreaScore;
		nAreaGradeRecordHistory = tblAllGradeRecord[eGradeType_EndlessHistory].nAreaScore;
		nKillGradeRecordToday	= tblAllGradeRecord[eGradeType_EndlessToday].nKillScore;
		nKillGradeRecordWeek	= tblAllGradeRecord[eGradeType_EndlessWeek].nKillScore;
		nKillGradeRecordHistory = tblAllGradeRecord[eGradeType_EndlessHistory].nKillScore;
		nRhyGradeRecordToday	= tblAllGradeRecord[eGradeType_EndlessToday].nMaxCombo;
		nRhyGradeRecordWeek		= tblAllGradeRecord[eGradeType_EndlessWeek].nMaxCombo;
		nRhyGradeRecordHistory	= tblAllGradeRecord[eGradeType_EndlessHistory].nMaxCombo;
		
		nAllScoreStandard		= g_data_graderecordshowlevel[1].nEndlessAllScore;
		nAreaScoreStandard		= g_data_graderecordshowlevel[1].nEndlessAreaScore;
		nKillScoreStandard		= g_data_graderecordshowlevel[1].nEndlessKillScore;
		nRhyScoreStandard		= g_data_graderecordshowlevel[1].nEndlessRhythmScore;
				
	elseif nRoomType == eRT_LimitTime then
		nAllGradeRecordToday	= tblAllGradeRecord[eGradeType_LimitToday].nAllScore;
		nAllGradeRecordWeek		= tblAllGradeRecord[eGradeType_LimitWeek].nAllScore;
		nAllGradeRecordHistory	= tblAllGradeRecord[eGradeType_LimitHistory].nAllScore;
		nAreaGradeRecordToday	= tblAllGradeRecord[eGradeType_LimitToday].nAreaScore;
		nAreaGradeRecordWeek	= tblAllGradeRecord[eGradeType_LimitWeek].nAreaScore;
		nAreaGradeRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nAreaScore;
		nKillGradeRecordToday	= tblAllGradeRecord[eGradeType_LimitToday].nKillScore;
		nKillGradeRecordWeek	= tblAllGradeRecord[eGradeType_LimitWeek].nKillScore;
		nKillGradeRecordHistory = tblAllGradeRecord[eGradeType_LimitHistory].nKillScore;
		nRhyGradeRecordToday	= tblAllGradeRecord[eGradeType_LimitToday].nMaxCombo;
		nRhyGradeRecordWeek		= tblAllGradeRecord[eGradeType_LimitWeek].nMaxCombo;
		nRhyGradeRecordHistory	= tblAllGradeRecord[eGradeType_LimitHistory].nMaxCombo;

		nAllScoreStandard		= g_data_graderecordshowlevel[1].nLimitAllScore;
		nAreaScoreStandard		= g_data_graderecordshowlevel[1].nLimitAreaScore;
		nKillScoreStandard		= g_data_graderecordshowlevel[1].nLimitKillScore;
		nRhyScoreStandard		= g_data_graderecordshowlevel[1].nLimitRhythmScore;

	elseif nRoomType == eRT_Team then
		nAllGradeRecordToday	= tblAllGradeRecord[eGradeType_TeamToday].nAllScore;
		nAllGradeRecordWeek		= tblAllGradeRecord[eGradeType_TeamWeek].nAllScore;
		nAllGradeRecordHistory	= tblAllGradeRecord[eGradeType_TeamHistory].nAllScore;
		nAreaGradeRecordToday	= tblAllGradeRecord[eGradeType_TeamToday].nAreaScore;
		nAreaGradeRecordWeek	= tblAllGradeRecord[eGradeType_TeamWeek].nAreaScore;
		nAreaGradeRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nAreaScore;
		nKillGradeRecordToday	= tblAllGradeRecord[eGradeType_TeamToday].nKillScore;
		nKillGradeRecordWeek	= tblAllGradeRecord[eGradeType_TeamWeek].nKillScore;
		nKillGradeRecordHistory = tblAllGradeRecord[eGradeType_TeamHistory].nKillScore;
		nRhyGradeRecordToday	= tblAllGradeRecord[eGradeType_TeamToday].nMaxCombo;
		nRhyGradeRecordWeek		= tblAllGradeRecord[eGradeType_TeamWeek].nMaxCombo;
		nRhyGradeRecordHistory	= tblAllGradeRecord[eGradeType_TeamHistory].nMaxCombo;

		nAllScoreStandard		= g_data_graderecordshowlevel[1].nTeamAllScore;
		nAreaScoreStandard		= g_data_graderecordshowlevel[1].nTeamAreaScore;
		nKillScoreStandard		= g_data_graderecordshowlevel[1].nTeamKillScore;
		nRhyScoreStandard		= g_data_graderecordshowlevel[1].nTeamRhythmScore;
	end
	
	local bAllTodayNew		= nCurAllScore >= nAllScoreStandard and nCurAllScore > nAllGradeRecordToday;
	local bAllWeekNew		= nCurAllScore >= nAllScoreStandard and nCurAllScore > nAllGradeRecordWeek;
	local bAllHistoryNew	= nCurAllScore >= nAllScoreStandard and nCurAllScore > nAllGradeRecordHistory;
	local bAreaTodayNew		= nCurAreaScore >= nAreaScoreStandard and nCurAreaScore > nAreaGradeRecordToday;
	local bAreaWeekNew		= nCurAreaScore >= nAreaScoreStandard and nCurAreaScore > nAreaGradeRecordWeek;
	local bAreaHistoryNew	= nCurAreaScore >= nAreaScoreStandard and nCurAreaScore > nAreaGradeRecordHistory;
	local bKillTodayNew		= nCurKillScore >= nKillScoreStandard and nCurKillScore > nKillGradeRecordToday;
	local bKillWeekNew		= nCurKillScore >= nKillScoreStandard and nCurKillScore > nKillGradeRecordWeek;
	local bKillHistoryNew	= nCurKillScore >= nKillScoreStandard and nCurKillScore > nKillGradeRecordHistory;
	local bRhyTodayNew		= nCurRhyScore >= nRhyScoreStandard and nCurRhyScore > nRhyGradeRecordToday;
	local bRhyWeekNew		= nCurRhyScore >= nRhyScoreStandard and nCurRhyScore > nRhyGradeRecordWeek;
	local bRhyHistoryNew	= nCurRhyScore >= nRhyScoreStandard and nCurRhyScore > nRhyGradeRecordHistory;

	if nRoomType == eRT_LimitSecret or nRoomType == eRT_TeamSecret
		or nRoomType == eRT_LimitRace or nRoomType == eRT_TeamRace then
		return;
	end

	if bAllHistoryNew then
		self.m_wndAllNewHistory:ShowWnd( true );
	else
		if bAllWeekNew then
			self.m_wndAllNewWeek:ShowWnd( true );
		else
			if bAllTodayNew then
				self.m_wndAllNewDay:ShowWnd( true );
			end
		end
	end

	if bAreaHistoryNew then
		self.m_wndAreaNewHistory:ShowWnd( true );
	else
		if bAllWeekNew then
			self.m_wndAreaNewWeek:ShowWnd( true );
		else
			if bAllTodayNew then
				self.m_wndAreaNewToday:ShowWnd( true );
			end
		end
	end

	if bKillHistoryNew then
		self.m_wnbKillNewHistory:ShowWnd( true );
	else
		if bKillWeekNew then
			self.m_wndKillNewWeek:ShowWnd( true );
		else
			if bKillTodayNew then
				self.m_wndKillNewToday:ShowWnd( true );
			end
		end
	end


	if bRhyHistoryNew then
		self.m_wndRhyNewHistory:ShowWnd( true );
	else
		if bRhyWeekNew then
			self.m_wndRhyNewWeek:ShowWnd( true );
		else
			if bRhyTodayNew then
				self.m_wndRhyNewToday:ShowWnd( true );
			end
		end
	end

end

-------------------CWndSettScoreKillItem Begin----------------------------
function CWndSettScoreKillItem:Ctor()

end

function CWndSettScoreKillItem:OnCreated()
	self.m_szKillInfo = self:GetDlgChild( "w_chengji" );
	self.m_wndDeadName = self:GetDlgChild( "name" );
	self.m_iconMine = self:GetDlgChild( "head.touxiang" );
	self.m_iconEnemy = self:GetDlgChild( "head2.touxiang" );
end

function CWndSettScoreKillItem:SetData( Data )
	self.m_wndDeadName:SetWndText( Data.m_szDeaderNickName );
	local str = g_App:GetString( "jiesuantips1" );
	str = string.format( str, Data.m_nCount );
	self.m_szKillInfo:SetWndText( str );
	CHeadIconConfig:Inst():SetIcon( self.m_iconEnemy, Data.m_nDeaderEquipID, Data.nDeaderAccountID );
	local MineHeadIconID = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1;
	CHeadIconConfig:Inst():SetIcon( self.m_iconMine, MineHeadIconID, g_App:GetAccountID() );
end
-------------------CWndSettScoreBeKilledItem Begin----------------------------

function CWndSettScoreBeKilledItem:Ctor()

end

function CWndSettScoreBeKilledItem:OnCreated()
	self.m_szKillInfo = self:GetDlgChild( "w_chengji" );
	self.m_wndKillerName = self:GetDlgChild( "name" );
	self.m_iconMine = self:GetDlgChild( "head2.touxiang" );
	self.m_iconEnemy = self:GetDlgChild( "head.touxiang" );
end

function CWndSettScoreBeKilledItem:SetData( Data )
	local str = g_App:GetString( "jiesuantips1" );
	str = string.format( str, Data.m_nCount );
	self.m_szKillInfo:SetWndText( str );
	self.m_wndKillerName:SetWndText( Data.m_szKillerNickName );
	local MineHeadIconID = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() + 1
	CHeadIconConfig:Inst():SetIcon( self.m_iconEnemy, Data.m_nKillerEquipID, Data.m_nKillerAccountID );
	CHeadIconConfig:Inst():SetIcon( self.m_iconMine, MineHeadIconID, g_App:GetAccountID() );
end
-------------------CWndSettScoreBeKilledItem End----------------------------

--endregion
