-- Native methods for the original CGWnd widget subclasses.
-- Methods deliberately use small defaults so missing visual-only features do
-- not prevent a screen from being created or interacted with.

local function node_of(wnd)
	return wnd and rawget(wnd, "__node") or nil
end

local function invoke(wnd, method_name, ...)
	local node = node_of(wnd)
	if node == nil then return nil end
	local method = node[method_name]
	if method == nil then return nil end
	return method(node, ...)
end

local function rect_value(rect, name)
	if rect == nil then return 0 end
	if type(rect) == "table" then
		local value = rect[name]
		if type(value) == "function" then
			return value(rect)
		end
		return value or 0
	end
	local ok, value = pcall(function() return rect[name](rect) end)
	if ok then return value end
	return 0
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

local function set_rect(wnd, method_name, index, rect)
	invoke(
		wnd,
		method_name,
		index or 0,
		rect_value(rect, "left"),
		rect_value(rect, "top"),
		rect_value(rect, "right"),
		rect_value(rect, "bottom")
	)
end

function CGButton:EnableWnd(value) invoke(self, "enable_wnd", value and true or false) end
function CGButton:IsEnable() return invoke(self, "is_enable") or false end

function CGCheckButton:SetCheck(value)
	invoke(self, "set_check", value and true or false)
end

function CGCheckButton:GetCheck()
	return invoke(self, "get_check") or false
end

function CGProgress:SetRange(value)
	invoke(self, "set_range", value or 0)
end

function CGProgress:GetRange()
	return invoke(self, "get_range") or 0
end

function CGProgress:SetPos(value)
	invoke(self, "set_pos_value", value or 0)
end

function CGProgress:GetPos()
	return invoke(self, "get_pos_value") or 0
end

function CGScrollBar:SetRange(value) invoke(self, "set_range", value or 0) end
function CGScrollBar:GetRange() return invoke(self, "get_range") or 0 end
function CGScrollBar:SetPos(value) invoke(self, "set_pos_value", value or 0) end
function CGScrollBar:GetPos() return invoke(self, "get_pos_value") or 0 end

function CGScrollPane:SetInertiaType(value)
	invoke(self, "set_inertia_type", value or 0)
end

function CGScrollPane:SetScrollVerticalPos(value)
	invoke(self, "set_scroll_vertical_pos", value or 0)
end

function CGScrollPane:GetScrollVerticalPos()
	return invoke(self, "get_scroll_vertical_pos") or 0
end

function CGScrollPane:GetVerticalScrollMax()
	return invoke(self, "get_vertical_scroll_max") or 0
end

function CGScrollPane:GetVerticalPageSize()
	return invoke(self, "get_vertical_page_size") or 0
end

function CGScrollPane:SetScrollHorizonPos(value)
	invoke(self, "set_scroll_horizon_pos", value or 0)
end

function CGScrollPane:GetScrollHorizonPos()
	return invoke(self, "get_scroll_horizon_pos") or 0
end

function CGScrollPane:ScrollToBottomLeft()
	invoke(self, "scroll_to_bottom_left")
end

function CGEdit:SetMaxStringLength(value)
	invoke(self, "set_max_string_length", value or 0)
end

function CGEdit:SetMaxCharLength(value)
	invoke(self, "set_max_char_length", value or 0)
end

function CGEdit:OnEditCompleted()
	invoke(self, "dispatch_message", GM_WM_EDIT_RETURN or 4353, 0, 0)
end

function CGRichWnd:GetFirstHyperLinkID()
	return invoke(self, "get_first_hyper_link_id") or 0
end

function CGRichWnd:GetHyperLinkID(unit_id)
	return invoke(self, "get_hyper_link_id", unit_id or 0) or 0
end

function CGRichWnd:GetHyperLinkIDString(link_id)
	return invoke(self, "get_hyper_link_id_string", link_id or 0) or ""
end

function CGRichWnd:GetRichUnitIDByHypLinkID(link_id)
	return invoke(self, "get_rich_unit_id_by_hyper_link_id", link_id or 0) or 0
end

function CGRichWnd:TestUnitID(x, y)
	return invoke(self, "test_unit_id", x or 0, y or 0) or 0
end

function CGRichWnd:SetInertiaType(value)
	invoke(self, "set_inertia_type", value or 0)
end

function CGListCtrl:SetInertiaType(value)
	invoke(self, "set_inertia_type", value or 0)
