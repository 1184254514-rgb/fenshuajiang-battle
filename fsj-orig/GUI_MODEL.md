# GUI data model (original `.gui` layouts as JSON) and runtime classes

`res://data/gui/<name>.json` = one original layout file (`gui/cfg/<name>.gui`), produced by `mod-work/tools/gui2json.py`.
Top level: `{"version":10013, "textures":["", "./../tex/fs_jm009.tex", ...], "window":{...}}`; texture index i -> `res://assets/tex/<name>.png`
(atlas, source rects are in atlas pixels; index 0 / -1 = none).
A window dict: `class_name` ("CGWnd","CGButton","CGCheckButton","CGListCtrl","CGEdit","CGRichWnd",...), `wnd_name` (caption key: marker char + 8-hex dictionary id, e.g. "虎900005e9",
look up in `config/dictionary/<first hex digit>.txt` lines `ID<TAB>text`; or plain text), `base_fields` {`this+0x0c` = window style flags (eWS_* constants), `this+0x10` x,
`this+0x14` y, `this+0x18` width, `this+0x1c` height (parent-local), `this+0x20/0x24` extra}, `field_0x3c`, `text` (FONT NAME, e.g. "微软雅黑"; "default"),
`text_style.raw_fields` {`this+0x2c` font size, `this+0x30`, `this+0x34`, `this+0x38` (colours/effect flags, partly unknown)}, `font_name`, `string_0x60`, `string_0x64`
(sound file for buttons, e.g. "sound\btn_xuanze.mp3"), `version_string_slots`, `fade_param`, `child_window_infos` (first entry with `image_lists` = the window's own images),
`children` = list of `{name, window}` (child key used by `GetDlgChild("a.b.c")`).
`image_lists[state]`: index = window STATE id (eST_* constants: 2 ENABLE, 3 DISABLE, 4 MOUSEOVER, 5 CLICKDOWN; check buttons use 6..9 UNCHECK_*; list items 13/14 LS_SEL/LS_UNSEL).
Each image: `texture_index`, `source_rect` {left,top,right,bottom} in atlas pixels (right<left or bottom<top = flipped), `destination_rect` window-local, `color_or_flags_u32` (0xAARRGGBB modulate;
texture_index 4294967295 = flat colour fill), `state`/`substate` (drawing sub-mode: 3 = stretch, 13/14/15/5/8/9/11 = nine-patch parts / flags — treat as plain quads for now).
Window style flags: eWS_CHILD 0x40000000, eWS_INVISIBLE 0x40000, eWS_ALPHAENABLE 0x10000, eWS_NOTSENDNOTIFY 0x80000, text alignment bits eWS_TEXTXC 0x1000000 (center X), eWS_TEXTXR 0x2000000, eWS_TEXTYC 0x4000000 (center Y), eWS_TEXTYB 0x8000000.

Runtime (`scripts/gui_runtime.gd`): `GuiRuntime.build(name) -> GuiWnd` builds the Control tree; `GuiWnd` (Control) draws the image list of its current `state` in `_draw()`.
`GuiWnd.kids` = children by key, `child("a.b")` path lookup, `show_wnd`, `set_wnd_text`, `set_state`, `class_of()`.
Lua side: `lua/natives/gui.lua` wraps nodes as Lua tables (`__node` field, node meta "lua"); the ORIGINAL Lua (`ui_frame/CGWnd.lua`) provides listeners, cue states, etc. on top of three native hooks:
`CGWnd.CreateFromRes`, `CGWnd.GetDlgChild`, and `CGWnd:OnMsgDispatch(nInputID, pWnd, nMessage, wParam, lParam)` which the engine calls for every window message
(messages are the `WM_*`/`GM_WM_*` constants, e.g. GM_WM_MOUSECLICK, GM_WM_ACTION (button action), GM_WM_STATE_CHANGED; for mouse messages lParam = x | (y << 16) in window-local pixels).
