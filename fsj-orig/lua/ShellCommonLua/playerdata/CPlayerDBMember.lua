-- the file come from c++ RoleProperty，don't alter
require "playerdata/CPlayerDBStruct"


--	begin CPlayerBaseData	--
CPlayerBaseData = class();
CPlayerBaseData.m_nSize = 353;
CPlayerBaseData.m_nID = 0;
CPlayerBaseData.m_aryMemberInfo = {};

function CPlayerBaseData:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 353 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CPlayerBaseData:GetSize()
	return 353;
end

function CPlayerBaseData:GetID()
	return 0;
end

function CPlayerBaseData:GetAccount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUTFBytes( 97 );
end

function CPlayerBaseData:SetAccount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteUTFBytes( v, 97 );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[1] = { 24, 97, "Account" };

function CPlayerBaseData:GetNickName()
	self.m_buffer:SetPosition( self.offset2BufferStart + 121 );
	return self.m_buffer:ReadUTFBytes( 22 );
end

function CPlayerBaseData:SetNickName( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 121 );
	self.m_buffer:WriteUTFBytes( v, 22 );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[2] = { 121, 22, "NickName" };

function CPlayerBaseData:GetCreateTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 143 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetCreateTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 143 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[3] = { 143, 4, "CreateTime" };

function CPlayerBaseData:GetLoginTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 147 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetLoginTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 147 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[4] = { 147, 4, "LoginTime" };

function CPlayerBaseData:GetLogoutTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 151 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetLogoutTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 151 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[5] = { 151, 4, "LogoutTime" };

