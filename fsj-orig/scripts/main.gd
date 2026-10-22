extends Node
# Entry scene: boots the original Lua client inside Godot (login screen -> home -> offline "自嗨" match). Claude.
var host: LuaHost

func _ready() -> void:
	# Exercise the exact exported runtime through optional developer CLI checks.
	var arguments := OS.get_cmdline_user_args()
	for route in ["lan-flow", "lan-ui", "skill-cast", "timed-flow", "planner-flow"]:
		if ("--verify-" + route) in arguments:
			var scene_path := "res://tests/lan_flow_regression.tscn" if route == "lan-flow" else "res://tests/lan_ui_smoke.tscn"
			if route == "skill-cast": scene_path = "res://tests/skill_cast_regression.tscn"
			if route == "planner-flow": scene_path = "res://tests/planner_flow_regression.tscn"
			if route == "timed-flow": scene_path = "res://tests/timed_flow_regression.tscn"
			add_child(load(scene_path).instantiate())
			return
	RenderingServer.set_default_clear_color(Color(0.55, 0.75, 0.9))
	var ui := Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	host = LuaHost.new()
	add_child(host)
	if not host.start(ui):
		push_error("Lua host failed to start")
		return
	var r = host.lua.do_string("require 'start_game'")
	if r is LuaError:
		push_error("start_game failed: " + str(r))
