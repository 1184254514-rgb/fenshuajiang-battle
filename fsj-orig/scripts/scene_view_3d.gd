class_name SceneView3D
extends SceneView

signal item_animation_finished(item_id: int, animation_name: String)

const TILE := 1.0
# World units (from the APK): gameplay/scene units are 16 per grid node (CManorLineClient::DeleteFromLastTo
# multiplies positions by 0.0625); models are scaled by equip.txt nScale 0.36 (CGameRenderObject::OnEquipUpdated).
# Our glTF already divides model units by 64, so a model needs 0.36 * 64 / 16 = 1.44.
const ENGINE_PER_NODE := 16.0
const EQUIP_SCALE := 0.36
const CHAR_SCALE := EQUIP_SCALE * 64.0 / ENGINE_PER_NODE
const UNIT_INTERVAL := 1.0
const INIT_RHYTHM_ID := 0
const INIT_LINE_RHYTHM_ID := 3
const BLOCK_CHUNK := 10

# ASSUMPTION: factor.y = 8 - UnitInterval is the manor's horizontal half extent.
# This gives a 14 px footprint and a 2 px gap, rather than the previous 15 px footprint.
const CELL := (16.0 - 2.0 * UNIT_INTERVAL) / 16.0
const PRESS_R := 3
const FADE_IN := 0.4
const FADE_OUT := 1.0
const LINE_FADE_UNIT := 0.012
const LINE_FADE := FADE_OUT

# An explicit texture overrides GuiRuntime's original peise.tex.
@export var block_palette_texture: Texture2D

# The source bound at CGameAppClient + 0x258 is distinct from peise.tex.
# Its resource name is absent from the supplied disassembly.
@export var original_ground_texture: Texture2D

@export var block_ai_is_jump := true
@export_range(0, 10000, 1) var block_jump_ratio := 3800
@export var block_move_radius_px := 48.0
@export var block_light_direction_engine := Vector3(0.0, -10.0, 3.0)

# CSnakeConstant + 0x4c is FadeInInterval (constant.txt 400 ms; offset table from CSnakeConstant::OnLoadedEnd).
# RenderImp uses this same field for both rise and disappearance (Claude).
@export var block_native_ramp_ms := 400.0

var network_replica := false
var world: Node3D
var camera: Camera3D
var map_inst: Node3D

# These retain the previous handles. Rendering now uses one mutually exclusive
# manor/line instance per cell, distributed over 10x10 chunks.
# tiles and trails refer to the first chunk; _block_chunks contains every chunk.
var tiles: MultiMeshInstance3D
var trails: MultiMeshInstance3D
var ground: MultiMeshInstance3D

var _block_chunks: Array[MultiMeshInstance3D] = []
var _cell_chunk := PackedInt32Array()
var _cell_slot := PackedInt32Array()
var _block_data := PackedColorArray()
var _block_mesh: ArrayMesh
var _block_material: ShaderMaterial
var _peise: Texture2D

var _val := PackedByteArray()
var _line_val := PackedByteArray()
var _line_colour := PackedByteArray()
var _capture_time := PackedFloat32Array()

# Heights here are the native byte-valued engine heights, not node heights.
var _heights := [36.0, 22.0, 10.0, 2.0, 2.0]
var _jumps := [true, true, false, false, false]
var _jumpers: Dictionary = {}

# idx -> native absolute height cap, equivalent to CManorUnitClient + 0x1d.
var _pressed: Dictionary = {}
var _press_sources: Dictionary = {}
var _press_dirty := true

# Local-clock timestamps; animation itself runs in the vertex shader.
var _rise: Dictionary = {}          # idx -> capture timestamp
var _sink: Dictionary = {}          # idx -> [disappearance deadline, saved colour]
var _trail_fade: Dictionary = {}    # idx -> [disappearance deadline, saved colour, grade]
var _trail_fade_order := 0
var _trail_fade_frame := -1

# Min-heap entries: [deadline, event kind, cell index, generation timestamp].
# kind: 0 manor disappearance, 1 line disappearance, 2 capture bookkeeping.
var _expiry_events: Array = []

var _trail_members: Dictionary = {}
var _known_player_colours: Dictionary = {}
# Manor IDs are persistent ownership identities, independent of the reusable colour slot.
var _manor_colours: Dictionary = {}
var _player_skill_states: Dictionary = {}

var _shadow_image: Image
var _shadow_texture: ImageTexture
var _shadow_bytes := PackedByteArray()
var _shadow_dirty := false

var _clock_origin_ms := 0
var _beat_index := 0
var _beat_phase := 1.0
var _last_beat_ms := -1.0

var actors: Dictionary = {}
var cam_target := Vector3.ZERO
const CAM_BACK := 300.0 / 16.0   # CGameSceneClient::UpdateCamera: pos = dest + (0, MinCameraY..MaxCameraY, -CameraZ)
const CAM_UP_MIN := 350.0 / 16.0
const CAM_UP_MAX := 430.0 / 16.0
var cam_up := CAM_UP_MIN
var HIDDEN := Transform3D(
	Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)),
	Vector3(0, -50, 0)
)

# INSTANCE_CUSTOM:
# r = native packed palette word: 1 + (5 * colour + grade) / 128 + 1 / 512
# g = capture timestamp or disappearance deadline, in scene-local seconds
# b = native byte-valued logic height cap
# a = mode + 8 * checkerboard parity
#
# mode: 0 absent, 1 live manor, 2 departing manor, 3 live line, 4 departing line,
# 5/6 local invisible-player live/departing line (screen-door translucent).
#
# peise.png is 128x128: rows (5 * colour + grade) select ten hues and five
# rhythm brightness grades; horizontal coordinates retain the baked Lambert lookup.
# ASSUMPTION: the manor/line cutoff uploaded in factor.w selects gapped manor
# footprints versus full-cell line footprints. The missing shader prevents proof.
# ASSUMPTION: the normal packed-word branch is opaque. The special player-state
# branch producing a word below 1 cannot be selected through the supplied API.
const BLOCK_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D peise : source_color, filter_linear, repeat_disable;

uniform vec4 height_engine_1_4 = vec4(36.0, 22.0, 10.0, 2.0);
uniform float height_engine_5 = 2.0;
uniform vec4 jump_flags_1_4 = vec4(1.0, 1.0, 0.0, 0.0);
uniform float jump_flag_5 = 0.0;

uniform float clock_s = 0.0;
uniform float fade_ramp_s = 0.4;
uniform float beat_remaining = 1.0;
uniform int beat_index = 0;
uniform float jump_ratio = 0.38;
uniform bool ai_is_jump = true;
uniform int local_colour = -1;
uniform float line_width_ratio = 1.142857142857;

varying float palette_v;
varying float draw_cell;
varying float draw_opacity;

float native_height(int grade) {
	if (grade < 4) {
		return height_engine_1_4[grade];
	}
	return height_engine_5;
}

float native_jump_flag(int grade) {
	if (grade < 4) {
		return jump_flags_1_4[grade];
	}
	return jump_flag_5;
}

void vertex() {
	int tag = int(floor(INSTANCE_CUSTOM.a + 0.5));
	int mode = tag % 8;
	int xy_parity = tag / 8;

	int code = clamp(
		int(floor(fract(INSTANCE_CUSTOM.r) * 128.0)),
		0,
		49
	);
	int grade = code % 5;
	int colour = code / 5;

	float target_height = native_height(grade);
	float height = target_height;
	float stamp = INSTANCE_CUSTOM.g;
	float ramp = max(fade_ramp_s, 0.000001);

	draw_cell = 0.0;
	draw_opacity = (mode == 5 || mode == 6) ? 0.35 : 1.0;

	// CManorBlockRenderable::RenderImp (0x38d9b6..0x38dbbc): jumping grades (IsJump) shrink linearly from 100% to
	// (1 - JumpRatio) over each beat; manor cells alternate by (valuation + beat), live lines by (x + y + beat).
	float beat_scale = 1.0;
	bool eligible = native_jump_flag(grade) != 0.0;
	eligible = eligible && (ai_is_jump || colour == local_colour);

	if (eligible && (mode == 1 || mode == 3 || mode == 5)) {
		int selector = grade;
		if (mode == 3 || mode == 5) {
			selector = xy_parity;
		}
		if (((selector + beat_index) % 2) == 0) {
			beat_scale = 1.0 - jump_ratio + jump_ratio * beat_remaining;
		}
	}

	if (mode == 1) {
		if (clock_s > stamp) {
			draw_cell = 1.0;
		}
		float rise = clamp((clock_s - stamp) / ramp, 0.0, 1.0);
		height = min(target_height, INSTANCE_CUSTOM.b);
		height *= beat_scale * rise;
	} else if (mode == 2) {
		if (clock_s < stamp) {
			draw_cell = 1.0;
		}
		// The departing-manor branch ignores the live cap and beat multiplier.
		height = target_height * clamp((stamp - clock_s) / ramp, 0.0, 1.0);
	} else if (mode == 3 || mode == 5) {
		draw_cell = 1.0;
		// RenderImp converts the beat-adjusted live-line height to a byte.
		height = floor(target_height * beat_scale);
	} else if (mode == 4 || mode == 6) {
		if (clock_s < stamp) {
			draw_cell = 1.0;
		}
		// The lingering-line branch uploads the full table height.
		height = target_height;
	}

	palette_v = (float(code) + 0.5) / 128.0;

	if (draw_cell < 0.5) {
		VERTEX = vec3(0.0);
	} else {
		if (mode == 3 || mode == 4 || mode == 5 || mode == 6) {
			VERTEX.x *= line_width_ratio;
			VERTEX.z *= line_width_ratio;
		}
		// Mesh bottom remains at zero: this changes height, not vertical position.
		// A pressed cell of height zero retains its coloured top footprint.
		// block heights are scene units (16 per node): RenderImp uploads the raw Height byte next to the
		// (cell + 0.5) * 16 centre; measured in the reference video a Height1=36 block stands ~2.25 cells (Claude)
		VERTEX.y *= height / 16.0;
	}
}

