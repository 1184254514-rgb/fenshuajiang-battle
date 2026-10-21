--region CWndTreasureBoxOpretionTips.lua
--Date 2017.12.08
--宝箱操作提示界面
--gui\cfg\fsj_pifu_baoxiangtips.gui

function CWndTreasureBoxOpretionTips:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndTreasureBoxOpretionTips:OnCreated()
	self.m_TextTips = self:GetDlgChild( "W_shuoming" );
	self.m_TextOk = self:GetDlgChild( "W_buttons.b_ok" );
	self.m_TextCancel = self:GetDlgChild( "W_buttons.b_close" );

	self.m_TextOk:AddActionListener( "OnClickOk", self );
	self.m_TextCancel:AddActionListener( "OnClickCancel", self );
end

function CWndTreasureBoxOpretionTips:ShowDetail( szTips, nTreasureBoxID, nTreasureBoxGetTime, nUnlockTime, nPosIndex )
	self.m_nTreasureBoxID = nTreasureBoxID;
	self.m_nTreasureBoxGetTime = nTreasureBoxGetTime;
	self.m_nPosIndex = nPosIndex;
	local szCancel = g_App:GetString( "jiesuobaoxiangtips2" );
	self.m_TextCancel:SetWndText( szCancel );
	self.m_TextTips:SetWndText( szTips );
	local nTimeNeed = g_tblTabFile.treasureboxbase[nTreasureBoxID].nTime;
	local nTimeRemain = nTimeNeed;
	if nUnlockTime then
		nTimeRemain = nTimeNeed - ( math.floor( (GetNatureTime()/1000 + 0.5 ) ) - nUnlockTime );
	end
	local nPayIndex = g_tblTabFile.treasureboxbase[nTreasureBoxID].nConsumeIndex;
	local nPayCount = CTreasureBoxOpenConsume:Inst():GetConsumeCount( nTimeRemain, nPayIndex );
	self.m_TextOk:SetWndText( nPayCount );
	self:ShowWnd( true );
end

function CWndTreasureBoxOpretionTips:OnClickOk()
	local NetMsg = COpenTreasureBox:new();
	NetMsg.m_nTreasureBoxID = self.m_nTreasureBoxID;
	NetMsg.m_nGetTime = self.m_nTreasureBoxGetTime;
	NetMsg.m_nPosIndex = self.m_nPosIndex;
	g_App:SendShellMsg( NetMsg );
	self:ShowWnd( false );
end

function CWndTreasureBoxOpretionTips:OnClickCancel()
	self:ShowWnd( false );
end


--endregion
