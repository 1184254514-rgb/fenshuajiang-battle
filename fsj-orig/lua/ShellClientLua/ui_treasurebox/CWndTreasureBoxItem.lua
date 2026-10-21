--region CWndTreasureBoxItem.lua
--Date 2017.11.23

function CWndTreasureBoxItem:Ctor( sResName, Parentwnd, nLoadType )
	CGWnd.Ctor( self, sResName, Parentwnd, nLoadType );
end

function CWndTreasureBoxItem:OnCreated()
	self.m_WndCouldOpen			= self:GetDlgChild( "yijiesuo" );
	self.m_WndCouldOpenTitle	= self:GetDlgChild( "yijiesuo.title" );
	self.m_WndCouldOpenButton	= self:GetDlgChild( "yijiesuo.btn_kaiqi" );

	self.m_WndLocked			= self:GetDlgChild( "weijiesuo" );
	self.m_WndLockedTitle		= self:GetDlgChild( "weijiesuo.title" );
	self.m_WndLockedDiscard		= self:GetDlgChild( "weijiesuo.diuqi" );
	self.m_WndLockedbutton		= self:GetDlgChild( "weijiesuo.btn_jiesuo" );

	self.m_WndNo				= self:GetDlgChild( "kong" );
	self.m_WndNoTips			= self:GetDlgChild( "kong.tips" );
	self.m_WndNoTips1			= self:GetDlgChild( "kong.tips1" );

	self.m_WndWaitingOpen		= self:GetDlgChild( "daojishi" );
	self.m_WndWaitingOpenTime	= self:GetDlgChild( "daojishi.time" );
	self.m_WndWaitingOpenButton = self:GetDlgChild( "daojishi.btn_jiasu" );
	self.m_WndWaitingOpenPrice	= self:GetDlgChild( "daojishi.btn_jiasu.W_jiage" );

	self.m_iconTreasureBox		= self:GetDlgChild( "icon" );
	self.m_tick					= CTick:new( "UpdateTime", self );

	self.m_WndLocked:AddActionListener( "OnClickUnLock", self );
	self.m_WndWaitingOpenButton:AddActionListener( "OnClickAccelerate", self );
	self.m_WndCouldOpen:AddActionListener( "OnClickOpen", self );
	self.m_WndLockedDiscard:AddActionListener( "OnDiscard", self );

	self.m_WndCouldOpen:ShowWnd( false );
	self.m_WndLocked:ShowWnd( false );
	self.m_WndNo:ShowWnd( false );
	self.m_WndWaitingOpen:ShowWnd( false );
end

function CWndTreasureBoxItem:SetTreasureBoxData( tblTreasureBox, nPosIndex )
	if not tblTreasureBox then 
		self.m_WndNo:ShowWnd( true );
		return
	end;
	self.m_nPosIndex = nPosIndex;
	self.m_tblData = tblTreasureBox;
	self.m_nTreasureBoxID = self.m_tblData.nTreasureBoxID;
	self.m_szName = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].dName;
	self.m_nTimeNeed = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nTime;
	self.m_nPayType = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nConsumeType;
	self.m_nPayIndex = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nConsumeIndex;
	self.m_nTimeNeed = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nTime;

	if self.m_tblData.nStatus == eTreasureBoxStatus_Lock then
		self.m_WndLockedTitle:SetWndText( self.m_szName );
		self.m_WndLocked:ShowWnd( true );
	elseif self.m_tblData.nStatus == eTreasureBoxStatus_WaitingOpen then
		self.m_WndWaitingOpen:ShowWnd( true );
		if not self.m_tick:IsRegisted() then
			self.m_tick:Start( 33 );
		end
	elseif self.m_tblData.nStatus == eTreasureBoxStatus_CouldOpen then
		self.m_WndCouldOpen:ShowWnd( true );
		self:StopTick();
	elseif self.m_tblData.nStatus == eTreasureBoxStatus_Opened  and self.m_tblData.nStatus == eTreasureBoxStatus_Discard then
		self:StopTick();
		self:DestroyWnd();
	end
	
	local nTreasureBoxLevel = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nLevel;
	if not self.m_pRenderObject then
		self.m_pRenderObject = g_App:CreateRenderObject();
	end
	self.m_pRenderObject:ShowTreasureBoxModel( nTreasureBoxLevel );
	local pViewportRenderer = self.m_iconTreasureBox:GetViewportRenderer();
	pViewportRenderer:AddChild( self.m_pRenderObject );
	local Camera = pViewportRenderer:GetCamera();
	local fUpX = g_data_treasureboxpos[2].fUpX;
	local fUpY = g_data_treasureboxpos[2].fUpY;
	local fUpZ = g_data_treasureboxpos[2].fUpZ;
	local fPosX = g_data_treasureboxpos[2].fPosX;
	local fPosY = g_data_treasureboxpos[2].fPosY;
	local fPosZ = g_data_treasureboxpos[2].fPosZ;
	local fDestX = g_data_treasureboxpos[2].fDestX;
	local fDestY = g_data_treasureboxpos[2].fDestY;
	local fDestZ = g_data_treasureboxpos[2].fDestZ;
	Camera:SetUp( CVector3f:new( fUpX, fUpY, fUpZ ) );
	Camera:SetPos( CVector3f:new( fPosX, fPosY, fPosZ ) );
	Camera:SetDest( CVector3f:new( fDestX, fDestY, fDestZ ) );
	local tblSzTreasureBoxOpenEffect = { "fx/cfg/box03.eft", "fx/cfg/box02.eft", "fx/cfg/box01.eft" };
	self.m_pRenderObject:AddFusionSkinEffect( tblSzTreasureBoxOpenEffect[nTreasureBoxLevel], "fx/stand", nil, false, -1 );
