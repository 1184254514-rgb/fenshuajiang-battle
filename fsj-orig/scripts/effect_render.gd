class_name EffectRender
extends RefCounted
const UnitsTrail = preload("res://scripts/effect_units_trail.gd")
const ModelUnits = preload("res://scripts/effect_units_model.gd")
## Godot rendering adapters. Simulation and billboarding happen in EffectEval.
##
## The source's "source_blend" parser fields actually contain EBlendMode
## presets; its "destination_blend" fields contain depth modes. Neither is
## sufficient to reconstruct source/destination blend factors without the
## omitted PrepareMaterial implementation.
##
## ASSUMPTION: Preset 1 is ordinary alpha; 2 is alpha-weighted addition, as
## suggested by the paired judgement sprites. Approximate 3 with multiply,
## 8 with addition, and unknown presets with alpha blending. Preset 11's
## framebuffer distortion cannot be recovered and uses alpha blending.
##
## Override a recovered preset before spawning effects, for example:
##     EffectRender.blend_overrides[8] = "premul"
## Valid mappings: "mix", "add", "sub", "mul", "premul".
##
## Native material constants:
## [CanvasItemMaterial](https://docs.godotengine.org/en/latest/classes/class_canvasitemmaterial.html)
## [BaseMaterial3D](https://docs.godotengine.org/en/latest/classes/class_basematerial3d.html)
##
## ASSUMPTION: Neutral effects use native unshaded materials. Non-neutral
## hue/saturation/additive colors use shaders because the native materials
## cannot express the source color transform. BuildColorTransform is absent:
## use a gray-axis hue rotation, luminance saturation, brightness, then
## additive color, followed by diffuse modulation.
##
## ASSUMPTION: PNGs use straight alpha and ordinary sRGB texture imports.
## Source lighting, framebuffer-dependent passes, and terrain height
## sampling are unavailable. Terrain sprites use a flat plane and an
## approximate static edge fade. +0xec/+0xf4 are NOT animated as UV scroll:
## the supplied renderer never multiplies them by elapsed time.
##
## Not runtime-tested in this response.

static var blend_overrides: Dictionary = {}
static var _canvas_materials: Dictionary = {}
static var _shaders: Dictionary = {}
static var _meshes: Dictionary = {}

const COLOR_SHADER: String = """
uniform float hue_turns = 0.0;
uniform float saturation = 1.0;
uniform float brightness = 1.0;
uniform vec4 additive = vec4(0.0);
uniform vec2 edge_width = vec2(0.0);
uniform vec2 edge_center = vec2(0.0);

vec3 effect_rgb(vec3 rgb) {
	float angle = hue_turns * 6.283185307179586;
	vec3 axis = vec3(0.577350269189626);
	float c = cos(angle);
	float s = sin(angle);
	vec3 shifted = rgb * c + cross(axis, rgb) * s
		+ axis * dot(axis, rgb) * (1.0 - c);
	float luminance = dot(shifted, vec3(0.299, 0.587, 0.114));
	return mix(vec3(luminance), shifted, saturation) * brightness
		+ additive.rgb;
}

float effect_edge(vec2 uv) {
	vec2 distance_to_edge = vec2(0.5) - abs(uv - vec2(0.5) - edge_center);
	float x = 1.0;
	float y = 1.0;
	if (edge_width.x > 0.000001) {
		x = clamp(distance_to_edge.x / edge_width.x, 0.0, 1.0);
	}
	if (edge_width.y > 0.000001) {
		y = clamp(distance_to_edge.y / edge_width.y, 0.0, 1.0);
	}
	return x * y;
}
"""


static func u1_context(
	host: Node, evaluation: EffectEval, context: Dictionary
) -> Dictionary:
	return UnitsTrail.context_for(host, evaluation, context, blend_overrides)

static func u1_has_tails(host: Node) -> bool:
	return UnitsTrail.has_tails(host)

static func prepare_model_units(
	owner: Node, evaluator: EffectEval, context: Dictionary
) -> void:
	context["u2_blend_overrides"] = blend_overrides
	ModelUnits.prepare(owner, evaluator, context)

static func update_model_units(owner: Node) -> void:
	ModelUnits.update(owner)

static func blend_name(preset: int) -> String:
	var mode: String = str(blend_overrides.get(preset, ""))
	if mode in ["mix", "add", "sub", "mul", "premul"]:
		return mode
	match preset:
		2, 8:
			return "add"
		3:
			return "mul"
		_:
			return "mix"


static func _canvas_blend(mode: String) -> int:
	match mode:
		"add":
			return CanvasItemMaterial.BLEND_MODE_ADD
		"sub":
			return CanvasItemMaterial.BLEND_MODE_SUB
		"mul":
			return CanvasItemMaterial.BLEND_MODE_MUL
		"premul":
			return CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		_:
			return CanvasItemMaterial.BLEND_MODE_MIX


static func _world_blend(mode: String) -> int:
	match mode:
		"add":
			return BaseMaterial3D.BLEND_MODE_ADD
		"sub":
			return BaseMaterial3D.BLEND_MODE_SUB
		"mul":
			return BaseMaterial3D.BLEND_MODE_MUL
		"premul":
			return BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
		_:
			return BaseMaterial3D.BLEND_MODE_MIX


