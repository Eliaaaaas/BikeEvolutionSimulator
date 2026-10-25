local count=0
local function test(name,callback)
 local ok,reason=pcall(callback);assert(ok,name..": "..tostring(reason));count+=1;print("PASS "..name)
end
test("central formatter suffixes, fractions, boundaries and huge balances",function()
 local f=modules.Format.number
 for _,pair in ipairs({{1500,"1.5K"},{250000,"250K"},{1e6,"1M"},{1e9,"1B"},{1e12,"1T"},{1.5,"1.5"},{999999,"1M"},{-1500,"-1.5K"},{0,"0"}}) do assert(f(pair[1])==pair[2],f(pair[1])) end
 assert(string.find(f(1e300),"e%+300"));assert(f(math.huge)=="—");assert(f(0/0)=="—")
end)
test("settings immediate session state and event deduplication",function()
 local s=modules.ClientState.new(true);assert(s.Collapsed and s.Animations and s.Volume==0.35)
 assert(modules.ClientState.setting(s,"Collapsed",false));assert(not s.Collapsed)
 assert(modules.ClientState.setting(s,"Volume",2));assert(s.Volume==1)
 assert(not modules.ClientState.setting(s,"Energy",999));assert(not modules.ClientState.setting(s,"Volume",0/0))
 assert(modules.ClientState.event(s,1));assert(not modules.ClientState.event(s,1));assert(not modules.ClientState.event(s,0));assert(modules.ClientState.event(s,2))
end)
test("progress and rebirth preview use current thresholds and permanent bonus",function()
 local s={Energy=2,Rebirths=0,SelectedTreadmill=2,ImpulseGain=2}
 local p=modules.Presentation.training(s);assert(p.Next==3 and p.Missing==2 and p.Ratio==0.5 and p.RebirthRequirement==3)
 s.Rebirths=3;assert(modules.Presentation.training(s).Ratio==1)
 s.Rebirths=0;s.Energy=1000;local r=modules.Presentation.rebirth(s);assert(r.Allowed and r.Multiplier==1 and r.NextMultiplier==1.5)
 s.Energy=0;assert(not modules.Presentation.rebirth(s).Allowed)
end)
test("starting Mountainbike stays free and owned in schema v1",function()
 local data=modules.Profile.new();assert(data.SchemaVersion==modules.Config.Data.SchemaVersion and table.find(data.OwnedVehicles,1))
 assert(modules.Catalog.Vehicles[1].Name=="Mountainbike" and modules.Catalog.Vehicles[1].CashCost==0)
end)
test("800-stud guide is finite, smooth and outside the main island",function()
 local course=modules.RaceCourse;assert(math.abs(course.Length-800)<0.001)
 local last=course.sample(0)
 for distance=1,800 do
  local p=course.sample(distance);assert(p.Z>=110 and p.Y==8.2)
  assert(math.abs(p.DX*p.DX+p.DZ*p.DZ-1)<1e-5)
  assert(math.sqrt((p.X-last.X)^2+(p.Z-last.Z)^2)<1.01);last=p
 end
 assert(course.sample(-100).X==course.sample(0).X)
 assert(course.sample(1e9).Z==course.sample(course.Length).Z)
end)
local function fixture()
 local now=1000;local data=modules.Profile.new();data.Energy=500;data.Cash=123
 local near,valid=true,true
 local events={};local spawned,restored,destroyed=0,0,0
 local adapter={profile=function() return data end,nearStart=function() return near end,
 begin=function(_,state) spawned+=1;state.Bike={};state.Original={Controls=true} end,
 valid=function() return valid end,move=function(_,state,p) state.LastPoint=p end,
 cleanup=function(_,state,reason) restored+=1;destroyed+=1;table.insert(events,reason) end,log=function() end}
 local c=modules.RaceController.new(adapter,function() return now end)
 return c,data,function(dt) now+=dt;c:tick() end,function(value) near=value end,function(value) valid=value end,events,adapter,
 function() return spawned,restored,destroyed end
