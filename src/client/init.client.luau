--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Protocol = require(Shared:WaitForChild("Protocol"))
local gui = Instance.new("ScreenGui")
gui.Name = "BikeDebugHUD"
gui.ResetOnSpawn = false
local label = Instance.new("TextLabel")
label.Name = "Stats"
label.Size = UDim2.fromOffset(290, 130)
label.Position = UDim2.fromOffset(16, 16)
label.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
label.BackgroundTransparency = 0.15
label.TextColor3 = Color3.new(1, 1, 1)
label.TextSize = 18
label.Font = Enum.Font.Code
label.Text = "Bike Evolution • Debug\nSpielerdaten werden geladen …"
label.Parent = gui
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild(Config.Network.Folder)
local function render(snapshot: any): boolean
 if not Protocol.validSnapshot(snapshot) then return false end
 label.Text = string.format("Bike Evolution • Debug\nEnergy: %s\nCash: %s\nRebirths: %s", tostring(snapshot.Energy), tostring(snapshot.Cash), tostring(snapshot.Rebirths))
 return true
end
local ready = false
(remotes:WaitForChild("SnapshotChanged") :: RemoteEvent).OnClientEvent:Connect(function(snapshot)
 if render(snapshot) then ready = true end
end)
task.spawn(function()
 local remote = remotes:WaitForChild("GetSnapshot") :: RemoteFunction
 while not ready do
  local ok, response = pcall(function() return remote:InvokeServer({ Version = Config.Network.ProtocolVersion }) end)
  if ok and type(response) == "table" and response.Ok and render(response.Data) then ready = true end
  if not ready then task.wait(2) end
 end
end)
