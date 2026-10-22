extends Node
# A host-authoritative ENet room. Payloads contain primitive data only.
const PROTOCOL := 1
const PORT := 27866
const MAX_PLAYERS := 10
var host: LuaHost
var peer: ENetMultiplayerPeer
var role := ""
var phase := "idle"
var status := "填写昵称，创建房间或输入房主 IP 加入"
var members: Array = []
var nickname := ""
var address := ""
var my_id := 1
var round_id := 0
var snapshots_received := 0
var last_snapshot := ""
var _send_left := 0.0
var _ping_left := 0.0
var _last_server_ms := 0
var _last_input: Dictionary = {}
var _pending_login := false
var _pending_profile: Dictionary = {}
var _join_started := 0
var _last_sequence := -1
var _sequence := 0
var _last_room_signature := ""

func lua_call(method: String, args: Array = []):
	if host == null or host.lua == null: return null
	var fn = host.lua.do_string("return SceneLAN and SceneLAN." + method)
	if fn == null or fn is LuaError: return null
	var result = fn.invokev(args)
	if result is LuaError:
		host._tick_errors += 1
		printerr("LUA ERROR in LAN ", method, ": ", result)
	return result

func local_ips() -> String:
	var found := PackedStringArray()
	for ip in IP.get_local_addresses():
		if ip.contains(":") or ip.begins_with("127.") or ip.begins_with("169.254."): continue
		found.append(ip)
	return " / ".join(found) if not found.is_empty() else "127.0.0.1"

func _profile(nick: String) -> Dictionary:
	var clean := ""
	for ch in nick.strip_edges():
		if ch.unicode_at(0) >= 32 and ch not in ["|", "\n", "\r"]: clean += ch
	clean = clean.left(16)
	if clean.is_empty(): clean = "画匠" + str(randi_range(100, 999))
	var data = JSON.parse_string(str(host.lua.do_string("return SceneSkills.GetHUDJSON()")))
	return {"nick": clean, "skill": int(data.get("selected", 3)), "passives": data.get("passives", [])}

func _ensure_login(profile: Dictionary) -> void:
	_pending_profile = profile
	var home = host.lua.do_string("return SceneSkills.GetHUD().home")
	if home != true:
		host.lua.do_string("if g_App and not g_App.__scene then g_App:GetLoginFrame():ConnectWorld() end")
		_pending_login = true
	else:
		lua_call("SetNick", [profile.nick])

func create_room(nick: String, port: int = PORT) -> bool:
	if peer != null: return false
	var profile := _profile(nick)
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, MAX_PLAYERS - 1, 2)
	if error != OK:
		peer = null
		status = "创建失败：端口 %d 不可用（%s）" % [port, error_string(error)]
		return false
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	peer.peer_disconnected.connect(_disconnected)
	role = "host"
	phase = "lobby"
	my_id = 1
	nickname = profile.nick
	profile.peer = 1
	members = [profile]
	address = local_ips()
	status = "房间已创建，等待朋友加入；房主点击开始比赛"
	_ensure_login(profile)
	return true

func join_room(nick: String, ip: String, port: int = PORT) -> bool:
	if peer != null: return false
	var target := ip.strip_edges()
	if not target.is_valid_ip_address():
		status = "请输入房主的局域网 IP，例如 192.168.1.8"
		return false
	var profile := _profile(nick)
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_client(target, port, 2)
	if error != OK:
		peer = null
		status = "连接失败：" + error_string(error)
		return false
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	role = "client"
	phase = "connecting"
	nickname = profile.nick
	address = target
	my_id = peer.get_unique_id()
	_pending_profile = profile
	_join_started = Time.get_ticks_msec()
	_last_server_ms = _join_started
	status = "正在连接 " + target + "…"
	_ensure_login(profile)
	return true

func _send(id: int, data: Dictionary, channel: int = 0) -> void:
	if peer == null: return
	peer.set_target_peer(id)
	peer.transfer_channel = channel
	peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	peer.put_packet(var_to_bytes(data))

