--region *.lua
--Date 2017-08-05

local nShowStart = 1;
local nShowFriend = nShowStart + 1;
local nShowWorld = nShowFriend + 1;
local nShowBeyondWorld = nShowWorld + 1;

CGameMainLua.eSound_CountDown	= 0;
CGameMainLua.eSound_GameOver	= 1;
CGameMainLua.eSound_GameEnd		= 2;
local nSpaceDis = 50;
local TblSubButtonName = 
{
	[1] = "shang",
	[2] = "xia",
	[3] = "zuo",
	[4] = "you"
}
local TblSeparateSubPos = 
{
	[1] = { x = 140, y = 20 },
	[2] = { x = 140, y = 260 },
	[3] = { x = 20, y = 140 },
	[4] = { x = 260, y = 140 }
}

function CGameMainLua:Ctor()
	self.m_tblEffectFly = {};
	self.m_tblTip = {};
    self.m_tblDianzan = {};

	self.m_tblSound = {};
end

function CGameMainLua:OnCreated()
	CGameMain.OnCreated( self );
	
	self.m_tickEffectFly		= CTick:new( "OnEffectFly", self );
	self.m_tickHideDoubleGrade	= CTick:new( "HideDoubleGrade", self );
	self.m_tickCloseTip			= CTick:new( "OnCloseTip", self, nil, 1 );
    self.m_pTick				= CTick:new( "HideStartWnd", self, nil, 1 );
	self.m_tickDianzan			= CTick:new( "UpdateDianzan", self );
	self.m_tickCountDownTime	= CTick:new( "OnCountDownTime", self );
	self.m_tickUpdateWnd		= CTick:new( "OnUpdateWnd", self );

	self.m_pBtnClose = self:GetDlgChild( "B_close" );
	self.m_pBtnClose:AddActionListener( "OnExitScene" , self );
	self.m_pWndBattleFace = self:GetDlgChild( "biaoqing" );
	self.m_pWndDoubleGradeText = self:GetDlgChild( "W_quandi.W_fanbei" );
	self.m_wndFirst = self:GetDlgChild( "W_huangguan" );
	self.m_wndExpProgress = self:GetDlgChild( "shengjijindutiao" );
	self.m_wndLevelUp = self:GetDlgChild( "FX_shengji" );
    self.m_pObserverCount = self:GetDlgChild( "guanzhanzhe.renshu" );
    self.m_pObserverName = self:GetDlgChild( "guanzhanzhe.name" );
    self.m_pDianzan = self:GetDlgChild( "dianzan" );
	self.m_wndCoin = self:GetDlgChild( "jinbi" );
	self.m_pWndGoldCoin = self.m_wndCoin:GetDlgChild( "E-jinbishuliang" );
	self.m_pWndRoomCount = self:GetDlgChild( "fangjianhao.fanghao" );
	self.m_pWndCountDown = self:GetDlgChild( "W_jieshudaojishi" );
	self.m_pWndGameTime = self:GetDlgChild( "W_youxishijian.shijian" );
	self.m_pWndTaskTarget = self:GetDlgChild( "renwu.mubiao" );
	self.m_pWndTaskDesc = self:GetDlgChild( "renwu.W_renwu" );
	self.m_pWndTask = self:GetDlgChild( "renwu" );

	self.m_pWndTaskTips = CTaskTipWnd:new( "gui/cfg/fsj_zjm_renwuitem.gui", self:GetParent(), 1 );
    self.m_pStartWnd = CGWnd:new( "gui/cfg/fsj_youxikaishi.gui", self, 1 );
	self.m_pWndRank1 = CWndMainRank1:new( "gui/cfg/fsj_phb_geren.gui", self, 1 );
	self.m_pWndRank2 = CWndMainRank2:new( "gui/cfg/fsj_phb_tuanzhan.gui", self, 1 );
    self.m_pKillInfoWnd = CKillInfoWnd:new( "gui/cfg/fsj_jishaxinxi.gui", self, 1 );
	self.m_wndOutInfo = COutInfoWnd:new( "gui/cfg/fsj_chujutishi.gui", self, 1 );
	self.m_pGameButton = CGameButton:new( "gui/cfg/fsj_zjm_anjian_big.gui", self, 1 );
    self.m_pObserve = CObserveWnd:new( "gui/cfg/fsj_guanzhan.gui", self, 1 );
	self.m_pWndTyro = CTyroWnd:new( "gui/cfg/zhishi_duihuakuang2.gui", self, 1 );
	self.m_pHeadWnd = CHeadWnd:new("gui/cfg/fsj_zhujuexinxi.gui",self, 1 );
	self.m_aryTrackTip = {};
	for i = 1, 3 do
		self.m_aryTrackTip[i] = CGWnd:new( "gui/cfg/fsj_jiantou.gui", self, 1 );
	end
	self.m_aryTrackTipForTeam = {};
	for i = 1, 3 do 
		self.m_aryTrackTipForTeam[i] = CGWnd:new( "gui/cfg/fsj_jiantou_tuanzhan.gui", self, 1 );
	end

	self.m_pWndTyro:ShowWnd( false );
	self.m_wndExpProgress:ShowWnd( false );
	self.m_wndLevelUp:ShowWnd( false );
	self.m_wndFirst:ShowWnd( false );
	self.m_pWndDoubleGradeText:ShowWnd( false );
	self.m_pWndBattleFace:ShowWnd( false );
	
	self:RegisterSound( CGameMainLua.eSound_CountDown, "sound/10sdaojishi.mp3", 0.8 );
	self:RegisterSound( CGameMainLua.eSound_GameOver, "music/playerover_01.mp3", 0.8 );
	self:RegisterSound( CGameMainLua.eSound_GameEnd, "music/ending.mp3", 0.8 );

	self:AddEventListener( WM_KEYDOWN, "OnKeyDownEvent", self );
end

function CGameMainLua:OnDestroy()
	CGameMain.OnDestroy( self );

	self:RemoveEventListener( WM_KEYDOWN, "OnKeyDownEvent", self );

	self:DestoryAllSound();

	self.m_tickEffectFly:Stop();	
	self.m_tickHideDoubleGrade:Stop();
	self.m_tickCloseTip:Stop();
	self.m_pTick:Stop();
	self.m_tickDianzan:Stop();
	self.m_tickCountDownTime:Stop();
	self.m_tickUpdateWnd:Stop();

	self.m_tickEffectFly		= nil;
	self.m_tickHideDoubleGrade	= nil;
	self.m_tickCloseTip			= nil;
	self.m_pTick				= nil;
	self.m_tickDianzan			= nil;
	self.m_tickCountDownTime	= nil;
	self.m_tickUpdateWnd		= nil;
end

