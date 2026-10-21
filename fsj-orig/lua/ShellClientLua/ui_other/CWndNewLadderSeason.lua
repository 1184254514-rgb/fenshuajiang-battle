--region CWndNewLadderSeason.lua
--Date	2017.9.20
--此文件由[BabeLua]插件自动生成
local TblLadderEffect = 
{
	[1] = "fx/cfg/duanwei_1_qt.eft", 
	[2] = "fx/cfg/duanwei_2_by.eft", 
	[3] = "fx/cfg/duanwei_3_hj.eft", 
	[4] = "fx/cfg/duanwei_4_bj.eft", 
	[5] = "fx/cfg/duanwei_5_zs.eft", 
	[6] = "fx/cfg/duanwei_6_ds.eft", 
	[7] = "fx/cfg/duanwei_7_wz.eft", 
	[8] = "fx/cfg/duanwei_8_cs.eft", 
}
local nShowLSTitle = 200;
local nShowLSStars = 700;

local nTimeInheritStep1 = 1000;
local nIntervalInheritStep1 = 50;
local nNumInheritStep1 = nTimeInheritStep1 / nIntervalInheritStep1;
local nTimeInheritStep3 = 1000;
local nIntervalInheritStep3 = 50;
local nNumInheritStep3 = nTimeInheritStep3 / nIntervalInheritStep3;
local nTimeShowInheritStep7 = 150;
local nIntervalInheritStep8 = 500;
local nTimeInheritStep9 = 1000;
local nIntervalInheritStep9 = 50;
local nNumInheritStep9 = nTimeInheritStep9 / nIntervalInheritStep9;

function CWndNewLadderSeason:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );
end

function CWndNewLadderSeason:OnCreated()
	self.m_pWndTitle = self:GetDlgChild( "title" );
	self.m_pWndTitle:ShowWnd( false );
	self.m_pWndLastSeason = self:GetDlgChild( "tx.loop" );
	self.m_pWndTextEffect = self:GetDlgChild( "tx.wenzitx" );
	self.m_pWndLSDis = self:GetDlgChild( "tx.end" );
	self.m_pWndCSAcc = self:GetDlgChild( "tx.cast" );
	self.m_pWndEffectShine = self:GetDlgChild( "tx.duanweiguang" );
	self.m_pWndCurSeason = self:GetDlgChild( "duanweitx2" );
	self.m_pWndLadderName = self:GetDlgChild( "duanweimingzi" );
	self.m_pWndLadderName:ShowWnd( false );
	self.m_tblStar = {};
	self.m_tblStar[1] = self:GetDlgChild( "chuanshuo" );
	self.m_tblStar[1]:ShowWnd( false );
	for i = 2, 5 do
		self.m_tblStar[i] = self:GetDlgChild( tostring( i ).."star" );
		self.m_tblStar[i]:ShowWnd( false );
	end
	self.m_pBtnContinue = self:GetDlgChild( "btn_jixu" );
	self.m_pBtnContinue:AddActionListener( "OnClickContinue", self );
	self.m_pBtnContinue:ShowWnd( false );
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pBtnClose:ShowWnd( false );
	self.m_pBtnClose:AddActionListener( "OnClickClose", self );

	self.m_pWndPrizeItem = CWndLadderPrizeItem:new( "gui/cfg/fsj_huodeprop.gui", self, 1 );

	self.m_tickShowLSStep2 = CTick:new( "ShowLastSeasonStep2", self, nil, 1 );
	self.m_tickShowLSNameStep2 = CTick:new( "OnShowLSNameStep2", self );
	self.m_tickLastSeason = CTick:new( "OnShowLastSeasonTick", self );
	self.m_tickLSStars = CTick:new( "OnShowLSStarsTick", self );
	self.m_tickLSChuanShuoStar = CTick:new( "OnShowLSChuanShuoStarTick", self, nil, 1 );
	self.m_tickInheritStep1 = CTick:new( "OnInheritStep1Tick", self );
	self.m_tickInheritStep3 = CTick:new( "OnInheritStep3Tick", self );
	self.m_tickShowInheritStep6 = CTick:new( "OnShowInheritStep6Tick", self, nil, 1 );
	self.m_tickShowInheritStep7 = CTick:new( "OnShowInheritStep7Tick", self, nil, 1 );
	self.m_tickInheritStep8 = CTick:new( "OnInheritStep8Tick", self );
	self.m_tickInheritStep9 = CTick:new( "OnInheritStep9Tick", self );
