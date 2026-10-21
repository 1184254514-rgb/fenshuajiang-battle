--region CWndResultEndless.lua
--Date 2017.08.24
--此文件由[BabeLua]插件自动生成

function CWndResultEndless:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType  );
end

function CWndResultEndless:OnCreated()
	self.m_WndVolume = self:GetDlgChild( "E_chanchu" );
	self.m_WndSum = self:GetDlgChild( "E_zongdefen" );
	self.m_WndConBit = self:GetDlgChild("E_lianjijiangli");
	self.m_WndGoldCoin = self:GetDlgChild( "E_jinbi" );
	self.m_WndKill = self:GetDlgChild( "E_jisha" );
	self.m_WndDirectorDie = self:GetDlgChild( "W_beiwanjiajisha" );
	self.m_WndManorAllUse = self:GetDlgChild( "W_shengli" );
	self.m_WndRemainEnd = self:GetDlgChild( "E_fangjianguanbi" );
	self.m_WndVolumeCoin = self:GetDlgChild( "E_tijidefen" );
	self.m_WndKillCoin = self:GetDlgChild( "E_jishadefen" );
	self.m_WndComobCoin = self:GetDlgChild( "E_lianjidefen" );
	self.m_WndSumCoin = self:GetDlgChild( "ewaijinbi.E_jinbishuliang" );
	self.m_BtnShard = self:GetDlgChild( "B_fenxiangzhanji" );
	self.m_BtnBack = self:GetDlgChild( "B_huizhujiemian" );
	self.m_BtnRedo = self:GetDlgChild( "B_zailaiyiju" );	
	self.m_BtnClose = self:GetDlgChild( "B_fanhui" );
	self.m_BonusCoin = self:GetDlgChild("ewaijiangli.E_jiangli");
	self.m_btnContinue = self:GetDlgChild( "B_jixu" );
	self.m_btnContinue:AddActionListener( "OnClose", self );
	self.m_Bonus = self:GetDlgChild("ewaijiangli");
	self.m_BonusCoin:ShowWnd( false );
	self.m_Bonus:ShowWnd( false );
	self.m_aryTarMark = {};
	self.m_aryTarMark[0] = self:GetDlgChild( "bg_jinriizuijia.tiji" );
	self.m_aryTarMark[1] = self:GetDlgChild( "bg_jinriizuijia.jisha" );
	self.m_aryTarMark[2] = self:GetDlgChild( "bg_jinriizuijia.lianji" );
	self.m_aryTarMark[3] = self:GetDlgChild( "bg_jinriizuijia.jifen" );
	self.m_aryTarMark[4] = self:GetDlgChild( "bg_lishiizuijia.tiji" );
	self.m_aryTarMark[5] = self:GetDlgChild( "bg_lishiizuijia.jisha" );
	self.m_aryTarMark[6] = self:GetDlgChild( "bg_lishiizuijia.lianji" );
	self.m_aryTarMark[7] = self:GetDlgChild( "bg_lishiizuijia.jifen" );

	self.m_listInfo = self:GetDlgChild( "list" );
	self.m_wndScore =  CWndSettScore:new( "gui/cfg/fsj_xianshimoshi_gerenjifen.gui", self.m_listInfo, 1 ); 
	for i = 0, 7 do
		self.m_aryTarMark[i]:ShowWnd( false );
	end

	self.m_BtnShard:AddActionListener( "OnShard", self );
	self.m_BtnClose:AddActionListener( "OnClose", self );
end

