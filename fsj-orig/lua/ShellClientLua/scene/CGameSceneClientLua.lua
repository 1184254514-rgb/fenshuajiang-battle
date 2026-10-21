--region CGameSceneClientLua.lua
--Date 2017-08-05

function CGameSceneClientLua:Ctor()
	CGameScene.Ctor( self );
    self.m_tblAccountID = {};
	self.m_tblAddCommend = {};
	print( "CGameSceneClientLua:Ctor" );
end

function CGameSceneClientLua:OnSceneCreated()
	CGameSceneClient.OnSceneCreated( self );
	g_App:WaitMsg( false );
    g_App:GetGameMain().m_pKillInfoWnd:ClearKillInfo();
	g_App:GetGameStart().m_pWndRaceTeam:ShowWnd( false );
	g_App:GetGameStart().m_pWndRace:ShowWnd( false );
	CPlayerRoomMemberInfoMgr:Instance():ClearData();
end

function CGameSceneClientLua:OnInsertPlayer( pPlayer, posPixel )
	local pManor = pPlayer:GetManor();
    if g_App:GetDirector() == pPlayer then
        self.myManor = pManor;
    end
	local nColorID = pManor:GetColorID();
	local nManorID = pManor:GetManorID();
	local nObjectID = pPlayer:GetObjectID();
	local nAccountID = pPlayer:GetAccountID();
	local szNickName = pPlayer:GetNickName();
	local nEquipID = pPlayer:GetEquipID();

	self.m_tblPlayerInfo[nObjectID] = {
		["m_nColorID"] = nColorID,
		["m_nManorID"] = nManorID,
		["m_szNickName"] = szNickName,
		["m_nEquipID"] = nEquipID;
	};
    if nAccountID > 0 then
        self.m_tblAccountID[nAccountID] = nAccountID;
        g_App:GetGameMain().m_pObserve:RefreshPlayers();
    end
    if self:IsObservedPlayer( pPlayer ) then
        g_App:GetGameMain().m_pObserve:SetMusicID( pPlayer:GetMusicID() );
    end
end

function CGameSceneClientLua:OnRemovePlayer( nAccountID )
    self.m_tblAccountID[nAccountID] = nil;
    g_App:GetGameMain().m_pObserve:RefreshPlayers();
end

function CGameSceneClientLua:GetPlayerList()
    local allPlayers = {};
    local pScene = g_App:GetScene();
    if pScene == nil then
        return allPlayers;
    end

    for k, v in pairs( self.m_tblAccountID ) do
        table.insert( allPlayers, k );
    end
    table.sort( allPlayers, function( a, b )
        local pPlayerA = pScene:GetPlayerByAccountID( a );
        local pPlayerB = pScene:GetPlayerByAccountID( b );
        local color1 = pPlayerA:GetColorID();
        local color2 = pPlayerB:GetColorID();
        return color1 < color2 or color1 == color2 and a < b;
    end );
    return allPlayers;
end

function CGameSceneClientLua:GetPlayerInfo( nObjectID )
	return self.m_tblPlayerInfo[nObjectID];
end

g_killInfoCfg = {};
g_killInfoCfg.priority = { 10, 10, 10, 10, 9, 9, 9, 9, 9, 2 };
g_killInfoCfg.guiName = { "T_shuangsha", "T_sansha", "T_sisha", "T_wusha", "N_dashatesha", "N_zhuzaibisai", "N_sharenruma", "N_wurennengdang", "N_chaoshen", "S_diyidixue" };
g_killInfoCfg.soundName = { "sound/shuangsha.mp3", "sound/sansha.mp3", "sound/sisha.mp3", "sound/wusha.mp3", "sound/dashatesha.mp3", "sound/zhuzaibisai.mp3",
 "sound/sharenruma.mp3", "sound/wurennengdang.mp3", "sound/chaoshen.mp3", "sound/diyidixue.mp3" };
g_killInfoCfg.guiEffect = { "fx/cfg/rybb_zi.eft", "fx/cfg/rybb_zi.eft", "fx/cfg/rybb_zi.eft", "fx/cfg/rybb_zi.eft", "fx/cfg/rybb_huang.eft",
 "fx/cfg/rybb_huang.eft", "fx/cfg/rybb_huang.eft", "fx/cfg/rybb_huang.eft", "fx/cfg/rybb_huang.eft", "fx/cfg/rybb_hong.eft" };

