class_name GuiDraw
extends RefCounted

# Native geometry and packed-color operations follow the supplied disassembly.
# The rectangle-buffer consumer and font compositor were not supplied; their
# remaining interpretation choices are explicitly marked ASSUMPTION below.
# This code has not been executed in Godot during this run.

const LOCK_LEFT := 1
const LOCK_RIGHT := 2
const LOCK_TOP := 4
const LOCK_BOTTOM := 8
const LOCK_ALL := 15
const LOCK_ZLEFT := 16
const LOCK_ZRIGHT := 32
const LOCK_ZTOP := 64
const LOCK_ZBOTTOM := 128
const LOCK_ZALL := 240

const IDF_ZOOM_WHILE_SCALE := 1
const IDF_ADD_TEXTURE_COLOR := 2
const IDF_DISABLE_ALPHA_TEST := 4
const IDF_ENABLE_ALPHA_BLEND := 8
const IDF_LEFT_WITHOUT_ZOOM := 16
const IDF_TOP_WITHOUT_ZOOM := 32
const IDF_MIRROR_WRAP := 64

# Round-1 aliases.
const DRAW_KEEP_SOURCE_ON_RESIZE := IDF_ZOOM_WHILE_SCALE
const DRAW_COLOR_TO_ADDITION := IDF_ADD_TEXTURE_COLOR
const DRAW_BUFFER_SELECTOR := IDF_ENABLE_ALPHA_BLEND
const DRAW_SOURCE_FROM_RIGHT := IDF_LEFT_WITHOUT_ZOOM
const DRAW_SOURCE_FROM_BOTTOM := IDF_TOP_WITHOUT_ZOOM
const DRAW_RECT_MODE_255 := IDF_MIRROR_WRAP

const WS_TOPMOST := 0x00008000
const WS_ALPHAENABLE := 0x00010000
const WS_DISABLECLIP := 0x00020000
const WS_INVISIBLE := 0x00040000
const WS_NOTSENDNOTIFY := 0x00080000
const WS_NOTRECIEVENOTIFY := 0x00100000
const WS_CUTBYPARENT := 0x00200000
const WS_IGNOREWHEEL := 0x00400000
const WS_TEXTXC := 0x01000000
const WS_TEXTXR := 0x02000000
const WS_TEXTYC := 0x04000000
const WS_TEXTYB := 0x08000000
const WS_AREAUSETEXRECT := 0x10000000
const WS_MSGTRANSPT := 0x20000000
const WS_CHILD := 0x40000000
const WS_MODULE := 0x80000000

const SCALE_EPSILON := 0.001
const NATIVE_CLIP_MIN := -32768.0
const NATIVE_CLIP_MAX := 32767.0

const _SLOTS_META := &"_gui_draw_slots"
const _CURSOR_META := &"_gui_draw_cursor"
const _ACTIVE_META := &"_gui_draw_active"
const _TEXT_MATERIAL_META := &"_gui_text_clip_material"

# ASSUMPTION: GetRectBuffer establishes batching/order, but the omitted buffer
# consumer establishes the actual blend equation. Use source-over in every
# bucket, including the explicitly ordered alpha-blend bucket. This preserves
# the existing renderer's transparent atlas edges and makes fades effective.
# IDF_ENABLE_ALPHA_BLEND is not an additive-blending flag.
#
# ASSUMPTION: alpha testing rejects alpha below 1/255 unless disabled.
# Saturation/hue operate on the sampled texture before multiply/add colors.
const _IMAGE_SHADER_SOURCE := """
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D gui_texture : source_color, filter_linear, repeat_disable;
uniform bool gui_has_texture = false;
uniform vec2 gui_texture_size = vec2(1.0);
uniform vec4 gui_multiply = vec4(1.0);
uniform vec4 gui_add = vec4(0.0);
uniform vec4 gui_clip_rect = vec4(-32768.0, -32768.0, 32767.0, 32767.0);
uniform vec4 gui_tile_rect = vec4(0.0);
uniform vec2 gui_wrap = vec2(0.0);
uniform bool gui_mirror_wrap = false;
uniform bool gui_alpha_test = true;
uniform float gui_saturation = 1.0;
uniform float gui_hue = 0.0;

varying vec2 gui_local_position;

void vertex() {
	gui_local_position = VERTEX;
}

float wrap_axis(float p, float a, float b, float signed_period) {
	float period = abs(signed_period);
	float extent = abs(b - a);
	if (period < 0.5 || period >= 65535.0 || extent <= 0.0) {
		return p;
	}

	period = min(period, extent);
	float direction = b >= a ? 1.0 : -1.0;
	float anchor = signed_period < 0.0 ? b - direction * period : a;
	float offset = (p - anchor) * direction;
	float tile = floor(offset / period);
	float within = offset - tile * period;

	if (gui_mirror_wrap && mod(tile, 2.0) >= 1.0) {
		within = period - within;
	}

	float result = anchor + direction * within;
	float other = anchor + direction * period;
	float padding = min(0.5, period * 0.5);
	return clamp(result, min(anchor, other) + padding, max(anchor, other) - padding);
}

vec3 rgb_to_hsv(vec3 c) {
	vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, k.wz), vec4(c.gb, k.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 0.0000001;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
		d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c) {
	vec3 p = abs(fract(c.xxx + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0);
	return c.z * mix(vec3(1.0), clamp(p - 1.0, 0.0, 1.0), c.y);
}

void fragment() {
	if (gui_local_position.x < gui_clip_rect.x ||
		gui_local_position.y < gui_clip_rect.y ||
		gui_local_position.x >= gui_clip_rect.z ||
		gui_local_position.y >= gui_clip_rect.w) {
		discard;
	}

	vec4 sampled = vec4(0.0);
	if (gui_has_texture) {
		vec2 pixel = UV;
		pixel.x = wrap_axis(pixel.x, gui_tile_rect.x, gui_tile_rect.z, gui_wrap.x);
		pixel.y = wrap_axis(pixel.y, gui_tile_rect.y, gui_tile_rect.w, gui_wrap.y);
		sampled = texture(gui_texture, pixel / gui_texture_size);

		if (gui_saturation != 1.0 || gui_hue != 0.0) {
			vec3 hsv = rgb_to_hsv(sampled.rgb);
			hsv.x = fract(hsv.x + gui_hue / 360.0);
			hsv.y = clamp(hsv.y * gui_saturation, 0.0, 1.0);
			sampled.rgb = hsv_to_rgb(hsv);
		}
	}

	vec4 result = clamp(sampled * gui_multiply + gui_add, vec4(0.0), vec4(1.0));
	if (gui_alpha_test && result.a < 1.0 / 255.0) {
		discard;
	}

	// The submitted polygon has no built-in texture. COLOR therefore contains
	// vertex/CanvasItem modulation, not a second sample of the atlas.
	COLOR = result * COLOR;
}
"""

