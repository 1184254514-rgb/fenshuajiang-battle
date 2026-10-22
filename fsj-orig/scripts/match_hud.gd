class_name MatchHud
extends Control
# Presentation for the local timed mode; Lua owns every rule and deadline.
# Fixed 1280x720 canvas follows the original game's stretch transform.
var host: LuaHost
var _respawn: Label
var _finish_layer: ColorRect
var _result_frame: Control
var _pages: Array[Control] = []
var _tabs: Array[Control] = []
var _scroll: ScrollContainer
var _rows: VBoxContainer
var _last_state: String = ""
var _poll_left: float = 0.0
var _font: Font = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")
const INK := Color("14364b")

func _ready() -> void:
	name = "MatchHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 3000
	_build_respawn()
	_build_results()
	_respawn.hide()
	_finish_layer.hide()

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

func _build_respawn() -> void:
	_respawn = _text(self, "3 秒后重生", Vector2(390, 280), Vector2(500, 72), 36, Color.WHITE)
	_respawn.name = "MatchRespawn"
	_respawn.add_theme_color_override("font_outline_color", INK)
	_respawn.add_theme_constant_override("outline_size", 9)

# Build the authored APK settlement frame and its three pages. Only hidden
# replay placement is adapted to make the existing local/LAN flow available.
func _build_results() -> void:
	_finish_layer = ColorRect.new()
	_finish_layer.name = "MatchResults"
	_finish_layer.color = Color(0.025, 0.08, 0.15, 0.9)
	_finish_layer.size = Vector2(1280, 720)
	_finish_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_finish_layer)
	_result_frame = GuiRuntime.build("fsj_xianshimoshi")
	_finish_layer.add_child(_result_frame)
	for path in ["btn_jietu", "tips", "btn_zuo/btn4"]:
		_result_frame.get_node(path).hide()
	for path in ["btn_zuo/btn_2/xinjilu", "btn_zuo/btn_3/xinjilu"]:
		_result_frame.get_node(path).hide()
	# The APK authors this at x=7620 (offscreen). Local timed play exposes it
	# alongside the original home button; no official queue/server is called.
	var replay = _result_frame.get_node("btn_jixuyouxi")
	replay.position.x = 762
	replay.name = "RematchButton"
	_bind(replay, func(): _action("SceneMatch.Rematch()"))
	var home = _result_frame.get_node("btn_huizhujiemian")
	home.name = "MatchHomeButton"
	_bind(home, func(): _action("SceneMatch.ReturnHome()"))
	var resources = ["fsj_xianshimoshi_benjupaiming", "fsj_xianshimoshi_gerenjifen", "fsj_xianshimoshi_jiezoutongji"]
	for resource in resources:
		var page = GuiRuntime.build(resource)
		_result_frame.get_node("list").add_child(page)
		_pages.append(page)
	for i in 3:
		var tab = _result_frame.get_node("btn_zuo/" + ["btn_1", "btn_2", "btn_3"][i])
		_tabs.append(tab)
		_bind(tab, _select_page.bind(i))
	# These resource controls intentionally sit offscreen in the original.
	# No unavailable friend/report/share/coin or ladder service is connected.
	_pages[0].get_node("jinbi").hide()
	_pages[0].get_node("duanwei").hide()
	var list = _pages[0].get_node("list")
	list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll = ScrollContainer.new()
	_scroll.name = "RankingScroll"
	_scroll.size = list.size
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list.add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 0)
	_scroll.add_child(_rows)
	for path in ["bg_benjudefen", "bg_tijidefen", "bg_jishadefen", "bg_lianjidefen"]:
		_pages[1].get_node(path + "/jilu").hide()
	for path in ["list1", "list2"]:
		_pages[1].get_node(path).hide()
	for path in ["kong1", "kong2"]:
		_pages[1].get_node(path).set_wnd_text("本局未记录逐次明细")
	for path in ["jiaoxue", "bg_lianjijilu", "bg_jinriizuijia", "bg_pingjia", "tongji/pingjia", "tongji/W_pingjia"]:
		_pages[2].get_node(path).hide()
	_pages[2].get_node("E_pingjia").hide()
	_select_page(0)