static func canvas_material(mode: String) -> CanvasItemMaterial:
	if not _canvas_materials.has(mode):
		var material: CanvasItemMaterial = CanvasItemMaterial.new()
		material.blend_mode = _canvas_blend(mode)
		material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_canvas_materials[mode] = material
	return _canvas_materials[mode]


static func needs_shader(packet: Dictionary) -> bool:
	var additive: Color = packet["add"]
	var fade: Vector2 = packet["fade"]
	var hue: float = fposmod(float(packet["hue"]), 1.0)
	return (
		not is_zero_approx(hue)
		or not is_equal_approx(float(packet["saturation"]), 1.0)
		or not is_equal_approx(float(packet["brightness"]), 1.0)
		or additive != Color(0, 0, 0, 0)
		or fade.length_squared() > 0.000000000001
	)


static func shader_for(world: bool, mode: String, depth: int) -> Shader:
	var key: String = "%s:%s:%d" % [str(world), mode, depth]
	if _shaders.has(key):
		return _shaders[key]
	var blend: String = "blend_" + mode
	if mode == "premul":
		blend = "blend_premul_alpha"
	var source: String
	if world:
		var depth_mode: String = "depth_draw_always"
		if depth == 2:
			depth_mode = "depth_draw_never"
		var modes: String = (
			"unshaded, cull_disabled, fog_disabled, "
			+ blend + ", " + depth_mode
		)
		if depth == 0:
			modes += ", depth_test_disabled"
		source = (
			"shader_type spatial;\nrender_mode " + modes + ";\n"
			+ COLOR_SHADER
			+ """
uniform sampler2D image_texture : source_color, filter_linear, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 atlas_rect = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec4 texel = texture(image_texture, atlas_rect.xy + UV * atlas_rect.zw);
	ALBEDO = effect_rgb(texel.rgb) * tint.rgb;
	ALPHA = clamp(texel.a + additive.a, 0.0, 1.0)
		* tint.a * effect_edge(UV);
}
"""
		)
	else:
		source = (
			"shader_type canvas_item;\nrender_mode unshaded, "
			+ blend + ";\n" + COLOR_SHADER
			+ """
uniform vec4 atlas_rect = vec4(0.0, 0.0, 1.0, 1.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec2 extent = atlas_rect.zw;
	if (abs(extent.x) < 0.000001) { extent.x = 1.0; }
	if (abs(extent.y) < 0.000001) { extent.y = 1.0; }
	vec2 local_uv = (UV - atlas_rect.xy) / extent;
	COLOR = vec4(
		effect_rgb(texel.rgb) * vertex_tint.rgb,
		clamp(texel.a + additive.a, 0.0, 1.0) * vertex_tint.a
			* effect_edge(local_uv)
	);
}
"""
		)
	var shader: Shader = Shader.new()
	shader.code = source
	_shaders[key] = shader
	return shader


static func effective_uv(packet: Dictionary) -> Rect2:
	var rectangle: Rect2 = packet["uv"]
	if int(packet["strips"]) > 1:
		var texture: Texture2D = packet["texture"]
		var inset: float = signf(rectangle.size.x) / maxf(1.0, texture.get_width())
		rectangle.position.x += inset
		rectangle.size.x -= 2.0 * inset
	return rectangle


static func set_uniforms(
	material: ShaderMaterial, packet: Dictionary, rectangle: Rect2, world: bool
) -> void:
	material.set_shader_parameter("hue_turns", float(packet["hue"]))
	material.set_shader_parameter("saturation", float(packet["saturation"]))
	material.set_shader_parameter("brightness", float(packet["brightness"]))
	material.set_shader_parameter("additive", packet["add"])
	material.set_shader_parameter("edge_width", packet["fade"])
	material.set_shader_parameter("edge_center", packet["fade_center"])
	material.set_shader_parameter("atlas_rect", Vector4(
		rectangle.position.x, rectangle.position.y,
		rectangle.size.x, rectangle.size.y
	))
	if world:
		material.set_shader_parameter("tint", packet["tint"])
		material.set_shader_parameter("image_texture", packet["texture"])


