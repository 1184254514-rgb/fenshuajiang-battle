--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CInstantMessageWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_wndParent = ParentWnd;
	self.m_tickWorldMsg = CTick:new( "OnWorldMsgTick", self );
	self.m_nPreWorldMsgTime = 0;
end

function CInstantMessageWnd:OnCreated()
	self.m_checkWorld = self:GetDlgChild( "b_shijie" );
	self.m_checkFriend = self:GetDlgChild( "b_haoyou" );

	self.m_checkWorld:AddEventListener( GM_WM_BTN_CHECKED, "OnShowWorld", self );
	self.m_checkFriend:AddEventListener( GM_WM_BTN_CHECKED, "OnShowFriend", self );

	self.m_editContent = self:GetDlgChild( "duihuakuang" );
	self.m_editContent:SetMaxCharLength( CHAT_MAX_CONTENT_LEN/3 )

	self.m_btnSend = self:GetDlgChild( "b_fasong" );
	self.m_btnSend:AddActionListener( "OnSend", self );
	self.m_wndTimeRemain = self:GetDlgChild( "b_lengque" );

	self.m_btnClose = self:GetDlgChild( "close" );
	self.m_btnClose:AddActionListener( "OnClose", self );

	self.m_wndFriend = CIMFriendWnd:new( "gui/cfg/fsj_liaotian_haoyou.gui", self, 1 );
	self.m_wndWorld = CIMWorldWnd:new( "gui/cfg/fsj_liaotian_shijie.gui", self, 1 );

	self.m_checkWorld:SetCheck( true );
	self.m_wndWorld:ShowWnd( true );

	g_App.m_EventDispatcher:AddEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
end

function CInstantMessageWnd:OnDestroy()	
	g_App.m_EventDispatcher:RemoveEventListener( "WorldMsgCooldown", "OnWorldMsgCooldown", self );
end

function CInstantMessageWnd:OnShowWorld()
	self.m_wndFriend:ShowWnd( false );
	self.m_wndWorld:ShowWnd( true );
	self:CheckSendState();
end

function CInstantMessageWnd:OnShowFriend()
	self.m_wndFriend:ShowWnd( true );
	self.m_wndWorld:ShowWnd( false );
	self:CheckSendState();
end

function CInstantMessageWnd:ShowPage( nType )
	self:ShowAndSetFocus( true );
	if nType == 0 then
		self.m_checkWorld:SetCheck( true );
	else
		self.m_checkFriend:SetCheck( true );
	end
end

function CInstantMessageWnd:OnWndShow( bShow )
	self.m_wndParent:OnImShow( bShow );
end

function CInstantMessageWnd:GetTargetId()
	if self.m_checkWorld:GetCheck() then
		return eSystemAccountID_WorldMsg;
	elseif self.m_checkFriend:GetCheck() then
		return self.m_wndFriend:GetTargetId();
	end
end

function CInstantMessageWnd:GetContent()
	local szContent = self.m_editContent:GetWndText();
	self.m_editContent:SetWndText( "" );
	return szContent;
end

function CInstantMessageWnd:OnWorldMsgCooldown( Event )
	self.m_wndTimeRemain:SetWndText( Event.m_szLeftTimeText );
	self:CheckSendState();
end

function CInstantMessageWnd:CheckSendState()
	local bFriend = self:GetTargetId() ~= eSystemAccountID_WorldMsg
	local szText = self.m_wndTimeRemain:GetWndText();
	local bShowSend = bFriend or szText == "";
	self.m_btnSend:ShowWnd( bShowSend );
	self.m_wndTimeRemain:ShowWnd( not bShowSend );
end

function CInstantMessageWnd:OnSend()
	g_App:GetInstantMessageDataMgr():SendMsg( self:GetTargetId(), self:GetContent() );
end

function CInstantMessageWnd:OnClose()
	self:ShowWnd( false );
end

--endregion
