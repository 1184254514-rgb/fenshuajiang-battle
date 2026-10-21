-- Native audio bridge.
--
-- Wiring in app.lua:
--   function Renderer:GetAudio() return NativeAudio() end
-- Call NativeButtonSound(window_or_node) once per accepted button activation.
--
-- Observed sound convention:
--   CreateSound(path, false, true) creates a temporary, auto-release sound.
--   Play(loop, restart) supports the observed Play(false, true).
-- The second CreateSound flag is accepted; all supplied calls pass false.
--
-- FightSound is already implemented by CKillInfoWnd: 0 skips playback and
-- 1/2/3 set the individual sound gain to 0.3/0.5/0.8. Do not multiply that
-- setting into the global sound bus or apply it to button sounds.
--
-- The excerpts do not specify music-volume INI units or IMusic signatures.
-- Compatibility choices here:
--   Setting/MusicVolume and Setting/SoundVolume are optional; absent = 1.
--   Values 0..1 are linear; values above 1 are interpreted as percentages.
--   Native Set*Volume methods always take linear 0..1.
--   IMusicListener:OnMusicEnd(music) receives natural, non-looping completion.
--   Stop, replacement and Release do not generate completion callbacks.
--   Positions and lengths are milliseconds.
--
-- Documented globals defined here: NativeAudio, NativeButtonSound, and a
-- chained NativeTickUpdate for settings refresh and completion delivery.

local function number(value)
	local n = tonumber(value)
	if n == nil or n ~= n or n == math.huge or n == -math.huge then
		return nil
	end
	return n
end

local function gain(value)
	local n = number(value)
	return n and math.max(0, math.min(1, n)) or nil
end

local function flag(value, default)
	if value == nil then return default end
	if type(value) == "number" then return value ~= 0 end
	return value ~= false
end

local function positive_id(value)
	local n = number(value)
	if n then
		n = math.floor(n)
		if n > 0 then return n end
	end
	return nil
end

local function audio_host()
	local host = rawget(_G, "Host")
	return host and host.audio or nil
end

-- Avoid the native class model's missing-member/no-op fallback when probing
-- optional INI getters and listener methods.
local function concrete_method(object, name)
	local seen = {}
	local function visit(t)
		if type(t) ~= "table" or seen[t] then return nil end
		seen[t] = true

		local method = rawget(t, name)
		if type(method) == "function" then return method end

		local bases = rawget(t, "__bases")
		if type(bases) == "table" then
			for _, base in ipairs(bases) do
				method = visit(base)
				if method then return method end
			end
		end

		local index = rawget(t, "__index")
		if type(index) == "table" then
			method = visit(index)
			if method then return method end
		end
		return visit(getmetatable(t))
	end
	return visit(object)
end

local function get_ini()
	local app = rawget(_G, "g_App")
	local getter = concrete_method(app, "GetIniFile")
	return getter and getter(app) or nil
end

local MISSING_INTEGER = -2147483648

local function read_setting(ini, key)
	if ini == nil then return nil end

	-- Preserve fractional settings when a real string getter is available.
	local getter = concrete_method(ini, "GetString")
	if getter then
		local ok, value = pcall(getter, ini, "Setting", key, "")
		if ok then
			local n = number(value)
			if n ~= nil then return n end
		end
	end

	getter = concrete_method(ini, "GetInteger")
	if getter then
		local ok, value = pcall(getter, ini, "Setting", key, MISSING_INTEGER)
		if ok then
			local n = number(value)
			if n ~= MISSING_INTEGER then return n end
		end
	end
	return nil
end

local function setting_gain(value)
	if value == nil then return 1 end
	if value > 1 then value = value / 100 end
	return gain(value) or 1
end

local UNKNOWN = {}
local settings_ini = UNKNOWN
local last_music_setting, last_sound_setting = UNKNOWN, UNKNOWN
local music_volume, sound_volume = 1, 1
local applied_host, applied_music, applied_sound

local function push_volumes()
	local a = audio_host()
	if not a then return nil end
	if a ~= applied_host then
		applied_host = a
		applied_music, applied_sound = nil, nil
	end
	if applied_music ~= music_volume then
		a:set_music_volume(music_volume)
		applied_music = music_volume
	end
	if applied_sound ~= sound_volume then
		a:set_sound_volume(sound_volume)
		applied_sound = sound_volume
	end
	return a
end

