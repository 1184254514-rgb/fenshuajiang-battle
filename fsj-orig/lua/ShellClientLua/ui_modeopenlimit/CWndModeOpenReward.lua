--region CWndModeOpenReward.lua
--Date 2017.11.06
--模式开放奖励发放界面  

function CWndModeOpenReward:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndModeOpenReward:OnCreated()
	self.m_BtnContinue			= self:GetDlgChild( "btn_jixu" );
	self.m_WndObtainMusic		= self:GetDlgChild( "yinyue" );
	self.m_WndMusicName			= self:GetDlgChild( "yinyue.bg" );
	self.m_WndObtainSkin		= self:GetDlgChild( "pifu" );
	self.m_WndSkinModel			= CRichIconWnd:new( self, "pifu.pifu" );
	self.m_WndSkinName			= self:GetDlgChild( "pifu.bg" );
	self.m_WndLimitModeOpen		= self:GetDlgChild( "xianshi" );
	self.m_WndTeamModeOpen		= self:GetDlgChild( "tuanzhan" );

	self.m_BtnContinue:AddActionListener( "NextStep", self );
	self.m_nStep = 1;
end

function CWndModeOpenReward:ShowWndByRoomType( nRoomType )
	self.m_nRoomType = nRoomType;
	if self.m_nRoomType == eRT_Team then return end;
	if not self:CheckPrize() then
		if self.m_nRoomType == eRT_Endless then 
			local pWndBalance = g_App:GetScene():GetWanfa().m_pWndBalance;
			pWndBalance:ShowWnd( true );
			return
		end
		if self.m_nRoomType == eRT_LimitTime then
			g_App:GetScene():GetWanfa():ShowResultLimit();
			return;
		end 
	end
	if nRoomType == eRT_Endless then
		self.m_WndLimitModeOpen:ShowWnd( true );
		self.m_WndTeamModeOpen:ShowWnd( false );
	elseif nRoomType == eRT_LimitTime then
		self.m_WndLimitModeOpen:ShowWnd( false );
		self.m_WndTeamModeOpen:ShowWnd( true );
	end
	self.m_WndObtainMusic:ShowWnd( false );
	self.m_WndObtainSkin:ShowWnd( false );
	self:SetData();
	self:ShowWnd( true );
end

function CWndModeOpenReward:NextStep()
	self.m_WndLimitModeOpen:ShowWnd( false );
	self.m_WndTeamModeOpen:ShowWnd( false );
	self.m_WndObtainMusic:ShowWnd( self.m_nStep == 1 );
	self.m_WndObtainSkin:ShowWnd( self.m_nStep == 2 );
	self:ShowWnd( self.m_nStep ~= 3 );
	local nPrizeMusicID = 0;
	local nRewardPrizeFragmentID = 0;
	local nRewardPrizeFragmentCount = 0;
	if self.m_nRoomType == eRT_Endless then
		nPrizeMusicID = CSnakeConstant:Inst():GetLimitModeOpenMusicID();
		nRewardPrizeFragmentID = CSnakeConstant:Inst():GetLimitModeOpenFragmentID();
		nRewardPrizeFragmentCount = CSnakeConstant:Inst():GetLimitModeOpenFramentCount();
	elseif self.m_nRoomType == eRT_LimitTime then
		nPrizeMusicID = CSnakeConstant:Inst():GetTeamModeOpenMusicID();
		nRewardPrizeFragmentID = CSnakeConstant:Inst():GetTeamModeOpenFragmentID();
		nRewardPrizeFragmentCount = CSnakeConstant:Inst():GetTeamModeOpenFragmentCount();
	end
	if self.m_nRoomType == eRT_Endless then
		local pWndBalance = g_App:GetScene():GetWanfa().m_pWndBalance;
		pWndBalance:ShowWnd( self.m_nStep == 3 );
	end
	if self.m_nRoomType == eRT_LimitTime and self.m_nStep == 3 then
		g_App:GetScene():GetWanfa():ShowResultLimit();
	end
	if self.m_nStep == 1 then
		g_App:SetSelectMusicID( nPrizeMusicID );
		g_App:GetGameMain():ChangeMusic( nPrizeMusicID );	
	end
	self.m_nStep = self.m_nStep + 1;
end

function CWndModeOpenReward:SetData()
	local nRewardMusicID = 0;
	local nRewardPrizeFragmentID = 0;
	local nRewardPrizeFragmentCount = 0;
	if self.m_nRoomType == eRT_Endless then
		nRewardMusicID = CSnakeConstant:Inst():GetLimitModeOpenMusicID();
		nRewardPrizeFragmentID = CSnakeConstant:Inst():GetLimitModeOpenFragmentID();
		nRewardPrizeFragmentCount = CSnakeConstant:Inst():GetLimitModeOpenFramentCount();
	elseif self.m_nRoomType == eRT_LimitTime then
		nRewardMusicID = CSnakeConstant:Inst():GetTeamModeOpenMusicID();
		nRewardPrizeFragmentID = CSnakeConstant:Inst():GetTeamModeOpenFragmentID();
		nRewardPrizeFragmentCount = CSnakeConstant:Inst():GetTeamModeOpenFragmentCount();
	end

	local szMusicName = CMusicConfig:Inst():GetMusicName( nRewardMusicID );
	local szFragmentName = g_tblTabFile.fragment[nRewardPrizeFragmentID].dName;
	szMusicName = string.format( self.m_WndMusicName:GetWndText(), szMusicName );
	szSkinName = string.format( self.m_WndSkinName:GetWndText(), szFragmentName );
	self.m_WndMusicName:SetWndText( szMusicName );
	self.m_WndSkinName:SetWndText( szFragmentName .. "X" .. nRewardPrizeFragmentCount );
	self.m_WndSkinModel:SetIconID( g_tblTabFile.fragment[nRewardPrizeFragmentID].nIconID );
end

function CWndModeOpenReward:CheckPrize()
	local bPrized = false;
	local nTarGetScore = 0;
	local nCurScore = 0;
	if self.m_nRoomType == eRT_Endless then
		bPrized = g_App:GetLimitModeOpenFlag();
		nTargetScore = CSnakeConstant:Inst():Getxianshijiesuomianji()/10000 * g_GetSceneNodeTotal( self.m_nRoomType );
		nCurScore = g_App:GetGameScore( eRT_Endless );
	elseif self.m_nRoomType == eRT_LimitTime then
		bPrized = g_App:GetTeamModeOpenFlag();
		nTargetScore = CSnakeConstant:Inst():Gettuanzhanjiesuofenshu();
		nCurScore = g_App:GetGameScore( eRT_LimitTime );
	end

	if not bPrized then
		if nCurScore < nTargetScore then
			return false;
		else
			if self.m_nRoomType == eRT_Endless then
				g_App:SetLimitModeOpenFlagTrue();
			elseif self.m_nRoomType == eRT_LimitTime then
				g_App:SetTeamModeOpenFlagTrue();
			end
			return true;
		end
	end
	
	return false;
end



--endregion
