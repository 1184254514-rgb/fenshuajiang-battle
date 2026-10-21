--region CWaitMsg.lua
--Date 2018-01-31

function CWaitMsg:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_WaitTick = CTick:new( "OnWaitMsg", self )
end

function CWaitMsg:OnCreated()
	self.m_wndMsg = self:GetDlgChild( "bg1" );
end

function CWaitMsg:OnDestroy()
	self.m_WaitTick:Stop();
end

function CWaitMsg:WaitMsg( bWait, nWaitTime, szText )
	if not bWait then
		return self:OnWaitMsg();
	end

	self:ShowWnd( true );
	self:SetFocus();
	if nWaitTime and nWaitTime ~= 0 then
		self.m_WaitTick:Start( nTickTime );
	else
		self.m_WaitTick:Stop();
	end

	if not szText then
		szText = g_App:GetString( "wanmingjiazaizhong" );
	end
	self.m_wndMsg:SetWndText( szText );
end

function CWaitMsg:OnWaitMsg()
	self:ShowWnd( false );
	self.m_WaitTick:Stop();
end



--endregion
