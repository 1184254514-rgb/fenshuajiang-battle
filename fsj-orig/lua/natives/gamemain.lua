-- Lua 5.4. Load after gui.lua, app.lua and scene.lua, before the original Lua.
--
-- GDScript integration: see PATCH_hud.md and scripts/hud_fx.gd.
-- Public integration globals:
--   GameMainInstallHooks()
--   NativeHUDObserveNodeCount(player, count)
--
-- Effect timers belong to Lua. Removing an effect cancels its visual only:
-- every AddEffect delivers one completion notification at its original deadline.
-- Durations are milliseconds; 0, negative and omitted durations use 600 ms.

local DEFAULT_EFFECT_MS = 600
local unpack_values = table.unpack
local pack_values = table.pack  -- captured: the original Help.lua later replaces table.pack

-- Read declared members without invoking the prelude's missing-native fallback.
local function lookup_class(cls, key, seen)
	if type(cls) ~= "table" then return nil end
	seen = seen or {}
	if seen[cls] then return nil end
	seen[cls] = true

	local value = rawget(cls, key)
	if value ~= nil then return value end

	local bases = rawget(cls, "__bases")
	if type(bases) == "table" then
		for _, base in ipairs(bases) do
			value = lookup_class(base, key, seen)
			if value ~= nil then return value end
		end
	end

	local index = rawget(cls, "__index")
	if type(index) == "table" and index ~= cls then
		value = lookup_class(index, key, seen)
		if value ~= nil then return value end
	end

	local mt = getmetatable(cls)
	if type(mt) == "table" then
		index = rawget(mt, "__index")
		if type(index) == "table" then
			return lookup_class(index, key, seen)
		end
	end
end

local function field(obj, key)
	if type(obj) == "table" then return rawget(obj, key) end
end

local function member(obj, key)
	if obj == nil then return nil end
	if type(obj) == "table" then
		local value = rawget(obj, key)
		if value ~= nil then return value end
		return lookup_class(getmetatable(obj), key)
	end
	local ok, value = pcall(function() return obj[key] end)
	if ok then return value end
end

local function invoke(obj, name, ...)
	local fn = member(obj, name)
	if fn == nil then return false, "Unavailable method: " .. name end
	return pcall(fn, obj, ...)
end

local function call(obj, name, ...)
	local ok, a, b, c = invoke(obj, name, ...)
	if ok then return a, b, c end
end

local function missing(cls, name, fn)
	if type(cls) == "table" and lookup_class(cls, name) == nil then
		rawset(cls, name, fn)
	end
end

local function number(value, default)
	value = tonumber(value)
	if value == nil or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	return value
end

local function boolean(value)
	return value ~= nil and value ~= false and value ~= 0
end

local function log_error(message)
	local text = "[HUD] " .. tostring(message)
	if not invoke(Host, "log", text) then print(text) end
end

local function view()
	return member(Host, "scene_view")
end

local function fx()
	return member(view(), "hud_fx")
end

local function scene()
	return call(g_App, "GetScene") or field(g_App, "__scene")
end

local function director()
	local sc = scene()
	if not sc then return nil end
	local player = call(g_App, "GetDirector") or field(sc, "m_pDirectorObj")
	local player_scene = field(player, "__scene") or call(player, "GetScene")
	if player_scene ~= nil and player_scene ~= sc then return nil end
	return player
end

local function component(vector, key, default)
	local value = member(vector, key)
	if type(value) == "function" then
		local ok, result = pcall(value, vector)
		if ok then return number(result, default) end
		return default
	end
	return number(value, default)
end

local function set_component(vector, key, value)
	local setter = member(vector, key)
	if type(setter) == "function" then
		setter(vector, value)
	elseif type(vector) == "table" then
		rawset(vector, key, value)
	else
		vector[key] = value
	end
end

local function write_vector(vector, x, y)
	vector = vector or CVector2f:new()
	set_component(vector, "x", x)
	set_component(vector, "y", y)
	return vector
end

local function connect_ui_root()
	local root = call(Host, "root_wnd")
	if root ~= nil then
		invoke(view(), "set_ui_root", root)
		invoke(fx(), "set_ui_root", root)
	end
end

local mains = setmetatable({}, { __mode = "k" })
local peaks = setmetatable({}, { __mode = "k" })
local pending_effects = {}
local next_effect_id = 0
local hud_time_ms = 0

-- ---------------------------------------------------------------- camera

local Camera = {}
Camera.__index = Camera

local camera = setmetatable({ fallback_scale = 2 }, Camera)
CGameMain.__cameraObj = camera

function Camera:GetScene()
	return scene()
end

function Camera:GetScale()
	return number(call(view(), "get_camera_scale"), self.fallback_scale)
end

function Camera:SetScale(value)
	value = math.max(0.1, math.min(16, number(value, self:GetScale())))
	self.fallback_scale = value
	invoke(view(), "set_camera_scale", value)
	return value
end

function Camera:GetRadian()
	-- SceneView does not rotate the world.
	return 0
end

function Camera:ScenePosToUIPos(x, y, out)
	if type(x) ~= "number" then
		local position = x
		out = y
		x = component(position, "x", 0)
		y = component(position, "z", nil) or component(position, "y", 0)
	end

	x, y = number(x, 0), number(y, 0)
	local screen_position = call(view(), "world_to_screen", x, y)
	local sx = component(screen_position, "x", nil)
	local sy = component(screen_position, "y", nil)

	if sx == nil or sy == nil then
		-- Headless/unpatched fallback matching the supplied SceneView camera.
		local center = member(view(), "cam")
		local offset = member(view(), "camera_offset")
		local cx = component(center, "x", 960) + component(offset, "x", 0)
		local cy = component(center, "y", 960) + component(offset, "y", 0)
		sx = (x - cx) * self:GetScale() + 640
		sy = (y - cy) * self:GetScale() + 360
	end

	-- Mutate the caller's native vector; do not replace its x()/y() accessors.
	return write_vector(out, sx, sy)
