--region CWndLadder.lua
--Date	2017.8.31
--此文件由[BabeLua]插件自动生成

local EFFECT_TIME = 1000;		--特效总播放时间
local EFFECT_TICK = 50;			--特效50毫秒执行一次
local EFFECT_NUM = EFFECT_TIME / EFFECT_TICK;
local szEffectFile = nil;
local szEffectFetch = nil;
local szEffectname = nil;
local szIconEffFile = nil;

function CWndLadder:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType  );

	self.m_tblLevelEff = {			--name指段位名称，num指小段
		{ name = "qingtong",	num = 0 },
		{ name = "baiyin",		num = 0 },
		{ name = "huangjin",	num = 2 },
		{ name = "huangjin",	num = 1 },
		{ name = "baijin",		num = 2 },
		{ name = "baijin",		num = 1 },
		{ name = "zuanshi",		num = 3 },
		{ name = "zuanshi",		num = 2 },
		{ name = "zuanshi",		num = 1 },
		{ name = "dashi",		num = 3 },
		{ name = "dashi",		num = 2 },
		{ name = "dashi",		num = 1 },
		{ name = "wangzhe",		num = 3 },
		{ name = "wangzhe",		num = 2 },
		{ name = "wangzhe",		num = 1 },
		{ name = "chuanshuo",	num = 0 },
	};
	self.m_tickEffectOccur = CTick:new( "MakeIconBigger", self, nil, EFFECT_NUM );
	self.m_tickEffectDownToZero = CTick:new( "OnChuanShuoDownToZeroTick", self, nil, 1 );
	self.m_tickNumFadeOut = CTick:new( "NumFadeOut", self, nil, EFFECT_NUM );
	self.m_tickNumFadeIn = CTick:new( "NumFadeIn", self, nil, EFFECT_NUM );
end

function CWndLadder:OnCreated()
	self.m_tblEffect = {};
	self.m_btnContinue = self:GetDlgChild( "btn_jixu" );
	self.m_btnContinue:AddActionListener( "OnClose", self );
	self.m_wndEffect = self:GetDlgChild( "texiao" );
	self.m_wndStarAdd = self:GetDlgChild( "star1" );
	self.m_wndStarDel = self:GetDlgChild( "star2" );
	self.m_wndWinBG = self:GetDlgChild( "bg2" );
	self.m_wndLoseBG = self:GetDlgChild( "bg1" );
	self.m_wndStarUpState = self:GetDlgChild( "bg_up" );
	self.m_wndStarDownSate = self:GetDlgChild( "bg_down" );
	self.m_wndTitleUp = self:GetDlgChild( "bg_title" );
	self.m_wndTitleDown = self:GetDlgChild( "bg_title2" );
end

function CWndLadder:OnClose()
	if self.m_tickEffect then
		self.m_tickEffect:Stop();
	end
	self:ShowWnd( false );
	local nRoomType = g_App:GetScene():GetRoomType();
	local wndModeOpenReward = g_App:GetScene():GetWanfa().m_pWndModeOpenReward;
	wndModeOpenReward:ShowWndByRoomType( nRoomType );
end

function CWndLadder:OnWndShow( bShow )
	if bShow then
		self:InitOriStar();
		self:InitCurStar();
		self:ShowLadder();
		self:ShowStar();
		self:ShowMessage();
		self:ShowOtherWnds();
	end
end

function CWndLadder:InitSettlementData( nSettlementType, nOldStar, nNewestStar, nTeamRank )
	self.m_nSettlementType = nSettlementType;
	self.m_nOriStar = nOldStar;
	self.m_nNewestStar = nNewestStar;
	self.m_nTeamRank = nTeamRank;
end

function CWndLadder:ShowStar()
	self.m_wndStarAdd:GetDlgChild( "add" ):SetWndText( "+1" ); 
	self.m_wndStarDel:GetDlgChild( "jian" ):SetWndText( self.m_nChange == 0 and "+0" or "-1" );
	self.m_wndStarAdd:ShowWnd( self.m_nChange > 0 );
	self.m_wndStarDel:ShowWnd( self.m_nChange <= 0 );