local function refresh_settings()
	local ini = get_ini()
	if ini ~= settings_ini then
		settings_ini = ini
		last_music_setting, last_sound_setting = UNKNOWN, UNKNOWN
	end

	if ini then
		local music = read_setting(ini, "MusicVolume")
		local sound = read_setting(ini, "SoundVolume")
		if music ~= last_music_setting then
			last_music_setting = music
			music_volume = setting_gain(music)
		end
		if sound ~= last_sound_setting then
			last_sound_setting = sound
			sound_volume = setting_gain(sound)
		end
	end

	-- Only INI changes replace runtime gains. A debug SetMusicVolume call
	-- therefore survives subsequent ticks when the INI value is unchanged.
	return push_volumes()
end

function IAudio:Ctor() end

local singleton = setmetatable({}, IAudio)

function NativeAudio()
	return singleton
end

function CGameAppClient:GetAudio()
	return singleton
end

function IAudio:RefreshSettings()
	return refresh_settings() ~= nil
end

function IAudio:SetMusicVolume(value)
	local volume = gain(value)
	if volume == nil then return false end
	refresh_settings()
	music_volume = volume
	push_volumes()
	return true
end

function IAudio:SetSoundVolume(value)
	local volume = gain(value)
	if volume == nil then return false end
	refresh_settings()
	sound_volume = volume
	push_volumes()
	return true
end

function IAudio:GetMusicVolume()
	refresh_settings()
	return music_volume
end

function IAudio:GetSoundVolume()
	refresh_settings()
	return sound_volume
end

function IAudio:CreateSound(path, compatibility_flag, auto_release)
	local sound = ISound:new(path, compatibility_flag, auto_release)
	if rawget(sound, "__handle") == 0 then return nil end
	return sound
end

function IAudio:CreateMusic(path, flag_or_listener, listener)
	if listener == nil and
		(type(flag_or_listener) == "table" or type(flag_or_listener) == "function") then
		listener = flag_or_listener
	end
	local music = IMusic:new(path, listener)
	if not rawget(music, "__valid") then return nil end
	return music
end

function IAudio:PlaySound(path, volume)
	local sound = self:CreateSound(path, false, true)
	if not sound then return false end
	if volume ~= nil then sound:SetVolume(volume) end
	local played = sound:Play(false, true)
	if not played then sound:Release() end
	return played
end

function IAudio:StopAllSounds()
	local a = audio_host()
	if a then a:stop_all_sounds() end
end

function ISound:Ctor(path, compatibility_flag, auto_release)
	self.__path = type(path) == "string" and path or ""
	self.__volume = 1
	self.__handle = 0
	self.__released = false
	self.__audio = refresh_settings()

	local a = rawget(self, "__audio")
	if a and self.__path ~= "" then
		self.__handle = a:sound_create(self.__path, flag(auto_release, false))
	end
end

local function sound_handle(self)
	return rawget(self, "__audio"), rawget(self, "__handle") or 0
end

function ISound:Play(looping, restart)
	refresh_settings()
	local a, handle = sound_handle(self)
	return a ~= nil and handle > 0 and
		a:sound_play(handle, flag(looping, false), flag(restart, true))
end

function ISound:Stop()
	local a, handle = sound_handle(self)
	if a and handle > 0 then a:sound_stop(handle) end
end

function ISound:Pause(paused)
	local a, handle = sound_handle(self)
	return a ~= nil and handle > 0 and
		a:sound_pause(handle, flag(paused, true))
end

function ISound:Resume()
	return self:Pause(false)
end

function ISound:IsPlaying()
	local a, handle = sound_handle(self)
	return a ~= nil and handle > 0 and a:sound_is_playing(handle)
end

function ISound:IsPaused()
	local a, handle = sound_handle(self)
	return a ~= nil and handle > 0 and a:sound_is_paused(handle)
end

function ISound:SetVolume(value)
	local volume = gain(value)
	if volume == nil or rawget(self, "__released") then return false end
	self.__volume = volume
	local a, handle = sound_handle(self)
	return a ~= nil and handle > 0 and a:sound_set_volume(handle, volume)
end

function ISound:GetVolume()
	return rawget(self, "__volume") or 1
end

function ISound:GetPosition()
	local a, handle = sound_handle(self)
	if a and handle > 0 then return a:sound_position_ms(handle) end
	return 0
end

function ISound:GetLength()
	local a = rawget(self, "__audio")
	if a and not rawget(self, "__released") then
		return a:stream_length_ms(rawget(self, "__path") or "")
	end
	return 0
end