end

function CGameMain:GetCamera()
	self.__camera = camera
	return camera
end

function CGameAppClient:GetCamera()
	return camera
end

function CGameAppClient:ScenePosToUIPos(position, selected_camera, out)
	selected_camera = selected_camera or camera
	local x = component(position, "x", 0)
	-- The original scene uses a 3D X/Z ground plane.
	local y = component(position, "z", nil) or component(position, "y", 0)
	out = out or CVector2f:new()

	local ok, result = invoke(selected_camera, "ScenePosToUIPos", x, y, out)
	if ok then return result or out end
	return camera:ScenePosToUIPos(x, y, out)
end

function CGameMain:ScenePosToUIPos(x, y, out)
	if type(x) == "number" then
		return camera:ScenePosToUIPos(x, y, out)
	end
	return CGameAppClient.ScenePosToUIPos(g_App, x, y, out)
end

missing(CGameScene, "GetCamera", function() return camera end)

missing(CGameScene, "GetScale", function(self)
	if scene() == self then return camera:GetScale() end
	return field(self, "__hud_scale") or 2
end)

missing(CGameScene, "SetScale", function(self, value)
	value = math.max(0.1, math.min(16, number(value, 2)))
	self.__hud_scale = value
	if scene() == self then camera:SetScale(value) end
	return value
end)

missing(CGameScene, "AddOffset", function(self, offset)
	if scene() ~= self then return false end
	-- The debug callers use positive native Y for "up".
	return invoke(view(), "add_camera_offset",
		component(offset, "x", 0), -component(offset, "y", 0))
end)

-- ---------------------------------------------------------------- HUD geometry helpers

missing(CVector2f, "NormalizeNoneZero", function(self)
	local x, y = component(self, "x", 0), component(self, "y", 0)
	local length = math.sqrt(x * x + y * y)
	if length > 0 then write_vector(self, x / length, y / length) end
	return self
end)

missing(CDir, "uDir", function(self, value)
	if value ~= nil then
		self.__hud_direction = math.floor(number(value, 0)) % 256
	end
	return field(self, "__hud_direction") or 0
end)

missing(CDir, "Set", function(self, vector)
	local x, y = component(vector, "x", 0), component(vector, "y", 0)
	-- 0 = up, 64 = right, 128 = down, 192 = left.
	local angle = math.atan(x, y) % (2 * math.pi)
	self:uDir(math.floor(angle * 256 / (2 * math.pi) + 0.5) % 256)
	return self
end)

missing(CDir, "GetRadian", function(self)
	return number(call(self, "uDir"), 0) * (2 * math.pi / 256)
end)

if rawget(_G, "Cut2DLine") == nil then
	function Cut2DLine(rect, start_position, end_position)
		local left = component(rect, "left", 0)
		local top = component(rect, "top", 0)
		local right = component(rect, "right", 0)
		local bottom = component(rect, "bottom", 0)
		if right < left or bottom < top then return false end

		local x, y = component(start_position, "x", 0), component(start_position, "y", 0)
		local dx = component(end_position, "x", x) - x
		local dy = component(end_position, "y", y) - y
		local enter, leave = 0, 1

		local function clip(p, q)
			if p == 0 then return q >= 0 end
			local ratio = q / p
			if p < 0 then
				if ratio > leave then return false end
				enter = math.max(enter, ratio)
			else
				if ratio < enter then return false end
				leave = math.min(leave, ratio)
			end
			return true
		end

		if not (clip(-dx, x - left) and clip(dx, right - x)
			and clip(-dy, y - top) and clip(dy, bottom - y)) then
			return false
		end

		write_vector(start_position, x + enter * dx, y + enter * dy)
		write_vector(end_position, x + leave * dx, y + leave * dy)
		return true
	end
end

-- ---------------------------------------------------------------- window transforms / small HUD properties

missing(CGWnd, "DoMove", function(self, x, y, duration_ms)
	x, y = number(x, 0), number(y, 0)
	duration_ms = math.max(0, number(duration_ms, 0))
	local ok, moved = invoke(fx(), "move_window", field(self, "__node"),
		x, y, duration_ms, false)
	if not ok or moved ~= true then
		invoke(self, "SetLocalX", x)
		invoke(self, "SetLocalY", y)
	end
	return self
end)

missing(CGWnd, "GetScaleX", function(self)
	return number(call(fx(), "get_scale_x", field(self, "__node")),
		number(component(member(field(self, "__node"), "scale"), "x", nil),
			field(self, "__hud_scale_x") or 1))
end)

missing(CGWnd, "GetScaleY", function(self)
	return number(call(fx(), "get_scale_y", field(self, "__node")),
		number(component(member(field(self, "__node"), "scale"), "y", nil),
			field(self, "__hud_scale_y") or 1))
end)

missing(CGWnd, "SetScaleX", function(self, value)
	value = number(value, 1)
	self.__hud_scale_x = value
	invoke(fx(), "set_scale", field(self, "__node"),
		value, number(call(self, "GetScaleY"), 1))
end)

missing(CGWnd, "SetScaleY", function(self, value)
	value = number(value, 1)
	self.__hud_scale_y = value
	invoke(fx(), "set_scale", field(self, "__node"),
		number(call(self, "GetScaleX"), 1), value)
end)

missing(CGWnd, "SetScale", function(self, x, y)
	if type(x) ~= "number" then
		local vector = x
		x, y = component(vector, "x", 1), component(vector, "y", 1)
	end
	x, y = number(x, 1), number(y, number(x, 1))
	invoke(self, "SetScaleX", x)
	invoke(self, "SetScaleY", y)
	return self
end)

missing(CGWnd, "SetRotationZ", function(self, radians)
	radians = number(radians, 0)
	self.__hud_rotation = radians
	invoke(fx(), "set_rotation", field(self, "__node"), radians)
end)

