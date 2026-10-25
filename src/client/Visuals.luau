--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Pose=require(script.Parent.AvatarPose)
local Visuals={}
function Visuals.new(settings:any,ui:any):any
 local poses:any={};local bikes:any={};local connection:RBXScriptConnection?=nil
 local api:any={}
 local function restore()
  for player,pose in pairs(poses) do Pose.destroy(pose.Record);poses[player]=nil end
  for bike,record in pairs(bikes) do
   for motor,base in pairs(record.Bases) do if motor.Parent then motor.C0=base end end
   bikes[bike]=nil
  end
 end
 local function visible(character:Model?):boolean
  if not character then return false end
  local root=character:FindFirstChild("HumanoidRootPart")
  local camera=workspace.CurrentCamera
  return root~=nil and root:IsA("BasePart") and (not camera or (root.Position-camera.CFrame.Position).Magnitude<230)
 end
 local function frame(dt:number)
  local folder=workspace:FindFirstChild("ActiveRaceBikes")
  local riderBikes:any={}
  if folder then
   for _,bike in ipairs(folder:GetChildren()) do
    if not bike:IsA("Model") or not bike.PrimaryPart then continue end
    if bike:GetAttribute("Bot") and bike:GetAttribute("RaceOwnerUserId")~=Players.LocalPlayer.UserId then
     if not bike:GetAttribute("LocallyHidden") then
      for _,part in ipairs(bike:GetDescendants()) do if part:IsA("BasePart") then part.LocalTransparencyModifier=1 end end
      bike:SetAttribute("LocallyHidden",true)
     end
     continue
    end
    local camera=workspace.CurrentCamera
    if camera and (bike.PrimaryPart.Position-camera.CFrame.Position).Magnitude>230 then continue end
    local owner=bike:GetAttribute("OwnerUserId");if type(owner)=="number" then riderBikes[owner]=bike end
    if not settings.Animations then continue end
    local record=bikes[bike]
    if not record then
     record={Bases={},Wheel=0,Crank=0,Yaw=nil,Steer=0}
     for _,motor in ipairs(bike:GetDescendants()) do if motor:IsA("Motor6D") then record.Bases[motor]=motor.C0 end end
     bikes[bike]=record
    end
    local distance=bike:GetAttribute("Distance") or 0
    local speed=bike:GetAttribute("RaceSpeed") or 0
    local target=distance/(bike:GetAttribute("WheelRadius") or 1.43)
    record.Wheel+=(target-record.Wheel)*math.min(1,dt*18)
    if speed==0 then record.Wheel=target end
    record.Crank=record.Wheel/2.2
    local _,yaw=bike.PrimaryPart.CFrame:ToEulerAnglesYXZ()
    local change=if record.Yaw then math.atan2(math.sin(yaw-record.Yaw),math.cos(yaw-record.Yaw))/math.max(dt,0.001) else 0
    record.Yaw=yaw;record.Steer+=(math.clamp(change*0.1,-0.18,0.18)-record.Steer)*math.min(1,dt*9)
    for motor,base in pairs(record.Bases) do
     if motor.Name=="SteeringMotor" then motor.C0=base*CFrame.Angles(0,record.Steer,0)
     elseif motor.Name=="CrankMotor" then motor.C0=base*CFrame.Angles(-record.Crank,0,0)
     elseif motor.Name=="FrameMotor" then motor.C0=base*CFrame.new(0,if bike:GetAttribute("Pedaling")==false and speed>0 then math.sin(os.clock()*28)*0.015 else 0,0)*CFrame.Angles(0,0,-record.Steer*0.4)
     else motor.C0=base*CFrame.Angles(-record.Wheel,0,0) end
    end
    -- A small visual roll of the frame group, without moving authoritative root/path.
   end
  end
  for bike in pairs(bikes) do if not bike.Parent then bikes[bike]=nil end end
  for _,player in ipairs(Players:GetPlayers()) do
   local character=player.Character
   local bike=riderBikes[player.UserId]
   local training=(player:GetAttribute("SelectedTreadmill") or 0)>0
   local wanted=settings.Animations and visible(character) and (bike~=nil or training)
   local current=poses[player]
   if current and (current.Character~=character or wanted and current.Bike~=bike) then Pose.destroy(current.Record);poses[player]=nil;current=nil end
   if current and not wanted then
    current.Exit=(current.Exit or 0)+dt;Pose.fade(current.Record,math.min(1,dt*18))
    if current.Exit>=0.2 then Pose.destroy(current.Record);poses[player]=nil;current=nil end
   end
   if wanted and character then
    if not current then local record=Pose.new(character,bike);if record then current={Record=record,Character=character,Bike=bike};poses[player]=current end end
    if current then
     current.Exit=nil
     local phase=if bike and bike:GetAttribute("Pedaling")==false then 0 elseif bike and bikes[bike] then bikes[bike].Crank else os.clock()*7
     Pose.update(current.Record,phase,bike~=nil,math.min(1,dt*12))
    end
   end
  end
  for player,pose in pairs(poses) do if player.Parent~=Players then Pose.destroy(pose.Record);poses[player]=nil end end
  if ui.Viewport and ui.Viewport.Frame.Parent and settings.Animations then
   local angle=os.clock()*0.22
   ui.Viewport.Camera.CFrame=CFrame.lookAt(Vector3.new(math.sin(angle)*(ui.Viewport.Distance or 10),(ui.Viewport.TargetY or 2)+3,math.cos(angle)*(ui.Viewport.Distance or 10)),Vector3.new(0,ui.Viewport.TargetY or 2,0))
  end
 end
 function api.refresh()
  if not settings.Animations then restore() end
  -- One shared connection; idle when no avatars, bikes or garage are active.
 end
 local function updateConnection()
  local active=ui.Viewport~=nil or next(poses)~=nil
  for _,player in ipairs(Players:GetPlayers()) do if visible(player.Character) and (player:GetAttribute("Racing") or (player:GetAttribute("SelectedTreadmill") or 0)>0) then active=true;break end end
  local folder=workspace:FindFirstChild("ActiveRaceBikes")
  local camera=workspace.CurrentCamera
  if not active and folder and camera then
   for _,model in ipairs(folder:GetChildren()) do if model:IsA("Model") and model.PrimaryPart and (model.PrimaryPart.Position-camera.CFrame.Position).Magnitude<230 and (model:GetAttribute("RaceSpeed") or 0)>0 then active=true;break end end
  end
  if active and settings.Animations and not connection then connection=RunService.PreSimulation:Connect(frame)
  elseif (not active or not settings.Animations) and connection then connection:Disconnect();connection=nil;restore() end
 end
 task.spawn(function() while ui.Gui.Parent do updateConnection();task.wait(0.2) end;if connection then connection:Disconnect() end;restore() end)
 return api
end
return Visuals
