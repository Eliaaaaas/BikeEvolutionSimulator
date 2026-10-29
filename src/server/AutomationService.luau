--!strict
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Catalog=require(Shared:WaitForChild("Catalog"))
local Access=require(Shared:WaitForChild("AutoTraining"))
local Nav=require(Shared:WaitForChild("AutoNavigation"))
local Service={}
function Service.new(data:any,mounts:any,race:any,training:any,zones:any,emit:any,hasVIP:((Player)->boolean)?):any
 local states:{[Player]:any}={};local api:any={}
 function api.state(player:Player):any
  if not states[player] then states[player]={AutoTrain=false,AutoRace=false,SlowMode=false,Difficulty="Easy",Phase="Manual",PauseUntil=0,NextTeleportAt=0} end
  return states[player]
 end
 local function fail(player:Player,s:any,reason:string)
  s.AutoTrain=false;s.PendingTraining=nil;s.Phase="Blocked";mounts.auto(player,nil)
  training:stop(player);emit(player,{Kind="InteractionError",Error=reason})
 end
 local function train(player:Player,s:any,profile:any,record:any)
  local available:{[number]:boolean}={};local restricted:{[number]:boolean}={}
  for id,zone in pairs(zones) do
   available[id]=zone:IsDescendantOf(workspace)
   restricted[id]=zone:GetAttribute("VIPOnly")==true or Catalog.Treadmills[id].VIPOnly==true
  end
  local best=Access.best(profile,available,restricted,if hasVIP then hasVIP(player) else false)
  if best==0 then
   if s.Phase~="TrainingUnavailable" then emit(player,{Kind="InteractionError",Error="NoAvailableTreadmill"}) end
   s.Phase="TrainingUnavailable";s.PendingTraining=nil;training:stop(player);mounts.auto(player,nil);return
  end
  local placed=s.TrainTarget==best and s.TrainCharacter==record.Character and mounts.onBelt(player,zones[best])
  mounts.auto(player,{Throttle=0,Steer=0,Brake=true,JumpId=record.State.JumpId})
  if not placed then
   if os.clock()<s.NextTeleportAt then s.Phase="TrainingPending";return end
   s.NextTeleportAt=os.clock()+Config.Training.AutoTeleportCooldown
   local ok,reason=mounts.trainTeleport(player,best)
   if not ok then fail(player,s,reason or "TrainingPositionBlocked");return end
   s.TrainTarget=best;s.TrainCharacter=record.Character;s.Path=nil
  end
  s.PendingTraining=nil
  if training:selection(player)~=best then
   local ok,reason=training:select(player,best)
   if not ok then
    if reason=="Cooldown" or reason=="Saving" then s.Phase="TrainingPending";return end
    fail(player,s,reason or "Locked");return
   end
  end
  s.Phase="Training"
 end
 local function raceNavigate(player:Player,s:any,record:any)
  s.Phase="NavigatingRace"
  if not s.Path or s.RouteCharacter~=record.Character then
   s.Path=Nav.path(record.State,{X=0,Z=63});s.RouteCharacter=record.Character;s.Index=1;s.Stuck=0;s.Last=nil
  end
  if math.abs(record.State.X)<5 and math.abs(record.State.Z-63)<6 then
   mounts.auto(player,{Throttle=0,Steer=0,Brake=true,JumpId=record.State.JumpId})
   local ok,err=race.start(player,s.Difficulty)
   if not ok and err~="Cooldown" then s.AutoRace=false;s.Phase="Blocked";mounts.auto(player,nil);emit(player,{Kind="InteractionError",Error=err}) end
   return
  end
  local input,distance=Nav.input(record.State,s.Path[s.Index])
  if distance<2 and s.Index<#s.Path then s.Index+=1;local nextInput=Nav.input(record.State,s.Path[s.Index]);input=nextInput end
  mounts.auto(player,input)
  if s.Last and math.abs(record.State.X-s.Last.X)+math.abs(record.State.Z-s.Last.Z)<.015 then s.Stuck=(s.Stuck or 0)+.2 else s.Stuck=0 end
  s.Last={X=record.State.X,Z=record.State.Z}
  if s.Stuck>12 then s.AutoRace=false;s.Phase="Blocked";mounts.auto(player,nil);emit(player,{Kind="InteractionError",Error="NavigationBlocked"}) end
 end
 function api.tick(player:Player)
  local s=api.state(player)
  local profile=data.context(player);local record=mounts.ensure(player)
  if not record or not profile or record.Humanoid.Health<=0 then mounts.auto(player,nil);return end
  -- Absolute race exclusion: no training teleports, even on unlock/reset/enable/respawn requests.
  if race.active(player) or record.Mode~="Manual" then s.Phase="Racing";s.WasRace=true;mounts.auto(player,nil);return end
  if s.WasRace then
   s.WasRace=nil;s.PauseUntil=os.clock()+3;s.Path=nil;s.TrainTarget=nil;s.PendingTraining=s.AutoTrain
  end
  -- Resume training once immediately after a race, then retain the normal three-second restart pause.
  if s.AutoTrain and (s.PendingTraining or not s.AutoRace or os.clock()<s.PauseUntil) then train(player,s,profile,record);return end
  if os.clock()<s.PauseUntil then s.Phase="Pause";mounts.auto(player,nil);return end
  if s.AutoRace then raceNavigate(player,s,record);return end
  s.Phase="Manual";s.Path=nil;mounts.auto(player,nil)
 end
 function api.toggle(player:Player,key:string,value:boolean,difficulty:string?):boolean
  local s=api.state(player);local previous=s[key];s[key]=value
  if difficulty then s.Difficulty=difficulty end
  if key=="AutoRace" and previous~=value then s.Path=nil;s.Stuck=0;s.Last=nil end
  if key=="AutoTrain" then
   if value and not previous then s.PendingTraining=true end
   if not value then s.PendingTraining=nil end
  end
  player:SetAttribute("SlowMode",s.SlowMode)
  api.tick(player) -- Activation does not wait for a route or the next input packet.
  return true
 end
 function api.remove(player:Player) states[player]=nil end
 return api
end
return Service