end

function CWndLadder:ShowLadder()		--先显示初始段位，特效播放完即显示或取消star
	self:ShowOriLadder();
	
--	if self.m_nCurAllStar < self.m_nMaxStar then
		self:PrepareEffect();
		self:StartPlayEffect();
--	else											--传说显示特效
--		self.m_wndOriLadder:ShowWnd( false );
--		self.m_wndCurLadder:ShowWnd( true );
--		if self.m_nCurAllStar >	self.m_nMaxStar then
--			if self.m_nChange > 0 then
--				szEffectFile = "fx/cfg/dw_xx_cast.eft";		--加星特效
--				szEffectFetch = "fx/cast";
--				szEffectname = "jiaxing";
--			elseif self.m_nChange < 0 then
--				szEffectFile = "fx/cfg/dw_xx_end.eft";		--减星特效
--				szEffectFetch = "fx/end";
--				szEffectname = "jianxing";
--			end
--			self.m_wndCurLadder:GetDlgChild( "w_xingshu" ):AddEffect( "fx/cfg/dws_shuzi.eft", "fx/loop", "chuanshuonum", 0 );
--			self.m_wndCurLadder:GetDlgChild( "star1" ):AddEffect( szEffectFile, szEffectFetch, szEffectname, 0 );
--		end
--		self.m_wndCurLadder:GetDlgChild( "star1" ):EnableWnd( self.m_nCurAllStar > self.m_nMaxStar );
--		self.m_wndCurLadder:GetDlgChild( "w_xingshu" ):SetWndText( "x"..( self.m_nCurAllStar - self.m_nMaxStar ) );
--	end
end

function CWndLadder:PrepareEffect()
	if self.m_nChange == 0 then
		return;
	elseif self.m_nChange > 0 then
		szEffectFile = "fx/cfg/dw_xx_cast.eft";		--加星特效
		szEffectFetch = "fx/cast";
		szEffectname = "jiaxing";
		szIconEffFile = "fx/cfg/dws_";				--升段特效
	elseif self.m_nChange < 0 then
		szEffectFile = "fx/cfg/dw_xx_end.eft";		--减星特效
		szEffectFetch = "fx/end";
		szEffectname = "jianxing";
		szIconEffFile = "fx/cfg/dwj_";				--降段特效
	end

	self.m_tblEffectStar = {};
	self.m_nIndex = 1;

	local bLevelChanged = false;		--已经播放升段或降段特效
	local WndLadder = self.m_wndOriLadder;
	local nCurStar = 1;
	local bDownToZero = false;
	for i = 1, math.abs( self.m_nChange ) do
		if self.m_nOriLevelHaveStar + i * self.m_nChange / math.abs( self.m_nChange ) > self.m_nOriLevelMaxStar
		and not bLevelChanged and self.m_nChange > 0 and self.m_nOriStar < self.m_nMaxStar then						--升段
			local tblOriDis = {};								--①旧的段位icon消失
			tblOriDis.wndEffect = WndLadder:GetDlgChild( "tx" );
			tblOriDis.szEffectFile = "fx/cfg/dwj_"..self.m_tblLevelEff[self.m_nOriLevel].name..".eft";
			tblOriDis.szEffectName = "fx/loop";
			tblOriDis.szEffectAttach = "OldIconDis";
			table.insert( self.m_tblEffect, tblOriDis );
			
			WndLadder = self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 ) );
			local tblNewOccur = {};									--②新的段位icon降落出现
			tblNewOccur.wndEffect = WndLadder:GetDlgChild( "tx" );
			tblNewOccur.szEffectFile = "fx/cfg/dws_"..self.m_tblLevelEff[self.m_nCurLadderLevel].name..".eft";
			tblNewOccur.szEffectName = "fx/loop";
			tblNewOccur.szEffectAttach = "NewIconOccur";
			table.insert( self.m_tblEffect, tblNewOccur );
			
			if self.m_nCurLadderLevel > self.m_nOriLevel then
				local tblLightOnce = {};								--③播放光特效
				tblLightOnce.wndEffect = WndLadder:GetDlgChild( "tx" );
				tblLightOnce.szEffectFile = "fx/cfg/dw_guang.eft";
				tblLightOnce.szEffectName = "fx/loop";
				tblLightOnce.szEffectAttach = "LightOnce";
				table.insert( self.m_tblEffect, tblLightOnce );
			end
			
			if self.m_tblLevelEff[self.m_nCurLadderLevel].num > 0 then		--④播放罗马数字特效
				local tblIconNum = {};
				tblIconNum.wndEffect = WndLadder:GetDlgChild( "shuzi" );
				tblIconNum.szEffectFile = "fx/cfg/dws_"..self.m_tblLevelEff[self.m_nCurLadderLevel].num..".eft";
				tblIconNum.szEffectName = "fx/loop";
				tblIconNum.szEffectAttach = "IconNumUp";
				table.insert( self.m_tblEffect, tblIconNum );
			end
			
			for ii = 1, self.m_nCurLevelMaxStar do
				local WndStar = WndLadder:GetDlgChild( "star"..ii );
				if WndStar then
					WndStar:EnableWnd( false );
				end
			end

			if self.m_nNewestStar >= self.m_nMaxStar then
				WndLadder:GetDlgChild( "star1" ):EnableWnd( true );