const _TEXT_SHADER_SOURCE := """
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 gui_clip_rect = vec4(-32768.0, -32768.0, 32767.0, 32767.0);
varying vec2 gui_local_position;

void vertex() {
	gui_local_position = VERTEX;
}

void fragment() {
	if (gui_local_position.x < gui_clip_rect.x ||
		gui_local_position.y < gui_clip_rect.y ||
		gui_local_position.x >= gui_clip_rect.z ||
		gui_local_position.y >= gui_clip_rect.w) {
		discard;
	}
	// Keep Godot's normal glyph/vertex COLOR calculation.
}
"""

static var _image_shader: Shader
static var _text_shader: Shader


# Compatibility with round 1. No adapters are needed or installed now.
static func configure(
	_decoder: Callable = Callable(),
	_scaler: Callable = Callable(),
	_clipper: Callable = Callable(),
	_color_product: Callable = Callable(),
	_submitter: Callable = Callable()
) -> bool:
	return true


static func is_configured() -> bool:
	return true


static func number(value: Variant, fallback: float = 0.0) -> float:
	if value == null:
		return fallback
	var result: float
	if value is String:
		var string_value: String = value
		if string_value.begins_with("0x") or string_value.begins_with("-0x"):
			result = float(string_value.hex_to_int())
		elif string_value.is_valid_float():
			result = string_value.to_float()
		else:
			return fallback
	elif value is int or value is float:
		result = float(value)
	else:
		return fallback
	return result if is_finite(result) else fallback


static func integer(value: Variant, fallback: int = 0) -> int:
	if value is int:
		return int(value)
	return int(number(value, float(fallback)))


static func rect_edges(value: Variant) -> Vector4:
	if value is Vector4:
		return value
	if value is Rect2:
		var rect: Rect2 = value
		return Vector4(rect.position.x, rect.position.y, rect.end.x, rect.end.y)
	if value is Dictionary:
		var rect: Dictionary = value
		var left := number(rect.get("left", 0.0))
		var top := number(rect.get("top", 0.0))
		return Vector4(
			left,
			top,
			number(rect.get("right", left), left),
			number(rect.get("bottom", top), top)
		)
	return Vector4.ZERO


static func rect_dictionary(rect: Vector4) -> Dictionary:
	return {"left": rect.x, "top": rect.y, "right": rect.z, "bottom": rect.w}


static func extent(rect: Vector4) -> Vector2:
	return Vector2(rect.z - rect.x, rect.w - rect.y)


