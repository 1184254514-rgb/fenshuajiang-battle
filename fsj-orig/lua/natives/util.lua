-- Assumptions: local-time millisecond values encode local wall-clock fields against the Unix epoch;
-- NatureTime values are Unix milliseconds. GammaHash uses 32-bit FNV-1a.
-- API: CTick and NativeTickUpdate; CVector2f, CVector3f, CDir, CFRect, CIRect,
-- CMatrix, CGammaRand, CPathMgr, CPos16, STime; time conversion/formatting,
-- MD5Ex, GammaHash, ScaleRect, Cut2DLine, and IsWifiConnect.

local function number(value, default)
	local n = tonumber(value)
	if n == nil or n ~= n then
		return default or 0
	end
	return n
end

local function object_member(obj, key)
	if obj == nil then return nil end
	local ok, value = pcall(function() return obj[key] end)
	if ok then return value end
	return nil
end

local function vector_component(obj, key)
	local member = object_member(obj, key)
	if type(member) == "function" then
		local ok, value = pcall(member, obj)
		if ok then return number(value, 0) end
	elseif member ~= nil then
		return number(member, 0)
	end
	local internal = object_member(obj, "_" .. key)
	return number(internal, 0)
end

local function set_vector_component(obj, key, value)
	value = number(value, 0)
	local member = object_member(obj, key)
	if type(member) == "function" then
		pcall(member, obj, value)
	elseif type(obj) == "table" then
		obj["_" .. key] = value
	end
end

local function rect_component(obj, key)
	local member = object_member(obj, key)
	if type(member) == "function" then
		local ok, value = pcall(member, obj)
		if ok then return number(value, 0) end
	elseif member ~= nil then
		return number(member, 0)
	end
	return number(object_member(obj, "_" .. key), 0)
end

local function set_rect_component(obj, key, value)
	value = number(value, 0)
	local member = object_member(obj, key)
	if type(member) == "function" then
		pcall(member, obj, value)
	elseif type(obj) == "table" then
		obj["_" .. key] = value
	end
end

-- STime -----------------------------------------------------------------------

local function time_accessor(name, field)
	STime[name] = function(self, value)
		if value ~= nil then
			self[field] = number(value, 0)
		end
		return number(self[field], 0)
	end
end

function STime:Ctor(year, month, day, hour, minutes, seconds, weekday, milliseconds)
	self._year = number(year, 0)
	self._month = number(month, 0)
	self._day = number(day, 0)
	self._hour = number(hour, 0)
	self._minutes = number(minutes, 0)
	self._seconds = number(seconds, 0)
	self._weekday = number(weekday, 0)
	self._milliseconds = number(milliseconds, 0)
end

time_accessor("m_nYear", "_year")
time_accessor("m_nMonth", "_month")
time_accessor("m_nDayOfMonth", "_day")
time_accessor("m_nDay", "_day")
time_accessor("m_nHour", "_hour")
time_accessor("m_nMinutes", "_minutes")
time_accessor("m_nSeconds", "_seconds")
time_accessor("m_nSecond", "_seconds")
time_accessor("m_nDayofWeek", "_weekday")
time_accessor("m_nDayOfWeek", "_weekday")
time_accessor("m_nMilliseconds", "_milliseconds")

-- Vectors ---------------------------------------------------------------------

local function vector_accessor(classTable, name, field)
	classTable[name] = function(self, value)
		if value ~= nil then
			self[field] = number(value, 0)
		end
		return number(self[field], 0)
	end
end

function CVector2f:Ctor(x, y)
	self._x = number(x, 0)
	self._y = number(y, 0)
	self._z = 0
end

vector_accessor(CVector2f, "x", "_x")
vector_accessor(CVector2f, "y", "_y")
vector_accessor(CVector2f, "z", "_z")

function CVector2f:Set(x, y)
	if type(x) == "table" or type(x) == "userdata" then
		y = vector_component(x, "y")
		x = vector_component(x, "x")
	end
	self:x(x)
	self:y(y)
	return self
end

function CVector2f:Zero()
	self:x(0)
	self:y(0)
	return self
end

function CVector2f:GetXY()
	return self:x(), self:y()
end

function CVector2f:GetXYZ()
	return self:x(), self:y(), self:z()
end

function CVector2f:Clone()
	return CVector2f:new(self:x(), self:y())
end