--				local char = 0;
--				local paramTab = CFontConfig:Inst():GetFontRect( string.byte( char ), 0xfefbea );
--				local rtWndNum = CFRect:new( paramTab:left(), paramTab:top(), paramTab:right(), paramTab:bottom() );
--				local fNumWidth = WndLadder:GetDlgChild( "w_xingshu.shuzi1" ):GetWndWidth();
--				local rtWndPosAndSize = CFRect:new( 0, 0, fNumWidth, WndLadder:GetDlgChild( "w_xingshu.shuzi1" ):GetWndHeight() );
--				WndLadder:GetDlgChild( "w_xingshu.shuzi1" ):AddImage( GSM_BS_BK, eST_ENABLE, 0, "fx/tex/wenzi.tex", rtWndNum, rtWndPosAndSize, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );
			end

			local WndNum = WndLadder:GetDlgChild( "w_xingshu" );
			if WndNum then
				WndNum:SetWndText( "" );
			end
			nCurStar = 1;
			bLevelChanged = true;
		elseif self.m_nOriLevelHaveStar + i * self.m_nChange / math.abs( self.m_nChange ) < 0 
		and not bLevelChanged and self.m_nChange < 0 and self.m_nNewestStar < self.m_nMaxStar then						--降段
			
			local tblOriDel = {};											--①播放旧段位收缩特效
			tblOriDel.wndEffect = WndLadder:GetDlgChild( "tx" );
			tblOriDel.szEffectFile = "fx/cfg/dwj_"..self.m_tblLevelEff[self.m_nOriLevel].name..".eft";
			tblOriDel.szEffectName = "fx/loop";
			tblOriDel.szEffectAttach = "OldIconDel";
			table.insert( self.m_tblEffect, tblOriDel );
			
			if self.m_nOriStar >= self.m_nMaxStar then
				WndLadder:GetDlgChild( "star1" ):EnableWnd( true );
				local char = 0;
				local paramTab = CFontConfig:Inst():GetFontRect( string.byte( char ), 0xfefbea );
				local rtWndNum = CFRect:new( paramTab:left(), paramTab:top(), paramTab:right(), paramTab:bottom() );
				local fNumWidth = WndLadder:GetDlgChild( "w_xingshu.shuzi1" ):GetWndWidth();
				local rtWndPosAndSize = CFRect:new( 0, 0, fNumWidth, WndLadder:GetDlgChild( "w_xingshu.shuzi1" ):GetWndHeight() );
				WndLadder:GetDlgChild( "w_xingshu.shuzi1" ):AddImage( GSM_BS_BK, eST_ENABLE, 0, "fx/tex/wenzi.tex", rtWndNum, rtWndPosAndSize, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );
			end

			WndLadder = self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 ) );
			local tblCurBigger = {};										--②手动实现新段位放大特效
			tblCurBigger.wndEffect = WndLadder:GetDlgChild( "icon" );
			tblCurBigger.szEffectFile = "";
			tblCurBigger.szEffectName = "";
			tblCurBigger.szEffectAttach = "CurIconBigger";
			table.insert( self.m_tblEffect, tblCurBigger );

			if self.m_tblLevelEff[self.m_nCurLadderLevel].num > 0 then		--③播放罗马数字特效
				local tblIconNum = {};
				tblIconNum.wndEffect = WndLadder:GetDlgChild( "shuzi" );
				tblIconNum.szEffectFile = "fx/cfg/dws_"..self.m_tblLevelEff[self.m_nCurLadderLevel].num..".eft";
				tblIconNum.szEffectName = "fx/loop";
				tblIconNum.szEffectAttach = "IconNumDown";
				table.insert( self.m_tblEffect, tblIconNum );
			end
			
			for ii = 1, self.m_nCurLevelMaxStar do
				local WndStar = WndLadder:GetDlgChild( "star"..ii );
				if WndStar then
					WndStar:EnableWnd( true );
				end
			end

			nCurStar = self.m_nCurLevelMaxStar + 1;
			bLevelChanged = true;
		else											--升星或降星
			if not bLevelChanged then
				nCurStar = self.m_nOriLevelHaveStar + i * self.m_nChange / math.abs( self.m_nChange );
				if self.m_nChange < 0 then
					nCurStar = nCurStar + 1;
				end
			elseif bLevelChanged and self.m_nChange < 0 then
				nCurStar = nCurStar - 1;
			end

			if self.m_nNewestStar > self.m_nMaxStar and self.m_nChange > 0 then
				self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".star1" ):EnableWnd( true );
				local sNum = tostring( self.m_nCurLevelHaveStar );
				local tblCHuanShuoUp = {};				
				tblCHuanShuoUp.szEffectFile = "fx/cfg/dw_shuzi.eft";
				tblCHuanShuoUp.wndEffect = WndLadder:GetDlgChild( "w_xingshu" );
				tblCHuanShuoUp.szEffectName = "fx/loop_";
				tblCHuanShuoUp.szEffectAttach = "ChuanShuoUp"; 
				tblCHuanShuoUp.cStarNum = sNum;
				table.insert( self.m_tblEffect, tblCHuanShuoUp );				
				return;
			elseif self.m_nChange < 0 and self.m_nNewestStar >= self.m_nMaxStar then
				self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".star1" ):EnableWnd( true );
				local tblCHuanShuoDown = {};
				tblCHuanShuoDown.wndEffect = WndLadder:GetDlgChild( "w_xingshu" );
				tblCHuanShuoDown.szEffectFile = "";
				tblCHuanShuoDown.szEffectName = "";
				tblCHuanShuoDown.szEffectAttach = "ChuanShuoDown";
				tblCHuanShuoDown.nStarNum = self.m_nCurLevelHaveStar;
				table.insert( self.m_tblEffect, tblCHuanShuoDown );
				return;
			elseif self.m_nChange < 0 and self.m_nOriStar > self.m_nMaxStar and self.m_nNewestStar < self.m_nMaxStar then	--由传说降段
				self:GetDlgChild( tostring( self.m_nOriLevel - 1 )..".star1" ):EnableWnd( true );		--即传说.star1
				if not bDownToZero then
					local tblCHuanShuoDown = {};
					tblCHuanShuoDown.wndEffect = WndLadder:GetDlgChild( "w_xingshu" );
					tblCHuanShuoDown.szEffectFile = "";
					tblCHuanShuoDown.szEffectName = "";
					tblCHuanShuoDown.szEffectAttach = "ChuanShuoDownToZero";
					tblCHuanShuoDown.nStarNum = self.m_nOriLevelHaveStar;
					bDownToZero = true;
					table.insert( self.m_tblEffect, tblCHuanShuoDown );
				end
			else
				local tblTemp = {};
				tblTemp.wndEffect = WndLadder:GetDlgChild( "star"..nCurStar );
				tblTemp.szEffectFile = szEffectFile;
				tblTemp.szEffectName = szEffectFetch;
				tblTemp.szEffectAttach = szEffectname;
				table.insert( self.m_tblEffect, tblTemp );
			end
		end
	end
