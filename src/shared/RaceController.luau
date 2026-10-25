--!strict
local Course=require(script.Parent.RaceCourse)
local Numbers=require(script.Parent.Numbers)
local Config=require(script.Parent.Config)
local Test=Config.Race.Test
local Controller:any={};Controller.__index=Controller
function Controller.speed(energy: number): number
 assert(Numbers.valid(energy),"Invalid race energy")
 -- Bounded logarithmic curve: no huge-number overflow, no client speed input.
 return Test.BaseSpeed+math.min(Test.SpeedBonusCap,math.log10(1+energy)*Test.EnergyFactor)
end
function Controller.new(adapter: any,clock: () -> number): any
 return setmetatable({Adapter=adapter,Clock=clock,States={},Cooldowns={},Sequence=0},Controller)
end
function Controller.finish(self:any,player:any,reason:string)
 local state=self.States[player];if not state then return end
 self.States[player]=nil;self.Cooldowns[player]=self.Clock()+2
 local ok,err=pcall(self.Adapter.cleanup,player,state,reason)
 if not ok then self.Adapter.log("RaceCleanupFailed",tostring(err)) end
end
function Controller.start(self:any,player:any): (boolean,string?)
 if self.States[player] then return false,"AlreadyRacing" end
 if (self.Cooldowns[player] or 0)>self.Clock() then return false,"Cooldown" end
 local data=self.Adapter.profile(player)
 if not data or not self.Adapter.nearStart(player) or not table.find(data.OwnedVehicles,1) then return false,"RaceUnavailable" end
 self.Sequence+=1
 local state={Id=self.Sequence,Started=self.Clock(),Last=self.Clock(),Distance=0,Speed=0,Target=Controller.speed(data.Energy),Phase="Countdown"}
 self.States[player]=state -- reserve before spawning anything; simultaneous starts are refused
 local ok,err=pcall(self.Adapter.begin,player,state)
 if not ok then self:finish(player,"Error");self.Adapter.log("RaceBeginFailed",tostring(err));return false,"RaceUnavailable" end
 return true,nil
end
function Controller.tick(self:any)
 for player,state in pairs(self.States) do
  local now=self.Clock();local dt=math.clamp(now-state.Last,0,0.25);state.Last=now
  local checked,valid=pcall(self.Adapter.valid,player,state)
  if not checked or not valid then self:finish(player,"Aborted");continue end
  if now-state.Started>Test.Timeout then self:finish(player,"Timeout");continue end
  if state.FinishedAt then
   state.Speed=0;state.Phase="Arrived"
  elseif now-state.Started>=Test.Countdown then
   state.Phase="Riding"
   local target=math.min(state.Target,math.max(6,(Course.Length-state.Distance)*1.8))
   if state.Speed<target then state.Speed=math.min(target,state.Speed+dt*12) else state.Speed=math.max(target,state.Speed-dt*18) end
   state.Distance=math.min(Course.Length,state.Distance+state.Speed*dt)
   if state.Distance>=Course.Length then state.FinishedAt=now;state.Speed=0;state.Phase="Arrived" end
  end
  local ok,err=pcall(self.Adapter.move,player,state,Course.sample(state.Distance))
  if not ok then self:finish(player,"Error");self.Adapter.log("RaceMoveFailed",tostring(err))
  elseif state.FinishedAt and now-state.FinishedAt>=0.6 then self:finish(player,"Finished") end
 end
end
function Controller.remove(self:any,player:any) self:finish(player,"Disconnect");self.Cooldowns[player]=nil end
return Controller
