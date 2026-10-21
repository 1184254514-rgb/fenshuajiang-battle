--region CActivityWnd.lua
--Date	2017/12/11
--此文件由[BabeLua]插件自动生成

local DaySeconds = 86400; -- 一天的秒数
local DayMiSeconds = 86400000; -- 一天的秒数

function CActivityWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );	
end

function CActivityWnd:OnCreated()
	self.m_pList = self:GetDlgChild( "list" );
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pBtnClose:AddActionListener( "OnClickClose", self );
	self.m_pBtnSignIn = self:GetDlgChild( "btn_zuo.btn_1" );
	self.m_pWndSignInRed = self.m_pBtnSignIn:GetDlgChild( "hongdian" );
	self.m_pBtnRoll = self:GetDlgChild( "btn_zuo.btn_2" );
	self.m_pWndRollRed = self.m_pBtnRoll:GetDlgChild( "hongdian" );
	self.m_pBtnSignIn:AddActionListener( "OnClickBtn", self );
	self.m_pBtnRoll:AddActionListener( "OnClickBtn", self );
	self.m_pWndSignIn = CSignInWnd:new( "gui/cfg/fsj_qiandao.gui", self.m_pList, 1 );
	self.m_pWndRoll = CRollWnd:new( "gui/cfg/fsj_zhuanpan.gui", self.m_pList, 1 );
	self.m_pWndLock = CGWnd:new( "gui/cfg/fsj_lockwindow.gui", self, 1 );
	self.m_pWndPrizeTip = CWndPrizeitemTip:new( "gui/cfg/fsj_qiandao_tips.gui", self, 1 );
	--获得时显示的窗口
	self.m_pWndResourceTip = CRollPrizeTip:new( "gui/cfg/fsj_huodeprop.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	self.m_pWndYinYueTip = CRollPrizeTip:new( "gui/cfg/fsj_huodeyinyue.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	self.m_pWndSkinTip = CRollPrizeTip:new( "gui/cfg/fsj_huodepifu.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	self.m_pWndFragmentTip = CRollPrizeTip:new( "gui/cfg/fsj_huodesuipian.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	self.m_pWndRhythmBarTip = CRollPrizeTip:new( "gui/cfg/fsj_huodejiezoutishiqi.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	self.m_pWndFaceTip = CRollPrizeTip:new( "gui/cfg/fsj_huodebiaoqing.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
	self.m_pBtnSignIn:SetCheck( true );	
	self:OnClickBtn();
end

function CActivityWnd:OnWndShow( bShow )
	if bShow then
		self.m_pBtnSignIn:SetCheck( true );	
		self:OnClickBtn();
		self.m_pWndSignInRed:ShowWnd( g_App:GetGameStart().m_bCanSignIn );
		self.m_pWndRollRed:ShowWnd( g_App:GetGameStart().m_bCanRoll );
	end
end

function CActivityWnd:OnClickBtn()
	self.m_pWndSignIn:ShowWnd( self.m_pBtnSignIn:GetCheck() );
	self.m_pWndRoll:ShowWnd( self.m_pBtnRoll:GetCheck() );
end

function CActivityWnd:OnClickClose()
	self:ShowWnd( false );
end

function CSignInWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CSignInWnd:OnCreated()
	self.m_pListDays = self:GetDlgChild( "list" );
	self.m_pListDays:ShowWnd( false );
	self.m_pBtnSignIn = self:GetDlgChild( "B_qiandao" );
	self.m_pBtnSignIn:AddActionListener( "OnClickSignIn", self );
end

function CSignInWnd:OnWndShow( bShow )
	if bShow then
		self:InitList();
	end
end

function CSignInWnd:InitList()
	self.m_pListDays:DeleteAllItem();
	self.m_pListDays:DeleteAllColumn();
	self.m_pListDays:ShowWnd( false );
	self.m_tblWeekItem = {};
	self.m_tblWeekItemType = {};
	
	for j = 1, 7 do		--一行显示7天
		self.m_pListDays:InsertColumn( j - 1, self.m_pListDays:GetWndWidth() / 7 );
	end
	for i = 1, 5 do		--最多显示5行
		self.m_tblWeekItem[i] = {};
		self.m_tblWeekItemType[i] = {};
		for j = 1, 7 do		--一行显示7天
			table.insert( self.m_tblWeekItem[i], "gui/cfg/fsj_qiandao_item.gui" );
			table.insert( self.m_tblWeekItemType[i], CWndSignInItem );
		end
		self.m_pListDays:InsertRowItemsFromRes( -1, self.m_tblWeekItem[i], self.m_tblWeekItemType[i] );
		self.m_pListDays:SetItemHeight( self.m_pListDays:GetWndHeight() / 5, -1 );
	end
	self.m_pListDays:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	self.m_pListDays:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectListItem", self );
end

function CSignInWnd:OnItemListLoaded()
	self.m_pListDays:RemoveActionListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	for i = 0, 34 do
		local pDayItem = self.m_pListDays:GetSubItem( math.floor( i / 7 ), i % 7 );
		if i >= self.m_nMonthDays then
			self.m_pListDays:SetSubItemVisible( false, math.floor( i / 7 ), i % 7 );
		end
		if i <= self.m_nMonthDays - 1 then
			local bSignIn = BitAnd( self.m_nSignInRecord, LeftShift( 1, i ) );
			pDayItem.m_pWndTime:SetWndText( i + 1 );
			pDayItem.m_pWndFinish:ShowWnd( i <= self.m_nDayOfMonth - 1 and bSignIn ~= 0 );
			pDayItem.m_pWndToday:ShowWnd( self.m_nDayOfMonth - 1 == i );
			pDayItem.m_pWndEver:ShowWnd( i < self.m_nDayOfMonth - 1 );
			local nPrizeID = self.m_tblMonthPrize[i + 1];
			local nBigType = CRewardConfig:Inst():GetType( nPrizeID );
			local nSmallType = CRewardConfig:Inst():GetItemID( nPrizeID );
			local nCount = CRewardConfig:Inst():GetCount( nPrizeID );
			local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nBigType, nSmallType ).nIconID;
			pDayItem.m_pWndPrize:SetIconID( nIconID );
			pDayItem.m_pWndPrizeNum:SetWndText( nCount );
			pDayItem.m_pWndNormal:ShowWnd( CSignInPrizeConfig:Inst():GetDayType( self.m_nDayStamp, i ) == 0 );
			pDayItem.m_pWndSpecial:ShowWnd( CSignInPrizeConfig:Inst():GetDayType( self.m_nDayStamp, i ) ~= 0 );
			pDayItem.m_pWndTag1:ShowWnd( CSignInPrizeConfig:Inst():GetTag( self.m_nDayStamp, i ) == 1 );
			pDayItem.m_pWndTag2:ShowWnd( CSignInPrizeConfig:Inst():GetTag( self.m_nDayStamp, i ) == 2 );
		end
	end
	self.m_pListDays:ShowWnd( true );
end

function CSignInWnd:ReFreshWnd()
	if self.m_pListDays:GetItemCount() > 0 then
		self:InitList();
	end
end

function CSignInWnd:SelectListItem( Event )
	local nSubItemWParam = Event.m_wParam;  --listctrl被选控件的行
    local nSubItemLParam = Event.m_lParam;  --listctrl被选控件的列
	g_App:GetGameStart().m_pWndActivity.m_pWndPrizeTip:ShowTip( self.m_tblMonthPrize[nSubItemWParam* 7 + nSubItemLParam + 1] );
end

function CSignInWnd:OnClickSignIn()	
	local NetMsg = CQueryActivity:new();
	NetMsg.nHandleType = eHAST_Update;
	NetMsg.nActivityType = eDAT_SignIn;
	g_App:SendShellMsg( NetMsg );
end

function CSignInWnd:SetSignInData( nFlag, nSignInRecord, nDayStamp )
	self.m_nFlag = nFlag or LeftShift( 1, 0 );
	self.m_nDayStamp = nDayStamp;
	self.m_nSignInRecord = nSignInRecord;
	self.m_nMonthDays = self:GetCurMonthDays( self.m_nDayStamp );
	local pPrizeValue = CBufferStream:new( 100 );
	CSignInPrizeConfig:Inst():GetCurMonthPrize( self.m_nDayStamp, pPrizeValue );
	self.m_tblMonthPrize = {};
	for i = 1, self.m_nMonthDays do
		table.insert( self.m_tblMonthPrize, pPrizeValue:ReadUint16() );
	end
end

function CSignInWnd:GetCurMonthDays( nDayStamp )
	local pSTime = GetFormatTimeSTMFromMillisecond( nDayStamp * DayMiSeconds );
	self.m_nDayOfMonth = pSTime:m_nDayOfMonth();
	local nTime1 = Format2LocalTime( pSTime:m_nYear(), pSTime:m_nMonth(), 1, 1, 1, 1 );
	if pSTime:m_nMonth() == 12 then
		return 31;
	else
		local nTime2 = Format2LocalTime( pSTime:m_nYear(), pSTime:m_nMonth() + 1, 1, 1, 1, 1 );
		return ( nTime2 - nTime1 ) / DaySeconds;
	end
end

function CSignInWnd:ShowSignInPrize()
	local nPrizeItemID = self.m_tblMonthPrize[self.m_nDayOfMonth];
	local nType = CRewardConfig:Inst():GetType( nPrizeItemID );
	local nItemID = CRewardConfig:Inst():GetItemID( nPrizeItemID );
	local nCount = CRewardConfig:Inst():GetCount( nPrizeItemID );
	local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).nIconID;
	local sName = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).dName;
	if nType ==  eGRT_Resource then
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip:ShowWnd( true );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip.m_pIcon:SetIconID( nIconID );
		nCount = g_App:GetMainPlayerData():IsVip() and nCount * VIP_Activity_Mul or nCount;
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip:GetDlgChild( "shuliang" ):SetWndText( nCount );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip.m_pWndTips:ShowWnd( not g_App:GetMainPlayerData():IsVip() );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip.m_pWndTips:SetWndText( g_App:GetString( "huiyuanqiandaotips" ) );
	elseif nType == eGRT_Equip then
		g_App:GetGameStart().m_pWndActivity.m_pWndSkinTip:ShowWnd( true );   
		local pRenderObject = g_App:CreateRenderObject();
		pRenderObject:OnEquipUpdated( nItemID, 0, true, false );

		local pair = SFramePair:new();
		pair:m_uStart(2);
		pair:m_uEnd(2);
		pRenderObject:SetNodeAni( "stand", nil, pair, eAPT_Once, 0, 0, 1.0, nil );
		local pViewportRenderer = g_App:GetGameStart().m_pWndActivity.m_pWndSkinTip:GetDlgChild( "moxing" ):GetViewportRenderer();
		pViewportRenderer:AddChild( pRenderObject );
		local Camera = pViewportRenderer:GetCamera();
		Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
		Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
		Camera:SetDest( CVector3f:new( 0, 25, 0 ) );
		local str = string.format( CStringConfig:Inst():GetString( "huodepifu" ), sName );
		g_App:GetGameStart().m_pWndActivity.m_pWndSkinTip:GetDlgChild( "bg" ):SetWndText( str );   
	elseif nType == eGRT_Music then
		g_App:GetGameStart().m_pWndActivity.m_pWndYinYueTip:ShowWnd( true );
		local str = string.format( CStringConfig:Inst():GetString( "huodeyinyue" ), CMusicConfig:Inst():GetMusicName( nItemID ) );
		g_App:GetGameStart().m_pWndActivity.m_pWndYinYueTip:GetDlgChild( "bg" ):SetWndText( str );   
	elseif nType == eGRT_RhythmNoticeBar then
		g_App:GetGameStart().m_pWndActivity.m_pWndRhythmBarTip:ShowWnd( true );
		if g_App:GetGameStart().m_pWndActivity.m_pWndRhythmBarTip.m_pIcon then
			g_App:GetGameStart().m_pWndActivity.m_pWndRhythmBarTip.m_pIcon:SetIconID( nIconID );
		end
		g_App:GetGameStart().m_pWndActivity.m_pWndRhythmBarTip:GetDlgChild( "name" ):SetWndText( sName );
	elseif nType == eGRT_BattleFace then
		g_App:GetGameStart().m_pWndActivity.m_pWndFaceTip:ShowWnd( true );
		g_App:GetGameStart().m_pWndActivity.m_pWndFaceTip:GetDlgChild( "biaoqing" ):AddEffect( g_tblTabFile.battleface[nItemID].szEffectFilePath, "fx/loop", nil, -1 );	
		local str = string.format( CStringConfig:Inst():GetString( "huodebiaoqing" ), sName );
		g_App:GetGameStart().m_pWndActivity.m_pWndFaceTip:GetDlgChild( "bg" ):SetWndText( str );   
	elseif nType == eGRT_TreasureBox or nType == eGRT_Fragment then
		g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip:ShowWnd( true );
		if g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip.m_pIcon then
			g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip.m_pIcon:SetIconID( nIconID );
		end
		g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip.m_pWndCount:SetWndText( nCount );
	end
