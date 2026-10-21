--region *.lua
--Date

------------------------------------------------------
-- CNotifyFriendChanged
------------------------------------------------------
function CNotifyFriendChanged:OnUnpack( pBuffer )
	self.m_nContext = pBuffer:ReadUint32();
	local nCount = pBuffer:ReadUint32();
    self.m_aryCharsInfo = {};
    for i = 1, nCount, 1 do
		local CharInfo = UnpackCharListInfo( pBuffer, {} );
        table.insert( self.m_aryCharsInfo, CharInfo );
    end
end

function CNotifyFriendChanged:OnNetReply( Connecter, pBuffer )
    CFriendMgr:Inst():UpdateCharsInfo( self.m_aryCharsInfo );
    local Event = {};
    Event.m_Type = "CharsInfoChanged";
    Event.m_tblCharsInfo = self.m_aryCharsInfo;
	Event.m_nContext = self.m_nContext;
    g_App.m_EventDispatcher:DispatchEvent( Event );
	if( self.m_nContext ~= 0 ) then
		g_App.m_GameStart.m_pFriendWnd:OnAnswerQueryChar();
	end
end

------------------------------------------------------
-- CNotifyFriendChanged
------------------------------------------------------
function CNotifyFriendInitData:OnUnpack( pBuffer )
	local nFolloweeCount = pBuffer:ReadUint32();
	local nFollowerCount = pBuffer:ReadUint32();
	local nBlacklistCount = pBuffer:ReadUint32();
	self.nFollowerTotalCount = pBuffer:ReadUint32();
	self.nNewFollowerCount = pBuffer:ReadUint32();
	self.bRefuseFollowers = pBuffer:ReadUint8() ~= 0;

    self.nFolloweeIDs = {};
    for i = 1, nFolloweeCount, 1 do
        local nID = pBuffer:ReadUint64();
        table.insert( self.nFolloweeIDs, nID );
    end
    self.nFollowerIDs = {};
    for i = 1, nFollowerCount, 1 do
        table.insert( self.nFollowerIDs, pBuffer:ReadUint64() );
    end
    self.nBlacklistIDs = {};
    for i = 1, nBlacklistCount, 1 do
        table.insert( self.nBlacklistIDs, pBuffer:ReadUint64() );
    end
    self.nFriendIDs = {};
    for i = 1, nFolloweeCount, 1 do
		if pBuffer:ReadInt8() ~= 0 then
			table.insert( self.nFriendIDs, self.nFolloweeIDs[i] );
		end
    end
end

function CNotifyFriendInitData:OnNetReply( Connecter, pBuffer )
	CFriendMgr:Inst():Init( self );
	local Event = {};
    Event.m_Type = "SocialLoginSucc";
    Event.m_nAccountID = g_App:GetAccountID();
	g_App.m_EventDispatcher:DispatchEvent( Event );
end

------------------------------------------------------
-- Followee
------------------------------------------------------
function CAnswerAddFollowee:OnUnpack( pBuffer )
	self.nAccountID = pBuffer:ReadUint64();
    self.nResult = pBuffer:ReadUint8();
    self.bFriend = pBuffer:ReadUint8() ~= 0;
end

function CAnswerAddFollowee:OnNetReply( Connecter, pBuffer )
    g_App:WaitMsg( false );
	if self.nResult == 0 then
		CFriendMgr:Inst():AddFollowee( self.nAccountID, self.bFriend );
        local Event = {};
        Event.m_Type = "AddFollowee";
        Event.nAccountID = self.nAccountID;
        g_App.m_EventDispatcher:DispatchEvent( Event );
    end

    if self.nResult <= 1 then
        g_App:HideMsg( g_App:GetString( "guanzhuchenggong" ) );
    elseif self.nResult == 4 then
        g_App:HideMsg( g_App:GetString( "guanzhushangxian" ) );
    elseif self.nResult == 5 then
        g_App:HideMsg( g_App:GetString( "fb_guanzhutips1" ) );
    end
end

function CAnswerRemoveFollowee:OnUnpack( pBuffer )
	self.nAccountID = pBuffer:ReadUint64();
    self.bSuccess = pBuffer:ReadUint8();
end

function CAnswerRemoveFollowee:OnNetReply( Connecter, pBuffer )
    g_App:WaitMsg( false );
	if self.bSuccess then
		CFriendMgr:Inst():RemoveFollowee( self.nAccountID );
        local Event = {};
        Event.m_Type = "RemoveFollowee";
        Event.nAccountID = self.nAccountID;
        g_App.m_EventDispatcher:DispatchEvent( Event );
    end