func _broadcast_room() -> void:
	for member in members:
		if int(member.peer) != 1:
			_send(int(member.peer), {"type": "room", "protocol": PROTOCOL, "members": members, "phase": phase, "round": round_id})

func _validated_profile(data: Dictionary) -> Dictionary:
	if int(data.get("protocol", -1)) != PROTOCOL: return {}
	var nick := str(data.get("nick", "")).strip_edges().left(16)
	for ch in nick:
		if ch.unicode_at(0) < 32 or ch == "|": return {}
	if nick.is_empty(): return {}
	var skill := int(data.get("skill", 3))
	if skill < 1 or skill > 7: return {}
	var passives = data.get("passives", [])
	if not passives is Array or passives.size() > 3: return {}
	var catalog = JSON.parse_string(str(host.lua.do_string("return SceneSkills.GetHUDJSON()")))
	var allowed: Array = [0]
	for item in catalog.get("passive", []): allowed.append(int(item.id))
	var used: Array = []
	for value in passives:
		var id := int(value)
		if id not in allowed or (id != 0 and id in used): return {}
		used.append(id)
	return {"nick": nick, "skill": skill, "passives": used}

func _handle(sender: int, data: Dictionary) -> void:
	var kind := str(data.get("type", ""))
	if role == "host":
		if kind == "hello":
			for member in members:
				if int(member.peer) == sender: return
			var profile := _validated_profile(data)
			if phase != "lobby" or members.size() >= MAX_PLAYERS or profile.is_empty():
				_send(sender, {"type": "reject", "message": "房间已开赛、已满，或版本不一致，请等待房主返回房间"})
				return
			profile.peer = sender
			members.append(profile)
			status = "%s 加入了房间（%d/10）" % [profile.nick, members.size()]
			_broadcast_room()
		elif kind == "input" and phase == "playing":
			var now := Time.get_ticks_msec()
			if now - int(_last_input.get(sender, 0)) < 25: return
			_last_input[sender] = now
			var direction := int(data.get("direction", 0))
			var skill := bool(data.get("skill", false))
			var grade := clampi(int(data.get("grade", -1)), -1, 3)
			lua_call("Input", [sender, direction, skill, grade])
		elif kind == "leave":
			_disconnected(sender)
		elif kind == "ping":
			_send(sender, {"type": "pong"})
		return
	if sender != 1: return
	_last_server_ms = Time.get_ticks_msec()
	if kind == "reject":
		leave_room(str(data.get("message", "房主拒绝了连接")))
	elif kind == "room":
		if int(data.get("protocol", -1)) != PROTOCOL: return
		members = data.get("members", [])
		phase = str(data.get("phase", "lobby"))
		status = "已加入房间，等待房主开始（%d/10）" % members.size()
	elif kind == "start":
		round_id = int(data.get("round", 0))
		_last_sequence = -1
		phase = "loading"
	elif kind == "snapshot":
		if int(data.get("round", -1)) != round_id: return
		var sequence := int(data.get("sequence", -1))
		if sequence <= _last_sequence or _pending_login: return
		if phase == "loading":
			lua_call("BeginClient")
			phase = "playing"
		if phase not in ["playing", "finished"]: return
		last_snapshot = str(data.get("state", "{}"))
		var applied = lua_call("Apply", [last_snapshot, my_id])
		if applied == true:
			_last_sequence = sequence
			snapshots_received += 1
			if host.lua.do_string("return g_App.__scene.__match_finished") == true: phase = "finished"
	elif kind == "lobby":
		lua_call("Leave")
		phase = "lobby"
		status = "比赛结束，可等待房主再开一局"
	elif kind == "closed":
		leave_room("房主关闭了房间")

