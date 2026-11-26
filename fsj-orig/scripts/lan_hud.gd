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
var _cached_replay: Control = null
var _cached_login_btn: Control = null
var _last_replay_is_client: int = -1
var _login_anim_t: float = 0.0
var _login_btn_scale: float = 1.0
var _lan_btn_scale: float = 1.0
var _login_hovered: bool = false
var _login_pressed: bool = false
var _login_signals_bound: bool = false
const INK := Color("14364b")
const CREAM := Color("fff8df")
var font: Font = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")

class LoginButtonSheen extends Control:
	var phase: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		clip_contents = true

	func _draw() -> void:
		# Periodic soft diagonal light sweep across the button face (0.0..1.0 active window).
		if phase < 0.0 or phase > 1.0:
			return
		var w := size.x
		var h := size.y
		var cx := lerpf(-48.0, w + 48.0, phase)
		var alpha := sin(phase * PI) * 0.28
		var slant := 18.0
		var half_w := 18.0
		var poly := PackedVector2Array([
			Vector2(cx - half_w + slant, 5.0),
			Vector2(cx + half_w + slant, 5.0),
			Vector2(cx + half_w - slant, h - 10.0),
			Vector2(cx - half_w - slant, h - 10.0),
		])
		draw_colored_polygon(poly, Color(1.0, 1.0, 1.0, alpha))