end

function CWndSignInItem:Ctor( szResName, wndParent, nLoadType )
	CGButton.Ctor( self, szResName, wndParent, nLoadType );	
end

function CWndSignInItem:OnCreated()
	self.m_pWndPrize = CRichIconWnd:new( self, "teshu.wupin" );
	self.m_pWndTime = self:GetDlgChild( "putong.riqi" );
	self.m_pWndPrizeNum = self:GetDlgChild( "teshu.shuliang" );
	self.m_pWndFinish = self:GetDlgChild( "gou" );
	self.m_pWndToday = self:GetDlgChild( "today" );
	self.m_pWndNormal = self:GetDlgChild( "putong" );
	self.m_pWndSpecial = self:GetDlgChild( "teshu" );
	self.m_pWndTag1 = self:GetDlgChild( "teshu.tag1" );
	self.m_pWndTag2 = self:GetDlgChild( "teshu.tag2" );
	self.m_pWndEver = self:GetDlgChild( "guoqi" );
end

function CWndPrizeitemTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );	
end

function CWndPrizeitemTip:OnCreated()
	self.m_pWndTipPrize = CRichIconWnd:new( self, "jiangli.wupin" );
	self.m_pWndTipPrizeNum = self:GetDlgChild( "jiangli.shuliang" );
	self.m_pBtnConfirm = self:GetDlgChild( "b_ok" );
	self.m_pBtnConfirm:AddActionListener( "OnClickConfirm", self );
