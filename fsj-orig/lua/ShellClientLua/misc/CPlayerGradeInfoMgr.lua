--region CPlayerGradeInfoMgr.lua
--Date 2017.09.21
--玩家信息管理器

function CPlayerGradeInfoMgr:Instance()
    if self.m_instance == nil then
       self.m_instance = self:new()
    end
    return self.m_instance;
end

function CPlayerGradeInfoMgr:Ctor()
	self.m_tblAllDataNew = {};
end

function CPlayerGradeInfoMgr:QueryAllScoreNewByAccountID( pWorldConn, nAccountID )
	if not pWorldConn then return end;
	local NetMsg = CGetAllRecordNew:new();
	NetMsg.m_nAccountID = nAccountID;
	pWorldConn:SendShellMsg( NetMsg );
end

function CPlayerGradeInfoMgr:SetAllDataNew( Data )
	self.m_tblAllDataNew = Data;
end

function CPlayerGradeInfoMgr:GetAllDataNew()
	if not next( self.m_tblAllDataNew ) then
		return nil;
	end
	return self.m_tblAllDataNew;
end

--endregion
