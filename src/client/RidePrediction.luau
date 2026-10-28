--!strict
-- Only the cosmetic local assembly is predicted; the replicated assembly is server-owned.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Rep=game:GetService("ReplicatedStorage")
local Shared=Rep:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Sim=require(Shared:WaitForChild("RideSimulation"))
local Surface=require(Shared:WaitForChild("BikeSurface"))
local Replay=require(Shared:WaitForChild("RideReconciliation"))
local Rig=require(Shared:WaitForChild("BikeRig"))
local Geometry=require(Shared:WaitForChild("RiderMount"))
local Content=require(Shared:WaitForChild("World1Content"))
local Prediction={}
function Prediction.new(ui:any,stateRemote:RemoteEvent):any
 local player=Players.LocalPlayer
 local reconciler=Replay.new()
 local folder=Instance.new("Folder");folder.Name="LocalBikePresentation";folder.Parent=workspace
 local hidden:{[BasePart]:number}={}
 local api:any={Active=false,Bike=nil,Character=nil,Epoch=0,Sequence=0}
 local rig:any=nil;local scene:any=nil;local rendered:CFrame?=nil;local vehicle=0
 local maxSpeed=Config.Bike.BaseSpeed
 local currentInput:any={Throttle=0,Steer=0,Brake=true,JumpId=0}
 local lastCommand=os.clock();local lastAck=os.clock()
 local function reset()
  api.Active=false
  for part,value in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=value end end;table.clear(hidden)
  if api.Bike then api.Bike:Destroy() end
  if api.Character then api.Character:Destroy() end
  api.Bike=nil;api.Character=nil;rig=nil;rendered=nil;vehicle=0
  -- Camera ownership belongs exclusively to RaceCamera (manual and race).
 end
 local function hide(model:Model)
  for _,part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") then
    if hidden[part]==nil then hidden[part]=part.LocalTransparencyModifier end
    part.LocalTransparencyModifier=1
   end
  end
 end
 local function build(id:number,state:any):boolean
  reset()
  local character=player.Character
  if not character then return false end
  local asset=Rep:WaitForChild("Vehicles"):FindFirstChild(Content.Vehicles[id].Model) :: Model?
  if not asset then return false end
  local was=character.Archivable;character.Archivable=true
  local copy=character:Clone();character.Archivable=was
  local bike=asset:Clone();bike.Name="PredictedRider";copy.Name="PredictedAvatar"
  for _,node in ipairs(copy:GetDescendants()) do
   if node:IsA("Script") or node:IsA("LocalScript") or node:IsA("IKControl") or node.Name=="LocalRiderTarget" or node.Name=="LocalRiderPole" then node:Destroy()
   elseif node:IsA("Motor6D") then
    node.Transform=CFrame.identity
    local base=node:GetAttribute("RiderBaseC0")
    if typeof(base)=="CFrame" then
     local angle=if string.find(node.Name,"Hip") then -1.15 elseif string.find(node.Name,"Knee") then 1.3 elseif string.find(node.Name,"Shoulder") then -1.1 elseif string.find(node.Name,"Elbow") then -.55 elseif node.Name=="Waist" then -.25 else 0
     node.C0=base*CFrame.Angles(angle,0,0)
    end
   elseif node:IsA("BasePart") then node.Anchored=false;node.CanCollide=false;node.CanTouch=false;node.CanQuery=false;node.Massless=true;node.LocalTransparencyModifier=0 end
  end
  local root=copy:FindFirstChild("HumanoidRootPart") :: BasePart?
  local hum=copy:FindFirstChildOfClass("Humanoid")
  if not root or not hum then copy:Destroy();bike:Destroy();return false end
  hum.WalkSpeed=0;hum.AutoRotate=false;hum.PlatformStand=true;hum.Sit=true
  rig=Rig.prepare(bike)
  local cf=CFrame.new(state.X,state.Y,state.Z)*CFrame.Angles(0,state.Yaw,0)
  Geometry.place(rig,cf)
  local offset=Geometry.offset(bike,copy)
  local weld=Instance.new("Weld");weld.Name="PermanentRiderMount";weld.Part0=rig.Frame;weld.Part1=root;weld.C0=rig.FrameFromRoot:Inverse()*offset;weld.Parent=rig.Frame
  bike:SetAttribute("OwnerUserId",player.UserId);bike:SetAttribute("VehicleId",id);bike:SetAttribute("Pedaling",id<=6);bike:SetAttribute("WheelRadius",if id==3 or id==8 then 1.15 else 1.43)
  for _,part in ipairs(bike:GetDescendants()) do if part:IsA("BasePart") then part.CanQuery=false end end
  bike.Parent=folder;copy.Parent=folder
  api.Bike=bike;api.Character=copy;api.Active=true;vehicle=id;rendered=cf
  scene=Surface.new(workspace,{character,folder,workspace:WaitForChild("PlayerBikes")},math.max(5.8,offset.Position.Y+root.Size.Y+1))
  return true
 end
 function api.intent(input:any) currentInput=input end
 function api.command(sequence:number,input:any)
  if not api.Active or not scene then return end
  Replay.command(reconciler,sequence,input,maxSpeed,scene);lastCommand=os.clock()
 end
 local ack=stateRemote.OnClientEvent:Connect(function(message)
  if not Replay.valid(message) or not Content.Vehicles[message.VehicleId] then return end
  -- Ignore stale epochs before changing the currently visible assembly.
  if type(message.Epoch)~="number" or message.Epoch<math.max(reconciler.Epoch,player:GetAttribute("DriveEpoch") or 0) then return end
  if message.Epoch==reconciler.Epoch and (message.Ack<=reconciler.Ack or message.Sequence<reconciler.Sequence) then return end
  if message.Mode~="Manual" or player:GetAttribute("Racing")==true or player:GetAttribute("AutoDriving")==true then reset();return end
  local changed=not api.Active or vehicle~=message.VehicleId or message.Epoch~=reconciler.Epoch
  if changed and not build(message.VehicleId,message.State) then return end
  if Replay.accept(reconciler,message,scene) then
   lastAck=os.clock();api.Epoch=reconciler.Epoch;api.Sequence=message.Sequence;api.JumpId=message.State.JumpId;maxSpeed=message.MaxSpeed
  end
 end)
 Run:BindToRenderStep("BikePresentation",Enum.RenderPriority.Camera.Value-2,function(dt:number)
  if not api.Active or not rig or not reconciler.State or player:GetAttribute("Racing")==true then return end
  if os.clock()-lastAck>Config.Bike.InputTimeout+.2 then reset();return end
  local state=table.clone(reconciler.State)
  local left=math.clamp(os.clock()-lastCommand,0,Config.Bike.InputInterval)
  while left>1e-6 do local step=math.min(Config.Bike.Tick,left);state=Sim.step(state,currentInput,step,maxSpeed,scene);left-=step end
  local target=CFrame.new(state.X,state.Y,state.Z)*CFrame.Angles(0,state.Yaw,0)
  if rendered and (rendered.Position-target.Position).Magnitude<12 then rendered=rendered:Lerp(target,1-math.exp(-math.min(dt,.1)*40)) else rendered=target end
  rig.Root.CFrame=rendered :: CFrame
  api.Bike:SetAttribute("Distance",state.Distance);api.Bike:SetAttribute("RaceSpeed",if (player:GetAttribute("SelectedTreadmill") or 0)>0 then 10 else math.abs(state.Speed))
  local authority=workspace:FindFirstChild("PlayerBikes")
  if authority then local model=authority:FindFirstChild("Rider_"..player.UserId);if model and model:IsA("Model") then hide(model) end end
  if player.Character then hide(player.Character) end
  -- Camera reads the rendered bike AFTER this presentation update.
 end)
 local racing=player:GetAttributeChangedSignal("Racing"):Connect(function() if player:GetAttribute("Racing")==true then reset() end end)
 local removing=player.CharacterRemoving:Connect(function() reset();reconciler=Replay.new() end)
 ui.Gui.Destroying:Connect(function() ack:Disconnect();Run:UnbindFromRenderStep("BikePresentation");racing:Disconnect();removing:Disconnect();reset();folder:Destroy() end)
 return api
end
return Prediction
