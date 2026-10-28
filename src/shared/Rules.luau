--!strict
local Config = require(script.Parent.Config)
local Numbers = require(script.Parent.Numbers)
local Catalog = require(script.Parent.Catalog)
local Rules = {}
function Rules.trainingGain(rebirths: number, treadmillMultiplier: number?): number
 assert(Numbers.validRebirth(rebirths), "Invalid rebirth count")
 return Numbers.multiply(Numbers.multiply(Config.Rules.BaseTraining, Numbers.add(1, Numbers.multiply(rebirths, Config.Rules.RebirthBonus))), treadmillMultiplier or 1)
end
function Rules.rebirthRequirement(rebirths: number): number
 assert(Numbers.validRebirth(rebirths), "Invalid rebirth count")
 return Numbers.multiply(Numbers.multiply(Config.Economy.RebirthBaseEnergy, Numbers.add(rebirths, 1)), if rebirths >= Config.Economy.RebirthHardFrom then Config.Economy.RebirthHardFactor else 1)
end
function Rules.withinTrainingZone(dx: number, dy: number, dz: number, width: number, depth: number): boolean
 -- Reject NaN/infinite transforms, including malformed client-owned character motion.
 for _, value in ipairs({dx, dy, dz, width, depth}) do
  if value ~= value or math.abs(value) == math.huge then return false end
 end
 return width > 0 and depth > 0 and math.abs(dx) <= width/2+1 and math.abs(dz) <= depth/2+1
  and math.abs(dy) <= Config.Training.MaxVerticalDistance
end
function Rules.canUseTreadmill(id: number, energy: number, rebirths: number, ownedWorlds: {number}): boolean
 if not Numbers.valid(id) or id % 1 ~= 0 or not Numbers.valid(energy) or not Numbers.validRebirth(rebirths) then return false end
 local treadmill = Catalog.Treadmills[id]
 return treadmill ~= nil and table.find(ownedWorlds, treadmill.WorldId) ~= nil
  and (energy >= treadmill.EnergyRequirement or rebirths >= treadmill.RebirthRequirement)
end
function Rules.rebirth(energy: number, rebirths: number): { Energy: number, Rebirths: number }?
 if not Numbers.valid(energy) or not Numbers.validRebirth(rebirths) or rebirths >= Numbers.MaxRebirths or energy < Rules.rebirthRequirement(rebirths) then return nil end
 return { Energy = 0, Rebirths = rebirths + 1 }
end
function Rules.canBuyWorld(cash: number, worldId: number, owned: {number}): boolean
 if worldId % 1 ~= 0 or worldId < 2 or worldId > Config.Rules.WorldCount then return false end
 return not table.find(owned, worldId) and cash >= Config.Economy.WorldBaseCash * (worldId - 1)
end
-- No world argument: vehicle ownership is independent of world progress.
function Rules.canBuyVehicle(cash: number, vehicleId: number, owned: {number}): boolean
 return vehicleId % 1 == 0 and vehicleId >= 1 and vehicleId <= Config.Rules.VehicleCount
  and not table.find(owned, vehicleId) and cash >= Catalog.Vehicles[vehicleId].CashCost
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
