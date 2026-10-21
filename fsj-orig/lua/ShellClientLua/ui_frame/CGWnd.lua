--region CGWnd.lua
--Date 2015-12-07

g_mapCGWnd = {}
local CGWnd_GetDlgChild = 
	CGWnd_GetDlgChild or CGWnd.GetDlgChild
local CGWnd_CreateFromRes = 
	CGWnd_CreateFromRes or CGWnd.CreateFromRes

eShowWndMask_Level = 0x1;
eShowWndMask_HuSong = 0x2;

local tblCueState = 
{ 
	hongdian	= 1,
	landian		= 2, 
	lvdian		= 3
};
	
--nLoadType	
--= 0 立刻显示
--= 1 先加载不显示
--= 2 显示时加载
function CGWnd:Ctor( sResName, ParentWnd, nLoadType )
    self.m_bHasRes = sResName;
	g_mapCGWnd[self] = self;
    if nil == sResName then
        return;
    end
    if not CGWnd.CreateFromRes( self, sResName, ParentWnd, nLoadType ) then
        print( "Create CGWnd Error", sResName );
    end
end

function CGWnd:tostring()
	return "Wnd:" .. self:GetWndName();
end

function CGWnd:Toggle()
    self:ShowWnd( not self:IsShow() );
end

function CGWnd:SetUserObject( Value )
	if self.m_userObject == Value then
		return false;
	end
    self.m_userObject = Value;
	return true;
end

function CGWnd:GetUserObject()
    return self.m_userObject;
end

function CGWnd:ShowAndSetFocus()
	self:ShowWnd( true );
	self:SetFocus();
end

function CGWnd:GetDlgChild( szChildName )
	local function WndClass( Wnd )
		local szClassName = Wnd:GetClassName();
		local WndClass = _G[szClassName];
		return ClassCast( WndClass, Wnd );
	end
	
	local wndChild = CGWnd_GetDlgChild( self, szChildName );
	if wndChild == nil then
		return nil;
	end		
	return wndChild and WndClass( wndChild ) or nil
end

--WndCheck 是否是self的leaf
function CGWnd:HasLeaf( WndCheck )
	while( WndCheck ) do
		if WndCheck == self then
			return true;
		end
		WndCheck = WndCheck:GetParent();
	end
	return false;
end

function CGWnd:CreatAsEmptyContain( wndParent, wndWidth, wndHeight )
	wndWidth = ( wndWidth or wndParent == nil ) and wndWidth or wndParent:GetWndWidth();
	wndHeight = ( wndHeight or wndParent == nil ) and wndHeight or wndParent:GetWndHeight();
	local widthStandar = g_App:GetGUIMgr():GetStandarUISheetWidth();
	local heightStandar = g_App:GetGUIMgr():GetStandarUISheetHeight();
	self:Create( "", BitOr( eWS_CHILD, eWS_ALPHAENABLE ), 0, 0, 
		widthStandar, heightStandar, wndParent, "", 12, -1, 0, 0, LOCK_ALL );
	self:SetWndSize( wndWidth, wndHeight );
	self.m_bPreventHideOnEscape = true;
end

function CGWnd:AddCloseAction( szBtnName )
	local wndChild = self:GetDlgChild( szBtnName or "close" );
	if( wndChild == nil ) then
		return;
	end
	wndChild:AddEventListener( GM_WM_ACTION, "OnClose", self );
end

function CGWnd:OnClose( Event )
	self:ShowWnd( false );
end

function CGWnd:IsHideOnEscape()
	return not self.m_bPreventHideOnEscape;
end

function CGWnd:SetHideOnEscape( bEnable )
	self.m_bPreventHideOnEscape = not bEnable
end

function CGWnd:SetMouseEnabled( value )
	local v = value and BitAnd( self:GetStyle(), BitNot( eWS_MSGTRANSPT ) ) or BitOr( self:GetStyle(), eWS_MSGTRANSPT )
	self:SetStyle( v );
end

function CGWnd:GetMouseEnabled()
	return BitAnd( self:GetStyle(), eWS_MSGTRANSPT ) == 0;
end

---------------------红点-------------------
function CGWnd:OnCueStateChanged()
end

function CGWnd:PostCueStateChange()
	local nCueState = self:GetCueState()
	for k, v in pairs( tblCueState ) do
		local wndCue = self:GetDlgChild( k );
		if wndCue then
			local nState = BitAnd( nCueState, v )
			wndCue:ShowWnd( nState ~= 0 );
		end
	end
	self:OnCueStateChanged()
	for k, v in pairs( self.m_tblCueLisener or {} ) do
		v:PostCueStateChange()
	end
end