function CVector2f:LengthSquared()
	local x, y = self:x(), self:y()
	return x * x + y * y
end

function CVector2f:Length()
	return math.sqrt(self:LengthSquared())
end

function CVector2f:NormalizeNoneZero()
	local length = self:Length()
	if length > 0 then
		self:x(self:x() / length)
		self:y(self:y() / length)
	end
	return self
end

function CVector2f:Normalize()
	return self:NormalizeNoneZero()
end

function CVector2f:Dot(other)
	return self:x() * vector_component(other, "x")
		+ self:y() * vector_component(other, "y")
end

function CVector3f:Ctor(x, y, z)
	self._x = number(x, 0)
	self._y = number(y, 0)
	self._z = number(z, 0)
end

vector_accessor(CVector3f, "x", "_x")
vector_accessor(CVector3f, "y", "_y")
vector_accessor(CVector3f, "z", "_z")

function CVector3f:Set(x, y, z)
	if type(x) == "table" or type(x) == "userdata" then
		local source = x
		x, y, z = vector_component(source, "x"),
			vector_component(source, "y"), vector_component(source, "z")
	end
	self:x(x)
	self:y(y)
	self:z(z)
	return self
end

function CVector3f:Zero()
	self:x(0)
	self:y(0)
	self:z(0)
	return self
end

function CVector3f:GetXYZ()
	return self:x(), self:y(), self:z()
end

function CVector3f:Clone()
	return CVector3f:new(self:x(), self:y(), self:z())
end

function CVector3f:LengthSquared()
	local x, y, z = self:x(), self:y(), self:z()
	return x * x + y * y + z * z
end

function CVector3f:Length()
	return math.sqrt(self:LengthSquared())
end

function CVector3f:NormalizeNoneZero()
	local length = self:Length()
	if length > 0 then
		self:x(self:x() / length)
		self:y(self:y() / length)
		self:z(self:z() / length)
	end
	return self
end

function CVector3f:Normalize()
	return self:NormalizeNoneZero()
end

function CVector3f:Dot(other)
	return self:x() * vector_component(other, "x")
		+ self:y() * vector_component(other, "y")
		+ self:z() * vector_component(other, "z")
end

function CVector3f:Cross(other)
	local x, y, z = self:x(), self:y(), self:z()
	local ox, oy, oz = vector_component(other, "x"),
		vector_component(other, "y"), vector_component(other, "z")
	return CVector3f:new(y * oz - z * oy, z * ox - x * oz, x * oy - y * ox)
end

-- Directions use 256 units per full turn, with zero pointing along +X.
function CDir:Ctor(direction)
	self._uDir = math.floor(number(direction, 0)) % 256
end

function CDir:uDir(value)
	if value ~= nil then
		self._uDir = math.floor(number(value, 0)) % 256
	end
	return number(self._uDir, 0) % 256
end

function CDir:Set(value, y)
	local x
	if type(value) == "table" or type(value) == "userdata" then
		x, y = vector_component(value, "x"), vector_component(value, "y")
	else
		x = number(value, 0)
		y = number(y, 0)
	end
	if x == 0 and y == 0 then
		self:uDir(0)
	else
		local radians = math.atan(y, x)
		self:uDir(math.floor(radians * 256 / (2 * math.pi) + 0.5))
	end
	return self
end

function CDir:GetRadian()
	return self:uDir() * (2 * math.pi / 256)
end

function CDir:Clone()
	return CDir:new(self:uDir())
end

-- Rectangles ------------------------------------------------------------------

local function rect_methods(classTable)
	function classTable:Ctor(left, top, right, bottom)
		self._left = number(left, 0)
		self._top = number(top, 0)
		self._right = number(right, 0)
		self._bottom = number(bottom, 0)
	end

	local fields = {
		{ "left", "_left" },
		{ "top", "_top" },
		{ "right", "_right" },
		{ "bottom", "_bottom" },
	}
	for i = 1, #fields do
		local method, field = fields[i][1], fields[i][2]
		classTable[method] = function(self, value)
			if value ~= nil then self[field] = number(value, 0) end
			return number(self[field], 0)
		end
	end

	function classTable:Set(left, top, right, bottom)
		self:left(left)
		self:top(top)
		self:right(right)
		self:bottom(bottom)
		return self
	end

	function classTable:Width()
		return self:right() - self:left()
	end

	function classTable:Height()
		return self:bottom() - self:top()
	end

	function classTable:IsEmpty()
		return self:Width() <= 0 or self:Height() <= 0
	end

	function classTable:Contains(x, y)
		if type(x) == "table" or type(x) == "userdata" then
			y = vector_component(x, "y")
			x = vector_component(x, "x")
		end
		x, y = number(x, 0), number(y, 0)
		return x >= self:left() and x <= self:right()
			and y >= self:top() and y <= self:bottom()
	end

	function classTable:Offset(dx, dy)
		dx, dy = number(dx, 0), number(dy, 0)
		self:left(self:left() + dx)
		self:right(self:right() + dx)
		self:top(self:top() + dy)
		self:bottom(self:bottom() + dy)
		return self
	end

	function classTable:Clone()
		return classTable:new(self:left(), self:top(), self:right(), self:bottom())
	end
