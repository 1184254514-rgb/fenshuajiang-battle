--region CWndMusicLoadPro.lua
--Date 2017.10.14
--音乐下载进度界面

function CWndMusicLoadPro:Ctor( sResName, ParentWnd, nLoadType )
	CGWnd.Ctor( self, sResName, ParentWnd, nLoadType );
end

function CWndMusicLoadPro:OnCreated()
	self.m_WndLoading		= self:GetDlgChild( "xiazaizhong" );
	self.m_WndLoadingPro	= self:GetDlgChild( "xiazaizhong.jindu" );

	self.m_WndLoadingEnd	= self:GetDlgChild( "xiazaiwancheng" );
	self.m_WndLoadingEndOk	= self:GetDlgChild( "xiazaiwancheng.b_ok" );
	self.m_WndLoadingEndOk:AddActionListener( "OnClickOk", self );

	self.m_tickHideWnd		= CTick:new( "OnTickHideWnd", self );

	self.m_WndLoadingEnd:ShowWnd( false );
	self.m_tickImitateLoading = CTick:new( "ImitateLoadingPro", self );
	self.m_WndLoadingPro:SetWndText( "" );
	self.m_nLoadingPecent = 0;
	self.m_wndBuyMusic = CWndBuyMusic:new( "gui/cfg/fsj_yinyuexuanze2_tips.gui", g_App:GetGUIMgr():GetRootWnd(), 1 );
end

function CWndMusicLoadPro:OnDestroy()
	if self.m_Listenter then
		GetGammaFileMgr():RemoveListener( self.m_Listenter );
	end
end

function CWndMusicLoadPro:OnClickOk()
	self:ShowWnd( false );
end

function CWndMusicLoadPro:LoadMusicComplete( nLoadType, nMusicID )
	self.m_nLoadType = nLoadType;
	self.m_nMusicID = nMusicID;
	self.m_tickHideWnd:Start( 1000 );
	self.m_tickImitateLoading:Stop();
	self.m_WndLoading:ShowWnd( false );
	self.m_WndLoadingEnd:ShowWnd( true );
end

function CWndMusicLoadPro:OnTickHideWnd()
	self.m_tickHideWnd:Stop();
	if self.m_nLoadType == eLoadMusicType_Shiting then
		local nType = CMusicConfig:Inst():GetMusicPlayType( self.m_nMusicID );
		g_App:GetGameStart():GetMusicWnd().m_bReplayMusic = true;
		g_App:SetBGMusic( math.floor( self.m_nMusicID / 10 )*10 + nType );
	end

	if self.m_nLoadType == eLoadMusicType_Buy then
		self.m_wndBuyMusic:SetData( self.m_nMusicID )
		self.m_wndBuyMusic:ShowWnd( true );
	end
	self:ShowWnd( false );
end

function CWndMusicLoadPro:ImitateLoadingPro()
	self.m_nLoadingPecent = self.m_nLoadingPecent + math.random( 0, 5 );
	if self.m_nLoadingPecent >= 100 then
		self.m_tickImitateLoading:Stop();
		return 
	end

	self.m_WndLoadingPro:SetWndText( self.m_nLoadingPecent .. "%" );
end

function CWndMusicLoadPro:OnWndShow( bShow )
	if bShow then
		self.m_tickImitateLoading:Start( 100 );
	end
end

function CWndMusicLoadPro:ReloadMusic( nMusicID )
	self:ShowWnd( true );
	if not self.m_Listenter then
		self.m_Listenter = IResListener:new();
		self.m_Listenter.OnLoadedEnd = function( listlua, szFileName, pBuffer, nSize )
			self:ShowWnd( false );
			local szLoadMd5 = CBufferStream:new()
			szLoadMd5:SetDataSize( 32 );
			MD5Ex( szLoadMd5, pBuffer, nSize );
			szLoadMd5 = szLoadMd5:ReadUTFBytes( 32 );
			local szSrcMd5 = string.sub( szFileName, -36, -5 );
			
			if szSrcMd5 == szLoadMd5 then
				local nBegin, nEnd = string.find( szFileName, "netmusic/" );
				if not nBegin or not nEnd then return end
				local szFileName = string.sub( szFileName, nEnd+1 );
				local f = io.open( g_App:GetNetMusicLoadPath() .. szFileName, "wb" );
				if not f then return end
				f:write( pBuffer:ReadBytes( nSize ) );
				io.close( f );
			end
		end
	end

	for i =1, eMusicCount_BySpeed do
		local nMusicID = math.floor( nMusicID / 10 ) * 10  + i;
		local bMusicIDExist = CMusicConfig:Inst():IsExistMusicID( nMusicID );
		if bMusicIDExist then
			local szMusicPath = CMusicConfig:Inst():GetMusicPath( nMusicID );
			local szNetPath = g_App:GetNetMusicPath() .. szMusicPath;
			local szFileName = string.sub( szMusicPath, 10 );
			local szPath = g_App:GetNetMusicLoadPath() .. szFileName;
			if not CPathMgr.IsFileExist( szPath ) then
				GetGammaFileMgr():Load( szNetPath, true, false, self.m_Listenter );
			end
		end
	end
end

function CWndMusicLoadPro:ShowWndWithWifi()
	self:ShowWnd( true );
end

--endregion
