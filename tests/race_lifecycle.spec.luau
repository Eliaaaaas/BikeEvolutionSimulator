-- Actual RaceService and BikeRig executed against lightweight engine doubles.
-- CFrame doubles model translation only; curve math is tested separately, real physics needs Studio.
local function fixture()
 local vector={};local vmeta={}
 function vector.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vmeta) end
 vmeta.__sub=function(a,b) return vector.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
 vmeta.__add=function(a,b) return vector.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
 vmeta.__index=function(a,key) if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end end
 vector.zero=vector.new()
 local cf={};local cm={}
 function cf.new(x,y,z) return setmetatable({Position=vector.new(x,y,z)},cm) end
 function cf.lookAt(p,_) return cf.new(p.X,p.Y,p.Z) end
 cm.__mul=function(a,b) local p=a.Position+b.Position;return cf.new(p.X,p.Y,p.Z) end
 cm.__index={ToObjectSpace=function(a,b) local p=b.Position-a.Position;return cf.new(p.X,p.Y,p.Z) end}
 local instance={}
 local function object(cls,name)
  local props={ClassName=cls,Name=name or cls,CFrame=cf.new(),Position=vector.zero};local children={};local self
  if cls=="ProximityPrompt" then props.Triggered={Connect=function() end} end
  local methods={}
  function methods:IsA(kind) return kind==cls or kind=="BasePart" and cls=="Part" end
  function methods:GetChildren() return table.clone(children) end
  function methods:GetDescendants() local result={};for _,c in ipairs(children) do table.insert(result,c);for _,d in ipairs(c:GetDescendants()) do table.insert(result,d) end end;return result end
  function methods:FindFirstChild(key) for _,c in ipairs(children) do if c.Name==key then return c end end;return nil end
  function methods:WaitForChild(key) local c=self:FindFirstChild(key);assert(c,key.." missing");return c end
  function methods:FindFirstChildOfClass(key) for _,c in ipairs(children) do if c.ClassName==key then return c end end;return nil end
  function methods:Destroy() self.Parent=nil end
  function methods:Clone()
   local copy=object(cls,props.Name)
   for key,value in pairs(props) do if key~="Parent" then copy[key]=value end end
   for _,c in ipairs(children) do local cloned=c:Clone();cloned.Parent=copy end
   return copy
  end
  function methods:SetAttribute(key,value) props[key]=value end
  function methods:GetAttribute(key) return props[key] end
  function methods:ChangeState(state) props.State=state end
  self=setmetatable({},{__index=function(_,key) if key=="_children" then return children end;return methods[key] or props[key] end,
   __newindex=function(_,key,value)
    if key=="Parent" then
     if props.Parent then local i=table.find(props.Parent._children,self);if i then table.remove(props.Parent._children,i) end end
     if value then table.insert(value._children,self) end
    elseif key=="CFrame" then props.Position=value.Position end
    props[key]=value
   end})
  return self
 end
 instance.new=function(cls) return object(cls) end
 local function add(parent,cls,name) local n=object(cls,name);n.Parent=parent;return n end
 local function signal()
  local callbacks={};return {Connect=function(_,callback) table.insert(callbacks,callback) end,
   Fire=function(_,...) for _,callback in ipairs(callbacks) do callback(...) end end}
 end
 local workspace=object("Folder","Workspace");local world=add(workspace,"Model","World1");local preview=add(world,"Model","RacePreview");add(preview,"Part","Platform")
 local prototype=object("Model","Mountainbike");local base=add(prototype,"Part","Root");base.Anchored=true
 for _,name in ipairs({"Frame","Steering","FrontWheel","RearWheel","Crank"}) do
  local group=add(prototype,"Model",name);local p=add(group,"Part","Pivot");p.Anchored=true;p.CFrame=cf.new(0,2,0)
  local body=add(group,"Part","Geometry");body.Anchored=true
 end
 local rep=object("Folder","ReplicatedStorage");add(rep,"Folder","Shared");local vehicles=add(rep,"Folder","Vehicles");prototype.Parent=vehicles
 local players=object("Folder","Players");players.PlayerRemoving=signal();players.PlayerAdded=signal();players.GetPlayers=function() return {} end
 local player=add(players,"Player","Rider");player.UserId=7;player.CharacterRemoving=signal();player.Respawns=0;player.LoadCharacterAsync=function(self) self.Respawns+=1 end
 local character=add(workspace,"Model","Character");player.Character=character
 local root=add(character,"Part","HumanoidRootPart");root.CFrame=cf.new(0,11,63);root.Anchored=false
 local hum=add(character,"Humanoid","Humanoid");hum.Health=100;hum.WalkSpeed=16;hum.AutoRotate=true;hum.PlatformStand=false
 local game={GetService=function(_,name) return if name=="Players" then players elseif name=="HttpService" then {GenerateGUID=function() return "fixture-race-uuid" end} else rep end}
 local shutdown;game.BindToClose=function(_,callback) shutdown=callback end
 local now=1000;local threads={};local task={defer=function(callback) callback() end,wait=function() coroutine.yield() end,spawn=function(callback) local co=coroutine.create(callback);table.insert(threads,co);assert(coroutine.resume(co)) end}
 local data=modules.Profile.new();data.Energy=500;data.Cash=75
 local service={change=function(_,cb) return cb(data),nil end,snapshot=function() return table.clone(data) end,ownsVehicle=function(_,id) return id==1 end}
 local old=modules.BikeRig;modules.BikeRig=modules.makeBikeRig(instance)
 local race=modules.makeRaceService(game,workspace,task,{clock=function() return now end},function() end,instance,cf,vector,{HumanoidStateType={GettingUp="GettingUp"},ModelStreamingMode={Atomic="Atomic"}})
 local events={};local api=race.new(service,function() end,function(_,event) table.insert(events,event) end);modules.BikeRig=old
 api.run()
 local function advance(dt)
  now+=dt;for _,co in ipairs(threads) do local ok,err=coroutine.resume(co);assert(ok,tostring(err)) end
 end
 return {api=api,player=player,hum=hum,root=root,data=data,workspace=workspace,events=events,advance=advance,shutdown=function() shutdown() end}