# ScaleRect, 0x29a008. Hard locks take precedence over proportional locks.
# Notice that a lone ZLEFT/ZTOP changes only that edge, whereas an entirely
# unlocked axis translates BOTH edges by half the size delta.
static func scale_rect(
	rect: Vector4,
	locks: int,
	old_size: Vector2,
	size_delta: Vector2
) -> Vector4:
	var result := rect
	var mask := locks & 0xffff

	if (mask & LOCK_RIGHT) != 0 or (mask & LOCK_ZRIGHT) != 0:
		if (mask & LOCK_RIGHT) != 0:
			result.z += size_delta.x
		elif old_size.x != 0.0:
			result.z += result.z * size_delta.x / old_size.x

		if (mask & LOCK_LEFT) == 0:
			if (mask & LOCK_ZLEFT) != 0:
				if old_size.x != 0.0:
					result.x += result.x * size_delta.x / old_size.x
			else:
				result.x += size_delta.x
	elif (mask & LOCK_LEFT) == 0:
		if (mask & LOCK_ZLEFT) != 0:
			if old_size.x != 0.0:
				result.x += result.x * size_delta.x / old_size.x
		else:
			result.x += size_delta.x * 0.5
			result.z += size_delta.x * 0.5

	if (mask & LOCK_BOTTOM) != 0 or (mask & LOCK_ZBOTTOM) != 0:
		if (mask & LOCK_BOTTOM) != 0:
			result.w += size_delta.y
		elif old_size.y != 0.0:
			result.w += result.w * size_delta.y / old_size.y

		if (mask & LOCK_TOP) == 0:
			if (mask & LOCK_ZTOP) != 0:
				if old_size.y != 0.0:
					result.y += result.y * size_delta.y / old_size.y
			else:
				result.y += size_delta.y
	elif (mask & LOCK_TOP) == 0:
		if (mask & LOCK_ZTOP) != 0:
			if old_size.y != 0.0:
				result.y += result.y * size_delta.y / old_size.y
		else:
			result.y += size_delta.y * 0.5
			result.w += size_delta.y * 0.5

	return result


static func decode_image(raw: Dictionary, textures: Array = []) -> Dictionary:
	var result: Dictionary = raw.duplicate(true)
	var source := rect_edges(raw.get("source_rect", {}))
	var destination := rect_edges(raw.get("destination_rect", {}))
	var texture: Texture2D = raw.get("texture") as Texture2D
	var texture_index := integer(raw.get("texture_index", -1), -1)
	var intentional_null := texture_index == -1 or texture_index == 0xffffffff or texture_index == 0

	if texture == null and texture_index > 0 and texture_index < textures.size():
		texture = textures[texture_index] as Texture2D

	var ready := texture != null or intentional_null
	if raw.has("ready"):
		ready = ready and bool(raw["ready"])
	if texture != null:
		ready = ready and texture.get_width() > 0 and texture.get_height() > 0

	var flags := integer(raw.get("draw_flags", raw.get("substate", 0))) & 0xffff

	# ASSUMPTION: the resource's explicit "none" texture indices represent
	# flat fills, as GUI_MODEL specifies. Normalize them to native additive
	# color primitives. A missing positive-index texture is NOT a flat fill.
	if texture == null and intentional_null:
		flags |= IDF_ADD_TEXTURE_COLOR

	var density: Vector2 = raw.get("uv_density", raw.get("_gui_uv_density", Vector2.ONE))
	if not raw.has("uv_density") and not raw.has("_gui_uv_density"):
		# ASSUMPTION: unobserved native density constructor defaults are 1,1.
		var destination_extent := extent(destination)
		var source_extent := extent(source)
		if absf(destination_extent.x) > SCALE_EPSILON:
			density.x = source_extent.x / destination_extent.x
		if absf(destination_extent.y) > SCALE_EPSILON:
			density.y = source_extent.y / destination_extent.y

	var saturation := 1.0
	var hue := 0.0
	if raw.has("saturation"):
		saturation = number(raw["saturation"], 1.0)
	elif raw.get("param_0x24_raw_u8") != null:
		# ASSUMPTION: serialized saturation is a percentage, with 100 neutral.
		saturation = number(raw["param_0x24_raw_u8"], 100.0) / 100.0
	if raw.has("hue"):
		hue = number(raw["hue"])
	elif raw.get("param_0x28_raw_i8") != null:
		# ASSUMPTION: serialized signed hue is in degrees.
		hue = number(raw["param_0x28_raw_i8"])

	result["source_rect"] = source
	result["destination_rect"] = destination
	result["color_or_flags_u32"] = integer(raw.get("color_or_flags_u32", 0xffffffff)) & 0xffffffff
	result["lock_flags"] = integer(raw.get("lock_flags", raw.get("state", 0))) & 0xffff
	result["draw_flags"] = flags
	result["wrap_width"] = integer(raw.get("wrap_width", raw.get("state_0x30", 0xffff))) & 0xffff
	result["wrap_height"] = integer(raw.get("wrap_height", raw.get("state_0x32", 0xffff))) & 0xffff
	result["group_id"] = integer(raw.get("group_id", raw.get("field_0x34", 0))) & 0xffff
	result["texture"] = texture
	result["ready"] = ready
	result["uv_density"] = density
	result["saturation"] = saturation
	result["hue"] = hue
	result["tile_rect"] = rect_edges(raw.get("tile_rect", raw.get("_gui_tile_rect", source)))
	return result


static func decode_groups(raw_groups: Array) -> Array:
	var result: Array = []
	for value in raw_groups:
		if not value is Dictionary:
			continue
		var group: Dictionary = value.duplicate(true)
		group["group_id"] = integer(group.get("group_id", 0)) & 0xffff
		group["lock_flags"] = integer(group.get("lock_flags", group.get("reserved_u16", 0))) & 0xffff
		group["rect"] = rect_edges(group.get("rect", {}))
		result.append(group)
	return result


