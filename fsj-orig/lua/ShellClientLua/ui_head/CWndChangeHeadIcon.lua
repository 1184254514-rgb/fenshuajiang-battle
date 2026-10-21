CChangeHeadIconItem = class( CGCheckButton );

function CChangeHeadIconItem:OnCreated()
    self:AddActionListener( "OnClick", self );
end

function CChangeHeadIconItem:OnClick()
	local NetMsg = CChangeHeadIcon:new();
    NetMsg.m_nIndex = self.nIcon - 1;
	g_App.m_WorldConnect:SendShellMsg( NetMsg );
end



function CWndChangeHeadIcon:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndChangeHeadIcon:OnCreated()
	self.m_pList1 = self:GetDlgChild( "list1" );
	self.m_pList2 = self:GetDlgChild( "list2" );
	self.m_pList3 = self:GetDlgChild( "list3" );
	self.m_pBtnClose = self:GetDlgChild( "close" );
	self.m_pBtnUploadHeadIcon = self:GetDlgChild( "btn_shangchuan" );
	self.m_pBtnClose:AddActionListener( "OnClose", self );
	self.m_pBtnUploadHeadIcon:AddActionListener( "OnClickUploadHeadIcon", self  );
	self.m_pwndCutPicture = CWndCutPicture:new( "gui/cfg/fsj_shangchuantupian.gui", self, 2 );
	self.m_pList1:SetInertiaType( eInertiaType_HScroll );
	self.m_pList2:SetInertiaType( eInertiaType_HScroll );
	self.m_pList3:SetInertiaType( eInertiaType_HScroll );
end

function CWndChangeHeadIcon:OnDestroy()
	self.m_pPictureData = nil;
end

function CWndChangeHeadIcon:OnClose()
	self:ShowWnd( false );
end

function CWndChangeHeadIcon:OnWndShow( bShow )
    if bShow then
        self:Refresh();
    end
end

function CWndChangeHeadIcon:OnClickUploadHeadIcon()
	if not g_App:IsGameSwitch( eGameSwitch_Picture ) then
		g_App:HideMsg( g_App:GetString( "gongnengtips" ) );
	else
		self.m_pPictureData = self.m_pPictureData or CPicture:new();
		self.m_pPictureData:LoadPicture( ePhotoSize );
		if not self.m_tickCheckPicture then
			self.m_tickCheckPicture = CTick:new( "OnCheckPictureLoaded", self );
		end
		self.m_tickCheckPicture:Start( 100 );
	end
end

function CWndChangeHeadIcon:OnCheckPictureLoaded()
	if self.m_pPictureData:GetShowTexture() then
		self.m_tickCheckPicture:Stop();
		self.m_pwndCutPicture:ShowWndWithType( ePictureType_Photo );
	end
end

