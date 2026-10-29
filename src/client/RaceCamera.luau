--!strict
-- Single camera owner. Native Roblox orbit/zoom for island; scripted chase only during a race.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Camera={}
function Camera.new(settings:any,ui:any)
 local player=Players.LocalPlayer
 local anchor=Instance.new("Part");anchor.Name="BikeCameraTarget";anchor.Size=Vector3.new(.1,.1,.1)
 anchor.Anchored=true;anchor.Transparency=1;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.Parent=workspace
 local active:Camera?=nil;local saved:any=nil;local target:Vector3?=nil;local wasRace=false;local teleportSerial=player:GetAttribute("BikeTeleportSerial") or 0
 local function restore()
  if active and saved then active.CameraType=saved.Type;active.CameraSubject=saved.Subject;active.FieldOfView=saved.Fov end
  active=nil;saved=nil;target=nil
 end
 local function frame(dt:number)
  local camera=workspace.CurrentCamera
  local character=player.Character
  local hum=if character then character:FindFirstChildOfClass("Humanoid") else nil
  if not camera or not hum or hum.Health<=0 then return end
  if active~=camera then restore();active=camera;saved={Type=camera.CameraType,Subject=camera.CameraSubject,Fov=camera.FieldOfView} end
  local prediction=ui.Prediction
  local bike=if prediction and prediction.Active then prediction.Bike else nil
  if not bike then local folder=workspace:FindFirstChild("PlayerBikes");bike=if folder then folder:FindFirstChild("Rider_"..player.UserId) else nil end
  local root=if bike then bike:FindFirstChild("Root") else nil
  if not root or not root:IsA("BasePart") then return end
  local racing=player:GetAttribute("Racing")==true
  local desired=root.Position+Vector3.new(0,4,0)
  local serial=player:GetAttribute("BikeTeleportSerial") or 0
  if not target or (target-desired).Magnitude>20 or wasRace~=racing or serial~=teleportSerial then target=desired
  else target=target:Lerp(desired,1-math.exp(-math.min(dt,.1)*35)) end
  wasRace=racing;teleportSerial=serial
  anchor.CFrame=CFrame.new(target :: Vector3)
  if racing then
   camera.CameraType=Enum.CameraType.Scriptable
   local forward=root.CFrame.LookVector
   local chase=CFrame.lookAt((target :: Vector3)-forward*17+Vector3.new(0,5,0),(target :: Vector3)+forward*9)
   camera.CFrame=camera.CFrame:Lerp(chase,1-math.exp(-math.min(dt,.1)*14));camera.FieldOfView=65
  else
   camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=anchor
   camera.FieldOfView=if saved then saved.Fov else 70
  end
 end
 -- Presentation at Camera-2; subject at Camera-1; native orbit runs at Camera.
 Run:BindToRenderStep("BikeCameraSubject",Enum.RenderPriority.Camera.Value-1,frame)
 frame(0)
 local removing=player.CharacterRemoving:Connect(function() target=nil end)
 ui.Gui.Destroying:Connect(function()
  Run:UnbindFromRenderStep("BikeCameraSubject");removing:Disconnect();restore();anchor:Destroy()
 end)
end
return Camera