end

------------------------------------------------------
-- Follower
------------------------------------------------------
function CNotifyNewFollower:OnUnpack( pBuffer )
	self.nAccountID = pBuffer:ReadUint64();
    self.bFriend = pBuffer:ReadUint8() ~= 0;
end

function CNotifyNewFollower:OnNetReply( Connecter, pBuffer )
	CFriendMgr:Inst():AddFollower( self.nAccountID, self.bFriend );
    local Event = {};
    Event.m_Type = "AddFollower";
    Event.nAccountID = self.nAccountID;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CNotifyRemoveFollower:OnUnpack( pBuffer )
	self.nAccountID = pBuffer:ReadUint64();
end

function CNotifyRemoveFollower:OnNetReply( Connecter, pBuffer )
	CFriendMgr:Inst():RemoveFollower( self.nAccountID );
    local Event = {};
    Event.m_Type = "RemoveFollower";
    Event.nAccountID = self.nAccountID;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

------------------------------------------------------
-- Blacklist
------------------------------------------------------
function CAnswerAddBlacklist:OnUnpack( pBuffer )
	self.nAccountID = pBuffer:ReadUint64();
    self.nResult = pBuffer:ReadUint8();
end

function CAnswerAddBlacklist:OnNetReply( Connecter, pBuffer )
    g_App:WaitMsg( false );
	if self.nResult == 0 then
        CFriendMgr:Inst():AddBlacklist( self.nAccountID );
        local Event = {};
        Event.m_Type = "AddBlacklist";
        Event.nAccountID = self.nAccountID;
        g_App.m_EventDispatcher:DispatchEvent( Event );
    elseif self.nResult == 3 then
        g_App:HideMsg( g_App:GetString( "heimingdanshangxian" ) );
    end
end

function CAnswerRemoveBlacklist:OnUnpack( pBuffer )
	self.nAccountID = pBuffer:ReadUint64();
    self.bSuccess = pBuffer:ReadUint8();
end

function CAnswerRemoveBlacklist:OnNetReply( Connecter, pBuffer )
    g_App:WaitMsg( false );
	if self.bSuccess then
        CFriendMgr:Inst():RemoveBlacklist( self.nAccountID );
        local Event = {}; 
        Event.m_Type = "RemoveBlacklist";
        Event.nAccountID = self.nAccountID;
        g_App.m_EventDispatcher:DispatchEvent( Event );
    end
end

------------------------------------------------------
-- CAnswerSetRefuseFollowers
------------------------------------------------------
function CAnswerSetRefuseFollowers:OnUnpack( pBuffer )
	self.bRefuse = pBuffer:ReadUint8() ~= 0;
end

function CAnswerSetRefuseFollowers:OnNetReply( Connecter, pBuffer )
    CFriendMgr:Inst():RefuseFollowers( self.bRefuse )
end


------------------------------------------------------
-- 以下开始为即时通讯代码
------------------------------------------------------
function CAnswerIMNewWorldMessage:OnUnpack( pBuffer )
    self.nAccountID = pBuffer:ReadUint64();
	self.nCreateTime = pBuffer:ReadUint32();
	self.nCurHeadIcon = pBuffer:ReadUint16();
	self.nCurLadderStar = pBuffer:ReadUint16();
	local nNameLen = pBuffer:ReadUint8();
	self.szName = pBuffer:ReadUTFBytes( nNameLen );
	local nLeftData = pBuffer:GetDataSize() - pBuffer:GetPosition();
	self.szContent = pBuffer:ReadUTFBytes( nLeftData );
end

function CAnswerIMNewWorldMessage:OnNetReply( Connecter, pBuffer )
	local FriendMgr = CFriendMgr:Inst();
	local CharInfo = FriendMgr:GetCharInfo( self.m_nAccountID )
	if CharInfo == nil then
		local tblCharInfo = {}
		tblCharInfo.nAccountID = self.nAccountID;
		local nID = self.nAccountID;
		tblCharInfo.szAccountID = "";
		for i = 0, 9, 1 do
		    local nNum = nID % 10;
			tblCharInfo.szAccountID = tostring( nNum ) .. tblCharInfo.szAccountID;
		    nID = math.floor( nID / 10 );
		end

		tblCharInfo.szCharName = self.szName;
		tblCharInfo.nState = 3;
		tblCharInfo.nLogoutTime = 0;
		tblCharInfo.nCurHeadIcon = self.nCurHeadIcon;
		tblCharInfo.nCurLadderStar = self.nCurLadderStar;	
		CFriendMgr:Inst():UpdateCharsInfo( { tblCharInfo } );
	else
		CharInfo.nCurHeadIcon = self.nCurHeadIcon;
		CharInfo.nCurLadderStar = self.nCurLadderStar;
	end

	local Event = {};
    Event.m_Type = "NewMessageWorld";
    Event.m_nAccountID = self.nAccountID;
    Event.m_nCreateTime = self.nCreateTime;
    Event.m_szContent = self.szContent;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerIMNewFriendMessage:OnUnpack( pBuffer )
    self.nAccountID = pBuffer:ReadUint64();
	self.nCreateTime = pBuffer:ReadUint32();
	local nLeftData = pBuffer:GetDataSize() - pBuffer:GetPosition();
	self.szContent = pBuffer:ReadUTFBytes( nLeftData );
