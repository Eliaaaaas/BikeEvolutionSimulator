--!strict
-- Local, distance-limited foam: built-in geometry only, no replicated updates or asset IDs.
local Effects={}
function Effects.new(settings:any,gui:ScreenGui)
 local island=workspace:WaitForChild("World1")
 local folder=Instance.new("Folder");folder.Name="LocalWaterfallFoam";folder.Parent=workspace
 local cascades:{{Source:BasePart,Foam:{BasePart}}}={}
 for _,source in ipairs(island:GetDescendants()) do
  if not source:IsA("BasePart") or source.Name~="Waterfall" then continue end
  local foam:{BasePart}={}
  for i=1,5 do
   local part=Instance.new("Part");part.Name="Foam";part.Anchored=true
   part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
   part.Material=Enum.Material.SmoothPlastic;part.Color=Color3.fromRGB(216,253,255)
   part.Size=Vector3.new(source.Size.X*0.85,0.14,0.08);part.Transparency=1;part.Parent=folder
   table.insert(foam,part)
  end
  table.insert(cascades,{Source=source,Foam=foam})
 end
 task.spawn(function()
  while gui.Parent do
   local active=false
   local camera=workspace.CurrentCamera
   local now=os.clock()
   for _,entry in ipairs(cascades) do
    local source=entry.Source
    local visible=settings.Animations and source.Parent~=nil and camera~=nil and (camera.CFrame.Position-source.Position).Magnitude<140
    for i,part in ipairs(entry.Foam) do
     if visible then
      active=true
      local phase=(now*0.38+i/#entry.Foam)%1
      part.CFrame=source.CFrame*CFrame.new(math.sin(i*2)*0.2,(0.5-phase)*source.Size.Y,source.Size.Z/2+0.05)
      part.Transparency=0.3+math.abs(phase-0.5)*0.8
     else part.Transparency=1 end
    end
   end
   task.wait(if active then 1/15 else 0.3)
  end
  folder:Destroy()
 end)
end
return Effects
