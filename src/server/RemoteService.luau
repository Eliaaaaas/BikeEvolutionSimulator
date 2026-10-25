--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Protocol = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Protocol"))
local Profile = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Profile"))
local RemoteService = {}
function RemoteService.start(dataService: { snapshot: (Player) -> Profile.Snapshot? })
 local folder = Instance.new("Folder")
 folder.Name = Config.Network.Folder
 local remotes: {[string]: any} = {}
 for name, className in pairs(Protocol.Remotes) do
  local remote = Instance.new(className)
  remote.Name = name
  remote.Parent = folder
  remotes[name] = remote
 end
 local lastRequest: {[Player]: number} = {}
 remotes.GetSnapshot.OnServerInvoke = function(player: Player, payload: any): any
  local now = os.clock()
  local previousRequest = lastRequest[player]
  if previousRequest and now - previousRequest < Config.Network.SnapshotCooldown then
   return { Ok = false, Error = "RateLimited" }
  end
  lastRequest[player] = now
  if not Protocol.validRequest(payload) then return { Ok = false, Error = "BadRequest" } end
  local snapshot = dataService.snapshot(player)
  return if snapshot then { Ok = true, Data = snapshot } else { Ok = false, Error = "NotReady" }
 end
 -- SnapshotChanged intentionally has no OnServerEvent handler: client fires have no effect.
 Players.PlayerRemoving:Connect(function(player) lastRequest[player] = nil end)
 folder.Parent = ReplicatedStorage
 task.spawn(function()
  local previous: {[Player]: Profile.Snapshot} = {}
  Players.PlayerRemoving:Connect(function(player) previous[player] = nil end)
  while true do
   task.wait(1)
   for _, player in ipairs(Players:GetPlayers()) do
    local snapshot = dataService.snapshot(player)
    local old = previous[player]
    if snapshot and (not old or old.Energy ~= snapshot.Energy or old.Cash ~= snapshot.Cash or old.Rebirths ~= snapshot.Rebirths) then
     previous[player] = snapshot
     remotes.SnapshotChanged:FireClient(player, snapshot)
    end
   end
  end
 end)
end
return RemoteService
