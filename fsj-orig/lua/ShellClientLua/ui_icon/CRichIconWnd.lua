--region CRichIconWnd.lua
--Date 2016/3/1

PropTipsWndName = { "propinfo", "scriptpropInfo" };

--带有稀有框和禁止图标的图标
function CRichIconWnd:Ctor( ParentWnd, szName )
	CGButton.Ctor( self );
    self.m_nColor = nil;
    self.m_nStar = nil;
    self.m_nIconID = nil;
	self.m_nCount = nil;
	self.m_nLevel = nil;
	self.m_bLock = nil;
	self.m_nBorder = nil;

    self.m_wndStar = nil;
    self.m_wndLv = nil;
    self.m_wndPropCount = nil;
    self.m_wndLock = nil;
    self.m_wndPinjie = nil;

    self.m_Context = {}

	if ParentWnd then
		if szName and szName ~= "" then
--			assert( ParentWnd:GetDlgChild( szName ) );
			ParentWnd:AssignDlgChildToWnd( self, szName );
		else
			self:CreateFromRes( "gui/cfg/icon.gui", ParentWnd );
		end
	end
end

function CRichIconWnd:OnCreated()	
	self:SetIconID( self.m_nIconID )
	self:SetPropCount( self.m_nCount );
	self:SetLock( self.m_bLock );
	self:SetLevel( self.m_nLevel );
    self:SetRaceIcon( self.m_nColor );
    self:SetStarCount( self.m_nStar );
	self:Draw3DObjAfterChildren( true );
end

function CRichIconWnd:SetChildSize( Child )
	local fOrgWidth = self:GetOrgWidth();
	local fOrgHeight = self:GetOrgHeight();
	local fWidth = self:GetWndWidth();
	local fHeight = self:GetWndHeight();

	local rtChild = CFRect:new();
	Child:GetWndLocalRect( rtChild );

	--rtChild应该包含本窗口从112到Org再到当前值的变化
	--此时rtChild已经包含了本窗口由Org变化为当前状态时的长宽变化
	--但是还缺少从112到Org的变化，得补上，方法如下：
	--先回退当前值到Org，然后再由112变化到当前值
	ScaleRect( rtChild, Child:GetLockFlag(), fWidth, fHeight, fOrgWidth - fWidth, fOrgHeight - fHeight );
	ScaleRect( rtChild, Child:GetLockFlag(), 112, 112, fWidth - 112, fHeight - 112 );
	Child:SetWndLocalRect( rtChild );
end

----------------------------------------------------------
-- IconID
----------------------------------------------------------
function CRichIconWnd:SetIconID( nID, nBorder )
    self.m_nIconID = nID;
    self.m_nBorder = nBorder or 0;
	if not self:IsCreated() then
		return;
	end
    CIconManager:Instance():SetIconToRichButton( self, self.m_nIconID, false, self.m_nBorder );
--	self.m_sPropWndName = self.m_sPropWndName or PropTipsWndName[1];
end

function CRichIconWnd:GetIconID()
    return self.m_nIconID;
end

----------------------------------------------------------
-- PropCount
----------------------------------------------------------
function CRichIconWnd:OnPropCountCreate()
	self:SetChildSize( self.m_wndPropCount );
	self.m_wndPropCount:RemoveEventListener( WM_CREATE, "OnPropCountCreate", self );
    self:SetPropCount( self.m_nCount );
end

function CRichIconWnd:SetPropCount( nCount )
	self.m_nCount = nCount;
	if not self:IsCreated() then
		return;
	end

	if( nCount and ( 
		type( nCount ) == "number" and nCount ~= 0 or 
		type( nCount ) == "string" and nCount ~= "" ) )then
		if self.m_wndPropCount == nil then
			self.m_wndPropCount = CGRichWnd:new();
			self.m_wndPropCount:CreateFromRes( "gui/cfg/icon_count.gui", self, 0 );
			self.m_wndPropCount:AddEventListener( WM_CREATE, "OnPropCountCreate", self );
		end		
		
		if self.m_wndPropCount:IsCreated() then
			if type( nCount ) == "number" and nCount < 0 then
				nCount = "#cffff0000"..nCount;
			end
			self.m_wndPropCount:SetWndText( nCount );
		end
	else
		if self.m_wndPropCount then
			self.m_wndPropCount:DestroyWnd();
			self.m_wndPropCount = nil;
		end
	end
