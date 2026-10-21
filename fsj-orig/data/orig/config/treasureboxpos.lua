-- -*- coding: utf8 -*-

--start table
local t = g_data_treasureboxpos or {}
t[1] = { fUpX = 0, fUpY = 1, fUpZ = 0, fPosX = -40, fPosY = 50, fPosZ = 100, fDestX = 0, fDestY = 0, fDestZ = 0, };
t[2] = { fUpX = 0, fUpY = 1, fUpZ = 0, fPosX = -120, fPosY = 80, fPosZ = 280, fDestX = 0, fDestY = 0, fDestZ = 0, }
g_data_treasureboxpos = t
--end table

local dict_headers = {}

if InitTableDict ~= nil then
	InitTableDict( g_data_treasureboxpos, dict_headers )
end

if OnTableLoadFinished ~= nil then
	OnTableLoadFinished( "treasureboxpos", g_data_treasureboxpos )
end