--region CLoadingListener.lua
--Date 2015-12-07

g_mapLoadedFiles = {}
g_mapLoadingListener = {}
g_mapTableLoadedHandler = {}
g_Dictionary = CDictionary.Inst();

--配置文件进行字典替换
function InitTableDict( tblData, tblDictHeaders, bMultiTable )
	if not bMultiTable then
		tblData = { tblData }
	end

	for _, t in pairs( tblData ) do
		if type( t ) == "table" then
			for _, v in pairs( t ) do
				for _, h in pairs( tblDictHeaders ) do
					if type( v[h] ) == "number" then
						v[h] = g_Dictionary:GetValue( v[h] );
					else 
						v[h] = g_Dictionary:GetValueByString( v[h] ) or v[h];
					end
				end
			end
		end
	end
end

--配置文件加载完毕回调注册函数
function OnTableLoadFinished( szFileName, tblData )	 
	if szFileName == "scenario" then
		print("a");
	end
	local tblCallback = g_mapTableLoadedHandler[szFileName];
	if not tblCallback or not tblCallback[1] then
		return;
	end
	
	if tblCallback[2] == nil then
		tblCallback[1]( tblData )
	elseif type( tblCallback[1] ) == "string" then
		tblCallback[2][tblCallback[1]]( tblCallback[2], tblData )
	else
		tblCallback[1]( tblCallback[2], tblData )
	end
end

--加载非lua配置文件
function LoadConfigFile( szFileName, Handler, CallBack, bSync )
   	CLoadingListener:new( szFileName, bSync, -1, Handler, CallBack );
end

--加载lua配置文件
function LoadLuaConfig( szFileName, Handler, CallBack, bSync )
   	CLoadingListener:new( szFileName, bSync, 0, Handler, CallBack );
end

--加载lua源文件
function LoadLuaSource( szFileName, Handler, CallBack, bSync )
   	CLoadingListener:new( szFileName, bSync, 1, Handler, CallBack );
end

-- 加载宏定义文件  
function LoadDefineFile( szFileName )
	local LoadListener = CLoadingListener:new( szFileName, false, nil, nil );
	LoadListener.OnLoadedEnd = function( Listener, szFileName, pBuffer, nSize )
		local tbl = dofile( szFileName )
		for k, v in pairs( tbl ) do
			G[k] = v;
		end
		CLoadingListener.OnLoadedEnd( Listener );
	end
end

function CLoadingListener:Ctor( szFileName, bSync, eLuaType, Handler, CallBack )
	--已经加载过的文件不重复加载
	if( g_mapLoadedFiles[szFileName] ) then
		return;
	end
	g_mapLoadedFiles[szFileName] = true;

    self.m_eLuaType = eLuaType;
    self.m_hTarget = Handler;
    self.m_cbFunc = CallBack;

	assert( type( CallBack ) ~= "string" or Handler and Handler[CallBack] );

	--lua文件支持reload，在这里注册回调
	--以文件名作为索引，因此所有lua配置文件不能重名
	if self.m_eLuaType == 0 then
		local _, _, szName = string.find( szFileName, "/([%w_]+).lua" );
		if( szName == nil ) then
			_, _, szName = string.find( szFileName, "/([%w_]+)/$" );
		end
		assert( szName and g_mapTableLoadedHandler[szName] == nil );
		g_mapTableLoadedHandler[szName] = { CallBack, Handler };
	end

 	local FileMgr = GetGammaFileMgr();
	local nLoadCount = nil;
    if bSync then
    	FileMgr:SyncLoad( szFileName, true, self ); 
    else
     	nLoadCount = FileMgr:Load( szFileName, false, true, self ); 
    end
	g_mapLoadingListener[self] = nLoadCount;
end

function CLoadingListener:OnLoadedEnd( szFileName, pBuffer, nSize )
	if g_mapLoadingListener[self] then
		g_mapLoadingListener[self] = g_mapLoadingListener[self] - 1;
		if g_mapLoadingListener[self] == 0 then
			g_mapLoadingListener[self] = nil;
		end
	end

    if nil == pBuffer then
        print( "Load File Error", szFileName );
        return;
    end
	pBuffer:SetDataSize( nSize );

	--lua文件的回调由配置文件加载完毕后
	--回调OnTableLoadFinished触发
    if self.m_eLuaType >= 0 then
        assert( pBuffer );
		local luaBlock = loadfile( szFileName )
		assert( luaBlock )
		luaBlock()
	--非lua文件直接回调
	elseif self.m_cbFunc then
		if self.m_hTarget == nil then
			self.m_cbFunc( pBuffer, nSize, szFileName )
		elseif type( self.m_cbFunc ) == "string" then
			self.m_hTarget[self.m_cbFunc]( self.m_hTarget, pBuffer, nSize, szFileName )
		else
			self.m_cbFunc( self.m_hTarget, pBuffer, nSize, szFileName )
		end
    end
end