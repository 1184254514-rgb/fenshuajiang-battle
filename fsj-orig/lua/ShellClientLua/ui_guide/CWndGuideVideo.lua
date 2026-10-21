--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndGuideVideo:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_bWaitingPlay = false;
	self.m_tickTime = CTick:new( "OnTickTime", self );
end

function CWndGuideVideo:OnCreated()
	self.m_pWndTime = self:GetDlgChild( "shijian" );
	self.m_pWndClose = self:GetDlgChild( "close" );
	self.m_pWndClose:AddActionListener( "OnWndClose", self );

	self.m_pVideoWnd = CVideoWnd:new();
	self:AssignDlgChildToWnd( self.m_pVideoWnd, "shipin", false );
	self.m_pVideoWnd:SetSaturation( 102 );

	if self.m_bWaitingPlay then
		self:PlayVideo( self.m_pFunction );
	end
end

function CWndGuideVideo:PlayVideo( pFunction )
	self.m_pFunction = pFunction;
	self:ShowWnd( true );
	if not self:IsCreated() then
		self.m_bWaitingPlay = true;
		return;
	end
	
	self.m_szH264File = "video/guide.264";
	self.m_szAudio = "video/guide.mp3";
	self.m_nFrameInterval = 1000 / CSnakeConstant:Inst():GetGuideFrame();
	self.m_nPlayAllTime = CSnakeConstant:Inst():GetGuideVideoTime();

	self:SetFocus();
	self.m_pVideoWnd:Play( self.m_szH264File, self.m_szAudio, self.m_nFrameInterval );
	self.m_tickTime:Start( 1000 );
	self.m_nTime = self.m_nPlayAllTime;
	self.m_nFullTime = self.m_nPlayAllTime;
	self:OnTickTime();
end

function CWndGuideVideo:OnTickTime()
	if self.m_nTime == 0 then
		self:OnEnd( false );
		return;
	end
	self.m_nTime = self.m_nTime - 1;
	self.m_pWndTime:SetWndText( tostring( self.m_nTime ) );
end

function CWndGuideVideo:OnWndClose()
	self:OnEnd( true );
end

function CWndGuideVideo:OnEnd( bJumpOver )
	self.m_tickTime:Stop();
	self.m_pVideoWnd:Terminate();
	self:ShowWnd( false );
	if self.m_pFunction then
		self.m_pFunction( bJumpOver );
	end

	if not bJumpOver then		
		g_App:FinishVideoGuide();
	end

	local NetMsg = CVideoGuideLog:new();
	NetMsg.bFull = not bJumpOver;
	NetMsg.nRecord = self.m_nFullTime - self.m_nTime;
	g_App:SendShellMsg( NetMsg );
end

--endregion
