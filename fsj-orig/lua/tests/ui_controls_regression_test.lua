-- Regression checks for D-pad CDir compass mapping and skill long-press tooltip data.
local checks = 0
local function check(ok, msg)
	checks = checks + 1
	assert(ok, "UI CONTROLS FAIL: " .. tostring(msg))
end

-- 1. CDir:Set compass convention (0 = up, 64 = right, 128 = down, 192 = left)
local function dir_of(dx, dy)
	local d = CDir:new()
	d:Set(CVector2f:new(dx, dy))
	return d:uDir()
end
check(dir_of(0, 100) == 0, "up vector (+Y) maps to uDir 0")
check(dir_of(100, 0) == 64, "right vector (+X) maps to uDir 64")
check(dir_of(0, -100) == 128, "down vector (-Y) maps to uDir 128")
check(dir_of(-100, 0) == 192, "left vector (-X) maps to uDir 192")

-- Match CGameButton:OnClickWholeScreen quadrant dispatch
local function quadrant(clickX, clickY, cx, cy)
	local v = CDir:new()
	v:Set(CVector2f:new(clickX - cx, cy - clickY))
	local u = v:uDir()
	if 96 <= u and u < 160 then return "down"
	elseif 160 <= u and u < 224 then return "left"
	elseif 32 <= u and u < 96 then return "right"
	else return "up" end
end
check(quadrant(240, 200, 240, 430) == "up", "clicking above D-pad center moves up")
check(quadrant(240, 620, 240, 430) == "down", "clicking below D-pad center moves down")
check(quadrant(60, 430, 240, 430) == "left", "clicking left of D-pad center moves left")
check(quadrant(420, 430, 240, 430) == "right", "clicking right of D-pad center moves right")

-- 2. Skill tooltip data for all active and passive skills
local hud = SceneSkills.GetHUD()
check(#hud.active >= 7, "all active skills available")
check(#hud.passive >= 8, "all passive skills available")
for _, row in ipairs(hud.active) do
	local tip = SceneSkills.GetSkillTooltip(row.id, 1)
	check(tip ~= nil, "active tooltip exists for " .. tostring(row.id))
	check(tip.tag == "主动技能", "active tag for " .. tostring(row.id))
	check(tip.title:find(row.name, 1, true) ~= nil, "active title includes name for " .. tostring(row.id))
	check(tip.effect ~= "", "active effect non-empty for " .. tostring(row.id))
	check(not tip.desc:find("#c", 1, true), "active desc stripped color tags for " .. tostring(row.id))
end
for _, row in ipairs(hud.passive) do
	local tip = SceneSkills.GetSkillTooltip(row.id, 6)
	check(tip ~= nil, "passive tooltip exists for " .. tostring(row.id))
	check(tip.tag == "被动技能", "passive tag for " .. tostring(row.id))
	check(tip.title:find("满级", 1, true) ~= nil, "level 6 shows max label for " .. tostring(row.id))
	check(tip.effect ~= "", "passive effect non-empty for " .. tostring(row.id))
	check(not tip.desc:find("#c", 1, true), "passive desc stripped color tags for " .. tostring(row.id))
end

print("UI CONTROLS REGRESSION PASS: " .. tostring(checks) .. " checks")
