--region CWndFusionSuccess.lua
--Date 2017.11.30
--"gui\cfg\fsj_pifu_hecheng2.gui"
--皮肤合成成功界面

function CWndFusionSuccess:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndFusionSuccess:OnCreated()
	self.m_TextName				= self:GetDlgChild( "name" );
	self.m_Model				= self:GetDlgChild( "moxing" );
	self.m_BtnOk				= self:GetDlgChild( "b_ok" );
	self.m_BtnOk:AddActionListener( "OnClose", self );
end

function CWndFusionSuccess:SetData( nFusionID )
	self.m_TextName:SetWndText( g_tblTabFile.fusion[nFusionID].dName );
	if not self.m_pRenderObject then
		self.m_pRenderObject = g_App:CreateRenderObject();
	end
	self.m_pRenderObject:OnEquipUpdated( nFusionID, 0, true, false );

	local pair = SFramePair:new();
	self.m_pRenderObject:SetNodeAni( "stand", nil, 
		pair, eAPT_Loop, 0, 0, 1.0, nil );
	local pViewportRenderer = self.m_Model:GetViewportRenderer();
	pViewportRenderer:AddChild( self.m_pRenderObject );
	local Camera = pViewportRenderer:GetCamera();
	Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
	Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
	Camera:SetDest( CVector3f:new( 0, 25, 0 ) );

	self:ShowAndSetFocus();
end

function CWndFusionSuccess:OnClose()
	self:ShowWnd( false )
end



--endregion
