--!strict
local Config = require(script.Parent.Config)
local Numbers = require(script.Parent.Numbers)
local Profile = {}
export type Snapshot = { Energy: number, Cash: number, Rebirths: number }
export type Pet = { SpeciesId: number, Variant: string }
export type Data = {
 SchemaVersion: number, Energy: number, Cash: number, Rebirths: number,
 OwnedWorlds: {number}, OwnedVehicles: {number}, Pets: {[string]: Pet}, EquippedPets: {string},
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
 return { SchemaVersion = 1, Energy = 0, Cash = 0, Rebirths = 0,
  OwnedWorlds = {1}, OwnedVehicles = {1}, Pets = {}, EquippedPets = {} }
end
function Profile.validate(data: any): boolean
 if type(data) ~= "table" or data.SchemaVersion ~= Config.Data.SchemaVersion then return false end
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
 return arrayValid(data.EquippedPets, Config.Rules.EquipSlots, function(id) return type(id) == "string" and data.Pets[id] ~= nil end)
end
function Profile.copy(data: Data): Data
 local pets = {}
 for id, pet in pairs(data.Pets) do pets[id] = { SpeciesId = pet.SpeciesId, Variant = pet.Variant } end
 return { SchemaVersion = data.SchemaVersion, Energy = data.Energy, Cash = data.Cash, Rebirths = data.Rebirths,
  OwnedWorlds = table.clone(data.OwnedWorlds), OwnedVehicles = table.clone(data.OwnedVehicles),
  Pets = pets, EquippedPets = table.clone(data.EquippedPets) }
end
function Profile.snapshot(data: Data): Snapshot
 return { Energy = data.Energy, Cash = data.Cash, Rebirths = data.Rebirths }
end
return table.freeze(Profile)