end

function CWndNewLadderSeason:OnDestroy()
	self.m_tickShowLSStep2:Stop();
	self.m_tickShowLSNameStep2:Stop();
	self.m_tickLastSeason:Stop();
	self.m_tickLSStars:Stop();
	self.m_tickLSChuanShuoStar:Stop();
	self.m_tickInheritStep1:Stop();
	self.m_tickInheritStep3:Stop();
	self.m_tickShowInheritStep6:Stop();
	self.m_tickShowInheritStep7:Stop();
	self.m_tickInheritStep8:Stop();
	self.m_tickInheritStep9:Stop();
	self.m_pWndTextEffect:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep2", self );
	self.m_pWndTextEffect:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep4", self );
	CGWnd.OnDestroy( self );
end

function CWndNewLadderSeason:OnWndShow( bShow )
	if bShow then
		if g_App:IsShowNewSeason() then
			self:InitData();
			self:StartLastSeason();
		else
			self:ShowWnd( false );
		end
	else
		g_App:SetShowNewSeason( false );
	end
end

function CWndNewLadderSeason:ShowedPrize()
	print( "1111111111111111 CWndNewLadderSeason:ShowedPrize()" );
	self.m_wndPrize:ShowWnd( false );
	self:ShowInherit();
end

function CWndNewLadderSeason:OnClickClose()
	self:ShowWnd( false );
end

function CWndNewLadderSeason:InitData()
	self.m_nLastSeasonStarInherit = g_App:GetLastSeasonStarInherit();
	self.m_nCurSeasonStarInherit = g_App:GetCurSeasonStarInherit();
	self.m_nMaxStar = CStarLevelConfig:Inst():GetMaxStar();
	self.m_tblPrize = {};
	self.m_tblPrize = SplitStr( CStarLevelConfig:Inst():GetSeasonPrizeStr( self.m_nLastSeasonStarInherit ), "," );	--self.m_nLastSeasonStarInherit
	self.m_pWndPrizeItem:SetPrizeList( self.m_tblPrize );
	self.m_nCSHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_nCurSeasonStarInherit );

	if self.m_nLastSeasonStarInherit >= self.m_nMaxStar then
		self.m_pWndLSStar = self.m_tblStar[1];
	else
		local nLSCurMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nLastSeasonStarInherit );
		self.m_pWndLSStar = self.m_tblStar[nLSCurMaxStar];
	end
	local nLastLevel = CStarLevelConfig:Inst():GetBigLevel( self.m_nLastSeasonStarInherit );
	self.m_pEffectLSLevel = TblLadderEffect[nLastLevel];
	local nCurLevel = CStarLevelConfig:Inst():GetBigLevel( self.m_nCurSeasonStarInherit );
	self.m_pEffectCSLevel = TblLadderEffect[nCurLevel];
	
	if self.m_nCurSeasonStarInherit >= self.m_nMaxStar then
		self.m_pWndCSStar = self.m_tblStar[1];
	else
		local nCSCurMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nCurSeasonStarInherit );
		self.m_pWndCSStar = self.m_tblStar[nCSCurMaxStar];
	end
end

