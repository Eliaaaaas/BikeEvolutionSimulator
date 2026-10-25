--!strict
local Config = require(script.Parent.Config)
local Catalog: any = { Worlds = {}, Vehicles = {}, Treadmills = {}, Eggs = {}, Pets = {} }
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
 Catalog.Treadmills[id] = table.freeze({ Id = id, WorldId = math.ceil(id / 5), TrainingMultiplier = id })
end
for id = 1, Config.Rules.EggCount do
 local species = {}
 for offset = 1, 4 do species[offset] = (id - 1) * 4 + offset end
 Catalog.Eggs[id] = table.freeze({ Id = id, WorldId = math.ceil(id / 3), Species = table.freeze(species) })
end
for id = 1, Config.Rules.PetSpeciesCount do
 Catalog.Pets[id] = table.freeze({ Id = id, EggId = math.ceil(id / 4) })
end
for _, category in pairs(Catalog) do table.freeze(category) end
return table.freeze(Catalog)
