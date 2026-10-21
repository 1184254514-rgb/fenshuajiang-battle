-- Assumptions: positions and byte offsets are zero-based; fixed-length UTF writes are NUL-padded;
-- UCS counts are UTF-16LE code units; Reset clears the buffer and both cursors.
-- Public API: SetDataSize, GetDataSize, GetPosition, SetPosition, Reset, GetReadError,
-- ClearReadError, IsInheritFrom; Read/WriteInt8, Int16, Int32, Int64, Uint8, Uint16,
-- Uint32, Uint64, Float, Double, Boolean, UTFBytes, UTF; ReadBytes, WriteBytes,
-- ReadUCSCounts.
local function ensure_data(buffer)
	if type(buffer._cb_data) ~= "string" then
		buffer._cb_data = ""
	end
	if type(buffer._cb_position) ~= "number" then
		buffer._cb_position = 0
	end
	return buffer._cb_data
end

local function integer_value(value)
	if type(value) == "boolean" then
		return value and 1 or 0
	end

	local number = tonumber(value)
	if number == nil or number ~= number or number == math.huge or number == -math.huge then
		return 0
	end

	local integer = math.tointeger(number)
	if integer ~= nil then
		return integer
	end

	number = math.floor(number)
	local modulus = 18446744073709551616.0
	local half = 9223372036854775808.0
	local wrapped = number % modulus
	if wrapped >= half then
		wrapped = wrapped - modulus
	end
	return math.tointeger(wrapped) or 0
end

local function normalize_integer(value, bits, signed)
	local integer = integer_value(value)
	if bits == 64 then
		return integer
	end

	local modulus = 1 << bits
	local masked = integer & (modulus - 1)
	if signed and masked >= (modulus >> 1) then
		masked = masked - modulus
	end
	return masked
end