end

function CWndLadder:ShowOriLadder()
	self.m_wndOriLadder:ShowWnd( true );
	for i = 1, self.m_nOriLevelMaxStar do
		local WndStar = self.m_wndOriLadder:GetDlgChild( "star"..i );
		if WndStar then
			WndStar:EnableWnd( i <= self.m_nOriLevelHaveStar );
		end
	end
	if self.m_nChange == 0 and self.m_nNewestStar >= self.m_nMaxStar then
		self.m_wndOriLadder:GetDlgChild( "star1" ):EnableWnd( self.m_nOriLevelHaveStar >= 1 );
		local sNum = tostring( self.m_nCurLevelHaveStar );
		for ii = 1, sNum:len() do
			local tblCHuanShuoUp = {};				
			local char = sNum:sub( ii, ii );
			table.insert( self.m_tblEffect, tblCHuanShuoUp );
			self.m_wndOriLadder:GetDlgChild( "w_xingshu.shuzi"..ii ):AddEffect( "fx/cfg/dw_shuzi.eft", "fx/loop_"..char, "ChuanShuoZero"..ii, -1 );
		end
	end
end

function CWndLadder:InitOriStar()
	self.m_nOriLevel = CStarLevelConfig:Inst():GetLevel( self.m_nOriStar );
	self.m_nOriLevelHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_nOriStar );
	self.m_nOriLevelMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nOriStar );
	self.m_wndOriLadder = self:GetDlgChild( tostring( self.m_nOriLevel - 1 ) );
	for i = eLL_Bronze, eLL_Legend do
		self:GetDlgChild( tostring( i ) ):ShowWnd( false );
	end
	print( "----------- CWndLadder:InitOriStar() ---------", self.m_nOriStar, self.m_nOriLevel );