end

function CWndPrizeitemTip:OnClickConfirm()
	self:ShowWnd( false );
end

function CWndPrizeitemTip:ShowTip( nPrizeID )	
	local nBigType = CRewardConfig:Inst():GetType( nPrizeID );
	local nSmallType = CRewardConfig:Inst():GetItemID( nPrizeID );
	local nCount = CRewardConfig:Inst():GetCount( nPrizeID );
	local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nBigType, nSmallType ).nIconID;
	self.m_pWndTipPrize:SetIconID( nIconID );
	self.m_pWndTipPrizeNum:SetWndText( nCount );
	self:ShowWnd( true );
end

local Prize_Item_Num = RollActivity_Item_Num;

function CRollWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );	
	self.m_tickRoll = CTick:new( "OnPrizeStay", self, nil, 1 );
	self.m_tickRollEnd = CTick:new( "OnRollEnd", self, nil, 1 );
end

function CRollWnd:OnCreated()
	self.m_pBtnRoll = self:GetDlgChild( "B_choujiang" );
	self.m_pBtnRoll:AddActionListener( "OnClickRoll", self );
	self.m_pWndPrize = self:GetDlgChild( "neirong" );
	self.m_pWndRollTime = self:GetDlgChild( "choujiangshijian" );
	self.m_pWndRollNum = self:GetDlgChild( "choujiangcishu" );
	self.m_pWndTips = self:GetDlgChild( "tips" );

	self.m_tblWndPrize = {};
	self:InitWnd();

	local pAudio = self:GetRenderer():GetAudio();
	if pAudio then
		self.m_pGetRollItem = pAudio:CreateSound( "sound/zhuanpanmingzhong.mp3", false );
		if self.m_pGetRollItem then
			self.m_pGetRollItem:SetVolume( 0.5 );
		end
	end
