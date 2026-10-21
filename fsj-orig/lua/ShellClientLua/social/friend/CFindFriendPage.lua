--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

function CFindFriendPage:Ctor( szResName, wndParent, nLoadType )
	CGWnd.Ctor( self, szResName, wndParent, nLoadType );
end

function CFindFriendPage:OnCreated()
    self.m_pList = self:GetDlgChild( "list" );
    self.m_pPage = self:GetDlgChild( "next" ):GetDlgChild( "yeshu" );
    self.m_pBtnLeft = self:GetDlgChild( "next" ):GetDlgChild( "b_zuo" );
    self.m_pBtnRight = self:GetDlgChild( "next" ):GetDlgChild( "b_you" );
    self.m_pBtnSearch = self:GetDlgChild( "yonghuchazhao" ):GetDlgChild( "b_sousuo" );
    self.m_pSearchName = self:GetDlgChild( "yonghuchazhao" ):GetDlgChild( "w_yonghu" );
    self.m_pSearchNameBg = self:GetDlgChild( "yonghuchazhao" ):GetDlgChild( "bg_shuoming" );
    self.m_pSearchName:AddEventListener( GM_WM_STATE_CHANGED, "OnTextChanged", self );
    self.m_pSearchName:AddEventListener( WM_SETFOCUS, "OnTextChanged", self );
    self.m_pSearchName:AddEventListener( WM_KILLFOCUS, "OnTextChanged", self );
    self.m_pSearchTip = self:GetDlgChild( "yonghuchazhao" ):GetDlgChild( "bg_shuoming" );
    self.m_pBtnSearchClear = self:GetDlgChild( "yonghuchazhao" ):GetDlgChild( "close" );
    self.m_pBtnSearchClear:AddActionListener( "OnSearchClear", self );
    self.m_pBtnSearchClear:ShowWnd( false );
    self.m_pNoPlayer = self:GetDlgChild( "w_gonggao" );

    self.m_pSaoyisao = self:GetDlgChild( "b_saoyisao" );
    self.m_pYaoyiyao = self:GetDlgChild( "b_yaoyiyao" );
    self.m_pWxyaoqing = self:GetDlgChild( "b_wxyaoqing" );
    self.m_pQqyaoqing = self:GetDlgChild( "b_qqyaoqing" );
    self.m_pFujin = self:GetDlgChild( "b_fujin" );
    self.m_pSaoyisao:EnableWnd( false );
    self.m_pYaoyiyao:EnableWnd( false );
    self.m_pFujin:EnableWnd( false );
    
	self.m_pBtnSearch:AddActionListener( "OnSearch", self );
	self.m_pBtnLeft:AddActionListener( "OnLeft", self );
	self.m_pBtnRight:AddActionListener( "OnRight", self );

	self.m_pWxyaoqing:AddActionListener( "OnWxyaoqing", self );
	self.m_pQqyaoqing:AddActionListener( "OnQqyaoqing", self );

    self.m_nPage = 0;
    self:Refresh();
end

function CFindFriendPage:OnDestroy()
end

function CFindFriendPage:OnWndShow( bShow )
	if not bShow then
		return;
	end
	self:RefreshQrcode();
end

function CFindFriendPage:OnSearch()
    if g_App.m_WorldConnect == nil then
        return;
    end
	local NetMsg = CSearchPlayers:new();
    NetMsg.szName = self.m_pSearchName:GetWndText();
	g_App.m_WorldConnect:SendShellMsg( NetMsg );
    g_App:WaitMsg( true, 1500 );
end

function CFindFriendPage:OnSearchClear()
    self.m_tblItems = nil;
    self.m_pSearchName:SetWndText( "" );
    self.m_pSearchNameBg:ShowWnd( true );
    self:Refresh();
end

function CFindFriendPage:OnLeft()
    self.m_nPage = math.max( math.min( self.m_nPage - 1, math.ceil( self.m_nTotalCount / 4 ) - 1 ), 0 );
    self:Refresh();
end

function CFindFriendPage:OnRight()
    self.m_nPage = math.max( math.min( self.m_nPage + 1, math.ceil( self.m_nTotalCount / 4 ) - 1 ), 0 );
    self:Refresh();
end

function CFindFriendPage:OnWxyaoqing()
	if not g_App:IsGameSwitch( eGameSwitch_Share ) then
		return g_App:HideMsg( g_App:GetString( "fenxiangweikaiqi" ) );
	end
	g_App:CreatePageShare( g_App:GetString( "haoyouchazhaojiemian" ) ):ShareWeiXin();
