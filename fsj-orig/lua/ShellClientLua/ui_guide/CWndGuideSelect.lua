--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndGuideSelect:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndGuideSelect:OnCreated()
	self.m_pWndVideo = self:GetDlgChild( "btn1" );
	self.m_pWndGame = self:GetDlgChild( "btn2" );
	self.m_pWndGuide = self:GetDlgChild( "btn3" );

	self.m_pWndVideo:AddActionListener( "OnVideo", self );
	self.m_pWndGame:AddActionListener( "OnGame", self );
	self.m_pWndGuide:AddActionListener( "OnGuide", self );
end

function CWndGuideSelect:OnVideo()
	self:ShowWnd( false );

	local pGuideVideoWnd = g_App:GetGuideVideoWnd();
	pGuideVideoWnd:PlayVideo( function( bJumpOver )
		if bJumpOver then
			CGuideMgr:Inst():Start();
		else
			local pGameStart = g_App:GetGameStart();
			pGameStart.m_pWndGuideSelect:ShowWnd( true );
		end
	end );
end

function CWndGuideSelect:OnGame()
	self:ShowWnd( false );
	local pGameStart = g_App:GetGameStart();
	g_App:PlayBGMusic();
	pGameStart:HintEnterGame( eRT_Endless );
end

function CWndGuideSelect:OnGuide()
	self:ShowWnd( false );
	CGuideMgr:Inst():Start();
end

--endregion
