--!strict
local Config=require(script.Parent.Config)
local Surface={}
function Surface.new(world:Workspace,excluded:{Instance},height:number):any
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances=excluded;params.RespectCanCollide=true
 local api={}
 function api.floor(x:number,y:number,z:number):(number?,number?)
  local hit=world:Raycast(Vector3.new(x,y+Config.Bike.StepHeight+.4,z),Vector3.new(0,-Config.Bike.FloorProbe,0),params)
  if not hit then return nil,nil end
  return hit.Position.Y,if hit.Normal then hit.Normal.Y else 1
 end
 function api.clear(x:number,y:number,z:number,yaw:number):boolean
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Exclude
  overlap.FilterDescendantsInstances=excluded;overlap.RespectCanCollide=true
  local hits=world:GetPartBoundsInBox(CFrame.new(x,y+height/2+.2,z)*CFrame.Angles(0,yaw,0),Vector3.new(2.8,height,6.4),overlap)
  for _,part in ipairs(hits) do if part.CanCollide then return false end end
  return true
 end
 function api.block(x:number,y:number,z:number,yaw:number,dx:number,dy:number,dz:number,ground:number?,grounded:boolean?):boolean
  local delta=Vector3.new(dx,dy,dz)
  if delta.Magnitude<1e-5 then return false end
  local cf=CFrame.new(x,y+height/2,z)*CFrame.Angles(0,yaw,0)
  if world:Blockcast(cf,Vector3.new(2.8,height,6.4),delta,params) then return true end
  if grounded and ground then
   local low=world:Blockcast(CFrame.new(x,ground+.5,z)*CFrame.Angles(0,yaw,0),Vector3.new(2.4,.7,6),delta,params)
   if low then
    if low.Normal and low.Normal.Y>=Config.Bike.MinGroundNormal then return false end
    local part=low.Instance
    if part and part:IsA("BasePart") then
     local name=part.Name
     local driveable=name=="AccessRamp" or name=="Deck" or name=="Belt" or name=="Platform" or name=="IslandSpawn" or string.find(name,"^Grass_") or string.find(name,"^Sand_") or name=="CoastGrass" or name=="CoastSand"
     if driveable and part.Position.Y+part.Size.Y/2<=ground+Config.Bike.StepHeight then return false end
    end
    return true
   end
  end
  return false
 end
 return api
end
return table.freeze(Surface)
