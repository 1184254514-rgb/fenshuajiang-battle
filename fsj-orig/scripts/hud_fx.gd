class_name HudFx
extends Node
# Presentation only. Lua owns effect deadlines and completion dispatch.
# Tween cancellation, hidden windows and freed Controls cannot lose Lua timers.

var ui_root: Control
var _states: Dictionary = {}
var _tooltip_slots: Dictionary = {}
var _tooltip_panel: PanelContainer = null
var _tooltip_title: Label = null
var _tooltip_tag: Label = null
var _tooltip_effect: Label = null
var _tooltip_desc: Label = null
var _tooltip_font: Font = preload("res://fonts/ZCOOLKuaiLe-Regular.ttf")
var _press_slot_key: String = ""
var _press_origin: Vector2 = Vector2.ZERO
var _press_elapsed: float = 0.0
var _press_shown: bool = false
var _press_touch_index: int = -1
var _active_long_pressed: bool = false
const SKILL_LONG_PRESS_SEC := 0.25
const SKILL_DRAG_CANCEL_PX := 48.0


class EffectMark extends Control:
	var caption: String = ""
	var flying: bool = false

	func _draw() -> void:
		var center: Vector2 = size * 0.5
		if flying:
			draw_circle(center, 5.0, Color(1.0, 0.86, 0.25, 0.95))
			draw_circle(center, 9.0, Color(1.0, 0.86, 0.25, 0.25))
			return

		if caption.is_empty():
			var radius: float = clampf(minf(size.x, size.y) * 0.32, 5.0, 24.0)
			draw_arc(center, radius, 0.0, TAU, 32,
				Color(1.0, 0.92, 0.55, 0.8), 2.0, true)
		else:
			var font: Font = ThemeDB.fallback_font
			var font_size: int = clampi(int(size.y * 0.65), 20, 48)
			var width: float = font.get_string_size(
				caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font,
				Vector2(center.x - width * 0.5, center.y + font_size * 0.35),
				caption, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				Color(1.0, 0.92, 0.55))


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)


func set_ui_root(root: Control) -> void:
	ui_root = root


func _window(state: Dictionary) -> Control:
	var reference: WeakRef = state.get("window") as WeakRef
	if reference == null:
		return null
	return reference.get_ref() as Control


func _state(window: Control) -> Dictionary:
	if not is_instance_valid(window):
		return {}

	var id: int = window.get_instance_id()
	if _states.has(id):
		return _states[id]

	var state: Dictionary = {
		"id": id,
		"window": weakref(window),
		"base_scale": window.scale,
		"base_alpha": window.modulate.a,
		"fx_scale": 1.0,
		"fx_alpha": 1.0,
		"show_alpha": 1.0,
		"last_scale": window.scale,
		"last_alpha": window.modulate.a,
		"shown": window.visible,
		"show_serial": 0,
		"fx_token": 0,
		"fx_tween": null,
		"show_tween": null,
		"move_tween": null,
		"marker": null,
		"progress": null,
	}
	_states[id] = state
	return state


func _kill_tween(state: Dictionary, key: String) -> void:
	var tween: Tween = state.get(key) as Tween
	if tween != null and tween.is_valid():
		tween.kill()
	state[key] = null


func _sync_external_changes(state: Dictionary) -> void:
	var window: Control = _window(state)
	if not is_instance_valid(window):
		return

	var last_scale: Vector2 = state["last_scale"]
	var actual_scale: Vector2 = window.scale
	if not actual_scale.is_equal_approx(last_scale):
		var factor: float = maxf(0.000001, float(state["fx_scale"]))
		state["base_scale"] = actual_scale / factor

	var actual_alpha: float = window.modulate.a
	if not is_equal_approx(actual_alpha, float(state["last_alpha"])):
		var factor: float = float(state["fx_alpha"]) * float(state["show_alpha"])
		state["base_alpha"] = actual_alpha / factor if factor > 0.000001 else actual_alpha


