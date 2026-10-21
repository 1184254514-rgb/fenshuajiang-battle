-- Image and text-style natives shared by CGWnd and every derived window class.
-- GuiImageOps owns the backing arrays and safely ignores missing resources.

local function node_of(wnd)
	return wnd and rawget(wnd, "__node") or nil
end

local function host_call(method_name, ...)
	local host = rawget(_G, "Host")
	if host == nil then return nil end
	local args = { n = select("#", ...), ... }   -- (the original Help.lua redefines table.pack)

	local ok, result = pcall(function()
		local api = host.img
		if api == nil then return nil end
		local method = api[method_name]
		if method == nil then return nil end
		return method(api, table.unpack(args, 1, args.n))
	end)
	if ok then return result end
	return nil
end

local function number_or(value, fallback)
	local number = tonumber(value)
	if number == nil then return fallback end
	return number
end

local function integer_or(value, fallback)
	local number = number_or(value, fallback)
	return math.tointeger(number) or fallback
end

local function color_or(value, fallback)
	if value == nil then return fallback end
	if type(value) == "string" then
		local text = value:gsub("^%s+", ""):gsub("%s+$", "")
		local number = tonumber(text)
		if number == nil then
			local hex = text:gsub("^0[xX]", "")
			if hex:match("^[%da-fA-F]+$") then number = tonumber(hex, 16) end
		end
		if number == nil then return fallback end
		return math.tointeger(number % 4294967296) or fallback
	end
	local number = tonumber(value)
	if number == nil then return fallback end
	return math.tointeger(number % 4294967296) or fallback
end

local function rect_value(rect, name)
	if rect == nil then return nil end
	local ok, member = pcall(function() return rect[name] end)
	if not ok or member == nil then return nil end
	local value = member
	if type(member) == "function" then
		ok, value = pcall(member, rect)
		if not ok then return nil end
	end
	return tonumber(value)
end

local function rect_to_table(rect)
	if rect == nil then return nil end
	return {
		left = rect_value(rect, "left") or rect_value(rect, "l") or 0,
		top = rect_value(rect, "top") or rect_value(rect, "t") or 0,
		right = rect_value(rect, "right") or rect_value(rect, "r") or 0,
		bottom = rect_value(rect, "bottom") or rect_value(rect, "b") or 0
	}
end

local function make_rect(source)
	source = source or {}
	local rect = {
		l = source.left or 0,
		t = source.top or 0,
		r = source.right or 0,
		b = source.bottom or 0
	}
	function rect:left(value) if value ~= nil then self.l = value end return self.l end
	function rect:top(value) if value ~= nil then self.t = value end return self.t end
	function rect:right(value) if value ~= nil then self.r = value end return self.r end
	function rect:bottom(value) if value ~= nil then self.b = value end return self.b end
	function rect:Width() return self.r - self.l end
	function rect:Height() return self.b - self.t end
	return rect
end

local function state_or(value, fallback)
	return integer_or(value, fallback)
end

local function image_rect_set(wnd, method_name, index, rect, image_state)
	if rect == nil then return end
	host_call(method_name, node_of(wnd), integer_or(index, 0), rect_to_table(rect), state_or(image_state, 2))
end

function CGWnd:RestoreImageFromCreateParam()
	return host_call("restore_image_from_create_param", node_of(self)) or false
end

function CGWnd:AddImage(group, image_state, index, texture_path, source_rect, destination_rect,
		color, lock_flags, draw_flags, arg0, arg1, arg2, saturation, hue_transform)
	return host_call(
		"add_image",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		integer_or(index, -1),
		texture_path,
		rect_to_table(source_rect),
		rect_to_table(destination_rect),
		color_or(color, 0xffffffff),
		integer_or(lock_flags, 0),
		integer_or(draw_flags, 0),
		integer_or(arg0, -1),
		integer_or(arg1, -1),
		integer_or(arg2, 0),
		number_or(saturation, 1),
		number_or(hue_transform, 0)
	) or false
end

function CGWnd:AddImageByTexture(group, image_state, index, texture, source_rect, destination_rect,
		color, lock_flags, draw_flags, arg0, arg1, arg2, saturation, hue_transform)
	return host_call(
		"add_image_by_texture",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		integer_or(index, -1),
		texture,
		rect_to_table(source_rect),
		rect_to_table(destination_rect),
		color_or(color, 0xffffffff),
		integer_or(lock_flags, 0),
		integer_or(draw_flags, 0),
		integer_or(arg0, -1),
		integer_or(arg1, -1),
		integer_or(arg2, 0),
		number_or(saturation, 1),
		number_or(hue_transform, 0)
	) or false
end

function CGWnd:GetImageCount(group, image_state)
	return host_call("get_image_count", node_of(self), integer_or(group, 0), state_or(image_state, 2)) or 0
end

function CGWnd:ClearWndBkImage(group, image_state)
	host_call("clear_wnd_bk_image", node_of(self), integer_or(group, 0), state_or(image_state, 2))
end

-- Native form: (group, state, index, color); convenience form: (index, color).
function CGWnd:SetImageColor(group, state_or_color, index_or_color, color)
	local image_group, image_state, image_index, image_color
	if color ~= nil then
		image_group = integer_or(group, 0)
		image_state = state_or(state_or_color, 2)
		image_index = integer_or(index_or_color, -1)
		image_color = color_or(color, 0xffffffff)
	elseif index_or_color ~= nil then
		image_group = integer_or(group, 0)
		image_state = state_or(state_or_color, 2)
		image_index = -1
		image_color = color_or(index_or_color, 0xffffffff)
	elseif state_or_color ~= nil then
		image_group = 0
		image_state = 2
		image_index = integer_or(group, -1)
		image_color = color_or(state_or_color, 0xffffffff)
	else
		return
	end
	host_call("set_image_color", node_of(self), image_group, image_state, image_index, image_color)
