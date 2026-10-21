--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CRankDataMgr:Ctor()
	self.m_tblFollowees = {};

	self.m_tblWorld = 
	{
		[eRankMode_Ladder] = {};
		[eRankMode_Endless] = {};
		[eRankMode_Limit] = {};
		[eRankMode_Team] = {};
		[eRankMode_Endless_Area] = {};
		[eRankMode_Race] = {};
	};

	self.m_tblSelfRankValue = 
	{ 
		[eRankMode_Ladder] = {};
		[eRankMode_Endless] = {}; 
		[eRankMode_Limit] = {}; 
		[eRankMode_Team] = {}; 

		[eRankMode_Endless_Area] = 
		{
			[eRankCycle_Day] = {};
			[eRankCycle_Week] = {};
			[eRankCycle_History] = {};
		}; 

		[eRankMode_Race] = 
		{
			[eRankCycle_Day] = {};
			[eRankCycle_Week] = {};
			[eRankCycle_Month] = {};
		}
	};

	self.m_tblRankType =
	{
		[eRankType_StarSeason]	= { eRankMode_Ladder, eRankCycle_Season };
		[eRankType_StarHistory] = { eRankMode_Ladder, eRankCycle_History };
		[eRankType_EndlessRecordDay] = { eRankMode_Endless, eRankCycle_Day };
		[eRankType_EndlessRecordWeek] = { eRankMode_Endless, eRankCycle_Week };
		[eRankType_EndlessRecordHistory] = { eRankMode_Endless, eRankCycle_History };
		[eRankType_LimitRecordDay] = { eRankMode_Limit, eRankCycle_Day };
		[eRankType_LimitRecordWeek] = { eRankMode_Limit, eRankCycle_Week };
		[eRankType_LimitRecordHistory] = { eRankMode_Limit, eRankCycle_History };
		[eRankType_TeamRecordDay] = { eRankMode_Team, eRankCycle_Day };
		[eRankType_TeamRecordWeek] = { eRankMode_Team, eRankCycle_Week };
		[eRankType_TeamRecordHistory] = { eRankMode_Team, eRankCycle_History };
		[eRankType_EndlessAreaDay] = { eRankMode_Endless_Area, eRankCycle_Day };
		[eRankType_EndlessAreaWeek] = { eRankMode_Endless_Area, eRankCycle_Week };
		[eRankType_EndlessAreaHistory] = { eRankMode_Endless_Area, eRankCycle_History };
		[eRankType_RaceRecordDay] = { eRankMode_Race, eRankCycle_Day };
		[eRankType_RaceRecordWeek] = { eRankMode_Race, eRankCycle_Week };
		[eRankType_RaceRecordMonth] = { eRankMode_Race, eRankCycle_Month };
	};

	g_App.m_EventDispatcher:AddEventListener( "FolloweesRank", "OnFolloweesData", self );
	g_App.m_EventDispatcher:AddEventListener( "WorldRank", "OnWorldData", self );
end

function CRankDataMgr:Destroy()
	g_App.m_EventDispatcher:RemoveEventListener( "FolloweesRank", "OnFolloweesData", self );
	g_App.m_EventDispatcher:RemoveEventListener( "WorldRank", "OnWorldData", self );
end

function CRankDataMgr:GetSelfRankValue( nModeType, nCycleType )
	if next(self.m_tblSelfRankValue) == nil then
		self:UpdateSelfRankValue();
	end
	return self.m_tblSelfRankValue[nModeType][nCycleType];
end

function CRankDataMgr:UpdateSelfRankValue()
	for nModeType = 1, eRankMode_Max, 1 do
		for nCycleType = 1, eRankCycle_Max, 1 do
			self:UpdateSelfRankValueItem( nModeType, nCycleType );
		end
	end
end

