--region CWndFusion.lua
--Date 2017.11.28
-- "fsj_pifu_hecheng" 
--碎片合成界面

local eStarAll = 6;
local eFragmentKindCount = 5;
function CWndFusion:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndFusion:OnCreated()
	self.m_BtnFusion			= self:GetDlgChild( "b_hecheng" );
	self.m_BtnClose				= self:GetDlgChild( "B_close" );
	self.m_BtnUsing				= self:GetDlgChild( "b_shiyong" );
	self.m_WndName				= self:GetDlgChild( "name" );
	self.m_tblIcon				= {};
	for i = 1, eFragmentKindCount do
		local tbl = {};
		tbl.m_icon = CRichIconWnd:new( self, "icon" .. i );
		tbl.m_count = self:GetDlgChild( "icon".. i .. ".shuliang" );
		tbl.m_WndDesc = CWndFragmentDesc:new( "gui/cfg/fsj_pifu_hecheng_cailiao.gui", self , 1 );
		self.m_tblIcon[i] = tbl;
		self.m_tblIcon[i].m_icon:AddEventListener( GM_WM_MOUSECLICK, "OnClickIcon", self );
	end
	
	self.m_Model				= self:GetDlgChild( "moxing" );
	self.m_TextPrice			= self:GetDlgChild( "b_hecheng.W_jiage" );
	self.m_tblStar			= {};
	for i = 1, eStarAll do
		self.m_tblStar[i]   = self:GetDlgChild( "star.star" .. i );	
	end
	self.m_BtnLeft				= self:GetDlgChild( "btn_zuo" );
	self.m_BtnRight				= self:GetDlgChild( "btn_you" );

	self.m_BtnFusion:AddActionListener( "OnFusion", self );
	self.m_BtnClose:AddActionListener( "OnClose", self );
	self.m_BtnLeft:AddActionListener( "OnLeft", self );
	self.m_BtnRight:AddActionListener( "OnRight", self );
	self.m_BtnUsing:AddActionListener( "OnUsing", self )
	self.m_Model:AddEventListener( GM_WM_MOUSECLICK, "OnClickModel", self );

	self.m_Listener = IAnimationListener:new();
	self.m_Listener.m_pWnd = self;
	self.m_Listener.OnAniPlayStart = function() end
	self.m_Listener.OnFrameString = function() end
	self.m_Listener.OnAniPlayEnd = function( this ) this.m_pWnd:OnAniPlayEnd(); end
	self.m_pRenderObject = g_App:CreateRenderObject();
	local pViewportRenderer = self.m_Model:GetViewportRenderer();
	pViewportRenderer:AddChild( self.m_pRenderObject );
	pViewportRenderer:EnableResetTimeOnShow( true );
	local Camera = pViewportRenderer:GetCamera();
	Camera:SetUp( CVector3f:new( 0, 1, 0 ) );
	Camera:SetPos( CVector3f:new( -40, 70, 60 ) );
	Camera:SetDest( CVector3f:new( 0, 25, 0 ) );
	self.m_LoadListener = IGammaResListener:new();
	self.m_LoadListener.m_pWnd = self;
	self.m_LoadListener.OnLoadedEnd = function( this ) this.m_pWnd:OnLoadedEnd(); end
	self.m_tickCheckAniLoad = CTick:new( "OnTickCheckLoad", self );
end

function CWndFusion:OnDestroy()
	g_App:DestroyRenderObject( self.m_pRenderObject );
	self.m_pRenderObject = nil;
	self.m_Listener = nil;
	self.m_tickCheckAniLoad:Stop();
	self.m_LoadListener = nil;
	CGWnd.OnDestroy( self );
end

function CWndFusion:OnUsing()
	self:ShowWnd( false );
	local NetMsg = CUsingSkin:new();
	NetMsg.nSkinID = self.m_nFusionID;
	g_App:SendShellMsg( NetMsg ); 
end

function CWndFusion:OnFusion()
	self:ShowWnd( false );
	local NetMsg = CFusion:new();
	NetMsg.m_nFusionID  = self.m_nFusionID;
	g_App:SendShellMsg( NetMsg );
end

function CWndFusion:OnClose()
	self:ShowWnd( false );