function CPlayerBaseData:GetBanChatTimeEnd()
	self.m_buffer:SetPosition( self.offset2BufferStart + 155 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetBanChatTimeEnd( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 155 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[6] = { 155, 4, "BanChatTimeEnd" };

function CPlayerBaseData:GetCurEquipID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 159 );
	return self.m_buffer:ReadUint16();
end

function CPlayerBaseData:SetCurEquipID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 159 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[7] = { 159, 2, "CurEquipID" };

function CPlayerBaseData:GetCurTask()
	self.m_buffer:SetPosition( self.offset2BufferStart + 161 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetCurTask( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 161 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[8] = { 161, 1, "CurTask" };

function CPlayerBaseData:GetAllGameTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 162 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetAllGameTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 162 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[9] = { 162, 4, "AllGameTime" };

function CPlayerBaseData:GetAllGameScore()
	self.m_buffer:SetPosition( self.offset2BufferStart + 166 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetAllGameScore( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 166 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[10] = { 166, 4, "AllGameScore" };

function CPlayerBaseData:GetAllStar()
	self.m_buffer:SetPosition( self.offset2BufferStart + 170 );
	return self.m_buffer:ReadInt32();
end

function CPlayerBaseData:SetAllStar( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 170 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[11] = { 170, 4, "AllStar" };

function CPlayerBaseData:GetRenameNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 174 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetRenameNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 174 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[12] = { 174, 4, "RenameNum" };

function CPlayerBaseData:GetCurHeadIcon()
	self.m_buffer:SetPosition( self.offset2BufferStart + 178 );
	return self.m_buffer:ReadUint16();
end

function CPlayerBaseData:SetCurHeadIcon( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 178 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[13] = { 178, 2, "CurHeadIcon" };

function CPlayerBaseData:GetLadderStarChangeTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 180 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetLadderStarChangeTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 180 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[14] = { 180, 4, "LadderStarChangeTime" };

function CPlayerBaseData:GetStreakNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 184 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetStreakNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 184 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[15] = { 184, 4, "StreakNum" };

function CPlayerBaseData:GetProtectScore()
	self.m_buffer:SetPosition( self.offset2BufferStart + 188 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetProtectScore( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 188 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[16] = { 188, 4, "ProtectScore" };

function CPlayerBaseData:GetInitData()
	self.m_buffer:SetPosition( self.offset2BufferStart + 192 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetInitData( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 192 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[17] = { 192, 1, "InitData" };

function CPlayerBaseData:GetCurRhythmNoticeBarID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 193 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetCurRhythmNoticeBarID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 193 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[18] = { 193, 1, "CurRhythmNoticeBarID" };

function CPlayerBaseData:GetSkillID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 194 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetSkillID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 194 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[19] = { 194, 4, "SkillID" };

function CPlayerBaseData:GetRechargeID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 198 );
	return self.m_buffer:ReadUint64();
end

function CPlayerBaseData:SetRechargeID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 198 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[20] = { 198, 8, "RechargeID" };

function CPlayerBaseData:GetBeCommendCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 206 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetBeCommendCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 206 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[21] = { 206, 4, "BeCommendCount" };

function CPlayerBaseData:GetExp()
	self.m_buffer:SetPosition( self.offset2BufferStart + 210 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetExp( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 210 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[22] = { 210, 4, "Exp" };

function CPlayerBaseData:GetEndlessGameScore()
	self.m_buffer:SetPosition( self.offset2BufferStart + 214 );
	return self.m_buffer:ReadUint64();
end

function CPlayerBaseData:SetEndlessGameScore( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 214 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[23] = { 214, 8, "EndlessGameScore" };

function CPlayerBaseData:GetLimitGameScore()
	self.m_buffer:SetPosition( self.offset2BufferStart + 222 );
	return self.m_buffer:ReadUint64();
end

function CPlayerBaseData:SetLimitGameScore( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 222 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[24] = { 222, 8, "LimitGameScore" };

function CPlayerBaseData:GetTeamGameScore()
	self.m_buffer:SetPosition( self.offset2BufferStart + 230 );
	return self.m_buffer:ReadUint64();
end

function CPlayerBaseData:SetTeamGameScore( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 230 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[25] = { 230, 8, "TeamGameScore" };

function CPlayerBaseData:GetAccumulateCouldObtainGold()
	self.m_buffer:SetPosition( self.offset2BufferStart + 238 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetAccumulateCouldObtainGold( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 238 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[26] = { 238, 4, "AccumulateCouldObtainGold" };

function CPlayerBaseData:GetVipGetTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 242 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetVipGetTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 242 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[27] = { 242, 4, "VipGetTime" };

function CPlayerBaseData:GetVipEndTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 246 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetVipEndTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 246 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[28] = { 246, 4, "VipEndTime" };

function CPlayerBaseData:GetVipPrizeGetTime()
	self.m_buffer:SetPosition( self.offset2BufferStart + 250 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetVipPrizeGetTime( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 250 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[29] = { 250, 4, "VipPrizeGetTime" };

function CPlayerBaseData:GetEndlessStrikeOthersTipCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 254 );
	return self.m_buffer:ReadUint16();
end

function CPlayerBaseData:SetEndlessStrikeOthersTipCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 254 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[30] = { 254, 2, "EndlessStrikeOthersTipCount" };

function CPlayerBaseData:GetEndlessMakeManorTipCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 256 );
	return self.m_buffer:ReadUint16();
end

function CPlayerBaseData:SetEndlessMakeManorTipCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 256 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[31] = { 256, 2, "EndlessMakeManorTipCount" };

function CPlayerBaseData:GetEndlessStrikeSelfTipCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 258 );
	return self.m_buffer:ReadUint16();
end

function CPlayerBaseData:SetEndlessStrikeSelfTipCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 258 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[32] = { 258, 2, "EndlessStrikeSelfTipCount" };

function CPlayerBaseData:GetEndlessDiedTipCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 260 );
	return self.m_buffer:ReadUint16();
end

function CPlayerBaseData:SetEndlessDiedTipCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 260 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[33] = { 260, 2, "EndlessDiedTipCount" };

function CPlayerBaseData:GetFirstRaceNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 262 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetFirstRaceNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 262 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[34] = { 262, 1, "FirstRaceNum" };

function CPlayerBaseData:GetSecondRaceNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 263 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetSecondRaceNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 263 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[35] = { 263, 1, "SecondRaceNum" };

function CPlayerBaseData:GetGMQueryCountToday()
	self.m_buffer:SetPosition( self.offset2BufferStart + 264 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetGMQueryCountToday( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 264 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[36] = { 264, 1, "GMQueryCountToday" };

function CPlayerBaseData:GetGMNotSolveCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 265 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetGMNotSolveCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 265 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[37] = { 265, 1, "GMNotSolveCount" };

function CPlayerBaseData:GetGMAnswerID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 266 );
	return self.m_buffer:ReadUint32();
end

function CPlayerBaseData:SetGMAnswerID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 266 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[38] = { 266, 4, "GMAnswerID" };

function CPlayerBaseData:GetSex()
	self.m_buffer:SetPosition( self.offset2BufferStart + 270 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetSex( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 270 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[39] = { 270, 1, "Sex" };

function CPlayerBaseData:GetAge()
	self.m_buffer:SetPosition( self.offset2BufferStart + 271 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetAge( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 271 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[40] = { 271, 1, "Age" };

function CPlayerBaseData:GetConstellation()
	self.m_buffer:SetPosition( self.offset2BufferStart + 272 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetConstellation( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 272 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[41] = { 272, 1, "Constellation" };

function CPlayerBaseData:GetArea()
	self.m_buffer:SetPosition( self.offset2BufferStart + 273 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetArea( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 273 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[42] = { 273, 1, "Area" };

function CPlayerBaseData:GetSignature()
	self.m_buffer:SetPosition( self.offset2BufferStart + 274 );
	return self.m_buffer:ReadUTFBytes( 76 );
end

function CPlayerBaseData:SetSignature( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 274 );
	self.m_buffer:WriteUTFBytes( v, 76 );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[43] = { 274, 76, "Signature" };

function CPlayerBaseData:GetTodayReportNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 350 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetTodayReportNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 350 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[44] = { 350, 1, "TodayReportNum" };

function CPlayerBaseData:GetFirstTeamRaceNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 351 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetFirstTeamRaceNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 351 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[45] = { 351, 1, "FirstTeamRaceNum" };

function CPlayerBaseData:GetSecondTeamRaceNum()
	self.m_buffer:SetPosition( self.offset2BufferStart + 352 );
	return self.m_buffer:ReadUint8();
end

function CPlayerBaseData:SetSecondTeamRaceNum( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 352 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 540 );
end

CPlayerBaseData.m_aryMemberInfo[46] = { 352, 1, "SecondTeamRaceNum" };

--	end CPlayerBaseData	--


--	begin CFirstEvent	--
CFirstEvent = class();
CFirstEvent.m_nSize = 156;
CFirstEvent.m_nID = 1;
CFirstEvent.m_aryMemberInfo = {};

function CFirstEvent:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 156 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CFirstEvent:GetSize()
	return 156;
end

function CFirstEvent:GetID()
	return 1;
end

function CFirstEvent:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CFirstEvent:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 893 );
end

function CFirstEvent:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CFirstEvent:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 893 );
end

function CFirstEvent:GetDataMaxCount()
	return 32;
end

function CFirstEvent:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 32 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CFirstEvent:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 32 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 893 );
end

CFirstEvent.m_aryMemberInfo[1] = { 28, 4, "Data", 32, nil };

--	end CFirstEvent	--


--	begin CHaveEquip	--
CHaveEquip = class();
CHaveEquip.m_nSize = 540;
CHaveEquip.m_nID = 2;
CHaveEquip.m_aryMemberInfo = {};

function CHaveEquip:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 540 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CHaveEquip:GetSize()
	return 540;
end

function CHaveEquip:GetID()
	return 2;
end

function CHaveEquip:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	return self.m_buffer:ReadUint16();
end

function CHaveEquip:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 1049 );
end

function CHaveEquip:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CHaveEquip:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 1049 );
end

function CHaveEquip:GetDataMaxCount()
	return 256;
end

function CHaveEquip:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 256 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 2 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 2 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 2, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CHaveEquip:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 256 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 2, 2 );
	local buffer = CBufferStream:new( 2 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 2 );
	self.m_buffer:WriteBytes( buffer, 0, 2 );
	RegistCommitData( self.m_buffer, 1049 );
end

CHaveEquip.m_aryMemberInfo[1] = { 28, 2, "Data", 256, nil };

--	end CHaveEquip	--


--	begin CHaveMusic	--
CHaveMusic = class();
CHaveMusic.m_nSize = 2076;
CHaveMusic.m_nID = 3;
CHaveMusic.m_aryMemberInfo = {};

function CHaveMusic:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 2076 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CHaveMusic:GetSize()
	return 2076;
end

function CHaveMusic:GetID()
	return 3;
end

function CHaveMusic:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	return self.m_buffer:ReadUint16();
end

function CHaveMusic:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	self.m_buffer:WriteInt16( v );
	RegistCommitData( self.m_buffer, 1589 );
end

function CHaveMusic:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CHaveMusic:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 1589 );
end

function CHaveMusic:GetDataMaxCount()
	return 1024;
end

function CHaveMusic:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 1024 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 2 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 2 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 2, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CHaveMusic:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 1024 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 2, 2 );
	local buffer = CBufferStream:new( 2 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 2 );
	self.m_buffer:WriteBytes( buffer, 0, 2 );
	RegistCommitData( self.m_buffer, 1589 );
end

CHaveMusic.m_aryMemberInfo[1] = { 28, 2, "Data", 1024, nil };

--	end CHaveMusic	--


--	begin CSeasonStarNum	--
CSeasonStarNum = class();
CSeasonStarNum.m_nSize = 172;
CSeasonStarNum.m_nID = 4;
CSeasonStarNum.m_aryMemberInfo = {};

function CSeasonStarNum:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 172 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CSeasonStarNum:GetSize()
	return 172;
end

function CSeasonStarNum:GetID()
	return 4;
end

function CSeasonStarNum:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CSeasonStarNum:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3665 );
end

function CSeasonStarNum:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CSeasonStarNum:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3665 );
end

function CSeasonStarNum:GetDataMaxCount()
	return 36;
end

function CSeasonStarNum:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 36 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CSeasonStarNum:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 36 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 3665 );
end

CSeasonStarNum.m_aryMemberInfo[1] = { 28, 4, "Data", 36, nil };

--	end CSeasonStarNum	--


--	begin CGoldOnDay	--
CGoldOnDay = class();
CGoldOnDay.m_nSize = 60;
CGoldOnDay.m_nID = 5;
CGoldOnDay.m_aryMemberInfo = {};

function CGoldOnDay:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 60 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CGoldOnDay:GetSize()
	return 60;
end

function CGoldOnDay:GetID()
	return 5;
end

function CGoldOnDay:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CGoldOnDay:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3837 );
end

function CGoldOnDay:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CGoldOnDay:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3837 );
end

function CGoldOnDay:GetDataMaxCount()
	return 8;
end

function CGoldOnDay:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 8 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CGoldOnDay:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 8 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 3837 );
end

CGoldOnDay.m_aryMemberInfo[1] = { 28, 4, "Data", 8, nil };

--	end CGoldOnDay	--


--	begin CResource	--
CResource = class();
CResource.m_nSize = 88;
CResource.m_nID = 6;
CResource.m_aryMemberInfo = {};

function CResource:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 88 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CResource:GetSize()
	return 88;
end

function CResource:GetID()
	return 6;
end

function CResource:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CResource:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3897 );
end

function CResource:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CResource:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3897 );
end

function CResource:GetDataMaxCount()
	return 15;
end

function CResource:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 15 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CResource:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 15 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 3897 );
end

CResource.m_aryMemberInfo[1] = { 28, 4, "Data", 15, nil };

--	end CResource	--


--	begin CWorldPrizeID	--
CWorldPrizeID = class();
CWorldPrizeID.m_nSize = 1052;
CWorldPrizeID.m_nID = 7;
CWorldPrizeID.m_aryMemberInfo = {};

function CWorldPrizeID:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 1052 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CWorldPrizeID:GetSize()
	return 1052;
end

function CWorldPrizeID:GetID()
	return 7;
end

function CWorldPrizeID:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CWorldPrizeID:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3985 );
end

function CWorldPrizeID:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CWorldPrizeID:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 3985 );
end

function CWorldPrizeID:GetDataMaxCount()
	return 256;
end

function CWorldPrizeID:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 256 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CWorldPrizeID:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 256 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 3985 );
end

CWorldPrizeID.m_aryMemberInfo[1] = { 28, 4, "Data", 256, nil };

--	end CWorldPrizeID	--


--	begin CRhythmNoticeBar	--
CRhythmNoticeBar = class();
CRhythmNoticeBar.m_nSize = 128;
CRhythmNoticeBar.m_nID = 8;
CRhythmNoticeBar.m_aryMemberInfo = {};

function CRhythmNoticeBar:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 128 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CRhythmNoticeBar:GetSize()
	return 128;
end

function CRhythmNoticeBar:GetID()
	return 8;
end

function CRhythmNoticeBar:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 1 );
	return self.m_buffer:ReadUint8();
end

function CRhythmNoticeBar:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 1 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 5037 );
end

function CRhythmNoticeBar:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CRhythmNoticeBar:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 5037 );
end

function CRhythmNoticeBar:GetDataMaxCount()
	return 100;
end

function CRhythmNoticeBar:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 100 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 1 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 1 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 1, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CRhythmNoticeBar:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 100 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 1 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 1, 1 );
	local buffer = CBufferStream:new( 1 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 1 );
	self.m_buffer:WriteBytes( buffer, 0, 1 );
	RegistCommitData( self.m_buffer, 5037 );
