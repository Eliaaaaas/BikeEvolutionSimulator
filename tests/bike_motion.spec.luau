local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local M=modules.BikeMotion
local P=modules.Protocol
local function drive(overrides)
 local p={Version=1,Sequence=1,Throttle=1,Steer=0,Brake=false}
 for k,v in pairs(overrides or {}) do p[k]=v end;return p
end
test("drive intents reject spoofed amounts, positions, NaN, infinity and replay-shaped sequences",function()
 assert(P.validDrive(drive()))
 for _,bad in ipairs({{Throttle=0/0},{Steer=math.huge},{Throttle=2},{Sequence=0},{Sequence=1.5},{Position=10},{Cash=5},{Brake=1}}) do assert(not P.validDrive(drive(bad))) end
end)
test("manual speed accelerates smoothly and never exceeds configured target",function()
 local speed=0
 for _=1,100 do local v=M.step(speed,0,1,0,false,.05,18);assert(v.Speed>=speed and v.Speed<=18);speed=v.Speed end
 assert(speed==18)
end)
test("manual braking stops without reversal and stale-input braking is effective",function()
 local speed=18
 for _=1,30 do speed=M.step(speed,0,0,0,true,.05,18).Speed;assert(speed>=0) end
 assert(speed==0)
end)
test("steering, bounded reverse and frame hitches preserve finite motion",function()
 local r=M.step(18,0,1,1,false,5,18);assert(r.Yaw>0 and math.abs(r.DX)+math.abs(r.DZ)<3)
 local speed=0;for _=1,100 do speed=M.step(speed,0,-1,0,false,.05,18).Speed end
 assert(math.abs(speed+18*.35)<1e-8)
end)
test("garage entry is a front-facing semicircle with vertical bounds",function()
 assert(M.inGarage(-35,12,8,-43,8,8,11))
 assert(not M.inGarage(-44,12,8,-43,8,8,11))
 assert(not M.inGarage(-31,12,8,-43,8,8,11))
 assert(not M.inGarage(-35,30,8,-43,8,8,11))
end)
print(string.format("%d permanent bike motion tests passed",count))
