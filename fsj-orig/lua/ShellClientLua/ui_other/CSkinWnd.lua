--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local eFaceType = { Born = 1, Kill = 2, Dead = 3 };
local eSelectType = { eCommonSkin = 1, eFusionSkin = 2, eRhythm = 3, eFace = 4; };

function CSkinWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CSkinWnd:OnCreated()
	self.m_pBtnClose		= self:GetDlgChild( "B_close" );
	self.m_pWndMoney		= self:GetDlgChild( "B_jinbi.jinbishuliang" );
	self.m_pBtnAddMoney		= self:GetDlgChild( "B_jinbi.btn_add" );
	self.m_pWndRainbowGold	= self:GetDlgChild( "jinbi2.jinbishuliang" );
	self.m_BtnShare = self:GetDlgChild( "jinbi2.btn_add" );
	self.m_BtnShare:AddActionListener( "OpenShareWnd", g_App:GetGameStart() );
	self.m_pWndList			= self:GetDlgChild( "list" );	
	self.m_pbtnCommonskin	= self:GetDlgChild( "liebiao.btn_1" );
	self.m_pBtnRhythm		= self:GetDlgChild( "liebiao.btn_3" );
	self.m_pBtnFace			= self:GetDlgChild( "liebiao.btn_4" );
	self.m_pBtnFusionSkin	= self:GetDlgChild( "liebiao.btn_6" );
	self.m_wndFace			= self:GetDlgChild( "biaoqing" );
	self.m_ListFace			= self:GetDlgChild( "biaoqing.list" );
	self.m_pbtnFaceBorn		= self:GetDlgChild( "biaoqing.btn.b_1" );
	self.m_pbtnFaceKill		= self:GetDlgChild( "biaoqing.btn.b_2" );
	self.m_pbtnFaceDead		= self:GetDlgChild( "biaoqing.btn.b_3" );
	self.m_wndFace:ShowWnd( false );

	self.m_pBtnAddMoney:AddActionListener( "OnClickAddMoney", self );
	self.m_pbtnFaceBorn:AddActionListener( "OnClickBorn", self );
	self.m_pbtnFaceKill:AddActionListener( "OnClickKill", self );
	self.m_pbtnFaceDead:AddActionListener( "OnClickDead", self );
	self.m_pbtnCommonskin:AddActionListener("OnCommonSkin",self );
	self.m_pBtnRhythm:AddActionListener( "OnBtnRhythm", self );
	self.m_pBtnFace:AddActionListener( "OnBtnFace", self );
	self.m_pBtnFusionSkin:AddActionListener( "OnBtnFusionSkin", self );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
	g_App:GetMainPlayerData():AddEventListener( "m_HaveEquip", "OnUpdate", self );
	g_App:GetMainPlayerData():AddEventListener( "m_FragmentData", "ReCalcCommonSkin", self );
	g_App:GetMainPlayerData():AddEventListener( "m_RhythmNoticeBar", "OnUpdate", self );
	g_App:GetMainPlayerData():AddEventListener( "m_BattleFaceData", "OnUpdate", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.CurEquipID", "OnUpdate", self );
	g_App:GetMainPlayerData():AddEventListener( "m_CharBaseData.CurRhythmNoticeBarID", "OnUpdate", self );
		
	self.m_nSelectType = eSelectType.eCommonSkin;
	self.m_pbtnCommonskin:SetCheck( true );

	self.m_nFaceType = eFaceType.Born;
	self.m_pbtnFaceBorn:SetCheck( true );
	self.m_ListFace:DeleteAllColumn();
	self.m_ListFace:SetInertiaType( eInertiaType_VScroll );

	self.m_pWndList:DeleteAllColumn();
	self.m_pWndList:SetInertiaType( eInertiaType_VScroll );
	
	local nSnakeCount = g_tblTabFile.equip.nRowCount - 1;
	self.m_nColums=4;
	self.m_nRows = math.ceil(nSnakeCount/self.m_nColums);
	for i = 1, self.m_nColums do
		self.m_pWndList:InsertColumn( i - 1, 310 );
	end

	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new ( "OnTimeTick", self );
	self.m_WndFusionSuccess = CWndFusionSuccess:new( "gui/cfg/fsj_pifu_hecheng2.gui", self, 1 );
	g_App.m_EventDispatcher:AddEventListener( "FusionSuccess", "OnFusionSuccess", self );
end

function CSkinWnd:OnDestroy()
	self.m_timeTick:Stop();
	g_App.m_EventDispatcher:RemoveEventListener( "FusionSuccess", "OnFusionSuccess", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_HaveEquip", "OnUpdate", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_FragmentData", "ReCalcCommonSkin", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_RhythmNoticeBar", "OnUpdate", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_BattleFaceData", "OnUpdate", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.CurEquipID", "OnUpdate", self );
	g_App:GetMainPlayerData():RemoveEventListener( "m_CharBaseData.CurRhythmNoticeBarID", "OnUpdate", self );
	CGWnd.OnDestroy( self );
end

function CSkinWnd:ReCalcCommonSkin()
	if ( not self.m_tblCommonSkin ) or ( not self.m_tblNotShowSkin ) then
		return;
	end

	local bReInsert = false;
	for i = 1, #self.m_tblNotShowSkin do
		if g_App:GetFragmentCount( self.m_tblNotShowSkin[i] ) ~= 0 then
			bReInsert = true;
			break;
		end
	end
	
	if bReInsert then
		self:InitSkinList();
	else
		self:OnUpdate();
	end

end

function CSkinWnd:OnFusionSuccess( Event )
	g_App.m_EventDispatcher:RemoveEventListener( "FusionSuccess", "OnFusionSuccess", self );
	self.m_WndFusionSuccess:SetData( Event.m_nFusionID );
end

function CSkinWnd:OnCommonSkin()
	if  self.m_nSelectType == eSelectType.eCommonSkin then 
		return true ;
	end 
	self.m_nSelectType = eSelectType.eCommonSkin;
	self:InitSkinList();
end

function CSkinWnd:OnBtnFusionSkin()
	if self.m_nSelectType == eSelectType.eFusionSkin then
		return
	end
	self.m_nSelectType = eSelectType.eFusionSkin;
	self:InitSkinList();
end

function CSkinWnd:OnBtnRhythm()
	if  self.m_nSelectType == eSelectType.eRhythm then 
		return true;
	end 
	self.m_nSelectType = eSelectType.eRhythm;
	self:InitSkinList();
end

function CSkinWnd:OnBtnFace()
	if self.m_nSelectType == eSelectType.eFace then
		return true;
	end
	self.m_nSelectType = eSelectType.eFace;
	self.m_pWndList:ShowWnd( false );
	self.m_wndFace:ShowWnd( true );
	self.m_pWndList:DeleteAllColumn();
	self.m_pWndList:DeleteAllItem();
	self:InitFaceList();
end

function CSkinWnd:OnClickBorn()
	if self.m_nFaceType == eFaceType.Born then
		return;
	end
	self.m_nFaceType = eFaceType.Born;
	self:InitFaceList();
end

function CSkinWnd:OnClickKill()
	if self.m_nFaceType == eFaceType.Kill then
		return;
	end
	self.m_nFaceType = eFaceType.Kill;
	self:InitFaceList();
end

function CSkinWnd:OnClickDead()
	if self.m_nFaceType == eFaceType.Dead then
		return;
	end
	self.m_nFaceType = eFaceType.Dead;
	self:InitFaceList();
end

function CSkinWnd:OnWndShow( bShow )
	if bShow then
		self.m_timeTick:Start(100);
		if self.m_nSelectType == eSelectType.eFace then
			self:InitFaceList();
			return;
		end
		self:InitSkinList();
	else
		self.m_timeTick:Stop();
	end
end

function CSkinWnd:InitFaceList()
	self.m_ListFace:DeleteAllColumn();
	self.m_ListFace:DeleteAllItem();
	for i =1, 4 do
		self.m_ListFace:InsertColumn( i - 1, 310 );
	end

	local nFaceCount = g_tblTabFile.battleface.nRowCount - 1;
	self.m_tblFaceBorn = {};
	self.m_tblFaceKill = {};
	self.m_tblFaceDead = {};
	for i = 1, nFaceCount do
		local nKind = g_tblTabFile.battleface[i].nKind;
		if nKind == eFaceType.Born then
			table.insert( self.m_tblFaceBorn, i );
		elseif nKind == eFaceType.Kill then
			table.insert( self.m_tblFaceKill, i );
		elseif nKind == eFaceType.Dead then
			table.insert( self.m_tblFaceDead, i );
		end	
	end

	local nRows = 0;
	if self.m_nFaceType == eFaceType.Born then
		nRows = math.ceil( table.count( self.m_tblFaceBorn ) / 4 );
	elseif self.m_nFaceType == eFaceType.Kill then
		nRows = math.ceil( table.count( self.m_tblFaceKill ) / 4 );
	elseif self.m_nFaceType == eFaceType.Dead then
		nRows = math.ceil( table.count( self.m_tblFaceDead ) / 4 );
	end	
	for j=1, nRows do
		self.m_ListFace:InsertRowItemsFromRes( -1, "gui/cfg/fsj_pifu_item4.gui", CWndBattleFaceItem );
	end	
	self.m_ListFace:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnFaceItemLoaded", self );
	self.m_ListFace:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnFaceItemSelect", self );	
end

function CSkinWnd:InitSkinList()
	self.m_wndFace:ShowWnd( false );
	self.m_pWndList:ShowWnd( true );
	self.m_tblCommonSkin = {};
	self.m_tblNotShowSkin = {};
	self.m_pWndList:DeleteAllColumn();
	self.m_pWndList:DeleteAllItem();
	for i = 1, self.m_nColums do
		self.m_pWndList:InsertColumn( i - 1, 310 );
	end
	local nSnakeCount = g_tblTabFile.equip.nRowCount - 1;
	for i = 1, nSnakeCount do 
		local nEquipID = g_tblTabFile.equip:GetRow(i).nID;
		local nSort = g_tblTabFile.equip[nEquipID].nSort;
		local nFragmentID = g_tblTabFile.equip[nEquipID].nFragmentID;
		local nAcquireType = g_tblTabFile.equip[nEquipID].nAcquire;
		local bInsert = false;
		if nAcquireType == eAcquireType_Operation then
			if g_App:GetFragmentCount( nFragmentID ) ~= 0 or self:IsHaveSkin( nEquipID ) then
				bInsert = true;
			else
				table.insert( self.m_tblNotShowSkin, nEquipID );
			end
		else
			bInsert = true;
		end
		if bInsert then
			local tbl = {};
			tbl.nEquipID = nEquipID;
			tbl.nSort = nSort;
			table.insert( self.m_tblCommonSkin, tbl )
		end
	end
	
	local nRows = 0;
	if self.m_nSelectType == eSelectType.eCommonSkin then
		nRows = math.ceil( table.count( self.m_tblCommonSkin ) / self.m_nColums );
		table.sort( self.m_tblCommonSkin, function( a, b ) return a.nSort < b.nSort end );
	elseif self.m_nSelectType == eSelectType.eRhythm then
		local nRhythmNoticeBarCount = g_tblTabFile.jiezoutishiqi.nRowCount - 1;
		nRows = math.ceil( nRhythmNoticeBarCount/ self.m_nColums );
	elseif self.m_nSelectType == eSelectType.eFusionSkin then
		local nCount = 0;
		for i = 1, g_tblTabFile.fusion.nRowCount do
			if CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nSort" ) > nCount then
				nCount = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nSort" );
			end	
		end
		self.m_nFusionskinCount = nCount;	
		nRows = math.ceil( self.m_nFusionskinCount/self.m_nColums);
	end
	for j=1, nRows do
		if self.m_nSelectType == eSelectType.eCommonSkin then
			self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_pifu_item3.gui", CSkinItemWnd );
		elseif self.m_nSelectType == eSelectType.eRhythm then
			self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_pifu_item1.gui", CRhythmNoticeBarItem );
		elseif self.m_nSelectType == eSelectType.eFusionSkin then
			self.m_pWndList:InsertRowItemsFromRes( -1, "gui/cfg/fsj_pifu_yangcheng.gui", CWndFusionSkinItem );
		end
	end	
	self.m_pWndList:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnItemLoaded", self );
	self.m_pWndList:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnItemSelect", self );
end

function CSkinWnd:IsHaveSkin( nSkinID )
	local PlayerData = g_App:GetMainPlayerData().m_HaveEquip;
	for i = 1, PlayerData:GetDataCount() do
		if PlayerData:GetData( i - 1 ) == nSkinID then
			return true;
		end
	end
	return false;	
end

function CSkinWnd:OnFaceItemLoaded()
	self.m_ListFace:RemoveAllEventListener( GM_WM_ITEM_ALLLOADED, "OnItemLoaded", self );
	local nItem = self.m_ListFace:GetItemCount();
	local nCol  = self.m_ListFace:GetColumnCount();
	for i = 0, nItem - 1 do
		for j = 0, nCol - 1 do
			local listItem = self.m_ListFace:GetSubItem( i, j );
			local nindex = i * 4 + j + 1;
			local nFaceCount = 0;
			if self.m_nFaceType == eFaceType.Born then
				listItem:SetFaceData( self.m_tblFaceBorn[nindex], true );
				nFaceCount = table.count( self.m_tblFaceBorn );
			elseif self.m_nFaceType == eFaceType.Kill then
				listItem:SetFaceData( self.m_tblFaceKill[nindex], true );
				nFaceCount = table.count( self.m_tblFaceKill );
			elseif self.m_nFaceType == eFaceType.Dead then
				listItem:SetFaceData( self.m_tblFaceDead[nindex], true );
				nFaceCount = table.count( self.m_tblFaceDead );
			end
			if nindex > nFaceCount then
				self.m_ListFace:SetSubItemVisible( false, i, j );
			end
		end 
	end
end

function CSkinWnd:OnTimeTick()
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
end

function CSkinWnd:OnItemLoaded()
	local nSnakeCount = g_tblTabFile.equip.nRowCount;
	local nItem = self.m_pWndList:GetItemCount();
	local nCol  = self.m_pWndList:GetColumnCount();
	for i=0,nItem-1 do
		for j=0 ,nCol-1 do
			local listItem = self.m_pWndList:GetSubItem( i,j );
			local nindex = i * nCol + j + 1;
			local nSkinCount = 0;
			if self.m_nSelectType == eSelectType.eCommonSkin then
				nSkinCount = table.count( self.m_tblCommonSkin );
				if nindex <= nSkinCount then
					listItem:SetSkinID( self.m_tblCommonSkin[nindex].nEquipID );
				end
			elseif self.m_nSelectType == eSelectType.eRhythm then
				listItem:SetDataByIndex( nindex, true );
				nSkinCount = g_tblTabFile.jiezoutishiqi.nRowCount - 1;
			elseif self.m_nSelectType == eSelectType.eFusionSkin then
				if nindex <= self.m_nFusionskinCount then
					listItem:SetDataByIndex( nindex );
				end
				nSkinCount = self.m_nFusionskinCount;
			end
			if nindex > nSkinCount then
				self.m_pWndList:SetSubItemVisible( false, i, j );
			end
		end 
	end
end

function CSkinWnd:OnItemSelect( Event )
	if self.m_nSelectType ~= eSelectType.eCommonSkin then
		return;
	end

	local nItem = Event.m_wParam;
	local nCol  = Event.m_lParam;
	local ptCursorPos = self:GetCursorPos();
	local nColumnCount = self.m_pWndList:GetColumnCount();
	local nRowCount    = self.m_pWndList:GetItemCount();
	local pWndStand = self.m_pWndList:GetSubItem( nItem, nCol );
	pWndStand.m_pWndName:EnableWnd( true );
	local wndButtonBuy = pWndStand.m_pWndLinqu;
	if wndButtonBuy:IsInWndArea( ptCursorPos:x(), ptCursorPos:y() ) then
		return ;
	end	
	for j=0, nRowCount-1 do
		for i = 0, nColumnCount - 1 do
			if i ~= nCol or j ~= nItem then
				local pWnd    = self.m_pWndList:GetSubItem( j, i );
				pWnd.m_pWndName:EnableWnd( false );
				local pRenderObject = pWnd:GetRenderObject();
				if pRenderObject == nil then
					break ;	
				end
				local pair = SFramePair:new();
				pair:m_uStart(2);
				pair:m_uEnd(2);
				pRenderObject:SetNodeAni( "stand", nil, pair, eAPT_Once, 0, 0, 1.0, nil );
			end
		end
	end
	pWndStand:OnSelect();
end

function CSkinWnd:OnUpdate()
	local nColumnCount = self.m_pWndList:GetColumnCount();
	local nItemCount   = self.m_pWndList:GetItemCount();
	for i = 0, nItemCount - 1 do 
		for j=0, nColumnCount-1 do
			local pWnd = self.m_pWndList:GetSubItem( i, j );
			pWnd:OnUpdate();
		end
	end
	if self.m_nSelectType == eSelectType.eFace then
		for i = 0, self.m_ListFace:GetItemCount() - 1 do 
			for j=0, self.m_ListFace:GetColumnCount() - 1 do
				local pWnd = self.m_ListFace:GetSubItem( i, j );
				pWnd:OnUpdate();
			end
		end	
	end
end

function CSkinWnd:OnClose()
	self:ShowWnd( false );
	self.m_timeTick:Stop();
end

function CSkinWnd:OnClickAddMoney()
	g_App:HideMsg(g_App:GetString("gongnengtips"));
end

----------------------CSkinItemWnd Start---------------------

function CSkinItemWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CSkinItemWnd:OnCreated()
	self.m_pWndName			= self:GetDlgChild( "W_pifubiaoti" );
	self.m_pWndShow			= self:GetDlgChild( "W_pifu" );	
	self.m_pWndPrice		= self:GetDlgChild( "B_jinbi" );
	self.m_pWndInsidePrice  = self:GetDlgChild( "B_jinbi.W_jiage" );
	self.m_ImgGold			= self:GetDlgChild( "B_jinbi.jinbi" );
	self.m_ImgRainbow		= self:GetDlgChild( "B_jinbi.fenxiangbi" );	
	self.m_pB_jinbi			= self:GetDlgChild( "B_lingqu" );
	self.m_pWndLinqu		= self:GetDlgChild( "B_lingqu.bg_lingqu" );
	self.m_pWndKeLingQu     = self:GetDlgChild( "B_lingqu.bg_kelingqu" );
	self.m_pWndOwned		= self:GetDlgChild( "B_shiyong" );
	self.m_pWndUsing		= self:GetDlgChild( "W_gouxuan" );
	self.m_pB_duihuan		= self:GetDlgChild( "B_duihuan" );
	self.m_pW_duihuan		= self:GetDlgChild( "B_duihuan.W_duihuan" );
	self.m_BtnSeasonPrize	= self:GetDlgChild( "B_saijijiangli" );
	self.m_WndFusion		= self:GetDlgChild( "B_suipian" );
	self.m_BtnFusion		= self:GetDlgChild( "B_suipian.hecheng" );
	self.m_BtnFusionPro		= self:GetDlgChild( "B_suipian.jindutiao" );
	self.m_TextPropText		= self:GetDlgChild( "B_suipian.jindutiao.shuzi" );
	self.m_pWndDesc			= self:GetDlgChild( "wenzi" );
	self.m_pWndSkill		= self:GetDlgChild( "jineng" );
	self.m_tblSkillWnd = {};
	for i = 1, 5 do
		local SubSkillWnd = CRichIconWnd:new( self.m_pWndSkill, i );
		if SubSkillWnd then
			table.insert( self.m_tblSkillWnd, SubSkillWnd );
		end
	end
	
	self.m_pWndDuihuan      = CSkinLingQu:new( "gui/cfg/fsj_pifu_duihuan.gui", self:GetParent():GetParent(), 1);
	self.m_pWndBuySkin      = CWndClickBuy:new( "gui/cfg/fsj_pifu_goumai2.gui", self:GetParent():GetParent(), 1);

	self.m_ImgGold:ShowWnd( false );
	self.m_ImgRainbow:ShowWnd( false );
	self.m_pWndPrice:ShowWnd( false );
	self.m_pB_jinbi:ShowWnd( false );
	self.m_pWndOwned:ShowWnd( false );
	self.m_pWndUsing:ShowWnd( false );
	self.m_pB_duihuan:ShowWnd( false );
	self.m_BtnSeasonPrize:ShowWnd( false );
	self.m_WndFusion:ShowWnd( false );
	self.m_pWndDesc:ShowWnd( false );
	self.m_WndFusion:AddActionListener( "OnClickFusion", self );
	self.m_BtnSeasonPrize:AddActionListener( "OnClickSeasonPrize", self );
	self.m_pB_duihuan:AddActionListener( "CLickB_duihuan", self );
	self.m_pWndOwned:AddActionListener( "ClickShiyong",self ); 
	self.m_pWndPrice:AddActionListener( "ClickBuy", self );
	self.m_pB_jinbi:AddActionListener( "ClickKelingqu", self );

	self.m_Listener = IAnimationListener:new();
	self.m_Listener.m_pWnd = self;
	self.m_Listener.OnAniPlayStart = function() end
	self.m_Listener.OnFrameString = function() end
	self.m_Listener.OnAniPlayEnd = function( this ) this.m_pWnd:OnAniPlayEnd(); end
end

function CSkinItemWnd:OnDestroy()
	g_App:DestroyRenderObject( self.m_pRenderObject );
	self.m_pRenderObject = nil;
	self.m_Listener = nil;
	CGWnd.OnDestroy( self );
end

function CSkinItemWnd:OnClickFusion()
	local NetMsg = CFusion:new();
	NetMsg.m_nFusionID  = self.m_nSkinID;
	g_App:SendShellMsg( NetMsg );
end

function CSkinItemWnd:SetSkinID( nSkinID )
	if nSkinID==nil then
		return ;
	end
	self.m_nSkinID = nSkinID;
	self.m_pRenderObject = g_App:CreateRenderObject();
	self.m_pRenderObject:OnEquipUpdated( nSkinID, 0, true, false );

	local pair = SFramePair:new();
		pair:m_uStart(2);
		pair:m_uEnd(2);
	self.m_pRenderObject:SetNodeAni( "stand", nil, 
		pair, eAPT_Once, 0, 0, 1.0, nil );
	local pViewportRenderer = self.m_pWndShow:GetViewportRenderer();
	pViewportRenderer:AddChild( self.m_pRenderObject );
	local Camera = pViewportRenderer:GetCamera();
	Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
	Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
	Camera:SetDest( CVector3f:new( 0, 25, 0 ) );

	local nPrice = g_tblTabFile.equip[self.m_nSkinID].nPrice;
	local nSign  = g_tblTabFile.equip[self.m_nSkinID].nAcquire;
	self.m_pWndName:SetWndText( g_tblTabFile.equip[self.m_nSkinID].dName );
	local nSeason = g_tblTabFile.equip[self.m_nSkinID].nSeason;
	local nPayIndex = g_tblTabFile.equip[self.m_nSkinID].nPayIndex;
	local nFragmentID = g_tblTabFile.equip[self.m_nSkinID].nFragmentID;
	local nCountNeed = g_tblTabFile.equip[self.m_nSkinID].nFragmentCount;
	local szDesc = g_tblTabFile.equip[self.m_nSkinID].dDescription;

	--显示皮肤技能
	if g_tblTabFile.equip_skill[self.m_nSkinID].nPassiveEnable ~= 0 then
		self.m_pWndSkill:ShowWnd( true );
		local nPassiveSkillCount = g_tblTabFile.equip_skill[self.m_nSkinID].nPassiveSkillCount;
		for i = 1, #self.m_tblSkillWnd do
			if i <= nPassiveSkillCount then
				self.m_pWndSkill:GetDlgChild( i ):ShowWnd( true );
				local nSkillID = g_tblTabFile.equip_skill[self.m_nSkinID]["nPassiveSkill"..(i - 1)];
				self.m_tblSkillWnd[i]:SetIconID( g_tblTabFile.skill[nSkillID].nIconID );
			elseif self.m_pWndSkill:GetDlgChild( i ) then
				self.m_pWndSkill:GetDlgChild( i ):ShowWnd( false );
			end
		end
	else
		self.m_pWndSkill:ShowWnd( false );
	end

	if self:IsOwned() then
		if self:IsUsing() then
			self.m_pWndUsing:ShowWnd( true );
			self.m_pWndName:EnableWnd( true );
		else
			self.m_pWndOwned:ShowWnd( true );
		end
	else
		self.m_pWndName:EnableWnd( false );
		if nSign == eAcquireType_Buy then
			self.m_pWndPrice:GetDlgChild( "W_jiage" ):SetWndText( tostring( nPrice ) );
			self.m_pWndPrice:ShowWnd( true );
			self.m_ImgGold:ShowWnd( nPayIndex == eResourceType_Gold );
			self.m_ImgRainbow:ShowWnd( nPayIndex == eResourceType_RainbowGold );
		elseif nSign == eAcquireType_Exchange then
			self.m_pB_duihuan:ShowWnd( true );
			self.m_pW_duihuan:ShowWnd( true );
		elseif nSign == eAcquireType_SeasonPrize then
			self.m_BtnSeasonPrize:ShowWnd( true );
		elseif nSign == eAcquireType_LimitModeUnlock then
			self.m_BtnSeasonPrize:GetDlgChild( "W_duihuan" ):SetWndText( g_App:GetString( "xianshipifujiangli" ) );
			self.m_BtnSeasonPrize:ShowWnd( true );
		elseif nSign == eAcquireType_TeamModeUnlock then
			self.m_BtnSeasonPrize:GetDlgChild( "W_duihuan" ):SetWndText( g_App:GetString( "tuanzhanpifujiangli" ) );
			self.m_BtnSeasonPrize:ShowWnd( true );
		elseif nSign == eAcquireType_FragmentFusion or nSign == eAcquireType_Operation then
			if self:CouldGet() then
				self.m_WndFusion:ShowWnd( true );
				local nCurCount = g_App:GetFragmentCount( nFragmentID );
				self.m_BtnFusionPro:SetRange( nCountNeed );
				self.m_BtnFusionPro:SetPos( nCurCount );
				self.m_TextPropText:SetWndText( nCurCount .. "/" .. nCountNeed );
				self.m_BtnFusion:ShowWnd( nCurCount >= nCountNeed );
				self.m_BtnFusionPro:ShowWnd( nCurCount < nCountNeed );
			else 
				self.m_pWndDesc:SetWndText( szDesc );
				self.m_pWndDesc:ShowWnd( true );
			end
		elseif nSign == eAcquireType_Signature then
			self.m_pWndKeLingQu:SetWndText( g_App:GetString( "qiandaojiangli" ) );
			self.m_pB_jinbi:ShowWnd( true );
			self.m_pWndKeLingQu:ShowWnd( true );
		end
	end   
end

function CSkinItemWnd:OnUpdate()
	if not self.m_nSkinID then
		return;
	end

	local nPrice = g_tblTabFile.equip[self.m_nSkinID].nPrice;
	local nSign  = g_tblTabFile.equip[self.m_nSkinID].nAcquire;
	local nSeason = g_tblTabFile.equip[self.m_nSkinID].nSeason;
	local nMonth = g_tblTabFile.equip[self.m_nSkinID].nMonth;
	local nSeasonTargetStar = g_tblTabFile.equip[self.m_nSkinID].nTargetSeasonStar;
	local nSeasonStar = g_App:GetLadderStarBySeason( nSeason );
	local nFragmentID = g_tblTabFile.equip[self.m_nSkinID].nFragmentID;
	local nCountNeed = g_tblTabFile.equip[self.m_nSkinID].nFragmentCount;
	local szDesc = g_tblTabFile.equip[self.m_nSkinID].dDescription;
	local bIsTodayGain = self:IsTodayGainFree();
	local bOwned = self:IsOwned();
	local bUsing = self:IsUsing();
	local nPayIndex = g_tblTabFile.equip[self.m_nSkinID].nPayIndex;
	if bOwned then
		self.m_pWndUsing:ShowWnd( bUsing );
		self.m_pWndOwned:ShowWnd( not bUsing );
		self.m_pB_jinbi:ShowWnd( false );
		self.m_pWndPrice:ShowWnd( false );
		self.m_BtnSeasonPrize:ShowWnd( false );
		self.m_WndFusion:ShowWnd( false );
		self.m_pWndDesc:ShowWnd( false );
	else
		if nSign == eAcquireType_AccumulateSignature then
			if not bIsTodayGain then
				local nGainTime = g_tblTabFile.equip[self.m_nSkinID].nGainTime;
				self.m_pWndKeLingQu:SetWndText( CStringConfig:Inst():GetSkinStr( nGainTime ):ReadUTFBytes(256) );
			else
				self.m_pWndKeLingQu:SetWndText( CStringConfig:Inst():GetSkinStr( 0 ):ReadUTFBytes(256) );
			end
			self.m_pB_jinbi:ShowWnd( true );
			self.m_pWndKeLingQu:ShowWnd( true );
		elseif nSign == eAcquireType_Buy then
			self.m_pWndInsidePrice:SetWndText( nPrice );
			self.m_pWndPrice:ShowWnd( true );
			self.m_ImgGold:ShowWnd( nPayIndex == eResourceType_Gold );
			self.m_ImgRainbow:ShowWnd( nPayIndex == eResourceType_RainbowGold );
		elseif nSign == eAcquireType_Exchange then
			self.m_pB_duihuan:ShowWnd( true );
			self.m_pW_duihuan:ShowWnd( true );
		elseif nSign == eAcquireType_SeasonPrize then
			local szSeason = g_App:GetString( "saijijiangli" );
			szSeason = string.format( szSeason, nMonth );
			self.m_BtnSeasonPrize:GetDlgChild( "W_duihuan" ):SetWndText( szSeason );				
			self.m_BtnSeasonPrize:ShowWnd( true );
		elseif nSign == eAcquireType_LimitModeUnlock then
			self.m_BtnSeasonPrize:GetDlgChild( "W_duihuan" ):SetWndText( g_App:GetString( "xianshipifujiangli" ) );
			self.m_BtnSeasonPrize:ShowWnd( true );		
		elseif nSign == eAcquireType_TeamModeUnlock then
			self.m_BtnSeasonPrize:GetDlgChild( "W_duihuan" ):SetWndText( g_App:GetString( "tuanzhanpifujiangli" ) );
			self.m_BtnSeasonPrize:ShowWnd( true );
		elseif nSign == eAcquireType_FragmentFusion then
			if self:CouldGet() then
				self.m_WndFusion:ShowWnd( true );
				local nCurCount = g_App:GetFragmentCount( nFragmentID );
				self.m_BtnFusionPro:SetRange( nCountNeed );
				self.m_BtnFusionPro:SetPos( nCurCount );
				self.m_TextPropText:SetWndText( nCurCount .. "/" .. nCountNeed );
				self.m_BtnFusion:ShowWnd( nCurCount >= nCountNeed );
				self.m_BtnFusionPro:ShowWnd( nCurCount < nCountNeed );
			else
				self.m_pWndDesc:SetWndText( szDesc );
				self.m_pWndDesc:ShowWnd( true );
			end
		elseif nSign == eAcquireType_Signature then
			self.m_pWndKeLingQu:SetWndText( g_App:GetString( "qiandaojiangli" ) );
			self.m_pB_jinbi:ShowWnd( true );
			self.m_pWndKeLingQu:ShowWnd( true );				
		end
	end
end

function CSkinItemWnd:IsOwned()
	local PlayerData = g_App:GetMainPlayerData().m_HaveEquip;
	for i = 1, PlayerData:GetDataCount() do
		if PlayerData:GetData( i - 1 ) == self.m_nSkinID then
			return true;
		end
	end
	return false;
end

function CSkinItemWnd:CLickB_duihuan()
	self.m_pWndDuihuan:SetData( self.m_nSkinID );
	if not g_App:GetWorldConn() then
		g_App:HideMsg( g_App:GetString( "nopifu" ) );
		return;
	end
end

function CSkinItemWnd:OnClickSeasonPrize()
	if g_tblTabFile.equip[self.m_nSkinID].nAcquire == eAcquireType_LimitModeUnlock then
		g_App:HideMsg( g_App:GetString( "xianshipifujiangli" ) );
		return; 
	elseif g_tblTabFile.equip[self.m_nSkinID].nAcquire == eAcquireType_TeamModeUnlock then
		g_App:HideMsg( g_App:GetString( "tuanzhanpifujiangli" ) );
		return;
	end
	local nSeason = g_tblTabFile.equip[self.m_nSkinID].nSeason;
	local nSeasonTargetStar = g_tblTabFile.equip[self.m_nSkinID].nSeasonTargetStar;
	local nSeasonStar = g_App:GetLadderStarBySeason( nSeason );
	local nMonth = g_tblTabFile.equip[self.m_nSkinID].nMonth;
	local str = g_App:GetString( "saijidabiao" );
	g_App:HideMsg( string.format( str, nMonth ) );
end 

function CSkinItemWnd:ClickBuy()
	self.m_pWndBuySkin:SetData( self.m_nSkinID );
	local nPrice = g_tblTabFile.equip[self.m_nSkinID].nPrice;
	if not g_App:GetWorldConn() then
		g_App:HideMsg( g_App:GetString( "nopifu" ) );
		return;
	end
end

function CSkinItemWnd:ClickShiyong()
	self.m_pWndOwned:ShowWnd(false);
	self.m_pWndUsing:ShowWnd(true);
	local NetMsg = CUsingSkin:new();
	NetMsg.nSkinID = self.m_nSkinID;
	g_App:SendShellMsg( NetMsg ); 
end

function CSkinItemWnd:ClickKelingqu()
	g_App:HideMsg( g_App:GetString( "qiandaojianglitips" ) );
--	if not g_App:GetWorldConn() then
--		g_App:HideMsg( g_App:GetString( "nopifu" ) );
--		return;
--	end
--	if self:IsTodayGainFree() then
--		local NetMsg = CBuySkin:new();
--		NetMsg.nSkinID = self.m_nSkinID;
--		g_App:SendShellMsg( NetMsg );
--		g_App:HideMsg( string.format( CStringConfig.Inst():GetString( "pifu_lingquchenggong" ), g_tblTabFile.equip[self.m_nSkinID].dName ) );
--		return;
--	end
--	g_App:HideMsg( g_App:GetString( "notime" ) );
end

function CSkinItemWnd:IsUsing()
	return g_App:GetMainPlayerData().m_CharBaseData:GetCurEquipID() == self.m_nSkinID;
end

function CSkinItemWnd:Using()
	if not self:IsOwned() then
		return;
	end
	if not g_App:GetWorldConn() then
		g_App:HideMsg( g_App:GetString( "nopifu" ) );
		return;
	end
	local NetMsg = CUsingSkin:new();
	NetMsg.nSkinID = self.m_nSkinID;
	g_App:SendShellMsg( NetMsg );
end


function CSkinItemWnd:IsTodayGainFree()
	local nPrice = g_tblTabFile.equip[self.m_nSkinID].nPrice;
	if nPrice ~= 0 then
		return false;
	end
	local DayMiSeconds = 86400000; -- 一天的毫秒数
	local MainData = g_App:GetMainPlayerData().m_CharBaseData;
	local nLocalTime = GetLocalTime();
	local nCreateTime = MainData:GetCreateTime();
	local nLocalCreateTime = NatureTime2LocalTime( nCreateTime*1000 );
	local nCreateDay = math.floor( nLocalCreateTime / DayMiSeconds );
	local nToday = math.floor( nLocalTime / DayMiSeconds );
	local nDeltaDay = nToday - nCreateDay;
	local nValidCount = math.limit( nDeltaDay, 0, CHAR_SKIN_MAX_COUNT ); --char_skin_max_count
	return nValidCount >= g_tblTabFile.equip[self.m_nSkinID].nGainTime;
end

function CSkinItemWnd:OnOkHide()
	self.m_pWndOkHide:ShowWnd( false );
end

function CSkinItemWnd:GetRenderObject()
	return self.m_pRenderObject;
end

function CSkinItemWnd:OnSelect()
	if not self:GetRenderObject() then
		return;
	end
	self:GetRenderObject():SetNodeAni( "stand_rest1", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, self.m_Listener );---展示动作--
end

function CSkinItemWnd:OnAniPlayEnd()
	self.m_pRenderObject:RemoveAnimationListener( self.m_Listener );
	self.m_pRenderObject:SetNodeAni( "stand", nil, SFramePair:new(), eAPT_Loop, 0, 0, 1.0, nil );---list动作---  点击的时候展示
end


function CSkinItemWnd:CouldGet()
	local nAccountLevel = g_App:GetAccountLevel();
	return g_tblTabFile.fragment[self.m_nSkinID]["nLevel"..nAccountLevel] ~= 0;
end


--- CSkinLingqu Begin ---
function CSkinLingQu:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType);
end

function CSkinLingQu:OnCreated()
	self.m_pTitle				= self:GetDlgChild( "title" );
	self.m_pClose				= self:GetDlgChild( "close" );
	self.m_pClose:AddActionListener( "OnClickClose", self );

	self.m_pbg1shuruduihuanma	= self:GetDlgChild( "bg1" );
	self.m_pbg2jiaruQQqun 		= self:GetDlgChild( "bg2" );

	self.m_pW_lipinma			= self:GetDlgChild( "W_lipinma" );
--	self.m_pW_lipinma:AddEventListener( GM_WM_STATE_CHANGED, "OnTextChanged", self );
--	self.m_pW_lipinma:AddEventListener( WM_SETFOCUS, "OnTextChanged", self );
--  self.m_pW_lipinma:AddEventListener( WM_KILLFOCUS, "OnTextChanged", self );

	self.m_pB_lingqu			= self:GetDlgChild( "B_lingqu" );
	self.m_pB_lingqu:AddActionListener( "OnClickZichuankouB_lingqu", self );
end

function CSkinLingQu:OnClickClose()
	self:ShowWnd( false );
end

function CSkinLingQu:SetData(nIndex)
	self:ShowAndSetFocus();
	self.m_nSkinIDDuihuan = nIndex;
	self:DuihuanOfWindows(self.m_nSkinIDDuihuan);
end

--function CSkinLingQu:OnTextChanged()
--   self.m_pW_lipinma:ShowWnd( self.m_pW_lipinma:GetWndText() == "" and not self.m_pW_lipinma:IsFocus() );
--   self.m_pW_lipinma:ShowWnd( self.m_pW_lipinma:GetWndText() ~= "" );
--end

function CSkinLingQu:OnWndShow( bShow )
--	if bShow then
--		self:ShowWnd( true );
--	else

--	end
end

function CSkinLingQu:DuihuanOfWindows( nIndex )
	
end

function CSkinLingQu:OnClickZichuankouB_lingqu()
    if g_App.m_WorldConnect == nil then
        return;
    end
	local NetMsg = CQueryActivateCode:new();
	NetMsg.szKey = self.m_pW_lipinma:GetWndText();
	g_App.m_WorldConnect:SendShellMsg( NetMsg );
end

--- CSkinLingqu End ---






-----CWndBuySkin Begin-----
function CWndClickBuy:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor(self,sRes,ParentWnd,nLoadType);
end

function CWndClickBuy:OnCreated()
	self.m_pWndPifu		 = self:GetDlgChild( "W_pifu" );

	self.m_pWndQueren	 = self:GetDlgChild("B_queren");
	self.m_wndQuxiao	 = self:GetDlgChild( "B_queren.B_quxiao" );
	self.m_wndQueren	 = self:GetDlgChild( "B_queren.B_queren" );

	self.m_wndPifubiaoti = self:GetDlgChild( "W_pifubiaoti" );

	self.m_pWndBuyCancel = self.m_pWndQueren:GetDlgChild( "B_quxiao" );
	self.m_pWndBuyOk	 = self.m_pWndQueren:GetDlgChild( "B_queren" );

	self.m_wndQuxiao:AddActionListener( "OnClickQuxiao", self );
	self.m_wndQueren:AddActionListener( "OnClickQueren", self );

	self.m_Listener = IAnimationListener:new();
	self.m_Listener.m_pWnd = self;
	self.m_Listener.OnAniPlayStart = function() end
	self.m_Listener.OnFrameString = function() end
	self.m_Listener.OnAniPlayEnd = function( this ) this.m_pWnd:OnAniPlayEnd(); end
	self.m_pRenderObject = g_App:CreateRenderObject();
	local pViewportRenderer = self.m_pWndPifu:GetViewportRenderer(); --皮肤窗口
	pViewportRenderer:EnableResetTimeOnShow( true );
	pViewportRenderer:AddChild( self.m_pRenderObject );
	local Camera = pViewportRenderer:GetCamera(); --pifuchuangkoudingwei
	Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
	Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
	Camera:SetDest( CVector3f:new( 0, 25, 0 ) );
end

function CWndClickBuy:OnDestroy()
	g_App:DestroyRenderObject( self.m_pRenderObject );
	self.m_pRenderObject = nil;
	self.m_Listener = nil;
	CGWnd.OnDestroy( self );
end

function CWndClickBuy:SetData(nIndex)
	self:ShowAndSetFocus();
	self.m_nSkinIDToBuy = nIndex;

	self.m_pRenderObject:OnEquipUpdated( self.m_nSkinIDToBuy, 0, true, false );
	self.m_pRenderObject:SetNodeAni( "stand_rest1", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, self.m_Listener );---list动作---  点击的时候展示	
	local nPrice = g_tblTabFile.equip[self.m_nSkinIDToBuy].nPrice;
	self.m_wndPifubiaoti:SetWndText( g_tblTabFile.equip[self.m_nSkinIDToBuy].dName );
end

function CWndClickBuy:OnAniPlayEnd()
	self.m_pRenderObject:RemoveAnimationListener( self.m_Listener );
	self.m_pRenderObject:SetNodeAni( "stand", nil, SFramePair:new(), eAPT_Loop, 0, 0, 1.0, nil );
end

function CWndClickBuy:OnClickQuxiao()
	self:ShowWnd( false );
end

function CWndClickBuy:OnClickQueren()
	self:ShowWnd( false );
	local nPrice = g_tblTabFile.equip[self.m_nSkinIDToBuy].nPrice;

	if not g_App:GetWorldConn() then
		g_App:HideMsg( g_App:GetString( "nopifu" ) );
		return;
	end

	local NetMsg = CBuySkin:new();
	NetMsg.nSkinID = self.m_nSkinIDToBuy;
	g_App:SendShellMsg( NetMsg );
end

-----CWndBuySkin end------


--endregion
