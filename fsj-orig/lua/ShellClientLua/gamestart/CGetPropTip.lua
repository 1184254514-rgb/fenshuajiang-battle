--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CGetPropTip:Ctor( wndParent, tblProp )
	CGWnd.Ctor( self, "gui/cfg/fsj_huodeprop.gui", wndParent, 0 );
	self.m_tblProp = tblProp;
end

function CGetPropTip:OnCreated()
	self.m_pWndIcon = CRichIconWnd:new( self, "tietu" );
	self.m_pWndCount = self:GetDlgChild( "shuliang" );
	self.m_pButton = self:GetDlgChild( "btn_jixu" );

	local nIconID = CPropBaseConfigMgr:Inst():GetConfig( self.m_tblProp.nType, self.m_tblProp.nIndex ).nIconID;
	self.m_pWndIcon:SetIconID( nIconID );
	self.m_pWndCount:SetWndText( tostring( self.m_tblProp.nCount ) );

	self.m_pButton:AddClickListener( "OnClick", self );
	self:SetFocus();
end

function CGetPropTip:OnClick( Event )
	Event.m_StopImmediately = true;
	self:DestroyWnd();
end

--endregion
