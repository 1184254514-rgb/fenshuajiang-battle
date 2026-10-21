class_name SkillHud
extends Control
# Original skill names, descriptions, icon atlas rectangles and rule clocks come
# from scene_skills.lua. This panel only presents the local loadout and controls.
var host: LuaHost
var _menu_layer: ColorRect
var _home: Panel
var _game: Panel
var _active: OptionButton
var _passives: Array[OptionButton] = []
var _description: Label
var _cast: Button
var _status: Label
var _duration: Label
var _icon: TextureRect
var _active_ids: Array[int] = []
var _passive_ids: Array[int] = []
var _catalog: Dictionary = {}
var _poll_left := 0.0
var _last_state := ""
var _ready_catalog := false
var _notice_left := 0.0
var _notice := ""
var _font: Font = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")
const INK := Color("14364b")
const CREAM := Color("fff8df")
const GOLD := Color("ffd55a")

func _ready() -> void:
	name = "SkillHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 2900
	_menu_layer = ColorRect.new()
	_menu_layer.name = "SkillMenuLayer"
	_menu_layer.color = Color(0.025, 0.08, 0.15, 0.62)
	_menu_layer.size = Vector2(1280, 720)
	_menu_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu_layer.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_action("SceneSkills.CloseMenu()"))
	add_child(_menu_layer)
	_home = _panel(Vector2(444, 197), Vector2(392, 326))
	_home.reparent(_menu_layer, false)
	_label(_home, "技能配置  ·  Lv.1", Vector2(18, 9), Vector2(304, 31), 24)
	var close := Button.new()
	close.name = "CloseSkillMenuButton"
	close.text = "×"
	close.position = Vector2(338, 7)
	close.size = Vector2(38, 34)
	close.focus_mode = Control.FOCUS_NONE
	_theme(close, 25)
	close.pressed.connect(func(): _action("SceneSkills.CloseMenu()"))
	_home.add_child(close)
	_active = _option(_home, Vector2(18, 48), Vector2(356, 43))
	_active.name = "ActiveSkillSelector"
	_active.item_selected.connect(_on_active_selected)
	_description = _label(_home, "", Vector2(20, 96), Vector2(352, 67), 17)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	for slot in 3:
		_label(_home, "被动 %d" % (slot + 1), Vector2(19, 174 + slot * 44), Vector2(77, 33), 19)
		var option := _option(_home, Vector2(99, 173 + slot * 44), Vector2(274, 36))
		option.name = "PassiveSkillSelector%d" % (slot + 1)
		option.item_selected.connect(func(index: int): _on_passive_selected(slot, index))
		_passives.append(option)
	_game = _panel(Vector2(968, 414), Vector2(286, 183))
	_icon = TextureRect.new()
	_icon.position = Vector2(16, 15)
	_icon.size = Vector2(46, 46)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_game.add_child(_icon)
	_cast = Button.new()
	_cast.name = "CastSkillButton"
	_cast.position = Vector2(71, 13)
	_cast.size = Vector2(198, 52)
	_cast.focus_mode = Control.FOCUS_NONE
	_theme(_cast, 23)
	_cast.add_theme_stylebox_override("normal", _box(GOLD))
	_cast.add_theme_stylebox_override("hover", _box(GOLD.lightened(0.15)))
	_cast.add_theme_stylebox_override("pressed", _box(GOLD.darkened(0.1)))
	_cast.add_theme_stylebox_override("disabled", _box(Color("d5d9cf")))
	_cast.pressed.connect(func(): _action("NativeKeySkill()"))
	_game.add_child(_cast)
	_status = _label(_game, "技能就绪", Vector2(17, 74), Vector2(252, 29), 20)
	_duration = _label(_game, "", Vector2(17, 104), Vector2(252, 29), 18)
	_label(_game, "Q / 空格释放技能", Vector2(17, 143), Vector2(252, 27), 18)
	_menu_layer.hide()
	_game.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if _menu_layer.visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_action("SceneSkills.CloseMenu()")
		get_viewport().set_input_as_handled()

func _box(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(13)
	return style

func _panel(pos: Vector2, extent: Vector2) -> Panel:
	var panel := Panel.new()
	panel.position = pos
	panel.size = extent
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _box(CREAM))
	add_child(panel)
	return panel

func _theme(control, font_size: int) -> void:
	control.add_theme_font_override("font", _font)
	control.add_theme_font_size_override("font_size", font_size)
	control.add_theme_color_override("font_color", INK)
	control.add_theme_color_override("font_hover_color", INK)
	control.add_theme_color_override("font_pressed_color", INK)
	control.add_theme_color_override("font_disabled_color", Color("6f7878"))

