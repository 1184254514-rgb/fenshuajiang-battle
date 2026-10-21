class_name GuiImageOps
extends RefCounted
## Image and text-style operations shared by every GuiWnd.
## Images are stored in GuiWnd.images_by_state, the arrays used by GuiWnd._draw().

const TEX_ROOT := "res://assets/tex/"
const TEXT_COLOR_META := "gui_state_text_colors"
const TEXT_BACKGROUND_META := "gui_state_text_background_colors"

static var _texture_cache: Dictionary = {}

var _originals: Dictionary = {}


func add_image(
	wnd: Object,
	group: int,
	image_state: int,
	index: int,
	texture_path: Variant,
	source_rect: Variant = null,
	destination_rect: Variant = null,
	color_or_flags_u32: int = 0xffffffff,
	lock_flags: int = 0,
	draw_flags: int = 0,
	arg0: int = -1,
	arg1: int = -1,
	arg2: int = 0,
	saturation: float = 1.0,
	hue_transform: float = 0.0
) -> bool:
	if not _valid_wnd(wnd):
		return false

	_remember_original(wnd)
	var texture := _texture_from_value(texture_path)
	var source := _rect(source_rect, _default_source(texture))
	var destination := _rect(destination_rect, _default_destination(wnd))
	var image := {
		"texture_index": -1,
		"texture": texture,
		"source_rect": source,
		"destination_rect": destination,
		"color_or_flags_u32": color_or_flags_u32 & 0xffffffff,
		"lock_flags": lock_flags,
		"draw_flags": draw_flags,
		"arg0": arg0,
		"arg1": arg1,
		"arg2": arg2,
		"saturation": saturation,
		"hue_transform": hue_transform,
		"group": group,
		"state": image_state
	}

	var images := _state_images(wnd, image_state, true)
	var insert_at := images.size() if index < 0 else clampi(index, 0, images.size())
	images.insert(insert_at, image)
	_store_states(wnd, _states(wnd))
	_redraw(wnd)
	return true


func add_image_by_texture(
	wnd: Object,
	group: int,
	image_state: int,
	index: int,
	texture_value: Variant,
	source_rect: Variant = null,
	destination_rect: Variant = null,
	color_or_flags_u32: int = 0xffffffff,
	lock_flags: int = 0,
	draw_flags: int = 0,
	arg0: int = -1,
	arg1: int = -1,
	arg2: int = 0,
	saturation: float = 1.0,
	hue_transform: float = 0.0
) -> bool:
	return add_image(
		wnd, group, image_state, index, texture_value, source_rect, destination_rect,
		color_or_flags_u32, lock_flags, draw_flags, arg0, arg1, arg2, saturation, hue_transform
	)


func get_image_count(wnd: Object, _group: int = 0, image_state: int = 2) -> int:
	if not _valid_wnd(wnd):
		return 0
	return _state_images(wnd, image_state, false).size()


func clear_wnd_bk_image(wnd: Object, _group: int = 0, image_state: int = 2) -> void:
	if not _valid_wnd(wnd):
		return
	_remember_original(wnd)
	var states := _states(wnd)
	if image_state < 0:
		for i in range(states.size()):
			states[i] = []
	else:
		while states.size() <= image_state:
			states.append([])
		states[image_state] = []
	_store_states(wnd, states)
	_redraw(wnd)


func restore_image_from_create_param(wnd: Object) -> bool:
	if not _valid_wnd(wnd):
		return false

	var instance_id := wnd.get_instance_id()
	var saved: Dictionary = _originals.get(instance_id, {})
	var reference: WeakRef = saved.get("ref") as WeakRef
	if reference == null or reference.get_ref() != wnd:
		_remember_original(wnd)
		saved = _originals.get(instance_id, {})

	var original: Array = saved.get("images", [])
	_store_states(wnd, original.duplicate(true))
	_redraw(wnd)
	return true


# Signature follows the native order used by the original scripts:
# SetImageColor(group, state, image_index, color). A negative index affects every image.
func set_image_color(
	wnd: Object,
	_group: int,
	image_state: int,
	image_index: int,
	color_or_flags_u32: int
) -> void:
	if not _valid_wnd(wnd):
		return
	var images := _state_images(wnd, image_state, false)
	var color := color_or_flags_u32 & 0xffffffff
	if image_index < 0:
		for value in images:
			if value is Dictionary:
				value["color_or_flags_u32"] = color
	elif image_index < images.size() and images[image_index] is Dictionary:
		images[image_index]["color_or_flags_u32"] = color
	_redraw(wnd)


