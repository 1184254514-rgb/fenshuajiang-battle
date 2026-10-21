--region CWndMusic.lua
--Date 2017.08.24
--此文件由[BabeLua]插件自动生成
----CWndMusic Begin-----

local SelectType = { eMuiscAll = 0, eMusicHot = 1, eMusicNew = 2, eMusicElectric = 3, eMusicClassical = 4 };
local OwnType = { eOwnAll = 1, eOwnNo = 2};
function CWndMusic:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
	self.m_tblMusicIDHave = {};
	self.m_tblMusicIDAll = {};
	self.m_tblMusicIDHot = {};
	self.m_tblMusicIDHotNo = {};
	self.m_tblMusicIDNew = {};
	self.m_tblMusicIDNewNo = {};
	self.m_tblMusicIDElectric = {};
	self.m_tblMusicIDElectricNo = {};
	self.m_tblMusicIDClassical = {};
	self.m_tblMusicIDClassicalNo = {};
	self.m_tblMusicIDToShow = {};
	self.m_nCallNum = 0;
end

function CWndMusic:OnCreated()
	self.m_listButton = self:GetDlgChild( "list2" );

	self.m_wndGoldCount = self:GetDlgChild( "jinbi.jinbishuliang" );
	self.m_pBtnAddMoney = self:GetDlgChild( "jinbi.btn_add" );
	self.m_pBtnAddMoney:AddActionListener( "OnClickAddMoney", self );--增加金币

	self.m_pWndRainbowGold = self:GetDlgChild( "jinbi2.jinbishuliang" );
	self.m_BtnShare = self:GetDlgChild( "jinbi2.btn_add" );
	self.m_BtnShare:AddActionListener( "OpenShareWnd", g_App:GetGameStart() );
	
	self.m_wndTitle = self:GetDlgChild( "W_biaoti" );
	self.m_btnClose = self:GetDlgChild( "B_close" );
	self.m_listMusic = self:GetDlgChild( "list" );
	self.m_cBtnOwn = self:GetDlgChild( "weiyongyou.b_gou" );
	self.m_cBtnOwn:AddActionListener( "OnClickOwnType", self );

	self.m_btnClose:AddActionListener( "OnClickClose", self );

	self.m_nSelectType = SelectType.eMuiscAll;	--默认选择为 “热门音乐”
	self.m_nOwnType = OwnType.eOwnAll;	--默认选择为“全部”
	self.m_bSort = true;  --排序
	self.m_bReplayMusic = false;

	self:InitButtonList();
	self.m_listButton:SetInertiaType( eInertiaType_HScroll );
	
	self.m_listMusic:SetInertiaType( eInertiaType_VScroll );
	g_App:GetMainPlayerData():AddEventListener( "m_HaveMusic", "RefreshMusicList", self );

	--设置网速 --弱到强 
	self.m_wifiIcon = {self:GetDlgChild("wifi.icon_3"),self:GetDlgChild("wifi.icon_2"),self:GetDlgChild("wifi.icon_1")};--弱到强
	self.m_timeTick = CTick:new( "OnTimeTick", self );
	self.m_timeTick:Start( 100 );
end

function CWndMusic:OnDestroy()
	self.m_timeTick:Stop();
	g_App:GetMainPlayerData():RemoveEventListener( "m_HaveMusic", "RefreshMusicList", self );
	CGWnd.OnDestroy( self );
end

function CWndMusic:OnTimeTick()
	if not g_App or not g_App:GetWorldConn() then 
		return  ;
	end
	local wifi = g_App:GetWorldConn():GetPingDelay();

	local nIconShowed = wifi < ePing_low and 3  or (wifi > ePing_high and 1 or 2);
	for k , v in pairs ( self.m_wifiIcon ) do 
		self.m_wifiIcon[k]:ShowWnd( k== nIconShowed );
		self.m_wifiIcon[k]:GetDlgChild("wangsu"):SetWndText(wifi);
	end 
end 

