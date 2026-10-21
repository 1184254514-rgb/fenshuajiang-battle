--region CWndTreasureBox.lua
--Date	2017.12.12
--宝箱界面


local eTreasureBoxType = { eLimitTreasureBox = 0, eTeamTreasureBox = 1 };
local eFx_Move_Times = 45;
function CWndTreasureBox:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndTreasureBox:OnCreated()
	self.m_BtnLimitTreasureBox		= self:GetDlgChild( "liebiao.btn_1" );
	self.m_BtnTeamTreasureBox		= self:GetDlgChild( "liebiao.btn_2" );
	self.m_tipsLimitTreasureBox		= self:GetDlgChild( "liebiao.btn_1.hongdian" );
	self.m_tipsTeamTreasureBox		= self:GetDlgChild( "liebiao.btn_2.hongdian" );
	self.m_TextDiamondCount			= self:GetDlgChild( "zuanshi.jinbishuliang" );
	self.m_BtnAddDiamond			= self:GetDlgChild( "zuanshi.btn_add" );
	self.m_TextPresentDiamondCount	= self:GetDlgChild( "zengsongzuanshi.jinbishuliang" );
	self.m_BtnAddPresentDiamond		= self:GetDlgChild( "zengsongzuanshi.btn_add" );

	self.m_BtnClose					= self:GetDlgChild( "B_close" );
	self.m_ListTreasureBox			= self:GetDlgChild( "baoxiang.list" );
	self.m_WndLevel					= self:GetDlgChild( "zhanghaodengji" );
	self.m_WndAccountLevelLock		= self:GetDlgChild( "zhanghaodengji.lock" );
	self.m_WndAccountLevelLV		= self:GetDlgChild( "zhanghaodengji.dengji" );
	self.m_WndAccountLevelPro		= self:GetDlgChild( "zhanghaodengji.jindutiao" );
	self.m_tblWndFxOrigin			= { self:GetDlgChild( "zhanghaodengji.tx1qidian" ), 
										self:GetDlgChild( "zhanghaodengji.tx2qidian" ), 
										self:GetDlgChild( "zhanghaodengji.tx3qidian") };
	self.m_tblPos					= {
										{ x = self.m_tblWndFxOrigin[1]:GetLocalX(); y = self.m_tblWndFxOrigin[1]:GetLocalY(); },
										{ x = self.m_tblWndFxOrigin[2]:GetLocalX(); y = self.m_tblWndFxOrigin[2]:GetLocalY(); },
										{ x = self.m_tblWndFxOrigin[3]:GetLocalX(); y = self.m_tblWndFxOrigin[3]:GetLocalY(); } };
	self.m_WndFxEnd					= self:GetDlgChild( "zhanghaodengji.txzhongidan" );
	self.m_nFxEndX					= self.m_WndFxEnd:GetLocalX();
	self.m_nFxEndY					= self.m_WndFxEnd:GetLocalY();
	self.m_WndFxExperience			= self:GetDlgChild( "zhanghaodengji.tx2" );
	self.m_wndFxLock				= self:GetDlgChild( "zhanghaodengji.tx3" );
	self.m_WndFxExperience			= CFontEffectWnd:new();
	self:AssignDlgChildToWnd( self.m_WndFxExperience, "zhanghaodengji.tx2", false );
	self.m_FxMoveEndY				= self.m_WndLevel:GetLocalY() - self.m_WndLevel:GetWndHeight();
	self.m_FxMoveEndX				= self.m_WndLevel:GetLocalX() - self.m_WndLevel:GetWndWidth();
	self.m_WndOprationTips			= CWndTreasureBoxOpretionTips:new( "gui/cfg/fsj_pifu_baoxiangtips.gui", self, 1 );
	self.m_WndAccountLevel			= CWndAccountLevel:new( "gui/cfg/fsj_baoxiang_shuoming.gui", self, 1 );

	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new ( "OnTimeTick", self );
	self.m_FxMoveTick = CTick:new( "OnFxMove", self );

	self.m_nSelectType = eTreasureBoxType.eLimitTreasureBox;
	self.m_bAuto = false;
	self.m_tipsLimitTreasureBox:ShowWnd( false );
	self.m_tipsTeamTreasureBox:ShowWnd( false );
	self.m_ListTreasureBox:ShowAndSetFocus();

	self.m_BtnClose:AddActionListener( "OnClose", self );
	self.m_BtnLimitTreasureBox:AddActionListener( "OnClickLimitTreasureBox", self );
	self.m_BtnTeamTreasureBox:AddActionListener( "OnClickTeamTreasureBox", self );
	self.m_BtnAddDiamond:AddActionListener( "OnClickAddDiamond", self );
	self.m_WndLevel:AddActionListener( "OnClickLevel", self );
	g_App.m_EventDispatcher:AddEventListener( "TreasureBoxOpened", "OnTreasureBoxOpened", self );
	g_App.m_EventDispatcher:AddEventListener( "DuringAccelerateTreasureBox", "OnDuringAccelerateTreasureBox", self );
	g_App:GetMainPlayerData():AddEventListener( "m_TreasureBoxData", "RefreshTreasureBoxList", self );
