--region CPictureLoadToWnd.lua
--Date 2018.03.22 

function CPictureLoadToWnd:Ctor()
	self.m_LoadListener = IResListener:new();
	self.m_LoadListener.m_Handler = self;
	self.m_LoadListener.OnLoadedEnd = function( this, szFileName, pBuffer, nSize )
		this.m_Handler:OnPictureLoadedEnd( this, szFileName, pBuffer, nSize );
	end
	self.m_tblPictureSize = {};
	self.m_tblTargetWnd = {};
end

function CPictureLoadToWnd:Destroy()
	self.m_LoadListener = nil;
	self.m_tblPictureSize = nil;
	self.m_tblTargetWnd = nil;
end

function CPictureLoadToWnd:Inst()
	if not self.m_Inst then
		self.m_Inst = CPictureLoadToWnd:new();
	end
	return self.m_Inst;
end

function CPictureLoadToWnd:LoadPicture( szFileName, WndTarget, nPictureSize )
	if not self.m_tblPictureSize[szFileName] then
		self.m_tblPictureSize[szFileName] = nPictureSize;
	end
	if not self.m_tblTargetWnd[szFileName] then
		self.m_tblTargetWnd[szFileName] = {};
	end
	table.insert( self.m_tblTargetWnd[szFileName], WndTarget );
	GetGammaFileMgr():Load( szFileName, true, false, self.m_LoadListener );
end

function CPictureLoadToWnd:OnPictureLoadedEnd( this, szFileName, pBuffer, nSize )
	if nSize == 0 or not self.m_tblPictureSize[szFileName] 
		or not self.m_tblTargetWnd[szFileName] or #self.m_tblTargetWnd[szFileName] == 0 then
			return
	end

	local nPictureSize = self.m_tblPictureSize[szFileName];
	local Renderer = g_App:GetRenderer();
	local Texture = Renderer:GetGraphic():CreateTexture( nPictureSize, nPictureSize, 0, eTF_ARGB32, 1, true );
	local nColorSize = nPictureSize * nPictureSize * 4;
	local ColorData = CBufferStream:new( nColorSize );
	local JpegDecoder = CImageDecoder.GetDecoder( "jpg" );
	local bSuccess = JpegDecoder:FillToARGB32( pBuffer, nSize, ColorData, nColorSize );
	Texture:FillFromMemory( ColorData, eTF_ARGB32, nil, 0 );
	local tblWndTarget = self.m_tblTargetWnd[szFileName];
	for i = 1, #tblWndTarget do
		local WndTarget = tblWndTarget[i];
		local rtImg = CFRect:new( 0, 0, nPictureSize, nPictureSize );
		local rtWnd = CFRect:new( 0, 0, WndTarget:GetWndWidth(), WndTarget:GetWndHeight() );
		local nFlag = BitOr( IDF_ZOOM_WHILE_SCALE, IDF_ENABLE_ALPHA_BLEND )
		for i = eST_ENABLE, eST_UNCHECK_CLICKDOWN, 1 do
			WndTarget:ClearWndBkImage( GSM_BS_BK, i )
			WndTarget:AddImageByTexture( GSM_BS_BK, i, 0, Texture, rtImg,
				rtWnd, 0xffffffff, LOCK_ALL, nFlag, -1, -1, 0, 1, 0 );
		end
	end
	self.m_tblTargetWnd[szFileName] = {};
end


--endregion
