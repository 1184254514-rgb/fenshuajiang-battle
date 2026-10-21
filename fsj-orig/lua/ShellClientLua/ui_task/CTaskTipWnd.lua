--region CTaskTipWnd.lua
--场景中的任务界面

function CTaskTipWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CTaskTipWnd:OnCreated()
	self.m_pWndTips = self:GetDlgChild( "shuoming"  );
	self.m_tipTick = CTick:new( "OnTick", self )
	self.m_ShrinkTick = CTick:new( "OnShrink", self );

	self.m_fMoveSpeedX = 0;
	self.m_fMoveSpeedY = 0;
	self.m_fScaleSpeedX = 0;
	self.m_fScaleSpeedY = 0;
	self.m_fOriginX = 0;
	self.m_fOriginY = 0;
	self.m_nTickCount = 0;
end

function CTaskTipWnd:OnDestroy()
	self.m_tipTick:Stop();
	self.m_ShrinkTick:Stop();
	CGWnd.OnDestroy( self );
end

function CTaskTipWnd:TaskTip( sz )
	self.m_pWndTips:SetWndText( sz );
	self:ShowAndSetFocus();
	self.m_tipTick:Start( 2000 );
	self.m_fMoveSpeedX = self:GetGlobalX() / ( CSnakeConstant:Inst():GetTaskWndFadeTime() / 33 );
	self.m_fMoveSpeedY = self:GetGlobalY() / ( CSnakeConstant:Inst():GetTaskWndFadeTime() / 33 );
	self.m_fScaleSpeedX = self:GetScaleX() / ( CSnakeConstant:Inst():GetTaskWndFadeTime() / 33 );
	self.m_fScaleSpeedY = self:GetScaleY() / ( CSnakeConstant:Inst():GetTaskWndFadeTime() / 33 );
	self.m_fOriginHeight = self:GetWndHeight();
	self.m_fOriginWidth = self:GetWndWidth();
	self.m_fOriginX = self:GetGlobalX();
	self.m_fOriginY = self:GetGlobalY();
end

function CTaskTipWnd:OnTick()
	self.m_tipTick:Stop();
	self.m_ShrinkTick:Start( 33 );
end

function CTaskTipWnd:OnShrink()
	self:SetScaleX( self:GetScaleX() - self.m_fScaleSpeedX * self.m_nTickCount );
	self:SetScaleY( self:GetScaleY() - self.m_fScaleSpeedY * self.m_nTickCount );
	self.m_nTickCount = self.m_nTickCount + 1;
	if self.m_nTickCount >= CSnakeConstant:Inst():GetTaskWndFadeTime() / 100 then
		self.m_ShrinkTick:Stop();
		self:ShowWnd( false );
		self:Reset();
	end
end

function CTaskTipWnd:Reset()
	self.m_nTickCount = 0;
	self:SetScaleX( 1 );
	self:SetScaleY( 1 );
end



--endregion