missing(CGWnd, "GetRotationZ", function(self)
	return number(member(field(self, "__node"), "rotation"),
		field(self, "__hud_rotation") or 0)
end)

missing(CGWnd, "SetFade", function(self, value)
	value = math.max(0, math.min(255, number(value, 255)))
	self.__hud_fade = value
	invoke(fx(), "set_fade", field(self, "__node"), value)
end)

missing(CGWnd, "GetFade", function(self)
	return number(call(fx(), "get_fade", field(self, "__node")),
		field(self, "__hud_fade") or 255)
end)

missing(CGWnd, "SetFadeDuration", function(self, duration_ms)
	self.__hud_fade_duration = math.max(0, number(duration_ms, 0))
end)

missing(CGWnd, "GetFadeDuration", function(self)
	return field(self, "__hud_fade_duration") or 0
end)

missing(CGWnd, "SetWndData", function(self, value)
	self.__hud_wnd_data = value
end)

missing(CGWnd, "GetWndData", function(self)
	local value = field(self, "__hud_wnd_data")
	if value == nil then return 0 end
	return value
end)

missing(CGWnd, "SetLockFlag", function(self, flags)
	flags = math.floor(number(flags, 0))
	self.__hud_lock_flags = flags
	invoke(fx(), "set_locks", field(self, "__node"), flags,
		LOCK_LEFT or eDF_Left or 1, LOCK_RIGHT or eDF_Right or 2,
		LOCK_TOP or eDF_Up or 4, LOCK_BOTTOM or eDF_Bottom or 8)
end)

missing(CGWnd, "GetLockFlag", function(self)
	return field(self, "__hud_lock_flags") or 0
end)