function CGWnd:ShowCueState( szName, bShow )
	if bShow then
		self.m_nCueState = BitOr( self.m_nCueState, tblCueState[szName] );
	else
		self.m_nCueState = BitAnd( self.m_nCueState, BitNot( tblCueState[szName] ) );
	end
	self:PostCueStateChange()
end

function CGWnd:ShowRedPoint( bShow )
	self:ShowCueState( "hongdian", bShow );
end

function CGWnd:ShowBluePoint( bShow )
	self:ShowCueState( "landian", bShow );
end

function CGWnd:ShowGreenPoint( bShow )
	self:ShowCueState( "lvdian", bShow );
end

function CGWnd:GetCueState()
	local nCueState = self.m_nCueState or 0;
	if nCueState == 7 then
		return nCueState;
	end
	for k, v in pairs( self.m_tblCueSource or {} ) do
		nCueState = BitOr( nCueState, v:GetCueState() )
		if nCueState == 7 then
			return nCueState;
		end
	end
	return nCueState;
end

function CGWnd:IsShowRedPoint()
	return BitAnd( self:GetCueState(), tblCueState["hongdian"] ) ~= 0;
end

function CGWnd:IsShowBluePoint()
	return BitAnd( self:GetCueState(), tblCueState["landian"] ) ~= 0;
end

function CGWnd:IsShowGreenPoint()
	return BitAnd( self:GetCueState(), tblCueState["lvdian"] ) ~= 0;
end

function CGWnd:AddCueListener( Wnd )
	self.m_tblCueLisener = self.m_tblCueLisener or {};
	Wnd.m_tblCueSource = Wnd.m_tblCueSource or {};
	self.m_tblCueLisener[Wnd] = Wnd;
	Wnd.m_tblCueSource[self] = self;
end

function CGWnd:RemoveCueListener( Wnd )
	if self.m_tblCueLisener then
		self.m_tblCueLisener[Wnd] = nil;
	end
	if Wnd.m_tblCueSource then
		Wnd.m_tblCueSource[self] = nil;
	end
end

function CGWnd:ClearCueListener()
	local tblListner = self.m_tblCueLisener;
	self.m_tblCueLisener = nil;
	for k, v in pairs( tblListner or {} ) do
		k.m_tblCueSource[self] = nil;
	end
	
	local tblSource = self.m_tblCueSource;
	self.m_tblCueSource = nil;
	for k, v in pairs( tblSource or {} ) do
		k.m_tblCueLisener[self] = nil;
	end
end
---------------------红点-------------------

function CGWnd:FastAddActionListenerForChild( szChildName, funHandler, pHandler )
	local wndChild = self:GetDlgChild( szChildName );
	if wndChild then
		wndChild:AddActionListener( funHandler, pHandler );
	end
	return wndChild;
end

function CGWnd:FastRemoveActionListenerForChild( szChildName, funHandler, pHandler )
	local wndChild = self:GetDlgChild( szChildName );
	if wndChild == nil then
		wndChild:RemoveActionListener( funHandler, pHandler );
	end
	return wndChild;
end

function CGWnd:AddClickListener( funHandler, pHandler )
	self:AddEventListener( GM_WM_MOUSECLICK, funHandler, pHandler );
end

function CGWnd:AddActionListener( funHandler, pHandler )
	self:AddEventListener( GM_WM_ACTION, funHandler, pHandler );
end

function CGWnd:RemoveActionListener( funHandler, pHandler )
	self:RemoveEventListener( GM_WM_ACTION, funHandler, pHandler );
end

function CGWnd:AddCreateListener( funHandler, pHandler )
	self:AddEventListener( WM_CREATE, funHandler, pHandler );
end

function CGWnd:RemoveCreateListener( funHandler, pHandler )
	self:RemoveEventListener( WM_CREATE, funHandler, pHandler );
end

function CGWnd:AddStateListener( funHandler, pHandler )
	self:AddEventListener( GM_WM_STATE_CHANGED, funHandler, pHandler );
end

function CGWnd:RemoveStateListener( funHandler, pHandler )
	self:RemoveEventListener( GM_WM_STATE_CHANGED, funHandler, pHandler );
end

function CGWnd:AddEventListener( Type, funHandler, pHandler )
	if self.m_EventDispatcher == nil then
		self.m_EventDispatcher = CEventDispatcher:new();
	end
	self.m_EventDispatcher:AddEventListener( Type, funHandler, pHandler );
end

function CGWnd:RemoveEventListener( Type, funHandler, pHandler )
	if self.m_EventDispatcher == nil then
		return;
	end
	self.m_EventDispatcher:RemoveEventListener( Type, funHandler, pHandler )
end

function CGWnd:RemoveAllEventListener()
	if self.m_EventDispatcher == nil then
		return;
	end
	self.m_EventDispatcher:RemoveAllEventListener();
end

function CGWnd:DispatchEvent( Event )
	if self.m_EventDispatcher == nil then
		return;
	end

	self.m_EventDispatcher:DispatchEvent( Event );