end

function CWndTreasureBoxItem:OnWndShow( bShow )
	if not bShow then
		if self.m_tick:IsRegisted() then
			self.m_tick:Stop();
		end
		if self.m_pRenderObject then
			g_App:DestroyRenderObject( self.m_pRenderObject );
			self.m_pRenderObject = nil;
		end
	end
end

function CWndTreasureBoxItem:OnDestroy()
	self:StopTick();
end

function CWndTreasureBoxItem:OnClickAccelerate()
	local szTips = g_App:GetString( "jiesuobaoxiangtips0" );
	local wndOperatDetail = g_App:GetGameStart().m_WndTreasureBox.m_WndOprationTips;
	wndOperatDetail:ShowDetail( szTips, self.m_nTreasureBoxID, self.m_tblData.nGetTime, self.m_tblData.nUnlockTime, self.m_nPosIndex );
end

function CWndTreasureBoxItem:OnClickUnLock()
	local NetMsg = CUnLockTreasureBox:new();
	NetMsg.m_nTreasureBoxID = self.m_nTreasureBoxID;
	NetMsg.m_nGetTime = self.m_tblData.nGetTime;
	NetMsg.m_nPosIndex = self.m_nPosIndex;
	g_App:SendShellMsg( NetMsg );
end

function CWndTreasureBoxItem:OnClickOpen()
	local NetMsg = COpenTreasureBox:new();
	NetMsg.m_nTreasureBoxID = self.m_nTreasureBoxID;
	NetMsg.m_nGetTime = self.m_tblData.nGetTime;
	NetMsg.m_nPosIndex = self.m_nPosIndex;
	g_App:SendShellMsg( NetMsg );
end

function CWndTreasureBoxItem:OnDiscard()
	local NetMsg = CDiacardTreasureBox:new();
	NetMsg.m_nTreasureBoxID = self.m_nTreasureBoxID;
	NetMsg.m_nGetTime = self.m_tblData.nGetTime;
	g_App:SendShellMsg( NetMsg );
end

function CWndTreasureBoxItem:UpdateTime()
	if not self:IsShow() then
		return
	end
	if( not self.m_tblData ) then
		return;
	end
	local nTimeElapse = math.floor( (GetNatureTime()/1000 ) ) - self.m_tblData.nUnlockTime;
	if nTimeElapse < 0 then
		nTimeElapse = 0;
	end
	local nTimeRemain = self.m_nTimeNeed - nTimeElapse;
	if nTimeRemain <= 0 then
		self.m_tick:Stop();
		self.m_WndCouldOpen:ShowWnd( true );
		local NetMsg = CCouldOpenTreasureBox:new();
		NetMsg.m_nTreasureBoxID = self.m_nTreasureBoxID;
		NetMsg.m_nGetTime = self.m_tblData.nGetTime;
		g_App:SendShellMsg( NetMsg );
		return;
	end
	local nHour = math.floor( nTimeRemain/3600 );
	local nMinute = math.floor( nTimeRemain/60%60 );
	local nSecond = math.floor( nTimeRemain%60);
	local szTime = string.format( "%02d:%02d:%02d", nHour, nMinute, nSecond );
	self.m_WndWaitingOpenTime:SetWndText( szTime );
	local nConsumecount = CTreasureBoxOpenConsume:Inst():GetConsumeCount( nTimeRemain, self.m_nPayIndex );
	self.m_WndWaitingOpenPrice:SetWndText( nConsumecount );
end

function CWndTreasureBoxItem:StopTick()
	if self.m_tick:IsRegisted() then
		self.m_tick:Stop();
	end
end

--endregion
