--region CWndPropellPlayer.lua
--Date 2018.03.27 推荐玩家列表界面
--"gui/cfg/fsj_haoyou_guangchang"

local PlayerCountOnePage =	6;		--每页显示推荐玩家数  
local StarCountMax = 5;				--星星最多显示个数
local StarLevelCount = 8;			--段位最大数量

function CWndPropellPlayer:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndPropellPlayer:OnCreated()
	self.m_BtnSwitch		=	self:GetDlgChild( "b_switch" );
	self.m_tblWndPlayer		=	{};
	for i = 1, PlayerCountOnePage do
		local WndInfo = {};
		WndInfo["Item"]				= self:GetDlgChild( "wanjia" .. i );
		WndInfo["WndStarNum"]		= self:GetDlgChild( "wanjia" .. i .. ".w_xingshu" );
		WndInfo["WndName"]			= self:GetDlgChild( "wanjia" .. i .. ".name" );
		for j = 1, StarCountMax do
			WndInfo["WndStar"..j]	= self:GetDlgChild( "wanjia" .. i .. ".icon_star" .. j );
		end
		for k = 1, StarLevelCount do
			WndInfo["WndStarLevel"] = self:GetDlgChild( "wanjia" .. i .. "icon_duanwei." .. k );
		end
		WndInfo["WndHeadIcon"]		= self:GetDlgChild( "wanjia" .. i .. "head.touxiang" );
		WndInfo["WndAge"]			= self:GetDlgChild( "wanjia" .. i .. "genderandage.nianling" );
		WndInfo["WndUnknownSex"]	= self:GetDlgChild( "wanjia" .. i .. "genderandage.weizhi" );
		WndInfo["WndMale"]			= self:GetDlgChild( "wanjia" .. i .. "genderandage.nv" );
		WndInfo["WndFemale"]		= self:GetDlgChild( "wanjia" .. i .. "genderandage.nan" );
		WndInfo["WndAreaName"]		= self:GetDlgChild( "wanjia" .. i .. "dingwei.name" );
		WndInfo["WndLadderName"]	= self:GetDlgChild( "wanjia" .. i .. "W_duanwei" );
		table.insert( self.m_tblWndPlayer, WndInfo);
		self.m_tblWndPlayer[i].Item:AddActionListener( "OnShowPlayerInfo", self );
	end

	self.m_BtnSwitch:AddActionListener( "OnClickSwitch", self );
	self.m_ComboBox = self:GetDlgChild( "xuanxiang" );
	self.m_ComboBox:GetListBox():SetInertiaType( eInertiaType_VScroll )
end

function CWndPropellPlayer:OnWndShow( bShow )
	if bShow then
		self.m_nPage = 1;
		self:InitCombobox();
	end
end

function CWndPropellPlayer:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndPropellPlayer:ShowPropellPlayer( tblPropellPlayerList )
	self.m_tblPropellPlayerList = tblPropellPlayerList;
	self:ShowWnd( true );
end

function CWndPropellPlayer:OnClickSwitch()
	self.m_nPage = self.m_nPage + 1;	
end

function CWndPropellPlayer:OnShowPlayerInfo()

end

function CWndPropellPlayer:InitCombobox()
	self.m_ComboBox:RemoveAllItem();
	for i = 0, eSexType_UnKnown do
		self.m_ComboBox:GetListBox():InsertRowItemsFromRes( -1, "gui/cfg/fsj_diyuitem.gui", CGButton );
	end	
	self.m_ComboBox:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnComboBoxLoaded", self );	
end

function CWndPropellPlayer:OnComboBoxLoaded()
	for i = 0 , eSexType_UnKnown do
		local SubItem = self.m_ComboBox:GetItem( i );
		SubItem:SetWndText( i );
	end
	self.m_ComboBox:SetSel( 0 );
	self.m_ComboBox:SetWndText( 0 );
	self.m_ComboBox:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnSelectChanged", self);
end

function CWndPropellPlayer:OnSelectChanged( Event )
	local wndItem = self.m_ComboBox:GetItem( Event.m_wParam );
	self.m_ComboBox:SetWndText( wndItem:GetWndText() );
end

--endregion
