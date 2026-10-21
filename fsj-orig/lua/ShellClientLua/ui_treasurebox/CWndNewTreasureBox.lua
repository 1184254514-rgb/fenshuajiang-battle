--region CWndNewTreasureBox.lua
--Date 2017.11.28
-- "fsj_pifu_baoxianghuode" 
--获得新宝箱提示界面

function CWndNewTreasureBox:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndNewTreasureBox:OnCreated()
	self.m_Icon = self:GetDlgChild( "baoxiangtexiao" );
	self.m_BtnBackGameStart = self:GetDlgChild( "b_ok" );
	self.m_BtnBackGameStart:AddActionListener( "OnBackGameStart", self );
	self.m_BtnViewTreasureBox = self:GetDlgChild( "b_chakan" );
	self.m_BtnViewTreasureBox:AddActionListener( "ViewTreasureBox", self );
	self.m_wndBigTreasureBox = self:GetDlgChild( "da" );
	self.m_wndMediaTreasureBox = self:GetDlgChild( "zhong" );
	self.m_wndSmallTreasureBox = self:GetDlgChild( "xiao" );
	self.m_pRenderObject = g_App:CreateRenderObject();
	self.m_pViewportRenderer = self.m_Icon:GetViewportRenderer();
	self.m_pViewportRenderer:AddChild( self.m_pRenderObject );
	self.m_pViewportRenderer:EnableResetTimeOnShow( true );

	self.m_Listener = IAnimationListener:new();
	self.m_Listener.m_pWnd = self;
	self.m_Listener.OnAniPlayStart = function() end
	self.m_Listener.OnFrameString = function() end
	self.m_Listener.OnAniPlayEnd = function( this ) this.m_pWnd:OnAniPlayEnd(); end

	self.m_tickScale = CTick:new( "OnScale", self );
end

function CWndNewTreasureBox:OnDestroy()
	self.m_tickScale:Stop();
	g_App:DestroyRenderObject( self.m_pRenderObject );
	self.m_pRenderObject = nil;
end

function CWndNewTreasureBox:SetData( nTreasureBoxID )
	local tblSzTreasureBoxOpenEffect = { "fx/cfg/box03.eft", "fx/cfg/box02.eft", "fx/cfg/box01.eft" };
	local nTreasureBoxLevel = g_tblTabFile.treasureboxbase[nTreasureBoxID].nLevel;
	self.m_wndBigTreasureBox:ShowWnd( nTreasureBoxLevel == 1 );
	self.m_wndMediaTreasureBox:ShowWnd( nTreasureBoxLevel == 2 );
	self.m_wndSmallTreasureBox:ShowWnd( nTreasureBoxLevel == 3 );
	self:ShowWnd( true );
	self.m_szEffectFile = tblSzTreasureBoxOpenEffect[nTreasureBoxLevel];
	local Camera = self.m_pViewportRenderer:GetCamera();
	local fUpX = g_data_treasureboxpos[1].fUpX;
	local fUpY = g_data_treasureboxpos[1].fUpY;
	local fUpZ = g_data_treasureboxpos[1].fUpZ;
	local fPosX = g_data_treasureboxpos[1].fPosX;
	local fPosY = g_data_treasureboxpos[1].fPosY;
	local fPosZ = g_data_treasureboxpos[1].fPosZ;
	local fDestX = g_data_treasureboxpos[1].fDestX;
	local fDestY = g_data_treasureboxpos[1].fDestY;
	local fDestZ = g_data_treasureboxpos[1].fDestZ;
	Camera:SetUp( CVector3f:new( fUpX, fUpY, fUpZ ) );
	Camera:SetPos( CVector3f:new( fPosX, fPosY, fPosZ ) );
	Camera:SetDest( CVector3f:new( fDestX, fDestY, fDestZ ) );
	self.m_pRenderObject:ShowTreasureBoxModel( nTreasureBoxLevel );
	self.m_pRenderObject:SetNodeAni( "rb1", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, self.m_Listener );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectFile, "fx/rb1", nil, false, 0 );
end

function CWndNewTreasureBox:OnAniPlayEnd()
	self.m_pRenderObject:SetNodeAni( "stand", nil, SFramePair:new(), eAPT_Loop, 0, 0, 1.0, nil );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectFile, "fx/stand", nil, false, -1 );
end

function CWndNewTreasureBox:ViewTreasureBox()
	self:ShowWnd( false );
	g_App:GetGameStart():ShowTreasureBoxWnd();
end

function CWndNewTreasureBox:OnBackGameStart()
	self.m_tickScale:Start( 33 );	
end

function CWndNewTreasureBox:OnScale()
	local nCurScaleX = self:GetScaleX() - 0.15;
	local nCurScaleY = self:GetScaleY() - 0.15;
	if nCurScaleX <= 0 or nCurScaleY <= 0 then
		self:ShowWnd( false );
		self.m_tickScale:Stop();
	end
	self:SetScaleX( nCurScaleX );
	self:SetScaleY( nCurScaleY );
end

function CWndNewTreasureBox:OnWndShow( bShow )
	self:SetScaleX( 1.0 );
	self:SetScaleY( 1.0 );
	if not bShow then
		g_App.m_nNewTreasureBoxID = nil;
	end
end



--endregion
