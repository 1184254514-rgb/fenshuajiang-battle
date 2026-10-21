--region CTableConfigMgr.lua
--Date

local TableConfigMgr = CTableConfigMgr:Inst();
local s_tblData = {};
g_tblTabFile = g_tblTabFile or {};

local tblFieldMetaTable = tblFieldMetaTable or
{
	__index = function( tblRow, szField )
		local tblFile = rawget( tblRow, "tblFile" );
		local szFile = rawget( tblFile, "szFile" );
		local nRowIndex = rawget( tblRow, "nRowIndex" );
		if string.sub( szField, 1, 1 ) == 'n' then
			return TableConfigMgr:GetConfigNumber( szFile, nRowIndex, szField );
		else
			return TableConfigMgr:GetConfigString( szFile, nRowIndex, szField );
		end
	end 
}

local funGetRow = function( tblFile, nRowIndex )
	tblRow = {}
	tblRow.tblFile = tblFile;
	tblRow.nRowIndex = nRowIndex;
	setmetatable( tblRow, tblFieldMetaTable )
	return tblRow;
end

local tblRowMetaTable = tblRowMetaTable or
{
	__index = function( tblFile, Key )
		local szFile = rawget( tblFile, "szFile" );
		if TableConfigMgr:IsSingleColumn( szFile ) then
			local nRowIndex = TableConfigMgr:GetRowIndexByString( szFile, Key );
			return TableConfigMgr:GetConfigNumber( szFile, nRowIndex );
		end

		tblRow = rawget( tblFile, Key );
		if not tblRow then
			tblRow = {}
			tblRow.tblFile = tblFile;
			if type( Key ) == "string" then
				tblRow.nRowIndex = TableConfigMgr:GetRowIndexByString( szFile, Key );
			else
				tblRow.nRowIndex = TableConfigMgr:GetRowIndexByNumber( szFile, Key );
			end
			setmetatable( tblRow, tblFieldMetaTable )
			rawset( tblFile, Key, tblRow );
		end
		return tblRow;
	end
}

local tblFileMetaTable = tblFileMetaTable or
{
	__index = function( tblAllFile, szFileName )
		local tblFile = rawget( tblAllFile, szFileName );
		if not tblFile then
			tblFile = {}
			tblFile.GetRow = funGetRow;
			tblFile.szFile = szFileName;
			tblFile.nRowCount = TableConfigMgr:GetConfigRowCount( szFileName );
			tblFile.nColumnCount = TableConfigMgr:GetConfigColumnCount( szFileName );
			setmetatable( tblFile, tblRowMetaTable )
			rawset( tblAllFile, szFileName, tblFile );
		end
		return tblFile;
	end
}

setmetatable( g_tblTabFile, tblFileMetaTable );

--endregion