static func quad_mesh(strips: int) -> ArrayMesh:
	strips = clampi(strips, 1, 56)
	if _meshes.has(strips):
		return _meshes[strips]
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var coordinates: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for i in range(strips):
		var first: float = float(i) / float(strips)
		var last: float = float(i + 1) / float(strips)
		var x0: float = -1.0 + 2.0 * first
		var x1: float = -1.0 + 2.0 * last
		var base: int = vertices.size()
		vertices.append_array(PackedVector3Array([
			Vector3(x0, 1, 0), Vector3(x1, 1, 0),
			Vector3(x1, -1, 0), Vector3(x0, -1, 0)
		]))
		for unused in range(4):
			normals.append(Vector3.BACK)
		# The source maps successive texture rows into successive X strips.
		# ASSUMPTION: arySpriteRectInfo uses the ordinary xy/width/height
		# convention, since the source shader itself is not supplied.
		coordinates.append_array(PackedVector2Array([
			Vector2(0, first), Vector2(1, first),
			Vector2(1, last), Vector2(0, last)
		]))
		indices.append_array(PackedInt32Array([
			base, base + 1, base + 2, base, base + 2, base + 3
		]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = coordinates
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[strips] = mesh
	return mesh


class CanvasQuad extends Node2D:
	var _texture: Texture2D
	var _polygons: Array = []
	var _coordinates: Array = []
	var _colors: PackedColorArray = PackedColorArray()
	var _shader_material: ShaderMaterial

	func update_quad(packet: Dictionary, parent_inverse: Transform2D) -> void:
		_texture = packet["texture"]
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		# ASSUMPTION: Repeat addressing, including UV rectangles outside 0..1.
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		z_index = clampi(int(packet["order"]), -4096, 4095)
		var mode: String = EffectRender.blend_name(int(packet["blend"]))
		var rectangle: Rect2 = EffectRender.effective_uv(packet)
		if EffectRender.needs_shader(packet):
			if _shader_material == null:
				_shader_material = ShaderMaterial.new()
			_shader_material.shader = EffectRender.shader_for(false, mode, 2)
			EffectRender.set_uniforms(_shader_material, packet, rectangle, false)
			material = _shader_material
		else:
			material = EffectRender.canvas_material(mode)

		var tint: Color = packet["tint"]
		_colors = PackedColorArray([tint, tint, tint, tint])
		_polygons.clear()
		_coordinates.clear()
		var matrix: Transform3D = packet["xf"]
		var strips: int = clampi(int(packet["strips"]), 1, 56)
		for i in range(strips):
			var first: float = float(i) / float(strips)
			var last: float = float(i + 1) / float(strips)
			var x0: float = -1.0 + 2.0 * first
			var x1: float = -1.0 + 2.0 * last
			var local_points: Array = [
				Vector3(x0, -1, 0), Vector3(x1, -1, 0),
				Vector3(x1, 1, 0), Vector3(x0, 1, 0)
			]
			var polygon: PackedVector2Array = PackedVector2Array()
			for point_value in local_points:
				var point: Vector3 = matrix * Vector3(point_value)
				polygon.append(parent_inverse * Vector2(point.x, point.y))
			_polygons.append(polygon)
			_coordinates.append(PackedVector2Array([
				rectangle.position + Vector2(0, first) * rectangle.size,
				rectangle.position + Vector2(1, first) * rectangle.size,
				rectangle.position + Vector2(1, last) * rectangle.size,
				rectangle.position + Vector2(0, last) * rectangle.size
			]))
		visible = true
		queue_redraw()

	func _draw() -> void:
		# [CanvasItem drawing](https://docs.godotengine.org/en/latest/classes/class_canvasitem.html)
		# Keep the texture in a member: drawing executes after this callback.
		if _texture == null:
			return
		for i in range(_polygons.size()):
			draw_primitive(_polygons[i], _colors, _coordinates[i], _texture)


class WorldQuad extends MeshInstance3D:
	var _standard_material: StandardMaterial3D
	var _shader_material: ShaderMaterial

	func update_quad(packet: Dictionary, parent_inverse: Transform3D) -> void:
		mesh = EffectRender.quad_mesh(int(packet["strips"]))
		transform = parent_inverse * Transform3D(packet["xf"])
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mode: String = EffectRender.blend_name(int(packet["blend"]))
		var depth: int = int(packet["depth"])
		var priority: int = clampi(int(packet["order"]), -128, 127)
		var rectangle: Rect2 = EffectRender.effective_uv(packet)
		if EffectRender.needs_shader(packet):
			if _shader_material == null:
				_shader_material = ShaderMaterial.new()
			_shader_material.shader = EffectRender.shader_for(true, mode, depth)
			_shader_material.render_priority = priority
			EffectRender.set_uniforms(_shader_material, packet, rectangle, true)
			material_override = _shader_material
		else:
			if _standard_material == null:
				_standard_material = StandardMaterial3D.new()
				_standard_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				_standard_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				_standard_material.cull_mode = BaseMaterial3D.CULL_DISABLED
				_standard_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
				_standard_material.texture_repeat = true
				_standard_material.disable_fog = true
				# Billboarding is already reflected in the packet's basis.
				_standard_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
			_standard_material.blend_mode = EffectRender._world_blend(mode)
			_standard_material.no_depth_test = depth == 0
			_standard_material.depth_draw_mode = (
				BaseMaterial3D.DEPTH_DRAW_DISABLED if depth == 2
				else BaseMaterial3D.DEPTH_DRAW_ALWAYS
			)
			_standard_material.render_priority = priority
			_standard_material.albedo_texture = packet["texture"]
			_standard_material.albedo_color = packet["tint"]
			_standard_material.uv1_offset = Vector3(
				rectangle.position.x, rectangle.position.y, 0
			)
			_standard_material.uv1_scale = Vector3(
				rectangle.size.x, rectangle.size.y, 1
			)
			material_override = _standard_material
		visible = true
