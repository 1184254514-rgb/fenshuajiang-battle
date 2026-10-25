-- Native peer connections for the current single active trail per player.
-- ConnectUnit 0x33d9e2 writes reciprocal +0x12 flags across manor/line layers;
-- AddUnit's ordinary same-layer continuation writes +0x11 instead. See the
-- peer capture audit: arbitrary adjacent/overlapped cells are NOT connections.
local C = {}
local directions = {{1,-1,0,2},{2,1,0,1},{4,0,1,8},{8,0,-1,4}}

function C.Clear(sc, p)
	local link = p.__linePeer
	if link and sc.__manorPeers then
		local peers = sc.__manorPeers[link.home]
		if peers and peers[link.direction] == link then
			peers[link.direction] = nil
			if next(peers) == nil then sc.__manorPeers[link.home] = nil end
		end
	end
	p.__linePeer = nil
end

function C.Connect(sc, p, home, first)
	C.Clear(sc, p)
	if home == nil or first == nil or not p.__alive or #p.__trail ~= 1
		or p.__trail[1] ~= first or sc.__trail[first] ~= p.__objectID
		or sc.__owner[home] ~= p.__manor.manorID then return false end
	local hx, hy = home % sc.__W, home // sc.__W
	local fx, fy = first % sc.__W, first // sc.__W
	for _, d in ipairs(directions) do
		if fx == hx + d[2] and fy == hy + d[3] then
			local link = {home=home,line=first,direction=d[1],reverse=d[4],player=p.__objectID}
			sc.__manorPeers = sc.__manorPeers or {}
			sc.__manorPeers[home] = sc.__manorPeers[home] or {}
			sc.__manorPeers[home][d[1]] = link
			p.__linePeer = link
			return true
		end
	end
	return false
end

function C.IsLive(sc, link)
	local p = sc.__players[link.player]
	if not p or not p.__alive or p.__linePeer ~= link
		or p.__trail[1] ~= link.line or sc.__trail[link.line] ~= link.player
		or sc.__owner[link.home] ~= p.__manor.manorID then return false end
	local peers = sc.__manorPeers and sc.__manorPeers[link.home]
	return peers ~= nil and peers[link.direction] == link
end

function C.BeforeClaim(sc, actor, idx, source)
	local peers = sc.__manorPeers and sc.__manorPeers[idx]
	if not peers then return end
	-- Native AddManorUnit 0x33e46c..0x33e57e checks 1,2,4,8 and re-reads
	-- flags after a death (which can remove the other connected line cells).
	for _, d in ipairs(directions) do
		local link = peers[d[1]]
		if link then
			if C.IsLive(sc, link) then
				local victim = sc.__players[link.player]
				if victim.__manor.manorID ~= actor.__manor.manorID then
					SceneSim.kill_player(sc, victim, actor, false, "anchor", {
						cell=idx,previousOwner=sc.__owner[idx],source=source,
						peerLineCell=link.line,peerDirection=link.direction})
				end
			else
				-- Reject stale/corrupt adapter state; adjacency alone cannot kill.
				peers[d[1]] = nil
				local p = sc.__players[link.player]
				if p and p.__linePeer == link then p.__linePeer = nil end
			end
		end
	end
	if next(peers) == nil then sc.__manorPeers[idx] = nil end
end

return C