end

function CRollWnd:OnDestroy()
	CGWnd.OnDestroy( self );
	self.m_pGetRollItem = nil;
end

function CRollWnd:OnWndShow( bShow )
	if bShow then
		self:InitWnd();
		self:InitRollWnd();
	end
end

function CRollWnd:InitWnd()
	for i = 1, Prize_Item_Num do
		table.insert( self.m_tblWndPrize, self.m_pWndPrize:GetDlgChild( i ) );
		self.m_tblWndPrize[i]:GetDlgChild( "xuanzhong" ):ShowWnd( false );
		self.m_tblWndPrize[i].pIcon = CRichIconWnd:new( self.m_tblWndPrize[i], "wupin" );
		self.m_tblWndPrize[i].pName = self.m_tblWndPrize[i]:GetDlgChild( "wupin.name" );
	end
	--self.m_tblWndPrize[1]:GetDlgChild( "xuanzhong" ):ShowWnd( true );
	self.m_tblRollItems = {};
	self.m_pLastWnd = self.m_tblWndPrize[1]:GetDlgChild( "xuanzhong" );
	g_App:GetGameStart().m_pWndActivity.m_pWndLock:ShowWnd( false );
end

function CRollWnd:OnClickRoll()
	local NetMsg = CQueryActivity:new();
	NetMsg.nHandleType = eHAST_Update;
	NetMsg.nActivityType = eDAT_Roll;
	g_App:SendShellMsg( NetMsg );