function CWndChangeHeadIcon:Refresh()
    self.m_pList1:DeleteAllItem();
    self.m_pList1:DeleteAllColumn();
    self.m_pList2:DeleteAllItem();
    self.m_pList2:DeleteAllColumn();
	self.m_pList3:DeleteAllItem();
	self.m_pList3:DeleteAllColumn();

    local i1 = 0;
    local i2 = 0;
    local tbl1 = {};
    local tbl2 = {};   
	for nId, Info in pairs( CHeadIconConfig:Inst().cfg ) do
		local bEnabled = false;
        for j = 0, g_App:GetMainPlayerData().m_HaveEquip:GetDataCount() - 1, 1 do
            if g_App:GetMainPlayerData().m_HaveEquip:GetData( j ) == nId then
                bEnabled = true;
                break;
            end
        end
            
        if bEnabled then
            table.insert( tbl1, nId );
        else
            table.insert( tbl2, nId );
        end
	end
	table.sort( tbl1, function( a, b ) return a < b; end );
	table.sort( tbl2, function( a, b ) return a < b; end );
        
    for i = self.m_pList1:GetColumnCount() + 1, #tbl1, 1 do
        self.m_pList1:InsertColumn( -1, 125 );
    end
    for i = self.m_pList2:GetColumnCount() + 1, #tbl2, 1 do
        self.m_pList2:InsertColumn( -1, 125 );
    end
	for i = 1, ePhoto_Max_Count_VIP do
		self.m_pList3:InsertColumn( -1, 125 );
	end

    self.m_pList1:InsertRowItemsFromRes( 0, "gui/cfg/fsj_zhujuexinxi_touxiangxiugai_item.gui", CChangeHeadIconItem, function ( ctrl, nItem, nCol )
        local listItem = ctrl:GetSubItemByIndex( nCol );
        local icon = tbl1[nCol + 1];
        listItem.nIcon = icon;
        listItem:SetCheck( g_App:GetMainPlayerData().m_CharBaseData:GetCurHeadIcon() == icon - 1 );
        CHeadIconConfig:Inst():SetIcon( listItem, icon );
    end, nil, nil );
    self.m_pList1:SetItemHeight( self.m_pList1:GetWndHeight() );
            
    self.m_pList2:InsertRowItemsFromRes( 0, "gui/cfg/fsj_zhujuexinxi_touxiangxiugai_item2.gui", CGWnd, function ( ctrl, nItem, nCol )
        local listItem = ctrl:GetSubItemByIndex( nCol );
        local icon = tbl2[nCol + 1];
        listItem:AddEventListener( GM_WM_MOUSECLICK, function()
			if icon < 1000 then
				g_App:HideMsg( string.format( CStringConfig.Inst():GetString( "xiugaitouxiang" ), g_tblTabFile.equip[icon].dName ) );
			else
				g_App:HideMsg( string.format( CStringConfig.Inst():GetString( "hechengtouxiangtishi" ), g_tblTabFile.fusion[icon].dName ) );
			end
        end, nil );
        CHeadIconConfig:Inst():SetIcon( listItem, icon );
    end, nil, nil );
    self.m_pList2:SetItemHeight( self.m_pList2:GetWndHeight() );

	self.m_pList3:InsertRowItemsFromRes( -1, "gui/cfg/fsj_zhujuexinxi_touxiangxiugai_zdy.gui", CHeadImage );
	self.m_pList3:AddEventListener( GM_WM_ITEM_ALLLOADED, "OnImgItemLoaded", self );
end

function CWndChangeHeadIcon:OnImgItemLoaded()
	self.m_pList3:RemoveEventListener( GM_WM_ITEM_ALLLOADED, "OnImgItemLoaded", self );
	local nItem = self.m_pList3:GetItemCount();
	local nCol  = self.m_pList3:GetColumnCount();
	for i = 0, nItem - 1 do
		for j = 0, nCol - 1 do
			local listItem = self.m_pList3:GetSubItem( i, j )
			local nindex = i * ePhoto_Max_Count_VIP + j;
			listItem:LoadHeadImg( nindex );
		end 
	end
	local NetMsg = CQueryPictureData:new();
	g_App:SendShellMsg( NetMsg );
end


----------------------------------------------------------------
----------------------------CHeadImage--------------------------
----------------------------------------------------------------

function CHeadImage:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CHeadImage:OnCreated()
	self.m_HeadImg = self:GetDlgChild( "touxiang" );
	self.m_WndTips = self:GetDlgChild( "tips" );
	self:AddClickListener( "OnClick", self );
	self.m_PublicPhotoLoadListener = IResListener:new();
	self.m_PublicPhotoLoadListener.m_Wnd = self;
	self.m_PublicPhotoLoadListener.OnLoadedEnd = function( this, szFileName, pBuffer, nSize )
		if this.m_Wnd.OnPublicPhotoLoadedEnd then
			this.m_Wnd:OnPublicPhotoLoadedEnd( this, szFileName, pBuffer, nSize );
		end
	end
	self.m_PrivatePhotoLoadListener = IResListener:new();
	self.m_PrivatePhotoLoadListener.m_Wnd = self;
	self.m_PrivatePhotoLoadListener.OnLoadedEnd = function( this, szFileName, pBuffer, nSize )
		if this.m_Wnd.OnPrivatePhotoLoadedEnd then
			this.m_Wnd:OnPrivatePhotoLoadedEnd( this, szFileName, pBuffer, nSize );
		end
	end

	g_App.m_EventDispatcher:AddEventListener( "AnswerPictureData", "RefreshPictureStatus", self );
end

function CHeadImage:OnDestroy()
	self.m_PrivatePhotoLoadListener = GetGammaFileMgr():RemoveListener( self.m_PublicPhotoLoadListener );
	self.m_PublicPhotoLoadListener = GetGammaFileMgr():RemoveListener( self.m_PrivatePhotoLoadListener );
	g_App.m_EventDispatcher:RemoveEventListener( "AnswerPictureData", "RefreshPictureStatus", self );