function CRankDataMgr:UpdateSelfRankValueItem( nModeType, nCycleType )
	local modelSelf = self.m_tblSelfRankValue[nModeType];
	if nModeType == eRankMode_Ladder then				-- 段位
		if nCycleType == eRankCycle_Season then
			modelSelf[nCycleType] = g_App:GetCurLadderStar();
		elseif nCycleType == eRankCycle_History then
			modelSelf[nCycleType] =  g_App:GetSeasonMaxStar();
		end
	elseif nModeType == eRankMode_Endless then	
		if nCycleType == eRankCycle_Day then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["TodayData"].EndlessAllScore;
		elseif nCycleType == eRankCycle_Week then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["WeekData"].EndlessAllScore;
		elseif nCycleType == eRankCycle_History then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["HistoryData"].EndlessAllScore;
		end
	elseif nModeType == eRankMode_Limit then	
		if nCycleType == eRankCycle_Day then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["TodayData"].LimitAllScore;
		elseif nCycleType == eRankCycle_Week then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["WeekData"].LimitAllScore;
		elseif nCycleType == eRankCycle_History then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["HistoryData"].LimitAllScore;
		end
	elseif nModeType == eRankMode_Team then	
		if nCycleType == eRankCycle_Day then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["TodayData"].TeamAllScore;
		elseif nCycleType == eRankCycle_Week then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["WeekData"].TeamAllScore;
		elseif nCycleType == eRankCycle_History then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew()["HistoryData"].TeamAllScore;
		end
	elseif nModeType == eRankMode_Endless_Area then	
		if nCycleType == eRankCycle_Day then
			modelSelf[nCycleType].nEndlessAreaScore, modelSelf[nCycleType].nEndlessAreaTime = 
				CPlayerGradeInfoMgr:Instance():GetAllDataNew()["TodayData"].EndlessAreaScore, CPlayerGradeInfoMgr:Instance():GetAllDataNew().nEndlessTimeToday;
		elseif nCycleType == eRankCycle_Week then
			modelSelf[nCycleType].nEndlessAreaScore, modelSelf[nCycleType].nEndlessAreaTime = 
				CPlayerGradeInfoMgr:Instance():GetAllDataNew()["WeekData"].EndlessAreaScore, CPlayerGradeInfoMgr:Instance():GetAllDataNew().nEndlessTimeWeek;
		elseif nCycleType == eRankCycle_History then
			modelSelf[nCycleType].nEndlessAreaScore, modelSelf[nCycleType].nEndlessAreaTime = 
				CPlayerGradeInfoMgr:Instance():GetAllDataNew()["HistoryData"].EndlessAreaScore, CPlayerGradeInfoMgr:Instance():GetAllDataNew().nEndlessTimeHistory;
		end
	elseif nModeType == eRankMode_Race then
		if nCycleType == eRankCycle_Day then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew().nRaceScoreDay;
		elseif nCycleType == eRankCycle_Week then
			modelSelf[nCycleType] = CPlayerGradeInfoMgr:Instance():GetAllDataNew().nRaceScoreWeek;
		elseif nCycleType == eRankCycle_Month then
			modelSelf[nCycleType] = g_App:GetCurRaceScore();
		end
	end
end

function CRankDataMgr:OnFolloweesData( Event )
	self.m_tblFollowees = { };
	for _,Data in pairs( Event.tblFollowees ) do
		self.m_tblFollowees[_] = {
			["nAccountID"] = Data.nAccountID;
			["szCharName"] = Data.szCharName;
			["nCurHeadIcon"] = Data.nCurHeadIcon;

			["nCurSeasonStar"] = Data.nCurSeasonStar;
			["SeasonMax"] = Data.SeasonMax;

			["nEndlessDayRecord"] = Data.nEndlessDayRecord;
			["nEndlessWeekRecord"] = Data.nEndlessWeekRecord;
			["nEndlessHistoryRecord"] = Data.nEndlessHistoryRecord;

			["nLimitDayRecord"] = Data.nLimitDayRecord;
			["nLimitWeekRecord"] = Data.nLimitWeekRecord;
			["nLimitHistoryRecord"] = Data.nLimitHistoryRecord;

			["nTeamDayRecord"] = Data.nTeamDayRecord;
			["nTeamWeekRecord"] = Data.nTeamWeekRecord;
			["nTeamHistoryRecord"] = Data.nTeamHistoryRecord;

			["nEndlessDayAreaScore"] = Data.nEndlessDayAreaScore;
			["nEndlessDayAreaTime"] = Data.nEndlessDayAreaTime;
			["nEndlessWeekAreaScore"] = Data.nEndlessWeekAreaScore;
			["nEndlessWeekAreaTime"] = Data.nEndlessWeekAreaTime;
			["nEndlessHistoryAreaScore"] = Data.nEndlessHistoryAreaScore;
			["nEndlessHistoryAreaTime"] = Data.nEndlessHistoryAreaTime;

			["nRaceDayScore"] = Data.nRaceDayScore;
			["nRaceWeekScore"] = Data.nRaceWeekScore;
			["nRaceMonthScore"] = Data.nRaceMonthScore;
		};
	end

	local Event = {};
    Event.m_Type = "RefreshRankWnd";
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CRankDataMgr:OnWorldData( Event )
	local nModeType = self.m_tblRankType[Event.nRankType][1];
	local nCycleType = self.m_tblRankType[Event.nRankType][2];
	self.m_tblWorld[nModeType][nCycleType] = {};
	local tblWorld = self.m_tblWorld[nModeType][nCycleType];
	for k, v in pairs( Event.tblAllRegion ) do
		tblWorld[k] = {}
		tblWorld[k].nAccountID = v.nAccountID;
		tblWorld[k].szCharName = v.szCharName;
		tblWorld[k].nCurHeadIcon = v.nCurHeadIcon;
		if nModeType == eRankMode_Endless_Area then
			tblWorld[k].nRankValue = {}
			tblWorld[k].nRankValue.nEndlessAreaScore = v.nRankValue[1];
			tblWorld[k].nRankValue.nEndlessAreaTime = v.nRankValue[2]; 
		else
			tblWorld[k].nRankValue = v.nRankValue[1];
		end
	end

	local Event = {};
    Event.m_Type = "RefreshRankWnd";
    g_App.m_EventDispatcher:DispatchEvent( Event );