void fragment() {
	if (draw_cell < 0.5) {
		discard;
	}
	// Screen-door coverage keeps the terrain in the opaque pass while showing
	// the local hidden trail against the original floor.
	if (draw_opacity < 1.0) {
		float checker = mod(floor(FRAGCOORD.x) + 2.0 * floor(FRAGCOORD.y), 3.0);
		if (checker > 0.5) { discard; }
	}
	ALBEDO = texture(peise, vec2(UV.x, palette_v)).rgb;
}
"""

# ASSUMPTION: the missing ground shader multiplies the floor colour by the binary
# occupancy texture. The recovered CPU code establishes the mask, not its blend.
# ASSUMPTION: when the separate original ground texture is unavailable, peise's
# grey row is a neutral fallback. No invented checkerboard or raised empty cubes.
const GROUND_SHADER_CODE := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;

uniform sampler2D peise : source_color, filter_linear, repeat_disable;
uniform sampler2D ground_diffuse : source_color, filter_linear, repeat_enable;
uniform sampler2D occupancy : filter_nearest, repeat_disable;
uniform bool has_ground_diffuse = false;
uniform vec2 ground_uv_repeat = vec2(1.0);

void fragment() {
	vec3 colour = texture(peise, vec2(0.5, 50.5 / 128.0)).rgb;
	if (has_ground_diffuse) {
		// the original shows the tcs_dt grid as light-blue cells (#9ED8EA, measured from gameplay video) with
		// whiter seams: keep the texture's light/dark pattern, take the hue from that tint (Claude)
		vec3 base = texture(ground_diffuse, UV * ground_uv_repeat).rgb;
		float lum = dot(base, vec3(0.299, 0.587, 0.114));
		colour = clamp(vec3(0.62, 0.847, 0.918) * (lum / 0.80), 0.0, 1.0);
	}
	float empty_mask = texture(occupancy, UV).r;
	ALBEDO = colour * empty_mask;
}
"""


func _ready() -> void:
	super._ready()
	# the original ground texture (CGameAppClient + 0x258): gui/tex/tcs_dt.tex, a 256 px grid of 16 px cells (Claude)
	if original_ground_texture == null and ResourceLoader.exists("res://assets/tex/tcs_dt.png"):
		original_ground_texture = load("res://assets/tex/tcs_dt.png")


func _w2v(x: float, y: float, h := 0.0) -> Vector3:
	return Vector3(x / NODE, h, -y / NODE)


var _scene_start_ms := 0

func begin_scene(w: int, h: int) -> void:
	network_replica = false
	super.begin_scene(w, h)
	_scene_start_ms = Time.get_ticks_msec()
	if world != null:
		world.queue_free()
	world = Node3D.new()
	add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.62, 0.8, 0.95)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.85, 0.9)
	e.ambient_light_energy = 0.9
	env.environment = e
	world.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-62, 20, 0)
	sun.light_energy = 0.8
	world.add_child(sun)

	# the map decoration (map01 + obj_03 fences) is created by CGameScene::CreateMapItem from map.txt (Claude)

	_clock_origin_ms = Time.get_ticks_msec()
	_make_block_field(w, h)

	camera = Camera3D.new()
	camera.fov = rad_to_deg(8000.0 / 10000.0)   # UpdateCamera: SetFovY(CameraFov / 10000) rad
	camera.near = 0.5
	camera.far = 600.0
	world.add_child(camera)
	camera.make_current()
	cam_target = _w2v(w * NODE * 0.5, h * NODE * 0.5)
	_place_camera(true)


func _make_unshaded(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			var m = mi.get_active_material(si)
			if m is StandardMaterial3D:
				var u := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				u.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				mi.set_surface_override_material(si, u)
	for c in n.get_children():
		_make_unshaded(c)


func _now_s() -> float:
	return float(Time.get_ticks_msec() - _clock_origin_ms) / 1000.0


func _ramp_s() -> float:
	return maxf(block_native_ramp_ms / 1000.0, 0.000001)


func _load_block_palette() -> Texture2D:
	var tex: Texture2D = block_palette_texture
	if tex == null:
		tex = GuiRuntime.atlas("peise.tex")
	if tex is AtlasTexture:
		# ShaderMaterial needs the palette's own UV domain, not its atlas region.
		var palette_image := tex.get_image()
		if palette_image != null and not palette_image.is_empty():
			tex = ImageTexture.create_from_image(palette_image)
	if tex != null:
		return tex

	# ASSUMPTION: fallback only. Three supplied samples cannot reconstruct all
	# 128 original columns. Using the actual peise.tex avoids this approximation.
	var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(_rgb(0x373936))
	for row in range(10):
		for x in range(128):
			var colour: Color
			if x <= 36:
				colour = _rgb(PALETTE_DARK[row])
			elif x <= 83:
				colour = _color_of(row)
			else:
				colour = _rgb(PALETTE_LIGHT[row])
			for grade in range(5):
				image.set_pixel(x, row * 5 + grade, colour)
	return ImageTexture.create_from_image(image)


func _make_block_field(w: int, h: int) -> void:
	tiles = null
	trails = null
	ground = null
	_block_chunks.clear()
	_pressed.clear()
	_press_sources.clear()
	_rise.clear()
	_sink.clear()
	_trail_fade.clear()
	_jumpers.clear()
	_expiry_events.clear()
	_trail_members.clear()
	_known_player_colours.clear()
	_manor_colours.clear()
	_player_skill_states.clear()
	_trail_fade_order = 0
	_trail_fade_frame = -1
	_press_dirty = true
	_beat_index = 0
	_beat_phase = 1.0
	_last_beat_ms = -1.0

	var count := w * h
	_val = PackedByteArray()
	_val.resize(count)
	_val.fill(INIT_RHYTHM_ID)
	_line_val = PackedByteArray()
	_line_val.resize(count)
	_line_val.fill(INIT_LINE_RHYTHM_ID)
	_line_colour = PackedByteArray()
	_line_colour.resize(count)
	_capture_time = PackedFloat32Array()
	_capture_time.resize(count)
	_capture_time.fill(-1000.0)

	_cell_chunk = PackedInt32Array()
	_cell_chunk.resize(count)
	_cell_slot = PackedInt32Array()
	_cell_slot.resize(count)
	_block_data = PackedColorArray()
	_block_data.resize(count)

	_shadow_bytes = PackedByteArray()
	_shadow_bytes.resize(count)
	_shadow_bytes.fill(255)
	_shadow_image = Image.create(w, h, false, Image.FORMAT_R8)
	_shadow_image.fill(Color.WHITE)
	_shadow_texture = ImageTexture.create_from_image(_shadow_image)
	_shadow_dirty = false

	_peise = _load_block_palette()
	var shader := Shader.new()
	shader.code = BLOCK_SHADER_CODE
	_block_material = ShaderMaterial.new()
	_block_material.shader = shader
	_block_material.set_shader_parameter("peise", _peise)
	_block_material.set_shader_parameter("line_width_ratio", 1.0 / CELL)
	_reload_block_music()
	_block_mesh = _cell_box(CELL, 1.0)

	_make_ground(w, h)

	for cy in range(0, h, BLOCK_CHUNK):
		for cx in range(0, w, BLOCK_CHUNK):
			var cw := mini(BLOCK_CHUNK, w - cx)
			var ch := mini(BLOCK_CHUNK, h - cy)
			var chunk := _make_tiles(cw * ch, 1.0)
			chunk.position = Vector3(cx, 0.0, -cy)
			# Covers all possible byte-valued heights after vertex displacement.
			chunk.multimesh.custom_aabb = AABB(
				Vector3(-0.001, -0.01, -float(ch) - 0.001),
				Vector3(float(cw) + 0.002, 4.02, float(ch) + 0.002)
			)
			var chunk_id := _block_chunks.size()
			_block_chunks.append(chunk)

			for ly in range(ch):
				for lx in range(cw):
					var x := cx + lx
					var y := cy + ly
					var idx := y * w + x
					var slot := ly * cw + lx
					_cell_chunk[idx] = chunk_id
					_cell_slot[idx] = slot
					chunk.multimesh.set_instance_transform(
						slot,
						Transform3D(
							Basis.IDENTITY,
							Vector3(float(lx) + 0.5, 0.0, -float(ly) - 0.5)
						)
					)
					var data := Color(0.0, 0.0, 255.0, float(((x + y) & 1) * 8))
					_block_data[idx] = data
					chunk.multimesh.set_instance_custom_data(slot, data)

	if not _block_chunks.is_empty():
		tiles = _block_chunks[0]
		trails = tiles
	_update_jumpers()


func _make_ground(w: int, h: int) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.0, 0.0),
		Vector3(w, 0.0, 0.0),
		Vector3(w, 0.0, -h),
		Vector3(0.0, 0.0, -h),
	])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP,
	])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(1.0, 0.0),
		Vector2(1.0, 1.0), Vector2(0.0, 1.0),
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var shader := Shader.new()
	shader.code = GROUND_SHADER_CODE
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("peise", _peise)
	material.set_shader_parameter("occupancy", _shadow_texture)
	material.set_shader_parameter("has_ground_diffuse", original_ground_texture != null)
	material.set_shader_parameter(
		"ground_diffuse",
		original_ground_texture if original_ground_texture != null else _peise
	)
	if original_ground_texture != null:
		# ASSUMPTION: GetWidth/GetDepth in the floor's UV calculation are pixel
		# lengths. The +3 and division by source texture dimensions are recovered.
		material.set_shader_parameter(
			"ground_uv_repeat",
			Vector2(
				(float(w) * NODE + 3.0) / float(original_ground_texture.get_width()),
				(float(h) * NODE + 3.0) / float(original_ground_texture.get_height())
			)
		)
	mesh.surface_set_material(0, material)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = 1
	# ASSUMPTION: a small negative bias keeps a completely pressed top visible
	# over the ground without introducing a visible raised ground layer.
	mm.set_instance_transform(
		0, Transform3D(Basis.IDENTITY, Vector3(0.0, -0.002, 0.0))
	)
	ground = MultiMeshInstance3D.new()
	ground.multimesh = mm
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ground)