function CGameMainLua:OnWndShow( bShow )
	CGameMain.OnWndShow( self, bSHow );
    if not bShow then
        self.m_tblDianzan = {};
        self.m_tickDianzan:Stop();
	else
		self.m_pWndTyro:ShowWnd( false );
		self.m_tblTip = {};
		self.m_pWndRank1.pWndSelfRank:InitValue();
		self.m_pWndRank2.pWndSelfRank:InitValue();
	    local pScene = g_App:GetScene();
	    if not pScene then
		    return;
	    end
	    local nRoomType = pScene:GetRoomType();
	    self.m_pBtnClose:ShowWnd( nRoomType == eRT_Endless );
	    self.m_wndExpProgress:ShowWnd( nRoomType ~= eRT_Endless and CSnakeConstant:Inst():GetWhetherShowExp() ~= 0 );
	    self.m_wndLevelUp:ShowWnd( nRoomType ~= eRT_Endless and CSnakeConstant:Inst():GetWhetherShowExp() ~= 0 );
        self:SetObserveGame( false );
        self:SetObserverCount( 0, "" );
        self.m_pDianzan:SetGlobalX( -self.m_pDianzan:GetWndWidth() );
    end
end

function CGameMainLua:OnKeyDownEvent( Event )
	local nChar = Event.m_wParam;

	local pScene = g_App:GetScene();
	if not pScene then
		return;
	end
	
	local pDirector = g_App:GetDirector();
	
	if nChar == 87 then -- 'W'
		self:ClickDir( eDF_Up );
	elseif nChar == 83 then -- 'S'
		self:ClickDir( eDF_Bottom );
	elseif nChar == 65 then -- 'A'
		self:ClickDir( eDF_Left );
	elseif nChar == 68 then -- 'D'
		self:ClickDir( eDF_Right );
	end
	if not g_App:IsDebug() then
		return;
	end
	if nChar == VK_SPACE and pDirector then
		pDirector:Stop();
	elseif nChar == VK_F1 then
		pScene:AddTargetPlay( 1 );
	elseif nChar == VK_F2 then
		pScene:AddTargetPlay( 10 );
	elseif nChar == VK_F3 then
		pScene:AddTargetPlay( 100 );
	elseif nChar == VK_F4 then
		pScene:AddTargetPlay( 1000 );
	elseif nChar == VK_F5 then
		pScene:AddTargetPlay( 10000 );
	elseif nChar == VK_F6 then
		pScene:AddTargetPlay( 100000 );
	elseif nChar == VK_SUBTRACT then
		pScene:SetScale( pScene:GetScale() * 1.1 );
	elseif nChar == VK_ADD then
		pScene:SetScale( pScene:GetScale() / 1.1 );
	elseif nChar == VK_LEFT then
		pScene:AddOffset( CVector2f:new( -50, 0 ) );
	elseif nChar == VK_RIGHT then
		pScene:AddOffset( CVector2f:new( 50, 0 ) );
	elseif nChar == VK_UP then
		pScene:AddOffset( CVector2f:new( 0, 50 ) );
	elseif Char == VK_DOWN then
		pScene:AddOffset( CVector2f:new( 0, -50 ) );
	end
end

function CGameMainLua:DestoryAllSound()
	for _, pSound in pairs( self.m_tblSound ) do
		pSound:Release();
	end
	self.m_tblSound = {};
end

function CGameMainLua:RegisterSound( nSoundType, pFileName, fVolume )
	local pAudio = self:GetRenderer():GetAudio();
	if not pAudio then
		return;
	end

	self.m_tblSound[nSoundType] = pAudio:CreateSound( pFileName, false );
	if not self.m_tblSound[nSoundType] then
		return;
	end
	self.m_tblSound[nSoundType]:SetVolume( fVolume );
end

function CGameMainLua:PlaySound( nSoundType )
	if not self.m_tblSound[nSoundType] then
		return;
	end
	self.m_tblSound[nSoundType]:Play( false, true );
end

function CGameMainLua:Start()
    CGameMain.Start( self );
	local pScene = g_App:GetScene();
	local nRoomType = pScene:GetRoomType();

	self:InitButton();
    self.m_pStartWnd:ShowWnd( true );
    self.m_pTick:Start( 3000 );
	
	self.m_pWndTyro.m_nLastTipIndex = eMUT_Init;

	self.m_pWndRank1:ShowWnd( false );
	self.m_pWndRank2:ShowWnd( false );
	
	for j =1, 3 do 
		self.m_aryTrackTipForTeam[j]:ShowWnd( false );
		self.m_aryTrackTip[j]:ShowWnd( false );
	end

	if self.m_pWndRank2.m_bOut then
		self.m_pWndRank2.m_bOut = false;
	end

	self.m_tickEffectFly:Start( 33 );
	self.m_wndCoin:ShowWnd( nRoomType == eRT_Endless );

	if nRoomType ~= eRT_Endless then
		self.m_tickCountDownTime:Start( 1000 );
	end
	self.m_pWndCountDown:ShowWnd( false );
	self.m_pWndGoldCoin:SetWndText( "0" );
	self.m_pWndGameTime:SetWndText( "" );
	self.m_pWndRoomCount:SetWndText( tostring( pScene:GetSceneID() ) );

	self.m_tickUpdateWnd:Start( 1000 );
	self:InitTask();

	self:GetRhythmWnd():Start( g_App:GetMainPlayerData().m_CharBaseData:GetCurRhythmNoticeBarID() );
end

function CGameMainLua:Clear()
	 CGameMain.Clear( self );
	 self.m_tickCountDownTime:Stop();
	 self.m_tickUpdateWnd:Stop();
end

function CGameMainLua:RoomOver()
	self.m_pGameButton:ShowWnd( false );
	self:GetRhythmWnd():ShowWnd( false );
end

function CGameMainLua:SetObserveGame( bObserveGame )
	self.m_bObserveGame = bObserveGame;
	self.m_pObserve:ShowWnd( bObserveGame );
	self.m_pObserve:OnHidePlayerList();
	self:GetRhythmWnd():ShowWnd( not bObserveGame );
	self.m_pGameButton:ShowWnd( not bObserveGame );
	if bObserveGame then
		self.m_pWndTyro:ShowWnd( false );
	    self:GetDlgChild( "shengjijindutiao" ):ShowWnd( false );
        local pScene = g_App:GetScene();
        if pScene then
            local pPlayer = pScene:GetObservedPlayer();
            if pPlayer then
                g_App:GetGameMain().m_pObserve:SetMusicID( pPlayer:GetMusicID() );
            end
        end
	end
	self:GetDlgChild( "guanzhanzhe" ):ShowWnd( not bObserveGame );
end

