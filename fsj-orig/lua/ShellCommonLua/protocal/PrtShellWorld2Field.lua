--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CLimitTimeRoom:OnUnpack( pBuffer )
	self.m_nTeamID = pBuffer:ReadUint64();
	self.m_nRaceRoomID = pBuffer:ReadUint64();
    self.m_nTeamLevel = pBuffer:ReadUint32();
    self.m_nTeamLevelRange = pBuffer:ReadUint32();
    self.m_nPlayerCount = pBuffer:ReadUint8();
	self.m_nType = pBuffer:ReadUint8();
	self.m_nAIUseSkill = pBuffer:ReadUint8();
	self.m_nRaceID = pBuffer:ReadUint8();
	self.tblAccountInfo = {};

	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i] = {};
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nAccountID = pBuffer:ReadUint64();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nKey = ReadUnit64String( pBuffer );
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nHeadID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nEquipID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nMusicID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_szNickName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nFaceID = {};
		for j = 1, MAX_BattleFace_Count do
			self.tblAccountInfo[i].m_nFaceID[j] = pBuffer:ReadUint8();
		end
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nSkillID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nSkillMaxLevel = pBuffer:ReadUint8();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_tblPassiveSkillID = {};
		for j = 1, Max_Passive_Skill_Num do
			self.tblAccountInfo[i].m_tblPassiveSkillID[j] = pBuffer:ReadUint16();
		end
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_tblPassiveSkillTopLevel = {};
		for j = 1, Max_Passive_Skill_Num do
			self.tblAccountInfo[i].m_tblPassiveSkillTopLevel[j] = pBuffer:ReadUint8();
		end
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nStarNum = pBuffer:ReadUint32();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nPos = pBuffer:ReadUint8();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_bDisable = pBuffer:ReadBoolean();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nMatchTime = pBuffer:ReadUint32();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nEquipPassiveSkillTopLevel = pBuffer:ReadInt8();
	end
end

function CLimitTimeRoom:OnNetReply( Connecter, pBuffer )
	local pWorldConn = g_App:GetWorldConn();
	local tblAccountID = {};
	local nType = eRT_LimitTime;		
	if self.m_nType == eMRT_LimitSecret then
		nType = eRT_LimitSecret;
		pWorldConn.m_tblMatchTeamInfo[self.m_nTeamID] = {};
	elseif self.m_nType == eMRT_TeamSecret then
		nType = eRT_TeamSecret;
		pWorldConn.m_tblMatchTeamInfo[self.m_nTeamID] = {};
	elseif self.m_nType == eMRT_LimitRace then
		nType = eRT_LimitRace;
		pWorldConn.m_tblRaceTeamInfo[self.m_nTeamID] = {};
		pWorldConn.m_tblRaceTeamInfo[self.m_nTeamID].nRaceID = self.m_nRaceID;
		pWorldConn.m_tblRaceTeamInfo[self.m_nTeamID].nRaceRoomID = self.m_nRaceRoomID;
	elseif self.m_nType == eMRT_TeamRace then
		nType = eRT_TeamRace;
		pWorldConn.m_tblRaceTeamInfo[self.m_nTeamID] = {};
		pWorldConn.m_tblRaceTeamInfo[self.m_nTeamID].nRaceID = self.m_nRaceID;
		pWorldConn.m_tblRaceTeamInfo[self.m_nTeamID].nRaceRoomID = self.m_nRaceRoomID;
	end
	if self.m_nTeamID and self.m_nType and self.m_nPlayerCount and self.m_nRaceRoomID then
		print( "CLimitTimeRoom:OnNetReply", "self.m_nTeamID "..self.m_nTeamID, "self.m_nType "..self.m_nType, "self.m_nPlayerCount "..self.m_nPlayerCount, "self.m_nRaceRoomID "..self.m_nRaceRoomID );
	end
	for _, info in pairs( self.tblAccountInfo ) do
		pWorldConn:AddAccountInfo(
		info.m_nAccountID,
		nType,
		info.m_nKey,
		info.m_szNickName,
		info.m_nHeadID,
		info.m_nEquipID,
        info.m_nMusicID,
        nil,
		info.m_nFaceID,
		info.m_nSkillID,
		info.m_nSkillMaxLevel,
		info.m_tblPassiveSkillID,
		info.m_tblPassiveSkillTopLevel,
		info.m_nStarNum,
		info.m_nMatchTime,
		info.m_nEquipPassiveSkillTopLevel,
		info.m_nPos,
		info.m_bDisable,
		self.m_nTeamID );

		table.insert( tblAccountID, info.m_nAccountID );
	end
	
	local tblExtend = {};
	tblExtend.m_nMinLevel = self.m_nTeamLevel - self.m_nTeamLevelRange;
	tblExtend.m_nMaxLevel = self.m_nTeamLevel + self.m_nTeamLevelRange;
	tblExtend.m_nAIUseSkill = self.m_nAIUseSkill;

	pWorldConn:AddRoomInfo( nType, tblAccountID, tblExtend, self.m_nTeamID );