function CSkinWnd:OnClickAddMoney() 
	g_App:HideMsg(g_App:GetString("gongnengtips"));
end

function CWndMusic:RefreshMusicList()
--	self.m_nCallNum = self.m_nCallNum + 1;
--	if self.m_nCallNum > 1 then
		self.m_bSort = false;
		self:InitMusicList();
		self:SetGoldCoinCount();
--	end
end

function CWndMusic:CalcMusicHave()
	self:ResetMusicHave();
	local PlayerData = g_App:GetMainPlayerData().m_HaveMusic;
	local nMusicsCount = CMusicConfig:Inst():GetMusicCount();
	for i = 0, nMusicsCount - 1 do 
		local nMusicIDHave = PlayerData:GetData( i );
		if nMusicIDHave ~= 0 then
			table.insert( self.m_tblMusicIDHave, nMusicIDHave );
		end
	end
end

function CWndMusic:ResetMusicHave()
	self.m_tblMusicIDHave = {};
end

function CWndMusic:IsHave( nMusicID )
	for i = 1, #self.m_tblMusicIDHave do
		local nRealID = math.floor( nMusicID / 10 );
		local nHaveID = math.floor( self.m_tblMusicIDHave[i] / 10 );
		if nRealID == nHaveID then
			return true;
		end
	end
	return false;
end

function CWndMusic:OnWndShow( bShow )
	self.m_bSort = true;
	if bShow then
		self:SetGoldCoinCount();
		self:InitMusicList();
		self:SetButtonState();
		self.m_timeTick:Start(1000);	
		local nRainbowGold = g_App:GetPropCount( eGRT_Resource, eResourceType_RainbowGold );
		self.m_pWndRainbowGold:SetWndText( nRainbowGold );
	else
		self:ResetMusicHave();
		self.m_cBtnPlayMusic = nil;
		if self.m_bReplayMusic then
			g_App:SetBGMusic( g_App:GetSelectMusicID() );
			self.m_bReplayMusic = false;
		end
		self.m_bDebug = nil;
		self.m_timeTick:Stop();
	end
end

function CWndMusic:SetSelectMusicCheck()
	local nItemCount = self.m_listMusic:GetItemCount();
	local nCurMusicID = g_App:GetSelectMusicID();
	local nRealID = math.floor( nCurMusicID/10 );
	for i = 0, nItemCount - 1 do 
		local subItem = self.m_listMusic:GetSubItem( i, 0 );
		local nIndex = subItem.m_nIndex;
		if not nIndex then return end
		local nMusicID = math.floor( nIndex/10 );
		if nMusicID == nRealID then
			local nSpeedIndex = nCurMusicID%10;
			if nSpeedIndex == 1 and subItem.m_wndSpeedMedium then
				self.m_cBtnPlayMusic = subItem.m_wndSpeedMedium;
				subItem.m_wndSpeedMedium:SetCheck( true );
			elseif nSpeedIndex == 2 and subItem.m_wndSpeedQuick then
				self.m_cBtnPlayMusic = subItem.m_wndSpeedQuick;
				subItem.m_wndSpeedQuick:SetCheck( true );
			elseif nSpeedIndex == 3 and subItem.m_wndSpeedFast then
				self.m_cBtnPlayMusic = subItem.m_wndSpeedFast;
				subItem.m_wndSpeedFast:SetCheck( true );
			end
		end	
	end
end

function CWndMusic:SetButtonState()
	local nIndex = self.m_nSelectType;
	local subButton = self.m_listButton:GetSubItem( 0, nIndex );
	subButton:SetCheck( true );
end

