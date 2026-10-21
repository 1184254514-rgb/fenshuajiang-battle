-- In-process stand-in for the original World server (offline single-player). Claude.
-- The original client talks to the server through CGameConnToWorldLua:SendShellMsg(PrtMsg); we intercept at the message-object
-- level (no binary packing) and answer by building the reply message objects and calling their OnNetReply, exactly like
-- CGameConnToWorldLua:PostShellMsg would after UnpackProtocal.
FakeWorld = FakeWorld or {}
local H = {}          -- handlers by message class name
FakeWorld.handlers = H

local function reply(conn, cls, fields)
	local m = cls:new()
	for k, v in pairs(fields or {}) do m[k] = v end
	m:OnNetReply(conn, nil)
	return m
end
FakeWorld.reply = reply

function FakeWorld.OnConnect(conn)
	-- the real server greets with eW2C_OnWorldConnect (announcement list) which makes the client call Login()
	reply(conn, COnWorldConnect, { m_tblDeclaration = {} })
end

function FakeWorld.Handle(conn, msg)
	local name = msg.m_sName or (getmetatable(msg) and getmetatable(msg).m_sName) or "?"
	local h = H[name]
	if h then
		h(conn, msg)
	else
		print("[FakeWorld] unhandled client message: " .. tostring(name))
	end
end

-- hook the client's send path (after the original scripts are loaded)
function FakeWorld.Install()
	function CGameConnToWorldLua:SendShellMsg(PrtMsg, pExtraBuffer, nSize)
		FakeWorld.Handle(self, PrtMsg)
	end
end

-- ---------- player profile ----------
-- Fills the client's CPlayerDBClient (a pure-Lua struct) directly, then runs the original ValidateResult.
function H.CValidateClient(conn, msg)
	local account = msg.m_szAccountName
	if account == nil or account == "" then account = "player" end
	print("[FakeWorld] login account=" .. tostring(account))
	local db = g_App.m_CharContext
	db.InitFromCompress = function() end   -- we fill the struct ourselves (no compressed blob)
	local b = db.m_CharBaseData
	local now = os.time()
	b:SetAccount(account)
	b:SetNickName(account)
	b:SetCreateTime(now); b:SetLoginTime(now)
	b:SetCurHeadIcon(1)
	b:SetInitData(1)
	g_App.__accountID = 10001
	g_App.m_bNewChar = false
	g_App:ValidateResult(nil, 0, db:GetSBlockDataSize())
end

FakeWorld.Install()
