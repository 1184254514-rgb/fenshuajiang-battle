--region CSceneLoading.lua
--Date 2015-12-09

function CSceneLoading:Ctor()
	self.m_PreChangeTime = 0;
	self.m_nPreValue = 0;
	self:SetHideOnEscape( false );
	self.m_tblTex = {};
end

function CSceneLoading:OnCreated()
	self.m_wndLoading = self:GetDlgChild( "jindutiao" );
	self.m_wndTipInfo = self:GetDlgChild( "tips" );
	self.m_bgImg = self:GetDlgChild( "ditu" );
	self.m_wndLoading:SetRange( 1000 );
	self.m_wndLoading:SetPos( 0 );			
	self.m_wndLoading:SetWndText( "0.0%" );
	self:SetStyle( BitOr( self:GetStyle(), eWS_TOPMOST ) );
end

function CSceneLoading:OnDestroy()
	for k, v in pairs( self.m_tblTex ) do
		v:Release();
	end
end

function CSceneLoading:SetFreeze( value )
	self.m_PreChangeTime = value and -1 or 0;
end

function CSceneLoading:GetFreeze()
	return self.m_PreChangeTime == -1;
end

function CSceneLoading:GetLoadingText()
	local nCurPos = math.floor( self.m_wndLoading:GetPos() ) * 0.1;
	return string.format( "%.1f", nCurPos ) .. "%";
end

function CSceneLoading:PreRender( CurTime, nDeltaTime )
	if not self.m_wndLoading then
		return;
	end
	
	g_App:HidePreLoadingUI();

	if self:GetFreeze() and self.m_nPreValue == self.m_wndLoading:GetPos() and 
	CurTime - self.m_PreChangeTime > 100 then
		self.m_wndLoading:SetPos( self.m_wndLoading:GetPos() + 1 );
		self.m_PreChangeTime = CurTime;
		self.m_wndLoading:SetWndText( self:GetLoadingText() );
	end

	if self.m_wndLoading:GetPos() >= self.m_wndLoading:GetRange() then
		self:ShowWnd( false );
	end

	self.m_nPreValue = self.m_wndLoading:GetPos();
end

function CSceneLoading:SetProgress( totalProgress )
	if not self:GetParent() or not self.m_wndLoading then
		return;
	end

	local nMax1 = math.max( totalProgress * 10, self.m_wndLoading:GetPos() );
	local nMin1 = math.min( nMax1, 1000 );
	self.m_wndLoading:SetPos( nMin1 );

	if self.m_wndLoading:GetPos() < self.m_wndLoading:GetRange() then
		self.m_wndLoading:SetWndText( self:GetLoadingText() );
	else
		self:ShowWnd( false );
	end
end

function CSceneLoading:LoadingDone()
	if self:IsShow() then
		self:ShowWnd( false );
	end
end

function CSceneLoading:OnWndShow( bShow )
	self:EnablePreRender( bShow );
	if bShow then
		self:SetShowInfo();
	else


	end
end

function CSceneLoading:OnLoadingConfigLoaded()
	local ResMgr = g_App:GetGUIMgr():GetRenderer():GetResourceMgr();
	for k, v in pairs( g_data_loading ) do
		self.m_tblTex[k] = ResMgr:CreateResource( v.sImgName, eFT_GammaTexture );
	end
end

function CSceneLoading:SetShowInfo()
	self.m_wndLoading:SetPos( 0 );
	self.m_wndLoading:SetWndText( "0.0%" );

	local nImgIndex, nTipsIndex = CLoadingImgTipsMgr:GetInstance():GetRandomMgrTipsText();
	local szTips = g_data_tips[nTipsIndex].sMsg;
	self.m_wndTipInfo:SetWndText( szTips and szTips or g_data_tips[1].sMsg );

	local rtImg = CFRect:new( g_data_loading[ nImgIndex ].nleft, 
							g_data_loading[ nImgIndex ].nTop, 
							g_data_loading[ nImgIndex ].nRight, 
							g_data_loading[ nImgIndex ].nBottom );
	local rtWnd = CFRect:new();
	rtWnd:right( self.m_bgImg:GetWndWidth() );
	rtWnd:bottom( self.m_bgImg:GetWndHeight() );
	local szResName = g_App:GetDataPath() .. g_data_loading[ nImgIndex ].sImgName;

	self.m_bgImg:RestoreImageFromCreateParam();
	self.m_bgImg:AddImage( GSM_BS_BK, eST_ENABLE, 0, szResName, 
		rtImg, rtWnd, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );
end

function CSceneLoading:OnLoadingDone()
	if self:GetShowFlag() then
		self:ShowWnd( false );
	end
end

--endregion
