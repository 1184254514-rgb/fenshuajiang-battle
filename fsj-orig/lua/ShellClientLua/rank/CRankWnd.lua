--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local eLadderStarTypeCount = 16;

function CRankWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CRankWnd:OnCreated()
	self.m_pBtnClose		= self:GetDlgChild( "close" );
	self.m_BtnFollowees		= self:GetDlgChild( "btn_you.btn_haoyou" );
	self.m_BtnAllRegion		= self:GetDlgChild( "btn_you.btn_quanqu" );
	self.m_BtnLadder		= self:GetDlgChild( "btn_zuo.btn_1" );
	self.m_BtnEndless		= self:GetDlgChild( "btn_zuo.btn_2" );
	self.m_BtnLimit			= self:GetDlgChild( "btn_zuo.btn_3" );
	self.m_BtnTeam			= self:GetDlgChild( "btn_zuo.btn_4" );
	self.m_BtnEndlessArea	= self:GetDlgChild( "btn_zuo.btn_5" );
	self.m_BtnRaceScore		= self:GetDlgChild( "btn_zuo.btn_6" );
	self.m_WndLadder		= self:GetDlgChild( "duanweibang" );
	self.m_WndScore			= self:GetDlgChild( "zihai_zongfenbang" );
	self.m_WndArea			= self:GetDlgChild( "zihaimianji" );
	self.m_WndRace			= self:GetDlgChild( "saishijifen");
	self.m_wndLoading		= self:GetDlgChild( "loading" );
	self.m_BtnSeason		= self:GetDlgChild( "duanweibang.btn_top.btn1" );
	self.m_BtnHistory		= self:GetDlgChild( "duanweibang.btn_top.btn2" );	
	self.m_BtnDay			= self:GetDlgChild( "zihai_zongfenbang.btn_top.btn1" );
	self.m_BtnWeek			= self:GetDlgChild( "zihai_zongfenbang.btn_top.btn2" );
	self.m_BtnTotal			= self:GetDlgChild( "zihai_zongfenbang.btn_top.btn3" );
	self.m_BtnDayArea		= self:GetDlgChild( "zihaimianji.btn_top.btn1" );
	self.m_BtnWeekArea		= self:GetDlgChild( "zihaimianji.btn_top.btn2" );
	self.m_BtnTotalArea		= self:GetDlgChild( "zihaimianji.btn_top.btn3" );
	self.m_BtnRaceDay		= self:GetDlgChild( "saishijifen.btn_top.btn1" );
	self.m_BtnRaceWeek		= self:GetDlgChild( "saishijifen.btn_top.btn2" );
	self.m_BtnRaceMonth		= self:GetDlgChild( "saishijifen.btn_top.btn3" );
	self.m_listRank			= self:GetDlgChild( "list" );
	self.m_wndSelf			= CRankItemWnd:new();

	self.m_wndSelf:ShowWnd( true );
	self.m_wndLoading:ShowWnd( false );
	self.m_BtnFollowees:SetCheck( true );
	self.m_BtnLadder:SetCheck( true );
	self.m_BtnSeason:SetCheck( true );
	self.m_BtnDay:SetCheck( true );
	self.m_BtnDayArea:SetCheck( true );
	self.m_BtnRaceDay:SetCheck( true );
	self.m_WndLadder:ShowWnd( true );
	self.m_WndScore:ShowWnd( false );
	self.m_WndArea:ShowWnd( false );
	self.m_WndRace:ShowWnd( false );

	self:AssignDlgChildToWnd( self.m_wndSelf, "wanjia" );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
	self.m_BtnFollowees:AddActionListener( "RefreshWnd", self );
	self.m_BtnAllRegion:AddActionListener( "RefreshWnd", self );
	self.m_BtnLadder:AddActionListener( "RefreshWnd", self );
	self.m_BtnEndless:AddActionListener( "RefreshWnd", self );
	self.m_BtnLimit:AddActionListener( "RefreshWnd", self );
	self.m_BtnTeam:AddActionListener( "RefreshWnd", self );
	self.m_BtnEndlessArea:AddActionListener( "RefreshWnd", self );
	self.m_BtnRaceScore:AddActionListener( "RefreshWnd", self );
	self.m_BtnSeason:AddActionListener( "RefreshWnd", self );
	self.m_BtnHistory:AddActionListener( "RefreshWnd", self );
	self.m_BtnDay:AddActionListener( "RefreshWnd", self );
	self.m_BtnWeek:AddActionListener( "RefreshWnd", self );
	self.m_BtnTotal:AddActionListener( "RefreshWnd", self );
	self.m_BtnDayArea:AddActionListener( "RefreshWnd", self );
	self.m_BtnWeekArea:AddActionListener( "RefreshWnd", self );
	self.m_BtnTotalArea:AddActionListener( "RefreshWnd", self );
	self.m_BtnRaceDay:AddActionListener( "RefreshWnd", self );
	self.m_BtnRaceWeek:AddActionListener( "RefreshWnd", self );
	self.m_BtnRaceMonth:AddActionListener( "RefreshWnd", self );

	g_App.m_EventDispatcher:AddEventListener( "RefreshRankWnd", "RefreshWnd", self );
	g_App.m_EventDispatcher:AddEventListener( "PlayerGradeRecordNew", "OnPlayerGradeRecordNew", self );

	local NetMsg = CGetAllRecordNew:new();
	NetMsg.m_nAccountID = g_App:GetAccountID();
	g_App:GetWorldConn():SendShellMsg( NetMsg );
	self.m_bIsShow = false;
	self.m_bHasSelfData = false;

	self.m_listRank:SetInertiaType( eInertiaType_VScroll );
	for i = 1, 200 do
		self.m_listRank:InsertRowItemsFromRes( -1, "gui/cfg/fsj_duanweibang_item2.gui", CRankItemWnd );
	end