end

CRhythmNoticeBar.m_aryMemberInfo[1] = { 28, 1, "Data", 100, nil };

--	end CRhythmNoticeBar	--


--	begin CDayCommendData	--
CDayCommendData = class();
CDayCommendData.m_nSize = 828;
CDayCommendData.m_nID = 9;
CDayCommendData.m_aryMemberInfo = {};

function CDayCommendData:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 828 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CDayCommendData:GetSize()
	return 828;
end

function CDayCommendData:GetID()
	return 9;
end

function CDayCommendData:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 8 );
	return self.m_buffer:ReadUint64();
end

function CDayCommendData:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 8 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 5165 );
end

function CDayCommendData:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CDayCommendData:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 5165 );
end

function CDayCommendData:GetDataMaxCount()
	return 100;
end

function CDayCommendData:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 100 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 8 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 8 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 8, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CDayCommendData:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 100 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 8 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 8, 8 );
	local buffer = CBufferStream:new( 8 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 8 );
	self.m_buffer:WriteBytes( buffer, 0, 8 );
	RegistCommitData( self.m_buffer, 5165 );
end

CDayCommendData.m_aryMemberInfo[1] = { 28, 8, "Data", 100, nil };

--	end CDayCommendData	--


--	begin CBattleFaceData	--
CBattleFaceData = class();
CBattleFaceData.m_nSize = 328;
CBattleFaceData.m_nID = 10;
CBattleFaceData.m_aryMemberInfo = {};