function CWndNewLadderSeason:StartLastSeason()
	self.m_pWndLastSeason:AddEffect( self.m_pEffectLSLevel, "fx/loop", "LastSeasonLoop", -1 );
	self.m_pWndTitle:SetWndText( g_App:GetString( "saijijiesuan3" ) );
	self.m_pWndTitle:ShowWnd( true );
	local dName = CStarLevelConfig:Inst():GetName( self.m_nLastSeasonStarInherit );
	self.m_pWndLadderName:SetWndText( dName );
	self.m_pWndLadderName:ShowWnd( true );
	self:ShowLastSeasonStep3();

	--self:ShowLastSeasonStep1();
	--self.m_tickShowLSStep2:Start( 5000 );
end

function CWndNewLadderSeason:ShowLastSeasonStep1()
	print( "CWndNewLadderSeason:ShowLastSeasonStep1()" );
	self.m_pWndLastSeason:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishLSLevelAcc", self );
	self.m_pWndLastSeason:AddEffect( self.m_pEffectLSLevel, "fx/end", "LSLevelAcc", 0 );
	self.m_pWndTitle:SetWndText( g_App:GetString( "saijijiesuan3" ) );
	self.m_pWndTitle:SetFadeDuration( 1000 );
	self.m_pWndTitle:ShowWnd( true );
end

function CWndNewLadderSeason:ShowLastSeasonStep2()
	print( "CWndNewLadderSeason:ShowLastSeasonStep2()" );
	self.m_tickShowLSStep2:Stop();
	self.m_pWndLastSeason:AddEffect( self.m_pEffectLSLevel, "fx/loop", "LastSeasonLoop", -1 );
	local dName = CStarLevelConfig:Inst():GetName( self.m_nLastSeasonStarInherit );
	self.m_pWndLadderName:SetWndText( dName );
	self.m_pWndLadderName:SetFadeDuration( 1000 );
	self.m_pWndLadderName:ShowWnd( true );
end

function CWndNewLadderSeason:OnFinishLSLevelAcc()
	self.m_pWndLastSeason:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishLSLevelAcc", self );
	self.m_tickLastSeason:Start( 100 );
end

function CWndNewLadderSeason:OnShowLastSeasonTick()
	local nTickCount = self.m_tickLastSeason:GetTickCount();
	if nTickCount >= nShowLSStars / 100 then		
		self.m_tickLastSeason:Stop();
		self:ShowLastSeasonStep3();
	end
end

function CWndNewLadderSeason:ShowLastSeasonStep3()	--显示星星
	print( "CWndNewLadderSeason:ShowLastSeasonStep3()" );
	local nLastLevel = CStarLevelConfig:Inst():GetBigLevel( self.m_nLastSeasonStarInherit );
	local nMaxStar = CStarLevelConfig:Inst():GetMaxStar();
	local nCurMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nLastSeasonStarInherit );
	local nCurHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_nLastSeasonStarInherit );
	local dName = CStarLevelConfig:Inst():GetName( self.m_nLastSeasonStarInherit );
	if not self.m_pEffectLSLevel then return end
	if self.m_nLastSeasonStarInherit >= nMaxStar then
		self.m_tblStar[1]:ShowWnd( true );
		self.m_tblStar[1]:GetDlgChild( "star1" ):EnableWnd( true );
		self.m_tickLSChuanShuoStar:Start( 100 );
	else
		for i = 1, nCurMaxStar do
			self.m_tblStar[nCurMaxStar]:GetDlgChild( "star"..i ):ShowWnd( false );
			self.m_tblStar[nCurMaxStar]:GetDlgChild( "star"..i ):EnableWnd( i <= nCurHaveStar );
		end
		self.m_tblStar[nCurMaxStar]:ShowWnd( true );
		self.m_tickLSStars:Start( 100 );
	end
end

function CWndNewLadderSeason:OnShowLSStarsTick()
	local nTickCount = self.m_tickLSStars:GetTickCount();
	local nCurMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nLastSeasonStarInherit );
	local WndStar = self.m_tblStar[nCurMaxStar]:GetDlgChild( "star"..nTickCount );
	if WndStar then
		WndStar:ShowWnd( true );
	end
	if nTickCount >= nCurMaxStar then
		self.m_tickLSStars:Stop();
		self.m_pBtnContinue:ShowWnd( true );
	end
