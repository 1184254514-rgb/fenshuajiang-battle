-- Prelude for running the ORIGINAL 粉刷匠 Lua scripts inside Godot (Lua 5.4). Claude.
-- Provides: Lua 5.1 compat, the engine's class()/ClassCast() object model, and a logger for native (C++) APIs
-- that the original scripts call but we have not implemented yet (see MISSING_NATIVE).

-- ---------- Lua 5.1 compat ----------
unpack = unpack or table.unpack
loadstring = loadstring or load
table.getn = table.getn or function(t) return #t end
table.maxn = table.maxn or function(t) local n = 0 for k in pairs(t) do if type(k) == "number" and k > n then n = k end end return n end
math.pow = math.pow or function(a, b) return a ^ b end
math.mod = math.mod or math.fmod
string.gfind = string.gfind or string.gmatch
math.ldexp = math.ldexp or function(m, e) return m * 2.0 ^ e end

-- Lua 5.1 string.format accepted non-integral numbers for %d/%i/%x/%X/%o/%c/%u (C cast = truncation); 5.4 errors.
do
	local orig_format = string.format
	local pack, unpack_ = table.pack, table.unpack   -- captured: the original Help.lua later redefines table.pack
	local function fix(fmt, ...)
		local args = pack(...)
		local i = 0
		for spec in fmt:gmatch("%%[-+ #0]*%d*%.?%d*([%a%%])") do
			if spec ~= "%" then
				i = i + 1
				local v = args[i]
				if (spec == "d" or spec == "i" or spec == "x" or spec == "X" or spec == "o" or spec == "c" or spec == "u")
						and type(v) == "number" and math.type(v) == "float" then
					if v ~= v or v == math.huge or v == -math.huge then v = 0 end
					args[i] = v >= 0 and math.floor(v) or math.ceil(v)
				end
			end
		end
		fmt = fmt:gsub("%%u", "%%d")
		return orig_format(fmt, unpack_(args, 1, args.n))
	end
	string.format = fix
end

-- ---------- missing-native logger ----------
MISSING_NATIVE = {}
local function note_missing(owner, key)
	local k = owner .. "." .. tostring(key)
	if not MISSING_NATIVE[k] then
		MISSING_NATIVE[k] = 0
		print("[MISSING NATIVE] " .. k)
	end
	MISSING_NATIVE[k] = MISSING_NATIVE[k] + 1
end
local function stub() return nil end

-- ---------- object model ----------
-- class(Base1, Base2, ...) -> class table. Instances are tables whose metatable is the class table.
-- Lookup order for members: own, then each base in order. `new` calls Ctor (inherited) with the arguments.
local ObjectBase = {}
ObjectBase.__index = ObjectBase
-- Native (C++) base classes may define `__native_construct(self, ...)`: it runs (base classes first) before the Lua Ctor,
-- standing in for the C++ constructor (e.g. creating the window resource).
local function run_native_construct(cls, o, ...)
	local bases = rawget(cls, "__bases")
	if bases then
		for i = 1, #bases do run_native_construct(bases[i], o, ...) end
	end
	local f = rawget(cls, "__native_construct")
	if f then f(o, ...) end
end
function ObjectBase.new(cls, ...)
	local o = setmetatable({}, cls)
	run_native_construct(cls, o, ...)
	local ctor = cls.Ctor
	if ctor then ctor(o, ...) end
	return o
end

function class(...)
	local bases = { ... }
	if #bases == 0 then bases[1] = ObjectBase end
	local cls = { __bases = bases }
	cls.__index = cls
	setmetatable(cls, { __index = function(t, k)
		for i = 1, #bases do
			local v = bases[i][k]
			if v ~= nil then return v end
		end
		return nil
	end })
	return cls
end

function ClassCast(cls, obj, ...)
	if obj == nil then return nil end
	if type(obj) == "table" then return setmetatable(obj, cls) end
	return obj
end

-- A native (C++) class implemented on the Godot side: members that are not implemented are logged and stubbed.
function native_class(name, ...)
	local c = class(...)
	c.__native_name = name
	local mt = getmetatable(c)
	local inherit = mt.__index
	mt.__index = function(t, k)
		local v = inherit(t, k)
		if v ~= nil then return v end
		if type(k) == "string" and k:find("^[A-Z]") then
			note_missing(name, k)
			return stub
		end
		return nil
	end
	_G[name] = c
	return c
end