function CBattleFaceData:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 328 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CBattleFaceData:GetSize()
	return 328;
end

function CBattleFaceData:GetID()
	return 10;
end

function CBattleFaceData:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	return SBattleFace:new( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 2, self.offset2BufferStart );
end

function CBattleFaceData:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	self.m_buffer:WriteBytes( v.m_buffer, v.offset2BufferStart, 2 );
	RegistCommitData( self.m_buffer, 5993 );
end

function CBattleFaceData:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CBattleFaceData:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 5993 );
end

function CBattleFaceData:GetDataMaxCount()
	return 150;
end

function CBattleFaceData:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 150 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 2 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 2 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 2, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CBattleFaceData:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 150 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 2 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 2, 2 );
	local buffer = CBufferStream:new( 2 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 2 );
	self.m_buffer:WriteBytes( buffer, 0, 2 );
	RegistCommitData( self.m_buffer, 5993 );
end

CBattleFaceData.m_aryMemberInfo[1] = { 28, 2, "Data", 150, nil };

--	end CBattleFaceData	--


--	begin CTreasureBoxData	--
CTreasureBoxData = class();
CTreasureBoxData.m_nSize = 112;
CTreasureBoxData.m_nID = 11;
CTreasureBoxData.m_aryMemberInfo = {};