func _apply(state: Dictionary) -> void:
	var window: Control = _window(state)
	if not is_instance_valid(window):
		return

	_sync_external_changes(state)
	var base_scale: Vector2 = state["base_scale"]
	window.scale = base_scale * float(state["fx_scale"])

	var tint: Color = window.modulate
	tint.a = clampf(float(state["base_alpha"]) *
		float(state["fx_alpha"]) * float(state["show_alpha"]), 0.0, 1.0)
	window.modulate = tint

	state["last_scale"] = window.scale
	state["last_alpha"] = tint.a


func _remove_marker(state: Dictionary) -> void:
	var marker: Control = state.get("marker") as Control
	if is_instance_valid(marker):
		marker.hide()
		marker.queue_free()
	state["marker"] = null


func _stop_effect_state(state: Dictionary) -> void:
	_sync_external_changes(state)
	_kill_tween(state, "fx_tween")
	_remove_marker(state)
	state["fx_token"] = 0
	state["fx_scale"] = 1.0
	state["fx_alpha"] = 1.0
	_apply(state)


func play_effect(window: Control, token: int, duration_ms: float,
		caption: String, strength: float, flying: bool) -> bool:
	var state: Dictionary = _state(window)
	if state.is_empty() or not is_inside_tree():
		return false

	# One visual pulse per Control; every logical effect retains its own Lua timer.
	_stop_effect_state(state)
	state["fx_token"] = token
	state["strength"] = clampf(strength, 0.0, 4.0)
	window.pivot_offset = window.size * 0.5

	var marker := EffectMark.new()
	marker.caption = caption
	marker.flying = flying
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.focus_mode = Control.FOCUS_NONE
	window.add_child(marker)
	marker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	state["marker"] = marker
	marker.queue_redraw()

	# Long logical effects still use a short visual placeholder.
	var seconds: float = clampf(duration_ms / 1000.0, 0.001, 0.6)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	state["fx_tween"] = tween
	tween.tween_method(_pulse.bind(int(state["id"]), token), 0.0, 1.0, seconds)
	tween.finished.connect(_finish_effect.bind(int(state["id"]), token))
	return true


func _pulse(progress: float, id: int, token: int) -> void:
	if not _states.has(id):
		return
	var state: Dictionary = _states[id]
	if int(state["fx_token"]) != token:
		return

	_sync_external_changes(state)
	var wave: float = sin(progress * PI)
	state["fx_scale"] = 1.0 + 0.12 * float(state["strength"]) * wave
	state["fx_alpha"] = 1.0 - 0.32 * wave
	_apply(state)


func _finish_effect(id: int, token: int) -> void:
	if not _states.has(id):
		return
	var state: Dictionary = _states[id]
	if int(state["fx_token"]) != token:
		return
	state["fx_tween"] = null
	_stop_effect_state(state)


# Original .eft playback for CGWnd:AddEffect (Claude): effect centred on the window, freed by stop_effect or
# when it ends (loop effects run until stopped).
var _eft_nodes: Dictionary = {}     # token -> Node

func play_eft(window: Control, token: int, file_name: String, effect_name: String, loop: bool) -> bool:
	if not is_instance_valid(window):
		return false
	var stem := file_name.get_file().get_basename().to_lower()
	if not FileAccess.file_exists("res://assets/fx/%s.json" % stem):
		return false
	var node = EffectPlayer.spawn_ui(window, stem, effect_name, window.size * 0.5, 1.0, loop)
	if node == null:
		return false
	_eft_nodes[token] = node
	return true

