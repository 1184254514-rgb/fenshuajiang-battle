extends Control
var host: LuaHost
var session: Node
var entry: Button
var layer: ColorRect
var panel: Panel
var nick: LineEdit
var ip: LineEdit
var host_button: Button
var join_button: Button
var start_button: Button
var leave_button: Button
var close_button: Button
var description: Label
var roster: Label
var status_label: Label
var opened := false
var _poll_left := 0.0
const INK := Color("14364b")
const CREAM := Color("fff8df")
var font: Font = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

func style(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = INK
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	return box

func theme_control(control: Control, size: int = 22) -> void:
	control.add_theme_font_override("font", font)
	control.add_theme_font_size_override("font_size", size)
	control.add_theme_color_override("font_disabled_color", Color("718080"))
	for key in ["font_color", "font_hover_color", "font_pressed_color"]:
		control.add_theme_color_override(key, INK)

func label(parent: Node, text: String, pos: Vector2, extent: Vector2, size: int = 22) -> Label:
	var node := Label.new()
	node.text = text
	node.position = pos
	node.size = extent
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_control(node, size)
	parent.add_child(node)
	return node

func button(parent: Node, text: String, pos: Vector2, extent: Vector2, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = pos
	node.size = extent
	node.focus_mode = Control.FOCUS_NONE
	theme_control(node)
	node.add_theme_stylebox_override("normal", style(Color("ffd55a")))
	node.add_theme_stylebox_override("hover", style(Color("ffe58c")))
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func field(parent: Node, pos: Vector2, extent: Vector2, placeholder: String) -> LineEdit:
	var node := LineEdit.new()
	node.position = pos
	node.size = extent
	node.placeholder_text = placeholder
	theme_control(node)
	node.add_theme_stylebox_override("normal", style(Color.WHITE))
	node.add_theme_stylebox_override("focus", style(Color("e0fff2")))
	node.add_theme_stylebox_override("read_only", style(Color("e9e8d9")))
	node.add_theme_color_override("font_uneditable_color", INK)
	parent.add_child(node)
	return node

func _ready() -> void:
	name = "LanHud"
	session = host.lan_session
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 3100
	entry = button(self, "局域网联机", Vector2(485, 628), Vector2(188, 64), func(): opened = true)
	entry.name = "LanEntryButton"
	layer = ColorRect.new()
	layer.color = Color(0.025, 0.08, 0.15, 0.72)
	layer.size = Vector2(1280, 720)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(layer)
	panel = Panel.new()
	panel.position = Vector2(270, 85)
	panel.size = Vector2(740, 552)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", style(CREAM))
	layer.add_child(panel)
	label(panel, "局域网 · 一起粉刷", Vector2(28, 18), Vector2(620, 48), 32)
	close_button = button(panel, "×", Vector2(676, 16), Vector2(42, 40), func(): opened = false)
	label(panel, "昵称", Vector2(30, 86), Vector2(90, 42))
	nick = field(panel, Vector2(122, 86), Vector2(312, 44), "随便取个名字")
	nick.max_length = 16
	nick.text = "画匠" + str(randi_range(100, 999))
	label(panel, "房主 IP", Vector2(30, 144), Vector2(100, 42))
	ip = field(panel, Vector2(136, 144), Vector2(298, 44), "例如 192.168.1.8")
	host_button = button(panel, "创建房间", Vector2(464, 85), Vector2(244, 46), func(): session.create_room(nick.text))
	host_button.name = "CreateLanRoomButton"
	join_button = button(panel, "加入房间", Vector2(464, 143), Vector2(244, 46), func(): session.join_room(nick.text, ip.text))
	join_button.name = "JoinLanRoomButton"
	description = label(panel, "同一 Wi-Fi 或有线局域网 · 无需密码\n最多 10 人，空位由 AI 补齐，每局 4 分钟", Vector2(30, 203), Vector2(678, 58), 19)
	roster = label(panel, "先在大厅底部「技能」中配置技能，再创建或加入房间。", Vector2(30, 273), Vector2(678, 141), 20)
	roster.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roster.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	status_label = label(panel, "", Vector2(30, 419), Vector2(678, 59), 18)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button = button(panel, "开始 4 分钟比赛", Vector2(30, 488), Vector2(420, 43), func(): session.start_match())
	start_button.name = "StartLanMatchButton"
	leave_button = button(panel, "离开房间", Vector2(472, 488), Vector2(236, 43), func(): session.leave_room())
	layer.hide()
	if "--lan" in OS.get_cmdline_user_args() or OS.has_feature("lan_build"): opened = true

func _process(delta: float) -> void:
	_poll_left -= delta
	if _poll_left > 0.0: return
	_poll_left = 0.1
	var in_game: bool = session.phase in ["playing", "finished", "loading"]
	var connected: bool = not session.role.is_empty()
	layer.visible = not in_game and (opened or connected)
	var original_modal: bool = host.lua.do_string("local h=g_App and g_App:GetGameStart();local w=h and rawget(h,'m_pWndNewSeasonComing');return w and w:IsShow() or false") == true
	entry.visible = not original_modal and not in_game and not layer.visible and host.lua.do_string("return not (g_App and g_App.__scene)") == true
	nick.editable = not connected
	ip.editable = not connected
	host_button.disabled = connected
	join_button.disabled = connected
	close_button.visible = not connected
	start_button.visible = session.role == "host"
	start_button.disabled = session.phase != "lobby"
	leave_button.visible = connected
	status_label.text = session.status
	if connected:
		description.text = "房主 IP：%s\nUDP 27866 · 同一局域网 · 每局 4 分钟" % session.address
		var names := PackedStringArray()
		for member in session.members:
			names.append(str(member.nick) + ("（房主）" if int(member.peer) == 1 else ""))
		roster.text = "房间成员 %d/10：\n%s\n\n空余的 %d 个位置由 AI 补齐。" % [names.size(), "、".join(names), 10 - names.size()]
	else:
		description.text = "同一 Wi-Fi 或有线局域网 · 无需密码\n最多 10 人，空位由 AI 补齐，每局 4 分钟"
		roster.text = "先在大厅底部「技能」中配置技能，再创建或加入房间。"
	var replay := get_parent().find_child("RematchButton", true, false) as Button
	if replay != null:
		replay.disabled = session.role == "client"
		replay.text = "等待房主再开" if session.role == "client" else "再来一局"
