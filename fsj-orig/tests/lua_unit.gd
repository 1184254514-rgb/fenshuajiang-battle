extends Node
# Runs a Lua test file against the full game stack: Godot --path fsj-orig res://tests/lua_unit.tscn -- --test=res://lua/tests/buffer_test.lua [--full]
func _ready() -> void:
	var test := ""; var full := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--test="): test = a.substr(7)
		elif a == "--full": full = true
	var ui := Control.new(); add_child(ui)
	var host := LuaHost.new(); add_child(host)
	if test.is_empty():
		printerr("TEST ERROR: missing --test=res://lua/tests/<file>.lua")
		get_tree().quit(1)
		return
	if not host.start(ui): get_tree().quit(1); return
	if full:
		var r0 = host.lua.do_string("require 'start_game'")
		if r0 is LuaError:
			printerr("START FAILED: ", r0)
			get_tree().quit(1)
			return
		for i in 5: await get_tree().process_frame
	var r = host.lua.do_file(test)
	if r is LuaError:
		printerr("TEST ERROR: ", r)
		get_tree().quit(1)
	elif host._tick_errors > 0:
		printerr("TEST ERROR: ", host._tick_errors, " Lua tick/callback errors")
		get_tree().quit(1)
	else:
		print("TEST DONE: ", r)
		get_tree().quit(0)