end

function CTeamRoom:OnUnpack( pBuffer )
	self.m_nTeamLevel = pBuffer:ReadUint32();
	self.m_nPlayerCount = pBuffer:ReadUint8();

	self.tblAccountInfo = {};

	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i] = {};
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nAccountID = pBuffer:ReadUint64();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nKey = ReadUnit64String( pBuffer );
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nHeadID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nEquipID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nMusicID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nTeamID = pBuffer:ReadUint32();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_szNickName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nFaceID = {};
		for j = 1, MAX_BattleFace_Count do
			self.tblAccountInfo[i].m_nFaceID[j]= pBuffer:ReadUint8();
		end
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nSkillID = pBuffer:ReadUint16();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nSkillMaxLevel = pBuffer:ReadUint8();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_tblPassiveSkillID = {};
		for j = 1, Max_Passive_Skill_Num do
			self.tblAccountInfo[i].m_tblPassiveSkillID[j] = pBuffer:ReadUint16();
		end
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_tblPassiveSkillTopLevel = {};
		for j = 1, Max_Passive_Skill_Num do
			self.tblAccountInfo[i].m_tblPassiveSkillTopLevel[j] = pBuffer:ReadUint8();
		end
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nStarNum = pBuffer:ReadUint32();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nMatchTime = pBuffer:ReadUint32();
	end
	for i = 1, self.m_nPlayerCount do
		self.tblAccountInfo[i].m_nEquipPassiveSkillTopLevel = pBuffer:ReadInt8();
	end
end

function CTeamRoom:OnNetReply( Connecter, pBuffer )
	local pWorldConn = g_App:GetWorldConn();
	local tblRoomInfo = {};
	local tblAccountID = {};
	for i = 1, self.m_nPlayerCount do
		local tblInfo = self.tblAccountInfo[i];
		pWorldConn:AddAccountInfo(
			tblInfo.m_nAccountID,
			eRT_Team,
			tblInfo.m_nKey,
			tblInfo.m_szNickName,
			tblInfo.m_nHeadID,
			tblInfo.m_nEquipID,
			tblInfo.m_nMusicID,
            nil,
			tblInfo.m_nFaceID,
			tblInfo.m_nSkillID,
			tblInfo.m_nSkillMaxLevel,
			tblInfo.m_tblPassiveSkillID,
			tblInfo.m_tblPassiveSkillTopLevel,
			tblInfo.m_nStarNum,
			tblInfo.m_nMatchTime,
			tblInfo.m_nEquipPassiveSkillTopLevel
			);

		if not tblRoomInfo[tblInfo.m_nTeamID] then
			tblRoomInfo[tblInfo.m_nTeamID] = {};
		end

		table.insert( tblAccountID, tblInfo.m_nAccountID );
		table.insert( tblRoomInfo[tblInfo.m_nTeamID], tblInfo.m_nAccountID );
	end

	local tblExtend = {};
	tblExtend.m_nTeamLevel = self.m_nTeamLevel;
	tblExtend.m_tblTeamInfo = tblRoomInfo;
	pWorldConn:AddRoomInfo( eRT_Team, tblAccountID, tblExtend );
end

function CObserveGame:OnUnpack( pBuffer )
	self.m_nAccountID = pBuffer:ReadUint64();
	self.m_nAccountID1 = pBuffer:ReadUint64();
	self.m_nKey = ReadUnit64String( pBuffer );
    self.m_szName = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CObserveGame:OnNetReply( Connecter, pBuffer )
	local pWorldConn = g_App:GetWorldConn();
	pWorldConn:AddAccountInfo(
		self.m_nAccountID,
		eRT_Observe,
		self.m_nKey,
		self.m_szName,
        0,
		0,
        0,
        self.m_nAccountID1,
		nil,
		nil,
		nil );