end

function CWndLadder:InitCurStar()
	self.m_nCurLadderLevel = CStarLevelConfig:Inst():GetLevel( self.m_nNewestStar );
	self.m_nCurLevelHaveStar = CStarLevelConfig:Inst():HaveStarOnLevel( self.m_nNewestStar );
	self.m_nCurLevelMaxStar = CStarLevelConfig:Inst():GetStarOnLevel( self.m_nNewestStar );
	self.m_wndCurLadder = self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 ) );
	self.m_nChange = self.m_nNewestStar - self.m_nOriStar;
	self.m_nMaxStar = CStarLevelConfig:Inst():GetMaxStar();
	print( "----------- CWndLadder:InitCurStar() ---------", self.m_nNewestStar, self.m_nCurLadderLevel, self.m_nCurLevelHaveStar );
end

function CWndLadder:StartPlayEffect()
	if #self.m_tblEffect <= 0 then
		return;
	end
	local Wnd = self.m_tblEffect[1];
	table.remove( self.m_tblEffect, 1 );

	
	if Wnd.szEffectAttach == "OldIconDis" or Wnd.szEffectAttach == "OldIconDel" then
		self.m_wndOriLadder:GetDlgChild( "icon" ):ShowWnd( false );
	end

	if Wnd.szEffectAttach == "NewIconOccur" then 
		self.m_wndOriLadder:ShowWnd( false );
	elseif Wnd.szEffectAttach == "CurIconBigger" then		--程序手动控制显示特效，完成该特效后继续播放其他特效
		self.m_wndOriLadder:ShowWnd( false );
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 ) ):ShowWnd( true );
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):ShowWnd( false );
		self.m_tickEffectOccur:Start( EFFECT_TICK );
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):SetScaleX( 0.01 );
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):SetScaleY( 0.01 );
	elseif Wnd.szEffectAttach == "ChuanShuoUp" then
		Wnd.wndEffect:GetParent():GetDlgChild( "tx1" ):AddEffect( "fx/cfg/dw_guang.eft", "fx/loop", "Light", -1 );
		
		for ii = 1, Wnd.cStarNum:len() do
			local tblCHuanShuoUp = {};				
			tblCHuanShuoUp.szEffectFile = "fx/cfg/dw_shuzi.eft";
			local char = Wnd.cStarNum:sub( ii, ii );
			table.insert( self.m_tblEffect, tblCHuanShuoUp );
			Wnd.wndEffect:GetDlgChild( "shuzi"..ii ):AddEffect( Wnd.szEffectFile, Wnd.szEffectName..char, Wnd.szEffectAttach..ii, -1 );
		end
	elseif Wnd.szEffectAttach == "ChuanShuoDown" then
		Wnd.nStarNum = self.m_nOriLevelHaveStar;
		self:ShowChuanShuoDown( Wnd );
	elseif Wnd.szEffectAttach == "ChuanShuoDownToZero" then
		local nEffectTime = 1000;
		local pEffectFrontWnd = CFontEffectWnd:new();
		Wnd.wndEffect:GetParent():AssignDlgChildToWnd( pEffectFrontWnd, "w_xingshu" );
		pEffectFrontWnd:SetEffectText( "fx/cfg/dw_shuzi.eft", tostring( Wnd.nStarNum ), 0xbf18f8, nEffectTime );
		self.m_tickEffectDownToZero:Start( nEffectTime );
	end
	if Wnd.szEffectAttach ~= "CurIconBigger" and Wnd.szEffectAttach ~= "ChuanShuoUp" then
		if Wnd.wndEffect then
			Wnd.wndEffect:AddEventListener( GM_WM_FX_PLAYCOMPLETE, "OnEffectPlayComplete", self );
			Wnd.wndEffect:AddEffect( Wnd.szEffectFile, Wnd.szEffectName, Wnd.szEffectAttach, 0, false, false, true );
		end
	end
		
	if Wnd.szEffectAttach == "jiaxing" then
		Wnd.wndEffect:EnableWnd( true );
	elseif Wnd.szEffectAttach == "jianxing" then
		Wnd.wndEffect:EnableWnd( false );
	elseif Wnd.szEffectAttach == "NewIconOccur" then
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 ) ):ShowWnd( true );
	end

	--判断是否是光特效，是的话则一直播放
	if Wnd.szEffectAttach == "LightOnce" then
		Wnd.wndEffect:GetParent():GetDlgChild( "tx1" ):AddEffect( Wnd.szEffectFile, Wnd.szEffectName, Wnd.szEffectAttach, -1 );
	end
