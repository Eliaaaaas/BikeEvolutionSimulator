local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local function fixture()
 local data=modules.Profile.new();data.Cash=1e6
 local clock=100;local serial=0;local events={}
 local service={change=function(_,cb) local copy=modules.Profile.copy(data);if not cb(copy) then return false,"Rejected" end;assert(modules.Profile.validate(copy));data=copy;return true,nil end}
 local e=modules.EconomyController.new(service,function() return clock end,function() return 1 end,function() serial+=1;return "pet-"..serial end,function(_,event) table.insert(events,event) end)
 return e,function() return data end,function(dt) clock+=dt end,events
end
test("v1 migration preserves balances, inventory IDs and equips; v2 is idempotent",function()
 local raw=modules.Profile.new();raw.SchemaVersion=1;raw.ActiveVehicle=nil;raw.DiscoveredPets=nil
 raw.Energy=123.5;raw.Cash=321;raw.Rebirths=7;raw.Pets.uuid={SpeciesId=12,Variant="Golden"};raw.EquippedPets={"uuid"};raw.OwnedVehicles={1,7}
 local migrated=modules.Profile.migrate(raw);assert(migrated and modules.Profile.validate(migrated))
 assert(migrated.ActiveVehicle==1 and migrated.Energy==123.5 and migrated.Cash==321 and migrated.Rebirths==7)
 assert(migrated.Pets.uuid.Variant=="Golden" and migrated.EquippedPets[1]=="uuid" and migrated.DiscoveredPets[1]==12)
 assert(raw.SchemaVersion==1 and raw.ActiveVehicle==nil)
 local again=modules.Profile.migrate(migrated);assert(again.SchemaVersion==2 and again.Cash==321 and again~=migrated)
 raw.Energy=-1;assert(not modules.Profile.migrate(raw));raw.SchemaVersion=999;assert(not modules.Profile.migrate(raw))
end)
test("migration honors foreign locks and only commits through UpdateAsync",function()
 local raw=modules.Profile.new();raw.SchemaVersion=1;raw.ActiveVehicle=nil;raw.DiscoveredPets=nil
 local record={Data=raw,Lock={Id="old",Expires=500}}
 local store={UpdateAsync=function(_,_,cb) local result=cb(record);if result then record=result end;return result end}
 local backend=modules.Persistence.new(store,modules.Profile,modules.Config.Data,"new",function() return 100 end,function() end)
 assert(not backend:load("p"));assert(record.Data.SchemaVersion==1)
 record.Lock.Expires=99;assert(backend:load("p"));assert(record.Data.SchemaVersion==2 and record.Lock.Id=="new")
end)
test("vehicle prices and classes preserve all stable catalogue IDs",function()
 local prices={0,250,750,2000,5000,12000,25000,50000,100000,200000}
 for id,price in ipairs(prices) do assert(modules.Catalog.Vehicles[id].CashCost==price);assert(modules.Catalog.Vehicles[id].Class==(if id<=6 then "Bicycle" else "Moped")) end
 assert(#modules.Catalog.Vehicles==40)
end)
test("atomic purchase/equip, no world requirement, duplicate requests do not debit twice",function()
 local e,get=fixture();local before=get().Cash
 assert(e:handle("p",{Action="BuyVehicle",VehicleId=10,RequestId=1}));assert(get().Cash==before-200000)
 assert(not e:handle("p",{Action="BuyVehicle",VehicleId=10,RequestId=1}));assert(get().Cash==before-200000)
 assert(e:handle("p",{Action="EquipVehicle",VehicleId=10,RequestId=2}));assert(get().ActiveVehicle==10)
 assert(not e:handle("p",{Action="EquipVehicle",VehicleId=9,RequestId=3}));assert(get().ActiveVehicle==10)
end)
test("all egg probability boundaries sum exactly to 10000",function()
 for egg=1,3 do
  local counts={0,0,0,0}
  for roll=1,10000 do local species=modules.PetRules.roll(egg,roll);counts[(species-1)%4+1]+=1 end
  for i,weight in ipairs(modules.World1Content.Weights) do assert(counts[i]==weight) end
 end
 assert(not modules.PetRules.roll(1,0));assert(not modules.PetRules.roll(1,10001))
end)
test("hatch deducts cash exactly once, records index, equips three unique pets",function()
 local e,get,advance=fixture();local before=get().Cash
 for i=1,4 do assert(e:handle("p",{Action="Hatch",EggId=1,RequestId=i}));advance(1.1) end
 assert(get().Cash==before-400 and #get().DiscoveredPets==1)
 for i=1,3 do assert(e:handle("p",{Action="EquipPet",PetId="pet-"..i,RequestId=4+i})) end
 assert(not e:handle("p",{Action="EquipPet",PetId="pet-4",RequestId=8}))
 assert(#get().EquippedPets==3)
 assert(e:handle("p",{Action="UnequipPet",PetId="pet-2",RequestId=9}));assert(#get().EquippedPets==2)
end)
test("pet bonuses add excess over one and support Golden/Rainbow without schema redesign",function()
 local data=modules.Profile.new();data.Pets.a={SpeciesId=1,Variant="Normal"};data.Pets.b={SpeciesId=1,Variant="Golden"};data.Pets.c={SpeciesId=1,Variant="Rainbow"};data.EquippedPets={"a","b","c"};data.DiscoveredPets={1}
 assert(math.abs(modules.PetRules.bonus(data,"Energy")-1.7)<1e-10)
 assert(math.abs(modules.PetRules.bonus(data,"Cash")-1.35)<1e-10)
 assert(modules.World1Content.FusionWorlds.Golden==4 and modules.World1Content.FusionWorlds.Rainbow==5)
end)
test("economic protocol requires bounded IDs and request sequences, rejects spoofed money",function()
 local valid=modules.Protocol.validAction
 assert(valid({Version=1,Action="Hatch",EggId=3,RequestId=1}))
 assert(not valid({Version=1,Action="Hatch",EggId=3}))
 assert(not valid({Version=1,Action="BuyVehicle",VehicleId=11,RequestId=1}))
 assert(not valid({Version=1,Action="Hatch",EggId=3,RequestId=1,Cash=0}))
 assert(not valid({Version=1,Action="EquipPet",PetId=string.rep("x",65),RequestId=1}))
end)
test("bot ranks use progress and crossing timestamps; all tiers reward every place",function()
 local rules=modules.RaceRules
 assert(rules.position({Distance=100,Bots={{Distance=101},{Distance=99},{Distance=150}}})==3)
 assert(rules.position({Distance=800,FinishedAt=20,Bots={{Distance=800,FinishedAt=19},{Distance=800,FinishedAt=21},{Distance=799}}})==2)
 for _,tier in ipairs({"Easy","Medium","Hard"}) do
  local definition=modules.World1Content.Difficulties[tier];assert(#definition.Speeds==5 and #definition.Rewards==6)
  for place=1,6 do assert(definition.Rewards[place]>0);if place>1 then assert(definition.Rewards[place]<definition.Rewards[place-1]) end end
 end
end)
test("race payout receipt prevents repeat cash including retry with pet bonus",function()
 local data=modules.Profile.new();data.Pets.a={SpeciesId=12,Variant="Normal"};data.EquippedPets={"a"};data.DiscoveredPets={12}
 local state={Difficulty="Hard",Place=1,FinishedAt=10,RewardId="server-uuid"}
 local ok,amount=modules.RaceRules.pay(data,state);assert(ok and math.abs(amount-5280)<1e-8)
 local before=data.Cash;local second,repeatAmount=modules.RaceRules.pay(data,state);assert(second and repeatAmount==0 and data.Cash==before)
 state.RewardId="other";state.FinishedAt=nil;assert(not modules.RaceRules.pay(data,state));assert(data.Cash==before)
end)
test("v2 persist/reload keeps active bike, pets, discoveries and race receipt",function()
 local stored=nil
 local store={UpdateAsync=function(_,_,cb) local result=cb(stored);if result then stored=result end;return result end}
 local function backend(id) return modules.Persistence.new(store,modules.Profile,modules.Config.Data,id,function() return 100 end,function() end) end
 local a=backend("a");local data=a:load("p");data.OwnedVehicles={1,10};data.ActiveVehicle=10
 data.Pets.uuid={SpeciesId=12,Variant="Rainbow"};data.DiscoveredPets={12};data.EquippedPets={"uuid"};data.LastRaceReward="paid-race"
 assert(a:save("p",data,true));local loaded=backend("b"):load("p")
 assert(loaded.ActiveVehicle==10 and loaded.Pets.uuid.Variant=="Rainbow" and loaded.EquippedPets[1]=="uuid" and loaded.DiscoveredPets[1]==12 and loaded.LastRaceReward=="paid-race")
end)
test("insufficient cash, full inventory and hatch cooldown cannot debit or grant",function()
 local data=modules.Profile.new();local sequence=0;local now=1
 local service={change=function(_,cb) local copy=modules.Profile.copy(data);if not cb(copy) then return false,"Rejected" end;data=copy;return true,nil end}
 local e=modules.EconomyController.new(service,function() return now end,function() return 10000 end,function() sequence+=1;return "new"..sequence end,function() end)
 assert(not e:handle("p",{Action="BuyVehicle",VehicleId=2,RequestId=1}));assert(data.Cash==0 and #data.OwnedVehicles==1)
 assert(not e:handle("p",{Action="Hatch",EggId=1,RequestId=2}));assert(next(data.Pets)==nil and data.Cash==0)
 data.Cash=1e6;assert(not e:handle("p",{Action="Hatch",EggId=1,RequestId=3}));assert(data.Cash==1e6)
 now=3;for i=1,500 do data.Pets[tostring(i)]={SpeciesId=1,Variant="Normal"} end;data.DiscoveredPets={1}
 assert(not e:handle("p",{Action="Hatch",EggId=1,RequestId=4}));assert(data.Cash==1e6)
end)
test("equipped vehicle affects authoritative speed and unowned selection is rejected",function()
 local data=modules.Profile.new();data.OwnedVehicles={1,10};data.ActiveVehicle=10
 local c=modules.RaceController.new({profile=function() return data end,nearStart=function() return true end,begin=function() end,cleanup=function() end,log=function() end},function() return 100 end)
 assert(c:start("p","Hard"));assert(math.abs(c.States.p.Target-24*2.1)<1e-10)
 assert(#c.States.p.Bots==5 and c.States.p.Bots[1].Speed==55)
 c:remove("p");data.ActiveVehicle=9;assert(not c:start("p","Hard"))
end)
test("UI keeps small vehicle and pet multipliers distinguishable",function()
 assert(modules.Format.multiplier(1.06)=="1.06" and modules.Format.multiplier(1.12)=="1.12")
 assert(modules.Format.multiplier(1.05)=="1.05" and modules.Format.multiplier(1.5)=="1.5")
end)
test("equipped pets modify actual training commit and actual race payout",function()
 local data=modules.Profile.new();data.Rebirths=2;data.DiscoveredPets={1,2,3}
 for i=1,3 do data.Pets[tostring(i)]={SpeciesId=i,Variant="Normal"};table.insert(data.EquippedPets,tostring(i)) end
 local service={change=function(_,cb) local candidate=modules.Profile.copy(data);if not cb(candidate) then return false,"Rejected" end;assert(modules.Profile.validate(candidate));data=candidate;return true,nil end}
 local training=modules.TrainingController.new(service,function() return 100 end,function() return true end)
 assert(training:select("p",1));assert(training:impulse("p",true));assert(math.abs(data.Energy-3.26)<1e-9)
 assert(modules.RaceRules.pay(data,{Difficulty="Easy",Place=1,FinishedAt=100,RewardId="coupled"}))
 assert(math.abs(data.Cash-266)<1e-9 and math.abs(data.Energy-3.26)<1e-9)
end)
print(string.format("%d World-1 economy/migration tests passed",count))