# CGWnd:SetEffectText (CEffectFont): big outlined text that pops and fades (Claude). The original renders each
# character through the eft's loop_N sprite slots; we draw the glyphs with the UI font instead.
func play_effect_text(window: Control, text: String, argb: int, duration_ms: float) -> bool:
	if not is_instance_valid(window):
		return false
	var lab := Label.new()
	lab.text = text
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := Color.hex(((argb & 0xFFFFFF) << 8) | 0xFF)
	if (argb & 0xFFFFFF) == 0xFFFFFF or argb == 0:
		col = Color(1.0, 0.86, 0.2)
	lab.add_theme_color_override("font_color", col)
	lab.add_theme_color_override("font_outline_color", Color(0.45, 0.2, 0.0))
	lab.add_theme_constant_override("outline_size", 10)
	lab.add_theme_font_size_override("font_size", 38)
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	window.add_child(lab)
	lab.size = Vector2(maxf(window.size.x, 200.0), 60)
	lab.position = Vector2((window.size.x - lab.size.x) * 0.5, (window.size.y - lab.size.y) * 0.5)
	lab.pivot_offset = lab.size * 0.5
	lab.scale = Vector2.ONE * 0.4
	var secs := maxf(0.4, duration_ms / 1000.0)
	var tw := lab.create_tween()
	tw.tween_property(lab, "scale", Vector2.ONE * 1.15, 0.12)
	tw.tween_property(lab, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(maxf(0.0, secs - 0.5))
	tw.parallel().tween_property(lab, "position:y", lab.position.y - 30.0, secs)
	tw.tween_property(lab, "modulate:a", 0.0, 0.3)
	tw.tween_callback(lab.queue_free)
	return true

func stop_eft(token: int) -> void:
	var n = _eft_nodes.get(token)
	_eft_nodes.erase(token)
	if n != null and is_instance_valid(n):
		n.queue_free()

func stop_effect(window: Control, token: int = 0) -> void:
	if token != 0:
		stop_eft(token)
	if not is_instance_valid(window):
		return
	var id: int = window.get_instance_id()
	if not _states.has(id):
		return
	var state: Dictionary = _states[id]
	if token != 0 and int(state["fx_token"]) != token:
		return
	_stop_effect_state(state)


func get_scale_x(window: Control) -> float:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return 1.0
	_sync_external_changes(state)
	var value: Vector2 = state["base_scale"]
	return value.x


func get_scale_y(window: Control) -> float:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return 1.0
	_sync_external_changes(state)
	var value: Vector2 = state["base_scale"]
	return value.y


func set_scale(window: Control, x: float, y: float) -> void:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return
	_sync_external_changes(state)
	state["base_scale"] = Vector2(x, y)
	window.pivot_offset = window.size * 0.5
	_apply(state)


func set_rotation(window: Control, radians: float) -> void:
	if not is_instance_valid(window):
		return
	window.pivot_offset = window.size * 0.5
	window.rotation = radians


func get_fade(window: Control) -> float:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return 255.0
	_sync_external_changes(state)
	return clampf(float(state["base_alpha"]) * 255.0, 0.0, 255.0)


func set_fade(window: Control, value: float) -> void:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return
	_sync_external_changes(state)
	state["base_alpha"] = clampf(value / 255.0, 0.0, 1.0)
	_apply(state)


func _global_ui_to_local(window: Control, point: Vector2) -> Vector2:
	if not is_instance_valid(ui_root):
		# Without a configured root, interpret coordinates in the window's canvas.
		var parent_item: CanvasItem = window.get_parent_item()
		if parent_item != null:
			return parent_item.get_global_transform().affine_inverse() * point
		return point

	var canvas_point: Vector2 = ui_root.get_global_transform_with_canvas() * point
	var parent_item: CanvasItem = window.get_parent_item()
	if parent_item != null:
		return parent_item.get_global_transform_with_canvas().affine_inverse() * canvas_point
	return canvas_point


func move_window(window: Control, x: float, y: float,
		duration_ms: float, global_ui: bool) -> bool:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return false
	_kill_tween(state, "move_tween")

	var target := Vector2(x, y)
	if global_ui:
		target = _global_ui_to_local(window, target)

	if duration_ms <= 0.0 or not is_inside_tree():
		window.position = target
		return true

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	state["move_tween"] = tween
	tween.tween_property(window, "position", target, duration_ms / 1000.0)
	return true


func show_window(window: Control, show: bool, duration_ms: float,
		was_shown: bool) -> void:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return

	_sync_external_changes(state)
	var old_tween: Tween = state.get("show_tween") as Tween
	var was_fading: bool = old_tween != null and old_tween.is_valid()
	_kill_tween(state, "show_tween")

	state["shown"] = show
	state["show_serial"] = int(state["show_serial"]) + 1
	var serial: int = int(state["show_serial"])

	if duration_ms <= 0.0 or not is_inside_tree():
		state["show_alpha"] = 1.0
		window.visible = show
		_apply(state)
		return

	if show and not was_shown and not was_fading:
		state["show_alpha"] = 0.0
	window.visible = true
	_apply(state)

	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	state["show_tween"] = tween
	tween.tween_method(_fade_visibility.bind(int(state["id"]), serial),
		float(state["show_alpha"]), 1.0 if show else 0.0,
		duration_ms / 1000.0)
	tween.finished.connect(_finish_visibility.bind(int(state["id"]), serial))


func _fade_visibility(alpha: float, id: int, serial: int) -> void:
	if not _states.has(id):
		return
	var state: Dictionary = _states[id]
	if int(state["show_serial"]) != serial:
		return
	_sync_external_changes(state)
	state["show_alpha"] = alpha
	_apply(state)


func _finish_visibility(id: int, serial: int) -> void:
	if not _states.has(id):
		return
	var state: Dictionary = _states[id]
	if int(state["show_serial"]) != serial:
		return

	state["show_tween"] = null
	var window: Control = _window(state)
	if is_instance_valid(window):
		window.visible = bool(state["shown"])
	state["show_alpha"] = 1.0
	_apply(state)


func set_locks(window: Control, flags: int, left_mask: int,
		right_mask: int, top_mask: int, bottom_mask: int) -> void:
	if not is_instance_valid(window):
		return

	var position_before: Vector2 = window.position
	var size_before: Vector2 = window.size
	var left: bool = (flags & left_mask) != 0
	var right: bool = (flags & right_mask) != 0
	var top: bool = (flags & top_mask) != 0
	var bottom: bool = (flags & bottom_mask) != 0

	window.anchor_left = 0.0 if left or not right else 1.0
	window.anchor_right = 1.0 if right else 0.0
	window.anchor_top = 0.0 if top or not bottom else 1.0
	window.anchor_bottom = 1.0 if bottom else 0.0
	window.position = position_before
	window.size = size_before


func get_str_width(window: Control, text: String) -> float:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 18
	if is_instance_valid(window):
		font = window.get_theme_font("font")
		font_size = window.get_theme_font_size("font_size")
	if font == null:
		font = ThemeDB.fallback_font
	return font.get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(1, font_size)).x


