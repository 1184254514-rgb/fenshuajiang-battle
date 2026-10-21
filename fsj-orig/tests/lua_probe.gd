extends Node
class H extends RefCounted:
	func bytes() -> PackedByteArray: return PackedByteArray([1, 2, 255, 0, 65])
	func text() -> String: return "你好abc"
	func hello(a, b): return str(a) + "/" + str(b)
func _ready() -> void:
	var lua := LuaState.new()
	lua.open_libraries()
	var h := H.new()
	lua.globals["H"] = h
	var r = lua.do_string("""
		local b = H:bytes()
		local out = {}
		out[#out+1] = type(b)
		out[#out+1] = tostring(#b)
		out[#out+1] = tostring(b:size())
		out[#out+1] = tostring(b[1])
		out[#out+1] = type(H:text())
		out[#out+1] = H:hello(1, 'x')
		out[#out+1] = string.pack('<I4', 258):byte(1, -1) .. ''
		local s = string.pack('<I4', 258)
		out[#out+1] = tostring(#s)
		return table.concat(out, ' | ')
	""")
	print("RESULT: ", r)
	# string -> PackedByteArray
	var f = lua.do_string("return function(s) return s end")
	var s = f.invoke(PackedByteArray([1,2,3]))
	print("roundtrip type: ", typeof(s), " ", s)
	var s2 = f.invoke("abcÿ")
	print("string rt: ", typeof(s2), " ", s2)
	get_tree().quit()