function CTreasureBoxData:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 112 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CTreasureBoxData:GetSize()
	return 112;
end

function CTreasureBoxData:GetID()
	return 11;
end

function CTreasureBoxData:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	return STreasureBoxData:new( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 14, self.offset2BufferStart );
end

function CTreasureBoxData:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 14 );
	self.m_buffer:WriteBytes( v.m_buffer, v.offset2BufferStart, 14 );
	RegistCommitData( self.m_buffer, 6321 );
end

function CTreasureBoxData:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CTreasureBoxData:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 6321 );
end

function CTreasureBoxData:GetDataMaxCount()
	return 6;
end

function CTreasureBoxData:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 6 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 14 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 14 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 14, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CTreasureBoxData:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 6 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 14 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 14, 14 );
	local buffer = CBufferStream:new( 14 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 14 );
	self.m_buffer:WriteBytes( buffer, 0, 14 );
	RegistCommitData( self.m_buffer, 6321 );
end

CTreasureBoxData.m_aryMemberInfo[1] = { 28, 14, "Data", 6, nil };

--	end CTreasureBoxData	--


--	begin CFragmentData	--
CFragmentData = class();
CFragmentData.m_nSize = 2076;
CFragmentData.m_nID = 12;
CFragmentData.m_aryMemberInfo = {};

