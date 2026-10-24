-- Long startup/render frames must not loop forever when a timer restarts.
local checks=0
local function equal(a,b,message) checks=checks+1;assert(a==b,message..': '..tostring(a)..' ~= '..tostring(b)) end
local calls=0
local restarting={}
function restarting:OnTick()
 calls=calls+1
 CGameAppClient.UnRegister(nil,self)
 CGameAppClient.Register(nil,self,3000)
end
CGameAppClient.Register(nil,restarting,3000)
NativeTickUpdate(10000)
equal(calls,1,'self restart runs once during long frame')
NativeTickUpdate(0)
equal(calls,1,'self restart keeps its full new delay')
NativeTickUpdate(3000)
equal(calls,2,'next frame does not process duplicate queue entries')
CGameAppClient.UnRegister(nil,restarting)
local childCalls=0
local child={OnTick=function() childCalls=childCalls+1 end}
local parent={OnTick=function(self)
 CGameAppClient.UnRegister(nil,self)
 CGameAppClient.Register(nil,child,1)
end}
CGameAppClient.Register(nil,parent,1)
NativeTickUpdate(100)
equal(childCalls,0,'new timer waits until a later pump')
NativeTickUpdate(1)
equal(childCalls,1,'new timer runs on following pump')
CGameAppClient.UnRegister(nil,child)
local periodicCalls=0
local periodic={OnTick=function() periodicCalls=periodicCalls+1 end}
CGameAppClient.Register(nil,periodic,1000)
NativeTickUpdate(3000)
equal(periodicCalls,3,'unchanged periodic timer retains bounded catch-up')
CGameAppClient.UnRegister(nil,periodic)
NativeTickUpdate(1000)
equal(periodicCalls,3,'stopped timer remains stopped')
return 'TICK SCHEDULE PASS: '..checks..' checks'
