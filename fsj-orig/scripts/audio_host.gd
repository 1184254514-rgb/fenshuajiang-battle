class_name AudioHost
extends Node

# Add beneath LuaHost and expose this instance as Host.audio.
# Public bridge methods accept/return strings, numbers and booleans.
# Gains are linear [0, 1]; positions and lengths are milliseconds.
#
# This node owns one background/IMusic player. The supplied SceneView keeps
# its rhythm player: we route it through the music bus and suspend background
# playback while SceneView.music_playing is true. Its rhythm clock is untouched.

const DATA_ROOT := "res://data/orig/"
const SOUND_BUS: StringName = &"OriginalSound"
const MUSIC_BUS: StringName = &"OriginalMusic"

@export_range(1, 128, 1) var max_sound_players: int = 24
@export_range(1, 128, 1) var max_cached_streams: int = 24


class CachedMP3:
	var stream: AudioStreamMP3
	var looping_stream: AudioStreamMP3
	var last_used: int = 0


class SoundRecord:
	var path: String = ""
	var volume: float = 1.0
	var auto_release: bool = false
	var looping: bool = false
	var slot: int = -1


class SoundVoice:
	var player: AudioStreamPlayer
	var handle: int = 0
	var order: int = 0


var _cache: Dictionary = {}
var _warned_paths: Dictionary = {}
var _cache_clock: int = 0
var _sounds: Dictionary = {}
var _voices: Array[SoundVoice] = []
var _next_handle: int = 0
var _voice_order: int = 0

var _sound_volume: float = 1.0
var _music_volume: float = 1.0
var _music_player: AudioStreamPlayer
var _music_ticket: int = 0
var _music_paused: bool = false
var _finished_music: Array[int] = []

var _scene_view: SceneView
var _scene_busy: bool = false
var _scene_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 100
	_apply_bus_volume(SOUND_BUS, _sound_volume)
	_apply_bus_volume(MUSIC_BUS, _music_volume)

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	for unused in range(mini(8, maxi(1, max_sound_players))):
		_add_voice()

	get_tree().node_added.connect(_on_node_added)
	_find_scene_view(get_tree().root)


func _process(_delta: float) -> void:
	_sync_scene_music()


func _gain(value: float) -> float:
	return clampf(value, 0.0, 1.0) if is_finite(value) else 0.0


func _ensure_bus(bus_name: StringName) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
	return index


func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var index := _ensure_bus(bus_name)
	AudioServer.set_bus_volume_db(
		index, linear_to_db(value) if value > 0.0 else -80.0
	)
	AudioServer.set_bus_mute(index, value <= 0.0)


func set_sound_volume(value: float) -> void:
	_sound_volume = _gain(value)
	_apply_bus_volume(SOUND_BUS, _sound_volume)


func set_music_volume(value: float) -> void:
	_music_volume = _gain(value)
	_apply_bus_volume(MUSIC_BUS, _music_volume)


func _resolve_path(path: String) -> String:
	var normalized := path.strip_edges().replace("\\", "/")
	if normalized.is_empty():
		return ""
	if normalized.begins_with("res://") or normalized.begins_with("user://"):
		return normalized.simplify_path()
	if normalized.is_absolute_path() or normalized.contains(":"):
		return ""
	return (DATA_ROOT + normalized).simplify_path()


func _warn_once(path: String, reason: String) -> void:
	if not _warned_paths.has(path):
		_warned_paths[path] = true
		push_warning("AudioHost: %s: %s" % [reason, path])


func _make_cache_room() -> void:
	while _cache.size() >= maxi(1, max_cached_streams):
		var oldest_path := ""
		var oldest_time := _cache_clock + 1
		for key in _cache:
			var entry: CachedMP3 = _cache[key]
			if entry.last_used < oldest_time:
				oldest_time = entry.last_used
				oldest_path = String(key)
		if oldest_path.is_empty():
			break
		# Playing voices retain their own resource references.
		_cache.erase(oldest_path)


