--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Rules = require(Shared:WaitForChild("Rules"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local Controller = require(Shared:WaitForChild("TrainingController"))
local Limiter = require(Shared:WaitForChild("RateLimiter"))
local Protocol = require(Shared:WaitForChild("Protocol"))
local Service = {}
function Service.new(dataService: any): any
 local training = workspace:WaitForChild("World1"):WaitForChild("Training")
 local zones: {[number]: BasePart} = {}
 for id=1,5 do zones[id] = training:WaitForChild("Treadmill_"..id):WaitForChild("Zone") :: BasePart end
 local function alive(player: Player): boolean
  local character = player.Character
  local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
  return humanoid ~= nil and humanoid.Health > 0 and character ~= nil and character:IsDescendantOf(workspace)
 end
 local function near(player: Player, id: number): boolean
  if not alive(player) then return false end
  local character = player.Character
  local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
  local zone = zones[id]
  if not root or not root:IsA("BasePart") or not zone then return false end
  local delta = root.Position - zone.Position
  -- Axis bounds match the actual belt. Vertical check prevents training from beneath the island.
  return Rules.withinTrainingZone(delta.X, delta.Y, delta.Z, zone.Size.X, zone.Size.Z)
 end
 local controller = Controller.new(dataService, os.clock, near)
 local limiter = Limiter.new(Config.Training.RemoteCapacity, Config.Training.RemoteRefillPerSecond, os.clock)
 local result: any = {}
 function result.handle(player: Player, payload: any): (boolean, string?)
  -- Shared gate for UI remotes AND proximity prompts, before inspecting untrusted payloads.
  if not limiter:allow(player) then return false, "RateLimited" end
  if not Protocol.validAction(payload) then return false, "BadRequest" end
  if not alive(player) then controller:stop(player); return false, "NotAlive" end
  if payload.Action == "Select" then return controller:select(player, payload.TreadmillId) end
  if payload.Action == "Click" then return controller:impulse(player, true) end
  if payload.Action == "Stop" then controller:stop(player); return true, nil end
  return controller:rebirth(player)
 end
 function result.snapshot(player: Player): any
  local snapshot = dataService.snapshot(player)
  if not snapshot then return nil end
  local selected = controller:selection(player)
  snapshot.SelectedTreadmill = selected
  snapshot.TrainingMultiplier = Rules.trainingGain(snapshot.Rebirths)
  snapshot.ImpulseGain = if selected == 0 then 0 else Rules.trainingGain(snapshot.Rebirths, Catalog.Treadmills[selected].TrainingMultiplier)
  snapshot.RebirthRequirement = Rules.rebirthRequirement(snapshot.Rebirths)
  return snapshot
 end
 function result.start()
  for id=1,5 do
   local prompt = Instance.new("ProximityPrompt")
   prompt.Name = "SelectTraining"
   prompt.ActionText = "Trainieren +"..Catalog.Treadmills[id].TrainingMultiplier
   prompt.ObjectText = "Laufband "..id
   prompt.HoldDuration = 0
   prompt.MaxActivationDistance = Config.Training.MaxDistance
   prompt.RequiresLineOfSight = false
   prompt.Parent = zones[id]
   prompt.Triggered:Connect(function(player) result.handle(player, {Version=1,Action="Select",TreadmillId=id}) end)
  end
  local function added(player: Player)
   player.CharacterRemoving:Connect(function() controller:stop(player) end)
  end
  Players.PlayerAdded:Connect(added)
  for _, player in ipairs(Players:GetPlayers()) do added(player) end
  Players.PlayerRemoving:Connect(function(player) controller:remove(player); limiter:remove(player) end)
  task.spawn(function()
   while true do task.wait(0.1); controller:tick() end
  end)
 end
 return result
end
return Service
