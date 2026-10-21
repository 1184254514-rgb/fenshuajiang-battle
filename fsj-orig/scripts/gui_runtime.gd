class_name GuiRuntime
extends RefCounted

const GUI_DIR := "res://data/gui/"
const TEX_DIR := "res://assets/tex/"
const GuiWidgetScript := preload("res://scripts/gui_widgets.gd")

static var dispatch: Callable = Callable()
static var _json_cache: Dictionary = {}
static var _tex_cache: Dictionary = {}


static func load_json(gui_name: String) -> Dictionary:
	var normalized := gui_name.replace("\\", "/")
	var base_name := normalized.get_file()
	if base_name.ends_with(".gui") or base_name.ends_with(".json"):
		base_name = base_name.get_basename()
	if base_name == "":
		base_name = normalized.get_basename()
	if _json_cache.has(base_name):
		return _json_cache[base_name]

	var path := GUI_DIR + base_name + ".json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing GUI JSON: " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid GUI JSON: " + path)
		return {}
	_json_cache[base_name] = parsed
	return parsed


static func atlas(path: String) -> Texture2D:
	var base_name := path.get_file().get_basename()
	if not _tex_cache.has(base_name):
		var resource_path := TEX_DIR + base_name + ".png"
		_tex_cache[base_name] = load(resource_path) if ResourceLoader.exists(resource_path) else null
	return _tex_cache[base_name] as Texture2D


# UI text keys: "<marker char><8 hex digits>" -> text from config/dictionary/<first hex digit>.txt (lines "ID<TAB>text")
static var _dict_files: Dictionary = {}
static var _hex_re: RegEx

static func resolve_text(raw: String) -> String:
	if raw.length() < 9:
		return raw
	if _hex_re == null:
		_hex_re = RegEx.new()
		_hex_re.compile("^.?([0-9a-fA-F]{8})$")
	var m := _hex_re.search(raw)
	if m == null:
		return raw
	var id := m.get_string(1).to_lower()
	var file_key := id.substr(0, 1)
	if not _dict_files.has(file_key):
		var table := {}
		var path := "res://data/orig/config/dictionary/%s.txt" % file_key
		if FileAccess.file_exists(path):
			var bytes := FileAccess.get_file_as_bytes(path)
			var text := bytes.slice(2).get_string_from_utf16() if bytes.size() > 2 and bytes[0] == 0xFF and bytes[1] == 0xFE else bytes.get_string_from_utf8()
			for line in text.split("
"):
				var tab := line.find("	")
				if tab > 0:
					table[line.substr(0, tab).strip_edges().to_lower()] = line.substr(tab + 1).strip_edges()
		_dict_files[file_key] = table
	var found = _dict_files[file_key].get(id, null)
	return str(found) if found != null else raw


static func argb(value: int) -> Color:
	var value_u32 := value & 0xffffffff
	return Color(
		float((value_u32 >> 16) & 255) / 255.0,
		float((value_u32 >> 8) & 255) / 255.0,
		float(value_u32 & 255) / 255.0,
		float((value_u32 >> 24) & 255) / 255.0
	)


static func build(gui_name: String) -> GuiWnd:
	var document := load_json(gui_name)
	if document.is_empty() or not document.has("window"):
		return null

	var textures: Array = []
	var texture_names: Array = document.get("textures", [])
	for texture_name in texture_names:
		textures.append(atlas(str(texture_name)) if str(texture_name) != "" else null)

	var root := GuiWnd.new()
	root.setup(document.get("window", {}), textures, "", GuiWidgetScript)
	return root


class GuiWnd extends GuiWidgetScript:
	pass


