--region GammaHash.lua
--Date 2015-12-23

function Hash( str )
	local Buffer = CBufferStream:new()
	Buffer:WriteUTFBytes( str );
	return GammaHash( Buffer, Buffer:GetPosition() );
end

local s_BufferSrc = CBufferStream:new()
local s_BufferDes = CBufferStream:new()
s_BufferDes:SetDataSize( 32 );

function HaskEx( str )
	s_BufferSrc:Reset();
	s_BufferDes:SetPosition( 0 );
	s_BufferSrc:WriteUTFBytes( str );
	MD5Ex( s_BufferDes, s_BufferSrc, s_BufferSrc:GetPosition() );
	return s_BufferDes:ReadUTFBytes( 32 );
end
		
--endregion