function CGameMainLua:InitButton()
	local IniFile = g_App:GetIniFile();
	local pWnd = self.m_pGameButton:GetDlgChild("group");

	local nPosX = IniFile:GetInteger( "Setting", "ButtonX", 0 );
	local nBtnConfigGroupLocalY = self:GetWndHeight() - pWnd:GetWndHeight();
	local nPosY = IniFile:GetInteger( "Setting", "ButtonY", nBtnConfigGroupLocalY ) - nSpaceDis;
	pWnd:SetLocalX( nPosX );
	pWnd:SetLocalY( nPosY );
	for i = 1, 4 do
		local SubBtn = pWnd:GetDlgChild( TblSubButtonName[i] );
		local nBtnConfigSubLocalX = IniFile:GetInteger( "Setting", "BtnConfigSubLocalX"..i, TblSeparateSubPos[i].x );
		local nBtnConfigSubLocalY = IniFile:GetInteger( "Setting", "BtnConfigSubLocalY"..i, TblSeparateSubPos[i].y );
		SubBtn:SetLocalX( nBtnConfigSubLocalX ); 
		SubBtn:SetLocalY( nBtnConfigSubLocalY );
	end
	pWnd:SetLockFlag( BitOr( eDF_Left, eDF_Bottom ) );

	local pWnd1 = self.m_pGameButton:GetDlgChild("B_jineng");	
	local nPosX = self:GetWndWidth() - pWnd1:GetWndWidth() - 90 - IniFile:GetInteger( "Setting", "ButtonX1", 0 );
	local nPosY = self:GetWndHeight() - pWnd1:GetWndHeight() - 90 - IniFile:GetInteger( "Setting", "ButtonY1", 0 );
	pWnd1:SetLocalX( nPosX );
	pWnd1:SetLocalY( nPosY );
	pWnd1:SetLockFlag( BitOr( eDF_Right, eDF_Bottom ) );

	self.m_pGameButton:ShowWnd( true );
	pWnd1:ShowWnd( false );
end

function CGameMainLua:InitSkillButton( nSkillID, nTopLevel )
	if not g_App:CouldUseSkill() then
		self.m_pGameButton:GetDlgChild( "B_jineng" ):ShowWnd( false );
		return
	end

	if not g_tblTabFile.skill[nSkillID].nID == 0 then
		print( "Not Exist SkillID : " .. tostring( nSkillID ) );
		return;
	end
	print( "InitSkillButton", nSkillID );
	local pWnd1 = self.m_pGameButton:GetDlgChild( "B_jineng.tietu" );
	self.m_pGameButton:GetDlgChild( "B_jineng" ):ShowWnd( true );
	pWnd1:ShowWnd( true );
	pWnd1:SetWndText( "" );
	pWnd1:EnableWnd( true );
	pWnd1.m_nSkillID = nSkillID;
	pWnd1.m_nTopLevel = nTopLevel;
	g_App:AssignWndToSkill( pWnd1, g_tblTabFile.skill[nSkillID].nIconID );
	self.m_pGameButton:RefreshActiveSkill( nSkillID, g_App:GetDirector().m_nActiveSkillLevel );
	--self.m_pGameButton:InitActiveSkill();
	self.m_pGameButton:InitPassiveSkill();
end

function CGameMainLua:GetGameButton()
	return self.m_pGameButton;
end

function CGameMainLua:SetObserverCount( nCount, szName )
    self:GetDlgChild( "guanzhanzhe" ):ShowWnd( nCount > 0 );
    self.m_pObserverCount:SetWndText( tostring( nCount ) );
    self.m_pObserverName:SetWndText( szName );
    self.m_pObserve:SetObserverCount( nCount, szName );
end

function CGameMainLua:AddEffectFly( nStartX, nStartY, nEndX, nEndY, szEffectName )
	local pWnd = CGWnd:new();
	pWnd:CreatAsEmptyContain( self, 30, 30 );
	pWnd:SetGlobalX( nStartX );
	pWnd:SetGlobalY( nStartY );
	pWnd.m_nStartX = nStartX;
	pWnd.m_nStartY = nStartY;
	pWnd.m_nTargetX = nEndX;
	pWnd.m_nTargetY = nEndY;
	local vDir = CVector2f:new( nEndX - nStartX, nEndY - nStartY );
	vDir:NormalizeNoneZero();
	pWnd.m_vFlyDir = vDir;
	pWnd:AddEffect( szEffectName, "fx/fly", "loop", -1 );
	pWnd:ShowWnd( true );
	pWnd:SetFocus();
	pWnd:SetStyle( BitOr( BitOr( pWnd:GetStyle(), eWS_TOPMOST ), eWS_MSGTRANSPT ) );
	table.insert( self.m_tblEffectFly, pWnd );
end

function CGameMainLua:OnEffectFly()
	local nSpeed = 25;

	local tblRemovePos = {};
	for _, pWnd in pairs( self.m_tblEffectFly ) do
		pWnd:SetGlobalX( pWnd:GetGlobalX() + pWnd.m_vFlyDir:x() * nSpeed );
		pWnd:SetGlobalY( pWnd:GetGlobalY() + pWnd.m_vFlyDir:y() * nSpeed );
		
		local nCurWidth = math.abs( pWnd:GetGlobalX() - pWnd.m_nStartX );
		local nCurHeight = math.abs( pWnd:GetGlobalY() - pWnd.m_nStartY );
		local nTargetWidth = math.abs( pWnd.m_nTargetX - pWnd.m_nStartX );
		local nTargetHeight = math.abs( pWnd.m_nTargetY - pWnd.m_nStartY );
	
		if nCurWidth > nTargetWidth or nCurHeight > nTargetHeight then
			table.insert( tblRemovePos, _ );
		end
	end
	
	for _, nPos in pairs( tblRemovePos ) do
		local pWnd = self.m_tblEffectFly[ nPos ];
		self.m_tblEffectFly[ nPos ] = nil;
		pWnd:DestroyWnd();
	end
end

function CGameMainLua:HideStartWnd()
    self.m_pStartWnd:ShowWnd( false );
	self.m_pTick:Stop();
end

function CGameMainLua:OnCountDownTime()
	local pScene = g_App:GetScene();
	if not pScene then
		return;
	end

	local nShowTime = math.floor( pScene:GetTimeRemain() / 1000 );
	if nShowTime <= 10 and nShowTime > 0 then
		self.m_pWndCountDown:ShowWnd( true );
		self.m_pWndCountDown:RemoveAllEffects();
		self.m_pWndCountDown:AddEffect( "fx/cfg/daojishi.eft", "fx/"..nShowTime, "daojishi", 1000 );
	end

	if nShowTime == 10 then
		self:PlaySound( CGameMainLua.eSound_CountDown );
	end
end

