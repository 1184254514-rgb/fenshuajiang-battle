--region CMessageBox.lua
--Date 2017.09.05

CMessageBox.OK = 1;
CMessageBox.Close = 2;

function CMessageBox:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_tblButton = {};
	self.m_nButtonWidth = 183;
	self.m_nMinInterval = 0;
	self.m_nMessageID = 1;
end

function CMessageBox:OnCreated()
	self.m_szTips = self:GetDlgChild( "W_shuoming" );
	self.m_pButtons = self:GetDlgChild( "W_buttons" );
	self.m_tblButton[CMessageBox.OK] = self.m_pButtons:GetDlgChild( "b_ok" );
	self.m_tblButton[CMessageBox.Close] = self.m_pButtons:GetDlgChild( "b_close" );
end

function CMessageBox:SetBoxData( szTips, tblButton, szOK, szCancel )
	self.m_szTips:SetWndText( szTips );
	if not szOK then
		szOK = CStringConfig.Inst():GetString( "queren" );
	end
	self.m_tblButton[CMessageBox.OK]:SetWndText( szOK );
	if not szCancel then
		szCancel = CStringConfig.Inst():GetString( "quxiao" );
	end
	self.m_tblButton[CMessageBox.Close]:SetWndText( szCancel );

	for _,pWnd in pairs( self.m_tblButton ) do
		pWnd:ShowWnd( false );
		pWnd:RemoveAllEventListener();
	end
	
	if not tblButton then
		tblButton = {
			[CMessageBox.OK] = CMessageBox.HideMessageBox;
		};
	end

	local nStartX = self.m_pButtons:GetGlobalX();
	local nCount = table.count( tblButton );
	local nMaxWidth = self.m_pButtons:GetWndWidth();
	local nInterval = 0;
	if nCount * self.m_nButtonWidth > nMaxWidth then
		nMaxWidth = nCount * self.m_nButtonWidth + ( nCount + 1 ) * self.m_nMinInterval;
		nInterval = self.m_nMinInterval;
	else
		nInterval = ( nMaxWidth - nCount * self.m_nButtonWidth ) / ( nCount + 1 );
	end

	nStartX = nStartX - ( nMaxWidth - self.m_pButtons:GetWndWidth() ) / 2;

	for nIndex,Callback in pairs( tblButton ) do
		local pWnd = self.m_tblButton[nIndex];
		nStartX = nStartX + nInterval;

		pWnd:SetGlobalX( nStartX );
		pWnd:ShowWnd( true );
        pWnd:RemoveAllEventListener();
		pWnd:AddActionListener( Callback, self );

		nStartX = nStartX + self.m_nButtonWidth;
	end
	self.m_nMessageID = self.m_nMessageID + 1;
	return self.m_nMessageID;
end

function CMessageBox:HideMessageBox()
	g_App.m_pMessageBox:ShowWnd( false );
end

--endregion