function CFragmentData:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 2076 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CFragmentData:GetSize()
	return 2076;
end

function CFragmentData:GetID()
	return 12;
end

function CFragmentData:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	return SFragmentData:new( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 8, self.offset2BufferStart );
end

function CFragmentData:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 8 );
	self.m_buffer:WriteBytes( v.m_buffer, v.offset2BufferStart, 8 );
	RegistCommitData( self.m_buffer, 6433 );
end

function CFragmentData:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CFragmentData:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 6433 );
end

function CFragmentData:GetDataMaxCount()
	return 256;
end

function CFragmentData:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 256 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 8 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 8 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 8, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CFragmentData:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 256 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 8 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 8, 8 );
	local buffer = CBufferStream:new( 8 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 8 );
	self.m_buffer:WriteBytes( buffer, 0, 8 );
	RegistCommitData( self.m_buffer, 6433 );
end

CFragmentData.m_aryMemberInfo[1] = { 28, 8, "Data", 256, nil };

--	end CFragmentData	--


--	begin CPassiveSkill	--
CPassiveSkill = class();
CPassiveSkill.m_nSize = 48;
CPassiveSkill.m_nID = 13;
CPassiveSkill.m_aryMemberInfo = {};

function CPassiveSkill:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 48 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CPassiveSkill:GetSize()
	return 48;
end

function CPassiveSkill:GetID()
	return 13;
end

function CPassiveSkill:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CPassiveSkill:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 8509 );
end

function CPassiveSkill:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CPassiveSkill:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 8509 );
end

function CPassiveSkill:GetDataMaxCount()
	return 5;
end

function CPassiveSkill:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 5 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CPassiveSkill:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 5 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 8509 );
end

CPassiveSkill.m_aryMemberInfo[1] = { 28, 4, "Data", 5, nil };

--	end CPassiveSkill	--


--	begin CDBSkillData	--
CDBSkillData = class();
CDBSkillData.m_nSize = 668;
CDBSkillData.m_nID = 14;
CDBSkillData.m_aryMemberInfo = {};

function CDBSkillData:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 668 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CDBSkillData:GetSize()
	return 668;
end

function CDBSkillData:GetID()
	return 14;
end

function CDBSkillData:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	return SDBSkillData:new( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 5, self.offset2BufferStart );
end

function CDBSkillData:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 5 );
	self.m_buffer:WriteBytes( v.m_buffer, v.offset2BufferStart, 5 );
	RegistCommitData( self.m_buffer, 8557 );
end

function CDBSkillData:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CDBSkillData:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 8557 );
end

function CDBSkillData:GetDataMaxCount()
	return 128;
end

function CDBSkillData:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 128 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 5 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 5 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 5, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CDBSkillData:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 128 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 5 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 5, 5 );
	local buffer = CBufferStream:new( 5 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 5 );
	self.m_buffer:WriteBytes( buffer, 0, 5 );
	RegistCommitData( self.m_buffer, 8557 );
end

CDBSkillData.m_aryMemberInfo[1] = { 28, 5, "Data", 128, nil };

--	end CDBSkillData	--


--	begin CRaceScore	--
CRaceScore = class();
CRaceScore.m_nSize = 172;
CRaceScore.m_nID = 15;
CRaceScore.m_aryMemberInfo = {};

function CRaceScore:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 172 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CRaceScore:GetSize()
	return 172;
end

function CRaceScore:GetID()
	return 15;
end

function CRaceScore:GetData( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CRaceScore:SetData( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9225 );
end

function CRaceScore:GetDataCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint32();
end

function CRaceScore:SetDataCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9225 );
end

