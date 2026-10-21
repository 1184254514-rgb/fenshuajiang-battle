--region CWndBattleFaceItem.lua
--Date 2017.11.09
--战斗表情Item 

local eBattleFaceType = {
			eCommon				= 1,
			eSignaturePrize		= 2,
	} 

function CWndBattleFaceItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndBattleFaceItem:OnCreated()
	self.m_WndUse				= self:GetDlgChild( "shiyong" );
	self.m_BtnUse				= self:GetDlgChild( "shiyong.check" );
	self.m_WndBattleFace		= self:GetDlgChild( "W_pifu" );
	self.m_WndGet				= self:GetDlgChild( "B_huode" );
	self.m_WndPrice				= self:GetDlgChild( "B_huode.W_jiage" );
	self.m_ImgGold				= self:GetDlgChild( "B_huode.jinbi" );
	self.m_ImgRainbow			= self:GetDlgChild( "B_huode.fenxiangbi" );
	self.m_BtnSignaturePrize	= self:GetDlgChild( "B_teshu" );
	self.m_ImgGold:ShowWnd( false );
	self.m_ImgRainbow:ShowWnd( false );
	self.m_WndName				= self:GetDlgChild( "W_pifubiaoti" );
	self.m_wndBuyBattleFace		= CWndBuyBattleFace:new( "gui/cfg/fsj_pifu_goumai2.gui", self:GetParent():GetParent():GetParent(), 1 );
	
	self.m_WndGet:AddActionListener( "OnClickPrice", self );
	self.m_BtnUse:AddActionListener( "OnClickUse", self );
	self.m_BtnSignaturePrize:AddActionListener( "OnClickSignaturePrize", self );
	self.m_WndUse:ShowWnd( false ); 
	self.m_WndGet:ShowWnd( false );
	self.m_BtnSignaturePrize:ShowWnd( false );	
end

function CWndBattleFaceItem:SetFaceData( nIndex, bInit )
	if not nIndex then return end;
	if not g_tblTabFile.battleface[nIndex] then
		return;
	end

	self.m_szFaceName			= g_tblTabFile.battleface[nIndex].dName;
	self.m_szFaceEffectPath		= g_tblTabFile.battleface[nIndex].szEffectFilePath;
	self.m_nKind				= g_tblTabFile.battleface[nIndex].nKind;
	self.m_nPayType				= g_tblTabFile.battleface[nIndex].nPayType;
	self.m_nPayIndex			= g_tblTabFile.battleface[nIndex].nPayIndex;
	self.m_nPrice				= g_tblTabFile.battleface[nIndex].nPrice;
	self.m_nAcquireType			= g_tblTabFile.battleface[nIndex].nAcquire;
	self.m_nIndex				= nIndex;

	self.m_WndName:SetWndText( self.m_szFaceName );
	self.m_WndPrice:SetWndText( self.m_nPrice );

	if self:IsHave( nIndex ) then
		if self:IsUsing( nIndex ) then
			self.m_BtnUse:SetCheck( true );
		else
			self.m_BtnUse:SetCheck( false );
		end
		self.m_WndUse:ShowWnd( true );
		self.m_WndGet:ShowWnd( false );
		self.m_BtnSignaturePrize:ShowWnd( false );
	else
		if self.m_nAcquireType == eAcquireType_Buy then
			self.m_WndGet:ShowWnd( true );
			self.m_WndUse:ShowWnd( false );
			self.m_ImgGold:ShowWnd( self.m_nPayIndex == eResourceType_Gold );
			self.m_ImgRainbow:ShowWnd( self.m_nPayIndex == eResourceType_RainbowGold );
		else
			self.m_BtnSignaturePrize:ShowWnd( true );
			self.m_BtnSignaturePrize:SetWndText( g_App:GetString( "qiandaojiangli" ) );
		end
	end

	if bInit then
		self.m_WndBattleFace:AddEffect( self.m_szFaceEffectPath, "fx/loop", nil, -1 );
	end
end

function CWndBattleFaceItem:OnClickSignaturePrize()
	g_App:HideMsg( g_App:GetString( "qiandaojianglitips" ) );
end

function CWndBattleFaceItem:OnUpdate()
	if not self.m_nIndex then 
		return 
	end
	self:SetFaceData( self.m_nIndex );
end

function CWndBattleFaceItem:OnClickPrice()
	self.m_wndBuyBattleFace:SetDataByIndex( self.m_nIndex )
end

function CWndBattleFaceItem:IsHave( nIndex )
	local PlayerData = g_App:GetMainPlayerData().m_BattleFaceData;
	for i = 1, PlayerData:GetDataCount() do
		local BattleFaceData = PlayerData:GetData( i - 1 );
		local nBattleFaceIndex = BattleFaceData:GetBattleFaceID();
		if nBattleFaceIndex == nIndex then
			return true;
		end
	end
	return false;
end

function CWndBattleFaceItem:IsUsing( nIndex )
	local PlayerData = g_App:GetMainPlayerData().m_BattleFaceData;
	for i = 1, PlayerData:GetDataCount() do
		local BattleFaceData = PlayerData:GetData( i - 1 );
		local nBattleFaceIndex = BattleFaceData:GetBattleFaceID();
		if nBattleFaceIndex == nIndex then
			return BattleFaceData:GetUsed() == 1 ;
		end
	end
	return false;
end

function CWndBattleFaceItem:OnClickUse()
	local NetMsg = CUseBattleFace:new();
	NetMsg.m_nIndex = self.m_nIndex;
	NetMsg.m_nType = self.m_nKind;
	NetMsg.m_bUsed = self:IsUsing( self.m_nIndex ) and 0 or 1;
	g_App:SendShellMsg( NetMsg );
end

--endregion
