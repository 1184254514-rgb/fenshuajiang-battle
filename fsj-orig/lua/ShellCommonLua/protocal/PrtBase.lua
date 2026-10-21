--region PrtBase.lua
--Date 2015-12-10

local s_BufferSend = CBufferStream:new()

--网络协议注册
function RegisterProtocal( tblPrt, tblClass, bSmallHead )
	tblClass.funRead = bSmallHead and CBufferStream.ReadUint8 or CBufferStream.ReadUint16
	tblClass.funWrite = bSmallHead and CBufferStream.WriteInt8 or CBufferStream.WriteInt16
	for k, v in pairs( tblPrt ) do
		local sClassName = "C"..string.sub( k, 6 );
		if _G[sClassName] == nil then
			_G[sClassName] = class()
			_G[sClassName].m_nID = v;
			_G[sClassName].m_sName = sClassName;
		end
		tblClass[v] = { _G[sClassName], _G[sClassName]:new() };
		_G[sClassName].funRead = tblClass.funRead
		_G[sClassName].funWrite = tblClass.funWrite
	end	
end

function UnpackProtocal( tblClass, pBuffer, nSize )
	pBuffer:SetDataSize( nSize );
	local nID = tblClass.funRead( pBuffer );
	local PrtInfo = tblClass[nID];
	local PrtClass = PrtInfo[1];
	local PrtObject = PrtInfo[2];
	PrtClass.OnUnpack( PrtObject, pBuffer )
	return PrtObject;
end

--由网络处理模块统一调用
function PackProtocal( Protocal, pExtraBuffer, nSize )
	s_BufferSend:Reset();
	Protocal.funWrite( s_BufferSend, Protocal.m_nID );
	Protocal:OnPack( s_BufferSend );
	if( pExtraBuffer and nSize > 0 ) then
		s_BufferSend:WriteBytes( pExtraBuffer, 0, nSize );
	end
	return s_BufferSend;
end

--endregion