end

function CWndFusion:OnLeft()
	self.m_nFusionID = self.m_nFusionID - 1;
	if self.m_nFusionID < self.m_nFusionIDMin then
		self.m_nFusionID = self.m_nFusionIDMax;
	end
	self:ShowDetail();
end

function CWndFusion:OnRight()
	self.m_nFusionID = self.m_nFusionID + 1 ;
	if self.m_nFusionID > self.m_nFusionIDMax then
		self.m_nFusionID = self.m_nFusionIDMin;
	end
	self:ShowDetail();
end

function CWndFusion:OnClickModel()
	self:ShowEffectAndAni();
end

function CWndFusion:OnAniPlayEnd()
	self.m_pRenderObject:RemoveAnimationListener( self.m_Listener );
	self.m_pRenderObject:SetNodeAni( "stand", nil, SFramePair:new(), eAPT_Loop, 0, 0, 1.0, nil );
end

function CWndFusion:ShowEffectAndAni()
	self.m_pRenderObject:SetNodeAni( "stand_rest1", nil, SFramePair:new(), eAPT_Once, 0, 0, 1.0, self.m_Listener );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectAniShow, "fx/loop", nil, false, 0 );
	self.m_pRenderObject:AddFusionSkinEffect( self.m_szEffectAllTime, "fx/loop", "alltime", false, -1 );
end

function CWndFusion:OnClickIcon( Event )
	local wndDesc = Event.m_CurrentTarget.m_wndDesc;
	local nFragmentID = Event.m_CurrentTarget.m_nFragmentID;
	if wndDesc and nFragmentID then
		wndDesc:SetData( nFragmentID );
	end
end

function CWndFusion:SetData( nIndex )
	self.m_nIndex = nIndex;
	local tbl = {};
	for i = 1, g_tblTabFile.fusion.nRowCount do
		local nSort = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nSort" )
		local nID = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nID" )
		if nSort == nIndex then
			table.insert( tbl, nID );
		end
	end
	
	self.m_nFusionID = tbl[1];
	self.m_nFusionIDMin = self.m_nFusionID;
	self.m_nFusionIDMax = tbl[table.count( tbl )];
	self:ShowDetail();
end

function CWndFusion:SetPromotedata( nIDToFusion, nIndex )
	self.m_nIndex = nIndex;
	local tbl = {};
	for i = 1, g_tblTabFile.fusion.nRowCount do
		local nSort = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nSort" )
		local nID = CTableConfigMgr:Inst():GetConfigNumber( "fusion", i, "nID" )
		if nSort == nIndex then
			table.insert( tbl, nID );
		end
	end
	self.m_nFusionID = nIDToFusion;
	self.m_nFusionIDMin = tbl[1];
	self.m_nFusionIDMax = tbl[table.count( tbl )];
	self:ShowDetail();
end