end

function CAnswerIMNewFriendMessage:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "NewMessageFriend";
    Event.m_nAccountID = self.nAccountID;
    Event.m_nCreateTime = self.nCreateTime;
    Event.m_szContent = self.szContent;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerBanChat:OnUnpack( pBuffer )
	local nLeftData = pBuffer:GetDataSize() - pBuffer:GetPosition();
	self.szEndTime = pBuffer:ReadUTFBytes( nLeftData );
end

function CAnswerBanChat:OnNetReply( Connecter, pBuffer )
	local szMsg = string.format( g_App:GetString( "gmniyibeijingyan" ), self.szEndTime );
	g_App:HideMsg( szMsg );
end

function CAnswerRelationshipCount:OnUnpack( pBuffer )
	self.nAttentionCount = pBuffer:ReadUint32( pBuffer );
	self.nFansCount = pBuffer:ReadUint32( pBuffer );
end

function CAnswerRelationshipCount:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "RelationshipCount";
	Event.m_nAttentionCount = self.nAttentionCount;
	Event.m_nFansCount = self.nFansCount;
	g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerFuzzySearchClan:OnUnpack( pBuffer )
	self.m_nCount = pBuffer:ReadUint32();
	self.m_tblClanInfo = {};
	for i = 1, self.m_nCount do
		local info = {};
		info.nClanID = pBuffer:ReadUint64();
		info.nIconID = pBuffer:ReadUint16();
		info.szClanName = pBuffer:ReadUTFBytes( CLANNAME_BYTE_SIZE + 1 );
		info.szClanSlogan = pBuffer:ReadUTFBytes( CLANSLOGAN_BYTE_SIZE + 1 );
		info.nMemcount = pBuffer:ReadUint8();
		info.nNeedApprove = pBuffer:ReadUint8();
		info.nDayActivity = pBuffer:ReadUint16();
		info.nWeekActivity = pBuffer:ReadUint32();
		info.nMonthActivity = pBuffer:ReadUint32();
		info.nAllActivity = pBuffer:ReadUint32();
		self.m_tblClanInfo[i] = info;
	end
end

function CAnswerFuzzySearchClan:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "AnswerFuzzySearchClan";
	Event.m_tblClanInfo = self.m_tblClanInfo;
	g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerJoinClan:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerJoinClan:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == eJoinClan_Ok or self.m_nResult == eJoinClan_Failed_InClan then
		local Event = {};
		Event.m_Type = "JoinClanSuccess";
		g_App.m_EventDispatcher:DispatchEvent( Event );
	elseif self.m_nResult == eJoinClan_Failed_MemberMax	 then
		g_App:HideMsg( g_App:GetString( "jiazuyiman" ) );
	elseif self.m_nResult == eJoinClan_Failed_NoClan then
		g_App:HideMsg( g_App:GetString( "jiazuyijiesan" ) );
	elseif self.m_nResult == eJoinClan_Approve_Wait then
		g_App:HideMsg( g_App:GetString( "dengdaipizhun" ) );
	elseif self.m_nResult == eJoinClan_Approve_Exist then
		g_App:HideMsg( g_App:GetString( "yijingshenqing" ) );
	end
end

function CAnswerExitClan:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerExitClan:OnNetReply( Connecter, pBuffer )
--	if self.m_nResult == eExitClan_Ok then
		local Event = {};
		Event.m_Type = "ExitClanSuccess";
		g_App.m_EventDispatcher:DispatchEvent( Event );
--	elseif self.m_nResult == eExitClan_Failed_NoInClan then
--		g_App:HideMsg( "exit clan failed, Not In Clan!" );
--	elseif self.m_nResult == eExitClan_Failed_NoClan then
--		g_App:HideMsg( "exit clan failed, Clan Not Exist!" );
--	end
end