end

function CFindFriendPage:OnQqyaoqing()
	if not g_App:IsGameSwitch( eGameSwitch_Share ) then
		return g_App:HideMsg( g_App:GetString( "fenxiangweikaiqi" ) );
	end
	g_App:CreatePageShare( g_App:GetString( "haoyouchazhaojiemian" ) ):ShareQQ();
end

function CFindFriendPage:Refresh()
    self.m_pList:DeleteAllItem();

    if self.m_tblItems ~= nil then
        self.m_pList:ShowWnd( true );
        self.m_pPage:ShowWnd( true );
        self.m_pSaoyisao:ShowWnd( false );
        self.m_pYaoyiyao:ShowWnd( false );
        self.m_pWxyaoqing:ShowWnd( false );
        self.m_pQqyaoqing:ShowWnd( false );
        self.m_pFujin:ShowWnd( false );

        local nCount = self.m_nTotalCount - self.m_nPage * 4;
        nCount = math.min( 4, nCount );
    
        if self.m_nTotalCount ~= 0 then
            self.m_pPage:SetWndText( ( self.m_nPage + 1 ) .. " / " .. math.ceil( self.m_nTotalCount / 4 ) );
            self.m_pBtnLeft:ShowWnd( self.m_nPage > 0 );
            self.m_pBtnRight:ShowWnd( self.m_nPage < math.ceil( self.m_nTotalCount / 4 ) - 1 );
            self.m_pNoPlayer:ShowWnd( false );
        else
            self.m_pBtnLeft:ShowWnd( false );
            self.m_pBtnRight:ShowWnd( false );
            self.m_pNoPlayer:ShowWnd( true );
            self.m_pPage:SetWndText( "0 / 0" );
        end
        for i = 0, nCount - 1, 1 do
            local item = self.m_tblItems[self.m_nPage * 4 + i];
            self.m_pList:InsertRowItemsFromRes( i, "gui/cfg/fsj_haoyou_chazhao2_item.gui", CCharListItem, function ( ctrl, nItem, nCol )
                local listItem = ctrl:GetSubItemByIndex( nItem );
                listItem:Set( item );
            end, nil, nil );
        end
    else
        self.m_pList:ShowWnd( false );
        self.m_pPage:ShowWnd( false );
        self.m_pBtnLeft:ShowWnd( false );
        self.m_pBtnRight:ShowWnd( false );
        self.m_pNoPlayer:ShowWnd( false );
        self.m_pSaoyisao:ShowWnd( true );
        self.m_pYaoyiyao:ShowWnd( true );
        self.m_pWxyaoqing:ShowWnd( true );
        self.m_pQqyaoqing:ShowWnd( true );
        self.m_pFujin:ShowWnd( true );
    end
end

function CFindFriendPage:OnTextChanged()
    self.m_pSearchNameBg:ShowWnd( self.m_pSearchName:GetWndText() == "" and not self.m_pSearchName:IsFocus() );
    self.m_pBtnSearchClear:ShowWnd( self.m_pSearchName:GetWndText() ~= "" );
end

function CFindFriendPage:OnResult( tblItems, nCount )
    self.m_tblItems = tblItems;
    self.m_nTotalCount = nCount;
    self.m_nPage = 0;
    self:Refresh();
end

function CFindFriendPage:RefreshQrcode()
	local szShareUrl = g_App:GetSharePageUrl();
	if string.len( szShareUrl ) == 0 then
		return;
	end

	local pBuffer = CBufferStream:new( 1024 * 1024 / 8 + 512 );
	local nSize = g_App:Qrcode( szShareUrl, pBuffer, 256 );
	if nSize == 0 then
		return;
	end

	local pQrcodeWnd = self:GetDlgChild( "erweima.erweima" );
	local rtWnd = CFRect:new();
	rtWnd:right( pQrcodeWnd:GetWndWidth() );
	rtWnd:bottom( pQrcodeWnd:GetWndHeight() );
	local rt  = CFRect:new( 0, 0, 335, 335 );
	pQrcodeWnd:ClearWndBkImage( GSM_BS_BK, eST_ENABLE );
	pQrcodeWnd:AddImage( GSM_BS_BK, eST_ENABLE, 0, pBuffer:ReadUTFBytes( 256 ), rt, 
		rtWnd, 0xffffffff, LOCK_ZALL, IDF_ZOOM_WHILE_SCALE, -1, -1, 0, 1, 0 ); 
end

--endregion
