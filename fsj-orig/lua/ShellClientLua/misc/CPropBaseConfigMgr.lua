--region CPropBaseConfigMgr.lua
--Date 2018.01.11
--资源配置的客户端管理  

CPropBaseConfigMgr = class();

local tblReSourceFileName =
{
	[0] = "currency",
	[1] = "equip",
	[2] = "musicbase",
	[3] = "jiezoutishiqi",
	[4] = "battleface",
	[5] = "treasureboxbase",
	[6] = "fragment",
};

function CPropBaseConfigMgr:Ctor()	
end

function CPropBaseConfigMgr:Inst()
	if not self.m_Inst then
		self.m_Inst = CPropBaseConfigMgr:new();
	end

	return self.m_Inst;
end

function CPropBaseConfigMgr:GetConfig( nType, nIndex )
	if g_tblTabFile[tblReSourceFileName[nType]][nIndex].nRowIndex ~= -1 then
		return g_tblTabFile[tblReSourceFileName[nType]][nIndex];
	else
		return g_tblTabFile.fusion[nIndex];
	end
end

--endregion