end

function CWndTreasureBox:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "TreasureBoxOpened", "OnTreasureBoxOpened", self );
	g_App.m_EventDispatcher:RemoveEventListener( "DuringAccelerateTreasureBox", "OnDuringAccelerateTreasureBox", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_TreasureBoxData", "RefreshTreasureBoxList", self );
	self.m_timeTick:Stop();
	self.m_FxMoveTick:Stop();
	CGWnd.OnDestroy( self );
end

function CWndTreasureBox:OnClickAddDiamond()
	g_App:GetGameStart():OpenDiamondShop();
end

function CWndTreasureBox:OnFxMove()
	local nCurX = self.m_tblWndFxOrigin[self.m_nPosIndex]:GetLocalX() + self.m_nMoveSpeedX;
	local nCurY = self.m_tblWndFxOrigin[self.m_nPosIndex]:GetLocalY() + self.m_nMoveSpeedY;
	self.m_tblWndFxOrigin[self.m_nPosIndex]:SetLocalX( nCurX );
	self.m_tblWndFxOrigin[self.m_nPosIndex]:SetLocalY( nCurY );
	self.m_nFxMoveTime = self.m_nFxMoveTime + 1;
	if self.m_nFxMoveTime > eFx_Move_Times then
		self.m_WndLevel:AddEffect( "fx/cfg/baoxiang_jyhq.eft", "fx/loop", nil, 0 );
		self.m_FxMoveTick:Stop();
		self.m_tblWndFxOrigin[self.m_nPosIndex]:RemoveAllEffects();
		if g_App:IsUnlockAccountLevel() then
			self.m_WndFxExperience:SetEffectText( "fx/cfg/quandi.eft", "+"..self.m_nExperienceAdd .. g_App:GetString( "jingyan" ), 0xfefbea, 2000 );
		else
			self.m_wndFxLock:AddEffect( "fx/cfg/baoxiang_jyhq_wcg.eft", "fx/loop", nil, 0);
		end
	end
end

function CWndTreasureBox:PlayExperienceAddEffect( nExperienceAdd, nPosIndex )
	self.m_WndAccountLevel:RemoveAllEffects();
	self.m_nExperienceAdd = nExperienceAdd;
	self.m_nPosIndex = nPosIndex;
	self.m_tblWndFxOrigin[nPosIndex]:SetLocalX( self.m_tblPos[nPosIndex].x );
	self.m_tblWndFxOrigin[nPosIndex]:SetLocalY( self.m_tblPos[nPosIndex].y );
	self.m_nMoveSpeedX = ( self.m_nFxEndX - self.m_tblPos[nPosIndex].x ) / eFx_Move_Times;
	self.m_nMoveSpeedY = ( self.m_nFxEndY - self.m_tblPos[nPosIndex].y ) / eFx_Move_Times;
	self.m_nFxMoveTime = 0;
	self.m_tblWndFxOrigin[nPosIndex]:RemoveAllEffects();
	self.m_tblWndFxOrigin[nPosIndex]:AddEffect( "fx/cfg/baoxiang_jingyan.eft", "fx/fly", nil, 0 );
	self.m_tblWndFxOrigin[nPosIndex]:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnBombEffectEnd", self );
end

function CWndTreasureBox:OnBombEffectEnd()
	self.m_tblWndFxOrigin[self.m_nPosIndex]:AddEffect( "fx/cfg/baoxiang_jyhq_guiji.eft", "fx/fly", nil, -1 );
	self.m_FxMoveTick:Start( 33 );
end

function CWndTreasureBox:OnClickLevel()
	self.m_WndAccountLevel:UpdateWnd();
end

function CWndTreasureBox:OnTimeTick()
	if not g_App or not g_App:GetWorldConn() then
		return;
	end
	local wifi = g_App:GetWorldConn():GetPingDelay();
	local nIconShowed = wifi < ePing_low and 3 or ( wifi > ePing_high and 1 or 2 );
	for k, v in pairs( self.m_wifiIcon ) do
		self.m_wifiIcon[k]:ShowWnd( k == nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild( "wangsu" ):SetWndText( wifi );
	end
	local nDiamondCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Diamond );
	self.m_TextDiamondCount:SetWndText( nDiamondCount );
	local nPresentDiamondCount = g_App:GetPropCount( eGRT_Resource, eResourceType_PresentDiamond );
	self.m_TextPresentDiamondCount:SetWndText( nPresentDiamondCount );	
end

function CWndTreasureBox:SetTipsTxt()
	local tblLimitTreasureBox = self:ClassifyTreasureBox( eTreasureBoxType.eLimitTreasureBox );
	local tblTeamTreasureBox = self:ClassifyTreasureBox( eTreasureBoxType.eTeamTreasureBox );
	local bShowTipsLimit = false;
	local bShowTipsTeam = false;
	if table.count( tblLimitTreasureBox ) == 0 then
		self.m_tipsLimitTreasureBox:GetDlgChild( "tips" ):SetWndText( g_App:GetString( "kongkongruye" ) );
		bShowTipsLimit = true;
	end
	if table.count( tblTeamTreasureBox ) == 0 then
		self.m_tipsTeamTreasureBox:GetDlgChild( "tips" ):SetWndText( g_App:GetString( "kongkongruye" ) );
		bShowTipsTeam = true;
	end

	for k, v in pairs( tblLimitTreasureBox ) do 
		if v.nStatus == eTreasureBoxStatus_CouldOpen then
			self.m_tipsLimitTreasureBox:GetDlgChild( "tips" ):SetWndText( g_App:GetString( "kuailaikaiqi" ) );
			bShowTipsLimit = true;
			break;
		end
	end

	for k, v in pairs( tblTeamTreasureBox ) do 
		if v.nStatus == eTreasureBoxStatus_CouldOpen then
			self.m_tipsTeamTreasureBox:GetDlgChild( "tips" ):SetWndText( g_App:GetString( "kuailaikaiqi" ) );
			bShowTipsTeam = true;
			break;
		end
	end

	if table.count( tblLimitTreasureBox ) == 3 then
		self.m_tipsLimitTreasureBox:GetDlgChild( "tips" ):SetWndText( g_App:GetString( "baoxiangyiman" ) );
		bShowTipsLimit = true;
	end
	if table.count( tblTeamTreasureBox ) == 3 then
		self.m_tipsTeamTreasureBox:GetDlgChild( "tips" ):SetWndText( g_App:GetString( "baoxiangyiman" ) );
		bShowTipsTeam = true;
	end

	self.m_tipsLimitTreasureBox:ShowWnd( bShowTipsLimit );
	self.m_tipsTeamTreasureBox:ShowWnd( bShowTipsTeam );
end

function CWndTreasureBox:OnTreasureBoxOpened( Event )
	g_App:GetGameStart():NotifyOpenTreasureBox( Event.m_nTreasureBoxID, Event.m_Data, Event.m_nExpAdd, Event.m_nPosIndex );
end

function CWndTreasureBox:RefreshTreasureBoxList()
	self:InitTreasureBoxList();
end

function CWndTreasureBox:OnDuringAccelerateTreasureBox( Event )
	local szTips = g_App:GetString( "jiesuobaoxiangtips0" );
	local nTreasureBoxID = Event.m_Data.m_nTreasureBoxID;
	local nGetTime = Event.m_Data.m_nTreasureBoxGetTime;
	local nPosIndex = Event.m_Data.m_nPosIndex;
	self.m_WndOprationTips:ShowDetail( szTips, nTreasureBoxID, nGetTime, nUnlockTime, nPosIndex );
end

function CWndTreasureBox:OnClickLimitTreasureBox()
	if self.m_nSelectType == eTreasureBoxType.eLimitTreasureBox then
		return;
	end
	self.m_nSelectType = eTreasureBoxType.eLimitTreasureBox;
	self:InitTreasureBoxList();
end

function CWndTreasureBox:OnClickTeamTreasureBox()
	if self.m_nSelectType == eTreasureBoxType.eTeamTreasureBox then
		return;
	end
	self.m_nSelectType = eTreasureBoxType.eTeamTreasureBox;
	self:InitTreasureBoxList();
end

function CWndTreasureBox:InitTreasureBoxList()
	self.m_tblTreasureBox = self:ClassifyTreasureBox( self.m_nSelectType );
	self.m_ListTreasureBox:DeleteAllColumn();
	self.m_ListTreasureBox:DeleteAllItem();
	for i =1, 3 do
		self.m_ListTreasureBox:InsertColumn( i - 1, 425 );
	end

	self.m_ListTreasureBox:InsertRowItemsFromRes( -1, "gui/cfg/fsj_pifu_baoxiang.gui", CWndTreasureBoxItem );
	self.m_ListTreasureBox:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnTreasureBoxItemLoaded", self );
	self:SetTipsTxt();
	self:SetAccountLevelState();
end

function CWndTreasureBox:SetAccountLevelState()
	local bUnlockAccountLevel = g_App:IsUnlockAccountLevel();
	if not bUnlockAccountLevel then
		self.m_WndAccountLevelPro:SetPos( 0 );
		self.m_WndAccountLevelLock:ShowWnd( true );
	else
		self.m_WndAccountLevelLock:ShowWnd( false );
		self.m_WndAccountLevelPro		= self:GetDlgChild( "zhanghaodengji.jindutiao" );
		self.m_WndAccountLevelLV:SetWndText( g_App:GetAccountLevel() );
		local nExpMin =  g_tblTabFile.playerlevel[g_App:GetAccountLevel()].nExpMin;
		local nExpMax = g_tblTabFile.playerlevel[g_App:GetAccountLevel()].nExpMax;
		if g_App:GetAccountLevel() == 5 then
			self.m_WndAccountLevelPro:SetRange( 1 );
			self.m_WndAccountLevelPro:SetPos( 1 );
		else
			if nExpMax < 0 then nExpMax = 0xffffff end;
			self.m_WndAccountLevelPro:SetRange( nExpMax - nExpMin );
			self.m_WndAccountLevelPro:SetPos( g_App:GetMainPlayerData().m_CharBaseData:GetExp() - nExpMin );
		end
	end
end

function CWndTreasureBox:ClassifyTreasureBox( nType )
	local PlayerData = g_App:GetMainPlayerData().m_TreasureBoxData;
	local tbl = {};
	for i = 1, PlayerData:GetDataCount() do
		local data = {};
		data.nTreasureBoxID = PlayerData:GetData( i - 1 ):GetTreasureBoxID();
		data.nGetTime = PlayerData:GetData( i - 1 ):GetGetTime();
		data.nUnlockTime = PlayerData:GetData( i - 1 ):GetUnlockTime();
		data.nType = PlayerData:GetData( i - 1 ):GetType();
		data.nStatus = PlayerData:GetData( i - 1 ):GetStatus();
		if data.nType == nType and data.nTreasureBoxID ~= 0 
			and data.nStatus ~= eTreasureBoxStatus_Opened and data.nStatus ~= eTreasureBoxStatus_Discard  then
			table.insert( tbl, data );
		end
	end
	return tbl;
end

function CWndTreasureBox:OnTreasureBoxItemLoaded()
	self.m_ListTreasureBox:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnTreasureBoxItemLoaded", self );
	local nItem = self.m_ListTreasureBox:GetItemCount();
	local nCol  = self.m_ListTreasureBox:GetColumnCount();
	self.m_tblTreasureBox = self:ClassifyTreasureBox( self.m_nSelectType );
	for i = 0, nItem - 1 do
		for j = 0, nCol - 1 do
			local listItem = self.m_ListTreasureBox:GetSubItem( i, j )
			local nindex = i * 3 + j + 1;
			if not listItem:IsCreated() then return end
			listItem:SetTreasureBoxData( self.m_tblTreasureBox[nindex], nindex );
		end 
	end
end

function CWndTreasureBox:OnWndShow( bShow )
	if bShow then
		self.m_nSelectType = g_App:GetGameStart().m_nTreasureBoxRedDotType%2 == 1 and eTreasureBoxType.eLimitTreasureBox or eTreasureBoxType.eTeamTreasureBox;
		if g_App.m_nNewTreasureBoxType then
			self.m_nSelectType = g_App.m_nNewTreasureBoxType;	
		end
		self:InitTreasureBoxList();
		self.m_BtnLimitTreasureBox:SetCheck( self.m_nSelectType == eTreasureBoxType.eLimitTreasureBox );
		self.m_BtnTeamTreasureBox:SetCheck( self.m_nSelectType == eTreasureBoxType.eTeamTreasureBox );
		self.m_timeTick:Start(100);
	else
		self.m_timeTick:Stop();	
	end
end

function CWndTreasureBox:OnClose()
	self:ShowWnd( false );
	g_App.m_nNewTreasureBoxType = nil;
end



--endregion
