function CShareWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CShareWnd:OnCreated()
	self.m_pWndLink = self:GetDlgChild( "bg_lianjie3" );
	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_pBtnClose:AddActionListener( "OnClickClose", self );
	self.m_pBtnShare = self:GetDlgChild( "B_fenxiang" );
	self.m_pBtnShare:AddActionListener( "OnClickShare", self );
	self.m_pBtnClipboard = self:GetDlgChild( "B_fuzhilianjie" );
	self.m_pBtnClipboard:AddActionListener( "OnClickCopy" , self );
	self.m_pWndContent = self:GetDlgChild( "E_neirong" );

	self.m_pWndGoldDay = self:GetDlgChild( "E_jinri" );
	self.m_pWndGoldHistory = self:GetDlgChild( "E_jilei" );

	self.m_pWndGoldDay:SetWndText("0");
	self.m_pWndGoldHistory:SetWndText("0");
	
	self.m_pShareChannelWnd = CShareChannelWnd:new("gui/cfg/fsj_fenxianglianjie.gui", self, 2 );
	self.m_pShareChannelWnd:SetSDK( g_App:CreatePageShare( g_App:GetString( "zhujiemian" ) ) );

	g_App.m_EventDispatcher:AddEventListener( "UpdateRainbowGold", "OnUpdateRainbowGold", self );
end

function CShareWnd:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "UpdateRainbowGold", "OnUpdateRainbowGold", self );
	CGWnd.OnDestroy( self );
end

function CShareWnd:OnUpdateRainbowGold( Event )
	self.m_pWndGoldDay:SetWndText(tostring(Event.RainbowGoldDay));
	self.m_pWndGoldHistory:SetWndText(tostring(Event.RainbowGoldHistory));
end

function CShareWnd:OnWndShow( bShow )
	if not bShow then
		return;
	end

	self.m_pWndContent:SetWndText( CStringConfig.Inst():GetString( "fenxiangneirong" ) );
	self.m_pWndLink:SetWndText( tostring( g_App:GetSharePageUrl()) );

	local NetMsg = CQueryRainbowGold:new();
	g_App:SendShellMsg( NetMsg );
end

function CShareWnd:OnClickClose()
	self:ShowWnd( false );
end

function CShareWnd:OnClickShare()
	self.m_pShareChannelWnd:ShowWnd( true );
end

function CShareWnd:OnClickCopy()
	g_App:MessageBox( g_App:GetString( "fuzhilianjie" ) );
	local lianjiejieshao = g_App:GetString( "lianjiejieshao");
	g_App:SetClipboardString( lianjiejieshao .. g_App:GetSharePageUrl() );
end