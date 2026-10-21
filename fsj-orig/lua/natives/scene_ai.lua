-- SceneAI: AI drivers for the offline scene (GPT gpt-6-astra, integrated by Claude). Profiles mirror config ai.txt.
-- Assumptions: AIType 1/2/3 means cautious/balanced/aggressive; safeline protects
-- trails of that length in pixels, reduced by elapsed-time steps and target kills.
-- safetime is match-start protection and applies to every target. Mode/stars default
-- to 0; use SetMatch(scene, mode, stars) otherwise. SetPlayerConfig(p, AIID) preserves
-- full profiles: the legacy __aiCfg cannot distinguish types 2 and 3.
-- Both Think(scene, p, dtMs) and the existing __ai(p, dtMs) callback are supported.
-- Native __scene/__aiCfg/__time/__kills are read for compatibility. No native state
-- is changed except through SetDirection. Cooldown-locked, unavoidable traps can kill.

SceneAI = {}

local NODE = 16
local DX = { [1] = -1, [2] = 1, [4] = 0, [8] = 0 }
local DY = { [1] = 0, [2] = 0, [4] = 1, [8] = -1 }  -- engine convention (scene.lua DIRS): up = +depth
local LEFT = { [1] = 8, [2] = 4, [4] = 1, [8] = 2 }
local RIGHT = { [1] = 4, [2] = 8, [4] = 2, [8] = 1 }
local OPPOSITE = { [1] = 2, [2] = 1, [4] = 8, [8] = 4 }
local DIRECTIONS = { 1, 2, 4, 8 }

local SEARCH_EXPANSIONS = 80
local SEARCH_NODES = 512
local SEARCH_DEPTH = 8
local TRAIL_LIMIT = 160
local ROSTER_BUDGET = 32

local floor, ceil = math.floor, math.ceil
local min, max, abs, sqrt = math.min, math.max, math.abs, math.sqrt
local random = math.random

local function weak_keys()
	return setmetatable({}, { __mode = "k" })
end

local states = weak_keys()
local configurations = weak_keys()
local worlds = weak_keys()
local kill_counts = weak_keys()

local function number(v, default)
	v = tonumber(v)
	if v and v == v and abs(v) < 1e12 then return v end
	return default
end

local function clamp(v, lo, hi)
	return max(lo, min(hi, v))
end

local function pair(v, fallback)
	local a, b
	if type(v) == "table" then
		a, b = number(v[1]), number(v[2])
	elseif type(v) == "string" then
		local first, second = v:match("^%s*([^;]+);%s*([^;]+)")
		a, b = number(first or v), number(second)
	else
		a = number(v)
	end
	if not a then
		a, b = fallback[1], fallback[2]
	end
	b = b or a
	return min(a, b), max(a, b)
end

local function sample(lo, hi)
	return lo + (hi - lo) * random()
end

local profiles = {}
local profile_order = {}
local intervals = { 840, 720, 500, 420, 360 }
local rhythms = {
	[0] = { {3, 3}, {3, 3}, {2, 2}, {2, 2}, {1, 2} },
	[10] = { {1, 2}, {1, 1}, {1, 1}, {0, 1}, {0, 1} },
	[20] = { {3, 3}, {2, 2}, {1, 2}, {1, 1}, {0, 1} },
	[30] = { {3, 3}, {2, 2}, {1, 2}, {1, 1}, {0, 1} },
}

