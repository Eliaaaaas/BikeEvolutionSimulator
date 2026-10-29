local Sim=modules.RideSimulation
local Replay=modules.RideReconciliation
local cfg=modules.Config.Bike
local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local function input(overrides)
 local r={Throttle=0,Steer=0,Brake=false,JumpId=0};for k,v in pairs(overrides or {}) do r[k]=v end;return r
end
local flat={floor=function() return 8,1 end,block=function() return false end}
local function new() return Sim.new(0,8.05,0,0) end
test("V4.3 one genuine jump follows gravity and lands without repeated held jumps",function()
 local s=new();local peak=s.Y
 local sweep={floor=flat.floor,block=function(_,bottom,_,_,_,dy) if dy<0 then assert(bottom+dy>=8.2-1e-7) end;return false end}
 for _=1,120 do s=Sim.step(s,input({JumpId=1}),cfg.Tick,18,sweep);peak=math.max(peak,s.Y) end
 assert(peak>12 and peak<13.2 and s.Grounded and math.abs(s.Y-8.05)<1e-8 and s.VY==0)
end)
test("V4.3 airborne second jump is consumed without adding upward velocity",function()
 local s=Sim.step(new(),input({JumpId=1}),cfg.Tick,18,flat)
 s=Sim.step(s,input({JumpId=2}),cfg.Tick,18,flat)
 assert(s.VY<cfg.JumpVelocity-cfg.Gravity*cfg.Tick)
 for _=1,100 do s=Sim.step(s,input({JumpId=2}),cfg.Tick,18,flat) end
 assert(s.Grounded and s.JumpId==2)
end)
test("V4.3 jumping requires real contact and cannot launch from unsupported air",function()
 local air={floor=function() return nil,nil end,block=function() return false end}
 local s=Sim.step(new(),input({JumpId=1}),cfg.Tick,18,air)
 assert(not s.Grounded and s.VY<0 and s.Y<8.05)
end)
test("V4.3 smooth ramps and small lips are traversable without three-point contact",function()
 local scene={floor=function(_,_,z) return 8+math.clamp(-z/11,0,1)*1.3,1 end,block=function() return false end}
 local s=new()
 for _=1,90 do s=Sim.step(s,input({Throttle=1}),cfg.Tick,18,scene) end
 assert(s.Z< -11 and math.abs(s.Y-9.35)<1e-6 and s.Grounded)
end)
test("V4.3 body sweeps reject walls and upward jump collisions stop ascent",function()
 local wall={floor=flat.floor,block=function() return true end}
 local s=Sim.step(new(),input({Throttle=1}),cfg.Tick,18,wall)
 assert(s.Z==0 and s.Speed==0)
 s=Sim.step(s,input({JumpId=1}),cfg.Tick,18,wall);assert(s.VY<=0)
end)
test("V4.3 steering stops immediately and responds at low rolling speed",function()
 local s=new();s.Speed=2
 s=Sim.step(s,input({Throttle=1,Steer=1}),cfg.Tick,18,flat);local yaw=s.Yaw
 assert(yaw~=0)
 s=Sim.step(s,input({Throttle=1,Steer=0}),cfg.Tick,18,flat);assert(s.Yaw==yaw)
end)
test("V4.3 full bicycle footprint and grounded state govern training",function()
 local s=new();s.X=0;s.Z=0
 assert(Sim.onBelt(s,0,8.1,0,8,12))
 s.Z=5;assert(not Sim.onBelt(s,0,8.1,0,8,12))
 s.Z=0;s.Grounded=false;assert(not Sim.onBelt(s,0,8.1,0,8,12))
end)
test("V4.3 server acknowledgements replay unconfirmed inputs and reject stale epochs",function()
 local r=Replay.new();local s=new()
 local message={Epoch=1,Ack=1,Sequence=0,State=s,Mode="Manual",MaxSpeed=18}
 assert(Replay.accept(r,message,flat))
 local c=input({Throttle=1});Replay.command(r,1,c,18,flat);Replay.command(r,2,c,18,flat)
 local expected=r.State.Z;local one=Sim.command(s,c,18,flat)
 message={Epoch=1,Ack=2,Sequence=1,State=one,Mode="Manual",MaxSpeed=18}
 assert(Replay.accept(r,message,flat) and math.abs(r.State.Z-expected)<1e-8 and #r.Pending==1)
 assert(not Replay.accept(r,message,flat))
 message.Epoch=2;message.Ack=1;message.Sequence=2;message.State=new();assert(Replay.accept(r,message,flat) and #r.Pending==0)
 message.Epoch=1;message.Ack=99;assert(not Replay.accept(r,message,flat))
end)
test("V4.3 prediction memory is bounded and nonfinite authoritative states are rejected",function()
 local r=Replay.new();r.State=new()
 for n=1,200 do Replay.command(r,n,input(),18,flat) end
 assert(#r.Pending==cfg.PendingLimit)
 local bad=new();bad.Y=0/0
 assert(not Replay.accept(r,{Epoch=1,Ack=1,Sequence=1,State=bad,Mode="Manual",MaxSpeed=18},flat))
end)
print(string.format("%d V4.3 ride simulation and prediction tests passed",count))
