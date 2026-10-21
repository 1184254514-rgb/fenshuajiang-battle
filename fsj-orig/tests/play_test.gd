extends Node
# Drives the real main scene with synthetic mouse/keyboard input like a player would: click the login edit box, type a
# name, click OK, click the "自嗨" card, then steer with arrow keys. Saves screenshots along the way.
var main: Node
var t := 0.0
var step := 0
var out := "C:/Users/Administrator/Desktop/gpt-collab-gamedev/mod-work/shots/"

func _ready() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)

func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed; e.position = pos; e.global_position = pos
		Input.parse_input_event(e)

func _key(k: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k; e.pressed = pressed
		Input.parse_input_event(e)

func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(out + n + ".png")
	print("shot ", n)

func _wnd_pos(lua_expr: String) -> Vector2:
	var r = main.host.lua.do_string("local w = " + lua_expr + " if not w or not w.__node then return nil end local n = w.__node local p = n.global_position local s = n.size return string.format('%f,%f', p.x + s.x / 2, p.y + s.y / 2)")
	if r == null or r is LuaError:
		print("wnd_pos failed: ", lua_expr, " ", r)
		return Vector2(-1, -1)
	var parts := str(r).split(",")
	return Vector2(float(parts[0]), float(parts[1]))

func _process(delta: float) -> void:
	t += delta
	match step:
		0:
			if t > 3.0:
				_shot("play0_login")
				var p := _wnd_pos("g_App:GetLoginFrame().m_pBtnLogin")   # SDK layout: green "denglu" button
				print("login btn at ", p)
				_click(p)
				step = 3
				t = 4.0
		1:
			if t > 3.5:
				for c in "player1":
					var e := InputEventKey.new(); e.unicode = c.unicode_at(0); e.keycode = OS.find_keycode_from_string(c.to_upper()); e.pressed = true
					Input.parse_input_event(e)
				step = 2
		2:
			if t > 4.0:
				_shot("play1_typed")
				var p := _wnd_pos("g_App:GetLoginFrame().m_pBtnOK")
				print("ok at ", p)
				_click(p)
				step = 3
		3:
			if t > 6.0:
				_shot("play2_home")
				var p := _wnd_pos("g_App:GetGameStart().m_pBtnEndless")
				print("endless btn at ", p)
				if p.x > 0: _click(p)
				step = 4
		4:
			if t > 8.0:
				_shot("play3_enter")
				step = 5
		5:
			if t > 10.25 and not has_meta("mid_shot"):
				set_meta("mid_shot", true)
				_shot("play4_keys")
			if t > 9.0 and t < 15.0:
				if int(t * 2) % 3 == 0: _key(KEY_UP)
				elif int(t * 2) % 3 == 1: _key(KEY_RIGHT)
				else: _key(KEY_DOWN)
			if t > 15.0:
				_shot("play4_game")
				print(main.host.lua.do_string("local sc = g_App.__scene if not sc then return 'no scene' end local d = g_App:GetDirector() return 'alive=' .. tostring(d and d.__alive) .. ' count=' .. tostring(d and d.__manor.count)"))
				get_tree().quit()