end

function CRollWnd:SetRollPrize( nPrizeIndex, nPrizePos, nLeftTimes )
	self.m_nPrizeIndex = nPrizeIndex;
	self.m_nPrizePos = nPrizePos;
	self.m_nLeftTimes = nLeftTimes;
	self:InitRollWnd();
	self:ShowRoll();
end

function CRollWnd:ShowRoll()	
	g_App:GetGameStart().m_pWndActivity.m_pWndLock:ShowAndSetFocus();
	self.m_tblRollItems = {}
	for i = 1, 2 do
		for j = 1, Prize_Item_Num do
			local tblItemInfo = {};
			tblItemInfo.pWnd = self.m_tblWndPrize[j];
			tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime();
			table.insert( self.m_tblRollItems, tblItemInfo );
		end
	end
	if self.m_nPrizePos > Prize_Item_Num / 2 then	--奖励在下半区
		for i = 1, self.m_nPrizePos - CSnakeConstant:Inst():GetRollSlowDownNum() do			
			local tblItemInfo = {};
			tblItemInfo.pWnd = self.m_tblWndPrize[i];
			tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime();
			table.insert( self.m_tblRollItems, tblItemInfo );
		end
		for i = self.m_nPrizePos - CSnakeConstant:Inst():GetRollSlowDownNum() + 1, self.m_nPrizePos do
			local tblItemInfo = {};
			tblItemInfo.pWnd = self.m_tblWndPrize[i];
			tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime() + i * CSnakeConstant:Inst():GetRollIncreaseTime();
			table.insert( self.m_tblRollItems, tblItemInfo );
		end
	else		--奖励在上半区
		if self.m_nPrizePos > CSnakeConstant:Inst():GetRollSlowDownNum() then	--比如从1减速到6
			for i = 1, Prize_Item_Num do
				local tblItemInfo = {};
				tblItemInfo.pWnd = self.m_tblWndPrize[i];
				tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime();
				table.insert( self.m_tblRollItems, tblItemInfo );
			end
			for i = 1, self.m_nPrizePos - CSnakeConstant:Inst():GetRollSlowDownNum() do
				local tblItemInfo = {};
				tblItemInfo.pWnd = self.m_tblWndPrize[i];
				tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime();
				table.insert( self.m_tblRollItems, tblItemInfo );
			end
			for i = self.m_nPrizePos - CSnakeConstant:Inst():GetRollSlowDownNum() + 1, self.m_nPrizePos do
				local tblItemInfo = {};
				tblItemInfo.pWnd = self.m_tblWndPrize[i];
				tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime() + i * CSnakeConstant:Inst():GetRollIncreaseTime();
				table.insert( self.m_tblRollItems, tblItemInfo );
			end
		else						--比如从10减速到2
			for i = 1, self.m_nPrizePos + Prize_Item_Num - CSnakeConstant:Inst():GetRollSlowDownNum() do
				local tblItemInfo = {};
				tblItemInfo.pWnd = self.m_tblWndPrize[i];
				tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime();
				table.insert( self.m_tblRollItems, tblItemInfo );
			end
			local nNum = 1;
			for i = self.m_nPrizePos + Prize_Item_Num - CSnakeConstant:Inst():GetRollSlowDownNum() + 1, Prize_Item_Num do
				local tblItemInfo = {};
				tblItemInfo.pWnd = self.m_tblWndPrize[i];
				tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime() + nNum * CSnakeConstant:Inst():GetRollIncreaseTime();
				table.insert( self.m_tblRollItems, tblItemInfo );
				nNum = nNum + 1;
			end
			for i = 1, self.m_nPrizePos do
				local tblItemInfo = {};
				tblItemInfo.pWnd = self.m_tblWndPrize[i];
				tblItemInfo.nStayTime = CSnakeConstant:Inst():GetRollStayTime() + nNum * CSnakeConstant:Inst():GetRollIncreaseTime();
				table.insert( self.m_tblRollItems, tblItemInfo );
				nNum = nNum + 1;
			end
		end		
	end
	self:OnPrizeStay();
