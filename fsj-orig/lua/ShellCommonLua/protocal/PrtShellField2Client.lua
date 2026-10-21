--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CCheckConnectReply:OnPack( pBuffer )
end

function CCheckConnectReply:OnUnpack( pBuffer )
end

function CCheckConnectReply:OnNetReply( Connecter, pBuffer )
	Connecter:CheckConnectReply();
end

function CNotifyObserverCount:OnUnpack( pBuffer )
    self.m_nCount = pBuffer:ReadUint32();
	self.m_szName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CNotifyObserverCount:OnNetReply( Connecter, pBuffer )
	g_App:GetGameMain():SetObserverCount( self.m_nCount, self.m_szName );
end

function CNotifyRemovePlayer:OnUnpack( pBuffer )
    self.m_nID = pBuffer:ReadUint64();
end

function CNotifyRemovePlayer:OnNetReply( Connecter, pBuffer )
	local pScene = g_App:GetScene();
    if pScene then
        pScene:OnRemovePlayer( self.m_nID );
    end
end

function CNotifyFieldKick:OnUnpack( pBuffer )
	self.m_nNotifyType = pBuffer:ReadUint16();
end

function CNotifyFieldKick:OnNetReply( Connecter, pBuffer )
	print( "NotifyFieldKick : ", self.m_nNotifyType );
	local Config = CKickMsgConfig.Inst();
	local szErrMsg = Config:GetErrMsg( self.m_nNotifyType );
	g_App:HideMsg( szErrMsg );
	Connecter:ShellCmdClose();
end

function CNotifyTeamOut:OnUnpack( pBuffer )
	self.m_nTeamOutColor = pBuffer:ReadUint8();
end

function CNotifyTeamOut:OnNetReply( Connecter, pBuffer )
	print( "------Notify Team Out------,Color ", self.m_nTeamOutColor );
	local pGameMain = g_App:GetGameMain();
	local wndTeamOut = pGameMain.m_wndOutInfo;
	if wndTeamOut then
		wndTeamOut:ShowInfo( self.m_nTeamOutColor );
	end
end

function CAnswerJoinRoomFailed:OnPack( pBuffer )
	pBuffer:WriteInt8( self.m_nResult );
end

function CAnswerJoinRoomFailed:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerJoinRoomFailed:OnNetReply( Connecter, pBuffer )
	print( "CAnswerJoinRoomFailed : "..self.m_nResult );
	g_App:WaitMsg( false );
	Connecter:ExitScene();
	g_App:GetWndFieldReconnectLast():ShowWnd( false );
end

--endregion
