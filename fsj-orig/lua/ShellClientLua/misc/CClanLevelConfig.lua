--region CClanLevelConfig.lua
--Date 2018.03.13

function CClanLevelConfig:Ctor()
end

function CClanLevelConfig:Inst()
	if not self.m_Inst then
		self.m_Inst = CClanLevelConfig:new();
	end
	return self.m_Inst;
end

function CClanLevelConfig:GetLevel( nAllActivity )
	local nLevelCount = g_tblTabFile.clanlevel.nRowCount - 1;
	for i = 1, nLevelCount do 
		local nLevel = g_tblTabFile.clanlevel:GetRow(i).nLevel;
		local nActivityMin = g_tblTabFile.clanlevel[nLevel].nActivityMin;
		local nActivityMax = g_tblTabFile.clanlevel[nLevel].nActivityMax;
		if nAllActivity >= nActivityMin and nAllActivity < nActivityMax then
			return nLevel;
		end
	end
	return 0;
end

function CClanLevelConfig:GetMaxLevel()
	return g_tblTabFile.clanlevel.nRowCount - 1;
end



--endregion