end

function CWndNewLadderSeason:OnShowLSChuanShuoStarTick()
	local nMaxStar = CStarLevelConfig:Inst():GetMaxStar();	
	self.m_tblStar[1]:GetDlgChild( "shuzi" ):SetWndText( self.m_nLastSeasonStarInherit - nMaxStar );
	self.m_tickLSChuanShuoStar:Stop();
	self.m_pBtnContinue:ShowWnd( true );
end

function CWndNewLadderSeason:OnClickContinue()
	self.m_pWndPrizeItem:ShowItem();
end

function CWndNewLadderSeason:StartInherit()
	print( "CWndNewLadderSeason:StartInherit()" );
	self:ShowInheritStep1();
end

function CWndNewLadderSeason:ShowInheritStep1()
	print( "CWndNewLadderSeason:ShowInheritStep1()" );
	self.m_tickInheritStep1:Start( nIntervalInheritStep1 );
	self.m_pBtnContinue:ShowWnd( true );
	self.m_pWndTitle:ShowWnd( true );
end

function CWndNewLadderSeason:OnInheritStep1Tick()
	local nTickCount = self.m_tickInheritStep1:GetTickCount();
	local nFade = 255 * ( 1 - nTickCount / nNumInheritStep1 );
	self.m_pBtnContinue:SetFade( nFade );
	self.m_pWndTitle:SetFade( nFade );
	if nTickCount >= nNumInheritStep1 then
		self.m_tickInheritStep1:Stop();
		self.m_pBtnContinue:ShowWnd( false );
		self.m_pBtnContinue:SetFade( 255 );
		self.m_pWndTitle:ShowWnd( false );
		self.m_pWndTitle:SetFade( 255 );
		self.m_pWndTitle:SetWndText( "" );
		self:ShowInheritStep2();
	end
end

function CWndNewLadderSeason:ShowInheritStep2()
	print( "CWndNewLadderSeason:ShowInheritStep2()" );
	self.m_pWndTextEffect:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep2", self );
	self.m_pWndTextEffect:AddEffect( "fx/cfg/duanwei02.eft", "fx/duanwei01", "readytoinherit", 0 );
end

function CWndNewLadderSeason:OnFinishInheritStep2()
	self.m_pWndTextEffect:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep2", self );
	self:ShowInheritStep3();
end

function CWndNewLadderSeason:ShowInheritStep3()
	print( "CWndNewLadderSeason:ShowInheritStep3()" );
	self.m_tickInheritStep3:Start( nIntervalInheritStep3 );
	self.m_pWndLadderName:ShowWnd( true );
	for i = 1, 5 do
		self.m_tblStar[i]:ShowWnd( false );
	end
	self.m_pWndLSStar:ShowWnd( true );
end

function CWndNewLadderSeason:OnInheritStep3Tick()
	local nTickCount = self.m_tickInheritStep3:GetTickCount();
	local nFade = 255 * ( 1 - nTickCount / nNumInheritStep3 );
	self.m_pWndLadderName:SetFade( nFade );
	self.m_pWndLSStar:SetFade( nFade );
	if nTickCount >= nNumInheritStep3 then
		self.m_tickInheritStep3:Stop();
		self.m_pWndLadderName:ShowWnd( false );
		self.m_pWndLadderName:SetFade( 255 );
		self.m_pWndLadderName:SetWndText( "" );
		self.m_pWndLSStar:ShowWnd( false );
		self.m_pWndLSStar:SetFade( 255 );
		self:ShowInheritStep4();
	end
end

function CWndNewLadderSeason:ShowInheritStep4()
	print( "CWndNewLadderSeason:ShowInheritStep4()" );
	self.m_pWndTextEffect:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep4", self );
	self.m_pWndTextEffect:AddEffect( "fx/cfg/duanwei01.eft", "fx/duanwei01", "startinherit", 0 );