func _cell_box(size_xz: float, h: float) -> ArrayMesh:
	# RebuildBlockBuffer has 16 vertices and 8 triangles per cell:
	# top, native -Z, native -X, native +X. No bottom or native +Z face.
	var a := size_xz * 0.5
	var faces := [
		[
			Vector3(0, 1, 0), Vector3.UP,
			[
				Vector3(-a, h, -a), Vector3(a, h, -a),
				Vector3(a, h, a), Vector3(-a, h, a),
			],
		],
		[
			Vector3(0, 0, -1), Vector3(0, 0, 1),
			[
				Vector3(-a, h, a), Vector3(a, h, a),
				Vector3(a, 0, a), Vector3(-a, 0, a),
			],
		],
		[
			Vector3(-1, 0, 0), Vector3(-1, 0, 0),
			[
				Vector3(-a, h, -a), Vector3(-a, h, a),
				Vector3(-a, 0, a), Vector3(-a, 0, -a),
			],
		],
		[
			Vector3(1, 0, 0), Vector3(1, 0, 0),
			[
				Vector3(a, h, a), Vector3(a, h, -a),
				Vector3(a, 0, -a), Vector3(a, 0, a),
			],
		],
	]

	# ASSUMPTION: the scene light supplies a normalized direction to the native
	# renderer. RebuildBlockBuffer itself normalizes the normals, not the light.
	var light := block_light_direction_engine.normalized()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for face in faces:
		var native_normal: Vector3 = face[0]
		var godot_normal: Vector3 = face[1]
		var quad: Array = face[2]
		var lambert := clampf(-native_normal.normalized().dot(light), 0.0, 1.0)
		var shade_byte := int(floor(lambert * 255.0))
		var u := float(shade_byte) / 255.0
		var first := vertices.size()
		for k in range(4):
			vertices.append(quad[k])
			normals.append(godot_normal)
			uvs.append(Vector2(u, 0.0))
		for k in [0, 1, 2, 0, 2, 3]:
			indices.append(first + k)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _make_tiles(count: int, h: float, size_xz := CELL) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.use_colors = false
	mm.mesh = (
		_block_mesh
		if _block_mesh != null and h == 1.0 and size_xz == CELL
		else _cell_box(size_xz, h)
	)
	mm.instance_count = count
	for i in range(count):
		mm.set_instance_transform(i, HIDDEN)

	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = _block_material
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(inst)
	return inst


func _cell_xform(idx: int, _h: float, press := 1.0) -> Transform3D:
	var center := _w2v(
		(float(idx % gw) + 0.5) * NODE,
		(float(int(idx / gw)) + 0.5) * NODE
	)
	return Transform3D(Basis().scaled(Vector3(1, press, 1)), center)


func _rgb(v: int) -> Color:
	return Color.hex((v << 8) | 0xFF)


func _palette_word(colour: int, grade: int) -> float:
	return (
		1.0
		+ float(5 * posmod(colour, 10) + clampi(grade, 0, 4)) / 128.0
		+ 1.0 / 512.0
	)


func _reload_block_music() -> void:
	var defaults := [36.0, 22.0, 10.0, 2.0, 2.0]
	var default_jumps := [true, true, false, false, false]
	for k in range(5):
		var height_text := music_param("Height%d" % (k + 1))
		var jump_text := music_param("IsJump%d" % (k + 1))
		_heights[k] = (
			float(clampi(int(height_text.to_float()), 0, 255))
			if height_text.is_valid_float()
			else defaults[k]
		)
		_jumps[k] = (
			jump_text.to_float() != 0.0
			if jump_text.is_valid_float()
			else default_jumps[k]
		)

	_press_dirty = true
	if _block_material == null:
		return
	_block_material.set_shader_parameter(
		"height_engine_1_4",
		Vector4(_heights[0], _heights[1], _heights[2], _heights[3])
	)
	_block_material.set_shader_parameter("height_engine_5", float(_heights[4]))
	_block_material.set_shader_parameter(
		"jump_flags_1_4",
		Vector4(
			1.0 if _jumps[0] else 0.0,
			1.0 if _jumps[1] else 0.0,
			1.0 if _jumps[2] else 0.0,
			1.0 if _jumps[3] else 0.0
		)
	)
	_block_material.set_shader_parameter("jump_flag_5", 1.0 if _jumps[4] else 0.0)


func start_music(music_path: String, rhythm_path: String) -> void:
	super.start_music(music_path, rhythm_path)
	_reload_block_music()
	_update_jumpers()


func end_scene() -> void:
	super.end_scene()
	items.clear()
	_popups.clear()
	if world != null:
		world.queue_free()
		world = null
	actors.clear()

	tiles = null
	trails = null
	ground = null
	_block_chunks.clear()
	_block_material = null
	_block_mesh = null
	_peise = null
	_shadow_texture = null
	_shadow_image = null
	_pressed.clear()
	_press_sources.clear()
	_rise.clear()
	_sink.clear()
	_trail_fade.clear()
	_jumpers.clear()
	_expiry_events.clear()
	_trail_members.clear()
	_known_player_colours.clear()
	_manor_colours.clear()
	_player_skill_states.clear()


func set_cell_valuation(idx: int, grade: int) -> void:
	if idx < 0 or idx >= _val.size():
		return
	# SetValuation itself only writes the byte; it does not restart capture.
	_val[idx] = clampi(grade, 0, 4)

	# ASSUMPTION: this bridge's unqualified set_val also addresses a live line
	# occupying the cell. It has no manor/line discriminator.
	if trail_cells[idx] != 0:
		_line_val[idx] = _val[idx]
	if tiles != null:
		_apply_tile(idx)


# The Lua simulation assigns a colour slot once per live manor. Do not derive
# it from owner IDs: AI respawns allocate fresh manor IDs while reusing free hues.
func set_manor_colour(manor_id: int, colour_id: int) -> void:
	var colour := posmod(colour_id, 10)
	if int(_manor_colours.get(manor_id, -1)) == colour:
		return
	_manor_colours[manor_id] = colour
	for idx in owner_cells.size():
		if owner_cells[idx] == manor_id:
			_apply_tile(idx)


func _manor_colour_for(manor_id: int) -> int:
	# Unregistered legacy snapshots keep their original ID-based fallback.
	return int(_manor_colours.get(manor_id, posmod(manor_id - 1, 10)))


# Crossing one's own route retracts that suffix immediately, unlike death fades.
func clear_trail_cell(idx: int) -> void:
	_trail_fade.erase(idx)
	_apply_tile(idx)


# Visual skill state is independent of occupancy and collision state in Lua.
# camera_bonus is a current native-pixel height offset; the skill clock owns its ramp.
func set_skill_cast(id: int, serial: int, effect_path: String, age_ms: int, lifetime_ms: int) -> bool:
	if not actors.has(id) or serial <= 0:
		return false
	var actor: Dictionary = actors[id]
	if serial <= int(actor.get("cast_serial", 0)):
		return false
	actor["cast_serial"] = serial
	var old := actor.get("cast_fx") as Node3D
	if is_instance_valid(old): old.queue_free()
	actor["cast_fx"] = null
	if not bool(actor.get("alive", false)) or effect_path in ["", "0"]:
		return false
	if lifetime_ms > 0 and age_ms >= lifetime_ms:
		return false
	var stem := effect_path.replace("\\", "/").get_file().get_basename()
	var definition := EffectEval.load_effect(stem, "fx/cast")
	if definition.is_empty(): return false
	# Old packets must not replay a completed one-shot visual, even when the
	# skill's gameplay lifetime exceeds the authored cast animation length.
	if age_ms > int(definition.get("duration_ms", 1000)) + 1000:
		return false
	var node := actor["node"] as Node3D
	var effect := EffectPlayer3D.spawn_world(node, stem, "fx/cast", Vector3.ZERO, EQUIP_SCALE / ENGINE_PER_NODE, false) as EffectPlayer3D
	if effect == null: return false
	effect.attached_model = actor.get("model_node") as Node3D
	actor["cast_fx"] = effect
	actor["cast_effect_path"] = effect_path
	actor["cast_spawn_count"] = int(actor.get("cast_spawn_count", 0)) + 1
	if age_ms > 0: effect._update_effect(float(age_ms) / 1000.0)
	return true