func _get_stream(path: String, looping: bool = false) -> AudioStreamMP3:
	var resolved := _resolve_path(path)
	if resolved.is_empty() or resolved.get_extension().to_lower() != "mp3":
		return null

	_cache_clock += 1
	var entry := _cache.get(resolved) as CachedMP3
	if entry == null:
		if not FileAccess.file_exists(resolved):
			_warn_once(resolved, "missing MP3")
			return null
		var bytes := FileAccess.get_file_as_bytes(resolved)
		if bytes.is_empty():
			_warn_once(resolved, "empty or unreadable MP3")
			return null

		var stream := AudioStreamMP3.new()
		stream.data = bytes
		stream.loop = false
		if stream.get_length() <= 0.0:
			_warn_once(resolved, "invalid MP3")
			return null

		_make_cache_room()
		entry = CachedMP3.new()
		entry.stream = stream
		_cache[resolved] = entry
		_warned_paths.erase(resolved)

	entry.last_used = _cache_clock
	if not looping:
		return entry.stream

	# Never mutate a stream shared with non-looping effects.
	if entry.looping_stream == null:
		entry.looping_stream = entry.stream.duplicate() as AudioStreamMP3
		entry.looping_stream.loop = true
	return entry.looping_stream


func has_stream(path: String) -> bool:
	return _get_stream(path) != null


func stream_length_ms(path: String) -> float:
	var stream := _get_stream(path)
	return stream.get_length() * 1000.0 if stream != null else 0.0


func clear_cache() -> void:
	_cache.clear()
	_warned_paths.clear()


func _new_handle() -> int:
	_next_handle += 1
	return _next_handle


func _add_voice() -> int:
	var index := _voices.size()
	var voice := SoundVoice.new()
	voice.player = AudioStreamPlayer.new()
	voice.player.name = "Sound%02d" % index
	voice.player.bus = SOUND_BUS
	voice.player.max_polyphony = 1
	add_child(voice.player)
	voice.player.finished.connect(_on_sound_finished.bind(index))
	_voices.append(voice)
	return index


func _voice_for(handle: int) -> SoundVoice:
	var record := _sounds.get(handle) as SoundRecord
	if record == null or record.slot < 0 or record.slot >= _voices.size():
		return null
	var voice := _voices[record.slot]
	return voice if voice.handle == handle else null


func _detach_voice(index: int, reclaim_auto: bool = true) -> void:
	var voice := _voices[index]
	var record := _sounds.get(voice.handle) as SoundRecord
	if record != null and record.slot == index:
		record.slot = -1
		if reclaim_auto and record.auto_release:
			_sounds.erase(voice.handle)

	voice.handle = 0
	voice.player.stop()
	voice.player.stream_paused = false
	voice.player.stream = null


func _allocate_voice() -> int:
	for index in range(_voices.size()):
		var voice := _voices[index]
		if voice.handle == 0:
			return index
		if not voice.player.playing and not voice.player.stream_paused:
			_detach_voice(index)
			return index

	if _voices.size() < maxi(1, max_sound_players):
		return _add_voice()

	# Deterministic voice stealing when the bounded pool is full.
	var oldest := 0
	for index in range(1, _voices.size()):
		if _voices[index].order < _voices[oldest].order:
			oldest = index
	_detach_voice(oldest)
	return oldest


func _on_sound_finished(index: int) -> void:
	var voice := _voices[index]
	# Ignore a completion belonging to playback already replaced in this slot.
	if voice.handle != 0 and not voice.player.playing \
			and not voice.player.stream_paused:
		_detach_voice(index)


func sound_create(path: String, auto_release: bool = false) -> int:
	if _get_stream(path) == null:
		return 0
	var record := SoundRecord.new()
	record.path = _resolve_path(path)
	record.auto_release = auto_release
	var handle := _new_handle()
	_sounds[handle] = record
	return handle


