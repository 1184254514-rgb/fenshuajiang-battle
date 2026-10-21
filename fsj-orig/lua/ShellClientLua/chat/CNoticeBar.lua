--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--公告栏
function CNoticeBar:Ctor( sResName, ParentWnd, nLoadType )
    CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );

end

local function SetClipMasked( wnd, bValue )
    local CLIP_BY_PARENT = 0x00200000;
    if bValue then
        wnd:SetStyle( BitOr( wnd:GetStyle(), CLIP_BY_PARENT ) );
    else
        wnd:SetStyle( BitAnd( wnd:GetStyle(), BitNot( CLIP_BY_PARENT ) ) );
    end
end

function CNoticeBar:OnCreated()
    self.m_timeTick = CTick:new( "OnTimeTick", self );
    self.m_nSlideSpeed = 0;     --x坐标上速度
    self.m_nOldX = 0;
    SetClipMasked( self, true );
    self:SetWndText( "" );

    self.m_wndMsg = self:GetDlgChild( "msg" );
    SetClipMasked( self.m_wndMsg, true );

	local nMaxCount = 100;
    local nMsgDuration = 10000;
    self.m_msgs = CSortInfo:new( nMaxCount );
    self.m_nSlideSpeed = self.m_wndMsg:GetWndWidth() / nMsgDuration;
    self.m_wndMsg:SetLocalX( self:GetWndWidth() + self.m_wndMsg:GetLocalX() );
    
    self.m_nOldX = self.m_wndMsg:GetLocalX();
    self:SetNextNoticeText();
	self.m_wndMsg:AddClickListener( "OnClick", self );
end
		
function CNoticeBar:OnDestroy()
    if self.m_timeTick:IsRegisted() then
        self.m_timeTick:Stop();
    end
end
		
function CNoticeBar:SetNextNoticeText()
    if not self.m_timeTick:IsRegisted() then
        self.m_timeTick:Start( 33 );
    end

    self.m_wndMsg:SetLocalX( self.m_nOldX );
    
    local strText = self.m_msgs:Pop();
    if strText and #strText > 0 then
        self.m_wndMsg:SetWndText( strText );
        self.m_wndMsg:SetWndSize( self.m_wndMsg:GetLineContentEndX(), self.m_wndMsg:GetWndHeight() );
    else
        self.m_wndMsg:SetWndSize( self:GetWndWidth(), self.m_wndMsg:GetWndHeight() );
        self.m_wndMsg:SetWndText( "" );
        self.m_timeTick:Stop();
        self:ShowWnd( false );
    end
end

function CNoticeBar:AddContent( strText, nGrade )
    self:ShowWnd( true );
    if self.m_msgs then
        self.m_msgs:Unshift( strText, nGrade );
    end

    if self.m_wndMsg and self.m_wndMsg:GetWndText() == "" then
        self:SetNextNoticeText();
    end
end

function CNoticeBar:OnTimeTick()
    local x = self.m_wndMsg:GetLocalX();
    x = x - self.m_nSlideSpeed * self.m_timeTick:GetInteval();
    self.m_wndMsg:SetLocalX( x );
	
    if x <= -self.m_wndMsg:GetWndWidth() then
        self.m_wndMsg:SetLocalX( self.m_nOldX );
        self.m_wndMsg:SetWndText( "" );
        self:SetNextNoticeText();
    end
end

function CNoticeBar:OnClick( Event )
	self:SetNextNoticeText();
end

--endregion
