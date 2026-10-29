local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local P=modules.Profile;local Premium=modules.PremiumRules;local Pet=modules.PetRules

test("V4.4 schema 2 migration preserves counters, vehicle selection and independent inventory",function()
 local p=P.new();p.SchemaVersion=2;p.Boosts=nil;p.Receipts=nil;p.Energy=1e18;p.Cash=54321;p.Rebirths=9
 p.Pets.a={SpeciesId=1,Variant="Rainbow"};p.EquippedPets={"a"};p.DiscoveredPets={1};p.OwnedVehicles={1,7};p.ActiveVehicle=7
 local q=P.migrate(p);assert(q and P.validate(q));assert(q.Energy==p.Energy and q.Cash==p.Cash and q.Rebirths==9 and q.ActiveVehicle==7)
 assert(q.Pets.a.Variant=="Rainbow" and q.EquippedPets[1]=="a" and q.Pets~=p.Pets and p.SchemaVersion==2 and q.Boosts.Energy==0 and not next(q.Receipts))
 p.Cash=-1;assert(not P.migrate(p))
end)
test("V4.4 malformed boosts receipts future schemas and unknown exclusive pets fail closed",function()
 local p=P.new();p.Boosts.Energy=math.huge;assert(not P.validate(p));p.Boosts.Energy=0/0;assert(not P.validate(p))
 p=P.new();p.Receipts.bad=-1;assert(not P.validate(p));p=P.new();p.SchemaVersion=4;assert(not P.migrate(p))
 p=P.new();p.Pets.x={SpeciesId=0,ExclusiveId="Unknown",Variant="Normal"};assert(not P.validate(p))
end)
test("V4.4 developer product grants mark receipt in same candidate and do not duplicate cash",function()
 local p=P.new();assert(Premium.grant(p,"receipt-a",101,{Cash=5000},"unused"));assert(p.Cash==5000 and p.Receipts['receipt-a']==101)
 assert(Premium.grant(p,"receipt-a",101,{Cash=5000},"unused"));assert(p.Cash==5000)
 local full=P.new();full.Cash=1e300;assert(not Premium.grant(full,"cap",101,{Cash=5000},"id") and not full.Receipts.cap)
 assert(not Premium.grant(p,"receipt-a",102,{Cash=5000},"unused"));assert(P.validate(p))
end)
test("V4.4 receipts stop at capacity without evicting previously processed IDs",function()
 local p=P.new();for i=1,modules.PremiumConfig.ReceiptLimit do p.Receipts[tostring(i)]=123 end
 assert(not Premium.grant(p,"new",123,{Cash=5000},"unused") and p.Cash==0)
 assert(Premium.grant(p,"1",123,{Cash=5000},"unused") and p.Cash==0)
end)
test("V4.4 potions extend active seconds with one multiplier and survive copy/reload",function()
 local p=P.new();local def={Boost="Energy",Seconds=300}
 assert(Premium.grant(p,"one",1,def,"id"));assert(Premium.grant(p,"two",1,def,"id"))
 assert(p.Boosts.Energy==600 and Premium.bonus(p,"Energy")==2 and Premium.bonus(p,"Energy",true)==4)
 local copy=P.migrate(P.copy(p));assert(copy and copy.Boosts.Energy==600 and copy.Receipts.one==1)
 assert(Premium.bonus(copy,"Cash")==1);copy.Boosts.Energy=0;assert(Premium.bonus(copy,"Energy")==1)
end)
test("V4.4 exclusive pets use separate species namespace and work with equip best",function()
 local p=P.new();assert(Premium.grant(p,"fox",41,{ExclusiveId="Sunfox"},"fox-id"))
 assert(p.Pets['fox-id'].ExclusiveId=="Sunfox" and p.EquippedPets[1]=="fox-id" and P.validate(p))
 p.Pets.weak={SpeciesId=1,Variant="Normal"};p.Pets.rainbow={SpeciesId=12,Variant="Rainbow"};p.DiscoveredPets={1,12}
 local best=Pet.best(p);assert(best[1]=="rainbow" and best[2]=="fox-id" and #best==3)
 local copy=P.migrate(P.copy(p));assert(copy and copy.Pets['fox-id'].ExclusiveId=="Sunfox")
 assert(#modules.Catalog.Pets==96 and #modules.Catalog.Eggs==24 and modules.Config.Rules.EquipSlots==3)
end)
test("V4.4 cash and training apply pets pass potion once and retain rebirth multiplier",function()
 local p=P.new();p.Rebirths=2;p.Pets.x={SpeciesId=1,Variant="Golden"};p.DiscoveredPets={1};p.EquippedPets={"x"};p.Boosts.Energy=20;p.Boosts.Cash=20
 local gain=modules.Rules.trainingGain(p.Rebirths,4)*Pet.bonus(p,"Energy")*Premium.bonus(p,"Energy",true)
 assert(math.abs(gain-38.4)<1e-8)
 local state={Difficulty="Easy",FinishedAt=1,Place=1,WorldId=1,CashPass=true}
 assert(math.abs(modules.RaceRules.reward(p,state)-880)<1e-8)
end)
test("V4.4 thresholds apply fourfold difficulty once and baseline remains reachable",function()
 local t=modules.Catalog.Treadmills;local seconds=0
 for i=2,40 do seconds+=(t[i].EnergyRequirement-t[i-1].EnergyRequirement)/t[i-1].TrainingMultiplier end
 assert(seconds/3600>9 and seconds/3600<10 and t[2].EnergyRequirement==84 and t[5].EnergyRequirement==2688)
 assert(t[40].EnergyRequirement<1e16 and modules.Numbers.valid(t[40].EnergyRequirement))
 assert(modules.Rules.rebirthRequirement(0)==1000 and modules.Rules.rebirthRequirement(1)==2000 and modules.Rules.rebirthRequirement(2)==12000)
end)
test("V4.4 island speed is bounded, energy-sensitive, vehicle-sensitive and slow mode isolated",function()
 local speed=modules.Progression.islandSpeed
 assert(speed(0,1,false)==18 and speed(1e8,1,false)>18 and speed(1e8,2.1,false)>speed(1e8,1,false))
 assert(speed(1e300,2.1,false)<=modules.Config.Bike.MaxSpeed and speed(1e300,2.1,true)==12)
 assert(speed(0/0,1,false)==18)
end)
test("V4.4 navigation issues only bounded inputs and no artificial jump or tap bonuses",function()
 local s=modules.RideSimulation.new(0,8.05,0,0)
 local input,d=modules.AutoNavigation.input(s,{X=0,Z=-20})
 assert(input.Throttle>0 and input.Steer==0 and d==20 and input.JumpId==s.JumpId and not input.Position and not input.Energy)
 local path=modules.AutoNavigation.path(s,{X=-54,Z=-51});assert(#path>=3 and path[#path].Z==-51)
end)
test("V4.4 automation and premium intents reject forged reward speed and arbitrary modes",function()
 local valid=modules.Protocol.validAction
 assert(valid({Version=1,Action="Automation",Setting="AutoTrain",Enabled=true}))
 assert(valid({Version=1,Action="Automation",Setting="AutoRace",Enabled=true,Difficulty="Hard"}))
 assert(not valid({Version=1,Action="Automation",Setting="Energy",Enabled=true}))
 assert(not valid({Version=1,Action="Automation",Setting="SlowMode",Enabled=true,Speed=1000}))
 assert(not valid({Version=1,Action="Premium",Offer="Small",Cash=5000}))
 assert(not Premium.product(0) and not Premium.product(999999))
 for _,group in ipairs({modules.PremiumConfig.Passes,modules.PremiumConfig.Products}) do for _,offer in pairs(group) do assert(offer.Id==0) end end
end)
test("V4.4 future race worlds have declared lengths without fabricated playable maps",function()
 for id,length in ipairs({800,1100,1400,1800,2200,2800,3500,4500}) do
  local world=modules.World1Content.RaceWorlds[id];assert(world.Length==length and world.Playable==(id==1))
 end
 assert(modules.RaceRules.reward(P.new(),{WorldId=2,Difficulty="Easy",Place=1,FinishedAt=1})==0)
end)
test("V4.4 duplicate or fractional Roblox product IDs fail registry validation",function()
 assert(Premium.registryValid(modules.PremiumConfig))
 assert(not Premium.registryValid({Products={a={Id=42},b={Id=42}},Passes={}}))
 assert(not Premium.registryValid({Products={a={Id=1.5}},Passes={}}))
 local p=P.new();assert(Premium.grant(p,"prism",99,{ExclusiveId="PrismRay"},"ray"));assert(P.validate(p) and Pet.stats(p.Pets.ray).Cash==3.2)
end)
print(count.." V4.4 pure regression tests passed")
