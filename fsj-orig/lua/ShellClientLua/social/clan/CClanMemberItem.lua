--region CClanMemberItem.lua
--Date 2018.03.14
--家族成员Item

function CClanMemberItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CClanMemberItem:OnCreated()
	self.m_WndStatus		=	self:GetDlgChild( "zhuangtai" );
	self.m_HeadIcon			=	self:GetDlgChild( "icon.touxiang" );
	self.m_WndWeekActivity	=	self:GetDlgChild( "huoyuedu" );
	self.m_WndName			=	self:GetDlgChild( "name" );
	self.m_WndPower			=	self:GetDlgChild( "shenfen" );
	self.m_WndLadderName	=	self:GetDlgChild( "duanwei.W_duanwei" );
	self.m_tblLadderIcon	=	{};
	for i = 1, 8 do
		local wnd			=	self:GetDlgChild( "duanwei.icon_duanwei." .. i );
		table.insert( self.m_tblLadderIcon, wnd );	
	end
	self:AddActionListener( "OnShowOpr", self );
end

function CClanMemberItem:SetData( tblMemberInfo )
	self.m_nAccountID = tblMemberInfo.nAccountID;
	local bIsSelf = g_App:GetAccountID() == self.m_nAccountID;
	local nColor = bIsSelf and 0xffffffff or 0xfffee0ab;
	for i = eST_ENABLE, eST_CLICKDOWN do
		self:SetImageColor( GSM_BS_BK, i, -1, nColor )
	end
	CHeadIconConfig:Inst():SetIcon( self.m_HeadIcon, tblMemberInfo.nCurHeadIcon + 1, self.m_nAccountID );
	self.m_WndName:SetWndText( tblMemberInfo.szCharName );
	self.m_WndWeekActivity:SetWndText( tblMemberInfo.nWeekActivity );
	local tblPowerString = {
							[0] = g_App:GetString( "zuyuan" ), 
							[1] = g_App:GetString( "fuzuzhang" ), 
							[2] = g_App:GetString( "zuzhang" ) };
	self.m_WndPower:SetWndText( tblPowerString[tblMemberInfo.nPower] );
	local STime = GetFormatTimeSTMFromMillisecond( tblMemberInfo.nLogoutTime * 1000 );
	local szTime = string.format( "%4d/%02d/%02d", STime:m_nYear(), STime:m_nMonth(), STime:m_nDayOfMonth() );
	local tblStatusString = {
							[0] = g_App:GetString( "zuihoushangxianriqi" ) .. "\n" .. szTime ,
							[1] = g_App:GetString( "online" ),
							[2] = g_App:GetString( "zuduizhong" ),
							[3] = g_App:GetString( "youxizhong" ),
							[4] = g_App:GetString( "guanzhanzhong" ) };
	self.m_WndStatus:SetWndText( tblStatusString[tblMemberInfo.nState] );
	local szLadderName = CStarLevelConfig.Inst():GetName( tblMemberInfo.nCurLadderStar );
	local nLadderLevel = CStarLevelConfig.Inst():GetBigLevel( tblMemberInfo.nCurLadderStar );
	self.m_WndLadderName:SetWndText( szLadderName );
	for i = 1, 8 do
		self.m_tblLadderIcon[i]:ShowWnd( i == nLadderLevel );
	end
end

function CClanMemberItem:OnShowOpr( Event )
	if self.m_nAccountID == g_App:GetAccountID() then
		return;				--当前Item为自己
	end

	local WndOpr = g_App:GetGameStart().m_WndClanMemberOpr;

	local nSelfPower = g_App:GetGameStart().m_WndClan.m_nPower;		--自己的权限
	local nItemPower = g_App:GetGameStart().m_WndClan:GetAccountAccess( self.m_nAccountID );	--当前Item所代表的玩家权限 
	if nSelfPower == eClan_Member then
		g_App:ShowPlayerInfo( self.m_nAccountID );
	elseif nSelfPower == eClan_Vice_Leader then
		if nItemPower == eClan_Leader then
			g_App:ShowPlayerInfo( self.m_nAccountID );
		end
	elseif nSelfPower == eClan_Leader then
		if nItemPower == eClan_Vice_Leader then
			WndOpr = g_App:GetGameStart().m_WndClanMemberOpr1;
		elseif nItemPower == eClan_Member then
			WndOpr = g_App:GetGameStart().m_WndClanMemberOpr;
		end
	end

	WndOpr:SetGlobalX( self:GetGlobalX() + self:GetWndWidth() - WndOpr:GetWndWidth() );
	WndOpr:SetGlobalY( self:GetGlobalY() - 80 );
	WndOpr:ShowOperateWnd( self.m_nAccountID, nItemPower );
end

--endregion
