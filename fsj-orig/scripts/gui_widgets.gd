extends Control
# Shared Godot control for the original GUI widget family.
# Image geometry is mutable and resized through the recovered ScaleRect path.
# Native clipping is per primitive/window; clip_contents must remain false.

const WS_INVISIBLE := GuiDraw.WS_INVISIBLE
const WS_TEXTXC := GuiDraw.WS_TEXTXC
const WS_TEXTXR := GuiDraw.WS_TEXTXR
const WS_TEXTYC := GuiDraw.WS_TEXTYC
const WS_TEXTYB := GuiDraw.WS_TEXTYB
const WM_LBUTTONDOWN := 513
const WM_LBUTTONUP := 514
const WM_CREATE := 1
const WM_SETFOCUS := 7
const WM_KILLFOCUS := 8
const GM_WM_MOUSEENTER := 4099
const GM_WM_MOUSELEAVE := 4100
const GM_WM_MOUSECLICK := 4101
const GM_WM_ACTION := 4229
const GM_WM_STATE_CHANGED := 4226
const GM_WM_VERTICAL_SCROLL := 4227
const GM_WM_HORIZON_SCROLL := 4228
const GM_WM_BTN_CHECKED := 5889
const GM_WM_ITEM_SELECT_CHANGED := 5377
const GM_WM_RICH_CLICK_ID := 5633
const GM_WM_EDIT_RETURN := 4353
const INERTIA_VSCROLL := 1
const INERTIA_HSCROLL := 2
const _WHITE := Color(1, 1, 1, 1)

static var _system_font: Font

var data: Dictionary = {}
var textures: Array = []
var key := ""
var state := 2
var wnd_text := ""
var images_by_state: Array = []
var groups_by_state: Array = []
var image_state_order: Array = []
var state_text_colors: Dictionary = {}
var text_colors_by_group: Dictionary = {}
var text_background_colors_by_group: Dictionary = {}
var kids: Dictionary = {}
var style_flags := 0
var enabled := true
var checked := false
var progress_range := 100.0
var progress_pos := 0.0
var inertia_type := 0
var scroll_x := 0.0
var scroll_y := 0.0
var scroll_velocity := Vector2.ZERO
var selected_row := -1
var selected_column := -1
var column_widths: Array = []
var item_heights: Array = []
var list_rows: Array = []
var combo_items: Array = []
var combo_item_nodes: Array = []
var combo_selection := -1
var lock_flag := 0
var wnd_data: Variant = 0
var fade_alpha := 1.0
var gui_saturation := 1.0
var text_color_override: Color
var text_background_color := Color(0, 0, 0, 0)
var text_font_size := 0
var clip_inset := Vector2.ZERO
var rich_links: Array = []
var rich_hit_rects: Array = []
var original_size := Vector2.ZERO

var _has_text_color_override := false
var _has_text_background_color_override := false
var _pressed := false
var _mouse_inside := false
var _touch_down := false
var _last_pointer := Vector2.ZERO
var _mouse_drag_start := Vector2.ZERO
var _mouse_drag_last := Vector2.ZERO
var _mouse_dragging := false
var _edit_control: LineEdit
var _edit_selection_color := Color(0.25, 0.45, 0.8, 0.4)
var _widget_script: Script
var _list_owner: Control
var _image_rect_overrides: Dictionary = {}
var _texture_rect_overrides: Dictionary = {}
var _create_images_by_state: Array = []
var _create_groups_by_state: Array = []
var _geometry_size := Vector2.ZERO
var _setup_done := false
var _lock_flag_set := false


func setup(w: Dictionary, tex: Array, child_key: String, widget_script: Script) -> void:
	_setup_done = false
	data = w
	textures = tex
	key = child_key
	_widget_script = widget_script
	name = child_key if child_key != "" else str(w.get("class_name", "Wnd"))
	wnd_text = GuiRuntime.resolve_text(str(w.get("wnd_name", "")))
	state = 2
	enabled = true
	# Native mobile windows do not participate in Godot's arrow-key focus
	# traversal. FOCUS_ALL let even HUD backgrounds swallow movement input.
	# Keep explicit/click focus; CGEdit's LineEdit owns text keyboard focus.
	focus_mode = Control.FOCUS_CLICK
	clip_contents = false

	# Use GUI_MODEL's corrected raw-word mapping, not gui_parse's explicitly
	# speculative window_rect/style_flags projections.
	var base: Dictionary = w.get("base_fields", {})
	position = Vector2(
		_signed_coordinate(base.get("this+0x10", 0)),
		_signed_coordinate(base.get("this+0x14", 0))
	)
	size = Vector2(
		maxf(0.0, _field_number(base, "this+0x18", 0.0)),
		maxf(0.0, _field_number(base, "this+0x1c", 0.0))
	)
	original_size = size
	_geometry_size = size
	style_flags = GuiDraw.integer(base.get("this+0x0c", 0)) & 0xffffffff
	_apply_style()
	state = _normal_state()

	# ASSUMPTION: the supplied files do not bind resource +0x20/+0x24 to
	# runtime text insets +0x60/+0x64. Preserve them in data, and default the
	# insets to zero rather than allowing guessed margins to erase captions.
	# Runtime code can supply verified distances through set_clip_inset().
	clip_inset = Vector2.ZERO
	var explicit_inset: Variant = w.get("text_clip_inset")
	if explicit_inset is Dictionary:
		clip_inset = Vector2(
			GuiDraw.number(explicit_inset.get("x", 0.0)),
			GuiDraw.number(explicit_inset.get("y", 0.0))
		)

	_load_image_states(w)

	kids.clear()
	var children: Array = w.get("children", [])
	for child_value in children:
		if not child_value is Dictionary:
			continue
		var child_window: Dictionary = child_value.get("window", {})
		var child_name := str(child_value.get("name", ""))
		var child_node = _widget_script.new()
		child_node.setup(child_window, tex, child_name, _widget_script)
		add_child(child_node)
		kids[child_name] = child_node

	if _is_edit():
		_create_edit_control()

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if not resized.is_connected(_on_resized):
		resized.connect(_on_resized)

	_setup_done = true
	set_notify_transform(true)
	set_process(false)
	queue_redraw()


func _ready() -> void:
	if _setup_done:
		queue_redraw()
		if _edit_control != null:
			_refresh_edit_control()
	if _has_preview() and is_visible_in_tree():
		set_process(true)
		_update_preview_state()


