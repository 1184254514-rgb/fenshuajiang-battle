--region CPlayerRoomMemberInfoMgr.lua
--Date	2018.3.5
--此文件由[BabeLua]插件自动生成

function CPlayerRoomMemberInfoMgr:Instance()
	if self.m_instance == nil then
       self.m_instance = self:new()
    end
    return self.m_instance;
end

function CPlayerRoomMemberInfoMgr:Ctor()
	self.m_tblAllMemberData = {};
	self.m_tblSelfData = {};
end

function CPlayerRoomMemberInfoMgr:SetData( AllData )	
	self.m_tblAllMemberData = AllData;
	for i = 0, self.m_tblAllMemberData.nCount - 1 do
		local MemberInfo = self.m_tblAllMemberData.members[i];
		if MemberInfo.nAccountID == g_App:GetAccountID() then
			self.m_tblSelfData = MemberInfo;
			break;
		end
	end
end

function CPlayerRoomMemberInfoMgr:GetAllData()
	return self.m_tblAllMemberData;
end

function CPlayerRoomMemberInfoMgr:GetMemberData()
	if not next( self.m_tblAllMemberData ) then
		return nil;
	end
	return self.m_tblAllMemberData.members;
end

function CPlayerRoomMemberInfoMgr:GetCount()
	if not next( self.m_tblAllMemberData ) then
		return 0;
	end
	return self.m_tblAllMemberData.nCount;
end

function CPlayerRoomMemberInfoMgr:GetTeamID()
	if not next( self.m_tblAllMemberData ) then
		return 0;
	end
	return self.m_tblAllMemberData.nTeamID;
end

function CPlayerRoomMemberInfoMgr:GetRoomType()
	if not next( self.m_tblAllMemberData ) then
		return nil;
	end
	return self.m_tblAllMemberData.nType;
end

function CPlayerRoomMemberInfoMgr:ClearData()
	self.m_tblAllMemberData = {};
end

function CPlayerRoomMemberInfoMgr:IsInTeam()
	if not next( self.m_tblAllMemberData ) then
		return false;
	end
	return self.m_tblAllMemberData.nCount > 0;
end

function CPlayerRoomMemberInfoMgr:IsCaptain()
	if not next( self.m_tblAllMemberData ) then
		return false;
	end
	return self.m_tblAllMemberData.members[0].nAccountID == g_App:GetAccountID();
end

function CPlayerRoomMemberInfoMgr:ChangeReady( nAccountID, bReady )
	if not next( self.m_tblAllMemberData ) then
		return false;
	end
	for i = 0, self.m_tblAllMemberData.nCount - 1 do
		local MemberInfo = self.m_tblAllMemberData.members[i];
		if MemberInfo.nAccountID == nAccountID then
			MemberInfo.bReady = bReady;
		end
	end
end

function CPlayerRoomMemberInfoMgr:ReSeat( nNum )
	if not next( self.m_tblAllMemberData ) then
		return false;
	end
	for i = 0, self.m_tblAllMemberData.nCount - 1 do
		local MemberInfo = self.m_tblAllMemberData.members[i];
		MemberInfo.nPos = ( MemberInfo.nPos + nNum - 1 ) % 12 + 1;
	end
end

function CPlayerRoomMemberInfoMgr:GetSelfPos()
	if not next( self.m_tblAllMemberData ) then
		return -1;
	end
	return self.m_tblSelfData.nPos;
end

function CPlayerRoomMemberInfoMgr:GetSelfReady()
	if not next( self.m_tblAllMemberData ) then
		return false;
	end
	return self.m_tblSelfData.bReady;
end
--endregion
