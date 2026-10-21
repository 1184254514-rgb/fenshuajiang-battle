--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


function CPlayerExit:Ctor()
end

function CPlayerExit:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nAccountID );
end

function CRaceStateChange:Ctor()
end

function CRaceStateChange:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nRaceRoomID );
	Buffer:WriteInt8( self.m_nRaceID );
	Buffer:WriteInt8( self.m_nState );
end

function CAnswerEverJoinRace:Ctor()
end

function CAnswerEverJoinRace:OnPack( Buffer )
	WriteUnit64String( Buffer, self.m_nKey );
	Buffer:WriteUint64( self.m_nSelfAccountID );
	Buffer:WriteInt8( self.m_nRoomType );
end

--endregion