func _bind(control: Control, action: Callable) -> void:
	# Use the actual authored widget, retaining its pressed/disabled textures.
	var pointer := {"down": false}
	control.gui_input.connect(func(event: InputEvent):
		if not control.is_enable():
			pointer.down = false
			return
		if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT: return
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.pressed: pointer.down = true
			else:
				if pointer.down and Rect2(Vector2.ZERO, control.size).has_point(event.position): action.call_deferred()
				pointer.down = false
	)

func _select_page(index: int) -> void:
	for i in _pages.size():
		_pages[i].visible = i == index
		_tabs[i].set_check(i == index)

func _fill_results(lines: PackedStringArray) -> void:
	var stats = JSON.parse_string(str(host.lua.do_string("return SceneMatch.SettlementDataJSON()")))
	if not stats is Dictionary: return
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for i in range(1, lines.size()):
		var values := lines[i].split("|")
		if values.size() < 9: continue
		var mine := values[7] == "1"
		var row = GuiRuntime.build("fsj_xianshimoshi_benjupaiming_item2" if mine else "fsj_xianshimoshi_benjupaiming_item1")
		row.custom_minimum_size = Vector2(965, 89)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.set_meta("object_id", int(values[1]))
		row.set_meta("director", mine)
		_rows.add_child(row)
		for path in ["b_guanzhu", "b_zhuangtai", "jinbi", "icon_duanwei", "zan", "jubao", "wanjiaxinxi"]:
			row.get_node(path).hide()
		for rank in 3: row.get_node("No_" + str(rank + 1)).visible = i == rank + 1
		row.get_node("paiming").visible = i > 3
		row.get_node("paiming").set_wnd_text(str(i))
		row.get_node("name").set_wnd_text(values[2])
		row.get_node("defen").set_wnd_text(values[6])
		var head = row.get_node("head/touxiang")
		var crop: Array = stats.get("avatars", {}).get(values[1], [])
		if crop.size() == 4:
			var atlas := AtlasTexture.new()
			atlas.atlas = GuiRuntime.atlas("fs_jm003.tex")
			atlas.region = Rect2(float(crop[0]), float(crop[1]), float(crop[2])-float(crop[0]), float(crop[3])-float(crop[1]))
			var avatar := TextureRect.new()
			avatar.name = "EquippedAvatar"
			avatar.texture = atlas
			avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			avatar.size = head.size
			avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			head.add_child(avatar)
		row.get_node("head").mouse_filter = Control.MOUSE_FILTER_IGNORE
	for pair in [["E_benju","total"], ["E_tiji","area"], ["E_jisha","kill"], ["E_lianji","combo"]]:
		_pages[1].get_node(pair[0]).set_wnd_text(str(int(stats.get(pair[1], 0))))
	_pages[1].get_node("jishacishu").set_wnd_text("击杀次数：%d" % int(stats.get("kills",0)))
	_pages[1].get_node("beijishacishu").set_wnd_text("被击杀次数：%d" % int(stats.get("deaths",0)))
	var counts: Array = stats.get("counts", [0,0,0,0])
	var beats := int(stats.get("beats", 0))
	for i in 4:
		_pages[2].get_node("tongji/E_" + str(i+1)).set_wnd_text("%.2f" % (100.0 * int(counts[i]) / beats if beats > 0 else 0.0))
	_pages[2].get_node("tongji/E_lianjijiangli").set_wnd_text(str(int(stats.get("maxCombo", 0))))
	var seconds := int(stats.get("seconds", 0))
	_pages[2].get_node("tongji/E_time").set_wnd_text("%02d:%02d:%02d" % [seconds/3600,(seconds/60)%60,seconds%60])
	_scroll.scroll_vertical = 0
	_select_page(0)

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
	_fill_results(lines)
