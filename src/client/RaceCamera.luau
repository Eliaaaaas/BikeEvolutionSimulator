--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Camera={}
function Camera.new(settings:any,ui:any)
 local player=Players.LocalPlayer
 local connection:RBXScriptConnection?=nil
 local active:Camera?=nil
 local original:any=nil
 local function stop()
  if connection then connection:Disconnect();connection=nil end
  if active and original then active.CameraType=original.Type;active.CameraSubject=original.Subject;active.FieldOfView=original.Fov end
  local camera=workspace.CurrentCamera
  local hum=if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
  if camera and hum then camera.CameraType=Enum.CameraType.Custom;camera.CameraSubject=hum end
  active=nil;original=nil
 end
 local function update()
  if player:GetAttribute("Racing")~=true then stop();return end
  if connection then return end
  connection=RunService.RenderStepped:Connect(function(dt:number)
   local camera=workspace.CurrentCamera
   local root=if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
   if not camera or not root or not root:IsA("BasePart") then stop();return end
   if active~=camera then
    if active and original then active.CameraType=original.Type;active.CameraSubject=original.Subject;active.FieldOfView=original.Fov end
    active=camera;original={Type=camera.CameraType,Subject=camera.CameraSubject,Fov=camera.FieldOfView}
   end
   camera.CameraType=Enum.CameraType.Scriptable
   local forward=root.CFrame.LookVector
   local target=CFrame.lookAt(root.Position-forward*15+Vector3.new(0,6,0),root.Position+forward*8-Vector3.new(0,1,0))
   camera.CFrame=if settings.Animations then camera.CFrame:Lerp(target,1-math.exp(-math.min(dt,.1)*8)) else target
   camera.FieldOfView=65
  end)
 end
 local attribute=player:GetAttributeChangedSignal("Racing"):Connect(update)
 local removing=player.CharacterRemoving:Connect(stop)
 local added=player.CharacterAdded:Connect(function(character)
  character:WaitForChild("Humanoid",15)
  if player.Character==character and player:GetAttribute("Racing")~=true then stop() end
 end)
 ui.Gui.Destroying:Connect(function() attribute:Disconnect();removing:Disconnect();added:Disconnect();stop() end)
 update()
end
return Camera
