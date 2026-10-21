# Image and text-style native integration

## Host exposure

Expose one `GuiImageOps` instance on the Lua host object so Lua can call `Host.img`:

```gdscript
LuaApi.set("img", GuiImageOps.new())
```

Place this beside the existing `Host`/`LuaApi` exports in `scripts/lua_host.gd`. If `LuaApi` is populated through a dictionary instead, add the equivalent `img` entry there.

## Load the Lua module

In `lua/natives/gui.lua`, immediately before its existing final line:

```lua
require("natives.gui_widgets")
```

insert:

```lua
require("natives.gui_images")
```

This loads the methods after `CGWnd` exists and before the widget subclasses are extended.

## Remove the old CGWnd definitions

In `lua/natives/gui.lua`, remove the existing definitions of:

```lua
function CGWnd:SetBackgroundColor(group, state, color) ... end
function CGWnd:SetWndTextColor(group, state, color) ... end
function CGWnd:SetWndTextBcColor(group, state, color) ... end
function CGWnd:SetSaturation(value) ... end
```

The new `gui_images.lua` supplies these methods through `Host.img`.

## Remove the CPicture duplicates

In `lua/natives/gui_widgets.lua`, delete the complete block beginning with:

```lua
-- Picture and font-effect windows share the same image/text backing store.
```

and ending with:

```lua
function CPicture:SetImageHue(_index, _hue) end
```

Keep the following `CFontEffectWnd` functions. The image and text-style methods now live on `CGWnd`, which `CPicture` and the other window classes inherit from.

## Make `_draw_image` use per-image textures

In `scripts/gui_widgets.gd`, replace the existing `texture_index` bounds-check block inside `_draw_image` with these exact three lines:

```gdscript
var image_texture: Texture2D = image_data.get("texture") as Texture2D
if image_texture == null and texture_index >= 0 and texture_index < textures.size(): image_texture = textures[texture_index] as Texture2D
if image_texture == null: draw_rect(target, modulate_color); return
```

Then change both `draw_texture_rect_region(...)` calls in `_draw_image` to pass `image_texture` as their first argument instead of `textures[texture_index]`. `_draw()` needs no change. This lets dynamically added images use their own texture while preserving layout atlas images and the flat-color fallback.

## Render text colours by state

`GuiImageOps` stores per-state text colours in node metadata. In `scripts/gui_widgets.gd`, add these lines at the start of `_get_text_color()`, before the existing `_has_text_color_override` check:

```gdscript
var state_colors: Dictionary = get_meta("gui_state_text_colors", {})
if state_colors.has(state): return _color_from_argb(int(state_colors[state]))
```

Replace `_draw_text_background` with:

```gdscript
func _draw_text_background(rect: Rect2) -> void:
	var state_colors: Dictionary = get_meta("gui_state_text_background_colors", {})
	var background := text_background_color
	if state_colors.has(state): background = _color_from_argb(int(state_colors[state]))
	if background.a > 0.0: draw_rect(rect, background)
```