function CRaceScore:GetDataMaxCount()
	return 36;
end

function CRaceScore:AddData( v, nIndex )
	local nCurCount = self:GetDataCount();
	if nCurCount >= 36 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nIndex * 4, nSize );
	self:SetData( v, nIndex );
	self:SetDataCount( nCurCount + 1);
	return true;
end

function CRaceScore:DelData( nIndex )
	local nCurCount = self:GetDataCount() - 1;
	if nCurCount >= 36 then
		return false;
	end
	self:SetDataCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 28 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 28 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 9225 );
end

CRaceScore.m_aryMemberInfo[1] = { 28, 4, "Data", 36, nil };

--	end CRaceScore	--


--	begin CRollActivity	--
CRollActivity = class();
CRollActivity.m_nSize = 132;
CRollActivity.m_nID = 16;
CRollActivity.m_aryMemberInfo = {};

function CRollActivity:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 132 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CRollActivity:GetSize()
	return 132;
end

function CRollActivity:GetID()
	return 16;
end

function CRollActivity:GetAccountID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint64();
end

function CRollActivity:SetAccountID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 9397 );
end

CRollActivity.m_aryMemberInfo[1] = { 24, 8, "AccountID" };

function CRollActivity:GetRollType()
	self.m_buffer:SetPosition( self.offset2BufferStart + 32 );
	return self.m_buffer:ReadUint32();
end

function CRollActivity:SetRollType( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 32 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9397 );
end

CRollActivity.m_aryMemberInfo[2] = { 32, 4, "RollType" };

function CRollActivity:GetRollValue300()
	self.m_buffer:SetPosition( self.offset2BufferStart + 36 );
	return self.m_buffer:ReadUint32();
end

function CRollActivity:SetRollValue300( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 36 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9397 );
end

CRollActivity.m_aryMemberInfo[3] = { 36, 4, "RollValue300" };

function CRollActivity:GetRollValue600()
	self.m_buffer:SetPosition( self.offset2BufferStart + 40 );
	return self.m_buffer:ReadUint32();
end

function CRollActivity:SetRollValue600( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 40 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9397 );
end

CRollActivity.m_aryMemberInfo[4] = { 40, 4, "RollValue600" };

function CRollActivity:GetRollValue900()
	self.m_buffer:SetPosition( self.offset2BufferStart + 44 );
	return self.m_buffer:ReadUint32();
end

function CRollActivity:SetRollValue900( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 44 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9397 );
end

CRollActivity.m_aryMemberInfo[5] = { 44, 4, "RollValue900" };

function CRollActivity:GetRollIndex( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 52 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CRollActivity:SetRollIndex( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 52 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9397 );
end

function CRollActivity:GetRollIndexCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 48 );
	return self.m_buffer:ReadUint32();
end

function CRollActivity:SetRollIndexCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 48 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9397 );
end

function CRollActivity:GetRollIndexMaxCount()
	return 20;
end

function CRollActivity:AddRollIndex( v, nIndex )
	local nCurCount = self:GetRollIndexCount();
	if nCurCount >= 20 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 52 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 52 + nIndex * 4, nSize );
	self:SetRollIndex( v, nIndex );
	self:SetRollIndexCount( nCurCount + 1);
	return true;
end

function CRollActivity:DelRollIndex( nIndex )
	local nCurCount = self:GetRollIndexCount() - 1;
	if nCurCount >= 20 then
		return false;
	end
	self:SetRollIndexCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 52 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 52 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 52 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 9397 );
end

CRollActivity.m_aryMemberInfo[6] = { 52, 4, "RollIndex", 20, nil };

--	end CRollActivity	--


--	begin CSignInActivity	--
CSignInActivity = class();
CSignInActivity.m_nSize = 137;
CSignInActivity.m_nID = 17;
CSignInActivity.m_aryMemberInfo = {};

function CSignInActivity:Ctor( buffer, offset )
	self.m_buffer = buffer or CBufferStream:new( 137 );
	self.offset2BufferStart = buffer and offset or 0;
end

function CSignInActivity:GetSize()
	return 137;
end

function CSignInActivity:GetID()
	return 17;
end

function CSignInActivity:GetAccountID()
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	return self.m_buffer:ReadUint64();
end

