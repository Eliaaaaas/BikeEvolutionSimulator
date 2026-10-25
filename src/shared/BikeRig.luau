--!strict
-- Authored geometry -> one anchored root with motorized welded groups, no manual vehicle physics.
local Rig={}
function Rig.prepare(model: Model): any
 local root=model:FindFirstChild("Root") :: BasePart
 assert(root and root:IsA("BasePart"),"Mountainbike root missing")
 model.PrimaryPart=root
 local motors: {[string]: Motor6D}={}
 local function group(name:string,parent:BasePart)
  local container=model:FindFirstChild(name) :: Model
  local pivot=container:FindFirstChild("Pivot") :: BasePart?
  local base=pivot or root
  for _,part in ipairs(container:GetDescendants()) do
   if part:IsA("BasePart") then
    part.Anchored=false;part.Massless=true;part.CanCollide=false;part.CanTouch=false
    if part~=base then local weld=Instance.new("WeldConstraint");weld.Part0=base;weld.Part1=part;weld.Parent=part end
   end
  end
  if pivot then
   local motor=Instance.new("Motor6D");motor.Name=name.."Motor";motor.Part0=parent;motor.Part1=pivot
   motor.C0=parent.CFrame:ToObjectSpace(pivot.CFrame);motor.Parent=parent;motors[name]=motor
  end
  return base
 end
 local frame=group("Frame",root)
 local steering=group("Steering",frame)
 group("FrontWheel",steering);group("RearWheel",frame);group("Crank",frame)
 root.Anchored=true
 return {Root=root,Motors=motors}
end
return Rig