function CGameMainLua:OnUpdateWnd()
	local pScene = g_App:GetScene();
	if not pScene then
		return;
	end

	local nRoomType = pScene:GetRoomType();
	local nTimeRemain = pScene:GetTimeRemain();
	local nShowTime = 0;
	if nRoomType == eRT_Endless then
		nShowTime = math.floor( ( GetNatureTime() - pScene:GetSceneTime() ) / 1000 );
	elseif nRoomType == eRT_LimitTime or nRoomType == eRT_Team 
		or nRoomType == eRT_LimitSecret or nRoomType == eRT_TeamSecret
		or nRoomType == eRT_LimitRace or nRoomType == eRT_TeamRace then
		nShowTime = math.floor( nTimeRemain / 1000 );
	end
	local szShowTime = string.format( "%02d:%02d", math.floor( nShowTime / 60 ), nShowTime % 60 );
	self.m_pWndGameTime:SetWndText( szShowTime );

	self:TyroLineTipHelp();
	self:CheckTaskFinish();
end

function CGameMainLua:TyroLineTipHelp()
	local nAllScore = g_App:GetMainPlayerData().m_CharBaseData:GetAllGameScore();
	if nAllScore > CSnakeConstant:Inst():GetStartLimitSchema() * 2 then
		return;
	end

	local pPlayer = g_App:GetDirector();
	if not pPlayer then
		return;
	end
	local nWaypointLineCount = pPlayer:GetWaypointListCount();
	local nLineTooLongTip = CSnakeConstant:Inst():GetLineTooLongTip();
	self:TyroTipHelp( eMUT_LineTooLong, nWaypointLineCount > nLineTooLongTip );
end

function CGameMainLua:CoinFly()
	local pGoldWnd = self.m_wndCoin:GetDlgChild( "jinjbiIcon" );
	local nStartX = self:GetWndWidth() / 2;
	local nStartY = self:GetWndHeight() / 2;
	local nEndX = pGoldWnd:GetGlobalX();
	local nEndY = pGoldWnd:GetGlobalY();

	self:AddEffectFly( nStartX, nStartY, nEndX, nEndY, "fx/cfg/xiaohuangdian.eft" );
	self:UpdatePickCoin();
end

function CGameMainLua:UpdatePickCoin()
	local pDirector = g_App:GetDirector();
	local pScene = g_App:GetScene();
	local nObservedID = pScene:GetObservedPlayerID();
	if not pDirector and nObservedID then
		pDirector = pScene:GetPlayerByAccountID( nObservedID );
	end
	if not pDirector then
		return;
	end
	local szCoinCount = tostring( pDirector:GetSimple32Property( eSPT32_PickUpCoin ) );
	self.m_pWndGoldCoin:SetWndText( szCoinCount );
end

function CGameMainLua:OnExitScene( Event )
	g_App:MessageBox( g_App:GetString( "tuichuchangjing" ),{
		[CMessageBox.Close] = function()
			g_App.m_pMessageBox:ShowWnd( false );
		end;
	    [CMessageBox.OK] = function()
			g_App.m_pMessageBox:ShowWnd( false );
			local pScene = g_App:GetScene();
			if not pScene then
				return;
			end

			if pScene:GetRoomType() == eRT_Endless then
				pScene:GetWanfa():Balance( eRO_Esc );
			else
				local pField = g_App:GetFieldConn();
				if pScene:GetSceneInfo():IsServer() and pField then
					local NetMsg = CExitRoom:new();
					pField:SendShellMsg( NetMsg );
					pField:ForceClose();
				end

				g_App:SwitchStart();
			end
		end;
	} );
end

function CGameMainLua:UpdateRank( nDirectorID, arySysScore, nCount, bShowFirst )
	local pScene = g_App:GetScene();
	if not pScene then
		return;
	end
	arySysScore:SetDataSize( nCount*6 );
	local tblRankData = {};
	local nRoomType = pScene:GetRoomType();
	for i = 1, nCount do
		local temp = {};
		temp.m_nObjectID = arySysScore:ReadUint16();
		temp.m_nCalAllScore = arySysScore:ReadUint32();
		if nRoomType == eRT_Endless then
			temp.m_nCalAllScore = temp.m_nCalAllScore/pScene:GetNodeTotal();
		end
		table.insert( tblRankData, temp );
	end

	table.sort( tblRankData, function( a, b )
		return a.m_nCalAllScore > b.m_nCalAllScore;
	end );
	
	self.m_wndFirst:SetWndText( g_App:GetNickName() );
	local nStrWidth = self.m_wndFirst:GetStrWidth( g_App:GetNickName() );
	self.m_wndFirst:SetWndText( "" );
	local pCamera = g_App:GetCamera();
	local vecUIPos = CVector2f:new();
	self.m_wndFirst:ShowWnd( bShowFirst and tblRankData[1].m_nObjectID == nDirectorID );

	self.m_pWndRank1:ShowWnd( false );
	self.m_pWndRank2:ShowWnd( false );
	if nRoomType == eRT_Endless or nRoomType == eRT_LimitTime or nRoomType == eRT_LimitSecret or nRoomType == eRT_LimitRace then
		self.m_pWndRank1:ShowWnd( true );
		self.m_pWndRank1:UpdateRank( nDirectorID, tblRankData, nCount, pScene );
	elseif nRoomType == eRT_Team or nRoomType == eRT_TeamSecret or nRoomType == eRT_TeamRace then
		self.m_pWndRank2:ShowWnd( true );
		self.m_pWndRank2:UpdateRank( nDirectorID, tblRankData, nCount, pScene );
	end
	
	self:UpdateTrackTip( nDirectorID, tblRankData, pScene );
end