func _exit_tree() -> void:
	GuiDraw.release_canvas(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _setup_done:
		_invalidate_gui()
		if _has_preview():
			_update_preview_state()
	elif what == NOTIFICATION_VISIBILITY_CHANGED:
		if _has_preview():
			if not is_visible_in_tree():
				_set_preview_running(false)
				if not _is_scrollable() or scroll_velocity.length() < 2.0:
					set_process(false)
			else:
				set_process(true)
				_update_preview_state()


func _load_image_states(w: Dictionary) -> void:
	images_by_state.clear()
	groups_by_state.clear()
	image_state_order.clear()
	state_text_colors.clear()

	# SChildWndInfo[0] is this window. Later entries are resource templates for
	# subsidiary parts; an empty first entry must not borrow a later template.
	var child_infos: Array = w.get("child_window_infos", [])
	if child_infos.is_empty() or not child_infos[0] is Dictionary:
		return
	var image_lists: Array = child_infos[0].get("image_lists", [])

	for record_index in range(image_lists.size()):
		if not image_lists[record_index] is Dictionary:
			continue
		var record: Dictionary = image_lists[record_index]

		# ASSUMPTION: the three raw SChildImageList header words are state ID,
		# foreground, and secondary text color, respectively. This matches the
		# searched state identifier and the two native state-color slots.
		# The converter preserves offsets but does not itself name these words.
		var state_id := GuiDraw.integer(record.get("header_u32_0x00", record_index))
		if state_id < 0 or state_id > 0xffff:
			# ASSUMPTION: invalid identifiers in older hand-authored JSON use
			# the old index convention; valid serialized identifiers do not.
			state_id = record_index

		while images_by_state.size() <= state_id:
			images_by_state.append(null)
			groups_by_state.append(null)

		# GetChildImageList returns the first matching record.
		if images_by_state[state_id] is Array:
			continue

		var images: Array = []
		for value in record.get("images", []):
			if not value is Dictionary:
				continue
			var image_data: Dictionary = value.duplicate(false)
			var source := GuiDraw.rect_edges(image_data.get("source_rect", {}))
			var destination := GuiDraw.rect_edges(image_data.get("destination_rect", {}))
			image_data["source_rect"] = GuiDraw.rect_dictionary(source)
			image_data["destination_rect"] = GuiDraw.rect_dictionary(destination)
			image_data["_gui_tile_rect"] = GuiDraw.rect_dictionary(source)
			image_data["_gui_uv_density"] = _image_density(source, destination, Vector2.ONE)
			images.append(image_data)

		var groups: Array = []
		for value in record.get("groups", []):
			if not value is Dictionary:
				continue
			var group: Dictionary = value.duplicate(false)
			var rect := GuiDraw.rect_edges(group.get("rect", {}))
			# The supplied loader description converts serialized floats into
			# an integer group rectangle. Integer conversion truncates to zero.
			rect = Vector4(int(rect.x), int(rect.y), int(rect.z), int(rect.w))
			group["rect"] = GuiDraw.rect_dictionary(rect)
			groups.append(group)

		images_by_state[state_id] = images
		groups_by_state[state_id] = groups
		image_state_order.append(state_id)

		var colors: Dictionary = {}
		if record.has("header_u32_0x04"):
			colors["foreground_argb"] = GuiDraw.integer(record["header_u32_0x04"]) & 0xffffffff
		if record.has("header_u32_0x08"):
			colors["secondary_argb"] = GuiDraw.integer(record["header_u32_0x08"]) & 0xffffffff
		if not colors.is_empty():
			state_text_colors[state_id] = colors


func _image_density(source: Vector4, destination: Vector4, previous: Vector2) -> Vector2:
	var result := previous
	var source_size := GuiDraw.extent(source)
	var destination_size := GuiDraw.extent(destination)
	if absf(destination_size.x) > GuiDraw.SCALE_EPSILON:
		result.x = source_size.x / destination_size.x
	if absf(destination_size.y) > GuiDraw.SCALE_EPSILON:
		result.y = source_size.y / destination_size.y
	return result


func _resize_all_image_lists(old_size: Vector2, size_delta: Vector2) -> void:
	if size_delta == Vector2.ZERO:
		return
	for image_state in range(images_by_state.size()):
		if not images_by_state[image_state] is Array:
			continue
		var raw_images: Array = images_by_state[image_state]
		var decoded := GuiDraw.decode_state(self, image_state, raw_images)
		var scaled := GuiDraw.resize_image_list(decoded, old_size, size_delta)
		var next_images: Array = scaled["images"]

		# Commit geometry only. Do not persist decoded readiness/texture values:
		# an asynchronously populated texture slot must be resolvable later.
		var decoded_index := 0
		for value in raw_images:
			if not value is Dictionary:
				continue
			if decoded_index >= next_images.size():
				break
			var next_image: Dictionary = next_images[decoded_index]
			value["source_rect"] = GuiDraw.rect_dictionary(next_image["source_rect"])
			value["destination_rect"] = GuiDraw.rect_dictionary(next_image["destination_rect"])
			value["_gui_uv_density"] = next_image["uv_density"]
			value["_gui_tile_rect"] = GuiDraw.rect_dictionary(next_image["tile_rect"])
			decoded_index += 1

		if image_state < groups_by_state.size() and groups_by_state[image_state] is Array:
			var raw_groups: Array = groups_by_state[image_state]
			var next_groups: Array = scaled["groups"]
			var group_index := 0
			for value in raw_groups:
				if not value is Dictionary:
					continue
				if group_index >= next_groups.size():
					break
				value["rect"] = GuiDraw.rect_dictionary(next_groups[group_index]["rect"])
				group_index += 1


func _sync_image_geometry() -> void:
	var old_size := _geometry_size
	var size_delta := size - old_size
	if size_delta == Vector2.ZERO:
		return
	_geometry_size = size
	_resize_all_image_lists(old_size, size_delta)

	# ASSUMPTION: the resource field supplying child-window locks is unknown.
	# Honor explicitly assigned window locks without guessing that field.
	for child_node in get_children():
		if not child_node is Control or not child_node.has_method("get_lock_flag"):
			continue
		if not bool(child_node.get("_lock_flag_set")):
			continue
		var child_rect := Vector4(
			child_node.position.x,
			child_node.position.y,
			child_node.position.x + child_node.size.x,
			child_node.position.y + child_node.size.y
		)
		var next_rect := GuiDraw.scale_rect(
			child_rect,
			int(child_node.call("get_lock_flag")),
			old_size,
			size_delta
		)
		child_node.call("set_pos", next_rect.x, next_rect.y)
		child_node.call("set_wnd_size", next_rect.z - next_rect.x, next_rect.w - next_rect.y)


func _on_resized() -> void:
	if not _setup_done:
		return
	_sync_image_geometry()
	if _edit_control != null:
		_edit_control.size = size
	if _is_list():
		_reflow_list()
	if not combo_item_nodes.is_empty():
		_reflow_combo_items()
	_invalidate_gui()


func _invalidate_gui() -> void:
	queue_redraw()
	if _edit_control != null:
		_refresh_edit_control()
	for child_node in get_children():
		if child_node.has_method("_invalidate_gui"):
			child_node.call("_invalidate_gui")


func _apply_style() -> void:
	visible = (style_flags & WS_INVISIBLE) == 0
	mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
		if (style_flags & GuiDraw.WS_MSGTRANSPT) != 0
		else Control.MOUSE_FILTER_PASS
	)
	# Clip scrollable list/scrollpanes to their authored bounds so scrolled rows
	# and 3D SubViewportContainer previews never bleed over headers or Return buttons.
	clip_contents = _is_list() or class_of() == "CGScrollPane"
	# ASSUMPTION: the native TOPMOST sibling partition maps to this z band.
	z_index = 1 if (style_flags & GuiDraw.WS_TOPMOST) != 0 else 0


func class_of() -> String:
	return str(data.get("class_name", "CGWnd"))


func child(path: String) -> Control:
	var current: Control = self
	for part in path.split("."):
		if part == "":
			continue
		if not current.has_method("_get_child_by_key"):
			return null
		current = current.call("_get_child_by_key", part)
		if current == null:
			return null
	return current


func _get_child_by_key(child_key: String) -> Control:
	if kids.has(child_key):
		return kids[child_key] as Control
	return null


func child_at(index: int) -> Control:
	var values: Array = kids.values()
	if index < 0 or index >= values.size():
		return null
	return values[index] as Control


func find_wnd(child_key: String) -> Control:
	if kids.has(child_key):
		return kids[child_key] as Control
	for value in kids.values():
		if not is_instance_valid(value) or not value.has_method("find_wnd"):
			continue
		var found: Control = value.call("find_wnd", child_key)
		if found != null:
			return found
	return null


func show_wnd(value: bool) -> void:
	var prev_vis := visible
	if value:
		style_flags &= ~WS_INVISIBLE
	else:
		style_flags |= WS_INVISIBLE
	if prev_vis != value:
		visible = value


func is_shown() -> bool:
	return visible


func set_wnd_text(value: String) -> void:
	var resolved := value if _edit_control != null else GuiRuntime.resolve_text(value)
	if _edit_control == null and resolved == wnd_text:
		return
	wnd_text = resolved
	rich_links.clear()
	rich_hit_rects.clear()
	if _edit_control != null and _edit_control.text != value:
		_edit_control.text = value
	queue_redraw()


func get_wnd_text() -> String:
	if _edit_control != null:
		return _edit_control.text
	return wnd_text


func set_pos(x: float, y: float) -> void:
	position = Vector2(x, y)
	_invalidate_gui()


func get_w() -> float:
	return size.x


func get_h() -> float:
	return size.y


func set_wnd_size(width: float, height: float) -> void:
	size = Vector2(maxf(0.0, width), maxf(0.0, height))
	# Also covers calls made outside the scene tree.
	_sync_image_geometry()
	if _edit_control != null:
		_edit_control.size = size
	_invalidate_gui()


func destroy() -> void:
	queue_free()


func set_state(new_state: int) -> void:
	if state == new_state:
		return
	var old_state := state
	state = new_state
	_invalidate_gui()
	_send(GM_WM_STATE_CHANGED, new_state, old_state)