end

function CWndNewLadderSeason:OnFinishInheritStep4()
	self.m_pWndTextEffect:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep4", self );
	self:ShowInheritStep5();
end

function CWndNewLadderSeason:ShowInheritStep5()
	print( "CWndNewLadderSeason:ShowInheritStep5()" );
	self.m_pWndTitle:SetWndText( g_App:GetString( "saijijiesuan2" ) );
	self.m_pWndTitle:SetFadeDuration( 1000 );
	self.m_pWndTitle:ShowWnd( true );
	self:ShowInheritStep6();
end

function CWndNewLadderSeason:ShowInheritStep6()
	print( "CWndNewLadderSeason:ShowInheritStep6()" );
	self.m_pWndLastSeason:ShowWnd( false );
	self.m_tickShowInheritStep6:Start( 5000 );
	self.m_pWndLSDis:AddEffect( self.m_pEffectLSLevel, "fx/cast", "LSDis", 0 );
	self.m_pWndCSAcc:AddEffect( self.m_pEffectCSLevel, "fx/end", "CSAcc", 0 );
	self.m_pWndEffectShine:AddEffect( "fx/cfg/duanweishenji_all.eft", "fx/duanweishenji_all", "inheritShine", 0 );
end

function CWndNewLadderSeason:OnFinishLSDis()
	self.m_pWndLSDis:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishLSDis", self );
end

function CWndNewLadderSeason:OnShowInheritStep6Tick()
	self.m_tickShowInheritStep6:Stop();
	self.m_pWndCSAcc:AddEffect( self.m_pEffectCSLevel, "fx/loop", "CurSeasonLoop", -1 );
	local dName = CStarLevelConfig:Inst():GetName( self.m_nCurSeasonStarInherit );
	self.m_pWndLadderName:SetWndText( dName );
	self.m_pWndLadderName:ShowWnd( true );
	self.m_tickShowInheritStep7:Start( nTimeShowInheritStep7 );
end

function CWndNewLadderSeason:OnShowInheritStep7Tick()
	self.m_tickShowInheritStep7:Stop();
	self:ShowInheritStep7();
end

function CWndNewLadderSeason:ShowInheritStep7()
	print( "CWndNewLadderSeason:ShowInheritStep7()" );
	for i = 1, 5 do
		self.m_tblStar[i]:ShowWnd( false );
	end
	self.m_pWndCSStar:ShowWnd( true );
	if self.m_nCurSeasonStarInherit >= self.m_nMaxStar then
		self.m_pWndCSStar:GetDlgChild( "star1" ):EnableWnd( true );
	else
		for i = 1, 5 do
			local WndStar = self.m_pWndCSStar:GetDlgChild( "star"..i );
			if WndStar then
				WndStar:EnableWnd( false );
			end
		end
	end
	self:ShowInheritStep8();
end

function CWndNewLadderSeason:ShowInheritStep8()
	print( "CWndNewLadderSeason:ShowInheritStep8()" );
	self.m_tickInheritStep8:Start( nIntervalInheritStep8 );
end

function CWndNewLadderSeason:OnInheritStep8Tick()
	local nTickCount = self.m_tickInheritStep8:GetTickCount();
	if nTickCount <= self.m_nCSHaveStar then
		self.m_pWndCSStar:GetDlgChild( "star"..nTickCount ):EnableWnd( true );
		self.m_pWndCSStar:GetDlgChild( "star"..nTickCount ):AddEffect( "fx/cfg/duanwei_start01.eft", "fx/duanwei_start01", "star", 0 );
	end
	if nTickCount >= self.m_nCSHaveStar or self.m_nCurSeasonStarInherit >= self.m_nMaxStar then
		self.m_tickInheritStep8:Stop();
		if self.m_pWndCSStar:GetDlgChild( "shuzi" ) then
			self.m_pWndCSStar:GetDlgChild( "star1" ):AddEffect( "fx/cfg/duanwei_start01.eft", "fx/duanwei_start01", "star", 0 );
			self.m_pWndCSStar:GetDlgChild( "shuzi" ):SetWndText( self.m_nCSHaveStar );
		end
		self:ShowInheritStep9();
	end
