local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local function snapshot(revision,inventory)
 return {Revision=revision,InventoryRevision=inventory,Energy=revision,Pets={},EquippedPets={},OwnedVehicles={1},DiscoveredPets={}}
end
test("late full snapshots cannot roll back a newer profile revision",function()
 local current=snapshot(5,2)
 assert(not modules.ClientState.snapshot(current,snapshot(4,2)))
 local next=modules.ClientState.snapshot(current,snapshot(6,2));assert(next.Energy==6 and current.Energy==5)
end)
test("partial snapshots reuse inventory only at the matching inventory revision",function()
 local current=snapshot(5,2);current.Pets.pet={SpeciesId=1}
 local partial={Revision=6,InventoryRevision=2,Energy=6}
 local merged=modules.ClientState.snapshot(current,partial)
 assert(merged and merged.Pets.pet.SpeciesId==1 and partial.Pets==nil)
 partial.InventoryRevision=3;assert(not modules.ClientState.snapshot(current,partial))
 assert(not modules.ClientState.snapshot(nil,partial))
 assert(not modules.ClientState.snapshot(current,{Revision=0/0}))
end)
test("invalid event sequence and infinite settings cannot poison client state",function()
 local state=modules.ClientState.new(false)
 for _,value in ipairs({math.huge,-math.huge,0/0,-1,1.5,9007199254740992}) do
  assert(not modules.ClientState.event(state,value));assert(state.LastEvent==0)
 end
 assert(not modules.ClientState.setting(state,"Volume",math.huge));assert(state.Volume==0.35)
 assert(not modules.ClientState.setting(state,"Volume",-math.huge));assert(modules.ClientState.event(state,1))
end)
test("race payout at currency cap reports actual credit and still consumes receipt",function()
 local data=modules.Profile.new();data.Cash=modules.Numbers.Max
 local state={WorldId=1,Difficulty="Hard",Place=1,FinishedAt=20,RewardId="cap"}
 local ok,amount=modules.RaceRules.pay(data,state)
 assert(ok and amount==0 and data.Cash==modules.Numbers.Max and data.LastRaceReward=="cap")
 local again,duplicate=modules.RaceRules.pay(data,state);assert(again and duplicate==0)
end)
local function raceFixture()
 local now=100;local profile=modules.Profile.new();local moved=0
 local controller=modules.RaceController.new({profile=function() return profile end,nearStart=function() return true end,begin=function() end,valid=function() return true end,move=function() moved+=1 end,cleanup=function() end,log=function() end},function() return now end)
 return controller,profile,function(delta) now+=delta;controller:tick() end
end
test("GO boundary excludes all pre-countdown time for player and bots",function()
 local controller,_,advance=raceFixture();assert(controller:start("p","Easy"))
 advance(2.98);assert(controller.States.p.Distance==0 and controller.States.p.Bots[1].Distance==0)
 advance(0.04)
 local state=controller.States.p
 assert(math.abs(state.Bots[1].Distance-22*0.02)<1e-8)
 assert(state.Distance>0 and state.Distance<0.01)
end)
test("race rejects invalid numeric energy without reserving a state",function()
 local controller,profile=raceFixture()
 for _,energy in ipairs({math.huge,-1,0/0,1e301}) do profile.Energy=energy;assert(not controller:start("p","Hard"));assert(not controller.States.p) end
end)
test("server stalls never grant unbounded race progress",function()
 local controller,_,advance=raceFixture();assert(controller:start("p","Easy"));advance(15)
 local state=controller.States.p;assert(state.Distance<=1 and state.Bots[1].Distance<=22*0.25)
end)
test("RNG and GUID failures cannot debit cash, grant pets or emit rewards",function()
 for _,mode in ipairs({"randomError","guidError","badRoll","badGuid"}) do
  local data=modules.Profile.new();data.Cash=1000;local events=0;local calls=0
  local service={change=function(_,cb) calls+=1;return cb(data) end}
  local economy=modules.EconomyController.new(service,function() return 100 end,function()
   if mode=="randomError" then error("rng unavailable") end
   return if mode=="badRoll" then 0/0 else 1
  end,function()
   if mode=="guidError" then error("guid unavailable") end
   return if mode=="badGuid" then "" else "guid"
  end,function() events+=1 end)
  local ok,reason=economy:handle("p",{Action="Hatch",EggId=1,RequestId=1})
  assert(not ok and reason=="ServiceUnavailable" and data.Cash==1000 and next(data.Pets)==nil and events==0 and calls==0)
 end
end)
test("failed profile commit never emits a hatch or spends persisted cash",function()
 local data=modules.Profile.new();data.Cash=1000;local events=0
 local economy=modules.EconomyController.new({change=function(_,cb) local candidate=modules.Profile.copy(data);assert(cb(candidate));return false,"Saving" end},function() return 100 end,function() return 1 end,function() return "guid" end,function() events+=1 end)
 local ok,reason=economy:handle("p",{Action="Hatch",EggId=1,RequestId=1})
 assert(not ok and reason=="Saving" and events==0 and data.Cash==1000 and next(data.Pets)==nil)
end)
test("invalid economy sequences cannot poison subsequent legitimate requests",function()
 local events=0
 local economy=modules.EconomyController.new({change=function() return true end},function() return 100 end,function() return 1 end,function() return "guid" end,function() events+=1 end)
 for _,request in ipairs({math.huge,0/0,-1,0,1.2,9007199254740992}) do assert(not economy:handle("p",{Action="EquipVehicle",VehicleId=1,RequestId=request})) end
 assert(economy.Requests.p==nil)
 assert(economy:handle("p",{Action="EquipVehicle",VehicleId=1,RequestId=1}));assert(events==1)
end)
test("race snapshots cannot travel backwards within the same data revision",function()
 local current=snapshot(5,2);current.SnapshotId=20
 local late=snapshot(5,2);late.SnapshotId=19
 assert(not modules.ClientState.snapshot(current,late))
 late.SnapshotId=20;assert(not modules.ClientState.snapshot(current,late))
 late.SnapshotId=21;assert(modules.ClientState.snapshot(current,late))
 late.SnapshotId=math.huge;assert(not modules.ClientState.snapshot(current,late))
end)
test("transient reward failures retry without duplicate finish or payout",function()
 local now=100;local calls,cleanups,logs=0,0,0
 local controller=modules.RaceController.new({profile=function() return modules.Profile.new() end,nearStart=function() return true end,begin=function() end,valid=function() return true end,move=function() end,
 reward=function() calls+=1;if calls==1 then error("transient") elseif calls==2 then return false,0 end;return true,200 end,
 cleanup=function(_,state,reason) cleanups+=1;assert(reason=="Finished" and state.Reward==200) end,log=function() logs+=1 end},function() return now end)
 assert(controller:start("p","Easy"));local state=controller.States.p;state.FinishedAt=now;state.Distance=800;state.Place=1
 for _=1,8 do now+=0.25;controller:tick() end
 assert(calls==3 and cleanups==1 and logs==1 and controller.States.p==nil)
 now+=1;controller:tick();assert(calls==3 and cleanups==1)
end)
print(string.format("%d World-1 hardening tests passed",count))
