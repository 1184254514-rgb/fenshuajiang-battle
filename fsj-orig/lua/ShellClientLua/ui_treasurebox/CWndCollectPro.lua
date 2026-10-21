--region CWndCollectPro.lua
--Date 2017.11.28
-- "fsj_pifu_shoujijindu"
--碎片收集进度界面

local  eStarAll = 6;
function CWndCollectPro:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndCollectPro:OnCreated()
	self.m_TextName			= self:GetDlgChild( "name" );
	self.m_Model			= self:GetDlgChild( "moxing" );
	self.m_Pro				= self:GetDlgChild( "jindutiao" );
	self.m_tblStar			= {};
	for i = 1, eStarAll do
		self.m_tblStar[i]   = self:GetDlgChild( "star.star" .. i );	
	end
	self.m_Btnclose			= self:GetDlgChild( "close" );
	self.m_tickPro			= CTick:new( "OnTick", self );
	self.m_Btnclose:AddActionListener( "OnHide", self );
end

function CWndCollectPro:OnDestroy()
	self.m_tickPro:Stop();
	CGWnd.OnDestroy( self );
end

function CWndCollectPro:OnActive( bActive )
	if not bActive then
		self:ShowWnd( false );
	end
end

function CWndCollectPro:ShowFragmentCollectPro( nFusionskinID, nEndCount, nAddCount, nRange )
	self.m_Btnclose:EnableWnd( false );
	self:ShowAndSetFocus();
	self.m_nFusionskinID = nFusionskinID;
	self.m_nEndCount = nEndCount;
	self.m_nAddCount = nAddCount;
	self.m_nTotal = nRange;
	self.m_Pro:SetRange( nRange );
	self.m_Pro:SetPos( nEndCount - nAddCount );
	self.m_szEffectAniShow = g_tblTabFile.fusion[nFusionskinID].szEffectAllAniShow;
	self.m_szEffectRest    = g_tblTabFile.fusion[nFusionskinID].szEffectRest;
	self.m_szSkinName	   = g_tblTabFile.fusion[nFusionskinID].dName;
	self.m_Pro:SetWndText( tostring( math.floor( self.m_nEndCount/self.m_nTotal * 100 +0.5 ) ) .. "%" );
	self.m_TextName:SetWndText( self.m_szSkinName );
	local nLevel = nFusionskinID%10;
	for i = 1, eStarAll do
		self.m_tblStar[i]:EnableWnd( i <= nLevel )
	end
	if not self.m_pRenderObject then
		self.m_pRenderObject = g_App:CreateRenderObject();
	end
	self.m_pRenderObject:OnEquipUpdated( self.m_nFusionskinID, 0, true, false );
	local pair = SFramePair:new();
		pair:m_uStart(2);
		pair:m_uEnd(2);
	self.m_pRenderObject:SetNodeAni( "stand", nil, pair, eAPT_Once, 0, 0, 1.0, nil );
	local pViewportRenderer = self.m_Model:GetViewportRenderer();
	pViewportRenderer:EnableResetTimeOnShow( true );
	pViewportRenderer:AddChild( self.m_pRenderObject );
	local Camera = pViewportRenderer:GetCamera();
	Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
	Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
	Camera:SetDest( CVector3f:new( 0, 25, 0 ) );
	if not self.pListener then
		self.pListener = IAnimationListener:new();
		g_RederObjectPro = self.m_pRenderObject;
		g_szEffectRestPro = self.m_szEffectRest;
		g_ListenerPro = self.pListener;
		g_BtnClose = self.m_Btnclose;
		self.pListener.OnAniPlayStart = function() 
		end;
		self.pListener.OnAniPlayEnd = function()
			self.m_pRenderObject:SetNodeAni( "stand", nil, SFramePair:new(), eAPT_Loop, 0, 0, 1.0, nil );
			self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectRest, "fx/loop", nil, false, -1 );
			self.m_Btnclose:EnableWnd( true );
		end
	end
	self.m_pRenderObject:SetNodeAni( "stand", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, self.pListener );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectRest, "fx/loop", nil, false, 0 );
	self.m_tickPro:Start( 100 );
end

function CWndCollectPro:OnTick()
	local nCurPos = self.m_Pro:GetPos();
	local nEndPos = nCurPos + 1;
	if nEndPos > self.m_nEndCount then
		self.m_Pro:SetPos( self.m_nEndCount );
		self.m_tickPro:Stop();
	end
	self.m_Pro:SetPos( nCurPos );
end

function CWndCollectPro:OnHide()
	self:ShowWnd( false );
end

function CWndCollectPro:OnWndShow( bShow )
	if not bShow then
		g_RederObjectPro = nil;
		g_szEffectRestPro = nil;
		g_ListenerPro = nil;
		g_BtnClose = nil;
		g_App:DestroyRenderObject( self.m_pRenderObject );
		self.m_pRenderObject = nil;
	end
end







--endregion
