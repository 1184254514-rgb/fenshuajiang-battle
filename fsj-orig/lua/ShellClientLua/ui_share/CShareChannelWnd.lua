--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CShareChannelWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );

	self:ShowWnd( false );
end

function CShareChannelWnd:OnCreated()
	self.m_pWndClose = self:GetDlgChild( "close" );
	self.m_pWndQQ = self:GetDlgChild( "qq" );
	self.m_pWndQQSpace = self:GetDlgChild( "qqspace" );
	self.m_pWndWeiXin = self:GetDlgChild( "weixin" );
	self.m_pWndWeiXinTimeline = self:GetDlgChild( "weixintimeline" );

	self.m_pWndClose:AddActionListener( "OnClickClose", self );
	self.m_pWndQQ:AddActionListener( "OnClickQQ", self );
	self.m_pWndQQSpace:AddActionListener( "OnClickQQSpace", self );
	self.m_pWndWeiXin:AddActionListener( "OnClickWeiXin", self );
	self.m_pWndWeiXinTimeline:AddActionListener( "OnClickWeiXinTimeline", self );
end

function CShareChannelWnd:SetSDK( pShareContext )
	self.m_pShareContext = pShareContext;
end

function CShareChannelWnd:OnClickClose()
	self:ShowWnd( false );
end

function CShareChannelWnd:OnClickQQ()
	self:ShowWnd( false );
	self.m_pShareContext:ShareQQ();
end

function CShareChannelWnd:OnClickQQSpace()
	self:ShowWnd( false );
	self.m_pShareContext:ShareQQSpace();
end

function CShareChannelWnd:OnClickWeiXin()
	self:ShowWnd( false );
	self.m_pShareContext:ShareWeiXin();
end

function CShareChannelWnd:OnClickWeiXinTimeline()
	self:ShowWnd( false );
	self.m_pShareContext:ShareWeiXinTimeline();
end


--endregion