func set_progress(window: Control, value: float, maximum: float) -> void:
	var state: Dictionary = _state(window)
	if state.is_empty():
		return

	# Used only when the existing GUI natives have no SetRange/SetPos.
	var fill: ColorRect = state.get("progress") as ColorRect
	if not is_instance_valid(fill):
		fill = ColorRect.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.focus_mode = Control.FOCUS_NONE
		fill.color = Color(1.0, 0.87, 0.3, 0.65)
		fill.show_behind_parent = true
		window.add_child(fill)
		state["progress"] = fill

	var fraction: float = clampf(value / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	fill.position = Vector2.ZERO
	fill.size = Vector2(window.size.x * fraction, window.size.y)
	fill.visible = fraction > 0.0


class SkillFuseOverlay extends Control:
	var active_ratio: float = 0.0
	var cd_ratio: float = 0.0
	var is_active: bool = false
	var is_cd: bool = false
	var cd_sec: int = 0
	var _cast_serial: int = -1
	var _anim_t: float = 0.0
	var _burst_t: float = 0.0
	var _ready_flash_t: float = 0.0
	var _was_cd: bool = false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_mode = Control.FOCUS_NONE
		z_index = 5
		set_process(false)

	func sync_state(
		p_active_ratio: float,
		p_cd_ratio: float,
		p_is_active: bool,
		p_is_cd: bool,
		p_cd_sec: int,
		p_cast_serial: int
	) -> void:
		var changed := false
		if p_cast_serial > 0 and p_cast_serial != _cast_serial:
			if _cast_serial >= 0:
				_burst_t = 0.36
			_cast_serial = p_cast_serial
			changed = true
		if _was_cd and not p_is_cd:
			_ready_flash_t = 0.42
			changed = true
		_was_cd = p_is_cd
		if (
			absf(active_ratio - p_active_ratio) > 0.001
			or absf(cd_ratio - p_cd_ratio) > 0.001
			or is_active != p_is_active
			or is_cd != p_is_cd
			or cd_sec != p_cd_sec
		):
			active_ratio = clampf(p_active_ratio, 0.0, 1.0)
			cd_ratio = clampf(p_cd_ratio, 0.0, 1.0)
			is_active = p_is_active
			is_cd = p_is_cd
			cd_sec = p_cd_sec
			changed = true
		var need_anim := (is_cd and cd_ratio > 0.001) or _burst_t > 0.0 or _ready_flash_t > 0.0
		if need_anim:
			set_process(true)
		elif changed:
			queue_redraw()
			set_process(false)

	func _process(delta: float) -> void:
		_anim_t += delta
		if _burst_t > 0.0:
			_burst_t = maxf(0.0, _burst_t - delta)
		if _ready_flash_t > 0.0:
			_ready_flash_t = maxf(0.0, _ready_flash_t - delta)
		queue_redraw()
		if not (is_cd and cd_ratio > 0.001) and _burst_t <= 0.0 and _ready_flash_t <= 0.0:
			set_process(false)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 4.0 or h <= 4.0:
			return
		var center := Vector2(w * 0.5, h * 0.5)
		var base_r := minf(w, h) * 0.455
		var start_a := -PI * 0.5

		# 1. Cooldown translucent dark radial wedge + 1:1 synchronized burning fuse ("烧绳")
		if is_cd and cd_ratio > 0.001:
			var sweep := TAU * cd_ratio
			var end_a := start_a + sweep
			var cd_r := base_r * 0.94
			var segs := maxi(12, int(ceil(cd_ratio * 48.0)))
			var pts := PackedVector2Array()
			pts.resize(segs + 2)
			pts[0] = center
			for i in range(segs + 1):
				var a := start_a + sweep * (float(i) / float(segs))
				pts[i + 1] = center + Vector2(cos(a), sin(a)) * cd_r
			draw_colored_polygon(pts, Color(0.04, 0.08, 0.16, 0.46))

			# Burning fuse arc locked 1:1 to exact remaining cooldown ratio (cd_ratio)
			var fuse_r := base_r * 1.02
			var seg_cnt := maxi(16, segs)

			# Charred rope track underneath
			draw_arc(center, fuse_r, 0.0, TAU, 48, Color(0.18, 0.09, 0.04, 0.52), 5.5, true)
			# Soft outer fire bloom
			draw_arc(center, fuse_r, start_a, end_a, seg_cnt, Color(1.0, 0.36, 0.04, 0.36), 13.0, true)
			# Main golden-orange braided burning rope
			draw_arc(center, fuse_r, start_a, end_a, seg_cnt, Color(1.0, 0.72, 0.16, 0.96), 5.8, true)
			# White-hot leading segment near the flame tip
			var hot_span := minf(sweep, 0.55)
			draw_arc(center, fuse_r, end_a - hot_span, end_a, maxi(6, int(ceil(hot_span * 12.0))), Color(1.0, 0.96, 0.70, 0.96), 2.8, true)

			# Live sizzling burning ember tip riding on the exact cooldown leading edge
			var tip := center + Vector2(cos(end_a), sin(end_a)) * fuse_r
			var pulse := 0.85 + 0.18 * sin(_anim_t * 32.0)
			draw_circle(tip, 14.0 * pulse, Color(1.0, 0.42, 0.04, 0.34))
			draw_circle(tip, 8.2 * pulse, Color(1.0, 0.68, 0.12, 0.88))
			draw_circle(tip, 4.2 * pulse, Color(1.0, 0.99, 0.88, 1.0))

			# 6 crackling spark particles spraying tangentially off the burning tip
			var tan_dir := Vector2(-sin(end_a), cos(end_a))
			var rad_dir := Vector2(cos(end_a), sin(end_a))
			for s_i in 6:
				var phase := fposmod(_anim_t * (2.6 + float(s_i) * 0.45) + float(s_i) * 0.37, 1.0)
				var spread := sin(float(s_i) * 2.13 + _anim_t * 14.0)
				var dist := 6.0 + phase * 18.0
				var sp_pos := tip + tan_dir * (dist * (0.65 + 0.35 * spread)) + rad_dir * (spread * (4.0 + phase * 10.0))
				var sp_alpha := (1.0 - phase) * 0.95
				var sp_r := lerpf(2.8, 0.9, phase)
				var sp_col := Color(1.0, lerpf(0.95, 0.38, phase), lerpf(0.65, 0.05, phase), sp_alpha)
				draw_circle(sp_pos, sp_r, sp_col)

		# 2. Cast activation burst ring
		if _burst_t > 0.0:
			var p := 1.0 - (_burst_t / 0.36)
			var br := base_r * lerpf(0.85, 1.24, p)
			draw_arc(center, br, 0.0, TAU, 40, Color(1.0, 0.88, 0.35, (1.0 - p) * 0.85), lerpf(6.0, 1.5, p), true)

		# 3. Cooldown-complete ready shimmer ring
		if _ready_flash_t > 0.0:
			var rp := 1.0 - (_ready_flash_t / 0.42)
			var rr := base_r * lerpf(0.92, 1.22, rp)
			draw_arc(center, rr, 0.0, TAU, 40, Color(0.55, 0.95, 1.0, (1.0 - rp) * 0.9), lerpf(5.5, 1.5, rp), true)

		# 4. Crisp outlined countdown number when cooling down
		if is_cd and cd_sec > 0:
			var txt := str(cd_sec)
			var font: Font = ThemeDB.fallback_font
			var fsize := clampi(int(minf(w, h) * 0.32), 22, 42)
			var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
			var baseline := Vector2(center.x - tw * 0.5, center.y + fsize * 0.34)
			draw_string_outline(font, baseline, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 5, Color(0.05, 0.08, 0.14, 0.88))
			draw_string(font, baseline, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(1.0, 1.0, 1.0, 0.98))


func set_skill_fuse(
	window: Control,
	active_ratio: float,
	cd_ratio: float,
	is_active: bool,
	is_cd: bool,
	cd_sec: int,
	cast_serial: int
) -> void:
	if not is_instance_valid(window):
		return
	var overlay := window.get_node_or_null("SkillFuseOverlay") as SkillFuseOverlay
	if overlay == null:
		overlay = SkillFuseOverlay.new()
		overlay.name = "SkillFuseOverlay"
		window.add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.sync_state(active_ratio, cd_ratio, is_active, is_cd, cd_sec, cast_serial)


func set_skill_tooltip_slot(
	slot_key: String,
	target: Control,
	title: String,
	tag: String,
	effect: String,
	desc: String
) -> void:
	if slot_key.is_empty():
		return
	if not is_instance_valid(target) or title.is_empty():
		_tooltip_slots.erase(slot_key)
		if _press_slot_key == slot_key:
			_hide_skill_tooltip()
		return
	_tooltip_slots[slot_key] = {
		"target": weakref(target),
		"title": title,
		"tag": tag,
		"effect": effect,
		"desc": desc,
		"is_active": slot_key == "active",
	}
	if _press_shown and _press_slot_key == slot_key:
		_show_skill_tooltip_for_slot(slot_key)


func clear_skill_tooltips() -> void:
	_tooltip_slots.clear()
	_active_long_pressed = false
	_hide_skill_tooltip()


func consume_active_long_press() -> bool:
	var was := _active_long_pressed
	_active_long_pressed = false
	return was


func _ensure_skill_tooltip_ui() -> PanelContainer:
	if is_instance_valid(_tooltip_panel):
		return _tooltip_panel
	var parent: Node = ui_root if is_instance_valid(ui_root) else get_tree().root
	if not is_instance_valid(parent):
		return null
	var panel := PanelContainer.new()
	panel.name = "SkillLongPressTooltip"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.z_index = 4000
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.11, 0.19, 0.94)
	style.border_color = Color(1.0, 0.84, 0.36, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 5)
	vbox.custom_minimum_size = Vector2(248, 0)
	panel.add_child(vbox)

	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	_tooltip_title = Label.new()
	_tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tooltip_title.add_theme_font_override("font", _tooltip_font)
	_tooltip_title.add_theme_font_size_override("font_size", 20)
	_tooltip_title.add_theme_color_override("font_color", Color(1.0, 0.87, 0.38, 1.0))
	header.add_child(_tooltip_title)

	_tooltip_tag = Label.new()
	_tooltip_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_tag.add_theme_font_override("font", _tooltip_font)
	_tooltip_tag.add_theme_font_size_override("font_size", 14)
	_tooltip_tag.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0, 1.0))
	header.add_child(_tooltip_tag)

	_tooltip_effect = Label.new()
	_tooltip_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_effect.custom_minimum_size = Vector2(248, 0)
	_tooltip_effect.add_theme_font_override("font", _tooltip_font)
	_tooltip_effect.add_theme_font_size_override("font_size", 16)
	_tooltip_effect.add_theme_color_override("font_color", Color(0.42, 0.96, 0.62, 1.0))
	vbox.add_child(_tooltip_effect)

	_tooltip_desc = Label.new()
	_tooltip_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(248, 0)
	_tooltip_desc.add_theme_font_override("font", _tooltip_font)
	_tooltip_desc.add_theme_font_size_override("font_size", 15)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 0.96))
	vbox.add_child(_tooltip_desc)

	parent.add_child(panel)
	_tooltip_panel = panel
	return panel


