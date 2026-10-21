
CObservePlayerItem = class( CGButton );

function CObservePlayerItem:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CObservePlayerItem:OnCreated()
    self.m_pHead = self:GetDlgChild( "head.touxiang" );
    self.m_pName = self:GetDlgChild( "name" );
    self.m_pSkill = self:GetDlgChild( "jineng.name" );
    self.m_pLevel = self:GetDlgChild( "experience.level" );
    self.m_pKill = self:GetDlgChild( "kill.number" );
    self.m_pDeath = self:GetDlgChild( "death.number" );
    self:AddActionListener( "OnClick", self );
end

function CObservePlayerItem:Refresh( nAccountID )
    self.m_nAccountID = nAccountID;
    local pScene = g_App:GetScene();
    if pScene == nil then
        return;
    end
    local pPlayer = pScene:GetPlayerByAccountID( nAccountID );
    if pPlayer == nil then
        return;
    end
    CHeadIconConfig:Inst():SetIcon( self.m_pHead, pPlayer:GetHeadIconID() + 1, nAccountID );
    self.m_pName:SetWndText( pPlayer:GetNickName() );
    if pScene:GetRoomType() == eRT_Team then
        self.m_pSkill:SetWndText( g_tblTabFile.skill[pPlayer:GetSkillID()].sName );
    else
        self.m_pSkill:SetWndText( "" );
    end
    self.m_pLevel:SetWndText( tostring( pPlayer:GetSimple32Property( eSPT32_Level ) ) );
    self.m_pKill:SetWndText( tostring( pPlayer:GetSimple32Property( eSPT32_KillCount ) ) );
    self.m_pDeath:SetWndText( tostring( pPlayer:GetSimple32Property( eSPT32_DeathCount ) ) );
    
    local color = g_App:GetManorColor( pPlayer:GetManor():GetColorID() );
    for i = eST_ENABLE, eST_CLICKDOWN, 1 do
	    self:SetBackgroundColor( GSM_BS_BK, i, color );
    end
end

function CObservePlayerItem:OnClick()
    local pScene = g_App:GetScene();
    if pScene == nil then
        return;
    end
    pScene:ChangeObservedPlayer( self.m_nAccountID );
end


function CObserveWnd:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CObserveWnd:OnCreated()
    self.m_pObserverCount = self:GetDlgChild( "guanzhanzhe.renshu" );
    self.m_pObserverName = self:GetDlgChild( "guanzhanzhe.name" );
    self.m_pMusic = self:GetDlgChild( "yinyue.name" );
    self.m_pPlayerListOpen = self:GetDlgChild( "liebiao.open" );
    self.m_pPlayerListClose = self:GetDlgChild( "liebiao.close" );
    self.m_pPlayerList = self:GetDlgChild( "liebiao.close.list" );
    self.m_pPlayerListClose:ShowWnd( false );
    self.m_tblPlayerItems = {};
    
    self:GetDlgChild( "liebiao.open" ):AddActionListener( "OnShowPlayerList" , self );
    self:GetDlgChild( "liebiao.close.close" ):AddActionListener( "OnHidePlayerList" , self );
    self:GetDlgChild( "dianzan" ):AddActionListener( "OnDianzan" , self );
    self:GetDlgChild( "shijiao" ):AddActionListener( "OnChangeView" , self );
    self:GetDlgChild( "tuichuguanzhan" ):AddActionListener( "OnExitScene" , self );
end

function CObserveWnd:SetObserverCount( nCount, szName )
    self.m_pObserverCount:SetWndText( tostring( nCount ) );
    self.m_pObserverName:SetWndText( szName );
end

function CObserveWnd:SetMusicID( nID )
    local szMusicName = CMusicConfig:Inst():GetMusicName( nID );
    self.m_pMusic:SetWndText( szMusicName );
end

function CObserveWnd:RefreshPlayers()
    if not self.m_pPlayerListClose:IsShow() then
        return;
    end
    local allPlayers = g_App:GetScene():GetPlayerList();
    self.m_pPlayerList:DeleteAllItem();
    local i = 0;
    for k, v in pairs( allPlayers ) do
        self.m_pPlayerList:InsertRowItemsFromRes( i, "gui/cfg/fsj_guanzhan_item.gui", CObservePlayerItem, function ( ctrl, nItem, nCol )
            local listItem = ctrl:GetSubItemByIndex( nItem );
            listItem:Refresh( v );
        end, nil, nil );
        i = i + 1;
    end
end

function CObserveWnd:RefreshPlayer( nAccountID )
    if not self.m_pPlayerListClose:IsShow() then
        return;
    end

    for i = 0, self.m_pPlayerList:GetItemCount() - 1, 1 do
        local item = self.m_pPlayerList:GetSubItemByIndex( i );
        if item.m_nAccountID == nAccountID then
            item:Refresh( nAccountID );
            return;
        end
    end

    self:RefreshPlayers();
end

function CObserveWnd:OnShowPlayerList()
    self.m_pPlayerListOpen:ShowWnd( false );
    self.m_pPlayerListClose:ShowWnd( true );
    self:RefreshPlayers();
end

function CObserveWnd:OnHidePlayerList()
    self.m_pPlayerListOpen:ShowWnd( true );
    self.m_pPlayerListClose:ShowWnd( false );
end

function CObserveWnd:OnDianzan()
    local pScene = g_App:GetScene();
    if pScene then
        pScene:AddCommend();
    end
end

function CObserveWnd:OnChangeView()
	local pScene = g_App:GetScene();
    if pScene then
        pScene:ChangeView();
    end
end

function CObserveWnd:OnExitScene()
	g_App:MessageBox( g_App:GetString( "tuichuguanzhantips" ),{
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
					pField:ShellCmdClose();
				end

				g_App:SwitchStart();
			end
		end;
	} );
end