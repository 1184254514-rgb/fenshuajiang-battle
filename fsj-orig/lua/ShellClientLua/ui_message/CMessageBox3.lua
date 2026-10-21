--region CMessageBox3.lua
--Date 2017/12/4
--此文件由[BabeLua]插件自动生成

CMessageBox3.First = 1;
CMessageBox3.Second = 2;
CMessageBox3.Third = 3;

function CMessageBox3:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_tblButton = {};
	self.m_nButtonWidth = 210;
	self.m_nMinInterval = 0;
end

function CMessageBox3:OnCreated()
	self.m_szTips = self:GetDlgChild( "tishi" );
	self.m_tblButton[CMessageBox3.First] = self:GetDlgChild( "btn_1" );
	self.m_tblButton[CMessageBox3.Second] = self:GetDlgChild( "btn_2" );
	self.m_tblButton[CMessageBox3.Third] = self:GetDlgChild( "btn_3" );
	self.m_btnClose = self:GetDlgChild( "close" );
	self.m_btnClose:AddActionListener( "HideMessageBox", self );
end

function CMessageBox3:SetData( szTips, tblButton, szFirst, szSecond, szThird )
	self.m_szTips:SetWndText( szTips );
	if szFirst then
		self.m_tblButton[CMessageBox3.First]:SetWndText( szFirst );
	end
	if szSecond then
		self.m_tblButton[CMessageBox3.Second]:SetWndText( szSecond );
	end
	if szThird then
		self.m_tblButton[CMessageBox3.Third]:SetWndText( szThird );
	end

	for _,pWnd in pairs( self.m_tblButton ) do
		pWnd:ShowWnd( false );
		pWnd:RemoveAllEventListener();
	end
	
	if not tblButton then
		tblButton = {
			[CMessageBox3.First] = CMessageBox3.HideMessageBox;
			[CMessageBox3.Second] = CMessageBox3.HideMessageBox;
			[CMessageBox3.Third] = CMessageBox3.HideMessageBox;
		};
	end

	for nIndex,Callback in pairs( tblButton ) do
		local pWnd = self.m_tblButton[nIndex];
		pWnd:ShowWnd( true );
        pWnd:RemoveAllEventListener();
		pWnd:AddActionListener( Callback, self );
	end
end

function CMessageBox3:HideMessageBox()
	g_App.m_pMessageBox3:ShowWnd( false );
end



--endregion