function ISound:Release()
	local a, handle = sound_handle(self)
	self.__handle = 0
	self.__released = true
	if a and handle > 0 then a:sound_release(handle) end
end

function ISound:__gc()
	local a, handle = sound_handle(self)
	self.__handle = 0
	self.__released = true
	if a and handle > 0 then
		-- Temporary one-shots survive collection until their audio finishes.
		-- pcall also makes VM/engine shutdown ordering harmless.
		pcall(function() a:sound_abandon(handle) end)
	end
end

function IMusicListener:Ctor() end
function IMusicListener:OnMusicEnd(music) end

local active_music

function IMusic:Ctor(path, listener)
	self.__path = type(path) == "string" and path or ""
	self.__volume = 1
	self.__loop = true
	self.__ticket = 0
	self.__released = false
	self.__listeners = {}
	self.__audio = refresh_settings()

	local a = rawget(self, "__audio")
	self.__valid = a ~= nil and self.__path ~= "" and a:has_stream(self.__path)
	if listener ~= nil then self:AddListener(listener) end
end

local function music_handle(self)
	return rawget(self, "__audio"), rawget(self, "__ticket") or 0
end

function IMusic:Play(looping, restart)
	if rawget(self, "__released") or not rawget(self, "__valid") then
		return false
	end
	refresh_settings()

	local a, ticket = music_handle(self)
	if not a then return false end
	local loop = flag(looping, rawget(self, "__loop") ~= false)

	if not flag(restart, true) and a:music_owns(ticket) then
		return a:music_pause(ticket, false)
	end

	local new_ticket = a:music_play(
		rawget(self, "__path"), loop, rawget(self, "__volume") or 1
	)
	if not new_ticket or new_ticket == 0 then return false end

	if active_music and active_music ~= self then
		active_music.__ticket = 0
	end
	self.__ticket = new_ticket
	self.__loop = loop
	active_music = self
	return true
end

function IMusic:Stop()
	local a, ticket = music_handle(self)
	self.__ticket = 0
	if active_music == self then active_music = nil end
	if a and ticket > 0 then a:music_stop(ticket) end
end

function IMusic:Pause(paused)
	local a, ticket = music_handle(self)
	return a ~= nil and ticket > 0 and
		a:music_pause(ticket, flag(paused, true))
end

function IMusic:Resume()
	return self:Pause(false)
end

function IMusic:IsPlaying()
	local a, ticket = music_handle(self)
	return a ~= nil and ticket > 0 and a:music_is_playing(ticket)
end

function IMusic:IsPaused()
	local a, ticket = music_handle(self)
	return a ~= nil and ticket > 0 and a:music_is_paused(ticket)
end

function IMusic:SetVolume(value)
	local volume = gain(value)
	if volume == nil or rawget(self, "__released") then return false end
	self.__volume = volume
	local a, ticket = music_handle(self)
	if a and ticket > 0 then a:music_set_volume(ticket, volume) end
	return true
end

function IMusic:GetVolume()
	return rawget(self, "__volume") or 1
end

function IMusic:GetPosition()
	local a, ticket = music_handle(self)
	if a and ticket > 0 then return a:music_position_ms(ticket) end
	return 0
end

function IMusic:SetPosition(position_ms)
	local position = number(position_ms)
	local a, ticket = music_handle(self)
	return position ~= nil and a ~= nil and ticket > 0 and
		a:music_seek_ms(ticket, position)
end

function IMusic:GetLength()
	local a = rawget(self, "__audio")
	if a and not rawget(self, "__released") then
		return a:stream_length_ms(rawget(self, "__path") or "")
	end
	return 0
end

local function contains(list, value)
	for _, entry in ipairs(list) do
		if entry == value then return true end
	end
	return false
end

