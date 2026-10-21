--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


CCharListItemOpr = class( CGWnd );
function CCharListItemOpr:OnCreated()
    self.m_pBtn = self:GetDlgChild( "b_guanzhu" );
    self.m_pBtn1 = self:GetDlgChild( "b_quguan" );
    self.m_pBtn2 = self:GetDlgChild( "b_heimingdan" );
    self.m_pBtn2 = self:GetDlgChild( "b_heimingdan" );

    if self.m_pBtn ~= nil then
	    self.m_pBtn:AddActionListener( "OnBtn", self );
    end
    if self.m_pBtn1 ~= nil then
	    self.m_pBtn1:AddActionListener( "OnBtn1", self );
    end
    if self.m_pBtn2 ~= nil then
	    self.m_pBtn2:AddActionListener( "OnBtn2", self );
    end
end

function CCharListItemOpr:OnActive( bActive )
	if not bActive then
	    self:ShowWnd( false );
    end
end

function CCharListItemOpr:Show( nAccountID )
	self:ShowAndSetFocus();
    self.nAccountID = nAccountID;
end

function CCharListItemOpr:OnBtn()
    if g_App.m_WorldConnect == nil then
        return;
    end
	local NetMsg = CAddFollowee:new();
    NetMsg.nAccountID = self.nAccountID;
	g_App.m_WorldConnect:SendShellMsg( NetMsg );
    self:ShowWnd( false );
end

function CCharListItemOpr:OnBtn1()
    if g_App.m_WorldConnect == nil then
        return;
    end
	local NetMsg = CRemoveFollowee:new();
    NetMsg.nAccountID = self.nAccountID;
    g_App:GetGameStart().m_pCharListTip:Show( 0, NetMsg );
    self:ShowWnd( false );
end

function CCharListItemOpr:OnBtn2()
    if g_App.m_WorldConnect == nil then
        return;
    end
	local NetMsg = CAddBlacklist:new();
    NetMsg.nAccountID = self.nAccountID;
    g_App:GetGameStart().m_pCharListTip:Show( 1, NetMsg );
    self:ShowWnd( false );
end

CCharListItemTip = class( CGWnd );
function CCharListItemTip:OnCreated()
    self.m_pTip1 = self:GetDlgChild( "bg_quguan" );
    self.m_pTip2 = self:GetDlgChild( "bg_heimingdan" );
    self.m_pTip3 = self:GetDlgChild( "bg_yichuheimingdan" );
    self.m_pBtnOK = self:GetDlgChild( "b_ok" );
    self.m_pBtnCancel = self:GetDlgChild( "b_quxiao" );

	self.m_pBtnOK:AddActionListener( "OnOK", self );
	self.m_pBtnCancel:AddActionListener( "OnCancel", self );
end

function CCharListItemTip:Show( nType, NetMsg )
    self.nType = nType;
    self.NetMsg = NetMsg;
    if nType == 0 then
        self.m_pTip1:ShowWnd( true );
        self.m_pTip2:ShowWnd( false );
        self.m_pTip3:ShowWnd( false );
    elseif nType == 1 then
        self.m_pTip1:ShowWnd( false );
        self.m_pTip2:ShowWnd( true );
        self.m_pTip3:ShowWnd( false );
    else
        self.m_pTip1:ShowWnd( false );
        self.m_pTip2:ShowWnd( false );
        self.m_pTip3:ShowWnd( true );
    end
    self:ShowAndSetFocus();
end

function CCharListItemTip:OnOK()
	g_App.m_WorldConnect:SendShellMsg( self.NetMsg );
    self.NetMsg = nil;
    self:ShowWnd( false );
end

function CCharListItemTip:OnCancel()
    self.NetMsg = nil;
    self:ShowWnd( false );
end


