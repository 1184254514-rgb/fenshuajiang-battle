class_name PlannerHud
extends Control
# Local planner console; normal gameplay keeps the original HUD untouched.
var host: LuaHost
var layer: ColorRect
var fields: Dictionary = {}
var save_button: Button
var defaults_button: Button
var actions: Dictionary = {}
var status: Label
var info: Label
var _poll := 0.0
var _editable := true
var _settings_path := "user://planner-settings.json"
var _test_mode := false
const SPECS = [
 ["duration_ms","比赛时长",30,3600,240,1000,"秒 · 下一局"],
 ["respawn_ms","重生等待",1,30,3,1000,"秒 · 下一局"],
 ["exp_count","场上经验数量",0,300,60,1,"份 · 下一局"],
 ["exp_reward","每份经验奖励",1,10000,100,1,"经验 · 下一局"],
 ["start_exp","开局初始经验",0,9000,0,1,"经验 · 下一局"],
 ["cooldown_percent","技能冷却比例",0,300,100,1,"% · 0 为无冷却 · 下一局"]]

func _ready() -> void:
	name="PlannerHud"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=4000
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--verify-"): _test_mode=true
	var scene=get_tree().current_scene
	if scene != null and scene.scene_file_path.begins_with("res://tests/"): _test_mode=true
	var parent_scene=host.get_parent()
	if parent_scene!=null and parent_scene.scene_file_path.begins_with("res://tests/"): _test_mode=true
	if _test_mode:
		_settings_path="user://planner-test-settings.json"
		host.lua.do_string("for k,s in pairs(ScenePlanner.spec) do ScenePlanner.settings[k]=s[1];ScenePlanner.project_settings[k]=s[1] end")
	_build()
	layer.hide()
	if not _test_mode: _load_settings()

func _style(fill: Color) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	box.bg_color=fill
	box.border_color=Color("68869c")
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	return box

