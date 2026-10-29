--!strict
-- Pure controller: identity, clock, live position checks and profile transactions are injected.
local Config = require(script.Parent.Config)
local Rules = require(script.Parent.Rules)
local Numbers = require(script.Parent.Numbers)
local PremiumRules=require(script.Parent.PremiumRules)
local PetRules=require(script.Parent.PetRules)
local Catalog = require(script.Parent.Catalog)
local Controller: any = {}
Controller.__index = Controller
function Controller.new(data: any, clock: () -> number, near: (any, number) -> boolean, feedback: ((any, any) -> ())?): any
 return setmetatable({ Data = data, Clock = clock, Near = near, States = {}, Feedback = feedback or function() end }, Controller)
end
function Controller.state(self: any, player: any): any
 if not self.States[player] then self.States[player] = { Selected = 0, LastAuto = self.Clock(), LastClick = -math.huge, LastSelect = -math.huge, LastRebirth = -math.huge } end
 return self.States[player]
end
function Controller.select(self: any, player: any, id: number): (boolean, string?)
 local state, now = self:state(player), self.Clock()
 if now - state.LastSelect < Config.Training.SelectCooldown then return false, "Cooldown" end
 state.LastSelect = now
 if id % 1 ~= 0 or id < 1 or id > Config.Rules.TreadmillCount or not self.Near(player, id) then return false, "TooFar" end
 local allowed = false
 local ok, reason = self.Data.change(player, function(data: any): boolean
  allowed = Rules.canUseTreadmill(id, data.Energy, data.Rebirths, data.OwnedWorlds)
  return allowed
 end)
 if not ok then return false, if reason == "Rejected" then "Locked" else reason end
 if state.Selected ~= id then state.Selected = id; state.LastAuto = now; self.Feedback(player,{Kind="Selected",TreadmillId=id}) end
 return true, nil
end
function Controller.stop(self: any, player: any)
 local state = self:state(player); state.Selected = 0
end
function Controller.impulse(self: any, player: any, click: boolean): (boolean, string?)
 local state, now = self:state(player), self.Clock()
 local id = state.Selected
 if id == 0 then return false, "NoTreadmill" end
 if not self.Near(player, id) then state.Selected = 0; return false, "TooFar" end
 if click then
  if now - state.LastClick < Config.Training.ClickCooldown then return false, "Cooldown" end
  state.LastClick = now
 else
  if now - state.LastAuto < Config.Training.AutoSeconds then return false, "Cooldown" end
  state.LastAuto = now -- no accumulated offline/catch-up impulses
 end
 local allowed = false
 local gain=0
 local ok, reason = self.Data.change(player, function(data: any): boolean
  allowed = Rules.canUseTreadmill(id, data.Energy, data.Rebirths, data.OwnedWorlds)
  if not allowed then return false end
  local before=data.Energy
  data.Energy = Numbers.add(data.Energy, Numbers.multiply(Rules.trainingGain(data.Rebirths, Catalog.Treadmills[id].TrainingMultiplier),Numbers.multiply(PetRules.bonus(data,"Energy"),if self.Premium then (self.Premium :: any)(player,data,"Energy") else PremiumRules.bonus(data,"Energy"))))
  gain=data.Energy-before
  return true
 end)
 if ok and gain>0 then self.Feedback(player,{Kind="Training",Amount=gain}) end
 if not allowed and reason == "Rejected" then state.Selected = 0 end
 return ok, if not allowed and reason == "Rejected" then "Locked" else reason
end
function Controller.rebirth(self: any, player: any): (boolean, string?)
 local state, now = self:state(player), self.Clock()
 if now - state.LastRebirth < Config.Training.RebirthCooldown then return false, "Cooldown" end
 state.LastRebirth = now
 local rebirths=0
 local ok, reason = self.Data.change(player, function(data: any): boolean
  local result = Rules.rebirth(data.Energy, data.Rebirths)
  if not result then return false end
  data.Energy, data.Rebirths = result.Energy, result.Rebirths
  rebirths=result.Rebirths
  if state.Selected ~= 0 and not Rules.canUseTreadmill(state.Selected, data.Energy, data.Rebirths, data.OwnedWorlds) then state.Selected = 0 end
  return true
 end)
 if ok then self.Feedback(player,{Kind="Rebirth",Rebirths=rebirths}) end
 return ok, if reason == "Rejected" then "NotEnoughEnergy" else reason
end
function Controller.tick(self: any)
 for player, state in pairs(self.States) do
  if state.Selected ~= 0 then self:impulse(player, false) end
 end
end
function Controller.selection(self: any, player: any): number
 local state = self.States[player]
 return if state then state.Selected else 0
end
function Controller.remove(self: any, player: any) self.States[player] = nil end
return Controller