end

function CWndLadder:OnChuanShuoEffectPlayComplete( event )
	event.m_Target:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnChuanShuoEffectPlayComplete", self );	
	local Wnd = event.m_Target:GetUserObject();
	local char = Wnd.cStarNum;
    local paramTab = CFontConfig:Inst():GetFontRect( string.byte( char ), 0xfefbea );
    local rtWndNum = CFRect:new( paramTab:left(), paramTab:top(), paramTab:right(), paramTab:bottom() );
    local fNumWidth = Wnd.wndEffect:GetWndWidth();
    local rtWndPosAndSize = CFRect:new( 0, 0, fNumWidth, Wnd.wndEffect:GetWndHeight() );
    Wnd.wndEffect:AddImage( GSM_BS_BK, eST_ENABLE, 0, "fx/tex/wenzi.tex", rtWndNum, rtWndPosAndSize, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );	
	self:StartPlayEffect();
end

function CWndLadder:OnChuanShuoDownToZeroTick()
	self:StartPlayEffect();
	self.m_tickEffectDownToZero:Stop();
end

function CWndLadder:OnEffectPlayComplete( event )
	event.m_Target:RemoveEventListener( GM_WM_FX_PLAYCOMPLETE, "OnEffectPlayComplete", self );	
	self:StartPlayEffect();