function CAnswerKickClan:OnUnpack( Buffer )
	self.m_nOperateAccountID = Buffer:ReadUint64();
	self.m_nBeKickAccountID = Buffer:ReadUint64();
	self.m_nResult = Buffer:ReadUint8();
end

function CAnswerKickClan:OnNetReply( Connecter, pBuffer )
	local nAccountID = g_App:GetAccountID();
	if self.m_nResult == eOperate_Failed_NoPower then
		if self.m_nOperateAccountID == nAccountID then
			g_App:HideMsg( g_App:GetString( "meiyouquanxian" ) );
		end
	elseif self.m_nResult ==  eOperate_Failed_NoInfo then
		if self.m_nOperateAccountID == nAccountID then
			g_App:HideMsg( "yituichujiazu" );
		end
	elseif self.m_nResult == eExitClan_Ok then
		local Event = {};
		Event.m_Type = "AnswerKickFromClan";
		g_App.m_EventDispatcher:DispatchEvent( Event );
	end
end

function CAnswerQueryPropellClan:OnUnpack( pBuffer )
	self.m_nCount = pBuffer:ReadUint32();
	self.m_tblClanInfo = {};
	for i = 1, self.m_nCount do
		local info = {};
		info.nClanID = pBuffer:ReadUint64();
		info.nIconID = pBuffer:ReadUint16();
		info.szClanName = pBuffer:ReadUTFBytes( CLANNAME_BYTE_SIZE + 1 );
		info.szClanSlogan = pBuffer:ReadUTFBytes( CLANSLOGAN_BYTE_SIZE + 1 );
		info.nMemcount = pBuffer:ReadUint8();
		info.nNeedApprove = pBuffer:ReadUint8();
		info.nDayActivity = pBuffer:ReadUint16();
		info.nWeekActivity = pBuffer:ReadUint32();
		info.nMonthActivity = pBuffer:ReadUint32();
		info.nAllActivity = pBuffer:ReadUint32();
		self.m_tblClanInfo[i] = info;
	end
end

function CAnswerQueryPropellClan:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "AnswerQueryPropellClan";
	Event.m_tblClanInfo = self.m_tblClanInfo;
	g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerClanOperate:OnUnpack( pBuffer )
	self.m_nAccountID = pBuffer:ReadUint64();
	self.m_nApplyAccountID = pBuffer:ReadUint64();
	self.m_nResult = pBuffer:ReadUint8();
	self.m_nOperateType = pBuffer:ReadUint8();
end

function CAnswerClanOperate:OnNetReply( Connecter, pBuffer )
	local nAccountID = g_App:GetAccountID();
	if self.m_nResult == eOperate_Failed_NoPower then
		if self.m_nAccountID == nAccountID then
			g_App:HideMsg( g_App:GetString( "meiyouquanxian" ) );
		end	
	elseif self.m_nResult == eOperate_Failed_NoInfo then
		if self.m_nAccountID == nAccountID then
			g_App:HideMsg( g_App:GetString( "yijiarujiazu" ) );
		end	
	elseif self.m_nResult == eOperate_Ok then
		if self.m_nApplyAccountID == nAccountID then
			if self.m_nOperateType == eRefuse_ClanApply then
				g_App:HideMsg( g_App:GetString( "jiarujiazushibai" ) );
			end
		end
		local Event = {};
		Event.m_Type = "AnswerClanOperate";
		g_App.m_EventDispatcher:DispatchEvent( Event );
	end
end

function CAnswerSetClanInfo:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerSetClanInfo:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == eOperate_Ok then
		local Event = {};
		Event.m_Type = "SetClanInfoSuccess";
		g_App.m_EventDispatcher:DispatchEvent( Event );	
	end
end

function CAnswerSetClanMemberPower:OnUnpack( pBuffer )
	self.m_nResult = pBuffer:ReadUint8();
end

function CAnswerSetClanMemberPower:OnNetReply( Connecter, pBuffer )
	if self.m_nResult == eOperate_Failed_NoInfo then
		g_App:HideMsg( g_App:GetString( "meiyouquanxian" ) );
	end

	local Event = {};
	Event.m_Type = "SetClanMemberPowerSuccess";
	g_App.m_EventDispatcher:DispatchEvent( Event );	
end

function CAnswerClanApplyListCount:OnUnpack( pBuffer )
	self.m_nCount = pBuffer:ReadUint32();
end

function CAnswerClanApplyListCount:OnNetReply( Connecter, pBuffer )
	local Event = {};
	Event.m_Type = "RefreshClanRedPoint";
	Event.m_bShow = self.m_nCount > 0;
	g_App.m_EventDispatcher:DispatchEvent( Event );	
end