function CGameMainLua:UpdateTrackTip( nDirectorID, tblRankData, pScene )
	local nRootWidth = self:GetGUI():GetRootWidth();
	local nRootHeight = self:GetGUI():GetRootHeight();
	local TrackWndWidth = self.m_aryTrackTip[1]:GetWndWidth();
	local TrackWndHeight = self.m_aryTrackTip[1]:GetWndHeight();
	local rectWnd = CFRect:new( 0, 0, nRootWidth - TrackWndWidth, nRootHeight - TrackWndHeight);
	local vecCenter = CVector2f:new( nRootWidth / 2, nRootHeight / 2 );
	-- local Scene = g_App:GetScene()
	--判断房间类型
	local nRoomType =  pScene:GetRoomType();
	if nRoomType == eRT_Team or nRoomType == eRT_TeamSecret then
		local tblPlayerInfo = pScene.m_tblPlayerInfo;
		local nSelfManorID = tblPlayerInfo[nDirectorID].m_nManorID;
		local tblMemberID = {};
		for k, v in pairs ( pScene.m_tblPlayerInfo ) do
			if v.m_nManorID == nSelfManorID and k ~= nDirectorID then
				table.insert( tblMemberID, k );
			end
		end

		local nColor = g_App:GetManorColor( tblPlayerInfo[nDirectorID].m_nColor );
		for k , v in pairs ( tblMemberID ) do	
			local MemberObject =  pScene:GetCharacterByID( v );
			if not MemberObject then return end;
			local vecPos = MemberObject:GetPixelPos();
			local pCamera = g_App:GetCamera();
			if pCamera:GetScene() == pScene and self.m_aryTrackTipForTeam[k] then
				local vPlayerPos = CVector3f:new( vecPos:x(), 0, vecPos:y() );
				local vecUIPos = CVector2f:new();
				g_App:ScenePosToUIPos( vPlayerPos, pCamera, vecUIPos );
				if vecUIPos:x() < self:GetWndWidth() and vecUIPos:x() > 0 and
					vecUIPos:y() > 0 and vecUIPos:y() < self:GetWndHeight() then
					self.m_aryTrackTipForTeam[k]:ShowWnd( false );
				else
					Cut2DLine( rectWnd, vecCenter, vecUIPos );
					local vDir = CDir:new();
					vDir:Set( CVector2f:new( vecUIPos:x() - vecCenter:x(), vecCenter:y() - vecUIPos:y() ) );
					local fRadian = vDir:GetRadian();
					
					self.m_aryTrackTipForTeam[k]:ShowWnd( true );
					self.m_aryTrackTipForTeam[k]:SetGlobalX( vecUIPos:x() );
					self.m_aryTrackTipForTeam[k]:SetGlobalY( vecUIPos:y() );

					local pWndArrow = self.m_aryTrackTipForTeam[k]:GetDlgChild("bg_jiantou");
					pWndArrow:SetRotationZ( fRadian );
					pWndArrow:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, nColor );
				end
			end	
		end
	else
		for i = 1, 3 do
			if not tblRankData[i] then
				self.m_aryTrackTip[i]:ShowWnd( false );
				if i == 2 then
					self.m_aryTrackTip[i+1]:ShowWnd( false );
				end
				break;
			end
			local nObjectID = tblRankData[i].m_nObjectID;
			local tblPlayerInfo = pScene:GetPlayerInfo( nObjectID );

			local pPlayer = pScene:GetCharacterByID( nObjectID );
			if nDirectorID == nObjectID or not pPlayer then
				self.m_aryTrackTip[i]:ShowWnd( false );
			else
				local vecPos = pPlayer:GetPixelPos();
				local pCamera = g_App:GetCamera();
				if pCamera:GetScene() == pScene then
					local vPlayerPos = CVector3f:new( vecPos:x(), 0, vecPos:y() );
					local vecUIPos = CVector2f:new();
					g_App:ScenePosToUIPos( vPlayerPos, pCamera, vecUIPos );
					if vecUIPos:x() < self:GetWndWidth() and vecUIPos:x() > 0 and
						vecUIPos:y() > 0 and vecUIPos:y() < self:GetWndHeight() then
						self.m_aryTrackTip[i]:ShowWnd( false );
					else
						Cut2DLine( rectWnd, vecCenter, vecUIPos );
						local vDir = CDir:new();
						vDir:Set( CVector2f:new( vecUIPos:x() - vecCenter:x(), vecCenter:y() - vecUIPos:y() ) );
						local fRadian = vDir:GetRadian();
					
						self.m_aryTrackTip[i]:ShowWnd( true );
						self.m_aryTrackTip[i]:SetGlobalX( vecUIPos:x() );
						self.m_aryTrackTip[i]:SetGlobalY( vecUIPos:y() );

						local pWndArrow = self.m_aryTrackTip[i]:GetDlgChild("bg_jiantou");
						pWndArrow:SetRotationZ( fRadian );
						for nNum = 1, 3 do
							self.m_aryTrackTip[i]:GetDlgChild( "number"..nNum ):ShowWnd( nNum == i );
						end
						
						if tblPlayerInfo then
							local nColor = g_App:GetManorColor( tblPlayerInfo.m_nColorID );
							pWndArrow:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, nColor );
						end
					end
				end
			end
		end
	end 
end

function CGameMainLua:TyroTipHelp( nIndex, bShow )	--EMainUITip	
	if self.m_bObserveGame then
		return;
	end
	local nStopTishiScore = CSnakeConstant:Inst():GetStopTishiScore();
	local nCurAllGameScore = g_App:GetMainPlayerData().m_CharBaseData:GetAllGameScore();
	if g_App:GetScene():GetRoomType() == eRT_Guide then
		self.m_pWndTyro:ShowWnd( false );
		return;
	end
	if nCurAllGameScore >= nStopTishiScore then
		return;
	end
	
	if bShow then
		local bAdd = true;

		--删除其他靠tick删除的提示  
		local tblTemp = {};
		for i = 1, #self.m_tblTip do
			--if self.m_tblTip[i] < eMUT_TickDisappear or ( nIndex >= eMUT_TickDisappear and self.m_tblTip[i] == nIndex ) then
			if self.m_tblTip[i] < eMUT_TickDisappear then
				table.insert( tblTemp, self.m_tblTip[i] );
			end
		end
		self.m_tblTip = tblTemp;		

		--若队列已存在，则不继续执行，否则加入队列中  
		for i = 1, #self.m_tblTip do
			if self.m_tblTip[i] == nIndex then
				bAdd = false;
				return;
			end
		end
		if bAdd then
			table.insert( self.m_tblTip, nIndex );
			if nIndex >= eMUT_TickDisappear then				
				self.m_tickCloseTip:Start( 2000 );
				self.m_tickCloseTip:SetContext( nIndex );
			end
		end
	else
		local tblTemp = {};
		for i = 1, #self.m_tblTip do
			if self.m_tblTip[i] ~= nIndex then
				table.insert( tblTemp, self.m_tblTip[i] );
			end
		end
		self.m_tblTip = tblTemp;
	end

	local nShowIndex = eMUT_Init;
	local nCount = #self.m_tblTip;
	if nCount == 0 then				
		self.m_pWndTyro:ShowWnd( false );
		self.m_tblTip = {};
		return;
	else		
		nShowIndex = self.m_tblTip[nCount];
		self.m_pWndTyro:ShowWnd( true );
	end	

	local sShowStr = "";
	if nShowIndex == eMUT_ClickRhythmly then
		sShowStr = "genjiezou";
	elseif nShowIndex == eMUT_NoLongPress then
		sShowStr = "biechangan";
	elseif nShowIndex == eMUT_LineTooLong then
		sShowStr = "xiantaichang";
	elseif nShowIndex == eMUT_StrikeOthers then
		sShowStr = "zhuangxian";
	elseif nShowIndex == eMUT_MakeManor then
		sShowStr = "shengchenglingdi";
	elseif nShowIndex == eMUT_StrikeSelf then
		sShowStr = "xiaochuxian";
	elseif nShowIndex == eMUT_Died then
		sShowStr = "qiexian";
	else
		self.m_pWndTyro:ShowWnd( false );
		self.m_tblTip = {};
	end
	self.m_pWndTyro.m_wndContent:SetWndText( CStringConfig:Inst():GetString( sShowStr ) );
end

