local a = Array()
a:append(5); a:append("x")
local n = Node:new()
a:append(n)
local r = tostring(a:size()) .. " " .. tostring(a[0])
n:free()
return r
