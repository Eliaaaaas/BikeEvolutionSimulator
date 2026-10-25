--!strict
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Profile = require(Shared:WaitForChild("Profile"))
local Persistence = require(script.Parent.Persistence)
local SavePolicy = require(script.Parent.SavePolicy)
local shutdownDeadline = math.huge
local function log(event: any)
 warn("[BikeData] " .. HttpService:JSONEncode(event))
end
local function newBackend()
 return Persistence.new(DataStoreService:GetDataStore(Config.Data.Store), Profile, Config.Data,
 game.JobId .. ":" .. HttpService:GenerateGUID(false), os.time, function(attempt: number) task.wait(attempt * 2) end, log)
end
local Service = {}
type Session = { Data: Profile.Data, Expires: number, Saving: boolean, Backend: any }
local sessions: {[Player]: Session} = {}
local closing = false
local loading = 0
local function key(player: Player): string return "Player_" .. player.UserId end
local function save(player: Player, release: boolean)
 local session = sessions[player]
 if not session then return end
 -- Serialize all writes, including leave during an autosave.
 while session.Saving and os.time() < math.min(session.Expires, shutdownDeadline) do task.wait() end
 if session.Saving then return end
 if sessions[player] ~= session then return end
 session.Saving = true
 local ok, reason = SavePolicy.flush(session, key(player), release, function() return shutdownDeadline end, os.time,
  function() task.wait(2) end, log)
 session.Saving = false
 if ok and release or not ok and reason ~= "DataStoreUnavailable" then
  sessions[player] = nil
  if not ok then
   log({ Event = "ProfileRecoveryExhausted", UserId = player.UserId, Reason = reason })
   warn("Profile save failed", player.UserId, reason)
   player:Kick("Deine Daten konnten nicht sicher gespeichert werden. Bitte später erneut verbinden.")
  end
 end
end
function Service.snapshot(player: Player): Profile.Snapshot?
 local session = sessions[player]
 if not session or session.Expires <= os.time() then return nil end
 return Profile.snapshot(session.Data)
end
function Service.start()
 local function added(player: Player)
  if closing then return end
  loading += 1
  local backend = newBackend()
  local data, reason, expires = backend:load(key(player))
  if not data then
   loading -= 1
   warn("Profile load rejected", player.UserId, reason)
   player:Kick("Spielerdaten sind momentan nicht verfügbar. Bitte später erneut versuchen.")
   return
  end
  if closing or player.Parent ~= Players then
   local orphan = { Data = data, Expires = expires, Backend = backend }
   SavePolicy.flush(orphan, key(player), true, function() return shutdownDeadline end, os.time, function() task.wait(2) end, log)
   loading -= 1
   return
  end
  sessions[player] = { Data = data, Expires = expires, Saving = false, Backend = backend }
  loading -= 1
 end
 Players.PlayerAdded:Connect(added)
 Players.PlayerRemoving:Connect(function(player) save(player, true) end)
 for _, player in ipairs(Players:GetPlayers()) do task.spawn(added, player) end
 task.spawn(function()
  while not closing do
   task.wait(Config.Data.AutosaveSeconds)
   if closing then break end
   for player in pairs(sessions) do task.spawn(save, player, false) end
  end
 end)
 -- Stop serving a profile as soon as its lease expires, even if a save is yielding.
 task.spawn(function()
  while not closing do
   task.wait(1)
   for player, session in pairs(sessions) do
    if session.Expires <= os.time() then player:Kick("Datensitzung abgelaufen. Bitte erneut verbinden.") end
   end
  end
 end)
 game:BindToClose(function()
  closing = true
  shutdownDeadline = os.time() + 24
  local pending = 0
  for player in pairs(sessions) do
   pending += 1
   task.spawn(function() save(player, true); pending -= 1 end)
  end
  local deadline = os.clock() + 25
  while (pending > 0 or loading > 0) and os.clock() < deadline do task.wait(0.1) end
  if pending > 0 or loading > 0 then warn("Shutdown save deadline reached; remaining locks expire automatically") end
 end)
end
return Service
