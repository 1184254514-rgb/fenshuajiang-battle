-- GPT audit:
-- Every former ASSUMPTION:
-- M01 STILL OPEN: native trace-back activation, traversal, completion,
--     interruption, collision policy, and their callers/ticks are not supplied.
--     The previous manual retreat remains an explicitly UNVERIFIED extension,
--     disabled by ENABLE_UNVERIFIED_TRACE_BACK=false. Its former claims about
--     remaining frame time, invulnerability, rhythm, and capture are not native
--     findings.
-- M02 STILL OPEN: CPlayer::GetAddSpeed (0x3419a6), the level-config GetAddSpeed
--     body/table, and missing-config behavior are not supplied. Keep an existing
--     GetAddSpeed; otherwise retain the previous formula/zero-config fallback.
-- M03 STILL OPEN: CManorUnit::Remove (0x33e244), CManorLine::BreakOn (0x33f21c),
--     and native trace retraction code are missing. Restoring saved valuation
--     remains part of the disabled manual-retreat extension.
-- M04 STILL OPEN: native trace activation/cost/cooldown/snap implementation and
--     caller are missing. Manual activation with activation-time cooldown remains
--     part of the disabled extension.
-- M05 STILL OPEN: CPlayer constructor/StartUp and native trace cooldown reset
--     bodies are missing. Ready-on-new-life remains the extension's fallback.
-- M06 STILL OPEN: original trace HUD/input handler and keyboard mapping are
--     missing. NativeKeyTraceBack is retained as an UNBOUND adapter function;
--     this module does not establish an original Space binding.
--
-- Recovered movement:
-- CPlayer::MoveOn (0x342730) accepts reversals, chooses the dominant axis
-- (ties choose Y), rejects tiny vectors, compares current effective speed with
-- the requested BASE speed for duplicate rejection, snaps accepted requests,
-- clips the requested segment, invokes CheckBarrier, then adds GetAddSpeed and
-- clamps the resulting speed to [1,4095] only when movement remains.
-- CGameScene::CheckBarrier (0x337d78) tests flag 1 along axis-aligned logical
-- paths and resolves the target to the last free logical-cell centre.
--
-- Additional parity limits:
-- STILL OPEN: MoveOn callers supplying its fourth argument, the travel extent,
-- are not supplied. Existing SetDirection/MoveDir continuous movement is retained
-- as an adapter using a map-spanning extent; it is not a recovered caller.
-- STILL OPEN: CCharacter::Stop (0x3337cc), MoveTo (0x333974/0x333b58), movement
-- ticks, CutLine (0x3338a8), and SceneSim/PATCH_A implementation are absent.
-- Position integration, callback timing, and inherited wall/collision behavior
-- cannot be certified exact from this input.
-- STILL OPEN: GetWidth (0x33660c), FormatToLogic (0x32f84c), and CheckUnitFlag
-- (0x33700c) bodies. Existing coordinate/flag adapters are retained.
-- Native MoveOn reads GetWidth TWICE for its X/Y clipping limits; the code below
-- preserves that square clipping behavior rather than substituting GetDepth.

local pack_values, unpack_values = table.pack, table.unpack   -- the original Help.lua later replaces table.pack (Claude)

local Move = {
	ENABLE_UNVERIFIED_TRACE_BACK = false,
}

local NODE, EPS = 16, 0.000001
local MOVE_INPUT_EPS = 0.009999999776482582
local DIRS = {
	[1] = { -1, 0 }, [2] = { 1, 0 },
	[4] = { 0, 1 }, [8] = { 0, -1 },
}

local function number(v, fallback)
	if type(v) == "number" and v == v and math.abs(v) < math.huge then
		return v
	end
	return fallback
end

local function trunc(v)
	local integral = math.modf(v)
	return integral
end

local function s16(v)
	v = trunc(v) & 0xffff
	return v >= 0x8000 and v - 0x10000 or v
end

local function component(v, name, index)
	local value = v[name]
	if type(value) == "function" then value = value(v) end
	if value == nil then value = v[index] end
	return number(value, 0)
end

