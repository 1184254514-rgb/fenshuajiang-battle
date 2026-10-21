--region CWndAccountLevel.lua
--Date 2018.01.19
--玩家账号等级界面 

local LEVELMIN = 1;
local LEVELMAX = 5;

function CWndAccountLevel:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndAccountLevel:OnCreated()
	self.m_WndTitle				= self:GetDlgChild( "title" );
	self.m_ListProp				= self:GetDlgChild( "list" );
	self.m_Pro					= self:GetDlgChild( "jindutiao" );
	self.m_ProText				= self:GetDlgChild( "jindutiao.shuzi" );
	self.m_WndCurLevel			= self:GetDlgChild( "dangqiandengji" );
	self.m_BtnClose				= self:GetDlgChild( "close" );
	self.m_BtnLeft				= self:GetDlgChild( "btn_zuo" );
	self.m_BtnRight				= self:GetDlgChild( "btn_you" );
	self.m_WndLockTip			= self:GetDlgChild( "shuoming" );
	self.m_BtnLockTips			= self:GetDlgChild( "shuo" );
	self.m_WndLockTips			= CWndAccountLevelLockTips:new( "gui/cfg/fsj_baoxiang_shuoshuoming.gui", self, 1 );

	self.m_BtnClose:AddActionListener( "OnClose", self );
	self.m_BtnLeft:AddActionListener( "OnLeft", self );
	self.m_BtnRight:AddActionListener( "OnRight", self );
	self.m_BtnLockTips:AddActionListener( "OnClickLock", self )

	self.m_ListProp:SetInertiaType( eInertiaType_VScroll );
end

function CWndAccountLevel:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndAccountLevel:OnWndShow( bShow )
	if bShow then
		if g_App:IsUnlockAccountLevel() then
			self.m_BtnLockTips:ShowWnd( false );
		end
	end
end

function CWndAccountLevel:OnClose()
	self:ShowWnd( false );
end

function CWndAccountLevel:OnLeft()
	self.m_nShowLevel = self.m_nShowLevel - 1;
	if self.m_nShowLevel < LEVELMIN then
		self.m_nShowLevel = LEVELMAX;
	end
	self:UpdateWnd();
end

function CWndAccountLevel:OnRight()
	self.m_nShowLevel = self.m_nShowLevel + 1;
	if self.m_nShowLevel > LEVELMAX then
		self.m_nShowLevel = LEVELMIN;
	end
	self:UpdateWnd();
end

function CWndAccountLevel:UpdateWnd()
	if not self.m_nShowLevel then
		self.m_nShowLevel = g_App:GetAccountLevel();
	end

	if not self.m_tblLevelProp then
		self.m_tblLevelProp = {};
		local nFragmentKindCount = g_tblTabFile.fragment.nRowCount;
		for i = LEVELMIN, LEVELMAX do
			self.m_tblLevelProp[i] = {};
			for j = 1, nFragmentKindCount do
				local FragmentConfig = g_tblTabFile.fragment:GetRow( j );
				local bShow = FragmentConfig.nAcquire == eAcquireType_OpenTreasureBox;
				local bTreasureBox = tonumber( FragmentConfig.bBTreasureBox ) == 1;
				local nProb = FragmentConfig["nLevel"..i];
				if bTreasureBox and bShow and nProb > 0 then
					local tbl = {};
					tbl.nFragmentID = FragmentConfig.nID;
					tbl.dName = FragmentConfig.dName;
					tbl.nIconID = FragmentConfig.nIconID;
					table.insert( self.m_tblLevelProp[i], tbl );
				end
			end		
		end			
	end
	
	self.m_tblPropShow = self.m_tblLevelProp[self.m_nShowLevel];
	self.m_ListProp:DeleteAllColumn();
	self.m_ListProp:DeleteAllItem();
	for i = 1, 6 do
		self.m_ListProp:InsertColumn( i - 1, 100 );
	end
	local nRows = math.ceil( table.count( self.m_tblPropShow ) / 6 );
	for i = 1, nRows do
		self.m_ListProp:InsertRowItemsFromRes( -1, "gui/cfg/fsj_baoxiang_shuoming_item.gui", CWndAccountLevelItem );
	end
	self.m_ListProp:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnPropItemLoaded", self );	

	self.m_WndCurLevel:SetWndText( g_App:GetAccountLevel() );
	local nExpMin =  g_tblTabFile.playerlevel[g_App:GetAccountLevel()].nExpMin;
	local nExpMax = g_tblTabFile.playerlevel[g_App:GetAccountLevel()].nExpMax;
	if g_App:GetAccountLevel() == 5 then
		self.m_Pro:SetRange( 1 );
		self.m_Pro:SetPos( 1 );
		self.m_ProText:SetWndText( "100%" );
	else
		if nExpMax < 0 then nExpMax = 0xffffff end;
		self.m_Pro:SetRange( nExpMax - nExpMin );
		self.m_Pro:SetPos( g_App:GetMainPlayerData().m_CharBaseData:GetExp() - nExpMin );
		local nRatio = math.floor( ( g_App:GetMainPlayerData().m_CharBaseData:GetExp() - nExpMin )/ (nExpMax - nExpMin ) * 100 );
		self.m_ProText:SetWndText( nRatio .. "%" );
	end

	self.m_WndTitle:SetWndText( string.format( g_App:GetString( "zhanghaosijijiesuo" ), self.m_nShowLevel ) );
	self.m_WndLockTip:ShowWnd( self.m_nShowLevel > LEVELMIN );
	if self.m_nShowLevel > g_App:GetAccountLevel() then
		self.m_WndLockTip:SetWndText( g_App:GetString( "weijiesuo" ) );
	else
		self.m_WndLockTip:SetWndText( g_App:GetString( "yijiesuo" ) );
	end
	self:ShowAndSetFocus();
