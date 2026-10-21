--region CWndTreasureBoxOpen.lua
--Date 2017.11.28
-- "fsj_pifu_baoxiangkaiqi.gui"
--宝箱开启获得碎片界面

local nEffectMoveTime = 20;

function CWndTreasureBoxOpen:Ctor( sResName, ParentWnd, nLoadType, nTreasureBoxID, tblProp, nExpAdd, nPosIndex, nMatrlIndex )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
	self.m_nTreasureBoxID = nTreasureBoxID;
	self.m_tblProp = tblProp;
	self.m_nExpAdd = nExpAdd;
	self.m_nPosIndex = nPosIndex;
	self.m_nMatrlIndex = nMatrlIndex;
end

function CWndTreasureBoxOpen:OnCreated()
	self.m_wndEffectBegin			= self:GetDlgChild( "txspawn" );
	self.m_wndEffectEnd				= self:GetDlgChild( "txend" );
	self.m_wndEffectMove			= self:GetDlgChild( "tx" );

	self.m_wndCommonFragment		= self:GetDlgChild( "putongpifu" );
	self.m_wndCommonFragmentIcon	= CRichIconWnd:new( self, "putongpifu.txdikuang.tietu" );
	self.m_wndCommonFragmentName	= self:GetDlgChild( "putongpifu.name" );
	self.m_wndCommonFragmentPro		= self:GetDlgChild( "putongpifu.jindutiao" );
	self.m_wndCommonFragmentProText = self:GetDlgChild( "putongpifu.jindutiao.zongshuliang" );
	self.m_wndCommonFragmentCount	= self:GetDlgChild( "putongpifu.txdikuang.tietu.huodeshuliang" );

	self.m_wndTreasureRemainTime	= self:GetDlgChild( "neirongshuliang" );
	self.m_wndTreasureRemainCount	= self:GetDlgChild( "neirongshuliang.shuzi" );

	self.m_wndGoldCoin				= self:GetDlgChild( "jinbi" );
	self.m_wndGoldCoinTotal			= self:GetDlgChild( "jinbi.jindutiao.zongshuliang" );
	self.m_wndGoldCoinIcon			= CRichIconWnd:new( self, "jinbi.txdikuang.tietu" );
	self.m_wndGoldCoinName			= self:GetDlgChild( "jinbi.name" );
	self.m_wndGoldCoinGet			= self:GetDlgChild( "jinbi.txdikuang.tietu.huodeshuliang" );
	self.m_wndGoldCoinSmallIcon		= CRichIconWnd:new( self, "jinbi.tietu");

	self.m_wndFusionFragment		= self:GetDlgChild( "hechengpifu" );
	self.m_wndFusionFragmentIcon	= CRichIconWnd:new( self, "hechengpifu.txdikuang.tietu" );
	self.m_wndFusionFragmentName	= self:GetDlgChild( "hechengpifu.name" );
	self.m_wndFusionFragmentPro		= self:GetDlgChild( "hechengpifu.jindutiao" );
	self.m_wndFusionFragmentProText = self:GetDlgChild( "hechengpifu.jindutiao.zongshuliang" );
	self.m_wndFusionFragmentCount	= self:GetDlgChild( "hechengpifu.txdikuang.tietu.huodeshuliang" );

	self.m_wndRainbowFragment		= self:GetDlgChild( "caihongshua" );
	self.m_wndRainbowFragmentIcon	= CRichIconWnd:new( self, "caihongshua.txdikuang.tietu" );
	self.m_wndRainbowFragmentName	= self:GetDlgChild( "caihongshua.name" );
	self.m_wndRainbowFragmentTotal	= self:GetDlgChild( "caihongshua.jindutiao.zongshuliang" );
	self.m_wndrainbowFragmentGet	= self:GetDlgChild( "caihongshua.txdikuang.tietu.huodeshuliang" );

	self.m_TreasureBoxOpenEffect	= self:GetDlgChild( "baoxiangtexiao" );
	self.m_BtnClose					= self:GetDlgChild( "b_ok" );

	self.m_BtnOpen					= self:GetDlgChild( "close" );

	self.m_nFxBeginX				= self.m_wndEffectBegin:GetLocalX();
	self.m_nFxBeginY				= self.m_wndEffectBegin:GetLocalY();
	self.m_nFxEndX					= self.m_wndEffectEnd:GetLocalX();
	self.m_nFxEndY					= self.m_wndEffectEnd:GetLocalY();
	self.m_nMoveSpeedX				= ( self.m_nFxEndX - self.m_nFxBeginX ) / nEffectMoveTime;
	self.m_nMoveSpeedY				= ( self.m_nFxEndY - self.m_nFxBeginY ) / nEffectMoveTime;

	
	self.m_BtnClose:AddActionListener( "OnClose", self );
	self.m_WndFusionSkinCollectPro = CWndCollectPro:new( "gui/cfg/fsj_pifu_shoujijindu.gui", self, 1 );
	self.m_BtnOpen:AddActionListener( "OpenTreasureBox", self );

	self.m_Listener = IAnimationListener:new();
	self.m_Listener.m_pWnd = self;
	self.m_Listener.OnAniPlayStart = function() end
	self.m_Listener.OnFrameString = function() end
	self.m_Listener.OnAniPlayEnd = function( this ) this.m_pWnd:OnAniPlayEnd(); end
	self.m_pRenderObject = g_App:CreateRenderObject();
	self.m_pViewportRenderer = self.m_TreasureBoxOpenEffect:GetViewportRenderer();
	self.m_pViewportRenderer:EnableResetTimeOnShow( true );
	self.m_pViewportRenderer:AddChild( self.m_pRenderObject );

	self.m_tickFxMove				= CTick:new( "OnFxMove", self );
	self.m_tickAddCount				= CTick:new( "OnAddCount", self );
	self.m_tickShowCollectPro		= CTick:new( "OnTickPro", self );
	self.m_tickFirstStep			= CTick:new( "OnFisrtStep", self );

	self:SetData();
