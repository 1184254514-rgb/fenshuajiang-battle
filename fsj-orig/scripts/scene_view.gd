class_name SceneView
extends Node2D
# 2D placeholder renderer for the in-game world (CGameScene) + rhythm clock/audio. The simulation lives in Lua
# (lua/natives/scene.lua); it pushes cell/player changes here. Drawn BEHIND the original UI windows. Claude.

const NODE := 16.0                 # world pixels per grid node
const ZOOM := 2.0                  # screen pixels per world pixel
# original manor colours: config/colourtable.txt order, RGB sampled from map/colour/peise.bmp (dark / mid / light columns)
const PALETTE: Array[int] = [
	0xFFCB5958, 0xFFBE427D, 0xFF8E64A2, 0xFF5597FD, 0xFF7ED4D1,
	0xFF48A87A, 0xFF93B945, 0xFFFFDD46, 0xFFDD9308, 0xFFFD7738,
]
const PALETTE_DARK: Array[int] = [0xA64346, 0x864172, 0x6D4F82, 0x4270B0, 0x4EA6BE, 0x418959, 0x76983A, 0xCAAF3E, 0xC07E00, 0xDD6A33]
const PALETTE_LIGHT: Array[int] = [0xFE837E, 0xE166A1, 0xC08CD4, 0x68CBF5, 0xAAF8E8, 0x5DD496, 0xA8DA50, 0xFFFF45, 0xEBAC00, 0xFF9E50]

var active := false
var gw := 0
var gh := 0
var owner_cells := PackedInt32Array()
var trail_cells := PackedInt32Array()
var players: Dictionary = {}       # id -> {x, y, color, name, alive, director}
var follow_id := -1
var cam := Vector2(960, 960)
var on_dir: Callable = Callable()  # called with eDF_* when a direction key is pressed
var on_trace: Callable = Callable() # Space: quick trace-back (natives/scene_move.lua NativeKeyTraceBack)
var on_skill: Callable = Callable() # Q / Space uses the selected active skill.

# rhythm / music
var beats := PackedFloat64Array()
var music_player: AudioStreamPlayer
var music_t0_ms := 0
var music_playing := false
var grade_text := ""
var grade_age := 0.0
var grade_color := Color.WHITE
var _font: Font

# HUD bridge (lua/natives/gamemain.lua; GPT design, adapted by Claude)
const HUD_FX_SCRIPT = preload("res://scripts/hud_fx.gd")
var hud_fx: Node
var hud_ui_root: Control
var camera_zoom: float = ZOOM
var camera_offset := Vector2.ZERO
var rhythm_visible := false
var rhythm_notice_bar_id := 0
var music_paused := false
var music_pause_started_ms := 0
var music_pause_position_ms := 0.0

func _ready() -> void:
	z_index = -10
	hud_fx = HUD_FX_SCRIPT.new()
	hud_fx.name = "HudFx"
	add_child(hud_fx)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	set_process(false)
	set_process_unhandled_key_input(true)

func _get_font() -> Font:
	if _font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "PingFang SC", "sans-serif"])
		_font = f
	return _font

# ---------------------------------------------------------------- world state (called from Lua)
func begin_scene(w: int, h: int) -> void:
	camera_zoom = ZOOM
	camera_offset = Vector2.ZERO
	rhythm_visible = false
	grade_text = ""
	grade_age = 1.0
	gw = w; gh = h
	owner_cells = PackedInt32Array(); owner_cells.resize(w * h)
	trail_cells = PackedInt32Array(); trail_cells.resize(w * h)
	players.clear()
	follow_id = -1
	active = true
	visible = true
	set_process(true)
	queue_redraw()

func end_scene() -> void:
	rhythm_visible = false
	active = false
	stop_music()
	set_process(false)
	players.clear()
	queue_redraw()

func set_cell(idx: int, owner: int, trail: int) -> void:
	if idx < 0 or idx >= owner_cells.size():
		return
	owner_cells[idx] = owner
	trail_cells[idx] = trail

func set_player(id: int, x: float, y: float, color_id: int, nick: String, alive: bool, is_director: bool) -> void:
	players[id] = {"x": x, "y": y, "color": color_id, "name": nick, "alive": alive, "director": is_director}
	if is_director and follow_id == -1:
		follow_id = id

var area_ratio := 0.0
var room_type := 0   # scene room type (0 endless; 2/8/10 team kinds), set by natives/scene.lua
func set_area_ratio(r: float) -> void:
	area_ratio = r

func set_follow(id: int) -> void:
	follow_id = id
	if players.has(id):
		cam = Vector2(players[id]["x"], players[id]["y"])

func palette_argb(id: int) -> int:
	return PALETTE[posmod(id, PALETTE.size())]

func _color_of(color_id: int) -> Color:
	return Color.hex(((PALETTE[posmod(color_id, PALETTE.size())] & 0xFFFFFF) << 8) | 0xFF)

