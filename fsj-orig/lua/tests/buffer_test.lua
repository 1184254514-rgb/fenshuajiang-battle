local function check(cond, msg) if not cond then error("FAIL: " .. msg, 2) end end
local b = CBufferStream:new()
b:WriteInt8(-5); b:WriteUint8(200); b:WriteInt16(-1234); b:WriteUint16(65000); b:WriteInt32(-70000); b:WriteUint32(4000000000)
b:WriteUint64(123456789012)
b:WriteUTFBytes("héllo中文")
b:WriteBytes("\1\2\3", 0, 3)
local n = b:GetDataSize()
b:SetPosition(0)
check(b:ReadInt8() == -5, "i8"); check(b:ReadUint8() == 200, "u8"); check(b:ReadInt16() == -1234, "i16")
check(b:ReadUint16() == 65000, "u16"); check(b:ReadInt32() == -70000, "i32"); check(b:ReadUint32() == 4000000000, "u32")
check(b:ReadUint64() == 123456789012, "u64")
local s = b:ReadUTFBytes(#"héllo中文"); check(s == "héllo中文", "utf " .. tostring(s))
-- original-script style: protocol class pack/unpack through PrtBase helpers loaded elsewhere; here just class inheritance
local f = CBufferStream.ReadUint16
check(type(f) == "function", "static fn")
return "buffer ok, size " .. n