end

function CRollWnd:OnPrizeStay()
	self.m_tickRoll:Stop();
	local tblRollItem = self.m_tblRollItems[1];
	self.m_pLastWnd:ShowWnd( false );
	tblRollItem.pWnd:GetDlgChild( "xuanzhong" ):ShowWnd( true );
	if #self.m_tblRollItems > 1 then
		self.m_tickRoll:Start( tblRollItem.nStayTime );
	else		--结束
		if self.m_pGetRollItem then
			self.m_pGetRollItem:Play( false, true );
		end
		self.m_tickRollEnd:Start( CSnakeConstant:Inst():GetRollEndStayTime() );
	end
	self.m_pLastWnd = self.m_tblRollItems[1].pWnd:GetDlgChild( "xuanzhong" );
	table.remove( self.m_tblRollItems, 1 );
end

function CRollWnd:OnRollEnd()
	self.m_tickRollEnd:Stop();
	g_App:GetGameStart().m_pWndActivity.m_pWndLock:ShowWnd( false );
	local nPrizeItemID = CRollActivityConfig:Inst():GetPrizeIDByPos( self.m_nPrizeIndex, self.m_nPrizePos );
	local nType = CRewardConfig:Inst():GetType( nPrizeItemID );
	local nItemID = CRewardConfig:Inst():GetItemID( nPrizeItemID );
	local nCount = CRewardConfig:Inst():GetCount( nPrizeItemID );
	local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).nIconID;
	if nType ==  eGRT_Resource then
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip:ShowWnd( true );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip.m_pIcon:SetIconID( nIconID );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip:GetDlgChild( "shuliang" ):SetWndText( nCount );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip.m_pWndTips:ShowWnd( not g_App:GetMainPlayerData():IsVip() );
		g_App:GetGameStart().m_pWndActivity.m_pWndResourceTip.m_pWndTips:SetWndText( g_App:GetString( "huiyuanchoujiangtips" ) );
	elseif nType == eGRT_Fragment then
		g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip:ShowWnd( true );
		if g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip.m_pIcon then
			g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip.m_pIcon:SetIconID( nIconID );
		end
		g_App:GetGameStart().m_pWndActivity.m_pWndFragmentTip.m_pWndCount:SetWndText( nCount );
	end
	self:InitWnd();
