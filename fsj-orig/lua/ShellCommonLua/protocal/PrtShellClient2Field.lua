--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CCheckConnect:OnPack( pBuffer )
end

function CCheckConnect:OnUnpack( pBuffer )
end

function CCheckConnect:OnNetReply( Connecter, pBuffer )
	local NetMsg = CCheckConnectReply:new();
	Connecter:SendShellMsg( NetMsg );
end

function CQueryJoinRoom:OnPack( pBuffer )
	pBuffer:WriteUint64( self.m_nAccountID );
	WriteUnit64String( pBuffer, self.m_nCheckKey );
	pBuffer:WriteInt8( self.m_bEnablAI );
	pBuffer:WriteInt16( self.m_nHeadIocnID );
end

function CQueryJoinRoom:OnUnpack( pBuffer )
	self.m_nAccountID = pBuffer:ReadUint64();
	self.m_nCheckKey = ReadUnit64String( pBuffer );
	self.m_bEnablAI = pBuffer:ReadInt8();
	self.m_nHeadIocnID = pBuffer:ReadInt16();
end

function CQueryJoinRoom:OnNetReply( Connecter, pBuffer )
	Connecter:QueryJoinRoom(
		self.m_nAccountID,
		self.m_nCheckKey,
		self.m_bEnablAI,
		self.m_nHeadIocnID
	);
end

function CExitRoom:Ctor()
end

function CExitRoom:OnPack( Buffer )
end

--gm 命令
function CSendScriptedCmd:Ctor()
    self.m_scritp = ""; 
end

function CSendScriptedCmd:OnPack( Buffer )
    Buffer:WriteUTF( self.m_scritp );
end

function CSendScriptedCmd:OnUnpack( Buffer )

end

--endregion
