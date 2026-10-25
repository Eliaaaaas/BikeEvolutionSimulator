local Config, Catalog, Rules, Profile, Protocol, Persistence = modules.Config, modules.Catalog, modules.Rules, modules.Profile, modules.Protocol, modules.Persistence
local passed = 0
local function test(name, callback)
 local ok, message = pcall(callback)
 if not ok then error("FAIL " .. name .. ": " .. tostring(message)) end
 passed += 1
 print("PASS " .. name)
end
local function equal(actual, expected) assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected)) end

test("catalog cardinalities and world assignments", function()
 equal(#Catalog.Worlds, 8); equal(#Catalog.Vehicles, 40); equal(#Catalog.Treadmills, 40)
 equal(#Catalog.Eggs, 24); equal(#Catalog.Pets, 96)
 for world = 1, 8 do
  local count = 0
  for _, treadmill in ipairs(Catalog.Treadmills) do if treadmill.WorldId == world then count += 1 end end
  equal(count, 5)
 end
 for _, egg in ipairs(Catalog.Eggs) do
  equal(#egg.Species, 4)
  for _, species in ipairs(egg.Species) do equal(Catalog.Pets[species].EggId, egg.Id) end
 end
end)
test("all vehicle class boundaries", function()
 for id = 1, 40 do
  local expected = if id <= 6 then "Bicycle" elseif id <= 15 then "Moped" elseif id <= 27 then "Motorcycle" elseif id <= 34 then "Supersport" else "RaceMachine"
  equal(Catalog.Vehicles[id].Class, expected)
 end
end)
test("initial training and permanent rebirth multiplier", function()
 equal(Rules.trainingGain(0), 1); equal(Rules.trainingGain(1), 1.5); equal(Rules.trainingGain(2), 2)
 equal(Rules.rebirth(999, 0), nil)
 local result = Rules.rebirth(1000, 0)
 equal(result.Energy, 0); equal(result.Rebirths, 1)
 equal(Rules.trainingGain(result.Rebirths), 1.5)
end)
test("worlds use cash and reject owned or invalid IDs", function()
 assert(Rules.canBuyWorld(1000, 2, {1}))
 assert(not Rules.canBuyWorld(999, 2, {1}))
 assert(not Rules.canBuyWorld(10000, 2, {1, 2}))
 assert(not Rules.canBuyWorld(10000, 9, {1}))
 assert(not Rules.canBuyWorld(10000, 2.5, {1}))
 equal(Catalog.Worlds[8].Currency, "Cash")
end)
test("vehicles are independent of world progression", function()
 assert(Rules.canBuyVehicle(Catalog.Vehicles[40].CashCost, 40, {1}))
 assert(not Rules.canBuyVehicle(0, 40, {1}))
 assert(not Rules.canBuyVehicle(1e6, 40, {1,40}))
 assert(not Rules.canBuyVehicle(1e6, 41, {1}))
end)
test("normal golden rainbow fusion and identity requirements", function()
 local pets, ids = {}, {}
 for i = 1, 5 do
  ids[i] = tostring(i); pets[ids[i]] = {SpeciesId = 1, Variant = "Normal"}
 end
 equal(Rules.fusion(pets, ids).Variant, "Golden")
 equal(Rules.fusion(pets, {"1", "1", "1", "1", "1"}), nil)
 pets['5'].SpeciesId = 2; equal(Rules.fusion(pets, ids), nil)
 pets['5'].SpeciesId = 1; pets['5'].Variant = "Golden"; equal(Rules.fusion(pets, ids), nil)
 for i = 1, 3 do pets[tostring(i)].Variant = "Golden" end
 equal(Rules.fusion(pets, {"1", "2", "3"}).Variant, "Rainbow")
 equal(Rules.fusion(pets, {"1", "2"}), nil)
 for i = 1, 3 do pets[tostring(i)].Variant = "Rainbow" end
 equal(Rules.fusion(pets, {"1", "2", "3"}), nil)
end)
test("races preserve energy and declare three bot difficulties", function()
 equal(Rules.raceEnergy(123.5), 123.5)
 equal(table.concat(Config.RaceDifficulties, ","), "Easy,Medium,Hard")
end)
test("profile defaults, finite balances and schema rejection", function()
 local data = Profile.new(); assert(Profile.validate(data))
 equal(data.Energy, 0); equal(data.Cash, 0); equal(data.Rebirths, 0)
 for _, bad in ipairs({-1, math.huge, 0/0}) do
  data.Energy = bad; assert(not Profile.validate(data))
 end
 data = Profile.new(); data.SchemaVersion = 2; assert(not Profile.validate(data))
 data = Profile.new(); data.Rebirths = 0.5; assert(not Profile.validate(data))
 data = Profile.new(); data.OwnedWorlds = {1,1}; assert(not Profile.validate(data))
end)
test("three unique owned pet equip slots", function()
 local data = Profile.new()
 for i = 1, 4 do data.Pets[tostring(i)] = { SpeciesId = i, Variant = "Normal" } end
 data.EquippedPets = {"1", "2", "3"}; assert(Profile.validate(data))
 data.EquippedPets = {"1", "2", "3", "4"}; assert(not Profile.validate(data))
 data.EquippedPets = {"1", "1"}; assert(not Profile.validate(data))
 data.EquippedPets = {"missing"}; assert(not Profile.validate(data))
end)
test("profile copies do not alias inventory", function()
 local data = Profile.new(); data.Pets.a = {SpeciesId = 1, Variant = "Normal"}
 local copy = Profile.copy(data); copy.Pets.a.Variant = "Golden"; copy.OwnedWorlds[1] = 2
 equal(data.Pets.a.Variant, "Normal"); equal(data.OwnedWorlds[1], 1)
end)
test("remote request allowlist and HUD payload validation", function()
 assert(Protocol.validRequest({Version = 1}))
 assert(not Protocol.validRequest({Version = 1, Cash = 100}))
 assert(not Protocol.validRequest({Version = 2})); assert(not Protocol.validRequest("bad"))
 assert(Protocol.validSnapshot({Energy = 0, Cash = 0, Rebirths = 0}))
 assert(not Protocol.validSnapshot({Energy = math.huge, Cash = 0, Rebirths = 0}))
end)
local function fixture()
 local now = 1000
 local store = { records = {}, failures = 0, calls = 0 }
 function store:UpdateAsync(key, callback)
  self.calls += 1
  if self.failures > 0 then self.failures -= 1; error("simulated outage") end
  local result = callback(self.records[key])
  if result ~= nil then self.records[key] = result end
  return result
 end
 local function backend(id) return Persistence.new(store, Profile, Config.Data, id, function() return now end, function() end) end
 return store, backend, function(value) now = value end
end
test("new profile, lock, durable save and release", function()
 local store, backend = fixture(); local server = backend("a")
 local data = server:load("p"); assert(data)
 data.Cash = 123; assert(server:save("p", data, false))
 equal(store.records.p.Data.Cash, 123)
 assert(server:save("p", data, true)); equal(store.records.p.Lock, nil)
 equal(backend("b"):load("p").Cash, 123)
end)
test("concurrent server cannot load or overwrite active session", function()
 local store, backend = fixture(); local a, b = backend("a"), backend("b")
 local data = a:load("p"); equal(b:load("p"), nil)
 data.Cash = 999; assert(not b:save("p", data, false)); equal(store.records.p.Data.Cash, 0)
end)
test("expired lease takeover prevents stale writes", function()
 local store, backend, setTime = fixture(); local a, b = backend("a"), backend("b")
 local data = a:load("p"); setTime(1181)
 assert(not a:save("p", data, false)); assert(b:load("p"))
 assert(not a:save("p", data, true)); equal(store.records.p.Lock.Id, "b")
end)
test("bounded retry recovers transient failures", function()
 local store, backend = fixture(); store.failures = 2
 assert(backend("a"):load("p")); equal(store.calls, 3)
end)
test("failed load never creates replacement data", function()
 local store, backend = fixture(); store.failures = 3
 equal(backend("a"):load("p"), nil); equal(store.records.p, nil); equal(store.calls, 3)
end)
test("corrupt and future records remain untouched", function()
 local store, backend = fixture()
 local corrupt = {Data = {SchemaVersion = 99, Cash = 12345}}
 store.records.p = corrupt; equal(backend("a"):load("p"), nil); equal(store.records.p, corrupt)
end)
test("failed save retains last durable data", function()
 local store, backend = fixture(); local a = backend("a"); local data = a:load("p")
 data.Cash = 999; store.failures = 3; assert(not a:save("p", data, false))
 equal(store.records.p.Data.Cash, 0)
end)
test("invalid state cannot overwrite durable profile", function()
 local store, backend = fixture(); local a = backend("a"); local data = a:load("p")
 data.Cash = -1; assert(not a:save("p", data, false)); equal(store.records.p.Data.Cash, 0)
end)
test("UpdateAsync callback replay rechecks ownership", function()
 local store, backend = fixture(); local a = backend("a"); local data = a:load("p")
 local original = store.UpdateAsync
 function store:UpdateAsync(key, callback)
  callback(self.records[key]) -- Roblox may discard this optimistic result.
  self.records[key].Lock.Id = "other-server"
  return original(self, key, callback)
 end
 data.Cash = 500
 assert(not a:save("p", data, false))
 equal(store.records.p.Data.Cash, 0)
 equal(store.records.p.Lock.Id, "other-server")
end)
test("public snapshot contains only HUD counters", function()
 local snapshot = Profile.snapshot(Profile.new())
 local count = 0
 for _ in pairs(snapshot) do count += 1 end
 equal(count, 3); equal(snapshot.Pets, nil); equal(snapshot.Lock, nil)
end)
test("all treadmill strengths and requirement progression", function()
 for id = 1, 40 do
  local t = Catalog.Treadmills[id]
  equal(t.TrainingMultiplier, 2 ^ (id - 1)); equal(t.CashCost, 0)
  if id > 1 then
   equal(t.EnergyRequirement, 4 ^ (id - 2))
   -- Repeated multiplication and exponentiation may differ by an ULP.
   assert(math.abs(t.RebirthRequirement / (3 ^ (id - 2)) - 1) < 1e-14)
  end
 end
end)
test("treadmill world AND energy OR rebirth; rebirth revokes access", function()
 assert(Rules.canUseTreadmill(1, 0, 0, {1}))
 assert(Rules.canUseTreadmill(6, Catalog.Treadmills[6].EnergyRequirement, 0, {1,2}))
 assert(not Rules.canUseTreadmill(6, 1e100, 1e9, {1}))
 assert(Rules.canUseTreadmill(3, 4, 0, {1}))
 assert(Rules.canUseTreadmill(3, 0, 3, {1}))
 assert(not Rules.canUseTreadmill(3, 3, 2, {1}))
 local reborn = Rules.rebirth(1000, 0)
 assert(not Rules.canUseTreadmill(3, reborn.Energy, reborn.Rebirths, {1}))
 assert(not Rules.canUseTreadmill(41, 1e100, 1e9, {1}))
 assert(not Rules.canUseTreadmill(0/0, 0, 0, {1}))
 assert(not Rules.canUseTreadmill(1, math.huge, 0, {1}))
end)
test("large balances and training are finite and bounded", function()
 local n = modules.Numbers
 equal(n.multiply(1e300, 1e300), 1e300); equal(n.add(1e300, 1e300), 1e300)
 equal(n.multiply(0, 1e300), 0)
 equal(Rules.trainingGain(Config.Numbers.MaxRebirths, 1e300), 1e300)
 assert(not pcall(Rules.trainingGain, 1e300, 1))
 assert(not pcall(n.multiply, 0/0, 1)); assert(not pcall(n.add, math.huge, 1))
 local data = Profile.new(); data.Energy = Catalog.Treadmills[40].EnergyRequirement
 assert(Profile.validate(data)); assert(Rules.canUseTreadmill(40, data.Energy, 0, {1,8}))
 assert(not Rules.rebirth(1e300, Config.Numbers.MaxRebirths))
end)
test("catalog metadata stays pending and individual overrides are preserved", function()
 for _, entries in ipairs({Catalog.Vehicles, Catalog.Eggs, Catalog.Pets}) do
  for _, entry in ipairs(entries) do equal(entry.ContentStatus, "Pending"); equal(entry.Name, false) end
 end
 local entry = modules.CatalogMetadata.resolve({Name="Reviewed name", Rarity="Rare", Multiplier=2.5, Design={AssetId="rbxassetid://123"}})
 equal(entry.Name, "Reviewed name"); equal(entry.Multiplier, 2.5); equal(entry.Design.AssetId, "rbxassetid://123")
 equal(entry.Design.IconId, false)
 assert(not pcall(modules.CatalogMetadata.resolve, {Multiplier=math.huge}))
end)
test("release response lost after commit is idempotently retried", function()
 local store, backend = fixture(); local a = backend("a"); local data = a:load("p")
 local original = store.UpdateAsync; local once = true
 function store:UpdateAsync(key, callback)
  local result = original(self, key, callback)
  if once then once = false; error("response lost after commit") end
  return result
 end
 data.Cash = 321; assert(a:save("p", data, true))
 equal(store.records.p.Data.Cash, 321); equal(store.records.p.Lock, nil)
end)
test("disconnect recovery retains latest state until successful release", function()
 local store, backend, setTime = fixture(); local a = backend("a"); local data = a:load("p")
 data.Cash = 765; store.failures = 3
 local session = {Data=data, Backend=a, Expires=1180}; local now=1000; local logs={}
 assert(modules.SavePolicy.flush(session, "p", true, 1024, function() return now end,
  function() now += 2; setTime(now) end, function(event) table.insert(logs,event) end))
 equal(store.records.p.Data.Cash,765); equal(store.records.p.Lock,nil); equal(#logs,1)
end)
test("autosave outage retains session for next save", function()
 local store, backend = fixture(); local a=backend("a"); local data=a:load("p"); data.Cash=99
 local session={Data=data, Backend=a, Expires=1180}; store.failures=3
 local ok, reason=modules.SavePolicy.flush(session,"p",false,math.huge,function() return 1000 end,function() error("must not loop") end,function() end)
 assert(not ok); equal(reason,"DataStoreUnavailable"); equal(session.Data.Cash,99)
 assert(a:save("p",session.Data,false)); equal(store.records.p.Data.Cash,99)
end)
test("shutdown recovery stops at deadline without releasing unsaved data", function()
 local store, backend, setTime=fixture(); local a=backend("a"); local data=a:load("p"); data.Cash=90
 local now=1000; store.failures=100
 local ok,reason=modules.SavePolicy.flush({Data=data,Backend=a,Expires=1180},"p",true,1004,
  function() return now end,function() now+=2;setTime(now) end,function() end)
 assert(not ok); equal(reason,"DeadlineExceeded"); equal(now,1004)
 equal(store.records.p.Data.Cash,0); equal(store.records.p.Lock.Id,"a")
end)
test("recovery never retries a stolen lease", function()
 local store,backend=fixture(); local a=backend("a");local data=a:load("p")
 store.records.p.Lock.Id="b"
 local ok,reason=modules.SavePolicy.flush({Data=data,Backend=a,Expires=1180},"p",true,1024,
 function() return 1000 end,function() error("unexpected retry") end,function() end)
 assert(not ok);equal(reason,"SessionLost");equal(store.records.p.Lock.Id,"b")
end)
test("one numeric authority and exact rebirth boundary roundtrips", function()
 local n = modules.Numbers
 equal(Config.Numbers.MaxBalance, n.Max); equal(Config.Numbers.MaxRebirths, n.MaxRebirths)
 local store,backend=fixture()
 for i,value in ipairs({0,1,1e9,n.MaxRebirths-1,n.MaxRebirths}) do
  local a=backend("boundary-a"..i); local data=a:load(tostring(i));data.Rebirths=value
  assert(Profile.validate(data)); assert(n.validRebirth(value))
  assert(a:save(tostring(i),data,true))
  equal(backend("boundary-b"..i):load(tostring(i)).Rebirths,value)
  assert(Rules.trainingGain(value) < math.huge)
  assert(Rules.rebirthRequirement(value) < math.huge)
 end
 local result=Rules.rebirth(Rules.rebirthRequirement(n.MaxRebirths-1),n.MaxRebirths-1)
 equal(result.Rebirths,n.MaxRebirths)
 local data=Profile.new();data.Rebirths=result.Rebirths;assert(Profile.validate(data))
 equal(Rules.rebirth(1e300,n.MaxRebirths),nil)
end)
test("invalid rebirth values rejected by profile and every rule entry", function()
 for _,value in ipairs({-1,0.5,modules.Numbers.MaxRebirths+1,1e300,math.huge,0/0}) do
  local data=Profile.new();data.Rebirths=value
  assert(not Profile.validate(data));assert(not modules.Numbers.validRebirth(value))
  assert(not pcall(Rules.trainingGain,value));assert(not pcall(Rules.rebirthRequirement,value))
  equal(Rules.rebirth(1e300,value),nil)
  assert(not Rules.canUseTreadmill(1,0,value,{1}))
 end
end)
test("release acknowledgement survives an entire failed retry batch", function()
 local store,backend=fixture();local a=backend("a");local data=a:load("p");data.Cash=710
 local original=store.UpdateAsync;local remaining=3
 function store:UpdateAsync(key,callback)
  local result=original(self,key,callback)
  if remaining>0 then remaining-=1;error("committed but acknowledgement lost") end
  return result
 end
 assert(not a:save("p",data,true));equal(store.records.p.Data.Cash,710)
 assert(a:save("p",data,true));equal(store.records.p.Data.Cash,710)
 equal(backend("rejoin"):load("p").Cash,710)
end)
test("rejoin after lost release cannot be overwritten by old retry", function()
 local store,backend=fixture();local a=backend("a");local data=a:load("p");data.Cash=710
 local original=store.UpdateAsync;local remaining=3
 function store:UpdateAsync(key,callback)
  local result=original(self,key,callback)
  if remaining>0 then remaining-=1;error("lost acknowledgement") end
  return result
 end
 assert(not a:save("p",data,true))
 local b=backend("b");local fresh=b:load("p");fresh.Cash=999;assert(b:save("p",fresh,false))
 assert(not a:save("p",data,true));equal(store.records.p.Data.Cash,999);equal(store.records.p.Lock.Id,"b")
end)
test("disconnect recovery observes a shutdown deadline set during retry", function()
 local store,backend,setTime=fixture();local a=backend("a");local data=a:load("p")
 local now,deadline=1000,math.huge;store.failures=100
 local ok,reason=modules.SavePolicy.flush({Data=data,Backend=a,Expires=1180},"p",true,function() return deadline end,
  function() return now end,function() deadline=1003;now+=2;setTime(now) end,function() end)
 assert(not ok);equal(reason,"DeadlineExceeded");equal(now,1004)
end)
print(string.format("%d rule/persistence tests passed", passed))