end

function CRollWnd:SetRollPrizeIndex( nRollIndex, nLeftTimes )
	self.m_nPrizeIndex = nRollIndex;
	self.m_nLeftTimes = nLeftTimes;
end

function CRollWnd:InitRollWnd()
	for i = 1, Prize_Item_Num do
		local nPrizeItemID = CRollActivityConfig:Inst():GetPrizeIDByPos( self.m_nPrizeIndex, i );
		local nTag = CRollActivityConfig:Inst():GetTagByPos( self.m_nPrizeIndex, i );
		local nType = CRewardConfig:Inst():GetType( nPrizeItemID );
		local nItemID = CRewardConfig:Inst():GetItemID( nPrizeItemID );
		local nCount = CRewardConfig:Inst():GetCount( nPrizeItemID );
		local nIconID = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).nIconID;
		local sName = CPropBaseConfigMgr:Inst():GetConfig( nType, nItemID ).dName;
		self.m_tblWndPrize[i].pName:SetWndText( sName );
		self.m_tblWndPrize[i].pIcon:SetIconID( nIconID );
		self.m_tblWndPrize[i]:GetDlgChild( "wupin.shuliang" ):SetWndText( nCount );
		self.m_tblWndPrize[i]:GetDlgChild( "tag1" ):ShowWnd( nTag == 1 );
		self.m_tblWndPrize[i]:GetDlgChild( "tag2" ):ShowWnd( nTag == 2 );
	end
	
	local nRoll1StartTime = CRollActivityConfig:Inst():GetActivityStartHour( 0 );
	local nRoll1EndTime = CRollActivityConfig:Inst():GetActivityEndHour( 0 );
	local nRoll2StartTime = CRollActivityConfig:Inst():GetActivityStartHour( 1 );
	local nRoll2EndTime = CRollActivityConfig:Inst():GetActivityEndHour( 1 );
	local nRollNum = CRollActivityConfig:Inst():GetActivityTimes( 0, g_App:GetMainPlayerData():IsVip() );
	local str1 = string.format( CStringConfig.Inst():GetString( "choujiangshijian" ), nRoll1StartTime, nRoll1EndTime, nRoll2StartTime, nRoll2EndTime );
	local str2 = string.format( CStringConfig.Inst():GetString( "choujiangcishu" ), nRollNum );
	self.m_pWndRollTime:SetWndText( str1 );
	self.m_pWndRollNum:SetWndText( str2 );
	self.m_nLeftTimes = self.m_nLeftTimes or CRollActivityConfig:Inst():GetActivityTimes( 0, g_App:GetMainPlayerData():IsVip() );
	self.m_pWndTips:ShowWnd( g_App:GetMainPlayerData():IsVip() );
	if self.m_nLeftTimes == 0 then
		self.m_pWndTips:SetWndText( g_App:GetString( "huiyuanchoujiangjiehsu" ) );
	else
		self.m_pWndTips:SetWndText( string.format( g_App:GetString( "huiyuanchoujiangcishu" ), self.m_nLeftTimes ) );
	end
end

function CRollPrizeTip:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );	
end

function CRollPrizeTip:OnCreated()
	self.m_pWndCount = self:GetDlgChild( "shuliang" );
	self.m_pBtnContinue = self:GetDlgChild( "btn_jixu" );
	self.m_pWndTips = self:GetDlgChild( "tips" );
	self.m_pIcon = CRichIconWnd:new( self, "tietu" );
	self.m_pBtnContinue:AddActionListener( "OnClickContinue", self );
end

function CRollPrizeTip:OnClickContinue()
	self:ShowWnd( false );
end
--endregion