function CWndMusic:SortMusicList()
	table.sort( self.m_tblMusicIDToShow, function ( a, b )
			if not a or not b then
				return true ;
			elseif self:IsHave( a.nMusicID )  and self:IsHave( b.nMusicID ) then
				return a.nMusicSort < b.nMusicSort;
			elseif self:IsHave( a.nMusicID )	and not self:IsHave( b.nMusicID ) then
				return true;
			elseif not self:IsHave( a.nMusicID ) and self:IsHave( b.nMusicID ) then
				return false;
			elseif ( ( not self:IsHave( a.nMusicID ) ) and ( not self:IsHave( b.nMusicID ) ) ) then
				if self:IsSpecial( a.nMusicID ) and self:IsSpecial( b.nMusicID ) then
					return a.nMusicSort < b.nMusicSort;
				elseif self:IsSpecial( a.nMusicID ) and  not self:IsSpecial( b.nMusicID ) then
					return true;
				elseif not self:IsSpecial( a.nMusicID ) and self:IsSpecial( b.nMusicID ) then
					return false;
				elseif not self:IsSpecial( a.nMusicID ) and  not self:IsSpecial( b.nMusicID ) then
					return a.nMusicSort < b.nMusicSort;
				end
			end 
		end)
end

function CWndMusic:IsSpecial( nIndex )
	return CMusicConfig:Inst():GetSpecial( nIndex ) ~= eAcquireType_Buy;
end

function CWndMusic:OnClickOwnType()
	self.m_bSort = true;
    if self.m_nOwnType == OwnType.eOwnAll then
		self.m_nOwnType = OwnType.eOwnNo;
        self.m_cBtnOwn:SetCheck( true );
    else
		self.m_nOwnType = OwnType.eOwnAll;
        self.m_cBtnOwn:SetCheck( false );
    end
	self.m_cBtnPlayMusic = nil;
	self:InitMusicList();
end

function CWndMusic:InitButtonList()
	self.m_listButton:DeleteAllColumn();
	self.m_listButton:DeleteAllItem();
	local nButtonCount = table.count( g_data_musiclist );
	for i = 1, nButtonCount do
		self.m_listButton:InsertColumn( i - 1, 100 );
	end
	self.m_listButton:InsertRowItemsFromRes( -1, "gui/cfg/fsj_anniu_item.gui", CWndMusicButton );
	self.m_listButton:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnButtonListItemLoaded", self );
	self.m_listButton:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnButtonItemSelectChanged", self);
end

function CWndMusic:OnButtonListItemLoaded()
	self.m_listButton:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnButtonListItemLoaded", self );
	for i = 1, table.count( g_data_musiclist ) do 
		local subItem = self.m_listButton:GetSubItem( 0, i - 1 );
		subItem:SetData( i - 1 );
	end
end

function CWndMusic:OnButtonItemSelectChanged( Event )
	local nIndex = Event.m_lParam;
	local subButton = self.m_listButton:GetSubItem( 0, Event.m_wParam );
	if self.m_nSelectType == nIndex then
		return
	end
	self.m_cBtnPlayMusic = nil;
	self.m_bSort = true;
	self.m_nSelectType = Event.m_lParam ;
	self:InitMusicList()
end

function CWndMusic:SetGoldCoinCount()
	local nGolodCoinCount = g_App:GetPropCount( eGRT_Resource, eResourceType_Gold );
	self.m_wndGoldCount:SetWndText( nGolodCoinCount );
	local nRainbowGold = g_App:GetPropCount( eGRT_Resource, eResourceType_RainbowGold );
	self.m_pWndRainbowGold:SetWndText( nRainbowGold );
end

