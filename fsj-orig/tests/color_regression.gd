extends Node

var failures: Array[String] = []

func check(condition: bool, detail: String) -> void:
	if not condition:
		failures.append(detail)
		push_error("COLOUR TEST: " + detail)

func _ready() -> void:
	var shot := "C:/Users/Administrator/Desktop/gpt-collab-gamedev/mod-work/shots/colour-regression.png"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shot="): shot = argument.substr(7)
	var view := SceneView3D.new()
	add_child(view)
	view.begin_scene(40, 22)
	view.set_process(false)
	var palette := view._peise.get_image()
	check(palette.get_width() == 128 and palette.get_height() == 128, "original palette size")
	var row_colours: Array[Color] = []
	var samples: Array[Vector3] = []
	for colour in range(10):
		var row_colour := palette.get_pixel(64, colour * 5)
		for previous in row_colours:
			check(row_colour != previous, "original palette hues must be unique")
		row_colours.append(row_colour)
		var manor_id := 100 + colour * 7
		view.set_manor_colour(manor_id, colour)
		var cell_x := 4 + (colour % 5) * 7
		var cell_y := 5 + int(colour / 5) * 10
		for y in range(cell_y - 1, cell_y + 2):
			for x in range(cell_x - 1, cell_x + 2):
				view.set_cell(y * view.gw + x, manor_id, 0)
		var centre := cell_y * view.gw + cell_x
		var decoded := int(floor(fposmod(view._block_data[centre].r, 1.0) * 128.0))
		check(decoded == colour * 5, "non-sequential manor ID must use explicit colour slot")
		view.players[colour + 1] = {"x": 0.0, "y": 0.0, "color": colour, "director": false, "alive": true, "name": str(colour)}
		var trail_index := (cell_y + 3) * view.gw + cell_x
		view.set_cell(trail_index, 0, colour + 1)
		var trail_decoded := int(floor(fposmod(view._block_data[trail_index].r, 1.0) * 128.0))
		check(int(trail_decoded / 5) == colour, "trail and manor must share their hue")
		samples.append(Vector3(float(cell_x) + 0.5, 36.0 / 16.0, -float(cell_y) - 0.5))
	# Valuation changes select the other brightness row, preserving the assigned hue.
	view.set_cell_valuation(5 * view.gw + 4, 3)
	check(int(floor(fposmod(view._block_data[5 * view.gw + 4].r, 1.0) * 128.0)) == 3, "valuation must survive colour encoding")
	view.set_cell_valuation(5 * view.gw + 4, 0)
	# Route rollback removes only the departing trail and immediately reveals its manor.
	var crossed := 5 * view.gw + 4
	view.set_cell(crossed, 100, 2)
	view.set_cell(crossed, 100, 0)
	view.clear_trail_cell(crossed)
	check(not view._trail_fade.has(crossed), "rollback must not leave a ghost trail")
	check(int(round(view._block_data[crossed].a)) % 8 == 1, "rollback must reveal live manor")
	view._block_material.set_shader_parameter("clock_s", 5.0)
	view._block_material.set_shader_parameter("ai_is_jump", false)
	view._block_material.set_shader_parameter("local_colour", -1)
	view.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	view.camera.size = 42.0
	view.camera.position = Vector3(19.5, 45.0, -10.5)
	view.camera.look_at(Vector3(19.5, 0.0, -10.5), Vector3(0, 0, -1))
	for unused in range(8): await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var rendered_colours: Array[Color] = []
		for sample in samples:
			var point := view.camera.unproject_position(sample)
			var rendered := image.get_pixel(clampi(int(point.x), 0, image.get_width()-1), clampi(int(point.y), 0, image.get_height()-1))
			for previous in rendered_colours:
				check(Vector3(rendered.r-previous.r, rendered.g-previous.g, rendered.b-previous.b).length() > 0.025, "rendered swatches must remain visibly different")
			rendered_colours.append(rendered)
		print("RENDERED COLOURS: ", rendered_colours)
		check(image.save_png(shot) == OK, "save colour evidence")
		print("COLOUR SHOT: ", shot)
	var removed := 15 * view.gw + 4
	view.set_cell(removed, 0, 0)
	check(int(view._sink[removed][1]) == 5, "disappearing manor must keep explicit hue")
	view.end_scene()
	check(view._manor_colours.is_empty(), "end scene must clear hue ownership")
	view.begin_scene(8, 8)
	view.set_process(false)
	check(view._manor_colours.is_empty(), "new scene must start with no stale manor hues")
	view.end_scene()
	if failures.is_empty(): print("COLOUR REGRESSION PASSED: ten hues, owner mapping, valuation, trail rollback and scene reset")
	get_tree().quit(0 if failures.is_empty() else 1)
