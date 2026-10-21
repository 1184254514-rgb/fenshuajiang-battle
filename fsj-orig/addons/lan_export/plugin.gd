@tool
extends EditorPlugin
var exporter: EditorExportPlugin

class RawAssets extends EditorExportPlugin:
	func _get_name() -> String:
		return "OriginalLuaData"
	func add_tree(path: String) -> void:
		var directory := DirAccess.open(path)
		if directory == null: return
		for child in directory.get_directories(): add_tree(path.path_join(child))
		for file in directory.get_files():
			if file.begins_with(".") or file.ends_with(".uid") or file.ends_with(".import"): continue
			if path.begins_with("res://lua/tests"): continue
			var full := path.path_join(file)
			if path.begins_with("res://assets/fx") and not file.ends_with(".json"): continue
			add_file(full, FileAccess.get_file_as_bytes(full), false)
	func _export_begin(_features: PackedStringArray, _debug: bool, _path: String, _flags: int) -> void:
		for folder in ["res://lua", "res://data", "res://assets/fx"]: add_tree(folder)

func _enter_tree() -> void:
	exporter = RawAssets.new()
	add_export_plugin(exporter)
func _exit_tree() -> void:
	remove_export_plugin(exporter)
	exporter = null