# ---------------------------------------------------------------- music and rhythm
var music_row: Dictionary = {}     # the config/music.txt row of the playing song (rhythm judgement parameters)

func music_param(name: String) -> String:
	return str(music_row.get(name, ""))

func beat_count() -> int:
	return beats.size()

func beat_at(i: int) -> float:
	return beats[i] if i >= 0 and i < beats.size() else -1.0

func start_music(music_path: String, rhythm_path: String) -> void:
	stop_music()
	beats = PackedFloat64Array()
	var rp := "res://data/orig/" + rhythm_path
	if not FileAccess.file_exists(rp):
		rp = "res://data/orig/config/" + rhythm_path   # music.txt says rhythm/x.txt; the files ship under config/rhythm
	if FileAccess.file_exists(rp):
		var f := FileAccess.open(rp, FileAccess.READ)
		var n := 0
		while not f.eof_reached() and n < 4000:
			var line := f.get_line().strip_edges()
			if line == "":
				continue
			var parts := line.split("\t") if line.contains("\t") else line.split(" ")
			if parts.size() >= 1 and parts[0].is_valid_float():
				beats.append(parts[0].to_float())
				n += 1
	var mp := "res://data/orig/" + music_path
	if FileAccess.file_exists(mp):
		var s := AudioStreamMP3.new()
		s.data = FileAccess.get_file_as_bytes(mp)
		s.loop = true
		music_player.stream = s
		music_player.play()
	music_t0_ms = Time.get_ticks_msec()
	music_playing = true

func stop_music() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream_paused = false
	music_playing = false
	music_paused = false
	music_pause_started_ms = 0
	music_pause_position_ms = 0.0

func music_ms() -> float:
	if music_paused:
		return music_pause_position_ms
	if music_player != null and music_player.playing:
		return (music_player.get_playback_position() + AudioServer.get_time_since_last_mix()) * 1000.0
	return float(Time.get_ticks_msec() - music_t0_ms)

func judge_click() -> int:
	# 1 perfect, 2 excellent, 3 ordinary, 4 fault, by the distance (ms) to the nearest beat
	if beats.is_empty():
		return 3
	var t := music_ms()
	var best := 1.0e9
	for b in beats:
		var d := absf(b - t)
		if d < best:
			best = d
		if b > t + 600.0:
			break
	if best <= 55.0:
		return 1
	if best <= 120.0:
		return 2
	if best <= 190.0:
		return 3
	return 4

func show_grade(grade: int, combo: int) -> void:
	var names := ["", "PERFECT", "GREAT", "GOOD", "MISS"]
	var cols := [Color.WHITE, Color(1, 0.85, 0.2), Color(0.4, 1, 0.5), Color(0.5, 0.8, 1), Color(1, 0.35, 0.35)]
	grade_text = "%s%s" % [names[grade], ("  x%d" % combo) if combo > 1 and grade < 4 else ""]
	grade_color = cols[grade]
	grade_age = 0.0

# ---------------------------------------------------------------- input
func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var d := 0
	match event.keycode:
		KEY_LEFT, KEY_A: d = 1
		KEY_RIGHT, KEY_D: d = 2
		KEY_UP, KEY_W: d = 4
		KEY_DOWN, KEY_S: d = 8
	if event.keycode in [KEY_Q, KEY_SPACE] and on_skill.is_valid():
		on_skill.call()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_SPACE and on_trace.is_valid():
		on_trace.call()
		get_viewport().set_input_as_handled()
		return
	if d != 0 and on_dir.is_valid():
		on_dir.call(d)
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- drawing
func _process(delta: float) -> void:
	if not active:
		return
	if players.has(follow_id):
		var p: Dictionary = players[follow_id]
		cam = cam.lerp(Vector2(p["x"], p["y"]), clampf(delta * 8.0, 0.0, 1.0))
	grade_age += delta
	queue_redraw()

func world_to_screen(x: float, y: float) -> Vector2:
	var point: Vector2 = get_global_transform_with_canvas() * _to_screen(Vector2(x, y))
	return _canvas_to_ui(point)

func _canvas_to_ui(point: Vector2) -> Vector2:
	if is_instance_valid(hud_ui_root):
		return hud_ui_root.get_global_transform_with_canvas().affine_inverse() * point
	return point

func set_ui_root(root: Control) -> void:
	hud_ui_root = root
	if is_instance_valid(hud_fx):
		hud_fx.set_ui_root(root)

func get_camera_scale() -> float:
	return camera_zoom

func set_camera_scale(value: float) -> void:
	camera_zoom = clampf(value, 0.1, 16.0)
	queue_redraw()

func add_camera_offset(x: float, y: float) -> void:
	camera_offset += Vector2(x, y)
	queue_redraw()

func start_rhythm(notice_bar_id: int) -> void:
	rhythm_notice_bar_id = notice_bar_id
	grade_text = ""
	grade_age = 1.0
	queue_redraw()

