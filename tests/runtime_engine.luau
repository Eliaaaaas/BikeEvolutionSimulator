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
 local vector,cf=modules.rigidMath()
 e.Vector3=vector;e.Vector2={new=function(x,y) return vector.new(x,y) end,zero=vector.zero};e.CFrame=cf
 local links={};e.CFrameWrites={}
 local function jointActive(j) return j.Parent and j.Part0 and j.Part1 and j:IsDescendantOf(e.Workspace) end
 local function propagate(root)
  local queue={root};local seen={[root]=true};local index=1
  while queue[index] do
   local p=queue[index];index+=1
   for j in pairs(links[p] or {}) do
    if not jointActive(j) then continue end
    local c0=j.C0 or cf.identity;local c1=j.C1 or cf.identity
    local a,b=j.Part0,j.Part1;local other=if a==p then b else a
    if other._properties.LeafJoint==j then continue end
    if seen[other] then continue end
    local value=if a==p then p.CFrame*c0*(j.Transform or cf.identity)*c1:Inverse() else p.CFrame*c1*(c0*(j.Transform or cf.identity)):Inverse()
    other._properties.CFrame=value;other._properties.Position=value.Position
    seen[other]=true;table.insert(queue,other)
   end
  end
 end
 local function object(cls,name)
  local properties={ClassName=cls,Name=name or cls,Position=vector.zero,CFrame=cf.new(),Size=vector.new(1,1,1),AbsoluteSize=vector.new(1000,700),C0=cf.identity,C1=cf.identity,Transform=cf.identity,PivotOffset=cf.identity,Archivable=true,LocalTransparencyModifier=0,Visible=true,CanvasPosition=vector.zero}
  local children,attributes,changed={},{},{};local self;local methods={}
  for _,event in ipairs({"Activated","MouseEnter","MouseLeave","Triggered","CharacterRemoving","CharacterAdded","AttributeChanged","Destroying","DescendantAdded"}) do properties[event]=signal() end
  if cls=="RemoteEvent" then properties.OnServerEvent=signal();properties.OnClientEvent=signal() end
  function methods:IsA(kind) return cls==kind or kind=="GuiButton" and cls=="TextButton" or kind=="BasePart" and (cls=="Part" or cls=="WedgePart" or cls=="SpawnLocation") end
  function methods:GetChildren() return table.clone(children) end
  function methods:GetDescendants() local result={};for _,c in ipairs(children) do table.insert(result,c);for _,d in ipairs(c:GetDescendants()) do table.insert(result,d) end end;return result end
  function methods:FindFirstChild(name) for _,c in ipairs(children) do if c.Name==name then return c end end;return nil end
  function methods:WaitForChild(name) local child=self:FindFirstChild(name);assert(child,"Missing actual fixture child: "..name);return child end
  function methods:FindFirstChildOfClass(name) for _,c in ipairs(children) do if c.ClassName==name then return c end end;return nil end
  function methods:IsDescendantOf(ancestor) local current=self.Parent;while current do if current==ancestor then return true end;current=current.Parent end;return false end
  function methods:GetPropertyChangedSignal(key) if not changed[key] then changed[key]=signal() end;return changed[key] end
  function methods:SetAttribute(key,value) attributes[key]=value;properties.AttributeChanged:Fire(key) end
  function methods:GetAttribute(key) return attributes[key] end
  function methods:GetAttributeChangedSignal(key)
   local sig=signal();properties.AttributeChanged:Connect(function(k) if k==key then sig:Fire() end end);return sig
  end
  function methods:GetScale() return 1 end
  function methods:Destroy() properties.Destroying:Fire();self.Parent=nil end
  function methods:Clone()
   local mapping={};local originals={}
   local function copy(node)
    local result=object(node.ClassName,node.Name);mapping[node]=result;table.insert(originals,node)
    for k,v in pairs(node._properties) do
     if k~="Parent" and k~="PrimaryPart" and k~="Part0" and k~="Part1" and k~="LeafJoint" and not (type(v)=="table" and v.Connect) then result[k]=v end
    end
    for k,v in pairs(node:GetAttributes()) do result:SetAttribute(k,v) end
    for _,child in ipairs(node:GetChildren()) do copy(child).Parent=result end
    return result
   end
   local result=copy(self)
   for _,node in ipairs(originals) do
    for _,key in ipairs({"Part0","Part1","PrimaryPart"}) do
     local value=node[key];if value then mapping[node][key]=mapping[value] or value end
    end
   end
   return result
  end
  function methods:GetAttributes() return table.clone(attributes) end
  function methods:Move(value) properties.MoveDirection=value end
  function methods:SetStateEnabled(state,value) properties.StateEnabled=properties.StateEnabled or {};properties.StateEnabled[state]=value end
  function methods:GetStateEnabled(state) return not properties.StateEnabled or properties.StateEnabled[state]~=false end
  function methods:ChangeState(state) properties.State=state end
  function methods:Kick(reason) properties.Kicks=(properties.Kicks or 0)+1;properties.KickReason=reason end
  function methods:GetPivot() return if properties.PrimaryPart then properties.PrimaryPart.CFrame*properties.PrimaryPart.PivotOffset else properties.Pivot or cf.new() end
  function methods:PivotTo(value)
   local delta=value*self:GetPivot():Inverse()
   for _,node in ipairs(self:GetDescendants()) do if node:IsA("BasePart") then local v=delta*node.CFrame;node._properties.CFrame=v;node._properties.Position=v.Position end end
   properties.Pivot=value
  end
  function methods:GetBoundingBox() return cf.new(0,2,0),vector.new(3,4,6) end
  function methods:FireServer(payload) self.OnServerEvent:Fire(e.Player,payload) end
  function methods:FireClient(player,payload) assert(player==e.Player);self.OnClientEvent:Fire(payload) end
  function methods:InvokeServer(payload) return self.OnServerInvoke(e.Player,payload) end
  self=setmetatable({},{__index=function(_,k)
   if (k=="CFrame" or k=="Position") and properties.LeafJoint and jointActive(properties.LeafJoint) then
    local j=properties.LeafJoint;local value=j.Part0.CFrame*j.C0*j.C1:Inverse()
    return if k=="CFrame" then value else value.Position
   end
   if methods[k]~=nil then return methods[k] end;if properties[k]~=nil then return properties[k] end;return if k=="_children" then children elseif k=="_properties" then properties else methods.FindFirstChild(self,k) end,__newindex=function(_,k,v)
   if k=="Parent" then
    if properties.Parent then local i=table.find(properties.Parent._children,self);if i then table.remove(properties.Parent._children,i) end end
    if v then table.insert(v._children,self) end
   elseif k=="CFrame" then properties.Position=v.Position end
   properties[k]=v
   if k=="CFrame" then e.CFrameWrites[self]=(e.CFrameWrites[self] or 0)+1;propagate(self) end
   if (cls=="Weld" or cls=="Motor6D") and (k=="Parent" or k=="Part0" or k=="Part1") then
    for _,part in ipairs({properties.Part0,properties.Part1}) do links[part]=links[part] or {};links[part][self]=true end
    if properties.Part0 then properties.Part0._properties.LeafJoint=nil end
    if cls=="Weld" and properties.Part1 and properties.Name~="PermanentRiderMount" then properties.Part1._properties.LeafJoint=self end
   end
   if (cls=="Weld" or cls=="Motor6D") and (k=="C0" or k=="C1" or k=="Parent") and jointActive(self) then propagate(self.Part0) end
  end})
  return self
 end
 e.Instance={new=function(cls) return object(cls) end}
 function e.add(parent,cls,name,x,y,z,sx,sy,sz) local n=object(cls,name);if x then n.CFrame=cf.new(x,y,z) end;if sx then n.Size=vector.new(sx,sy,sz) end;n.Parent=parent;return n end
 local game=object("DataModel","game");game.JobId="integration";game.PrivateServerId="";game.PrivateServerOwnerId=0
 e.Workspace=e.add(game,"Workspace","Workspace");e.Workspace.TestCFrame=cf;e.Rep=e.add(game,"ReplicatedStorage","ReplicatedStorage");e.add(e.Rep,"Folder","Shared")
 e.Players=e.add(game,"Players","Players");e.Players.PlayerAdded=signal();e.Players.PlayerRemoving=signal()
 e.Players.GetPlayers=function() local all={};for _,p in ipairs(e.Players:GetChildren()) do if p:IsA("Player") then table.insert(all,p) end end;return all end
 e.Player=e.add(e.Players,"Player","Tester");e.Player.UserId=123;e.Players.LocalPlayer=e.Player
 e.add(e.Player,"PlayerGui","PlayerGui").GetGuiObjectsAtPosition=function() return {} end
 local character=e.add(e.Workspace,"Model","Character");e.Player.Character=character
 e.Player.Respawns=0;e.Player.LoadCharacterAsync=function() e.Player.Respawns+=1 end
 e.Root=e.add(character,"Part","HumanoidRootPart",0,11,0);e.Root.Anchored=false
 local hum=e.add(character,"Humanoid","Humanoid");hum.Health=100;hum.WalkSpeed=16;hum.AutoRotate=true;hum.PlatformStand=false
 e.GroundY=nil;e.Collision=false;e.NoGround=false
 e.Workspace.Raycast=function(_,origin,_) local y=e.GroundY
  if y==nil then
   y=8
   if e.FloorY then y=e.FloorY(origin.X,origin.Z)
   else for _,x in ipairs({-54,-36,-18,24,42}) do
    -- V4.4 authored deck is flush; no analytic ramp.
    if math.abs(origin.X-x)<4 and origin.Z>=-57 and origin.Z<=-45 then y=8.05 end
   end end
  end
  return if e.NoGround or y==nil then nil else {Position=vector.new(origin.X,y,origin.Z),Normal=vector.new(0,1,0)} end
 e.Workspace.Blockcast=function() return if e.Collision then {} else nil end
 e.RaycastParams={new=function() return {} end}
 e.OverlapParams={new=function() return {} end}
 e.Workspace.GetPartBoundsInBox=function() return if e.Occupied then {e.Occupied} else {} end
 e.Move=vector.zero;e.Controls={GetMoveVector=function() return e.Move end,moveFunction=function() e.DefaultMoves=(e.DefaultMoves or 0)+1 end}
 e.PlayerModule={GetControls=function() return e.Controls end}
 e.Workspace.CurrentCamera={ViewportSize=vector.new(1000,700),CFrame=cf.new(0,20,30)}
 local serial=0
 local store=modules.StudioStore.new();e.Store=store;e.StoreCalls=0;e.FailStoreCreation=false
 local bindings={}
 local render=signal()
 local fireRender=render.Fire
 function render:Fire(dt)
  local ordered={};for name,entry in pairs(bindings) do table.insert(ordered,{Name=name,Entry=entry}) end
  table.sort(ordered,function(a,b) return a.Entry.Priority<b.Entry.Priority end)
  for _,entry in ipairs(ordered) do if bindings[entry.Name] then entry.Entry.Callback(dt) end end
  fireRender(self,dt)
 end
 local market={PromptGamePassPurchaseFinished=signal(),UserOwnsGamePassAsync=function() return false end,PromptGamePassPurchase=function() e.PassPrompt=true end,PromptProductPurchase=function() e.ProductPrompt=true end}
 local services={MarketplaceService=market,Players=e.Players,ReplicatedStorage=e.Rep,RunService={PreSimulation=signal(),RenderStepped=render,BindToRenderStep=function(_,name,priority,cb) bindings[name]={Priority=priority,Callback=cb} end,UnbindFromRenderStep=function(_,name) bindings[name]=nil end,IsStudio=function() return e.Studio~=false end},
 HttpService={GenerateGUID=function() serial+=1;return "integration-"..serial end,JSONEncode=function() return "[]" end},
 DataStoreService={GetDataStore=function(_,name) e.StoreCalls+=1;e.StoreName=name;if e.FailStoreCreation then error("Publish place first") end;return store end},
 ContextActionService={BindActionAtPriority=function(_,name,callback,touch,priority,...) e.ActionBindings=e.ActionBindings or {};e.ActionBindings[name]={Touch=touch,Priority=priority,Keys={...}}; if name=="BikeBrake" then e.BrakeCallback=callback else e.JumpCallback=callback end end,SetTitle=function() end,SetPosition=function(_,name,pos) e.ActionPositions=e.ActionPositions or {};e.ActionPositions[name]=pos end,UnbindAction=function() e.BrakeCallback=nil end},
 UserInputService={TouchEnabled=false,InputBegan=signal(),TouchTap=signal(),WindowFocused=signal(),WindowFocusReleased=signal(),GetFocusedTextBox=function() return nil end},TweenService={Create=function(_,target,_,props) local done=signal();return {Completed=done,Cancel=function() end,Play=function() for k,v in pairs(props) do target[k]=v end;done:Fire() end} end}}
 e.Players.GetPlayerByUserId=function(_,id) for _,player in ipairs(e.Players:GetPlayers()) do if player.UserId==id then return player end end;return nil end
 function game:GetService(name) return services[name] or self:FindFirstChild(name) end
 function game:BindToClose(cb) table.insert(e.Closes,cb) end
 e.Game=game;e.OS={clock=function() return e.Now end,time=function() return math.floor(e.Now) end}
 e.Warn=function(...) table.insert(e.Warnings,{...}) end
 e.Random={new=function() return {NextInteger=function() return 1 end} end}
 e.Color3={new=function(...) return {...} end,fromRGB=function(...) return {...} end}
 e.UDim={new=function(...) return {...} end};e.UDim2={new=function(...) return {...} end,fromScale=function(...) return {...} end,fromOffset=function(...) return {...} end}
 e.ColorSequence={new=function(...) return {...} end};e.TweenInfo={new=function(...) return {...} end}
 e.Enum=setmetatable({RenderPriority={Camera={Value=200}}},{__index=function(_,name) return setmetatable({},{__index=function(_,key) return name.."."..key end}) end})
 return e
end
modules.runtimeEngine=engine
