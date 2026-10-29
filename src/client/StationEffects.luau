--!strict
local Input=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules=require(Shared:WaitForChild("Rules"))
local Stations={}
function Stations.new(settings:any,ui:any)
 local training=workspace:WaitForChild("World1"):WaitForChild("Training")
 local entries:any={}
 local effects=Instance.new("Folder");effects.Name="LocalTrainingSparks";effects.Parent=workspace
 for id=1,5 do
  local model=training:WaitForChild("Treadmill_"..id)
  local parts={}
  for _,part in ipairs(model:GetChildren()) do
   if part:IsA("BasePart") and (string.find(part.Name,"^BeltStripe_") or part.Name=="NeonEdge") then
    table.insert(parts,{Part=part,Base=part.CFrame,Color=part.Color,Transparency=part.Transparency})
   end
  end
  local zone=model:WaitForChild("Zone") :: BasePart
  local sparks={}
  for j=1,(if Input.TouchEnabled then 2 else 4) do
   local p=Instance.new("Part");p.Name="TrainingSpark";p.Shape=Enum.PartType.Ball;p.Size=Vector3.new(.2,.2,.2);p.Color=Color3.fromRGB(115,255,217)
   p.Material=Enum.Material.Neon;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Transparency=1;p.Parent=effects;table.insert(sparks,p)
  end
  entries[id]={Zone=zone,Parts=parts,Sparks=sparks}
 end
 task.spawn(function()
  while ui.Gui.Parent do
   local camera=workspace.CurrentCamera;local now=os.clock();local snap=ui.Snapshot;local active=false
   for id,entry in ipairs(entries) do
    local nearby=camera~=nil and (camera.CFrame.Position-entry.Zone.Position).Magnitude<90
    local allowed=snap and Rules.canUseTreadmill(id,snap.Energy,snap.Rebirths,snap.OwnedWorlds or {1})
    local animate=nearby and settings.Animations and allowed
    if animate then active=true end
    for _,record in ipairs(entry.Parts) do
     local part=record.Part
     part.Color=if allowed then record.Color else Color3.fromRGB(77,83,104)
     if animate and string.find(part.Name,"^BeltStripe_") then
      local offset=(record.Base.Position.Z-entry.Zone.Position.Z+now*4+6)%12-6
      part.CFrame=record.Base+Vector3.new(0,0,entry.Zone.Position.Z+offset-record.Base.Position.Z)
     else part.CFrame=record.Base end
     part.Transparency=record.Transparency
    end
    for j,spark in ipairs(entry.Sparks) do
     spark.Transparency=if animate then .2 else 1
     if animate then spark.Position=entry.Zone.Position+Vector3.new(math.sin(now+j*2)*4,1+(now+j*.6)%3,math.cos(now+j)*4) end
    end
   end
   task.wait(if active then 1/15 else .3)
  end
  effects:Destroy()
  for _,entry in ipairs(entries) do for _,r in ipairs(entry.Parts) do if r.Part.Parent then r.Part.CFrame=r.Base;r.Part.Color=r.Color;r.Part.Transparency=r.Transparency end end end
 end)
end
return Stations
