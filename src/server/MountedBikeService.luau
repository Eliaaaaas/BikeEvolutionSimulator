--!strict
local Players=game:GetService("Players")
local Rep=game:GetService("ReplicatedStorage")
local Shared=Rep:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Content=require(Shared:WaitForChild("World1Content"))
local Sim=require(Shared:WaitForChild("RideSimulation"))
local Surface=require(Shared:WaitForChild("BikeSurface"))
local Geometry=require(Shared:WaitForChild("RiderMount"))
local Rig=require(Shared:WaitForChild("BikeRig"))
local Protocol=require(Shared:WaitForChild("Protocol"))
local Limiter=require(Shared:WaitForChild("RateLimiter"))
local Progression=require(Shared:WaitForChild("Progression"))
local Service={}
function Service.new(data:any):any
 local folder=Instance.new("Folder");folder.Name="PlayerBikes";folder.Parent=workspace
 local records:{[Player]:any}={}
 local sequence:{[Player]:number}={}
 local gate=Limiter.new(16,40,os.clock)
 local epoch:{[Player]:number}={}
 local stateSink:any=function() end
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
  local record:any={Character=char,Root=root,Humanoid=hum,Bike=bike,Rig=rig,VehicleId=id,InventoryRevision=revision,Mode="Manual",Connections={},Speed=0,Yaw=if old then old.Yaw else 0,Distance=if old then old.Distance else 0,Input={Throttle=0,Steer=0,Brake=true,At=0}}
  record.Offset=Geometry.offset(bike,char)
  local initial=if old then old.Frame else CFrame.new(root.Position.X,root.Position.Y-record.Offset.Position.Y,root.Position.Z-record.Offset.Position.Z)
  if not old then
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char,folder};params.RespectCanCollide=true
   local floor=workspace:Raycast(root.Position+Vector3.new(0,6,0),Vector3.new(0,-24,0),params)
   if floor then initial=CFrame.new(initial.Position.X,floor.Position.Y+.05,initial.Position.Z) end
  end
  Geometry.place(rig,initial);record.Frame=initial
  epoch[player]=(epoch[player] or 0)+1;record.Epoch=epoch[player];record.Queue={};record.Processed=sequence[player] or 0;record.AckAt=0
  record.State=if old and old.State then table.clone(old.State) else Sim.new(initial.Position.X,initial.Position.Y,initial.Position.Z,record.Yaw)
  record.State.JumpId=player:GetAttribute("DriveJumpId") or 0
  player:SetAttribute("DriveEpoch",record.Epoch)
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
 function api.setStateSink(callback:any) stateSink=callback end
 local function maxSpeed(player:Player,r:any):number
  local snap=data.snapshot(player)
  return Progression.islandSpeed(if snap then snap.Energy else 0,Content.Vehicles[r.VehicleId].Speed,player:GetAttribute("SlowMode")==true)
 end
 function api.auto(player:Player,input:any)
  local r=records[player];if not r then return end
  local changed=(r.Auto~=nil)~=(input~=nil)
  r.Auto=input;player:SetAttribute("AutoDriving",input~=nil)
  if changed then r.Queue={};r.LastCommand=nil;r.Speed=0;r.State.Speed=0 end
 end
 local function sendState(player:Player,r:any)
  if not r.State then return end
  r.Ack=(r.Ack or 0)+1
  stateSink(player,{Ack=r.Ack,Epoch=r.Epoch,Sequence=r.Processed,State=table.clone(r.State),Mode=r.Mode,VehicleId=r.VehicleId,MaxSpeed=maxSpeed(player,r)})
 end
 function api.input(player:Player,payload:any):boolean
  if player.Parent~=Players or not gate:allow(player) or not Protocol.validDrive(payload) then return false end
  local r=records[player]
  if not r or r.Mode~="Manual" or player:GetAttribute("Racing")==true or not data.snapshot(player) then return false end
  if payload.Epoch~=nil and payload.Epoch~=r.Epoch or payload.Sequence<=(sequence[player] or 0) or #r.Queue>=Config.Bike.QueueLimit then return false end
  sequence[player]=payload.Sequence;player:SetAttribute("DriveSequence",payload.Sequence)
  table.insert(r.Queue,{Throttle=payload.Throttle,Steer=payload.Steer,Brake=payload.Brake,JumpId=payload.JumpId or r.State.JumpId,Sequence=payload.Sequence})
  r.Input.At=os.clock()
  return true
 end
 function api.onBelt(player:Player,zone:BasePart):boolean
  local r=records[player]
  return r~=nil and r.Mode=="Manual" and Sim.onBelt(r.State,zone.Position.X,zone.Position.Y,zone.Position.Z,zone.Size.X,zone.Size.Z)
 end
 function api.race(player:Player):any
  local record=api.ensure(player);assert(record,"Mounted rider unavailable")
  record.Mode="Race";record.Queue={};record.Speed=0;record.Input={Throttle=0,Steer=0,Brake=true,At=0}
  sendState(player,record)
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
  local scene=Surface.new(workspace,{record.Character,folder},6)
  local floor=scene.floor(cf.Position.X,cf.Position.Y,cf.Position.Z)
  if floor and math.abs(cf.Position.Y-floor-.05)<=Config.Bike.StepHeight then cf=CFrame.new(cf.Position.X,floor+.05,cf.Position.Z)*CFrame.Angles(0,yaw,0) end
  record.State=Sim.new(cf.Position.X,cf.Position.Y,cf.Position.Z,yaw)
  record.State.Distance=record.Distance;record.State.JumpId=player:GetAttribute("DriveJumpId") or 0;record.Queue={};record.LastCommand=nil
  api.move(record,cf,0,record.Distance)
 end
 function api.finish(player:Player,record:any,reason:string)
  if records[player]~=record then return end
  record.Mode="Manual";record.Speed=0;record.Yaw=0;record.Input={Throttle=0,Steer=0,Brake=true,At=0}
  if player.Character==record.Character and record.Root.Parent and record.Humanoid.Health>0 and reason~="Disconnect" and reason~="Shutdown" then
   epoch[player]=(epoch[player] or 0)+1;record.Epoch=epoch[player];player:SetAttribute("DriveEpoch",record.Epoch)
   record.Queue={};record.Processed=sequence[player] or 0
   record.State=Sim.new(0,8.05,50,0);record.State.Distance=record.Distance;record.State.JumpId=player:GetAttribute("DriveJumpId") or 0
   api.move(record,CFrame.new(0,8.05,50),0,record.Distance);seated(record);sendState(player,record)
  end
 end
 function api.tick(dt:number):boolean
  local ran=false
  for _,player in ipairs(Players:GetPlayers()) do
   local record=api.ensure(player)
   if not record then if records[player] then drop(player) end;continue end
   if record.Mode~="Manual" or player:GetAttribute("Racing")==true then continue end
   record.Humanoid.Sit=true;record.Humanoid.Jump=false;record.Humanoid.WalkSpeed=0;record.Humanoid.AutoRotate=false;record.Humanoid.PlatformStand=true
   record.Root.Anchored=false;record.Rig.Root.Anchored=true
   record.Humanoid:Move(Vector3.zero,false)
   local height=math.max(5.8,record.Offset.Position.Y+record.Root.Size.Y+1)
   local scene=Surface.new(workspace,{record.Character,folder},height)
   record.CommandPhase=(record.CommandPhase or 0)+1
   if record.CommandPhase>=Config.Bike.CommandSteps then
    record.CommandPhase=0
    local command:any=table.remove(record.Queue,1)
    if command then record.LastCommand=command
    elseif record.LastCommand and os.clock()-record.Input.At<Config.Bike.InputTimeout then command=table.clone(record.LastCommand :: {[string]:any});command.Sequence=nil
    else command={Throttle=0,Steer=0,Brake=true,JumpId=record.State.JumpId} end
    if record.Auto then
     if command.Sequence then record.Processed=command.Sequence end
     record.State.JumpId=math.max(record.State.JumpId,command.JumpId or record.State.JumpId)
     command=record.Auto
    end
    ran=true
    record.State=Sim.command(record.State,command,maxSpeed(player,record),scene)
    if command.Sequence then record.Processed=command.Sequence end
    player:SetAttribute("DriveJumpId",record.State.JumpId)
    record.Speed=record.State.Speed;record.Yaw=record.State.Yaw
    if record.State.Y< -35 then record.Humanoid.Health=0 end
    local training=(player:GetAttribute("SelectedTreadmill") or 0)>0 and record.State.Grounded
    local distance=record.State.Distance
    if training then distance+=10*Config.Bike.InputInterval;record.State.Distance=distance end
    api.move(record,CFrame.new(record.State.X,record.State.Y,record.State.Z)*CFrame.Angles(0,record.State.Yaw,0),if training then 10 else math.abs(record.Speed),distance)
   end
   if os.clock()-record.AckAt>=Config.Bike.AckInterval then record.AckAt=os.clock();sendState(player,record) end
  end
  return ran
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
  Players.PlayerRemoving:Connect(function(player) drop(player);sequence[player]=nil;epoch[player]=nil;gate:remove(player) end)
  task.spawn(function()
   local last=os.clock();local failed=false
   while true do
    task.wait(Config.Bike.Tick);local now=os.clock()
    local ok,err=pcall(api.tick,math.min(now-last,.1));last=now
    if not ok and not failed then warn("[PermanentBike]",tostring(err)) end
    if (not ok or err==true) and failed~=not ok then
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
