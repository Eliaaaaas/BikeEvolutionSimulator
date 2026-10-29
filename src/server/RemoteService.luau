--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Protocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Protocol"))
local RemoteService = {}
function RemoteService.start(gameplay: any)
 local folder = Instance.new("Folder")
 folder.Name = Config.Network.Folder
 local remotes: {[string]: any} = {}
 for name, className in pairs(Protocol.Remotes) do
  local remote = Instance.new(className)
  remote.Name = name
  remote.Parent = folder
  remotes[name] = remote
 end
 gameplay.setDriveState(function(player:Player,state:any) remotes.DriveState:FireClient(player,state) end)
 gameplay.setFeedback(function(player:Player,event:any) remotes.Feedback:FireClient(player,event) end)
 remotes.Drive.OnServerEvent:Connect(function(player:Player,payload:any) gameplay.drive(player,payload) end)
 local lastRequest: {[Player]: number} = {}
 remotes.GetSnapshot.OnServerInvoke = function(player: Player, payload: any): any
  if player.Parent~=Players then return {Ok=false,Error="NotReady"} end
  local now, previousRequest = os.clock(), lastRequest[player]
  if previousRequest and now - previousRequest < Config.Network.SnapshotCooldown then return { Ok=false, Error="RateLimited" } end
  lastRequest[player] = now
  if not Protocol.validRequest(payload) then return { Ok=false, Error="BadRequest" } end
  local snapshot = gameplay.snapshot(player,true)
  return if snapshot then {Ok=true,Data=snapshot} else {Ok=false,Error=gameplay.status(player)}
 end
 local lastFeedback: {[Player]: number} = {}
 local previous: {[Player]: any} = {}
 remotes.Action.OnServerEvent:Connect(function(player: Player, payload: any)
  local ok, reason = gameplay.handle(player, payload)
  -- No amplification: silently drop floods, throttle negative feedback too.
  if reason == "RateLimited" then return end
  if not ok and lastFeedback[player] and os.clock() - (lastFeedback[player] or 0) < 0.5 then return end
  lastFeedback[player] = os.clock()
  local actionName=if type(payload)=="table" and type(payload.Action)=="string" and #payload.Action<=20 then payload.Action else ""
  if ok and (actionName=="EquipBest" or actionName=="UnequipAll" or actionName=="EquipPet" or actionName=="UnequipPet" or actionName=="Hatch") then
   local snapshot=gameplay.snapshot(player,true)
   if snapshot then previous[player]=snapshot;remotes.SnapshotChanged:FireClient(player,snapshot) end
  end
  remotes.ActionResult:FireClient(player, {Ok=ok,Error=reason,Action=actionName})
 end)
 Players.PlayerRemoving:Connect(function(player) lastRequest[player]=nil;lastFeedback[player]=nil;previous[player]=nil end)
 -- SnapshotChanged and ActionResult deliberately have no OnServerEvent handlers.
 folder.Parent = ReplicatedStorage
 task.spawn(function()
  while true do
   task.wait(0.25)
   for _, player in ipairs(Players:GetPlayers()) do
    local snapshot, old = gameplay.snapshot(player), previous[player]
    if snapshot and (not old or old.Revision~=snapshot.Revision or old.Energy~=snapshot.Energy or old.Cash~=snapshot.Cash or old.Rebirths~=snapshot.Rebirths or old.PremiumEnergy~=snapshot.PremiumEnergy or old.PremiumCash~=snapshot.PremiumCash or old.Automation.Phase~=snapshot.Automation.Phase or old.Automation.AutoTrain~=snapshot.Automation.AutoTrain or old.Automation.AutoRace~=snapshot.Automation.AutoRace or old.Automation.SlowMode~=snapshot.Automation.SlowMode or old.SelectedTreadmill~=snapshot.SelectedTreadmill or old.Race.Phase~=snapshot.Race.Phase or old.Race.Countdown~=snapshot.Race.Countdown or old.Race.Place~=snapshot.Race.Place or math.abs(old.Race.Progress-snapshot.Race.Progress)>0.005) then
     previous[player]=snapshot
     remotes.SnapshotChanged:FireClient(player,snapshot)
    end
   end
  end
 end)
end
return RemoteService
