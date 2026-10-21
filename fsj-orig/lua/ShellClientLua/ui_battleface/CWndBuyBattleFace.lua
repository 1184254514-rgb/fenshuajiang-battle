--region CWndBuyBattleFace.lua
--Date 2017.11.10

function CWndBuyBattleFace:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType );
end

function CWndBuyBattleFace:OnCreated()
	self.m_wndDetail		= self:GetDlgChild( "W_pifu" );
	self.m_wndOk			= self:GetDlgChild( "B_queren.B_queren" );
	self.m_wndCancel		= self:GetDlgChild( "B_queren.B_quxiao" );
	self.m_wndName			= self:GetDlgChild( "W_pifubiaoti" );

	self.m_wndOk:AddActionListener( "OnOk", self );
	self.m_wndCancel:AddActionListener( "OnCancel", self );
end

function CWndBuyBattleFace:SetDataByIndex( nIndex )
	self:ShowAndSetFocus();
	self.m_nIndex = nIndex;
	self.m_szName		= g_tblTabFile.battleface[nIndex].dName;
	self.m_nPrice		= g_tblTabFile.battleface[nIndex].nPrice;
	self.m_szEffectPath	= g_tblTabFile.battleface[nIndex].szEffectFilePath;

	self.m_wndName:SetWndText( self.m_szName );
	self.m_wndDetail:AddEffect( self.m_szEffectPath, "fx/loop", nil, -1 );
end

function CWndBuyBattleFace:OnCancel()
	self:ShowWnd( false );
end

function CWndBuyBattleFace:OnOk()
	self:ShowWnd( false );
	local NetMsg = CBuyBattleFace:new();
	NetMsg.m_nIndex		= self.m_nIndex;
	g_App:SendShellMsg( NetMsg );
end 

--endregion
