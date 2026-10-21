--region CWndBuyRhythmNoticeBar.lua
--Date 2017.10.30
--节奏提示器购买界面

function CWndBuyRhythmNoticeBar:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndBuyRhythmNoticeBar:OnCreated()
	self.m_wndDetail		= self:GetDlgChild( "W_pifu" );
	self.m_wndOk			= self:GetDlgChild( "B_queren.B_queren" );
	self.m_wndCancel		= self:GetDlgChild( "B_queren.B_quxiao" );
	self.m_wndName			= self:GetDlgChild( "W_pifubiaoti" );

	self.m_wndOk:AddActionListener( "OnOk", self );
	self.m_wndCancel:AddActionListener( "OnCancel", self );
end

function CWndBuyRhythmNoticeBar:SetDataByIndex( nIndex )
	self:ShowAndSetFocus();
	self.m_nIndex = nIndex;
	self.m_szName		= g_tblTabFile.jiezoutishiqi[nIndex].dName;
	self.m_nPrice		= g_tblTabFile.jiezoutishiqi[nIndex].nPrice;
	self.m_szEffectPath	= g_tblTabFile.jiezoutishiqi[nIndex].sEffectFileName;
	self.m_wndName:SetWndText( self.m_szName );
	self.m_wndDetail:AddEffect( self.m_szEffectPath, "fx/loop", "jiezoutiaodong", -1 );
end

function CWndBuyRhythmNoticeBar:OnCancel()
	self:ShowWnd( false );
end

function CWndBuyRhythmNoticeBar:OnOk()
	self:ShowWnd( false );
	local NetMsg = CBuyRhythmNoticeBar:new();
	NetMsg.m_nIndex		= self.m_nIndex;
	g_App:SendShellMsg( NetMsg );
end 



--endregion