function CWndMusic:CalcMusicList()
	local nMusicCount = CMusicConfig:Inst():GetMusicCount();
	for i = 0, nMusicCount - 1 do
		local nMusicID = CMusicConfig:Inst():GetMusicID( i );
		local nMusicSort = CMusicConfig:Inst():GetMusicSort( i );
		local tblMusicInfo = {};
		tblMusicInfo.nMusicID = nMusicID;
		tblMusicInfo.nMusicSort = nMusicSort;
		local bHave = self:IsHave( nMusicID );
		local KindArray = {};
		for j = 0, 9 do
			KindArray[j] = CMusicConfig:Inst():GetMusicKind( nMusicID, j );
		end
		local bHave = self:IsHave( nMusicID )
		--先判断该音乐类型列表中是否有当前的筛选类型
		local bShow = CMusicConfig:Inst():GetMusicShowType( nMusicID ) == 1;
		if self:IsType( KindArray ) then
			--判断当前拥有类型
			if bShow then
				if self.m_nOwnType == OwnType.eOwnAll then
					if not self:IsInTable( self.m_tblMusicIDToShow, tblMusicInfo.nMusicID ) then
					table.insert( self.m_tblMusicIDToShow, tblMusicInfo );
					end
				else
					if not bHave then
						if not self:IsInTable( self.m_tblMusicIDToShow, tblMusicInfo.nMusicID ) then
							table.insert( self.m_tblMusicIDToShow, tblMusicInfo );
						end
					end
				end
			end
		end	
		
	end
end

function CWndMusic:IsType( tblKind )
	for k , v in pairs ( tblKind ) do 
		if v == self.m_nSelectType then
			return true;
		end
	end	
	return false;
end

function CWndMusic:IsInTable( tbl, nMusicID )
	for i = 1, #tbl do
		local nRealID = math.floor( tbl[i].nMusicID / 10 );
		local nRealMusicID = math.floor( nMusicID / 10 );
		if nRealID == nRealMusicID then 
			return true;
		end
	end
	return false;
end

function CWndMusic:InitMusicList()
--	self:ClearAllTable();
	self.m_listMusic:DeleteAllItem();
	if not self.m_bDebug then
		self:CalcMusicHave();
	end
--	self:CalcMusicList();
	if self.m_bSort then
		self:ClearAllTable();
		--self:CalcMusicHave();
		self:CalcMusicList();
		self:SortMusicList();
	end

	for i = 1, #self.m_tblMusicIDToShow do
		local nMusicID = self.m_tblMusicIDToShow[i].nMusicID;
		local bHave = self:IsHave( nMusicID );
		if bHave then
			self.m_listMusic:InsertRowItemsFromRes( -1, "gui/cfg/fsj_yinyuexuanze_item2.gui", CWndMusicItemHave );
		else
			self.m_listMusic:InsertRowItemsFromRes( -1, "gui/cfg/fsj_yinyuexuanze2_item1.gui", CWndMusicItemNo );
		end
	end
	
	self.m_listMusic:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	self.m_listMusic:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnItemSelectChanged", self);
end

function CWndMusic:ClearAllTable()
	self.m_tblMusicIDAll = {};
	self.m_tblMusicIDHot = {};
	self.m_tblMusicIDHotNo = {};
	self.m_tblMusicIDNew = {};
	self.m_tblMusicIDNewNo = {};
	self.m_tblMusicIDElectric = {};
	self.m_tblMusicIDElectricNo = {};
	self.m_tblMusicIDClassical = {};
	self.m_tblMusicIDClassicalNo = {};
	self.m_tblMusicIDToShow = {};
end

function CWndMusic:OnListItemLoaded()
	self.m_listMusic:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnListItemLoaded", self );
	for i = 1, #self.m_tblMusicIDToShow do 
		local subItem = self.m_listMusic:GetSubItem( i - 1, 0 );
		subItem:SetData( self.m_tblMusicIDToShow[i].nMusicID );
	end
	self:SetSelectMusicCheck();
	if not self.m_bSort then
		self.m_listMusic:SetScrollVerticalPos( self.m_listVerticalPos or 0 );
	end
end

function CWndMusic:OnItemSelectChanged( Event )
	local nRow = Event.m_wParam;
	local SubItem = self.m_listMusic:GetSubItem( nRow, 0 );
	local nMusicID = SubItem.m_nIndex;
end

function CWndMusic:OnClickClose()
	self:ShowWnd( false );
end