end

function CWndNewLadderSeason:ShowInheritStep9()
	print( "CWndNewLadderSeason:ShowInheritStep9()" );
	self.m_tickInheritStep9:Start( nIntervalInheritStep9 );
end

function CWndNewLadderSeason:OnInheritStep9Tick()
	local nTickCount = self.m_tickInheritStep9:GetTickCount();
	local nFade = 255 * ( 1 - nTickCount / nNumInheritStep9 );
	self.m_pWndTitle:SetFade( nFade );
	if nTickCount >= nNumInheritStep9 then
		self.m_tickInheritStep9:Stop();
		self.m_pWndTitle:ShowWnd( false );
		self.m_pWndTitle:SetWndText( "" );
		self.m_pWndTitle:SetFade( 255 );
		self:ShowInheritStep10();
	end	
end

function CWndNewLadderSeason:ShowInheritStep10()
	print( "CWndNewLadderSeason:ShowInheritStep10()" );	
	self.m_pWndTextEffect:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep10", self );
	self.m_pWndTextEffect:AddEffect( "fx/cfg/duanwei03.eft", "fx/duanwei01", "readytoinherit", 0 );
end

function CWndNewLadderSeason:OnFinishInheritStep10()
	self.m_pWndTextEffect:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnFinishInheritStep10", self );
	self:ShowInheritStep11();
end

function CWndNewLadderSeason:ShowInheritStep11()
	print( "CWndNewLadderSeason:ShowInheritStep11()" );
	self.m_pWndTitle:SetWndText( g_App:GetString( "saijijiesuan1" ) );
	self.m_pWndTitle:SetFadeDuration( 1000 );
	self.m_pWndTitle:ShowWnd( true );
	self.m_pBtnClose:ShowWnd( true );
end

---------------------------------CWndLadderPrizeItem---------------------------------
function CWndLadderPrizeItem:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CWndLadderPrizeItem:OnCreated()
	self.m_pWndIcon = CRichIconWnd:new( self, "tietu" );
	self.m_pWndNum = self:GetDlgChild( "shuliang" );
	self.m_pBtnConfirm = self:GetDlgChild( "btn_jixu" );
	self.m_pBtnConfirm:AddActionListener( "OnClickConfirm", self );
end

function CWndLadderPrizeItem:OnClickConfirm()
	local nLeftPrizeNum = self:ShowItem();
	if nLeftPrizeNum == 0 then
		self:GetParent():StartInherit();
	end
end

function CWndLadderPrizeItem:SetPrizeList( tblPrize )
	self.m_tblPrize = tblPrize;
end

function CWndLadderPrizeItem:ShowItem()
	local nPrizeNum = #self.m_tblPrize;
	if nPrizeNum > 0 then
		self:ShowWnd( true );
		local prizeInfo = self.m_tblPrize[1];
		local nType = CRewardConfig:Inst():GetType( tonumber( prizeInfo ) );
		local nItemID = CRewardConfig:Inst():GetItemID( tonumber( prizeInfo ) );
		local nCount = CRewardConfig:Inst():GetCount( tonumber( prizeInfo ) );
		local szName = CRewardConfig:Inst():GetName( tonumber( prizeInfo ) );
		self.m_pWndNum:SetWndText( nCount );

		if nType == eGRT_Resource then
			self.m_pWndIcon:SetIconID( g_tblTabFile.currency[nItemID].nIconID );
		elseif nType == eGRT_Equip then
			self.m_pWndIcon:SetIconID( g_tblTabFile.equip[nItemID].nIconID );
		end
		table.remove( self.m_tblPrize, 1 );
	else
		self:ShowWnd( false );
	end
	return nPrizeNum;
end
--endregion
