--region Help.lua
--Date 2016-05-11

local nMaxInt32 = 0xffffffff + 1;
g_ChannelSplitChar = "@";

function GetNumberString( nValue )
	local nValue = nValue or 0;
	local nLow = nValue%nMaxInt32;
	local nHeight = math.floor( nValue/nMaxInt32 );
	if nHeight > 0 then
		return string.format( "%08x%08x", nHeight, nLow );
	else
		return string.format( "%08x", nLow );
	end
end

function ReadUnit64String( pBuffer )
	local nLow = pBuffer:ReadUint32();
	local nHigh = pBuffer:ReadUint32();
	return string.format( "%08x%08x", nHigh, nLow );
end

function WriteUnit64String( pBuffer, strKey )
	local nLow = tonumber( "0x"..string.sub( strKey, 9, 16 ) );
	local nHigh = tonumber( "0x"..string.sub( strKey, 1, 8 ) );
	pBuffer:WriteInt32( nLow );
	pBuffer:WriteInt32( nHigh );
end

function GetCampRelation( nCamp1, nCamp2 )
	if nCamp == eCT_0 or nCamp2 == eCT_0 then
		return eRelationType_Friendly;
	end
	return nCamp1 == nCamp2 and eRelationType_Friendly or eRelationType_Opposed;
end

function DumpBuffer( Buffer, nStartPos, nLen )
	if not Buffer:IsInheritFrom( CBufferStream ) then
		return;
	end
	local nOldPos = Buffer:GetPosition();
	nStartPos = nStartPos or 0;
	nLen = nLen or Buffer:GetDataSize();

	Buffer:SetPosition( nStartPos );
	local nMax = math.min( Buffer:GetDataSize(), nStartPos + nLen );
	local strResult = "0x";
	local nCount = 0;	
	for i = nStartPos, nMax-1 do
		local nByte = Buffer:ReadUint8();
		strResult = strResult .. string.format( "%02x", nByte );
		nCount = nCount + 1;
		if nCount % 4 == 0 then
			strResult = strResult .. " ";
		end
	end
	Buffer:SetPosition( nOldPos );
	print( strResult );
end

--比较两个日期大小，STime1大于STime2返回1，等于返回0， 小于返回-1
function CompareDate( STime1, STime2 )
    if STime1:m_nYear() > STime2:m_nYear() then
        return 1;
    elseif STime1:m_nYear() == STime2:m_nYear() then
        if STime1:m_nMonth() > STime2:m_nMonth() then
            return 1;
        elseif STime1:m_nMonth() == STime2:m_nMonth() then
            if STime1:m_nDayOfMonth() > STime2:m_nDayOfMonth() then
                return 1;
            elseif STime1:m_nDayOfMonth() == STime2:m_nDayOfMonth() then
                return 0;
            end
        end
    end
    return -1;
end

--字符串分割函数
--传入字符串和分隔符，返回分割后的table
function SplitStr( str, delimiter )
	if not str or str == "" or not delimiter then
		return {};
	end
	
    local result = {};
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

--将函数形式的
function GetFuncAndParam( szFuncDes )
	if not szFuncDes then return end;

	local tblParam = {}
	local sFunName = nil;
	local szDes = string.gsub( szFuncDes, "%s", "").." ";
	for sMatch in szDes : gmatch( "(.-)[%(%),]" ) do
		if nil == sFunName then
			if funName ~= "setdb" then
				sFunName = sMatch;
			else
				sFunName = sMatch;
			end
		elseif sMatch ~= "" then
			table.insert( tblParam, sMatch )
		end
    end
	return { Func = sFunName or szFuncDes, Parms = tblParam };
end

-- 反序查找字符，返回位置
function ReverseFind( szStr, char )
	local nIndex = string.find( string.reverse(szStr), char );
	return string.len( szStr ) - nIndex + 1;
end


