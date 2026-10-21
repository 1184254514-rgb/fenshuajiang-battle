--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


CFriendMgr.eRelationType_Followee		= 0;
CFriendMgr.eRelationType_Follower		= 1;
CFriendMgr.eRelationType_Blacklist		= 2;
CFriendMgr.eRelationType_NewFollower	= 3;
CFriendMgr.eRelationType_Friends		= 4;

local function IsExist( Table, Value )
    for k, v in pairs( Table ) do
        if v == Value then
            return true;
        end
    end	
	return false;
end

local function Erase( Table, Value )
    for k, v in pairs( Table ) do
        if v == Value then
			table.remove( Table, k )
            return;
        end
    end	
end

function CFriendMgr:Ctor()
	self:Clear();
end

function CFriendMgr:Inst()
	if not self.m_Inst then
		self.m_Inst = CFriendMgr:new();
	end

	return self.m_Inst;
end

function CFriendMgr:Clear()
	self.m_tblFriends = {};
	self.m_tblFollowee = {};
	self.m_tblFollower = {}
    self.m_tblBlacklist = {};
    self.m_tblNewFollower = {};
	self.m_nFollowerTotalCount = 0;
	self.m_bRefuseFollowers = false;
	self.m_tblCharInfo = {}
end

function CFriendMgr:Init( InitData )
	self.m_tblFriends = InitData.nFriendIDs;
	self.m_tblFollowee = InitData.nFolloweeIDs;
	self.m_tblFollower = InitData.nFollowerIDs;
	self.m_tblBlacklist	= InitData.nBlacklistIDs;
	self.m_nFollowerTotalCount = InitData.nFollowerTotalCount;
	self.m_bRefuseFollowers = InitData.bRefuseFollowers;

	local nNewFollowCount = #InitData.nFollowerIDs;
	if( nNewFollowCount > InitData.nNewFollowerCount ) then
		nNewFollowCount = InitData.nNewFollowerCount;
	end
	
    self.m_tblNewFollower = {};
	for i = 1, nNewFollowCount, 1 do
        table.insert( self.m_tblNewFollower, InitData.nFollowerIDs[i] );
	end
	self:SortAllListByState()
end

function CFriendMgr:SortAllListByState( tblSortList )
	local tblCharInfo = self.m_tblCharInfo;
	local Compare = function ( a, b ) 
		local InfoA = tblCharInfo[a];
		local InfoB = tblCharInfo[b];
		local nStateA = InfoA and InfoA.nState or 0;
		local nStateB = InfoB and InfoB.nState or 0;
		return nStateA > nStateB; 
	end 

	tblSortList = tblSortList or 
	{ 
		self.m_tblFriends, 
		self.m_tblFollowee, 
		self.m_tblFollower, 
		self.m_tblBlacklist,
		self.m_tblNewFollower
	};

	for k, v in pairs( tblSortList ) do
		table.sort( v, Compare )
	end
end

function CFriendMgr:UpdateCharsInfo( tblCharsInfo )
	for k, v in pairs( tblCharsInfo ) do
		self.m_tblCharInfo[v.nAccountID] = v;
	end
	self:SortAllListByState()
end

function CFriendMgr:GetCharInfoTotalCount( eRelation )
	if eRelation == CFriendMgr.eRelationType_Follower then
		return self.m_nFollowerTotalCount;
	else
		return self:GetCharInfoDataCount( eRelation )
	end
end

function CFriendMgr:GetCharInfoDataCount( eRelation )
	if eRelation == CFriendMgr.eRelationType_Followee then
		return #self.m_tblFollowee;
	elseif eRelation == CFriendMgr.eRelationType_Follower then
		return #self.m_tblFollower;
	elseif eRelation == CFriendMgr.eRelationType_Blacklist then
		return #self.m_tblBlacklist;
	elseif eRelation == CFriendMgr.eRelationType_NewFollower then
		return #self.m_tblNewFollower;
	elseif eRelation == CFriendMgr.eRelationType_Friends then
		return #self.m_tblFriends;
	end
end

function CFriendMgr:GetCharInfo( nAccountID )
	if nAccountID == g_App:GetAccountID() then
		local tblChar = {};
		tblChar.nAccountID = g_App:GetAccountID();
		tblChar.szCharName = g_App:GetNickName();
		tblChar.nState = 1;
		tblChar.nLogoutTime = math.floor( GetNatureTime()/1000 );
		tblChar.nCurHeadIcon = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
		tblChar.nCurLadderStar = g_App:GetCurLadderStar();
		return tblChar;
	end
	if nAccountID == eSystemAccountID_CustomerService then
		local tblChar = {};
		tblChar.nAccountID = eSystemAccountID_CustomerService;
		tblChar.szCharName = g_App:GetString( "xitongxiaoxi" );
		tblChar.nState = 100000;
		tblChar.nLogoutTime = 0;
		tblChar.nCurHeadIcon = 11;
		tblChar.nCurLadderStar = 9999;
		return tblChar;
	end
	return self.m_tblCharInfo[nAccountID];