func start_match() -> bool:
	if role != "host" or phase not in ["lobby", "finished"] or _pending_login: return false
	round_id += 1
	_sequence = 0
	var ok = lua_call("BeginHost", [JSON.stringify(members)])
	if ok != true:
		status = "启动比赛失败，请返回大厅重试"
		return false
	phase = "playing"
	status = "比赛中 · %d 秒" % roundi(float(host.lua.do_string("return SceneMatch.GetTimeRemain(g_App.__scene)")) / 1000.0)
	for member in members:
		if int(member.peer) != 1: _send(int(member.peer), {"type": "start", "round": round_id})
	_send_left = 0.0
	return true

func send_input(direction: int, skill: bool, grade: int = -1) -> void:
	if phase != "playing": return
	if role == "host": lua_call("Input", [1, direction, skill, grade])
	elif role == "client": _send(1, {"type": "input", "direction": direction, "skill": skill, "grade": grade})

func game_action(action: String) -> void:
	if action == "rematch":
		if role == "host": start_match()
		else: status = "请等待房主再开一局"
	elif action == "leave":
		if role == "host":
			lua_call("Leave")
			phase = "lobby"
			for member in members:
				if int(member.peer) != 1: _send(int(member.peer), {"type": "lobby"})
			_broadcast_room()
		else: leave_room("已离开联机比赛")

func _disconnected(id: int) -> void:
	if role != "host": return
	for i in range(members.size() - 1, -1, -1):
		if int(members[i].peer) == id:
			status = str(members[i].nick) + " 已离开，比赛中由 AI 接管"
			members.remove_at(i)
			lua_call("DropPeer", [id])
	_last_input.erase(id)
	_broadcast_room()

func leave_room(message: String = "已离开房间") -> void:
	if peer != null:
		if role == "host":
			for member in members:
				if int(member.peer) != 1: _send(int(member.peer), {"type": "closed"})
		elif peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_send(1, {"type": "leave"})
		if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
			peer.host.flush()
		peer.close()
		peer = null
	lua_call("Leave")
	role = ""
	phase = "idle"
	members.clear()
	_pending_login = false
	_last_sequence = -1
	status = message

func _exit_tree() -> void:
	if peer != null: peer.close()

func _process(delta: float) -> void:
	if _pending_login and host.lua.do_string("return SceneSkills and SceneSkills.GetHUD().home") == true:
		_pending_login = false
		lua_call("SetNick", [_pending_profile.nick])
	if peer == null: return
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		leave_room("连接已断开，请检查房主 IP、同一局域网和防火墙许可")
		return
	peer.poll()
	if role == "client" and peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		leave_room("与房主的连接已断开，已返回大厅")
		return
	if role == "client" and phase == "connecting":
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			phase = "registering"
			var hello := _pending_profile.duplicate(true)
			hello.type = "hello"
			hello.protocol = PROTOCOL
			_send(1, hello)
		elif Time.get_ticks_msec() - _join_started > 8000:
			leave_room("连接超时：请检查 IP、同一局域网，以及房主的专用网络防火墙许可")
			return
	var packets := 0
	while peer != null and peer.get_available_packet_count() > 0 and packets < 64:
		var sender := peer.get_packet_peer()
		var packet := peer.get_packet()
		packets += 1
		if packet.size() > (4096 if role == "host" else 2097152): continue
		var data = bytes_to_var(packet)
		if data is Dictionary: _handle(sender, data)
	if peer == null: return
	if role == "host" and phase in ["playing", "finished"]:
		_send_left -= delta
		if _send_left <= 0.0:
			_send_left = 0.1
			_sequence += 1
			last_snapshot = str(lua_call("Snapshot"))
			for member in members:
				if int(member.peer) != 1:
					_send(int(member.peer), {"type": "snapshot", "round": round_id, "sequence": _sequence, "state": last_snapshot}, 1)
			if host.lua.do_string("return g_App.__scene and g_App.__scene.__match_finished") == true: phase = "finished"
	elif role == "client":
		_ping_left -= delta
		if _ping_left <= 0.0 and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
			_ping_left = 2.0
			_send(1, {"type": "ping"})
		if Time.get_ticks_msec() - _last_server_ms > 10000:
			leave_room("与房主的连接已断开，已返回大厅")