function CWndResultEndless:UpdateData( nRoomOverType, StScore, szKillName )
	local Scene = g_App:GetScene();
	local str = "";

	local tblBattleInfo = g_App:GetPlayerBattleInfo();
	
	local szNickName = g_App:GetMainPlayerData().m_CharBaseData:GetNickName();
	self.m_wndScore:UpdateWndData( StScore, tblBattleInfo, szNickName );
	self.m_wndScore:ShowWnd( true );

	self.m_WndDirectorDie:ShowWnd( false );
	self.m_WndManorAllUse:ShowWnd( false );
	self.m_WndRemainEnd:ShowWnd( false );
	if ( nRoomOverType == eRO_DirectorDie ) then
		str = g_App:GetString( "jiesuanbiaoti" );
		str = string.format( str, szKillName );
		self.m_WndDirectorDie:SetWndText( str );
		self.m_WndDirectorDie:ShowWnd( true );
	elseif( nRoomOverType == eRO_RemainEnd ) then
		self.m_WndRemainEnd:ShowWnd( true );
	elseif( nRoomOverType == eRO_ManorAllUse ) then
		self.m_WndManorAllUse:ShowWnd( true );
	end

	self.m_WndSumCoin:SetWndText( tostring( StScore.nAllCoin ) );
	self.m_WndKill:SetWndText( tostring( StScore.nKillCount ) );
	self.m_WndVolume:SetWndText( tostring( StScore.nAreaScore ) );
	self.m_WndVolumeCoin:SetWndText( tostring( StScore.nAreaScore ) ); 
	self.m_WndConBit:SetWndText( tostring( StScore.nComboScore ) );
	self.m_WndComobCoin:SetWndText( tostring( StScore.nComboScore ) );
	self.m_WndKillCoin:SetWndText( tostring( StScore.nKillScore ) );

--	local nBonus = self:CheckTask( StScore.aryMaxGrade[eHG_Area], StScore.aryMaxGrade[eHG_Kill], 
--		StScore.aryMaxGrade[eHG_Combo], StScore.aryMaxGrade[eHG_All] );

--	self.m_WndSum:SetWndText( tostring( StScore.nAllScore + nBonus ) );
	self.m_WndSum:SetWndText( StScore.nAllScore );
--	CheckHisRecord( StScore );
end

function CWndResultEndless:OnShard()
	self:Shard();
end

function CWndResultEndless:OnBack()
	self:Back();
end

function CWndResultEndless:OnRedo()
	self:Redo();
end

function CWndResultEndless:Shard()
end

function CWndResultEndless:Back()
	g_App:SwitchStart();
end

function CWndResultEndless:Redo()
	local Scene = g_App:GetScene();
	local nRoomType = Scene:GetRoomType();
	g_App:SwitchStart();
	g_App:EnterRoom( nRoomType );
end

function CWndResultEndless:CheckTask( nVolume, nkill, nCombo, nScore   )
--	local PlayerDB = g_App:GetPlayerData();
--	local nCurTask = PlayerDB:GetCurTask();
--	local nCurTar = CDailyTaskConfig::Inst().GetTarget( nCurTask );
--	if( nCurTar == TASK_FINISHED )
--		return 0;
--	uint32 aryGrade[] = { nVolume, nkill, nCombo, nScore };
--	if( nCurTar > aryGrade[ nCurTask % eHG_Count])
--		return 0;

--	uint32 nBonus = CDailyTaskConfig::Inst().GetBonus( nCurTask );
--	char szBuffer[512];
--	gammasstream(szBuffer)<<nBonus;
--	m_pBonus->ShowWnd(true);
--	m_pBonusCoin->SetWndText(szBuffer );
--	m_pBonusCoin->ShowWnd( true );
--	m_aryTarMark[nCurTask % eHG_Count]->ShowWnd( true );
--	return nBonus;
end

function CWndResultEndless:CheckHisRecord( StScore )
--	const CPlayerBaseData& PlayerDB = CGameAppClient::Inst().GetPlayerData();
--	int64 nCreateTime = PlayerDB.GetCreateTime();
--	int64 nLocalTime = GetLocalTime();
--	int64 nLocalCreateTime = NatureTime2LocalTime( nCreateTime*1000 );
--	uint32 nCreateDay = ( uint32 )( nLocalCreateTime/eTimeConst_DayMiSeconds );
--	uint32 nToday = nLocalTime/eTimeConst_DayMiSeconds;
--	int64  nDeltaDay = (int64)nToday - nCreateDay;
--	if( nDeltaDay < 1 )
--		return;
--	uint32 aryScore[eHG_Count] = { StScore.nAreaScore, StScore.nKillScore, StScore.nComboScore, StScore.nAllScore };
--	for( int i = 0; i < eHG_Count; i ++ )
--	{
--		if( aryScore[i] > PlayerDB.GetHisGrade(i) )
--			m_aryTarMark[i + eHG_Count]->ShowWnd(true);
--	}
end

function CWndResultEndless:OnClose()
	self:ShowWnd( false );
	g_App:GetScene():GetWanfa().m_pWndBalance:ShowWnd( true );
end


--endregion
