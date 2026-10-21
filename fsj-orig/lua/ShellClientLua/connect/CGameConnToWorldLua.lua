--region *.lua
--Date 2017-08-05

function CGameConnToWorldLua:Ctor()
	print( "CGameConnToWorldLua:Ctor" );
end

function CGameConnToWorldLua:OnConnected()
	CGameConnToWorld.OnConnected( self );

	if self.m_msgPendingLoginMsg then
		self:SendShellMsg( self.m_msgPendingLoginMsg );
	end
end

function CGameConnToWorldLua:OnDisConnect()
	CGameConnToWorld.OnDisConnect( self );
	g_App:GetLoginFrame():OnWorldDisConnect( self:IsShellDisconnect() );
end

function CGameConnToWorldLua:SendShellMsg( PrtMsg, pExtraBuffer, nSize )
	local PackBuffer = PackProtocal( PrtMsg, pExtraBuffer, nSize );
	local nLen = PackBuffer:GetPosition();
	CGameConnToWorld.SendShellMsg( self, PackBuffer, nLen );
end

function CGameConnToWorldLua:PostShellMsg( pBuffer, nSize )
	local nPosBuffer = pBuffer:GetPosition();
	local nID = pBuffer:ReadUint16();
	pBuffer:SetPosition(nPosBuffer);
	local prtClass;
    if nID < eRank_MinId then
        prtClass = g_PrtWorld2ClientClass;
    elseif nID < eSocial_MinId then
        prtClass = g_PrtRank2ClientClass;
    else
        prtClass = g_PrtSocial2ClientClass;
    end
	local NetMsg = UnpackProtocal( prtClass, pBuffer, nSize );
	NetMsg:OnNetReply( self, pBuffer );
	return nSize;
end

function CGameConnToWorldLua:Login( szAccount, szToken, szChannel, szSDKType, 
					pid, gid, szGHomeDeviceID, szPushDeviceID, bGuest )
	local NetMsg = CValidateClient:new();
	NetMsg.m_MachineInfo = g_App:GetMachineInfo();
	NetMsg.m_nTime = math.floor( GetNatureTime() / 1000 );

	NetMsg.m_szAccountName = szAccount;
	NetMsg.m_szToken = szToken;
	NetMsg.m_szChannel = szChannel;
	NetMsg.m_szSDKType = szSDKType;
	NetMsg.m_pid = pid;
	NetMsg.m_gid = gid;
	NetMsg.m_szGHomeDeviceID = szGHomeDeviceID;
	NetMsg.m_szPushDeviceID = szPushDeviceID;

	if not self:IsConnected() then
		self.m_msgPendingLoginMsg = NetMsg;
	else
		self:SendShellMsg( NetMsg );
	end

	self:OnGuestUpgrade( bGuest );
	g_App:WaitMsg( true );
end

function CGameConnToWorldLua:ReLogin()
	if not self.m_msgPendingLoginMsg then
		return;
	end

	self:SendShellMsg( self.m_msgPendingLoginMsg );
end

function CGameConnToWorldLua:OnGuestUpgrade( bGuest )
	self.m_bGuest = bGuest;
end

function CGameConnToWorldLua:IsGuest()
	return self.m_bGuest;
end

--endregion