function CGameMainLua:OnCloseTip()
	local nTickContext = self.m_tickCloseTip:GetContext();
	local tblTemp = {};
	for i = 1, #self.m_tblTip do
		if self.m_tblTip[i] ~= nTickContext then
			table.insert( tblTemp, self.m_tblTip[i] );
		end
	end
	self.m_tblTip = tblTemp;
	self.m_pWndTyro.m_nLastTipIndex = eMUT_Init;
	self.m_pWndTyro:ShowWnd( false );
	self.m_tickCloseTip:Stop();
end

function CGameMainLua:PlayBattleFaceEffect( nIndex, nType )
	if nType == eBFT_Death then
		if nIndex ~= 0 then
			local Scene = g_App:GetScene();
			local wndReborn = Scene:GetWanfa().m_pWndRebirthEff;
			if wndReborn then
				local wndFace = wndReborn:GetDlgChild( "biaoqing" );
				if wndFace then
					wndFace:RemoveAllEffects();
					wndFace:AddEffect( g_tblTabFile.battleface[nIndex].szEffectFilePath, "fx/loop", nil, 3000 );
				end
			end
		end
	end
end

function CGameMainLua:ShowDoubleGradeText()
	self.m_pWndDoubleGradeText:ShowWnd( true );
	self.m_tickHideDoubleGrade:Start( 850 );	
end

function CGameMainLua:HideDoubleGrade()
	self.m_pWndDoubleGradeText:ShowWnd( false );
	self.m_tickHideDoubleGrade:Stop();
end

function CGameMainLua:PostStartCooling( nCooling )
	self.m_pGameButton:PostStartCooling( nCooling );
end

function CGameMainLua:PostEndCooling()
	self.m_pGameButton:PostEndCooling();
end

function CGameMainLua:UpdateDianzan()
    if self.m_nDianzan == 0 then
        local curX = self.m_pDianzan:GetGlobalX() + self.m_pDianzan:GetWndWidth() * 4 * 33 / 1000;
        if curX >= 0 then
            curX = 0;
            self.m_nDianzan = 1;
            self.m_tickDianzan:Stop();
            self.m_tickDianzan:Start( 1000 );
        end
        self.m_pDianzan:SetGlobalX( curX );
    elseif self.m_nDianzan == 1 then
        self.m_nDianzan = 2;
        self.m_tickDianzan:Stop();
        if self.m_tblDianzan[1] ~= nil then
            self.m_tickDianzan:Start( 33 );
        else
            self.m_tickDianzan:Start( 1000 );
        end
    elseif self.m_nDianzan == 2 then
        local curX = self.m_pDianzan:GetGlobalX() - self.m_pDianzan:GetWndWidth() * 4 * 33 / 1000;
        if curX < -self.m_pDianzan:GetWndWidth() then
            curX = -self.m_pDianzan:GetWndWidth();
            self.m_nDianzan = 0;
            self.m_tickDianzan:Stop();
            
            if self.m_tblDianzan[1] ~= nil then
                self.m_pDianzan:SetWndText( self.m_tblDianzan[1] );
                table.remove( self.m_tblDianzan, 1 );
                self.m_tickDianzan:Start( 33 );
            end
        else
            self.m_tickDianzan:Stop();
            self.m_tickDianzan:Start( 33 );
        end
        self.m_pDianzan:SetGlobalX( curX );
    end
end

function CGameMainLua:OnDianzan( szText )
    if not self:IsShow() then
        return;
    end
    if not self.m_tickDianzan:IsRegisted() then
        self.m_nDianzan = 0;
        self.m_pDianzan:SetWndText( szText );
        self.m_tickDianzan:Start( 33 );
    else
        table.insert( self.m_tblDianzan, szText );
    end
end

function CGameMainLua:InitTask()
	self.m_pWndTaskTips:ShowWnd( false );
	self.m_pWndTaskTarget:ShowWnd( false );
	self.m_pWndTaskDesc:ShowWnd( false );

	local Scene = g_App:GetScene();
	if not Scene or Scene:GetRoomType() ~= eRT_Endless then
		return
	end

	local szTask = "";
	local nCurTask = g_App:GetMainPlayerData().m_CharBaseData:GetCurTask();
	local nCurTarget = CDailyTaskConfig:Inst():GetTarget( nCurTask );
	if nCurTask ~= TASK_FINISHED then
		local nTaskType = CDailyTaskConfig:Inst():GetTaskType( nCurTask );
		if nTaskType == 0 then
			szTask = string.format( CStringConfig:Inst():GetTarStr( nCurTask ):ReadUTFBytes(256), nCurTarget * 100/10000 ); 
		else
			szTask = string.format( CStringConfig:Inst():GetTarStr( nCurTask ):ReadUTFBytes(256), nCurTarget ); 
		end
		self.m_pWndTaskTips:TaskTip( szTask );
		self.m_pWndTaskDesc:SetWndText( szTask );
		self.m_pWndTask:ShowWnd( true );
		self.m_pWndTaskDesc:ShowWnd( true );
	else
		self.m_pWndTaskTips:ShowWnd( false );
		self.m_pWndTask:ShowWnd( false );
	end
	self.m_pWndTaskTarget:SetWndData( 0 );
end

function CGameMainLua:CheckTaskFinish()
	local sz = "";
	local Scene = g_App:GetScene();
	local Player = g_App:GetDirector();
	if not Scene or not Player or Scene:GetRoomType() ~= eRT_Endless then
		self.m_pWndTask:ShowWnd(false);
		return;
	end
	
	local nCurTask = g_App:GetMainPlayerData().m_CharBaseData:GetCurTask();
	local nTarget = CDailyTaskConfig:Inst():GetTarget( nCurTask );
	if nCurTask == TASK_FINISHED then
		self.m_pWndTask:ShowWnd(false);
		return;
	end

	local nTaskType = CDailyTaskConfig:Inst():GetTaskType( nCurTask );
	local nMaxGrade = 0;
	if nTaskType == 0 then
		nMaxGrade = Player:GetSimple32Property( eSPT32_MaxAreaScore );
		nTarget = nTarget / 10000 * Scene:GetNodeTotal();
	elseif nTaskType == 1 then
		nMaxGrade = Player:GetSimple32Property( eSPT32_KillCount );
	elseif nTaskType == 2 then
		nMaxGrade = Player:GetSimple32Property( eSPT32_MaxComboCount );
	elseif nTaskType == 3 then
		nMaxGrade = Player:GetSimple32Property( eSPT32_MaxAreaScore ) + Player:GetSimple32Property( eSPT32_KillScore )
			 + Player:GetSimple32Property( eSPT32_ComboScore );
	end

	if nTarget > nMaxGrade then
		if nTaskType == 0 then
			sz = string.format( "%d%%" ,nMaxGrade * 100/Scene:GetNodeTotal() );
		else
			sz = sz .. nMaxGrade;
		end
	else
		sz = CStringConfig:Inst():GetString( "mubiaowancheng" );
	end

	self.m_pWndTaskTarget:SetWndText( sz );
	self.m_pWndTaskTarget:ShowWnd( true );

	if nTarget <= nMaxGrade and self.m_pWndTaskTarget:GetWndData() ~= 0 then
		self.m_pWndTaskTarget:SetWndData( 1 );
		local pWnd = self:GetDlgChild( "W_mubiaodacheng" );
		pWnd:RemoveAllEffects();
		pWnd:AddEffect( "fx/cfg/renwudacheng.eft", "fx/loop", "renwudacheng", 1000 );
	end
