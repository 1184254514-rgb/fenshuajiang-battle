--region CWndBalanceShare.lua
--Date	2018/3/28
--此文件由[BabeLua]插件自动生成

local TeamRadio = 50;	--百分比

function CWndBalanceShare:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndBalanceShare:OnCreated()
	self.m_pBtnContinue = self:GetDlgChild( "btn_jixu" );
	self.m_pBtnContinue:AddActionListener( "OnClickContinue", self );
	self.m_pBtnShare = self:GetDlgChild( "btn_fenxiang" );
	self.m_pBtnShare:AddActionListener( "OnClickShare", self );
	self.m_pShareChannelWnd = CShareChannelWnd:new("gui/cfg/fsj_fenxianglianjie.gui", self, 1 );
end

function CWndBalanceShare:OnDestroy()
	CGWnd.OnDestroy( self );
end

function CWndBalanceShare:OnWndShow( bShow )
	
end

function CWndBalanceShare:CheckHonourAndShowShare( nRoomType, structScore, 
	nTeamRank, nRunTime, tblBattleInfo, tblSettlementTeam )
	self.m_nModeType = 1;	--无尽
	self.m_structScore = structScore;
	self.m_nTeamRank = nTeamRank;
	self.m_nRunTime = nRunTime;
	self.m_nHonourType = eHornorShareType_Nothing;
	local pScene = g_App:GetScene();
	if not pScene then
		return;
	end
	if not g_App:IsGameSwitch( eGameSwitch_HonorShare ) then
		return;
	end

	if nRoomType == eRT_Endless then
		self.m_nModeType = 1;
		local nAllNode = pScene:GetNodeTotal();
		if self.m_structScore.nNodeCount == nAllNode then
			self.m_nHonourType = eHornorShareType_EndlessWhole;
		end
	elseif nRoomType == eRT_LimitTime then
		self.m_nModeType = 2;
		local nAllNode = pScene:GetNodeTotal();
		if self.m_structScore.nNodeCount == nAllNode then
			self.m_nHonourType = eHornorShareType_LimitWhole;
		elseif nTeamRank <= 3 then
			local bDead = false;
			for k, v in pairs( tblBattleInfo ) do
				if v.m_nDeaderAccountID == g_App:GetAccountID() then
					bDead = true;
					break;
				end
			end
			if not bDead then
				self.m_nHonourType = eHornorShareType_UndeadBetter;
			end
		end
	elseif nRoomType == eRT_Team then
		self.m_nModeType = 3;
		local tblSelfTeam = tblSettlementTeam[nTeamRank];
		local nTeamAllScore = 0;
		local nSelfScore = 0;
		for i = 1, #tblSelfTeam do
			nTeamAllScore = nTeamAllScore + tblSelfTeam[i].m_nAllScore;
			if tblSelfTeam[i].m_nAccountID == g_App:GetAccountID() then
				nSelfScore = tblSelfTeam[i].m_nAllScore;
			end
		end
		if nSelfScore / nTeamAllScore * 100 >= TeamRadio then
			self.m_nHonourType = eHornorShareType_TeamBest;
		end
	end
	
	if self.m_nHonourType ~= eHornorShareType_Nothing then
		self:ShowAndSetFocus();
	end
end

function CWndBalanceShare:OnClickShare()
	local nMinutes = math.floor( self.m_nRunTime / 60 );
	local nSeconds = self.m_nRunTime % 60;
	local szImgUrl = g_App:CreateHonourUrl( self.m_nModeType, self.m_structScore.nAllScore, self.m_nTeamRank, self.m_nHonourType, nMinutes, nSeconds );
	
	print( "------------------" );
	print( self.m_nModeType, self.m_structScore.nAllScore, "22222222222222222", szImgUrl );
	local szSrcName = g_App:GetString( "jiesuanjiemian" );
	local pContext = CShareContext:new( szSrcName );
	pContext:SetImageData( szImgUrl );
	self.m_pShareChannelWnd:SetSDK( pContext );
	self.m_pShareChannelWnd:ShowWnd( true );
end

function CWndBalanceShare:OnClickContinue()
	self:ShowWnd( false );
end
--endregion