end

function CRankWnd:OnDestroy()	
	g_App.m_EventDispatcher:RemoveEventListener( "RefreshRankWnd", "RefreshWnd", self );
	g_App.m_EventDispatcher:RemoveEventListener( "PlayerGradeRecordNew", "OnPlayerGradeRecordNew", self );
	CGWnd.OnDestroy( self );
end

function CRankWnd:ShowTempTip()
	g_App:HideMsg( CStringConfig.Inst():GetString( "gongnengtips" ) );
	self.m_BtnFollowees:SetCheck( true );
end

function CRankWnd:OnClose()
	self:ShowWnd( false );
end

function CRankWnd:IsLadder()
	return self.m_BtnLadder:GetCheck() and true or false;
end

function CRankWnd:GetModeType()
	local nModeType = nil;
	if self.m_BtnLadder:GetCheck() then
		nModeType = eRankMode_Ladder;
	elseif self.m_BtnEndless:GetCheck() then
		nModeType = eRankMode_Endless;
	elseif self.m_BtnLimit:GetCheck() then
		nModeType = eRankMode_Limit;
	elseif self.m_BtnTeam:GetCheck() then
		nModeType = eRankMode_Team;
	elseif self.m_BtnEndlessArea:GetCheck() then
		nModeType = eRankMode_Endless_Area;
	elseif self.m_BtnRaceScore:GetCheck() then
		nModeType = eRankMode_Race;
	end

	return nModeType;
end

