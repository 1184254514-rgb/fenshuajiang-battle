-- Lua 5.4. CRhythmWnd from the engine disassembly (GPT gpt-6-astra); integrated by Claude.
-- Load after ctx_gui.lua and after ctx_clickdir.lua defines NativeTickUpdate.
--
-- This transcribes the supplied CRhythmWnd control flow. Exact engine parity
-- cannot be established from this dump: SMusicCon::GetRange,
-- SMusicCon::GetLeftInterval, SMusicCon::GetValuation, SMusicCon's parameters,
-- the jiezoutishiqi table, and the valuation effect-name table are absent.
-- Fallbacks for those omissions are explicitly marked below.
--
-- ClickRhythm is void in the supplied C++. This Lua adaptation returns:
--   grade, notified
-- grade is the raw computed valuation, normally 0..3; nil means no judgement.
-- notified reports whether CRhythmWnd::NotifyRhythm passed its gates.
-- Duplicate clicks still compute a grade and change the last-click timestamp.
--
-- Optional integration callbacks live in CRhythmWnd.Config:
--   player(mainWnd) -> current native player
--   notifyPlayer(player, grade) -> full CPlayerClient notification implementation
--   sceneBlocked(scene) -> whether the native scene's +0x500 gate is nonzero
--   roomType(scene, player) -> native room type
--   prizeRatio(combo) -> CPrizeConfig::GetRatioByCount
--   bonusBasisPoints(player) -> GetSimple32Property(0x15)
--   clientEvent(player, grade, zero) -> unidentified client virtual +0x74
--   sendRhythm(scene, player, packet) -> field connection's SendShellMsg
--   doubleGradeWhen(scene, player) -> scene[0x2c8] <= constant[0x110]
--   hint(mainWnd, one, show) and hintCount -> virtual +0x12c / constant[0xb4]
--   imageWriter(wnd, group, substate, texture, sourceRect, destinationRect)
--       -> true after replacing that entire image list
--   fontWriter(wnd, effectFile, text, color, milliseconds)
--   effectRateWriter(wnd, attachment, rate)
--
-- music overrides:
--   getRange(integerMs, beats) -> zeroBasedIndex, leftBeatMs, intervalMs
--   getLeftInterval(zeroBasedIndex, beats) -> preceding interval in ms
--   valuation(normalizedDistance) -> raw native grade
--   intervalsMs: optional 1-based Lua array containing the original second
--                column, converted from seconds to milliseconds.
--
-- No original ShellClientLua/ShellCommonLua files need modification.

assert(type(class) == "function", "rhythm_wnd requires the prelude class helper")
assert(type(CGWnd) == "table", "rhythm_wnd requires CGWnd")
assert(type(CGameMain) == "table", "rhythm_wnd requires CGameMain")

local pack_values, unpack_values = table.pack, table.unpack   -- the original Help.lua later replaces table.pack
local Base = CGWnd
local Rhythm = class(Base)
CRhythmWnd = Rhythm

local RESOURCE = "gui/cfg/fsj_jiezoutishi.gui"
local PERFECT, EXCELLENT, ORDINARY, FAULT = 0, 1, 2, 3
local HIT, MISS, NORMAL, NONE = 0, 1, 2, 3
local UINT32 = 4294967296
local FONT_COLOR = 0x00FEFBEA

Rhythm.PERFECT = PERFECT
Rhythm.EXCELLENT = EXCELLENT
Rhythm.ORDINARY = ORDINARY
Rhythm.FAULT = FAULT

Rhythm.Config = {
    -- ASSUMPTION: the table name maps to this resource path.
    noticeBarPath = "config/resource/jiezoutishiqi.txt",

    -- Optional numeric-ID -> original jiezoutishiqi row overrides.
    noticeBars = nil,

    -- ASSUMPTION: these missing SMusicCon parameters provide usable defaults.
    -- They are not recovered constants. Supply the original parameters and
    -- valuation function to reproduce the game's actual judgement boundaries.
    music = {
        nearPreviousRatio = 0.5, -- SMusicCon +0x68
        nearNextRatio = 0.5,     -- SMusicCon +0x6c
        pixelsPerSecond = 360,   -- SMusicCon +0x10
        singleBeatIntervalMs = 360,
        thresholds = { 0.20, 0.50, 1.00 },
    },

    -- ASSUMPTION: local room 0 when no room-type adapter is supplied.
    defaultRoomType = 0,

    -- The five-pointer table used by ShowValuationTips is absent.
    -- Set this to a table indexed by RAW grade when its names are available.
    -- Claude: the judgement words are the named effects inside fx/cfg/perfegt.eft
    valuationNames = { [0] = "fx/perfegt", [1] = "fx/great", [2] = "fx/good", [3] = "fx/miss" },

    -- ASSUMPTION: readable substitutes for missing effect-font rendering.
    valuationLabels = {
        [PERFECT] = "Perfect",
        [EXCELLENT] = "Excellent",
        [ORDINARY] = "Ordinary",
        [FAULT] = "Fault",
        [4] = "4",
    },
    valuationFallbackMs = 1000,
    pointsSuffix = "分",
    comboLabel = "COMBO",
    skillLabel = "技能加成",
    doubleLabel = "×3",
}

-- Claude: the local (director) player
Rhythm.Config.player = function() return g_App and g_App:GetDirector() end

local live = setmetatable({}, { __mode = "k" })
local warnings = {}
local noticeCache = {}
local hitSerial = 0