func get_image_color(wnd: Object, _group: int, image_state: int, image_index: int) -> int:
	if not _valid_wnd(wnd):
		return 0xffffffff
	var images := _state_images(wnd, image_state, false)
	if image_index < 0 or image_index >= images.size():
		return 0xffffffff
	var value: Variant = images[image_index]
	if value is Dictionary:
		return int(value.get("color_or_flags_u32", 0xffffffff)) & 0xffffffff
	return 0xffffffff


func set_image_list(
	wnd: Object,
	_group: int,
	image_state: int,
	image_list: Variant,
	_start_index: int = 0,
	_arg0: int = -1,
	_arg1: int = 0,
	_arg2: int = -1
) -> bool:
	if not _valid_wnd(wnd):
		return false
	_remember_original(wnd)

	var images: Array = []
	if image_list is Array:
		images = image_list.duplicate(true)
	elif image_list is Dictionary:
		var nested: Variant = image_list.get("images", [])
		if nested is Array:
			images = nested.duplicate(true)
	elif image_list is Object:
		var nested_images: Variant = _read_member(image_list, ["images", "get_images", "GetImages"])
		if nested_images is Array:
			images = nested_images.duplicate(true)

	var states := _states(wnd)
	while states.size() <= image_state:
		states.append([])
	if image_state >= 0:
		states[image_state] = images
		_store_states(wnd, states)
		_redraw(wnd)
	return true


func get_image_wnd_rect(wnd: Object, image_index: int, image_state: int = 2) -> Dictionary:
	var fallback := _default_destination(wnd)
	return _get_image_rect(wnd, image_index, image_state, "destination_rect", fallback)