func _hide_skill_tooltip() -> void:
	_press_slot_key = ""
	_press_elapsed = 0.0
	_press_shown = false
	_press_touch_index = -1
	if is_instance_valid(_tooltip_panel):
		_tooltip_panel.visible = false


func _slot_control(slot_key: String) -> Control:
	if not _tooltip_slots.has(slot_key):
		return null
	var ref: WeakRef = _tooltip_slots[slot_key].get("target") as WeakRef
	if ref == null:
		return null
	var ctrl: Control = ref.get_ref() as Control
	if not is_instance_valid(ctrl) or not ctrl.is_visible_in_tree():
		return null
	return ctrl


func _hit_tooltip_slot(pos: Vector2) -> String:
	for key in _tooltip_slots:
		var ctrl := _slot_control(String(key))
		if ctrl != null and ctrl.get_global_rect().has_point(pos):
			return String(key)
	return ""


func _show_skill_tooltip_for_slot(slot_key: String) -> void:
	var ctrl := _slot_control(slot_key)
	if ctrl == null or not _tooltip_slots.has(slot_key):
		_hide_skill_tooltip()
		return
	var panel := _ensure_skill_tooltip_ui()
	if panel == null:
		return
	var data: Dictionary = _tooltip_slots[slot_key]
	_tooltip_title.text = String(data.get("title", ""))
	_tooltip_tag.text = String(data.get("tag", ""))
	var eff := String(data.get("effect", ""))
	_tooltip_effect.visible = not eff.is_empty()
	_tooltip_effect.text = "当前效果：" + eff
	var desc := String(data.get("desc", ""))
	_tooltip_desc.visible = not desc.is_empty()
	_tooltip_desc.text = desc

	panel.size = Vector2.ZERO
	var sz := panel.get_combined_minimum_size()
	panel.size = sz
	var rect := ctrl.get_global_rect()
	var vp_size := get_viewport().get_visible_rect().size
	var x := rect.position.x + (rect.size.x - sz.x) * 0.5
	var y := rect.position.y - sz.y - 12.0
	if y < 12.0:
		y = rect.position.y + rect.size.y + 12.0
	x = clampf(x, 12.0, maxf(12.0, vp_size.x - sz.x - 12.0))
	y = clampf(y, 12.0, maxf(12.0, vp_size.y - sz.y - 12.0))
	panel.global_position = Vector2(x, y)
	panel.visible = true
	_press_shown = true
	if bool(data.get("is_active", false)):
		_active_long_pressed = true