func sound_play(handle: int, looping: bool = false, restart: bool = true) -> bool:
	if not is_inside_tree() or not is_node_ready():
		return false
	var record := _sounds.get(handle) as SoundRecord
	if record == null:
		return false

	var existing := _voice_for(handle)
	if existing != null and not restart \
			and (existing.player.playing or existing.player.stream_paused):
		existing.player.stream_paused = false
		return true

	var stream := _get_stream(record.path, looping)
	if stream == null:
		return false
	if existing != null:
		# Restarting an auto-release sound must preserve its handle.
		_detach_voice(record.slot, false)

	var index := _allocate_voice()
	var voice := _voices[index]
	record.slot = index
	record.looping = looping
	_voice_order += 1
	voice.handle = handle
	voice.order = _voice_order
	voice.player.bus = SOUND_BUS
	voice.player.stream = stream
	voice.player.volume_linear = record.volume
	voice.player.stream_paused = false
	voice.player.play()
	return true


func sound_stop(handle: int) -> void:
	var record := _sounds.get(handle) as SoundRecord
	if record == null:
		return
	if _voice_for(handle) != null:
		_detach_voice(record.slot)
	elif record.auto_release:
		_sounds.erase(handle)


func sound_release(handle: int) -> void:
	var record := _sounds.get(handle) as SoundRecord
	if record == null:
		return
	if _voice_for(handle) != null:
		_detach_voice(record.slot, false)
	_sounds.erase(handle)


func sound_abandon(handle: int) -> void:
	# A temporary Lua wrapper may be collected before its one-shot finishes.
	var record := _sounds.get(handle) as SoundRecord
	if record != null and record.auto_release and not record.looping \
			and _voice_for(handle) != null:
		return
	sound_release(handle)


func sound_set_volume(handle: int, value: float) -> bool:
	var record := _sounds.get(handle) as SoundRecord
	if record == null:
		return false
	record.volume = _gain(value)
	var voice := _voice_for(handle)
	if voice != null:
		voice.player.volume_linear = record.volume
	return true


func sound_pause(handle: int, paused: bool = true) -> bool:
	var voice := _voice_for(handle)
	if voice == null:
		return false
	voice.player.stream_paused = paused
	return true


func sound_is_playing(handle: int) -> bool:
	var voice := _voice_for(handle)
	return voice != null and voice.player.playing \
		and not voice.player.stream_paused


func sound_is_paused(handle: int) -> bool:
	var voice := _voice_for(handle)
	return voice != null and voice.player.stream_paused


func _position_ms(player: AudioStreamPlayer) -> float:
	var seconds := player.get_playback_position()
	if player.playing and not player.stream_paused:
		seconds += AudioServer.get_time_since_last_mix()
	var stream := player.stream as AudioStreamMP3
	if stream != null and stream.get_length() > 0.0:
		if stream.loop:
			seconds = fposmod(seconds, stream.get_length())
		else:
			seconds = minf(seconds, stream.get_length())
	return maxf(0.0, seconds * 1000.0)


func sound_position_ms(handle: int) -> float:
	var voice := _voice_for(handle)
	return _position_ms(voice.player) if voice != null else 0.0


func stop_all_sounds() -> void:
	for handle in _sounds.keys():
		sound_stop(int(handle))


func music_play(path: String, looping: bool = true, volume: float = 1.0) -> int:
	if not is_inside_tree() or _music_player == null:
		return 0
	var stream := _get_stream(path, looping)
	if stream == null:
		return 0

	_sync_scene_music()
	_music_player.stop()
	_music_ticket = _new_handle()
	_music_paused = false
	_music_player.stream_paused = false
	_music_player.stream = stream
	_music_player.volume_linear = _gain(volume)
	_music_player.play()
	_music_player.stream_paused = _scene_busy
	return _music_ticket


func music_owns(ticket: int) -> bool:
	return ticket > 0 and ticket == _music_ticket


func music_stop(ticket: int) -> void:
	if not music_owns(ticket):
		return
	_music_ticket = 0
	_music_paused = false
	_music_player.stop()
	_music_player.stream_paused = false
	_music_player.stream = null


func music_pause(ticket: int, paused: bool = true) -> bool:
	if not music_owns(ticket):
		return false
	_music_paused = paused
	_sync_scene_music()
	return true


func music_is_playing(ticket: int) -> bool:
	return music_owns(ticket) and _music_player.playing \
		and not _music_player.stream_paused


