local s_funCompleted = function() end;
local s_tblCurLoaded = { m_tblChildList = {}, m_nCheckIndex = 1 };
local s_tblAllLoaded = { ["CGameClient"] = s_tblCurLoaded };
local s_tblRoot = s_tblCurLoaded
local s_require = require;
local s_nCurTime = GetGammaTime()

--重载require
require = function( szName )
	szName = AsyncRequire( szName )
	if s_tblAllLoaded[szName] then
		return
	end
	local tblLoading = { m_tblChildList = {}, m_nCheckIndex = 1 };
	table.insert( s_tblCurLoaded.m_tblChildList, tblLoading );
	s_tblAllLoaded[szName] = tblLoading;
end

--检查某个lua文件是否加载完毕
function CheckGameClientNode( tblCheck )
	--已经加载了lua文件但是还没运行
	if tblCheck.m_luaBlock ~= s_funCompleted then
		s_tblCurLoaded = tblCheck;
		tblCheck.m_luaBlock();
		tblCheck.m_luaBlock = s_funCompleted;
	end
	
	--单次时间不能太长
	if GetGammaTime() - s_nCurTime > 50 then
		return false;
	end
	
	--按顺序处理子文件
	local tblChild = tblCheck.m_tblChildList[tblCheck.m_nCheckIndex];
	while tblChild do
		if not tblChild.m_bComplete then
			if not tblChild.m_luaBlock then
				return false;
			end

			if not CheckGameClientNode( tblChild ) then
				return false;
			end

			tblCheck.m_nCheckIndex = tblCheck.m_nCheckIndex + 1;
			tblChild = tblCheck.m_tblChildList[tblCheck.m_nCheckIndex];
		end
	end

	--自己和所有子文件全部加载完毕
	tblCheck.m_bComplete = true;
	return true;
end

function OnGameClientLoaded( szFileName )
	if not s_tblAllLoaded then
		return true;
	end

	if szFileName then
		--一个文件加载完毕
		local tblCurLoaded = s_tblAllLoaded[szFileName]
		tblCurLoaded.m_szFileName = szFileName;
		tblCurLoaded.m_luaBlock = loadfile( szFileName )
	end
	s_nCurTime = GetGammaTime()
	if not CheckGameClientNode( s_tblRoot ) then
		return false;
	end

	--加载完毕清除数据
	require = s_require;
	s_funCompleted = nil;
	s_tblCurLoaded = nil;
	s_tblAllLoaded = nil;
	s_tblRoot = nil;
	s_require = nil;
	s_nCurTime = nil;
	return true;
end

s_tblCurLoaded.m_luaBlock = s_funCompleted;
require "GameClientRequire";