end
test("race start needs race zone, profile and vehicle and forbids duplicate starts",function()
 local c,data,_,near,_,_,_,counts=fixture();near(false);assert(not c:start("p"));near(true)
 data.OwnedVehicles={};assert(not c:start("p"));data.OwnedVehicles={1}
 assert(c:start("p"));assert(not c:start("p"));local made=counts();assert(made==1)
end)
test("countdown, automatic acceleration, finish and safe restoration preserve energy and cash",function()
 local c,data,advance,_,_,events,_,counts=fixture();local energy,cash=data.Energy,data.Cash
 assert(c:start("p"));advance(1);assert(c.States.p.Distance==0 and c.States.p.Phase=="Countdown")
 for _=1,700 do advance(0.1) end
 assert(c.States.p==nil and events[1]=="Finished");local made,restored,destroyed=counts();assert(made==1 and restored==1 and destroyed==1)
 assert(data.Energy==energy and data.Cash==cash)
end)
test("death, disconnect and explicit abort clean once without payouts",function()
 for _,mode in ipairs({"Death","Disconnect","Cancel"}) do
  local c,data,advance,_,valid,events,_,counts=fixture();assert(c:start("p"))
  if mode=="Death" then valid(false);advance(0.1) elseif mode=="Disconnect" then c:remove("p") else c:finish("p","Aborted") end
  c:finish("p","Aborted");assert(c.States.p==nil and #events==1);assert(data.Energy==500 and data.Cash==123)
  local _,restored,destroyed=counts();assert(restored==1 and destroyed==1)
 end
end)
test("technical begin and movement failures restore and remove reserved races",function()
 for _,method in ipairs({"begin","move","valid"}) do
  local c,_,advance,_,_,_,adapter,counts=fixture();adapter[method]=function() error("injected fault") end
  local ok=c:start("p");if ok then advance(0.1) end
  assert(c.States.p==nil);local _,restored=counts();assert(restored==1)
 end
end)
test("independent concurrent racers and bounded authoritative speeds",function()
 local c,_,advance=fixture();assert(c:start("a"));assert(c:start("b"));advance(3.1)
 assert(c.States.a.Distance==c.States.b.Distance and c.States.a~=c.States.b)
 assert(modules.RaceController.speed(0)==24 and modules.RaceController.speed(1e300)==52)
 assert(not pcall(modules.RaceController.speed,0/0))
end)
test("race payloads never allow client speed/energy/waypoints",function()
 assert(modules.Protocol.validAction({Version=1,Action="StartRace"}));assert(modules.Protocol.validAction({Version=1,Action="AbortRace"}))
 assert(not modules.Protocol.validAction({Version=1,Action="StartRace",Speed=999}))
 assert(not modules.Protocol.validAction({Version=1,Action="StartRace",TreadmillId=1}))
end)
test("confirmed training/rebirth feedback emitted once only after committed changes",function()
 local data=modules.Profile.new();local events={};local now=1000
 local service={change=function(_,callback) if callback(data) then return true,nil else return false,"Rejected" end end}
 local c=modules.TrainingController.new(service,function() return now end,function() return true end,function(_,event) table.insert(events,event) end)
 assert(c:select("p",1));assert(c:impulse("p",true));assert(not c:impulse("p",true));assert(events[2].Kind=="Training" and events[2].Amount==1 and #events==2)
 data.Energy=1000;assert(c:rebirth("p"));assert(not c:rebirth("p"));assert(events[3].Kind=="Rebirth" and #events==3)
end)
test("abort cooldown and timeout bound stale race sessions",function()
 local c,_,advance,_,_,events=fixture();assert(c:start("p"));c:finish("p","Aborted")
 assert(not c:start("p"));advance(2.1);assert(c:start("p"));advance(151)
 assert(c.States.p==nil and events[2]=="Timeout")
end)
test("all session toggles change immediately without touching a profile",function()
 local state=modules.ClientState.new(false);local profile=modules.Profile.new()
 for _,name in ipairs({"Animations","Popups","Sound","Collapsed"}) do
  assert(modules.ClientState.setting(state,name,false));assert(state[name]==false)
  assert(modules.ClientState.setting(state,name,true));assert(state[name]==true)
 end
 assert(profile.Energy==0 and profile.Rebirths==0 and profile.SchemaVersion==modules.Config.Data.SchemaVersion)
end)
print(string.format("%d Phase 2.1 tests passed",count))
