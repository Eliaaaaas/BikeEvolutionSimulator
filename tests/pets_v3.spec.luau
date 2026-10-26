local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local function fixtureV3()
 local data=modules.Profile.new();data.Cash=1e6
 local now,serial,sequence,roll=100,0,0,1;local events={}
 local service={change=function(_,cb) local candidate=modules.Profile.copy(data);if not cb(candidate) then return false,"Rejected" end;assert(modules.Profile.validate(candidate));data=candidate;return true end}
 local economy=modules.EconomyController.new(service,function() return now end,function() return roll end,function() serial+=1;return "hatched-"..serial end,function(_,event) table.insert(events,event) end)
 local function action(kind,fields)
  sequence+=1;local payload=fields or {};payload.RequestId=sequence;payload.Action=kind
  local ok,reason=economy:handle("p",payload);now+=1.1;return ok,reason
 end
 return action,function() return data end,function(id,species,variant)
  data.Pets[id]={SpeciesId=species,Variant=variant or "Normal"}
  if not table.find(data.DiscoveredPets,species) then table.insert(data.DiscoveredPets,species) end
 end,function(value) roll=value end,economy,events
end
test("first, second and third genuine hatches fill three distinct slots atomically",function()
 local action,get=fixtureV3()
 for i=1,3 do
  assert(action("Hatch",{EggId=1}));local data=get()
  assert(#data.EquippedPets==i and data.EquippedPets[i]=="hatched-"..i)
  assert(math.abs(modules.PetRules.bonus(data,"Energy")-(1+.1*i))<1e-9)
  assert(math.abs(modules.PetRules.bonus(data,"Cash")-(1+.05*i))<1e-9)
 end
 assert(get().Cash==1e6-300)
end)
test("full slots keep current pets even when a much stronger pet hatches",function()
 local action,get,_,setRoll=fixtureV3()
 for _=1,3 do assert(action("Hatch",{EggId=1})) end
 local before=table.clone(get().EquippedPets);setRoll(10000)
 assert(action("Hatch",{EggId=3}));assert(get().Pets['hatched-4'].SpeciesId==12)
 for i,id in ipairs(before) do assert(get().EquippedPets[i]==id) end
end)
test("Unequip All is persistent state; only a new hatch fills one empty slot",function()
 local action,get,seed=fixtureV3()
 assert(action("Hatch",{EggId=1}));assert(action("UnequipAll"));assert(#get().EquippedPets==0)
 seed("existing-strong",12,"Rainbow")
 assert(#get().EquippedPets==0 and modules.PetRules.bonus(get(),"Energy")==1)
 assert(action("Hatch",{EggId=1}));assert(#get().EquippedPets==1 and get().EquippedPets[1]=="hatched-2")
 assert(not table.find(get().EquippedPets,"existing-strong"))
end)
test("Equip Best ranks balanced Energy and Cash bonuses and replaces weaker equips",function()
 local action,get,seed=fixtureV3()
 seed("weak",1);seed("energy",4);seed("cash",9);seed("strongest",12);seed("runner",8)
 assert(action("EquipPet",{PetId="weak"}));assert(action("EquipBest"))
 local ids=get().EquippedPets
 assert(#ids==3 and ids[1]=="strongest" and ids[2]=="runner" and ids[3]=="energy")
 assert(not table.find(ids,"weak"))
 assert(math.abs(modules.PetRules.bonus(get(),"Energy")-4.2)<1e-9)
 assert(math.abs(modules.PetRules.bonus(get(),"Cash")-3.15)<1e-9)
 local stats=modules.PetRules.stats({SpeciesId=9,Variant="Normal"})
 assert(math.abs(stats.Score-.35)<1e-9)
 local inventoryCount=0;for _ in pairs(get().Pets) do inventoryCount+=1 end;assert(inventoryCount==5)
end)
test("Golden and Rainbow score the existing excess-bonus variant formula",function()
 local action,get,seed=fixtureV3()
 seed("normal",4);seed("golden",4,"Golden");seed("rainbow",4,"Rainbow");seed("bestNormal",12)
 assert(action("EquipBest"));local ids=get().EquippedPets
 assert(ids[1]=="rainbow" and ids[2]=="bestNormal" and ids[3]=="golden")
 assert(math.abs(modules.PetRules.bonus(get(),"Energy")-6.2)<1e-9)
 assert(math.abs(modules.PetRules.bonus(get(),"Cash")-4)<1e-9)
end)
test("identical pets are distinct instances; tie breaking preserves current equips",function()
 local action,get,seed=fixtureV3()
 for _,id in ipairs({"a","b","c","z"}) do seed(id,4) end
 assert(action("EquipPet",{PetId="z"}));assert(action("EquipBest"))
 assert(table.concat(get().EquippedPets,",")=="z,a,b")
 assert(action("EquipBest"));assert(table.concat(get().EquippedPets,",")=="z,a,b")
 assert(action("EquipBest"));assert(table.concat(get().EquippedPets,",")=="z,a,b")
end)
test("unknown, missing, consumed and pending-catalogue pets cannot be newly equipped",function()
 local action,get,seed=fixtureV3()
 seed("pending",96);seed("owned",1)
 assert(not action("EquipPet",{PetId="pending"}));assert(not action("EquipPet",{PetId="missing"}))
 assert(action("EquipBest"));assert(#get().EquippedPets==1 and get().EquippedPets[1]=="owned")
 get().Pets.owned=nil;get().EquippedPets={}
 assert(not action("EquipPet",{PetId="owned"}));assert(action("EquipBest"));assert(#get().EquippedPets==0)
end)
test("Equip Best handles empty inventory and does not become an always-on mode",function()
 local action,get,seed=fixtureV3()
 assert(action("EquipBest"));assert(#get().EquippedPets==0)
 seed("old",1);assert(action("EquipBest"));seed("new-strong",12)
 assert(#get().EquippedPets==1 and get().EquippedPets[1]=="old")
 assert(action("EquipBest"));assert(get().EquippedPets[1]=="new-strong")
end)
test("new protocol intents reject payload-selected pets, bonuses and replayed requests",function()
 for _,kind in ipairs({"EquipBest","UnequipAll"}) do
  assert(modules.Protocol.validAction({Version=1,Action=kind,RequestId=1}))
  assert(not modules.Protocol.validAction({Version=1,Action=kind}))
  assert(not modules.Protocol.validAction({Version=1,Action=kind,RequestId=1,PetId="stolen"}))
  assert(not modules.Protocol.validAction({Version=1,Action=kind,RequestId=1,Score=1e9}))
 end
 local action,get,seed,_,economy=fixtureV3();seed("a",1)
 assert(action("EquipBest"));assert(not economy:handle("p",{Action="UnequipAll",RequestId=1}));assert(#get().EquippedPets==1)
end)
test("save/reload preserves instance IDs, best equips, bonuses and explicit unequip",function()
 local action,get,seed=fixtureV3();seed("a",1);seed("g",4,"Golden");seed("r",12,"Rainbow");assert(action("EquipBest"))
 local store=modules.StudioStore.new()
 local function backend(id) return modules.Persistence.new(store,modules.Profile,modules.Config.Data,id,function() return 100 end,function() end) end
 local a=backend("a");assert(a:load("p"));assert(a:save("p",get(),true))
 local b=backend("b");local loaded=b:load("p")
 assert(table.concat(loaded.EquippedPets,",")==table.concat(get().EquippedPets,","))
 assert(modules.PetRules.bonus(loaded,"Energy")==modules.PetRules.bonus(get(),"Energy"))
 assert(modules.PetRules.bonus(loaded,"Cash")==modules.PetRules.bonus(get(),"Cash"))
 loaded.EquippedPets={};assert(b:save("p",loaded,true));local empty=backend("c"):load("p")
 assert(#empty.EquippedPets==0 and empty.Pets.r.Variant=="Rainbow")
end)
local function fusionProfile(variant,count)
 local data=modules.Profile.new();data.OwnedWorlds={1,4,5};data.DiscoveredPets={1,2}
 local ids={}
 for i=1,count do local id="ingredient-"..i;data.Pets[id]={SpeciesId=1,Variant=variant};table.insert(ids,id) end
 data.Pets.other={SpeciesId=2,Variant="Normal"};data.EquippedPets={"other",ids[1],ids[2]}
 return data,ids
end
test("future Golden and Rainbow fusion replaces consumed slots once and preserves others",function()
 for _,variant in ipairs({"Normal","Golden"}) do
  local data,ids=fusionProfile(variant,if variant=="Normal" then 5 else 3)
  assert(modules.PetRules.fuse(data,ids,"fused"));assert(modules.Profile.validate(data))
  assert(table.concat(data.EquippedPets,",")=="other,fused")
  assert(data.Pets.fused.Variant==(if variant=="Normal" then "Golden" else "Rainbow"))
  for _,id in ipairs(ids) do assert(data.Pets[id]==nil) end
 end
end)
test("fusion of unequipped ingredients does not refill manual empty slots or accept locked worlds",function()
 local data,ids=fusionProfile("Normal",5);data.EquippedPets={};data.OwnedWorlds={1}
 assert(not modules.PetRules.fuse(data,ids,"fused"));assert(data.Pets[ids[1]])
 data.OwnedWorlds={1,4};assert(not modules.PetRules.fuse(data,ids,ids[1]))
 local duplicate=table.clone(ids);duplicate[2]=duplicate[1];assert(not modules.PetRules.fuse(data,duplicate,"fused"))
 assert(modules.PetRules.fuse(data,ids,"fused"));assert(#data.EquippedPets==0 and modules.Profile.validate(data))
end)
test("failed equip commit cannot mutate persisted equips or emit success",function()
 local data=modules.Profile.new();data.Pets.a={SpeciesId=1,Variant="Normal"};data.DiscoveredPets={1};local events=0
 local economy=modules.EconomyController.new({change=function(_,cb) local candidate=modules.Profile.copy(data);assert(cb(candidate));return false,"Saving" end},function() return 100 end,function() return 1 end,function() return "new" end,function() events+=1 end)
 assert(not economy:handle("p",{Action="EquipBest",RequestId=1}));assert(#data.EquippedPets==0 and events==0)
end)
test("balanced score can prefer lower Energy when Cash makes the pet stronger overall",function()
 local action,get,seed=fixtureV3()
 seed("top",12,"Rainbow");seed("second",12,"Golden")
 seed("more-energy",3,"Golden");seed("more-cash",10,"Normal")
 local energy=modules.PetRules.stats(get().Pets['more-energy']);local cash=modules.PetRules.stats(get().Pets['more-cash'])
 assert(cash.Energy<energy.Energy and cash.Cash>energy.Cash and cash.Score>energy.Score)
 assert(action("EquipBest"));assert(table.find(get().EquippedPets,"more-cash") and not table.find(get().EquippedPets,"more-energy"))
end)
print(string.format("%d V3 pet equip tests passed",count))