local function warn_once(key, message)
    if warnings[key] then return end
    warnings[key] = true
    Host:log("[CRhythmWnd] " .. message)
end

local function finite(n)
    return type(n) == "number"
        and n == n
        and n ~= math.huge
        and n ~= -math.huge
end

local function trunc(n)
    return n < 0 and math.ceil(n) or math.floor(n)
end

local function u32(n)
    return trunc(n) % UINT32
end

local function i32(n)
    n = u32(n)
    return n >= 2147483648 and n - UINT32 or n
end

local function f32(n)
    -- The native judge mixes float32 arithmetic with double clock values.
    return (string.unpack("<f", string.pack("<f", n)))
end

local function unsigned_product(a, b)
    -- Lua integers preserve the native 32-bit multiplication wrap here.
    local ia = assert(math.tointeger(u32(a)))
    local ib = assert(math.tointeger(u32(b)))
    return (ia * ib) & 0xffffffff
end

local function scene()
    return Host.scene_view
end

local function music_time()
    local s = scene()
    if s == nil then return nil end
    local n = tonumber(s:music_ms())
    if not finite(n) then return nil end
    -- ASSUMPTION: negative transport preroll corresponds to play time zero.
    return math.max(0, n)
end

local function wall_time()
    return assert(tonumber(Host:time_ms()), "Host:time_ms() must return milliseconds")
end

local function own_method(object, name, classNames)
    -- Avoid ordinary lookup on empty native class tables: it manufactures
    -- [MISSING NATIVE] no-op functions.
    if type(object) == "table" then
        local fn = rawget(object, name)
        if type(fn) == "function" then return fn end
        local mt = getmetatable(object)
        if type(mt) == "table" then
            fn = rawget(mt, name)
            if type(fn) == "function" then return fn end
        end
    elseif type(object) == "userdata" then
        local ok, fn = pcall(function() return object[name] end)
        if ok and type(fn) == "function" then return fn end
    end

    for _, className in ipairs(classNames or {}) do
        local cls = rawget(_G, className)
        local fn = type(cls) == "table" and rawget(cls, name) or nil
        if type(fn) == "function" then return fn end
    end
end

local function require_child(parent, name)
    return assert(parent:GetDlgChild(name), RESOURCE .. ": missing " .. name)
end