static func decode_state(wnd, state: int, raw_images: Array) -> Dictionary:
	var images: Array = []
	for value in raw_images:
		if value is Dictionary:
			images.append(decode_image(value, wnd.textures))
	var groups: Array = []
	if state >= 0 and state < wnd.groups_by_state.size():
		if wnd.groups_by_state[state] is Array:
			groups = decode_groups(wnd.groups_by_state[state])
	var colors := get_state_text_colors(wnd, state)
	return {
		"images": images,
		"groups": groups,
		"fade_byte": effective_fade_byte(wnd),
		"saturation": wnd.gui_saturation,
		"text_color_argb": colors["foreground_argb"],
		"text_bc_color_argb": colors["secondary_argb"]
	}


static func resolve_state(wnd, requested: int) -> int:
	var lists: Array = wnd.images_by_state
	if requested >= 0 and requested < lists.size() and lists[requested] is Array:
		return requested

	# GetChildImageList searches identifiers, then falls back to its first record.
	for value in wnd.image_state_order:
		var candidate := int(value)
		if candidate >= 0 and candidate < lists.size() and lists[candidate] is Array:
			return candidate
	for candidate in range(lists.size()):
		if lists[candidate] is Array:
			return candidate
	return -1


static func resize_image_list(
	image_list: Dictionary,
	old_size: Vector2,
	size_delta: Vector2
) -> Dictionary:
	var result: Dictionary = image_list.duplicate(true)
	var groups: Array = result.get("groups", [])
	var images: Array = result.get("images", [])
	var changes: Dictionary = {}

	for value in groups:
		if not value is Dictionary:
			continue
		var group: Dictionary = value
		var before := rect_edges(group.get("rect", {}))
		var after := scale_rect(
			before,
			integer(group.get("lock_flags", group.get("reserved_u16", 0))),
			old_size,
			size_delta
		)
		group["rect"] = after
		changes[integer(group.get("group_id", 0)) & 0xffff] = {
			"before": before,
			"after": after
		}

	for index in range(images.size()):
		if not images[index] is Dictionary:
			continue
		var item: Dictionary = images[index]
		var origin_delta := Vector2.ZERO
		var reference_size := old_size
		var reference_delta := size_delta
		var group_id := integer(item.get("group_id", item.get("field_0x34", 0))) & 0xffff
		if changes.has(group_id):
			var change: Dictionary = changes[group_id]
			var before: Vector4 = change["before"]
			var after: Vector4 = change["after"]
			origin_delta = Vector2(after.x - before.x, after.y - before.y)
			reference_size = extent(before)
			reference_delta = extent(after) - reference_size
		images[index] = scale_image_geometry(
			item, origin_delta, reference_size, reference_delta
		)

	result["groups"] = groups
	result["images"] = images
	return result


static func scale_image_geometry(
	image: Dictionary,
	origin_delta: Vector2,
	old_reference_size: Vector2,
	reference_size_delta: Vector2
) -> Dictionary:
	var result: Dictionary = image.duplicate(true)
	var source := rect_edges(result.get("source_rect", {}))
	var destination := rect_edges(result.get("destination_rect", {}))
	var density: Vector2 = result.get("uv_density", result.get("_gui_uv_density", Vector2.ONE))
	if not result.has("tile_rect"):
		result["tile_rect"] = rect_edges(result.get("_gui_tile_rect", source))

	# Native translation happens before ScaleRect, without rebasing to the
	# group's origin. Groups do not add a second translation at draw time.
	destination += Vector4(origin_delta.x, origin_delta.y, origin_delta.x, origin_delta.y)
	var previous_extent := extent(destination)
	var source_extent := extent(source)
	if absf(previous_extent.x) > SCALE_EPSILON:
		density.x = source_extent.x / previous_extent.x
	if absf(previous_extent.y) > SCALE_EPSILON:
		density.y = source_extent.y / previous_extent.y

	destination = scale_rect(
		destination,
		integer(result.get("lock_flags", result.get("state", 0))),
		old_reference_size,
		reference_size_delta
	)
	var next_extent := extent(destination)
	var flags := integer(result.get("draw_flags", result.get("substate", 0))) & 0xffff

	if (flags & IDF_ZOOM_WHILE_SCALE) == 0:
		if next_extent.x != previous_extent.x:
			var delta_x := (next_extent.x - previous_extent.x) * density.x
			if (flags & IDF_LEFT_WITHOUT_ZOOM) != 0:
				source.x -= delta_x
			else:
				source.z += delta_x
		if next_extent.y != previous_extent.y:
			var delta_y := (next_extent.y - previous_extent.y) * density.y
			if (flags & IDF_TOP_WITHOUT_ZOOM) != 0:
				source.y -= delta_y
			else:
				source.w += delta_y

	result["source_rect"] = source
	result["destination_rect"] = destination
	result["uv_density"] = density
	return result


static func _is_gui_window(node: Node) -> bool:
	return (
		node is Control
		and node.has_method("class_of")
		and node.has_method("get_style")
		and node.has_method("get_org_width")
	)


