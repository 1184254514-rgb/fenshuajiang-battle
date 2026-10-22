class_name MatchHud
extends Control
# Presentation for the local timed mode; Lua owns every rule and deadline.
# Fixed 1280x720 canvas follows the original game's stretch transform.
var host: LuaHost
var _respawn: Label
var _finish_layer: ColorRect
var _winner: Label
var _placement: Label
var _rows: VBoxContainer
var _last_state: String = ""
var _poll_left: float = 0.0
var _font: Font = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")
const INK := Color("14364b")
const CREAM := Color("fff8df")
const GOLD := Color("ffd55a")
const TEAL := Color("18afaa")

func _ready() -> void:
	name = "MatchHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 3000
	_build_respawn()
	_build_results()
	_respawn.hide()
	_finish_layer.hide()

func _box(color: Color, border: Color = INK, radius: int = 14) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(3)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.03, 0.12, 0.19, 0.25)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 4)
	return box

func _text(parent: Node, caption: String, pos: Vector2, extent: Vector2, font_size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = caption
	label.position = pos
	label.size = extent
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, pos: Vector2, extent: Vector2, fill: Color, action: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = pos
	button.size = extent
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_stylebox_override("normal", _box(fill))
	button.add_theme_stylebox_override("hover", _box(fill.lightened(0.13)))
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.1)))
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: _action(action))
	parent.add_child(button)
	return button

func _build_respawn() -> void:
	_respawn = _text(self, "3 秒后重生", Vector2(390, 280), Vector2(500, 72), 36, Color.WHITE)
	_respawn.name = "MatchRespawn"
	_respawn.add_theme_color_override("font_outline_color", INK)
	_respawn.add_theme_constant_override("outline_size", 9)

func _build_results() -> void:
	_finish_layer = ColorRect.new()
	_finish_layer.name = "MatchResults"
	_finish_layer.color = Color(0.025, 0.08, 0.15, 0.78)
	_finish_layer.position = Vector2.ZERO
	_finish_layer.size = Vector2(1280, 720)
	_finish_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_finish_layer)
	var panel := Panel.new()
	panel.position = Vector2(300, 42)
	panel.size = Vector2(680, 636)
	panel.add_theme_stylebox_override("panel", _box(CREAM, INK, 20))
	_finish_layer.add_child(panel)
	_text(panel, "时间到！", Vector2(0, 12), Vector2(680, 55), 41)
	_winner = _text(panel, "本局冠军", Vector2(20, 67), Vector2(640, 41), 25, Color("008f90"))
	_placement = _text(panel, "你的成绩", Vector2(20, 110), Vector2(640, 34), 22)
	var heading := _text(panel, "名次       画匠                        占地       击杀", Vector2(40, 156), Vector2(600, 32), 20, Color("607584"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_rows = VBoxContainer.new()
	_rows.position = Vector2(35, 194)
	_rows.size = Vector2(610, 345)
	_rows.add_theme_constant_override("separation", 3)
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_rows)
	var replay := _button(panel, "再来一局", Vector2(58, 552), Vector2(260, 57), GOLD, "SceneMatch.Rematch()")
	replay.name = "RematchButton"
	var home := _button(panel, "返回大厅", Vector2(362, 552), Vector2(260, 57), Color("8be3d0"), "SceneMatch.ReturnHome()")
	home.name = "MatchHomeButton"

func _action(code: String) -> void:
	if host == null or host.lua == null:
		return
	var result = host.lua.do_string("return " + code)
	if result is LuaError:
		host._tick_errors += 1
		printerr("LUA ERROR in timed-match UI: ", result)
	_last_state = ""
	_poll_left = 0.0

func _process(delta: float) -> void:
	_poll_left -= delta
	if _poll_left > 0.0 or host == null or host.lua == null:
		return
	_poll_left = 0.1
	var result = host.lua.do_string("return SceneMatch and SceneMatch.UIState() or 'none'")
	if result is LuaError:
		if _last_state != "ui_error":
			host._tick_errors += 1
			printerr("LUA ERROR in timed-match HUD: ", result)
		_last_state = "ui_error"
		return
	var snapshot: String = str(result)
	if snapshot == _last_state:
		return
	_last_state = snapshot
	_render(snapshot)

func _render(snapshot: String) -> void:
	var lines: PackedStringArray = snapshot.split("\n")
	var header: PackedStringArray = lines[0].split("|")
	var mode: String = header[0]
	_finish_layer.visible = mode == "finished"
	_respawn.hide()
	if header.size() < 10:
		return
	var respawn_ms: int = int(header[7])
	if mode == "playing" and respawn_ms > 0:
		_respawn.text = "%d 秒后重生" % int(ceil(float(respawn_ms) / 1000.0))
		if header.size() > 11:
			var causes := {"trail": "路线被切断", "body": "撞到护盾", "territory": "领地被占完"}
			var cause := str(causes.get(header[10], ""))
			if not cause.is_empty(): _respawn.text += " · " + cause
		_respawn.show()
	if mode != "finished":
		return
	_winner.text = "本局冠军  " + header[8]
	_placement.text = "你获得第 %s 名  ·  占地 %0.1f%%  ·  得分 %s" % [header[2], float(header[4]), header[6]]
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for i in range(1, lines.size()):
		var values: PackedStringArray = lines[i].split("|")
		if values.size() < 9:
			continue
		var line := HBoxContainer.new()
		line.custom_minimum_size = Vector2(600, 30)
		line.add_theme_constant_override("separation", 8)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rows.add_child(line)
		var mine: bool = values[7] == "1"
		var color: Color = Color("008b8d") if mine else INK
		_add_cell(line, values[0], 55, color)
		_add_cell(line, values[2] + ("（你）" if mine else ""), 290, color)
		_add_cell(line, "%0.1f%%" % float(values[4]), 125, color)
		_add_cell(line, values[5], 70, color)

func _add_cell(parent: HBoxContainer, caption: String, width: float, color: Color) -> void:
	var label := Label.new()
	label.text = caption
	label.custom_minimum_size = Vector2(width, 30)
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
