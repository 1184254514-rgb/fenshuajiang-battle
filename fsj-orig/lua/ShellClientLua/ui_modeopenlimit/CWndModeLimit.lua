--region CWndModeLimit.lua
--Date 2017.11.03
--模式未开放提示界面  

function CWndModeLimit:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndModeLimit:OnCreated()
	self.m_BtnHide = self:GetDlgChild( "btn_jixu" );
	self.m_WndLimitMode = self:GetDlgChild( "xianshi" );
	self.m_WndTeamMode = self:GetDlgChild( "tuanzhan" );
	self.m_WndLimitMode:ShowWnd( false );
	self.m_WndTeamMode:ShowWnd( false );

	self.m_Progress = self:GetDlgChild( "jindutiao" );
	self.m_ProText = self:GetDlgChild( "jindutiao.shuzi" );
	self.m_BtnHide:AddActionListener( "OnClickHide", self );
end

function CWndModeLimit:ShowWndByType( nRoomType, nProgress, nTotal )
	if nRoomType == eRT_LimitTime then
		self.m_WndLimitMode:ShowWnd( true );
		self.m_WndTeamMode:ShowWnd( false );
		self.m_ProText:SetWndText( string.format( "%d%%", nProgress/g_GetSceneNodeTotal( eRT_Endless )*100 ));
	elseif nRoomType == eRT_Team then
		self.m_WndLimitMode:ShowWnd( false );
		self.m_WndTeamMode:ShowWnd( true );
		self.m_ProText:SetWndText( nProgress );
	end

	self.m_Progress:SetRange( nTotal );
	self.m_Progress:SetPos( nProgress );

	self:ShowWnd( true );
end

function CWndModeLimit:OnClickHide()
	self:ShowWnd( false );
end



--endregion
