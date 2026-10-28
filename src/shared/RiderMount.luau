--!strict
-- Offsets come from authored saddle geometry and actual avatar pelvis dimensions.
local Mount={}
function Mount.offset(bike:Model,character:Model):CFrame
 local root=character:FindFirstChild("HumanoidRootPart") :: BasePart
 local frame=bike:FindFirstChild("Frame") :: Model
 local saddle=frame:FindFirstChild("Saddle") :: BasePart
 local base=bike:FindFirstChild("Root") :: BasePart
 assert(root and saddle and base,"Rider geometry missing")
 local localSeat=base.CFrame:ToObjectSpace(saddle.CFrame)
 local pelvis=character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
 local support=root.Size.Y*.5
 local pelvisX,pelvisZ=0,0
 if pelvis and pelvis:IsA("BasePart") then
  -- Use bind-pose Motor6D offsets, not an animated/world-space pelvis sample.
  support=pelvis.Size.Y*.5
  for _,joint in ipairs(root:GetChildren()) do
   if joint:IsA("Motor6D") and joint.Part1==pelvis then
    local bind:CFrame=(joint:GetAttribute("RiderBaseC0") :: CFrame?) or joint.C0
    local delta=(bind*joint.C1:Inverse()).Position
    support-=delta.Y;pelvisX=delta.X;pelvisZ=delta.Z
    break
   end
  end
 end
 return CFrame.new(localSeat.Position.X-pelvisX,localSeat.Position.Y+saddle.Size.Y*.5+support,localSeat.Position.Z-pelvisZ)
end
function Mount.place(rig:any,cf:CFrame)
 -- PrimaryPart pivots may contain a nonzero PivotOffset. Preserve that relation explicitly.
 local model=rig.Root.Parent :: Model
 local rootToPivot=rig.Root.CFrame:ToObjectSpace(model:GetPivot())
 model:PivotTo(cf*rootToPivot)
end
return table.freeze(Mount)