end

function CHeadImage:OnClick()
	if not self.m_nHeadIconID then return end;
	local NetMsg = CChangeHeadIcon:new();
    NetMsg.m_nIndex = self.m_nHeadIconID;
	g_App.m_WorldConnect:SendShellMsg( NetMsg );
end

function CHeadImage:LoadHeadImg( nCol )
	self.m_nPictureIndex = nCol;
	self.m_nHeadIconID = eHeadIconImg_Begin_ID + nCol;

	local szPictureLoadPath = g_App:GetImgCDN() .. "uploads/user_image/" .. g_App:GetServerID() .. "/";
	local szPhotoLoadPath = szPictureLoadPath .. "public/" .. g_App:GetAccountID() .. "/Photo_" .. nCol .. ".jpg";	--先下载已审核图片   
	GetGammaFileMgr():Load( szPhotoLoadPath, true, false, self.m_PublicPhotoLoadListener );
end

function CHeadImage:OnPublicPhotoLoadedEnd( this, szFileName, pBuffer, nSize )
	if nSize == 0 then
		self:GetParent():SetSubItemVisible( false, 0, self.m_nPictureIndex );
		self:GetParent():SetColumnWidth( self.m_nPictureIndex, 0 );
		local szPictureLoadPath = g_App:GetImgCDN() .. "uploads/user_image/" .. g_App:GetServerID() .. "/";
		local szPhotoNotCheckPath = szPictureLoadPath .. "private/" .. g_App:GetPictureKey() .. "/Photo_" .. self.m_nPictureIndex .. ".jpg";
		GetGammaFileMgr():Load( szPhotoNotCheckPath, true, false, self.m_PrivatePhotoLoadListener );
		return;
	end
	self:DecodePictureDataAndShowWnd( pBuffer, nSize );
end

function CHeadImage:OnPrivatePhotoLoadedEnd( this, szFileName, pBuffer, nSize )
	if nSize == 0 then
		return
	end
	self:DecodePictureDataAndShowWnd( pBuffer, nSize );
end

function CHeadImage:DecodePictureDataAndShowWnd( pBuffer, nSize )
	self:GetParent():SetSubItemVisible( true, 0, self.m_nPictureIndex );
	self:GetParent():SetColumnWidth( self.m_nPictureIndex, 125 );
	local Renderer = g_App:GetRenderer();
	local Texture = Renderer:GetGraphic():CreateTexture( ePhotoSize, ePhotoSize, 0, eTF_ARGB32, 1, true );
	local nColorSize = ePhotoSize * ePhotoSize * 4;
	local ColorData = CBufferStream:new( nColorSize );
	local JpegDecoder = CImageDecoder.GetDecoder( "jpg" );
	local bSuccess = JpegDecoder:FillToARGB32( pBuffer, nSize, ColorData, nColorSize );
	Texture:FillFromMemory( ColorData, eTF_ARGB32, nil, 0 );
	local rtImg = CFRect:new( 0, 0, ePhotoSize, ePhotoSize );
	local rtWnd = CFRect:new( 0, 0, self.m_HeadImg:GetWndWidth(), self.m_HeadImg:GetWndHeight() );
	local nFlag = BitOr( IDF_ZOOM_WHILE_SCALE, IDF_ENABLE_ALPHA_BLEND )
	for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
		self.m_HeadImg:ClearWndBkImage( GSM_BS_BK, i )
		self.m_HeadImg:AddImageByTexture( GSM_BS_BK, i, 0, Texture, rtImg,
			rtWnd, 0xffffffff, LOCK_ALL, nFlag, -1, -1, 0, 1, 0 );
	end
end

function CHeadImage:RefreshPictureStatus( Event )
	if Event.m_tblPictureStatus[self.m_nPictureIndex] then
		if Event.m_tblPictureStatus[self.m_nPictureIndex].nStatus == 0 then
			self.m_WndTips:SetWndText( g_App:GetString( "zhaopianweishenhe" ) );
		elseif Event.m_tblPictureStatus[self.m_nPictureIndex].nStatus == 2 then
			self.m_WndTips:SetWndText( g_App:GetString( "shenheweitongguo" ) );
		end
	end		
end
