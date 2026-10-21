--region *.lua
--Date 2017-08-05

function CGameConnToFieldLua:Ctor()
	self.m_tickNetDelay = CTick:new( "CheckDelay", self );
    self.m_pExit = false;
	self.m_nReconnectCount = 0;
end

function CGameConnToFieldLua:SendShellMsg( PrtMsg, pExtraBuffer, nSize )
	local PackBuffer = PackProtocal( PrtMsg, pExtraBuffer, nSize );
	local nLen = PackBuffer:GetPosition();
	CGameConnToField.SendShellMsg( self, PackBuffer, nLen );
end

function CGameConnToFieldLua:PostShellMsg( pBuffer, nSize )
	local NetMsg = UnpackProtocal( g_PrtField2ClientClass, pBuffer, nSize );
	NetMsg:OnNetReply( self, pBuffer );
	return nSize;
end

function CGameConnToFieldLua:OnConnected()
	CGameConnToField.OnConnected( self );
	
	local NetMsg = CCheckConnect:new();
	self:SendShellMsg( NetMsg );
	self.m_tickNetDelay:Start( 1000 );
end

function CGameConnToFieldLua:OnDisConnect()
	CGameConnToField.OnDisConnect( self );
	self:OnDelayLessTime();
	self.m_tickNetDelay:Stop();
	g_App.m_NetDelayWnd:SetNetDelay( 0 );
    if g_App:GetScene() == nil then
        return;
    end
    if self.m_pExit then
        self.m_pExit = false;
        return;
    end
    
    g_App:MessageBox( g_App:GetString( "weilianwangtishi" ),{
		[CMessageBox.OK] = function()
	        g_App.m_pMessageBox:ShowWnd( false );
            g_App:SwitchStart();
		end;
	} );
end

function CGameConnToFieldLua:CheckDelay()
	local nNetDelay = self:GetPingDelay();
	g_App.m_NetDelayWnd:SetNetDelay( nNetDelay );
end

function CGameConnToFieldLua:SoonEnterRoom( nCheckKey )
	self.m_nCheckKey = nCheckKey;
end

function CGameConnToFieldLua:CheckConnectReply()
	local NetMsg = CQueryJoinRoom:new();
	NetMsg.m_nAccountID = g_App:GetAccountID();
	NetMsg.m_nCheckKey = self.m_nCheckKey;
	NetMsg.m_bEnablAI = false;
	NetMsg.m_nHeadIocnID = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
	self:SendShellMsg( NetMsg );
end

function CGameConnToFieldLua:AnswerJoinRoomSucceed()
	g_App:GetWndFieldReconnectLast():ShowWnd( false );
	g_App:WaitMsg( false );
	g_App:GetGameStart().m_pWndRaceTeam:ShowWnd( false );
end

function CGameConnToFieldLua:OnReconnecting()
	self.m_nReconnectCount = self.m_nReconnectCount + 1;
	g_App:GetWndFieldReconnect():ReconnectTitle( self.m_nReconnectCount );
end

function CGameConnToFieldLua:OnDelayLessTime()
	self.m_nReconnectCount = 0;
	g_App:GetWndFieldReconnect():ShowWnd( false );
end

-------------------- wnd reconnect ----------------------
function CWndReconnect:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndReconnect:OnCreated()
	self.m_pWndTitle = self:GetDlgChild( "tishi" );

	if self.m_nReconnectCount and self.m_nReconnectCount ~= 0 then
		self:ReconnectTitle( self.m_nReconnectCount );
	end
end

function CWndReconnect:ReconnectTitle( nReconnectCount )
	if not self.m_pWndTitle then
		self.m_nReconnectCount = nReconnectCount;
		return;
	end
	local szString = g_App:GetString( "changshichonglian" );
	szString = string.format( szString, nReconnectCount );
	self.m_pWndTitle:SetWndText( szString );

	if self:IsShow() then
		return;
	end
	self:ShowWnd( true );
end
--endregion
