function CLevelTipWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CLevelTipWnd:OnCreated()
	self.m_BtnClose = self:GetDlgChild( "close" );
	self.m_BtnClose:AddActionListener( "OnClickClose", self );
end

function CLevelTipWnd:OnClickClose()
	self:ShowWnd( false );
end