end

function CRankDataMgr:QueryRank( nDataType, nModeType, nCycleType )
	if nDataType == eRankRange_Followees then			-- 好友
		local NetMsg = CQueryFolloweesRank:new();
		g_App:SendShellMsg( NetMsg );
	else		
		for k, v in pairs( self.m_tblRankType ) do
			if v[1] == nModeType and v[2] == nCycleType then
				local NetMsg = CQueryWorldRecord:new( k );
				g_App:SendShellMsg( NetMsg );
				return;
			end
		end
	end
end

function CRankDataMgr:GetFolloweesRankValue( RankData, nRangeType, nModeType, nCycleType )
	if nModeType == eRankMode_Ladder then
		if nCycleType == eRankCycle_Season then
			return RankData.nCurSeasonStar;
		elseif nCycleType == eRankCycle_History then
			return RankData.SeasonMax;
		end
	elseif nModeType == eRankMode_Endless then
		if nCycleType == eRankCycle_Day then
			return RankData.nEndlessDayRecord;
		elseif nCycleType == eRankCycle_Week then
			return RankData.nEndlessWeekRecord;
		elseif nCycleType == eRankCycle_History then
			return RankData.nEndlessHistoryRecord;
		end 
	elseif nModeType == eRankMode_Limit then
		if nCycleType == eRankCycle_Day then
			return RankData.nLimitDayRecord;
		elseif nCycleType == eRankCycle_Week then
			return RankData.nLimitWeekRecord;
		elseif nCycleType == eRankCycle_History then
			return RankData.nLimitHistoryRecord;
		end
	elseif nModeType == eRankMode_Team then
		if nCycleType == eRankCycle_Day then
			return RankData.nTeamDayRecord;
		elseif nCycleType == eRankCycle_Week then
			return RankData.nTeamWeekRecord;
		elseif nCycleType == eRankCycle_History then
			return RankData.nTeamHistoryRecord;
		end
	elseif nModeType == eRankMode_Endless_Area then
		if nCycleType == eRankCycle_Day then
			return { 
				nEndlessAreaScore = RankData.nEndlessDayAreaScore; 
				nEndlessAreaTime = RankData.nEndlessDayAreaTime 
			};
		elseif nCycleType == eRankCycle_Week then
			return {
				nEndlessAreaScore = RankData.nEndlessWeekAreaScore; 
				nEndlessAreaTime = RankData.nEndlessWeekAreaTime 
			};
		elseif nCycleType == eRankCycle_History then
			return { 
				nEndlessAreaScore = RankData.nEndlessHistoryAreaScore; 
				nEndlessAreaTime = RankData.nEndlessHistoryAreaTime 
			};
		end
	elseif nModeType == eRankMode_Race then
		if nCycleType == eRankCycle_Day then
			return RankData.nRaceDayScore;
		elseif nCycleType == eRankCycle_Week then
			return RankData.nRaceWeekScore;
		elseif nCycleType == eRankCycle_Month then
			return RankData.nRaceMonthScore;
		end
	end

	return nil;
end

function AreaCompare(a, b)
	if ( a.nRankValue.nEndlessAreaScore > b.nRankValue.nEndlessAreaScore ) then
		return true;
	elseif ( a.nRankValue.nEndlessAreaScore == b.nRankValue.nEndlessAreaScore ) then
		return a.nRankValue.nEndlessAreaTime < b.nRankValue.nEndlessAreaTime;
	end
	return false;
end

function CRankDataMgr:GetFolloweesRankData()
	for _,Data in pairs( self.m_tblFollowees ) do
		self.m_tblFollowees[_].nRankValue = self:GetFolloweesRankValue( Data, eRankRange_Followees, eRankMode_Ladder, eRankCycle_Season );
	end
	table.sort( self.m_tblFollowees, function( a, b ) return a.nRankValue > b.nRankValue end );
	return self.m_tblFollowees;
end

