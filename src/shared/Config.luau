--!strict
local Numbers = require(script.Parent.Numbers)
local Config = {
 Data = { Store = "BikeEvolution_Player_v1", SchemaVersion = 3, AutosaveSeconds = 60,
  LeaseSeconds = 180, Attempts = 3, MaxPets = 500 },
 Rules = { WorldCount = 8, VehicleCount = 40, TreadmillCount = 40, TreadmillsPerWorld = 5,
  EggCount = 24, PetSpeciesCount = 96, EquipSlots = 3, BaseTraining = 1,
  RebirthBonus = 0.5, GoldenIngredients = 5, RainbowIngredients = 3 },
 Numbers = { MaxBalance = Numbers.Max, MaxRebirths = Numbers.MaxRebirths },
 Treadmills = { EnergyBase = 21, Difficulty = 4, RebirthBase = 1, RebirthFactor = 3 },
 Training = { AutoSeconds = 1, ClickCooldown = 0.2, SelectCooldown = 0.4, RebirthCooldown = 1,
  RemoteCapacity = 12, RemoteRefillPerSecond = 8, MaxDistance = 10, MaxVerticalDistance = 6 },
 Bike = { Tick = 1/60, CommandSteps = 2, InputInterval = 1/30, InputTimeout = .45, BaseSpeed = 18, MaxSpeed = 46,
  Acceleration = 40, Braking = 90, Drag = 35, TurnRate = 2.8, StepHeight = 1.6,
  Gravity = 80, JumpVelocity = 28, JumpCooldown = .65, GroundTolerance = .22, MinGroundNormal = .7,
  FloorProbe = 18, QueueLimit = 8, AckInterval = .1, PendingLimit = 90 },
 Network = { Folder = "BikeRemotes", ProtocolVersion = 1, SnapshotCooldown = 1 },
 -- Economy values are provisional configuration, not implemented purchase systems.
 Economy = { RebirthBaseEnergy = 1000, RebirthHardFrom = 2, RebirthHardFactor = 4, WorldBaseCash = 1000, VehicleBaseCash = 100 },
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