function CWndMusic:GetAllMusicByGM()
	self.m_bDebug = true;
	local nMusicCount = CMusicConfig:Inst():GetMusicCount();
	for i = 0, nMusicCount - 1 do
		local nMusicID = CMusicConfig:Inst():GetMusicID( i );
		table.insert( self.m_tblMusicIDHave, nMusicID );
	end	
end

----CWndMusic End-----

----CWndMusicItemHave Begin-------
function CWndMusicItemHave:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
	self.m_tblMusicIDAll = {};
end

function CWndMusicItemHave:OnCreated()
	self.m_wndMusicName = self:GetDlgChild( "name" );
	self.m_wndSpeedMedium = self:GetDlgChild( "B_zhongsu" );
	self.m_wndSpeedMediumScore = self:GetDlgChild( "B_zhongsu.jiaobiao" );
	self.m_wndSpeedQuick = self:GetDlgChild( "B_kuaisu" );
	self.m_wndSpeedQuickScore = self:GetDlgChild( "B_kuaisu.jiaobiao" );
	self.m_wndSpeedFast = self:GetDlgChild( "B_jisu" );
	self.m_wndSpeedFastScore = self:GetDlgChild( "B_jisu.jiaobiao" );
	self.m_wndDetail = self:GetDlgChild( "b_xiangqing" );
	self.m_wndDetail:ShowWnd( false );

	self.m_wndSpeedMedium:AddActionListener( "OnClickMedium", self );
	self.m_wndSpeedQuick:AddActionListener( "OnClickQuick", self );
	self.m_wndSpeedFast:AddActionListener( "OnClickFast", self);
end

function CWndMusicItemHave:SetCheckState( Event )
	local wndParent = self:GetParent():GetParent();
	if wndParent.m_cBtnPlayMusic and wndParent.m_cBtnPlayMusic ~= Event.m_Target then
		wndParent.m_cBtnPlayMusic:SetCheck( false );
	end
	wndParent.m_cBtnPlayMusic = Event.m_Target;
end

function CWndMusicItemHave:OnClickMedium( Event )
	self:SetCheckState( Event );
	local nRealID = math.floor( self.m_nIndex/10 );
	local nSpeedID = 1;
	local nMusicID = nRealID * 10 + nSpeedID;
	self:PlayOrLoadMusic( nMusicID );
end

function CWndMusicItemHave:OnClickQuick( Event )
	self:SetCheckState( Event );
	local nRealID = math.floor( self.m_nIndex/10 );
	local nSpeedID = 2;
	local nMusicID = nRealID * 10 + nSpeedID;
	self:PlayOrLoadMusic( nMusicID );
end

function CWndMusicItemHave:OnClickFast( Event )
	self:SetCheckState( Event );
	local nRealID = math.floor( self.m_nIndex/10 );
	local nSpeedID = 3;
	local nMusicID = nRealID * 10 + nSpeedID;
	self:PlayOrLoadMusic( nMusicID );
end

function CWndMusicItemHave:IsMusicNeedLoad( nMusicID )
	local bNetMusic = CMusicConfig:Inst():IsNetMusic( nMusicID );
	if not bNetMusic then
		return false;
	else
		local szMusicPath = CMusicConfig:Inst():GetMusicPath( nMusicID );
		local szNetPath = g_App:GetNetMusicPath()..szMusicPath;
		local szFileName = string.sub( szMusicPath, 10 );
		local szPathName = g_App:GetNetMusicLoadPath() .. szFileName;
		if CPathMgr.IsFileExist( szPathName )then
			return false;
		else
			return true;
		end
	end
end