function CWndFusion:ShowDetail()
	if self:IsHave() then
		self.m_BtnUsing:ShowWnd( true );
		self.m_BtnFusion:ShowWnd( false );
	else
		self.m_BtnUsing:ShowWnd( false  );
		self.m_BtnFusion:ShowWnd( true );
	end
	self.m_tblFragment = {};
	for i = 1, eFragmentKindCount do
		local Prop = {};
		Prop.m_nFragmentID = g_tblTabFile.fusion[self.m_nFusionID]["nFragment"..i];
		if Prop.m_nFragmentID == 0 then
			break;
		end
		Prop.m_nFragmentCountNeed = g_tblTabFile.fusion[self.m_nFusionID]["nCount"..i];
		Prop.m_nFragmentCountHave = g_App:GetFragmentCount( Prop.m_nFragmentID );
		table.insert( self.m_tblFragment, Prop );
	end
	self.m_nPrice = g_tblTabFile.fusion[self.m_nFusionID].nPayCount;
	self.m_nPayType = g_tblTabFile.fusion[self.m_nFusionID].nPayType;
	self.m_nPayIndex = g_tblTabFile.fusion[self.m_nFusionID].nPayIndex;
	self.m_szName = g_tblTabFile.fusion[self.m_nFusionID].dName;
	self.m_TextPrice:SetWndText( self.m_nPrice );
	self.m_WndName:SetWndText( self.m_szName );

	self.m_szEffectAllTime = g_tblTabFile.fusion[self.m_nFusionID].szEffectAllTime;
	self.m_szEffectAniShow = g_tblTabFile.fusion[self.m_nFusionID].szEffectAllAniShow;
	self.m_szEffectRest    = g_tblTabFile.fusion[self.m_nFusionID].szEffectRest;

	for i = 1, eFragmentKindCount do 
		if self.m_tblFragment[i] then
			local nIconID = g_tblTabFile.fragment[self.m_tblFragment[i].m_nFragmentID].nIconID;
			self.m_tblIcon[i].m_icon:SetIconID( nIconID );
			local str = "";
			if self.m_tblFragment[i].m_nFragmentCountNeed <= self.m_tblFragment[i].m_nFragmentCountHave then
				str = "#cff00ff00" .. self.m_tblFragment[i].m_nFragmentCountHave .."/".. self.m_tblFragment[i].m_nFragmentCountNeed;
			else
				str = "#cffa9793c" .. self.m_tblFragment[i].m_nFragmentCountHave .."/".. self.m_tblFragment[i].m_nFragmentCountNeed;
			end
			self.m_tblIcon[i].m_icon:ShowWnd( true );
			self.m_tblIcon[i].m_count:SetWndText( str );
			self.m_tblIcon[i].m_icon.m_nFragmentID =  self.m_tblFragment[i].m_nFragmentID ;	
			self.m_tblIcon[i].m_icon.m_wndDesc = self.m_tblIcon[i].m_WndDesc;
		else
			self.m_tblIcon[i].m_icon:ShowWnd( false );
		end
	end
	
	for i = 1, eStarAll do 
		self.m_tblStar[i]:EnableWnd( i<= self.m_nFusionID%10 );
	end

	self.m_pRenderObject:OnEquipUpdated( self.m_nFusionID, 0, true, false );
	self:ShowWnd( true );
	self.m_AniGroup = self.m_pRenderObject:GetAnimateGroup();
	if self.m_AniGroup:IsAniLoaded( "stand" ) and self.m_AniGroup:IsAniLoaded( "stand_rest1" ) then
		self:ShowEffectAndAni();
	else
		self.m_AniGroup:AddLoadListener( self.m_LoadListener );
	end
end

function CWndFusion:IsHave()
	local PlayerData = g_App:GetMainPlayerData().m_HaveEquip;
	for i = 1, PlayerData:GetDataCount() do
		if PlayerData:GetData( i - 1 ) == self.m_nFusionID then
			return true;
		end
	end
	return false;
end

function CWndFusion:OnLoadedEnd()
	self.m_AniGroup:CheckAndLoadAni( "stand" );
	self.m_AniGroup:CheckAndLoadAni( "stand_rest1" );
	self.m_tickCheckAniLoad:Start( 33 );
end

function CWndFusion:OnTickCheckLoad()
	if self.m_AniGroup:IsAniLoaded( "stand" ) and self.m_AniGroup:IsAniLoaded( "stand_rest1" ) then
		self.m_tickCheckAniLoad:Stop();
		self:ShowEffectAndAni();
	end
end




-----材料说明框
-----fsj_pifu_hecheng_cailiao
function CWndFragmentDesc:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndFragmentDesc:OnCreated()
	self.m_TextFrom			= self:GetDlgChild( "w_tujing" );
	self.m_TextName			= self:GetDlgChild( "name" );
	self.m_Icon				= CRichIconWnd:new( self, "icon" );
	self:AddEventListener( GM_WM_MOUSECLICK, "OnClick", self );
end

function CWndFragmentDesc:SetData( nFragmentID )
	local szName = g_tblTabFile.fragment[nFragmentID].dName;
	local szDesc = g_tblTabFile.fragment[nFragmentID].dDescription;
	local nIconID = g_tblTabFile.fragment[nFragmentID].nIconID;
	self.m_TextName:SetWndText( szName );
	self.m_TextFrom:SetWndText( szDesc );
	self.m_Icon:SetIconID( nIconID );
	self:ShowWnd( true );
end

function CWndFragmentDesc:OnClick()
	self:ShowWnd( false );
end



--endregion
