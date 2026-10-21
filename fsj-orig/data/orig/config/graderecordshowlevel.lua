-- -*- coding: utf8 -*-
-- source: graderecordshowlevel.xlsx

--start table
local t = g_data_graderecordshowlevel or {}
t[1] = { nEndlessAllScore = 6000, nEndlessAreaScore = 5000, nEndlessKillScore = 1200, nEndlessRhythmScore = 1000, nEndlessMaxCombo = 100, nLimitAllScore = 6000, nLimitAreaScore = 4000, nLimitKillScore = 1600, nLimitRhythmScore = 1000, nLimitMaxCombo = 80, nTeamAllScore = 8000, nTeamAreaScore = 6000, nTeamKillScore = 2000, nTeamRhythmScore = 1000, nTeamMaxCombo = 80, }
g_data_graderecordshowlevel = t
--end table

local dict_headers = {}

if InitTableDict ~= nil then
	InitTableDict( g_data_graderecordshowlevel, dict_headers )
end

if OnTableLoadFinished ~= nil then
	OnTableLoadFinished( "graderecordshowlevel", g_data_graderecordshowlevel )
end