func _input(event: InputEvent) -> void:
	if _tooltip_slots.is_empty():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			var hit := _hit_tooltip_slot(mb.position)
			if not hit.is_empty():
				_press_slot_key = hit
				_press_origin = mb.position
				_press_elapsed = 0.0
				_press_shown = false
				_press_touch_index = -1
				if hit == "active":
					_active_long_pressed = false
				else:
					get_viewport().set_input_as_handled()
		else:
			if not _press_slot_key.is_empty():
				var was_passive := _press_slot_key != "active"
				_hide_skill_tooltip()
				if was_passive:
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if not _press_slot_key.is_empty() and _press_touch_index < 0:
			var mm := event as InputEventMouseMotion
			if mm.position.distance_to(_press_origin) > SKILL_DRAG_CANCEL_PX:
				_hide_skill_tooltip()
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var hit := _hit_tooltip_slot(st.position)
			if not hit.is_empty():
				_press_slot_key = hit
				_press_origin = st.position
				_press_elapsed = 0.0
				_press_shown = false
				_press_touch_index = st.index
				if hit == "active":
					_active_long_pressed = false
				else:
					get_viewport().set_input_as_handled()
		elif st.index == _press_touch_index and not _press_slot_key.is_empty():
			var was_passive := _press_slot_key != "active"
			_hide_skill_tooltip()
			if was_passive:
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _press_touch_index and not _press_slot_key.is_empty():
			if sd.position.distance_to(_press_origin) > SKILL_DRAG_CANCEL_PX:
				_hide_skill_tooltip()


