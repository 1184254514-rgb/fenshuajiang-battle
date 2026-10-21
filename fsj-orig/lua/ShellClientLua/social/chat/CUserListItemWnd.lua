--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

eLadderBigLevelCount = 8;
local s_tblStateName = { "offline", "online", "ingame" };

function CUserListItemWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_nUnReadNum = 0;
	self.m_CharInfo = nil;
end

function CUserListItemWnd:OnCreated()
	self.m_pWndStatus = self:GetDlgChild( "zhuangtai" );
	self.m_pWndName = self:GetDlgChild( "name" );
	self.m_pWndIcon = self:GetDlgChild( "icon" );
	self.m_pWndHead = self:GetDlgChild( "head.touxiang" );
	self.m_pWndStar = self:GetDlgChild( "duanwei" );
	if not self.m_CharInfo then
		return;
	end
	self:UpdateItem( self.m_CharInfo )
end

function CUserListItemWnd:OnDestroy()
end

function CUserListItemWnd:GetAccountID()
	return self.m_CharInfo and self.m_CharInfo.nAccountID;
end

function CUserListItemWnd:UpdateItem( CharInfo )
	-- CharInfo.nAccountID;
	-- CharInfo.nCurHeadIcon;
	-- CharInfo.szCharName;
	-- CharInfo.nState;
	-- CharInfo.nCurLadderStar;
	self.m_CharInfo = CharInfo;
	if( not self:IsCreated() ) then
		return;
	end

	self.m_nUnReadNum = g_App:GetInstantMessageDataMgr():
		GetAccountUnReadCount( self.m_CharInfo.nAccountID );
	self:ShowRedPoint( self.m_nUnReadNum > 0 );

	self.m_pWndName:ShowWnd( true );
	self.m_pWndName:SetWndText( self.m_CharInfo.szCharName );

	self.m_pWndHead:ShowWnd( true );
	CHeadIconConfig:Inst():SetIcon( self.m_pWndHead, self.m_CharInfo.nCurHeadIcon + 1, CharInfo.nAccountID );

	local cfgLevel = CStarLevelConfig:Inst();

	if self:GetAccountID() > 0 then
		self.m_pWndIcon:ShowWnd( true );
		local nBigLevel = cfgLevel:GetBigLevel( self.m_CharInfo.nCurLadderStar );
		for i = 1, eLadderBigLevelCount do -- 循环一下，判断哪个图标要显示
			self.m_pWndIcon:GetDlgChild( tostring( i ) ):ShowWnd( i == nBigLevel );
		end

		self.m_pWndStar:ShowWnd( true );
		self.m_pWndStar:SetWndText( cfgLevel:GetName( self.m_CharInfo.nCurLadderStar ) );

		self.m_pWndStatus:ShowWnd( true );
		local nLenStatus = #s_tblStateName;
		for i = 1, nLenStatus do
			local wndStatus = self.m_pWndStatus:GetDlgChild( s_tblStateName[i] );
			wndStatus:ShowWnd( i == math.min( CharInfo.nState + 1, 3 ) )
		end
	else
		self.m_pWndIcon:ShowWnd( false );
		self.m_pWndStar:ShowWnd( false );
		self.m_pWndStatus:ShowWnd( false );
	end
end

function CUserListItemWnd:OnSelect()
	self.m_nUnReadNum = 0;
	self:ShowRedPoint( false );
	g_App:GetInstantMessageDataMgr():ClearAccountUnReadCount( self.m_CharInfo.nAccountID );
end


--endregion