func enable_wnd(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	if not enabled:
		_pressed = false
		_touch_down = false
	_set_visual_state(false)
	_invalidate_gui()


func is_enable() -> bool:
	return enabled


func set_check(value: bool) -> void:
	checked = value
	if checked and _is_radio_button():
		var parent := get_parent()
		if parent != null:
			for sibling in parent.get_children():
				if sibling != self and sibling is Control and sibling.has_method("_is_radio_button") and sibling.call("_is_radio_button"):
					if bool(sibling.get("checked")):
						sibling.set("checked", false)
						sibling.call("_set_visual_state", bool(sibling.get("_mouse_inside")))
						sibling.queue_redraw()
	_set_visual_state(_mouse_inside)
	queue_redraw()


func get_check() -> bool:
	return checked


func set_range(value: float) -> void:
	var next_range := maxf(0.0, value)
	if is_equal_approx(progress_range, next_range):
		return
	progress_range = next_range
	queue_redraw()


func get_range() -> float:
	return progress_range


func set_pos_value(value: float) -> void:
	if is_equal_approx(progress_pos, value):
		return
	progress_pos = value
	queue_redraw()


func get_pos_value() -> float:
	return progress_pos


func set_inertia_type(value: int) -> void:
	inertia_type = value


func set_scroll_vertical_pos(value: float) -> void:
	var next_value := clampf(value, 0.0, get_vertical_scroll_max())
	var delta := next_value - scroll_y
	scroll_y = next_value
	if _is_list():
		_reflow_list()
	else:
		for child_node in get_children():
			if child_node is Control:
				child_node.position.y -= delta
	_invalidate_gui()


func get_scroll_vertical_pos() -> float:
	return scroll_y


func set_scroll_horizon_pos(value: float) -> void:
	var next_value := clampf(value, 0.0, get_horizontal_scroll_max())
	var delta := next_value - scroll_x
	scroll_x = next_value
	if _is_list():
		_reflow_list()
	else:
		for child_node in get_children():
			if child_node is Control:
				child_node.position.x -= delta
	_invalidate_gui()


func get_scroll_horizon_pos() -> float:
	return scroll_x


func get_vertical_page_size() -> float:
	return size.y


func get_vertical_scroll_max() -> float:
	if _is_list():
		var content_height := 0.0
		for row_index in range(list_rows.size()):
			content_height += _row_height(row_index)
		return maxf(0.0, content_height - size.y)

	var bottom := size.y
	for child_node in get_children():
		if child_node is Control and child_node.visible:
			bottom = maxf(bottom, child_node.position.y + scroll_y + child_node.size.y)
	return maxf(0.0, bottom - size.y)


func get_horizontal_scroll_max() -> float:
	if _is_list():
		var content_width := 0.0
		for column_index in range(get_column_count()):
			content_width += _column_width(column_index)
		return maxf(0.0, content_width - size.x)

	var right := size.x
	for child_node in get_children():
		if child_node is Control and child_node.visible:
			right = maxf(right, child_node.position.x + scroll_x + child_node.size.x)
	return maxf(0.0, right - size.x)


func scroll_to_bottom_left() -> void:
	set_scroll_vertical_pos(get_vertical_scroll_max())
	set_scroll_horizon_pos(0.0)


func set_item_height(height: float, row_index: int = -1) -> void:
	if row_index < 0:
		var count := maxi(item_heights.size(), list_rows.size())
		while item_heights.size() < count:
			item_heights.append(height)
		for index in range(item_heights.size()):
			item_heights[index] = height
	else:
		while item_heights.size() <= row_index:
			item_heights.append(height)
		item_heights[row_index] = height
	_reflow_list()


var _columns_explicit := false   # set once Lua manages columns itself (DeleteAllColumn / InsertColumn)

func insert_column(index: int, width: float) -> void:
	_columns_explicit = true
	var insert_at := column_widths.size() if index < 0 else clampi(index, 0, column_widths.size())
	column_widths.insert(insert_at, maxf(0.0, width))
	_reflow_list()


func delete_all_column() -> void:
	_columns_explicit = true
	column_widths.clear()
	_reflow_list()


func get_column_count() -> int:
	# a list whose columns the script cleared really has 0 columns (CSkillDevelopWnd with no skills); untouched
	# resource lists keep their implicit single column (Claude)
	return column_widths.size() if _columns_explicit else maxi(1, column_widths.size())


func set_column_width(index: int, width: float) -> void:
	if index < 0:
		return
	while column_widths.size() <= index:
		column_widths.append(0.0)
	column_widths[index] = maxf(0.0, width)
	_reflow_list()


func insert_list_row(cells: Array, index: int = -1) -> void:
	var insert_at := list_rows.size() if index < 0 else clampi(index, 0, list_rows.size())
	var row: Array = []
	for cell in cells:
		row.append(cell)
	list_rows.insert(insert_at, row)
	if not item_heights.is_empty():
		while item_heights.size() < insert_at:
			item_heights.append(0.0)
		item_heights.insert(insert_at, 0.0)
	for cell in row:
		if cell is Control and cell.has_method("_select_node"):
			cell.set("_list_owner", self)
	_reflow_list()


func delete_all_items() -> void:
	for row in list_rows:
		for cell in row:
			if cell is Control and is_instance_valid(cell):
				cell.queue_free()
	list_rows.clear()
	selected_row = -1
	selected_column = -1
	item_heights.clear()
	_reflow_list()


func delete_item(row_index: int) -> void:
	if row_index < 0 or row_index >= list_rows.size():
		return
	var row: Array = list_rows[row_index]
	for cell in row:
		if cell is Control and is_instance_valid(cell):
			cell.queue_free()
	list_rows.remove_at(row_index)
	if row_index < item_heights.size():
		item_heights.remove_at(row_index)
	if selected_row == row_index:
		selected_row = -1
		selected_column = -1
	elif selected_row > row_index:
		selected_row -= 1
	_reflow_list()


func get_item_count() -> int:
	return list_rows.size()


func get_sub_item(row_index: int, column_index: int) -> Control:
	if row_index < 0 or row_index >= list_rows.size():
		return null
	var row: Array = list_rows[row_index]
	if column_index < 0 or column_index >= row.size():
		return null
	return row[column_index] as Control


func get_item(row_index: int) -> Control:
	return get_sub_item(row_index, 0)


func get_item_index(item: Control) -> int:
	for row_index in range(list_rows.size()):
		var row: Array = list_rows[row_index]
		for column_index in range(row.size()):
			if row[column_index] == item:
				return row_index * get_column_count() + column_index
	return -1


func set_sub_item_visible(value: bool, row_index: int, column_index: int) -> void:
	var item := get_sub_item(row_index, column_index)
	if item != null:
		item.visible = value


func has_image_state(image_state: int) -> bool:
	return image_state >= 0 and image_state < images_by_state.size() and images_by_state[image_state] is Array


func select_item(row_index: int, column_index: int = 0) -> void:
	if row_index < 0 or row_index >= list_rows.size():
		return
	selected_row = row_index
	selected_column = column_index
	for row_i in range(list_rows.size()):
		var row: Array = list_rows[row_i]
		for col_i in range(row.size()):
			var cell = row[col_i]
			if cell is Control:
				var is_sel := (row_i == selected_row and (row.size() <= 1 or col_i == selected_column))
				if cell.has_method("_is_check_button") and cell.call("_is_check_button"):
					if cell.has_method("set_check"):
						cell.call("set_check", is_sel)
				elif cell.has_method("has_image_state") and cell.call("has_image_state", 13) and cell.has_method("set_state"):
					cell.call("set_state", 13 if is_sel else 14)
	_send(GM_WM_ITEM_SELECT_CHANGED, row_index, column_index)


func get_select_item() -> int:
	return selected_row


func get_select_column() -> int:
	return selected_column


func get_list_box_node() -> Control:
	for candidate in ["list", "listbox", "list_box", "items"]:
		if kids.has(candidate):
			return kids[candidate] as Control
	return self


func insert_combo_item(index: int, value: String) -> int:
	var insert_at := combo_items.size() if index < 0 else clampi(index, 0, combo_items.size())
	combo_items.insert(insert_at, value)

	var item_node = _widget_script.new()
	var item_data := {
		"class_name": "CGWnd",
		"wnd_name": "",
		"base_fields": {
			"this+0x0c": 0,
			"this+0x10": 0,
			"this+0x14": insert_at * 24,
			"this+0x18": size.x,
			"this+0x1c": 24
		},
		"child_window_infos": [],
		"children": []
	}
	item_node.setup(item_data, textures, "ComboItem%d" % insert_at, _widget_script)
	var list_box := get_list_box_node()
	list_box.add_child(item_node)
	item_node.set_wnd_text(value)
	combo_item_nodes.insert(insert_at, item_node)
	_reflow_combo_items()
	return insert_at


func remove_all_combo_items() -> void:
	combo_items.clear()
	for item_node in combo_item_nodes:
		if item_node is Control and is_instance_valid(item_node):
			item_node.queue_free()
	combo_item_nodes.clear()
	list_rows.clear()
	combo_selection = -1


func set_combo_sel(index: int) -> void:
	combo_selection = index if index >= 0 and index < combo_items.size() else -1
	if combo_selection >= 0:
		set_wnd_text(str(combo_items[combo_selection]))


func get_combo_sel() -> int:
	return combo_selection


func get_combo_item(index: int) -> Control:
	if index < 0 or index >= combo_item_nodes.size():
		return null
	return combo_item_nodes[index] as Control


func set_lock_flag(value: int) -> void:
	lock_flag = value & 0xffff
	_lock_flag_set = true


func get_lock_flag() -> int:
	return lock_flag


func set_style(value: int) -> void:
	style_flags = value & 0xffffffff
	_apply_style()
	_invalidate_gui()


func get_style() -> int:
	return style_flags


func set_fade(value: float) -> void:
	fade_alpha = clampf(value / 255.0 if value > 1.0 else value, 0.0, 1.0)
	# Native image/text colors already contain fade. Do not assign modulate.a.
	_invalidate_gui()


func set_clip_inset(x: float, y: float) -> void:
	clip_inset = Vector2(x, y)
	_invalidate_gui()


func _store_text_color(
	target: Dictionary,
	group: int,
	image_state: int,
	color_value: int
) -> void:
	var colors: Dictionary = target.get(group, {})
	colors[image_state] = color_value & 0xffffffff
	target[group] = colors


func set_wnd_text_color(group: int, image_state: int, color_value: int) -> void:
	_store_text_color(text_colors_by_group, group, image_state, color_value)
	if group == 0 or group == -1:
		var colors: Dictionary = get_meta("gui_state_text_colors", {})
		colors[image_state] = color_value & 0xffffffff
		set_meta("gui_state_text_colors", colors)
		if image_state < 0:
			text_color_override = _color_from_argb(color_value)
			_has_text_color_override = true
	_invalidate_gui()


func set_wnd_text_background_color(group: int, image_state: int, color_value: int) -> void:
	_store_text_color(text_background_colors_by_group, group, image_state, color_value)
	if group == 0 or group == -1:
		var colors: Dictionary = get_meta("gui_state_text_background_colors", {})
		colors[image_state] = color_value & 0xffffffff
		set_meta("gui_state_text_background_colors", colors)
		if image_state < 0:
			text_background_color = _color_from_argb(color_value)
			_has_text_background_color_override = true
	_invalidate_gui()


func set_font_size(value: int) -> void:
	text_font_size = maxi(1, value)
	_invalidate_gui()


func add_wnd_text(value: String) -> void:
	set_wnd_text(wnd_text + value)


func get_str_width(value: String) -> float:
	return _font().get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size()).x


