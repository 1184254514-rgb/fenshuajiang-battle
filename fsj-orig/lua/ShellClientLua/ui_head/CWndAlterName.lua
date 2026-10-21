function CWndAlterName:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndAlterName:OnCreated()
	self.m_pWndPrice				= self:GetDlgChild( "jinbi.W_jiage" );
	self.m_btnBuy					= self:GetDlgChild( "jinbi" );
	self.m_pWndOkHide				= self:GetDlgChild( "queren" );
	self.m_btnOk					= self:GetDlgChild( "queren.B_queren" );
	self.m_pWndCancel				= self:GetDlgChild( "queren.B_quxiao" );
	self.m_wndNewName				= self:GetDlgChild( "mingzi" );
	self.m_btnClose					= self:GetDlgChild( "close" );
	self.m_CBtnMale					= self:GetDlgChild( "xingbie.nan" );
	self.m_CBtnFemale				= self:GetDlgChild( "xingbie.nv" );
	self.m_CbtnUnKnown				= self:GetDlgChild( "xingbie.weizhi" );
	self.m_WndTextAge				= self:GetDlgChild( "nianling.neirong" );
	self.m_ComboBoxConstellation	= self:GetDlgChild( "xingzuo.neirong" );
	self.m_ComboBoxArea				= self:GetDlgChild( "dingwei.neirong" );

	self.m_pWndCostIcon = CRichIconWnd:new( self.m_btnBuy, "icon" );
	self.m_wndNewName:SetMaxStringLength( CHARNAME_BYTE_SIZE );
	self.m_wndNewName:SetWndText( g_App:GetNickName() );
	self.m_pWndOkHide:ShowWnd( false );
	self.m_WndTextAge:SetStyle( eES_DIGITAL_CRITICAL );
	self.m_WndTextAge:SetMaxStringLength( 2 );
	self.m_ComboBoxConstellation:GetListBox():SetInertiaType( eInertiaType_VScroll );
	self.m_ComboBoxArea:GetListBox():SetInertiaType( eInertiaType_VScroll );

	self.m_pWndCancel:AddActionListener( "OnClickCancel", self );
	self.m_btnOk:AddActionListener( "OnClickOk", self );
	self.m_btnBuy:AddActionListener( "OnClickBuy", self );
	self.m_btnClose:AddActionListener( "OnClickClose", self );
	self.m_wndNewName:AddEventListener( GM_WM_STATE_CHANGED, "OnNameChange", self );
	self.m_wndNewName:AddEventListener( WM_CHAR, "OnNameChange", self );
end

function CWndAlterName:OnClickCancel()
	self.m_pWndOkHide:ShowWnd( false );
end

function CWndAlterName:OnClickClose()
	self:ShowWnd( false );
end
function CWndAlterName:OnClickOk() 
	local szName = self.m_wndNewName:GetWndText();
	g_App:Rename( szName );
end

function CWndAlterName:OnClickBuy()	
	self.m_pWndOkHide:ShowWnd( true );
end