func get_image_texture_rect(wnd: Object, image_index: int, image_state: int = 2) -> Dictionary:
	return _get_image_rect(
		wnd, image_index, image_state, "source_rect",
		{"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	)


func set_image_wnd_rect(
	wnd: Object,
	image_index: int,
	rect: Variant,
	image_state: int = 2
) -> void:
	_set_image_rect(wnd, image_index, rect, image_state, "destination_rect")


func set_image_texture_rect(
	wnd: Object,
	image_index: int,
	rect: Variant,
	image_state: int = 2
) -> void:
	_set_image_rect(wnd, image_index, rect, image_state, "source_rect")


func set_image_texture(
	wnd: Object,
	_group: int,
	image_state: int,
	image_index: int,
	texture_value: Variant
) -> bool:
	var image := _image_at(wnd, image_state, image_index)
	if image.is_empty():
		return false
	var texture := _texture_from_value(texture_value)
	image["texture"] = texture
	image["texture_index"] = -1
	if texture == null:
		image.erase("texture")
	_redraw(wnd)
	return true


func set_image_texture_by_path(
	wnd: Object,
	group: int,
	image_state: int,
	image_index: int,
	path: Variant
) -> bool:
	return set_image_texture(wnd, group, image_state, image_index, path)


func set_image_hue(
	wnd: Object,
	image_index: int,
	hue_transform: float,
	image_state: int = 2
) -> void:
	_set_image_numeric(wnd, image_state, image_index, "hue_transform", hue_transform)


func set_image_saturation(
	wnd: Object,
	image_index: int,
	saturation: float,
	image_state: int = 2
) -> void:
	_set_image_numeric(wnd, image_state, image_index, "saturation", saturation)


func set_saturation(wnd: Object, saturation: float) -> void:
	if not _valid_wnd(wnd):
		return
	wnd.set_meta("gui_saturation", saturation)
	var states := _states(wnd)
	for state_index in range(states.size()):
		var images: Variant = states[state_index]
		if not images is Array:
			continue
		for image in images:
			if image is Dictionary:
				image["saturation"] = saturation
	_redraw(wnd)


func set_background_color(
	wnd: Object,
	_group: int,
	image_state: int,
	color_or_flags_u32: int
) -> void:
	if not _valid_wnd(wnd):
		return
	var images := _state_images(wnd, image_state, true)
	if images.is_empty():
		images.append({
			"texture_index": -1,
			"source_rect": {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0},
			"destination_rect": _default_destination(wnd),
			"color_or_flags_u32": color_or_flags_u32 & 0xffffffff
		})
	else:
		for image in images:
			if image is Dictionary:
				image["color_or_flags_u32"] = color_or_flags_u32 & 0xffffffff
	_store_states(wnd, _states(wnd))
	_redraw(wnd)


func set_wnd_text_color(
	wnd: Object,
	_group: int,
	image_state: int,
	color_or_flags_u32: int
) -> void:
	_set_state_color(wnd, TEXT_COLOR_META, image_state, color_or_flags_u32)
	if _valid_wnd(wnd) and int(wnd.get("state")) == image_state:
		wnd.set("text_color_override", _color_from_argb(color_or_flags_u32))
		wnd.set("_has_text_color_override", true)
	_redraw(wnd)


func get_wnd_text_color(wnd: Object, _group: int = 0, image_state: int = 2) -> int:
	if not _valid_wnd(wnd):
		return 0xffffffff
	var colors: Dictionary = wnd.get_meta(TEXT_COLOR_META, {})
	if colors.has(image_state):
		return int(colors[image_state]) & 0xffffffff

	if int(wnd.get("state")) == image_state and wnd.has_method("_get_text_color"):
		return _argb_from_color(wnd.call("_get_text_color"))

	var style: Dictionary = wnd.get("data").get("text_style", {})
	var raw: Dictionary = style.get("raw_fields", {})
	for field_name in ["this+0x30", "this+0x34", "this+0x38"]:
		if raw.has(field_name):
			var value := _int_value(raw[field_name])
			if value != 0:
				return value & 0xffffffff
	return 0xffffffff


func set_state_text_color(
	wnd: Object,
	_group: int,
	image_state: int,
	color_or_flags_u32: int
) -> void:
	set_wnd_text_color(wnd, 0, image_state, color_or_flags_u32)


func get_state_text_color(wnd: Object, group: int = 0, image_state: int = 2) -> int:
	return get_wnd_text_color(wnd, group, image_state)


func set_wnd_text_background_color(
	wnd: Object,
	_group: int,
	image_state: int,
	color_or_flags_u32: int
) -> void:
	_set_state_color(wnd, TEXT_BACKGROUND_META, image_state, color_or_flags_u32)
	if _valid_wnd(wnd) and int(wnd.get("state")) == image_state:
		wnd.set("text_background_color", _color_from_argb(color_or_flags_u32))
	_redraw(wnd)


func get_wnd_text_background_color(wnd: Object, _group: int = 0, image_state: int = 2) -> int:
	if not _valid_wnd(wnd):
		return 0
	var colors: Dictionary = wnd.get_meta(TEXT_BACKGROUND_META, {})
	if colors.has(image_state):
		return int(colors[image_state]) & 0xffffffff
	if int(wnd.get("state")) == image_state:
		return _argb_from_color(wnd.get("text_background_color"))
	return 0


func set_state_text_background_color(
	wnd: Object,
	group: int,
	image_state: int,
	color_or_flags_u32: int
) -> void:
	set_wnd_text_background_color(wnd, group, image_state, color_or_flags_u32)


func get_bounds(wnd: Object) -> Dictionary:
	return _default_destination(wnd)


func get_image_group(wnd: Object, _image_state: int = 2) -> Object:
	return wnd


# Mask support is recorded for compatibility; the current GuiWnd renderer does not apply masks.
func set_mask_texture(wnd: Object, texture_value: Variant) -> bool:
	if not _valid_wnd(wnd):
		return false
	var texture := _texture_from_value(texture_value)
	wnd.set_meta("gui_mask_texture", texture)
	return true


func set_mask_texture_by_path(wnd: Object, path: Variant) -> bool:
	return set_mask_texture(wnd, path)


func get_mask_texture(wnd: Object) -> Variant:
	if not _valid_wnd(wnd):
		return null
	return wnd.get_meta("gui_mask_texture") if wnd.has_meta("gui_mask_texture") else null


func clear_mask_texture(wnd: Object) -> void:
	if _valid_wnd(wnd) and wnd.has_meta("gui_mask_texture"):
		wnd.remove_meta("gui_mask_texture")


func _valid_wnd(wnd: Object) -> bool:
	return wnd != null and is_instance_valid(wnd) and wnd is Control


func _states(wnd: Object) -> Array:
	if not _valid_wnd(wnd):
		return []
	var value: Variant = wnd.get("images_by_state")
	return value if value is Array else []


func _store_states(wnd: Object, states: Array) -> void:
	if _valid_wnd(wnd):
		wnd.set("images_by_state", states)


func _state_images(wnd: Object, image_state: int, create: bool) -> Array:
	if not _valid_wnd(wnd) or image_state < 0:
		return []
	var states := _states(wnd)
	if create:
		while states.size() <= image_state:
			states.append([])
		if not (states[image_state] is Array):
			states[image_state] = []
		_store_states(wnd, states)
	elif image_state >= states.size() or not (states[image_state] is Array):
		return []
	return states[image_state]


func _image_at(wnd: Object, image_state: int, image_index: int) -> Dictionary:
	if not _valid_wnd(wnd) or image_index < 0:
		return {}
	var images := _state_images(wnd, image_state, false)
	if image_index >= images.size() or not (images[image_index] is Dictionary):
		return {}
	return images[image_index]


func _get_image_rect(
	wnd: Object,
	image_index: int,
	image_state: int,
	rect_key: String,
	fallback: Dictionary
) -> Dictionary:
	var image := _image_at(wnd, image_state, image_index)
	var value: Variant = image.get(rect_key, fallback)
	return value.duplicate(true) if value is Dictionary else fallback.duplicate(true)


func _set_image_rect(
	wnd: Object,
	image_index: int,
	rect_value: Variant,
	image_state: int,
	rect_key: String
) -> void:
	var image := _image_at(wnd, image_state, image_index)
	if image.is_empty() or rect_value == null:
		return
	image[rect_key] = _rect(rect_value, {})
	_redraw(wnd)


func _set_image_numeric(
	wnd: Object,
	image_state: int,
	image_index: int,
	key: String,
	value: float
) -> void:
	if not _valid_wnd(wnd):
		return
	if image_index < 0:
		for image in _state_images(wnd, image_state, false):
			if image is Dictionary:
				image[key] = value
	else:
		var image := _image_at(wnd, image_state, image_index)
		if not image.is_empty():
			image[key] = value
	_redraw(wnd)


func _default_destination(wnd: Object) -> Dictionary:
	var dimensions := Vector2.ZERO
	if _valid_wnd(wnd):
		dimensions = wnd.get("size")
	return {
		"left": 0.0, "top": 0.0,
		"right": dimensions.x, "bottom": dimensions.y
	}


func _default_source(texture: Texture2D) -> Dictionary:
	if texture == null:
		return {"left": 0.0, "top": 0.0, "right": 1.0, "bottom": 1.0}
	return {
		"left": 0.0, "top": 0.0,
		"right": float(texture.get_width()), "bottom": float(texture.get_height())
	}


func _rect(value: Variant, fallback: Dictionary) -> Dictionary:
	if value == null:
		return fallback.duplicate(true)
	if value is Dictionary:
		return {
			"left": _number(value.get("left", value.get("l", 0.0))),
			"top": _number(value.get("top", value.get("t", 0.0))),
			"right": _number(value.get("right", value.get("r", 0.0))),
			"bottom": _number(value.get("bottom", value.get("b", 0.0)))
		}
	return fallback.duplicate(true)


func _number(value: Variant) -> float:
	if value is String:
		return value.to_float()
	if value is int or value is float:
		return float(value)
	return 0.0


func _texture_from_value(value: Variant, depth: int = 0) -> Texture2D:
	if depth > 5 or value == null:
		return null
	if value is Texture2D:
		return value
	if value is String or value is StringName:
		return _load_texture_path(str(value))

	if value is Dictionary:
		for key in ["texture", "Texture", "texture2d", "Texture2D", "native_texture"]:
			if value.has(key):
				var nested := _texture_from_value(value[key], depth + 1)
				if nested != null:
					return nested
		return null

	if value is Object:
		for property in value.get_property_list():
			var property_name := str(property.get("name", ""))
			if property_name in ["texture", "Texture", "texture2d", "Texture2D", "native_texture"]:
				var nested := _texture_from_value(value.get(property_name), depth + 1)
				if nested != null:
					return nested
		for method in value.get_method_list():
			var method_name := str(method.get("name", ""))
			if method_name in [
				"get_texture", "GetTexture", "get_texture2d", "GetTexture2D",
				"get_native_texture", "GetNativeTexture"
			]:
				var nested := _texture_from_value(value.call(method_name), depth + 1)
				if nested != null:
					return nested
	return null


func _read_member(value: Object, names: Array) -> Variant:
	for property in value.get_property_list():
		var property_name := str(property.get("name", ""))
		if property_name in names:
			return value.get(property_name)
	for method in value.get_method_list():
		var method_name := str(method.get("name", ""))
		if method_name in names:
			return value.call(method_name)
	return null


func _load_texture_path(path_value: String) -> Texture2D:
	var normalized := path_value.strip_edges().replace("\\", "/")
	if normalized == "":
		return null
	if _texture_cache.has(normalized):
		return _texture_cache[normalized] as Texture2D

	var candidates: Array[String] = []
	if normalized.begins_with("res://") and normalized.to_lower().ends_with(".png"):
		_add_candidate(candidates, normalized)

	var relative := normalized
	if relative.begins_with("res://"):
		relative = relative.substr(6)
	if relative.begins_with("assets/tex/"):
		relative = relative.substr("assets/tex/".length())
	while relative.begins_with("./"):
		relative = relative.substr(2)
	if relative.begins_with("data/orig/"):
		relative = relative.substr("data/orig/".length())

	var asset_relative := relative
	if asset_relative.to_lower().ends_with(".tex"):
		asset_relative = asset_relative.substr(0, asset_relative.length() - 4) + ".png"
	elif not asset_relative.to_lower().ends_with(".png"):
		asset_relative += ".png"

	_add_candidate(candidates, TEX_ROOT + asset_relative)

	var known_prefixes := ["gui/tex/", "fx/tex/", "tex/"]
	for prefix in known_prefixes:
		if relative.begins_with(prefix):
			var suffix := relative.substr(prefix.length())
			if suffix.to_lower().ends_with(".tex"):
				suffix = suffix.substr(0, suffix.length() - 4) + ".png"
			elif not suffix.to_lower().ends_with(".png"):
				suffix += ".png"
			_add_candidate(candidates, TEX_ROOT + suffix)

	var base_name := relative.get_file()
	if base_name.to_lower().ends_with(".tex"):
		base_name = base_name.substr(0, base_name.length() - 4) + ".png"
	elif not base_name.to_lower().ends_with(".png"):
		base_name += ".png"
	_add_candidate(candidates, TEX_ROOT + base_name)

	var loaded: Texture2D
	for candidate in candidates:
		if not ResourceLoader.exists(candidate):
			continue
		var resource: Resource = ResourceLoader.load(candidate)
		if resource is Texture2D:
			loaded = resource as Texture2D
			break

	_texture_cache[normalized] = loaded
	return loaded


func _add_candidate(candidates: Array[String], candidate: String) -> void:
	if candidate != "" and not candidates.has(candidate):
		candidates.append(candidate)


func _remember_original(wnd: Object) -> void:
	if not _valid_wnd(wnd):
		return
	for key in _originals.keys():
		var old: Dictionary = _originals[key]
		var old_ref: WeakRef = old.get("ref") as WeakRef
		if old_ref == null or old_ref.get_ref() == null:
			_originals.erase(key)

	var instance_id := wnd.get_instance_id()
	var existing: Dictionary = _originals.get(instance_id, {})
	var existing_ref: WeakRef = existing.get("ref") as WeakRef
	if existing_ref != null and existing_ref.get_ref() == wnd:
		return
	_originals[instance_id] = {
		"ref": weakref(wnd),
		"images": _states(wnd).duplicate(true)
	}


func _set_state_color(wnd: Object, meta_name: String, image_state: int, color: int) -> void:
	if not _valid_wnd(wnd):
		return
	var colors: Dictionary = wnd.get_meta(meta_name, {})
	colors[image_state] = color & 0xffffffff
	wnd.set_meta(meta_name, colors)


func _color_from_argb(value: int) -> Color:
	var color := value & 0xffffffff
	return Color(
		float((color >> 16) & 255) / 255.0,
		float((color >> 8) & 255) / 255.0,
		float(color & 255) / 255.0,
		float((color >> 24) & 255) / 255.0
	)


func _argb_from_color(value: Variant) -> int:
	if not value is Color:
		return 0xffffffff
	var color: Color = value
	return (
		(roundi(color.a * 255.0) << 24)
		| (roundi(color.r * 255.0) << 16)
		| (roundi(color.g * 255.0) << 8)
		| roundi(color.b * 255.0)
	) & 0xffffffff


func _int_value(value: Variant) -> int:
	if value is String:
		var text: String = String(value).strip_edges()
		return int(text) if text.begins_with("0x") else text.to_int()
	if value is int or value is float:
		return int(value)
	return 0


func _redraw(wnd: Object) -> void:
	if _valid_wnd(wnd):
		(wnd as CanvasItem).queue_redraw()

