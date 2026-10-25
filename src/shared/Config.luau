--!strict
local Numbers = require(script.Parent.Numbers)
local Config = {
 Data = { Store = "BikeEvolution_Player_v1", SchemaVersion = 2, AutosaveSeconds = 60,
  LeaseSeconds = 180, Attempts = 3, MaxPets = 500 },
 Rules = { WorldCount = 8, VehicleCount = 40, TreadmillCount = 40, TreadmillsPerWorld = 5,
  EggCount = 24, PetSpeciesCount = 96, EquipSlots = 3, BaseTraining = 1,
  RebirthBonus = 0.5, GoldenIngredients = 5, RainbowIngredients = 3 },
 Numbers = { MaxBalance = Numbers.Max, MaxRebirths = Numbers.MaxRebirths },
 Treadmills = { EnergyBase = 1, RebirthBase = 1, EnergyFactor = 4, RebirthFactor = 3 },
 Training = { AutoSeconds = 1, ClickCooldown = 0.2, SelectCooldown = 0.4, RebirthCooldown = 1,
  RemoteCapacity = 12, RemoteRefillPerSecond = 8, MaxDistance = 10, MaxVerticalDistance = 6 },
 Network = { Folder = "BikeRemotes", ProtocolVersion = 1, SnapshotCooldown = 1 },
 -- Economy values are provisional configuration, not implemented purchase systems.
 Economy = { RebirthBaseEnergy = 1000, WorldBaseCash = 1000, VehicleBaseCash = 100 },
 Race = { Automatic = true, OpponentType = "Bot", EnergyCost = 0,
  Test = { BaseSpeed = 24, EnergyFactor = 4, SpeedBonusCap = 28, Countdown = 3, Timeout = 150 } },
 RaceDifficulties = { "Easy", "Medium", "Hard" },
}
local function freezeDeep(value)
 for _, child in pairs(value) do
  if type(child) == "table" then freezeDeep(child) end
 end
 return table.freeze(value)
end
return freezeDeep(Config)
