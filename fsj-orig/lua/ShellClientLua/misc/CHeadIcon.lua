CHeadIconConfig = class();

function CHeadIconConfig:Ctor()
	self.m_tblIcon	= {};	
end

function CHeadIconConfig:Inst()
	if not self.m_Inst then
		self.m_Inst = CHeadIconConfig:new();
	end

	return self.m_Inst;
end

function CHeadIconConfig:Destroy()
	local LoadMgr = GetGammaFileMgr()
	for k, v in pairs( self.m_tblIcon ) do
		if v.m_PublicLoadListener then
			LoadMgr:RemoveListener( v.m_PublicLoadListener );
		end
		if v.m_PrivateLoadListener then
			LoadMgr:RemoveListener( v.m_PrivateLoadListener );
		end
	end 
end

function CHeadIconConfig:LoadConfigFile( szFilePath, bSync )
	LoadConfigFile( szFilePath .. "icon.txt", self, "OnConfigFileLoaded", bSync );
end

function CHeadIconConfig:OnConfigFileLoaded( pBuffer, nSize, szFileName )
    self.cfg = {};
    self.nCount = 0;
	local tabFile = CTabFile:new();
	if tabFile:Init( pBuffer, nSize ) then
		for i = 1,tabFile:GetHeight() - 1 do
			local n = tabFile:GetInteger( i, "cChar", 0 );
            local item = {};
            item.szName = tabFile:GetString( i, "name", "" );
            item.fTop = tabFile:GetFloat( i, "fTop(y)", 0 );
            item.fBottom = tabFile:GetFloat( i, "fBottom", 0 );
            item.fLeft = tabFile:GetFloat( i, "fLeft(x)", 0 );
            item.fRight = tabFile:GetFloat( i, "fRight", 0 );
            self.cfg[n] = item;
            self.nCount = self.nCount + 1;
        end
    end
end

function CHeadIconConfig:SetIcon( pIcon, i, nAccountID )
	if i < eHeadIconImg_Begin_ID then
		local cfgItem = self.cfg[i];
		if cfgItem == nil then
		    return;
		end		
		local rtImg = CFRect:new( cfgItem.fLeft, cfgItem.fTop, cfgItem.fRight, cfgItem.fBottom );
		local rtWnd = CFRect:new();
		rtWnd:right( pIcon:GetWndWidth() );
		rtWnd:bottom( pIcon:GetWndHeight() );

		pIcon:RestoreImageFromCreateParam();
		for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
		    pIcon:AddImage( GSM_BS_BK, i, pIcon:GetImageCount( GSM_BS_BK, i ), g_App:GetDataPath() .. "gui/tex/fs_jm003.tex", 
			    rtImg, rtWnd, 0xffffffff, LOCK_ALL, IDF_ENABLE_ALPHA_BLEND, -1, -1, 0, 1, 0 );
		end

	else
		local nPhotoIndex = (i-1)%10;
		pIcon.m_nPhotoIndex = nPhotoIndex;
		if not nAccountID then return end;
		if not pIcon.m_PublicLoadListener then
			pIcon.m_PublicLoadListener = IResListener:new();
			pIcon.m_nAccountID = nAccountID;
			pIcon.m_PublicLoadListener.OnLoadedEnd = function ( filelist, szFileName, pBuffer, nSize )
				if nSize > 0 then
					local Renderer = g_App:GetRenderer();
					local Texture = Renderer:GetGraphic():CreateTexture( ePhotoSize, ePhotoSize, 0, eTF_ARGB32, 1, true );
					local nColorSize = ePhotoSize * ePhotoSize * 4;
					local ColorData = CBufferStream:new( nColorSize );
					local JpegDecoder = CImageDecoder.GetDecoder( "jpg" );
					local bSuccess = JpegDecoder:FillToARGB32( pBuffer, nSize, ColorData, nColorSize );
					Texture:FillFromMemory( ColorData, eTF_ARGB32, nil, 0 );
					local rtImg = CFRect:new( 0, 0, ePhotoSize, ePhotoSize );
					local rtWnd = CFRect:new( 0, 0, pIcon:GetWndWidth(), pIcon:GetWndHeight() );
					local nFlag = BitOr( IDF_ZOOM_WHILE_SCALE, IDF_ENABLE_ALPHA_BLEND )
					for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
						pIcon:ClearWndBkImage( GSM_BS_BK, i )
						pIcon:AddImageByTexture( GSM_BS_BK, i, 0, Texture, rtImg,
							rtWnd, 0xffffffff, LOCK_ALL, nFlag, -1, -1, 0, 1, 0 );
					end
				else
					if pIcon.m_nAccountID == g_App:GetAccountID() then
						local szPictureLoadPath = g_App:GetImgCDN() .. "uploads/user_image/" .. g_App:GetServerID() .. "/";
						local szUnCheckPath = szPictureLoadPath .. "private/" .. g_App:GetPictureKey() .. "/Photo_" .. pIcon.m_nPhotoIndex .. ".jpg";
						GetGammaFileMgr():Load( szUnCheckPath, true, false, pIcon.m_PrivateLoadListener );
					else
						self:SetIcon( pIcon, 1 );
					end
				end
			end
		end
		
		if not pIcon.m_PrivateLoadListener then
			pIcon.m_PrivateLoadListener = IResListener:new();
			pIcon.m_PrivateLoadListener.OnLoadedEnd = function ( filelist, szFileName, pBuffer, nSize )
				if nSize > 0 then
					local Renderer = g_App:GetRenderer();
					local Texture = Renderer:GetGraphic():CreateTexture( ePhotoSize, ePhotoSize, 0, eTF_ARGB32, 1, true );
					local nColorSize = ePhotoSize * ePhotoSize * 4;
					local ColorData = CBufferStream:new( nColorSize );
					local JpegDecoder = CImageDecoder.GetDecoder( "jpg" );
					local bSuccess = JpegDecoder:FillToARGB32( pBuffer, nSize, ColorData, nColorSize );
					Texture:FillFromMemory( ColorData, eTF_ARGB32, nil, 0 );
					local rtImg = CFRect:new( 0, 0, ePhotoSize, ePhotoSize );
					local rtWnd = CFRect:new( 0, 0, pIcon:GetWndWidth(), pIcon:GetWndHeight() );
					local nFlag = BitOr( IDF_ZOOM_WHILE_SCALE, IDF_ENABLE_ALPHA_BLEND )
					for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
						pIcon:ClearWndBkImage( GSM_BS_BK, i )
						pIcon:AddImageByTexture( GSM_BS_BK, i, 0, Texture, rtImg,
							rtWnd, 0xffffffff, LOCK_ALL, nFlag, -1, -1, 0, 1, 0 );
					end
				else
					self:SetIcon( pIcon, 1 );
				end		
			end
		end

		local szPictureLoadPath = g_App:GetImgCDN() .. "uploads/user_image/" .. g_App:GetServerID() .. "/";
		local szPhotoLoadPath = szPictureLoadPath .. "public/" .. nAccountID .. "/Photo_" .. nPhotoIndex .. ".jpg";
		GetGammaFileMgr():Load( szPhotoLoadPath, true, false, pIcon.m_PublicLoadListener );

		table.insert( self.m_tblIcon, pIcon );
	end
end