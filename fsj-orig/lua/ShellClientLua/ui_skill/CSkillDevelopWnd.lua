--region CSkillDevelopWnd.lua
--Date	2018/1/3
--此文件由[BabeLua]插件自动生成

local nListShowNum = 5;

function CSkillDevelopWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CSkillDevelopWnd:OnCreated()	
	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_pWndMoney = self:GetDlgChild( "jinbi.jinbishuliang" );
	self.m_pWndRainbowGold = self:GetDlgChild( "jinbi2.jinbishuliang" );
	self.m_pWndSkillGold = self:GetDlgChild( "jinengdaoju.jinbishuliang" );
	self.m_BtnShare = self:GetDlgChild( "jinbi2.btn_add" );
	self.m_pBtnActive = self:GetDlgChild( "liebiao.btn_1" );
	self.m_pBtnPassive = self:GetDlgChild( "liebiao.btn_2" );
	self.m_list = self:GetDlgChild( "list" );
	self.m_pWndDelockInfo = self:GetDlgChild( "jiesuotiaojian" );
	self.m_pWndSkillInfo = self:GetDlgChild( "miaoshu" );
	self.m_pWndSkillIcon = CRichIconWnd:new( self, "icon" );
	self.m_pBtnDelock = self:GetDlgChild( "b_jiesuo" );
	self.m_pWndDelockCost = CRichIconWnd:new( self.m_pBtnDelock, "icon" );
	self.m_pWndMaxLevel = self:GetDlgChild( "manji" );
	self.m_pWndContent = self:GetDlgChild( "miaoshu" );
	self.m_pProExp = self:GetDlgChild( "jindutiao" );
	self.m_pBtnUpgrade = self:GetDlgChild( "b_shengji" );
	self.m_pWndUpgradeCost = CRichIconWnd:new( self.m_pBtnUpgrade, "icon" );
	self.m_pBtnLock = self:GetDlgChild( "b_weijiesuo" );
	self.m_pWndEffect = self:GetDlgChild( "tx" );
	self.m_pBtnDirection = self:GetDlgChild( "b_bangzhu" );
	self.m_pBtnSkillGold = self:GetDlgChild( "jinengdaoju" );
	
	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new ( "OnRefreshTimeTick", self );
	self.m_tblShowSkillInfo = {};		--右侧显示  
	self.m_pWndLockTip = CLockTipWnd:new( "gui/cfg/messageboxdanxuan.gui", self, 1 );

	self.m_list:SetInertiaType( eInertiaType_HScroll );
	
	self.m_pBtnActive:AddActionListener( "OnClickShow", self );
	self.m_pBtnPassive:AddActionListener( "OnClickShow", self );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
	self.m_BtnShare:AddActionListener( "OpenShareWnd", g_App:GetGameStart() );
	self.m_pBtnDelock:AddActionListener( "OnDelockSkill", self );
	self.m_pBtnUpgrade:AddActionListener( "OnUpgradeSkill", self );
	self.m_pBtnLock:AddActionListener( "OnClickLock", self );
	self.m_pBtnDirection:AddActionListener( "OnClickDirection", self );
	self.m_pBtnSkillGold:AddEventListener( GM_WM_MOUSECLICK, "ShowSkillGoldDesc", self );
	g_App:GetMainPlayerData():AddEventListener( "m_DBSkillData", "UpdateInfo", self );	--有可能段位发生变化，影响技能
	g_App:GetMainPlayerData():AddEventListener( "m_DBSkillData", "RefreshSkillInfo", self );
	g_App:GetMainPlayerData():AddEventListener( "m_PassiveSkill", "UpdateInfo", self );
end

function CSkillDevelopWnd:OnDestroy()
	self.m_timeTick:Stop();
	self.m_list:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	self.m_list:RemoveEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectListItem", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_DBSkillData", "UpdateInfo", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_DBSkillData", "RefreshSkillInfo", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_PassiveSkill", "UpdateInfo", self );
	CGWnd.OnDestroy( self );
end