function CCharListItem:OnCreated()
    local resName = self:GetResName();

    self.m_pHead = self:GetDlgChild( "head.touxiang" );
    self.m_pID = self:GetDlgChild( "w_id" );
    self.m_pName = self:GetDlgChild( "name" );
    self.m_pState = self:GetDlgChild( "W_youxizhuangtai" );
    self.m_pBtn = self:GetDlgChild( "B_ok" );
    self.m_pBtn1 = self:GetDlgChild( "B_qita" );
    self.m_pBlacklist = self:GetDlgChild( "bg_heimingdan" );
	self.m_pBtnShowInfo = self:GetDlgChild( "wanjiaxinxi" );
	self.m_pBtnShowInfo:AddActionListener( "OnShowInfo", self );
    
    if self.m_pBtn ~= nil then
	    self.m_pBtn:AddActionListener( "OnBtn", self );
    end
    if self.m_pBtn1 ~= nil then
	    self.m_pBtn1:AddActionListener( "OnBtn1", self );
    end

    local pLevel = self:GetDlgChild( "duanwei" );
    if pLevel then
        self.m_pLevelText = pLevel:GetDlgChild( "W_duanwei" );
        self.m_pLevelIcons = {};
        for j = 1, 8, 1 do
            self.m_pLevelIcons[j] = pLevel:GetDlgChild( "icon_duanwei." .. tostring( j ) );
        end
    end

	self.m_bInSearchList = "fsj_haoyou_chazhao2_item" == resName;
    g_App.m_EventDispatcher:AddEventListener( "AddFollowee", "OnAddFollowee", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveFollowee", "OnRemoveFollowee", self );
    g_App.m_EventDispatcher:AddEventListener( "AddBlacklist", "OnAddBlacklist", self );
    g_App.m_EventDispatcher:AddEventListener( "RemoveBlacklist", "OnRemoveBlacklist", self );
end

function CCharListItem:OnDestroy()
    g_App.m_EventDispatcher:RemoveEventListener( "AddFollowee", "OnAddFollowee", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveFollowee", "OnRemoveFollowee", self );
    g_App.m_EventDispatcher:RemoveEventListener( "AddBlacklist", "OnAddBlacklist", self );
    g_App.m_EventDispatcher:RemoveEventListener( "RemoveBlacklist", "OnRemoveBlacklist", self );
	CGWnd.OnDestroy( self );
end

local tblLadder = {
	[eLL_Bronze + 1] = 1;
	[eLL_Siler + 1] = 2;
	[eLL_Gold2 + 1] = 3;
	[eLL_Gold1 + 1] = 3;
	[eLL_Platinum2 + 1] = 4;
	[eLL_Platinum1 + 1] = 4;
	[eLL_Diamond3 + 1] = 5;
	[eLL_Diamond2 + 1] = 5;
	[eLL_Diamond1 + 1] = 5;
	[eLL_Master3 + 1] = 6;
	[eLL_Master2 + 1] = 6;
	[eLL_Master1 + 1] = 6;
	[eLL_King3 + 1] = 7;
	[eLL_King2 + 1] = 7;
	[eLL_King1 + 1] = 7;
	[eLL_Legend + 1] = 8;
}

function CCharListItem:Set( item )
    self.item = item;
    self.m_pName:SetWndText( item.szCharName );
    CHeadIconConfig:Inst():SetIcon( self.m_pHead, item.nCurHeadIcon + 1, item.nAccountID );
    if( self.m_pID ~= nil ) then
        self.m_pID:SetWndText( item.szAccountID );
    end
    
    if self.m_pLevelText ~= nil then
        self.m_pLevelText:SetWndText( CStarLevelConfig:Inst():GetName( item.nCurLadderStar ) );
        local nLevel = CStarLevelConfig:Inst():GetLevel( item.nCurLadderStar );
        nLevel = tblLadder[nLevel];

        for j = 1, 8, 1 do
            self.m_pLevelIcons[j]:ShowWnd( j == nLevel );
        end
    end
	
    if self.m_bInSearchList then
        if CFriendMgr:Inst():IsBlacklist( item.nAccountID ) then
            self.m_pBlacklist:ShowWnd( true );
            self.m_pBtn:ShowWnd( false );
            self.m_pBtn1:ShowWnd( false );
        else
            self.m_pBlacklist:ShowWnd( false );
            self.m_pBtn:ShowWnd( true );
            self.m_pBtn1:ShowWnd( true );
            if CFriendMgr:Inst():IsFollowee( item.nAccountID ) then
                self.m_pBtn:SetWndText( CStringConfig.Inst():GetString( "yichu" ) );
            else
                self.m_pBtn:SetWndText( CStringConfig.Inst():GetString( "guanzhu" ) );
            end
        end        
    else
        if( item.nState ~= 0 ) then
            self.m_pState:SetWndText( CStringConfig.Inst():GetString( "online" ) );
        else
            self.m_pState:SetWndText( CStringConfig.Inst():GetString( "offline" ) );
        end
        self.m_pBtn:ShowWnd( CFriendMgr:Inst():IsBlacklist( item.nAccountID ) );
    end
end

function CCharListItem:OnAddFollowee( Event )
    if Event.nAccountID == self.item.nAccountID then
        self:Set( self.item );
    end
end

function CCharListItem:OnRemoveFollowee( Event )
    if Event.nAccountID == self.item.nAccountID then
        self:Set( self.item );
    end
end

function CCharListItem:OnAddBlacklist( Event )
    if Event.nAccountID == self.item.nAccountID then
        self:Set( self.item );
    end
end

function CCharListItem:OnRemoveBlacklist( Event )
    if Event.nAccountID == self.item.nAccountID then
        self:Set( self.item );
    end
end

function CCharListItem:OnBtn()
    if g_App.m_WorldConnect == nil then
        return;
    end
    local item = self.item;
    if self.m_bInSearchList then
        if not CFriendMgr:Inst():IsFollowee( item.nAccountID ) then
	        local NetMsg = CAddFollowee:new();
            NetMsg.nAccountID = item.nAccountID;
	        g_App.m_WorldConnect:SendShellMsg( NetMsg );
        else
	        local NetMsg = CRemoveFollowee:new();
            NetMsg.nAccountID = item.nAccountID;
            g_App:GetGameStart().m_pCharListTip:Show( 0, NetMsg );
        end
    else
        if CFriendMgr:Inst():IsBlacklist( item.nAccountID ) then
	        local NetMsg = CRemoveBlacklist:new();
            NetMsg.nAccountID = item.nAccountID;
            g_App:GetGameStart().m_pCharListTip:Show( 2, NetMsg );
        else
	        local NetMsg = CJoinGame:new();
            NetMsg.nAccountID = item.nAccountID;
            NetMsg.nTeamID = 0;
	        g_App:SendShellMsg( NetMsg );
        end
    end
end

function CCharListItem:OnBtn1()
    if g_App.m_WorldConnect == nil then
        return;
    end
    local item = self.item;
    if self.m_bInSearchList then
        if not CFriendMgr:Inst():IsBlacklist( item.nAccountID ) then
	        local NetMsg = CAddBlacklist:new();
            NetMsg.nAccountID = item.nAccountID;
            g_App:GetGameStart().m_pCharListTip:Show( 1, NetMsg );
        else
	        local NetMsg = CRemoveBlacklist:new();
            NetMsg.nAccountID = item.nAccountID;
            g_App:GetGameStart().m_pCharListTip:Show( 2, NetMsg );
        end
    else
        if not CFriendMgr:Inst():IsBlacklist( item.nAccountID ) then
            local opr;
            if self.nList == 1 or self.nList == 3 then
                opr = g_App:GetGameStart().m_pCharListOpr1;
            else
                opr = g_App:GetGameStart().m_pCharListOpr;
            end
            opr:Show( item.nAccountID );
            opr:SetGlobalX( self:GetGlobalX() + self:GetWndWidth() - opr:GetWndWidth() );
            opr:SetGlobalY( self:GetGlobalY() );
        end
    end
end

function CCharListItem:OnShowInfo()	
	g_App:ShowPlayerInfo( self.item.nAccountID );
end

--endregion
