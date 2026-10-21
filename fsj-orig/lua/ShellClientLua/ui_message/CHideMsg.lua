--region CHideMsg.lua
--Date 2018-01-31

function CHideMsg:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_TipTick = CTick:new( "OnTick", self )
end

function CHideMsg:OnCreated()
	self:AddClickListener( "OnClickEvent", self );
end

function CHideMsg:OnDestroy()
	self.m_TipTick:Stop();
end

function CHideMsg:OnClickEvent()
	self:ShowWnd( false );
end

function CHideMsg:Hide( szTit, nTickTime )
	self:SetWndText( szTit );
	self:ShowWnd( true );
	self:SetFocus();
	self.m_TipTick:Start( nTickTime or CSnakeConstant:Inst():GetTipShow() );
end

function CHideMsg:OnTick()
	self:ShowWnd( false );
	self.m_TipTick:Stop();
end

--endregion
