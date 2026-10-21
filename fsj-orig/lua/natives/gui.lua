-- Window natives backed by Godot GuiWidgets. Original UI scripts wrap their
-- widgets in Lua objects and receive native messages through NativeWndDispatch.

local function node_of(wnd)
	if wnd == nil then return nil end
	return rawget(wnd, "__node")
end

local function invoke(wnd, method_name, ...)
	local node = node_of(wnd)
	if node == nil then return nil end
	local method = node[method_name]
	if method == nil then return nil end
	return method(node, ...)
end

local function wrap(node)
	if node == nil then return nil end
	local existing = (node:has_meta("lua") and node:get_meta("lua") or nil)
	if existing ~= nil then return existing end

	local class_name = node:class_of()
	local class = rawget(_G, class_name) or CGWnd
	local wnd = setmetatable({ __node = node }, class)
	node:set_meta("lua", wnd)
	return wnd
end

WrapWnd = wrap

function NativeWndDispatch(node, nMessage, wParam, lParam)
	if node == nil then return false end
	local wnd = (node:has_meta("lua") and node:get_meta("lua") or nil)
	if wnd == nil then
		wnd = wrap(node)
	end
	if wnd == nil or wnd.OnMsgDispatch == nil then return false end
	return wnd:OnMsgDispatch(0, wnd, nMessage, wParam, lParam)
end

function CGWnd.CreateFromRes(self, szResName, wndParent, nLoadType)
	local parent_node = wndParent and wndParent.__node or nil
	local node = Host:create_gui(szResName, parent_node)
	if node == nil then return false end
	self.__node = node
	node:set_meta("lua", self)
	-- nLoadType: 0 = show now, 1 = load hidden, 2 = load when first shown (we load at once, hidden)
	if (nLoadType or 0) ~= 0 then invoke(self, "show_wnd", false) end
	-- the C++ loads window resources asynchronously: OnCreated arrives on a later frame, after the Lua Ctor finished
	-- OnCreated is delivered once: on a later frame, or earlier by the first ShowWnd(true) (nLoadType 2 waits for that)
	self.__lazyCreate = true
	if nLoadType ~= 2 then
		DeferCall(function()
			if self.__node ~= nil and self.__lazyCreate then self.__lazyCreate = nil self:OnCreated() end
		end)
	end
	return true
end

-- default lifecycle hooks (the original scripts override them)
function CGWnd:OnCreated() end
function CGWnd:OnWndShow(bShow) end
function CGWnd:OnDestroy() end

function CGWnd.GetDlgChild(self, szPath)
	if type(szPath) == "number" then   -- GetDlgChild(i): the i-th child window (1-based)
		return wrap(invoke(self, "child_at", math.tointeger(szPath - 1) or 0))
	end
	return wrap(invoke(self, "child", tostring(szPath or "")))
end

function CGWnd.OnMsgDispatch(self, nInputID, pWnd, nMessage, wParam, lParam)
	return true
end

function CGWnd:GetClassName()
	return invoke(self, "class_of") or "CGWnd"
end

function CGWnd:ShowWnd(value)
	value = value and true or false
	if value and self.__lazyCreate then
		self.__lazyCreate = nil
		self:OnCreated()
	end
	local changed = invoke(self, "is_shown") ~= value
	invoke(self, "show_wnd", value)
	if changed then self:OnWndShow(value) end
end

function CGWnd:IsShow()
	return invoke(self, "is_shown") or false
end

function CGWnd:GetWndName()
	local node = node_of(self)
	return node and node.name or ""
end

function CGWnd:SetWndName(value)
	local node = node_of(self)
	if node and node.set_wnd_name then node:set_wnd_name(tostring(value or "")) end
end

function CGWnd:SetWndText(value)
	invoke(self, "set_wnd_text", tostring(value or ""))
end

function CGWnd:GetWndText()
	return invoke(self, "get_wnd_text") or ""
end

function CGWnd:GetWndWidth()
	return invoke(self, "get_w") or 0
end

function CGWnd:GetWndHeight()
	return invoke(self, "get_h") or 0
end

function CGWnd:SetWndSize(width, height)
	invoke(self, "set_wnd_size", width or 0, height or 0)
end

function CGWnd:SetPosition(x, y)
	if y == nil and x ~= nil then
		local ok_x, value_x = pcall(function() return x:x() end)
		local ok_y, value_y = pcall(function() return x:y() end)
		if ok_x and ok_y then
			x, y = value_x, value_y
		elseif type(x) == "table" then
			x, y = x.x or 0, x.y or 0
		end
	end
	invoke(self, "set_pos", x or 0, y or 0)
end