end

function CWndTreasureBoxOpen:OnDestroy()
	self:StopAllTick();
	g_App:DestroyRenderObject( self.m_pRenderObject );
	self.m_pRenderObject = nil;
end

function CWndTreasureBoxOpen:OnWndShow( bShow )
	if not bShow then
		self:StopAllTick();
		self:DestroyWnd();
	end
end

function CWndTreasureBoxOpen:ResetFxPos()
	self.m_wndEffectMove:RemoveAllEffects();
	self.m_wndEffectMove:SetLocalX( self.m_nFxBeginX );
	self.m_wndEffectMove:SetLocalY( self.m_nFxBeginY );
end

function CWndTreasureBoxOpen:HideWnd()
	self.m_wndCommonFragment:ShowWnd( false );
	self.m_wndFusionFragment:ShowWnd( false );
	self.m_wndGoldCoin:ShowWnd( false );
	self.m_wndRainbowFragment:ShowWnd( false );
	self.m_wndTreasureRemainTime:ShowWnd( false );
	self.m_BtnClose:ShowWnd( false );
end

function CWndTreasureBoxOpen:SetData( nTreasureboxID, tblProp )
	self:HideWnd();
	self:ShowAndSetFocus();
	self.m_nKindCount = table.count( self.m_tblProp );
	self.m_nClickTime = 1;
	self.m_nFxMoveTime = 0;
	self.m_BtnOpen:EnableWnd( false );
	self:ResetFxPos();
	local nTreasureBoxLevel = g_tblTabFile.treasureboxbase[self.m_nTreasureBoxID].nLevel;
	local tblSzTreasureBoxOpenEffect = { "fx/cfg/box03.eft", "fx/cfg/box02.eft", "fx/cfg/box01.eft" };
	self.m_szTreasureBoxOpenEffect = tblSzTreasureBoxOpenEffect[nTreasureBoxLevel];
	self.m_pRenderObject:ShowTreasureBoxModel( nTreasureBoxLevel, self.m_nMatrlIndex );
	self.m_pRenderObject:SetNodeAni( "stand1", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, self.m_Listener );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szTreasureBoxOpenEffect, "fx/stand1", nil, false, 0 );
	local Camera = self.m_pViewportRenderer:GetCamera();
	local fUpX = g_data_treasureboxpos[1].fUpX;
	local fUpY = g_data_treasureboxpos[1].fUpY;
	local fUpZ = g_data_treasureboxpos[1].fUpZ;
	local fPosX = g_data_treasureboxpos[1].fPosX;
	local fPosY = g_data_treasureboxpos[1].fPosY;
	local fPosZ = g_data_treasureboxpos[1].fPosZ;
	local fDestX = g_data_treasureboxpos[1].fDestX;
	local fDestY = g_data_treasureboxpos[1].fDestY;
	local fDestZ = g_data_treasureboxpos[1].fDestZ;
	Camera:SetUp( CVector3f:new( fUpX, fUpY, fUpZ ) );
	Camera:SetPos( CVector3f:new( fPosX, fPosY, fPosZ ) );
	Camera:SetDest( CVector3f:new( fDestX, fDestY, fDestZ ) );
	local PlayerData = g_App:GetMainPlayerData().m_HaveEquip;
	self.m_tblSkinHave = {};
	for i = 1, PlayerData:GetDataCount() do
		local nSkinID = PlayerData:GetData( i - 1 );
		if nSkinID ~= 0 then
			self.m_tblSkinHave[nSkinID] = nSkinID;
		end
	end
	self.m_tickFirstStep:Start( 1500 );