static func _parent_window(wnd) -> Control:
	var current: Node = wnd.get_parent()
	while current != null:
		if _is_gui_window(current):
			return current as Control
		current = current.get_parent()
	return null


static func _layout_origin(wnd) -> Vector2:
	# ASSUMPTION: native global layout coordinates correspond to accumulated
	# Control/Node2D positions before display transforms. The CanvasItem tree
	# applies those transforms once, after these logical clipping calculations.
	var result := Vector2.ZERO
	var current: Node = wnd
	while current != null and not current is Viewport and not current is CanvasLayer:
		if current is Control:
			result += (current as Control).position
		elif current is Node2D:
			result += (current as Node2D).position
		current = current.get_parent()
	return result


static func _has_native_transform(wnd) -> bool:
	# These are the available 2D equivalents of the native transform fields.
	return wnd.rotation != 0.0 or wnd.scale != Vector2.ONE or wnd.pivot_offset != Vector2.ZERO


static func get_global_clip_bounds(
	wnd,
	for_images: bool,
	force_clip: bool = false
) -> Vector4:
	var origin := _layout_origin(wnd)
	var inset: Vector2 = Vector2.ZERO if for_images else wnd.clip_inset
	var flags := int(wnd.style_flags)
	var result: Vector4

	if (flags & WS_DISABLECLIP) != 0 and not force_clip:
		result = Vector4(NATIVE_CLIP_MIN, NATIVE_CLIP_MIN, NATIVE_CLIP_MAX, NATIVE_CLIP_MAX)
	else:
		result = Vector4(
			origin.x + inset.x,
			origin.y + inset.y,
			origin.x + wnd.size.x - inset.x,
			origin.y + wnd.size.y - inset.y
		)

	if _has_native_transform(wnd):
		return result

	var parent = _parent_window(wnd)
	while parent != null:
		# This check occurs even when the lower window's CUTBYPARENT is unset.
		if _has_native_transform(parent):
			return result

		if (flags & WS_CUTBYPARENT) != 0:
			var parent_origin := _layout_origin(parent)
			var parent_inset: Vector2 = Vector2.ZERO if for_images else parent.clip_inset
			result.x = maxf(result.x, parent_origin.x + parent_inset.x)
			result.y = maxf(result.y, parent_origin.y + parent_inset.y)
			result.z = minf(result.z, parent_origin.x + parent.size.x - parent_inset.x)
			result.w = minf(result.w, parent_origin.y + parent.size.y - parent_inset.y)

		# Do not stop at an unset CUTBYPARENT, and do not honor a parent's
		# DISABLECLIP here: neither shortcut exists in GetGlobalClipBounds.
		flags = int(parent.style_flags)
		parent = _parent_window(parent)

	# AREAUSETEXRECT and ALPHAENABLE are not tested by this native function.
	return result


static func get_clip_bounds(wnd, for_images: bool, force_clip: bool = false) -> Vector4:
	var result := get_global_clip_bounds(wnd, for_images, force_clip)
	var origin := _layout_origin(wnd)
	return result - Vector4(origin.x, origin.y, origin.x, origin.y)


static func effective_fade_byte(wnd) -> int:
	# ASSUMPTION: inheritance of the native fade byte is not supplied. Preserve
	# the previous Control hierarchy's multiplicative inheritance, but bake
	# each window/ancestor contribution once instead of using modulate.a too.
	var opacity := 1.0
	var current = wnd
	while current != null:
		opacity *= clampf(float(current.fade_alpha), 0.0, 1.0)
		current = _parent_window(current)
	return clampi(roundi(opacity * 255.0), 0, 255)


static func multiply_argb(a: int, b: int) -> int:
	# CColor::operator*(CColor): unsigned truncation after division by 255.0.
	var result := 0
	for shift: int in [0, 8, 16, 24]:
		var product := ((a >> shift) & 255) * ((b >> shift) & 255)
		result |= floori(float(product) / 255.0) << shift
	return result & 0xffffffff


static func multiply_argb_scalar(value: int, factor: float) -> int:
	# CColor::operator*(float): rounded 8.8 multiplier; 255 and above bypass
	# multiplication, while lower factors multiply each byte and shift by 8.
	if not is_finite(factor) or factor <= 0.0:
		return 0
	if factor >= 255.0 / 256.0:
		return value & 0xffffffff
	var twice := floori(factor * 512.0)
	var weight := (twice >> 1) + (twice & 1)
	var result := 0
	for shift: int in [0, 8, 16, 24]:
		result |= ((((value >> shift) & 255) * weight) >> 8) << shift
	return result & 0xffffffff


static func saturated_add_argb(a: int, b: int) -> int:
	var result := 0
	for shift: int in [0, 8, 16, 24]:
		result |= mini(255, ((a >> shift) & 255) + ((b >> shift) & 255)) << shift
	return result & 0xffffffff


static func fade_image_list_argb(value: int, fade_byte: int) -> int:
	var packed := value & 0xffffffff
	var product := ((packed >> 24) & 255) * (fade_byte & 255)
	return (packed & 0x00ffffff) | ((product >> 8) << 24)


