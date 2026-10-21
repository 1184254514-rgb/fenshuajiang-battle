--region *.lua
--Date

function CAnswerFolloweesRank:OnUnpack( pBuffer )
	local nCount = pBuffer:ReadUint32();
    self.tblFollowees = {};
    for i = 1, nCount, 1 do
		self.tblFollowees[i] = {};
        self.tblFollowees[i].nAccountID = pBuffer:ReadUint64();
        self.tblFollowees[i].szCharName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
        self.tblFollowees[i].nCurHeadIcon = pBuffer:ReadUint16();
		self.tblFollowees[i].nCurSeasonStar = pBuffer:ReadUint32();
		self.tblFollowees[i].SeasonMax = pBuffer:ReadUint32();

		self.tblFollowees[i].nEndlessDayRecord = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessWeekRecord = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessHistoryRecord = pBuffer:ReadUint32();

		self.tblFollowees[i].nLimitDayRecord = pBuffer:ReadUint32();
		self.tblFollowees[i].nLimitWeekRecord = pBuffer:ReadUint32();
		self.tblFollowees[i].nLimitHistoryRecord = pBuffer:ReadUint32();

		self.tblFollowees[i].nTeamDayRecord = pBuffer:ReadUint32();
		self.tblFollowees[i].nTeamWeekRecord = pBuffer:ReadUint32();
		self.tblFollowees[i].nTeamHistoryRecord = pBuffer:ReadUint32();

		self.tblFollowees[i].nEndlessDayAreaScore = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessDayAreaTime = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessWeekAreaScore = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessWeekAreaTime = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessHistoryAreaScore = pBuffer:ReadUint32();
		self.tblFollowees[i].nEndlessHistoryAreaTime = pBuffer:ReadUint32();

		self.tblFollowees[i].nRaceDayScore = pBuffer:ReadUint32();
		self.tblFollowees[i].nRaceWeekScore = pBuffer:ReadUint32();
		self.tblFollowees[i].nRaceMonthScore = pBuffer:ReadUint32();
	end
end

function CAnswerFolloweesRank:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "FolloweesRank";
    Event.tblFollowees = self.tblFollowees;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerWorldRecord:OnUnpack( pBuffer )
	self.nRankType = pBuffer:ReadUint8();
    self.tblAllRegion = {};
	local nCount = pBuffer:ReadUint32();
    for i = 1, nCount do
		self.tblAllRegion[i] = {};
		self.tblAllRegion[i].nAccountID = pBuffer:ReadUint64();
        self.tblAllRegion[i].szCharName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
        self.tblAllRegion[i].nCurHeadIcon = pBuffer:ReadUint16();
		self.tblAllRegion[i].nRankValue = { pBuffer:ReadUint32(), pBuffer:ReadUint32() };
	end
end

function CAnswerWorldRecord:OnNetReply( Connecter, pBuffer )
	local Event = {};
    Event.m_Type = "WorldRank";
	Event.nRankType = self.nRankType;
    Event.tblAllRegion = self.tblAllRegion;
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CAnswerWorldMaxRecord:OnUnpack( pBuffer )
	self.szEndlessName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	self.nEndlessDay = pBuffer:ReadUint32();
	self.szLimitName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	self.nLimitDay = pBuffer:ReadUint32();
	self.szTeamName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	self.nTeamDay = pBuffer:ReadUint32();
end

function CAnswerWorldMaxRecord:OnNetReply( Connecter, pBuffer )
	g_App:SetWorldTodayScore( self.szEndlessName, self.nEndlessDay, self.szLimitName, self.nLimitDay, self.szTeamName, self.nTeamDay );
end