--region *.lua
--Date

function CAddFollowee:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
end		  
		  
function CAddFollowee:OnUnpack( Buffer )
end

function CRemoveFollowee:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
end		  
		  
function CRemoveFollowee:OnUnpack( Buffer )
end

function CAddBlacklist:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
end		  
		  
function CAddBlacklist:OnUnpack( Buffer )
end

function CRemoveBlacklist:OnPack( Buffer )
    Buffer:WriteUint64( self.nAccountID );
end		  
		  
function CRemoveBlacklist:OnUnpack( Buffer )
end

function CQueryCharInfo:OnPack( Buffer )
	Buffer:WriteInt32( self.nContext )
	Buffer:WriteInt32( #self.tblCharsID )
	for k, v in pairs ( self.tblCharsID ) do
		Buffer:WriteUint64( v );
	end	
end		  
		  
function CQueryCharInfo:OnUnpack( Buffer )
end

function CSetRefuseFollowers:Ctor()
end

function CSetRefuseFollowers:OnPack( Buffer )
	Buffer:WriteInt8( self.bRefuse )
end

function CClearNewFollowers:Ctor()
end

function CClearNewFollowers:OnPack( Buffer )
end

function CSendIMNewMessage:Ctor()
end

function CSendIMNewMessage:OnPack( Buffer )
	-- nTargetId		收消息的人（特殊的，0为世界消息）
	-- szContent		消息内容（文字、语音路径、图片路径）
	Buffer:WriteUint64( self.nTargetId );
	Buffer:WriteUTFBytes( self.szContent );
end

function CQueryRelationshipCount:Ctor()
end

function CQueryRelationshipCount:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nAccountID )
end

function CFuzzySearchClan:Ctor()
end

function CFuzzySearchClan:OnPack( Buffer )
	local nPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szClanName );
	Buffer:SetPosition( nPos + CLANNAME_BYTE_SIZE + 1 );
end

function CJoinClan:Ctor()
end

function CJoinClan:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nClanID );
end

function CExitClan:Ctor()
end

function CExitClan:OnPack( Buffer )
end

function CKickClan:Ctor()
end

function CKickClan:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nBeKickAccountID );
end

function CAccurateSearchClan:Ctor()
end

function CAccurateSearchClan:OnPack(args)
end

function CQueryPropellClan:Ctor()
end

function CQueryPropellClan:OnPack( Buffer )
end

function CQueryApplyList:Ctor()
end

function CQueryApplyList:OnPack( Buffer )
end

function CClanApplyOperate:Ctor()
end

function CClanApplyOperate:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nApplyAccountID );
	Buffer:WriteInt8( self.m_nOperateType );
end

function CSetClanInfo:Ctor()
end

function CSetClanInfo:OnPack( Buffer )
	local nPos = Buffer:GetPosition();
	Buffer:WriteUTFBytes( self.m_szClanSlogan );
	Buffer:SetPosition( nPos + CLANSLOGAN_BYTE_SIZE + 1 );
	Buffer:WriteInt16( self.m_nClanIconID );
	Buffer:WriteInt8( self.m_nNeedApprove );
end

function CSetClanMemberPower:Ctor()
end

function CSetClanMemberPower:OnPack( Buffer )
	Buffer:WriteUint64( self.m_nBeSetAccountID );
	Buffer:WriteInt8( self.m_nNewPower );
end

function CCustomSearchClan:Ctor()
end

function CCustomSearchClan:OnPack( Buffer )
	Buffer:WriteInt32( self.m_nAllActivityMin );
	Buffer:WriteInt32( self.m_nAllActivityMax );
	Buffer:WriteInt32( self.m_nQueryPage );
	Buffer:WriteInt8( self.m_nCountMin );
	Buffer:WriteInt8( self.m_nCountMax );
	Buffer:WriteInt8( self.m_nNeedApprove );	
end