function CRankWnd:GetCurSelect()
	local nRangeType = nil;	-- 好友、世界
	local nModeType = nil;	-- 段位、无尽分数、限时分数、团战分数、无尽面积、赛事积分  
	local nCycleType = nil;	-- 日、周、赛季、历史、月  

	if self.m_BtnFollowees:GetCheck() then
		nRangeType = eRankRange_Followees;
	elseif self.m_BtnAllRegion:GetCheck() then
		nRangeType = eRankRange_AllRegion;
	end

	if self.m_BtnLadder:GetCheck() then
		nModeType = eRankMode_Ladder;
		if self.m_BtnSeason:GetCheck() then
			nCycleType = eRankCycle_Season;
		elseif self.m_BtnHistory:GetCheck() then
			nCycleType = eRankCycle_History;
		end
	else
		if self.m_BtnEndlessArea:GetCheck() then 
			nModeType = eRankMode_Endless_Area;

			if self.m_BtnDayArea:GetCheck() then
				nCycleType = eRankCycle_Day;
			elseif self.m_BtnWeekArea:GetCheck() then
				nCycleType = eRankCycle_Week;
			elseif self.m_BtnTotalArea:GetCheck() then
				nCycleType = eRankCycle_History;
			end
		elseif self.m_BtnRaceScore:GetCheck() then
			nModeType = eRankMode_Race;
			if self.m_BtnRaceDay:GetCheck() then
				nCycleType = eRankCycle_Day;
			elseif self.m_BtnRaceWeek:GetCheck() then
				nCycleType = eRankCycle_Week;
			elseif self.m_BtnRaceMonth:GetCheck() then
				nCycleType = eRankCycle_Month;
			end
		else
			if self.m_BtnEndless:GetCheck() then
				nModeType = eRankMode_Endless;
			elseif self.m_BtnLimit:GetCheck() then
				nModeType = eRankMode_Limit;
			elseif self.m_BtnTeam:GetCheck() then
				nModeType = eRankMode_Team;
			end

			if self.m_BtnDay:GetCheck() then
				nCycleType = eRankCycle_Day;
			elseif self.m_BtnWeek:GetCheck() then
				nCycleType = eRankCycle_Week;
			elseif self.m_BtnTotal:GetCheck() then
				nCycleType = eRankCycle_History;
			end
		end
	end

	local tblRankData = g_App:GetRankDataMgr():GetRankData( nRangeType, nModeType, nCycleType );

	if tblRankData == nil then
		g_App:GetRankDataMgr():QueryRank( nRangeType, nModeType, nCycleType );
	end

	return nRangeType, nModeType, nCycleType, tblRankData;
end

function CRankWnd:RefreshWndStar()
end

function CRankWnd:RefreshWndRecord()
end

