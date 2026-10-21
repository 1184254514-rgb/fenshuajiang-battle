--region CWndLoadMusicTips.lua
--Date 2017.1014 
--音乐下载确认界面

function CWndLoadMusicTips:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndLoadMusicTips:OnCreated()
	self.m_TextMusicSize	= self:GetDlgChild( "daxiao" );
	self.m_WndLoadListen	= self:GetDlgChild( "W_shitingtishi" );
	self.m_WndLoadBuy		= self:GetDlgChild( "W_goumaitishi" );
	self.m_BtnOk			= self:GetDlgChild( "b_ok" );
	self.m_BtnCancel		= self:GetDlgChild( "b_quxiao" );
	
	self.m_BtnOk:AddActionListener( "StartLoadMusic", self );
	self.m_BtnCancel:AddActionListener( "CancelLoadMusic", self );
	
	self.m_WndLoadListen:ShowWnd( false );
	self.m_WndLoadBuy:ShowWnd( false );
	self.m_WndLoadMusicPro = CWndMusicLoadPro:new( "gui/cfg/fsj_yinyuexuanze_tips2.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );	
end

function CWndLoadMusicTips:StartLoadMusic()
	self:ShowWnd( false );
	self.m_WndLoadMusicPro:ShowWnd( true );		
	if not self.m_Listenter then
		self.m_Listenter = IResListener:new();
		self.m_Listenter.OnLoadedEnd = function( listlua, szFileName, pBuffer, nSize )
			self.m_WndLoadMusicPro:LoadMusicComplete( self.m_nLoadType, self.m_nMusicID );
			local szLoadMd5 = CBufferStream:new()
			szLoadMd5:SetDataSize( 32 );
			MD5Ex( szLoadMd5, pBuffer, nSize );
			szLoadMd5 = szLoadMd5:ReadUTFBytes( 32 );
			local szSrcMd5 = string.sub( szFileName, -36, -5 );
			
			if szSrcMd5 == szLoadMd5 then
				local nBegin, nEnd = string.find( szFileName, "netmusic/" );
				if not nBegin or not nEnd then return end
				local szFileName = string.sub( szFileName, nEnd+1 );
				local f = io.open( g_App:GetNetMusicLoadPath() .. szFileName, "w" );
				if not f then return end
				f:write( pBuffer:ReadBytes( nSize) );
				io.close( f );
			end
		end
	end

	for i =1, eMusicCount_BySpeed do
		local nMusicID = math.floor( self.m_nMusicID / 10 ) * 10  + i;
		local bMusicIDExist = CMusicConfig:Inst():IsExistMusicID( nMusicID );
		if bMusicIDExist then
			local szMusicPath = CMusicConfig:Inst():GetMusicPath( nMusicID );
			local szNetPath = g_App:GetNetMusicPath() .. szMusicPath;
			local szFileName = string.sub( szMusicPath, 10 );
			local szPathName = g_App:GetNetMusicLoadPath() .. szFileName;
			if not CPathMgr.IsFileExist( szPathName ) then
				GetGammaFileMgr():Load( szNetPath, true, false, self.m_Listenter );
			end
		end
	end
end

function CWndLoadMusicTips:CancelLoadMusic()
	self:ShowWnd( false );
end

function CWndLoadMusicTips:ShowWndByType( nType, nMusicID, bWifi )
	self.m_nLoadType = nType;
	self.m_nMusicID = nMusicID;

	if bWifi then
		self:LoadMusicWithWifi( nType, nMusicID );
		return
	end

	if nType == eLoadMusicType_Shiting then
		self.m_WndLoadListen:ShowWnd( true );
		self.m_WndLoadBuy:ShowWnd( false );
	elseif nType == eLoadMusicType_Buy then
		self.m_WndLoadListen:ShowWnd( false );
		self.m_WndLoadBuy:ShowWnd( true );
	end

	local fMusicSize = CMusicConfig:Inst():GetMusicSize( nMusicID );
	local szText = self.m_TextMusicSize:GetWndText();
	szText = string.format( szText, fMusicSize );
	self.m_TextMusicSize:SetWndText( szText );

	self:ShowWnd( true );
end

function CWndLoadMusicTips:LoadMusicWithWifi( nType, nMusicID )
	self.m_WndLoadMusicPro:ShowWndWithWifi();
	if not self.m_Listenter then
		self.m_Listenter = IResListener:new();
		self.m_Listenter.OnLoadedEnd = function( listlua, szFileName, pBuffer, nSize )
			self.m_WndLoadMusicPro:LoadMusicComplete( self.m_nLoadType, self.m_nMusicID );
			local szLoadMd5 = CBufferStream:new()
			szLoadMd5:SetDataSize( 32 );
			MD5Ex( szLoadMd5, pBuffer, nSize );
			szLoadMd5 = szLoadMd5:ReadUTFBytes( 32 );
			local szSrcMd5 = string.sub( szFileName, -36, -5 );
			
			if szSrcMd5 == szLoadMd5 then
				local nBegin, nEnd = string.find( szFileName, "netmusic/" );
				if not nBegin or not nEnd then return end
				local szFileName = string.sub( szFileName, nEnd+1 );
				local f = io.open( g_App:GetNetMusicLoadPath() .. szFileName, "w" );
				if not f then return end
				f:write( pBuffer:ReadBytes( nSize ) );
				io.close( f );
			end
		end
	end

	for i =1, eMusicCount_BySpeed do
		local nMusicID = math.floor( self.m_nMusicID / 10 ) * 10  + i;
		local bMusicIDExist = CMusicConfig:Inst():IsExistMusicID( nMusicID );
		if bMusicIDExist then
			local szMusicPath = CMusicConfig:Inst():GetMusicPath( nMusicID );
			local szNetPath = g_App:GetNetMusicPath() .. szMusicPath;
			local szFileName = string.sub( szMusicPath, 10 );
			local szPathName = g_App:GetNetMusicLoadPath() .. szFileName;
			if not CPathMgr.IsFileExist( szPathName )then
				GetGammaFileMgr():Load( szNetPath, true, false, self.m_Listenter );
			end
		end
	end
end

function CWndLoadMusicTips:OnDestroy()
	if self.m_Listenter then
		GetGammaFileMgr():RemoveListener( self.m_Listenter );
	end
end


--endregion