end

function CGWnd:HasEventListener( Type, funListner, pHandler )
	if self.m_EventDispatcher == nil then
		return false;
	end
	return self.m_EventDispatcher:HasEventListener( Type, funListner, pHandler );
end

local CGWnd_OnMsgDispatch = CGWnd_OnMsgDispatch or CGWnd.OnMsgDispatch;
function CGWnd:OnMsgDispatch( nInputID, pWnd, nMessage, wParam, lParam )	
	if nMessage >= GM_WM_FXFIRST and nMessage <= GM_WM_FXLAST then	
		wParam = self:GetAttachEffectName( wParam );
	end

	local Dispatch = self.m_EventDispatcher;
	if nMessage == WM_DESTROY and pWnd == self then
		g_mapCGWnd[self] = nil;
		self.m_EventDispatcher = nil;
		self:ClearCueListener();
	end

	if Dispatch == nil then
		return CGWnd_OnMsgDispatch( self, nInputID, pWnd, nMessage, wParam, lParam );
	end
	
	local Event = CEventDispatcher:CreateEvent( nMessage, pWnd, nInputID );
	Event.m_CurrentTarget = self;
	Event.m_wParam = wParam;
	Event.m_lParam = lParam;
	
	if nMessage >= WM_MOUSEFIRST and nMessage <= WM_MOUSELAST or nMessage >= GM_WM_MOUSEFIRST and nMessage <= GM_WM_MOUSELAST then
		Event.x = int16( Event.m_lParam );
		Event.y = int16( Event.m_lParam / 65536 );
		Event.m_GlobalX = self:GetGlobalX() + Event.x;
		Event.m_GlobalY = self:GetGlobalY() + Event.y;
	end

    Event.m_StopImmediately = false;
	Dispatch:DispatchEvent( Event );
	if( Event.m_StopImmediately ) then
		return false;
	end
	return CGWnd_OnMsgDispatch( self, nInputID, pWnd, nMessage, wParam, lParam )
		and not Event.m_StopImmediately;
end

function CGWnd:GetChildBottomMost()
	return self:GtSafeDeltaXWnd( self:GetLastChild() );
end

function CGWnd:GetBrotherAbove()
	return self:GetSafeDeltaXWnd( self:GetPreWnd() );
end

function CGWnd:GtSafeDeltaXWnd( wnd )
	if not wnd then
		return nil;
	end
	local className = wnd:GetClassName();
	if className == wnd:GetWndName() then
		return wnd
	end
	local WndClass = _G[className];
	return ClassCast( WndClass, Wnd ); 
end

function CGWnd:GetFullName()
	local szName = self:GetWndName();
	local Parent = self:GetParent();
	while Parent do
		szName = Parent:GetWndName() .. "." .. szName;
		Parent = Parent:GetParent();
	end
	return szName;
end

--缩放窗口
-- nScaleType: 缩放效果如下
-- ↗: 放大; ↘: 缩小
--     0             1                 2                    3        
--    ↗↘                         ↗↘                        ↗↘       
--  ↗    ↘     ↘     ↗       ↗     ↘     ↗      ↘     ↗    ↘     
--                 ↘↗         |         ↘↗           ↘↗             
--                             |      |      |                       
--                           Speed1, Speed2, Speed3                  
local fDefMagnifyScale = 2;
local fDefShrinkScale = 0.3;
local fDefSpeed = 0.1;
function CGWnd:PlayWndScaleEffect( nScaleType, fMagnifyScale, fShrinkScale, fSpeed1, fSpeed2, fSpeed3 )
	if not self:IsShow() then
		return;
	end

	nScaleType = nScaleType or 0;

	self:EnablePreRender( true );
	self.m_bMagnify = ( nScaleType == 0 or nScaleType == 2 ) and true or false;
	self.m_funPreRender = 
		function() 
			local fScaleSpeed = self.m_bMagnify and 
				( fSpeed1 or fDefSpeed ) or ( fSpeed2 or fDefSpeed );

			local DeltaScale;
			fScale = self:GetScaleX() + fScaleSpeed * ( self.m_bMagnify and 1 or -1 );

			if nScaleType == 0 or nScaleType == 2 then
				if self.m_bMagnify then
					fScale = fScale > ( fMagnifyScale or fDefMagnifyScale ) 
						and ( fMagnifyScale or fDefMagnifyScale ) or fScale;
				else
					fScale = fScale < 1 and 1 or fScale;
				end
			elseif nScaleType == 1 or nScaleType == 3 then
				if self.m_bMagnify then
					fScale = fScale > 1 and 1 or fScale;
				else
					fScale = fScale < ( fShrinkScale or fDefShrinkScale ) 
						and ( fShrinkScale or fDefShrinkScale ) or fScale;
				end
			end

			self:SetScaleX( fScale );
			self:SetScaleY( fScale );

			if nScaleType == 0 or nScaleType == 2 then
				local fTmp = fMagnifyScale or fDefMagnifyScale;
				if math.abs( self:GetScaleX()- fTmp ) < 0.0001 then
					self.m_bMagnify = not self.m_bMagnify;
				end
			elseif nScaleType == 1 or nScaleType == 3 then
				local fTmp = fShrinkScale or fDefShrinkScale;
				if math.abs( self:GetScaleX() - fTmp ) < 0.0001 then
					self.m_bMagnify = not self.m_bMagnify;
				end
			end

			if self:GetScaleX() == 1 then
				if ( nScaleType == 0 and not self.m_bMagnify ) or ( nScaleType == 1 and self.m_bMagnify ) then
					self:EnablePreRender( false );
					self:RemoveEventListener( GM_WM_PRERENDER, "m_funPreRender", self );
					self.m_bPlaying = false;
				elseif nScaleType == 2 then
					self:RemoveEventListener( GM_WM_PRERENDER, "m_funPreRender", self );
					self:PlayWndScaleEffect( 1, fMagnifyScale, fShrinkScale, fSpeed2, fSpeed3 );
				elseif nScaleType == 3 then
					self:RemoveEventListener( GM_WM_PRERENDER, "m_funPreRender", self );
					self:PlayWndScaleEffect( 0, fMagnifyScale, fShrinkScale, fSpeed1, fSpeed3 );
				end
			end
		end

	self:AddEventListener( GM_WM_PRERENDER, "m_funPreRender", self );
	self.m_bPlaying = true;
