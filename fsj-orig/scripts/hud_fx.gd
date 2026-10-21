class_name HudFx
extends Node
# Presentation only. Lua owns effect deadlines and completion dispatch.
# Tween cancellation, hidden windows and freed Controls cannot lose Lua timers.

var ui_root: Control
var _states: Dictionary = {}


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


func _process(_delta: float) -> void:
	for id in _states.keys():
		var state: Dictionary = _states[id]
		if not is_instance_valid(_window(state)):
			_kill_tween(state, "fx_tween")
			_kill_tween(state, "show_tween")
			_kill_tween(state, "move_tween")
			_states.erase(id)


func _exit_tree() -> void:
	for value in _states.values():
		var state: Dictionary = value
		_cancel_state(state)
	_states.clear()
