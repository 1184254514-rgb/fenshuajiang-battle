--region CRhythmNoticeBarItem.lua
--Date 2017.10.28
--节奏提示器购买Item

function CRhythmNoticeBarItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );	
end

function CRhythmNoticeBarItem:OnCreated()
	self.m_wndName		= self:GetDlgChild( "W_pifubiaoti" );
	self.m_wndUse		= self:GetDlgChild( "B_shiyong" );
	self.m_wndPrice		= self:GetDlgChild( "B_jinbi.W_jiage");
	self.m_wndBuy		= self:GetDlgChild( "B_jinbi" );
	self.m_ImgGold		= self:GetDlgChild( "B_jinbi.jinbi" );
	self.m_ImgRainbow	= self:GetDlgChild( "B_jinbi.fenxiangbi" );	
	self.m_wndDetail	= self:GetDlgChild( "W_pifu" );

	self.m_wndHide1		= self:GetDlgChild( "W_gouxuan" );
	self.m_wndHide4		= self:GetDlgChild( "B_duihuan" );
	self.m_wndDesc		= self:GetDlgChild( "wenzi" );

	self.m_wndBuy:AddActionListener( "OnClickPrice", self );
	self.m_wndUse:AddActionListener( "OnClickUse", self );
	self.m_wndDetail:AddEventListener( GM_WM_MOUSECLICK, "OnPlayEffect", self );
	self.m_wndHide1:ShowWnd( false );
	self.m_wndHide4:ShowWnd( false );
	self.m_ImgGold:ShowWnd( false );
	self.m_ImgRainbow:ShowWnd( false );
	self.m_wndDesc:ShowWnd( false );
	self.m_wndBuyRhythmNoticeBar = CWndBuyRhythmNoticeBar:new( "gui/cfg/fsj_pifu_goumai2.gui", self:GetParent():GetParent(), 1 );
	g_App.m_EventDispatcher:AddEventListener( "AnswerBuyRhythmNoticeBar", "OnAnswerBuyRhythmNoticeBar", self );
end

function CRhythmNoticeBarItem:OnDestroy()
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerBuyRhythmNoticeBar", "OnAnswerBuyRhythmNoticeBar", self );
	CGWnd.OnDestroy( self );
end

function CRhythmNoticeBarItem:SetDataByIndex( nSortIndex, bInit, bSelf )
	if nSortIndex > g_tblTabFile.jiezoutishiqi.nRowCount then
		return;
	end
	local nIndex = nSortIndex;
	if not bSelf then
		for i = 1, g_tblTabFile.jiezoutishiqi.nRowCount do
			local nSort = g_tblTabFile.jiezoutishiqi[i].nSort;
			if nSort == nSortIndex then
				nIndex = g_tblTabFile.jiezoutishiqi[i].nID;
			end
		end
	end

	self.m_nIndex		= nIndex;
	self.m_szName		= g_tblTabFile.jiezoutishiqi[nIndex].dName;
	self.m_nPrice		= g_tblTabFile.jiezoutishiqi[nIndex].nPrice;
	self.m_szEffectPath	= g_tblTabFile.jiezoutishiqi[nIndex].sEffectFileName;
	self.m_nPayIndex	= g_tblTabFile.jiezoutishiqi[nIndex].nPayIndex;
	self.m_nAcquireType	= g_tblTabFile.jiezoutishiqi[nIndex].nAcquire;
	self.m_wndName:SetWndText( self.m_szName );
	self.m_wndPrice:SetWndText( self.m_nPrice );

	if self:IsHave( nIndex ) then
		if not self:IsUsing( nIndex ) then
			self.m_wndUse:ShowWnd( true );
			self.m_wndHide1:ShowWnd( false );
		else
			self.m_wndUse:ShowWnd( false );
			self.m_wndHide1:ShowWnd( true );
		end
		self.m_wndBuy:ShowWnd( false );
	else
		if self.m_nAcquireType == eAcquireType_Buy then
			self.m_wndBuy:ShowWnd( true );
			self.m_wndUse:ShowWnd( false );
			self.m_ImgGold:ShowWnd( self.m_nPayIndex == eResourceType_Gold );
			self.m_ImgRainbow:ShowWnd( self.m_nPayIndex == eResourceType_RainbowGold );
		end
	end

	if bInit then
		self.m_wndDetail:AddEffect( self.m_szEffectPath, "fx/loop", "jiezoutiaodong", -1 );	
	end
end

function CRhythmNoticeBarItem:OnClicksignaturePrize()
	g_App:HideMsg( g_App:GetString( "qiandaojianglitips" ) );
end

function CRhythmNoticeBarItem:OnPlayEffect()	
--	self.m_wndDetail:AddEffect( self.m_szEffectPath, "fx/loop", "jiezoutiaodong", -1 );
end

function CRhythmNoticeBarItem:OnClickPrice()
	self.m_wndBuyRhythmNoticeBar:SetDataByIndex( self.m_nIndex );
end

function CRhythmNoticeBarItem:OnClickUse()
	local NetMsg = CUseRhythmNoticeBar:new();
	NetMsg.m_nIndex = self.m_nIndex;
	g_App:SendShellMsg( NetMsg );
end

function CRhythmNoticeBarItem:OnUpdate()
	if not self.m_nIndex then 
		return 
	end
	self:SetDataByIndex( self.m_nIndex, false, true );
end

function CRhythmNoticeBarItem:IsHave( nIndex )
	local PlayerData = g_App:GetMainPlayerData().m_RhythmNoticeBar;
	for i = 1, PlayerData:GetDataCount() do
		if PlayerData:GetData( i - 1 ) == nIndex then
			return true;
		end
	end
	return false;
end

function CRhythmNoticeBarItem:IsUsing( nIndex )
	return nIndex == g_App:GetMainPlayerData().m_CharBaseData:GetCurRhythmNoticeBarID();
end

function CRhythmNoticeBarItem:OnAnswerBuyRhythmNoticeBar()
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerBuyRhythmNoticeBar", "OnAnswerBuyRhythmNoticeBar", self );
	self.m_wndBuyRhythmNoticeBar:ShowWnd( false );
end

--endregion