end

function CGWnd:GetImageColor(group, image_state, image_index)
	return host_call(
		"get_image_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		integer_or(image_index, 0)
	) or 0xffffffff
end

function CGWnd:SetImageList(group, image_state, image_list, start_index, arg0, arg1, arg2)
	return host_call(
		"set_image_list",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		image_list,
		integer_or(start_index, 0),
		integer_or(arg0, -1),
		integer_or(arg1, 0),
		integer_or(arg2, -1)
	) or false
end

function CGWnd:GetImageWndRect(image_index, image_state)
	return make_rect(host_call(
		"get_image_wnd_rect", node_of(self), integer_or(image_index, 0), state_or(image_state, 2)
	))
end

function CGWnd:GetImageTextureRect(image_index, image_state)
	return make_rect(host_call(
		"get_image_texture_rect", node_of(self), integer_or(image_index, 0), state_or(image_state, 2)
	))
end

function CGWnd:SetImageWndRect(image_index, rect, top, right, bottom, image_state)
	if type(rect) == "number" then
		rect = { left = rect, top = top or 0, right = right or 0, bottom = bottom or 0 }
	end
	image_rect_set(self, "set_image_wnd_rect", image_index, rect, image_state)
end

function CGWnd:SetImageTextureRect(image_index, rect, top, right, bottom, image_state)
	if type(rect) == "number" then
		rect = { left = rect, top = top or 0, right = right or 0, bottom = bottom or 0 }
	end
	image_rect_set(self, "set_image_texture_rect", image_index, rect, image_state)
end

function CGWnd:SetImageTexture(group, image_state, image_index, texture)
	if texture == nil then
		texture, image_index, image_state, group = image_state, group, 2, 0
	end
	return host_call(
		"set_image_texture",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		integer_or(image_index, 0),
		texture
	) or false
end

function CGWnd:SetImageTextureByPath(group, image_state, image_index, path)
	return host_call(
		"set_image_texture_by_path",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		integer_or(image_index, 0),
		path
	) or false
end

function CGWnd:SetImageHue(index_or_group, hue_or_index, hue)
	local image_index, value
	if hue ~= nil then
		image_index, value = integer_or(hue_or_index, 0), number_or(hue, 0)
	else
		image_index, value = integer_or(index_or_group, 0), number_or(hue_or_index, 0)
	end
	host_call("set_image_hue", node_of(self), image_index, value, 2)
end

function CGWnd:SetImageSaturation(image_index, saturation, image_state)
	host_call(
		"set_image_saturation",
		node_of(self),
		integer_or(image_index, -1),
		number_or(saturation, 1),
		state_or(image_state, 2)
	)
end

function CGWnd:GetImageGroup(_image_state)
	return self
end

function CGWnd:GetBounds(_rect)
	return make_rect(host_call("get_bounds", node_of(self)))
end

function CGWnd:SetBackgroundColor(group, image_state, color)
	host_call(
		"set_background_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		color_or(color, 0)
	)
end

function CGWnd:SetWndTextColor(group, image_state, color)
	host_call(
		"set_wnd_text_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		color_or(color, 0xffffffff)
	)
end

function CGWnd:GetWndTextColor(group, image_state)
	return host_call(
		"get_wnd_text_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2)
	) or 0xffffffff
end

function CGWnd:SetStateTextColor(group, image_state, color)
	if color == nil then
		color, image_state, group = image_state, group, 0
	end
	host_call(
		"set_state_text_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		color_or(color, 0xffffffff)
	)
end

function CGWnd:GetStateTextColor(group, image_state)
	if image_state == nil then
		image_state, group = group, 0
	end
	return host_call(
		"get_state_text_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2)
	) or 0xffffffff
end

function CGWnd:SetWndTextBcColor(group, image_state, color)
	host_call(
		"set_wnd_text_background_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2),
		color_or(color, 0)
	)
end

function CGWnd:GetWndTextBcColor(group, image_state)
	return host_call(
		"get_wnd_text_background_color",
		node_of(self),
		integer_or(group, 0),
		state_or(image_state, 2)
	) or 0
end

function CGWnd:SetWndTextBackgroundColor(group, image_state, color)
	return self:SetWndTextBcColor(group, image_state, color)
end

function CGWnd:GetWndTextBackgroundColor(group, image_state)
	return self:GetWndTextBcColor(group, image_state)
end

function CGWnd:SetSaturation(value)
	host_call("set_saturation", node_of(self), number_or(value, 100))
end

function CGWnd:SetMaskTexture(texture)
	return host_call("set_mask_texture", node_of(self), texture) or false
end

function CGWnd:SetMaskTextureByPath(path)
	return host_call("set_mask_texture_by_path", node_of(self), path) or false
end

function CGWnd:SetImageMaskTexture(texture)
	return self:SetMaskTexture(texture)
end

function CGWnd:GetMaskTexture()
	return host_call("get_mask_texture", node_of(self))
end

function CGWnd:ClearMaskTexture()
	host_call("clear_mask_texture", node_of(self))
end