func get_line_content_end_x() -> float:
	var lines := wnd_text.split("\n", true)
	var widest := 0.0
	for line in lines:
		widest = maxf(widest, get_str_width(line))
	return widest


func get_cur_height() -> float:
	var lines := maxi(1, wnd_text.split("\n", true).size())
	return float(lines) * _font().get_height(_font_size())


func get_max_width() -> float:
	return size.x


func _image_matches_group(image_data: Dictionary, group: int) -> bool:
	# ASSUMPTION: retain group 0/-1 as the whole-window API target used by the
	# existing runtime; positive targets select the serialized SImage group ID.
	return group <= 0 or (
		GuiDraw.integer(image_data.get("group_id", image_data.get("field_0x34", 0))) & 0xffff
	) == (group & 0xffff)


func set_background_color(group: int, image_state: int, color_value: int) -> void:
	set_image_color(group, -1, image_state, color_value)


func get_image_count(group: int, image_state: int) -> int:
	var count := 0
	for image_value in _images_for_state(image_state):
		if image_value is Dictionary and _image_matches_group(image_value, group):
			count += 1
	return count


func clear_wnd_bk_image(group: int, image_state: int) -> void:
	if image_state < 0 or image_state >= images_by_state.size():
		return
	if not images_by_state[image_state] is Array:
		return
	var retained: Array = []
	for image_value in images_by_state[image_state]:
		if image_value is Dictionary and not _image_matches_group(image_value, group):
			retained.append(image_value)
	images_by_state[image_state] = retained
	queue_redraw()


func set_image_color(group: int, image_index: int, image_state: int, color_value: int) -> void:
	var images := _images_for_state(image_state)
	for index in range(images.size()):
		if image_index >= 0 and index != image_index:
			continue
		var image_value: Variant = images[index]
		if image_value is Dictionary and _image_matches_group(image_value, group):
			image_value["color_or_flags_u32"] = color_value & 0xffffffff
	queue_redraw()


func restore_image_from_create_param() -> void:
	_load_image_states(data)
	_image_rect_overrides.clear()
	_texture_rect_overrides.clear()
	# Restore authored geometry, then adapt it to the current window once.
	_resize_all_image_lists(original_size, size - original_size)
	_geometry_size = size
	queue_redraw()


func _reference_images() -> Array:
	var selected := GuiDraw.resolve_state(self, 2)
	return _images_for_state(selected)


func get_image_wnd_rect(image_index: int) -> Dictionary:
	var images := _reference_images()
	if image_index >= 0 and image_index < images.size() and images[image_index] is Dictionary:
		return GuiDraw.rect_dictionary(GuiDraw.rect_edges(images[image_index].get("destination_rect", {})))
	return {"left": 0, "top": 0, "right": size.x, "bottom": size.y}


func get_image_texture_rect(image_index: int) -> Dictionary:
	var images := _reference_images()
	if image_index >= 0 and image_index < images.size() and images[image_index] is Dictionary:
		return GuiDraw.rect_dictionary(GuiDraw.rect_edges(images[image_index].get("source_rect", {})))
	return {"left": 0, "top": 0, "right": 0, "bottom": 0}


func set_image_wnd_rect(image_index: int, left: float, top: float, right: float, bottom: float) -> void:
	_image_rect_overrides[image_index] = {
		"left": left, "top": top, "right": right, "bottom": bottom
	}
	_apply_image_rect_override(image_index, "destination_rect", _image_rect_overrides[image_index])


func set_image_texture_rect(image_index: int, left: float, top: float, right: float, bottom: float) -> void:
	_texture_rect_overrides[image_index] = {
		"left": left, "top": top, "right": right, "bottom": bottom
	}
	_apply_image_rect_override(image_index, "source_rect", _texture_rect_overrides[image_index])


func get_wnd_local_rect() -> Dictionary:
	return {
		"left": position.x,
		"top": position.y,
		"right": position.x + size.x,
		"bottom": position.y + size.y
	}


func set_wnd_local_rect(left: float, top: float, right: float, bottom: float) -> void:
	set_pos(left, top)
	set_wnd_size(right - left, bottom - top)


func get_org_width() -> float:
	return original_size.x


func get_org_height() -> float:
	return original_size.y


func get_root_width() -> float:
	return get_viewport_rect().size.x


func get_root_height() -> float:
	return get_viewport_rect().size.y


func get_bounds() -> Dictionary:
	return {"left": 0, "top": 0, "right": size.x, "bottom": size.y}


func get_image_group(_image_state: int) -> Control:
	return self


func get_gui() -> Control:
	return self


func get_wnd_data() -> Variant:
	return wnd_data


func set_wnd_data(value: Variant) -> void:
	wnd_data = value


func set_local_x(value: float) -> void:
	position.x = value
	_invalidate_gui()


func set_local_y(value: float) -> void:
	position.y = value
	_invalidate_gui()


func get_local_x() -> float:
	return position.x


func get_local_y() -> float:
	return position.y


func get_global_x() -> float:
	return global_position.x


func get_global_y() -> float:
	return global_position.y


func set_global_x(value: float) -> void:
	var point := global_position
	point.x = value
	global_position = point
	_invalidate_gui()


func set_global_y(value: float) -> void:
	var point := global_position
	point.y = value
	global_position = point
	_invalidate_gui()


func set_scale_x(value: float) -> void:
	scale.x = value
	_invalidate_gui()


func set_scale_y(value: float) -> void:
	scale.y = value
	_invalidate_gui()


func get_scale_x() -> float:
	return scale.x


func get_scale_y() -> float:
	return scale.y


func reparent_to(new_parent: Node, keep_global: bool = true) -> void:
	if new_parent == null:
		return
	reparent(new_parent, keep_global)
	_invalidate_gui()


func is_focus() -> bool:
	return has_focus() or (_edit_control != null and _edit_control.has_focus())


func enable_pre_render(value: bool) -> void:
	set_process(value)


func set_max_string_length(value: int) -> void:
	if _edit_control != null:
		_edit_control.max_length = maxi(0, value)


func set_max_char_length(value: int) -> void:
	set_max_string_length(value)


func dispatch_message(message: int, w_param: int = 0, l_param: int = 0) -> void:
	_send(message, w_param, l_param)


func get_first_hyper_link_id() -> int:
	return 1 if rich_links.size() > 0 else 0


func get_hyper_link_id(unit_id: int) -> int:
	return unit_id if unit_id > 0 and unit_id <= rich_links.size() else 0


func get_hyper_link_id_string(link_id: int) -> String:
	if link_id <= 0 or link_id > rich_links.size():
		return ""
	return str(rich_links[link_id - 1])


func get_rich_unit_id_by_hyper_link_id(link_id: int) -> int:
	return link_id if link_id > 0 and link_id <= rich_links.size() else 0