func set_player_skill_state(id: int, hidden: bool, armor: int, camera_bonus: float = 0.0) -> void:
	var state := {"hidden": hidden, "armor": maxi(armor, 0), "camera_bonus": maxf(camera_bonus, 0.0)}
	if _player_skill_states.get(id, {}) == state:
		return
	_player_skill_states[id] = state
	_apply_player_skill_visuals(id)
	if _trail_members.has(id):
		for idx in _trail_members[id]:
			_apply_tile(int(idx))
	for idx in _trail_fade:
		if _fade_player(int(idx)) == id:
			_apply_tile(int(idx))
	if players.has(id) and bool(players[id].get("director", false)):
		_place_camera()
	queue_redraw()


func _is_player_hidden(id: int) -> bool:
	return bool(_player_skill_states.get(id, {}).get("hidden", false))


func _is_enemy_hidden(id: int) -> bool:
	return _is_player_hidden(id) and not (players.has(id) and bool(players[id].get("director", false)))


func _fade_player(idx: int) -> int:
	var entry: Array = _trail_fade.get(idx, [])
	return int(entry[3]) if entry.size() > 3 else 0


func _apply_player_skill_visuals(id: int) -> void:
	if not actors.has(id):
		return
	var actor: Dictionary = actors[id]
	var hidden := _is_player_hidden(id)
	var local_hidden := hidden and not _is_enemy_hidden(id)
	var armor := int(_player_skill_states.get(id, {}).get("armor", 0))
	var style_key := Vector3i(int(hidden), int(local_hidden), armor)
	if actor.get("skill_style_key", Vector3i(-1, -1, -1)) == style_key:
		return
	actor["skill_style_key"] = style_key
	var node := actor["node"] as Node3D
	if hidden and not local_hidden:
		node.visible = false
	elif bool(actor.get("alive", false)):
		node.visible = true
	# Keep newly instantiated normal meshes untouched until a skill needs an
	# override. This also avoids an unnecessary first-frame material rewrite.
	if not hidden and armor <= 0 and not actor.has("skill_materials") and not actor.has("armor_shell"):
		return
	if not actor.has("skill_materials"):
		var records: Array = []
		var model := actor.get("model_node") as Node3D
		var meshes: Array = model.find_children("*", "MeshInstance3D", true, false) if model != null else []
		if model is MeshInstance3D: meshes.append(model)
		var ring := actor.get("colour_ring") as MeshInstance3D
		if ring != null: meshes.append(ring)
		for mesh_value in meshes:
			var mesh := mesh_value as MeshInstance3D
			for surface in mesh.mesh.get_surface_count():
				var original := mesh.get_surface_override_material(surface)
				var material := mesh.get_active_material(surface) as BaseMaterial3D
				if material == null: continue
				if original == null: original = material
				var ghost := material.duplicate() as BaseMaterial3D
				ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				ghost.albedo_color.a *= 0.28
				records.append({"mesh": mesh, "surface": surface, "original": original, "ghost": ghost})
		actor["skill_materials"] = records
	for record in actor["skill_materials"]:
		var mesh := record["mesh"] as MeshInstance3D
		if is_instance_valid(mesh):
			mesh.set_surface_override_material(int(record["surface"]), record["ghost"] if local_hidden else record["original"])
	var effect := actor.get("state_fx") as Node3D
	if is_instance_valid(effect): effect.visible = not hidden
	if armor > 0 and not actor.has("armor_shell"):
		var shell := MeshInstance3D.new()
		shell.name = "Armor"
		var sphere := SphereMesh.new()
		sphere.radius = 0.95
		sphere.height = 2.2
		sphere.radial_segments = 24
		sphere.rings = 12
		shell.mesh = sphere
		shell.position.y = 0.8
		shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.25, 0.85, 1.0, 0.22)
		material.rim_enabled = true
		material.rim = 1.0
		shell.material_override = material
		node.add_child(shell)
		actor["armor_shell"] = shell
	if actor.has("armor_shell"):
		(actor["armor_shell"] as MeshInstance3D).visible = armor > 0


func _trail_colour_for(player_id: int) -> int:
	if players.has(player_id):
		return posmod(int(players[player_id]["color"]), 10)
	# ASSUMPTION: only used for out-of-order player/cell notifications.
	return posmod(player_id - 1, 10)


func set_cell(idx: int, owner: int, trail: int) -> void:
	if idx < 0 or idx >= owner_cells.size():
		return
	if tiles == null or idx >= _val.size():
		super.set_cell(idx, owner, trail)
		return

	var prev := owner_cells[idx]
	var prev_trail := trail_cells[idx]
	var now := _now_s()

	if prev_trail != trail:
		if prev_trail != 0 and _trail_members.has(prev_trail):
			var old_members: Dictionary = _trail_members[prev_trail]
			old_members.erase(idx)
			if old_members.is_empty():
				_trail_members.erase(prev_trail)
		if trail != 0:
			if not _trail_members.has(trail):
				_trail_members[trail] = {}
			var new_members: Dictionary = _trail_members[trail]
			new_members[idx] = true

	if prev_trail != 0 and trail == 0:
		if owner == prev:
			var frame := Engine.get_process_frames()
			if frame != _trail_fade_frame:
				_trail_fade_frame = frame
				_trail_fade_order = 0
			# CManorLineClient::DeleteFromLastTo (0x392d04): each removed unit is stamped
			# now + distance(unit cell, player cell) * LineFadeOutPerUnit - the line disappears outward from the
			# player (Claude, from the APK).
			var dist := float(_trail_fade_order)
			if players.has(prev_trail):
				var pcx: float = float(players[prev_trail]["x"]) / NODE
				var pcy: float = float(players[prev_trail]["y"]) / NODE
				dist = Vector2(float(idx % gw) - pcx, float(idx / gw) - pcy).length()
			var deadline := now + dist * LINE_FADE_UNIT
			_trail_fade[idx] = [
				deadline, int(_line_colour[idx]), int(_line_val[idx]), prev_trail
			]
			_trail_fade_order += 1
			_push_expiry(deadline, 1, idx, deadline)
		else:
			_trail_fade.erase(idx)

	if trail != 0:
		_trail_fade.erase(idx)
		if trail != prev_trail:
			_line_val[idx] = INIT_LINE_RHYTHM_ID
		_line_colour[idx] = _trail_colour_for(trail)

	if owner != 0:
		_sink.erase(idx)
		if owner != prev:
			# CManorClient::OnNewAddUnit (0x392c50): every unit added by a capture gets
			# SetParentChangedTime(now + GammaRand(0, const+0x4c)) - cells pop up one by one at random within the
			# fade-in interval. CManorClient::AddManorUnit (start manor) stamps plain `now` (Claude, from the APK).
			var stamp_t := now
			if Time.get_ticks_msec() - _scene_start_ms > 1000:
				stamp_t = now + randf() * _ramp_s()
			_capture_time[idx] = stamp_t
			_rise[idx] = stamp_t
			_push_expiry(stamp_t + _ramp_s(), 2, idx, stamp_t)
	elif prev != 0:
		_rise.erase(idx)
		# CManorClient::RemoveAllUnit (0x392f64): each unit gets SetParentChangedTime(now + FadeInInterval
		# + GammaRand(0, FadeInInterval)) and its cap reset to 255; RenderImp shrinks it over the last
		# FadeInInterval before that time (Claude, from the APK).
		var deadline := now + _ramp_s() + randf() * _ramp_s()
		_sink[idx] = [deadline, _manor_colour_for(prev)]
		_push_expiry(deadline, 0, idx, deadline)

	super.set_cell(idx, owner, trail)
	if owner != prev:
		_press_dirty = true
	_apply_tile(idx)


func _apply_tile(i: int) -> void:
	if i < 0 or i >= _block_data.size() or _block_chunks.is_empty():
		return

	var now := _now_s()
	var mode := 0
	var colour := 0
	var grade := int(_val[i])
	var stamp := 0.0
	var cap := 255.0

	# RenderImp gives a live line precedence over its underlying manor.
	if trail_cells[i] != 0 and not _is_enemy_hidden(int(trail_cells[i])) and not (_is_player_hidden(int(trail_cells[i])) and owner_cells[i] != 0):
		mode = 5 if _is_player_hidden(int(trail_cells[i])) else 3
		colour = int(_line_colour[i])
		grade = int(_line_val[i])
	elif owner_cells[i] != 0:
		mode = 1
		colour = _manor_colour_for(owner_cells[i])
		stamp = float(_capture_time[i])
		cap = float(_pressed.get(i, 255))
	elif _sink.has(i) and now < float(_sink[i][0]):
		mode = 2
		stamp = float(_sink[i][0])
		colour = int(_sink[i][1])
	elif _trail_fade.has(i) and now < float(_trail_fade[i][0]) and not _is_enemy_hidden(_fade_player(i)):
		mode = 6 if _is_player_hidden(_fade_player(i)) else 4
		stamp = float(_trail_fade[i][0])
		colour = int(_trail_fade[i][1])
		grade = int(_trail_fade[i][2])

	var x := i % gw
	var y := int(i / gw)
	var tag := mode + 8 * ((x + y) & 1)
	var word := _palette_word(colour, grade) if mode != 0 else 0.0
	var data := Color(word, stamp, cap, float(tag))

	if _block_data[i] != data:
		_block_data[i] = data
		var chunk := _block_chunks[_cell_chunk[i]]
		chunk.multimesh.set_instance_custom_data(_cell_slot[i], data)

	if mode == 1 and _jumps[grade]:
		_jumpers[i] = true
	else:
		_jumpers.erase(i)
	_set_shadow_mask(i, mode != 0 and mode != 5 and mode != 6)


func _set_shadow_mask(idx: int, occupied: bool) -> void:
	if _shadow_image == null:
		return
	var value := 0 if occupied else 255
	if _shadow_bytes[idx] == value:
		return
	_shadow_bytes[idx] = value
	_shadow_image.set_pixel(
		idx % gw, int(idx / gw),
		Color(float(value) / 255.0, 0.0, 0.0, 1.0)
	)
	_shadow_dirty = true


