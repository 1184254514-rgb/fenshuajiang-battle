# Running the ORIGINAL 粉刷匠 Lua scripts in Godot — native layer contract

Goal: the 176 original Lua files (`res://lua/ShellClientLua`, `res://lua/ShellCommonLua`, UTF-8 now, Lua 5.4) run UNMODIFIED.
The original C++ engine registered ~139 classes, ~700 constants and ~25 functions into Lua; we re-implement exactly what the
scripts use ("natives"). Do NOT edit the original scripts; add natives only.

## Runtime
* Lua 5.4 via the lua-gdextension addon, one `LuaState` (see `scripts/lua_host.gd`). Lua stdlib is open (`string.pack/unpack`, `utf8`, `os`, `io`).
* `lua/prelude.lua` is loaded first: Lua 5.1 compat (`unpack`, `loadstring`, `table.getn`, `math.pow` ...), the engine object model
  `class(Base1, Base2)` / `ClassCast(cls, obj)` and `native_class(name, ...)`, plus the list of native class names (each already
  exists as an EMPTY native class; members you do not define are logged as `[MISSING NATIVE] Class.member` and return a no-op).
* `lua/natives_consts.lua`: generated constants (do not edit).
* Natives you write go in `lua/natives/<group>.lua`; `lua/natives.lua` requires them in a fixed order. A native class is extended like:
  ```lua
  function CTick:Ctor(szFunc, tblTarget) ... end        -- Ctor is called by Class:new(...)
  function CTick:Start(nInterval) ... end
  function CTick.Static() ... end                        -- statics are plain functions on the class table
  ```
  `Class:new(...)` creates `setmetatable({}, Class)` and calls `Class.Ctor(obj, ...)` (inherited). Subclasses written in the original Lua call
  `Base.Ctor(self, ...)` explicitly. `ClassCast(cls, obj)` = `setmetatable(obj, cls)`.
* Calling Godot from Lua: `Host` is a global GDScript object (`scripts/lua_host.gd` `LuaApi`), call with `:`.
  Godot Strings <-> Lua strings are UTF-8. `PackedByteArray` is a Lua userdata with 0-based indexing (`b[0]`), `#b` = size.
  Binary data inside Lua should be Lua strings (binary-safe), built with `string.pack`/`string.unpack` (little-endian `<`).
  Host API available now: `Host:read_text(path)` -> UTF-8 string (auto-detects UTF-16LE/BE BOM, UTF-8 BOM, falls back to GBK; `res://` or
  game-relative paths like "config/xxx.txt" resolve under `res://data/orig/`), `Host:read_bytes(path)` -> PackedByteArray,
  `Host:file_exists(path)`, `Host:time_ms()`, `Host:unix_ms()`, `Host:log(str)`.
* Original data files live in `res://data/orig/` (mirror of the original package: `config/`, `misc/`, `gui/`, ...). Config tables are tab-separated text,
  first row = column names.

## Rules
* Pure Lua unless a Godot facility is really needed. No third-party libraries.
* Match the original engine's behaviour as the Lua call sites expect it (read how the scripts call a method: argument order, return values,
  1-based vs 0-based indices, nil vs 0). When unsure, prefer what the call sites need over completeness.
* Keep each file self-contained; no global side effects except defining natives (and documented globals).
* Performance matters moderately (mobile target) but correctness first.
