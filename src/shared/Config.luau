--!strict
local Config = {
 Data = { Store = "BikeEvolution_Player_v1", SchemaVersion = 1, AutosaveSeconds = 60,
  LeaseSeconds = 180, Attempts = 3, MaxPets = 500 },
 Rules = { WorldCount = 8, VehicleCount = 40, TreadmillCount = 40, TreadmillsPerWorld = 5,
  EggCount = 24, PetSpeciesCount = 96, EquipSlots = 3, BaseTraining = 1,
  RebirthBonus = 0.5, GoldenIngredients = 5, RainbowIngredients = 3 },
 Numbers = { MaxBalance = 1e300, MaxRebirths = 9007199254740991 },
 Treadmills = { EnergyBase = 1, RebirthBase = 1, EnergyFactor = 4, RebirthFactor = 3 },
 Network = { Folder = "BikeRemotes", ProtocolVersion = 1, SnapshotCooldown = 1 },
 -- Economy values are provisional configuration, not implemented purchase systems.
 Economy = { RebirthBaseEnergy = 1000, WorldBaseCash = 1000, VehicleBaseCash = 100 },
 Race = { Automatic = true, OpponentType = "Bot", EnergyCost = 0 },
 RaceDifficulties = { "Easy", "Medium", "Hard" },
}
local function freezeDeep(value)
 for _, child in pairs(value) do
  if type(child) == "table" then freezeDeep(child) end
 end
 return table.freeze(value)
end
return freezeDeep(Config)
