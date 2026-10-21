--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CWndShop:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );

	self.m_tblCheckButton = {};
end

function CWndShop:OnCreated()
	self.m_pWndList = self:GetDlgChild( "list" );
	self.m_pWndDiamond = self:GetDlgChild( "zuanshi.jinbishuliang" );
	self.m_pWndPresentDiamond = self:GetDlgChild( "zengsongzuanshi.jinbishuliang" );

	self.m_tblCheckButton = 
	{
		[self:GetDlgChild( "btn_shang.btn1" )] = CWndShopDiamond:new( "gui/cfg/fsj_chongzhi_zuanshi.gui", self.m_pWndList, 2 );
	};

	local nIndex = 0;
	for pBtn,pWnd in pairs( self.m_tblCheckButton ) do
		pBtn:AddClickListener( "OnClick", self );
		pWnd:ShowWnd( nIndex == 0 );
		pBtn:SetCheck( nIndex == 0 );
		nIndex = nIndex + 1;
	end

	self:AddCloseAction( "close" );
	g_App:GetMainPlayerData():AddEventListener( "m_Resource", "RefreshWnd", self );
end

function CWndShop:OnDestroy()
	g_App:GetMainPlayerData():RemoveEventListener( "m_Resource", "RefreshWnd", self );
end

function CWndShop:OnWndShow( bShow )
	if bShow then
		self:RefreshWnd();
	end
end

function CWndShop:RefreshWnd()
	self.m_pWndDiamond:SetWndText( tostring( g_App:GetPropCount( eGRT_Resource, eResourceType_Diamond ) ) );
	self.m_pWndPresentDiamond:SetWndText( tostring( g_App:GetPropCount( eGRT_Resource, eResourceType_PresentDiamond ) ) );
end

function CWndShop:OnClick( Event )
	local pButton = Event.m_Target;
	for pBtn,pWnd in pairs( self.m_tblCheckButton ) do
		pWnd:ShowWnd( pButton == pBtn );
	end
end

--endregion
