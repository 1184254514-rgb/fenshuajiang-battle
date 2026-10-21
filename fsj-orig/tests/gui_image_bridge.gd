extends Node
var checks := 0
var failed := false
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failed = true
  printerr("GUI IMAGE FAIL: ", message)
func _ready() -> void:
 var ui := Control.new()
 add_child(ui)
 var host := LuaHost.new()
 add_child(host)
 if not host.start(ui): get_tree().quit(1); return
 var boot = host.lua.do_string("require 'start_game'")
 check(not boot is LuaError, "original scripts loaded")
 for i in 5: await get_tree().process_frame
 var node = host.lua.do_string("""
  __image_bridge=CGWnd:new('gui/cfg/fsj_zjm.gui',nil,1)
  local w=__image_bridge:GetDlgChild('W_youxishijian')
  local src=CFRect:new();src:left(10);src:top(20);src:right(42);src:bottom(68)
  local dst=CFRect:new();dst:left(1);dst:top(2);dst:right(65);dst:bottom(98)
  assert(w:AddImage(0,2,-1,'gui/tex/fs_jm002.tex',src,dst,0xffffffff,15,9,-1,-1,0,1,0),'AddImage failed after original table.unpack override')
  return w.__node
 """)
 check(node is Control, "image bridge returns actual GUI node")
 if node is Control:
  var images: Array = node.get("images_by_state")[2]
  check(not images.is_empty(), "original Lua adds atlas image after Help.lua")
  var item: Dictionary = images.back()
  check(item["texture"] is Texture2D, "atlas texture loaded")
  var src: Dictionary = item["source_rect"]
  var dst: Dictionary = item["destination_rect"]
  check(src == {"left":10.0,"top":20.0,"right":42.0,"bottom":68.0}, "Lua rectangle keeps precise atlas crop")
  check(dst == {"left":1.0,"top":2.0,"right":65.0,"bottom":98.0}, "Lua rectangle keeps destination geometry")
  var count = host.lua.do_string("return __image_bridge:GetDlgChild('W_youxishijian'):GetImageCount(0,2)")
  check(int(count)==images.size(), "image-count native uses captured standard unpack")
 check(host._tick_errors==0, "no original Lua errors")
 if not failed: print("GUI IMAGE PASSED: ",checks," checks")
 get_tree().quit(1 if failed else 0)