func _local_block_colour() -> int:
	# RenderImp (0x38d996) takes the manor of GetPlayerByAccountID(local account), i.e. the director offline (Claude).
	for id in players:
		if bool(players[id]["director"]):
			return posmod(int(players[id]["color"]), 10)
	if players.has(follow_id):
		return posmod(int(players[follow_id]["color"]), 10)
	return -1


func _beat_bounce() -> float:
	var ratio := float(block_jump_ratio) / 10000.0
	return 1.0 - ratio + ratio * _beat_phase


func _update_jumpers() -> void:
	_beat_index = 0
	_beat_phase = 1.0
	_last_beat_ms = -1.0

	if music_playing and not beats.is_empty():
		var t := music_ms()
		# Upper bound: number of beat timestamps <= current play time.
		var lo := 0
		var hi := beats.size()
		while lo < hi:
			var mid := int((lo + hi) / 2)
			if beats[mid] <= t:
				lo = mid + 1
			else:
				hi = mid
		_beat_index = lo
		if lo > 0:
			_last_beat_ms = beats[lo - 1]
		if lo > 0 and lo < beats.size():
			var interval := beats[lo] - beats[lo - 1]
			if interval > 0.0:
				_beat_phase = (beats[lo] - t) / interval

	if _block_material == null:
		return
	_block_material.set_shader_parameter("beat_index", _beat_index)
	_block_material.set_shader_parameter("beat_remaining", _beat_phase)
	_block_material.set_shader_parameter(
		"jump_ratio", float(block_jump_ratio) / 10000.0
	)
	_block_material.set_shader_parameter("ai_is_jump", block_ai_is_jump)
	_block_material.set_shader_parameter("local_colour", _local_block_colour())


func _push_expiry(at_s: float, kind: int, idx: int, token_s: float) -> void:
	var event := [at_s, kind, idx, token_s]
	var at := _expiry_events.size()
	_expiry_events.append(event)
	while at > 0:
		var parent := int((at - 1) / 2)
		if float(_expiry_events[parent][0]) <= at_s:
			break
		_expiry_events[at] = _expiry_events[parent]
		at = parent
	_expiry_events[at] = event


func _pop_expiry() -> Array:
	var result: Array = _expiry_events[0]
	var tail: Array = _expiry_events.pop_back()
	if _expiry_events.is_empty():
		return result

	var at := 0
	var count := _expiry_events.size()
	while true:
		var child := at * 2 + 1
		if child >= count:
			break
		var right := child + 1
		if right < count and float(_expiry_events[right][0]) < float(_expiry_events[child][0]):
			child = right
		if float(tail[0]) <= float(_expiry_events[child][0]):
			break
		_expiry_events[at] = _expiry_events[child]
		at = child
	_expiry_events[at] = tail
	return result


func _refresh_trail_colours() -> void:
	for id in players:
		var colour := posmod(int(players[id]["color"]), 10)
		if int(_known_player_colours.get(id, -1)) == colour:
			continue
		_known_player_colours[id] = colour
		if not _trail_members.has(id):
			continue
		var members: Dictionary = _trail_members[id]
		for idx in members:
			_line_colour[idx] = colour
			_apply_tile(idx)


func _update_tiles(_delta: float) -> void:
	var now := _now_s()
	_refresh_trail_colours()

	while not _expiry_events.is_empty() and float(_expiry_events[0][0]) <= now:
		var event := _pop_expiry()
		var kind := int(event[1])
		var idx := int(event[2])
		var token := float(event[3])
		match kind:
			0:
				if _sink.has(idx) and float(_sink[idx][0]) == token:
					_sink.erase(idx)
					_apply_tile(idx)
			1:
				if _trail_fade.has(idx) and float(_trail_fade[idx][0]) == token:
					_trail_fade.erase(idx)
					_apply_tile(idx)
			2:
				if _rise.has(idx) and float(_rise[idx]) == token:
					_rise.erase(idx)

	if _shadow_dirty and _shadow_texture != null:
		_shadow_texture.update(_shadow_image)
		_shadow_dirty = false
	if _block_material != null:
		_block_material.set_shader_parameter("clock_s", now)
		_block_material.set_shader_parameter("fade_ramp_s", _ramp_s())


# CPlayerClient::OnSetPosition (0x395c90), recovered by GPT, checked by Claude: the shaped-cap flag
# *(*(player + 0x18) + 0x18) is the player's manor's scene pointer (CManorClient +0x18 = scene, as in
# CManorClient::RemoveAllUnit), non-null for every player in a scene, so every alive player presses.
# 0x1a452c is sqrtf (used the same way by RebuildBlockBuffer / MakeResValid).
#
# CPlayerClient::OnSetPosition:
# - Reads CSnakeConstant +0x1c: MoveRadius, R, in pixels.
# - Converts positions to signed-short integer pixels, then divides by 16
#   with truncation toward zero to obtain grid coordinates.
# - If the grid coordinate changed, calls ResetLogicHeight(old_cell) first.
# - Visits the inclusive square new_cell +/- trunc(R / 16).
# - Writes only in-bounds manor units whose parent and parent.vtable[0x0c]
#   result are non-null, and whose centre has distance d STRICTLY BELOW R
#   from the new, fractional pixel position. There is no owner comparison.
# - With the nested flag zero, writes R's low byte.
# - Otherwise writes the low byte of trunc(R - sqrt(R*R - d*d)).
#   The second square uses the already calculated, float32 distance.
# - Each write replaces the previous cap; overlapping players do not take
#   a minimum. Cells leaving the disk retain their previous caps.
# - The non-server path calls CPlayer::OnSetPosition, then requires
#   CCharacter::IsValid(). The server path has no corresponding validity
#   check. The local-player comparisons do not restrict the cap loop.
#
# ResetLogicHeight writes 255 to qualifying manor units throughout the
# inclusive old-cell square +/- trunc(R / 16), without a distance test or
# ownership comparison. DestroyPlayer calls it at the destroyed player's
# current cell after CGameScene::DestroyPlayer, regardless of director.
# The unit constructor and SetParentChangedTime also write 255 immediately.
# OnNewAddUnit's FadeInInterval (+0x4c) randomizes the capture timestamp;
# it does not delay that cap reset. There is no press easing or timer.
#
# PressAllWay (+0xb8), UnitInterval, valuation and music heights are not
# read by these cap writers. Rendering applies min(cap, table_height).
# Trail units are separate: a trail does not exclude its underlying manor.
#
# Limits of this polling adapter:
# - The nested flag's identity/initialization is absent. In particular,
#   these instructions cannot establish an indirect PressAllWay effect.
#   CPlayer::OnSetPosition (0x343488) and CCharacter::IsValid() are missing.
# - Exact callback cadence/order requires the missing callers of
#   CPlayerClient::OnSetPosition and CGameSceneClient::DestroyPlayer.
#   Here, first observations and changed positions generate callbacks;
#   removals/deaths reset first, then movement follows players' order.
#   Equal-position callbacks and intervening events cannot be reconstructed.
# - owner_cells != 0 represents the native parent predicate; its unnamed
#   virtual method at +0x0c is missing. _capture_time is assumed to mirror
#   SetParentChangedTime's timestamp. Observable owner/timestamp changes
#   reset first; indistinguishable repeated parent events cannot be recovered.
# Thus the recovered writes are reproduced under these explicit mappings;
# the supplied snapshots cannot guarantee exact native event replay.

var _press_native_grid_size := Vector2i(-1, -1)
var _press_native_cap_parents: Dictionary = {}
var _press_native_f32_buffer := PackedFloat32Array([0.0])


func _update_press(_delta: float) -> void:
	var dirty: Dictionary = {}
	var grid_size := Vector2i(gw, gh)

	if grid_size != _press_native_grid_size:
		for key in _pressed.keys():
			_press_native_set_cap(int(key), 255, dirty)
		_press_native_cap_parents.clear()
		_press_sources.clear()
		_press_native_grid_size = grid_size

	var radius_px := int(block_move_radius_px)
	var extent := int(float(radius_px) / NODE)
	var positions: Dictionary = {}

	for id in players:
		var player: Dictionary = players[id]
		if bool(player["alive"]):
			positions[id] = _press_native_position(player)

	# Constructor/SetParentChangedTime resets matter even without movement.
	for key in _pressed.keys():
		var idx := int(key)
		if idx < 0 or idx >= gw * gh:
			_press_native_set_cap(idx, 255, dirty)
			continue

		var token: Array = _press_native_cap_parents.get(idx, [])
		if (
			token.size() != 2
			or owner_cells[idx] == 0
			or int(token[0]) != int(owner_cells[idx])
			or float(token[1]) != float(_capture_time[idx])
		):
			_press_native_set_cap(idx, 255, dirty)

	for id in _press_sources:
		if positions.has(id):
			continue

		var last_position: Vector2 = _press_sources[id]
		if players.has(id):
			var removed_player: Dictionary = players[id]
			last_position = _press_native_position(removed_player)

		_press_native_reset(
			_press_native_node(last_position), extent, dirty
		)

	for id in positions:
		var position_px: Vector2 = positions[id]

		if _press_sources.has(id):
			var old_position: Vector2 = _press_sources[id]
			if old_position == position_px:
				continue

			var old_cell := _press_native_node(old_position)
			if old_cell != _press_native_node(position_px):
				_press_native_reset(old_cell, extent, dirty)

		_press_native_write_disk(position_px, true, radius_px, extent, dirty)

	_press_sources = positions
	_press_dirty = false

	for key in dirty:
		var idx := int(key)
		if idx >= 0 and idx < gw * gh:
			_apply_tile(idx)