end

function CGWnd:ShowTopResWnd()
	
end

--nFadeInType 
-- 1 From Left To Right
-- 2 From Right To Left
-- 3 From Top To Bottom
-- 4 From Bottom To Top
function CGWnd:FadeIn( nFadeInType, nBeginPos, nEndPos, nFadeInTime )
	if not self:IsShow() then
		return
	end

	self:EnablePreRender( true );
	local nMoveSpeed = math.abs( nEndPos - nBeginPos ) / nFadeInTime;
	self.m_funcFadeIn = function()
		if nFadeInType == 1 then
			local x = nBeginPos + nMoveSpeed;
			self:SetGlobalX( x );
			self:FadeIn( nFadeInType, self:GetGlobalX(), nEndPos, nFadeInTime );
			if  math.abs( x - nEndPos ) < 1 then
				self:RemoveEventListener( GM_WM_PRERENDER, "m_funcFadeIn", self );	
			end
		elseif nFadeInType == 2 then
			local x = nBeginPos - nMoveSpeed;
			self:SetGlobalX( x );
			self:FadeIn( nFadeInType, self:GetGlobalX(), nEndPos, nFadeInTime );
			if math.abs( x - nEndPos ) < 1 then
				self:RemoveEventListener( GM_WM_PRERENDER, "m_funcFadeIn", self );	
			end
		elseif nFadeInType == 3 then
			local y = nBeginPos + nMoveSpeed;
			self:SetGlobalY( y );
			self:FadeIn( nFadeInType, self:GetGlobalY(), nEndPos, nFadeInTime );
			if math.abs( y - nEndPos ) < 1 then
				self:RemoveEventListener( GM_WM_PRERENDER, "m_funcFadeIn", self );	
			end
		elseif nFadeInType == 4 then
			local y = nBeginPos - nMoveSpeed;
			self:SetGlobalY( y );
			self:FadeIn( nFadeInType, self:GetGlobalY(), nEndPos, nFadeInTime );
			if math.abs( y - nEndPos ) < 1 then
				self:RemoveEventListener( GM_WM_PRERENDER, "m_funcFadeIn", self );	
			end
		end
	end
	self:AddEventListener( GM_WM_PRERENDER, "m_funcFadeIn", self );
end

function CGWnd:DoScale( fBeginScale, fEndScale, nScaleTime )
	if not self:IsShow() then
		return;
	end

	local ScaleTime = nScaleTime or g_data_miscconfig.m_nWndScaleTime;
	self:EnablePreRender( true );
	local fScaleSpeed = ( fEndScale - fBeginScale ) / ScaleTime;
	self.m_funcDoScale = function ()
		local fScale = fBeginScale + fScaleSpeed;
		self:SetScaleX( fScale );
		self:SetScaleY( fScale );
		self:DoScale( fScale, fEndScale, ScaleTime );

		if math.abs( self:GetScaleX() - fEndScale ) <= 0.01 then
			self:RemoveEventListener( GM_WM_PRERENDER, "m_funcDoScale", self );
		end
	end

	self:AddEventListener( GM_WM_PRERENDER, "m_funcDoScale", self );
end

--endregion