function Move.install(sim)
	assert(type(sim) == "table", "scene_move: apply PATCH_A.md first")
	if sim.__a_installed then return sim.__a_module end

	for _, name in ipairs({
		"const", "cell", "set_cell", "set_val", "sync_player",
		"enter_node", "kill_player", "step_player",
	}) do
		assert(type(sim[name]) == "function", "scene_move: missing SceneSim." .. name)
	end

	local function constant(name, fallback)
		return number(sim.const(name, fallback), fallback)
	end

	local function property(p, id)
		local ok, value = pcall(p.GetSimple32Property, p, id)
		return ok and number(value, 0) or 0
	end

	local function add_speed(p)
		local ok, value = pcall(p.GetAddSpeed, p)
		return ok and trunc(number(value, 0)) or 0
	end

	if type(CPlayerClient.GetAddSpeed) ~= "function" then
		function CPlayerClient:GetAddSpeed()
			-- M02: retained fallback. The referenced native body is absent.
			local levelBonus = 0
			local cfg = CPlayerLevelConfig
			if cfg then
				local ok, value = pcall(function()
					return cfg:Inst():GetAddSpeed(property(self, 7))
				end)
				if ok then levelBonus = number(value, 0) end
			end
			return trunc(levelBonus)
				+ trunc(constant("HighSpeed", 180) * property(self, 8) / 10000)
		end
	end

	local function base_speed(p)
		return trunc(p.__speedup and constant("HighSpeed", 180)
			or constant("MoveSpeed", 80))
	end

	local function speed_for(p, base)
		return math.max(1, math.min(4095, trunc(base) + add_speed(p)))
	end

	local function move_speed(p)
		return speed_for(p, base_speed(p))
	end

	local function now(p)
		return p.__scene and number(p.__scene.__time, 0) or 0
	end

	local function ensure(p)
		p.__a_tracing = p.__a_tracing == true
		p.__a_trace_ready_at = p.__a_trace_ready_at or 0
		if p.__a_trace_cd_total_ms == nil then
			p.__a_trace_cd_total_ms =
				math.max(0, trunc(constant("TraceBackCDTime", 10000)))
		end
		p.__a_trace_cd_ms =
			math.ceil(math.max(0, p.__a_trace_ready_at - now(p)))
		p.__a_speedup = not not (p.__alive and p.__speedup and not p.__a_tracing)
		p.__a_under = p.__a_under or {}
	end

	local function index_at(sc, x, y)
		return sim.cell(sc, s16(trunc(x / NODE)), s16(trunc(y / NODE)))
	end

	local function owned(sc, p, idx)
		return idx ~= nil and p.__manor ~= nil
			and sc.__owner[idx] == p.__manor.manorID
	end

	local function centre(sc, idx)
		return {
			x = (idx % sc.__W) * NODE + NODE / 2,
			y = (idx // sc.__W) * NODE + NODE / 2,
			idx = idx,
		}
	end

	local function invalidate_route(p)
		p.__a_path, p.__a_cells, p.__a_visits, p.__a_home = nil, nil, nil, nil
	end

	local function forget_motion(p)
		p.__a_motion_dir, p.__a_motion_speed = nil, nil
		p.__a_motion_target_x, p.__a_motion_target_y = nil, nil
		p.__a_request_dir, p.__a_request_speed = nil, nil
		p.__a_request_base, p.__a_request_distance = nil, nil
	end

	local function remember_home(sc, p, idx)
		invalidate_route(p)
		p.__a_home = owned(sc, p, idx) and centre(sc, idx) or nil
		p.__a_under = {}
	end

	local function append_point(path, x, y)
		local last = path[#path]
		local dx, dy = x - last.x, y - last.y
		if math.abs(dx) <= EPS and math.abs(dy) <= EPS then return true end
		if math.abs(dx) > EPS and math.abs(dy) > EPS then return false end

		if #path >= 2 then
			local before = path[#path - 1]
			local ax, ay = last.x - before.x, last.y - before.y
			local horizontal = math.abs(ay) <= EPS
				and math.abs(dy) <= EPS and ax * dx > 0
			local vertical = math.abs(ax) <= EPS
				and math.abs(dx) <= EPS and ay * dy > 0
			if horizontal or vertical then
				last.x, last.y = x, y
				return true
			end
		end
		path[#path + 1] = { x = x, y = y }
		return true
	end

	local function record_position(sc, p, ox, oy, x, y)
		if not Move.ENABLE_UNVERIFIED_TRACE_BACK
			or not p.__alive or p.__a_tracing then return end
		ensure(p)

		local idx = index_at(sc, x, y)
		if owned(sc, p, idx) then
			remember_home(sc, p, idx)
			return
		end
		if idx == nil or sc.__trail[idx] ~= p.__objectID then
			invalidate_route(p)
			return
		end

		local path = p.__a_path
		if not path then
			local previous = index_at(sc, ox, oy)
			if not owned(sc, p, previous) then
				invalidate_route(p)
				return
			end
			local home = centre(sc, previous)
			p.__a_home = home
			path = { { x = home.x, y = home.y } }
			p.__a_path, p.__a_cells, p.__a_visits = path, {}, {}
			if not append_point(path, ox, oy) then
				invalidate_route(p)
				return
			end
		end

		if not append_point(path, x, y) then
			invalidate_route(p)
			return
		end

		local cells = p.__a_cells
		if cells[#cells] ~= idx then
			cells[#cells + 1] = idx
			p.__a_visits[idx] = (p.__a_visits[idx] or 0) + 1
		end
	end

	local function eligible(p)
		ensure(p)
		if not Move.ENABLE_UNVERIFIED_TRACE_BACK then
			return false, "native-trace-unavailable"
		end
		local sc = p.__scene
		if not sc or not sc.__started then return false, "scene-not-running" end
		if sc:GetRoomType() ~= 0 then return false, "not-endless" end
		if not p.__alive then return false, "dead" end
		if p.__a_tracing then return false, "tracing" end
		if p.__a_trace_cd_ms > 0 then return false, "cooldown" end
		if owned(sc, p, index_at(sc, p.__x, p.__y)) then return false, "home" end
		if #(p.__trail or {}) == 0 then return false, "no-trail" end
		if not p.__a_path or #p.__a_path < 2
			or not p.__a_cells or #p.__a_cells == 0
			or not p.__a_home then
			return false, "no-recorded-route"
		end
		if not owned(sc, p, p.__a_home.idx) then return false, "home-lost" end
		return true
	end

	local function publish(p)
		ensure(p)
		local available = eligible(p)
		local view = Host and Host.scene_view
		if not view or p.__objectID == nil then return end

		local ok, method = pcall(function() return view.set_player_move_state end)
		if ok and type(method) == "function" then
			method(view, p.__objectID, p.__a_speedup, p.__a_tracing,
				p.__a_trace_cd_ms, p.__a_trace_cd_total_ms, available)
		end
	end

	local function erase_trail_cell(sc, p, idx)
		if sc.__trail[idx] == p.__objectID then
			sim.set_cell(sc, idx, nil, 0)

			-- M03: valuation restoration is an unrecovered extension.
			local saved = p.__a_under[idx]
			if saved and saved.owner == sc.__owner[idx] and saved.grade ~= nil then
				sim.set_val(sc, idx, saved.grade)
			elseif sc.__owner[idx] == 0 and sc.__val then
				sc.__val[idx] = nil
			end
		end

		local trail = p.__trail
		local segment = p.__segStart or 1
		for k = #trail, 1, -1 do
			if trail[k] == idx then
				table.remove(trail, k)
				if k < segment then segment = segment - 1 end
			end
		end
		p.__segStart = math.max(1, math.min(segment, #trail + 1))
		p.__a_under[idx] = nil

		if sim.a_on_trail_retracted then sim.a_on_trail_retracted(sc, p, idx) end
	end

	local function cancel_trace(p, reason)
		p.__a_tracing = false
		p.__a_trace_last_stop = reason
		forget_motion(p)
		invalidate_route(p)
	end

	local function finish_trace(sc, p)
		local pending = {}
		for k, idx in ipairs(p.__trail) do pending[k] = idx end
		for _, idx in ipairs(pending) do
			erase_trail_cell(sc, p, idx)
			if not p.__alive then return end
		end
		p.__trail, p.__segStart = {}, 1
		p.__a_tracing = false
		p.__a_trace_last_stop = "home"
		remember_home(sc, p, index_at(sc, p.__x, p.__y))
		forget_motion(p)
	end

	local previous_position = sim.a_after_position
	sim.a_after_position = function(sc, p, ox, oy, x, y)
		if previous_position then previous_position(sc, p, ox, oy, x, y) end
		record_position(sc, p, ox, oy, x, y)
	end

	sim.a_move_speed = function(p)
		if p.__a_motion_speed ~= nil then return p.__a_motion_speed end
		return move_speed(p)
	end

	local function width(sc)
		if type(sc.GetWidth) == "function" then
			return trunc(number(sc:GetWidth(), sc.__W * NODE))
		end
		return sc.__W * NODE
	end

	local function unit_flag(sc, gx, gy)
		local items = rawget(_G, "SceneItemsC")
		if items and type(items.GetItemUnitFlags) == "function" then
			return items.GetItemUnitFlags(sc, gx, gy)
		end
		if type(sc.GetItemUnitFlags) == "function" then
			return trunc(number(sc:GetItemUnitFlags({ x = gx, y = gy }), 0))
		end
		return 0
	end

	local function check_barrier(sc, ox, oy, tx, ty)
		if type(sc.CheckBarrier) == "function" then
			local target = { x = tx, y = ty }
			sc:CheckBarrier({ x = ox, y = oy }, target)
			return component(target, "x", 1), component(target, "y", 2)
		end

		-- CGameScene::CheckBarrier (0x337d78), for independent module loading.
		local gx, gy = s16(trunc(ox / NODE)), s16(trunc(oy / NODE))
		local ex, ey = s16(trunc(tx / NODE)), s16(trunc(ty / NODE))
		if gx ~= ex and gy ~= ey then return tx, ty end
		if gx == ex and gy == ey or (unit_flag(sc, gx, gy) & 1) ~= 0 then
			return ox, oy
		end

		local dx, dy = s16(ex - gx), s16(ey - gy)
		local length = s16(trunc(math.sqrt(dx * dx + dy * dy)))
		if length > 0 then
			dx, dy = s16(trunc(dx / length)), s16(trunc(dy / length))
		end
		local x, y = gx, gy
		while x ~= ex or y ~= ey do
			local nx, ny = s16(x + dx), s16(y + dy)
			if (unit_flag(sc, nx, ny) & 1) ~= 0 then break end
			x, y = nx, ny
		end
		return s16(x * NODE + 8), s16(y * NODE + 8)
	end

	local function begin_motion(sc, p, dir, base, distance, force)
		if not sc then return false, "no-scene" end
		if not p.__alive then return false, "dead" end
		if not DIRS[dir] then return false, "invalid-direction" end
		if p.__a_tracing then return false, "tracing" end
		base, distance = trunc(base), trunc(distance)

		-- CPlayer::MoveOn (0x342730): compare effective speed to requested
		-- BASE speed before calculating the additional speed.
		local currentDir = p.__a_motion_dir or p.__dir
		local currentSpeed = p.__a_motion_speed or 0
		if not force and currentDir == dir and math.abs(currentSpeed - base) < 1 then
			return false, "unchanged"
		end

		local vector = DIRS[dir]
		local ox, oy = p.__x, p.__y
		local sx = s16(s16(trunc(ox / NODE)) * NODE + 8)
		local sy = s16(s16(trunc(oy / NODE)) * NODE + 8)
		local tx, ty = sx + vector[1] * distance, sy + vector[2] * distance

		-- CPlayer::MoveOn (0x342730): both clipping maxima use GetWidth()-1.
		-- Axis-aligned, in-bounds segment clipping is represented directly;
		-- the general native CutLine helper body is missing.
		local limitX, limitY = width(sc) - 1, width(sc) - 1
		tx = math.max(0, math.min(limitX, tx))
		ty = math.max(0, math.min(limitY, ty))

		p.__dir = dir
		p.__a_motion_dir = dir
		p.__a_motion_speed = 0
		p.__a_motion_target_x, p.__a_motion_target_y = nil, nil
		p.__a_request_dir = dir
		p.__a_request_base = base
		p.__a_request_distance = distance

		-- CCharacter::Stop body is missing. Preserve SceneSim's position hook.
		p.__x, p.__y = sx, sy
		sim.a_after_position(sc, p, ox, oy, sx, sy)
		ensure(p)
		if not p.__alive then return false, "dead" end

		tx, ty = check_barrier(sc, p.__x, p.__y, tx, ty)
		if tx == p.__x and ty == p.__y then
			-- Native does not call GetAddSpeed/MoveTo when no travel remains.
			p.__a_request_speed = nil
			sim.sync_player(p)
			return true
		end

		local speed = speed_for(p, base)
		p.__a_motion_speed = speed
		p.__a_request_speed = speed
		p.__a_motion_target_x, p.__a_motion_target_y = tx, ty
		sim.sync_player(p)
		return true
	end

	local function request_motion(sc, p, dir, explicit)
		if not sc then return false, "no-scene" end
		local base = base_speed(p)
		local speed = speed_for(p, base)

		if not explicit and p.__a_request_dir == dir
			and p.__a_request_base == base
			and (p.__a_request_speed == speed or p.__a_motion_speed == 0) then
			return false, "unchanged"
		end

		-- Unrecovered caller extent: retain the previous continuous adapter.
		-- A full map width reaches the square boundary from an in-bounds centre.
		local result, reason = begin_motion(sc, p, dir, base, width(sc), not explicit)
		if result then
			-- Cache the requested speed even when the native barrier stops it.
			p.__a_request_speed = speed
		end
		return result, reason
	end

	function CPlayerClient:MoveOn(x, y, requestedBaseSpeed, travelExtent)
		x, y = number(x, 0), number(y, 0)
		-- CPlayer::MoveOn (0x342730), literal-pool threshold.
		if math.abs(x) < MOVE_INPUT_EPS and math.abs(y) < MOVE_INPUT_EPS then
			return false, "zero-direction"
		end
		local dir
		if math.abs(x) > math.abs(y) then
			dir = x > 0 and 2 or 1
		else
			dir = y > 0 and 4 or 8
		end
		local result, reason = begin_motion(self.__scene, self, dir,
			number(requestedBaseSpeed, 0), number(travelExtent, 0), false)
		publish(self)
		return result, reason
	end

	local previous_enter = sim.enter_node
	sim.enter_node = function(sc, p, x, y, previous_idx)
		ensure(p)
		local idx = sim.cell(sc, x, y)
		if p.__a_tracing then
			-- M01: retained manual-extension collision policy.
			if idx and p.__alive then
				local id = sc.__trail[idx] or 0
				local victim = id ~= 0 and sc.__players[id] or nil
				if victim and victim ~= p and victim.__alive then
					sim.kill_player(sc, victim, p, true, "trail")
				end
			end
			return
		end

		if Move.ENABLE_UNVERIFIED_TRACE_BACK
			and idx and not owned(sc, p, idx)
			and sc.__trail[idx] ~= p.__objectID and p.__a_under[idx] == nil then
			p.__a_under[idx] = {
				owner = sc.__owner[idx],
				grade = sc.__val and sc.__val[idx],
			}
		end
		return previous_enter(sc, p, x, y, previous_idx)
	end

	local previous_die = sim.a_on_die
	sim.a_on_die = function(sc, p)
		if previous_die then previous_die(sc, p) end
		p.__a_tracing, p.__a_speedup = false, false
		p.__a_trace_last_stop = "dead"
		forget_motion(p)
		invalidate_route(p)
		p.__a_under = {}
		publish(p)
	end

	local function trace_step(sc, p, dtMs)
		-- Entire routine is the retained, disabled M01/M03 extension.
		local speed = math.max(1, trunc(constant("TraceBackSpeed", 600)))
		local budget, travelled = speed * dtMs / 1000, 0

		while budget > EPS and p.__alive and p.__a_tracing do
			local path = p.__a_path
			if not path or #path < 2 then break end
			local tip, target = path[#path], path[#path - 1]
			if math.abs(tip.x - p.__x) > EPS or math.abs(tip.y - p.__y) > EPS then
				cancel_trace(p, "position-changed")
				break
			end

			local vx, vy = target.x - p.__x, target.y - p.__y
			if math.abs(vx) > EPS and math.abs(vy) > EPS then
				cancel_trace(p, "invalid-route")
				break
			end
			local length = math.abs(vx) + math.abs(vy)
			if length <= EPS then
				table.remove(path)
			else
				local amount = math.min(4, length, budget)
				local dx = math.abs(vx) > EPS and (vx > 0 and 1 or -1) or 0
				local dy = math.abs(vy) > EPS and (vy > 0 and 1 or -1) or 0
				local ox, oy = p.__x, p.__y
				local x, y = ox + dx * amount, oy + dy * amount
				local arrived = amount >= length - EPS
				if arrived then x, y = target.x, target.y end

				local oldIdx, idx = index_at(sc, ox, oy), index_at(sc, x, y)
				if idx == nil
					or (not owned(sc, p, idx) and sc.__trail[idx] ~= p.__objectID) then
					cancel_trace(p, "trail-lost")
					break
				end

				local crossed = idx ~= oldIdx
				local cells, home = p.__a_cells, p.__a_home
				if not cells or not home then
					cancel_trace(p, "invalid-route")
					break
				end
				if crossed then
					local expected = cells[#cells - 1] or home.idx
					if #cells > 0 then
						if cells[#cells] ~= oldIdx or expected ~= idx then
							cancel_trace(p, "invalid-route")
							break
						end
					elseif not owned(sc, p, oldIdx) or not owned(sc, p, idx) then
						cancel_trace(p, "invalid-route")
						break
					end
				end

				p.__dir = dx < 0 and 1 or dx > 0 and 2 or dy > 0 and 4 or 8
				p.__x, p.__y = x, y
				if arrived then table.remove(path) else tip.x, tip.y = x, y end
				budget, travelled = budget - amount, travelled + amount

				if crossed and #cells > 0 then
					local leaving = table.remove(cells)
					local count = (p.__a_visits[leaving] or 0) - 1
					p.__a_visits[leaving] = count > 0 and count or nil
					if count <= 0 then erase_trail_cell(sc, p, leaving) end
				end
				if p.__alive and p.__a_tracing then
					if crossed then
						sim.enter_node(sc, p, s16(trunc(x / NODE)), s16(trunc(y / NODE)))
					end
					if p.__alive and p.__a_tracing then
						sim.a_after_position(sc, p, ox, oy, x, y)
					end
				end
			end
		end

		local path = p.__a_path
		if p.__alive and p.__a_tracing and path and #path < 2 then
			if #path == 1 and owned(sc, p, index_at(sc, p.__x, p.__y)) then
				finish_trace(sc, p)
			else
				cancel_trace(p, "home-lost")
			end
		end
		return math.min(dtMs, travelled * 1000 / speed)
	end

	function CPlayerClient:CanTraceBack()
		return eligible(self)
	end

	function CPlayerClient:IsTracingBack()
		return self.__a_tracing == true
	end

	function CPlayerClient:GetTraceBackCDRemain()
		ensure(self)
		return self.__a_trace_cd_ms
	end

	function CPlayerClient:GetTraceBackCDTime()
		ensure(self)
		return self.__a_trace_cd_total_ms
	end

	function CPlayerClient:TraceBack()
		local ok, reason = eligible(self)
		if not ok then return false, reason end
		local sc, path = self.__scene, self.__a_path
		local tip = path[#path]
		if math.abs(tip.x - self.__x) > EPS or math.abs(tip.y - self.__y) > EPS then
			return false, "position-changed"
		end
		for k = 2, #path do
			local dx, dy = path[k].x - path[k - 1].x, path[k].y - path[k - 1].y
			if math.abs(dx) > EPS and math.abs(dy) > EPS then
				return false, "invalid-route"
			end
		end
		for _, idx in ipairs(self.__a_cells) do
			if not owned(sc, self, idx) and sc.__trail[idx] ~= self.__objectID then
				return false, "trail-lost"
			end
		end

		-- M04: retained extension activation; no native claim.
		self.__a_trace_cd_total_ms =
			math.max(0, trunc(constant("TraceBackCDTime", 10000)))
		self.__a_trace_ready_at = now(self) + self.__a_trace_cd_total_ms
		self.__a_tracing = true
		self.__a_trace_last_stop = nil
		publish(self)
		return true
	end

	function CPlayerClient:SetDirection(dir)
		if not self.__alive then return false, "dead" end
		if not DIRS[dir] then return false, "invalid-direction" end
		if self.__a_tracing then return false, "tracing" end
		if not self.__scene then return false, "no-scene" end
		request_motion(self.__scene, self, dir, true)
		publish(self)
		return true
	end

	function CPlayerClient:MoveDir(x, y)
		x, y = number(x, 0), number(y, 0)
		if math.abs(x) < MOVE_INPUT_EPS and math.abs(y) < MOVE_INPUT_EPS then
			return false, "zero-direction"
		end

		-- CPlayer::MoveOn (0x342730): ties select Y, reversals are accepted.
		local dir
		if math.abs(x) > math.abs(y) then
			dir = x > 0 and 2 or 1
		else
			dir = y > 0 and 4 or 8
		end
		return self:SetDirection(dir)
	end

	local previous_rhythm = CPlayerClient.RhythmSpeed
	function CPlayerClient:RhythmSpeed(grade, ...)
		local was = not not self.__speedup
		local result = pack_values(previous_rhythm(self, grade, ...))
		ensure(self)
		if self.__alive and not self.__a_tracing
			and was ~= (not not self.__speedup) then
			request_motion(self.__scene, self, self.__dir, true)
		end
		publish(self)
		return unpack_values(result, 1, result.n)
	end

	local previous_add = CGameScene.AddPlayer
	function CGameScene:AddPlayer(...)
		local result = pack_values(previous_add(self, ...))
		if result[1] then ensure(result[1]) end
		return unpack_values(result, 1, result.n)
	end

	local previous_start = CPlayerClient.StartUp
	function CPlayerClient:StartUp(...)
		-- M05: extension-only life reset; native cooldown reset is missing.
		self.__a_tracing, self.__a_speedup = false, false
		self.__a_trace_ready_at, self.__a_trace_cd_ms = 0, 0
		self.__a_trace_cd_total_ms =
			math.max(0, trunc(constant("TraceBackCDTime", 10000)))
		self.__a_trace_last_stop = nil
		forget_motion(self)
		invalidate_route(self)
		self.__a_under = {}

		local result = pack_values(previous_start(self, ...))
		ensure(self)
		if Move.ENABLE_UNVERIFIED_TRACE_BACK and self.__scene then
			remember_home(self.__scene, self,
				index_at(self.__scene, self.__x, self.__y))
		end
		publish(self)
		return unpack_values(result, 1, result.n)
	end

	local previous_step = sim.step_player
	sim.step_player = function(sc, p, dtMs)
		ensure(p)
		dtMs = math.max(0, number(dtMs, 0))
		if not p.__alive then publish(p); return end

		if p.__a_tracing and not Move.ENABLE_UNVERIFIED_TRACE_BACK then
			cancel_trace(p, "disabled")
		end
		if p.__a_tracing then
			dtMs = math.max(0, dtMs - trace_step(sc, p, dtMs))
		end

		if p.__alive and not p.__a_tracing and dtMs > EPS then
			request_motion(sc, p, p.__dir, false)
			local speed = p.__a_motion_speed or 0
			local tx, ty = p.__a_motion_target_x, p.__a_motion_target_y
			local activeMs = dtMs

			if speed <= 0 or tx == nil or ty == nil then
				activeMs = 0
			else
				local distance = math.abs(tx - p.__x) + math.abs(ty - p.__y)
				activeMs = math.min(dtMs, distance * 1000 / speed)
			end

			if activeMs > EPS then
				previous_step(sc, p, activeMs)
			else
				sim.sync_player(p)
			end

			if p.__alive and tx ~= nil and ty ~= nil
				and math.abs(p.__x - tx) <= EPS
				and math.abs(p.__y - ty) <= EPS then
				p.__a_motion_speed = 0
				sim.sync_player(p)
			end
		elseif p.__alive then
			sim.sync_player(p)
		end
		publish(p)
	end

	function CGameMain:ClickTraceBack()
		local p = g_App and g_App:GetDirector()
		if not p then return false, "no-director" end
		return p:TraceBack()
	end

	function NativeKeyTraceBack()
		-- M06: callable adapter only; no recovered keyboard binding.
		local gm = g_App and g_App:GetGameMain()
		if not gm then return false, "no-game-main" end
		return gm:ClickTraceBack()
	end

	sim.__a_installed, sim.__a_module = true, Move
	return Move
end

return Move.install(assert(rawget(_G, "SceneSim"), "scene_move: apply PATCH_A.md first"))