end

function CGListCtrl:InsertColumn(index, width)
	invoke(self, "insert_column", index == nil and -1 or index, width or 0)
	return true
end

function CGListCtrl:DeleteAllColumn()
	invoke(self, "delete_all_column")
end

function CGListCtrl:GetColumnCount()
	return invoke(self, "get_column_count") or 0
end

function CGListCtrl:SetColumnWidth(index, width)
	invoke(self, "set_column_width", index or 0, width or 0)
end

function CGListCtrl:InsertItemFromHandler(index, handler)
	local count_columns = self:GetColumnCount()   -- 0 columns -> no cells (Claude)
	local row_index = index == nil or index < 0 and self:GetItemCount() or index
	if row_index == nil then row_index = self:GetItemCount() end
	local cells = {}

	for column_index = 0, count_columns - 1 do
		local class_name = handler:GetClassName(row_index, column_index)
		local item_class = rawget(_G, class_name) or CGWnd
		local item = item_class:new()
		handler:OnCreateItem(item, row_index, column_index)
		cells[#cells + 1] = item
	end

	local nodes = Array()   -- Godot Array (a plain Lua table is not accepted by the typed GDScript parameter)
	for _, item in ipairs(cells) do
		if item and item.__node then nodes:append(item.__node) end
	end
	invoke(self, "insert_list_row", nodes, row_index)

	for _, item in ipairs(cells) do
		if item and item.OnMsgDispatch then
			item:OnMsgDispatch(0, item, WM_CREATE or 1, 0, 0)
		end
	end
	return row_index
end

function CGListCtrl:GetItemCount()
	return invoke(self, "get_item_count") or 0
end

function CGListCtrl:GetSubItem(row_index, column_index)
	return WrapWnd(invoke(self, "get_sub_item", row_index or 0, column_index or 0))
end

function CGListCtrl:GetItem(row_index)
	return WrapWnd(invoke(self, "get_item", row_index or 0))
end

function CGListCtrl:GetItemIndex(item)
	return invoke(self, "get_item_index", item and item.__node or nil) or -1
end

function CGListCtrl:SetSubItemVisible(value, row_index, column_index)
	invoke(self, "set_sub_item_visible", value and true or false, row_index or 0, column_index or 0)
end

function CGListCtrl:SetSubItemVisibleByIndex(value, index)
	local columns = math.max(1, self:GetColumnCount())
	self:SetSubItemVisible(value, math.floor((index or 0) / columns), (index or 0) % columns)
end

function CGListCtrl:GetSubItemByIndex(index)
	local columns = math.max(1, self:GetColumnCount())
	return self:GetSubItem(math.floor((index or 0) / columns), (index or 0) % columns)
end

function CGListCtrl:DeleteAllItem()
	invoke(self, "delete_all_items")
end

function CGListCtrl:DeleteItem(index)
	invoke(self, "delete_item", index or 0)
end

function CGListCtrl:SelectItem(row_index, column_index)
	invoke(self, "select_item", row_index or 0, column_index or 0)
end

function CGListCtrl:GetSelectItem()
	return invoke(self, "get_select_item") or -1
end

function CGListCtrl:GetSelectColumn()
	return invoke(self, "get_select_column") or -1
end

function CGListCtrl:SetItemHeight(height, index)
	invoke(self, "set_item_height", height or 0, index == nil and -1 or index)
end

function CGListCtrl:SetScrollVerticalPos(value)
	invoke(self, "set_scroll_vertical_pos", value or 0)
end

function CGListCtrl:GetScrollVerticalPos()
	return invoke(self, "get_scroll_vertical_pos") or 0
end

function CGListCtrl:GetVerticalScrollMax()
	return invoke(self, "get_vertical_scroll_max") or 0
end

function CGListCtrl:GetVerticalPageSize()
	return invoke(self, "get_vertical_page_size") or 0
end

function CGListCtrl:SetScrollHorizonPos(value)
	invoke(self, "set_scroll_horizon_pos", value or 0)
end

function CGListCtrl:GetScrollHorizonPos()
	return invoke(self, "get_scroll_horizon_pos") or 0
end

function CGListCtrl:ScrollToBottomLeft()
	invoke(self, "scroll_to_bottom_left")
end

function CGComboBox:GetListBox()
	return WrapWnd(invoke(self, "get_list_box_node"))
end

function CGComboBox:InsertItem(index, value)
	if value == nil then
		value, index = index, -1
	end
	return invoke(self, "insert_combo_item", index == nil and -1 or index, tostring(value or ""))
end

function CGComboBox:AddItem(value)
	return self:InsertItem(-1, value)
end

function CGComboBox:GetItem(index)
	local list_box = self:GetListBox()
	if list_box and list_box.__node then
		local item = list_box.__node:get_item(index or 0)
		if item ~= nil then return WrapWnd(item) end
		item = list_box.__node:get_combo_item(index or 0)
		if item ~= nil then return WrapWnd(item) end
	end
	return WrapWnd(invoke(self, "get_combo_item", index or 0))
end

function CGComboBox:RemoveAllItem()
	invoke(self, "remove_all_combo_items")
end

function CGComboBox:SetSel(index)
	invoke(self, "set_combo_sel", index or -1)
end

function CGComboBox:GetCurrentSel()
	return invoke(self, "get_combo_sel") or -1
end

function CGComboBox:GetItemCount()
	return invoke(self, "get_item_count") or 0
end

function CGTreeCtrl:SetInertiaType(value)
	invoke(self, "set_inertia_type", value or 0)
end

function CGTreeCtrl:GetItemCount()
	return invoke(self, "get_item_count") or 0
end

function CGTreeCtrl:GetItem(index)
	return WrapWnd(invoke(self, "get_item", index or 0))
end

function CGTreeCtrl:GetSubItem(row_index, column_index)
	return WrapWnd(invoke(self, "get_sub_item", row_index or 0, column_index or 0))
end

function CGTreeCtrl:DeleteAllItem()
	invoke(self, "delete_all_items")
end

function CGTreeCtrl:SelectItem(row_index, column_index)
	invoke(self, "select_item", row_index or 0, column_index or 0)
end

function CGTreeCtrl:GetSelectItem()
	return invoke(self, "get_select_item") or -1
end

function CGTreeCtrl:SetScrollVerticalPos(value)
	invoke(self, "set_scroll_vertical_pos", value or 0)
end

function CGTreeCtrl:GetScrollVerticalPos()
	return invoke(self, "get_scroll_vertical_pos") or 0
end


function CFontEffectWnd:SetEffectText(file, value, color, time)
	invoke(self, "set_effect_text", file or "", tostring(value or ""), color or 0xffffffff, time or 0)
end

function CFontEffectWnd:SetWndText(value)
	invoke(self, "set_wnd_text", tostring(value or ""))
end

function CFontEffectWnd:AddWndText(value)
	invoke(self, "add_wnd_text", tostring(value or ""))
end

-- Common aliases used by subclasses that inherit methods through native_class.
function CGScrollPane:GetCurHeight() return invoke(self, "get_cur_height") or 0 end
function CGScrollPane:GetMaxWidth() return invoke(self, "get_max_width") or 0 end
function CGScrollPane:GetLineContentEndX() return invoke(self, "get_line_content_end_x") or 0 end
function CGScrollPane:GetFirstHyperLinkID() return invoke(self, "get_first_hyper_link_id") or 0 end
function CGScrollPane:GetHyperLinkIDString(index) return invoke(self, "get_hyper_link_id_string", index or 0) or "" end
function CGScrollPane:TestUnitID(x, y) return invoke(self, "test_unit_id", x or 0, y or 0) or 0 end
function CGScrollPane:SetItemHeight(height, index) invoke(self, "set_item_height", height or 0, index == nil and -1 or index) end
function CGScrollPane:DeleteAllItem() invoke(self, "delete_all_items") end
function CGScrollPane:GetItemCount() return invoke(self, "get_item_count") or 0 end
function CGScrollPane:GetSubItem(row, column) return WrapWnd(invoke(self, "get_sub_item", row or 0, column or 0)) end

function CGWnd:GetWndLocalRect()
	return make_rect(invoke(self, "get_wnd_local_rect"))
end

function CGWnd:SetWndLocalRect(rect)
	set_rect(self, "set_wnd_local_rect", 0, rect)
end

function CGWnd:GetOrgWidth() return invoke(self, "get_org_width") or self:GetWndWidth() end
function CGWnd:GetOrgHeight() return invoke(self, "get_org_height") or self:GetWndHeight() end

function CGWnd:OnEditCompleted()
	invoke(self, "dispatch_message", GM_WM_EDIT_RETURN or 4353, 0, 0)
end
