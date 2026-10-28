--!strict
-- Roblox PlayerModule supplies both WASD/arrows and the native mobile thumbstick.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Driver={}
function Driver.new(ui:any,remote:RemoteEvent)
 local player=Players.LocalPlayer
 -- PlayerModule is inserted by Roblox at runtime and is absent from the Rojo sourcemap.
 local loadPlayerModule:(Instance)->any=require
 local controls=loadPlayerModule(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
 -- Keep controller input collection active, but remove its default Player:Move dispatcher.
 -- Disable() would also disable the native touch thumbstick and GetMoveVector().
 local originalMove=controls.moveFunction
 assert(type(originalMove)=="function","Unsupported Roblox ControlModule: moveFunction missing")
 local suppressMove=function()
  local hum=if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
  if hum then hum:Move(Vector3.zero,false);hum.Jump=false;hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false) end
 end
 controls.moveFunction=suppressMove
 local function stopWalking(character:Model?)
  local hum=if character then character:FindFirstChildOfClass("Humanoid") else nil
  if hum then hum:Move(Vector3.zero,false);hum.Jump=false;hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,false) end
 end
 stopWalking(player.Character)
 local spawned=player.CharacterAdded:Connect(stopWalking)
 local sequence=player:GetAttribute("DriveSequence") or 0
 local brake=false;local focused=true
 Actions:BindActionAtPriority("BikeBrake",function(_,state)
  brake=state==Enum.UserInputState.Begin or state==Enum.UserInputState.Change
  return Enum.ContextActionResult.Sink
 end,true,3001,Enum.KeyCode.Space,Enum.KeyCode.LeftShift)
 Actions:SetTitle("BikeBrake","BREMSE")
 Actions:SetPosition("BikeBrake",UDim2.fromScale(.32,.68))
 local lost=Input.WindowFocusReleased:Connect(function() focused=false;brake=true end)
 local gained=Input.WindowFocused:Connect(function() focused=true;brake=false end)
 task.spawn(function()
  while ui.Gui.Parent do
   controls.moveFunction=suppressMove
   local move=controls:GetMoveVector()
   local blocked=not focused or ui.isMenuOpen() or Input:GetFocusedTextBox()~=nil or player:GetAttribute("Racing")==true or not ui.Snapshot
   sequence+=1
   remote:FireServer({Version=1,Sequence=sequence,Throttle=if blocked then 0 else math.clamp(-move.Z,-1,1),Steer=if blocked then 0 else math.clamp(move.X,-1,1),Brake=blocked or brake})
   task.wait(Config.Bike.InputInterval)
  end
  sequence+=1;remote:FireServer({Version=1,Sequence=sequence,Throttle=0,Steer=0,Brake=true})
  spawned:Disconnect();lost:Disconnect();gained:Disconnect()
  if controls.moveFunction==suppressMove then controls.moveFunction=originalMove end
  Actions:UnbindAction("BikeBrake")
 end)
end
return Driver