func _label(parent: Node, caption: String, pos: Vector2, extent: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = caption
	label.position = pos
	label.size = extent
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_theme(label, font_size)
	parent.add_child(label)
	return label

func _option(parent: Node, pos: Vector2, extent: Vector2) -> OptionButton:
	var option := OptionButton.new()
	option.position = pos
	option.size = extent
	option.focus_mode = Control.FOCUS_CLICK
	_theme(option, 20)
	option.add_theme_constant_override("icon_max_width", 30)
	option.add_theme_stylebox_override("normal", _box(Color("f1e7cb")))
	option.add_theme_stylebox_override("hover", _box(Color("fff1bd")))
	_theme(option.get_popup(), 21)
	option.get_popup().add_theme_constant_override("icon_max_width", 30)
	parent.add_child(option)
	return option

func _skill_icon(row: Dictionary) -> Texture2D:
	var resource_path := "res://assets/tex/" + str(row.get("icon", "")).get_file().get_basename() + ".png"
	if not ResourceLoader.exists(resource_path): return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(resource_path) as Texture2D
	atlas.region = Rect2(float(row.get("left", 0)), float(row.get("top", 0)), float(row.get("right", 0)) - float(row.get("left", 0)), float(row.get("bottom", 0)) - float(row.get("top", 0)))
	return atlas

func _populate(data: Dictionary) -> void:
	for value in data.get("active", []):
		var row: Dictionary = value
		var id := int(row["id"])
		_catalog[id] = row
		_active_ids.append(id)
		_active.add_icon_item(_skill_icon(row), str(row["name"]), id)
		_active.set_item_tooltip(_active.item_count - 1, str(row.get("description", "")))
	_passive_ids.append(0)
	for option in _passives: option.add_item("不装备", 0)
	for value in data.get("passive", []):
		var row: Dictionary = value
		var id := int(row["id"])
		_catalog[id] = row
		_passive_ids.append(id)
		for option in _passives:
			option.add_icon_item(_skill_icon(row), str(row["name"]), id)
			option.set_item_tooltip(option.item_count - 1, str(row.get("description", "")))
	_ready_catalog = true

func _on_active_selected(index: int) -> void:
	if index >= 0 and index < _active_ids.size():
		_action("SceneSkills.SetSelected(%d,1)" % _active_ids[index])

func _on_passive_selected(slot: int, index: int) -> void:
	if index >= 0 and index < _passive_ids.size():
		_action("SceneSkills.SetPassive(%d,%d,1)" % [slot + 1, _passive_ids[index]])

func _action(code: String) -> void:
	if host == null or host.lua == null: return
	var result = host.lua.do_string("return " + code)
	if result is LuaError:
		host._tick_errors += 1
		printerr("LUA ERROR in skill UI: ", result)
	elif result is bool and not result:
		_notice = "该被动已装备，请选择其他技能"
		_notice_left = 2.0
	elif result is Array and not result.is_empty() and result[0] is bool and not result[0]:
		_notice = str(result[1]) if result.size() > 1 else "当前无法释放技能"
		_notice_left = 2.0
	_last_state = ""
	_poll_left = 0.0

func _process(delta: float) -> void:
	_poll_left -= delta
	var previous_notice := _notice_left
	_notice_left = maxf(0.0, _notice_left - delta)
	if previous_notice > 0.0 and _notice_left == 0.0: _last_state = ""
	if _poll_left > 0.0 or host == null or host.lua == null: return
	_poll_left = 0.1
	var result = host.lua.do_string("return SceneSkills and SceneSkills.GetHUDJSON() or '{}' ")
	if result is LuaError:
		if _last_state != "error":
			host._tick_errors += 1
			printerr("LUA ERROR in skill HUD: ", result)
		_last_state = "error"
		return
	var snapshot := str(result)
	if snapshot == _last_state and _notice_left == 0.0: return
	_last_state = snapshot
	var parsed = JSON.parse_string(snapshot)
	if not parsed is Dictionary: return
	_render(parsed)

func _render(data: Dictionary) -> void:
	if not _ready_catalog and not data.get("active", []).is_empty(): _populate(data)
	_menu_layer.visible = bool(data.get("home", false)) and bool(data.get("menu_open", false))
	_game.visible = bool(data.get("running", false))
	var selected := int(data.get("selected", 3))
	if selected in _active_ids: _active.select(_active_ids.find(selected))
	var row: Dictionary = _catalog.get(selected, {})
	_description.text = _notice if _notice_left > 0.0 else str(row.get("description", ""))
	var equipped: Array = data.get("passives", [])
	for slot in _passives.size():
		var passive_id := int(equipped[slot]) if slot < equipped.size() else 0
		if passive_id in _passive_ids: _passives[slot].select(_passive_ids.find(passive_id))
	var cooldown := int(data.get("cooldown_ms", 0))
	var duration := int(data.get("duration_ms", 0))
	_cast.text = str(data.get("name", "释放技能"))
	_cast.disabled = not bool(data.get("alive", false)) or cooldown > 0
	_icon.texture = _skill_icon(_catalog.get(int(data.get("skill_id", selected)), {}))
	_status.text = "冷却 %.1f 秒" % (cooldown / 1000.0) if cooldown > 0 else "技能就绪"
	_duration.text = "效果剩余 %.1f 秒" % (duration / 1000.0) if duration > 0 else "每次释放后进入独立冷却"