end

function CWndTreasureBoxOpen:OnFisrtStep()
	self.m_tickFirstStep:Stop();
	self:OpenTreasureBox( true );
end

function CWndTreasureBoxOpen:OnAniPlayEnd()
	self.m_pRenderObject:SetNodeAni( "stand3", nil, SFramePair:new(), eAPT_Loop, 0, 0, 1.0, nil );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szTreasureBoxOpenEffect, "fx/stand3", nil, false, -1 );
--	if self.m_nClickTime == 1 then
--		self:OpenTreasureBox( true );
--	else
	if self.m_nClickTime ~= 1 then
		self.m_BtnOpen:EnableWnd( true );
	end
	self.m_wndTreasureRemainTime:ShowWnd( true );
	self.m_wndTreasureRemainCount:SetWndText( self.m_nKindCount - self.m_nClickTime + 1 );
end

function CWndTreasureBoxOpen:OpenTreasureBox( bInit )
	self.m_BtnOpen:EnableWnd( false );
	local PropData = self.m_tblProp[self.m_nClickTime];
	if PropData then
		self.m_PropData = PropData;
		self.m_BtnClose:ShowWnd( false );
		self.m_wndTreasureRemainCount:SetWndText( self.m_nKindCount - self.m_nClickTime );
		self.m_nClickTime = self.m_nClickTime + 1;
		self.m_wndEffectMove:ShowWnd( true );
		self.m_wndEffectMove:AddEffect( "fx/cfg/baoxiang_wupin.eft", "fx/fly", nil, -1 );
		self.m_tickFxMove:Start( 33 );
		if bInit ~= true then
			self.m_pRenderObject:SetNodeAni( "stand2", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, nil );
			self.m_pRenderObject:AddFusionSkinEffect( self.m_szTreasureBoxOpenEffect, "fx/stand2", "opentreasureboxstand2", false, 0 );
		end
		self.m_wndGoldCoin:ShowWnd( false );
		self.m_wndRainbowFragment:ShowWnd( false );
		self.m_wndCommonFragment:ShowWnd( false );
		self.m_wndFusionFragment:ShowWnd( false );
	else
		if self.m_nExpAdd then
			local wndTreasureBox = g_App:GetGameStart().m_WndTreasureBox;
			wndTreasureBox:PlayExperienceAddEffect( self.m_nExpAdd, self.m_nPosIndex );
		end
		self.m_BtnOpen:EnableWnd( true );
		if bInit ~= true then
			bInit.m_StopImmediately = true;
		end
		self:DestroyWnd();
	end
end

