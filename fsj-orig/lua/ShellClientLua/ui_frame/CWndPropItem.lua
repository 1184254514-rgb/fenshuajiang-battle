--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndPropItem:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndPropItem:OnCreated()
	self.m_pWndIcon = CRichIconWnd:new( self, "icon.tietu" );
	self.m_pWndCount = self:GetDlgChild( "shuliang" );

	self:UpdateWnd();
end

function CWndPropItem:SetProp( nType, nTypeIndex, nCount )
	self.m_nType = tonumber( nType );
	self.m_nTypeIndex = tonumber( nTypeIndex );
	self.m_nCount = tonumber( nCount );

	if not self:IsCreated() then
		return;
	end
	self:UpdateWnd();
end

function CWndPropItem:UpdateWnd()
	if not self.m_nType then
		return;
	end
	local tblConfig = CPropBaseConfigMgr:Inst():GetConfig( self.m_nType, self.m_nTypeIndex );
	self.m_pWndIcon:SetIconID( tblConfig.nIconID );
	self.m_pWndCount:SetWndText( tostring( self.m_nCount ) );
end

--endregion