func test_unit_id(x: float, y: float) -> int:
	var point := Vector2(x, y)
	var clip := GuiDraw.get_clip_bounds(self, false)
	if point.x < clip.x or point.x >= clip.z or point.y < clip.y or point.y >= clip.w:
		return 0
	for hit in rich_hit_rects:
		if hit["rect"].has_point(point):
			return int(hit["unit"])
	return 0


func set_saturation(value: float) -> void:
	gui_saturation = maxf(0.0, value)
	queue_redraw()


func invalidate() -> void:
	_invalidate_gui()


# Existing non-rendering compatibility hooks.
func add_effect(_file: String, _name: String = "", _attach: String = "", _time: float = 0.0) -> bool:
	return true


func remove_effect(_name: String = "") -> bool:
	return true


func remove_all_effects() -> void:
	pass


func set_effect_text(_file: String, value: String, _color: int = 0xffffffff, _time: float = 0.0) -> void:
	set_wnd_text(value)


func get_attach_effect_name(value: Variant) -> Variant:
	return value


func _draw() -> void:
	_sync_image_geometry()
	GuiDraw.begin_window(self, self)

	var draw_state := GuiDraw.resolve_state(self, state)
	# A progress fill state is submitted by its cropped pass only.
	if not (_is_progress() and draw_state == 10):
		_draw_state_images(draw_state)
	if _is_progress():
		_draw_progress_fill()

	GuiDraw.end_window(self)

	if _is_edit():
		if _edit_control != null:
			GuiDraw.bind_text_clip(_edit_control, self)
		return
	if wnd_text == "":
		rich_hit_rects.clear()
		return
	if _is_rich():
		_draw_rich_text()
	else:
		_draw_plain_text()


func _draw_state_images(image_state: int) -> void:
	if image_state >= 0:
		GuiDraw.draw_window(self, self, image_state)


func _draw_image(image_data: Dictionary, image_state: int = -1) -> void:
	var selected_state := state if image_state < 0 else image_state
	GuiDraw.draw_images(self, self, selected_state, [image_data])


func _draw_progress_fill() -> void:
	var fill_images := _images_for_state(10)
	if fill_images.is_empty():
		return
	var ratio := 0.0 if progress_range <= 0.0 else clampf(progress_pos / progress_range, 0.0, 1.0)
	if ratio <= 0.0:
		return

	# ASSUMPTION: preserve the existing progress direction bits and cropping
	# behavior; the original progress widget's draw implementation is absent.
	# Crop CURRENT, already-resized geometry, so ScaleRect is never applied
	# to an artificially shortened progress rectangle.
	var progress_style := GuiDraw.integer(data.get("field_0x3c", 0))
	var vertical := (progress_style & 2) != 0
	var reverse := (progress_style & 4) != 0

	for image_value in fill_images:
		if not image_value is Dictionary:
			continue
		var image_copy: Dictionary = image_value.duplicate(true)
		var destination := GuiDraw.rect_edges(image_copy.get("destination_rect", {}))
		var source := GuiDraw.rect_edges(image_copy.get("source_rect", {}))

		if vertical:
			var amount := (destination.w - destination.y) * ratio
			var source_amount := (source.w - source.y) * ratio
			if reverse:
				destination.y = destination.w - amount
				source.y = source.w - source_amount
			else:
				destination.w = destination.y + amount
				source.w = source.y + source_amount
		else:
			var amount := (destination.z - destination.x) * ratio
			var source_amount := (source.z - source.x) * ratio
			if reverse:
				destination.x = destination.z - amount
				source.x = source.z - source_amount
			else:
				destination.z = destination.x + amount
				source.z = source.x + source_amount

		image_copy["destination_rect"] = GuiDraw.rect_dictionary(destination)
		image_copy["source_rect"] = GuiDraw.rect_dictionary(source)
		# Cropping is not source extension. Keep the authored repeat domain;
		# GuiDraw still uses the unmodified cached tile rectangle.
		_draw_image(image_copy, 10)


func _draw_plain_text() -> void:
	var font := _font()
	var font_size := _font_size()
	var lines := wnd_text.split("\n", true)
	var line_height := font.get_height(font_size)
	var ascent := font.get_ascent(font_size)
	var total_height := line_height * float(lines.size())
	var y := ascent

	if (style_flags & WS_TEXTYC) != 0:
		y = (size.y - total_height) * 0.5 + ascent
	elif (style_flags & WS_TEXTYB) != 0:
		y = size.y - total_height + ascent

	var color := _get_text_color()
	for line in lines:
		var line_width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var x := 4.0
		if (style_flags & WS_TEXTXC) != 0:
			x = (size.x - line_width) * 0.5
		elif (style_flags & WS_TEXTXR) != 0:
			x = size.x - line_width - 4.0
		_draw_text_line(font, font_size, Vector2(x, y), line, color)
		y += line_height