static func fade_text_or_direct_rect_argb(value: int, fade_byte: int) -> int:
	var packed := value & 0xffffffff
	var product := ((packed >> 24) & 255) * (fade_byte & 255)
	var alpha := ((product >> 8) | (product >> 15)) & 255
	return (packed & 0x00ffffff) | (alpha << 24)


static func color_from_argb(value: int) -> Color:
	var packed := value & 0xffffffff
	return Color(
		float((packed >> 16) & 255) / 255.0,
		float((packed >> 8) & 255) / 255.0,
		float(packed & 255) / 255.0,
		float((packed >> 24) & 255) / 255.0
	)


static func color_to_argb(value: Color) -> int:
	return (
		(clampi(roundi(value.a * 255.0), 0, 255) << 24)
		| (clampi(roundi(value.r * 255.0), 0, 255) << 16)
		| (clampi(roundi(value.g * 255.0), 0, 255) << 8)
		| clampi(roundi(value.b * 255.0), 0, 255)
	)


static func _packed_color(value: Variant, fallback: int) -> int:
	if value is Color:
		return color_to_argb(value)
	return integer(value, fallback) & 0xffffffff


static func _lookup_state_color(
	values: Dictionary,
	requested: int,
	selected: int,
	fallback: int
) -> int:
	for candidate in [requested, selected, -1]:
		if values.has(candidate):
			return _packed_color(values[candidate], fallback)
		if values.has(str(candidate)):
			return _packed_color(values[str(candidate)], fallback)
	return fallback


static func _group_color(
	groups: Dictionary,
	group_id: int,
	requested: int,
	selected: int,
	fallback: int
) -> int:
	var result := fallback
	if groups.get(-1) is Dictionary:
		result = _lookup_state_color(groups[-1], requested, selected, result)
	if groups.get(group_id) is Dictionary:
		result = _lookup_state_color(groups[group_id], requested, selected, result)
	return result


static func get_state_text_colors(wnd, state: int, group_id: int = 0) -> Dictionary:
	var selected := state
	var colors: Dictionary = wnd.state_text_colors
	if not colors.has(selected):
		selected = 2 if wnd.enabled else 3
	if not colors.has(selected):
		selected = resolve_state(wnd, state)

	var foreground := 0xffffffff
	var secondary := 0
	var pair: Dictionary = colors.get(selected, {})
	if pair.has("foreground_argb"):
		foreground = integer(pair["foreground_argb"]) & 0xffffffff
	else:
		# ASSUMPTION: for legacy/runtime-created windows without state headers,
		# +0x30 is the default foreground. An unspecified/zero legacy field
		# keeps the old white default. Explicit state colors may be zero.
		var text_style: Dictionary = wnd.data.get("text_style", {})
		var raw: Dictionary = text_style.get("raw_fields", {})
		var legacy := integer(raw.get("this+0x30", text_style.get("text_color_u32", 0)))
		if legacy != 0:
			foreground = legacy & 0xffffffff
	if pair.has("secondary_argb"):
		secondary = integer(pair["secondary_argb"]) & 0xffffffff

	if wnd._has_text_color_override:
		foreground = color_to_argb(wnd.text_color_override)
	if wnd._has_text_background_color_override:
		secondary = color_to_argb(wnd.text_background_color)

	foreground = _group_color(wnd.text_colors_by_group, group_id, state, selected, foreground)
	secondary = _group_color(wnd.text_background_colors_by_group, group_id, state, selected, secondary)

	# Retain the existing runtime's metadata entrypoints, including JSON keys.
	var foreground_meta: Dictionary = wnd.get_meta("gui_state_text_colors", {})
	var secondary_meta: Dictionary = wnd.get_meta("gui_state_text_background_colors", {})
	if group_id == 0:
		foreground = _lookup_state_color(foreground_meta, state, selected, foreground)
		secondary = _lookup_state_color(secondary_meta, state, selected, secondary)

	return {"foreground_argb": foreground, "secondary_argb": secondary}