function CRankWnd:RefreshWnd()
	if self.m_bIsShow == false or self.m_bHasSelfData == false then
		return;
	end
	self.m_WndLadder:ShowWnd( false );
	self.m_WndScore:ShowWnd( false );
	self.m_WndArea:ShowWnd( false );
	self.m_WndRace:ShowWnd( false );
	local nModeTypeTmd = self:GetModeType();
	local pWndUpdate = nil;
	local strItemGui = nil
	if nModeTypeTmd == eRankMode_Ladder then
		pWndUpdate = self.m_WndLadder;
	elseif nModeTypeTmd == eRankMode_Endless_Area then
		pWndUpdate = self.m_WndArea;
	elseif nModeTypeTmd == eRankMode_Race then
		pWndUpdate = self.m_WndRace;
	else
		pWndUpdate = self.m_WndScore;
	end
	pWndUpdate:ShowWnd( true );

	self.m_wndLoading:ShowWnd( true );
	local nRangeType, nModeType, nCycleType, tblRankData = self:GetCurSelect();
	if tblRankData == nil then
		return;
	end

	self.m_nModeType = nModeType;

	if pWndUpdate == self.m_WndScore then
		wndTitle = self.m_WndScore:GetDlgChild( "title" );
		if nModeType == eRankMode_Endless then
			wndTitle:SetWndText( CStringConfig.Inst():GetString( "zihaizongfenbang" ) );
		elseif nModeType == eRankMode_Limit then
			wndTitle:SetWndText( CStringConfig.Inst():GetString( "xianshizongfenbang" ) );
		elseif nModeType == eRankMode_Team then
			wndTitle:SetWndText( CStringConfig.Inst():GetString( "tuanzhanzongfenbang" ) );
		end
	end

	local nDataCount = #tblRankData; 
	local nItemCount = self.m_listRank:GetItemCount();
	local bInsertNewItem = nDataCount > nItemCount;
	if nDataCount > nItemCount then
		for i = nItemCount + 1, nDataCount do
			self.m_listRank:InsertRowItemsFromRes( -1, "gui/cfg/fsj_duanweibang_item2.gui", CRankItemWnd );
		end
	end

	local tblSelf = nil;
	local nSelfIndex = -1;
	for i = 0, nItemCount - 1 do
		self.m_listRank:SetSubItemVisible( i < nDataCount, i, 0 );
		if i < nDataCount then
			local Data = tblRankData[ i + 1 ];
			if Data.nAccountID == g_App:GetAccountID() then
				tblSelf = Data;
				nSelfIndex = i + 1;
			end
			local subItem = self.m_listRank:GetSubItem( i, 0 );
			subItem:UpdateRankItem( Data, nModeType, i + 1 );
		end
	end

	if bInsertNewItem then
		self.m_listRank:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
		self.m_listRank:ShowWnd( false );
	else
		self:OnListItemLoaded();
	end

	if not tblSelf and nRangeType == eRankRange_Followees then
		return;
	end

	if not tblSelf and nRangeType == eRankRange_AllRegion then
		tblSelf = {};
		tblSelf.nAccountID = g_App:GetAccountID();
		tblSelf.szCharName = g_App:GetNickName();
		tblSelf.nCurHeadIcon = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
		tblSelf.nRankValue = g_App:GetRankDataMgr():GetSelfRankValue( nModeType, nCycleType );
	end
	self.m_wndSelf:UpdateRankItem( tblSelf, nModeType, nSelfIndex );
end

function CRankWnd:OnListItemLoaded( Event )
	self.m_listRank:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	self.m_listRank:ShowWnd( true );
	self.m_wndLoading:ShowWnd( false );
end

function CRankWnd:OnPlayerGradeRecordNew()
	g_App:GetRankDataMgr():UpdateSelfRankValue();
	self.m_bHasSelfData = true;
	self:RefreshWnd();
end

function CRankWnd:OnWndShow( bShow )
	if bShow then
		local NetMsg = CGetAllRecordNew:new();
		NetMsg.m_nAccountID = g_App:GetAccountID();
		g_App:GetWorldConn():SendShellMsg( NetMsg );
		self.m_bNeedUpdateSelf = true;
	end
	self.m_bIsShow = bShow;
end

------------------------------- Item Start ------------------------------
function CRankItemWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGButton.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CRankItemWnd:CreateFromRes( sResName, ParentWnd )
	return CGButton.CreateFromRes( self, sResName, ParentWnd, 1 )
end

function CRankItemWnd:OnCreated()
	self:AddActionListener( "OnShowInfo", self );
	if self.m_AccountInfo then
		self:UpdateRankItem( self.m_AccountInfo, self.m_nModeType, self.m_nRankIndex );
	end
end

function CRankItemWnd:OnShowInfo()
	if g_App:GetAccountID() ~= self.m_AccountInfo.nAccountID then
		g_App:ShowPlayerInfo( self.m_AccountInfo.nAccountID );
	end
end