func _press_native_position(player: Dictionary) -> Vector2:
	return Vector2(
		_press_native_f32(float(player["x"])),
		_press_native_f32(float(player["y"]))
	)


func _press_native_node(position_px: Vector2) -> Vector2i:
	var pixel_x := int(position_px.x) & 0xffff
	var pixel_y := int(position_px.y) & 0xffff

	if pixel_x >= 0x8000:
		pixel_x -= 0x10000
	if pixel_y >= 0x8000:
		pixel_y -= 0x10000

	return Vector2i(
		int(float(pixel_x) / NODE),
		int(float(pixel_y) / NODE)
	)


func _press_native_reset(
	cell: Vector2i, extent: int, dirty: Dictionary
) -> void:
	var x0 := maxi(0, cell.x - extent)
	var x1 := mini(gw - 1, cell.x + extent)
	var y0 := maxi(0, cell.y - extent)
	var y1 := mini(gh - 1, cell.y + extent)

	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var idx := y * gw + x
			if owner_cells[idx] != 0:
				_press_native_set_cap(idx, 255, dirty)


func _press_native_write_disk(
	position_px: Vector2,
	shaped: bool,
	radius_px: int,
	extent: int,
	dirty: Dictionary
) -> void:
	if radius_px <= 0:
		return

	var cell := _press_native_node(position_px)
	var radius := _press_native_f32(float(radius_px))
	var radius_squared := _press_native_f32(float(radius_px * radius_px))
	var x0 := maxi(0, cell.x - extent)
	var x1 := mini(gw - 1, cell.x + extent)
	var y0 := maxi(0, cell.y - extent)
	var y1 := mini(gh - 1, cell.y + extent)

	for x in range(x0, x1 + 1):
		for y in range(y0, y1 + 1):
			var idx := y * gw + x
			if owner_cells[idx] == 0:
				continue

			var centre_x := _press_native_f32((float(x) + 0.5) * NODE)
			var centre_y := _press_native_f32((float(y) + 0.5) * NODE)
			var dx := _press_native_f32(position_px.x - centre_x)
			var dy := _press_native_f32(position_px.y - centre_y)
			var distance_squared := _press_native_f32(
				_press_native_f32(dy * dy)
				+ _press_native_f32(dx * dx)
			)
			var distance := _press_native_f32(sqrt(distance_squared))

			if not (distance < radius):
				continue

			var cap := radius_px & 0xff
			if shaped:
				var remainder := _press_native_f32(
					radius_squared - _press_native_f32(distance * distance)
				)
				var root := _press_native_f32(sqrt(remainder))
				cap = int(_press_native_f32(radius - root)) & 0xff

			_press_native_set_cap(idx, cap, dirty)


func _press_native_set_cap(
	idx: int, cap: int, dirty: Dictionary
) -> void:
	cap = cap & 0xff

	if cap == 255:
		if _pressed.has(idx):
			_pressed.erase(idx)
			dirty[idx] = true
		_press_native_cap_parents.erase(idx)
		return

	if int(_pressed.get(idx, 255)) != cap:
		_pressed[idx] = cap
		dirty[idx] = true

	_press_native_cap_parents[idx] = [
		int(owner_cells[idx]), float(_capture_time[idx])
	]


func _press_native_f32(value: float) -> float:
	_press_native_f32_buffer[0] = value
	return _press_native_f32_buffer[0]


func set_player_model(id: int, model_path: String) -> void:
	var old: Dictionary = actors.get(id, {})
	if old.get("model", "") == model_path and old.has("node"):
		return
	if old.has("node"):
		old["node"].queue_free()
	var a := {}
	var node := Node3D.new()
	var scene = load(model_path) if ResourceLoader.exists(model_path) else load("res://assets/models/p_001.glb")
	if scene != null:
		var model: Node3D = scene.instantiate()
		model.scale = Vector3.ONE * CHAR_SCALE
		node.add_child(model)
		a["model_node"] = model
		var aps := model.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty():
			var ap: AnimationPlayer = aps[0]
			for n in ["run_w", "sprint", "stand", "stand1", "stand2", "chat"]:
				if ap.has_animation(n):
					ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
			a["anim"] = ap
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font = _get_font()
	label.font_size = 56
	label.pixel_size = 0.018
	label.outline_size = 12
	label.position = Vector3(0, 1.3 * CHAR_SCALE, 0)
	label.visible = false
	node.add_child(label)
	var colour_ring := MeshInstance3D.new()
	colour_ring.name = "ManorColour"
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.49
	ring_mesh.outer_radius = 0.62
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 6
	colour_ring.mesh = ring_mesh
	colour_ring.scale.y = 0.16
	colour_ring.position.y = 0.04
	colour_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring_material := StandardMaterial3D.new()
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	colour_ring.material_override = ring_material
	node.add_child(colour_ring)
	world.add_child(node)
	var ap_ref = a.get("anim")
	actors[id] = {
		"node": node, "model": model_path, "label": label,
		"last": Vector3.ZERO, "yaw": 0.0, "anim": ap_ref,
		"alive": true, "state": "", "pid": id, "model_node": a.get("model_node"),
		"colour_ring": colour_ring, "colour_slot": -1,
	}
	_play(actors[id], "run_w")


func set_player(id: int, x: float, y: float, color_id: int, nick: String, alive: bool, is_director: bool) -> void:
	super.set_player(id, x, y, color_id, nick, alive, is_director)
	if world == null:
		return
	if not actors.has(id):
		set_player_model(id, "res://assets/models/p_001.glb")
	var a: Dictionary = actors[id]
	var node: Node3D = a["node"]
	var colour_slot := posmod(color_id, 10)
	if int(a.get("colour_slot", -1)) != colour_slot:
		a["colour_slot"] = colour_slot
		var ring := a.get("colour_ring") as MeshInstance3D
		if ring != null:
			(ring.material_override as StandardMaterial3D).albedo_color = _color_of(colour_slot)
	if alive and not a["alive"]:
		node.visible = true
		_play(a, "run_w")
	elif not alive and a["alive"]:
		if a["anim"] != null and (a["anim"] as AnimationPlayer).has_animation("fly_die"):
			_play(a, "fly_die")
			get_tree().create_timer((a["anim"] as AnimationPlayer).get_animation("fly_die").length).timeout.connect(
				func(): if is_instance_valid(node) and not a["alive"]: node.visible = false)
		else:
			node.visible = false
	if bool(a["alive"]) != alive:
		a.erase("skill_style_key")
	a["alive"] = alive
	_apply_player_skill_visuals(id)
	if not alive:
		return
	var p := _w2v(x, y)
	var now := Time.get_ticks_msec()
	var dt := (now - int(a.get("t", now))) / 1000.0
	if dt > 0.0:
		var v: float = (p - a["last"]).length() / dt
		a["spd"] = lerpf(float(a.get("spd", 5.0)), v if v < 40.0 else float(a.get("spd", 5.0)), clampf(dt * 8.0, 0.0, 1.0))
		a["t"] = now
		var spd: float = a["spd"]
		if a["state"] != "fly_die":
			_play(a, "stand" if spd < 0.5 else ("sprint" if spd > 8.0 else "run_w"))
	else:
		a["t"] = now
	var d: Vector3 = p - a["last"]
	if d.length() > 0.01 and d.length() < 4.0:
		a["yaw"] = atan2(d.x, d.z) + PI
	a["last"] = p
	if network_replica and a.has("net_target") and node.position.distance_to(p) < 12.0:
		a["net_from"] = node.position
		a["net_age"] = 0.0
	else:
		node.position = p
		a["net_from"] = p
		a["net_age"] = 0.1
	a["net_target"] = p
	var lab: Label3D = a["label"]
	lab.text = nick
	lab.modulate = Color(1, 0.35, 0.3) if is_director else Color(1, 1, 1)


# Character state effects (Claude): equip.txt szFx<colour> = fx/cfg/benpao_<colour+1>.eft; the effect whose
# dependency list holds the playing animation is attached to the model (CGameRenderObject state_fx; same rule as
# CGameRenderItem::OnLoadedEnd). Units follow their bone_name (b_00x roller, Bip001 Prop1 ...).
var _fx_defs: Dictionary = {}   # stem -> {anim: effect name}

func _state_effect_for(stem: String, anim_name: String) -> String:
	if not _fx_defs.has(stem):
		var table := {}
		var path := "res://assets/fx/%s.json" % stem
		if FileAccess.file_exists(path):
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if data is Dictionary and data.get("effects") is Dictionary:
				for en in data["effects"]:
					for dep in data["effects"][en].get("dependency_names", []):
						if str(dep) != "" and not table.has(str(dep)):
							table[str(dep)] = str(en)
		_fx_defs[stem] = table
	return str(_fx_defs[stem].get(anim_name, ""))