func music_is_paused(ticket: int) -> bool:
	return music_owns(ticket) and _music_player.stream_paused


func music_set_volume(ticket: int, value: float) -> bool:
	if not music_owns(ticket):
		return false
	_music_player.volume_linear = _gain(value)
	return true


func music_position_ms(ticket: int) -> float:
	return _position_ms(_music_player) if music_owns(ticket) else 0.0


func music_seek_ms(ticket: int, position: float) -> bool:
	if not music_owns(ticket) or not is_finite(position):
		return false
	var length := _music_player.stream.get_length()
	_music_player.seek(clampf(position / 1000.0, 0.0, length))
	return true


func _on_music_finished() -> void:
	if _music_ticket == 0 or _music_player.playing \
			or _music_player.stream_paused:
		return
	_finished_music.append(_music_ticket)
	_music_ticket = 0
	_music_paused = false
	_music_player.stream = null


func take_finished_music() -> int:
	return int(_finished_music.pop_front()) if not _finished_music.is_empty() else 0


func _find_scene_view(node: Node) -> bool:
	if node is SceneView:
		_watch_scene_view(node as SceneView)
		return true
	for child in node.get_children():
		if _find_scene_view(child):
			return true
	return false


func _on_node_added(node: Node) -> void:
	if node is SceneView:
		_watch_scene_view(node as SceneView)


func _watch_scene_view(view: SceneView) -> void:
	_scene_view = view
	if not view.is_node_ready() and not view.ready.is_connected(_sync_scene_music):
		view.ready.connect(_sync_scene_music, CONNECT_ONE_SHOT)
	_sync_scene_music()


func _sync_scene_music() -> void:
	var scene_player: AudioStreamPlayer = null
	_scene_busy = false
	if is_instance_valid(_scene_view):
		_scene_busy = _scene_view.music_playing
		if is_instance_valid(_scene_view.music_player):
			scene_player = _scene_view.music_player
			scene_player.bus = MUSIC_BUS

	if not _scene_busy:
		if _scene_paused and scene_player != null:
			scene_player.stream_paused = false
		_scene_paused = false
	elif _scene_paused and scene_player != null:
		scene_player.stream_paused = true

	if _music_ticket != 0 and _music_player != null:
		_music_player.stream_paused = _music_paused or _scene_busy


func scene_pause(paused: bool) -> bool:
	_sync_scene_music()
	if not _scene_busy or not is_instance_valid(_scene_view.music_player):
		return false
	_scene_paused = paused
	_scene_view.music_player.stream_paused = paused
	return true


func _layout_sound(value: Variant) -> Variant:
	if not (value is Dictionary):
		return null
	var direct: Variant = value.get("string_0x64")
	if direct is String:
		return direct
	var window: Variant = value.get("window")
	if window is Dictionary:
		var nested: Variant = window.get("string_0x64")
		if nested is String:
			return nested
	return null


func button_sound_path(instance_id: int) -> String:
	if instance_id <= 0 or not is_instance_id_valid(instance_id):
		return ""
	var object: Object = instance_from_id(instance_id)
	if not (object is Node):
		return ""
	var node := object as Node

	# Preferred explicit bridge for builders that discard their source JSON:
	# node.set_meta("string_0x64", window_json.get("string_0x64", ""))
	if node.has_meta("string_0x64"):
		var direct: Variant = node.get_meta("string_0x64")
		return String(direct) if direct is String else ""

	var properties := node.get_property_list()
	for info in properties:
		if String(info["name"]) == "string_0x64":
			var direct: Variant = node.get("string_0x64")
			return String(direct) if direct is String else ""

	# Also support the existing GuiWnd retaining its window JSON in any
	# Dictionary property. Never descend into children and select their sounds.
	for info in properties:
		var kind := int(info["type"])
		var scripted := (int(info["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0
		if kind == TYPE_DICTIONARY or (kind == TYPE_NIL and scripted):
			var value: Variant = _layout_sound(node.get(String(info["name"])))
			if value is String:
				return String(value)

	for key in node.get_meta_list():
		var value: Variant = _layout_sound(node.get_meta(key))
		if value is String:
			return String(value)
	return ""