function CWndMusicItemHave:PlayOrLoadMusic( nMusicID )
	local bNeedLoad = self:IsMusicNeedLoad( nMusicID );
	if not bNeedLoad then
		g_App:SetSelectMusicID( nMusicID );
		g_App:SetBGMusic( nMusicID );
	else
		local szLoad = g_App:GetString( "yinyuexiazai" )
		g_App.nReloadMusicID = nMusicID;
		g_App.m_wndReloadMusic = CWndMusicLoadPro:new( "gui/cfg/fsj_yinyuexuanze_tips2.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );	
		g_App:MessageBox( szLoad, {
			[CMessageBox.Close] = function()
				g_App.m_pMessageBox:ShowWnd( false );
			end;
			[CMessageBox.OK] = function()
				g_App.m_pMessageBox:ShowWnd( false );
				g_App.m_wndReloadMusic:ReloadMusic( g_App.nReloadMusicID );
				g_App.nReloadMusicID = nil;
				g_App.m_wndReloadMusic = nil;
			end;
		});
	end
end

function CWndMusicItemHave:SetData( nIndex )
	self:CalcAllMusicID()
	local nRealID = math.floor( nIndex / 10 );
	local nRealIDMedium = nRealID * 10 + 1;
	local nRealIDQuick = nRealID * 10 + 2;
	local nRealIDFast = nRealID * 10 + 3;
	local bShowMedium = self:IsExist( nRealIDMedium );
	local bShowQuick = self:IsExist( nRealIDQuick );
	local bShowFast = self:IsExist( nRealIDFast );
	self.m_wndSpeedMedium:ShowWnd( bShowMedium );
	self.m_wndSpeedQuick:ShowWnd( bShowQuick );
	self.m_wndSpeedFast:ShowWnd( bShowFast );
	local szMusicName = CMusicConfig:Inst():GetMusicName( nIndex );
	self.m_wndMusicName:SetWndText( szMusicName );
	self.m_nIndex = nIndex;
end

function CWndMusicItemHave:CalcAllMusicID()
	local nMusicCount = CMusicConfig:Inst():GetMusicCount();
	for i = 0, nMusicCount - 1 do
		local nMusicID = CMusicConfig:Inst():GetMusicID( i );
		table.insert( self.m_tblMusicIDAll, nMusicID )
	end 
end

function CWndMusicItemHave:IsExist( nMusicID )
	for i = 1, #self.m_tblMusicIDAll do
		if self.m_tblMusicIDAll[i] == nMusicID then
			return true;
		end 
	end
	return false;
end
----CWndMusicItemHave end-------

----CWndMusicItemNo Begin-------
function CWndMusicItemNo:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
end

function CWndMusicItemNo:OnCreated()
	self.m_BtnBuy		= self:GetDlgChild( "B_buy" );
	self.m_wndPrice		= self:GetDlgChild( "B_buy.W_jiage" );
	self.m_wndMusicName = self:GetDlgChild( "name" );
	self.m_BtnPlay		= self:GetDlgChild( "b_shiting" );
	self.m_ImgGold		= self:GetDlgChild( "B_buy.jinbi");
	self.m_ImgRainbow	= self:GetDlgChild( "B_buy.fenxiangbi");
	self.m_wndSpecial   = self:GetDlgChild( "b_teshu" );

	self.m_wndSpecial:ShowWnd( false );
	self.m_ImgGold:ShowWnd( false );
	self.m_ImgGold:ShowWnd( false );

	self.m_BtnBuy:AddActionListener( "OnClickBuyMusic", self );
	self.m_BtnPlay:AddActionListener( "OnClickPlayMusic", self );

	self.m_wndBuyMusic = CWndBuyMusic:new( "gui/cfg/fsj_yinyuexuanze2_tips.gui", self:GetParent():GetParent(), 1 );
	self.m_wndLoadMusic = CWndLoadMusicTips:new( "gui/cfg/fsj_yinyuexuanze_tips1.gui",  g_App:GetGUIMgr():GetRootWnd(), 1 );
end

function CWndMusicItemNo:SetData( nIndex )
	local szMusicName = CMusicConfig:Inst():GetMusicName( nIndex );
	self.m_wndMusicName:SetWndText( szMusicName );
	local nMusicPrice = CMusicConfig:Inst():GetPrice( nIndex );
	self.m_wndPrice:SetWndText( nMusicPrice );
	self.m_nIndex = nIndex;
	self.m_nPayType = CMusicConfig:Inst():GetPayType( nIndex );
	self.m_nPayIndex = CMusicConfig:Inst():GetPayIndex( nIndex );
	self.m_nSpecial = CMusicConfig:Inst():GetSpecial( nIndex );
	if self.m_nSpecial == eAcquireType_Buy then
		if self.m_nPayIndex == eResourceType_RainbowGold then
			self.m_ImgRainbow:ShowWnd( true );
		elseif self.m_nPayIndex == eResourceType_Gold then
			self.m_ImgGold:ShowWnd( true );
		end
	elseif self.m_nSpecial == eAcquireType_LimitModeUnlock then
		self.m_wndSpecial:GetDlgChild( "W_jiage" ):SetWndText( g_App:GetString( "xianshipifujiangli" ) );
		self.m_wndSpecial:ShowWnd( true );
		self.m_BtnBuy:ShowWnd( false );
	elseif self.m_nSpecial == eAcquireType_TeamModeUnlock then
		self.m_wndSpecial:GetDlgChild( "W_jiage" ):SetWndText( g_App:GetString( "tuanzhanpifujiangli" ) );
		self.m_wndSpecial:ShowWnd( true );
		self.m_BtnBuy:ShowWnd( false );
	elseif self.m_nSpecial == eAcquireType_Signature then
		self.m_wndSpecial:GetDlgChild( "W_jiage" ):SetWndText( g_App:GetString( "qiandaojiangli" ) );
		self.m_wndSpecial:ShowWnd( true );
		self.m_BtnBuy:ShowWnd( false );
	end
end

function CWndMusicItemNo:OnClickBuyMusic()
	local nMusicID = self.m_nIndex;
	local bNetMusic = CMusicConfig:Inst():IsNetMusic( nMusicID );
	if not bNetMusic then
		self.m_wndBuyMusic:SetData( nMusicID );
	else
		local szMusicPath =  CMusicConfig:Inst():GetMusicPath( self.m_nIndex );
		local szNetPath = g_App:GetNetMusicPath()..szMusicPath;
		local szFileName = string.sub( szMusicPath, 10 );
		local szPathName = g_App:GetNetMusicLoadPath() .. szFileName;
		local bFileExist =  CPathMgr.IsFileExist( szPathName )
		if not bFileExist then
			local bWifi = IsWifiConnect();
			self.m_wndLoadMusic:ShowWndByType( eLoadMusicType_Buy, self.m_nIndex, bWifi )
		else
			self.m_wndBuyMusic:SetData( nMusicID );
		end	
	end
end

function CWndMusicItemNo:OnClickPlayMusic( Event )
	local bNetMusic = CMusicConfig:Inst():IsNetMusic( self.m_nIndex );
	if not bNetMusic then
		local wndParent = self:GetParent():GetParent();
		if wndParent.m_cBtnPlayMusic and wndParent.m_cBtnPlayMusic ~= Event.m_Target then
			wndParent.m_cBtnPlayMusic:SetCheck( false );
		end
		local nPlayType = CMusicConfig:Inst():GetMusicPlayType( self.m_nIndex );
		g_App:SetBGMusic( math.floor( self.m_nIndex / 10 )*10 + nPlayType );
	else
		local szMusicPath =  CMusicConfig:Inst():GetMusicPath( self.m_nIndex );
		local szNetPath = g_App:GetNetMusicPath()..szMusicPath;
		local szFileName = string.sub( szMusicPath, 10 );
		local szPathName = g_App:GetNetMusicLoadPath() .. szFileName;
		local bFileExist =  CPathMgr.IsFileExist( szPathName )
		if not bFileExist then
			local bWifi = IsWifiConnect();
			self.m_wndLoadMusic:ShowWndByType( eLoadMusicType_Shiting, self.m_nIndex, bWifi )
		else
			local nPlayType = CMusicConfig:Inst():GetMusicPlayType( self.m_nIndex );
			g_App:SetBGMusic( math.floor( self.m_nIndex / 10 )*10 + nPlayType );
		end
	end
	local wndParent = self:GetParent():GetParent();
	if wndParent.m_cBtnPlayMusic and wndParent.m_cBtnPlayMusic ~= Event.m_Target then
		wndParent.m_cBtnPlayMusic:SetCheck( false );
	end
	wndParent.m_cBtnPlayMusic = Event.m_Target;
	wndParent.m_bReplayMusic = true;
end

----CWndMusicItemNo End---------

----CWndBuyMusic Begin----
function CWndBuyMusic:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
end

function CWndBuyMusic:OnCreated()
	self.m_wndTitle = self:GetDlgChild( "title" );
	self.m_wndGoldCoinCount1 = self:GetDlgChild( "jinbi1.shuliang" );
	self.m_wndGoldCoinCount2 = self:GetDlgChild( "jinbi2.shuliang" );
	self.m_btnCancel = self:GetDlgChild( "b_quxiao" );
	self.m_btnOk = self:GetDlgChild( "b_ok" );
	self.m_wndTips = self:GetDlgChild( "W_tishi" );

	self.m_btnCancel:AddActionListener( "OnClickCancel", self );
	self.m_btnOk:AddActionListener( "OnClickOk", self );
	self.m_ImgGold = self:GetDlgChild( "jinbi1.jinbi" );
	self.m_ImgRainbow = self:GetDlgChild( "jinbi1.fenxiangbi" );
	self.m_ImgGold:ShowWnd( false );
	self.m_ImgRainbow:ShowWnd( false );
end

function CWndBuyMusic:SetData( nMusicID )
	self:ShowAndSetFocus();
	self.m_nMusicIDToBuy = nMusicID;
	self.m_nPrice = CMusicConfig:Inst():GetPrice( nMusicID );
	self.m_nMusicName = CMusicConfig:Inst():GetMusicName( nMusicID );
	self.m_nPayType = CMusicConfig:Inst():GetPayType( nMusicID );
	self.m_nPayIndex = CMusicConfig:Inst():GetPayIndex( nMusicID );
	if self.m_nPayIndex == eResourceType_RainbowGold then
		self.m_ImgRainbow:ShowWnd( true );
	elseif self.m_nPayIndex == eResourceType_Gold then
		self.m_ImgGold:ShowWnd( true );
	end
	self:Refresh();
end

function CWndBuyMusic:Refresh()
	self.m_wndGoldCoinCount1:SetWndText( self.m_nPrice );
	self.m_wndTips:SetWndText( self.m_nMusicName );
end

function CWndBuyMusic:OnClickCancel()
	self:ShowWnd( false );
end

function CWndBuyMusic:OnClickOk()
	local nGoldHave = g_App:GetPropCount( eGRT_Resource, eResourceType_Gold );
	local bCanBuy = nGoldHave >= self.m_nPrice;
--	if not bCanBuy then
--		g_App:HideMsg( g_App:GetString( "nojinbi" ) );
--		return;
--	end
	self:ShowWnd( false );
--	local ParentList = self:GetParent().m_listMusic;
--	self:GetParent().m_listVerticalPos = ParentList:GetScrollVerticalPos();
	local ParentList = g_App:GetGameStart().m_WndMusic.m_listMusic;
	g_App:GetGameStart().m_WndMusic.m_listVerticalPos = ParentList:GetScrollVerticalPos();
	local NetMsg = CBuyMusic:new();
	NetMsg.m_nMusicID = self.m_nMusicIDToBuy;
	g_App:SendShellMsg( NetMsg );
end

function CWndMusicButton:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
end

function CWndMusicButton:OnCreated()	
end

function CWndMusicButton:OnDestroy()
end

function CWndMusicButton:SetData( nIndex )
	local szButtonName = CDictionary:Inst():GetValueByString( g_data_musiclist[nIndex].sName );
	self:SetWndText( szButtonName );
end

----CWndBuyMusic End----
--endregion