func _update_state_fx(a: Dictionary, anim_name: String) -> void:
	var old = a.get("state_fx")
	if old != null and is_instance_valid(old):
		old.queue_free()
	a["state_fx"] = null
	var node: Node3D = a.get("node")
	if node == null or not is_instance_valid(node):
		return
	var pid := int(a.get("pid", -1))
	# OnEquipUpdated's colour argument is the manor colour only in eRT_Team / eRT_TeamSecret (2, 8), else 0
	# (CPlayerClientLua:OnInsertToScene, CGameAppClient::SetDirector) (Claude)
	var colour := int(players[pid]["color"]) if players.has(pid) and room_type in [2, 8] else 0
	var stem := "benpao_%d" % (posmod(colour, 10) + 1)
	var en := _state_effect_for(stem, anim_name)
	if en == "":
		return
	var model: Node3D = a.get("model_node")
	var loop := anim_name in ["run_w", "sprint", "stand", "stand1", "stand2"]
	var fxn = EffectPlayer3D.spawn_world(node, stem, en, Vector3.ZERO, EQUIP_SCALE / ENGINE_PER_NODE, loop)   # render object scaled by nScale
	if fxn != null:
		fxn.attached_model = model
		a["state_fx"] = fxn
		fxn.visible = not _is_player_hidden(pid)

func _play(a: Dictionary, anim_name: String) -> void:
	var ap = a.get("anim")
	if ap == null or a.get("state", "") == anim_name or not (ap as AnimationPlayer).has_animation(anim_name):
		return
	a["state"] = anim_name
	(ap as AnimationPlayer).play(anim_name, 0.12)
	_update_state_fx(a, anim_name)


# CGameRenderObject::GetAniCurFrame (0x38cb98), used for the director's render object (OnEquipUpdated last arg,
# CGameAppClient::SetDirector) while a looped animation plays and the scene music runs: SMusicCon::GetRange gives the
# beat interval [start, start + len) holding the play time and its running index; the frame is
# (index & 1) * N / 2 + (t - start) / len * N / 2, so one beat covers half a cycle (Claude).
func _beat_sync_anim(a: Dictionary) -> void:
	var ap = a.get("anim")
	if ap == null or not music_playing or music_paused or beats.size() < 2:
		return
	var ap_ := ap as AnimationPlayer
	if not ap_.is_playing() or ap_.current_animation == "":
		return
	var anim := ap_.get_animation(ap_.current_animation)
	if anim == null or anim.loop_mode == Animation.LOOP_NONE:
		return
	var period := 0.0
	if music_player != null and music_player.stream != null:
		period = music_player.stream.get_length() * 1000.0
	if period <= 0.0:
		return
	var t := fposmod(music_ms(), period)
	var n := beats.size()
	var lo := 0
	var hi := n
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if beats[mid] <= t:
			lo = mid
		else:
			hi = mid
	var start: float
	var length: float
	var index: int
	if t < beats[0]:
		start = beats[n - 1] - period
		length = beats[0] - start
		index = -1
	elif lo == n - 1:
		start = beats[n - 1]
		length = period - beats[n - 1] + beats[0]
		index = n - 1
	else:
		start = beats[lo]
		length = beats[lo + 1] - beats[lo]
		index = lo
	if length <= 0.0:
		return
	var loops := int(floor(float(Time.get_ticks_msec() - music_t0_ms) / period))
	var parity := posmod(index + loops * n, 2)
	var frac := clampf((t - start) / length, 0.0, 1.0)
	ap_.seek((float(parity) + frac) * 0.5 * anim.length, true)


func set_follow(id: int) -> void:
	follow_id = id
	if players.has(id):
		cam_target = _w2v(players[id]["x"], players[id]["y"])
		_place_camera(true)


func _place_camera(_snap := false) -> void:
	if camera == null:
		return
	var k := ZOOM / maxf(camera_zoom, 0.1)
	var t := cam_target + Vector3(camera_offset.x / NODE, 0, camera_offset.y / NODE)
	# UpdateCamera sets Dest = player and Pos = Dest + (0, height * scale, -CameraZ) every frame, with no smoothing
	# (CCamera::SetDest/SetPos bool only picks world vs local space); only the height takes the scene scale (Claude)
	cam_up = lerpf(CAM_UP_MIN, CAM_UP_MAX, clampf((area_ratio - 0.10) / 0.40, 0.0, 1.0))
	var bonus := float(_player_skill_states.get(follow_id, {}).get("camera_bonus", 0.0)) / NODE
	camera.position = t + Vector3(0, cam_up * k + bonus, CAM_BACK)
	camera.look_at(t, Vector3.UP)


func set_camera_scale(value: float) -> void:
	super.set_camera_scale(value)
	_place_camera()


func add_camera_offset(x: float, y: float) -> void:
	super.add_camera_offset(x, y)
	_place_camera()


func world_to_screen(x: float, y: float) -> Vector2:
	if camera == null:
		return super.world_to_screen(x, y)
	var p := camera.unproject_position(_w2v(x, y))
	var canvas: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * p
	if is_instance_valid(hud_ui_root):
		return _canvas_to_ui(canvas)
	var vs := get_viewport().get_visible_rect().size
	return p * Vector2(1280.0 / vs.x, 720.0 / vs.y)


func _process(delta: float) -> void:
	if not active:
		return
	for id in actors:
		var a: Dictionary = actors[id]
		var node: Node3D = a["node"]
		if network_replica and a.has("net_target"):
			a["net_age"] = minf(float(a.get("net_age", 0.0)) + delta, 0.1)
			node.position = (a["net_from"] as Vector3).lerp(a["net_target"], float(a["net_age"]) / 0.1)
		node.rotation.y = lerp_angle(node.rotation.y, a["yaw"], clampf(delta * 14.0, 0.0, 1.0))
		if players.has(id) and players[id]["director"]:
			_beat_sync_anim(a)
		var sfx = a.get("state_fx")
		if sfx != null and is_instance_valid(sfx):
			var mode := Node.PROCESS_MODE_INHERIT if _on_screen(node.position) else Node.PROCESS_MODE_DISABLED
			if sfx.process_mode != mode:
				sfx.process_mode = mode
			sfx.visible = mode == Node.PROCESS_MODE_INHERIT and not _is_player_hidden(int(id))
	if players.has(follow_id):
		var p: Dictionary = players[follow_id]
		cam_target = actors[follow_id]["node"].position if network_replica and actors.has(follow_id) else _w2v(p["x"], p["y"])
		_place_camera()
	var _t0 := Time.get_ticks_usec()
	if tiles != null:
		_update_press(delta)
		_t0 = Prof.add("press", _t0)
		_update_tiles(delta)
		_t0 = Prof.add("tiles", _t0)
		_update_jumpers()
		_t0 = Prof.add("jumpers", _t0)
	_update_items(delta)
	_t0 = Prof.add("items", _t0)
	_update_flies(delta)
	grade_age += delta
	queue_redraw()


const PLATE_SRC := {"blue": [157, 166], "purple": [176, 186], "orange": [195, 205]}
var _plate_tex: Texture2D