-- ---------- native class declarations ----------
-- The C++ engine registers these classes into Lua (CScript::RegistClass). Each starts as an empty logged native class;
-- real implementations live in lua/natives/*.lua and fill in members. Names come from the original binary.
NATIVE_CLASS_NAMES = {
	"CBufferStream", "CInventoryConfig", "CHeroRichName", "CRichFrameFactory", "CLoadingImgTipsMgr", "CPictureLoadToWnd", "CMatchPosHandle", "CFieldInfo",
	"CSyncDataDest",
	"IGUIMgr",
	"CGWnd",
	"CGButton",
	"CGCheckButton",
	"CGProgress",
	"CGScrollBar",
	"CGScrollPane",
	"CGEdit",
	"CGComboBox",
	"CGListCtrl",
	"CGRichWnd",
	"CGTreeCtrl",
	"STreeNode",
	"ITableItemCreateHandler",
	"CWindow3DContainer",
	"CViewportRenderer",
	"CWindow3D",
	"CWindow3DUnit",
	"CImageDecoder",
	"CJpgDecoder",
	"CDir",
	"CVector2f",
	"CVector3f",
	"CVector4f",
	"CPos16",
	"CMatrix",
	"CIRect",
	"CFRect",
	"RECT",
	"STime",
	"CVersion",
	"CGammaObject",
	"CTick",
	"CJson",
	"CIniFile",
	"CTabFile",
	"CPathMgr",
	"CGammaRand",
	"CDictionary",
	"IGammaUnknown",
	"IGammaFileMgr",
	"IGammaResListener",
	"CGammaResFile",
	"IResListener",
	"CCommonFileHead",
	"CDependentRes",
	"CAddress",
	"CDynamicObject",
	"ITexture",
	"CResourceManager",
	"CRenderer",
	"CImageGroup",
	"CSmthFont",
	"CEffectGroup",
	"CAxisAlignBoudingBox",
	"CAlphaControler",
	"SFramePair",
	"CCameraLens",
	"SCameraInfo",
	"SSceneEnvData",
	"CObject3D",
	"CEntity",
	"CLinkbleEntity",
	"CEffect",
	"CMesh",
	"CCamera",
	"CAniControler",
	"IEffectListener",
	"IEffectHandler",
	"IEffectUnitListener",
	"IEffectUnitHandler",
	"CScene",
	"CMapFileScene",
	"CTextureFile",
	"IAnimation",
	"CAniGroup",
	"IAnimationListener",
	"IAniControlerListener",
	"CEffectUnit",
	"IAudio",
	"IMusic",
	"ISound",
	"IMusicListener",
	"IGraphic",
	"CBaseApp",
	"CBaseAppEx",
	"CBaseConn",
	"CBaseTCP",
	"CBaseUDP",
	"CSyncDataDef",
	"CGameAppClient",
	"CGameConnToWorld",
	"CGameConnToField",
	"CGameStart",
	"CGameMain",
	"IVideoListener",
	"CVideoWnd",
	"CPlayerClient",
	"CGameSceneClient",
	"CStringConfig",
	"CKickMsgConfig",
	"CRenamePrizeConfig",
	"CStarLevelConfig",
	"CRewardConfig",
	"CGameTipConfig",
	"CSignInPrizeConfig",
	"CRollActivityConfig",
	"CRhythmWnd",
	"CMusicConfig",
	"CRectConfig",
	"CFontConfig",
	"CAIEquipConfig",
	"CFontEffectWnd",
	"CGameRenderObject",
	"CGuideMgr",
	"CRhythmGuide",
	"CPicture",
	"CGameApp",
	"CCharacter",
	"CPlayer",
	"CGameScene",
	"CManorNode",
	"CItem",
	"CManor",
	"CUSFilter",
	"CSnakeConstant",
	"CPlayerLevelConfig",
	"CDailyTaskConfig",
	"CRankPrizeConfig",
	"CMapInfo",
	"CSceneList",
	"SPlayerContex",
	"CSkillConf",
	"CTreasureBoxOpenConsume",
	"CTableConfigMgr",
	"CEvaluateConfig",
	"SRhythmData",
	"StruScore"
}
-- widget hierarchy (all window classes derive from CGWnd in the C++ engine)
native_class("CGWnd")
native_class("CGButton", CGWnd)
native_class("CGCheckButton", CGButton)
for _, n in ipairs({ "CGProgress", "CGScrollBar", "CGScrollPane", "CGEdit", "CGComboBox", "CGListCtrl", "CGRichWnd", "CGTreeCtrl",
		"CWindow3DContainer", "CWindow3D", "CPicture", "CVideoWnd", "CFontEffectWnd" }) do
	native_class(n, CGWnd)
end
-- app-level classes created by C++ and subclassed in Lua
native_class("CGameStart", CGWnd)
native_class("CGameMain", CGWnd)
-- game-world classes: client versions derive from the shared (server/client) C++ classes
native_class("CGameApp")
native_class("CGameAppClient", CGameApp)
native_class("CCharacter")
native_class("CPlayer", CCharacter)
native_class("CPlayerClient", CPlayer)
native_class("CGameScene")
native_class("CGameSceneClient", CGameScene)
native_class("CManor")
native_class("CManorNode")
for _, n in ipairs(NATIVE_CLASS_NAMES) do
	if rawget(_G, n) == nil then native_class(n) end
end

-- Engine free functions (CScript::RegistFunction) not implemented yet are logged stubs.
NATIVE_FUNCTION_NAMES = { "AsyncRequire", "BitAnd", "BitNot", "BitOr", "Cut2DLine", "DumpMemoryInfo", "Format2LocalTime",
	"Format2NatureTime", "GammaHash", "GetDateTime", "GetFormatTimeSTMFromMillisecond", "GetGammaFileMgr", "GetGammaTime",
	"GetLocalTime", "GetNatureTime", "HandleOutPutText", "IsWifiConnect", "LeftShift", "LocalTime2NatureTime", "MD5Ex",
	"NatureTime2LocalTime", "RightShift", "ScaleRect", "RegistCommitData" }
for _, n in ipairs(NATIVE_FUNCTION_NAMES) do
	if rawget(_G, n) == nil then
		_G[n] = function(...) note_missing("<function>", n) return nil end
	end
end