end
local count=0
local function test(name,callback) local ok,err=pcall(callback);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
test("real bike rig assembly creates five motors and safe anchored root",function()
 local e=fixture();assert(e.api.start(e.player));local folder=e.workspace:FindFirstChild("ActiveRaceBikes");local bike=folder:GetChildren()[1]
 local motors=0
 for _,n in ipairs(bike:GetDescendants()) do if n:IsA("Motor6D") then motors+=1;assert(n.Part0 and n.Part1) end end
 assert(motors==5 and bike.PrimaryPart.Anchored);assert(e.root.Anchored and e.hum.WalkSpeed==0)
 e.api.abort(e.player);assert(#folder:GetChildren()==0 and not e.root.Anchored and e.hum.WalkSpeed==16 and e.hum.AutoRotate and not e.hum.PlatformStand)
 assert(e.root.Position.Z==50 and e.root.Position.Y==12 and e.player:GetAttribute("Racing")==false)
end)
test("actual finish restores controls and never mutates currency",function()
 local e=fixture();assert(e.api.start(e.player))
 for _=1,700 do e.advance(0.1) end
 assert(not e.api.active(e.player));assert(e.events[#e.events].Reason=="Finished")
 assert(e.hum.WalkSpeed==16 and not e.root.Anchored and e.data.Energy==500 and e.data.Cash==75)
 assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==0)
end)
test("technical root removal still restores humanoid controls and clears bike",function()
 local e=fixture();assert(e.api.start(e.player));e.root:Destroy();e.advance(0.1)
 assert(not e.api.active(e.player));assert(e.hum.WalkSpeed==16 and e.hum.AutoRotate and not e.hum.PlatformStand and e.player.Respawns==1)
 assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==0)
end)
test("shutdown cleanup restores a live rider without leaving an anchored character",function()
 local e=fixture();assert(e.api.start(e.player));e.shutdown()
 assert(not e.api.active(e.player));assert(not e.root.Anchored and e.hum.WalkSpeed==16)
end)
test("real Easy race creates five opponents and pays a validated finish once",function()
 local e=fixture();assert(e.api.start(e.player,"Easy"));assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==6)
 assert(e.api.snapshot(e.player).Opponents==5)
 for _=1,700 do e.advance(0.1) end
 assert(not e.api.active(e.player));local result=e.events[#e.events]
 assert(result.Reason=="Finished" and result.Place>=1 and result.Place<=6)
 assert(e.data.Cash==75+modules.World1Content.Difficulties.Easy.Rewards[result.Place] and e.data.Energy==500)
 local cash=e.data.Cash;for _=1,20 do e.advance(0.1) end;assert(e.data.Cash==cash)
 assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==0)
end)
print(string.format("%d race adapter tests passed",count))