function CRankItemWnd:UpdateRankItem( tblData, nModeType, nRankIndex )
	self.m_AccountInfo = tblData;
	self.m_nModeType = nModeType;
	self.m_nRankIndex = nRankIndex;
	if not self:IsCreated() then
		return;
	end

	-- 自己的背景色和其他玩家分开
	local bIsSelf = g_App:GetAccountID() == tblData.nAccountID;	
	local nColor = bIsSelf and 0xffffffff or 0xfffee0ab;
	for i = eST_ENABLE, eST_CLICKDOWN do
		self:SetImageColor( GSM_BS_BK, i, -1, nColor )
	end

	-- 排名
	local pWndIndex = self:GetDlgChild( "paiming" );
	pWndIndex:GetDlgChild( "bg_mine" ):ShowWnd( bIsSelf );
	pWndIndex:ShowWnd( true );
	if self.m_nRankIndex == -1 then
		pWndIndex:SetWndText( CStringConfig.Inst():GetString( "weishangbang" ) );
	else
		pWndIndex:SetWndText( tostring( self.m_nRankIndex ) );
	end

	-- 头像
	local pWndHead = self:GetDlgChild( "head.touxiang" );
	pWndHead:ShowWnd( true );
	CHeadIconConfig:Inst():SetIcon( pWndHead, tblData.nCurHeadIcon + 1, tblData.nAccountID );

	-- 名字
	local pWndName = self:GetDlgChild( "name" );
	pWndName:ShowWnd( true );
	pWndName:SetWndText( tblData.szCharName );

	self:GetDlgChild( "icon_duanwei" ):ShowWnd( false );
	self:GetDlgChild( "duanwei_name" ):ShowWnd( false );
	self:GetDlgChild( "star" ):ShowWnd( false );
	self:GetDlgChild( "shuliang" ):ShowWnd( false );
	self:GetDlgChild( "danjuzongfen" ):ShowWnd( false );
	self:GetDlgChild( "shijian" ):ShowWnd( false );

	if nModeType == eRankMode_Ladder then
		self:UpdateItemLadder( tblData );
	elseif nModeType == eRankMode_Endless_Area then
		self:UpdateItemEndlessArea( tblData );
	else
		self:UpdateItemScore( tblData );
	end
end

function CRankItemWnd:UpdateItemLadder( tblData )
	local Config = CStarLevelConfig:Inst();

	-- 段位图标
	local pWndLadder = self:GetDlgChild( "icon_duanwei" );
	pWndLadder:ShowWnd( true );
	local nStarLevel = Config:GetLevel( tblData.nRankValue );
	for i = 1, eLadderStarTypeCount do -- 循环一下，判断哪个图标要显示
		pWndLadder:GetDlgChild( tostring( i - 1 ) ):ShowWnd( i == nStarLevel );
	end

	-- 段位名
	local pWndLadderName = self:GetDlgChild( "duanwei_name" );
	pWndLadderName:ShowWnd( true );
	pWndLadderName:SetWndText( Config:GetName( tblData.nRankValue ) );

	-- “星”图标
	local pWndStar = self:GetDlgChild( "star" );
	pWndStar:ShowWnd( true );

	-- 星后的数字
	local pWndStarNum = self:GetDlgChild( "shuliang" );
	pWndStarNum:ShowWnd( true );
	pWndStarNum:SetWndText( tostring( Config:HaveStarOnLevel( tblData.nRankValue ) ) );
end

function CRankItemWnd:UpdateItemEndlessArea( tblData )
	local pWndAreaScore = self:GetDlgChild( "danjuzongfen" );
	pWndAreaScore:ShowWnd( true );
	pWndAreaScore:SetWndText( string.format( "%.2f%%", 
		tblData.nRankValue.nEndlessAreaScore * 100 / g_GetSceneNodeTotal(eRT_Endless)) );

	local pWndAreaTime = self:GetDlgChild( "shijian" );
	pWndAreaTime:ShowWnd( true );
	local nAreaTime = tblData.nRankValue.nEndlessAreaScore == 0 and 0 or tblData.nRankValue.nEndlessAreaTime;
	pWndAreaTime:SetWndText( string.format( "%02d:%02d", nAreaTime/60, nAreaTime%60 ) );
end

function CRankItemWnd:UpdateItemScore( tblData )
	local pWndScore = self:GetDlgChild( "danjuzongfen" );
	pWndScore:ShowWnd( true );
	pWndScore:SetWndText( tblData.nRankValue );
end

--endregion