end

function CWndLadder:ShowMessage()	
	local Scene = g_App:GetScene();
	local Wanfa = Scene:GetWanfa();
	local nRoomType = Scene:GetRoomType();
	local szLadderName = CStarLevelConfig:Inst():GetName( self.m_nNewestStar );
	local nRank = self.m_nTeamRank;
	local DicStr = "";
	if self.m_nSettlementType ~= eSettlementType_RemainEnd and nRank ~= 1 then
		DicStr = nRoomType == eRT_LimitTime and "tianti_xianshijiesuang3" or "tianti_tuantuijiesuang3";
	end
	if self.m_nChange == 0 then
		DicStr = nRoomType == eRT_LimitTime and "tianti_xianshijiesuang" or "tianti_tuantuijiesuang";
	else
		DicStr = nRoomType == eRT_LimitTime and "tianti_xianshijiesuang2" or "tianti_tuantuijiesuang2";
	end
	print( "CWndLadder:ShowMessage()	", DicStr, self.m_nSettlementType, nRank, self.m_nChange );
	local str = CStringConfig:Inst():GetString( DicStr )	
	if self.m_nChange == 0 then
		str = string.format( str, szLadderName, nRank );
	else
		str = string.format( str, szLadderName, nRank, self.m_nChange > 0 and "+1" or "-1" );
	end
	if self.m_nSettlementType ~= eSettlementType_RemainEnd and nRank ~= 1 then
		local szNum = self.m_nChange > 0 and "+1" or "-1";
		szNum = self.m_nChange == 0 and "+0" or szName;
		str = string.format( str, szLadderName, nRank, szNum );
	end
	self:GetDlgChild( "shuoming" ):SetWndText( str );	
end

function CWndLadder:ShowOtherWnds()	
	self.m_wndWinBG:ShowWnd( self.m_nChange >= 0 );
	self.m_wndLoseBG:ShowWnd( self.m_nChange < 0 );
	self.m_wndStarUpState:ShowWnd( self.m_nCurLadderLevel > self.m_nOriLevel );
	self.m_wndStarDownSate:ShowWnd( self.m_nCurLadderLevel < self.m_nOriLevel );
	self.m_wndTitleUp:ShowWnd( self.m_nChange >= 0 );
	self.m_wndTitleDown:ShowWnd( self.m_nChange < 0 );
end

function CWndLadder:MakeIconBigger()
	local fScaleX = self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):GetScaleX();
	self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):SetScaleX( fScaleX + ( 1 - 0.01 ) / EFFECT_NUM );
	local fScaleY = self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):GetScaleY();
	self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):SetScaleY( fScaleY + ( 1 - 0.01 ) / EFFECT_NUM );
	self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):ShowWnd( true );
	--print( "CWndLadder:MakeIconBigger()", self.m_tickEffectOccur:GetTickCount() );
	if self.m_tickEffectOccur:GetTickCount() >= EFFECT_NUM then
		self.m_tickEffectOccur:Stop();
		self:StartPlayEffect();
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):SetScaleX( 1 );
		self:GetDlgChild( tostring( self.m_nCurLadderLevel - 1 )..".icon" ):SetScaleY( 1 );
	end
end

function CWndLadder:ShowChuanShuoDown( Wnd )
	local sNum = tostring( Wnd.nStarNum );
    local nNum = sNum:len();
    for i = 1, nNum  do
        local char = sNum:sub( i, i );
        local paramTab = CFontConfig:Inst():GetFontRect( string.byte( char ), 0xfefbea );
        local rtWndNum = CFRect:new( paramTab:left(), paramTab:top(), paramTab:right(), paramTab:bottom() );
        local fNumWidth = Wnd.wndEffect:GetDlgChild( "shuzi"..i ):GetWndWidth();
        local rtWndPosAndSize = CFRect:new( 0, 0, fNumWidth, Wnd.wndEffect:GetWndHeight() );
        Wnd.wndEffect:GetDlgChild( "shuzi"..i ):AddImage( GSM_BS_BK, eST_ENABLE, 0, "fx/tex/wenzi.tex", rtWndNum, rtWndPosAndSize, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );                       
    end

	self.m_tickNumFadeOut:SetContext( Wnd );
	self.m_tickNumFadeOut:Start( EFFECT_TICK );
