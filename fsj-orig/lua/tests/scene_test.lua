g_App:EnterRoom(eRT_Endless)
local sc = g_App.__scene
local w = sc.m_pWanfa
local d = w.m_EventDispatcher
local out = {}
out[#out+1] = "resultWnd=" .. tostring(w.m_pResultWnd)
local cnt = 0
for k, v in pairs(d) do out[#out+1] = tostring(k) .. "=" .. tostring(v) end
-- try to dispatch manually
local ok, err = pcall(function() d:DispatchEvent({ m_Type = "OnSceneCreated" }) end)
out[#out+1] = "manual dispatch ok=" .. tostring(ok) .. " " .. tostring(err)
out[#out+1] = "after: resultWnd=" .. tostring(w.m_pResultWnd) .. " running=" .. tostring(w.m_tickCreateDirector:IsRunning())
local i = debug.getinfo(CGameSceneClient.OnSceneCreated, "S")
out[#out+1] = "CGameSceneClient.OnSceneCreated=" .. i.source .. ":" .. i.linedefined
return table.concat(out, " | ")