end

----------------------------------------------------------
-- Lock
----------------------------------------------------------
function CRichIconWnd:OnLockCreate()
	self:SetChildSize( self.m_wndLock );
	self.m_wndLock:RemoveEventListener( WM_CREATE, "OnLockCreate", self );
end

function CRichIconWnd:SetLock( bLock )
    self.m_bLock = bLock;
	if not self:IsCreated() then
		return;
	end
	
	if( bLock )then
		if self.m_wndLock == nil then
			self.m_wndLock = CGButton:new();
			self.m_wndLock:CreateFromRes( "gui/cfg/icon_lock.gui", self, 0 );
		end	
	else
		if self.m_wndLock then
			self.m_wndLock:DestroyWnd();
			self.m_wndLock = nil;
		end
	end
end

function CRichIconWnd:IsLock()
    return self.m_bLock;
end

----------------------------------------------------------
-- Level
----------------------------------------------------------
function CRichIconWnd:OnLevelCreate()
	self:SetChildSize( self.m_wndLv );
	self.m_wndLv:RemoveEventListener( WM_CREATE, "OnLevelCreate", self );
    self:SetLevel( self.m_nLevel );
end

function CRichIconWnd:SetLevel( nLevel )
	self.m_nLevel = nLevel;
	if not self:IsCreated() then
		return;
	end

	if( nLevel and nLevel >= 1 )then
		if self.m_wndLv == nil then
			self.m_wndLv = CGRichWnd:new();
			self.m_wndLv:CreateFromRes( "gui/cfg/icon_dengji.gui", self, 0 );
			self.m_wndLv:AddEventListener( WM_CREATE, "OnLevelCreate", self );
		end		
		
		if self.m_wndLv:IsCreated() then
			self.m_wndLv:SetWndText( string.format( g_data_string["hero_name"], nLevel, "" ) );
		end
	else
		if self.m_wndLv then
			self.m_wndLv:DestroyWnd();
			self.m_wndLv = nil;
		end
	end
end

----------------------------------------------------------
-- RareIcon
----------------------------------------------------------
function CRichIconWnd:OnRaceIconCreate()
	self:SetChildSize( self.m_wndPinjie );
	self.m_wndPinjie:RemoveEventListener( WM_CREATE, "OnRaceIconCreate", self );
	self.m_wndPinjie:ShowWnd( true );
end

function CRichIconWnd:SetRaceIcon( nColor )
    self.m_nColor = nColor;
	if not self:IsCreated() then
		return;
	end

    if self.m_wndPinjie ~= nil then
		if self.m_wndPinjie.m_nColor == self.m_nColor then
			return;
		end
		if self.m_wndStar then
			self.m_wndStar:SetParent( self );
		end
        self.m_wndPinjie:DestroyWnd();
		self.m_wndPinjie = nil;
    end

	if( nColor and nColor >= 1 )then
		self.m_wndPinjie = CRichFrameFactory.CreateRichFrame( self.m_nColor, self )
		self.m_wndPinjie:AddEventListener( WM_CREATE, "OnRaceIconCreate", self );
		self.m_wndPinjie.m_nColor = self.m_nColor;
	end
end

----------------------------------------------------------
-- StarCount
----------------------------------------------------------
function CRichIconWnd:OnStarCountCreate()
	self:SetChildSize( self.m_wndStar );
	self.m_wndStar:RemoveEventListener( WM_CREATE, "OnStarCountCreate", self );