function CWndTreasureBoxOpen:OnFxMove()
	self.m_nFxMoveTime = self.m_nFxMoveTime + 1;
	if self.m_nFxMoveTime > nEffectMoveTime then
		self.m_nFxMoveTime = 0;
		self.m_tickFxMove:Stop();
		self.m_wndEffectMove:RemoveAllEffects();
		self.m_wndEffectMove:ShowWnd( false );
		self:ShowFragmentData( self.m_PropData );
		self:ResetFxPos();
		if self.m_nKindCount == self.m_nClickTime - 1 then
			self.m_BtnClose:ShowWnd( true );
		end
	end
	local nCurX = self.m_wndEffectMove:GetLocalX() + self.m_nMoveSpeedX;
	local nCurY = self.m_wndEffectMove:GetLocalY() + self.m_nMoveSpeedY;
	self.m_wndEffectMove:SetLocalX( nCurX );
	self.m_wndEffectMove:SetLocalY( nCurY );	 
end

function CWndTreasureBoxOpen:ShowFragmentData( PropData )
	local nPropType = PropData.nType;
	local nPropIndex = PropData.nIndex;
	local nPropCount = PropData.nCount;
	if nPropType == eGRT_Fragment then
		local nFragmentType = g_tblTabFile.fragment[nPropIndex].nFragmentType;
		local nSkinID = g_tblTabFile.fragment[nPropIndex].nSkin;
		local szFragmentName = g_tblTabFile.fragment[nPropIndex].dName;
		local nIconID = g_tblTabFile.fragment[nPropIndex].nIconID;
		if nSkinID ~= 0 then
			if nFragmentType == 1 then
				self.m_wndCommonFragment:ShowWnd( true );
				self.m_wndCommonFragmentIcon:RestoreImageFromCreateParam();
				self.m_wndCommonFragmentIcon:SetIconID( nIconID );
				self.m_wndCommonFragmentName:SetWndText( szFragmentName );
				self.m_wndCommonFragmentCount:SetWndText( nPropCount );
				local nCountNeed = g_tblTabFile.fragment[nPropIndex].nCountMax;
				self.m_wndCommonFragmentPro:SetRange( nCountNeed );
				self.m_nType = 1;
				self.m_ProMax = nCountNeed;
			elseif nFragmentType == 2 then
				self.m_wndFusionFragment:ShowWnd( true );
				self.m_wndFusionFragmentIcon:RestoreImageFromCreateParam();
				self.m_wndFusionFragmentIcon:SetIconID( nIconID );
				self.m_wndFusionFragmentName:SetWndText( szFragmentName );
				self.m_wndFusionFragmentCount:SetWndText( nPropCount );
				local nFusionSkinIDMin = nSkinID - nSkinID%10 + 1;
				local nFusionSkinIDMax = nSkinID;
				self.m_nFusionSkin = nFusionSkinIDMin;
				for i = nFusionSkinIDMin, nFusionSkinIDMax do
					if not self.m_tblSkinHave[i] then
						self.m_nFusionSkin = i;
						break;
					end
				end
				self.m_ProMax = 0;
				for i = 1, 5 do
					if g_tblTabFile.fusion[self.m_nFusionSkin]["nFragment"..i] == nPropIndex then
						self.m_nCountNeed = g_tblTabFile.fusion[self.m_nFusionSkin]["nCount"..i];
					end
					self.m_ProMax = self.m_ProMax + g_tblTabFile.fusion[self.m_nFusionSkin]["nCount"..i]
				end
				self.m_wndFusionFragmentPro:SetRange( nCountNeed );
				self.m_nType = 2;
				self.m_nAddCount = nPropCount;
			end
		else
			self.m_wndRainbowFragment:ShowWnd( true );
			self.m_wndRainbowFragmentIcon:RestoreImageFromCreateParam();
			self.m_wndRainbowFragmentIcon:SetIconID( nIconID );
			self.m_wndRainbowFragmentName:SetWndText( szFragmentName );
			self.m_wndrainbowFragmentGet:SetWndText( nPropCount );
			self.m_nType = 3;
		end
		self.m_nCountAddSpeed = 1;
		self.m_nCountBegin = g_App:GetFragmentCount( nPropIndex ) - nPropCount;
		self.m_nCountEnd = g_App:GetFragmentCount( nPropIndex );
	elseif nPropType == eGRT_Resource then
		self.m_nType = 4;
		self.m_wndGoldCoin:ShowWnd( true );
		self.m_wndGoldCoinGet:SetWndText( nPropCount );
		self.m_nCountAddSpeed = math.floor( nPropCount/30);
		local nIconID = g_tblTabFile.currency[nPropIndex].nIconID;
		self.m_wndGoldCoinIcon:RestoreImageFromCreateParam();
		self.m_wndGoldCoinSmallIcon:RestoreImageFromCreateParam();
		self.m_wndGoldCoinSmallIcon:SetIconID( nIconID );
		self.m_wndGoldCoinIcon:SetIconID( nIconID );
		self.m_wndGoldCoinName:SetWndText( g_tblTabFile.currency[nPropIndex].dName );
		if self.m_nCountAddSpeed == 0 then
			self.m_nCountAddSpeed = 1;
		end
		self.m_nCountBegin = g_App:GetPropCount( nPropType, nPropIndex ) - nPropCount;
		self.m_nCountEnd = g_App:GetPropCount( nPropType, nPropIndex );
	end
	self.m_tickAddCount:Start( 33 );		