static func build_rect_commands(
	images: Array,
	clip: Vector4,
	call_add: int = 0,
	call_multiply: int = 0xffffffff,
	call_saturation: float = 1.0,
	call_hue: float = 0.0,
	image_index: int = -1
) -> Array:
	var result: Array = []
	if clip.z <= clip.x or clip.w <= clip.y:
		return result

	var first := 0
	var limit := images.size()
	if image_index >= 0 and image_index < images.size():
		first = image_index
		limit = image_index + 1

	for index in range(first, limit):
		if not images[index] is Dictionary:
			continue
		var item: Dictionary = images[index]
		if not bool(item.get("ready", false)):
			continue

		var destination := rect_edges(item.get("destination_rect", {}))
		if destination.x == destination.z or destination.y == destination.w:
			continue
		var source := rect_edges(item.get("source_rect", {}))
		var flags := integer(item.get("draw_flags", 0)) & 0xffff
		var image_color := integer(item.get("color_or_flags_u32", 0xffffffff)) & 0xffffffff
		var multiplier := call_multiply & 0xffffffff
		var addition := call_add & 0xffffffff
		var texture: Texture2D = item.get("texture") as Texture2D

		if (flags & IDF_ADD_TEXTURE_COLOR) != 0:
			addition = saturated_add_argb(addition, multiply_argb(multiplier, image_color))
		elif texture != null:
			multiplier = multiply_argb(image_color, multiplier)
		if texture == null:
			multiplier = 0
		if ((multiplier | addition) & 0xff000000) == 0:
			continue

		var wrap_width := integer(item.get("wrap_width", 0xffff)) & 0xffff
		var wrap_height := integer(item.get("wrap_height", 0xffff)) & 0xffff
		if (flags & IDF_LEFT_WITHOUT_ZOOM) != 0:
			wrap_width = -wrap_width
		if (flags & IDF_TOP_WITHOUT_ZOOM) != 0:
			wrap_height = -wrap_height

		result.append({
			"destination_rect": destination,
			"source_rect": source,
			"tile_rect": rect_edges(item.get("tile_rect", source)),
			"clip_rect": clip,
			"texture": texture,
			"multiply_argb": multiplier,
			"add_argb": addition,
			"wrap_width": wrap_width,
			"wrap_height": wrap_height,
			"buffer_selector": (flags & IDF_ENABLE_ALPHA_BLEND) != 0,
			"rect_mode_byte": 255 if (flags & IDF_MIRROR_WRAP) != 0 else 1,
			"saturation": call_saturation * number(item.get("saturation", 1.0), 1.0),
			"hue": call_hue + number(item.get("hue", 0.0)),
			"raw_draw_flags": flags
		})
	return result


static func _get_image_shader() -> Shader:
	if _image_shader == null:
		_image_shader = Shader.new()
		_image_shader.code = _IMAGE_SHADER_SOURCE
	return _image_shader


static func _get_text_shader() -> Shader:
	if _text_shader == null:
		_text_shader = Shader.new()
		_text_shader.code = _TEXT_SHADER_SOURCE
	return _text_shader


static func bind_text_clip(canvas: CanvasItem, wnd) -> void:
	var clip := get_clip_bounds(wnd, false)
	if canvas != wnd and canvas is Control:
		# The embedded LineEdit is positioned directly in window coordinates.
		var offset: Vector2 = (canvas as Control).position
		clip -= Vector4(offset.x, offset.y, offset.x, offset.y)

	var material: ShaderMaterial = (canvas.get_meta(_TEXT_MATERIAL_META) if canvas.has_meta(_TEXT_MATERIAL_META) else null) as ShaderMaterial
	if material == null:
		material = ShaderMaterial.new()
		material.shader = _get_text_shader()
		canvas.set_meta(_TEXT_MATERIAL_META, material)
		canvas.material = material
	elif canvas.material != material:
		canvas.material = material
	material.set_shader_parameter("gui_clip_rect", clip)


# A frame encloses every image pass for this CanvasItem, including progress.
# Text remains on the parent CanvasItem. Image RIDs draw behind that parent,
# so images, progress, text and normal child controls retain their layering.
static func begin_window(canvas: CanvasItem, wnd) -> void:
	if not canvas.has_meta(_SLOTS_META):
		canvas.set_meta(_SLOTS_META, [])
	canvas.set_meta(_CURSOR_META, 0)
	canvas.set_meta(_ACTIVE_META, true)
	if canvas == wnd:
		bind_text_clip(canvas, wnd)


static func end_window(canvas: CanvasItem) -> void:
	var slots: Array = canvas.get_meta(_SLOTS_META, [])
	var used := int(canvas.get_meta(_CURSOR_META, 0))
	for index in range(used, slots.size()):
		var slot: Dictionary = slots[index]
		RenderingServer.canvas_item_set_visible(slot["rid"], false)
	canvas.set_meta(_ACTIVE_META, false)


static func release_canvas(canvas: CanvasItem) -> void:
	var slots: Array = canvas.get_meta(_SLOTS_META, [])
	for value in slots:
		var rid: RID = value["rid"]
		if rid.is_valid():
			RenderingServer.free_rid(rid)
	for meta_name in [_SLOTS_META, _CURSOR_META, _ACTIVE_META]:
		if canvas.has_meta(meta_name):
			canvas.remove_meta(meta_name)


static func draw_window(canvas: CanvasItem, wnd, state: int) -> void:
	var automatic_frame := not bool(canvas.get_meta(_ACTIVE_META, false))
	if automatic_frame:
		begin_window(canvas, wnd)
	var selected := resolve_state(wnd, state)
	if selected >= 0:
		draw_images(canvas, wnd, selected, wnd.images_by_state[selected])
	if automatic_frame:
		end_window(canvas)