local function write_at(buffer, position, bytes)
	local data = ensure_data(buffer)
	position = math.max(0, math.floor(position))

	if position > #data then
		data = data .. string.rep("\0", position - #data)
	end

	local left = data:sub(1, position)
	local right = data:sub(position + #bytes + 1)
	buffer._cb_data = left .. bytes .. right
end

local function write_blob(buffer, bytes)
	local position = math.max(0, math.floor(buffer._cb_position or 0))
	write_at(buffer, position, bytes)
	buffer._cb_position = position + #bytes
end

local function read_blob(buffer, length)
	local data = ensure_data(buffer)
	length = tonumber(length)

	if length == nil or length ~= length or length == math.huge or length == -math.huge then
		buffer._cb_read_error = true
		return nil
	end

	length = math.floor(length)
	if length < 0 then
		buffer._cb_read_error = true
		return nil
	end

	local position = math.max(0, math.floor(buffer._cb_position or 0))
	if position + length > #data then
		buffer._cb_read_error = true
		return nil
	end

	local bytes = data:sub(position + 1, position + length)
	buffer._cb_position = position + length
	return bytes
end

local function read_integer(buffer, format, size)
	local bytes = read_blob(buffer, size)
	if bytes == nil then
		return 0
	end

	local ok, value = pcall(string.unpack, format, bytes)
	if not ok then
		buffer._cb_read_error = true
		return 0
	end
	return value
end

local function valid_length(value, default_value)
	if value == nil then
		return default_value
	end
	local number = tonumber(value)
	if number == nil or number ~= number or number == math.huge or number == -math.huge then
		return nil
	end
	return math.floor(number)
end

function CBufferStream:SetDataSize(size)
	local new_size = valid_length(size, 0)
	if new_size == nil or new_size < 0 then
		new_size = 0
	end

	local data = ensure_data(self)
	if new_size < #data then
		self._cb_data = data:sub(1, new_size)
	elseif new_size > #data then
		self._cb_data = data .. string.rep("\0", new_size - #data)
	end

	self._cb_position = 0
	self._cb_read_error = false
end

function CBufferStream:GetDataSize()
	return #ensure_data(self)
end

function CBufferStream:GetPosition()
	ensure_data(self)
	return math.max(0, math.floor(self._cb_position or 0))
end

function CBufferStream:SetPosition(position)
	local new_position = valid_length(position, 0)
	if new_position == nil or new_position < 0 then
		new_position = 0
	end
	self._cb_position = new_position
end

function CBufferStream:Reset()
	self._cb_data = ""
	self._cb_position = 0
	self._cb_read_error = false
end

function CBufferStream:GetReadError()
	return self._cb_read_error == true
end

function CBufferStream:ClearReadError()
	self._cb_read_error = false
end

function CBufferStream:IsInheritFrom(class_type)
	if self == class_type then
		return true
	end

	local current = getmetatable(self)
	while type(current) == "table" do
		if current == class_type then
			return true
		end
		current = rawget(current, "_base") or rawget(current, "Base") or rawget(current, "__base")
		if type(current) == "table" and current[1] ~= nil then
			current = current[1]
		end
	end
	return false
end

local integer_types = {
	{ "Int8", 1, true, "i1" },
	{ "Int16", 2, true, "i2" },
	{ "Int32", 4, true, "i4" },
	{ "Int64", 8, true, "i8" },
	{ "Uint8", 1, false, "I1" },
	{ "Uint16", 2, false, "I2" },
	{ "Uint32", 4, false, "I4" },
}

for _, info in ipairs(integer_types) do
	local name, size, signed, format = info[1], info[2], info[3], info[4]
	CBufferStream["Read" .. name] = function(self)
		return read_integer(self, "<" .. format, size)
	end
	CBufferStream["Write" .. name] = function(self, value)
		local normalized = normalize_integer(value, size * 8, signed)
		write_blob(self, string.pack("<" .. format, normalized))
	end
end

function CBufferStream:ReadUint64()
	return read_integer(self, "<i8", 8)
end

function CBufferStream:WriteUint64(value)
	write_blob(self, string.pack("<i8", normalize_integer(value, 64, false)))
end

function CBufferStream:ReadFloat()
	return read_integer(self, "<f", 4)
end

function CBufferStream:WriteFloat(value)
	write_blob(self, string.pack("<f", tonumber(value) or 0))
end

function CBufferStream:ReadDouble()
	return read_integer(self, "<d", 8)
end

function CBufferStream:WriteDouble(value)
	write_blob(self, string.pack("<d", tonumber(value) or 0))
end

function CBufferStream:ReadBoolean()
	return self:ReadUint8() ~= 0
end

function CBufferStream:WriteBoolean(value)
	self:WriteUint8(value and 1 or 0)
end

function CBufferStream:ReadUTFBytes(length)
	local requested = valid_length(length, #ensure_data(self) - self:GetPosition())
	if requested == nil or requested < 0 then
		self._cb_read_error = true
		return ""
	end
	return read_blob(self, requested) or ""
end

function CBufferStream:WriteUTFBytes(value, length)
	local bytes = type(value) == "string" and value or ""
	if length ~= nil then
		local requested = valid_length(length, #bytes)
		if requested == nil or requested < 0 then
			requested = 0
		end
		if #bytes > requested then
			bytes = bytes:sub(1, requested)
		elseif #bytes < requested then
			bytes = bytes .. string.rep("\0", requested - #bytes)
		end
	end
	write_blob(self, bytes)
end

function CBufferStream:ReadUTF()
	local length = self:ReadUint16()
	if self:GetReadError() then
		return ""
	end
	return self:ReadUTFBytes(length)
end

function CBufferStream:WriteUTF(value)
	local bytes = type(value) == "string" and value or ""
	local length = math.min(#bytes, 65535)
	self:WriteUint16(length)
	self:WriteUTFBytes(bytes:sub(1, length))
end

function CBufferStream:ReadUCSCounts(count)
	local units = valid_length(count, 0)
	if units == nil or units < 0 then
		self._cb_read_error = true
		return ""
	end

	local remaining = #ensure_data(self) - self:GetPosition()
	if units > math.floor(remaining / 2) then
		self._cb_read_error = true
		return ""
	end

	local bytes = read_blob(self, units * 2)
	if bytes == nil then
		return ""
	end

	local codepoints = {}
	local index = 1
	while index <= units do
		local unit = string.unpack("<I2", bytes, (index - 1) * 2 + 1)
		index = index + 1

		if unit >= 0xD800 and unit <= 0xDBFF and index <= units then
			local next_unit = string.unpack("<I2", bytes, (index - 1) * 2 + 1)
			if next_unit >= 0xDC00 and next_unit <= 0xDFFF then
				unit = 0x10000 + (unit - 0xD800) * 0x400 + (next_unit - 0xDC00)
				index = index + 1
			else
				unit = 0xFFFD
			end
		elseif unit >= 0xD800 and unit <= 0xDFFF then
			unit = 0xFFFD
		end

		codepoints[#codepoints + 1] = utf8.char(unit)
	end
	return table.concat(codepoints)
end

function CBufferStream:ReadBytes(target, offset, size)
	if type(target) == "number" or target == nil then
		local requested = valid_length(target, #ensure_data(self) - self:GetPosition())
		if requested == nil or requested < 0 then
			self._cb_read_error = true
			return ""
		end
		return read_blob(self, requested) or ""
	end

	local target_offset = valid_length(offset, 0)
	local requested = valid_length(size, #ensure_data(self) - self:GetPosition())
	if target_offset == nil or target_offset < 0 or requested == nil or requested < 0 then
		self._cb_read_error = true
		return ""
	end

	local bytes = read_blob(self, requested)
	if bytes == nil then
		return ""
	end

	if type(target) == "table" and type(target._cb_data) == "string" then
		write_at(target, target_offset, bytes)
	elseif type(target) == "table" then
		for index = 1, #bytes do
			target[target_offset + index - 1] = bytes:byte(index)
		end
	elseif type(target) == "userdata" then
		for index = 1, #bytes do
			pcall(function()
				target[target_offset + index - 1] = bytes:byte(index)
			end)
		end
	end

	return bytes
end

function CBufferStream:WriteBytes(source, offset, size)
	if source == nil then
		return
	end

	local source_offset = valid_length(offset, 0)
	if source_offset == nil or source_offset < 0 then
		return
	end

	local source_data
	if type(source) == "string" then
		source_data = source
	elseif type(source) == "table" then
		source_data = ensure_data(source)
	elseif type(source) == "userdata" then
		local ok, source_length = pcall(function()
			return #source
		end)
		if not ok then
			return
		end
		local byte_values = {}
		for index = 0, source_length - 1 do
			local byte_ok, byte = pcall(function()
				return source[index]
			end)
			if byte_ok then
				byte_values[#byte_values + 1] = string.char((tonumber(byte) or 0) & 0xFF)
			end
		end
		source_data = table.concat(byte_values)
	else
		return
	end

	local requested = valid_length(size, math.max(0, #source_data - source_offset))
	if requested == nil or requested < 0 then
		return
	end

	local bytes = source_data:sub(source_offset + 1, source_offset + requested)
	if #bytes < requested then
		bytes = bytes .. string.rep("\0", requested - #bytes)
	end
	write_blob(self, bytes)
end