func _draw_text_line(font: Font, font_size: int, point: Vector2, line: String, color: Color) -> void:
	var secondary := _get_text_secondary_color()
	# ASSUMPTION: CSmthFont's secondary color is a one-pixel glyph outline.
	# Its compositor is absent. Applying it to glyphs preserves text legibility
	# without inventing opaque rectangles behind every serialized caption.
	if secondary.a > 0.0:
		draw_string_outline(
			font, point, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 1, secondary
		)
	draw_string(font, point, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_rich_text() -> void:
	var font := _font()
	var font_size := _font_size()
	var ascent := font.get_ascent(font_size)
	var line_height := font.get_height(font_size)
	rich_hit_rects.clear()
	rich_links.clear()
	var segments := _parse_rich_segments(wnd_text)
	var max_width := maxf(size.x - 8.0, 32.0)

	var laid_lines: Array = []
	var cur_runs: Array = []
	var cur_width := 0.0

	for segment in segments:
		var value := str(segment.get("text", ""))
		var raw_color: Color = segment.get("color", _get_text_color(false))
		var color := _fade_text_color(raw_color)
		var link_id := str(segment.get("link", ""))
		var unit_id := 0
		if link_id != "":
			if not rich_links.has(link_id):
				rich_links.append(link_id)
			unit_id = rich_links.find(link_id) + 1

		var raw_lines := value.split("\n", true)
		for rl_index in range(raw_lines.size()):
			var raw_line := raw_lines[rl_index]
			var acc := ""
			var acc_w := 0.0
			for ch_i in raw_line.length():
				var ch := raw_line.substr(ch_i, 1)
				var cw := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				if cur_width + acc_w + cw > max_width and (acc != "" or not cur_runs.is_empty()):
					if acc != "":
						cur_runs.append({"text": acc, "width": acc_w, "color": color, "unit": unit_id})
						cur_width += acc_w
						acc = ""
						acc_w = 0.0
					laid_lines.append({"runs": cur_runs, "width": cur_width})
					cur_runs = []
					cur_width = 0.0
				acc += ch
				acc_w += cw
			if acc != "":
				cur_runs.append({"text": acc, "width": acc_w, "color": color, "unit": unit_id})
				cur_width += acc_w
			if rl_index < raw_lines.size() - 1:
				laid_lines.append({"runs": cur_runs, "width": cur_width})
				cur_runs = []
				cur_width = 0.0
	if not cur_runs.is_empty() or laid_lines.is_empty():
		laid_lines.append({"runs": cur_runs, "width": cur_width})

	var total_height := line_height * float(laid_lines.size())
	var y := ascent
	if (style_flags & WS_TEXTYC) != 0:
		y = (size.y - total_height) * 0.5 + ascent
	elif (style_flags & WS_TEXTYB) != 0:
		y = size.y - total_height + ascent

	for line_entry in laid_lines:
		var line_width := float(line_entry["width"])
		var x := 4.0
		if (style_flags & WS_TEXTXC) != 0:
			x = (size.x - line_width) * 0.5
		elif (style_flags & WS_TEXTXR) != 0:
			x = size.x - line_width - 4.0
		for run in line_entry["runs"]:
			var text := str(run["text"])
			var width := float(run["width"])
			var color: Color = run["color"]
			var unit_id := int(run["unit"])
			_draw_text_line(font, font_size, Vector2(x, y), text, color)
			if unit_id > 0:
				rich_hit_rects.append({
					"rect": Rect2(x, y - ascent, width, line_height),
					"unit": unit_id
				})
			x += width
		y += line_height


func _parse_rich_segments(source: String) -> Array:
	var result: Array = []
	# Keep parsed colors unfaded; all rich runs use the same single fade path.
	var default_color := _get_text_color(false)
	var current_color := default_color
	var active_link := ""
	var buffer := ""
	var index := 0

	while index < source.length():
		var marker := source.substr(index, 2)
		if marker == "#r":   # CGRichWnd line break (Claude)
			buffer += "\n"
			index += 2
			continue
		if marker == "#n":
			if buffer != "":
				result.append({"text": buffer, "color": current_color, "link": active_link})
				buffer = ""
			current_color = default_color
			active_link = ""
			index += 2
			continue

		if marker == "#c" and index + 10 <= source.length():
			var color_hex := source.substr(index + 2, 8)
			if _is_hex_color(color_hex):
				if buffer != "":
					result.append({"text": buffer, "color": current_color, "link": active_link})
					buffer = ""
				current_color = _color_from_argb(color_hex.hex_to_int())
				index += 10
				continue

		if (marker == "#l" or marker == "#h") and index + 2 < source.length():
			var open_char := source.substr(index + 2, 1)
			if open_char == "[" or open_char == "{":
				var close_char := "]" if open_char == "[" else "}"
				var close_index := source.find(close_char, index + 3)
				if close_index >= 0:
					if buffer != "":
						result.append({"text": buffer, "color": current_color, "link": active_link})
						buffer = ""
					active_link = source.substr(index + 3, close_index - index - 3)
					index = close_index + 1
					continue

		buffer += source.substr(index, 1)
		index += 1

	if buffer != "":
		result.append({"text": buffer, "color": current_color, "link": active_link})
	return result


func _is_hex_color(value: String) -> bool:
	if value.length() != 8:
		return false
	const HEX_DIGITS := "0123456789abcdefABCDEF"
	for index in range(value.length()):
		if HEX_DIGITS.find(value.substr(index, 1)) < 0:
			return false
	return true


func _font() -> Font:
	if _system_font == null:
		var system_font := SystemFont.new()
		system_font.font_names = [
			"Microsoft YaHei",
			"Noto Sans CJK SC",
			"PingFang SC",
			"sans-serif"
		]
		_system_font = system_font
	return _system_font


func _font_size() -> int:
	if text_font_size > 0:
		return text_font_size
	var style: Dictionary = data.get("text_style", {})
	var raw: Dictionary = style.get("raw_fields", {})
	return maxi(1, int(_field_number(raw, "this+0x2c", 18.0)))


func _get_text_color(apply_fade: bool = true) -> Color:
	var colors := GuiDraw.get_state_text_colors(self, state)
	var packed := int(colors["foreground_argb"])
	if apply_fade:
		packed = GuiDraw.fade_text_or_direct_rect_argb(packed, GuiDraw.effective_fade_byte(self))
	return _color_from_argb(packed)


func _get_text_secondary_color(apply_fade: bool = true) -> Color:
	var colors := GuiDraw.get_state_text_colors(self, state)
	var packed := int(colors["secondary_argb"])
	if apply_fade:
		packed = GuiDraw.fade_text_or_direct_rect_argb(packed, GuiDraw.effective_fade_byte(self))
	return _color_from_argb(packed)


func _fade_text_color(value: Color) -> Color:
	return _color_from_argb(GuiDraw.fade_text_or_direct_rect_argb(
		GuiDraw.color_to_argb(value), GuiDraw.effective_fade_byte(self)
	))


func _color_from_argb(value: int) -> Color:
	return GuiDraw.color_from_argb(value)


func _field_number(source: Dictionary, field_name: String, fallback: float) -> float:
	return GuiDraw.number(source.get(field_name, fallback), fallback)


func _signed_coordinate(value: Variant) -> float:
	var result := GuiDraw.number(value)
	# Resource coordinates are read as u32; preserve two's-complement negatives.
	if result >= 2147483648.0 and result <= 4294967295.0:
		result -= 4294967296.0
	return result


func _images_for_state(image_state: int) -> Array:
	if image_state < 0 or image_state >= images_by_state.size():
		return []
	if not images_by_state[image_state] is Array:
		return []
	return images_by_state[image_state]


func _apply_image_rect_override(image_index: int, rect_key: String, rect_value: Dictionary) -> void:
	if image_index < 0:
		return
	# ASSUMPTION: setters with no state parameter target the corresponding
	# image in every state, so switching state does not undo a runtime edit.
	for state_images in images_by_state:
		if not state_images is Array or image_index >= state_images.size():
			continue
		if not state_images[image_index] is Dictionary:
			continue
		var image_data: Dictionary = state_images[image_index]
		image_data[rect_key] = rect_value.duplicate(true)
		if rect_key == "source_rect":
			image_data["_gui_tile_rect"] = rect_value.duplicate(true)
			image_data.erase("tile_rect")
		var source := GuiDraw.rect_edges(image_data.get("source_rect", {}))
		var destination := GuiDraw.rect_edges(image_data.get("destination_rect", {}))
		var previous: Vector2 = image_data.get("_gui_uv_density", Vector2.ONE)
		image_data["_gui_uv_density"] = _image_density(source, destination, previous)
		image_data.erase("uv_density")
	queue_redraw()


# Effect-font windows (CEffectFontWnd via AssignDlgChildToWnd) render text through effects; their authored
# solid-colour placeholder image is not drawn by the engine (Claude).
func clear_placeholder_images() -> void:
	for st in images_by_state.size():
		var list = images_by_state[st]
		if list is Array:
			images_by_state[st] = (list as Array).filter(func(im): var ti := int(im.get("texture_index", 0)) if im is Dictionary else 0; return not (ti < 0 or ti == 4294967295))
	queue_redraw()


func _captures_click() -> bool:
	return _is_button() or _is_check_button() or _is_scrollable() or _edit_control != null or _list_owner != null


func _is_check_button() -> bool:
	return class_of() == "CGCheckButton"


func _is_radio_button() -> bool:
	return _is_check_button() and (style_flags & 0x1) != 0


func _scroll_drag_target() -> Control:
	if _is_scrollable() and inertia_type != 0:
		return self
	if _list_owner != null and is_instance_valid(_list_owner) and _list_owner.has_method("_is_scrollable") and _list_owner.call("_is_scrollable") and int(_list_owner.get("inertia_type")) != 0:
		return _list_owner
	return null


func _is_button() -> bool:
	return class_of() == "CGButton" or class_of() == "CGCheckButton" or class_of() == "CGComboBox"


func _is_progress() -> bool:
	return class_of() == "CGProgress"


func _is_edit() -> bool:
	return class_of() == "CGEdit"


func _is_rich() -> bool:
	return class_of() == "CGRichWnd"


func _is_list() -> bool:
	return class_of() == "CGListCtrl" or class_of() == "CGTreeCtrl"


func _is_scrollable() -> bool:
	return _is_list() or class_of() == "CGScrollPane" or _is_rich()


func _normal_state() -> int:
	if not enabled:
		return 7 if _is_check_button() and not checked else 3
	if _is_check_button() and not checked:
		return 6
	return 2


func _hover_state() -> int:
	if _is_check_button() and not checked:
		return 8
	return 4


func _pressed_state() -> int:
	if _is_check_button() and not checked:
		return 9
	return 5


func _set_visual_state(is_hovered: bool) -> void:
	if not enabled:
		set_state(7 if _is_check_button() and not checked else 3)
	elif _pressed:
		set_state(_pressed_state())
	elif is_hovered and _is_button():
		set_state(_hover_state())
	else:
		set_state(_normal_state())


func _on_mouse_entered() -> void:
	_mouse_inside = true
	if _is_button():
		_set_visual_state(true)
	_send(GM_WM_MOUSEENTER, 0, 0)


func _on_mouse_exited() -> void:
	_mouse_inside = false
	if not _pressed:
		_set_visual_state(false)
	_send(GM_WM_MOUSELEAVE, 0, 0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_inside = Rect2(Vector2.ZERO, size).has_point(event.position)
		if _pressed:
			var drag_target := _scroll_drag_target()
			if drag_target != null:
				var motion := event as InputEventMouseMotion
				var total_delta := motion.global_position - _mouse_drag_start
				var step_delta := motion.global_position - _mouse_drag_last
				_mouse_drag_last = motion.global_position
				var target_inertia := int(drag_target.get("inertia_type"))
				if not _mouse_dragging:
					if (target_inertia == INERTIA_HSCROLL and absf(total_delta.x) >= 10.0) or (target_inertia == INERTIA_VSCROLL and absf(total_delta.y) >= 10.0):
						_mouse_dragging = true
				if _mouse_dragging:
					drag_target.call("_handle_scroll_drag", step_delta)
					accept_event()
					return
			_set_visual_state(_mouse_inside)
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP or mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_handle_wheel(mouse_event)
			return
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not enabled:
			return
		# Plain windows (decor/effect overlays such as "texiao" on the home-screen buttons) report the click to Lua
		# but let it bubble to the parent window, so the button underneath still fires (Claude).
		var capture := _captures_click()
		if mouse_event.pressed:
			_send(WM_LBUTTONDOWN, 1, _pack_lparam(mouse_event.position))
			_pressed = true
			_mouse_drag_start = mouse_event.global_position
			_mouse_drag_last = mouse_event.global_position
			_mouse_dragging = false
			_set_visual_state(true)
			if capture: accept_event()
		else:
			var was_pressed := _pressed
			var was_dragging := _mouse_dragging
			_send(WM_LBUTTONUP, 0, _pack_lparam(mouse_event.position))
			_pressed = false
			_mouse_dragging = false
			if was_pressed and not was_dragging:
				_finish_click(mouse_event.position)
				if capture: accept_event()
			elif was_dragging and capture:
				accept_event()
			_set_visual_state(_mouse_inside)
		return

	if event is InputEventScreenTouch:
		if not enabled:
			return
		var touch_event := event as InputEventScreenTouch
		_last_pointer = touch_event.position
		if touch_event.pressed:
			_send(WM_LBUTTONDOWN, 1, _pack_lparam(touch_event.position))
			_touch_down = true
			_pressed = true
			_set_visual_state(true)
			accept_event()
		else:
			var was_pressed := _touch_down
			_send(WM_LBUTTONUP, 0, _pack_lparam(touch_event.position))
			_touch_down = false
			_pressed = false
			if was_pressed:
				_finish_click(touch_event.position)
				accept_event()
			_set_visual_state(Rect2(Vector2.ZERO, size).has_point(touch_event.position))
		return

	if event is InputEventScreenDrag and _touch_down and _is_scrollable():
		var drag := event as InputEventScreenDrag
		var delta := drag.position - _last_pointer
		_last_pointer = drag.position
		_handle_scroll_drag(delta)
		accept_event()


func _finish_click(point: Vector2) -> void:
	if not enabled or not Rect2(Vector2.ZERO, size).has_point(point):
		return
	if _list_owner != null and is_instance_valid(_list_owner):
		_list_owner.call("_select_node", self)
	var l_param := _pack_lparam(point)
	var link_unit := test_unit_id(point.x, point.y)
	if link_unit > 0:
		_send(GM_WM_RICH_CLICK_ID, link_unit << 16, l_param)
	if _is_check_button():
		if _is_radio_button():
			set_check(true)
		else:
			checked = not checked
			_set_visual_state(_mouse_inside)
		_send(GM_WM_BTN_CHECKED, 1 if checked else 0, l_param)
	_send(GM_WM_MOUSECLICK, 1, l_param)
	if _is_button():
		_send(GM_WM_ACTION, 1, l_param)


func _select_node(cell: Control) -> void:
	var item_index := get_item_index(cell)
	if item_index >= 0:
		var columns := get_column_count()
		select_item(floori(float(item_index) / float(columns)), item_index % columns)


func _handle_wheel(event: InputEventMouseButton) -> void:
	if not enabled or not _is_scrollable() or (style_flags & GuiDraw.WS_IGNOREWHEEL) != 0:
		return
	if not event.pressed:
		return
	var direction := -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
	if inertia_type == INERTIA_HSCROLL:
		set_scroll_horizon_pos(scroll_x + direction * 48.0)
		_send(GM_WM_HORIZON_SCROLL, int(scroll_x), _pack_lparam(event.position))
	else:
		set_scroll_vertical_pos(scroll_y + direction * 48.0)
		_send(GM_WM_VERTICAL_SCROLL, int(scroll_y), _pack_lparam(event.position))
	accept_event()


func _handle_scroll_drag(delta: Vector2) -> void:
	if inertia_type == INERTIA_HSCROLL:
		set_scroll_horizon_pos(scroll_x - delta.x)
		scroll_velocity.x = -delta.x * 12.0
		_send(GM_WM_HORIZON_SCROLL, int(scroll_x), 0)
		set_process(true)
	elif inertia_type == INERTIA_VSCROLL:
		set_scroll_vertical_pos(scroll_y - delta.y)
		scroll_velocity.y = -delta.y * 12.0
		_send(GM_WM_VERTICAL_SCROLL, int(scroll_y), 0)
		set_process(true)


func _process(delta: float) -> void:
	var keep_running := false
	if _has_preview():
		if is_visible_in_tree():
			_update_preview_state()
			keep_running = true
		else:
			_set_preview_running(false)
	if _is_scrollable() and scroll_velocity.length() >= 2.0:
		if inertia_type == INERTIA_HSCROLL:
			set_scroll_horizon_pos(scroll_x + scroll_velocity.x * delta)
		else:
			set_scroll_vertical_pos(scroll_y + scroll_velocity.y * delta)
		scroll_velocity *= pow(0.08, delta)
		if scroll_velocity.length() >= 2.0:
			keep_running = true
		else:
			scroll_velocity = Vector2.ZERO
	else:
		scroll_velocity = Vector2.ZERO
	if not keep_running:
		set_process(false)


func _send(message: int, w_param: int = 0, l_param: int = 0) -> void:
	if GuiRuntime.dispatch.is_valid():
		GuiRuntime.dispatch.call(self, message, w_param, l_param)


func _pack_lparam(point: Vector2) -> int:
	var x := int(point.x) & 0xffff
	var y := int(point.y) & 0xffff
	return x | (y << 16)


func _column_width(column_index: int) -> float:
	if column_index >= 0 and column_index < column_widths.size() and float(column_widths[column_index]) > 0.0:
		return float(column_widths[column_index])
	return size.x / float(get_column_count())


func _row_height(row_index: int) -> float:
	if row_index >= 0 and row_index < item_heights.size() and float(item_heights[row_index]) > 0.0:
		return float(item_heights[row_index])
	if row_index >= 0 and row_index < list_rows.size():
		var row: Array = list_rows[row_index]
		for cell in row:
			if cell is Control and cell.size.y > 0.0:
				return cell.size.y
	return 24.0


func _reflow_list() -> void:
	var y := -scroll_y
	for row_index in range(list_rows.size()):
		var row: Array = list_rows[row_index]
		var x := -scroll_x
		for column_index in range(row.size()):
			var cell = row[column_index]
			if cell is Control:
				cell.position = Vector2(x, y)
				if cell.size.x <= 0.0:
					cell.size.x = _column_width(column_index)
				if cell.size.y <= 0.0:
					cell.size.y = _row_height(row_index)
				if cell.has_method("_select_node"):
					cell.set("_list_owner", self)
			x += _column_width(column_index)
		y += _row_height(row_index)
	queue_redraw()


func _reflow_combo_items() -> void:
	for index in range(combo_item_nodes.size()):
		var item_node = combo_item_nodes[index]
		if item_node is Control:
			item_node.position = Vector2(0.0, float(index) * 24.0)
			if item_node.has_method("set_wnd_size"):
				item_node.call("set_wnd_size", size.x, 24.0)
			else:
				item_node.size = Vector2(size.x, 24.0)


func _create_edit_control() -> void:
	_edit_control = LineEdit.new()
	_edit_control.position = Vector2.ZERO
	_edit_control.size = size
	_edit_control.text = wnd_text
	_edit_control.clear_button_enabled = false
	_edit_control.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_edit_control.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_edit_control.add_theme_stylebox_override("read_only", StyleBoxEmpty.new())
	_edit_control.text_changed.connect(_on_edit_text_changed)
	_edit_control.focus_entered.connect(_on_edit_focus_changed.bind(true))
	_edit_control.focus_exited.connect(_on_edit_focus_changed.bind(false))
	_edit_control.text_submitted.connect(_on_edit_submitted)
	add_child(_edit_control)
	_edit_selection_color = _edit_control.get_theme_color("selection_color")
	_refresh_edit_control()


func _refresh_edit_control() -> void:
	if _edit_control == null:
		return
	_edit_control.editable = enabled
	_edit_control.add_theme_font_override("font", _font())
	_edit_control.add_theme_font_size_override("font_size", _font_size())

	var foreground := _get_text_color()
	var secondary := _get_text_secondary_color()
	_edit_control.add_theme_color_override("font_color", foreground)
	_edit_control.add_theme_color_override("font_uneditable_color", foreground)
	_edit_control.add_theme_color_override("font_selected_color", foreground)
	_edit_control.add_theme_color_override("font_placeholder_color", foreground)
	_edit_control.add_theme_color_override("caret_color", foreground)
	_edit_control.add_theme_color_override("selection_color", _fade_text_color(_edit_selection_color))
	_edit_control.add_theme_color_override("font_outline_color", secondary)
	_edit_control.add_theme_constant_override("outline_size", 1 if secondary.a > 0.0 else 0)

	if (style_flags & WS_TEXTXC) != 0:
		_edit_control.alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif (style_flags & WS_TEXTXR) != 0:
		_edit_control.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		_edit_control.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# Theme colors already include native text fade; neither the LineEdit nor
	# its parent receives another fade modulation.
	GuiDraw.bind_text_clip(_edit_control, self)
	_edit_control.queue_redraw()


func _on_edit_text_changed(value: String) -> void:
	wnd_text = value


func _on_edit_focus_changed(has_focus_value: bool) -> void:
	_send(WM_SETFOCUS if has_focus_value else WM_KILLFOCUS, 0, 0)
	if not has_focus_value:
		_send(GM_WM_EDIT_RETURN, 0, 0)


func _on_edit_submitted(_value: String) -> void:
	_send(GM_WM_EDIT_RETURN, 0, 0)


static var _shared_preview_env: Environment = null
static var _preview_scene_cache: Dictionary = {}
static var _preview_budget_frame: int = -1
static var _preview_budget_left: int = 0

var _preview_holder: SubViewportContainer = null
var _preview_vp: SubViewport = null
var _preview_ap: AnimationPlayer = null
var _preview_model_path := ""
var _preview_pending_path := ""
var _preview_pending_ani := "stand"
var _preview_pending_loop := true
var _preview_running := false


func _has_preview() -> bool:
	return _preview_pending_path != "" or _preview_vp != null


func clear_preview_model() -> void:
	_preview_model_path = ""
	_preview_pending_path = ""
	_preview_running = false
	_preview_ap = null
	_preview_vp = null
	if _preview_holder != null and is_instance_valid(_preview_holder):
		_preview_holder.queue_free()
		_preview_holder = null


func _is_preview_on_screen() -> bool:
	if not is_inside_tree() or not is_visible_in_tree():
		return false
	var my_rect := get_global_rect()
	if my_rect.size.x <= 1.0 or my_rect.size.y <= 1.0:
		return false
	var vp := get_viewport()
	if vp != null:
		var screen_rect := vp.get_visible_rect()
		if not my_rect.intersects(screen_rect):
			return false
	var cur := get_parent()
	while cur != null and cur is Control:
		var ctrl := cur as Control
		if ctrl.clip_contents:
			var clip_rect := ctrl.get_global_rect()
			if not my_rect.intersects(clip_rect):
				return false
			my_rect = my_rect.intersection(clip_rect)
		cur = cur.get_parent()
	return my_rect.size.x > 1.0 and my_rect.size.y > 1.0


func _set_preview_running(active: bool) -> void:
	if _preview_vp == null or not is_instance_valid(_preview_vp):
		_preview_running = false
		return
	if _preview_running == active:
		return
	_preview_running = active
	_preview_vp.render_target_update_mode = (
		SubViewport.UPDATE_WHEN_VISIBLE if active else SubViewport.UPDATE_DISABLED
	)
	if _preview_ap != null and is_instance_valid(_preview_ap):
		_preview_ap.process_mode = (
			Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		)
	if _preview_holder != null and is_instance_valid(_preview_holder):
		_preview_holder.visible = active


func _take_preview_budget() -> bool:
	var frame := Engine.get_process_frames()
	if frame != _preview_budget_frame:
		_preview_budget_frame = frame
		_preview_budget_left = 4
	if _preview_budget_left <= 0:
		return false
	_preview_budget_left -= 1
	return true


func _update_preview_state() -> void:
	var on_screen := _is_preview_on_screen()
	if not on_screen:
		_set_preview_running(false)
		return
	if _preview_vp == null and _preview_pending_path != "":
		if _take_preview_budget():
			_build_preview_model(_preview_pending_path, _preview_pending_ani, _preview_pending_loop)
	if _preview_vp != null:
		_set_preview_running(true)


func _resolve_preview_ani(ap: AnimationPlayer, ani_name: String) -> String:
	if ap == null:
		return ""
	if ani_name != "" and ap.has_animation(ani_name):
		return ani_name
	for fallback in ["stand", "stand1", "stand2", "run_w", "chat"]:
		if ap.has_animation(fallback):
			return fallback
	var all := ap.get_animation_list()
	return str(all[0]) if not all.is_empty() else ""


func play_preview_ani(ani_name: String = "stand", loop: bool = true) -> void:
	_preview_pending_ani = ani_name
	_preview_pending_loop = loop
	if _preview_vp == null and _preview_pending_path != "" and is_visible_in_tree():
		_build_preview_model(_preview_pending_path, ani_name, loop)
	if _preview_ap == null or not is_instance_valid(_preview_ap):
		return
	var pick := _resolve_preview_ani(_preview_ap, ani_name)
	if pick == "":
		return
	var anim := _preview_ap.get_animation(pick)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if not loop:
		# Play showcase emote once, then seamlessly resume looping idle animation.
		if not _preview_ap.animation_finished.is_connected(_on_preview_ani_finished):
			_preview_ap.animation_finished.connect(_on_preview_ani_finished, CONNECT_ONE_SHOT)
		_preview_ap.stop()
		_preview_ap.play(pick)
	else:
		if _preview_ap.current_animation != pick or not _preview_ap.is_playing():
			_preview_ap.play(pick)
			_preview_ap.advance(0.0)
	if _is_preview_on_screen():
		_set_preview_running(true)


func _on_preview_ani_finished(_finished_name: StringName) -> void:
	play_preview_ani("stand", true)


func show_preview_model(model_path: String, ani_name: String = "stand", loop: bool = true) -> void:
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		return
	_preview_pending_path = model_path
	_preview_pending_ani = ani_name
	_preview_pending_loop = loop
	if _preview_model_path == model_path and _preview_holder != null and is_instance_valid(_preview_holder):
		play_preview_ani(ani_name, loop)
		if is_visible_in_tree():
			set_process(true)
			_update_preview_state()
		return
	if _preview_holder != null and is_instance_valid(_preview_holder):
		_preview_holder.queue_free()
		_preview_holder = null
		_preview_vp = null
		_preview_ap = null
		_preview_model_path = ""
		_preview_running = false
	if is_visible_in_tree():
		set_process(true)
		_update_preview_state()


func _build_preview_model(model_path: String, ani_name: String, loop: bool) -> void:
	if not _preview_scene_cache.has(model_path):
		_preview_scene_cache[model_path] = ResourceLoader.load(model_path)
	var packed = _preview_scene_cache[model_path]
	if packed == null or not (packed is PackedScene):
		return
	var inst: Node = (packed as PackedScene).instantiate()
	if not (inst is Node3D):
		inst.queue_free()
		return
	_preview_model_path = model_path

	var holder := SubViewportContainer.new()
	holder.name = "ModelPreview3D"
	holder.stretch = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2.ZERO
	holder.size = size if size.x > 8.0 and size.y > 8.0 else Vector2(200, 200)
	holder.clip_contents = true

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.handle_input_locally = false
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.positional_shadow_atlas_size = 0
	vp.use_debanding = false
	vp.size = Vector2i(160, 160)
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	holder.add_child(vp)
	_preview_vp = vp

	if _shared_preview_env == null:
		var env := Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0, 0, 0, 0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(1.0, 1.0, 1.0)
		env.ambient_light_energy = 1.15
		_shared_preview_env = env
	var env_node := WorldEnvironment.new()
	env_node.environment = _shared_preview_env
	vp.add_child(env_node)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38.0, 32.0, 0.0)
	light.light_energy = 1.0
	light.shadow_enabled = false
	vp.add_child(light)

	var model_root := Node3D.new()
	vp.add_child(model_root)
	var model3d: Node3D = inst as Node3D
	model_root.add_child(model3d)

	var aps := model3d.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_preview_ap = aps[0] as AnimationPlayer
		_preview_ap.process_mode = Node.PROCESS_MODE_DISABLED
		var pick := _resolve_preview_ani(_preview_ap, ani_name)
		if pick != "":
			var anim := _preview_ap.get_animation(pick)
			if anim != null:
				anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
			if not loop:
				if not _preview_ap.animation_finished.is_connected(_on_preview_ani_finished):
					_preview_ap.animation_finished.connect(_on_preview_ani_finished, CONNECT_ONE_SHOT)
			_preview_ap.play(pick)
			_preview_ap.advance(0.0)

	# Auto-frame model from its mesh bounds so every character & chest fills the card cleanly
	var has_bounds := false
	var bounds := AABB()
	for m in model3d.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi != null and mi.mesh != null:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var a := mi.mesh.get_aabb()
			if not has_bounds:
				bounds = a
				has_bounds = true
			else:
				bounds = bounds.merge(a)
	var center := Vector3(0, 0.45, 0)
	var radius := 0.65
	if has_bounds and bounds.size.length() > 0.001:
		center = bounds.get_center()
		radius = maxf(bounds.size.y * 0.55, maxf(bounds.size.x, bounds.size.z) * 0.55)
		radius = clampf(radius, 0.15, 20.0)

	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.near = maxf(0.02, radius * 0.05)
	cam.far = maxf(50.0, radius * 40.0)
	vp.add_child(cam)
	cam.look_at_from_position(center + Vector3(-radius * 1.15, radius * 0.95, -radius * 3.15), center, Vector3.UP)

	add_child(holder)
	move_child(holder, 0)
	_preview_holder = holder
	_preview_running = false
	if _is_preview_on_screen():
		_set_preview_running(true)