func _draw_head_infos() -> void:
	if camera == null:
		return
	if _plate_tex == null:
		_plate_tex = GuiRuntime.atlas("fs_jm008.tex")
	var font := _get_font()
	for id in actors:
		var a: Dictionary = actors[id]
		if not players.has(id) or not players[id]["alive"] or _is_enemy_hidden(int(id)):
			continue
		var node: Node3D = a["node"]
		var wp := node.global_position + Vector3(0, 1.3 * CHAR_SCALE, 0)
		if camera.is_position_behind(wp):
			continue
		var sp := camera.unproject_position(wp)
		var vs := get_viewport().get_visible_rect().size
		sp *= Vector2(1280.0 / vs.x, 720.0 / vs.y)
		var nick := String(players[id]["name"])
		var tw := font.get_string_size(nick, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var w := maxf(tw + 22.0, 40.0)
		var x0 := sp.x - w * 0.5
		var y0 := sp.y - 27.0
		var src: Array = PLATE_SRC["orange"] if players[id]["director"] else PLATE_SRC["blue"]
		# CPlayerClient::SetNickName (0x3955b8): the three-piece plate is only used in rooms 2, 8, 10 (team kinds);
		# the endless room shows the bare name (Claude, from the APK)
		if _plate_tex != null and room_type in [2, 8, 10]:
			var cap := Rect2(src[0], 270, 9, 40)
			draw_texture_rect_region(_plate_tex, Rect2(x0, y0, 9, 27), cap)
			draw_texture_rect_region(_plate_tex, Rect2(x0 + 9, y0, w - 18, 27), Rect2(src[1], 270, 1, 40))
			draw_set_transform(Vector2(x0 + w, y0), 0.0, Vector2(-1, 1))
			draw_texture_rect_region(_plate_tex, Rect2(0, 0, 9, 27), cap)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string_outline(font, Vector2(x0, y0 + 19), nick, HORIZONTAL_ALIGNMENT_CENTER, w, 14, 3, Color(0, 0, 0, 0.6))
		draw_string(font, Vector2(x0, y0 + 19), nick, HORIZONTAL_ALIGNMENT_CENTER, w, 14, Color.WHITE)


var items: Dictionary = {}
# CPlayerClient::OnUpdateFlyEffect (0x394bf8): step_px = Diamondinitialspeed * dt_ms / 1000 + age_s * Diamondacceleration,
# toward (player x, Diamondendheight px, player z); released on arrival (constant.txt 200 / 40 / 40)
var _flies: Array = []

func _update_flies(delta: float) -> void:
	var now_s := Time.get_ticks_msec() / 1000
	var keep: Array = []
	for f in _flies:
		var fxn: Node3D = f["fx"]
		if not is_instance_valid(fxn):
			continue
		if not actors.has(int(f["target"])):
			fxn.queue_free()
			continue
		var tnode: Node3D = actors[int(f["target"])]["node"]
		var target := tnode.global_position + Vector3(0, 40.0 / ENGINE_PER_NODE, 0)
		var step := (200.0 * delta + float(now_s - int(f["birth"])) * 40.0) / ENGINE_PER_NODE
		var d := target - fxn.global_position
		if d.length() <= step:
			fxn.queue_free()
			continue
		fxn.global_position += d.normalized() * step
		keep.append(f)
	_flies = keep
var _popups: Array = []


static func _hv(hint, key: String, default = null):
	if hint == null:
		return default
	var v = hint.get(key) if hint is Object and hint.has_method("get") else (hint.get(key, default) if hint is Dictionary else default)
	return default if v == null else v


# Items follow CItemClient (Claude, from the APK):
#   OnObjectCreated: CGameRenderItem gets mapitem.txt sModPath/sActPath/sFxPath, SetWorldDirectionXZ(nDir, 256 per turn)
#     and SetLocalScale(nFangdabeilv / 10000); position = item pixel position (CreateMapItem: GetLogicCenterOnPixel).
#   OnSetState: 1 -> "rb1" once, 2 -> "bind" looped, 3 -> "fly_die" once; OnAniPlayEnd: 1 -> state 2, 3 -> DelItem.
#   The effect whose dependency_names holds the playing animation runs on the item (CGameRenderItem state fx).
#   OnCircle / OnCollideDropOut / collide exp: CPlayerClient::AddFlyEffect(item world position), then state 3.
#   CGameRenderItem::OnUpdate: standing on a manor cell, y = min(cell logic height cap, valuation height).
# Animation-only items (mapitem 15 has no model) take their lengths from role/ani/<stem>.ans frame counts.
const ITEM_ANI_FRAMES := {"jingyanhezi": {"bind": 29, "fly_die": 29, "rb1": 89}}

func add_item(id: int, kind: String, x: float, y: float, hint = null) -> void:
	if world == null:
		return
	remove_item(id, null)
	var mpath := str(_hv(hint, "model", ""))
	var apath := str(_hv(hint, "animation", ""))
	var fpath := str(_hv(hint, "effect", ""))
	var node := Node3D.new()
	node.rotation.y = -float(_hv(hint, "direction_raw", 0)) / 256.0 * TAU
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * float(_hv(hint, "scale_raw", 10000)) / 10000.0 * 64.0 / ENGINE_PER_NODE
	node.add_child(holder)
	var model: Node3D = null
	var ap: AnimationPlayer = null
	var stem := mpath.get_file().get_basename()
	if stem != "" and ResourceLoader.exists("res://assets/models/%s.glb" % stem):
		model = (load("res://assets/models/%s.glb" % stem) as PackedScene).instantiate()
		holder.add_child(model)
		if kind == "map":
			_make_unshaded(model)
		var aps := model.find_children("*", "AnimationPlayer", true, false)
		if not aps.is_empty():
			ap = aps[0]
			if ap.has_animation("bind"):
				ap.get_animation("bind").loop_mode = Animation.LOOP_LINEAR
	world.add_child(node)
	var to := _w2v(x, y)
	var from := _w2v(float(_hv(hint, "from_x_px", x)), float(_hv(hint, "from_y_px", y)))
	var flight := float(_hv(hint, "flight_ms", 0)) / 1000.0
	node.position = from if flight > 0.0 else to
	var it := {
		"node": node, "holder": holder, "model": model, "ap": ap, "kind": kind,
		"fx_stem": fpath.get_file().get_basename(), "ani_stem": apath.get_file().get_basename(),
		"t0": Time.get_ticks_msec(), "from": from, "to": to, "flight": flight,
		"px": Vector2(x, y), "state_fx": null, "anim": "", "anim_end": -1.0,
	}
	items[id] = it
	var initial_animation := str(_hv(hint, "state_animation", "rb1" if flight > 0.0 else "bind"))
	_item_play(id, initial_animation)


func _item_anim_len(it: Dictionary, anim_name: String) -> float:
	var ap: AnimationPlayer = it["ap"]
	if ap != null and ap.has_animation(anim_name):
		return ap.get_animation(anim_name).length
	var frames: Dictionary = ITEM_ANI_FRAMES.get(str(it["ani_stem"]), {})
	return float(frames.get(anim_name, 0)) * 0.033


func _item_play(id: int, anim_name: String) -> void:
	var it: Dictionary = items.get(id, {})
	if it.is_empty():
		return
	it["anim"] = anim_name
	var ap: AnimationPlayer = it["ap"]
	if ap != null and ap.has_animation(anim_name):
		ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR if anim_name == "bind" else Animation.LOOP_NONE
		ap.play(anim_name)
	var looped := anim_name == "bind"
	it["anim_end"] = -1.0 if looped else Time.get_ticks_msec() / 1000.0 + _item_anim_len(it, anim_name)
	var old = it["state_fx"]
	if old != null and is_instance_valid(old):
		old.queue_free()
	it["state_fx"] = null
	if str(it["fx_stem"]) == "":
		return
	var en := _state_effect_for(str(it["fx_stem"]), anim_name)
	if en == "":
		return
	var fxn = EffectPlayer3D.spawn_world(it["holder"], str(it["fx_stem"]), en, Vector3.ZERO, 1.0 / 64.0, looped)
	if fxn != null:
		fxn.attached_model = it["model"]
		it["state_fx"] = fxn


func remove_item(id: int, picked_by = null) -> void:
	var it: Dictionary = items.get(id, {})
	if it.is_empty():
		return
	var node: Node3D = it["node"]
	if picked_by != null and actors.has(int(picked_by)) and is_instance_valid(node):
		var fxn = EffectPlayer3D.spawn_world(world, "zuanshixifu", "fx/loop", node.global_position, 1.0 / ENGINE_PER_NODE, true)
		if fxn != null:
			_flies.append({"fx": fxn, "target": int(picked_by), "birth": Time.get_ticks_msec() / 1000})
		it["dying"] = true
		_item_play(id, "fly_die")
		return
	items.erase(id)
	if is_instance_valid(node):
		node.queue_free()


func _item_ground(px: Vector2) -> float:
	var gx := int(floor(px.x / NODE))
	var gy := int(floor(px.y / NODE))
	if gx < 0 or gy < 0 or gx >= gw or gy >= gh:
		return 0.0
	var idx := gy * gw + gx
	if idx >= owner_cells.size() or owner_cells[idx] == 0 or idx >= _val.size():
		return 0.0
	var h := minf(float(_heights[clampi(int(_val[idx]), 0, 4)]), float(_pressed.get(idx, 255)))
	return h / ENGINE_PER_NODE


func _on_screen(p: Vector3) -> bool:
	if camera == null:
		return true
	for o in [Vector3.ZERO, Vector3(2, 0, 2), Vector3(-2, 0, 2), Vector3(2, 0, -2), Vector3(-2, 0, -2), Vector3(0, 3, 0)]:
		if camera.is_position_in_frustum(p + o):
			return true
	return false


func _update_items(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	var now_s := now / 1000.0
	for id in items.keys():
		# A Lua animation callback can remove other items while this snapshot is visited.
		var it: Dictionary = items.get(id, {})
		if it.is_empty():
			continue
		var node: Node3D = it["node"]
		if not is_instance_valid(node):
			items.erase(id)
			continue
		var fl: float = it["flight"]
		if fl > 0.0:
			var t := clampf((now - int(it["t0"])) / 1000.0 / fl, 0.0, 1.0)
			node.position = (it["from"] as Vector3).lerp(it["to"], t)
			if t >= 1.0:
				it["flight"] = 0.0
		else:
			node.position.y = _item_ground(it["px"])
		# like the engine, only on-screen render objects update: effects of items far from the camera target are
		# paused and hidden (no visible change) (Claude)
		var near: bool = it["kind"] == "map" or _on_screen(node.position)
		if near != node.visible:
			node.visible = near
			node.process_mode = Node.PROCESS_MODE_INHERIT if near else Node.PROCESS_MODE_DISABLED
		var end_s: float = it["anim_end"]
		if end_s >= 0.0 and now_s >= end_s:
			if it["anim"] == "rb1":
				_item_play(id, "bind")
				# CItemClient::OnAniPlayEnd changes logical state 1 -> 2. Flight
				# interpolation is independent; it must not arm the pickup early.
				item_animation_finished.emit(id, "rb1")
			elif it["anim"] == "fly_die":
				items.erase(id)
				node.queue_free()
				item_animation_finished.emit(id, "fly_die")


func show_capture_popup(text: String, duration_ms: int = 1000, _text_eft = null, _bg_eft = null) -> void:
	_popups.append({"text": text, "age": 0.0, "ms": maxf(200.0, float(duration_ms))})


func _draw_popups(delta: float) -> void:
	var font := _get_font()
	var keep: Array = []
	for pp in _popups:
		pp["age"] = float(pp["age"]) + delta
		var t: float = float(pp["age"]) * 1000.0 / float(pp["ms"])
		if t >= 1.0:
			continue
		keep.append(pp)
		var sc := 1.0 + 0.4 * maxf(0.0, 1.0 - t * 5.0)
		var a := clampf(1.0 - maxf(0.0, t - 0.6) / 0.4, 0.0, 1.0)
		var size := int(40 * sc)
		var pos := Vector2(440, 250 - t * 40.0)
		draw_string_outline(font, pos, String(pp["text"]), HORIZONTAL_ALIGNMENT_CENTER, 400, size, 8, Color(0.55, 0.25, 0.0, a))
		draw_string(font, pos, String(pp["text"]), HORIZONTAL_ALIGNMENT_CENTER, 400, size, Color(1.0, 0.86, 0.2, a))
	_popups = keep


func _draw() -> void:
	if not active:
		return
	_draw_head_infos()
	_draw_popups(get_process_delta_time())
	_draw_rhythm(_get_font())
