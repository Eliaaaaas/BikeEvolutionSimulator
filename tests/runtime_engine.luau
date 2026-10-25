-- Engine doubles: real integration code runs; rendering, physics and actual replication do NOT.
local function engine()
 local e={Now=1000,Queue={},Warnings={},Closes={}}
 local function signal()
  local callbacks={};local result={}
  function result:Connect(cb) local connection={Connected=true};function connection:Disconnect() self.Connected=false end;table.insert(callbacks,{Callback=cb,Connection=connection});return connection end
  function result:Once(cb) local c;c=self:Connect(function(...) c:Disconnect();cb(...) end);return c end
  function result:Fire(...) for _,entry in ipairs(table.clone(callbacks)) do if entry.Connection.Connected then entry.Callback(...) end end end
  return result
 end
 e.Signal=signal
 e.Task={}
 function e.Task.spawn(cb,...) local args=table.pack(...);table.insert(e.Queue,{At=e.Now,Thread=coroutine.create(function() cb(table.unpack(args,1,args.n)) end)}) end
 e.Task.defer=e.Task.spawn
 function e.Task.delay(seconds,cb) table.insert(e.Queue,{At=e.Now+seconds,Thread=coroutine.create(cb)}) end
 function e.Task.wait(seconds) return coroutine.yield(seconds or .01) end
 function e.advance(seconds)
  local untilTime=e.Now+seconds;local steps=0
  while true do
   table.sort(e.Queue,function(a,b) return a.At<b.At end);local next=e.Queue[1]
   if not next or next.At>untilTime then break end
   table.remove(e.Queue,1);e.Now=next.At;steps+=1;assert(steps<100000,"runaway scheduler")
   local ok,wait=coroutine.resume(next.Thread);assert(ok,tostring(wait))
   if coroutine.status(next.Thread)~="dead" then next.At=e.Now+wait;table.insert(e.Queue,next) end
  end
  e.Now=untilTime
 end
 local vector,meta={},{}
 function vector.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},meta) end
 meta.__add=function(a,b) return vector.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
 meta.__sub=function(a,b) return vector.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
 meta.__unm=function(a) return vector.new(-a.X,-a.Y,-a.Z) end
 meta.__index=function(a,k) if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end end
 vector.zero=vector.new();e.Vector3=vector;e.Vector2={new=function(x,y) return vector.new(x,y) end,zero=vector.zero}
 local cf,cm={},{}
 function cf.new(x,y,z) return setmetatable({Position=if type(x)=="table" then x else vector.new(x,y,z)},cm) end
 function cf.lookAt(p,_) return cf.new(p) end
 cm.__mul=function(a,b) return cf.new(a.Position+b.Position) end
 cm.__index={ToObjectSpace=function(a,b) return cf.new(b.Position-a.Position) end}
 e.CFrame=cf
 local function object(cls,name)
  local properties={ClassName=cls,Name=name or cls,Position=vector.zero,CFrame=cf.new(),Size=vector.new(1,1,1),AbsoluteSize=vector.new(1000,700),Visible=true,CanvasPosition=vector.zero}
  local children,attributes,changed={},{},{};local self;local methods={}
  for _,event in ipairs({"Activated","MouseEnter","MouseLeave","Triggered","CharacterRemoving","AttributeChanged"}) do properties[event]=signal() end
  if cls=="RemoteEvent" then properties.OnServerEvent=signal();properties.OnClientEvent=signal() end
  function methods:IsA(kind) return cls==kind or kind=="BasePart" and (cls=="Part" or cls=="SpawnLocation") end
  function methods:GetChildren() return table.clone(children) end
  function methods:GetDescendants() local result={};for _,c in ipairs(children) do table.insert(result,c);for _,d in ipairs(c:GetDescendants()) do table.insert(result,d) end end;return result end
  function methods:FindFirstChild(name) for _,c in ipairs(children) do if c.Name==name then return c end end;return nil end
  function methods:WaitForChild(name) local child=self:FindFirstChild(name);assert(child,"Missing actual fixture child: "..name);return child end
  function methods:FindFirstChildOfClass(name) for _,c in ipairs(children) do if c.ClassName==name then return c end end;return nil end
  function methods:IsDescendantOf(ancestor) local current=self.Parent;while current do if current==ancestor then return true end;current=current.Parent end;return false end
  function methods:GetPropertyChangedSignal(key) if not changed[key] then changed[key]=signal() end;return changed[key] end
  function methods:SetAttribute(key,value) attributes[key]=value;properties.AttributeChanged:Fire(key) end
  function methods:GetAttribute(key) return attributes[key] end
  function methods:Destroy() self.Parent=nil end
  function methods:Clone() local c=object(cls,properties.Name);for k,v in pairs(properties) do if k~="Parent" and k~="PrimaryPart" then c[k]=v end end;for _,child in ipairs(children) do child:Clone().Parent=c end;return c end
  function methods:ChangeState(state) properties.State=state end
  function methods:Kick(reason) properties.Kicks=(properties.Kicks or 0)+1;properties.KickReason=reason end
  function methods:GetPivot() return properties.Pivot or cf.new() end
  function methods:PivotTo(value) properties.Pivot=value end
  function methods:GetBoundingBox() return cf.new(0,2,0),vector.new(3,4,6) end
  function methods:FireServer(payload) self.OnServerEvent:Fire(e.Player,payload) end
  function methods:FireClient(player,payload) assert(player==e.Player);self.OnClientEvent:Fire(payload) end
  function methods:InvokeServer(payload) return self.OnServerInvoke(e.Player,payload) end
  self=setmetatable({},{__index=function(_,k) return methods[k] or properties[k] or (if k=="_children" then children else methods.FindFirstChild(self,k)) end,__newindex=function(_,k,v)
   if k=="Parent" then
    if properties.Parent then local i=table.find(properties.Parent._children,self);if i then table.remove(properties.Parent._children,i) end end
    if v then table.insert(v._children,self) end
   elseif k=="CFrame" then properties.Position=v.Position end
   properties[k]=v
  end})
  return self
 end
 e.Instance={new=function(cls) return object(cls) end}
 function e.add(parent,cls,name,x,y,z,sx,sy,sz) local n=object(cls,name);if x then n.CFrame=cf.new(x,y,z) end;if sx then n.Size=vector.new(sx,sy,sz) end;n.Parent=parent;return n end
 local game=object("DataModel","game");game.JobId="integration";game.PrivateServerId="";game.PrivateServerOwnerId=0
 e.Workspace=e.add(game,"Workspace","Workspace");e.Rep=e.add(game,"ReplicatedStorage","ReplicatedStorage");e.add(e.Rep,"Folder","Shared")
 e.Players=e.add(game,"Players","Players");e.Players.PlayerAdded=signal();e.Players.PlayerRemoving=signal()
 e.Players.GetPlayers=function() local all={};for _,p in ipairs(e.Players:GetChildren()) do if p:IsA("Player") then table.insert(all,p) end end;return all end
 e.Player=e.add(e.Players,"Player","Tester");e.Player.UserId=123;e.Players.LocalPlayer=e.Player
 e.add(e.Player,"PlayerGui","PlayerGui")
 local character=e.add(e.Workspace,"Model","Character");e.Player.Character=character
 e.Root=e.add(character,"Part","HumanoidRootPart",0,11,0);e.Root.Anchored=false
 local hum=e.add(character,"Humanoid","Humanoid");hum.Health=100;hum.WalkSpeed=16;hum.AutoRotate=true;hum.PlatformStand=false
 e.Workspace.CurrentCamera={ViewportSize=vector.new(1000,700),CFrame=cf.new(0,20,30)}
 local serial=0
 local store=modules.StudioStore.new();e.StoreCalls=0;e.FailStoreCreation=false
 local services={Players=e.Players,ReplicatedStorage=e.Rep,RunService={IsStudio=function() return e.Studio~=false end},
 HttpService={GenerateGUID=function() serial+=1;return "integration-"..serial end,JSONEncode=function() return "[]" end},
 DataStoreService={GetDataStore=function(_,name) e.StoreCalls+=1;e.StoreName=name;if e.FailStoreCreation then error("Publish place first") end;return store end},
 UserInputService={TouchEnabled=false},TweenService={Create=function(_,target,_,props) local done=signal();return {Completed=done,Cancel=function() end,Play=function() for k,v in pairs(props) do target[k]=v end;done:Fire() end} end}}
 function game:GetService(name) return services[name] or self:FindFirstChild(name) end
 function game:BindToClose(cb) table.insert(e.Closes,cb) end
 e.Game=game;e.OS={clock=function() return e.Now end,time=function() return math.floor(e.Now) end}
 e.Warn=function(...) table.insert(e.Warnings,{...}) end
 e.Random={new=function() return {NextInteger=function() return 1 end} end}
 e.Color3={new=function(...) return {...} end,fromRGB=function(...) return {...} end}
 e.UDim={new=function(...) return {...} end};e.UDim2={new=function(...) return {...} end,fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end}
 e.ColorSequence={new=function(...) return {...} end};e.TweenInfo={new=function(...) return {...} end}
 e.Enum=setmetatable({},{__index=function(_,name) return setmetatable({},{__index=function(_,key) return name.."."..key end}) end})
 return e
end
modules.runtimeEngine=engine