function CWndAlterName:OnWndShow( bShow )
	if bShow then
		self.m_wndNewName:SetWndText( g_App:GetNickName() );
		local nCostType = CRenamePrizeConfig.Inst():GetCostType( g_App:GetMainPlayerData().m_CharBaseData:GetRenameNum() );
		local nPrize = CRenamePrizeConfig.Inst():GetPrize( g_App:GetMainPlayerData().m_CharBaseData:GetRenameNum() );
		local nSex = g_App:GetMainPlayerData().m_CharBaseData:GetSex();
		self.m_CBtnFemale:SetCheck( nSex == eSexType_Female );
		self.m_CBtnMale:SetCheck( nSex == eSexType_Male );
		self.m_CbtnUnKnown:SetCheck( nSex == eSexType_UnKnown );
		self.m_WndTextAge:SetWndText( g_App:GetMainPlayerData().m_CharBaseData:GetAge() );
		self.m_pWndCostIcon:SetIconID( g_tblTabFile.currency[nCostType].nIconID );
		self.m_pWndPrice:SetWndText( tostring( nPrize ) );
		self:InitConstellationComboBox();
		self:InitAreaComboBox();
	else
		local NetMsg = CAlterPlayerInfo:new();
		if self.m_CBtnFemale:GetCheck() then
			NetMsg.m_nNewSex = eSexType_Female;
		elseif self.m_CBtnMale:GetCheck() then
			NetMsg.m_nNewSex = eSexType_Male;
		elseif self.m_CbtnUnKnown:GetCheck() then
			NetMsg.m_nNewSex = eSexType_UnKnown;
		end
		NetMsg.m_nNewAge = tonumber( self.m_WndTextAge:GetWndText() );
		NetMsg.m_nNewConstellation = self.m_ComboBoxConstellation:GetCurrentSel();
		NetMsg.m_nNewArea = self.m_ComboBoxArea:GetCurrentSel();
		g_App:GetWorldConn():SendShellMsg( NetMsg );
	end
end

function CWndAlterName:InitConstellationComboBox()
	self.m_ComboBoxConstellation:RemoveAllItem();
	for i = 1, Max_Constellation_Count do
		self.m_ComboBoxConstellation:GetListBox():InsertRowItemsFromRes( -1, "gui/cfg/fsj_xingzuoitem.gui", CGButton );	
	end	
	self.m_ComboBoxConstellation:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnConstellationComboBoxLoaded", self );	
end

function CWndAlterName:OnConstellationComboBoxLoaded()
	for i = 0 , Max_Constellation_Count - 1 do
		local SubItem = self.m_ComboBoxConstellation:GetItem( i );
		SubItem:GetDlgChild( "neirong" ):SetWndText( g_tblTabFile.constellation[i].dName );
	end
	local nCurConstellation = g_App:GetMainPlayerData().m_CharBaseData:GetConstellation();
	self.m_ComboBoxConstellation:SetSel( nCurConstellation );
	self.m_ComboBoxConstellation:SetWndText( g_tblTabFile.constellation[nCurConstellation].dName );
	self.m_ComboBoxConstellation:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnConstellationSelectChanged", self);	
end

function CWndAlterName:OnConstellationSelectChanged( Event )
	local wndItem = self.m_ComboBoxConstellation:GetItem( Event.m_wParam );
	local wndItemText = wndItem:GetDlgChild( "neirong" );
	self.m_ComboBoxConstellation:SetWndText( wndItemText:GetWndText() );
end

function CWndAlterName:InitAreaComboBox()
	self.m_ComboBoxArea:RemoveAllItem();
	for i = 1, Max_AreaCount_Count do
		self.m_ComboBoxArea:GetListBox():InsertRowItemsFromRes( -1, "gui/cfg/fsj_diyuitem.gui", CGButton );	
	end	
	self.m_ComboBoxArea:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnAreaComboBoxLoaded", self );	
end

function CWndAlterName:OnAreaComboBoxLoaded()
	for i = 0 , Max_AreaCount_Count - 1 do
		local SubItem = self.m_ComboBoxArea:GetItem( i );
		SubItem:GetDlgChild( "neirong" ):SetWndText( g_tblTabFile.area[i].dName );
	end
	local nCurArea = g_App:GetMainPlayerData().m_CharBaseData:GetArea();
	self.m_ComboBoxArea:SetSel( nCurArea );
	self.m_ComboBoxArea:SetWndText( g_tblTabFile.area[nCurArea].dName );
	self.m_ComboBoxArea:AddEventListener( GM_WM_ITEM_SELECT_CHANGED, "OnAreaSelectChanged", self);
end

function CWndAlterName:OnAreaSelectChanged( Event )
	local wndItem = self.m_ComboBoxArea:GetItem( Event.m_wParam );
	local wndItemText = wndItem:GetDlgChild( "neirong" );
	self.m_ComboBoxArea:SetWndText( wndItemText:GetWndText() );
end