--!strict
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules=require(Shared:WaitForChild("Rules"))
local Nav=require(Shared:WaitForChild("AutoNavigation"))
local Service={}
function Service.new(data:any,mounts:any,race:any,training:any,zones:any,emit:any):any
 local states:{[Player]:any}={};local api:any={}
 function api.state(player:Player):any
  if not states[player] then states[player]={AutoTrain=false,AutoRace=false,SlowMode=false,Difficulty="Easy",Phase="Manual",PauseUntil=0} end
  return states[player]
 end
 function api.toggle(player:Player,key:string,value:boolean,difficulty:string?):boolean
  local s=api.state(player);s[key]=value
  if difficulty then s.Difficulty=difficulty end
  if key~="SlowMode" then s.Path=nil;s.Target=nil;s.Stuck=0;s.Last=nil end
  player:SetAttribute("SlowMode",s.SlowMode)
  return true
 end
 function api.tick(player:Player)
  local s=api.state(player)
  local profile=data.context(player);local record=mounts.ensure(player)
  if not record or not profile or record.Humanoid.Health<=0 then mounts.auto(player,nil);return end
  if race.active(player) then s.Phase="Racing";s.WasRace=true;mounts.auto(player,nil);return end
  if s.WasRace then s.WasRace=nil;s.PauseUntil=os.clock()+3;s.Path=nil;s.Target=nil end
  if os.clock()<s.PauseUntil then s.Phase="Pause";mounts.auto(player,nil);return end
  local target:any=nil;local key:any=nil
  if s.AutoRace then target={X=0,Z=63};key="Race"
  elseif s.AutoTrain then
   for id=5,1,-1 do if Rules.canUseTreadmill(id,profile.Energy,profile.Rebirths,profile.OwnedWorlds) then target={X=zones[id].Position.X,Z=zones[id].Position.Z};key=id;break end end
  end
  if not target then s.Phase="Manual";s.Path=nil;s.Target=nil;mounts.auto(player,nil);return end
  if key~=s.Target or s.Character~=record.Character then
   s.Target=key;s.Character=record.Character;s.Path=Nav.path(record.State,target);s.Index=1;s.Stuck=0;s.Last=nil
  end
  if key=="Race" and math.abs(record.State.X)<5 and math.abs(record.State.Z-63)<6 then
   mounts.auto(player,{Throttle=0,Steer=0,Brake=true,JumpId=record.State.JumpId})
   local ok,err=race.start(player,s.Difficulty)
   if not ok and err~="Cooldown" then s.AutoRace=false;s.Phase="Blocked";mounts.auto(player,nil);emit(player,{Kind="InteractionError",Error=err}) end
   return
  end
  if type(key)=="number" and mounts.onBelt(player,zones[key]) then
   s.Phase="Training";mounts.auto(player,{Throttle=0,Steer=0,Brake=true,JumpId=record.State.JumpId});return
  end
  s.Phase="Navigating"
  local waypoint=s.Path[s.Index]
  local input,distance=Nav.input(record.State,waypoint)
  if distance<2 and s.Index<#s.Path then s.Index+=1;local nextInput=Nav.input(record.State,s.Path[s.Index]);input=nextInput end
  mounts.auto(player,input)
  if s.Last and math.abs(record.State.X-s.Last.X)+math.abs(record.State.Z-s.Last.Z)<.015 then s.Stuck=(s.Stuck or 0)+.2 else s.Stuck=0 end
  s.Last={X=record.State.X,Z=record.State.Z}
  if s.Stuck>12 then
   s.AutoTrain=false;s.AutoRace=false;s.Phase="Blocked";mounts.auto(player,nil);emit(player,{Kind="InteractionError",Error="NavigationBlocked"})
  end
 end
 function api.remove(player:Player) states[player]=nil end
 return api
end
return Service