function CRankDataMgr:GetRankData( nRangeType, nModeType, nCycleType )
	if nRangeType == eRankRange_Followees then
		for _,Data in pairs( self.m_tblFollowees ) do
			if Data.nAccountID == g_App:GetAccountID() then
				self.m_tblFollowees[_].nRankValue = self:GetSelfRankValue(nModeType, nCycleType);
			else
				self.m_tblFollowees[_].nRankValue = self:GetFolloweesRankValue( Data, nRangeType, nModeType, nCycleType );
			end
		end
		if self.m_tblFollowees[1] then		--局内排行 好友今日最高分
			local szEndlessName, nEndlessDay, szLimitName, nLimitDay, szTeamName, nTeamDay;
			table.sort( self.m_tblFollowees, function( a, b ) return a.nEndlessDayAreaScore > b.nEndlessDayAreaScore; end );
			local tblAreaScore = {};
			for i = 1, #self.m_tblFollowees do
				if self.m_tblFollowees[i].nEndlessDayAreaScore == self.m_tblFollowees[1].nEndlessDayAreaScore then
					table.insert( tblAreaScore, self.m_tblFollowees[i] );
				else
					break;
				end
			end
			table.sort( tblAreaScore, function( a, b ) return a.nEndlessDayAreaTime < b.nEndlessDayAreaTime; end );
			szEndlessName = tblAreaScore[1].szCharName;
			nEndlessDay = tblAreaScore[1].nEndlessDayAreaScore;
			
			table.sort( self.m_tblFollowees, function( a, b ) return a.nLimitDayRecord > b.nLimitDayRecord; end );
			szLimitName = self.m_tblFollowees[1].szCharName;
			nLimitDay = self.m_tblFollowees[1].nLimitDayRecord;

			table.sort( self.m_tblFollowees, function( a, b ) return a.nTeamDayRecord > b.nTeamDayRecord; end );
			szTeamName = self.m_tblFollowees[1].szCharName;
			nTeamDay = self.m_tblFollowees[1].nTeamDayRecord;

			g_App:SetFriendTodayScore( szEndlessName, nEndlessDay, szLimitName, nLimitDay, szTeamName, nTeamDay );
		end

		if nModeType == eRankMode_Endless_Area then
			table.sort( self.m_tblFollowees, AreaCompare);
		else
			table.sort( self.m_tblFollowees, function( a, b ) return a.nRankValue > b.nRankValue end );
		end
		return self.m_tblFollowees;
	elseif nRangeType == eRankRange_AllRegion then
		local bNeedSort = false;
		local bSelfIndex = false;
		local tblRankData = self.m_tblWorld[nModeType][nCycleType];
		if not tblRankData then
			return nil;
		end

		local nLen = table.getn( tblRankData );
		for i,Data in pairs( tblRankData ) do
			if Data.nAccountID == g_App:GetAccountID() then
				bSelfIndex = true; -- 自己上榜了
				local nRankValue = self:GetSelfRankValue( nModeType, nCycleType );
				if nModeType == eRankMode_Endless_Area then
					local nEndlessAreaScore, nEndlessAreaTime = nRankValue.nEndlessAreaScore, nRankValue.nEndlessAreaTime;
					if Data.nEndlessAreaScore ~= nEndlessAreaScore or Data.nEndlessAreaTime ~= nEndlessAreaTime then -- 分数发生了改变
						Data.nRankValue = nRankValue;
						bNeedSort = true;
						break;
					end
				else 
					if Data.nRankValue ~= nRankValue then -- 分数发生了改变
						Data.nRankValue = nRankValue;
						bNeedSort = true;
						break;
					end
				end
			end
			if i == nLen and bSelfIndex == false then -- 自己未上榜
				local nRankValue = self:GetSelfRankValue(nModeType, nCycleType);
				if nModeType == eRankMode_Endless_Area then
					local nEndlessAreaScore, nEndlessAreaTime = nRankValue.nEndlessAreaScore, nRankValue.nEndlessAreaTime;
					if nEndlessAreaScore > Data.nRankValue.nEndlessAreaScore or (nEndlessAreaScore == Data.nRankValue.nEndlessAreaScore and nEndlessAreaTime < Data.nRankValue.nEndlessAreaTime ) then
						tblRankData[i] = {
							["nAccountID"] = g_App:GetAccountID();
							["szCharName"] = g_App:GetNickName();
							["nCurHeadIcon"] = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
							["nRankValue"] = nRankValue;
						};
						bNeedSort = true;
						break;
					end
				else
					if nRankValue > Data.nRankValue then
						tblRankData[i] = {
							["nAccountID"] = g_App:GetAccountID();
							["szCharName"] = g_App:GetNickName();
							["nCurHeadIcon"] = g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon();
							["nRankValue"] = nRankValue;
						};
						bNeedSort = true;
						break;
					end
				end
			end
		end

		-- 如果自己未上榜，但分数大于最后榜单，则去掉最后榜单，把自己插入榜单
		if bNeedSort then
			if nModeType == eRankMode_Endless_Area then
				table.sort( tblRankData, AreaCompare );
			else
				table.sort( tblRankData, function( a, b ) return a.nRankValue > b.nRankValue end );
			end
		end
		return tblRankData;
	end
end
--endregion
