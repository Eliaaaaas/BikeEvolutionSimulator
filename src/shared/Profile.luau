--!strict
local Config = require(script.Parent.Config)
local Numbers = require(script.Parent.Numbers)
local Profile = {}
export type Snapshot = { Energy: number, Cash: number, Rebirths: number }
export type Pet = { SpeciesId: number, Variant: string }
export type Data = {
 SchemaVersion: number, Energy: number, Cash: number, Rebirths: number,
 OwnedWorlds: {number}, OwnedVehicles: {number}, Pets: {[string]: Pet}, EquippedPets: {string}, ActiveVehicle: number, DiscoveredPets: {number},
}
local function numberIn(value: any, maximum: number, integer: boolean)
 return type(value) == "number" and value == value and value >= 0 and value <= maximum and (not integer or value % 1 == 0)
end
local function arrayValid(value: any, maximum: number, predicate: (any) -> boolean)
 if type(value) ~= "table" or #value > maximum then return false end
 local count, seen = 0, {}
 for key, item in pairs(value) do
  count += 1
  if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > #value or seen[item] or not predicate(item) then return false end
  seen[item] = true
 end
 return count == #value
end
function Profile.new(): Data
 return { SchemaVersion = Config.Data.SchemaVersion, Energy = 0, Cash = 0, Rebirths = 0,
  OwnedWorlds = {1}, OwnedVehicles = {1}, Pets = {}, EquippedPets = {}, ActiveVehicle = 1, DiscoveredPets = {} }
end
local function validate(data: any, legacy: boolean): boolean
 if type(data) ~= "table" or data.SchemaVersion ~= (if legacy then 1 else Config.Data.SchemaVersion) then return false end
 if not numberIn(data.Energy, Config.Numbers.MaxBalance, false) or not numberIn(data.Cash, Config.Numbers.MaxBalance, false) or (type(data.Rebirths) ~= "number" or not Numbers.validRebirth(data.Rebirths)) then return false end
 if not arrayValid(data.OwnedWorlds, 8, function(id: any) return numberIn(id, 8, true) and id >= 1 end) then return false end
 if not arrayValid(data.OwnedVehicles, 40, function(id: any) return numberIn(id, 40, true) and id >= 1 end) then return false end
 if not table.find(data.OwnedWorlds, 1) or not table.find(data.OwnedVehicles, 1) or type(data.Pets) ~= "table" then return false end
 local count = 0
 for id, raw in pairs(data.Pets) do
  local pet: any = raw
  count += 1
  if count > Config.Data.MaxPets or type(id) ~= "string" or #id == 0 or #id > 64 or type(pet) ~= "table" then return false end
  if not numberIn(pet.SpeciesId, 96, true) or pet.SpeciesId < 1 then return false end
  if pet.Variant ~= "Normal" and pet.Variant ~= "Golden" and pet.Variant ~= "Rainbow" then return false end
 end
 if not legacy then
  if not numberIn(data.ActiveVehicle,40,true) or not table.find(data.OwnedVehicles,data.ActiveVehicle) then return false end
  if not arrayValid(data.DiscoveredPets,96,function(id:any) return numberIn(id,96,true) and id>=1 end) then return false end
  for _,rawPet in pairs(data.Pets) do local pet:any=rawPet;if not table.find(data.DiscoveredPets,pet.SpeciesId) then return false end end
 end
 return arrayValid(data.EquippedPets, Config.Rules.EquipSlots, function(id) return type(id) == "string" and data.Pets[id] ~= nil end)
end
function Profile.validate(data: any): boolean return validate(data,false) end
function Profile.copy(data: Data): Data
 local pets = {}
 for id, pet in pairs(data.Pets) do pets[id] = { SpeciesId = pet.SpeciesId, Variant = pet.Variant } end
 return { SchemaVersion = data.SchemaVersion, Energy = data.Energy, Cash = data.Cash, Rebirths = data.Rebirths,
  OwnedWorlds = table.clone(data.OwnedWorlds), OwnedVehicles = table.clone(data.OwnedVehicles),
  Pets = pets, EquippedPets = table.clone(data.EquippedPets), ActiveVehicle = data.ActiveVehicle, DiscoveredPets = table.clone(data.DiscoveredPets) }
end
function Profile.migrate(raw: any): Data?
 if type(raw)~="table" then return nil end
 if raw.SchemaVersion==Config.Data.SchemaVersion then return if Profile.validate(raw) then Profile.copy(raw) else nil end
 if not validate(raw,true) then return nil end
 local enriched:any=table.clone(raw)
 enriched.SchemaVersion=Config.Data.SchemaVersion;enriched.ActiveVehicle=1;enriched.DiscoveredPets={}
 for _,rawPet in pairs(raw.Pets) do local pet:any=rawPet;if not table.find(enriched.DiscoveredPets,pet.SpeciesId) then table.insert(enriched.DiscoveredPets,pet.SpeciesId) end end
 table.sort(enriched.DiscoveredPets)
 return Profile.copy(enriched)
end
function Profile.snapshot(data: Data): Snapshot
 return { Energy = data.Energy, Cash = data.Cash, Rebirths = data.Rebirths }
end
return table.freeze(Profile)