function CGWnd:SetLocalX(value) invoke(self, "set_local_x", value or 0) end
function CGWnd:SetLocalY(value) invoke(self, "set_local_y", value or 0) end
function CGWnd:GetLocalX() return invoke(self, "get_local_x") or 0 end
function CGWnd:GetLocalY() return invoke(self, "get_local_y") or 0 end
function CGWnd:GetGlobalX() return invoke(self, "get_global_x") or 0 end
function CGWnd:GetGlobalY() return invoke(self, "get_global_y") or 0 end
function CGWnd:SetGlobalX(value) invoke(self, "set_global_x", value or 0) end
function CGWnd:SetGlobalY(value) invoke(self, "set_global_y", value or 0) end
function CGWnd:SetScaleX(value) invoke(self, "set_scale_x", value or 1) end
function CGWnd:SetScaleY(value) invoke(self, "set_scale_y", value or 1) end
function CGWnd:GetScaleX() return invoke(self, "get_scale_x") or 1 end
function CGWnd:GetScaleY() return invoke(self, "get_scale_y") or 1 end

function CGWnd:GetParent()
	return wrap(invoke(self, "get_parent"))
end

function CGWnd:SetParent(parent)
	local parent_node = parent and parent.__node or nil
	invoke(self, "reparent_to", parent_node, true)
end

function CGWnd:DestroyWnd()
	if self.__node ~= nil then
		self:OnDestroy()
		invoke(self, "destroy")
		self.__node = nil
	end
end

function CGWnd:IsCreated()
	return self.__node ~= nil
end

function CGWnd:SetFocus()
	local node = node_of(self)
	if node and node.grab_focus then node:grab_focus() end
end

function CGWnd:IsFocus()
	return invoke(self, "is_focus") or false
end

function CGWnd:EnableWnd(value)
	invoke(self, "enable_wnd", value and true or false)
end

function CGWnd:IsEnable()
	return invoke(self, "is_enable") or false
end

function CGWnd:SetStyle(value) invoke(self, "set_style", value or 0) end
function CGWnd:GetStyle() return invoke(self, "get_style") or 0 end
function CGWnd:SetLockFlag(value) invoke(self, "set_lock_flag", value or 0) end
function CGWnd:GetLockFlag() return invoke(self, "get_lock_flag") or 0 end
function CGWnd:SetFade(value) invoke(self, "set_fade", value or 255) end
function CGWnd:SetFadeDuration(_value) end
function CGWnd:EnablePreRender(value) invoke(self, "enable_pre_render", value and true or false) end
function CGWnd:Invalidate() invoke(self, "invalidate") end
function CGWnd:SetWndData(value) invoke(self, "set_wnd_data", value) end
function CGWnd:GetWndData() return invoke(self, "get_wnd_data") end
function CGWnd:GetGUI() return node_of(self) end

function CGWnd:AddEffect(file, name, attach, time)
	return invoke(self, "add_effect", file or "", name or "", attach or "", time or 0) or true
end

function CGWnd:RemoveEffect(name)
	return invoke(self, "remove_effect", name or "") or true
end

function CGWnd:RemoveAllEffects()
	invoke(self, "remove_all_effects")
end

function CGWnd:GetAttachEffectName(value)
	return invoke(self, "get_attach_effect_name", value) or value
end

-- Some original widgets expose these names through their base window type.
function CGWnd:SetFontSize(value) invoke(self, "set_font_size", value or 18) end
function CGWnd:AddWndText(value) invoke(self, "add_wnd_text", tostring(value or "")) end
function CGWnd:GetStrWidth(value) return invoke(self, "get_str_width", tostring(value or "")) or 0 end
function CGWnd:GetLineContentEndX() return invoke(self, "get_line_content_end_x") or 0 end
function CGWnd:GetCurHeight() return invoke(self, "get_cur_height") or 0 end
function CGWnd:GetMaxWidth() return invoke(self, "get_max_width") or self:GetWndWidth() end
function CGWnd:SetMaxStringLength(value) invoke(self, "set_max_string_length", value or 0) end
function CGWnd:SetMaxCharLength(value) invoke(self, "set_max_char_length", value or 0) end
function CGWnd:IsInWndArea(x, y)
	local node = node_of(self)
	if node == nil then return false end
	return x >= 0 and y >= 0 and x <= node:get_w() and y <= node:get_h()
end

function CGWnd:GetRootWidth() return invoke(self, "get_root_width") or self:GetWndWidth() end
function CGWnd:GetRootHeight() return invoke(self, "get_root_height") or self:GetWndHeight() end

-- Load the widget-class methods after the shared CGWnd wrapper exists.
require("natives.gui_widgets")