end

function CWndLadder:NumFadeOut()
	local Wnd = self.m_tickNumFadeOut:GetContext();
	local sNum = tostring( Wnd.nStarNum );
	local nNum = sNum:len();
	for i = 1, nNum do
		Wnd.wndEffect:GetDlgChild( "shuzi"..i ):SetFade( 255 * ( 1 - self.m_tickNumFadeOut:GetTickCount() / self.m_tickNumFadeOut:GetRepeatCount() ) );
	end
	if self.m_tickNumFadeOut:GetTickCount() >= EFFECT_NUM then	
		if Wnd.nStarNum == 0 then	--由传说0星降段，直接播下个段位特效
			self:StartPlayEffect();
			return;
		end
		Wnd.nStarNum = self.m_nCurLevelHaveStar;
		if Wnd.szEffectAttach == "ChuanShuoDownToZero" then
			Wnd.nStarNum = 0;
		end
		local sNum = tostring( Wnd.nStarNum );
		local nNum = sNum:len();
		for i = 1, nNum  do
			Wnd.wndEffect:GetDlgChild( "shuzi"..i ):RestoreImageFromCreateParam();
			local char = sNum:sub( i, i );
			local paramTab = CFontConfig:Inst():GetFontRect( string.byte( char ), 0xfefbea );
			local rtWndNum = CFRect:new( paramTab:left(), paramTab:top(), paramTab:right(), paramTab:bottom() );
			local fNumWidth = Wnd.wndEffect:GetDlgChild( "shuzi"..i ):GetWndWidth();
			local rtWndPosAndSize = CFRect:new( 0, 0, fNumWidth, Wnd.wndEffect:GetWndHeight() );
			Wnd.wndEffect:GetDlgChild( "shuzi"..i ):AddImage( GSM_BS_BK, eST_ENABLE, 0, "fx/tex/wenzi.tex", rtWndNum, rtWndPosAndSize, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );                       
		end
		self.m_tickNumFadeOut:Stop();
		self.m_tickNumFadeIn:SetContext( Wnd );
		self.m_tickNumFadeIn:Start( EFFECT_TICK );
	end
end

function CWndLadder:NumFadeIn()
	local Wnd = self.m_tickNumFadeIn:GetContext();
	Wnd.wndEffect:SetFade( 255 * self.m_tickNumFadeOut:GetTickCount() / self.m_tickNumFadeOut:GetRepeatCount() );
	if self.m_tickNumFadeOut:GetTickCount() >= EFFECT_NUM then
		self.m_tickNumFadeIn:Stop();
		self:StartPlayEffect();
	end
end

function CWndLadder:ShowChuanShuoUp( Wnd )
	local sNum = tostring( Wnd.nStarNum );
    local nNum = sNum:len();
    for i = 1, nNum  do
        local char = sNum:sub( i, i );
        local paramTab = CFontConfig:Inst():GetFontRect( string.byte( char ), 0xfefbea );
        local rtWndNum = CFRect:new( paramTab:left(), paramTab:top(), paramTab:right(), paramTab:bottom() );
        local fNumWidth = Wnd.wndEffect:GetDlgChild( "shuzi"..i ):GetWndWidth();
        local rtWndPosAndSize = CFRect:new( fNumWidth * ( i - 1 ), 0, fNumWidth * i, Wnd.wndEffect:GetWndHeight() );
        Wnd.wndEffect:GetDlgChild( "shuzi"..i ):AddImage( GSM_BS_BK, eST_ENABLE, 0, "fx/tex/wenzi.tex", rtWndNum, rtWndPosAndSize, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );                       
    end
end
--endregion