end

function CGameMainLua:ShowPlayerInfo( nAccountID )
	self.m_pHeadWnd:ShowPlayerInfo( nAccountID );
end

function CTyroWnd:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType  );
end

function CTyroWnd:OnCreated()
	self.m_wndContent = self:GetDlgChild( "you.neirong1" );
	self.m_nLastTipIndex = eMUT_Init;		--记录上次提示的类型
	self:ShowWnd( false );
end

function CTyroWnd:OnWndShow( bShow )
	if bShow then
		print();
	else
		print();
	end
end

------------------------------		RankWnd Start	---------------------------

function CWndMainRank1:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType  );
end

function CWndMainRank1:OnCreated()
	self.pWndSelfRank = CWndMainRank3:new();
	self:AssignDlgChildToWnd( self.pWndSelfRank, "xinxi.jilu" );
end

function CWndMainRank1:OnWndShow( bShow )	
	if bShow then
		--self.pWndSelfRank:InitValue();
	end
end

function CWndMainRank1:UpdateRank( nDirectorID, tblRankData, nCount, pScene )
	if not self:IsCreated() then
		return;
	end

	for i = 1, 7 do
		local pParNode = self:GetDlgChild( "xinxi.paihang.paihang_"..i );
		local pPlac = pParNode:GetDlgChild( "mingci" );
		local pName = pParNode:GetDlgChild( "mingcheng" );
		local pScore = pParNode:GetDlgChild( "jifen" );

		pPlac:SetWndText( tostring( i ) );
		pName:SetWndText( g_App:GetString( "rankEmpty" ) );
		pScore:SetWndText( "0" );
		pPlac:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, 0 );
		pParNode:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, 0 );
		
		if i <= nCount then
			local nObjectID = tblRankData[i].m_nObjectID;
			local tblPlayerInfo = pScene:GetPlayerInfo( nObjectID );
			if tblPlayerInfo then
				pName:SetWndText( tblPlayerInfo.m_szNickName );
				if pScene:GetRoomType() ~= eRT_Endless then
					pScore:SetWndText( tostring( tblRankData[i].m_nCalAllScore ) );
				else
					pScore:SetWndText( string.format( "%0.1f", tblRankData[i].m_nCalAllScore * 100 ) .. "%" );		
				end

				local nColor = g_App:GetManorColor( tblPlayerInfo.m_nColorID );
				pPlac:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, nColor );
				nColor = BitOr( BitAnd( nColor, 0x00FFFFFF ), 0x96000000 );
				pParNode:SetBackgroundColor( GSM_BS_BK, eST_ENABLE, nColor );
			end
		end
	end

	local pWndPlayer = self:GetDlgChild( "xinxi.zhujue" );
	local pPlac = pWndPlayer:GetDlgChild( "mingci" );
	local pName = pWndPlayer:GetDlgChild( "mingcheng" );
	local pScore = pWndPlayer:GetDlgChild( "jifen" );

	for i = 1, #tblRankData do
		local tblPlayerInfo = pScene:GetPlayerInfo( nDirectorID );
		if tblPlayerInfo and tblRankData[i].m_nObjectID == nDirectorID then
			pPlac:SetWndText( tostring( i ) );
			pName:SetWndText( tblPlayerInfo.m_szNickName );
			if pScene:GetRoomType() ~= eRT_Endless then
				pScore:SetWndText( tblRankData[i].m_nCalAllScore );
			else
				pScore:SetWndText( string.format( "%0.1f", tblRankData[i].m_nCalAllScore * 100 ) .. "%" );
			end

			--更新局内排行信息
			if pScene:GetRoomType() ~= eRT_LimitSecret and pScene:GetRoomType() ~= eRT_TeamSecret
				and pScene:GetRoomType() ~= eRT_LimitRace and pScene:GetRoomType() ~= eRT_TeamRace then
				self.pWndSelfRank:UpdateScore( tblRankData[i].m_nCalAllScore );
			else
				self.pWndSelfRank:ShowWnd( false );
			end
		end
	end
end

function CWndMainRank2:Ctor( sRes, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sRes, ParentWnd, nLoadType  );
end

function CWndMainRank2:OnCreated()
	self.pWndSelfRank = CWndMainRank3:new();
	self:AssignDlgChildToWnd( self.pWndSelfRank, "xinxi.jilu" );
end

function CWndMainRank2:OnWndShow( bShow )
	if bShow then
		--self.pWndSelfRank:InitValue();
	end
end

function CWndMainRank2:UpdateRank( nDirectorID, tblRankData, nCount, pScene )
	if not self:IsCreated() then
		return;
	end

	local tblTeamData = {};
	for i = 1, nCount do
		local tblPlayerInfo = pScene:GetPlayerInfo( tblRankData[ i ].m_nObjectID );
		if tblPlayerInfo then
			if not tblTeamData[tblPlayerInfo.m_nManorID] then
				tblTeamData[tblPlayerInfo.m_nManorID] = {};
			end
			table.insert( tblTeamData[tblPlayerInfo.m_nManorID], tblRankData[ i ] );
		end
	end
	
	local tblTeamScore = {};
	for _,aryData in pairs( tblTeamData ) do
		local TeamData = {};
		TeamData.m_nTeamScore = 0;
		for _,Data in pairs( aryData ) do
			TeamData.m_nTeamScore = TeamData.m_nTeamScore + Data.m_nCalAllScore;
		end
		
		local nObjectID = aryData[1].m_nObjectID;
		local tblPlayerInfo = pScene:GetPlayerInfo( nObjectID );
		TeamData.m_nColor = g_App:GetManorColor( tblPlayerInfo.m_nColorID );
		table.insert( tblTeamScore, TeamData );
	end

	table.sort( tblTeamScore , function( a, b )
		return a.m_nTeamScore > b.m_nTeamScore;
	end );

	local nAllScore = 0;
	for _,Team in pairs( tblTeamScore ) do
		nAllScore = nAllScore + Team.m_nTeamScore;
	end

	for i = 1, 3 do
		local pParNode = self:GetDlgChild( "xinxi.paihang.paihang_"..i );
		if not pParNode then
			break;
		end
		local pScore = pParNode:GetDlgChild( "jifen" );
		local pProgress = pParNode:GetDlgChild( "jindutiao" );

		pProgress:SetRange( nAllScore );
		pProgress:SetPos( 0 );
		pScore:SetWndText( "0" );
		pProgress:SetBackgroundColor( GSM_BS_BK, eST_FILL, 0 );

		if i <= #tblTeamScore then
			pScore:SetWndText( tostring( tblTeamScore[i].m_nTeamScore ) );
			pProgress:SetPos( tblTeamScore[i].m_nTeamScore );
			local nColor = BitOr( tblTeamScore[i].m_nColor, 0xFF000000 );
			pProgress:SetBackgroundColor( GSM_BS_BK, eST_FILL, nColor );
		end
	end
	if self.m_bOut then
		self:GetDlgChild( "xinxi.paihang.paihang_3.jifen" ):SetWndText( g_App:GetString( "yichuju" ) );
	end

	local pWndPlayer = self:GetDlgChild( "xinxi.zhujue" );
	local pPlac = pWndPlayer:GetDlgChild( "mingci" );
	local pName = pWndPlayer:GetDlgChild( "mingcheng" );
	local pScore = pWndPlayer:GetDlgChild( "jifen" );

	for i = 1, #tblRankData do
		local tblPlayerInfo = pScene:GetPlayerInfo( nDirectorID );
		if tblPlayerInfo and tblRankData[i].m_nObjectID == nDirectorID then
			pScore:SetWndText( tblRankData[i].m_nCalAllScore );

			--更新局内排行信息
			if pScene:GetRoomType() ~= eRT_LimitSecret and pScene:GetRoomType() ~= eRT_TeamSecret
				and pScene:GetRoomType() ~= eRT_LimitRace and pScene:GetRoomType() ~= eRT_TeamRace then
				self.pWndSelfRank:UpdateScore( tblRankData[i].m_nCalAllScore );
			else
				self.pWndSelfRank:ShowWnd( false );
			end
		end
	end
