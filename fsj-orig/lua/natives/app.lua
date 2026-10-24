-- Application object (CGameAppClient), GUI manager and file manager natives. Claude.

-- ---------- base64 (binary files from Godot arrive as base64 text) ----------
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b64idx = {}
for i = 1, #B64 do b64idx[B64:byte(i)] = i - 1 end
local function b64decode(s)
	local out, n = {}, 0
	local acc, bits = 0, 0
	for i = 1, #s do
		local v = b64idx[s:byte(i)]
		if v then
			acc = (acc << 6) | v; bits = bits + 6
			if bits >= 8 then
				bits = bits - 8
				n = n + 1; out[n] = string.char((acc >> bits) & 0xFF)
				acc = acc & ((1 << bits) - 1)
			end
		end
	end
	return table.concat(out)
end
function ReadGameFileBytes(path) return b64decode(Host:read_base64(path)) end

-- ---------- loadfile / dofile on game-relative paths ----------
local _loadfile, _dofile = loadfile, dofile
function loadfile(name, mode, env)
	if type(name) == "string" and Host:file_exists(name) then
		local chunk = Host:read_text(name)
		if env ~= nil then return load(chunk, "@" .. name, "t", env) end
		return load(chunk, "@" .. name, "t")
	end
	if env ~= nil then return _loadfile(name, mode, env) end
	return _loadfile(name, mode)
end
function dofile(name)
	local f = loadfile(name)
	if not f then error("cannot open " .. tostring(name)) end
	return f()
end

