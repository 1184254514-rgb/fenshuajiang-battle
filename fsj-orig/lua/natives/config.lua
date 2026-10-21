-- Assumptions: CTableConfigMgr row arguments are 1-based and exclude the header; CTabFile row/column arguments are 0-based physical table indexes. Numeric cells become numbers in row tables, while GetConfigString returns their original text. Empty numeric cells and missing numeric values return 0.
-- Config files are loaded lazily through Host. Missing files are logged once and treated as empty.

local logged_missing = {}
local file_cache = {}
local table_views = {}
local singletons = {}

local function log_missing(path)
	if not logged_missing[path] then
		logged_missing[path] = true
		print("[config] missing: " .. tostring(path))
	end
end

local function read_text(path)
	if type(Host) ~= "userdata" and type(Host) ~= "table" then
		log_missing(path)
		return nil
	end

	local ok_exists, exists = pcall(function()
		return Host:file_exists(path)
	end)
	if ok_exists and exists == false then
		log_missing(path)
		return nil
	end

	local ok, text = pcall(function()
		return Host:read_text(path)
	end)
	if not ok or type(text) ~= "string" then
		log_missing(path)
		return nil
	end

	return text
end

local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_tabs(line)
	local fields = {}
	local start = 1
	while true do
		local pos = line:find("\t", start, true)
		if not pos then
			fields[#fields + 1] = line:sub(start)
			break
		end
		fields[#fields + 1] = line:sub(start, pos - 1)
		start = pos + 1
	end
	return fields
end

local function numeric_value(s)
	local t = trim(s)
	if t == "" then return nil end
	return tonumber(t)
end

local function typed_value(s)
	local n = numeric_value(s)
	if n ~= nil then return n end
	return s
end

local function normalize_path(path)
	return (tostring(path or ""):gsub("\\", "/"))
end

local function basename(path)
	local name = normalize_path(path):match("([^/]+)$") or tostring(path or "")
	return (name:gsub("%.[^%.]+$", ""))
end

local function parse_table_text(text, path)
	local data = {
		path = path,
		headers = {},
		rows = {},
		kv = {},
		kvraw = {},
		by_id = {},
		has_header = false,
		width = 0,
	}

	if type(text) ~= "string" or text == "" then return data end
	text = text:gsub("^\239\187\191", "")
	text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

	local lines = {}
	for line in (text .. "\n"):gmatch("(.-)\n") do
		if line ~= "" then
			lines[#lines + 1] = line
		end
	end
	if #lines == 0 then return data end

	local first = split_tabs(lines[1])
	local second = lines[2] and split_tabs(lines[2]) or nil
	local first_is_numeric = numeric_value(first[1]) ~= nil
	local second_is_numeric = first[2] ~= nil and numeric_value(first[2]) ~= nil

	-- Key/value files such as constant.txt and string.txt have no column header.
	-- A one-column label followed by numeric rows is a normal header.
	local key_value = not first_is_numeric and second_is_numeric
	data.key_value = key_value
	local header = not first_is_numeric and not key_value
	if #first == 1 and second and numeric_value(second[1]) ~= nil then
		header = true
	end

	local first_data_line = 1
	if header then
		data.has_header = true
		data.headers = first
		first_data_line = 2
	else
		for i = 1, #first do
			data.headers[i] = "col" .. tostring(i)
		end
	end

	data.width = #data.headers
	for line_index = first_data_line, #lines do
		local cells = split_tabs(lines[line_index])
		if #cells > data.width then
			for i = data.width + 1, #cells do
				data.headers[i] = "col" .. tostring(i)
			end
			data.width = #cells
		end

		local row = {
			_raw = cells,
			_rowIndex = #data.rows + 1,
			tblFile = data,
		}
		for col = 1, data.width do
			local name = trim(data.headers[col] or "")
			local raw = cells[col] or ""
			if name ~= "" then
				row[name] = typed_value(raw)
				row._raw[name] = raw
			end
		end
		data.rows[#data.rows + 1] = row

		local key_raw = cells[1]
		if key_raw and key_raw ~= "" then
			local key_typed = typed_value(key_raw)
			data.kv[key_raw] = typed_value(cells[2] or "")
			data.kvraw[key_raw] = cells[2] or ""
			data.by_id[key_raw] = row
			data.by_id[tostring(key_typed)] = row
			if type(key_typed) == "number" then
				data.by_id[key_typed] = row
			end
		end
	end

	return data
end

local function load_table(path)
	path = normalize_path(path)
	if file_cache[path] ~= nil then
		return file_cache[path] or nil
	end

	local text = read_text(path)
	if text == nil then
		file_cache[path] = false
		return nil
	end

	local data = parse_table_text(text, path)
	file_cache[path] = data
	return data
end

local function row_by_id(data, id, id_field)
	if not data then return nil end
	if id == nil then return nil end

	if id_field then
		for _, row in ipairs(data.rows) do
			if row[id_field] == id or tostring(row[id_field]) == tostring(id) then
				return row
			end
		end
	end

	local row = data.by_id[id] or data.by_id[tostring(id)]
	if row then return row end

	local n = tonumber(id)
	if n then
		return data.rows[n] or data.rows[n + 1]
	end
	return nil
end

local function row_by_index(data, index, zero_based)
	if not data or index == nil then return nil end
	local n = tonumber(index)
	if not n then return nil end
	if zero_based then n = n + 1 end
	return data.rows[n]
end

local function raw_cell(row, field)
	if not row then return nil end
	local raw = row._raw and row._raw[field]
	if raw ~= nil then return raw end
	local value = row[field]
	if value == nil then return nil end
	return tostring(value)
end

local function get_field(row, field)
	if not row or field == nil then return nil end
	return row[field]
end

local function get_number(row, field, default)
	if default == nil then default = 0 end
	if not row or field == nil then return default end
	local value = row[field]
	if type(value) == "number" then return value end
	local n = tonumber(value)
	if n ~= nil then return n end
	return default
end

local function normalize_name(value)
	return (tostring(value or ""):lower():gsub("[^%w]", ""))
end

local function value_for_field(data, row, requested)
	if not row then return nil end
	if row[requested] ~= nil then return row[requested] end
	local wanted = normalize_name(requested)
	for _, header in ipairs(data and data.headers or {}) do
		if normalize_name(header) == wanted then
			return row[header]
		end
		local normalized = normalize_name(header)
		if normalized:sub(2) == wanted then
			return row[header]
		end
	end
	return nil
end

local function dictionary_value(value)
	if value == nil then return nil end
	if type(CDictionary) ~= "table" then return nil end
	local dict
	if type(CDictionary.Inst) == "function" then
		dict = CDictionary:Inst()
	end
	if not dict or type(dict.GetValueByString) ~= "function" then return nil end
	local ok, result = pcall(function()
		return dict:GetValueByString(value)
	end)
	if ok then return result end
	return nil
end

local function maybe_translate(value)
	if value == nil then return nil end
	local result = dictionary_value(value)
	if result ~= nil then return result end
	return value
end

local function table_view(data, alias)
	if not data then return nil end
	local view = {
		nRowCount = #data.rows,
		nColumnCount = data.width,
		nWidth = data.width,
		rows = data.rows,
		byID = data.by_id,
		tblFile = data,
	}
	for i, row in ipairs(data.rows) do
		if rawget(view, i) == nil then view[i] = row end
		row.nRowIndex = i
		local raw_id = row._raw and row._raw[1]
		local typed_id = row._raw and typed_value(raw_id or "")
		if raw_id and raw_id ~= "" then
			view[raw_id] = row
			view[tostring(typed_id)] = row
			if type(typed_id) == "number" then view[typed_id] = row end
		end
	end

	setmetatable(view, {
		__index = function(_, key)
			return data.by_id[key] or data.by_id[tostring(key)]
		end,
	})
	table_views[alias] = data
	return view
end

g_tblTabFile = rawget(_G, "g_tblTabFile") or {}

local function register_table(path)
	local data = load_table(path)
	if not data then return nil end
	local alias = basename(path)
	local view = table_view(data, alias)
	table_views[alias] = data
	table_views[alias:lower()] = data
	return data
end

local function empty_ctor()
end

local native_classes = {
	CTableConfigMgr, CTabFile, CIniFile, CJson, CDictionary, CStringConfig,
	CKickMsgConfig, CRenamePrizeConfig, CStarLevelConfig, CRewardConfig,
	CGameTipConfig, CSignInPrizeConfig, CRollActivityConfig, CMusicConfig,
	CRectConfig, CFontConfig, CAIEquipConfig, CPlayerLevelConfig,
	CDailyTaskConfig, CRankPrizeConfig, CEvaluateConfig,
	CTreasureBoxOpenConsume, CSkillConf, CSceneList, CMapInfo,
	CInventoryConfig, CUSFilter, CSnakeConstant,
}
for _, cls in ipairs(native_classes) do
	if type(cls) == "table" and rawget(cls, "Ctor") == nil then
		cls.Ctor = empty_ctor
	end
end

local function define_singleton(cls)
	if type(cls) ~= "table" then return end
	function cls.Inst(...)
		local instance = singletons[cls]
		if not instance then
			instance = setmetatable({}, cls)
			singletons[cls] = instance
			local ctor = rawget(cls, "Ctor")
			if ctor then ctor(instance, ...) end
		end
		return instance
	end
	cls.Instance = cls.Inst
end

for _, cls in ipairs(native_classes) do
	define_singleton(cls)
end

function CTableConfigMgr:Load(path, bFlag, bFlag2)
	local data = register_table(path)
	return data ~= nil
end

local function data_of(name)
	local alias = tostring(name or ""):lower()
	local data = table_views[alias]
	if not data then data = register_table("config/" .. tostring(name or "") .. ".txt") end
	return data
end

-- Natives used by ShellCommonLua/misc/CTableConfigMgr.lua (row indices are 1-based data rows; 0 = not found)
function CTableConfigMgr:GetConfigRowCount(name) local d = data_of(name) return d and #d.rows or 0 end
function CTableConfigMgr:GetConfigColumnCount(name) local d = data_of(name) return d and d.width or 0 end
function CTableConfigMgr:IsSingleColumn(name) local d = data_of(name) return d ~= nil and d.key_value == true end
function CTableConfigMgr:GetRowIndexByString(name, key)
	local d = data_of(name)
	local row = d and (d.by_id[key] or d.by_id[tostring(key)])
	return row and row._rowIndex or 0
end
function CTableConfigMgr:GetRowIndexByNumber(name, key)
	local d = data_of(name)
	local row = d and (d.by_id[key] or d.by_id[tostring(key)])
	return row and row._rowIndex or 0
end
function CTableConfigMgr:GetConfigNumber(name, row_index, field)
	local d = data_of(name)
	if not d then return 0 end
	local row = row_by_index(d, row_index, false)
	if not row then return 0 end
	if field == nil then return tonumber(row._raw and row._raw[2]) or 0 end
	return get_number(row, field, 0)
end
function CTableConfigMgr:GetConfigString(name, row_index, field)
	local d = data_of(name)
	if not d then return "" end
	local row = row_by_index(d, row_index, false)
	if not row then return "" end
	if field == nil then return row._raw and row._raw[2] or "" end
	return raw_cell(row, field) or ""
end

function CTableConfigMgr:GetConfig(name, row_index)
	local alias = tostring(name or ""):lower()
	local data = table_views[alias]
	if not data then
		local view = g_tblTabFile[alias] or g_tblTabFile[name]
		if view then data = rawget(view, "tblFile") end
	end
	if not data then data = register_table("config/" .. tostring(name or "") .. ".txt") end
	return row_by_index(data, row_index, false)
end

function CTableConfigMgr:GetRowCount(name)
	local alias = tostring(name or ""):lower()
	local data = table_views[alias]
	if not data then data = register_table("config/" .. tostring(name or "") .. ".txt") end
	return data and #data.rows or 0
end

function CTableConfigMgr:GetConfigTable(name)
	local alias = tostring(name or ""):lower()
	local view = g_tblTabFile[alias] or g_tblTabFile[name]
	if view then return view end
	register_table("config/" .. tostring(name or "") .. ".txt")
	return g_tblTabFile[alias] or g_tblTabFile[name]
end

function CTabFile:Ctor()
	self.m_data = parse_table_text("", "")
end

local function decode_text(raw)
	if raw:sub(1, 2) == "\255\254" then          -- UTF-16LE BOM
		local out, i, n = {}, 3, #raw
		while i + 1 <= n do
			local c = raw:byte(i) | (raw:byte(i + 1) << 8); i = i + 2
			if c >= 0xD800 and c <= 0xDBFF and i + 1 <= n then
				local c2 = raw:byte(i) | (raw:byte(i + 1) << 8)
				if c2 >= 0xDC00 and c2 <= 0xDFFF then c = 0x10000 + ((c - 0xD800) << 10) + (c2 - 0xDC00); i = i + 2 end
			end
			out[#out + 1] = utf8.char(c)
		end
		return table.concat(out)
	elseif raw:sub(1, 3) == "\239\187\191" then   -- UTF-8 BOM
		return raw:sub(4)
	end
	return raw
end

local function buffer_to_string(buffer, size)
	local raw
	if type(buffer) == "string" then
		raw = buffer
	elseif type(buffer) == "table" and type(rawget(buffer, "_cb_data")) == "string" then
		raw = rawget(buffer, "_cb_data")
	elseif type(buffer) == "table" then
		raw = rawget(buffer, "data") or rawget(buffer, "text") or rawget(buffer, "m_data")
	end
	if type(raw) ~= "string" then return "" end
	if size and tonumber(size) and tonumber(size) >= 0 then raw = raw:sub(1, tonumber(size)) end
	return decode_text(raw)
end

function CTabFile:Init(buffer, size)
	local text = buffer_to_string(buffer, size)
	self.m_data = parse_table_text(text, "<buffer>")
	self.m_text = text
	return text ~= ""
end

function CTabFile:GetHeight()
	local data = self.m_data
	if not data then return 0 end
	return #data.rows + (data.has_header and 1 or 0)
end

function CTabFile:GetWidth()
	return self.m_data and self.m_data.width or 0
end

function CTabFile:GetRowCount()
	return self.m_data and #self.m_data.rows or 0
end

function CTabFile:GetColumnIndex(name)
	if not self.m_data then return -1 end
	for i, header in ipairs(self.m_data.headers) do
		if header == name then return i - 1 end
	end
	return -1
end

function CTabFile:GetColumnName(index)
	if not self.m_data then return "" end
	local col = tonumber(index) or 0
	return self.m_data.headers[col + 1] or ""
end

function CTabFile:GetString(row_index, column, default)
	default = default == nil and "" or default
	local data = self.m_data
	if not data then return default end

	local row_number = tonumber(row_index)
	if row_number == nil then return default end
	local column_number
	local row

	if type(column) == "string" then
		local name = column
		if data.has_header and row_number == 0 then
			for i, header in ipairs(data.headers) do
				if header == name then return header end
			end
			return default
		end
		row = row_by_index(data, data.has_header and row_number or row_number + 1, false)
		if row then return raw_cell(row, name) or default end
		return default
	end

	column_number = (tonumber(column) or 0) + 1
	if data.has_header and row_number == 0 then
		return data.headers[column_number] or default
	end
	local data_row = data.has_header and row_number or (row_number + 1)
	row = row_by_index(data, data_row, false)
	if not row then return default end
	local header = data.headers[column_number]
	if header then return raw_cell(row, header) or default end
	return row._raw and row._raw[column_number] or default
end

function CTabFile:GetInteger(row_index, column, default)
	if default == nil then default = 0 end
	local value = self:GetString(row_index, column, nil)
	local n = tonumber(value)
	if n == nil then return default end
	return math.floor(n)
end

function CTabFile:GetNumber(row_index, column, default)
	if default == nil then default = 0 end
	local value = self:GetString(row_index, column, nil)
	local n = tonumber(value)
	return n == nil and default or n
end

function CTabFile:GetFloat(row_index, column, default)
	return self:GetNumber(row_index, column, default)
end

local function parse_ini(instance, text)
	instance.m_sections = {}
	instance.m_section_names = {}
	local current = ""
	instance.m_sections[current] = {}
	text = tostring(text or ""):gsub("^\239\187\191", ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	for line in (text .. "\n"):gmatch("(.-)\n") do
		local s = trim(line)
		if s ~= "" and not s:match("^[;#]") then
			local section = s:match("^%[([^%]]+)%]$")
			if section then
				current = trim(section)
				instance.m_sections[current] = instance.m_sections[current] or {}
				instance.m_section_names[current] = true
			else
				local key, value = s:match("^([^=]+)=(.*)$")
				if key then
					instance.m_sections[current][trim(key)] = trim(value)
				end
			end
		end
	end
end

function CIniFile:Ctor()
	self.m_sections = { [""] = {} }
	self.m_section_names = {}
end

function CIniFile:Init(source)
	local text
	if type(source) == "string" and (source:find("\n", 1, true) or source:find("=", 1, true)) then
		text = source
	else
		text = read_text(source)
	end
	if text == nil then
		parse_ini(self, "")
		return false
	end
	parse_ini(self, text)
	return true
end

function CIniFile:Load(path)
	return self:Init(path)
end

function CIniFile:GetString(section, key, default)
	default = default == nil and "" or default
	local values = self.m_sections and self.m_sections[tostring(section or "")]
	local value = values and values[tostring(key or "")]
	if value == nil then return default end
	return value
end

function CIniFile:GetInteger(section, key, default)
	if default == nil then default = 0 end
	local n = tonumber(self:GetString(section, key, nil))
	if n == nil then return default end
	return math.floor(n)
end

function CIniFile:GetNumber(section, key, default)
	if default == nil then default = 0 end
	local n = tonumber(self:GetString(section, key, nil))
	return n == nil and default or n
end

function CIniFile:SetString(section, key, value)
	local name = tostring(section or "")
	self.m_sections = self.m_sections or { [""] = {} }
	self.m_sections[name] = self.m_sections[name] or {}
	self.m_sections[name][tostring(key or "")] = tostring(value or "")
	self.m_section_names[name] = true
	return true
end

function CIniFile:SetInteger(section, key, value)
	return self:SetString(section, key, math.floor(tonumber(value) or 0))
end

function CIniFile:SetNumber(section, key, value)
	return self:SetString(section, key, tonumber(value) or 0)
end

function CIniFile:WriteString(section, key, value)
	return self:SetString(section, key, value)
end

function CIniFile:Save(path)
	if not path then return false end
	local sections = self.m_sections or {}
	local names = {}
	for name in pairs(sections) do
		if name ~= "" then names[#names + 1] = name end
	end
	table.sort(names)
	local lines = {}
	for key, value in pairs(sections[""] or {}) do
		lines[#lines + 1] = tostring(key) .. "=" .. tostring(value)
	end
	for _, name in ipairs(names) do
		lines[#lines + 1] = "[" .. name .. "]"
		local keys = {}
		for key in pairs(sections[name] or {}) do keys[#keys + 1] = key end
		table.sort(keys)
		for _, key in ipairs(keys) do
			lines[#lines + 1] = tostring(key) .. "=" .. tostring(sections[name][key])
		end
	end
	return table.concat(lines, "\n")
end

local function json_decode(text)
	local i, length = 1, #text

	local function skip_space()
		while i <= length and text:sub(i, i):match("%s") do i = i + 1 end
	end

	local parse_value

	local function parse_string()
		i = i + 1
		local out = {}
		while i <= length do
			local c = text:sub(i, i)
			if c == '"' then
				i = i + 1
				return table.concat(out)
			elseif c == "\\" then
				local escape = text:sub(i + 1, i + 1)
				i = i + 2
				if escape == '"' or escape == "\\" or escape == "/" then
					out[#out + 1] = escape
				elseif escape == "b" then
					out[#out + 1] = "\b"
				elseif escape == "f" then
					out[#out + 1] = "\f"
				elseif escape == "n" then
					out[#out + 1] = "\n"
				elseif escape == "r" then
					out[#out + 1] = "\r"
				elseif escape == "t" then
					out[#out + 1] = "\t"
				elseif escape == "u" then
					local hex = text:sub(i, i + 3)
					local cp = tonumber(hex, 16)
					i = i + 4
					if cp then
						if cp >= 0xD800 and cp <= 0xDBFF and text:sub(i, i + 1) == "\\u" then
							local low = tonumber(text:sub(i + 2, i + 5), 16)
							if low and low >= 0xDC00 and low <= 0xDFFF then
								cp = 0x10000 + (cp - 0xD800) * 0x400 + (low - 0xDC00)
								i = i + 6
							end
						end
						out[#out + 1] = utf8.char(cp)
					end
				elseif escape ~= "" then
					out[#out + 1] = escape
				end
			else
				out[#out + 1] = c
				i = i + 1
			end
		end
		return nil
	end

	local function parse_array()
		i = i + 1
		local result = {}
		skip_space()
		if text:sub(i, i) == "]" then i = i + 1 return result end
		while i <= length do
			local value = parse_value()
			result[#result + 1] = value
			skip_space()
			local c = text:sub(i, i)
			if c == "]" then i = i + 1 return result end
			if c ~= "," then return nil end
			i = i + 1
			skip_space()
		end
		return nil
	end

	local function parse_object()
		i = i + 1
		local result = {}
		skip_space()
		if text:sub(i, i) == "}" then i = i + 1 return result end
		while i <= length do
			if text:sub(i, i) ~= '"' then return nil end
			local key = parse_string()
			if key == nil then return nil end
			skip_space()
			if text:sub(i, i) ~= ":" then return nil end
			i = i + 1
			local value = parse_value()
			result[key] = value
			skip_space()
			local c = text:sub(i, i)
			if c == "}" then i = i + 1 return result end
			if c ~= "," then return nil end
			i = i + 1
			skip_space()
		end
		return nil
	end

	parse_value = function()
		skip_space()
		local c = text:sub(i, i)
		if c == '"' then return parse_string() end
		if c == "{" then return parse_object() end
		if c == "[" then return parse_array() end
		if text:sub(i, i + 3) == "true" then i = i + 4 return true end
		if text:sub(i, i + 4) == "false" then i = i + 5 return false end
		if text:sub(i, i + 3) == "null" then i = i + 4 return nil end
		local token = text:sub(i):match("^%-?%d+%.?%d*[eE]?[+-]?%d*")
		if token and token ~= "" then
			local number = tonumber(token)
			if number ~= nil then
				i = i + #token
				return number
			end
		end
		return nil
	end

	local result = parse_value()
	skip_space()
	if i <= length then return nil end
	return result
end

function CJson:Ctor()
	self.m_value = nil
	self.m_error = nil
end

function CJson:Init(text, size)
	local source = buffer_to_string(text, size)
	local value = json_decode(source)
	self.m_value = value
	self.m_error = value == nil and "invalid json" or nil
	return value ~= nil
end

function CJson:Parse(text)
	return self:Init(text)
end

function CJson:Load(path)
	local text = read_text(path)
	if not text then return false end
	return self:Init(text)
end

local function json_path(value, ...)
	local keys = { ... }
	if #keys == 0 then return value end
	local current = value
	for _, key in ipairs(keys) do
		if type(current) ~= "table" then return nil end
		current = current[key]
	end
	return current
end

function CJson:GetValue(key, ...)
	if key == nil then return self.m_value end
	return json_path(self.m_value, key, ...)
end

function CJson:GetString(key, default, ...)
	local value = self:GetValue(key, ...)
	if value == nil then return default == nil and "" or default end
	if type(value) == "string" then return value end
	return tostring(value)
end

function CJson:GetInteger(key, default, ...)
	local value = self:GetValue(key, ...)
	local number = tonumber(value)
	if number == nil then return default == nil and 0 or default end
	return math.floor(number)
end

function CJson:GetNumber(key, default, ...)
	local number = tonumber(self:GetValue(key, ...))
	return number == nil and (default == nil and 0 or default) or number
end

function CJson:GetBoolean(key, default, ...)
	local value = self:GetValue(key, ...)
	if type(value) == "boolean" then return value end
	if value == nil then return default or false end
	if value == 0 or value == "0" or value == "false" then return false end
	return true
end

function CJson:GetArray(key, ...)
	local value = self:GetValue(key, ...)
	return type(value) == "table" and value or {}
end

function CJson:GetObject(key, ...)
	local value = self:GetValue(key, ...)
	return type(value) == "table" and value or {}
end

function CJson:SetValue(key, value, ...)
	local keys = { key, ... }
	if #keys == 0 then self.m_value = value return true end
	if type(self.m_value) ~= "table" then self.m_value = {} end
	local current = self.m_value
	for i = 1, #keys - 1 do
		local part = keys[i]
		if type(current[part]) ~= "table" then current[part] = {} end
		current = current[part]
	end
	current[keys[#keys]] = value
	return true
end

function CJson:GetError()
	return self.m_error
end

local dictionary_cache = {}

local function read_dictionary_file(letter)
	letter = tostring(letter or ""):lower()
	if dictionary_cache[letter] ~= nil then return dictionary_cache[letter] end
	local path = "config/dictionary/" .. letter .. ".txt"
	local text = read_text(path)
	if text == nil then
		dictionary_cache[letter] = false
		return nil
	end

	local result = {}
	text = text:gsub("^\239\187\191", ""):gsub("\r\n", "\n"):gsub("\r", "\n")
	for line in (text .. "\n"):gmatch("(.-)\n") do
		local id, value = line:match("^([^\t]+)\t(.*)$")
		if id then result[trim(id)] = value end
	end
	dictionary_cache[letter] = result
	return result
end

function CDictionary:Load(path)
	if path then
		local text = read_text(path)
		if not text then return false end
		local values = {}
		for line in (text .. "\n"):gmatch("(.-)\n") do
			local id, value = line:match("^([^\t]+)\t(.*)$")
			if id then values[trim(id)] = value end
		end
		self.m_values = values
		return true
	end
	return true
end

function CDictionary:GetValueByString(key)
	if key == nil then return nil end
	if self.m_values then
		local value = self.m_values[tostring(key)]
		if value ~= nil then return value end
	end

	local id = tostring(key)
	local values = read_dictionary_file(id:sub(1, 1))
	if values and values[id] ~= nil then return values[id] end

	-- Some scripts carry a category prefix before the dictionary ID.
	local suffix = id:match("([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])$")
	if suffix then
		local suffix_values = read_dictionary_file(suffix:sub(1, 1))
		if suffix_values then return suffix_values[suffix] end
	end

	local number = tonumber(id)
	if number then
		local padded = string.format("%08d", math.floor(number))
		local padded_values = read_dictionary_file(padded:sub(1, 1))
		if padded_values then return padded_values[padded] end
	end
	return nil
end

function CDictionary:GetValueByID(id)
	return self:GetValueByString(id)
end

function CDictionary:GetValue(key)
	return self:GetValueByString(key)
end

local function string_config_data()
	return load_table("config/string.txt")
end

local function string_config_lookup(key)
	local data = string_config_data()
	if data then
		local raw_key = tostring(key or "")
		local raw_value = data.kvraw[raw_key]
		if raw_value ~= nil then
			local translated = dictionary_value(raw_value)
			return translated or raw_value
		end
	end
	return dictionary_value(key)
end

local function text_buffer(text)
	local object = { m_text = tostring(text or ""), m_position = 0 }
	function object:ReadUTFBytes(count)
		local start = self.m_position + 1
		local stop = count and (self.m_position + tonumber(count)) or #self.m_text
		local value = self.m_text:sub(start, stop)
		self.m_position = math.min(#self.m_text, stop)
		return value
	end
	function object:ReadString(count)
		return self:ReadUTFBytes(count)
	end
	function object:GetSize()
		return #self.m_text
	end
	function object:GetLength()
		return #self.m_text
	end
	function object:SetPosition(position)
		self.m_position = math.max(0, tonumber(position) or 0)
		return true
	end
	function object:GetPosition()
		return self.m_position
	end
	function object:ToString()
		return self.m_text
	end
	return object
end

function CStringConfig:GetString(key, default)
	local value = string_config_lookup(key)
	if value ~= nil then return value end
	return default == nil and tostring(key or "") or default
end

function CStringConfig:GetTarStr(task_id)
	local data = load_table("config/dailytask.txt")
	local row = row_by_id(data, task_id, "nTaskID")
	local value = value_for_field(data, row, "TarStr")
		or value_for_field(data, row, "TargetString")
		or value_for_field(data, row, "dTarget")
		or value_for_field(data, row, "nTargetString")
	return text_buffer(maybe_translate(value) or "")
end

function CStringConfig:GetSkinStr(value)
	local key = tostring(value or "")
	local candidates = {
		"SkinStr" .. key,
		"Skin" .. key,
		"GetSkinStr" .. key,
	}
	for _, candidate in ipairs(candidates) do
		local result = string_config_lookup(candidate)
		if result ~= nil then return text_buffer(result) end
	end
	return text_buffer(string_config_lookup(key) or "")
end

function CStringConfig:GetValue(key)
	return self:GetString(key)
end

function CKickMsgConfig:GetErrMsg(notify_type)
	local data = load_table("config/World2ClientTips.txt")
	local row = row_by_id(data, notify_type, "nID")
	local value = row and row.dDescribe
	if value == nil then return "" end
	return maybe_translate(value) or tostring(value)
end

local function rename_row(index)
	local data = load_table("config/renameprize.txt")
	local n = tonumber(index) or 0
	return row_by_id(data, n + 1, "nID") or row_by_id(data, n, "nID")
end

function CRenamePrizeConfig:GetCostType(index)
	return get_number(rename_row(index), "nCostType", 0)
end

function CRenamePrizeConfig:GetPrize(index)
	return get_number(rename_row(index), "nCostValue", 0)
end

local function star_data()
	return load_table("config/starlevel.txt")
end

local function star_row(star)
	local data = star_data()
	if not data then return nil end
	local row = row_by_id(data, star, "nAllStar")
	if row then return row end
	local n = tonumber(star)
	if not n then return nil end
	if n < 0 then return data.rows[1] end
	return data.rows[#data.rows]
end

function CStarLevelConfig:GetLevel(star)
	return get_number(star_row(star), "nLevel", 0)
end

function CStarLevelConfig:GetBigLevel(star)
	local row = star_row(star)
	return get_number(row, "nBigLevel", get_number(row, "nLevel", 0))
end

function CStarLevelConfig:HaveStarOnLevel(star)
	return get_number(star_row(star), "nCurStar", 0)
end

function CStarLevelConfig:GetStarOnLevel(star)
	return get_number(star_row(star), "nStar", 0)
end

function CStarLevelConfig:GetMaxStar()
	local data = star_data()
	local maximum = 0
	for _, row in ipairs(data and data.rows or {}) do
		maximum = math.max(maximum, get_number(row, "nAllStar", 0))
	end
	return maximum
end

function CStarLevelConfig:GetMaxLevel()
	local data = star_data()
	local maximum = 0
	for _, row in ipairs(data and data.rows or {}) do
		maximum = math.max(maximum, get_number(row, "nLevel", 0))
	end
	return maximum
end

function CStarLevelConfig:GetStarCount(level)
	local data = star_data()
	local target = tonumber(level) or 0
	for _, row in ipairs(data and data.rows or {}) do
		if get_number(row, "nLevel", -1) >= target then
			return get_number(row, "nAllStar", 0)
		end
	end
	return self:GetMaxStar()
end

function CStarLevelConfig:GetName(star)
	local row = star_row(star)
	return maybe_translate(row and row.nName) or ""
end

function CStarLevelConfig:GetIconID(star)
	return get_number(star_row(star), "nIconID", 0)
end

function CStarLevelConfig:GetDescription(star)
	local row = star_row(star)
	return maybe_translate(row and row.dDescription) or ""
end

function CStarLevelConfig:GetSeasonPrizeStr(star)
	local row = star_row(star)
	return tostring(row and row.nSeasonPrizeList or "")
end

function CStarLevelConfig:GetSeasonPrizeStrByLevel(level)
	local data = star_data()
	local target = tonumber(level)
	if not target then return "" end
	for _, row in ipairs(data and data.rows or {}) do
		if get_number(row, "nLevel", -1) == target then
			return tostring(row.nSeasonPrizeList or "")
		end
	end
	return ""
end

local function reward_row(id)
	local data = load_table("config/reward.txt")
	return row_by_id(data, id, "nID")
end

function CRewardConfig:GetType(id)
	return get_number(reward_row(id), "nType", 0)
end

function CRewardConfig:GetItemID(id)
	return get_number(reward_row(id), "nItemID", 0)
end

function CRewardConfig:GetCount(id)
	return get_number(reward_row(id), "nCount", 0)
end

function CRewardConfig:GetName(id)
	local row = reward_row(id)
	return maybe_translate(row and row.dName) or ""
end

function CGameTipConfig:GetString(show_type, star)
	local data = load_table("config/uitips.txt")
	local row = row_by_id(data, show_type, "id")
	if not row then row = row_by_index(data, (tonumber(show_type) or 0) + 1, false) end
	if row then
		local required_star = get_number(row, "nStar", -1)
		if required_star < 0 or star == nil or (tonumber(star) or -1) >= required_star then
			local value = row.dicnum
			return maybe_translate(value) or ""
		end
	end
	return ""
end

local function signin_data()
	return load_table("config/signin_prize.txt")
end

local function signin_row(day)
	return row_by_id(signin_data(), day, "nMonthDay")
end

local function signin_prefix(month_stamp)
	if type(month_stamp) == "string" then
		local value = month_stamp:lower()
		if value:find("double", 1, true) or value == "dm" then return "DM" end
		return "SM"
	end
	local n = tonumber(month_stamp) or 0
	return n == 0 and "SM" or "DM"
end

function CSignInPrizeConfig:GetDayType(month_stamp, day)
	local prefix = signin_prefix(month_stamp)
	return get_number(signin_row(day), "n" .. prefix .. "DayType", 0)
end

function CSignInPrizeConfig:GetTag(month_stamp, day)
	local prefix = signin_prefix(month_stamp)
	return get_number(signin_row(day), "n" .. prefix .. "Tag", 0)
end

local function write_buffer_value(buffer, value)
	if type(buffer) == "table" then
		local values = rawget(buffer, "m_ConfigValues")
		if not values then values = {}; rawset(buffer, "m_ConfigValues", values) end
		values[#values + 1] = value
	end

	if buffer == nil then return end
	local names = { "WriteUint32", "WriteUInt32", "WriteInt32", "WriteNumber" }
	local mt = getmetatable(buffer)
	local methods = mt and type(mt.__index) == "table" and mt.__index or nil
	for _, name in ipairs(names) do
		local fn = rawget(buffer, name) or (mt and rawget(mt, name)) or (methods and rawget(methods, name))
		if type(fn) == "function" then
			pcall(fn, buffer, value)
			return
		end
	end
end

function CSignInPrizeConfig:GetCurMonthPrize(month_stamp, buffer)
	local data = signin_data()
	local prefix = signin_prefix(month_stamp)
	for _, row in ipairs(data and data.rows or {}) do
		write_buffer_value(buffer, get_number(row, "n" .. prefix .. "Month", 0))
	end
	return true
end

local function roll_row(index)
	local data = load_table("config/day_roll_activity.txt")
	local n = tonumber(index)
	if n == nil then return nil end
	return row_by_id(data, n + 1, "nID") or row_by_index(data, n + 1, false)
end

function CRollActivityConfig:GetPrizeIDByPos(activity_index, position)
	local row = roll_row(activity_index)
	local pos = math.floor(tonumber(position) or 0)
	return get_number(row, "nPrizeID" .. tostring(pos), 0)
end

function CRollActivityConfig:GetTagByPos(activity_index, position)
	local row = roll_row(activity_index)
	local pos = math.floor(tonumber(position) or 0)
	return get_number(row, "nTag" .. tostring(pos), 0)
end

function CRollActivityConfig:GetActivityStartHour(activity_index)
	return get_number(roll_row(activity_index), "nStarthour", 0)
end

function CRollActivityConfig:GetActivityEndHour(activity_index)
	return get_number(roll_row(activity_index), "nEndHour", 0)
end

function CRollActivityConfig:GetActivityTimes(activity_index, is_vip)
	local row = roll_row(activity_index)
	if is_vip then return get_number(row, "nVIPRollTimes", get_number(row, "nRollTimes", 0)) end
	return get_number(row, "nRollTimes", 0)
end

local function music_data()
	return load_table("config/music.txt")
end

local function music_row(id)
	local data = music_data()
	return row_by_id(data, id, "nID")
end

local function music_row_by_index(index)
	return row_by_index(music_data(), index, true)
end

local function music_value(id, ...)
	local row = music_row(id)
	if row then return row end
	return music_row_by_index(id)
end

function CMusicConfig:GetMusicCount()
	local data = music_data()
	return data and #data.rows or 0
end

function CMusicConfig:GetMusicID(index)
	local row = music_row_by_index(index)
	return get_number(row, "nID", 0)
end

function CMusicConfig:GetMusicSort(index)
	local row = music_row_by_index(index)
	return get_number(row, "nSort", 0)
end

function CMusicConfig:GetMusicName(id)
	local row = music_value(id)
	return maybe_translate(row and row.dName) or ""
end

function CMusicConfig:GetMusicPath(id)
	local row = music_value(id)
	return tostring((row and (row.MusicPath or row.szMusicPath)) or "")
end

function CMusicConfig:GetMusicSize(id)
	local row = music_value(id)
	return get_number(row, "nMusicSize", get_number(row, "fMusicSize", get_number(row, "nSize", 0)))
end

function CMusicConfig:IsNetMusic(id)
	local path = self:GetMusicPath(id):lower()
	return path:find("netmusic/", 1, true) == 1
end

function CMusicConfig:IsExistMusicID(id)
	return music_row(id) ~= nil
end

function CMusicConfig:GetSpecial(id)
	local row = music_value(id)
	return get_number(row, "nSpecial", get_number(row, "nAcquire", 0))
end

function CMusicConfig:GetPrice(id)
	local row = music_value(id)
	return get_number(row, "nPrice", get_number(row, "nPropvalue", 0))
end

function CMusicConfig:GetPayType(id)
	return get_number(music_value(id), "nPayType", 0)
end

function CMusicConfig:GetPayIndex(id)
	return get_number(music_value(id), "nPayIndex", 0)
end

function CMusicConfig:GetMusicPlayType(id)
	local row = music_value(id)
	return get_number(row, "nMusicPlayType", get_number(row, "nPlayType", get_number(row, "nType", 0)))
end

function CMusicConfig:GetMusicShowType(id)
	local row = music_value(id)
	return get_number(row, "nShow", get_number(row, "nShowType", 0))
end

function CMusicConfig:GetMusicKind(id, kind_index)
	local data = music_data()
	local row = music_value(id)
	if not row then return 0 end
	local index = math.floor(tonumber(kind_index) or 0)
	local candidates = {
		"nKind" .. tostring(index),
		"nKind" .. tostring(index + 1),
		"nMusicKind" .. tostring(index),
		"nMusicKind" .. tostring(index + 1),
		"Kind" .. tostring(index),
		"Kind" .. tostring(index + 1),
	}
	for _, field in ipairs(candidates) do
		if row[field] ~= nil then return get_number(row, field, 0) end
	end
	local kind = row.nKind or row.nMusicKind
	if type(kind) == "string" then
		local parts = {}
		for part in kind:gmatch("[^;,]+") do parts[#parts + 1] = tonumber(part) or 0 end
		return parts[index + 1] or 0
	end
	if data then
		for _, header in ipairs(data.headers) do
			local normalized = normalize_name(header)
			if normalized == "nkind" .. tostring(index) or normalized == "nmusickind" .. tostring(index) then
				return get_number(row, header, 0)
			end
		end
	end
	return 0
end

local function rect_object(left, top, right, bottom)
	local result = {
		m_left = tonumber(left) or 0,
		m_top = tonumber(top) or 0,
		m_right = tonumber(right) or 0,
		m_bottom = tonumber(bottom) or 0,
	}
	function result:left() return self.m_left end
	function result:top() return self.m_top end
	function result:right() return self.m_right end
	function result:bottom() return self.m_bottom end
	function result:GetLeft() return self.m_left end
	function result:GetTop() return self.m_top end
	function result:GetRight() return self.m_right end
	function result:GetBottom() return self.m_bottom end
	function result:GetWidth() return self.m_right - self.m_left end
	function result:GetHeight() return self.m_bottom - self.m_top end
	return result
end

function CRectConfig:GetRect(index)
	local data = load_table("config/rect.txt")
	local row = row_by_id(data, index, "index") or row_by_index(data, index, true)
	if not row then return rect_object(0, 0, 0, 0) end
	return rect_object(row.left, row.top, row.right, row.bottom)
end

function CRectConfig:GetInfo(index)
	return self:GetRect(index)
end

function CFontConfig:GetFontRect(char_code, color)
	local data = load_table("config/font_config.txt")
	local wanted_char = tonumber(char_code)
	local wanted_color = tonumber(color)
	local fallback
	for _, row in ipairs(data and data.rows or {}) do
		if get_number(row, "cChar", -1) == wanted_char then
			if wanted_color == nil or get_number(row, "nColor", -1) == wanted_color then
				return rect_object(row.fLeft, row.fTop, row.fRight, row.fBottom)
			end
			fallback = row
		end
	end
	if fallback then return rect_object(fallback.fLeft, fallback.fTop, fallback.fRight, fallback.fBottom) end
	return rect_object(0, 0, 0, 0)
end

local function ai_data()
	return load_table("config/ai_equip_random.txt")
end

function CAIEquipConfig:GetAIEquipID(server_hours, ladder_star, object_id, flag)
	local data = ai_data()
	local hours = tonumber(server_hours) or 0
	local star = tonumber(ladder_star) or 0
	local selected
	for _, row in ipairs(data and data.rows or {}) do
		local min_hours = get_number(row, "nServerStartHours", 0)
		local min_star = get_number(row, "nMinLadderStar", 0)
		local max_star = get_number(row, "nMaxLadderStar", 999999)
		if hours >= min_hours and star >= min_star and star <= max_star then
			if not selected or min_hours >= get_number(selected, "nServerStartHours", 0) then
				selected = row
			end
		end
	end
	if not selected then selected = data and data.rows[1] end
	if not selected then return 0 end

	local choices, total = {}, 0
	for i = 1, 10 do
		local id = get_number(selected, "nEquipID" .. tostring(i), 0)
		local weight = get_number(selected, "nMaybe" .. tostring(i), 0)
		if id ~= 0 then
			if weight <= 0 then weight = 1 end
			total = total + weight
			choices[#choices + 1] = { id = id, weight = weight }
		end
	end
	if #choices == 0 then return 0 end

	local seed = math.floor(tonumber(object_id) or (hours * 31 + star * 17))
	local pick = (math.abs(seed) % total) + 1
	for _, choice in ipairs(choices) do
		pick = pick - choice.weight
		if pick <= 0 then return choice.id end
	end
	return choices[1].id
end

local function player_level_data()
	return load_table("config/playerlevel.txt")
end

local function player_level_row(exp)
	local data = player_level_data()
	local value = tonumber(exp) or 0
	local last
	for _, row in ipairs(data and data.rows or {}) do
		last = row
		local minimum = get_number(row, "nExpMin", 0)
		local maximum = get_number(row, "nExpMax", -1)
		if value >= minimum and (maximum < 0 or value < maximum) then return row end
	end
	return last
end

function CPlayerLevelConfig:GetLevel(exp)
	return get_number(player_level_row(exp), "nLevel", 0)
end

function CPlayerLevelConfig:GetCurLevelExp(exp)
	local row = player_level_row(exp)
	return (tonumber(exp) or 0) - get_number(row, "nExpMin", 0)
end

function CPlayerLevelConfig:GetLevelExp(exp)
	local row = player_level_row(exp)
	if not row then return 0 end
	local minimum = get_number(row, "nExpMin", 0)
	local maximum = get_number(row, "nExpMax", -1)
	if maximum < 0 then return -1 end
	return maximum - minimum
end

local function daily_task_data()
	return load_table("config/dailytask.txt")
end

function CDailyTaskConfig:GetTarget(task_id)
	return get_number(row_by_id(daily_task_data(), task_id, "nTaskID"), "nTarget", 0)
end

function CDailyTaskConfig:GetTaskType(task_id)
	return get_number(row_by_id(daily_task_data(), task_id, "nTaskID"), "nTaskType", 0)
end

function CDailyTaskConfig:GetMaxTaskCount()
	local data = daily_task_data()
	return data and #data.rows or 0
end

function CRankPrizeConfig:GetRhythmLevelPrize(rank)
	local data = load_table("config/rankprize.txt")
	local row = row_by_id(data, rank, "rank") or row_by_index(data, rank, true)
	return get_number(row, "coin", 0)
end

function CRankPrizeConfig:GetPrize(index, room_type)
	local data = load_table("config/day_race/race_rankprize.txt")
	local row = row_by_index(data, index, true)
	if not row then
		local rank_data = load_table("config/rankprize.txt")
		row = row_by_id(rank_data, (tonumber(index) or 0) + 1, "rank")
		return get_number(row, "coin", 0)
	end
	return get_number(row, "nPrizeValue1", get_number(row, "nPrizeIndex1", get_number(row, "nPrizeNum", 0)))
end

local function evaluate_label(value)
	local data = load_table("config/evaluate.txt")
	local index = tonumber(value)
	if index == nil then return tostring(value or "") end
	local row = row_by_id(data, index, "Index") or row_by_index(data, index + 1, false)
	if not row then return "" end
	local labels = { "SSS", "SS", "S", "A", "B", "C", "D" }
	for _, label in ipairs(labels) do
		if row[label] ~= nil then return label end
	end
	return ""
end

-- CEvaluateConfig::GetString (0x3342a4): picks one of the colour rows (Index > 10: 11, 12, 13) at random and
-- returns the dictionary text of its column for the code; codes run D=0 .. SSS=6 (GetRank 0x33432c) (Claude)
function CEvaluateConfig:GetString(value)
	local code = tonumber(value)
	local data = load_table("config/evaluate.txt")
	if code == nil or code < 0 or code > 6 or not data then return evaluate_label(value) end
	local rows = {}
	for _, row in ipairs(data.rows or {}) do
		if (tonumber(row.Index) or 0) > 10 then rows[#rows + 1] = row end
	end
	if #rows == 0 then return evaluate_label(value) end
	local row = rows[math.random(#rows)]
	local labels = { "D", "C", "B", "A", "S", "SS", "SSS" }
	local id = row[labels[math.floor(code) + 1]]
	local text = id and CDictionary:Inst():GetValueByString(id)
	return text or ""
end

function CTreasureBoxOpenConsume:GetConsumeCount(remaining_time, pay_index)
	local data = load_table("config/treasurebox/treasureboxopenconsume.txt")
	local minutes = tonumber(remaining_time) or 0
	for _, row in ipairs(data and data.rows or {}) do
		local minimum = get_number(row, "nRemainTimeMin", 0)
		local maximum = get_number(row, "nRemainTimeMax", -1)
		if minutes >= minimum and (maximum < 0 or minutes <= maximum) then
			local index = math.floor(tonumber(pay_index) or 0)
			local field_index = index == 0 and 1 or index
			return get_number(row, "nConsumeCount" .. tostring(field_index), 0)
		end
	end
	return 0
end

local function skill_data()
	return load_table("config/skill/skilllevel.txt")
end

function CSkillConf:GetInfo(skill_id, level)
	local data = skill_data()
	local wanted_id = tonumber(skill_id)
	local wanted_level = tonumber(level)
	for _, row in ipairs(data and data.rows or {}) do
		if get_number(row, "nID", -1) == wanted_id
			and (wanted_level == nil or get_number(row, "nLevel", -1) == wanted_level) then
			return row
		end
	end
	return row_by_id(data, skill_id, "nID")
end

function CSkillConf:GetConfig(skill_id, level)
	return self:GetInfo(skill_id, level)
end

function CSkillConf:GetSkillInfo(skill_id, level)
	return self:GetInfo(skill_id, level)
end

local function parse_attributes(tag)
	local attrs = {}
	for key, quoted, value in tag:gmatch("([%w_]+)%s*=%s*(['\"])(.-)%2") do
		attrs[key:lower()] = value
	end
	return attrs
end

local scene_cache

local function scene_data()
	if scene_cache ~= nil then return scene_cache end
	scene_cache = {}
	local text = read_text("config/scene_list.xml")
	if not text then return scene_cache end
	for tag in text:gmatch("<[%w_:%-]+%s+[^>]->") do
		local attrs = parse_attributes(tag)
		local room = tonumber(attrs.nroomtype or attrs.roomtype or attrs.type)
		local width = tonumber(attrs.nwidth or attrs.width)
		local depth = tonumber(attrs.ndepth or attrs.depth or attrs.nheight or attrs.height)
		if room ~= nil and (width ~= nil or depth ~= nil) then
			scene_cache[room] = {
				nRoomType = room,
				nWidth = width or 0,
				nDepth = depth or 0,
				nHeight = depth or 0,
				tblFile = "config/scene_list.xml",
			}
		end
	end
	return scene_cache
end

local function scene_info_object(info)
	info = info or { nWidth = 0, nDepth = 0, nHeight = 0 }
	local result = {
		nRoomType = info.nRoomType,
		nWidth = info.nWidth or 0,
		nDepth = info.nDepth or info.nHeight or 0,
		nHeight = info.nHeight or info.nDepth or 0,
		tblFile = info.tblFile,
	}
	function result:GetWidth() return self.nWidth end
	function result:GetDepth() return self.nDepth end
	function result:GetHeight() return self.nHeight end
	return result
end

function CSceneList:GetInfo(room_type)
	return scene_info_object(scene_data()[tonumber(room_type) or room_type])
end

function CSceneList:GetSceneInfo(room_type)
	return self:GetInfo(room_type)
end

local function map_data()
	return load_table("config/map/map.txt")
end

function CMapInfo:GetInfo(map_id)
	local data = map_data()
	local result = {}
	for _, row in ipairs(data and data.rows or {}) do
		if tostring(row.nMapID) == tostring(map_id) then
			result[#result + 1] = row
		end
	end
	return result
end

function CMapInfo:GetMapInfo(map_id)
	return self:GetInfo(map_id)
end

local inventory_paths = {
	[0] = "config/resource/currency.txt",
	[1] = "config/resource/equip.txt",
	[2] = "config/resource/musicbase.txt",
	[3] = "config/resource/jiezoutishiqi.txt",
	[4] = "config/resource/battleface.txt",
	[5] = "config/resource/treasureboxbase.txt",
	[6] = "config/resource/fragment.txt",
	[7] = "config/resource/skill.txt",
	currency = "config/resource/currency.txt",
	equip = "config/resource/equip.txt",
	music = "config/resource/musicbase.txt",
	jiezoutishiqi = "config/resource/jiezoutishiqi.txt",
	battleface = "config/resource/battleface.txt",
	treasurebox = "config/resource/treasureboxbase.txt",
	fragment = "config/resource/fragment.txt",
	skill = "config/resource/skill.txt",
	fusion = "config/resource/fusion.txt",
}

local function inventory_row(prop_type, prop_index)
	local path = inventory_paths[prop_type]
	if not path then path = inventory_paths[tostring(prop_type or ""):lower()] end
	if not path then return nil end
	local data = load_table(path)
	return row_by_id(data, prop_index, "nID") or row_by_index(data, prop_index, true)
end

function CInventoryConfig:GetPropIcon(prop_type, prop_index)
	return get_number(inventory_row(prop_type, prop_index), "nIconID", 0)
end

function CInventoryConfig:GetPropRich(prop_type, prop_index)
	local row = inventory_row(prop_type, prop_index)
	return get_number(row, "nPropRich", get_number(row, "nRichIcon", get_number(row, "nRaceIcon", 0)))
end

function CInventoryConfig:GetPropName(prop_type, prop_index)
	local row = inventory_row(prop_type, prop_index)
	return maybe_translate(row and row.dName) or ""
end

local filter_data_cache

local function filter_data()
	if filter_data_cache ~= nil then return filter_data_cache end
	filter_data_cache = load_table("config/ultra_say_filter.txt")
	return filter_data_cache
end

local function filter_column(filter_type)
	local value = tonumber(filter_type)
	if value == 0 then return "nChatFilter" end
	if value == 1 then return "nRoleFilter" end
	if value == 2 then return "nNameFilter" end
	if value == 3 then return "nMailFilter" end
	if type(filter_type) == "string" then
		local s = filter_type:lower()
		if s:find("role", 1, true) then return "nRoleFilter" end
		if s:find("name", 1, true) then return "nNameFilter" end
		if s:find("mail", 1, true) then return "nMailFilter" end
	end
	return "nChatFilter"
end

local function get_buffer_text(buffer, length)
	if type(buffer) == "string" then return buffer end
	if type(buffer) == "table" then
		local value = rawget(buffer, "m_text") or rawget(buffer, "data") or rawget(buffer, "text")
		if type(value) == "string" then return value end
	end
	local mt = type(buffer) == "table" and getmetatable(buffer) or nil
	local methods = mt and type(mt.__index) == "table" and mt.__index or nil
	local fn = (type(buffer) == "table" and rawget(buffer, "ReadUTFBytes"))
		or (mt and rawget(mt, "ReadUTFBytes"))
		or (methods and rawget(methods, "ReadUTFBytes"))
	if type(fn) == "function" then
		local ok, value = pcall(fn, buffer, length)
		if ok and type(value) == "string" then return value end
	end
	return ""
end

function CUSFilter:CheckString(value, length, filter_type)
	local text = tostring(value or "")
	local max_length = tonumber(length)
	if max_length and max_length > 0 and #text + 1 > max_length then
		return false
	end

	local data = filter_data()
	if not data then return true end
	local column = filter_column(filter_type)
	for _, row in ipairs(data.rows) do
		local blocked = get_number(row, column, 0) ~= 0
		local word = row.sString
		if blocked and type(word) == "string" and word ~= "" and text:find(word, 1, true) then
			return false
		end
	end
	return true
end

function CUSFilter:Filter(buffer, length, filter_type)
	local text = get_buffer_text(buffer, length)
	if text == "" then return "" end
	local data = filter_data()
	if not data then return text end
	local column = filter_column(filter_type)
	for _, row in ipairs(data.rows) do
		local word = row.sString
		if type(word) == "string" and word ~= "" and get_number(row, column, 0) ~= 0 then
			local replacement = string.rep("*", math.max(1, #word))
			text = text:gsub(word, replacement)
		end
	end

	if type(buffer) == "table" then
		local mt = getmetatable(buffer)
		local methods = mt and type(mt.__index) == "table" and mt.__index or nil
		local setpos = rawget(buffer, "SetPosition") or (mt and rawget(mt, "SetPosition")) or (methods and rawget(methods, "SetPosition"))
		local write = rawget(buffer, "WriteUTFBytes") or (mt and rawget(mt, "WriteUTFBytes")) or (methods and rawget(methods, "WriteUTFBytes"))
		if type(setpos) == "function" and type(write) == "function" then
			pcall(setpos, buffer, 0)
			pcall(write, buffer, text, #text + 1)
		elseif rawget(buffer, "m_text") ~= nil then
			rawset(buffer, "m_text", text)
		end
	end
	return text
end

local function config_constant_data()
	return load_table("config/constant.txt")
end

local constant_getters = {}
CSnakeConstant.__index = function(self, key)
	local method = rawget(CSnakeConstant, key)
	if method ~= nil then return method end
	-- constant.txt also has lower-case row names (xianshijiesuomianji, tuanzhanjiesuofenshu ...): accept Get<any>
	if type(key) == "string" and key:match("^Get[%a]") then
		if constant_getters[key] then return constant_getters[key] end
		local requested = normalize_name(key:sub(4))
		constant_getters[key] = function()
			local data = config_constant_data()
			if not data then return 0 end
			for _, row in ipairs(data.rows) do
				local row_key = row._raw and row._raw[1] or row.col1
				if normalize_name(row_key) == requested then
					return typed_value(row._raw and row._raw[2] or "")
				end
			end
			return 0
		end
		return constant_getters[key]
	end
	return nil
end

local function install_dynamic_config_getters(cls, path, id_field)
	local cache = {}
	cls.__index = function(self, key)
		local method = rawget(cls, key)
		if method ~= nil then return method end
		if type(key) == "string" and key:match("^Get[A-Z]") then
			if cache[key] then return cache[key] end
			local requested = key:sub(4)
			cache[key] = function(instance, id, optional_field)
				local data = load_table(path)
				if requested == "Count" or requested == "RowCount" then
					return data and #data.rows or 0
				end
				local row = row_by_id(data, id, id_field) or row_by_index(data, id, true)
				local field = optional_field or requested
				local value = value_for_field(data, row, field)
				if value == nil then return 0 end
				if type(value) == "string" and (field:match("^d") or field:match("^sz")) then
					return maybe_translate(value) or value
				end
				return value
			end
			return cache[key]
		end
		return nil
	end
end

install_dynamic_config_getters(CKickMsgConfig, "config/World2ClientTips.txt", "nID")
install_dynamic_config_getters(CRenamePrizeConfig, "config/renameprize.txt", "nID")
install_dynamic_config_getters(CStarLevelConfig, "config/starlevel.txt", "nAllStar")
install_dynamic_config_getters(CRewardConfig, "config/reward.txt", "nID")
install_dynamic_config_getters(CGameTipConfig, "config/uitips.txt", "id")
install_dynamic_config_getters(CSignInPrizeConfig, "config/signin_prize.txt", "nMonthDay")
install_dynamic_config_getters(CRollActivityConfig, "config/day_roll_activity.txt", "nID")
install_dynamic_config_getters(CMusicConfig, "config/music.txt", "nID")
install_dynamic_config_getters(CRectConfig, "config/rect.txt", "index")
install_dynamic_config_getters(CFontConfig, "config/font_config.txt", "cChar")
install_dynamic_config_getters(CAIEquipConfig, "config/ai_equip_random.txt", "nId")
install_dynamic_config_getters(CPlayerLevelConfig, "config/playerlevel.txt", "nLevel")
install_dynamic_config_getters(CDailyTaskConfig, "config/dailytask.txt", "nTaskID")
install_dynamic_config_getters(CRankPrizeConfig, "config/rankprize.txt", "rank")
install_dynamic_config_getters(CEvaluateConfig, "config/evaluate.txt", "Index")
install_dynamic_config_getters(CTreasureBoxOpenConsume, "config/treasurebox/treasureboxopenconsume.txt", "nRemainTimeMin")
install_dynamic_config_getters(CSkillConf, "config/skill/skilllevel.txt", "nID")
install_dynamic_config_getters(CMapInfo, "config/map/map.txt", "nMapID")
install_dynamic_config_getters(CInventoryConfig, "config/resource/equip.txt", "nID")
install_dynamic_config_getters(CUSFilter, "config/ultra_say_filter.txt", "nID")

return true