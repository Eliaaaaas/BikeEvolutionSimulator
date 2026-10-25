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
local Economy=require(Shared:WaitForChild("EconomyController"))
local PetRules=require(Shared:WaitForChild("PetRules"))
local Numbers=require(Shared:WaitForChild("Numbers"))
local Http=game:GetService("HttpService")
local RaceService=require(script.Parent.RaceService)
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
  if not alive(player) or player:GetAttribute("Racing")==true then return false end
  local character = player.Character
  local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
  local zone = zones[id]
  if not root or not root:IsA("BasePart") or not zone then return false end
  local delta = root.Position - zone.Position
  -- Axis bounds match the actual belt. Vertical check prevents training from beneath the island.
  return Rules.withinTrainingZone(delta.X, delta.Y, delta.Z, zone.Size.X, zone.Size.Z)
 end
 local sink: any=function() end
 local sequence: {[Player]:number}={}
 local function emit(player:Player,event:any)
  sequence[player]=(sequence[player] or 0)+1;event.Id=sequence[player]
  local ok,err=pcall(sink,player,event);if not ok then warn("[Feedback]",player.UserId,tostring(err)) end
 end
 local controller = Controller.new(dataService, os.clock, near,emit)
 local race=RaceService.new(dataService,function(player) controller:stop(player) end,emit)
 local rng=Random.new()
 local economy=Economy.new(dataService,os.clock,function() return rng:NextInteger(1,10000) end,function() return Http:GenerateGUID(false) end,emit)
 local limiter = Limiter.new(Config.Training.RemoteCapacity, Config.Training.RemoteRefillPerSecond, os.clock)
 local inventorySent: {[Player]:number}={}
 local result: any = {}
 function result.setFeedback(callback:any) sink=callback end
 function result.handle(player: Player, payload: any): (boolean, string?)
  if player.Parent~=Players then return false,"NotReady" end
  -- Shared gate for UI remotes AND proximity prompts, before inspecting untrusted payloads.
  if not limiter:allow(player) then return false, "RateLimited" end
  if not Protocol.validAction(payload) then return false, "BadRequest" end
  if not alive(player) then controller:stop(player); return false, "NotAlive" end
  if payload.Action=="AbortRace" then race.abort(player);return true,nil end
  if race.active(player) then return false,"AlreadyRacing" end
  if payload.Action=="StartRace" then return race.start(player,payload.Difficulty or "Easy") end
  if payload.RequestId then return economy:handle(player,payload) end
  if payload.Action == "Select" then return controller:select(player, payload.TreadmillId) end
  if payload.Action == "Click" then return controller:impulse(player, true) end
  if payload.Action == "Stop" then controller:stop(player); return true, nil end
  return controller:rebirth(player)
 end
 function result.snapshot(player: Player, forceInventory: boolean?): any
  local snapshot = dataService.snapshot(player)
  if not snapshot then return nil end
  local selected = controller:selection(player)
  snapshot.SelectedTreadmill = selected
  player:SetAttribute("SelectedTreadmill",selected)
  snapshot.Race=race.snapshot(player)
  local profile=dataService.read(player)
  if not profile then return nil end
  snapshot.ActiveVehicle=profile.ActiveVehicle
  local inventoryRevision=dataService.inventoryRevision(player)
  snapshot.InventoryRevision=inventoryRevision
  snapshot.LastRequestId=economy.Requests[player] or 0
  if forceInventory or inventorySent[player]~=inventoryRevision then
   snapshot.OwnedVehicles=profile.OwnedVehicles;snapshot.Pets=profile.Pets
   snapshot.EquippedPets=profile.EquippedPets;snapshot.DiscoveredPets=profile.DiscoveredPets
   inventorySent[player]=inventoryRevision
   local followers={}
   for _,id in ipairs(profile.EquippedPets) do table.insert(followers,profile.Pets[id]) end
   player:SetAttribute("PetFollowers",Http:JSONEncode(followers))
  end
  snapshot.PetEnergyBonus=PetRules.bonus(profile,"Energy");snapshot.PetCashBonus=PetRules.bonus(profile,"Cash")
  snapshot.Revision=dataService.revision(player)
  snapshot.TrainingMultiplier = Rules.trainingGain(snapshot.Rebirths)
  snapshot.ImpulseGain = if selected == 0 then 0 else Numbers.multiply(Rules.trainingGain(snapshot.Rebirths, Catalog.Treadmills[selected].TrainingMultiplier),snapshot.PetEnergyBonus)
  snapshot.RebirthRequirement = Rules.rebirthRequirement(snapshot.Rebirths)
  return snapshot
 end
 function result.start()
  local island=workspace:WaitForChild("World1")
  local function menuPrompt(part:BasePart,title:string,event:any)
   local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Öffnen";prompt.ObjectText=title;prompt.MaxActivationDistance=12;prompt.Parent=part
   prompt.Triggered:Connect(function(player)
    local root=if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
    if limiter:allow(player) and alive(player) and root and root:IsA("BasePart") and (root.Position-part.Position).Magnitude<=14 then emit(player,table.clone(event)) end
   end)
  end
  for id=1,3 do menuPrompt(island:WaitForChild("EggStation_"..id):WaitForChild("Egg") :: BasePart,Catalog.Eggs[id].Name,{Kind="OpenEgg",EggId=id}) end
  menuPrompt(island:WaitForChild("GaragePreview"):WaitForChild("Platform") :: BasePart,"Garage",{Kind="OpenMenu",Menu="Garage"})
  menuPrompt(island:WaitForChild("RebirthStation"):WaitForChild("RebirthOrb") :: BasePart,"Rebirth",{Kind="OpenMenu",Menu="Rebirths"})
  race.request=function(player) result.handle(player,{Version=1,Action="StartRace"}) end
  race.run()
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
  Players.PlayerRemoving:Connect(function(player) controller:remove(player); limiter:remove(player);sequence[player]=nil;inventorySent[player]=nil;economy:remove(player) end)
  task.spawn(function()
   while true do task.wait(0.1); controller:tick() end
  end)
 end
 return result
end
return Service
