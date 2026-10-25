--!strict
local Config = require(script.Parent.Config)
local Rules = {}
function Rules.trainingGain(rebirths: number, treadmillMultiplier: number?): number
 return Config.Rules.BaseTraining * (1 + rebirths * Config.Rules.RebirthBonus) * (treadmillMultiplier or 1)
end
function Rules.rebirthRequirement(rebirths: number): number
 return Config.Economy.RebirthBaseEnergy * (rebirths + 1)
end
function Rules.rebirth(energy: number, rebirths: number): { Energy: number, Rebirths: number }?
 if energy < Rules.rebirthRequirement(rebirths) then return nil end
 return { Energy = 0, Rebirths = rebirths + 1 }
end
function Rules.canBuyWorld(cash: number, worldId: number, owned: {number}): boolean
 if worldId % 1 ~= 0 or worldId < 2 or worldId > Config.Rules.WorldCount then return false end
 return not table.find(owned, worldId) and cash >= Config.Economy.WorldBaseCash * (worldId - 1)
end
-- No world argument: vehicle ownership is independent of world progress.
function Rules.canBuyVehicle(cash: number, vehicleId: number, owned: {number}): boolean
 return vehicleId % 1 == 0 and vehicleId >= 1 and vehicleId <= Config.Rules.VehicleCount
  and not table.find(owned, vehicleId) and cash >= Config.Economy.VehicleBaseCash * (vehicleId - 1)
end
function Rules.fusion(pets: {[string]: {SpeciesId: number, Variant: string}}, ids: {string}): { SpeciesId: number, Variant: string }?
 if #ids == 0 then return nil end
 local first = pets[ids[1]]
 if not first then return nil end
 local count = if first.Variant == "Normal" then Config.Rules.GoldenIngredients elseif first.Variant == "Golden" then Config.Rules.RainbowIngredients else 0
 if #ids ~= count then return nil end
 local seen = {}
 for _, id in ipairs(ids) do
  local pet = pets[id]
  if seen[id] or not pet or pet.SpeciesId ~= first.SpeciesId or pet.Variant ~= first.Variant then return nil end
  seen[id] = true
 end
 return { SpeciesId = first.SpeciesId, Variant = if first.Variant == "Normal" then "Golden" else "Rainbow" }
end
function Rules.raceEnergy(energy: number): number return energy end
return table.freeze(Rules)