end

function CWndTreasureBoxOpen:OnAddCount()
	self.m_nCountBegin = self.m_nCountBegin + self.m_nCountAddSpeed;
	if self.m_nCountBegin > self.m_nCountEnd then
		if self.m_nType == 1 then
			self.m_wndCommonFragmentProText:SetWndText( self.m_nCountEnd .. "/" .. self.m_ProMax );
			self.m_wndCommonFragmentPro:SetPos( self.m_nCountEnd );
		elseif self.m_nType == 2 then
			self.m_wndFusionFragmentProText:SetWndText( self.m_nCountEnd .. "/" .. self.m_nCountNeed );
			self.m_wndFusionFragmentPro:SetPos( self.m_nCountEnd );
			self.m_tickShowCollectPro:Start( 500 );
		elseif self.m_nType == 3 then
			self.m_wndRainbowFragmentTotal:SetWndText( self.m_nCountEnd );
		elseif self.m_nType == 4 then
			self.m_wndGoldCoinTotal:SetWndText( self.m_nCountEnd );
		end
		if self.m_nType ~= 2 then
			self.m_BtnOpen:EnableWnd( true );
		end
		self.m_tickAddCount:Stop();
		return;
	end

	if self.m_nType == 1 then
		self.m_wndCommonFragmentProText:SetWndText( self.m_nCountBegin .. "/" .. self.m_ProMax );
		self.m_wndCommonFragmentPro:SetPos( self.m_nCountBegin );	
	elseif self.m_nType == 2 then
		self.m_wndFusionFragmentProText:SetWndText( self.m_nCountBegin .. "/" .. self.m_ProMax );
		self.m_wndFusionFragmentPro:SetPos( self.m_nCountBegin );
	elseif self.m_nType == 3 then
		self.m_wndRainbowFragmentTotal:SetWndText( self.m_nCountBegin );
	elseif self.m_nType == 4 then
		self.m_wndGoldCoinTotal:SetWndText( self.m_nCountBegin );
	end
end

function CWndTreasureBoxOpen:OnTickPro()
	self.m_tickShowCollectPro:Stop();
	self.m_BtnOpen:EnableWnd( true );
	self.m_WndFusionSkinCollectPro:ShowFragmentCollectPro( self.m_nFusionSkin, self.m_nCountEnd, self.m_nAddCount, self.m_ProMax );
end

function CWndTreasureBoxOpen:OnClose( Event )
	self.m_wndTreasureRemainTime:ShowWnd( false );
	self:StopAllTick();
	Event.m_StopImmediately = true;
	self:DestroyWnd();
end

function CWndTreasureBoxOpen:StopAllTick()
	self.m_tickFxMove:Stop();
	self.m_tickAddCount:Stop();
	self.m_tickShowCollectPro:Stop();
	self.m_tickFirstStep:Stop();
end

--endregion
