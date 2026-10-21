-- the file come from c++ RoleProperty，don't alter
require "playerdata/CPlayerDBMember"

function CPlayerDB:Ctor( buffer )
	self.m_buffer = buffer;
	self.m_CharBaseData = CPlayerBaseData:new( self.m_buffer, 540 );
	self.m_FirstEvent = CFirstEvent:new( self.m_buffer, 893 );
	self.m_HaveEquip = CHaveEquip:new( self.m_buffer, 1049 );
	self.m_HaveMusic = CHaveMusic:new( self.m_buffer, 1589 );
	self.m_SeasonStarNum = CSeasonStarNum:new( self.m_buffer, 3665 );
	self.m_GoldOnDay = CGoldOnDay:new( self.m_buffer, 3837 );
	self.m_Resource = CResource:new( self.m_buffer, 3897 );
	self.m_WorldPrizeID = CWorldPrizeID:new( self.m_buffer, 3985 );
	self.m_RhythmNoticeBar = CRhythmNoticeBar:new( self.m_buffer, 5037 );
	self.m_DayCommendData = CDayCommendData:new( self.m_buffer, 5165 );
	self.m_BattleFaceData = CBattleFaceData:new( self.m_buffer, 5993 );
	self.m_TreasureBoxData = CTreasureBoxData:new( self.m_buffer, 6321 );
	self.m_FragmentData = CFragmentData:new( self.m_buffer, 6433 );
	self.m_PassiveSkill = CPassiveSkill:new( self.m_buffer, 8509 );
	self.m_DBSkillData = CDBSkillData:new( self.m_buffer, 8557 );
	self.m_RaceScore = CRaceScore:new( self.m_buffer, 9225 );
	self.m_RollActivity = CRollActivity:new( self.m_buffer, 9397 );
	self.m_SignInActivity = CSignInActivity:new( self.m_buffer, 9529 );

	local tbl = {};
	for k, v in pairs( self )  do
		if v.m_nID then
			tbl[v.m_nID] = v;
		end
	end

	for k, v in pairs( tbl )  do
		self[k] = v;
	end
end

function CPlayerDB:GetSize()
	return 9668;
end

function CPlayerDB:GetSBlockDataSize()
	return 24;
end