function IMusic:AddListener(listener)
	if rawget(self, "__released") then return false end
	if type(listener) ~= "table" and type(listener) ~= "function" then
		return false
	end
	local list = rawget(self, "__listeners")
	if not contains(list, listener) then list[#list + 1] = listener end
	return true
end

function IMusic:RemoveListener(listener)
	local list = rawget(self, "__listeners") or {}
	for index = #list, 1, -1 do
		if list[index] == listener then table.remove(list, index) end
	end
end

function IMusic:SetListener(listener)
	self.__listeners = {}
	if listener ~= nil then return self:AddListener(listener) end
	return true
end

function IMusic:Release()
	self:Stop()
	self.__released = true
	self.__valid = false
	self.__listeners = {}
end

function IMusic:__gc()
	pcall(IMusic.Release, self)
end

local function dispatch_music_finished(a, ticket)
	local music = active_music
	if not music or rawget(music, "__audio") ~= a or
		rawget(music, "__ticket") ~= ticket then
		return
	end

	active_music = nil
	music.__ticket = 0

	local batch = {}
	for index, listener in ipairs(rawget(music, "__listeners") or {}) do
		batch[index] = listener
	end

	for _, listener in ipairs(batch) do
		if rawget(music, "__released") then break end
		if contains(rawget(music, "__listeners") or {}, listener) then
			local ok, err = true, nil
			if type(listener) == "function" then
				ok, err = pcall(listener, music)
			else
				local callback = concrete_method(listener, "OnMusicEnd")
				if callback then ok, err = pcall(callback, listener, music) end
			end
			if not ok then print("[audio listener] " .. tostring(err)) end
		end
	end
end

-- App music uses the background player. Gameplay continues to use the
-- existing Host:start_music(id), preserving SceneView's rhythm-data loading.
function CGameAppClient:SetBGMusic(value)
	local id = positive_id(value)
	if not id then return false end

	local old = rawget(self, "__native_bg_music")
	if old and rawget(self, "__native_bg_music_id") == id and
		not rawget(old, "__released") then
		return old:Play(true, false)
	end

	local config = CMusicConfig:Inst()
	local path = config and config:GetMusicPath(id)
	if type(path) ~= "string" or path == "" then return false end

	local music = singleton:CreateMusic(path)
	if not music then return false end
	if not music:Play(true, true) then
		music:Release()
		return false
	end

	if old then old:Release() end
	self.__native_bg_music = music
	self.__native_bg_music_id = id
	return true
end

function CGameAppClient:PlayBGMusic()
	local music = rawget(self, "__native_bg_music")
	if music and not rawget(music, "__released") then
		return music:Play(true, false)
	end
	return CGameAppClient.SetBGMusic(
		self, rawget(self, "__native_bg_music_id") or self:GetSelectMusicID()
	)
end

function CGameAppClient:StopBGMusic()
	local music = rawget(self, "__native_bg_music")
	if music then music:Stop() end
end

function CGameAppClient:SetSelectMusicID(value)
	local id = positive_id(value)
	if not id then return false end
	self:GetIniFile():WriteInteger("Setting", "MusicID", id)
	return true
end

function CGameMain:ChangeMusic(value)
	local id = positive_id(value)
	local host = rawget(_G, "Host")
	if not id or not host then return false end
	refresh_settings()
	return host:start_music(id) ~= false
end

function CGameMain:PauseSceneMusic(paused)
	local a = refresh_settings()
	return a ~= nil and a:scene_pause(flag(paused, true))
end

local function table_button_path(value)
	if type(value) ~= "table" then return nil end
	local path = rawget(value, "string_0x64")
	if type(path) == "string" then return path end
	local window = rawget(value, "window")
	if type(window) == "table" then
		path = rawget(window, "string_0x64")
		if type(path) == "string" then return path end
	end
	return nil
end

function NativeButtonSound(node)
	local a = refresh_settings()
	if not a or node == nil then return false end

	local path = table_button_path(node)
	if path == nil then
		if type(node) == "table" then
			node = rawget(node, "__node") or node
		end

		local instance_id
		if type(node) == "number" then
			instance_id = node
		else
			local ok, id = pcall(function() return node:get_instance_id() end)
			if ok then instance_id = number(id) end
		end
		if not instance_id or instance_id <= 0 then return false end
		path = a:button_sound_path(instance_id)
	end

	if type(path) ~= "string" or path:match("^%s*$") then return false end
	-- A clip located under music/ still uses the sound bus when played as
	-- an effect. Classification follows the API, never the directory name.
	return singleton:PlaySound(path, 1)
end

local previous_tick = rawget(_G, "NativeTickUpdate")
local settings_elapsed = 100

function NativeTickUpdate(dt)
	if type(previous_tick) == "function" then previous_tick(dt) end

	-- The supplied native tick manager uses milliseconds.
	settings_elapsed = settings_elapsed + math.max(0, number(dt) or 0)
	if settings_elapsed >= 100 then
		settings_elapsed = 0
		refresh_settings()
	end

	local a = audio_host()
	if not a then return end
	for unused = 1, 64 do
		local ticket = a:take_finished_music()
		if not ticket or ticket == 0 then break end
		dispatch_music_finished(a, ticket)
	end
end

return singleton
