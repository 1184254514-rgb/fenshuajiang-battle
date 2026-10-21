--region CWndClanApplyList.lua
--Date 2017.03.14
--家族申请列表

function CWndClanApplyList:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndClanApplyList:OnCreated()
	self.m_ListApply	=	self:GetDlgChild( "list" );
	self.m_BtnClose		=	self:GetDlgChild( "close" );
	self.m_BtnClose:AddActionListener( "OnClose", self );
	self.m_ListApply:SetInertiaType(  eInertiaType_VScroll );
	g_App.m_EventDispatcher:AddEventListener( "OnAnswerApplyList", "InitWndData", self );
end

function CWndClanApplyList:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "OnAnswerApplyList", "InitWndData", self );
end

function CWndClanApplyList:OnWndShow( bShow )
	if bShow then
		self:InitList();
	end
end

function CWndClanApplyList:InitList()
	self.m_ListApply:DeleteAllItem();
	for i = 1, #self.m_tblClanApplyList do
		self.m_ListApply:InsertRowItemsFromRes( -1, "gui/cfg/fsj_jiazu_shenqing_item.gui", CWndClanApplyListItem );
	end
	self.m_ListApply:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnApplyListItemLoaded", self );
end

function CWndClanApplyList:InitWndData( Event )
	if Event.m_nResult ~= eOperate_Ok then
		return;
	end
	self.m_tblClanApplyList = Event.m_tblClanApplyList
	self:ShowAndSetFocus();
end

function CWndClanApplyList:OnApplyListItemLoaded( Event )
	self.m_ListApply:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnApplyListItemLoaded", self );
	for i = 1, #self.m_tblClanApplyList do 
		local subItem = self.m_ListApply:GetSubItem( i - 1, 0 );
		subItem:SetData( self.m_tblClanApplyList[i] );
	end		
end



-----------------------------------------------------------
------家族申请列表Item  
-----------------------------------------------------------
function CWndClanApplyListItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndClanApplyListItem:OnCreated()
	self.m_Text				= self:GetDlgChild( "wenzi" );
	self.m_WndHead			= self:GetDlgChild( "icon.touxiang" );
	self.m_WndAge			= self:GetDlgChild( "genderandage.nianling" );
	self.m_WndMale			= self:GetDlgChild( "genderandage.nan" );
	self.m_WndFemale		= self:GetDlgChild( "genderandage.nv" );
	self.m_WndUnknownSex	= self:GetDlgChild( "genderandage.weizhi" );
	self.m_WndLadderName	= self:GetDlgChild( "duanwei.W_duanwei" );
	self.m_tblLadderIcon	= {};
	for i = 1, 8 do
		local wndIcon		= self:GetDlgChild( "duanwei.icon_duanwei." .. i );
		table.insert( self.m_tblLadderIcon, wndIcon );
	end
	self.m_BtnAgree			= self:GetDlgChild( "btn_ok" );
	self.m_BtnRefruse		= self:GetDlgChild( "btn_no" );
	self.m_BtnAgree:AddActionListener( "OnClickAgree", self );
	self.m_BtnRefruse:AddActionListener( "OnClickRefuse", self );
	self:AddClickListener( "OnShowPlayerInfo", self );
end

function CWndClanApplyListItem:OnDestroy()
end

function CWndClanApplyListItem:OnShowPlayerInfo()
	g_App:ShowPlayerInfo( self.m_nAccountID );
end

function CWndClanApplyListItem:SetData( Data )
	self.m_Text:SetWndText( Data.szCharName );
	CHeadIconConfig:Inst():SetIcon( self.m_WndHead, Data.nCurHeadIcon + 1, Data.nAccountID );
	self.m_WndAge:SetWndText( Data.nAge );
	self.m_WndMale:ShowWnd( Data.nSex == eSexType_Male );
	self.m_WndFemale:ShowWnd( Data.nSex == eSexType_Female );
	self.m_WndUnknownSex:ShowWnd( Data.nSex == eSexType_UnKnown );
	local szLadderName = CStarLevelConfig.Inst():GetName( Data.nCurLadderCount );
	self.m_WndLadderName:SetWndText( szLadderName );
	local nCurLadderLevel = CStarLevelConfig.Inst():GetBigLevel( Data.nCurLadderCount );
	for i = 1, 8 do
		self.m_tblLadderIcon[i]:ShowWnd( i == nCurLadderLevel );	
	end	
	self.m_nAccountID = Data.nAccountID;
end

function CWndClanApplyListItem:OnClickAgree( Event )
	local NetMsg = CClanApplyOperate:new();
	NetMsg.m_nApplyAccountID = self.m_nAccountID;
	NetMsg.m_nOperateType = eAgree_ClanApply;
	g_App:SendShellMsg( NetMsg );
	Event.m_StopImmediately = true;
	self:DestroyWnd();
end

function CWndClanApplyListItem:OnClickRefuse( Event )
	local NetMsg = CClanApplyOperate:new();
	NetMsg.m_nApplyAccountID = self.m_nAccountID;
	NetMsg.m_nOperateType = eRefuse_ClanApply;
	g_App:SendShellMsg( NetMsg );
	Event.m_StopImmediately = true;
	self:DestroyWnd();
end


--endregion