static func draw_images(canvas: CanvasItem, wnd, state: int, raw_images: Array) -> void:
	var automatic_frame := not bool(canvas.get_meta(_ACTIVE_META, false))
	if automatic_frame:
		begin_window(canvas, wnd)

	var decoded := decode_state(wnd, state, raw_images)
	var commands := build_rect_commands(
		decoded["images"],
		get_clip_bounds(wnd, true),
		0,
		fade_image_list_argb(0xffffffff, int(decoded["fade_byte"])),
		float(decoded["saturation"]),
		0.0
	)
	for command in commands:
		_submit_command(canvas, command)

	if automatic_frame:
		end_window(canvas)


static func _submit_command(canvas: CanvasItem, command: Dictionary) -> void:
	var slots: Array = canvas.get_meta(_SLOTS_META, [])
	var cursor := int(canvas.get_meta(_CURSOR_META, 0))
	var slot: Dictionary

	if cursor == slots.size():
		var new_rid := RenderingServer.canvas_item_create()
		var new_material := ShaderMaterial.new()
		new_material.shader = _get_image_shader()
		slot = {"rid": new_rid, "material": new_material}
		slots.append(slot)
		canvas.set_meta(_SLOTS_META, slots)
	else:
		slot = slots[cursor]

	var rid: RID = slot["rid"]
	var material: ShaderMaterial = slot["material"]
	var texture: Texture2D = command.get("texture") as Texture2D
	var source: Vector4 = command["source_rect"]
	var destination: Vector4 = command["destination_rect"]
	var tile: Vector4 = command["tile_rect"]
	var flags := int(command["raw_draw_flags"])
	var wrap := Vector2(float(command["wrap_width"]), float(command["wrap_height"]))

	# ASSUMPTION: wrap dimensions are source-pixel periods, 0/65535 disable
	# wrapping, and negative periods anchor at the opposite authored edge.
	# The unavailable consumer does not establish initial atlas-subrect phase.
	# Keep unchanged source intervals identical to the original plain quads;
	# enable wrapping on axes extended by ScaleImage.
	# Claude: an authored source interval LONGER than its period is a tiled strip (login.gui top/bottom bands:
	# source x -1180..308 with period 100 repeat the 100 px at 208..308); anchor the period at the edge that lies
	# inside the texture. Shorter intervals keep the plain-quad behaviour.
	var tex_size := Vector2(texture.get_width(), texture.get_height()) if texture != null else Vector2.ZERO
	wrap.x = _wrap_axis_period(wrap.x, tile.x, tile.z, tex_size.x)
	wrap.y = _wrap_axis_period(wrap.y, tile.y, tile.w, tex_size.y)

	material.set_shader_parameter("gui_texture", texture)
	material.set_shader_parameter("gui_has_texture", texture != null)
	material.set_shader_parameter(
		"gui_texture_size",
		Vector2(texture.get_width(), texture.get_height()) if texture != null else Vector2.ONE
	)
	material.set_shader_parameter("gui_multiply", color_from_argb(int(command["multiply_argb"])))
	material.set_shader_parameter("gui_add", color_from_argb(int(command["add_argb"])))
	material.set_shader_parameter("gui_clip_rect", command["clip_rect"])
	material.set_shader_parameter("gui_tile_rect", tile)
	material.set_shader_parameter("gui_wrap", wrap)
	material.set_shader_parameter("gui_mirror_wrap", (flags & IDF_MIRROR_WRAP) != 0)
	material.set_shader_parameter("gui_alpha_test", (flags & IDF_DISABLE_ALPHA_TEST) == 0)
	material.set_shader_parameter("gui_saturation", float(command["saturation"]))
	material.set_shader_parameter("gui_hue", float(command["hue"]))

	RenderingServer.canvas_item_set_parent(rid, canvas.get_canvas_item())
	RenderingServer.canvas_item_set_draw_behind_parent(rid, true)
	RenderingServer.canvas_item_set_draw_index(rid, cursor)
	RenderingServer.canvas_item_set_material(rid, material.get_rid())
	RenderingServer.canvas_item_set_visible(rid, true)
	RenderingServer.canvas_item_clear(rid)

	# Signed destination/source edges are retained independently. No transform
	# reversal or atlas-wide repeat is needed to implement flipped images.
	var points := PackedVector2Array([
		Vector2(destination.x, destination.y),
		Vector2(destination.z, destination.y),
		Vector2(destination.z, destination.w),
		Vector2(destination.x, destination.w)
	])
	var uvs := PackedVector2Array([
		Vector2(source.x, source.y),
		Vector2(source.z, source.y),
		Vector2(source.z, source.w),
		Vector2(source.x, source.w)
	])
	RenderingServer.canvas_item_add_polygon(
		rid, points, PackedColorArray([Color.WHITE]), uvs, RID()
	)
	canvas.set_meta(_CURSOR_META, cursor + 1)


static func _wrap_axis_period(period: float, a: float, b: float, tex_extent: float) -> float:
	var p := absf(period)
	if p < 0.5 or p >= 65535.0 or absf(b - a) <= p + 0.5:
		return 0.0
	var a_in := a >= -0.5 and a <= tex_extent + 0.5
	var b_in := b >= -0.5 and b <= tex_extent + 0.5
	if b_in and not a_in:
		return -p
	if a_in and not b_in:
		return p
	return period