end

rect_methods(CFRect)
rect_methods(CIRect)

-- A small row-major 4x4 matrix implementation. CMatrix:new(existingMatrix) copies it.
function CMatrix:Ctor(source)
	self._m = {}
	for row = 1, 4 do
		for column = 1, 4 do
			local index = (row - 1) * 4 + column
			local value
			if type(source) == "table" then
				local src = source._m or source
				value = src[index]
				if value == nil and type(source.Get) == "function" then
					local ok, got = pcall(source.Get, source, row, column)
					if ok then value = got end
				end
			end
			if value ~= nil then
				self._m[index] = number(value, 0)
			else
				self._m[index] = row == column and 1 or 0
			end
		end
	end
end

function CMatrix:Identity()
	for row = 1, 4 do
		for column = 1, 4 do
			self._m[(row - 1) * 4 + column] = row == column and 1 or 0
		end
	end
	return self
end

function CMatrix:Get(row, column)
	row, column = math.floor(number(row, 0)), math.floor(number(column, 0))
	if row < 1 or row > 4 or column < 1 or column > 4 then return nil end
	return self._m[(row - 1) * 4 + column]
end

function CMatrix:Set(row, column, value)
	if type(row) == "table" then
		local source = row._m or row
		for i = 1, 16 do self._m[i] = number(source[i], 0) end
		return self
	end
	row, column = math.floor(number(row, 0)), math.floor(number(column, 0))
	if row >= 1 and row <= 4 and column >= 1 and column <= 4 then
		self._m[(row - 1) * 4 + column] = number(value, 0)
	end
	return self
end

function CMatrix:GetData()
	local result = {}
	for i = 1, 16 do result[i] = self._m[i] end
	return result
end

function CMatrix:Clone()
	return CMatrix:new(self)
end

-- 16-bit position -------------------------------------------------------------

function CPos16:Ctor(x, y)
	self._x = number(x, 0)
	self._y = number(y, 0)
end

vector_accessor(CPos16, "x", "_x")
vector_accessor(CPos16, "y", "_y")

function CPos16:Set(x, y)
	if type(x) == "table" or type(x) == "userdata" then
		y = vector_component(x, "y")
		x = vector_component(x, "x")
	end
	self:x(x)
	self:y(y)
	return self
end

function CPos16:Clone()
	return CPos16:new(self:x(), self:y())
end

-- Timer -----------------------------------------------------------------------

local activeTicks = {}
local tickSerial = 0

local function log_tick_error(message)
	local host = rawget(_G, "Host")
	local logger = object_member(host, "log")
	if type(logger) == "function" then
		pcall(logger, host, tostring(message))
	elseif type(print) == "function" then
		pcall(print, "[CTick] " .. tostring(message))
	end
end

local function invoke_tick_callback(tick, callback)
	if type(callback) == "function" then
		local ok, err = pcall(callback, tick.m_TickContext, tick)
		if not ok then
			log_tick_error(err)
			return false
		end
		return true
	end

	if type(callback) == "string" then
		local target = tick.m_pHandler
		local method = object_member(target, callback)
		if type(method) == "function" then
			local ok, err = pcall(method, target, tick.m_TickContext)
			if not ok then
				log_tick_error(err)
				return false
			end
		end
	end
	return true
end

