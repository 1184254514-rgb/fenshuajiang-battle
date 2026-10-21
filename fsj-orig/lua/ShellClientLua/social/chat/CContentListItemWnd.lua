--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CContentListItemWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CContentListItemWnd:OnCreated()
	self.m_pWndName = self:GetDlgChild( "name" );
	self.m_pWndIcon = self:GetDlgChild( "icon" );
	self.m_pWndHead = self:GetDlgChild( "head" );
	self.m_pWndHeadIcon = self:GetDlgChild( "head.touxiang" );
	self.m_pWndStar = self:GetDlgChild( "duanwei" );
	self.m_pWndContent = self:GetDlgChild( "neirong" );
	self.m_xStart = self.m_pWndContent:GetLocalX();
	self.m_yStart = self.m_pWndContent:GetLocalY();
	self.m_fWidth = self.m_pWndContent:GetWndWidth();
	self:AddClickListener( "OnClickItem", self );
end

function CContentListItemWnd:GetAccountID()
	return self.m_ContentData and self.m_ContentData.nAccountID;
end

function CContentListItemWnd:IsSelfItem()
	local nAccountID = self:GetAccountID();
	return nAccountID and nAccountID == g_App:GetAccountID();
end

function CContentListItemWnd:UpdateItem( ContentData )
	-- ContentData.nAccountID;
	-- ContentData.nCreateTime;
	-- ContentData.szContent;
	self.m_ContentData = ContentData;
	if( not self:IsCreated() ) then
		return;
	end
	
	local FriendMgr = CFriendMgr:Inst();
	local CharInfo = FriendMgr:GetCharInfo( ContentData.nAccountID )
	self.m_pWndName:ShowWnd( true );
	self.m_pWndName:SetWndText( CharInfo.szCharName );

	self.m_pWndHead:ShowWnd( true );
	CHeadIconConfig:Inst():SetIcon( self.m_pWndHeadIcon, CharInfo.nCurHeadIcon + 1, ContentData.nAccountID );

	local cfgLevel = CStarLevelConfig:Inst();

	self.m_pWndIcon:ShowWnd( true );
	local nBigLevel = cfgLevel:GetBigLevel( CharInfo.nCurLadderStar );
	for i = 1, eLadderBigLevelCount do -- 循环一下，判断哪个图标要显示
		self.m_pWndIcon:GetDlgChild( tostring( i ) ):ShowWnd( i == nBigLevel );
	end

	self.m_pWndStar:ShowWnd( true );
	self.m_pWndStar:SetWndText( cfgLevel:GetName( CharInfo.nCurLadderStar ) );

	self.m_pWndContent:ShowWnd( true );
	self.m_pWndContent:SetWndSize( self.m_fWidth, 0 );
	self.m_pWndContent:SetWndText( ContentData.szContent );
	local fCurHeight = self.m_pWndContent:GetCurHeight() + 2;

	local xStart = self.m_xStart;
	local fWidth = self.m_pWndContent:GetMaxWidth();
	if BitAnd( self.m_pWndContent:GetLockFlag(), LOCK_LEFT ) == 0 then
		xStart = self.m_xStart + self.m_fWidth - fWidth - 2;
	end

	self.m_pWndContent:SetLocalX( xStart );
	self.m_pWndContent:SetLocalY( self.m_yStart );
	self.m_pWndContent:SetWndSize( fWidth + 2, fCurHeight );

	local wndParent = self:GetParent();
	local nItemIndex = wndParent:GetItemIndex( self );
	wndParent:SetItemHeight( fCurHeight + 96, nItemIndex );
end

function CContentListItemWnd:OnClickItem( Event )
	if self.m_pWndHead == Event.m_Target then
		local CharInfo = CFriendMgr:Inst():GetCharInfo( self.m_ContentData.nAccountID )
		g_App:ShowPlayerInfo( CharInfo.nAccountID );
		return;
	end	

	if self.m_pWndContent == Event.m_Target then
		return;
	end

	local xContent = self.m_pWndContent:GetLocalX();
	local yContent = self.m_pWndContent:GetLocalY() - 15;
	local wContent = self.m_pWndContent:GetWndWidth();
	local hContent = self.m_pWndContent:GetWndHeight() + 30;
	if( Event.x < xContent or Event.x > xContent + wContent or
		Event.y < yContent or Event.y > yContent + hContent ) then
		return;
	end

	local nLinkID = self.m_pWndContent:GetFirstHyperLinkID();
	if not nLinkID or self.m_pWndContent:GetHyperLinkIDString( 2 ) then
		return;
	end
	local nUnitID = self.m_pWndContent:GetRichUnitIDByHypLinkID( nLinkID );
	local strLinkID = self.m_pWndContent:GetHyperLinkIDString( nLinkID );
	g_App.m_CmdMgr:TriggerHyperLink( strLinkID, self, nUnitID );
end

--endregion
