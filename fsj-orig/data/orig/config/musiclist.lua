-- -*- coding: utf8 -*-
-- source: musiclist.xlsx

--start table
local t = g_data_musiclist or {}

local l = {
	{"0a010000"},
	{"0a010001"},
	{"0a010002"},
	{"0a010003"},
};

t[0]=l[1]
t[1]=l[2]
t[2]=l[3]
t[3]=l[4]

g_data_musiclist = t

local f =
{
	sName = 1, 
}

local m =
{
	__index = function( t, k )
		return rawget( t, f[k] or k );
	end,

	__newindex = function( t, k, v )
		rawset( t, f[k] or k, v );
	end
}

for k, v in pairs( l ) do
	setmetatable( v, m );
end
--end table

local dict_headers = {}

if InitTableDict ~= nil then
	InitTableDict( g_data_musiclist, dict_headers )
end

if OnTableLoadFinished ~= nil then
	OnTableLoadFinished( "musiclist", g_data_musiclist )
end