local function register_tick(tick)
	if tick.m_bInRegistry then return end
	tick.m_bInRegistry = true
	activeTicks[#activeTicks + 1] = tick
end

function CTick:Ctor(callback, target, localTickManager, repeatCount, context, completeCallback)
	self.m_funTick = callback
	self.m_pHandler = target
	self.m_pLocalTickMgr = localTickManager
	self.m_nRepeatCount = number(repeatCount, 0)
	self.m_TickContext = context
	self.m_funTickComplete = completeCallback
	self.m_nTickCount = 0
	self.m_nInterval = 0
	self.m_nElapsed = 0
	self.m_bRunning = false
	self.m_bRegistered = false
	self.m_bInRegistry = false
	tickSerial = tickSerial + 1
	self.m_nTickID = tickSerial
	self.m_szTickName = type(callback) == "string" and callback or "function"
end

function CTick:OnTick()
	self.m_nTickCount = number(self.m_nTickCount, 0) + 1
	if not invoke_tick_callback(self, self.m_funTick) then
		self:Stop()
		return false
	end

	local repeatCount = number(self.m_nRepeatCount, 0)
	if repeatCount > 0 and self.m_nTickCount >= repeatCount then
		self:Stop()
		if self.m_funTickComplete ~= nil then
			invoke_tick_callback(self, self.m_funTickComplete)
		end
	end
	return true
end

function CTick:Start(intervalMs, resetCount, localTickManager)
	if localTickManager ~= nil then self.m_pLocalTickMgr = localTickManager end
	self.m_nInterval = math.max(0, number(intervalMs, self.m_nInterval or 0))
	self.m_nElapsed = 0
	if resetCount ~= false then self.m_nTickCount = 0 end
	self.m_bRunning = true
	self.m_bRegistered = true
	register_tick(self)
	return true
end

function CTick:Stop()
	self.m_bRunning = false
	self.m_bRegistered = false
	return true
end

function CTick:IsRunning()
	return self.m_bRunning == true
end

function CTick:IsRegisted()
	return self.m_bRegistered == true
end

function CTick:SetLocal(localTickManager)
	self.m_pLocalTickMgr = localTickManager
	return self
end

function CTick:GetTickCount()
	return number(self.m_nTickCount, 0)
end

function CTick:GetRepeatCount()
	return number(self.m_nRepeatCount, 0)
end

function CTick:SetTickCount(count)
	self.m_nTickCount = number(count, 0)
	return self
end

function CTick:SetRepeatCount(count)
	self.m_nRepeatCount = number(count, 0)
	return self
end

function CTick:GetTickFun()
	return self.m_funTick
end

function CTick:SetTickFun(callback)
	self.m_funTick = callback
	return self
end

function CTick:GetTickCompleteFun()
	return self.m_funTickComplete
end

function CTick:SetTickCompleteFun(callback)
	self.m_funTickComplete = callback
	return self
end

function CTick:GetContext()
	return self.m_TickContext
end

function CTick:SetContext(context)
	self.m_TickContext = context
	return self
end

function CTick:GetInterval()
	return number(self.m_nInterval, 0)
end

function CTick:SetInterval(intervalMs)
	self.m_nInterval = math.max(0, number(intervalMs, 0))
	self.m_nElapsed = 0
	return self
end

function CTick.GetTickID()
	tickSerial = tickSerial + 1
	return tostring(tickSerial)
end

function CTick.DumpTick()
	local count = 0
	for i = 1, #activeTicks do
		local tick = activeTicks[i]
		if tick and tick.m_bRunning then
			count = count + 1
			if type(print) == "function" then
				pcall(print, "[CTick] " .. tostring(tick.m_nTickID) .. " "
					.. tostring(tick.m_szTickName) .. " interval="
					.. tostring(tick.m_nInterval))
			end
		end
	end
	return count
end

function NativeTickUpdate(dtMs)
	local elapsed = math.max(0, number(dtMs, 0))
	local initialCount = #activeTicks
	local fired = 0

	for i = 1, initialCount do
		local tick = activeTicks[i]
		if tick and tick.m_bRunning then
			local interval = math.max(0, number(tick.m_nInterval, 0))
			if interval <= 0 then
				tick.m_nElapsed = 0
				tick:OnTick()
				fired = fired + 1
			else
				tick.m_nElapsed = number(tick.m_nElapsed, 0) + elapsed
				while tick.m_bRunning and tick.m_nElapsed >= interval do
					tick.m_nElapsed = tick.m_nElapsed - interval
					tick:OnTick()
					fired = fired + 1
					interval = math.max(0, number(tick.m_nInterval, 0))
					if interval <= 0 then
						tick.m_nElapsed = 0
						break
					end
				end
			end
		end
	end

	local write = 1
	for read = 1, #activeTicks do
		local tick = activeTicks[read]
		if tick and tick.m_bRunning then
			activeTicks[write] = tick
			tick.m_bInRegistry = true
			write = write + 1
		else
			if tick then tick.m_bInRegistry = false end
		end
	end
	for i = #activeTicks, write, -1 do activeTicks[i] = nil end

	return fired
end

-- Time conversion -------------------------------------------------------------

local function safe_date(format, seconds)
	local ok, value = pcall(os.date, format, seconds)
	if ok and type(value) == "table" then return value end
	return nil
end

local function time_zone_offset(seconds)
	seconds = number(seconds, 0)
	local utc = safe_date("!*t", seconds)
	local localTime = safe_date("*t", seconds)
	if not utc or not localTime then return 0 end
	utc.isdst = localTime.isdst
	local ok, localInterpretation = pcall(os.time, utc)
	if not ok or localInterpretation == nil then return 0 end
	return seconds - localInterpretation
end

local function nature_seconds_to_local(seconds)
	return seconds + time_zone_offset(seconds)
end

local function local_seconds_to_nature(seconds)
	local candidate = number(seconds, 0)
	for _ = 1, 3 do
		candidate = seconds - time_zone_offset(candidate)
	end
	return candidate
end

local function set_stime_from_table(target, parts, milliseconds)
	if target == nil then target = STime:new() end
	if not parts then parts = {} end
	local values = {
		{ "m_nYear", parts.year },
		{ "m_nMonth", parts.month },
		{ "m_nDayOfMonth", parts.day },
		{ "m_nHour", parts.hour },
		{ "m_nMinutes", parts.min },
		{ "m_nSeconds", parts.sec },
		{ "m_nDayofWeek", parts.wday and parts.wday - 1 or 0 },
		{ "m_nMilliseconds", milliseconds or 0 },
	}
	for i = 1, #values do
		local method = object_member(target, values[i][1])
		if type(method) == "function" then
			pcall(method, target, values[i][2] or 0)
		elseif type(target) == "table" then
			target["_" .. values[i][1]] = number(values[i][2], 0)
		end
	end
	return target
end

function GetFormatTimeSTMFromMillisecond(milliseconds)
	local ms = number(milliseconds, 0)
	local seconds = math.floor(ms / 1000)
	local parts = safe_date("!*t", seconds)
	local remainder = ms - seconds * 1000
	return set_stime_from_table(nil, parts, remainder)
end

function Format2LocalTime(year, month, day, hour, minutes, seconds)
	local parts = {
		year = math.floor(number(year, 1970)),
		month = math.floor(number(month, 1)),
		day = math.floor(number(day, 1)),
		hour = math.floor(number(hour, 0)),
		min = math.floor(number(minutes, 0)),
		sec = math.floor(number(seconds, 0)),
	}
	local ok, epoch = pcall(os.time, parts)
	if not ok or epoch == nil then return 0 end
	return nature_seconds_to_local(epoch)
end

function NatureTime2LocalTime(milliseconds)
	local ms = number(milliseconds, 0)
	local seconds = ms / 1000
	return ms + time_zone_offset(seconds) * 1000
end

function LocalTime2NatureTime(milliseconds)
	local ms = number(milliseconds, 0)
	return local_seconds_to_nature(ms / 1000) * 1000
end

function Format2NatureTime(year, month, day, hour, minutes, seconds)
	local parts = {
		year = math.floor(number(year, 1970)),
		month = math.floor(number(month, 1)),
		day = math.floor(number(day, 1)),
		hour = math.floor(number(hour, 0)),
		min = math.floor(number(minutes, 0)),
		sec = math.floor(number(seconds, 0)),
	}
	local ok, epoch = pcall(os.time, parts)
	if not ok or epoch == nil then return 0 end
	return epoch * 1000
end

function GetLocalTime()
	local now
	if type(GetNatureTime) == "function" then
		local ok, value = pcall(GetNatureTime)
		if ok then now = tonumber(value) end
	end
	if now == nil then
		local host = rawget(_G, "Host")
		local unixMs = object_member(host, "unix_ms")
		if type(unixMs) == "function" then
			local ok, value = pcall(unixMs, host)
			if ok then now = tonumber(value) end
		end
	end
	if now == nil then now = os.time() * 1000 end
	return NatureTime2LocalTime(now)
end

function GetDateTime(target)
	local parts = safe_date("*t", os.time())
	return set_stime_from_table(target, parts, 0)
end

-- Buffer helpers used by MD5Ex and GammaHash ----------------------------------

local function payload_to_string(payload, size)
	if type(payload) == "string" then
		if size ~= nil then return payload:sub(1, math.max(0, math.floor(number(size, 0)))) end
		return payload
	end
	if payload == nil then return "" end

	local okLength, length = pcall(function() return #payload end)
	if not okLength then length = nil end
	if type(payload) == "table" then
		length = tonumber(payload.n or payload.size) or length
	end
	if size ~= nil then
		length = math.max(0, math.floor(number(size, length or 0)))
	end
	if length == nil or length <= 0 then return "" end

	local okZero, zeroValue = pcall(function() return payload[0] end)
	local zeroBased = okZero and zeroValue ~= nil
	local first = zeroBased and 0 or 1
	local chunks = {}
	for i = 0, length - 1 do
		local ok, byte = pcall(function() return payload[first + i] end)
		if not ok or byte == nil then break end
		byte = math.floor(number(byte, 0)) % 256
		chunks[#chunks + 1] = string.char(byte)
	end
	return table.concat(chunks)
end

local function call_buffer_method(buffer, methodName, ...)
	local method = object_member(buffer, methodName)
	if type(method) ~= "function" then return nil end
	local ok, result = pcall(method, buffer, ...)
	if ok then return result end
	return nil
end

local function extract_buffer_bytes(buffer, size)
	if type(buffer) == "string" then
		return payload_to_string(buffer, size)
	end
	if buffer == nil then return "" end

	local requested = size
	if requested == nil then
		requested = call_buffer_method(buffer, "GetPosition")
	end

	for _, name in ipairs({ "GetBuffer", "GetData", "GetBytes", "GetByteArray" }) do
		local payload = call_buffer_method(buffer, name)
		if payload ~= nil and payload ~= buffer then
			local bytes = payload_to_string(payload, requested)
			if bytes ~= "" or number(requested, 0) == 0 then return bytes end
		end
	end

	local reader = object_member(buffer, "ReadUTFBytes")
	if type(reader) == "function" and requested ~= nil then
		local position = call_buffer_method(buffer, "GetPosition")
		if object_member(buffer, "SetPosition") then
			pcall(object_member(buffer, "SetPosition"), buffer, 0)
		elseif object_member(buffer, "Seek") then
			pcall(object_member(buffer, "Seek"), buffer, 0)
		end
		local ok, result = pcall(reader, buffer, math.max(0, math.floor(number(requested, 0))))
		if position ~= nil and object_member(buffer, "SetPosition") then
			pcall(object_member(buffer, "SetPosition"), buffer, position)
		end
		if ok and type(result) == "string" then return result end
	end

	return payload_to_string(buffer, requested)
end

local function write_buffer_bytes(buffer, bytes)
	if buffer == nil then return end
	local setPosition = object_member(buffer, "SetPosition")
	if type(setPosition) == "function" then pcall(setPosition, buffer, 0) end

	for _, name in ipairs({ "WriteUTFBytes", "WriteBytes", "SetData", "SetBuffer" }) do
		local method = object_member(buffer, name)
		if type(method) == "function" then
			local ok = pcall(method, buffer, bytes)
			if ok then return end
		end
	end

	if type(buffer) == "table" then
		buffer.data = bytes
	end
end

-- Pure Lua 5.4 MD5 ------------------------------------------------------------

local MD5_MASK = 0xffffffff
local MD5_K = {
	0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
	0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
	0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
	0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
	0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
	0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
	0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
	0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
	0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
	0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
	0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
	0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
	0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
	0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
	0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
	0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
}
local MD5_S = {
	7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
	5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
	4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
	6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
}

local function rotate_left32(value, amount)
	return ((value << amount) | (value >> (32 - amount))) & MD5_MASK
end

local function md5_hex(message)
	local bitLength = #message * 8
	message = message .. string.char(0x80)
	local padding = (56 - (#message % 64)) % 64
	if padding > 0 then message = message .. string.rep("\0", padding) end
	message = message .. string.pack("<I8", bitLength)

	local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

	for offset = 1, #message, 64 do
		local words = {}
		for i = 0, 15 do
			words[i + 1] = string.unpack("<I4", message, offset + i * 4)
		end

		local a, b, c, d = a0, b0, c0, d0
		for i = 0, 63 do
			local f, g
			if i < 16 then
				f = (b & c) | ((~b) & d)
				g = i
			elseif i < 32 then
				f = (d & b) | ((~d) & c)
				g = (5 * i + 1) % 16
			elseif i < 48 then
				f = b ~ c ~ d
				g = (3 * i + 5) % 16
			else
				f = c ~ (b | (~d))
				g = (7 * i) % 16
			end

			local nextValue = (a + f + MD5_K[i + 1] + words[g + 1]) & MD5_MASK
			nextValue = rotate_left32(nextValue, MD5_S[i + 1])
			nextValue = (b + nextValue) & MD5_MASK
			a, d, c, b = d, c, b, nextValue
		end

		a0 = (a0 + a) & MD5_MASK
		b0 = (b0 + b) & MD5_MASK
		c0 = (c0 + c) & MD5_MASK
		d0 = (d0 + d) & MD5_MASK
	end

	local digest = string.pack("<I4I4I4I4", a0, b0, c0, d0)
	local hex = {}
	for i = 1, #digest do
		hex[i] = string.format("%02x", digest:byte(i))
	end
	return table.concat(hex)
end

function MD5Ex(destinationBuffer, sourceBuffer, size)
	local digest = md5_hex(extract_buffer_bytes(sourceBuffer, size))
	write_buffer_bytes(destinationBuffer, digest)
	return digest
end

function GammaHash(sourceBuffer, size)
	local bytes = extract_buffer_bytes(sourceBuffer, size)
	local hash = 2166136261
	for i = 1, #bytes do
		hash = ((hash ~ bytes:byte(i)) * 16777619) & MD5_MASK
	end
	return hash
end

-- Path helpers ----------------------------------------------------------------

local function normalize_path(path)
	if path == nil then return "" end
	return tostring(path):gsub("\\", "/")
end

function CPathMgr.ToPhysicalPath(path, buffer, maxLength)
	local result = normalize_path(path)
	if maxLength ~= nil then
		local limit = math.max(0, math.floor(number(maxLength, #result)))
		if limit > 0 then result = result:sub(1, limit) end
	end
	return result
end

function CPathMgr.MakeDirectory(path)
	local normalized = normalize_path(path)
	local host = rawget(_G, "Host")
	for _, name in ipairs({ "make_dir", "create_dir" }) do
		local method = object_member(host, name)
		if type(method) == "function" then
			local ok, result = pcall(method, host, normalized)
			if ok then return result ~= false end
		end
	end
	-- The available Host contract is read-only; treat cache-directory creation as best-effort.
	return true
end

function CPathMgr.IsFileExist(path)
	local normalized = normalize_path(path)
	local host = rawget(_G, "Host")
	local fileExists = object_member(host, "file_exists")
	if type(fileExists) == "function" then
		local ok, result = pcall(fileExists, host, normalized)
		if ok then return result == true end
	end
	local ok, file = pcall(io.open, normalized, "rb")
	if ok and file then
		pcall(file.close, file)
		return true
	end
	return false
end

-- Geometry helpers ------------------------------------------------------------

local function has_flag(flags, names)
	flags = math.tointeger(number(flags, 0)) or 0
	for i = 1, #names do
		local bit = rawget(_G, names[i])
		if bit ~= nil then
			bit = math.tointeger(number(bit, 0)) or 0
			if bit ~= 0 then
				local bitAnd = rawget(_G, "BitAnd")
				if type(bitAnd) == "function" then
					local ok, result = pcall(bitAnd, flags, bit)
					if ok and result ~= nil then
						if number(result, 0) ~= 0 then return true end
					end
				end
				if (flags & bit) ~= 0 then return true end
			end
		end
	end
	return false
end

function ScaleRect(rect, lockFlags, width, height, deltaWidth, deltaHeight)
	if rect == nil then return nil end
	local left, right = rect_component(rect, "left"), rect_component(rect, "right")
	local top, bottom = rect_component(rect, "top"), rect_component(rect, "bottom")
	local dw, dh = number(deltaWidth, 0), number(deltaHeight, 0)

	local lockLeft = has_flag(lockFlags, { "LOCK_LEFT", "eDF_Left" })
	local lockRight = has_flag(lockFlags, { "LOCK_RIGHT", "eDF_Right" })
	local lockTop = has_flag(lockFlags, { "LOCK_TOP", "eDF_Top" })
	local lockBottom = has_flag(lockFlags, { "LOCK_BOTTOM", "eDF_Bottom" })

	if lockLeft and lockRight then
		right = right + dw
	elseif lockRight then
		left, right = left + dw, right + dw
	elseif not lockLeft then
		left, right = left + dw * 0.5, right + dw * 0.5
	end

	if lockTop and lockBottom then
		bottom = bottom + dh
	elseif lockBottom then
		top, bottom = top + dh, bottom + dh
	elseif not lockTop then
		top, bottom = top + dh * 0.5, bottom + dh * 0.5
	end

	set_rect_component(rect, "left", left)
	set_rect_component(rect, "right", right)
	set_rect_component(rect, "top", top)
	set_rect_component(rect, "bottom", bottom)
	return rect
end

function Cut2DLine(rect, startPoint, endPoint)
	if rect == nil or startPoint == nil or endPoint == nil then return false end

	local left, right = rect_component(rect, "left"), rect_component(rect, "right")
	local top, bottom = rect_component(rect, "top"), rect_component(rect, "bottom")
	local x0, y0 = vector_component(startPoint, "x"), vector_component(startPoint, "y")
	local x1, y1 = vector_component(endPoint, "x"), vector_component(endPoint, "y")
	local dx, dy = x1 - x0, y1 - y0

	local function inside(x, y)
		return x >= left and x <= right and y >= top and y <= bottom
	end
	if inside(x1, y1) then return false end

	local tExit = math.huge
	if dx > 0 then
		tExit = math.min(tExit, (right - x0) / dx)
	elseif dx < 0 then
		tExit = math.min(tExit, (left - x0) / dx)
	end
	if dy > 0 then
		tExit = math.min(tExit, (bottom - y0) / dy)
	elseif dy < 0 then
		tExit = math.min(tExit, (top - y0) / dy)
	end

	if tExit == math.huge or tExit < 0 then return false end
	tExit = math.min(1, tExit)
	set_vector_component(endPoint, "x", x0 + dx * tExit)
	set_vector_component(endPoint, "y", y0 + dy * tExit)
	return true
end

function IsWifiConnect()
	return true
end

-- Random helper ---------------------------------------------------------------

function CGammaRand:Ctor(seed)
	self._state = math.floor(number(seed, math.random(1, 0x7ffffffe))) & MD5_MASK
	if self._state == 0 then self._state = 0x6d2b79f5 end
end

function CGammaRand:Seed(seed)
	self._state = math.floor(number(seed, 1)) & MD5_MASK
	if self._state == 0 then self._state = 0x6d2b79f5 end
	return self
end

function CGammaRand:_NextUInt32()
	local x = number(self._state, 1) & MD5_MASK
	x = (x ~ ((x << 13) & MD5_MASK)) & MD5_MASK
	x = (x ~ (x >> 17)) & MD5_MASK
	x = (x ~ ((x << 5) & MD5_MASK)) & MD5_MASK
	self._state = x
	return x
end

function CGammaRand:RandomInt(minimum, maximum)
	if maximum == nil then
		if minimum == nil then
			return self:_NextUInt32()
		end
		minimum, maximum = 1, minimum
	end
	minimum = math.floor(number(minimum, 0))
	maximum = math.floor(number(maximum, minimum))
	if maximum < minimum then minimum, maximum = maximum, minimum end
	local range = maximum - minimum + 1
	if range <= 1 then return minimum end
	return minimum + (self:_NextUInt32() % range)
end

function CGammaRand:RandomFloat(minimum, maximum)
	minimum = number(minimum, 0)
	maximum = number(maximum, 1)
	if maximum < minimum then minimum, maximum = maximum, minimum end
	return minimum + (self:_NextUInt32() / 0xffffffff) * (maximum - minimum)
end

function CGammaRand:Rand(minimum, maximum)
	return self:RandomInt(minimum, maximum)
end

function CGammaRand:Random(minimum, maximum)
	return self:RandomInt(minimum, maximum)
end

function CGammaRand:RandFloat(minimum, maximum)
	return self:RandomFloat(minimum, maximum)
end