function CGameSceneClientLua:AddKillInfo( szName1, szName2, color1, color2, nType, p0 )
    local killInfo = {};
    killInfo.szName1 = szName1;
    killInfo.szName2 = szName2;
    killInfo.color1 = color1;
    killInfo.color2 = color2;

    if nType == 0 then
        killInfo.priority = 0;
        killInfo.guiName = "Z_jisha";
        killInfo.soundName = "sound/jishabobao.mp3";
        killInfo.guiEffect = "fx/cfg/rybb_hong.eft";
    else
        if p0 then
            killInfo.priority = 0;
        else
            killInfo.priority = g_killInfoCfg.priority[nType];
        end
        killInfo.guiName = g_killInfoCfg.guiName[nType];
        killInfo.soundName = g_killInfoCfg.soundName[nType];
        killInfo.guiEffect = g_killInfoCfg.guiEffect[nType];
    end

    g_App:GetGameMain().m_pKillInfoWnd:AddKillInfo( killInfo );
end

function CGameSceneClientLua:OnPlayerKill( nID, nID1, nKillCount, nKillCount1, bFirstKill )
    local player1 = ClassCast( CPlayerClientLua, self:GetCharacterByID( nID ) );
    local player2 = ClassCast( CPlayerClientLua, self:GetCharacterByID( nID1 ) );
    if player1 == nil or player2 == nil then
        return;
    end

    local szName1 = player1:GetNickName();
    local szName2 = player2:GetNickName();
    local myPlayer = g_App:GetDirector();
    local p0 = false;
    local myObjectID;
    if myPlayer ~= nil then
        self.m_pManor = myPlayer:GetManor();
        
        myObjectID = myPlayer:GetObjectID();
        if myObjectID == nID or myObjectID == nID1 then
            p0 = true;
        end
    end
    local color1 = g_App:GetManorColor( player1:GetManor():GetColorID() );
    local color2 = g_App:GetManorColor( player2:GetManor():GetColorID() );

    if nKillCount >= 2 then
        self:AddKillInfo( szName1, szName2, color1, color2, math.min( 5, nKillCount ) - 1, p0 );
    elseif nKillCount1 >= 3 then
        self:AddKillInfo( szName1, szName2, color1, color2, math.min( 7, nKillCount1 ) + 2, p0 );
    end
    if bFirstKill then
        self:AddKillInfo( szName1, szName2, color1, color2, 10, p0 );
    end
    if nKillCount < 2 and nKillCount1 < 3 and not bFirstKill and p0 then
        self:AddKillInfo( szName1, szName2, color1, color2, 0, p0 );
    end

    if myObjectID == nID1 and self.m_pWanfa.m_pWndRebirthEff ~= nil then
        self.m_pWanfa.m_pWndRebirthEff:GetDlgChild( "jishatishi" ):SetWndText( string.format( g_App:GetString( "beijishatishi" ), szName1 ) );
    end
end

function CGameSceneClientLua:OnCameraChangeSetProgress( fCur )
	local fMaxExpProgressY = CSnakeConstant:Inst():GetMaxExpProgressY();
	local fMinExpProgressY = CSnakeConstant:Inst():GetMinExpProgressY();
	local fProgressY = fMinExpProgressY + ( fMaxExpProgressY - fMinExpProgressY ) * fCur;
	local WndProgress = g_App:GetGameMain().m_wndExpProgress;
	local nSpaceDis = 10;
	if self:GetRoomType() == eRT_Team or self:GetRoomType() == eRT_TeamSecret 
		or self:GetRoomType() == eRT_TeamRace then
		nSpaceDis = 25;
	end

	if not self.m_nStrWidth then
		WndProgress:SetWndText( g_App:GetNickName() );
		local szText = WndProgress:GetWndText();
		self.m_nStrWidth = WndProgress:GetStrWidth( g_App:GetNickName() );
		WndProgress:SetWndText( szText );
	else
		WndProgress:DoMove( g_App:GetGameMain():GetWndWidth() / 2 - self.m_nStrWidth / 2 - WndProgress:GetWndWidth() - nSpaceDis, fProgressY * g_App:GetGameMain():GetWndHeight() / 720 );
	end
	--print( "11111111", fCur, g_App:GetGameMain():GetWndWidth() / 2, g_App:GetGameMain():GetWndHeight(), self.m_nStrWidth / 2, WndProgress:GetWndWidth(), g_App:GetGameMain():GetWndWidth() / 2 - self.m_nStrWidth / 2 - WndProgress:GetWndWidth() - 10, fProgressY, WndProgress:GetGlobalX(), WndProgress:GetGlobalY() );
end

function CGameSceneClientLua:AddCommend()
	local nObservedPlayerID = self:GetObservedPlayerID();
	if nObservedPlayerID == 0 then
		return false;
	end
	if self.m_tblAddCommend[nObservedPlayerID] then
		g_App:HideMsg( g_App:GetString( "yidianzan" ) );
		return false;
	end
	self.m_tblAddCommend[nObservedPlayerID] = true;
	local NetMsg = CAddCommend:new();
	NetMsg.m_nBeCommendID = nObservedPlayerID;
	g_App:GetWorldConn():SendShellMsg( NetMsg );
	return true;
end
--endregion
