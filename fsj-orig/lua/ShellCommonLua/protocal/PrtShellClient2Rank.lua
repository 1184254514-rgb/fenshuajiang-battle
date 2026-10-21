--region *.lua
--Date

function CQueryFolloweesRank:Ctor()
end

function CQueryFolloweesRank:OnPack( Buffer )
	local tblFriend = CFriendMgr:Inst().m_tblFriends;
	local nFriendCount = #tblFriend + 1; -- （好友 + 自己）的数量 
	Buffer:WriteInt32( nFriendCount );
	for k, nAccountID in pairs(tblFriend) do
		Buffer:WriteUint64( nAccountID );
	end
	Buffer:WriteUint64( g_App:GetAccountID() );
end

function CQueryWorldRecord:Ctor( nRankType )
	self.nRankType = nRankType;
end

function CQueryWorldRecord:OnPack( Buffer )
	Buffer:WriteInt8( self.nRankType );
end

function CQueryWorldMaxRecord:Ctor()	
end

function CQueryWorldMaxRecord:OnPack( Buffer )
end