function CSignInActivity:SetAccountID( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 24 );
	self.m_buffer:WriteUint64( v );
	RegistCommitData( self.m_buffer, 9529 );
end

CSignInActivity.m_aryMemberInfo[1] = { 24, 8, "AccountID" };

function CSignInActivity:GetSignIn()
	self.m_buffer:SetPosition( self.offset2BufferStart + 32 );
	return self.m_buffer:ReadUint8();
end

function CSignInActivity:SetSignIn( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 32 );
	self.m_buffer:WriteInt8( v );
	RegistCommitData( self.m_buffer, 9529 );
end

CSignInActivity.m_aryMemberInfo[2] = { 32, 1, "SignIn" };

function CSignInActivity:GetSingleYearMonth( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 37 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CSignInActivity:SetSingleYearMonth( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 37 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9529 );
end

function CSignInActivity:GetSingleYearMonthCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 33 );
	return self.m_buffer:ReadUint32();
end

function CSignInActivity:SetSingleYearMonthCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 33 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9529 );
end

function CSignInActivity:GetSingleYearMonthMaxCount()
	return 12;
end

function CSignInActivity:AddSingleYearMonth( v, nIndex )
	local nCurCount = self:GetSingleYearMonthCount();
	if nCurCount >= 12 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 37 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 37 + nIndex * 4, nSize );
	self:SetSingleYearMonth( v, nIndex );
	self:SetSingleYearMonthCount( nCurCount + 1);
	return true;
end

function CSignInActivity:DelSingleYearMonth( nIndex )
	local nCurCount = self:GetSingleYearMonthCount() - 1;
	if nCurCount >= 12 then
		return false;
	end
	self:SetSingleYearMonthCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 37 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 37 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 37 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 9529 );
end

CSignInActivity.m_aryMemberInfo[3] = { 37, 4, "SingleYearMonth", 12, nil };

function CSignInActivity:GetDoubleYearMonth( nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 89 + nIndex * 4 );
	return self.m_buffer:ReadUint32();
end

function CSignInActivity:SetDoubleYearMonth( v, nIndex )
	assert( nIndex and nIndex >= 0 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 89 + nIndex * 4 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9529 );
end

function CSignInActivity:GetDoubleYearMonthCount()
	self.m_buffer:SetPosition( self.offset2BufferStart + 85 );
	return self.m_buffer:ReadUint32();
end

function CSignInActivity:SetDoubleYearMonthCount( v )
	self.m_buffer:SetPosition( self.offset2BufferStart + 85 );
	self.m_buffer:WriteInt32( v );
	RegistCommitData( self.m_buffer, 9529 );
end

function CSignInActivity:GetDoubleYearMonthMaxCount()
	return 12;
end

function CSignInActivity:AddDoubleYearMonth( v, nIndex )
	local nCurCount = self:GetDoubleYearMonthCount();
	if nCurCount >= 12 then
		return false;
	end
	if nIndex == nil or nIndex > nCurCount then
		 nIndex = nCurCount;
	end
	local nSize = 4 * ( nCurCount - nIndex );
	self.m_buffer:SetPosition( self.offset2BufferStart + 89 + ( nIndex + 1 ) * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 89 + nIndex * 4, nSize );
	self:SetDoubleYearMonth( v, nIndex );
	self:SetDoubleYearMonthCount( nCurCount + 1);
	return true;
end

function CSignInActivity:DelDoubleYearMonth( nIndex )
	local nCurCount = self:GetDoubleYearMonthCount() - 1;
	if nCurCount >= 12 then
		return false;
	end
	self:SetDoubleYearMonthCount( nCurCount );
	self.m_buffer:SetPosition( self.offset2BufferStart + 89 + nIndex * 4 );
	self.m_buffer:WriteBytes( self.m_buffer, self.offset2BufferStart + 89 + nCurCount * 4, 4 );
	local buffer = CBufferStream:new( 4 );
	self.m_buffer:SetPosition( self.offset2BufferStart + 89 + nCurCount * 4 );
	self.m_buffer:WriteBytes( buffer, 0, 4 );
	RegistCommitData( self.m_buffer, 9529 );
end

CSignInActivity.m_aryMemberInfo[4] = { 89, 4, "DoubleYearMonth", 12, nil };

--	end CSignInActivity	--

