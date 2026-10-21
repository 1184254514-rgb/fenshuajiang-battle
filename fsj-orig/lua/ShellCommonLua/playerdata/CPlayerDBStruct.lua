-- the file come from c++ RoleProperty，don't alter

-- begin SBattleFace --
SBattleFace = class();
function SBattleFace:Ctor( buffer, offset, parent_offset )
	self.m_buffer = buffer or CBufferStream:new( self:GetStructSize() );
	self.offset2BufferStart = buffer and offset or 0;
	self.parent_offset2BufferStart = buffer and parent_offset or 0;
end

function SBattleFace:GetBattleFaceID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	return self.m_buffer:ReadUint8();
end

function SBattleFace:SetBattleFaceID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SBattleFace:GetUsed()
	self.m_buffer:SetPosition( self.offset2BufferStart + 1 );
	return self.m_buffer:ReadUint8();
end

function SBattleFace:SetUsed( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 1 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SBattleFace:GetStructSize()
	return 2;
end

-- end SBattleFace --

-- begin STreasureBoxData --
STreasureBoxData = class();
function STreasureBoxData:Ctor( buffer, offset, parent_offset )
	self.m_buffer = buffer or CBufferStream:new( self:GetStructSize() );
	self.offset2BufferStart = buffer and offset or 0;
	self.parent_offset2BufferStart = buffer and parent_offset or 0;
end

function STreasureBoxData:GetTreasureBoxID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	return self.m_buffer:ReadUint32();
end

function STreasureBoxData:SetTreasureBoxID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function STreasureBoxData:GetGetTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 4 );
	return self.m_buffer:ReadUint32();
end

function STreasureBoxData:SetGetTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function STreasureBoxData:GetUnlockTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 8 );
	return self.m_buffer:ReadUint32();
end

function STreasureBoxData:SetUnlockTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 8 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function STreasureBoxData:GetStatus()
	self.m_buffer:SetPosition( self.offset2BufferStart + 12 );
	return self.m_buffer:ReadUint8();
end

function STreasureBoxData:SetStatus( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 12 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function STreasureBoxData:GetType()
	self.m_buffer:SetPosition( self.offset2BufferStart + 13 );
	return self.m_buffer:ReadUint8();
end

function STreasureBoxData:SetType( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 13 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function STreasureBoxData:GetStructSize()
	return 14;
end

-- end STreasureBoxData --

-- begin SFragmentData --
SFragmentData = class();
function SFragmentData:Ctor( buffer, offset, parent_offset )
	self.m_buffer = buffer or CBufferStream:new( self:GetStructSize() );
	self.offset2BufferStart = buffer and offset or 0;
	self.parent_offset2BufferStart = buffer and parent_offset or 0;
end

function SFragmentData:GetFragmentID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	return self.m_buffer:ReadUint32();
end

function SFragmentData:SetFragmentID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SFragmentData:GetCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 4 );
	return self.m_buffer:ReadUint32();
end

function SFragmentData:SetCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SFragmentData:GetStructSize()
	return 8;
end

-- end SFragmentData --

-- begin SDBSkillData --
SDBSkillData = class();
function SDBSkillData:Ctor( buffer, offset, parent_offset )
	self.m_buffer = buffer or CBufferStream:new( self:GetStructSize() );
	self.offset2BufferStart = buffer and offset or 0;
	self.parent_offset2BufferStart = buffer and parent_offset or 0;
end

function SDBSkillData:GetSkillID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	return self.m_buffer:ReadUint16();
end

function SDBSkillData:SetSkillID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 0 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SDBSkillData:GetLevel()
	self.m_buffer:SetPosition( self.offset2BufferStart + 2 );
	return self.m_buffer:ReadUint16();
end

function SDBSkillData:SetLevel( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 2 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SDBSkillData:GetState()
	self.m_buffer:SetPosition( self.offset2BufferStart + 4 );
	return self.m_buffer:ReadUint8();
end

function SDBSkillData:SetState( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 4 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, self.parent_offset2BufferStart );
end

function SDBSkillData:GetStructSize()
	return 5;
end

-- end SDBSkillData --

