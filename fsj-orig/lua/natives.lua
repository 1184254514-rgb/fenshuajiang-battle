-- Loads the native implementations in a fixed order. Claude.
local function try(name)
	local ok, err = pcall(require, name)
	if not ok then print("[NATIVE LOAD FAILED] " .. name .. ": " .. tostring(err)) end
end
package.path = "res://lua/?.lua;" .. package.path
try("natives/util")
try("natives/buffer")
try("natives/config")
try("natives/gui")
try("natives/gui_widgets")
try("natives/gui_images")
try("natives/app")
try("natives/scene_ai")
try("natives/scene")
try("natives/audio")
try("natives/gamemain")
try("natives/rhythm_wnd")
try("natives/scene_skills")
try("natives/scene_match")

try("natives/scene_battle_hud")
