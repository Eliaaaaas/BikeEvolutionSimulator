--!strict
local Config = require(script.Parent.Config)
local Numbers = require(script.Parent.Numbers)
local Content = require(script.Parent.World1Content)
local Metadata = require(script.Parent.CatalogMetadata)
local Catalog: { Worlds: {any}, Vehicles: {any}, Treadmills: {any}, Eggs: {any}, Pets: {any} } = { Worlds = {}, Vehicles = {}, Treadmills = {}, Eggs = {}, Pets = {} }
local function vehicleClass(id: number): string
 if id <= 6 then return "Bicycle" end
 if id <= 15 then return "Moped" end
 if id <= 27 then return "Motorcycle" end
 if id <= 34 then return "Supersport" end
 return "RaceMachine"
end
for id = 1, Config.Rules.WorldCount do
 Catalog.Worlds[id] = table.freeze({ Id = id, CashCost = if id == 1 then 0 else Config.Economy.WorldBaseCash * (id - 1), Currency = "Cash" })
end
for id = 1, Config.Rules.VehicleCount do
 Catalog.Vehicles[id] = table.freeze({ Id = id, Class = vehicleClass(id), CashCost = if id == 1 then 0 else Config.Economy.VehicleBaseCash * (id - 1) })
end
for id = 1, Config.Rules.TreadmillCount do
 Catalog.Treadmills[id] = table.freeze({ Id = id, WorldId = math.ceil(id / 5), TrainingMultiplier = Numbers.power(2, id - 1), CashCost = 0,
  EnergyRequirement = if id == 1 then 0 else Numbers.multiply(Config.Treadmills.EnergyBase, Numbers.power(Config.Treadmills.EnergyFactor, id - 2)),
  RebirthRequirement = if id == 1 then 0 else Numbers.multiply(Config.Treadmills.RebirthBase, Numbers.power(Config.Treadmills.RebirthFactor, id - 2)) })
end
for id = 1, Config.Rules.EggCount do
 local species = {}
 for offset = 1, 4 do species[offset] = (id - 1) * 4 + offset end
 Catalog.Eggs[id] = table.freeze({ Id = id, WorldId = math.ceil(id / 3), Species = table.freeze(species) })
end
for id = 1, Config.Rules.PetSpeciesCount do
 Catalog.Pets[id] = table.freeze({ Id = id, EggId = math.ceil(id / 4) })
end
-- Explicit pending fields can be replaced per stable ID without inventing content.
for _, group in ipairs({ {Items=Catalog.Vehicles,Metadata=Metadata.Vehicles}, {Items=Catalog.Eggs,Metadata=Metadata.Eggs}, {Items=Catalog.Pets,Metadata=Metadata.Pets} }) do
 for id, entry in ipairs(group.Items) do
  local enriched = table.clone(entry)
  for key, value in pairs(Metadata.resolve(group.Metadata[id])) do enriched[key] = value end
  group.Items[id] = table.freeze(enriched)
 end
end
for id, content in ipairs(Content.Vehicles) do
 local v=table.clone(Catalog.Vehicles[id]);v.Name=content.Name;v.CashCost=content.Price;v.SpeedMultiplier=content.Speed;v.Model=content.Model;v.Playable=true;v.ContentStatus="Configured";v.Design=table.freeze({ModelPath="ReplicatedStorage/Vehicles/"..content.Model})
 Catalog.Vehicles[id]=table.freeze(v)
end
for id,content in ipairs(Content.Eggs) do
 local e=table.clone(Catalog.Eggs[id]);e.Name=content.Name;e.CashCost=content.Price;e.Weights=Content.Weights;e.Playable=true;e.ContentStatus="Configured";Catalog.Eggs[id]=table.freeze(e)
end
for id,content in ipairs(Content.Pets) do
 local p=table.clone(Catalog.Pets[id]);p.Name=content.Name;p.Rarity=Content.Rarities[(id-1)%4+1];p.EnergyMultiplier=content.Energy;p.CashMultiplier=content.Cash;p.Playable=true;p.ContentStatus="Configured";p.Model="Pet"..id;p.HatchWeight=Content.Weights[(id-1)%4+1];p.HatchChance=p.HatchWeight/10000;p.Design=table.freeze({ModelPath="ReplicatedStorage/PetModels/Pet"..id});Catalog.Pets[id]=table.freeze(p)
end
for _, category in ipairs({Catalog.Worlds,Catalog.Vehicles,Catalog.Treadmills,Catalog.Eggs,Catalog.Pets}) do table.freeze(category) end
return table.freeze(Catalog)
