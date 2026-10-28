--!strict
local Players=game:GetService("Players")
local Rep=game:GetService("ReplicatedStorage")
local Shared=Rep:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Content=require(Shared:WaitForChild("World1Content"))
local Motion=require(Shared:WaitForChild("BikeMotion"))
local Geometry=require(Shared:WaitForChild("RiderMount"))
local Rig=require(Shared:WaitForChild("BikeRig"))
local Protocol=require(Shared:WaitForChild("Protocol"))
local Limiter=require(Shared:WaitForChild("RateLimiter"))
local Service={}
function Service.new(data:any):any
 local folder=Instance.new("Folder");folder.Name="PlayerBikes";folder.Parent=workspace
 local records:{[Player]:any}={}
 local sequence:{[Player]:number}={}
 local gate=Limiter.new(20,15,os.clock)
 local api:any={}
 local function poseNode(node:Instance)
  if node:IsA("BasePart") then node.CanCollide=false
  elseif node:IsA("LocalScript") and node.Name=="Animate" then node.Disabled=true
  elseif node:IsA("Motor6D") and node:GetAttribute("RiderBaseC0")==nil then
   local base=node.C0;node:SetAttribute("RiderBaseC0",base)
   local angle=if string.find(node.Name,"Hip") then -1.15 elseif string.find(node.Name,"Knee") then 1.3 elseif string.find(node.Name,"Shoulder") then -1.1 elseif string.find(node.Name,"Elbow") then -.55 elseif node.Name=="Waist" then -.25 else 0
   node.C0=base*CFrame.Angles(angle,0,0)
  end
 end
 local function seated(record:any)
  local hum=record.Humanoid
  hum.WalkSpeed=0;hum.AutoRotate=false;hum.PlatformStand=true;hum.Sit=true;hum.Jump=false
  local animator=hum:FindFirstChildOfClass("Animator")
  if animator then
   for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
  end
  record.Root.Anchored=false;record.Rig.Root.Anchored=true
  hum:Move(Vector3.zero,false);hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
  -- Replicated fallback pose also works before client IK loads and with effects disabled.
  for _,node in ipairs(record.Character:GetDescendants()) do poseNode(node) end
 end
 local function drop(player:Player)
  local r=records[player];if r then for _,c in ipairs(r.Connections) do c:Disconnect() end;r.Bike:Destroy();records[player]=nil end
  player:SetAttribute("Mounted",false)
 end
 function api.ensure(player:Player):any
  local char=player.Character
  local root=if char then char:FindFirstChild("HumanoidRootPart") else nil
  local hum=if char then char:FindFirstChildOfClass("Humanoid") else nil
  if not char or not root or not root:IsA("BasePart") or not hum or hum.Health<=0 or not char:IsDescendantOf(workspace) then return nil end
  local old=records[player]
  if old and old.Character~=char then drop(player);old=nil end
  local ready=data.snapshot(player)~=nil
  local revision=if ready then data.inventoryRevision(player) else -1
  local profile=if ready and (not old or old.InventoryRevision~=revision) then data.read(player) else nil
  local id=if profile then profile.ActiveVehicle or 1 elseif old then old.VehicleId else 1
  if not Content.Vehicles[id] then id=1 end
  if old and old.Bike.Parent and old.Rig.Root.Parent and old.Weld.Parent and (old.VehicleId==id or player:GetAttribute("Racing")==true) then
   old.InventoryRevision=revision
   if old.SizingDirty then
    old.Offset=Geometry.offset(old.Bike,char);old.Weld.C0=old.Rig.FrameFromRoot:Inverse()*old.Offset;old.SizingDirty=false
   end
   return old
  end
  -- Construct the replacement before removing the old model: never unmount the rider.
  local definition=Content.Vehicles[id]
  local asset=Rep:WaitForChild("Vehicles"):FindFirstChild(definition.Model)
  assert(asset and asset:IsA("Model"),"Mounted vehicle missing: "..definition.Model)
  local bike=asset:Clone();bike.Name="Rider_"..player.UserId;bike.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
  local rig=Rig.prepare(bike)
  local record={Character=char,Root=root,Humanoid=hum,Bike=bike,Rig=rig,VehicleId=id,InventoryRevision=revision,Mode="Manual",Connections={},Speed=0,Yaw=if old then old.Yaw else 0,Distance=if old then old.Distance else 0,Input={Throttle=0,Steer=0,Brake=true,At=0}}
  record.Offset=Geometry.offset(bike,char)
  local initial=if old then old.Frame else CFrame.new(root.Position.X,root.Position.Y-record.Offset.Position.Y,root.Position.Z-record.Offset.Position.Z)
  if not old then
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char,folder};params.RespectCanCollide=true
   local floor=workspace:Raycast(root.Position+Vector3.new(0,6,0),Vector3.new(0,-24,0),params)
   if floor then initial=CFrame.new(initial.Position.X,floor.Position.Y+.05,initial.Position.Z) end
  end
  Geometry.place(rig,initial);record.Frame=initial
  -- Only the vehicle root is anchored and positioned. The avatar is a passenger joint.
  local weld=Instance.new("Weld");weld.Name="PermanentRiderMount"
  weld.Part0=rig.Frame;weld.Part1=root;weld.C0=rig.FrameFromRoot:Inverse()*record.Offset
  record.Weld=weld;seated(record)
  weld.Parent=rig.Frame
  bike:SetAttribute("VehicleId",id);bike:SetAttribute("OwnerUserId",player.UserId);bike:SetAttribute("Pedaling",id<=6)
  bike:SetAttribute("WheelRadius",if id==3 or id==8 then 1.15 else 1.43)
  bike:SetAttribute("RaceSpeed",0);bike:SetAttribute("Distance",record.Distance);bike.Parent=folder
  records[player]=record;player:SetAttribute("Mounted",true)
  local watched:{[Instance]:boolean}={}
  local function watchSize(part:Instance)
   if part:IsA("BasePart") and not watched[part] and (part.Name=="HumanoidRootPart" or part.Name=="LowerTorso" or part.Name=="Torso") then
    watched[part]=true
    table.insert(record.Connections,part:GetPropertyChangedSignal("Size"):Connect(function() record.SizingDirty=true end))
   end
   if part:IsA("Animator") then
    table.insert(record.Connections,part.AnimationPlayed:Connect(function(track) track:Stop(0) end))
   end
  end
  for _,part in ipairs(char:GetDescendants()) do watchSize(part) end
  table.insert(record.Connections,char.DescendantAdded:Connect(function(node)
   if records[player]==record then poseNode(node);watchSize(node);record.SizingDirty=true end
  end))
  player.CameraMinZoomDistance=10;player.CameraMaxZoomDistance=60
  if old then for _,c in ipairs(old.Connections) do c:Disconnect() end;old.Bike:Destroy() end
  return record
 end
 function api.input(player:Player,payload:any):boolean
  if player.Parent~=Players or not gate:allow(player) or not Protocol.validDrive(payload) then return false end
  if payload.Sequence<=(sequence[player] or 0) then return false end
  sequence[player]=payload.Sequence;player:SetAttribute("DriveSequence",payload.Sequence)
  local record=records[player]
  if not record or record.Mode~="Manual" or player:GetAttribute("Racing")==true or not data.snapshot(player) then return false end
  record.Input={Throttle=payload.Throttle,Steer=payload.Steer,Brake=payload.Brake,At=os.clock()}
  return true
 end
 function api.race(player:Player):any
  local record=api.ensure(player);assert(record,"Mounted rider unavailable")
  record.Mode="Race";record.Speed=0;record.Input={Throttle=0,Steer=0,Brake=true,At=0}
  return record
 end
 function api.move(record:any,cf:CFrame,speed:number,distance:number)
  record.Frame=cf
  record.Rig.Root.CFrame=cf
  record.Rig.Root.AssemblyLinearVelocity=Vector3.zero;record.Rig.Root.AssemblyAngularVelocity=Vector3.zero
  record.Distance=distance
  record.Bike:SetAttribute("RaceSpeed",speed);record.Bike:SetAttribute("Distance",distance)
 end
 function api.teleport(player:Player,cf:CFrame)
  local record=api.ensure(player);if not record then return end
  record.Speed=0;local _,yaw=cf:ToEulerAnglesYXZ();record.Yaw=yaw
  api.move(record,cf,0,record.Distance)
 end
 function api.finish(player:Player,record:any,reason:string)
  if records[player]~=record then return end
  record.Mode="Manual";record.Speed=0;record.Yaw=0;record.Input={Throttle=0,Steer=0,Brake=true,At=0}
  if player.Character==record.Character and record.Root.Parent and record.Humanoid.Health>0 and reason~="Disconnect" and reason~="Shutdown" then
   api.move(record,CFrame.new(0,8.05,50),0,record.Distance);seated(record)
  end
 end
 function api.tick(dt:number)
  for _,player in ipairs(Players:GetPlayers()) do
   local record=api.ensure(player)
   if not record then if records[player] then drop(player) end;continue end
   if record.Mode~="Manual" or player:GetAttribute("Racing")==true then continue end
   record.Humanoid.Sit=true;record.Humanoid.Jump=false;record.Humanoid.WalkSpeed=0;record.Humanoid.AutoRotate=false;record.Humanoid.PlatformStand=true
   record.Root.Anchored=false;record.Rig.Root.Anchored=true
   record.Humanoid:Move(Vector3.zero,false)
   local input=record.Input
   if os.clock()-input.At>Config.Bike.InputTimeout then input={Throttle=0,Steer=0,Brake=true} end
   local motion=Motion.step(record.Speed,record.Yaw,input.Throttle,input.Steer,input.Brake,dt,math.min(Config.Bike.MaxSpeed,Config.Bike.BaseSpeed*Content.Vehicles[record.VehicleId].Speed))
   local current=record.Frame.Position
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={record.Character,folder};params.RespectCanCollide=true
   local ground=workspace:Raycast(Vector3.new(current.X+motion.DX,current.Y+Config.Bike.StepHeight+.5,current.Z+motion.DZ),Vector3.new(0,-6,0),params)
   local y=if ground then ground.Position.Y+.05 else current.Y
   local supported=ground~=nil
   for _,wheel in ipairs({-2.6,2.6}) do
    local x=current.X+motion.DX-math.sin(motion.Yaw)*wheel
    local z=current.Z+motion.DZ-math.cos(motion.Yaw)*wheel
    local support=workspace:Raycast(Vector3.new(x,current.Y+Config.Bike.StepHeight+.5,z),Vector3.new(0,-6,0),params)
    if not support then supported=false else y=math.max(y,support.Position.Y+.05) end
   end
   local step=math.abs(y-current.Y)<=Config.Bike.StepHeight
   local delta=Vector3.new(motion.DX,0,motion.DZ)
   local height=math.max(5.8,record.Offset.Position.Y+record.Root.Size.Y+1)
   local hit=if delta.Magnitude>.001 then workspace:Blockcast(CFrame.new(current.X,math.max(current.Y,y)+.4+height/2,current.Z),Vector3.new(7.8,height,7.8),delta,params) else nil
   local accepted=supported and step and hit==nil
   local x=current.X+(if accepted then motion.DX else 0);local z=current.Z+(if accepted then motion.DZ else 0)
   record.Speed=if accepted then motion.Speed else 0;record.Yaw=motion.Yaw
   if accepted then record.Distance+=math.abs(record.Speed)*math.min(dt,.1) end
   local training=(player:GetAttribute("SelectedTreadmill") or 0)>0
   if training then record.Distance+=10*math.min(dt,.1) end
   api.move(record,CFrame.new(x,if accepted then y else current.Y,z)*CFrame.Angles(0,record.Yaw,0),if training then 10 else math.abs(record.Speed),record.Distance)
  end
 end
 function api.start()
  local function added(player:Player)
   player.CharacterAdded:Connect(function(character)
    -- Freeze as soon as the root exists; the normal movement controller cannot walk away.
    local root=character:WaitForChild("HumanoidRootPart",15)
    if root and root:IsA("BasePart") then root.Anchored=true end
    character:WaitForChild("Humanoid",15)
    if player.Character==character then api.ensure(player) end
   end)
   player.CharacterRemoving:Connect(function() drop(player) end)
   api.ensure(player)
  end
  Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers()) do added(p) end
  Players.PlayerRemoving:Connect(function(player) drop(player);sequence[player]=nil;gate:remove(player) end)
  task.spawn(function()
   local last=os.clock();local failed=false
   while true do
    task.wait(Config.Bike.Tick);local now=os.clock()
    local ok,err=pcall(api.tick,math.min(now-last,.1));last=now
    if not ok and not failed then warn("[PermanentBike]",tostring(err)) end
    if failed~=not ok then
     failed=not ok
     local runtime=Rep:FindFirstChild("BikeRuntime")
     if runtime then
      runtime:SetAttribute("BikeState",if failed then "Failed" else "Ready")
      runtime:SetAttribute("BikeError",if failed then (if runtime:GetAttribute("Diagnostics")==true then string.sub(tostring(err),1,600) else "Fahrzeugsteuerung nicht verfügbar") else nil)
     end
    end
   end
  end)
 end
 return api
end
return Service