end

function CWndMainRank3:OnCreated()
	self.m_wndName = self:GetDlgChild( "mingzi" );
	self.m_wndScore = self:GetDlgChild( "fenshu" );
	self.m_wndWorldScore = self:GetDlgChild( "fenlei.shijie" );
	self.m_wndFriendScore = self:GetDlgChild( "fenlei.haoyou" );
	self.m_wndNoScore = self:GetDlgChild( "fenlei.kong" );
	self.m_wndSelfScore = self:GetDlgChild( "fenlei.ziji" );
	self.m_wndEffect1 = self:GetDlgChild( "fenlei.tx1" );
	self:InitValue();
end

function CWndMainRank3:InitValue()
	self.m_nShowFlag = nShowStart;
	self.m_bSelfFlag = false;
	self.m_bFriendFlag = false;
	self.m_bWorldFlag = false;
end

function CWndMainRank3:UpdateScore( nScore )
	self.m_wndWorldScore:ShowWnd( false );
	self.m_wndFriendScore:ShowWnd( false );
	self.m_wndSelfScore:ShowWnd( false );
	
	local pScene = g_App:GetScene();
	local nTodayType = eGradeType_EndlessToday;
	local nTodayWorldType = eRankMode_Endless;
	if pScene and pScene:GetRoomType() == eRT_Endless then
		nTodayType = eGradeType_EndlessToday;
	elseif pScene and pScene:GetRoomType() == eRT_LimitTime then
		nTodayType = eGradeType_LimitToday;
	elseif pScene and pScene:GetRoomType() == eRT_Team then
		nTodayType = eGradeType_TeamToday;
	end
	local tblRankData = g_App:GetCurRankData( nTodayType );
	local nShowScore = 0;			--显示的分数
	local szShowName = "";					--显示的名字
	if not tblRankData then return end

	if nScore == 0 then
		self:InitValue();
	end

	if tblRankData.nTodayScore == 0 and tblRankData.nFriendScore == 0 and tblRankData.nWorldScore == 0 then
		nShowScore = nScore;
		szShowName = g_App:GetNickName();
		self.m_wndWorldScore:ShowWnd( false );
		self.m_wndFriendScore:ShowWnd( false );
		self.m_wndSelfScore:ShowWnd( false );
		self.m_wndNoScore:ShowWnd( true );
	else
		if nScore <= tblRankData.nTodayScore then
			nShowScore = tblRankData.nTodayScore;
			szShowName = g_App:GetNickName();
			self.m_wndWorldScore:ShowWnd( false );
			self.m_wndFriendScore:ShowWnd( false );
			self.m_wndSelfScore:ShowWnd( true );
			self.m_wndNoScore:ShowWnd( false );
			if tblRankData.nTodayScore == tblRankData.nWorldScore then
				self.m_wndWorldScore:ShowWnd( true );
				self.m_wndSelfScore:ShowWnd( false );
				self.m_bWorldFlag = true;
			end
		elseif nScore <= tblRankData.nFriendScore and tblRankData.szFriendName ~= g_App:GetNickName() then
			nShowScore = tblRankData.nFriendScore;
			szShowName = tblRankData.szFriendName;
			if not self.m_bFriendFlag then
				self.m_wndEffect1:RemoveAllEffects();
				self.m_wndEffect1:AddEffect( "fx/cfg/qiehuan.eft", "fx/loop", "qiehuan", 0 );
				self.m_bFriendFlag = true;
			end
			self.m_wndWorldScore:ShowWnd( false );
			self.m_wndFriendScore:ShowWnd( true );
			self.m_wndSelfScore:ShowWnd( false );
			self.m_wndNoScore:ShowWnd( false );
			if tblRankData.nFriendScore == tblRankData.nWorldScore then
				self.m_wndWorldScore:ShowWnd( true );
				self.m_wndFriendScore:ShowWnd( false );
				self.m_bWorldFlag = true;
			end
		elseif nScore <= tblRankData.nWorldScore then
			if not self.m_bWorldFlag then
				self.m_wndEffect1:RemoveAllEffects();
				self.m_wndEffect1:AddEffect( "fx/cfg/qiehuan.eft", "fx/loop", "qiehuan", 0 );
				self.m_bWorldFlag = true;
			end
			nShowScore = tblRankData.nWorldScore;
			szShowName = tblRankData.szWorldName;
			self.m_wndWorldScore:ShowWnd( true );
			self.m_wndFriendScore:ShowWnd( false );
			self.m_wndSelfScore:ShowWnd( false );
			self.m_wndNoScore:ShowWnd( false );
		else
			nShowScore = nScore;
			szShowName = g_App:GetNickName();
			self.m_wndWorldScore:ShowWnd( true );
			self.m_wndFriendScore:ShowWnd( false );
			self.m_wndSelfScore:ShowWnd( false );
			self.m_wndNoScore:ShowWnd( false );
		end
	end
	
	if nTodayType == eGradeType_EndlessToday then
		self.m_wndScore:SetWndText( string.format( "%.2f%%", nShowScore * 100 ));
	else
		self.m_wndScore:SetWndText( nShowScore );
	end
	self.m_wndName:SetWndText( szShowName );	
end
------------------------------		RankWnd End		---------------------------
--endregion