--按key顺序遍历
function PairsByKeysAsc( tbl )
	local a = {};
	for k in pairs( tbl ) do
		a[ #a + 1 ] = k;
	end
	table.sort( a );
	local i = 0;
	return function()
		i = i +1;
		return a[i], tbl[a[i]];
	end
end

--按key逆序遍历
function PairsByKeysDesc( tbl )
	local a = {};
	for k in pairs( tbl ) do
		a[ #a + 1 ] = k;
	end
	table.sort( a, function( m, n ) return m > n; end );
	local i = 0;
	return function()
		i = i +1;
		return a[i], tbl[a[i]];
	end
end

--获取tbl最小值
function table.minn( tbl )
	local iter = PairsByKeysAsc(tbl);
	return iter();
end

function table.shuffle( t )
	local n = #t;
	for i = 1, n do
		local m = math.random( i, n );
		local temp = t[i];
		t[i] = t[m];
		t[m] = temp;
	end
end

function table.count( t )
	local nCount = 0  
	for k, v in pairs( t ) do  
		nCount = nCount + 1  
	end  
	return nCount;
end

function table.clone( t )
	local c = {};
	setmetatable( c, getmetatable( t ) );
	for k, v in pairs( t ) do
		c[k] = type( v ) == "table" and table.clone( v ) or v;
	end
	return c;
end

function table.print( t )
	print( json.encode( t ) );
end

local function check_type( v )
	local szType = type( v );
	return szType == "table" or szType == "number" or szType == "string";
end

function table.pack( t, Buffer )
	Buffer:WriteInt16( table.count( t ) );
	for k, v in pairs( t ) do
		if check_type( k ) and check_type( v ) then
			if type( k ) == "table" then
				Buffer:WriteInt8( 0 );
				table.pack( k, Buffer )
			elseif type( k ) == "number" then
				Buffer:WriteInt8( 1 );
				Buffer:WriteDouble( k );
			elseif type( k ) == "string" then
				Buffer:WriteInt8( 2 );
				Buffer:WriteUTF( k );
			end
			if type( v ) == "table" then
				Buffer:WriteInt8( 0 );
				table.pack( v, Buffer )
			elseif type( v ) == "number" then
				Buffer:WriteInt8( 1 );
				Buffer:WriteDouble( v );
			elseif type( v ) == "string" then
				Buffer:WriteInt8( 2 );
				Buffer:WriteUTF( v );
			end
		end
	end
end

function table.unpack( Buffer )
	local tbl = {};
	local nCount = Buffer:ReadUint16();
	for j = 1, nCount do
		local nType = Buffer:ReadUint8();
		local key = nil;
		if nType == 0 then
			key = table.unpack( Buffer )
		elseif nType == 1 then
			key = Buffer:ReadDouble();
		else
			key = Buffer:ReadUTF();
		end
		
		local nType = Buffer:ReadUint8();
		if nType == 0 then
			tbl[key] = table.unpack( Buffer )
		elseif nType == 1 then
			tbl[key] = Buffer:ReadDouble();
		else
			tbl[key] = Buffer:ReadUTF();
		end
	end
	return tbl;
end

function math.limit( val, min, max )
	if val < min then
		return min;
	end
	if val > max then
		return max;
	end
	return val;
end

function MAKE_UINT16( cha0, char1 )
	return BitOr( char0, LeftShift( char1, 8 ) );
end

function MAKE_UINT32( cha0, char1 )
	return BitOr( char0, LeftShift( char1, 16 ) );
end

function HIUINT16( l )
	return RightShift( l, 16 );
end

function LOUINT16( l )
	return BitAnd( l, 0xffff );
end

function HIUINT8( w )
	return RightShift( w, 8 );
end

function LOUINT16( w )
	return BitAnd( w, 0xff );
end

local s_GammaRand = CGammaRand:new();

function SetRandomSeed( nValue )
	s_GammaRand:SetSeed( nValue );
end

function GetRandom( Min, Max )
	local nRandom = s_GammaRand:GetRand();
	return ( nRandom*( Max - Min )/0x8000 + Min );
end

-- 枚举C++常量  
function EnumLua( n ) 
	return n;
end

function GetCurMonthDays( nLocalTime )
	nLocalTime = nLocalTime or GetLocalTime();
	local pSTime = GetFormatTimeSTMFromMillisecond( nLocalTime );
	local nTime1 = Format2LocalTime( pSTime:m_nYear(), pSTime:m_nMonth(), 1, 1, 1, 1 );
	if pSTime:m_nMonth() == 12 then
		return 31;
	else
		local nTime2 = Format2LocalTime( pSTime:m_nYear(), pSTime:m_nMonth() + 1, 1, 1, 1, 1 );
		return ( nTime2 - nTime1 ) / eTimeConst_DaySeconds;
	end
end

--endregion
