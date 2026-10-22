@tool
extends ScrollContainer
# Editor-only authoring panel. Runtime overrides stay in user:// and are never
# imported as project code or shipped as account/server administration.
var editor_plugin: EditorPlugin
var fields: Dictionary={}
var content: VBoxContainer
var message: Label
var config_path="res://data/planner_settings.json"
var test_mode:=false
const SPECS=[
 ["duration_ms","比赛时长（秒）",30,3600,240,1000],
 ["respawn_ms","重生等待（秒）",1,30,3,1000],
 ["exp_count","场上经验数量",0,300,60,1],
 ["exp_reward","每份经验奖励",1,10000,100,1],
 ["start_exp","开局初始经验",0,9000,0,1],
 ["cooldown_percent","技能冷却比例（%）",0,300,100,1]]

func _ready() -> void:
	name="策划设置"
	custom_minimum_size.x=300
	content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_child(content)
	test_mode="--verify-planner-editor" in OS.get_cmdline_user_args()
	if test_mode: config_path="user://planner-editor-test.json"
	var title=Label.new()
	title.text="粉刷匠 · 策划设置"
	title.add_theme_font_size_override("font_size",20)
	content.add_child(title)
	var note=Label.new()
	note.text="保存到项目后，重新运行生效。
导出的游戏也会使用这些参数。"
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	for spec in SPECS:
		var label=Label.new()
		label.text=spec[1]
		content.add_child(label)
		var spin=SpinBox.new()
		spin.name=spec[0]
		spin.min_value=spec[2]
		spin.max_value=spec[3]
		spin.step=1
		spin.value=spec[4]
		content.add_child(spin)
		fields[spec[0]]=spin
	_button("保存到项目",_save)
	_button("从项目重新读取",_load)
	var line=HSeparator.new()
	content.add_child(line)
	_button("标准 4 分钟",_preset.bind("standard"))
	_button("快速测试（60 秒）",_preset.bind("quick"))
	_button("满级技能测试",_preset.bind("max"))
	_button("运行项目",_run_project)
	message=Label.new()
	message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	message.text="预设先填入参数；点击“保存到项目”后再运行。
客户端隐藏入口：F8。其本机设置可覆盖项目值，F8中“恢复项目值”可清除覆盖。"
	content.add_child(message)
	_load()
	if test_mode: call_deferred("_verify")

func _button(text: String,action: Callable) -> void:
	var button=Button.new()
	button.text=text
	button.pressed.connect(action)
	content.add_child(button)

func _preset(kind: String) -> void:
	for spec in SPECS: fields[spec[0]].value=spec[4]
	if kind=="quick":
		fields.duration_ms.value=60
		fields.respawn_ms.value=1
		fields.exp_count.value=80
		fields.exp_reward.value=500
		fields.cooldown_percent.value=25
	elif kind=="max":
		fields.start_exp.value=9000
		fields.cooldown_percent.value=0
	message.text="预设已填入；保存到项目后，重新运行生效。"

func _values(commit_edits: bool=true) -> Dictionary:
	var result={}
	for spec in SPECS:
		var field: SpinBox=fields[spec[0]]
		if commit_edits and field.get_line_edit().has_focus(): field.apply()
		result[spec[0]]=roundi(field.value)*int(spec[5])
	return result

func _validated(data) -> Dictionary:
	if not data is Dictionary: return {}
	var result={}
	for spec in SPECS:
		var value=data.get(spec[0],null)
		if not (value is int or value is float) or not is_finite(float(value)): return {}
		result[spec[0]]=clampi(roundi(float(value)),int(spec[2])*int(spec[5]),int(spec[3])*int(spec[5]))
	return result

func _save() -> bool:
	var data=_validated(_values())
	if data.is_empty():
		message.text="参数无效，未保存。"
		return false
	var file=FileAccess.open(config_path,FileAccess.WRITE)
	if file==null:
		message.text="保存失败，请检查工程目录权限。"
		return false
	file.store_string(JSON.stringify(data,"  ")+"
")
	file.close()
	message.text="已保存到项目。停止当前运行后，点击“运行项目”开始新测试局。"
	if editor_plugin!=null and not test_mode: editor_plugin.get_editor_interface().get_resource_filesystem().scan()
	return true

func _load() -> bool:
	if not FileAccess.file_exists(config_path): return false
	var parser=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(config_path))!=OK:
		message.text="项目设置格式无效，保留面板当前值。"
		return false
	var data=_validated(parser.data)
	if data.is_empty():
		message.text="项目设置参数不完整，保留面板当前值。"
		return false
	for spec in SPECS: fields[spec[0]].value=float(data[spec[0]])/float(spec[5])
	message.text="已读取项目设置。"
	return true

func _run_project() -> void:
	if editor_plugin==null: return
	var editor=editor_plugin.get_editor_interface()
	if editor.is_playing_scene():
		message.text="请先停止当前运行，再运行新的测试配置。"
		return
	if _save(): editor.play_main_scene()

func _verify() -> void:
	var count=0
	var failures=[]
	for spec in SPECS:
		if fields.has(spec[0]): count+=1
		else: failures.append("missing field "+spec[0])
	_preset("quick")
	await get_tree().process_frame
	if _values(false).duration_ms==60000: count+=1
	else: failures.append("quick preset duration")
	if _save(): count+=1
	else: failures.append("write test settings")
	_preset("max")
	await get_tree().process_frame
	if _values(false).start_exp==9000 and _values(false).cooldown_percent==0: count+=1
	else: failures.append("max preset")
	if _load() and fields.duration_ms.value==60 and fields.start_exp.value==0: count+=1
	else: failures.append("load persisted preset")
	if _validated({}).is_empty(): count+=1
	else: failures.append("reject incomplete data")
	var data=_values(false)
	data.duration_ms=-999
	if _validated(data).duration_ms==30000: count+=1
	else: failures.append("clamp duration")
	_preset("standard")
	await get_tree().process_frame
	if _values(false).duration_ms==240000 and _values(false).exp_reward==100: count+=1
	else: failures.append("standard preset")
	if failures.is_empty(): print("PLANNER EDITOR PASSED: ",count," checks")
	else: printerr("PLANNER EDITOR FAILED: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)