local function split_tabs(line)
    local fields = {}
    for field in (line .. "\t"):gmatch("(.-)\t") do
        if field:sub(1, 1) == '"' and field:sub(-1) == '"' then
            field = field:sub(2, -2):gsub('""', '"')
        end
        fields[#fields + 1] = field
    end
    return fields
end

local function read_notice_table(path)
    if noticeCache[path] ~= nil then return noticeCache[path] end

    local rows = {}
    noticeCache[path] = rows
    if not Host:file_exists(path) then
        warn_once("notice:" .. path,
            "Notice-bar table unavailable: " .. path ..
            "; retaining the GUI resource's authored note images.")
        return rows
    end

    local contents = Host:read_text(path)
    if type(contents) ~= "string" then return rows end
    contents = contents:gsub("^\239\187\191", "")

    local header, idColumn
    for line in contents:gmatch("[^\r\n]+") do
        if not line:match("^%s*$") and not line:match("^%s*#") then
            local fields = split_tabs(line)
            if not header then
                header = fields
                for i, name in ipairs(header) do
                    if name == "nID" or name == "ID" or name == "id"
                        or name == "nId" or name == "nNoticeBarID" then
                        idColumn = i
                        break
                    end
                end
                -- ASSUMPTION: unnamed ID conventions use the first column.
                idColumn = idColumn or 1
            else
                local id = tonumber(fields[idColumn])
                if id then
                    local row = {}
                    for i, name in ipairs(header) do
                        row[name] = fields[i] or ""
                    end
                    rows[trunc(id)] = row
                end
            end
        end
    end
    return rows
end

local function node_method(node, name)
    if node == nil then return nil end
    local ok, exists = pcall(function() return node:has_method(name) end)
    if not ok or not exists then return nil end
    return node[name]
end

local function replace_image_list(wnd, group, substate, texture, source, dest)
    local cfg = Rhythm.Config
    if cfg.imageWriter then
        return cfg.imageWriter(wnd, group, substate, texture, source, dest) == true
    end

    local getList = rawget(Base, "GetWndBkImage")
    local addImage = rawget(Base, "AddImage")
    if type(getList) == "function" and type(addImage) == "function" then
        local list = getList(wnd, group, substate)
        if list ~= nil then
            local clear = own_method(list, "ClearImage", { "CGImageList" })
            if not clear then return false end
            clear(list)
        end

        -- After ClearImage the insertion index is zero.
        -- ASSUMPTION: an independently implemented AddImage native accepts
        -- rectangles as Lua tables with left/top/right/bottom fields.
        addImage(wnd, group, substate, 0, texture, source, dest,
            0xffffffff, 15, 8, 0xffffffff, 0xffffffff, 0, 1.0, 0.0)
        return true
    end

    -- Implement the missing Lua-side image bridge if GuiWidgets already
    -- supplies corresponding primitives. Never call an unverified method.
    --
    -- ASSUMPTION: these optional Godot primitives use the argument convention
    -- below. They are not part of the supplied ctx_gui.lua contract.
    local node = rawget(wnd, "__node")
    local clear = node_method(node, "clear_images")
    local add = node_method(node, "add_image")
    if clear and add then
        clear(node, group, substate)
        add(node, group, substate, 0, texture, source, dest,
            0xffffffff, 15, 8, 0xffffffff, 0xffffffff, 0, 1.0, 0.0)
        return true
    end

    -- The supplied API cannot change a texture or source rectangle.
    -- Retaining the authored image is an explicit degraded mode, not a
    -- pretend implementation of image-list mutation.
    return false
end

function Rhythm:Ctor(resName, parentWnd, nLoadType)
    assert(parentWnd and parentWnd.__node,
        "CRhythmWnd requires a created parent window")

    self.__isNativeRhythmWnd = true
    self._main = parentWnd
    self._noticeID = 0
    self._lastTime = 0
    self._clicked = false       -- native +0x90
    self._enabled = false       -- native +0x91
    self._lastClick = 0         -- native +0x94
    self._combo = 0             -- native +0x98
    self._missRun = 0           -- native +0x9c
    self._stateMs = 0           -- native +0x38
    self._running = false
    self._textExpiry = {}
    self._created = false
    self._doubleDue = nil
    self._lastWall = nil

    assert(Base.CreateFromRes(self, resName or RESOURCE, parentWnd, nLoadType or 0),
        "Unable to create " .. tostring(resName or RESOURCE))
    live[self] = true
end

function Rhythm:OnCreated()
    if self._created then return end

    self._left = require_child(self, "W_tishitiaozuo")
    self._right = require_child(self, "W_tishitiaoyou")
    self._template = require_child(self, "W_jiepai")
    self._hit = require_child(self, "W_jiepaimingzhong")
    self._miss = require_child(self, "W_jiepaicuoguo")
    self._tips = require_child(self, "W_wenzitishi")
    self._time = require_child(self, "W_time")
    self._marker = require_child(self, "W_biaozhunpai")
    self._markerEffect = require_child(self, "W_biaozhunpaitexiao")
    self._hitEffect = require_child(self, "W_jiepaimingzhongtexiao")
    self._comboLabel = require_child(self, "W_combo")
    self._comboNumber = require_child(self, "W_font_effect")
    self._points = require_child(self, "W_jiafen")
    self._double = require_child(self, "W_fanbei")

    local skill = require_child(self, "jinengjiacheng")
    self._skillNumber = require_child(skill, "shuzifuhao")
    self._skillLabel = require_child(skill, "wenzi")

    self._slots = {}
    for i = 0, 2 do
        local name = "W_zuo" .. i
        self._slots[i + 1] = {
            left = require_child(self._left, name),
            right = require_child(self._right, name),
        }
    end

    -- Preserve resource geometry, including deliberately offscreen windows.
    -- The JSON's window_rect contains misinterpreted bits; its very large
    -- base_fields X values are not sufficient evidence to divide coordinates.
    self._marker:ShowWnd(false)
    -- effect-font windows: hide their solid placeholder rectangles (Claude)
    for _, w in ipairs({ self._comboNumber, self._points, self._double, self._skillNumber }) do
        local n = w and rawget(w, "__node")
        if n then pcall(function() n:clear_placeholder_images() end) end
    end
    self._created = true
end

function Rhythm:_ensureCreated()
    if not self._created then
        self.__lazyCreate = nil
        self:OnCreated()
    end
end

Rhythm.ShowWnd = Base.ShowWnd
Rhythm.IsShow = Base.IsShow

function Rhythm:GetClassName()
    return "CRhythmWnd"
end

function Rhythm:OnDestroy()
    live[self] = nil
    self._running = false
    self._doubleDue = nil
    self._textExpiry = {}
    if self._main and rawget(self._main, "__rhythmWnd") == self then
        self._main.__rhythmWnd = nil
    end
end

function Rhythm:SetMusicConfig(parameters)
    local merged = {}
    for k, v in pairs(Rhythm.Config.music) do merged[k] = v end
    for k, v in pairs(parameters) do merged[k] = v end
    self._musicConfig = merged
end

function Rhythm:_music()
    return self._musicConfig or Rhythm.Config.music
end

function Rhythm:_player()
    local provider = Rhythm.Config.player
    return provider and provider(self._main) or nil
end

local function chart_of(s)
    if s == nil then return nil end
    -- Claude: read the beat list through SceneView methods (a Godot PackedFloat64Array does not map to Lua #/indexing)
    local count = tonumber(s:beat_count()) or 0
    if count == 0 then return nil end
    local cache = rawget(Rhythm, "__chartCache")
    if not cache or cache.count ~= count or cache.first ~= s:beat_at(0) then
        local data = {}
        for i = 0, count - 1 do data[i] = s:beat_at(i) end
        cache = { data = data, count = count, base = 0, first = data[0] }
        Rhythm.__chartCache = cache
    end
    return cache
end

local function beat(chart, index)
    if index < 0 or index >= chart.count then return nil end
    local value = tonumber(chart.data[index + chart.base])
    if not finite(value) then return nil end
    return trunc(value)
end

function Rhythm:_intervalAfter(chart, index)
    local parameters = self:_music()
    local intervals = parameters.intervalsMs
    if intervals and intervals[index + 1] ~= nil then
        local value = tonumber(intervals[index + 1])
        if finite(value) and value > 0 then return trunc(value) end
        return nil
    end

    local a, b = beat(chart, index), beat(chart, index + 1)
    if a and b and b > a then return b - a end
    if index == chart.count - 1 and index > 0 then
        local previous = beat(chart, index - 1)
        if previous and a and a > previous then return a - previous end
    end

    if chart.count == 1 then
        return trunc(parameters.singleBeatIntervalMs)
    end
end

function Rhythm:_range(integerMs, chart)
    local parameters = self:_music()
    if parameters.getRange then
        local index, start, interval = parameters.getRange(integerMs, chart.data)
        assert(finite(index) and finite(start) and finite(interval) and interval > 0,
            "music.getRange must return index, startMs, positive intervalMs")
        return trunc(index), trunc(start), trunc(interval)
    end

    -- ASSUMPTION: absent GetRange, use consecutive chart entries, one virtual
    -- interval before the first beat, and one final interval after the last.
    -- The original's lead-in, tail and malformed-chart handling are unknown.
    local first = beat(chart, 0)
    local firstInterval = self:_intervalAfter(chart, 0)
    if not first or not firstInterval or firstInterval <= 0 then return nil end

    if integerMs < first then
        local start = first - firstInterval
        if integerMs < start then return nil end
        return -1, start, firstInterval
    end

    local low, high = 0, chart.count - 1
    while low < high do
        local mid = (low + high + 1) // 2
        local value = beat(chart, mid)
        if not value then return nil end
        if value <= integerMs then low = mid else high = mid - 1 end
    end

    local start = beat(chart, low)
    local interval = self:_intervalAfter(chart, low)
    if not interval or interval <= 0 then return nil end
    if low == chart.count - 1 and integerMs >= start + interval then return nil end
    return low, start, interval
end

function Rhythm:_leftInterval(chart, index)
    local parameters = self:_music()
    if parameters.getLeftInterval then
        return parameters.getLeftInterval(index, chart.data)
    end
    if parameters.intervalsMs and parameters.intervalsMs[index] ~= nil then
        return parameters.intervalsMs[index]
    end
    local previous, current = beat(chart, index - 1), beat(chart, index)
    return previous and current and current - previous or nil
end

function Rhythm:GetValuation(normalized)
    local parameters = self:_music()
    if parameters.valuation then
        local value = parameters.valuation(normalized)
        assert(math.tointeger(value) and value >= 0 and value <= 4,
            "music.valuation must return a raw grade in 0..4")
        return value
    end

    -- ASSUMPTION: inclusive, ascending thresholds. Neither the actual
    -- thresholds nor GetValuation's comparison operators were supplied.
    if not finite(normalized) or normalized < 0 then return FAULT end
    for grade = PERFECT, ORDINARY do
        if normalized <= f32(parameters.thresholds[grade + 1]) then
            return grade
        end
    end
    return FAULT
end

function Rhythm:_phase(integerMs, start, interval)
    local parameters = self:_music()
    local length = f32(interval)
    local elapsed = f32(u32(integerMs - start))
    local remaining = f32(length - elapsed)
    local distance, ratio

    -- Native ties select the next-beat side, using +0x6c.
    if elapsed < remaining then
        distance = elapsed
        ratio = f32(parameters.nearPreviousRatio)
    else
        distance = remaining
        ratio = f32(parameters.nearNextRatio)
    end

    local window = f32(length * ratio)
    assert(window > 0, "Rhythm timing ratios must be positive")
    return distance, ratio, window
end

function Rhythm:RhythmStat(state)
    self:_ensureCreated()
    if state == nil then
        if self._template:IsShow() then return NORMAL end
        if self._hit:IsShow() then return HIT end
        if self._miss:IsShow() then return MISS end
        return NONE
    end

    self._template:ShowWnd(state == NORMAL)
    self._hit:ShowWnd(state == HIT)
    self._miss:ShowWnd(state == MISS)
    self._stateMs = 0
end

function Rhythm:UpdateItemPos(leftItem, x)
    leftItem:SetLocalX(x)
    local rightItem = require_child(self._right, leftItem:GetWndName())
    rightItem:SetLocalX(f32(f32(self._right:GetWndWidth() - x)
        - rightItem:GetWndWidth()))
end

function Rhythm:_hideNotes()
    for _, pair in ipairs(self._slots) do
        pair.left:ShowWnd(false)
        pair.right:ShowWnd(false)
    end
end

function Rhythm:UpdateNoticeBar(_ignoredArgument)
    self:_ensureCreated()

    -- The native reads its stored +0x80 ID; the incoming argument is unused.
    local cfg = Rhythm.Config
    local rows = cfg.noticeBars or read_notice_table(cfg.noticeBarPath)
    local row = rows[self._noticeID] or rows[tostring(self._noticeID)]
    self._noticeRow = row
    self._skinApplied = false
    if not row then return false end

    local texture = row.sTextureFileName
    local source = {
        left = tonumber(row.nLeft),
        top = tonumber(row.nTop),
        right = tonumber(row.nRight),
        bottom = tonumber(row.nBottom),
    }
    if type(texture) ~= "string" or texture == ""
        or not finite(source.left) or not finite(source.top)
        or not finite(source.right) or not finite(source.bottom) then
        warn_once("bad-notice:" .. self._noticeID,
            "Incomplete jiezoutishiqi row for ID " .. self._noticeID)
        return false
    end

    for _, pair in ipairs(self._slots) do
        for _, wnd in ipairs({ pair.left, pair.right }) do
            local dest = {
                left = 0, top = 0,
                right = wnd:GetWndWidth(), bottom = wnd:GetWndHeight(),
            }
            -- Native replaces group 1, substates 2 through 9, on all six notes.
            -- Every ID selects its own table texture and source rectangle.
            for substate = 2, 9 do
                local ok, applied = pcall(replace_image_list,
                    wnd, 1, substate, texture, source, dest)
                if not ok or not applied then
                    warn_once("image-writer",
                        "Notice-bar skin replacement requires image-list " ..
                        "mutation unavailable in the supplied GUI API. " ..
                        "Provide Config.imageWriter or the native image methods." ..
                        (not ok and (" " .. tostring(applied)) or ""))
                    return false
                end
            end
        end
    end
    self._skinApplied = true
    return true
end

-- Claude: SMusicCon comes from the song's config/music.txt row: LeftRadius/RightRadius (basis points of the beat
-- interval on each side), RhythmSpeed (note speed, UI px/s), RangeMax1..4 (basis points of that window) -> grades.
function Rhythm:_loadMusicConfig()
    local s = scene()
    if not s then return end
    local function p(name) return tonumber(s:music_param(name)) end
    local left, right, speed = p("LeftRadius"), p("RightRadius"), p("RhythmSpeed")
    if not (left and right and speed) then return end
    self._musicConfig = {
        nearPreviousRatio = left / 10000,
        nearNextRatio = right / 10000,
        pixelsPerSecond = speed,
        thresholds = { (p("RangeMax1") or 4000) / 10000, (p("RangeMax2") or 7000) / 10000, (p("RangeMax3") or 10000) / 10000 },
        valuation = function(n)
            if not finite(n) or n < 0 then return FAULT end
            if n <= (p("RangeMax1") or 4000) / 10000 then return PERFECT end
            if n <= (p("RangeMax2") or 7000) / 10000 then return EXCELLENT end
            if n <= (p("RangeMax3") or 10000) / 10000 then return ORDINARY end
            return FAULT
        end,
    }
end

function Rhythm:Start(noticeBarID)
    self:_ensureCreated()
    self._noticeID = trunc(tonumber(noticeBarID) or 0) % 256
    self._lastTime = 0
    self._clicked = false
    self._enabled = false

    -- Start does NOT reset +0x94, +0x98 or +0x9c.
    self:_loadMusicConfig()
    self:UpdateNoticeBar(self._noticeID)
    self:ShowWnd(true)
    self:RhythmStat(NORMAL)
    Base.EnablePreRender(self, true)
    self._running = true
    self._lastWall = wall_time()

    if not self:_music().valuation then
        warn_once("valuation-defaults",
            "SMusicCon judgement data was not supplied; using the explicitly " ..
            "assumed ratios and valuation thresholds in CRhythmWnd.Config.music.")
    end
end

function Rhythm:Stop()
    self:ShowWnd(false)
    Base.EnablePreRender(self, false)
    self._running = false
    -- Stop does not reset rhythm state or cancel DoubleGrade's separate tick.
end

function Rhythm:EnableRhythm(enabled)
    self._enabled = not not enabled
end

function Rhythm:ResetRhythm()
    self._enabled = false
    self._lastClick = 0
end

function Rhythm:_temporaryText(wnd, text, milliseconds)
    wnd:SetWndText(text)
    wnd:ShowWnd(true)
    self._textExpiry[wnd] = wall_time() + milliseconds
end

function Rhythm:_effectText(wnd, file, text, milliseconds)
    local writer = Rhythm.Config.fontWriter
    if writer then
        writer(wnd, file, text, FONT_COLOR, milliseconds)
        return
    end

    -- ASSUMPTION: ordinary text substitutes for CFontEffectWnd's unavailable
    -- per-glyph effect renderer. This uses only supplied CGWnd operations.
    self:_temporaryText(wnd, text, milliseconds)
end

function Rhythm:ShowValuationTips(grade)
    self:_ensureCreated()
    local cfg = Rhythm.Config
    self._tips:RemoveAllEffects()
    self._tips:SetWndText("")
    self._textExpiry[self._tips] = nil
    self._tips:ShowWnd(true)

    local name = cfg.valuationNames and cfg.valuationNames[grade]
    if name then
        self._tips:AddEffect("fx/cfg/perfegt.eft", name, "valuation", 0)
    else
        self:_temporaryText(self._tips,
            cfg.valuationLabels[grade] or tostring(grade),
            cfg.valuationFallbackMs)
    end
end

function Rhythm:DoubleGrade()
    self:_ensureCreated()
    self._double:ShowWnd(true)
    self._double:AddEffect("fx/cfg/combox3.eft", "fx/loop", "", 0)
    self._doubleDue = wall_time() + 850

    -- ASSUMPTION: readable fallback for an unavailable .eft renderer.
    if not Rhythm.Config.fontWriter then
        self._double:SetWndText(Rhythm.Config.doubleLabel)
        self._doubleHasFallbackText = true
    end
    -- The native function adds an effect; it does not multiply grades/scores.
end

function Rhythm:OnTick()
    -- This is the COMPLETE native OnTick, apart from clearing fallback text.
    -- It is the one-shot DoubleGrade cleanup, not the music update loop.
    if self._created then
        self._double:RemoveAllEffects()
        if self._doubleHasFallbackText then
            self._double:SetWndText("")
            self._doubleHasFallbackText = nil
        end
    end
    self._doubleDue = nil
    -- Keep W_fanbei shown: the C++ does not call ShowWnd(false).
end

local function room_type(s, player)
    local cfg = Rhythm.Config
    return cfg.roomType and cfg.roomType(s, player) or cfg.defaultRoomType
end

local function prize_ratio(count)
    local cfg = Rhythm.Config
    if cfg.prizeRatio then return u32(cfg.prizeRatio(count)) end

    local cls = rawget(_G, "CPrizeConfig")
    local inst = type(cls) == "table" and rawget(cls, "Inst")
    local get = type(cls) == "table" and rawget(cls, "GetRatioByCount")
    if type(inst) == "function" and type(get) == "function" then
        local object = inst()
        if object then return u32(get(object, count)) end
    end

    -- ASSUMPTION: no prize when its configuration is unavailable.
    -- In particular, do not retain ClickDir's fabricated grade-based score.
    warn_once("prizes",
        "Prize configuration unavailable; fallback player accounting records " ..
        "grades and combos, but awards no invented combo points.")
    return 0
end

local function bonus_basis_points(player)
    local cfg = Rhythm.Config
    if cfg.bonusBasisPoints then return u32(cfg.bonusBasisPoints(player)) end
    local get = own_method(player, "GetSimple32Property",
        { "CPlayerClient", "CPlayer" })
    if get then return u32(get(player, 0x15)) end
    -- ASSUMPTION: no skill bonus when the property native is unavailable.
    return 0
end

local function prize_points(ratio, bonus)
    -- Native magic multiplication implements unsigned division by 10000.
    return u32(ratio + (unsigned_product(ratio, bonus) // 10000))
end

function Rhythm:ShowConBeat(count, _grade)
    self:_ensureCreated()
    if count <= 4 then return end

    -- NotifyRhythm calls this BEFORE incrementing/resetting the window streak.
    -- The incoming grade is unused in the supplied ShowConBeat.
    self:_effectText(self._comboNumber, "fx/cfg/combo.eft", tostring(count), 1000)
    self._comboLabel:RemoveAllEffects()
    self._comboLabel:AddEffect("fx/cfg/perfegt.eft", "fx/combo", "", 1000)
    if not Rhythm.Config.fontWriter then
        self:_temporaryText(self._comboLabel, Rhythm.Config.comboLabel, 1000)
    end

    local player = self:_player()
    if not player then return end
    local ratio = prize_ratio(count)
    local bonus = bonus_basis_points(player)
    local points = prize_points(ratio, bonus)
    if points == 0 then return end

    local s = scene()
    if not s or room_type(s, player) == 0 then return end

    local condition = Rhythm.Config.doubleGradeWhen
    -- No guessed threshold substitutes for the missing scene/constant fields.
    if condition and condition(s, player) then self:DoubleGrade() end

    self:_effectText(self._points, "fx/cfg/combo.eft",
        "+" .. points .. Rhythm.Config.pointsSuffix, 1000)

    local percentage = bonus // 100
    if percentage ~= 0 then
        self._skillLabel:RemoveAllEffects()
        self._skillLabel:AddEffect(
            "fx/cfg/jineng_jiacheng_zi.eft", "fx/zi_xiao", "", 1000)
        if not Rhythm.Config.fontWriter then
            self:_temporaryText(self._skillLabel, Rhythm.Config.skillLabel, 1000)
        end
        self:_effectText(self._skillNumber, "fx/cfg/jineng_jiacheng_xiao.eft",
            "+" .. percentage .. "%", 1000)
    end
end

local function record_local_player(player, grade)
    if grade > FAULT then return end

    local rhythm = rawget(player, "__rhythm")
    if not rhythm then
        rhythm = {}
        player.__rhythm = rhythm
    end
    local stats = rawget(player, "__stats")
    if not stats then
        stats = {}
        player.__stats = stats
    end

    rhythm.count = rhythm.count or {}
    rhythm.nativeGrades = rhythm.nativeGrades or {}
    rhythm.total = (rhythm.total or 0) + 1
    rhythm.nativeGrades[#rhythm.nativeGrades + 1] = grade

    -- Compatibility boundary: existing ctx_clickdir HUD/stat tables use 1..4.
    local displayGrade = grade + 1
    rhythm.count[displayGrade] = (rhythm.count[displayGrade] or 0) + 1

    if grade == FAULT then
        rhythm.combo = 0
    else
        rhythm.combo = (rhythm.combo or 0) + 1
    end
    rhythm.maxCombo = math.max(rhythm.maxCombo or 0, rhythm.combo)

    -- Keep the supplied HUD's auxiliary table coherent.
    stats.maxGrade = stats.maxGrade or {}
    stats.maxGrade[displayGrade] =
        math.max(stats.maxGrade[displayGrade] or 0, rhythm.combo)

    local ratio = prize_ratio(rhythm.combo)
    if ratio ~= 0 then
        stats.comboScore = (stats.comboScore or 0)
            + prize_points(ratio, bonus_basis_points(player))
    else
        stats.comboScore = stats.comboScore or 0
    end
end

function Rhythm:_notifyPlayer(player, grade)
    local cfg = Rhythm.Config
    if cfg.notifyPlayer then
        cfg.notifyPlayer(player, grade)
        return
    end

    -- Use an explicitly implemented client native when present.
    local client = own_method(player, "NotifyRhythm", { "CPlayerClient" })
    if client then
        client(player, grade)
        return
    end

    local s = scene()
    local room = room_type(s, player)
    if room == 4 or room == 5 then return end

    local speed = own_method(player, "RhythmSpeed", { "CPlayerClient" })
    if speed then speed(player, grade) end
    if cfg.clientEvent then cfg.clientEvent(player, grade, 0) end

    if room == 0 or room == 3 or room == 6 then
        local playerClass = rawget(_G, "CPlayer")
        local baseNotify = type(playerClass) == "table"
            and rawget(playerClass, "NotifyRhythm")
        if type(baseNotify) == "function" then
            baseNotify(player, grade)
        else
            record_local_player(player, grade)
        end
    elseif cfg.sendRhythm then
        cfg.sendRhythm(s, player, string.pack("BB", 8, grade))
    else
        warn_once("field-connection",
            "This room routes rhythm to the field connection; supply " ..
            "Config.notifyPlayer or Config.sendRhythm.")
    end
end

function Rhythm:NotifyRhythm(grade, onlyIfNotClicked)
    local s = scene()
    if not s then return false end

    -- ASSUMPTION: the unidentified scene +0x500 gate is clear unless provided.
    local blocked = Rhythm.Config.sceneBlocked
    if blocked and blocked(s) then return false end
    if not self._enabled then return false end
    if onlyIfNotClicked and self._clicked then return false end

    local player = self:_player()
    if not player then return false end

    self:ShowConBeat(self._combo, grade)
    self:ShowValuationTips(grade)
    self:_notifyPlayer(player, grade)

    if grade == FAULT then
        self._missRun = u32(self._missRun + 1)
        self._combo = 0
    else
        self._missRun = 0
        self._combo = u32(self._combo + 1)
    end

    local cfg = Rhythm.Config
    if self._main and cfg.hintCount and cfg.hint then
        if self._missRun >= cfg.hintCount then cfg.hint(self._main, 1, true) end
        if self._combo >= cfg.hintCount then cfg.hint(self._main, 1, false) end
    end
    return true
end

function Rhythm:_beatPulse(interval)
    local file = self._noticeRow and self._noticeRow.sEffectFileName
    if file == nil then
        -- ASSUMPTION: use the effect present in the supplied GUI when the
        -- notice-bar table's sEffectFileName is unavailable.
        file = "fx/cfg/jiezoupengzhuang.eft"
    end
    if file == "" then return end

    self._markerEffect:AddEffect(file, "fx/loop", "jiezoupengzhuang", -1)
    local rateWriter = Rhythm.Config.effectRateWriter
    if rateWriter then
        rateWriter(self._markerEffect, "jiezoupengzhuang", f32(500 / interval))
    else
        -- AddEffect's supplied four-argument API cannot set playback speed.
        warn_once("effect-rate",
            "Beat effects use their authored playback speed until " ..
            "Config.effectRateWriter is supplied; note positions use music time.")
    end
end

function Rhythm:UpdateTime(now)
    self:_ensureCreated()
    local s = scene()
    if not s then return end
    if not finite(now) then now = music_time() end
    if now == nil then return end

    local previous = self._lastTime
    self._lastTime = now

    local chart = chart_of(s)
    if not chart then
        self:_hideNotes()
        self._marker:ShowWnd(false)
        return
    end
    local index, start, interval = self:_range(trunc(now), chart)
    if index == nil then
        self:_hideNotes()
        self._marker:ShowWnd(false)
        return
    end

    local parameters = self:_music()
    local speed = u32(parameters.pixelsPerSecond)
    local accumulated = f32(0)
    local unavailable = false

    for slot = 0, 2 do
        local pair = self._slots[slot + 1]
        local intervalPart
        if slot == 0 then
            intervalPart = interval - (now - start)
        else
            intervalPart = self:_leftInterval(chart, index + 1 + slot)
        end

        -- ASSUMPTION: absent end-of-chart GetLeftInterval behavior, hide slots
        -- beyond the supplied chart instead of inventing additional notes.
        if unavailable or beat(chart, index + 1 + slot) == nil
            or not finite(intervalPart) then
            unavailable = true
            pair.left:ShowWnd(false)
            pair.right:ShowWnd(false)
        else
            accumulated = f32(accumulated + f32(speed * (intervalPart / 1000)))
            self:UpdateItemPos(pair.left,
                f32(self._left:GetWndWidth() - accumulated))
            pair.left:ShowWnd(true)
            pair.right:ShowWnd(true)
        end
    end

    local length = f32(interval)
    local nextRatio = f32(parameters.nearNextRatio)
    local previousRatio = f32(parameters.nearPreviousRatio)
    local resetBoundary = f32(f32(start) + f32(length * nextRatio))

    if previous < resetBoundary and now >= resetBoundary then
        if not self._clicked then
            local sum = f32(nextRatio + previousRatio)
            local silenceLimit = f32(length + f32(length * sum))
            if now - u32(self._lastClick) > silenceLimit then
                self:RhythmStat(MISS)
                self:NotifyRhythm(FAULT, false)
            end
        end
        self._clicked = false
    end

    -- Native examines the current range only; it does not replay every
    -- intervening miss or beat effect after a stalled frame.
    if previous < start and now >= start then
        self:_beatPulse(interval)
    end

    local currentPlayTime = u32(trunc(music_time() or now))
    local distance, _, window = self:_phase(currentPlayTime, start, interval)
    self._marker:ShowWnd(self:GetValuation(f32(distance / window)) == PERFECT)
end

function Rhythm:ClickRhythm()
    local s = scene()
    if not s or not self:_player() then return nil, false end
    local now = music_time()
    local chart = chart_of(s)
    if now == nil or not chart then return nil, false end

    local integerMs = u32(trunc(now))
    local index, start, interval = self:_range(i32(integerMs), chart)
    if index == nil then return nil, false end
    self:_ensureCreated()

    -- These native gates do NOT include IsShow, _running, or _enabled.
    -- _enabled is checked later by NotifyRhythm.
    local _, _, window = self:_phase(integerMs, start, interval)

    if self._lastClick == 0 then
        self._lastClick = u32(assert(beat(chart, 0)))
    end

    local elapsedSinceClick = i32(integerMs - self._lastClick)

    -- ASSUMPTION: the unlabeled helper at 0x45fae0 is signed divmod.
    -- The surrounding half-interval comparison is signed. For nonnegative
    -- click deltas this also equals unsigned divmod.
    -- Lua's % differs from C remainder for negative operands.
    local remainder = elapsedSinceClick
        - trunc(elapsedSinceClick / interval) * interval

    if elapsedSinceClick > trunc(interval / 2) then
        local opposite = u32(interval - remainder)
        remainder = u32(remainder)
        if remainder >= opposite then remainder = opposite end
    end

    local distance = f32(u32(remainder))
    self._lastClick = integerMs

    self:RhythmStat(distance > window and MISS or HIT)
    local grade = self:GetValuation(f32(distance / window))
    local notified = self:NotifyRhythm(grade, true)

    if not self._clicked then
        self._clicked = true
        if grade ~= FAULT then
            hitSerial = hitSerial + 1
            self._hitEffect:AddEffect(
                "fx/cfg/jiezoupengzhuang1.eft",
                "fx/loop",
                "jiezoupengzhuang1_" .. hitSerial,
                0)
        end
    end

    return grade, notified
end

function Rhythm:PreRender(_absoluteMs, elapsedMs)
    if not scene() then return end
    self:_ensureCreated()

    local now = music_time()
    if now == nil then return end

    -- The supplied native writes the integer play time, not a mm:ss string.
    self._time:SetWndText(tostring(u32(trunc(now))))
    self._stateMs = u32(self._stateMs + math.max(0, trunc(elapsedMs or 0)))

    -- Strictly greater than 90 ms.
    if self._stateMs > 90 and self:RhythmStat() ~= NORMAL then
        self:RhythmStat(NORMAL)
    end
end

function Rhythm:_frame(now)
    if not self.__node then
        live[self] = nil
        return
    end

    local elapsed = self._lastWall and math.max(0, now - self._lastWall) or 0
    self._lastWall = now

    if self._doubleDue and now >= self._doubleDue then self:OnTick() end

    for wnd, deadline in pairs(self._textExpiry) do
        if now >= deadline then
            if wnd.__node then wnd:SetWndText("") end
            self._textExpiry[wnd] = nil
        end
    end

    if self._running then
        local playTime = music_time()
        if playTime ~= nil then self:UpdateTime(playTime) end
        if self:IsShow() then self:PreRender(now, elapsed) end
    end
end

-- before the HUD window itself exists (CGameMain construction), hand out a stub that remembers Start()
local Pending = {}
Pending.__index = Pending
function Pending:Start(id) self.startID = id end
function Pending:Stop() self.startID = nil end
function Pending:ShowWnd(b) self.shown = b end
function Pending:IsShow() return self.shown == true end
function Pending:_sync() end
function Pending:ClickRhythm() return nil, false end
function Pending:EnableRhythm() end
Rhythm._sync = function() end   -- called by natives/gamemain.lua's HUD visibility hook

function CGameMain:GetRhythmWnd()
    if not rawget(self, "__node") then
        local stub = rawget(self, "__rhythmPending")
        if not stub then stub = setmetatable({}, Pending); self.__rhythmPending = stub end
        return stub
    end
    local existing = rawget(self, "__rhythmWnd")
    if type(existing) == "table"
        and rawget(existing, "__isNativeRhythmWnd")
        and rawget(existing, "__node") then
        return existing
    end

    local wnd = Rhythm:new(RESOURCE, self, 1)
    self.__rhythmWnd = wnd
    local stub = rawget(self, "__rhythmPending")
    if stub then
        self.__rhythmPending = nil
        if stub.startID ~= nil then wnd:Start(stub.startID) end
        if stub.shown ~= nil then wnd:ShowWnd(stub.shown) end
    end
    return wnd
end

-- Documented global native integration: preserve the existing simulation
-- driver and its return values, then advance the registered rhythm windows.
--
-- ASSUMPTION: NativeTickUpdate is the once-per-frame host entry point and
-- remains the installed driver after this module is loaded. The supplied
-- fragment identifies it but does not show the rest of its implementation.
--
-- ShowWnd(false) changes visibility only. This adapter continues UpdateTime
-- until Stop, while suppressing hidden PreRender calls. Hidden-window update
-- scheduling was not included in the disassembly.
local previousTick = assert(rawget(_G, "NativeTickUpdate"),
    "Load natives.rhythm_wnd after ctx_clickdir defines NativeTickUpdate")
assert(type(previousTick) == "function", "NativeTickUpdate must be a function")

function NativeTickUpdate(...)
    local result = pack_values(previousTick(...))
    local now = wall_time()
    for wnd in pairs(live) do wnd:_frame(now) end
    return unpack_values(result, 1, result.n)
end

return Rhythm
