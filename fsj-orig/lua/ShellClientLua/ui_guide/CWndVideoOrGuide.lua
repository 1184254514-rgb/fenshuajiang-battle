--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndVideoOrGuide:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndVideoOrGuide:OnCreated()
	self.m_pWndVideo = self:GetDlgChild( "btn1" );
	self.m_pWndGuide = self:GetDlgChild( "btn2" );
	self.m_pWndRhythmGuide = self:GetDlgChild( "btn3" );

	self.m_pWndVideo:AddActionListener( "OnVideo", self );
	self.m_pWndGuide:AddActionListener( "OnGuide", self );
	self.m_pWndRhythmGuide:AddActionListener( "OnRhythmGuide", self );
	self:AddCloseAction();
end

function CWndVideoOrGuide:OnWndShow( bShow )
	if bShow then
		self.m_pWndVideo:GetDlgChild( "tips2" ):ShowWnd( g_App:GetFirstEvent( eFE_VideoGuidePrize ) );
		self.m_pWndVideo:GetDlgChild( "hongdian" ):ShowWnd( not g_App:GetFirstEvent( eFE_VideoGuidePrize ) );
		self.m_pWndGuide:GetDlgChild( "tips2" ):ShowWnd( g_App:GetFirstEvent( eFE_NewerGuidePrize ) );
		self.m_pWndGuide:GetDlgChild( "hongdian" ):ShowWnd( not g_App:GetFirstEvent( eFE_NewerGuidePrize ) );
		self.m_pWndRhythmGuide:GetDlgChild( "tips2" ):ShowWnd( g_App:GetFirstEvent( eFE_RhythmGuidePrize ) );
		self.m_pWndRhythmGuide:GetDlgChild( "hongdian" ):ShowWnd( not g_App:GetFirstEvent( eFE_RhythmGuidePrize ) );
	end
end

function CWndVideoOrGuide:OnVideo()
	self:ShowWnd( false );
	g_App:StopBGMusic();
	g_App:GetGuideVideoWnd():PlayVideo( function()
		g_App:PlayBGMusic();
	end );
end

function CWndVideoOrGuide:OnGuide()
	self:ShowWnd( false );
	CGuideMgr:Inst():Start();
end

function CWndVideoOrGuide:OnRhythmGuide()
	self:ShowWnd( false );
	CRhythmGuide:Inst():Start();
end
--endregion
