--!strict
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Course=require(Shared:WaitForChild("RaceCourse"))
local Logic=require(Shared:WaitForChild("RaceController"))
local BikeRig=require(Shared:WaitForChild("BikeRig"))
local Content=require(Shared:WaitForChild("World1Content"))
local RaceRules=require(Shared:WaitForChild("RaceRules"))
local Http=game:GetService("HttpService")
local Race={}
function Race.new(data:any,stopTraining:(Player)->(),feedback:(Player,any)->()):any
 local prototype=game:GetService("ReplicatedStorage"):WaitForChild("Vehicles"):WaitForChild("Mountainbike") :: Model
 local bikes=Instance.new("Folder");bikes.Name="ActiveRaceBikes";bikes.Parent=workspace
 local adapter:any={}
 function adapter.profile(player:Player):any
  local profile=if data.read then data.read(player) else data.snapshot(player)
  if not profile or not data.ownsVehicle(player,1) then return nil end
  return {Energy=profile.Energy,OwnedVehicles=profile.OwnedVehicles or {1},ActiveVehicle=profile.ActiveVehicle or 1}
 end
 local function character(player:Player): (BasePart?,Humanoid?)
  local model=player.Character
  local root=if model then model:FindFirstChild("HumanoidRootPart") else nil
  local hum=if model then model:FindFirstChildOfClass("Humanoid") else nil
  return if root and root:IsA("BasePart") then root else nil,hum
 end
 function adapter.nearStart(player:Player):boolean
  local root,hum=character(player)
  return root~=nil and hum~=nil and hum.Health>0 and (root.Position-Vector3.new(0,11,63)).Magnitude<=16
 end
 function adapter.begin(player:Player,state:any)
  stopTraining(player)
  local root,hum=character(player);assert(root and hum,"Missing rider")
  state.Character=player.Character;state.Root=root;state.Humanoid=hum;state.Lane=0
  state.RewardId=if state.Difficulty=="Test" then "test" else Http:GenerateGUID(false)
  state.Original={Anchored=root.Anchored,AutoRotate=hum.AutoRotate,WalkSpeed=hum.WalkSpeed,PlatformStand=hum.PlatformStand}
  local definition=Content.Vehicles[state.VehicleId]
  local asset=if state.VehicleId==1 then prototype else game:GetService("ReplicatedStorage").Vehicles:FindFirstChild(definition.Model)
  assert(asset,"Vehicle model missing")
  local bike=asset:Clone();state.Bike=bike;bike.Name="Mountainbike_"..player.UserId
  -- Build joints while still at prototype origin, before transporting the assembly.
  state.Rig=BikeRig.prepare(bike)
  bike:SetAttribute("VehicleId",state.VehicleId);bike:SetAttribute("Pedaling",state.VehicleId<=6);bike:SetAttribute("WheelRadius",if state.VehicleId==3 or state.VehicleId==8 then 1.15 else 1.43)
  bike:SetAttribute("OwnerUserId",player.UserId);bike:SetAttribute("RaceSpeed",0);bike:SetAttribute("Distance",0)
  bike.Parent=bikes
  state.BotModels={}
  for i,bot in ipairs(state.Bots) do
   local botAsset=game:GetService("ReplicatedStorage"):WaitForChild("Vehicles"):FindFirstChild("Vehicle2") or prototype
   local model=botAsset:Clone();table.insert(state.BotModels,model)
   local rig=BikeRig.prepare(model);model.Name="Bot_"..player.UserId.."_"..i
   model:SetAttribute("RaceSpeed",0);model:SetAttribute("Distance",0);model:SetAttribute("Bot",true)
   model.Parent=bikes;bot.Rig=rig;bot.Model=model;bot.Lane=({-8,-5,-2,3,7})[i]
  end
  player:SetAttribute("Racing",true)
  root.Anchored=true;hum.AutoRotate=false;hum.WalkSpeed=0;hum.PlatformStand=true
  feedback(player,{Kind="RaceStarted",RaceId=state.Id})
 end
 function adapter.reward(player:Player,state:any): (boolean,number)
  local amount=0
  local ok=data.change(player,function(profile:any):boolean
   local accepted
   accepted,amount=RaceRules.pay(profile,state)
   return accepted
  end)
  return ok,amount
 end
 function adapter.valid(player:Player,state:any):boolean
  return player.Parent==Players and player.Character==state.Character and state.Humanoid and state.Humanoid.Health>0
   and state.Root and state.Root.Parent~=nil and state.Bike and state.Bike.Parent==bikes and data.snapshot(player)~=nil
 end
 function adapter.move(player:Player,state:any,point:any)
  local position=Vector3.new(point.X+point.DZ*state.Lane,point.Y,point.Z-point.DX*state.Lane)
  local cf=CFrame.lookAt(position,position+Vector3.new(point.DX,0,point.DZ))
  state.Rig.Root.CFrame=cf
  state.Root.CFrame=cf*CFrame.new(0,4.8,0.9)
  state.Root.AssemblyLinearVelocity=Vector3.zero;state.Root.AssemblyAngularVelocity=Vector3.zero
  state.Bike:SetAttribute("RaceSpeed",state.Speed);state.Bike:SetAttribute("Distance",state.Distance)
  for _,bot in ipairs(state.Bots) do
   local p=Course.sample(bot.Distance);local pos=Vector3.new(p.X+p.DZ*bot.Lane,p.Y,p.Z-p.DX*bot.Lane)
   bot.Rig.Root.CFrame=CFrame.lookAt(pos,pos+Vector3.new(p.DX,0,p.DZ))
   bot.Model:SetAttribute("RaceSpeed",if bot.FinishedAt then 0 else bot.Speed);bot.Model:SetAttribute("Distance",bot.Distance)
  end
 end
 function adapter.cleanup(player:Player,state:any,reason:string)
  -- Restore controls even when a part was removed or Character changed during teardown.
  local ok,err=pcall(function()
   if state.Original then
    if state.Humanoid and state.Humanoid.Parent then
     state.Humanoid.AutoRotate=state.Original.AutoRotate;state.Humanoid.WalkSpeed=state.Original.WalkSpeed
     state.Humanoid.PlatformStand=state.Original.PlatformStand
    end
    if state.Root and state.Root.Parent then
     state.Root.Anchored=state.Original.Anchored
     if reason~="Disconnect" and player.Character==state.Character and state.Humanoid and state.Humanoid.Health>0 then
      state.Root.CFrame=CFrame.new(0,12,50);state.Root.AssemblyLinearVelocity=Vector3.zero;state.Root.AssemblyAngularVelocity=Vector3.zero
      state.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
     end
    end
   end
  end)
  if state.Original and (not state.Root or not state.Root.Parent) and reason~="Disconnect" and reason~="Shutdown"
   and player.Parent==Players and player.Character==state.Character and state.Humanoid and state.Humanoid.Health>0 then
   task.defer(function()
    if player.Parent==Players and player.Character==state.Character then
     local spawned,spawnError=pcall(function() player:LoadCharacterAsync() end)
     if not spawned then warn("[RaceRespawn]",player.UserId,tostring(spawnError)) end
    end
   end)
  end
  if state.Bike then state.Bike:Destroy() end
  for _,model in ipairs(state.BotModels or {}) do model:Destroy() end
  player:SetAttribute("Racing",false)
  if player.Parent==Players then feedback(player,{Kind="RaceEnded",Reason=reason,RaceId=state.Id,Place=state.Place,Reward=state.Reward,Difficulty=state.Difficulty}) end
  if not ok then warn("[RaceRestore]",player.UserId,tostring(err)) end
 end
 function adapter.log(event:string,err:string) warn("[Race]",event,err) end
 local controller=Logic.new(adapter,os.clock)
 local api:any={}
 function api.active(player:Player):boolean return controller.States[player]~=nil end
 function api.start(player:Player,difficulty:string?): (boolean,string?) return controller:start(player,difficulty) end
 function api.abort(player:Player) controller:finish(player,"Aborted") end
 function api.snapshot(player:Player):any
  local state=controller.States[player]
  return {Phase=if state then state.Phase else "Idle",Progress=if state then state.Distance/Course.Length else 0,
   Countdown=if state then math.max(0,Config.Race.Test.Countdown-math.floor(os.clock()-state.Started)) else 0,Speed=if state then state.Speed else 0,Place=if state then RaceRules.position(state) else 0,Difficulty=if state then state.Difficulty else "Easy",Opponents=if state then #state.Bots else 5}
 end
 function api.run()
  Players.PlayerRemoving:Connect(function(player) controller:remove(player) end)
  local function added(player:Player) player.CharacterRemoving:Connect(function() controller:finish(player,"Aborted") end) end
  Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers()) do added(p) end
  local zone=workspace:WaitForChild("World1"):WaitForChild("RacePreview"):WaitForChild("Platform")
  local prompt=Instance.new("ProximityPrompt");prompt.Name="StartTestRace";prompt.ActionText="Easy-Rennen starten";prompt.ObjectText="5 Bots • Cash gewinnen"
  prompt.MaxActivationDistance=12;prompt.HoldDuration=0.5;prompt.Parent=zone
  -- Runtime installs the shared limiter handler; prompts cannot bypass it.
  prompt.Triggered:Connect(function(player) if api.request then api.request(player) end end)
  task.spawn(function() while true do task.wait(1/15);controller:tick() end end)
  game:BindToClose(function() for p in pairs(controller.States) do controller:finish(p,"Shutdown") end end)
 end
 return api
end
return Race