end

function CFriendMgr:GetCharsInfo( eRelation, nStart, nEnd )
	local aryName = 
	{
		"m_tblFollowee", 
		"m_tblFollower", 
		"m_tblBlacklist", 
		"m_tblNewFollower", 
		"m_tblFriends" 
	}
	local tblCharIDs = self[aryName[eRelation + 1]];
	local tblCharInfo = {}
	nEnd = math.min( nEnd, #tblCharIDs );
	for i = nStart + 1, nEnd, 1 do
		local nAccountID = tblCharIDs[i]
		local CharInfo = self.m_tblCharInfo[nAccountID]
		if not CharInfo then
			CharInfo = {}
			CharInfo.nAccountID = nAccountID;
			CharInfo.nState = 0;
			CharInfo.nLogoutTime = 0;
			CharInfo.nCurHeadIcon = 0;
			CharInfo.nCurLadderStar = 0;
		end
		table.insert( tblCharInfo, CharInfo );
	end
	return tblCharInfo;
end

function CFriendMgr:GetUncacheCharIDs( eType, nStart, nEnd )
	local tblCharInfo = self:GetCharsInfo( eType, nStart, nEnd );
	local tblUncacheIDs = {}
	for k, v in pairs( tblCharInfo ) do
		if not v.szCharName then
			table.insert( tblUncacheIDs, v.nAccountID );
		end
	end
	return tblUncacheIDs;
end

function CFriendMgr:IsFriends( nAccountID )
	return IsExist( self.m_tblFriends, nAccountID );
end

function CFriendMgr:IsFollowee( nAccountID )
	return IsExist( self.m_tblFollowee, nAccountID );
end

function CFriendMgr:IsBlacklist( nAccountID )
	return IsExist( self.m_tblBlacklist, nAccountID );
end

function CFriendMgr:GetRelationship( nAccountID )
    return self:IsFriends( nAccountID ) and 1 or 
		self:IsBlacklist( nAccountID ) and 2 or 0;
end

function CFriendMgr:ClearNewFollower()
    self.m_tblNewFollower = {};
end

function CFriendMgr:AddFollowee( nAccountID, bFriend )
	if not IsExist( self.m_tblFollowee, nAccountID ) then
		table.insert( self.m_tblFollowee, nAccountID );
		self:SortAllListByState( { self.m_tblFollowee } );
	end
	if( bFriend and not self:IsFriends( nAccountID ) ) then
		table.insert( self.m_tblFriends, nAccountID );
		self:SortAllListByState( { self.m_tblFriends } );
	end
end

function CFriendMgr:AddFollower( nAccountID, bFriend )
	if not IsExist( self.m_tblFollower, nAccountID ) then
		table.insert( self.m_tblFollower, nAccountID );
		self:SortAllListByState( { self.m_tblFollower } );
	end
	if not IsExist( self.m_tblNewFollower, nAccountID ) then
		table.insert( self.m_tblNewFollower, nAccountID );
		self:SortAllListByState( { self.m_tblNewFollower } );
	end
	if( bFriend and not self:IsFriends( nAccountID ) ) then
		table.insert( self.m_tblFriends, nAccountID );
		self:SortAllListByState( { self.m_tblFriends } );
	end
	self.m_nFollowerTotalCount = self.m_nFollowerTotalCount + 1;
end

function CFriendMgr:AddBlacklist( nAccountID )
	if not self:IsBlacklist( nAccountID ) then
		table.insert( self.m_tblBlacklist, nAccountID );
		self:RemoveFollowee( nAccountID );
	end
end

function CFriendMgr:RemoveFollowee( nAccountID )
	Erase( self.m_tblFollowee, nAccountID );
	Erase( self.m_tblFriends, nAccountID );
end

function CFriendMgr:RemoveFollower( nAccountID )
	self.m_nFollowerTotalCount = self.m_nFollowerTotalCount - 1;
	Erase( self.m_tblFollower, nAccountID );
	Erase( self.m_tblFriends, nAccountID );
end

function CFriendMgr:RemoveBlacklist( nAccountID )
	Erase( self.m_tblBlacklist, nAccountID );
end

function CFriendMgr:RefuseFollowers( bRefuse )
	self.m_bRefuseFollowers = bRefuse;
end
--endregion
