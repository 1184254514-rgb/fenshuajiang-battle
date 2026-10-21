--region CNetDelayWnd.lua
--Date 2017-08-19

function CNetDelayWnd:Ctor()
end

function CNetDelayWnd:OnCreated()
	self.m_tblChild = {};
	self.m_tblChild[1] = self:GetDlgChild( "1000" );
	self.m_tblChild[2] = self:GetDlgChild( "3000" );
	self.m_tblChild[3] = self:GetDlgChild( "5000" );
	self.m_btnExit = self:GetDlgChild( "5000.yes" );
	self.m_btnExit:AddActionListener( "ExitRoom", self );
end

function CNetDelayWnd:OnDestroy()
end

function CNetDelayWnd:SetNetDelay( nNetDelay )
	if nNetDelay < 1000 then
		self:ShowWnd( false );
		return;
	end

	if( not self:IsShow() ) then
		self:ShowAndSetFocus();
	end
	
	local nLevel = 1;
	if nNetDelay >= 3000 then
		nLevel = 2;
	end

	for k, v in pairs( self.m_tblChild ) do
		v:ShowWnd( k == nLevel );
	end	
end

function CNetDelayWnd:ExitRoom( Event )
	if not g_App.m_FieldConnect then
		return;
	end
	g_App.m_FieldConnect:ShellCmdClose();
end

--endregion