missing(CGWnd, "GetStrWidth", function(self, text)
	text = tostring(text or "")
	local width = call(fx(), "get_str_width", field(self, "__node"), text)
	if type(width) == "number" then return width end
	local ok, length = pcall(utf8.len, text)
	return (ok and length or #text) * 9
end)

local function update_progress(self)
	invoke(fx(), "set_progress", field(self, "__node"),
		field(self, "__hud_progress") or 0, field(self, "__hud_range") or 0)
end

missing(CGWnd, "SetRange", function(self, maximum)
	self.__hud_range = math.max(0, number(maximum, 0))
	self.__hud_progress = math.max(0,
		math.min(self.__hud_range, field(self, "__hud_progress") or 0))
	update_progress(self)
end)

missing(CGWnd, "GetRange", function(self)
	return field(self, "__hud_range") or 0
end)

missing(CGWnd, "SetPos", function(self, position)
	local maximum = number(call(self, "GetRange"), 0)
	self.__hud_range = maximum
	self.__hud_progress = math.max(0, math.min(maximum, number(position, 0)))
	update_progress(self)
end)

missing(CGWnd, "GetPos", function(self)
	return field(self, "__hud_progress") or 0
end)

-- Keep the original native ShowWnd notification path. Only the rendered
-- visibility may linger during a fade; IsShow reflects the requested state.
local original_show = lookup_class(CGWnd, "ShowWnd")
local original_is_show = lookup_class(CGWnd, "IsShow")

function CGWnd:IsShow()
	local requested = field(self, "__hud_requested_show")
	if requested ~= nil then return requested end
	if original_is_show then return boolean(original_is_show(self)) end
	return boolean(member(field(self, "__node"), "visible"))
end

function CGWnd:ShowWnd(value, ...)
	local show = boolean(value)
	local previous = CGWnd.IsShow(self)
	local serial = (field(self, "__hud_show_serial") or 0) + 1
	self.__hud_show_serial = serial
	self.__hud_requested_show = show

	local result
	if original_show then
		result = pack_values(original_show(self, show, ...))
	else
		invoke(field(self, "__node"), "show_wnd", show)
		if previous ~= show then invoke(self, "OnWndShow", show) end
		result = pack_values()
	end

	if self.__hud_show_serial == serial and previous ~= show then
		local duration = field(self, "__hud_fade_duration")
		if duration ~= nil then
			invoke(fx(), "show_window", field(self, "__node"),
				show, duration, previous)
		end
	end
	return unpack_values(result, 1, result.n)
end

missing(CGWnd, "GetShowFlag", function(self)
	return CGWnd.IsShow(self)
end)

-- ---------------------------------------------------------------- effects

local function cancel_visual(effect)
	effect.cancelled = true
	invoke(fx(), "stop_effect", effect.node, effect.id)
end

function CGWnd:AddEffect(file_name, effect_name, attach_name, duration_ms,
		flag1, flag2, flag3, effect_scale)
	duration_ms = number(duration_ms, 0)
	local requested_ms = duration_ms
	if duration_ms <= 0 then duration_ms = DEFAULT_EFFECT_MS end

	next_effect_id = next_effect_id + 1
	local effect = {
		id = next_effect_id,
		window = self,
		node = field(self, "__node"),
		file = file_name,
		name = effect_name,
		attach = attach_name == nil and "" or tostring(attach_name),
		deadline = hud_time_ms + duration_ms,
		duration = duration_ms,
		cancelled = false,
		completed = false,
		requested_ms = requested_ms,
	}

	local effects = field(self, "__hud_effects")
	if effects == nil then
		effects = {}
		self.__hud_effects = effects
	end
	effects[effect.id] = effect
	pending_effects[#pending_effects + 1] = effect

	-- Original .eft playback (Claude); the placeholder pulse only when the effect file is unknown.
	local ok, played = invoke(fx(), "play_eft", effect.node, effect.id, tostring(file_name or ""),
		tostring(effect_name or ""), (effect.requested_ms or 0) < 0)
	if not ok or played ~= true then
		local label = tostring(effect_name or ""):match("^fx/(%d+)$") or ""
		invoke(fx(), "play_effect", effect.node, effect.id, duration_ms, label,
			math.max(0, number(effect_scale, 1)), effect_name == "fx/fly")
	end

	return effect.id
end

function CGWnd:GetAttachEffectName(token)
	if type(token) == "string" then return token end
	local effects = field(self, "__hud_effects")
	local effect = effects and effects[token]
	return effect and effect.attach or ""
end

function CGWnd:RemoveEffect(token_or_attach)
	local effects = field(self, "__hud_effects")
	if effects == nil then return end
	for id, effect in pairs(effects) do
		if id == token_or_attach or effect.attach == token_or_attach then
			cancel_visual(effect)
		end
	end
end

function CGWnd:RemoveAllEffects()
	local effects = field(self, "__hud_effects")
	if effects ~= nil then
		for _, effect in pairs(effects) do cancel_visual(effect) end
	end
end

local function destroy_flight(window)
	if field(window, "__hud_flight_destroyed") then return end
	window.__hud_flight_destroyed = true
	invoke(window, "DestroyWnd")
end

function CGWnd:AddEffectFly(start_x, start_y, end_x, end_y, file_name)
	start_x, start_y = number(start_x, 0), number(start_y, 0)
	end_x, end_y = number(end_x, start_x), number(end_y, start_y)

	local window = CGWnd:new()
	invoke(window, "CreatAsEmptyContain", self, 30, 30)
	invoke(window, "SetGlobalX", start_x)
	invoke(window, "SetGlobalY", start_y)

	local style = math.floor(number(call(window, "GetStyle"), 0))
	style = style | (eWS_TOPMOST or 0) | (eWS_MSGTRANSPT or 0)
	invoke(window, "SetStyle", style)
	invoke(window, "ShowWnd", true)

	-- Match the original 25 UI pixels per 33 ms; zero-distance flights finish.
	local dx, dy = end_x - start_x, end_y - start_y
	local duration = math.max(1, math.ceil(math.sqrt(dx * dx + dy * dy) * 33 / 25))
	local token = CGWnd.AddEffect(window, file_name, "fx/fly", "loop", duration)

	local flights = field(self, "__hud_flights")
	if flights == nil then flights = {}; self.__hud_flights = flights end
	flights[window] = true

	window.__hud_effects[token].after_complete = function()
		flights[window] = nil
		destroy_flight(window)
	end

	local ok, moved = invoke(fx(), "move_window", field(window, "__node"),
		end_x, end_y, duration, true)
	if not ok or moved ~= true then
		invoke(window, "SetGlobalX", end_x)
		invoke(window, "SetGlobalY", end_y)
	end
	return window
end

CGameMain.AddEffectFly = CGWnd.AddEffectFly

missing(CGWnd, "SetEffectText", function(self, file_name, text, rgb, duration_ms)
	local ok, shown = invoke(fx(), "play_effect_text", field(self, "__node"), tostring(text or ""),
		math.floor(number(rgb, 0xFFFFFF)), number(duration_ms, 1000))
	if ok and shown then invoke(self, "ShowWnd", true) return true end
	invoke(self, "SetWndText", tostring(text or ""))
	local color = math.floor(number(rgb, 0xFFFFFF))
	if color >= 0 and color <= 0xFFFFFF then color = color | 0xFF000000 end
	invoke(self, "SetWndTextColor", GSM_BS_BK, eST_ENABLE, color)
	invoke(self, "ShowWnd", true)
	return CGWnd.AddEffect(self, file_name, "fx/loop", "text", duration_ms)
end)

local function complete_effect(effect)
	if effect.completed then return end
	effect.completed = true
	invoke(fx(), "stop_effect", effect.node, effect.id)

	-- Keep the token->attachment mapping until OnMsgDispatch and all synchronous
	-- listeners have returned. ui_frame/CGWnd.lua translates wParam through it.
	local message = rawget(_G, "GM_WM_FX_PLAYCOMPLETE")
	if message ~= nil then
		local ok, err = invoke(effect.window, "OnMsgDispatch",
			0, effect.window, message, effect.id, 0)
		if not ok then log_error("Effect completion: " .. tostring(err)) end
	else
		log_error("GM_WM_FX_PLAYCOMPLETE is unavailable; load natives_consts.lua first")
	end

	local effects = field(effect.window, "__hud_effects")
	if effects ~= nil and effects[effect.id] == effect then
		effects[effect.id] = nil
	end
	if effect.after_complete then
		local ok, err = pcall(effect.after_complete)
		if not ok then log_error(err) end
	end
end

local function pump_effects()
	local waiting, due = {}, {}
	for _, effect in ipairs(pending_effects) do
		if not effect.completed then
			if hud_time_ms >= effect.deadline then
				due[#due + 1] = effect
			else
				waiting[#waiting + 1] = effect
			end
		end
	end

	-- Detach the batch before invoking listeners; callbacks may enqueue effects.
	pending_effects = waiting
	for _, effect in ipairs(due) do complete_effect(effect) end
end

-- ---------------------------------------------------------------- audio

local function native_audio()
	local factory = rawget(_G, "NativeAudio")
	if type(factory) ~= "function" then return nil end
	local ok, audio = pcall(factory)
	if ok then return audio end
end

local audio_renderers = setmetatable({}, { __mode = "k" })
local fallback_renderer = { GetAudio = function() return native_audio() end }

local function expose_audio(renderer)
	if renderer == nil then return fallback_renderer end
	-- app.lua's Renderer is a Lua object. Preserve its other capabilities.
	if type(renderer) == "table" and not audio_renderers[renderer] then
		audio_renderers[renderer] = true
		local old_get_audio = member(renderer, "GetAudio")
		renderer.GetAudio = function(self)
			local audio = native_audio()
			if audio ~= nil then return audio end
			if old_get_audio then
				local ok, old_audio = pcall(old_get_audio, self)
				if ok then return old_audio end
			end
			return nil
		end
	end
	return renderer
end

local function install_audio_renderer(cls)
	local original = lookup_class(cls, "GetRenderer")
	rawset(cls, "GetRenderer", function(self)
		local renderer
		if original then renderer = original(self) end
		return expose_audio(renderer)
	end)
end

install_audio_renderer(CGWnd)
install_audio_renderer(CGameAppClient)

missing(CGameAppClient, "GetAudio", function(self)
	return native_audio() or call(call(self, "GetRenderer"), "GetAudio")
end)

function CGameMain:RegisterSound(kind, file_name, volume)
	self.m_tblSound = field(self, "m_tblSound") or {}
	self.__hud_sound_specs = field(self, "__hud_sound_specs") or {}
	volume = math.max(0, math.min(1, number(volume, 1)))
	self.__hud_sound_specs[kind] = { file_name, volume }

	local previous = self.m_tblSound[kind]
	self.m_tblSound[kind] = nil
	if previous ~= nil then invoke(previous, "Release") end

	local audio = native_audio() or call(call(self, "GetRenderer"), "GetAudio")
	local sound = call(audio, "CreateSound", file_name, false)
	if sound ~= nil then
		self.m_tblSound[kind] = sound
		invoke(sound, "SetVolume", volume)
	end
	return sound
end

function CGameMain:PlaySound(kind)
	local sounds = field(self, "m_tblSound") or {}
	local sound = sounds[kind]
	if sound == nil then
		local specs = field(self, "__hud_sound_specs") or {}
		local spec = specs[kind]
		if spec then sound = CGameMain.RegisterSound(self, kind, spec[1], spec[2]) end
	end
	if sound == nil then return false end
	local ok, result = invoke(sound, "Play", false, true)
	return ok and result ~= false
end

function CGameMain:DestoryAllSound()
	local sounds = field(self, "m_tblSound") or {}
	self.m_tblSound = {}
	self.__hud_sound_specs = {}
	for _, sound in pairs(sounds) do invoke(sound, "Release") end
end

CGameMain.DestroyAllSound = CGameMain.DestoryAllSound

function CGameMain:PauseSceneMusic(pause)
	self.__hud_music_paused = boolean(pause)
	invoke(view(), "set_music_paused", self.__hud_music_paused)
end

function CGameMain:ChangeMusic(music_id)
	local sc = scene()
	if sc == nil then return false end
	music_id = math.floor(number(music_id, 0))
	local ok, result = invoke(Host, "start_music", music_id)
	if not ok or result == false then return false end

	-- Music selection is presentation state; movement/judging rules are unchanged.
	sc.__musicID = music_id
	if field(self, "__hud_music_paused") then
		invoke(view(), "set_music_paused", true)
	end
	return true
end

missing(CGameAppClient, "SetSelectMusicID", function(self, music_id)
	return invoke(call(self, "GetIniFile"), "SetInteger",
		"Setting", "MusicID", math.floor(number(music_id, 0)))
end)

-- ---------------------------------------------------------------- rhythm window

local Rhythm = {}
Rhythm.__index = Rhythm

function Rhythm:_sync()
	local parent_visible = field(self.owner, "__hud_visible")
	if parent_visible == nil then parent_visible = CGWnd.IsShow(self.owner) end
	local visible = self.running and self.shown and parent_visible
	invoke(view(), "set_rhythm_visible", boolean(visible))
end

function Rhythm:Start(notice_bar_id)
	self.notice_bar_id = math.floor(number(notice_bar_id, 0))
	self.running, self.shown = true, true
	-- Skin ID is retained; the current renderer uses one placeholder bar.
	-- Starting this window must not restart music or change its beat clock.
	invoke(view(), "start_rhythm", self.notice_bar_id)
	self:_sync()
	return true
end

function Rhythm:ShowWnd(show)
	self.shown = boolean(show)
	self:_sync()
end

function Rhythm:IsShow()
	return self.shown == true
end

function Rhythm:Stop()
	self.running, self.shown = false, false
	self:_sync()
end

Rhythm.Clear = Rhythm.Stop

function Rhythm:GetParent() return self.owner end
function Rhythm:GetNoticeBarID() return self.notice_bar_id or 0 end
function Rhythm:IsCreated() return field(self.owner, "__node") ~= nil end

function CGameMain:GetRhythmWnd()
	local rhythm = field(self, "__rhythmWnd")
	if getmetatable(rhythm) ~= Rhythm then
		rhythm = setmetatable({
			owner = self, running = false, shown = false, notice_bar_id = 0,
		}, Rhythm)
		self.__rhythmWnd = rhythm
	end
	return rhythm
end

-- ---------------------------------------------------------------- read-only HUD data

function NativeHUDObserveNodeCount(player, count)
	if player == nil then return end
	count = math.max(0, number(count, 0))
	peaks[player] = math.max(peaks[player] or 0, count)
end

local function node_count(player)
	return math.max(0, number(call(call(player, "GetManor"), "GetNodeCount"), 0))
end

local function maximum_nodes(player)
	if player == nil then return 0 end
	NativeHUDObserveNodeCount(player, node_count(player))
	return peaks[player] or 0
end

function CGameMain:GetMaxNodeCount()
	local sc = scene()
	if sc ~= nil and sc == field(self, "__hud_scene") then
		self.__hud_max_nodes = math.max(field(self, "__hud_max_nodes") or 0,
			maximum_nodes(director()))
	end
	return field(self, "__hud_max_nodes") or 0
end

missing(CPlayerClient, "GetPixelPos", function(self)
	return CVector2f:new(number(field(self, "__x"), 0), number(field(self, "__y"), 0))
end)

missing(CPlayerClient, "GetColorID", function(self)
	return number(call(call(self, "GetManor"), "GetColorID"), 0)
end)

missing(CPlayerClient, "GetHeadIconID", function(self)
	return field(self, "__headID") or 0
end)

local original_property = lookup_class(CPlayerClient, "GetSimple32Property")
function CPlayerClient:GetSimple32Property(property)
	local stats = field(self, "__stats") or {}
	local rhythm = field(self, "__rhythm") or {}

	if property ~= nil then
		if property == eSPT32_MaxAreaScore then return maximum_nodes(self) end
		if property == eSPT32_MaxComboCount then return rhythm.maxCombo or 0 end
		if property == eSPT32_PickUpCoin then return stats.pickUpCoin or 0 end
		if property == eSPT32_KillScore then return stats.killScore or 0 end
		if property == eSPT32_ComboScore then return stats.comboScore or 0 end
	end
	if original_property then return original_property(self, property) end
	return 0
end

-- Observer selection changes the camera only; it never changes the director.
function CGameScene:GetObservedPlayer()
	local account_id = field(self, "__hud_observed_account") or 0
	if account_id == 0 then return nil end
	return call(self, "GetPlayerByAccountID", account_id)
end

function CGameScene:GetObservedPlayerID()
	if self:GetObservedPlayer() == nil then return 0 end
	return field(self, "__hud_observed_account") or 0
end

function CGameScene:IsObservedPlayer(player)
	return player ~= nil and player == self:GetObservedPlayer()
end

function CGameScene:IsObserveredID(account_id)
	return account_id ~= nil and account_id ~= 0
		and account_id == self:GetObservedPlayerID()
end

function CGameScene:ChangeObservedPlayer(account_id)
	account_id = number(account_id, 0)
	local player
	if account_id ~= 0 then
		player = call(self, "GetPlayerByAccountID", account_id)
		if player == nil then return false end
	end
	self.__hud_observed_account = account_id
	if scene() == self then
		local target = player or director()
		invoke(view(), "set_follow", number(call(target, "GetObjectID"), -1))
	end
	return true
end

missing(CGameScene, "ChangeView", function(self)
	local accounts = {}
	for _, player in ipairs(field(self, "__order") or {}) do
		local account_id = number(call(player, "GetAccountID"), 0)
		if account_id > 0 and boolean(call(player, "IsAlive")) then
			accounts[#accounts + 1] = account_id
		end
	end
	table.sort(accounts)
	if #accounts == 0 then return self:ChangeObservedPlayer(0) end

	local current = self:GetObservedPlayerID()
	for i, account_id in ipairs(accounts) do
		if account_id == current then
			return self:ChangeObservedPlayer(accounts[i % #accounts + 1])
		end
	end
	return self:ChangeObservedPlayer(accounts[1])
end)

-- ---------------------------------------------------------------- tutorial tips

local tip_keys = {
	{ "eMUT_ClickRhythmly", "genjiezou" },
	{ "eMUT_NoLongPress", "biechangan" },
	{ "eMUT_LineTooLong", "xiantaichang" },
	{ "eMUT_StrikeOthers", "zhuangxian" },
	{ "eMUT_MakeManor", "shengchenglingdi" },
	{ "eMUT_StrikeSelf", "xiaochuxian" },
	{ "eMUT_Died", "qiexian" },
}

local function contains(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then return true end
	end
	return false
end

local function tips_allowed(self)
	local sc = scene()
	if sc == nil or field(self, "m_bObserveGame") then return false end
	if eRT_Guide ~= nil and call(sc, "GetRoomType") == eRT_Guide then return false end
	local data = call(g_App, "GetMainPlayerData")
	local base = member(data, "m_CharBaseData")
	local score = number(call(base, "GetAllGameScore"), 0)
	local constants = call(CSnakeConstant, "Inst")
	local limit = number(call(constants, "GetStopTishiScore"), math.huge)
	return score < limit
end

local function count_tip(index)
	local sc = scene()
	if not sc or eRT_Endless == nil or call(sc, "GetRoomType") ~= eRT_Endless then return end
	if type(g_App) ~= "table" then return end
	local counts = field(g_App, "__hud_tip_counts")
	if counts == nil then counts = {}; g_App.__hud_tip_counts = counts end
	counts[index] = (counts[index] or 0) + 1
end

missing(CGameAppClient, "GetEndlessTipCount", function(self, index)
	return (field(self, "__hud_tip_counts") or {})[index] or 0
end)

local function render_tip(self)
	local list = field(self, "m_tblTip") or {}
	local window = field(self, "m_pWndTyro")
	local index = list[#list]
	local key

	for _, entry in ipairs(tip_keys) do
		local value = rawget(_G, entry[1])
		if value ~= nil and index == value then key = entry[2]; break end
	end

	if key == nil then
		invoke(window, "ShowWnd", false)
		return false
	end

	local text = call(call(CStringConfig, "Inst"), "GetString", key) or key
	invoke(member(window, "m_wndContent"), "SetWndText", text)
	if type(window) == "table" then window.m_nLastTipIndex = index end
	invoke(window, "ShowWnd", true)
	return true
end

function CGameMain:TyroTipHelp(index, show)
	if index == nil then return false end
	if not tips_allowed(self) then
		self.m_tblTip = {}
		self.__hud_tip_deadline = nil
		invoke(field(self, "m_tickCloseTip"), "Stop")
		invoke(field(self, "m_pWndTyro"), "ShowWnd", false)
		return false
	end

	local old = field(self, "m_tblTip") or {}
	local existed = contains(old, index)
	local list = {}
	local transient = number(eMUT_TickDisappear, math.huge)
	show = boolean(show)

	for _, value in ipairs(old) do
		if show then
			if value < transient then list[#list + 1] = value end
		elseif value ~= index then
			list[#list + 1] = value
		end
	end

	if show and not contains(list, index) then list[#list + 1] = index end
	self.m_tblTip = list

	if show and index >= transient then
		self.__hud_tip_index = index
		self.__hud_tip_deadline = hud_time_ms + 2000
	elseif not show and field(self, "__hud_tip_index") == index then
		self.__hud_tip_deadline = nil
	end

	local visible = render_tip(self)
	if show and not existed and visible then count_tip(index) end
	return visible
end

-- ---------------------------------------------------------------- base lifecycle

local tick_fields = {
	"m_tickEffectFly", "m_tickHideDoubleGrade", "m_tickCloseTip", "m_pTick",
	"m_tickDianzan", "m_tickCountDownTime", "m_tickUpdateWnd",
}

local transient_fields = {
	"m_pWndTyro", "m_pStartWnd", "m_pWndCountDown", "m_pWndDoubleGradeText",
	"m_pWndTaskTips", "m_wndFirst", "m_pWndRank1", "m_pWndRank2", "m_pGameButton",
	"m_wndOutInfo", "m_pObserve", "m_pHeadWnd",
}

local function hide_arrows(self)
	for _, key in ipairs({ "m_aryTrackTip", "m_aryTrackTipForTeam" }) do
		for _, window in pairs(field(self, key) or {}) do
			invoke(window, "ShowWnd", false)
		end
	end
end

local function belongs_to(window, parent)
	if window == parent then return true end
	local parent_node, node = field(parent, "__node"), field(window, "__node")
	return parent_node ~= nil and node ~= nil
		and call(parent_node, "is_ancestor_of", node) == true
end

function CGameMain:Clear()
	self.__hud_running = false
	self.__hud_pending_start = nil
	self.__hud_pending_show = nil
	self.__hud_tip_deadline = nil
	CGameMain.GetRhythmWnd(self):Stop()

	for _, key in ipairs(tick_fields) do invoke(field(self, key), "Stop") end
	local buttons = field(self, "m_pGameButton")
	invoke(field(buttons, "m_tickPress"), "Stop")
	invoke(field(buttons, "m_tickSkillCD"), "Stop")
	invoke(field(self, "m_pKillInfoWnd"), "ClearKillInfo")

	self.m_tblTip = {}
	self.m_tblDianzan = {}
	for _, key in ipairs(transient_fields) do invoke(field(self, key), "ShowWnd", false) end
	hide_arrows(self)

	for window in pairs(field(self, "__hud_flights") or {}) do destroy_flight(window) end
	self.__hud_flights = {}
	for _, window in pairs(field(self, "m_tblEffectFly") or {}) do
		invoke(window, "DestroyWnd")
	end
	self.m_tblEffectFly = {}

	local task_tip = field(self, "m_pWndTaskTips") -- This popup is a sibling of GameMain.
	for _, effect in ipairs(pending_effects) do
		if belongs_to(effect.window, self) or effect.window == task_tip then
			cancel_visual(effect)
		end
	end
	invoke(fx(), "cancel_tree", field(self, "__node"))
	invoke(fx(), "cancel_tree", field(task_tip, "__node"))

	for _, sound in pairs(field(self, "m_tblSound") or {}) do invoke(sound, "Stop") end
	-- Preserve the last peak for settlement callers. Start resets the round.
	return true
end

function CGameMain:Start()
	CGameMain.Clear(self)
	local sc = scene()
	if sc == nil then return false end

	mains[self] = true
	self.__hud_scene = sc
	self.__hud_running = true
	self.__hud_visible = CGWnd.IsShow(self)
	self.__hud_max_nodes = 0
	self.__hud_music_paused = false
	if type(g_App) == "table" then g_App.__hud_tip_counts = {} end
	connect_ui_root()
	invoke(view(), "set_music_paused", false)
	CGameMain.GetMaxNodeCount(self)
	-- native part: the engine's debug FPS readout is hidden in release builds (Claude)
	local fps = self:GetDlgChild("W_fps")
	if fps then fps:ShowWnd(false) end
	return true
end

function CGameMain:OnWndShow(show)
	-- CGameMainLua passes the misspelled global bSHow. Native ShowWnd and the
	-- post-load wrapper retain the real argument so nil is not mistaken for hide.
	if show == nil then
		show = field(self, "__hud_requested_show")
		if show == nil then show = CGWnd.IsShow(self) end
	end
	self.__hud_visible = boolean(show)
	if self.__hud_visible then
		CGameMain.GetRhythmWnd(self):_sync()
	else
		CGameMain.Clear(self)
	end
end

function CGameMain:OnCreated()
	mains[self] = true
	connect_ui_root()
	CGameMain.GetRhythmWnd(self)
	self.__camera = camera
	local base = lookup_class(CGWnd, "OnCreated")
	if type(base) == "function" then base(self) end
end

function CGameMain:OnDestroy()
	CGameMain.Clear(self)
	CGameMain.DestoryAllSound(self)
	mains[self] = nil
	local base = lookup_class(CGWnd, "OnDestroy")
	if type(base) == "function" then base(self) end
end

-- Retain scene.lua's direction/rhythm implementation, adding only nil/stale-scene guards.
local original_click_dir = lookup_class(CGameMain, "ClickDir")
if original_click_dir then
	function CGameMain:ClickDir(direction)
		if scene() == nil or director() == nil or view() == nil then return end
		return original_click_dir(self, direction)
	end
end

-- ---------------------------------------------------------------- original-script integration

local function main_ready(self)
	local rank1 = field(self, "m_pWndRank1")
	local rank2 = field(self, "m_pWndRank2")
	local tyro = field(self, "m_pWndTyro")
	local buttons = field(self, "m_pGameButton")
	return field(self, "m_pTick") ~= nil
		and field(tyro, "m_wndContent") ~= nil
		and field(buttons, "m_pBtnTop") ~= nil
		and field(field(rank1, "pWndSelfRank"), "m_wndName") ~= nil
		and field(field(rank2, "pWndSelfRank"), "m_wndName") ~= nil
end

local function hide_rank(self)
	invoke(field(self, "m_wndFirst"), "ShowWnd", false)
	invoke(field(self, "m_pWndRank1"), "ShowWnd", false)
	invoke(field(self, "m_pWndRank2"), "ShowWnd", false)
	hide_arrows(self)
end

function GameMainInstallHooks()
	local cls = rawget(_G, "CGameMainLua")
	if type(cls) ~= "table" or rawget(cls, "__hud_hooks_installed") then return end
	local original_start = rawget(cls, "Start")
	if type(original_start) ~= "function" then return end
	cls.__hud_hooks_installed = true

	-- These Lua overrides would otherwise bypass the newly supplied natives.
	-- Their original files remain unchanged.
	cls.RegisterSound = CGameMain.RegisterSound
	cls.PlaySound = CGameMain.PlaySound
	cls.DestoryAllSound = CGameMain.DestoryAllSound
	cls.AddEffectFly = CGameMain.AddEffectFly

	cls.Start = function(self, ...)
		if scene() == nil then return CGameMain.Clear(self) end
		if not main_ready(self) then
			self.__hud_pending_start = true
			return false
		end
		self.__hud_pending_start = nil
		return original_start(self, ...)
	end

	local original_on_show = rawget(cls, "OnWndShow")
	if type(original_on_show) == "function" then
		cls.OnWndShow = function(self, show)
			if show == nil then show = CGWnd.IsShow(self) end
			show = boolean(show)
			self.__hud_requested_show = show
			if not main_ready(self) then
				CGameMain.OnWndShow(self, show)
				if show then self.__hud_pending_show = true end
				return
			end
			return original_on_show(self, show)
		end
	end

	local original_tip = rawget(cls, "TyroTipHelp")
	if type(original_tip) == "function" then
		cls.TyroTipHelp = function(self, index, show)
			if index == nil then return end
			if not tips_allowed(self)
				or field(field(self, "m_pWndTyro"), "m_wndContent") == nil then
				return CGameMain.TyroTipHelp(self, index, show)
			end
			local existed = contains(field(self, "m_tblTip"), index)
			local result = original_tip(self, index, show)
			if boolean(show) and not existed
				and contains(field(self, "m_tblTip"), index)
				and boolean(call(field(self, "m_pWndTyro"), "IsShow")) then
				count_tip(index)
			end
			return result
		end
	end

	local original_rank = rawget(cls, "UpdateRank")
	if type(original_rank) == "function" then
		cls.UpdateRank = function(self, director_id, buffer, count, show_first)
			count = math.max(0, math.floor(number(count, 0)))
			local size = number(call(buffer, "GetDataSize"), nil)
			if size then count = math.min(count, math.floor(size / 6)) end
			if scene() == nil or buffer == nil or count == 0 or not main_ready(self) then
				hide_rank(self)
				return
			end
			invoke(buffer, "SetPosition", 0)
			return original_rank(self, director_id or 0, buffer, count, show_first)
		end
	end

	local original_track = rawget(cls, "UpdateTrackTip")
	if type(original_track) == "function" then
		cls.UpdateTrackTip = function(self, director_id, ranks, sc)
			if sc == nil or director() == nil then hide_arrows(self); return end
			local room = call(sc, "GetRoomType")
			if room == eRT_Team or room == eRT_TeamSecret then
				local info = field(sc, "m_tblPlayerInfo")
				if type(info) ~= "table" or info[director_id] == nil then
					hide_arrows(self)
					return
				end
			end
			return original_track(self, director_id, ranks or {}, sc)
		end
	end

	local original_coin = rawget(cls, "UpdatePickCoin")
	if type(original_coin) == "function" then
		cls.UpdatePickCoin = function(self, ...)
			local sc = scene()
			if sc == nil then return end
			if director() == nil and number(call(sc, "GetObservedPlayerID"), 0) == 0 then return end
			return original_coin(self, ...)
		end
	end

	local original_skill = rawget(cls, "InitSkillButton")
	if type(original_skill) == "function" then
		cls.InitSkillButton = function(self, ...)
			if scene() == nil or director() == nil then return false end
			return original_skill(self, ...)
		end
	end
end

local previous_construct = rawget(CGameMain, "__native_construct")
CGameMain.__native_construct = function(self, ...)
	GameMainInstallHooks()
	if type(previous_construct) == "function" then previous_construct(self, ...) end
	-- Preserve app.lua's native resource creation and replace scene.lua's stubs.
	mains[self] = true
	self.__rhythmWnd = nil
	CGameMain.GetRhythmWnd(self)
	self.__camera = camera
	self.__hud_max_nodes = 0
end

local previous_install = rawget(_G, "SceneInstallHooks")
function SceneInstallHooks(...)
	if type(previous_install) == "function" then previous_install(...) end
	GameMainInstallHooks()
end

-- ---------------------------------------------------------------- per-frame presentation work

local function pump_main(self)
	if main_ready(self) then
		if field(self, "__hud_pending_show") then
			self.__hud_pending_show = nil
			local ok, err = invoke(self, "OnWndShow", true)
			if not ok then log_error(err) end
		end
		if field(self, "__hud_pending_start") and scene() ~= nil then
			self.__hud_pending_start = nil
			local ok, err = invoke(self, "Start")
			if not ok then log_error(err) end
		end
	end

	if field(self, "__hud_running") then CGameMain.GetMaxNodeCount(self) end

	local deadline = field(self, "__hud_tip_deadline")
	if deadline ~= nil and hud_time_ms >= deadline then
		local index = field(self, "__hud_tip_index")
		self.__hud_tip_deadline = nil
		CGameMain.TyroTipHelp(self, index, false)
	end
end

local previous_tick = rawget(_G, "NativeTickUpdate")
function NativeTickUpdate(dt)
	-- Advance before calling previous drivers: effects created during this frame
	-- start at the new time and cannot consume the same frame's dt immediately.
	hud_time_ms = hud_time_ms + math.max(0, number(dt, 0))
	local player = director()
	if player then NativeHUDObserveNodeCount(player, node_count(player)) end

	local result
	if type(previous_tick) == "function" then
		result = pack_values(pcall(previous_tick, dt))
	else
		result = pack_values(true)
	end

	for main in pairs(mains) do pump_main(main) end
	pump_effects()

	-- Presentation callbacks still run if another driver fails; preserve its error.
	if not result[1] then error(result[2], 0) end
	return unpack_values(result, 2, result.n)
end

return true