for _, group in ipairs({ 0, 10, 20, 30 }) do
	for i = 1, 5 do
		local id = group + i
		profiles[id] = {
			type = group >= 30 and 3 or group >= 20 and 2 or 1,
			think = { intervals[i], intervals[i] },
			changeDir = { intervals[i], intervals[i] },
			enclose = { 80, 160 },
			expand = {
				group >= 20 and 320 or id == 1 and 240 or 160,
				group >= 20 and 320 or id == 1 and 240 or 160,
			},
			attack = {
				group >= 20 and 320 or group == 10 and 160 or id == 1 and 40 or 80,
				group >= 20 and 320 or group == 10 and 160 or id == 1 and 40 or 80,
			},
			defence = {
				group >= 20 and 80 or id == 1 and 40 or 160,
				group >= 20 and 80 or id == 1 and 40 or 160,
			},
			operation = { 80, 80 },
			rhythm = rhythms[group][i],
		}
		profile_order[#profile_order + 1] = id
	end
end

profiles[1011] = {
	type = 101,
	think = { 360, 360 }, changeDir = { 360, 360 },
	enclose = { 80, 160 }, expand = { 160, 160 },
	attack = { 320, 320 }, defence = { 256, 256 },
	operation = { 80, 80 }, rhythm = { 0, 1 },
}

local fields = {
	{ "think", "ThinkInterval", 20, 10000 },
	{ "changeDir", "ChangeDirInterval", 1, 10000 },
	{ "enclose", "EncloseDistance", 0, 4096 },
	{ "expand", "ExpandDistance", 0, 4096 },
	{ "attack", "AttackDistance", 0, 512 },
	{ "defence", "DefenceDistance", 0, 512 },
	{ "operation", "OperationDistance", 16, 512 },
	{ "rhythm", "RhythmGaussian", 0, 10 },
}

local function make_config(p)
	local supplied = configurations[p]
	local raw = supplied or p.__aiCfg
	local base = profiles[1]
	local legacy = supplied == nil and type(raw) == "table"
		and raw.AIType == nil and raw.type == nil
		and raw.DefenceDistance == nil and raw.defence == nil

	if type(raw) == "number" then
		base = profiles[raw] or base
		raw = nil
	elseif type(raw) == "table" then
		local id = number(raw.ID)
		if id and profiles[id] then
			base = profiles[id]
		elseif legacy then
			for _, candidate in ipairs(profile_order) do
				local c = profiles[candidate]
				if number(raw.think) == c.think[1]
					and number(raw.changeDir) == c.changeDir[1]
					and number(raw.expand) == c.expand[1]
					and number(raw.attack) == c.attack[1] then
					base = c
					break
				end
			end
		end
	else
		raw = nil
	end

	local c = { type = base.type }
	if raw then
		c.type = number(raw.AIType or raw.type, c.type)
	end
	for _, f in ipairs(fields) do
		local short, long = f[1], f[2]
		local value = raw and (raw[long] or raw[short])
		-- scene.lua discarded the upper endpoint of this particular range.
		if legacy and short == "enclose" and type(value) == "number"
			and value == base.enclose[1] then
			value = nil
		end
		local lo, hi = pair(value, base[short])
		c[short .. "Lo"] = clamp(lo, f[3], f[4])
		c[short .. "Hi"] = clamp(hi, f[3], f[4])
	end
	return c
end

function SceneAI.SetPlayerConfig(p, idOrConfig)
	configurations[p] = idOrConfig
	states[p] = nil
end

function SceneAI.SetKillCount(p, count)
	kill_counts[p] = max(0, floor(number(count, 0)))
end

local function move_speed()
	local ok, value = pcall(function()
		local constants = CSnakeConstant and CSnakeConstant:Inst()
		return constants and constants:GetMoveSpeed()
	end)
	return ok and max(1, number(value, 80)) or 80
end

local function get_world(scene)
	local w = worlds[scene]
	if not w then
		w = {
			now = 0, speed = move_speed(), mode = 0, stars = 0,
			live = {}, present = {}, cursor = 1, tail = 0,
		}
		worlds[scene] = w
	end
	return w
end

function SceneAI.SetMatch(scene, mode, stars)
	local w = get_world(scene)
	w.mode = number(mode, 0) == 1 and 1 or 0
	w.stars = max(0, number(stars, 0))
end

local function update_world(scene, p, dt)
	local w = get_world(scene)
	local native_time = number(scene.__time)
	if native_time then
		w.now = max(0, native_time)
	elseif not w.leader or not w.leader.__alive or w.leader == p then
		-- Fallback for small standalone simulations without scene.__time.
		w.leader = p
		w.now = w.now + dt
	end

	local order = scene.__order
	local n = #order
	if w.rosterTime ~= w.now or w.order ~= order or w.orderSize ~= n then
		w.rosterTime = w.now
		if w.order ~= order or n < w.tail then
			w.order, w.tail, w.cursor = order, 0, 1
			w.live, w.present = {}, {}
		end
		w.orderSize = n

		for i = #w.live, 1, -1 do
			local q = w.live[i]
			if not q.__alive or scene.__players[q.__objectID] ~= q then
				w.present[q] = nil
				table.remove(w.live, i)
			end
		end

		local function visit(i)
			local q = order[i]
			if q and q.__alive and not w.present[q] then
				w.present[q] = true
				w.live[#w.live + 1] = q
			end
		end

		-- New spawns get priority; a rolling scan also notices reused players.
		local added = min(ROSTER_BUDGET // 2, n - w.tail)
		for _ = 1, added do
			w.tail = w.tail + 1
			visit(w.tail)
		end
		for _ = 1, min(n, ROSTER_BUDGET - added) do
			if w.cursor > n then w.cursor = 1 end
			visit(w.cursor)
			w.cursor = w.cursor + 1
		end
	end
	return w
end

local function cell(scene, x, y)
	if x < 0 or y < 0 or x >= scene.__W or y >= scene.__H then
		return nil
	end
	return y * scene.__W + x
end

local function protection(w, enemy)
	local stars = w.stars
	local safe, grace
	if stars <= 4 then
		safe, grace = w.mode == 1 and 2400 or 1600, 15000
	elseif stars <= 10 then
		safe, grace = 1200, 10000
	elseif stars <= 20 then
		safe, grace = 800, 5000
	else
		return 0, 5000
	end
	local kills = kill_counts[enemy]
	if kills == nil then kills = max(0, number(enemy.__kills, 0)) end
	safe = max(0, safe - floor(w.now / 5000) * 64 - kills * 32)
	return safe, grace
end

local function attackable(scene, w, s, id)
	local enemy = scene.__players[id]
	if not enemy or not enemy.__alive or id == s.id then return false end
	if enemy.__manor.manorID == s.mid then return false end
	local safe, grace = protection(w, enemy)
	return w.now >= grace and #enemy.__trail * NODE > safe
end

local function passable(scene, w, s, idx, allowed, cleared)
	local t = scene.__trail[idx] or 0
	if t == 0 then return true end
	if t == s.id then return cleared end
	return t == allowed and attackable(scene, w, s, t)
end

local function can_turn(s)
	return s.now - s.lastTurn >= s.turnDelay
end

local function remaining_lock(s)
	return max(0, s.turnDelay - (s.now - s.lastTurn))
end

-- Probe every crossed cell, including cells between the head and the endpoint.
-- Entering home clears the current trail before subsequent cells are crossed.
local function probe(scene, w, s, p, d, distance, allowed)
	local cx, cy = floor(p.__x / NODE), floor(p.__y / NODE)
	local ex = floor((p.__x + DX[d] * (distance + 0.01)) / NODE)
	local ey = floor((p.__y + DY[d] * (distance + 0.01)) / NODE)
	local steps = abs(ex - cx) + abs(ey - cy)
	local cleared, owned = false, 0
	local x, y = cx, cy
	for k = 1, steps do
		local nx, ny = x + DX[d], y + DY[d]
		local idx = cell(scene, nx, ny)
		if not idx or not passable(scene, w, s, idx, allowed, cleared) then
			return false, k - 1, owned, x, y
		end
		x, y = nx, ny
		if scene.__owner[idx] == s.mid then
			cleared = true
			owned = owned + 1
		end
	end
	return true, steps, owned, x, y
end

local function remember_home(s, idx)
	if s.homes[1] ~= idx then
		table.insert(s.homes, 1, idx)
		if #s.homes > 8 then s.homes[9] = nil end
	end
end

local function nearest_home(scene, s, cx, cy)
	local best, distance
	for i = #s.homes, 1, -1 do
		local idx = s.homes[i]
		if scene.__owner[idx] ~= s.mid then
			table.remove(s.homes, i)
		else
			local d = abs(idx % scene.__W - cx) + abs(idx // scene.__W - cy)
			if not distance or d < distance then
				best, distance = idx, d
			end
		end
	end

	-- Territory theft can invalidate all remembered anchors. Recover incrementally.
	if not best then
		local total = scene.__W * scene.__H
		for _ = 1, min(128, total) do
			local idx = s.homeScan
			s.homeScan = (idx + 1) % total
			if scene.__owner[idx] == s.mid then
				local d = abs(idx % scene.__W - cx) + abs(idx // scene.__W - cy)
				if not distance or d < distance then best, distance = idx, d end
			end
		end
		if best then remember_home(s, best) end
	end

	if best then return best % scene.__W, best // scene.__W, distance end
	return nil, nil, nil
end

local function tile_distance2(px, py, x, y)
	local dx = max(x * NODE - px, 0, px - (x + 1) * NODE)
	local dy = max(y * NODE - py, 0, py - (y + 1) * NODE)
	return dx * dx + dy * dy
end

local function threatened(scene, w, s, p)
	local n = #p.__trail
	if n == 0 or s.defence <= 0 then return false end
	if n > TRAIL_LIMIT then return true end
	local radius2 = s.defence * s.defence
	for _, enemy in ipairs(w.live) do
		if enemy ~= p and enemy.__alive
			and enemy.__manor.manorID ~= s.mid then
			for i = 1, n do
				local idx = p.__trail[i]
				if scene.__trail[idx] == s.id
					and tile_distance2(enemy.__x, enemy.__y,
						idx % scene.__W, idx // scene.__W) <= radius2 then
					return true
				end
			end
		end
	end
	return false
end

local function heap_push(heap, node)
	local i = #heap + 1
	while i > 1 do
		local parent = i // 2
		if heap[parent].f <= node.f then break end
		heap[i] = heap[parent]
		i = parent
	end
	heap[i] = node
end

local function heap_pop(heap)
	local first, last = heap[1], heap[#heap]
	heap[#heap] = nil
	if #heap > 0 then
		local i = 1
		while i * 2 <= #heap do
			local child = i * 2
			if child < #heap and heap[child + 1].f < heap[child].f then
				child = child + 1
			end
			if last.f <= heap[child].f then break end
			heap[i] = heap[child]
			i = child
		end
		heap[i] = last
	end
	return first
end

local function on_ancestry(node, x, y)
	while node.parent do
		local parent = node.parent
		if node.x == parent.x then
			if x == node.x and y >= min(node.y, parent.y)
				and y <= max(node.y, parent.y) then return true end
		elseif y == node.y and x >= min(node.x, parent.x)
			and x <= max(node.x, parent.x) then
			return true
		end
		node = parent
	end
	return x == node.x and y == node.y
end

local function reconstruct(node, x, y, d)
	local reversed = { { x = x, y = y, d = d } }
	while node.parent do
		reversed[#reversed + 1] = { x = node.x, y = node.y, d = node.d }
		node = node.parent
	end
	local result = {}
	for i = #reversed, 1, -1 do
		local point = reversed[i]
		local last = result[#result]
		if last and last.d == point.d then
			last.x, last.y = point.x, point.y
		else
			result[#result + 1] = point
		end
	end
	return result
end

-- Bounded directed A*: edges are long enough to obey the turn cooldown.
-- Existing and hypothetical future trail cells both block a route.
local function search(scene, w, s, sx, sy, heading, kind, target,
		hx, hy, allowed, prefix, budget, ready)
	local start = cell(scene, sx, sy)
	if not start then return nil end
	if kind == "home" and scene.__owner[start] == s.mid then return {}, 0 end

	local tx, ty
	if target then tx, ty = target % scene.__W, target // scene.__W end

	local function heuristic(x, y)
		if kind == "attack" then return abs(x - tx) + abs(y - ty) end
		if hx then return abs(x - hx) + abs(y - hy) end
		return 0
	end

	local root = {
		x = sx, y = sy, d = heading, g = 0, depth = 0,
		f = heuristic(sx, sy),
	}
	local heap, best = { root }, {}
	best[start * 16 + heading] = 0
	local created = 1

	for _ = 1, SEARCH_EXPANSIONS do
		if #heap == 0 then break end
		local node = heap_pop(heap)
		local key = (node.y * scene.__W + node.x) * 16 + node.d
		if node.g <= (best[key] or math.huge) and node.depth < SEARCH_DEPTH then
			for _, d in ipairs({ node.d, LEFT[node.d], RIGHT[node.d] }) do
				local permitted = node.parent ~= nil or ready or d == heading
				if permitted then
					local minimum = s.leg
					if node == root and d == heading then
						local lock = ready and 0 or remaining_lock(s)
						minimum = max(1, ceil(w.speed * lock / (1000 * NODE)) + 1)
					end
					local maximum = min(budget - node.g, minimum + s.leg + 1)
					local hitX, hitY, hitStep
					local cleared = false

					for k = 1, maximum do
						local x, y = node.x + DX[d] * k, node.y + DY[d] * k
						local idx = cell(scene, x, y)
						if not idx or not passable(scene, w, s, idx, allowed, cleared) then
							break
						end
						local owned = scene.__owner[idx] == s.mid
						if not cleared and not owned
							and ((prefix and prefix[idx]) or on_ancestry(node, x, y)) then
							break
						end
						if kind == "attack" and not owned and hx then
							local rx, ry = (x - hx) * NODE, (y - hy) * NODE
							if rx * rx + ry * ry > s.expand * s.expand then break end
						end

						local goal = kind == "home" and owned
							or kind == "attack" and idx == target
						if goal and not hitStep then
							hitX, hitY, hitStep = x, y, k
							if kind == "home" then cleared = true end
						end

						if hitStep and k >= minimum then
							-- Attack routes include straight follow-through until another
							-- turn is legal; home routes merely verify that follow-through.
							if kind == "attack" then
								return reconstruct(node, x, y, d), node.g + k
							end
							return reconstruct(node, hitX, hitY, d), node.g + hitStep
						end

						if not hitStep and created < SEARCH_NODES
							and (k == minimum or k == minimum + 1
								or k == minimum + s.leg) then
							local g = node.g + k
							local childKey = idx * 16 + d
							if g < (best[childKey] or math.huge) then
								best[childKey] = g
								created = created + 1
								heap_push(heap, {
									x = x, y = y, d = d, g = g,
									depth = node.depth + 1, parent = node,
									f = g + heuristic(x, y)
										+ (d ~= node.d and 0.35 or 0),
								})
							end
						end
					end
				end
			end
		end
	end
	return nil
end

local function validate_loop(scene, w, s, sx, sy, points)
	local x, y = sx, sy
	local visited, result = {}, {}
	local outside, exposed, cost = false, 0, 0
	for _, q in ipairs(points) do
		local length = abs(q.x - x) + abs(q.y - y)
		local ax, ay = x, y
		for k = 1, length do
			x, y = ax + DX[q.d] * k, ay + DY[q.d] * k
			local idx = cell(scene, x, y)
			if not idx or not passable(scene, w, s, idx, nil, false) then
				return nil
			end
			local owned = scene.__owner[idx] == s.mid
			if not owned then
				if visited[idx] then return nil end
				visited[idx], outside = true, true
				exposed = exposed + 1
				if exposed > s.maxTrail - s.leg then return nil end
			elseif outside then
				-- A thin strip of home must not hide a wall just beyond it.
				for extra = 1, max(1, s.leg - k) do
					local tail = cell(scene, x + DX[q.d] * extra, y + DY[q.d] * extra)
					if not tail or not passable(scene, w, s, tail, nil, true) then
						return nil
					end
				end
				result[#result + 1] = { x = x, y = y, d = q.d }
				return result, cost + k, exposed
			end
		end
		cost = cost + length
		result[#result + 1] = q
	end
	return nil
end

local function expansion(scene, w, s, p, cx, cy)
	local radius = floor(s.expand / NODE)
	local low = max(s.leg, ceil(s.cfg.encloseLo / NODE))
	local high = min(floor(s.cfg.encloseHi / NODE),
		floor(sqrt(max(0, radius * radius - s.leg * s.leg))))
	if high < low then return nil end

	local bestPlan, bestScore, bestAnchor
	local ready = can_turn(s)
	for _, d in ipairs(DIRECTIONS) do
		if d ~= OPPOSITE[p.__dir] and (ready or d == p.__dir) then
			local homeRun = 0
			for k = 1, max(scene.__W, scene.__H) do
				local idx = cell(scene, cx + DX[d] * k, cy + DY[d] * k)
				if not idx or scene.__owner[idx] ~= s.mid
					or (scene.__trail[idx] or 0) ~= 0 then break end
				homeRun = k
			end

			for _, side in ipairs({ LEFT[d], RIGHT[d] }) do
				local width = random(low, high)
				local depthMax = floor(sqrt(max(0, radius * radius - width * width)))
				if depthMax >= s.leg then
					local depth = random(max(s.leg, floor(depthMax * 0.6)), depthMax)
					local reach = homeRun + depth
					local bx, by = cx + DX[d] * reach, cy + DY[d] * reach
					local ex, ey = bx + DX[side] * width, by + DY[side] * width
					local rx, ry = cx + DX[side] * width, cy + DY[side] * width
					local points = {
						{ x = bx, y = by, d = d },
						{ x = ex, y = ey, d = side },
						{ x = rx, y = ry, d = OPPOSITE[d] },
						{ x = cx, y = cy, d = OPPOSITE[side] },
					}
					local route, cost = validate_loop(scene, w, s, cx, cy, points)
					if route then
						local score = depth * width / max(1, cost)
							+ random() * 1.8 + (d == p.__dir and 0.3 or 0)
						for _, enemy in ipairs(w.live) do
							if enemy ~= p and enemy.__alive then
								local dx = enemy.__x / NODE - ex
								local dy = enemy.__y / NODE - ey
								if dx * dx + dy * dy < (s.defence / NODE + 2) ^ 2 then
									score = score - 3
								end
							end
						end
						if not bestScore or score > bestScore then
							bestScore = score
							bestPlan = { points = route, at = 1, kind = "expand" }
							bestAnchor = cell(scene,
								cx + DX[d] * homeRun, cy + DY[d] * homeRun)
						end
					end
				end
			end
		end
	end
	if bestAnchor then remember_home(s, bestAnchor) end
	return bestPlan
end

local function prefix_cells(scene, s, sx, sy, points)
	local result = {}
	local x, y = sx, sy
	for _, q in ipairs(points) do
		local length = abs(q.x - x) + abs(q.y - y)
		for _ = 1, length do
			x, y = x + DX[q.d], y + DY[q.d]
			local idx = y * scene.__W + x
			if scene.__owner[idx] ~= s.mid then result[idx] = true end
		end
	end
	return result
end

local function attack_plan(scene, w, s, p, cx, cy, hx, hy)
	if s.attack <= 0 or not hx then return nil end
	if #p.__trail * NODE > s.operation then return nil end

	local radius = ceil(s.attack / NODE)
	local target, targetID, bestScore
	local eligibility = {}
	local range2 = s.attack * s.attack
	for y = max(0, cy - radius), min(scene.__H - 1, cy + radius) do
		for x = max(0, cx - radius), min(scene.__W - 1, cx + radius) do
			local idx = y * scene.__W + x
			local id = scene.__trail[idx] or 0
			if id ~= 0 and id ~= s.id then
				if eligibility[id] == nil then
					eligibility[id] = attackable(scene, w, s, id)
				end
				if eligibility[id] then
					local dx, dy = (x + 0.5) * NODE - p.__x, (y + 0.5) * NODE - p.__y
					local distance2 = dx * dx + dy * dy
					if distance2 <= range2 then
						local score = sqrt(distance2) / NODE
							+ 0.2 * (abs(x - hx) + abs(y - hy))
						if not bestScore or score < bestScore then
							target, targetID, bestScore = idx, id, score
						end
					end
				end
			end
		end
	end
	if not target then return nil end

	local budget = min(s.maxTrail - #p.__trail,
		ceil(s.attack / NODE * 1.6) + s.leg * 2)
	local outward, outwardCost = search(scene, w, s, cx, cy, p.__dir,
		"attack", target, hx, hy, targetID, nil, budget, can_turn(s))
	if not outward or #outward == 0 then return nil end

	-- Verify an escape before committing, including the trail this attack would lay.
	local endpoint = outward[#outward]
	local virtual = prefix_cells(scene, s, cx, cy, outward)
	local homeward, homeCost = search(scene, w, s, endpoint.x, endpoint.y,
		endpoint.d, "home", nil, hx, hy, targetID, virtual,
		s.maxTrail - #p.__trail - outwardCost, true)
	if not homeward then return nil end
	if #p.__trail + outwardCost + homeCost > s.maxTrail - s.leg then return nil end

	local attackEnd = #outward
	for _, q in ipairs(homeward) do outward[#outward + 1] = q end
	return {
		points = outward, at = 1, kind = "attack",
		allowed = targetID, target = target, attackEnd = attackEnd,
	}
end

local function return_plan(scene, w, s, p, cx, cy, hx, hy)
	local route = search(scene, w, s, cx, cy, p.__dir, "home", nil,
		hx, hy, nil, nil, min(TRAIL_LIMIT, max(48, s.maxTrail)), can_turn(s))
	if route and #route > 0 then
		return { points = route, at = 1, kind = "home" }
	end
	return nil
end

local function new_state(scene, w, p)
	local cfg = make_config(p)
	local s = {
		cfg = cfg, id = p.__objectID, mid = p.__manor.manorID,
		now = 0, lastTurn = -1e12,
		turnDelay = sample(cfg.changeDirLo, cfg.changeDirHi),
		nextThink = 0, nextAttack = sample(900, 2200),
		expand = sample(cfg.expandLo, cfg.expandHi),
		attack = sample(cfg.attackLo, cfg.attackHi),
		defence = sample(cfg.defenceLo, cfg.defenceHi),
		operation = sample(cfg.operationLo, cfg.operationHi),
		rhythm = sample(cfg.rhythmLo, cfg.rhythmHi),
		homes = {}, homeScan = 0, aimBias = 0,
	}
	-- One extra cell absorbs frame quantization and imperfect turn placement.
	s.leg = max(2, ceil(w.speed * cfg.changeDirHi / (1000 * NODE)) + 1)
	s.maxTrail = min(TRAIL_LIMIT, max(s.leg * 6,
		ceil((2 * (s.expand + cfg.encloseHi) + 2 * s.operation) / NODE)))
	s.maxOutsideMs = max(4000,
		2 * (s.expand + cfg.encloseHi) / w.speed * 1000 + cfg.thinkHi * 2)
	states[p] = s
	return s
end

local function follow_plan(s, p, cx, cy, step)
	local plan = s.plan
	if not plan then return nil end
	while plan.at <= #plan.points do
		local q = plan.points[plan.at]
		local horizontal = DX[q.d] ~= 0
		if (horizontal and cy ~= q.y) or (not horizontal and cx ~= q.x) then
			s.plan = nil
			return nil
		end
		local remaining = ((q.x + 0.5) * NODE - p.__x) * DX[q.d]
			+ ((q.y + 0.5) * NODE - p.__y) * DY[q.d]
		if remaining < -NODE * 0.5 then
			s.plan = nil
			return nil
		end
		if cx ~= q.x or cy ~= q.y
			or remaining > max(0.25, step * 0.5) + s.aimBias then
			return q.d
		end

		local nextPoint = plan.points[plan.at + 1]
		if not nextPoint then
			s.plan = nil
			return nil
		end
		if nextPoint.d ~= p.__dir and not can_turn(s) then return p.__dir end
		plan.at = plan.at + 1
		if plan.kind == "attack" and plan.at > plan.attackEnd then
			plan.kind, plan.allowed = "home", nil
			s.returning = true
		end
	end
	s.plan = nil
	return nil
end

local function required_distance(w, s, p, d, dt)
	local hold = d == p.__dir and remaining_lock(s) or s.cfg.changeDirHi
	-- NativeTickUpdate caps movement frames at 100 ms.
	return w.speed * (max(dt, hold) + 100) / 1000
end

local function fallback_direction(scene, w, s, p, outside, dt)
	local bestDir, bestScore
	local allowed = s.plan and s.plan.allowed
	for _, d in ipairs({ p.__dir, LEFT[p.__dir], RIGHT[p.__dir] }) do
		local required = required_distance(w, s, p, d, dt)
		local clear = probe(scene, w, s, p, d, required, allowed)
		if clear then
			local _, length, owned, x, y = probe(scene, w, s, p, d,
				max(required, s.operation), allowed)
			local score = length * 0.12 + owned * (outside and 1.5 or 3)
				+ (d == p.__dir and 0.35 or 0)
			if s.hx then
				score = score - (abs(x - s.hx) + abs(y - s.hy))
					* (outside and 0.65 or 0.15)
			end
			if not bestScore or score > bestScore then
				bestScore, bestDir = score, d
			end
		end
	end
	return bestDir
end

function SceneAI.Think(scene, p, dtMs)
	-- scene.lua calls p.__ai(p, dtMs), rather than passing the scene.
	if type(p) == "number" or p == nil then
		dtMs, p = p, scene
		scene = p and p.__scene
	end
	if not scene or not p then return end
	if not p.__alive then
		states[p] = nil
		return
	end
	if not DX[p.__dir] or not p.__manor
		or not scene.__W or not scene.__H
		or scene.__W <= 0 or scene.__H <= 0 then return end

	local dt = max(0, number(dtMs, 0))
	local w = update_world(scene, p, dt)
	local s = states[p]
	if not s or s.mid ~= p.__manor.manorID or s.scene ~= scene then
		s = new_state(scene, w, p)
		s.scene = scene
	end
	s.now = s.now + dt

	local cx, cy = floor(p.__x / NODE), floor(p.__y / NODE)
	local idx = cell(scene, cx, cy)
	if not idx then return end
	local count = #p.__trail
	local outside = scene.__owner[idx] ~= s.mid or count > 0

	if outside then
		s.outAt = s.outAt or s.now
	else
		if s.outAt then
			s.outAt, s.plan, s.returning = nil, nil, false
			s.nextAttack = max(s.nextAttack, s.now + sample(600, 1400))
		end
		remember_home(s, idx)
		s.hx, s.hy = cx, cy
	end

	local plan = s.plan
	if plan and plan.kind == "attack" then
		local enemy = scene.__players[plan.allowed]
		if not enemy or not enemy.__alive then
			plan.kind, plan.allowed = "home", nil
			s.returning = outside
		elseif scene.__trail[plan.target] ~= plan.allowed
			or not attackable(scene, w, s, plan.allowed) then
			s.plan, s.returning = nil, outside
		end
	end

	if s.now >= s.nextThink then
		s.nextThink = s.now + sample(s.cfg.thinkLo, s.cfg.thinkHi)
		local hx, hy, homeDistance = nearest_home(scene, s, cx, cy)
		s.hx, s.hy = hx, hy

		if outside then
			local returnMs = (homeDistance or s.maxTrail) * NODE / w.speed * 1000
				+ 2 * s.cfg.changeDirHi
			if threatened(scene, w, s, p)
				or count >= s.maxTrail - s.leg * 2
				or s.now - s.outAt + returnMs >= s.maxOutsideMs then
				s.returning = true
			end
			if not s.plan then s.returning = true end
		else
			s.returning = false
		end

		plan = s.plan
		if plan and plan.kind ~= "attack" then
			local endpoint = plan.points[#plan.points]
			local destination = cell(scene, endpoint.x, endpoint.y)
			if not destination or scene.__owner[destination] ~= s.mid then
				s.plan = nil
				s.returning = outside
			end
		end

		if s.returning then
			if not s.plan or s.plan.kind ~= "home" then
				s.plan = return_plan(scene, w, s, p, cx, cy, hx, hy)
			end
		else
			if s.now >= s.nextAttack then
				local aggression = s.cfg.type == 3 and 0.75
					or s.cfg.type == 2 and 0.55
					or s.cfg.type == 101 and 0.60 or 0.28
				aggression = aggression / (1 + s.rhythm * 0.15)
				s.nextAttack = s.now + sample(1200, 3000) + s.rhythm * 180
				if random() < aggression then
					local attack = attack_plan(scene, w, s, p, cx, cy, hx, hy)
					if attack then s.plan = attack end
				end
			end
			if not s.plan and not outside then
				s.plan = expansion(scene, w, s, p, cx, cy)
			end
		end
	end

	local wanted = follow_plan(s, p, cx, cy, w.speed * dt / 1000)
	local allowed = s.plan and s.plan.allowed

	-- Safety is checked every frame; expensive sensing/planning uses ThinkInterval.
	-- No emergency turn bypasses ChangeDirInterval.
	if not can_turn(s) then
		if not probe(scene, w, s, p, p.__dir,
			required_distance(w, s, p, p.__dir, dt), allowed) then
			s.plan = nil
			if outside then s.returning = true end
		end
		return
	end

	local chosen
	if wanted and wanted ~= OPPOSITE[p.__dir]
		and probe(scene, w, s, p, wanted,
			required_distance(w, s, p, wanted, dt), allowed) then
		chosen = wanted
	else
		-- A discarded attack must not grant incidental permission to hit its trail.
		s.plan = nil
		if outside then s.returning = true end
		chosen = fallback_direction(scene, w, s, p, outside, dt)
	end

	if chosen and chosen ~= p.__dir and chosen ~= OPPOSITE[p.__dir] then
		p:SetDirection(chosen)
		if p.__dir == chosen then
			s.lastTurn = s.now
			s.turnDelay = sample(s.cfg.changeDirLo, s.cfg.changeDirHi)
			s.aimBias = sample(-1, 1) * min(2, s.rhythm)
		else
			s.plan = nil
		end
	end
end

return SceneAI