--!strict
-- Roblox PlayerModule supplies both WASD/arrows and the native mobile thumbstick.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Prediction=require(script.Parent.RidePrediction)
local Driver={}
function Driver.new(ui:any,remote:RemoteEvent,stateRemote:RemoteEvent)
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
 local prediction=Prediction.new(ui,stateRemote);ui.Prediction=prediction
 local sequence=player:GetAttribute("DriveSequence") or 0
 local jumpId=player:GetAttribute("DriveJumpId") or 0
 local brake=false;local focused=true
 Actions:BindActionAtPriority("BikeBrake",function(_,state)
  brake=state==Enum.UserInputState.Begin or state==Enum.UserInputState.Change
  return Enum.ContextActionResult.Sink
 end,true,3001,Enum.KeyCode.LeftShift)
 Actions:SetTitle("BikeBrake","BREMSE")
 Actions:SetPosition("BikeBrake",UDim2.fromScale(.32,.68))
 Actions:BindActionAtPriority("BikeJump",function(_,state)
  if state==Enum.UserInputState.Begin and focused and not ui.isMenuOpen() and player:GetAttribute("Racing")~=true and ui.Snapshot then jumpId+=1 end
  return Enum.ContextActionResult.Sink
 end,true,3001,Enum.KeyCode.Space)
 Actions:SetTitle("BikeJump","SPRUNG");Actions:SetPosition("BikeJump",UDim2.new(1,-90,1,-90))
 local lost=Input.WindowFocusReleased:Connect(function() focused=false;brake=true end)
 local gained=Input.WindowFocused:Connect(function() focused=true;brake=false end)
 task.spawn(function()
  while ui.Gui.Parent do
   controls.moveFunction=suppressMove
   local move=controls:GetMoveVector()
   local blocked=not focused or ui.isMenuOpen() or Input:GetFocusedTextBox()~=nil or player:GetAttribute("Racing")==true or not ui.Snapshot
   sequence=math.max(sequence,prediction.Sequence or 0)+1;jumpId=math.max(jumpId,prediction.JumpId or 0)
   local intent={Throttle=if blocked then 0 else math.clamp(-move.Z,-1,1),Steer=if blocked then 0 else math.clamp(move.X,-1,1),Brake=blocked or brake,JumpId=jumpId}
   prediction.intent(intent);prediction.command(sequence,intent)
   remote:FireServer({Version=1,Sequence=sequence,Epoch=player:GetAttribute("DriveEpoch"),Throttle=intent.Throttle,Steer=intent.Steer,Brake=intent.Brake,JumpId=jumpId})
   task.wait(Config.Bike.InputInterval)
  end
  sequence+=1;remote:FireServer({Version=1,Sequence=sequence,Throttle=0,Steer=0,Brake=true})
  spawned:Disconnect();lost:Disconnect();gained:Disconnect()
  if controls.moveFunction==suppressMove then controls.moveFunction=originalMove end
  Actions:UnbindAction("BikeBrake");Actions:UnbindAction("BikeJump")
 end)
end
return Driver