function CSkillDevelopWnd:OnWndShow( bShow )
	if bShow then
		if not g_App:GetFirstEvent( eFE_ShowSkillDirections ) then
			g_App:GetGameStart().m_pWndTip:ShowTipWnd( eShowTipType_Skill );
			local NetMsg = CAlterFirstEvent:new();
			NetMsg.nFirstEventType = eFE_ShowSkillDirections;
			g_App:SendShellMsg( NetMsg );
		end
		self.m_timeTick:Start(100);
		self.m_pBtnActive:SetCheck( true );
		self:OnClickShow();
	else
		self.m_timeTick:Stop();
		self.m_listHorizonPos = nil;
	end
end

function CSkillDevelopWnd:OnClose()
	self:ShowWnd( false );
end

function CSkillDevelopWnd:OnClickDirection()
	g_App:GetGameStart().m_pWndTip:ShowTipWnd( eShowTipType_Skill );
	if not g_App:GetFirstEvent( eFE_ShowSkillDirections ) then
		local NetMsg = CAlterFirstEvent:new();
		NetMsg.nFirstEventType = eFE_ShowSkillDirections;
		g_App:SendShellMsg( NetMsg );
	end
end

function CSkillDevelopWnd:OnRefreshTimeTick()	
	if not g_App or not g_App:GetWorldConn() then
		return;
	end
	local wifi = g_App:GetWorldConn():GetPingDelay();
	local nIconShowed = wifi < ePing_low and 3 or ( wifi > ePing_high and 1 or 2 );
	for k, v in pairs( self.m_wifiIcon ) do
		self.m_wifiIcon[k]:ShowWnd( k == nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild( "wangsu" ):SetWndText( wifi );
	end
	local nCoinCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Gold );
	self.m_pWndMoney:SetWndText( tostring( nCoinCount ) );
	local nRainbowGold = g_App:GetPropCount( eGRT_Resource, eResourceType_RainbowGold );
	self.m_pWndRainbowGold:SetWndText( nRainbowGold );
	local nSkillGold = g_App:GetPropCount( eGRT_Resource, eResourceType_SkillGold );
	self.m_pWndSkillGold:SetWndText( nSkillGold );
end

function CSkillDevelopWnd:OnClickShow()
	self.m_listHorizonPos = nil;
	self.m_tblShowSkillInfo = {};
	self:InitList();
end

function CSkillDevelopWnd:InitList()
	self:InitSkillTbl();
	self.m_list:DeleteAllItem();
	self.m_list:DeleteAllColumn();
	self.m_list:ShowWnd( false );
	self.m_tblGuiItem = {};
	self.m_tblClassItem = {};
	
	local nItemNum = #self:GetShowSkillTbl();
	for j = 1, nItemNum do
		self.m_list:InsertColumn( j - 1, self.m_list:GetWndWidth() / nListShowNum );
		table.insert( self.m_tblGuiItem, "gui/cfg/fsj_jineng_item.gui" );
		if self.m_pBtnActive:GetCheck() then
			table.insert( self.m_tblClassItem, CSkillDevelopActiveItem );
		else
			table.insert( self.m_tblClassItem, CSkillDevelopPassiveItem );
		end
	end
	self.m_list:InsertRowItemsFromRes( -1, self.m_tblGuiItem, self.m_tblClassItem );

	self.m_list:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	self.m_list:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "SelectListItem", self );
end

function CSkillDevelopWnd:OnItemListLoaded()
	self.m_list:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnItemListLoaded", self ); 
	self:RefreshInfo( self:GetInitSkillID(), true );
	self.m_list:SetScrollHorizonPos( self:GetInitPos() );
end

function CSkillDevelopWnd:UpdateInfo()
	self:InitSkillTbl();
	local tblSkill = self:GetShowSkillTbl();	
	local nInitSkillID = 0;
	if self.m_nSelectIndex then
		nInitSkillID = tblSkill[self.m_nSelectIndex].nSkillID;
	else
		nInitSkillID = self:GetInitSkillID();
	end
	self:RefreshInfo( nInitSkillID );
	self:RefreshSkillInfo();
end

function CSkillDevelopWnd:GetInitSkillID()
	if self.m_pBtnActive:GetCheck() then
		return g_App:GetMainPlayerData().m_CharBaseData:GetSkillID();
	else
		local TblPassiveSkill = {};
		for i = 1, CSnakeConstant:Inst():GetPassvieSkillNum() do
			local nPassiveSkillID = g_App:GetMainPlayerData().m_PassiveSkill:GetData( i - 1 );
			if nPassiveSkillID ~= 0 then
				return g_App:GetMainPlayerData().m_PassiveSkill:GetData( i - 1 );
			end
		end
		return 0;
	end