func _label(parent: Node, text: String, pos: Vector2, extent: Vector2, font_size: int=20) -> Label:
	var label=Label.new()
	label.text=text
	label.position=pos
	label.size=extent
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("e8f0f5"))
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _button(parent: Node, caption: String, pos: Vector2, extent: Vector2, action: Callable) -> Button:
	var button=Button.new()
	button.text=caption
	button.position=pos
	button.size=extent
	button.add_theme_font_size_override("font_size",20)
	button.add_theme_stylebox_override("normal",_style(Color("25546f")))
	button.add_theme_stylebox_override("hover",_style(Color("397596")))
	button.add_theme_stylebox_override("pressed",_style(Color("183f57")))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _build() -> void:
	layer=ColorRect.new()
	layer.size=Vector2(1280,720)
	layer.color=Color(0.02,0.05,0.09,0.85)
	layer.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(layer)
	var panel=Panel.new()
	panel.position=Vector2(100,35)
	panel.size=Vector2(1080,650)
	panel.add_theme_stylebox_override("panel",_style(Color("132735")))
	layer.add_child(panel)
	_label(panel,"策划后台",Vector2(28,17),Vector2(650,40),30)
	_label(panel,"F8 打开 / 关闭   ·   参数仅本机保存，联机由房主控制",Vector2(29,65),Vector2(950,29),19)
	_button(panel,"关闭",Vector2(954,20),Vector2(95,40),func():layer.hide())
	_label(panel,"下一局参数",Vector2(30,112),Vector2(500,30),23)
	for i in SPECS.size():
		var spec=SPECS[i]
		var y=158+i*57
		_label(panel,spec[1],Vector2(30,y+3),Vector2(183,32))
		var spin=SpinBox.new()
		spin.name=spec[0]
		spin.position=Vector2(218,y)
		spin.size=Vector2(133,37)
		spin.min_value=spec[2]
		spin.max_value=spec[3]
		spin.step=1
		spin.value=spec[4]
		spin.add_theme_font_size_override("font_size",20)
		panel.add_child(spin)
		fields[spec[0]]=spin
		_label(panel,spec[6],Vector2(367,y+7),Vector2(280,28),16)
	save_button=_button(panel,"保存并应用",Vector2(30,516),Vector2(180,44),_save_settings)
	save_button.name="SavePlannerSettings"
	defaults_button=_button(panel,"恢复项目值",Vector2(230,516),Vector2(157,44),_restore_defaults)
	defaults_button.name="ResetPlannerDefaults"
	_label(panel,"本局即时调试",Vector2(690,112),Vector2(350,30),23)
	info=_label(panel,"请先开始比赛",Vector2(690,155),Vector2(350,65),18)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var labels=[["add_xp","本人 +1000 经验"],["max_xp","本人升至满级"],["clear_cd","清除本人技能冷却"],["pause_ai","暂停 / 恢复 AI"],["restart","重开测试局"]]
	for i in labels.size():
		var row=labels[i]
		var button=_button(panel,row[1],Vector2(690,234+i*56),Vector2(350,43),_run_action.bind(row[0]))
		button.name="PlannerAction_"+row[0]
		actions[row[0]]=button
	_label(panel,"面板打开时比赛继续运行。
即时操作会影响整局测试。",Vector2(690,526),Vector2(360,60),17)
	status=_label(panel,"默认：4分钟、3秒重生、每份100经验、正常技能冷却。",Vector2(30,587),Vector2(1015,50),17)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F8:
			layer.visible=not layer.visible
			if layer.visible: _refresh(true)
			get_viewport().set_input_as_handled()
		elif layer.visible and event.keycode==KEY_ESCAPE:
			layer.hide()
			get_viewport().set_input_as_handled()

func _unhandled_key_input(_event: InputEvent) -> void:
	if layer.visible: get_viewport().set_input_as_handled()

func _invoke(method: String, args: Array=[]) -> Dictionary:
	var callback=host.lua.do_string("return function(...) local ok,msg=ScenePlanner."+method+"(...);return SceneSkills.EncodeJSON({ok=ok,message=msg}) end")
	if callback is LuaError: return {"ok":false,"message":str(callback)}
	var result=callback.invokev(args)
	if result is LuaError:
		host._tick_errors+=1
		return {"ok":false,"message":str(result)}
	var parsed=JSON.parse_string(str(result))
	return parsed if parsed is Dictionary else {"ok":false,"message":"操作未完成"}

func _show_result(result: Dictionary) -> void:
	status.text=str(result.get("message",""))
	status.add_theme_color_override("font_color",Color("a5e8bd") if result.get("ok",false) else Color("ffc58b"))

func _values() -> Dictionary:
	var values={}
	for spec in SPECS:
		var spin: SpinBox=fields[spec[0]]
		if spin.get_line_edit().has_focus(): spin.apply()
		values[spec[0]]=roundi(spin.value)*int(spec[5])
	return values

func _save_settings() -> void:
	var text=JSON.stringify(_values(),"  ")
	var result=_invoke("ApplyJSON",[text])
	if result.get("ok",false):
		var file=FileAccess.open(_settings_path,FileAccess.WRITE)
		if file==null: result={"ok":false,"message":"设置已应用，但本机保存失败，请检查目录权限"}
		else:
			file.store_string(text)
			file.close()
			result.message="已保存到本机；下一局生效。当前比赛的参数保持不变。"
	_show_result(result)

func _load_settings() -> bool:
	if not FileAccess.file_exists(_settings_path): return false
	var result=_invoke("ApplyJSON",[FileAccess.get_file_as_string(_settings_path)])
	_show_result(result)
	return result.get("ok",false)

func _restore_defaults() -> void:
	var text=str(host.lua.do_string("return ScenePlanner.ProjectJSON()"))
	var result=_invoke("ApplyJSON",[text])
	if result.get("ok",false):
		if FileAccess.file_exists(_settings_path):
			var error=DirAccess.remove_absolute(_settings_path)
			if error!=OK: result={"ok":false,"message":"项目值已应用，但移除本机覆盖失败"}
		if result.get("ok",false): result.message="已恢复项目设置，并移除本机覆盖；下一局生效。"
	_refresh(true)
	_show_result(result)

func _run_action(action: String) -> void:
	_show_result(_invoke("Action",[action]))
	_refresh(false)

func _process(delta: float) -> void:
	_poll-=delta
	if not layer.visible or _poll>0: return
	_poll=0.25
	_refresh(false)

func _refresh(fill_fields: bool) -> void:
	var result=host.lua.do_string("return ScenePlanner.StateJSON()")
	if result is LuaError: return
	var data=JSON.parse_string(str(result))
	if not data is Dictionary: return
	_editable=data.get("editable",false)
	for spec in SPECS:
		fields[spec[0]].editable=_editable
		if fill_fields or not _editable: fields[spec[0]].value=float(data.settings.get(spec[0],spec[4]*spec[5]))/spec[5]
	save_button.disabled=not _editable
	defaults_button.disabled=not _editable
	for button in actions.values(): button.disabled=not _editable or not data.get("active",false)
	info.text=("房主 / 单机可操作" if _editable else "联机客人只读")+"
角色 Lv.%d · 技能 Lv.%d · %d 经验" % [int(data.get("level",1)),int(data.get("skill",1)),int(data.get("xp",0))]
	if data.get("paused",false): info.text+=" · AI已暂停"
