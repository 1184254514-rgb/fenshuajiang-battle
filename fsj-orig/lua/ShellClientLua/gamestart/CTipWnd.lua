--region CTipWnd.lua
--Date	2018/3/26
--此文件由[BabeLua]插件自动生成

function CTipWnd:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CTipWnd:OnCreated()
	self.m_pWndTitle = self:GetDlgChild( "title" );
	self.m_pWndContent = self:GetDlgChild( "neirong" );
	self.m_pWndContent:SetInertiaType( eInertiaType_VScroll );
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pBtnClose:AddActionListener( "OnClickClose", self );
end

function CTipWnd:OnDestroy()
	
	CGWnd.OnDestroy( self );
end

function CTipWnd:OnClickClose()
	self:ShowWnd( false );
end

function CTipWnd:ShowTipWnd( nType )
	local szTitle, szContent;
	self.m_pWndContent:SetScrollVerticalPos( 0 );
	if nType == eShowTipType_Skill then
		szTitle = g_App:GetString( "jinengtitle" );
		szContent = g_App:GetString( "jinengneirong" );
	elseif nType == eShowTipType_LimitSecret then
		szTitle = g_App:GetString( "sirenfangjiantitle" );
		szContent = g_App:GetString( "sirenfangjianneirong" );
	elseif nType == eShowTipType_TeamSecret then
		szTitle = g_App:GetString( "sirenfangjiantitle" );
		szContent = g_App:GetString( "sirenfangjianneirong" );
	elseif nType == eShowTipType_Setting then
		szTitle = g_App:GetString( "yonghuxieyititle" );
		szContent = g_App:GetString( "yonghuxieyineirong" );
	end
	self.m_pWndTitle:SetWndText( szTitle );
	self.m_pWndContent:SetWndText( szContent );
	self:ShowAndSetFocus();
	g_App:GetIniFile():WriteInteger( "Setting", "GameStartTipWnd"..nType, 0 );
	g_App:GetIniFile():Save();
end
--endregion