end

function CSkillDevelopWnd:GetInitPos()
	local tblSkill = self:GetShowSkillTbl();
	for i = 1, #tblSkill do
		if tblSkill[i].nSkillID == self:GetInitSkillID() then
			if i <= ( nListShowNum + 1 ) / 2 then		--前几个
				return 0;
			elseif i >= ( #tblSkill - ( nListShowNum - 1 ) / 2 ) then		--后几个
				return self.m_list:GetWndWidth() / nListShowNum * ( #tblSkill - nListShowNum );
			else
				return self.m_list:GetWndWidth() / nListShowNum * ( i - ( nListShowNum + 1 ) / 2 );
			end
		end
	end
	return 0;
end

function CSkillDevelopWnd:RefreshInfo( nInitSkillID, bInit )
	local nItem = self.m_list:GetItemCount();
	local nCol  = self.m_list:GetColumnCount();
	local tblSkill = self:GetShowSkillTbl();
	local nItemNum = #tblSkill;
	for j = 0, nCol - 1 do
		local pSkillItem = self.m_list:GetSubItem( 0, j );
		local nIndex = j + 1;
		if nIndex > nItemNum then
			self.m_list:SetSubItemVisible( false, 0, j );
		else
			pSkillItem.m_tblSkill = tblSkill[nIndex];
			pSkillItem:RefreshInfo( nInitSkillID );
			if bInit and pSkillItem.m_tblSkill.nSkillID == nInitSkillID then
				self.m_tblShowSkillInfo = tblSkill[nIndex];
			end
		end
	end
	self.m_list:ShowAndSetFocus();
	self:RefreshSkillInfo();
	if self.m_listHorizonPos then
		self.m_list:SetScrollHorizonPos( self.m_listHorizonPos );
	end
end

function CSkillDevelopWnd:SelectListItem( Event )
	local nSubItemWParam = Event.m_wParam;  --listctrl被选控件的行
    local nSubItemLParam = Event.m_lParam;  --listctrl被选控件的列
	local nIndex = nSubItemLParam + 1;
	local pSkillItem = self.m_list:GetSubItem( 0, nSubItemLParam );
	local tblSkill = self:GetShowSkillTbl();
	self.m_nSelectIndex = nIndex;
	self.m_tblShowSkillInfo = tblSkill[nIndex];
	self:RefreshSkillInfo();
	self.m_listHorizonPos = self.m_list:GetScrollHorizonPos();
	--print( "22222222CSkillDevelopWnd:SelectListItem", nIndex, self.m_list:GetScrollHorizonPos(), self.m_list:GetWndWidth() / nListShowNum );
end

function CSkillDevelopWnd:InitSkillTbl()
	self.m_tblActiveSkill = {};
	self.m_tblPassiveSkill = {};
	self.m_nSkillNum = 0;
	for i = 1, Max_SkillDevelop_Num do
		local SkillInfo = g_App:GetMainPlayerData().m_DBSkillData:GetData( i - 1 );
		local nSkillID = SkillInfo:GetSkillID();
		local nSkillState = SkillInfo:GetState();
		local nSkillLevel = SkillInfo:GetLevel();
		if nSkillID ~= 0 and g_tblTabFile.skill[nSkillID].nShow == 1 then
			local tblSkill = {};
			tblSkill.nSkillID = nSkillID;
			tblSkill.nSkillState = nSkillState;
			tblSkill.nSkillLevel = nSkillLevel;
			tblSkill.nSkillSort = g_tblTabFile.skill[nSkillID].nSort;
			
			if g_tblTabFile.skill[nSkillID].nSkillType == eConfigSkillType_Active then	--主动技能 
				table.insert( self.m_tblActiveSkill, tblSkill );
			elseif g_tblTabFile.skill[nSkillID].nSkillType == eConfigSkillType_Passive then	--被动技能 
				table.insert( self.m_tblPassiveSkill, tblSkill );
			end

			self.m_nSkillNum = self.m_nSkillNum + 1;
		elseif nSkillID == 0 then
			break;
		end
	end
	table.sort( self.m_tblActiveSkill, function( a, b ) return a.nSkillSort < b.nSkillSort end );
	table.sort( self.m_tblPassiveSkill, function( a, b ) return a.nSkillSort < b.nSkillSort end );
end

function CSkillDevelopWnd:GetShowSkillTbl()
	if self.m_pBtnActive:GetCheck() then
		return self.m_tblActiveSkill;
	else
		return self.m_tblPassiveSkill;
	end
end

function CSkillDevelopWnd:RefreshSkillInfo()
	if not next( self.m_tblShowSkillInfo ) then
		return;
	end

	local tblNewInfo = self:GetShowSkillTbl();
	for i = 1, #tblNewInfo do
		if tblNewInfo[i].nSkillID == self.m_tblShowSkillInfo.nSkillID then
			self.m_tblShowSkillInfo = tblNewInfo[i];
			break;
		end
	end

	--self.m_tblShowSkillInfo
	local SkillConf = g_tblTabFile.skill[self.m_tblShowSkillInfo.nSkillID];
	local bMaxLevel = self.m_tblShowSkillInfo.nSkillLevel == SkillConf.nMaxLevel;
	local bDelock = not bMaxLevel and ( self.m_tblShowSkillInfo.nSkillState == eSDST_Unlock );	--已解锁
	local bLock = self.m_tblShowSkillInfo.nSkillState == eSDST_Lock;	--未解锁
	self.m_pWndSkillIcon:SetIconID( SkillConf.nIconID );
	if bLock then
		self.m_pWndSkillInfo:SetWndText( CStringConfig:Inst():GetString( "wenhao" ) );
	else
		self.m_pWndSkillInfo:SetWndText( SkillConf.dDescription );
	end

	self.m_pWndMaxLevel:ShowWnd( bMaxLevel );
	self.m_pBtnDelock:ShowWnd( not bMaxLevel and self.m_tblShowSkillInfo.nSkillState == eSDST_CanDeblock );
	self.m_pWndDelockCost:SetIconID( g_tblTabFile.currency[SkillConf.nDelockType1].nIconID );
	self.m_pBtnDelock:GetDlgChild( "bg" ):SetWndText( SkillConf.nDelockValue1 );

	self.m_pWndContent:ShowWnd( true );
	self.m_pProExp:ShowWnd( not bMaxLevel and ( self.m_tblShowSkillInfo.nSkillState == eSDST_Unlock ) );
	self.m_pBtnUpgrade:ShowWnd( bDelock );
	self.m_pWndUpgradeCost:SetIconID( g_tblTabFile.currency[SkillConf.nUpgradeType].nIconID );
	self.m_pBtnUpgrade:GetDlgChild( "bg" ):SetWndText( SkillConf["nCurLV"..self.m_tblShowSkillInfo.nSkillLevel] );

	self.m_pBtnLock:ShowWnd( bLock );

	if bDelock then	--升级中
		local nRange = SkillConf["nCurLV"..self.m_tblShowSkillInfo.nSkillLevel];
		local nPos = g_App:GetMainPlayerData().m_Resource:GetData( SkillConf.nUpgradeType );
		self.m_pProExp:SetRange( nRange );
		self.m_pProExp:SetPos( nPos );
		self.m_pProExp:GetDlgChild( "shuzi" ):SetWndText( tostring( nPos ).."/"..nRange );
	end
	
end

function CSkillDevelopWnd:OnDelockSkill()
	local NetMsg = CDelockSkill:new();
	NetMsg.nSkillID = self.m_tblShowSkillInfo.nSkillID;
	g_App:SendShellMsg( NetMsg );
end

function CSkillDevelopWnd:OnUpgradeSkill()
	local NetMsg = CUpgradeSkill:new();
	NetMsg.nSkillID = self.m_tblShowSkillInfo.nSkillID;
	g_App:SendShellMsg( NetMsg );
end

function CSkillDevelopWnd:OnClickLock()
	local nDelockType2 = g_tblTabFile.skill[self.m_tblShowSkillInfo.nSkillID].nDelockType2;
	local nPreID = 0;
	if nDelockType2 == eSDDT_PreSkill then
		nPreID = g_tblTabFile.skill[self.m_tblShowSkillInfo.nSkillID].nDelockValue2;
	end
	if nPreID == 0 then
		return;
	end
	local str = CStringConfig.Inst():GetString( "jinengtips" );
	self.m_pWndLockTip.m_pWndTip:SetWndText( str );
	self.m_pWndLockTip:ShowWnd( true );
end

function CSkillDevelopWnd:ShowSkillGoldDesc()
	g_App:GetGameStart():ShowPropDescWnd( self, eGRT_Resource, eResourceType_SkillGold );
end

-------------------------CSkillDevelopItem----------------------------
function CSkillDevelopItem:Ctor( szResName, wndParent, nLoadType )
	CGCheckButton.Ctor( self, szResName, wndParent, nLoadType  );
end

function CSkillDevelopItem:OnCreated()
	self.m_pWndIcon = CRichIconWnd:new( self, "icon" );
	self.m_pBtnUse = self:GetDlgChild( "b_shiyong" );
	self.m_pBtnDelock = self:GetDlgChild( "b_kejiesuo" );
	self.m_pWndUnlock = self:GetDlgChild( "b_weijiesuo" );
	self.m_pWndInUse = self:GetDlgChild( "shiyongzhong" );
	self.m_pWndMaxLevel = self:GetDlgChild( "manji" );
	self.m_pWndCanUpgrade = self:GetDlgChild( "keshengji" );
	self.m_pWndSkillName = self:GetDlgChild( "name" );
	self.m_pWndCurLevel = self:GetDlgChild( "dengji" );
	self.m_pWndQuestion = self:GetDlgChild( "wenhao" );

	self.m_nItemType = 1;
	self.m_tblSkill = {};
	self.m_pBtnDelock:AddActionListener( "OnDelockSkill", self );
end

function CSkillDevelopItem:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CSkillDevelopItem:RefreshInfo( nCheckSkillID )
	local bSetCheck = self.m_tblSkill.nSkillID == nCheckSkillID;
	local bMaxLevel = self.m_tblSkill.nSkillLevel == g_tblTabFile.skill[self.m_tblSkill.nSkillID].nMaxLevel;
	local bInUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and self.m_tblSkill.nSkillID == g_App:GetMainPlayerData().m_CharBaseData:GetSkillID();
	if self.m_nItemType == 2 then
		bInUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and self:WhetherPassiveInUse( self.m_tblSkill.nSkillID );
	end
	local bShowUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and not bInUse;
	self.m_pBtnUse:ShowWnd( bShowUse );
	self.m_pBtnDelock:ShowWnd( not bMaxLevel and self.m_tblSkill.nSkillState == eSDST_CanDeblock );
	self.m_pWndInUse:ShowWnd( bInUse );
	self.m_pWndMaxLevel:ShowWnd( bMaxLevel );
	self.m_pWndCanUpgrade:ShowWnd( not bMaxLevel and ( self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock ) );
	if self.m_tblSkill.nSkillState ~= eSDST_Lock then
		self.m_pWndIcon:SetIconID( g_tblTabFile.skill[self.m_tblSkill.nSkillID].nIconID );
		self.m_pWndSkillName:SetWndText( g_tblTabFile.skill[self.m_tblSkill.nSkillID].dName );
	else
		self.m_pWndSkillName:SetWndText( CStringConfig:Inst():GetString( "wenhao" ) );
	end
	self.m_pWndUnlock:ShowWnd( self.m_tblSkill.nSkillState == eSDST_Lock );	
	self.m_pWndQuestion:ShowWnd( self.m_tblSkill.nSkillState == eSDST_Lock );	
	self.m_pWndCurLevel:GetDlgChild( "shuzi" ):SetWndText( self.m_tblSkill.nSkillLevel );
	self.m_pWndCurLevel:ShowWnd( self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock );
	if bSetCheck then
		self:SetCheck( true );
	end
end

function CSkillDevelopItem:OnDelockSkill()
	local NetMsg = CDelockSkill:new();
	NetMsg.nSkillID = self.m_tblSkill.nSkillID;
	g_App:SendShellMsg( NetMsg );
end

function CSkillDevelopItem:WhetherPassiveInUse( nSkillID )
	local TblPassiveSkill = {};
	for i = 1, CSnakeConstant:Inst():GetPassvieSkillNum() do
		local nPassiveSkillID = g_App:GetMainPlayerData().m_PassiveSkill:GetData( i - 1 );
		if nPassiveSkillID ~= 0 then
			table.insert( TblPassiveSkill, nPassiveSkillID );
		end
	end
	for i = 1, #TblPassiveSkill do
		if TblPassiveSkill[i] == nSkillID then
			return true;
		end
	end
	return false;
end

-------------------------CSkillDevelopActiveItem----------------------------
function CSkillDevelopActiveItem:Ctor( szResName, wndParent, nLoadType )
	CSkillDevelopItem.Ctor( self, szResName, wndParent, nLoadType  );
end

function CSkillDevelopActiveItem:OnCreated()
	CSkillDevelopItem.OnCreated( self );
	self.m_nItemType = 1;
	self.m_pBtnUse:AddActionListener( "OnClickChoose", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.SkillID", "RefreshActive", self );
end

function CSkillDevelopActiveItem:OnDestroy()
	CSkillDevelopItem.OnDestroy( self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.SkillID", "RefreshActive", self );
end

function CSkillDevelopActiveItem:OnClickChoose()
	print( "!!!!!!!!!!!!!!CSkillDevelopActiveItem:OnClickChoose SkillID", self.m_tblSkill.nSkillID );
	local NetMsg = CAlterUseSkill:new();
	NetMsg.nSkillID = self.m_tblSkill.nSkillID;
	g_App:SendShellMsg( NetMsg );
end

function CSkillDevelopActiveItem:RefreshActive()
	local bMaxLevel = self.m_tblSkill.nSkillLevel == g_tblTabFile.skill[self.m_tblSkill.nSkillID].nMaxLevel;
	local bInUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and self.m_tblSkill.nSkillID == g_App:GetMainPlayerData().m_CharBaseData:GetSkillID();
	local bShowUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and not bInUse;
	self.m_pWndInUse:ShowWnd( bInUse );
	self.m_pBtnUse:ShowWnd( bShowUse );
end

function CSkillDevelopActiveItem:SkillIsInUse()
	return self.m_tblSkill.nSkillID == g_App:GetMainPlayerData().m_CharBaseData:GetSkillID();
end

function CSkillDevelopActiveItem:IsDispatchPlayerDBEvent()
	return true;
end

-------------------------CSkillDevelopPassiveItem----------------------------
function CSkillDevelopPassiveItem:Ctor( szResName, wndParent, nLoadType )
	CSkillDevelopItem.Ctor( self, szResName, wndParent, nLoadType  );
end

function CSkillDevelopPassiveItem:OnCreated()
	CSkillDevelopItem.OnCreated( self );
	self.m_nItemType = 2;
	self.m_pWndInUse:AddActionListener( "OnClickChoose", self );
	self.m_pBtnUse:AddActionListener( "OnClickChoose", self );
end

function CSkillDevelopPassiveItem:OnDestroy()
	CSkillDevelopItem.OnDestroy( self );
end

function CSkillDevelopPassiveItem:OnClickChoose()
	--print( "!!!!!!!!!!!!!!CSkillDevelopPassiveItem:OnClickChoose SkillID", self.m_tblSkill.nSkillID );
	local NetMsg = CAlterPassiveSkill:new();
	NetMsg.nSkillID = self.m_tblSkill.nSkillID;
	g_App:SendShellMsg( NetMsg );
end

function CSkillDevelopPassiveItem:RefreshPassive()
	local bMaxLevel = self.m_tblSkill.nSkillLevel == g_tblTabFile.skill[self.m_tblSkill.nSkillID].nMaxLevel;
	local bInUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and self:WhetherPassiveInUse( self.m_tblSkill.nSkillID );
	local bShowUse = self.m_tblSkill.nSkillState ~= eSDST_Lock and self.m_tblSkill.nSkillState ~= eSDST_CanDeblock and not bInUse;
	self.m_pWndInUse:ShowWnd( bInUse );
	self.m_pBtnUse:ShowWnd( bShowUse );
end

function CSkillDevelopPassiveItem:SkillIsInUse()
	return self:WhetherPassiveInUse( self.m_tblSkill.nSkillID );
end


----------------------------CLockTipWnd----------------------------
function CLockTipWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CLockTipWnd:OnCreated()
	self.m_pWndTip = self:GetDlgChild( "tishi" );
	self.m_pBtnConfirm = self:GetDlgChild( "b_ok" );

	self.m_pBtnConfirm:AddActionListener( "OnClickOK", self );
end

function CLockTipWnd:OnClickOK()
	self:ShowWnd( false );
end


--endregion