-- ---------- file manager (GetGammaFileMgr) ----------
-- Load()/SyncLoad() deliver listener:OnLoadedEnd(name, buffer, size); Load is deferred to the next frame like the async original.
local FileMgr = class()
local pending = {}
local function deliver(name, listener)
	local buf
	if Host:file_exists(name) then
		local raw = ReadGameFileBytes(name)
		buf = CBufferStream:new()
		buf:WriteBytes(raw, 0, #raw)
		buf:SetPosition(0)
		if listener and listener.OnLoadedEnd then listener:OnLoadedEnd(name, buf, #raw) end
	else
		print("[FileMgr] missing file: " .. tostring(name))
		if listener and listener.OnLoadedEnd then listener:OnLoadedEnd(name, nil, 0) end
	end
end
function FileMgr:Load(name, bA, bB, listener) pending[#pending + 1] = { name, listener } return 1 end
function FileMgr:SyncLoad(name, bA, listener) deliver(name, listener) end
function FileMgr:LoadDir(...) return 0 end
function FileMgr:RemoveListener(listener)
	for i = #pending, 1, -1 do
		if pending[i][2] == listener then table.remove(pending, i) end
	end
end
local fileMgr = setmetatable({}, { __index = FileMgr })
function GetGammaFileMgr() return fileMgr end

-- ---------- GUI manager ----------
local GUIMgr = class()
function GUIMgr:GetRootWnd() return WrapWnd(Host:root_wnd()) end
function GUIMgr:GetStandarUISheetWidth() return 1280 end
function GUIMgr:GetStandarUISheetHeight() return 720 end

-- ---------- application ----------
local app
function CGameAppClient.Inst()
	if app == nil then
		app = setmetatable({}, CGameAppClient)
		app.__guimgr = setmetatable({}, GUIMgr)
	end
	return app
end
function CGameAppClient:GetGUIMgr() return self.__guimgr end
function CGameAppClient:GetGameSettingPath() return "config/" end
function CGameAppClient:GetChannelShare() return "" end
function CGameAppClient:IsQuit() return false end
function CGameAppClient:LoadCfg() end
function CGameAppClient:PostAllLoaded() end

-- ---------- app natives used by login / start ----------
-- The released game ran WITH the platform SDK: login.gui then shows only the green "denglu" button (no account box).
-- We emulate that SDK locally (see SendSDKCmd / LoginInstallHooks). Claude.
function CGameAppClient:IsWithSDK() return true end
function CGameAppClient:GetServerListPath() return "config/serverlist.txt" end
function CGameAppClient:PreResolveDomain(ip) end
function CGameAppClient:HidePreLoadingUI() end
function CGameAppClient:GetChannel() return "local" end
function CGameAppClient:GetSDKType() return "local" end
local sdk_login_clicked = false
function CGameAppClient:SendSDKCmd(nCmd, szJson)
	if nCmd == eLoginAndPayCmd_LOGIN then
		-- the SDK login "dialog": proceeds once the player has pressed the green login button; the local profile
		-- (user://profile.json in the fake World server) supplies the account
		if not sdk_login_clicked then return end
		local conn = self:GetWorldConn()
		if conn then conn:Login("", "", self:GetChannel(), self:GetSDKType(), "", "", "", 0, false) end
	elseif nCmd == eLoginAndPayCmd_LOGOUT then
		sdk_login_clicked = false
		self:OnResult(eLoginAndPayResult_LOGOUT_SUCCESS, "")
	elseif nCmd == eLoginAndPayCmd_EXIT_GAME then
		CGameAppClient.Quit(self)
	end
end

-- called from start_game.lua once the original scripts are loaded
function LoginInstallHooks()
	local auto = false
	local orig_loaded = CGameLogin.OnLoadedEnd
	CGameLogin.OnLoadedEnd = function(self, ...)
		auto = true
		local ok, err = pcall(orig_loaded, self, ...)
		auto = false
		if not ok then error(err, 0) end
	end
	local orig_connect = CGameLogin.ConnectWorld
	CGameLogin.ConnectWorld = function(self, ...)
		if auto then return orig_connect(self, ...) end
		-- the player pressed "denglu": if the World connection is already up, just log in
		sdk_login_clicked = true
		local conn = g_App:GetWorldConn()
		if conn and conn:IsConnected() then
			return self:Login()
		end
		return orig_connect(self, ...)
	end
end
function CGameAppClient:CommitCharData(n) end
function CGameAppClient:GetAccountID() return self.__accountID or 0 end
function CGameAppClient:GetServerID() return 1 end
function CGameAppClient:Quit() print("[app] Quit requested") end
function CGameAppClient:GetMachineInfo(data, n)
	for _, v in ipairs({ "Godot", "PC", "x86_64", "Windows", "00000000-0000-0000-0000-000000000000", "zh_CN" }) do data:WriteUTF(v) end
	for _, v in ipairs({ 0, 0, 2000, 8, 8192 }) do data:WriteUint32(v) end
	data:WriteUint16(1280); data:WriteUint16(720)
	data:SetPosition(0)
end

-- main-page / in-game windows that the C++ classes create themselves
local function create_native_wnd(self, res)
	CGWnd.CreateFromRes(self, res, WrapWnd(Host:root_wnd()), 1)
end
CGameStart.__native_construct = function(self) create_native_wnd(self, "gui/cfg/fsj_denglu.gui") end
CGameMain.__native_construct = function(self) create_native_wnd(self, "gui/cfg/fsj_zjm.gui") end
local gameStart, gameMain
function CGameAppClient:GetGameStart()
	if gameStart == nil then gameStart = CGameStartLua:new() end
	return gameStart
end
function CGameAppClient:GetGameMain()
	if gameMain == nil and CGameMainLua then gameMain = CGameMainLua:new() end
	return gameMain
end

-- ---------- world connection ----------
function CGameConnToWorld:IsConnected() return self.__connected == true end
function CGameConnToWorld:OnConnected() self.__connected = true end
function CGameConnToWorld:OnDisConnect() self.__connected = false end
function CGameConnToWorld:ShellCmdClose() self.__connected = false end
function CGameConnToWorld:IsShellDisconnect() return false end
function CGameConnToWorld.SendShellMsg(self, buf, len) end   -- replaced by the fake server (lua/server/fake_world.lua)
function CGameAppClient.ConnectToWorldServer(app, ip, port)
	local conn = CGameConnToWorldLua:new()
	app:OnWorldAlloc(conn)
	DeferCall(function()
		conn:OnConnected()
		if FakeWorld and FakeWorld.OnConnect then FakeWorld.OnConnect(conn) end
	end)
	return conn
end

-- run a function on the next frame (mimics the asynchronous engine callbacks: window creation, file loads)
local deferred = {}
function DeferCall(fn) deferred[#deferred + 1] = fn end

-- per-frame pump, in this order: window-created callbacks, file-load callbacks, then (once) the original post-load sequence
local allDone = false
local _tick = NativeTickUpdate
function NativeTickUpdate(dt)
	if #deferred > 0 then
		local batch = deferred; deferred = {}
		for _, f in ipairs(batch) do f() end
	end
	if #pending > 0 then
		local batch = pending; pending = {}
		for _, it in ipairs(batch) do deliver(it[1], it[2]) end
	end
	if not allDone and g_App and #pending == 0 and #deferred == 0 then
		allDone = true
		g_App:LoadCfg()
		g_App:PostAllLoaded()
	end
	if _tick then _tick(dt) end
end

-- ---------- renderer / audio (stub: silent for now) ----------
local Renderer = class()
function Renderer:GetAudio() return NativeAudio and NativeAudio() or nil end
local renderer = setmetatable({}, Renderer)
function CGWnd:GetRenderer() return renderer end
function CGameAppClient:GetRenderer() return renderer end

function CGWnd:IsInheritFrom(cls)
	local c = getmetatable(self)
	local function inherits(k)
		if k == cls then return true end
		local bases = rawget(k, "__bases")
		if bases then for i = 1, #bases do if inherits(bases[i]) then return true end end end
		return false
	end
	return c ~= nil and inherits(c)
end
-- parent:AssignDlgChildToWnd(luaWnd, "a.b"): make an existing child window the native peer of luaWnd
function CGWnd:AssignDlgChildToWnd(wnd, path, bCreate)
	local node = self.__node and self.__node:child(path) or nil
	if node == nil then return false end
	wnd.__node = node
	node:set_meta("lua", wnd)
	DeferCall(function() if wnd.__node ~= nil then wnd:OnCreated() end end)
	return true
end
function CGameAppClient.Register(...) end

-- ---------- settings ini (in memory for now) ----------
local settingsIni
function CGameAppClient:GetIniFile()
	if settingsIni == nil then
		settingsIni = CIniFile:new()
		settingsIni:SetInteger("State", "Guide", 1)   -- skip the first-run tutorial for now (CGuideMgr is not implemented yet)
		for _, n in ipairs({ "WriteInteger", "WriteInteger64", "WriteString", "WriteNumber" }) do
			if rawget(CIniFile, n) == nil then CIniFile[n] = CIniFile.SetInteger end
		end
		if rawget(CIniFile, "GetInteger64") == nil then CIniFile.GetInteger64 = CIniFile.GetInteger end
	end
	return settingsIni
end

function CGameAppClient:WaitMsg(bWait, nTime) end   -- the Lua CGameClient:WaitMsg shows its own "waiting" window
function RegistCommitData(buffer, nOffset) end       -- C++ marks player-data blocks dirty for the server; nothing to commit offline

-- ---------- ladder season / time ----------
function CGameAppClient:GetCurLadderSeason() return 1 end

-- ---------- 3D (not implemented yet): a null object answering every call so UI scripts keep running ----------
local Null = {}
Null.__index = function(t, k) return function(self, ...) return self end end
function NullObject() return setmetatable({}, Null) end
function CGWnd:GetViewportRenderer() self.__vp = self.__vp or NullObject() return self.__vp end
function CGameAppClient:CreateRenderObject() return NullObject() end
function CGameAppClient:GetDataPath() return "" end

function CGameAppClient:GetLogPath() return "user://log/" end
local newSeason = false
function CGameAppClient:IsShowNewSeason() return newSeason end
function CGameAppClient:SetShowNewSeason(b) newSeason = b end
function IAnimationListener.Ctor(self) end

function int16(v)   -- signed 16-bit view of an integer (mouse lParam packing)
	v = math.tointeger(v) or math.floor(v)
	v = v & 0xFFFF
	if v >= 0x8000 then v = v - 0x10000 end
	return v
end

function CGameAppClient:GetSelectMusicID() return self:GetIniFile():GetInteger("Setting", "MusicID", 121) end

-- ---------- tick manager (the original CTick.lua calls g_App:Register / UnRegister / RegisterLocal) ----------
local ticks = {}
local tickList = {}          -- registration order (deterministic dispatch)
function CGameAppClient:Register(tick, nInterval, nIndex)
	tick.__schedule_generation = (tick.__schedule_generation or 0) + 1
	tick.__interval = math.max(1, math.floor(tonumber(nInterval) or 1))
	tick.__elapsed = 0
	if not ticks[tick] then ticks[tick] = true; tickList[#tickList + 1] = tick end
	tick.__reg = true
end
CGameAppClient.RegisterLocal = CGameAppClient.Register
function CGameAppClient:UnRegister(tick)
	tick.__reg = false
	ticks[tick] = nil
end
function CTick:Stop() CGameAppClient.UnRegister(nil, self) end
function CTick:IsRegisted() return self.__reg == true end
function CTick:IsRunning() return self.__reg == true end
function CTick:GetInteval() return self.__interval or 0 end
function CTick:GetInterval() return self.__interval or 0 end

local function pump_ticks(dt)
	local list = tickList
	tickList = {}
	local due, seen = {}, {}
	for _, t in ipairs(list) do
		if ticks[t] and not seen[t] then
			seen[t] = true
			tickList[#tickList + 1] = t
			due[#due + 1] = {t, t.__schedule_generation}
		end
	end
	-- Callbacks can stop/restart themselves or start another timer. Iterate
	-- a fixed snapshot: appending to the live queue during a long frame must
	-- not run a restarted timer endlessly inside this same pump.
	for _, scheduled in ipairs(due) do
		local t, generation = scheduled[1], scheduled[2]
		if t.__reg and t.__schedule_generation == generation then
			t.__elapsed = (t.__elapsed or 0) + dt
			local n = 0
			while t.__reg and t.__elapsed >= t.__interval and n < 4 do
				t.__elapsed = t.__elapsed - t.__interval
				n = n + 1
				local ok, err = pcall(t.OnTick, t)
				if not ok then
					print("[tick error] " .. tostring(t.m_funTick) .. ": " .. tostring(err))
					t.__reg = false; ticks[t] = nil
				end
				if t.__schedule_generation ~= generation then break end
			end
			if n >= 4 then t.__elapsed = 0 end
		end
	end
end
local _tick3 = NativeTickUpdate
function NativeTickUpdate(dt)
	_tick3(dt)
	pump_ticks(dt)
end

function CGameConnToWorld:GetPingDelay() return 20 end
local GuiInfo = class()
function GuiInfo:GetRootWidth() return 1280 end
function GuiInfo:GetRootHeight() return 720 end
local guiInfo = setmetatable({}, GuiInfo)
function CGWnd:GetGUI() return guiInfo end