func set_rhythm_visible(value: bool) -> void:
	rhythm_visible = value
	queue_redraw()

func set_music_paused(value: bool) -> void:
	if music_paused == value:
		return
	if value:
		music_pause_position_ms = music_ms()
		music_pause_started_ms = Time.get_ticks_msec()
		music_paused = true
	else:
		music_t0_ms += Time.get_ticks_msec() - music_pause_started_ms
		music_paused = false
	if music_player != null:
		music_player.stream_paused = value
	queue_redraw()

func _to_screen(wp: Vector2) -> Vector2:
	return (wp - cam - camera_offset) * camera_zoom + Vector2(640, 360)

func _draw() -> void:
	if not active:
		return
	var view_w := 1280.0 / camera_zoom
	var view_h := 720.0 / camera_zoom
	# ground
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280, 720)), Color(0.78, 0.86, 0.93))
	var world := Rect2(_to_screen(Vector2.ZERO), Vector2(gw, gh) * NODE * camera_zoom)
	draw_rect(world, Color(0.93, 0.97, 1.0))
	var center: Vector2 = cam + camera_offset
	var x0 := maxi(0, int((center.x - view_w * 0.5) / NODE) - 1)
	var x1 := mini(gw - 1, int((center.x + view_w * 0.5) / NODE) + 1)
	var y0 := maxi(0, int((center.y - view_h * 0.5) / NODE) - 1)
	var y1 := mini(gh - 1, int((center.y + view_h * 0.5) / NODE) + 1)
	var cs := NODE * camera_zoom
	# light grid
	for gx in range(x0, x1 + 2):
		var sx := _to_screen(Vector2(gx * NODE, 0)).x
		draw_line(Vector2(sx, 0), Vector2(sx, 720), Color(0.85, 0.9, 0.96), 1.0)
	for gy in range(y0, y1 + 2):
		var sy := _to_screen(Vector2(0, gy * NODE)).y
		draw_line(Vector2(0, sy), Vector2(1280, sy), Color(0.85, 0.9, 0.96), 1.0)
	# territory and trails
	for gy in range(y0, y1 + 1):
		for gx in range(x0, x1 + 1):
			var idx := gy * gw + gx
			var o := owner_cells[idx]
			var t := trail_cells[idx]
			var rect := Rect2(_to_screen(Vector2(gx * NODE, gy * NODE)), Vector2(cs, cs))
			if o != 0:
				var c := _color_of(o - 1)
				c.a = 0.85
				draw_rect(rect.grow(-0.5), c)
			if t != 0 and players.has(t):
				var tc := _color_of(int(players[t]["color"]))
				tc = tc.lightened(0.35); tc.a = 0.9
				draw_rect(rect.grow(-cs * 0.2), tc)
	# world border
	draw_rect(world, Color(0.25, 0.3, 0.45), false, 3.0)
	# players
	var font := _get_font()
	for id in players:
		var pl: Dictionary = players[id]
		if not pl["alive"]:
			continue
		var sp := _to_screen(Vector2(pl["x"], pl["y"]))
		var col := _color_of(int(pl["color"]))
		var half := cs * 0.55
		draw_rect(Rect2(sp - Vector2(half, half), Vector2(half * 2, half * 2)), col.darkened(0.35))
		draw_rect(Rect2(sp - Vector2(half - 3, half - 3), Vector2((half - 3) * 2, (half - 3) * 2)), col.lightened(0.15))
		draw_circle(sp + Vector2(-5, -3), 3.0, Color.WHITE)
		draw_circle(sp + Vector2(5, -3), 3.0, Color.WHITE)
		draw_string(font, sp + Vector2(-60, -half - 8), String(pl["name"]), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 18,
			Color(0.1, 0.1, 0.2) if not pl["director"] else Color(0.8, 0.1, 0.1))
	_draw_rhythm(font)

func _draw_rhythm(font: Font) -> void:
	if not music_playing or not rhythm_visible:
		return
	# beat bar at the bottom centre: upcoming beats slide towards the centre marker
	var t := music_ms()
	var y := 690.0
	var cx := 640.0
	draw_line(Vector2(cx - 300, y), Vector2(cx + 300, y), Color(1, 1, 1, 0.5), 3.0)
	for b in beats:
		var dt := (b - t) / 1000.0
		if dt < -0.4:
			continue
		if dt > 1.5:
			break
		var x := cx + dt * 220.0
		var a := clampf(1.0 - absf(dt) / 1.5, 0.15, 1.0)
		draw_rect(Rect2(x - 3, y - 12, 6, 24), Color(1, 0.9, 0.3, a))
	draw_rect(Rect2(cx - 4, y - 18, 8, 36), Color(1, 1, 1, 0.9), false, 2.0)
	if grade_age < 0.8:
		var a2 := 1.0 - grade_age / 0.8
		var c := grade_color
		c.a = a2
		draw_string(font, Vector2(cx - 150, 650 - grade_age * 30.0), grade_text, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 34, c)