class NativeLoginButton extends Button:
	var _tex: Texture2D = preload("res://assets/tex/fs_jm002.png")
	var _sys_font: SystemFont = null
	var _caption: String = ""

	func _init(caption_text: String) -> void:
		_caption = caption_text
		text = ""
		flat = true
		focus_mode = Control.FOCUS_NONE
		_sys_font = SystemFont.new()
		_sys_font.font_names = ["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "SimHei"]
		var empty := StyleBoxEmpty.new()
		for k in ["normal", "hover", "pressed", "focus", "disabled"]:
			add_theme_stylebox_override(k, empty)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
			queue_redraw()

	func _draw() -> void:
		if _tex == null:
			return
		var down := is_pressed()
		var hover := is_hovered() and not down
		var top_y := 6.0 if down else 1.0
		var bot_y := 101.0 if down else 102.0
		var h := bot_y - top_y
		var w := size.x
		var tint := Color(1.06, 1.06, 1.06, 1.0) if hover else Color.WHITE
		# Exact 3-slice coordinates from login.json -> denglu (fs_jm002.tex)
		draw_texture_rect_region(_tex, Rect2(0.0, top_y, 20.0, h), Rect2(229.0, 8.0, 20.0, 117.0), tint)
		draw_texture_rect_region(_tex, Rect2(20.0, top_y, maxf(0.0, w - 40.0), h), Rect2(252.0, 8.0, 1.0, 117.0), tint)
		draw_texture_rect_region(_tex, Rect2(w - 20.0, top_y, 20.0, h), Rect2(257.0, 8.0, 20.0, 117.0), tint)
		var fsize := 28
		var tsize := _sys_font.get_string_size(_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
		var tx := (w - tsize.x) * 0.5
		var ty := (8.0 + 49.0 * 0.5) + (_sys_font.get_ascent(fsize) - _sys_font.get_descent(fsize)) * 0.5 + (4.0 if down else 0.0)
		draw_string(_sys_font, Vector2(tx, ty), _caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color("fffef2"))

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
	entry = NativeLoginButton.new("局域网联机")
	entry.name = "LanEntryButton"
	entry.position = Vector2(652, 581)
	entry.size = Vector2(183, 75)
	entry.pivot_offset = entry.size * 0.5
	entry.pressed.connect(func(): opened = true)
	var lan_sheen := LoginButtonSheen.new()
	lan_sheen.name = "LoginButtonSheen"
	entry.add_child(lan_sheen)
	add_child(entry)
	entry.hide()
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
	description = label(panel, "同一 Wi-Fi 或有线局域网 · 无需密码\n最多 10 人，空位由 AI 补齐，默认 4 分钟", Vector2(30, 203), Vector2(678, 58), 19)
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

func _ensure_login_btn_fx(btn: Control) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	btn.pivot_offset = btn.size * 0.5
	if btn.get_node_or_null("LoginButtonSheen") == null:
		var sheen := LoginButtonSheen.new()
		sheen.name = "LoginButtonSheen"
		btn.add_child(sheen)
	if not _login_signals_bound:
		_login_signals_bound = true
		btn.mouse_entered.connect(func(): _login_hovered = true)
		btn.mouse_exited.connect(func(): _login_hovered = false; _login_pressed = false)
		btn.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
				_login_pressed = ev.pressed
			elif ev is InputEventScreenTouch:
				_login_pressed = ev.pressed)

func _animate_login_buttons(delta: float) -> void:
	if not entry.visible:
		return
	_login_anim_t += delta
	var k := 1.0 - exp(-22.0 * delta)
	var breath := 1.0 + 0.018 * sin(_login_anim_t * 2.6)
	var sweep_cycle := fmod(_login_anim_t, 3.2)
	var login_phase := sweep_cycle / 0.65 if sweep_cycle < 0.65 else -1.0
	var lan_sweep := fmod(_login_anim_t + 0.25, 3.2)
	var lan_phase := lan_sweep / 0.65 if lan_sweep < 0.65 else -1.0

	if _cached_login_btn != null and is_instance_valid(_cached_login_btn) and _cached_login_btn.is_visible_in_tree():
		_ensure_login_btn_fx(_cached_login_btn)
		var target_s := 0.93 if _login_pressed else (1.06 if _login_hovered else breath)
		_login_btn_scale = lerpf(_login_btn_scale, target_s, k)
		_cached_login_btn.scale = Vector2(_login_btn_scale, _login_btn_scale)
		_cached_login_btn.modulate = Color(1.07, 1.07, 1.07, 1.0) if (_login_hovered and not _login_pressed) else Color.WHITE
		var ls := _cached_login_btn.get_node_or_null("LoginButtonSheen") as LoginButtonSheen
		if ls != null:
			ls.phase = login_phase
			ls.queue_redraw()

	entry.pivot_offset = entry.size * 0.5
	var lan_target := 0.93 if entry.is_pressed() else (1.06 if entry.is_hovered() else breath)
	_lan_btn_scale = lerpf(_lan_btn_scale, lan_target, k)
	entry.scale = Vector2(_lan_btn_scale, _lan_btn_scale)
	var es := entry.get_node_or_null("LoginButtonSheen") as LoginButtonSheen
	if es != null:
		es.phase = lan_phase
		es.queue_redraw()

func _process(delta: float) -> void:
	_animate_login_buttons(delta)
	_poll_left -= delta
	if _poll_left > 0.0: return
	_poll_left = 0.1
	var in_game: bool = session.phase in ["playing", "finished", "loading"]
	var connected: bool = not session.role.is_empty()
	var should_show := not in_game and (opened or connected)
	if layer.visible != should_show:
		layer.visible = should_show
	if _cached_login_btn == null or not is_instance_valid(_cached_login_btn):
		_cached_login_btn = get_parent().find_child("denglu", true, false) as Control
	var on_login := _cached_login_btn != null and _cached_login_btn.is_visible_in_tree()
	var show_entry := not in_game and not should_show and on_login
	if show_entry:
		# Pair 登录 (left) and 局域网联机 (right) symmetrically on the 1280px login baseline.
		if absf(_cached_login_btn.position.x - 549.0) < 2.0:
			_cached_login_btn.position.x = 445.0
		entry.position = Vector2(652, 581)
		entry.size = Vector2(183, 75)
	if entry.visible != show_entry:
		entry.visible = show_entry
	if should_show:
		nick.editable = not connected
		ip.editable = not connected
		host_button.disabled = connected
		join_button.disabled = connected
		close_button.visible = not connected
		start_button.visible = session.role == "host"
		start_button.disabled = session.phase != "lobby"
		leave_button.visible = connected
		if status_label.text != session.status:
			status_label.text = session.status
		if connected:
			description.text = "房主 IP：%s\nUDP 27866 · 同一局域网 · 默认 4 分钟，时长由房主设置" % session.address
			var names := PackedStringArray()
			for member in session.members:
				names.append(str(member.nick) + ("（房主）" if int(member.peer) == 1 else ""))
			roster.text = "房间成员 %d/10：\n%s\n\n空余的 %d 个位置由 AI 补齐。" % [names.size(), "、".join(names), 10 - names.size()]
		else:
			description.text = "同一 Wi-Fi 或有线局域网 · 无需密码\n最多 10 人，空位由 AI 补齐，默认 4 分钟"
			roster.text = "先在大厅底部「技能」中配置技能，再创建或加入房间。"
	var is_client := 1 if session.role == "client" else 0
	if _cached_replay == null or not is_instance_valid(_cached_replay):
		_cached_replay = get_parent().find_child("RematchButton", true, false) as Control
		_last_replay_is_client = -1
	if _cached_replay != null and _last_replay_is_client != is_client:
		_last_replay_is_client = is_client
		_cached_replay.enable_wnd(is_client == 0)
		_cached_replay.set_wnd_text("等待房主再开" if is_client == 1 else "继续游戏")