end

function CEverJoinRace:OnUnpack( pBuffer )
	self.m_tblTeammate = {};
	for i = 1, ETEAM_PLAY_COUNT - 1 do
		self.m_tblTeammate[i] = pBuffer:ReadUint64();
	end
	self.m_nKey = ReadUnit64String( pBuffer );
	self.m_nRoomType = pBuffer:ReadInt8();

	--SPlayerContex
	self.tblInfo = {};
	self.tblInfo["m_nAccountID"] = pBuffer:ReadUint64();
	self.tblInfo["m_nManorID"] = pBuffer:ReadUint32();
	self.tblInfo["m_nHeadIconID"] = pBuffer:ReadUint16();
	self.tblInfo["m_nEquipID"] = pBuffer:ReadUint16();
	self.tblInfo["m_nMusicID"] = pBuffer:ReadUint16();
	self.tblInfo["m_nSkillID"] = pBuffer:ReadUint16();
	self.tblInfo["m_aryFaceID"] = {};
	for i = 1, MAX_BattleFace_Count do
		self.tblInfo["m_aryFaceID"][i] = pBuffer:ReadInt8();
	end
	self.tblInfo["m_nStarNum"] = pBuffer:ReadUint32();
	self.tblInfo["m_nActiveSkillTopLevel"] = pBuffer:ReadInt8();
	self.tblInfo["m_aryPassiveSkillID"] = {};
	self.tblInfo["m_aryPassiveSkillTopLevel"] = {};
	for i = 1, Max_Passive_Skill_Num do
		self.tblInfo["m_aryPassiveSkillID"][i] = pBuffer:ReadUint16();
	end
	for i = 1, Max_Passive_Skill_Num do
		self.tblInfo["m_aryPassiveSkillTopLevel"][i] = pBuffer:ReadInt8();
	end
	self.tblInfo["m_nMatchTime"] = pBuffer:ReadUint32();
	self.tblInfo["m_nEquipPassiveSkillTopLevel"] = pBuffer:ReadInt8();
	self.tblInfo["m_szNickName"] = pBuffer:ReadUTFBytes( CHARNAME_BYTE_SIZE + 1 );
end

function CEverJoinRace:OnNetReply( Connecter, pBuffer )
	local pWorldConn = g_App:GetWorldConn();
	if not pWorldConn then
		return;
	end
	local nSceneID = nil;
	local pScene = nil;
	for i = 1, ETEAM_PLAY_COUNT - 1 do
		nSceneID = pWorldConn:GetPlayerSceneID( self.m_tblTeammate[i] );
		pScene = pWorldConn:GetSceneFromID( nSceneID );
		if pScene then
			break;
		end
	end
	if not pScene then
		return;
	end
	local nManorID = pScene:GetPlayerManorID( self.m_tblTeammate[1] );
	if not pScene:CheckSettled( nManorID ) then
		local NetMsg = CAnswerEverJoinRace:new();
		NetMsg.m_nKey = self.m_nKey;
		NetMsg.m_nSelfAccountID = self.tblInfo.m_nAccountID;
		NetMsg.m_nRoomType = self.m_nRoomType;
		pWorldConn:SendShellMsg( NetMsg );
	end

	pWorldConn:AddAccountInfo(
		self.tblInfo.m_nAccountID,
		nil,
		self.m_nKey,
		self.tblInfo.m_szNickName,
		self.tblInfo.m_nHeadIconID,
		self.tblInfo.m_nEquipID,
        self.tblInfo.m_nMusicID,
        nil,
		self.tblInfo.m_aryFaceID,
		self.tblInfo.m_nSkillID,
		self.tblInfo.m_nActiveSkillTopLevel,
		self.tblInfo.m_aryPassiveSkillID,
		self.tblInfo.m_aryPassiveSkillTopLevel,
		self.tblInfo.m_nStarNum,
		self.tblInfo.m_nMatchTime,
		self.tblInfo.m_nEquipPassiveSkillTopLevel,
		nil,
		nil,
		nil,
		nSceneID,
		nManorID );
end
--endregion