end

function CRichIconWnd:SetStarCount( nCount )
	local bRefreshFlag = false;
	if nCount ~= self.m_nStar then
		bRefreshFlag = true;
	end
    self.m_nStar = nCount;
	if not self:IsCreated() then
		return;
	end

	if( nCount and nCount >= 1 )then
		if self.m_wndStar == nil then
			self.m_wndStar = CGWnd:new();
			self.m_wndStar:CreateFromRes( "gui/cfg/icon_star"..nCount..".gui", self, 0 );
			self.m_wndStar:AddEventListener( WM_CREATE, "OnStarCountCreate", self );
		elseif bRefreshFlag then
			self.m_wndStar:DestroyWnd();
			self.m_wndStar = nil;
			self.m_wndStar = CGWnd:new();
			self.m_wndStar:CreateFromRes( "gui/cfg/icon_star"..nCount..".gui", self, 0 );
			self.m_wndStar:AddEventListener( WM_CREATE, "OnStarCountCreate", self );
		end	
	else
		if self.m_wndStar then
			self.m_wndStar:DestroyWnd();
			self.m_wndStar = nil;
		end
	end
end

----------------------------------------------------------
-- Misc
----------------------------------------------------------
function CRichIconWnd:SetWndText( szText )
	self:SetPropCount( szText );
end

function CRichIconWnd:SetIconByProp( nPropType, nPropIndex, wnd )
    self.m_Context = { nPropType, nPropIndex };
    self:SetIconID( CInventoryConfig:Instance():GetPropIcon( nPropType, nPropIndex ) );
    self:SetRaceIcon( CInventoryConfig:Instance():GetPropRich( nPropType, nPropIndex ) );
	local bScriptProp = nPropType == ePFT_SCRIPT;
	self.m_sPropWndName = bScriptProp and PropTipsWndName[2] or PropTipsWndName[1];
	self.m_wndParent = wnd;
	self:AddEventListener( GM_WM_MOUSECLICK, "OnClicked", self );
end

function CRichIconWnd:SetHeroRaceIcon( nGrade )
	local nColorIndex = CHeroRichName.GetRichGradeIcon( nGrade );
	return self:SetRaceIcon( nColorIndex );
end

function CRichIconWnd:SetCallBackFun( fFun, Context, Handle )
    self.m_fCallBackFun = fFun;
	self.m_Handle = Handle;
    if Context ~= nil then
        self.m_Context = Context;
    end
    self:AddEventListener( GM_WM_MOUSECLICK, "OnClicked", self );
end

function CRichIconWnd:SetClickWndName( WndName )
	self.m_sPropWndName = WndName;
end

function CRichIconWnd:OnClicked()
    if self.m_Context ~= nil  then
        if self.m_fCallBackFun then
		    self.m_fCallBackFun( self.m_Handle, self.m_Context );
		else
			local wnd = g_App.m_wndGameMainState:GetWnd( self.m_sPropWndName );
			if wnd then
				local wndParent = self.m_wndParent or self:GetParent() ;
				--不设置父窗口,否则被剪切
				wnd:SetData( self.m_Context[1], self.m_Context[2], nil );
			end
	    end 
    end
end

function CRichIconWnd:SetHeroInfo( HeroInfo, szStarIcon )
	local nGrade = nil;
	local nStar = nil;
	local nLevel = nil;
	local nIconID = g_data_Hero[0].nAvatar;
	if HeroInfo then
		nGrade = HeroInfo:GetGrade();
		nStar = HeroInfo:GetStar();
		nLevel = HeroInfo:GetLevel();
		nIconID = g_data_Hero[HeroInfo:GetID()].nAvatar;
	end
	self:SetHeroRaceIcon( nGrade );
	self:SetStarCount( nStar, szStarIcon );
	self:SetLevel( nLevel );
	self:SetIconID( nIconID );
end
--endregion
