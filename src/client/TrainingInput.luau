--!strict
local Input=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tap=require(Shared:WaitForChild("TrainingTap"))
local Binding={}
function Binding.new(ui:any,send:(string)->())
 local gate=Tap.new(os.clock)
 local function press(kind:string,processed:boolean,position:Vector2?)
  local playerGui=ui.Gui.Parent
  if position and playerGui and playerGui:IsA("PlayerGui") then
   for _,object in ipairs(playerGui:GetGuiObjectsAtPosition(position.X,position.Y)) do
    local current:Instance?=object
    while current and current~=playerGui do
     if current:IsA("GuiButton") then processed=true;break end
     current=current.Parent
    end
   end
  end
  if gate:accept(kind,processed or Input:GetFocusedTextBox()~=nil,ui.Snapshot,ui.isMenuOpen()) then send("Click") end
 end
 local mouse=Input.InputBegan:Connect(function(input:InputObject,processed:boolean)
  if input.UserInputType==Enum.UserInputType.MouseButton1 then press("Mouse",processed,if input.Position then Vector2.new(input.Position.X,input.Position.Y) else nil) end
 end)
 -- Touch InputBegan is deliberately ignored: TouchTap is the sole touch source.
 local touch=Input.TouchTap:Connect(function(positions:{Vector2},processed:boolean)
  if #positions==1 then press("Touch",processed,positions[1]) end
 end)
 ui.Gui.Destroying:Connect(function() mouse:Disconnect();touch:Disconnect() end)
end
return Binding
