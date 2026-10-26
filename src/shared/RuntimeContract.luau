--!strict
-- Single contract for startup and build-level integration checks.
local Contract={}
Contract.Paths={
 {"Workspace","World1","IslandSpawn"},{"Workspace","World1","Training"},
 {"Workspace","World1","GaragePreview","Platform"},{"Workspace","World1","GaragePreview","EntryZone"},{"Workspace","World1","RacePreview","Platform"},
 {"Workspace","TestCourse","Road_0"},{"Workspace","World1","ShopArea","Platform"},{"Workspace","World1","WorldPreview","Platform"},
}
for id=1,5 do table.insert(Contract.Paths,{"Workspace","World1","Training","Treadmill_"..id,"Zone"}) end
for id=1,3 do table.insert(Contract.Paths,{"Workspace","World1","EggStation_"..id,"Egg"}) end
for id=1,10 do
 local name=if id==1 then "Mountainbike" else "Vehicle"..id
 for _,group in ipairs({"Root","Frame","Steering","FrontWheel","RearWheel"}) do
  table.insert(Contract.Paths,{"ReplicatedStorage","Vehicles",name,group})
  if group~="Root" then table.insert(Contract.Paths,{"ReplicatedStorage","Vehicles",name,group,"Pivot"}) end
 end
 if id<=6 then table.insert(Contract.Paths,{"ReplicatedStorage","Vehicles",name,"Crank","Pivot"}) end
end
for id=1,12 do table.insert(Contract.Paths,{"ReplicatedStorage","PetModels","Pet"..id}) end
function Contract.inspect(root:any):{string}
 local errors={}
 for _,path in ipairs(Contract.Paths) do
  local current=root
  for _,name in ipairs(path) do current=current:FindFirstChild(name);if not current then break end end
  if not current then table.insert(errors,table.concat(path,"/"))
  elseif table.find({"Zone","Root","Pivot","Platform","Egg","Road_0","IslandSpawn"},path[#path]) and not current:IsA("BasePart") then
   table.insert(errors,table.concat(path,"/").." is not a BasePart")
  end
 end
 return errors
end
return table.freeze(Contract)
