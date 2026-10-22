@tool
extends EditorPlugin
var dock: Control
func _enter_tree() -> void:
	dock=preload("res://addons/planner_tools/planner_dock.gd").new()
	dock.name="策划设置"
	dock.editor_plugin=self
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL,dock)
func _exit_tree() -> void:
	if is_instance_valid(dock):
		remove_control_from_docks(dock)
		dock.queue_free()