func _cancel_state(state: Dictionary) -> void:
	_stop_effect_state(state)
	_kill_tween(state, "move_tween")
	_kill_tween(state, "show_tween")
	state["show_serial"] = int(state["show_serial"]) + 1
	state["show_alpha"] = 1.0
	var window: Control = _window(state)
	if is_instance_valid(window):
		window.visible = bool(state["shown"])
	_apply(state)


func cancel_tree(root: Control) -> void:
	if not is_instance_valid(root):
		return
	for value in _states.values():
		var state: Dictionary = value
		var window: Control = _window(state)
		if is_instance_valid(window) and (window == root or root.is_ancestor_of(window)):
			# Native ShowWnd may have changed visibility without requesting a fade.
			if state.get("show_tween") == null:
				state["shown"] = window.visible
			_cancel_state(state)


func _process(delta: float) -> void:
	if not _press_slot_key.is_empty():
		var ctrl := _slot_control(_press_slot_key)
		if ctrl == null:
			_hide_skill_tooltip()
		elif not _press_shown:
			_press_elapsed += delta
			if _press_elapsed >= SKILL_LONG_PRESS_SEC:
				_show_skill_tooltip_for_slot(_press_slot_key)
	var stale: Array = []
	for id in _states:
		var state: Dictionary = _states[id]
		if not is_instance_valid(_window(state)):
			stale.append(id)
	for id in stale:
		var state: Dictionary = _states[id]
		_kill_tween(state, "fx_tween")
		_kill_tween(state, "show_tween")
		_kill_tween(state, "move_tween")
		_states.erase(id)


func _exit_tree() -> void:
	clear_skill_tooltips()
	for value in _states.values():
		var state: Dictionary = value
		_cancel_state(state)
	_states.clear()