end

function CWndAccountLevel:OnPropItemLoaded()
	self.m_ListProp:RemoveAllEventListener( GM_WM_ITEM_ALLLOADED, "OnPropItemLoaded", self );
	local nItem = self.m_ListProp:GetItemCount();
	local nCol  = self.m_ListProp:GetColumnCount();
	local nPropCount = table.count( self.m_tblPropShow );
	for i = 0, nItem - 1 do
		for j = 0, nCol - 1 do
			local listItem = self.m_ListProp:GetSubItem( i, j );
			local nindex = i * 6 + j + 1;
			listItem:SetData( self.m_tblPropShow[nindex], true );		
			if nindex > nPropCount then
				self.m_ListProp:SetSubItemVisible( false, i, j );
			end
		end 
	end
end

function CWndAccountLevel:OnClickLock()
	self.m_WndLockTips:ShowWnd( true );
end




function CWndAccountLevelItem:Ctor( sResName, Parentwnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndAccountLevelItem:OnCreated()
	self.m_Icon = CRichIconWnd:new( self, "tietu" );
end

function CWndAccountLevelItem:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndAccountLevelItem:SetData( Data )
	if not Data then return end;
	self.m_Icon:SetIconID( Data.nIconID );
end



function CWndAccountLevelLockTips:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndAccountLevelLockTips:OnCreated()
	self.m_BtnOk = self:GetDlgChild( "btn" );
	self.m_TextRainbowCount = self:GetDlgChild( "yinfushuliang" );

	self.m_BtnOk:AddActionListener( "OnClickOK", self );
	g_App.m_EventDispatcher:AddEventListener( "UpdateRainbowGold", "OnUpdateRainbowGold", self );
end

function CWndAccountLevelLockTips:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "UpdateRainbowGold", "OnUpdateRainbowGold", self );
	CGWnd.OnDestroy( self );
end

function CWndAccountLevelLockTips:OnClickOK()
	self:ShowWnd( false );
end

function CWndAccountLevelLockTips:OnWndShow( bShow )
	if not bShow then
		return;
	end
	local NetMsg = CQueryRainbowGold:new();
	g_App:SendShellMsg( NetMsg );
end

function CWndAccountLevelLockTips:OnUpdateRainbowGold( Event )
	self.m_TextRainbowCount:SetWndText( Event.RainbowGoldHistory .. "/" .. CSnakeConstant:Inst():GetUnlockAccountLevelRainbowHistory() );
end


--endregion
