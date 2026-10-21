
function CKillInfoWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CKillInfoWnd:OnCreated()
    self.m_pName1 = self:GetDlgChild( "jishazhe" );
    self.m_pName2 = self:GetDlgChild( "beijishazhe" );
    self.m_pName1_0 = self:GetDlgChild( "jishazhe.youfang" );
    self.m_pName1_1 = self:GetDlgChild( "jishazhe.difang" );
    self.m_pName2_0 = self:GetDlgChild( "beijishazhe.youfang" );
    self.m_pName2_1 = self:GetDlgChild( "beijishazhe.difang" );
    
    self.m_pFadeTick = CTick:new( "FadeTick", self );
    self.m_pTick = CTick:new( "HideKillInfo", self, nil, 1 );
    self.m_pTick1 = CTick:new( "CheckKillInfoTick", self, nil, 1 );
    self.m_pTick2 = CTick:new( "CheckKillInfo", self, nil, 1 );
    self.m_infos = {};
end

function CKillInfoWnd:AddKillInfo( info )
    self.m_infos[info.priority] = self.m_infos[info.priority] or {};
    table.insert( self.m_infos[info.priority], info );

    self:CheckKillInfo();
end

function CKillInfoWnd:ClearKillInfo()
    if not self:IsCreated() then
        return;
    end
    self:ShowWnd( false );
    self.m_infos = {};
    self.m_info = nil;
    self.m_pTick:Stop();
    self.m_pTick1:Stop();
    self.m_pTick2:Stop();
    self.m_pFadeTick:Stop();
end

function CKillInfoWnd:CheckKillInfo()
    local selfInfo = self.m_infos[0];
    if selfInfo ~= nil and selfInfo[1] ~= nil then
        if self.m_info == nil or self.m_info.priority > 0 and not self.m_pTick2:IsRegisted() then
            self:ShowKillInfo( table.remove( selfInfo, 1 ) );
            return;
        end
    end

    if self.m_info == nil then
        local n = table.maxn( self.m_infos );
        for i = n, 1, -1 do
            local infos = self.m_infos[i];
            if infos ~= nil and infos[1] ~= nil then
                self:ShowKillInfo( table.remove( infos, 1 ) );
                return;
            end
        end
    end
end

function CKillInfoWnd:ShowKillInfo( info )
    self.m_info = info;
	self.m_pName1_0:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, info.color1 );
    self.m_pName1_0:ShowWnd( true );
    self.m_pName1_1:ShowWnd( false );
    self.m_pName1_0:SetWndText( info.szName1 );
	self.m_pName2_0:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, info.color2 );
    self.m_pName2_0:ShowWnd( true );
    self.m_pName2_1:ShowWnd( false );
    self.m_pName2_0:SetWndText( info.szName2 );

    if self.m_pCurInfo ~= nil then
        self.m_pCurInfo:ShowWnd( false );
    end
    self.m_pCurInfo = self:GetDlgChild( info.guiName );
    self.m_pCurInfo:ShowWnd( true );

    self:SetFadeDuration( 1 );
    self:ShowWnd( true );
    self:AddEffect( info.guiEffect, "fx/loop", "eft", 0, false, false, false, 1.0 );

	local nFightSound = g_App:GetIniFile():GetInteger( "Setting", "FightSound", 0 );
	if nFightSound > 0 then
		local pAudio = g_App:GetRenderer():GetAudio();
		if  pAudio then
			local pSound = pAudio:CreateSound( info.soundName, false, true );
			if  pSound ~= nil  then
				if nFightSound ==  1 then
					pSound:SetVolume( 0.3 );
				end
				if nFightSound ==  2 then
					pSound:SetVolume( 0.5 );
				end
				if nFightSound ==  3 then
					pSound:SetVolume( 0.8 );
				end
				pSound:Play( false, true );
				pSound:Release();
			end
		end



	end
    self.m_pTick:Start( 1000 );
    self.m_pTick1:Start( 3000 );
    self.m_pTick2:Start( 500 );

    if self.m_origPos == nil then
        self.m_origPos = {};
        self.m_origPos[1] = self.m_pCurInfo:GetLocalY();
        self.m_origPos[2] = self.m_pName1:GetLocalX();
        self.m_origPos[3] = self.m_pName2:GetLocalX();
    end

    self.m_pCurInfo:SetLocalY( self.m_origPos[1] - 200 );
    self.m_pName1:SetLocalX( self.m_origPos[2] - 500 );
    self.m_pName2:SetLocalX( self.m_origPos[3] + 500 );
    self.m_nFadeTime = 0;
    self.m_pFadeTick:Start( 33 );
end

function CKillInfoWnd:FadeTick()
    self.m_nFadeTime = self.m_nFadeTime + 33;
    local t = math.min( 1, self.m_nFadeTime / 250 );
    local t1 = 1 - t * t;
    self.m_pCurInfo:SetLocalY( self.m_origPos[1] - t1 * 200 );
    self.m_pName1:SetLocalX( self.m_origPos[2] - t1 * 500 );
    self.m_pName2:SetLocalX( self.m_origPos[3] + t1 * 500 );

    if t >= 1 then
        self.m_pFadeTick:Stop();
    end
end

function CKillInfoWnd:HideKillInfo()
    self:SetFadeDuration( 1500 );
    self:ShowWnd( false );
end

function CKillInfoWnd:CheckKillInfoTick()
    self.m_info = nil;
    self:CheckKillInfo();
end