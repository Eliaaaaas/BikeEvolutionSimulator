--!strict
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Format=require(Shared:WaitForChild("Format"))
local Presentation=require(Shared:WaitForChild("Presentation"))
local Catalog=require(Shared:WaitForChild("Catalog"))
local Content=require(Shared:WaitForChild("World1Content"))
local Premium=require(Shared:WaitForChild("PremiumConfig"))
local PetRules=require(Shared:WaitForChild("PetRules"))
local State=require(Shared:WaitForChild("ClientState"))
local Icons=require(script.Parent.Icons)
local UI={}
local white=Color3.new(1,1,1)
local palette={Rebirths=Color3.fromRGB(121,90,205),Garage=Color3.fromRGB(44,133,204),Pets=Color3.fromRGB(194,85,181),Race=Color3.fromRGB(231,94,55),Worlds=Color3.fromRGB(47,168,188),Shop=Color3.fromRGB(43,169,105),Settings=Color3.fromRGB(54,130,174)}
local function make(class:string,parent:Instance?,props:any):any
 local o:any=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local function corner(o:Instance,r:number) make("UICorner",o,{CornerRadius=UDim.new(0,r)}) end
local function text(parent:Instance,value:string,height:number):any
 return make("TextLabel",parent,{Size=UDim2.new(1,-16,0,height),BackgroundTransparency=1,Text=value,TextWrapped=true,TextColor3=white,TextSize=16,Font=Enum.Font.GothamBold,LayoutOrder=0})
end
function UI.new(playerGui:Instance,settings:any,audio:any):any
 for _,name in ipairs({"PalmBaySidebar","BikeHUDV3","BikeHUDV4"}) do
  local old=playerGui:FindFirstChild(name);if old then old:Destroy() end
 end
 local gui=make("ScreenGui",playerGui,{Name="BikeHUDV4",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 local root=make("Frame",gui,{Size=UDim2.new(1,-16,1,-16),Position=UDim2.fromOffset(8,8),BackgroundTransparency=1})
 local sidebar=make("Frame",root,{Name="MenuSidebar",Size=UDim2.fromOffset(160,400),AnchorPoint=Vector2.new(0,.5),Position=UDim2.new(0,0,.5,0),BackgroundTransparency=1,BorderSizePixel=0})
 local scale=make("UIScale",sidebar,{Scale=1})
 local toggle=make("TextButton",sidebar,{Name="MenuToggle",Size=UDim2.fromOffset(44,28),Text="☰",TextColor3=white,TextSize=22,Font=Enum.Font.GothamBold,BackgroundTransparency=1,BorderSizePixel=0})
 local list=make("Frame",sidebar,{Name="Navigation",Position=UDim2.fromOffset(0,32),Size=UDim2.new(1,0,1,-32),BackgroundTransparency=1,BorderSizePixel=0})
 local buttons:any={};local labels:any={};local scales:any={};local activeTweens:any={}
 local function tween(object:any,properties:any,duration:number?)
  if activeTweens[object] then activeTweens[object]:Cancel();activeTweens[object]=nil end
  if not settings.Animations then for key,value in pairs(properties) do object[key]=value end;return end
  local t=TweenService:Create(object,TweenInfo.new(duration or 0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
  activeTweens[object]=t;t.Completed:Once(function() if activeTweens[object]==t then activeTweens[object]=nil end end);t:Play()
 end
 local sidebarHeight=400
 local arrange:()->()=function() end
 local generation=0
 local api:any={Gui=gui,Settings=settings,Buttons=buttons,Snapshot=nil,Viewport=nil,OnAction=function() end,OnSetting=function() end,OnMenu=function() end,Difficulty="Easy"}
 -- V2 contract: this transparent container lays out free-standing icons and values only.
 local resourceCanvas=make("Frame",gui,{Name="SafeResourceCanvas",Position=UDim2.fromOffset(0,0),ZIndex=0,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0})
 local resourceHUD=make("Frame",resourceCanvas,{Name="ResourceHUD",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-10,1,-10),Size=UDim2.fromOffset(190,108),BackgroundTransparency=1,BorderSizePixel=0})
 local resourceValues:any={};local resourceRows:any={};local resourceIcons:any={}
 for i,name in ipairs({"Energy","Cash","Rebirths"}) do
  local holder=make("Frame",resourceHUD,{Name=name.."Status",Size=UDim2.new(1,0,0,36),Position=UDim2.fromOffset(0,(i-1)*36),BackgroundTransparency=1,BorderSizePixel=0})
  local icon=Icons.resource(holder,name);make("UIScale",icon,{Scale=1});resourceIcons[name]=icon;resourceRows[name]=holder
  resourceValues[name]=make("TextLabel",holder,{Name="Value",Position=UDim2.fromOffset(40,0),Size=UDim2.new(1,-40,1,0),BackgroundTransparency=1,BorderSizePixel=0,Text="—",TextColor3=white,TextSize=27,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right,TextStrokeColor3=Color3.fromRGB(14,45,61),TextStrokeTransparency=0.25,TextWrapped=false,TextScaled=true})
  make("UITextSizeConstraint",resourceValues[name],{MinTextSize=12,MaxTextSize=27})
 end
 api.ResourceHUD=resourceHUD;api.ResourceValues=resourceValues
 for i,name in ipairs({"Garage","Pets","Race","Worlds","Rebirths","Shop","Settings"}) do
  local button=make("TextButton",list,{Name=name,LayoutOrder=i,Size=UDim2.new(1,-4,0,47),BackgroundColor3=white,BackgroundTransparency=0.04,BorderSizePixel=0,Text="",AutoButtonColor=false})
  local ends={Garage={Color3.fromRGB(44,224,220),Color3.fromRGB(42,88,218)},Pets={Color3.fromRGB(247,118,206),Color3.fromRGB(136,69,217)},Race={Color3.fromRGB(255,179,68),Color3.fromRGB(232,65,74)},Worlds={Color3.fromRGB(65,222,243),Color3.fromRGB(36,174,114)},Rebirths={Color3.fromRGB(172,106,245),Color3.fromRGB(65,112,234)},Shop={Color3.fromRGB(172,234,72),Color3.fromRGB(39,195,176)},Settings={Color3.fromRGB(112,203,251),Color3.fromRGB(40,102,180)}}
  corner(button,12)
  make("Frame",button,{Name="ButtonDepth",Size=UDim2.new(1,-4,0,4),Position=UDim2.new(0,2,1,-1),BackgroundColor3=palette[name],BorderSizePixel=0})
  make("UIGradient",button,{Color=ColorSequence.new(ends[name][1],ends[name][2]),Rotation=30})
  make("UIStroke",button,{Color=white,Transparency=0.8,Thickness=1})
  Icons.draw(button,name)
  labels[name]=make("TextLabel",button,{Position=UDim2.fromOffset(48,0),Size=UDim2.new(1,-52,1,0),BackgroundTransparency=1,Text=name,TextColor3=white,TextSize=14,TextStrokeTransparency=0.65,TextStrokeColor3=Color3.fromRGB(16,72,95),TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamBold,TextWrapped=true})
  local hover=make("UIScale",button,{Scale=1});scales[name]=hover;buttons[name]=button
  button.MouseEnter:Connect(function() if settings.Animations then tween(hover,{Scale=1.025}) end end)
  button.MouseLeave:Connect(function() tween(hover,{Scale=1}) end)
  button.Activated:Connect(function()
   audio.play("Button");settings.Active=name
   for key,b in pairs(buttons) do local s=b:FindFirstChildOfClass("UIStroke");if s then tween(s,{Thickness=if key==name then 3 else 1,Transparency=if key==name then 0.1 else 0.8}) end end
   tween(button,{BackgroundTransparency=0},0.07);task.delay(0.1,function() if button.Parent then tween(button,{BackgroundTransparency=0.08}) end end)
   api.CurrentMenu=name;api.OnMenu(name)
  end)
 end
 local autoBar=make("Frame",root,{Name="AutomationControls",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,0),Size=UDim2.fromOffset(270,38),BackgroundTransparency=1})
 local switches:any={}
 for index,key in ipairs({"AutoTrain","AutoRace","SlowMode"}) do
  local parent=if key=="SlowMode" then root else autoBar
  local b=make("TextButton",parent,{Name=key,Size=UDim2.fromOffset(128,38),Position=if key=="SlowMode" then UDim2.new(0,0,1,-42) else UDim2.fromOffset((index-1)*136,0),BackgroundColor3=white,TextColor3=white,TextStrokeTransparency=.45,TextStrokeColor3=Color3.fromRGB(15,65,85),TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,Text="",AutoButtonColor=false})
  corner(b,12);make("UIGradient",b,{Color=ColorSequence.new(Color3.fromRGB(79,212,207),Color3.fromRGB(65,110,207)),Rotation=25})
  switches[key]=b
  b.Activated:Connect(function()
   if not api.Snapshot then return end
   local mode=api.Snapshot.Automation or {};api.OnAction("Automation",{Setting=key,Enabled=not mode[key],Difficulty=api.Difficulty})
  end)
 end
 local boostText=make("TextLabel",autoBar,{Name="ActiveBoosts",Size=UDim2.new(1,80,0,32),Position=UDim2.fromOffset(-40,39),BackgroundTransparency=1,Text="",TextColor3=white,TextStrokeTransparency=.25,TextStrokeColor3=Color3.fromRGB(15,55,75),TextSize=12,Font=Enum.Font.GothamBold})
 local noticeToast=make("TextLabel",root,{Name="ActionNotice",Visible=false,AnchorPoint=Vector2.new(0.5,0),Size=UDim2.new(0.7,0,0,58),Position=UDim2.fromScale(0.6,0.14),BackgroundTransparency=1,Text="",TextWrapped=true,TextColor3=white,TextStrokeColor3=Color3.fromRGB(15,55,68),TextStrokeTransparency=0.2,TextSize=15,Font=Enum.Font.GothamBold})
 local overlay=make("TextButton",root,{Visible=false,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,51,68),BackgroundTransparency=0.3,Text="",AutoButtonColor=false,ZIndex=20})
 local window=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0.9,0,0.85,0),Position=UDim2.fromScale(0.5,0.5),BackgroundColor3=Color3.fromRGB(26,98,134),BorderSizePixel=0,ZIndex=21});corner(window,22)
 local windowStroke=make("UIStroke",window,{Color=Color3.fromRGB(140,242,255),Thickness=2,Transparency=.25})
 local windowGradient=make("UIGradient",window,{Color=ColorSequence.new(Color3.fromRGB(199,247,255),Color3.fromRGB(112,178,228)),Rotation=100})
 make("UISizeConstraint",window,{MaxSize=Vector2.new(560,560),MinSize=Vector2.new(240,200)})
 local titleIcon=make("Frame",window,{Name="MenuTitleIcon",Size=UDim2.fromOffset(40,40),Position=UDim2.fromOffset(8,4),BackgroundTransparency=1,ZIndex=22})
 local heading=make("TextLabel",window,{Size=UDim2.new(1,-110,0,48),Position=UDim2.fromOffset(48,0),Text="",BackgroundTransparency=1,TextColor3=white,TextSize=22,TextScaled=true,TextWrapped=false,Font=Enum.Font.GothamBold,ZIndex=22})
 make("UITextSizeConstraint",heading,{MinTextSize=12,MaxTextSize=22})
 local close=make("TextButton",window,{Size=UDim2.fromOffset(42,38),Position=UDim2.new(1,-50,0,6),Text="×",TextColor3=white,TextSize=28,BackgroundTransparency=1,ZIndex=22})
 local content=make("ScrollingFrame",window,{Size=UDim2.new(1,-24,1,-90),Position=UDim2.fromOffset(12,54),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ZIndex=22})
 local notice=make("TextLabel",window,{Size=UDim2.new(1,-20,0,26),Position=UDim2.new(0,10,1,-28),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(255,234,150),TextSize=12,TextWrapped=true,ZIndex=24,Font=Enum.Font.GothamBold})
 local function clear()
  api.Viewport=nil
  for object,t in pairs(activeTweens) do if object:IsDescendantOf(content) then t:Cancel();activeTweens[object]=nil end end
  for _,child in ipairs(content:GetChildren()) do child:Destroy() end
  make("UIListLayout",content,{Padding=UDim.new(0,12),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})
 end
 local function row(value:string,height:number?):any
  local l=text(content,value,height or 52);l.ZIndex=23;l.TextSize=15;l.TextStrokeTransparency=.8
  return l
 end
 local function bar(ratio:number):any
  local frame=make("Frame",content,{Size=UDim2.new(1,-20,0,15),BackgroundColor3=Color3.fromRGB(13,76,98),BorderSizePixel=0,ZIndex=23});corner(frame,8)
  local fill=make("Frame",frame,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(111,234,115),BorderSizePixel=0,ZIndex=24});corner(fill,8)
  tween(fill,{Size=UDim2.fromScale(math.clamp(ratio,0,1),1)},0.3);return fill
 end
 local function command(value:string,callback:()->()):any
  local b=make("TextButton",content,{Size=UDim2.new(1,-20,0,48),Text=value,TextColor3=white,TextSize=16,TextWrapped=true,Font=Enum.Font.GothamBold,BackgroundColor3=palette[api.CurrentMenu] or palette.Worlds,BorderSizePixel=0,ZIndex=23});corner(b,12)
  make("UIGradient",b,{Color=ColorSequence.new(Color3.fromRGB(207,255,242),Color3.fromRGB(114,189,245)),Rotation=22})
  make("UIStroke",b,{Color=white,Transparency=.7,Thickness=1})
  b.TextStrokeTransparency=.7;b.TextStrokeColor3=Color3.fromRGB(20,74,103)
  local scale=make("UIScale",b,{Scale=1})
  b.MouseEnter:Connect(function() tween(scale,{Scale=1.015},.12) end)
  b.MouseLeave:Connect(function() tween(scale,{Scale=1},.12) end)
  b.Activated:Connect(function() audio.play("Button");callback() end);return b
 end
 function api.preview(folder:Instance,modelName:string,pet:boolean):any
  local view=make("ViewportFrame",content,{Size=UDim2.new(1,-20,0,180),BackgroundColor3=Color3.fromRGB(26,76,100),BorderSizePixel=0,Ambient=Color3.fromRGB(200,220,230),LightColor=white,ZIndex=23});corner(view,14)
  local world=Instance.new("WorldModel");world.Parent=view
  local source=folder:FindFirstChild(modelName)
  local distance=if pet then 5 else 10
  if source and source:IsA("Model") then
   local model=source:Clone();model.Parent=world
   local bounds,size=model:GetBoundingBox()
   model:PivotTo(CFrame.new(-bounds.Position)*model:GetPivot())
   distance=math.max(3,math.max(size.X,size.Y,size.Z)*1.45)
  else row("Modell fehlt: "..modelName,35) end
  local camera=Instance.new("Camera");camera.FieldOfView=40;camera.CFrame=CFrame.lookAt(Vector3.new(distance*0.75,distance*0.4,distance),Vector3.zero);camera.Parent=view;view.CurrentCamera=camera
  api.Viewport={Camera=camera,Frame=view,Distance=distance,TargetY=0}
  return view
 end
 function api.collapse(value:boolean)
  State.setting(settings,"Collapsed",value)
  arrange()
  api.OnSetting()
 end
 toggle.Activated:Connect(function() audio.play("Button");api.collapse(not settings.Collapsed) end)
 local function hide()
  api.Closing=true
  local token=generation
  api.Viewport=nil
  tween(window,{Position=UDim2.fromScale(0.5,0.53)},0.12)
  task.delay(if settings.Animations then 0.12 else 0,function() if generation==token then overlay.Visible=false;api.Viewport=nil end end)
 end
 close.Activated:Connect(hide)
 function api.open(name:string)
  api.Closing=false
  content.CanvasPosition=Vector2.zero
  api.CurrentMenu=name
  generation+=1
  clear();notice.Text="";heading.Text=({Rebirths="REBIRTH",Pets="PETS",Garage="BIKE GARAGE",Eggs="EGGS",Egg="EGG HATCH",Hatch="NEUES PET",Race="RACE",Worlds="WORLDS",Shop="SHOP",Settings="SETTINGS"})[name] or name
  local accent=palette[name] or palette.Pets
  windowStroke.Color=accent
  windowGradient.Rotation=if name=="Race" then 25 else 100
  for _,child in ipairs(titleIcon:GetChildren()) do child:Destroy() end
  local icon=Icons.draw(titleIcon,if name=="Egg" or name=="Eggs" or name=="Hatch" then "Pets" else name);icon.Position=UDim2.fromOffset(0,0);icon.Size=UDim2.fromOffset(34,34)
  overlay.Visible=true;window.Position=UDim2.fromScale(0.5,0.53);tween(window,{Position=UDim2.fromScale(0.5,0.5)})
  local snap=api.Snapshot
  if name=="Settings" then
   for _,entry in ipairs({{Key="Animations",Label="Animationen"},{Key="Popups",Label="Energy-Pop-ups"},{Key="Sound",Label="Soundeffekte"},{Key="Collapsed",Label="Kompakte Sidebar"}}) do
    local b:any
    b=command(entry.Label..": "..(if settings[entry.Key] then "AN" else "AUS"),function()
     if entry.Key=="Collapsed" then api.collapse(not settings.Collapsed) else State.setting(settings,entry.Key,not settings[entry.Key]) end
     b.Text=entry.Label..": "..(if settings[entry.Key] then "AN" else "AUS");api.OnSetting()
    end)
   end
   local volume=row("Lautstärke: "..math.floor(settings.Volume*100).." %",30)
   command("− Leiser",function() State.setting(settings,"Volume",settings.Volume-0.1);volume.Text="Lautstärke: "..math.floor(settings.Volume*100).." %";api.OnSetting() end)
   command("+ Lauter",function() State.setting(settings,"Volume",settings.Volume+0.1);volume.Text="Lautstärke: "..math.floor(settings.Volume*100).." %";api.OnSetting() end)
  elseif name=="Shop" then
   row("PREMIUM SHOP",40)
   row("Roblox bestätigt Preis und Zahlung. Unkonfigurierte Angebote und Käufe im nicht persistenten Studio-Preview bleiben deaktiviert.",65)
   for _,category in ipairs({"Gamepasses","Cash Bundles","Boost Potions","Exclusive Pets"}) do
    row(category,32)
    local offers=if category=="Gamepasses" then Premium.Passes else Premium.Products
    local keys={};for key,def in pairs(offers) do if category=="Gamepasses" or def.Category==category then table.insert(keys,key) end end;table.sort(keys)
    for _,key in ipairs(keys) do
     local def=offers[key];local enabled=def.Id>0 and not def.Unavailable and snap and snap.PremiumAvailable==true
     if def.ExclusiveId then local pet=Premium.Exclusives[def.ExclusiveId];api.preview(game:GetService("ReplicatedStorage").PetModels,pet.Model,true);row("Energy ×"..pet.EnergyMultiplier.." / Cash ×"..pet.CashMultiplier,30) end
     local b=command(def.Name..(if enabled then " • Roblox-Kauf öffnen" elseif def.Id<=0 then " • NOCH NICHT KONFIGURIERT" else " • IM PREVIEW GESPERRT"),function() if enabled then api.OnAction("Premium",{Offer=key}) end end)
     b.Active=enabled;b.AutoButtonColor=enabled;b.BackgroundTransparency=if enabled then 0 else .4
    end
   end
   command("Fahrzeuge kaufen",function() api.open("Garage") end)
   command("Eier kaufen / öffnen",function() api.open("Eggs") end)
   command("Pet-Inventar",function() api.open("Pets") end)
  elseif name=="Worlds" and snap then
   row("WELTEN • "..#(snap.OwnedWorlds or {1}).." / 8 freigeschaltet",45)
   for id=1,8 do
    local owned=table.find(snap.OwnedWorlds or {1},id)~=nil
    row((if id==1 then "PALM BAY" else "WELT "..id).." • "..(if owned then "Freigeschaltet" else "Gesperrt")..(if id>1 then "\nMap noch nicht in diesem Build. Keine Reise/Käufe." else "\nAktuelle Insel"),60)
   end
   command("Rennen in Palm Bay",function() api.open("Race") end)
  elseif name=="Garage" and snap then
   local id=api.VehicleId or snap.ActiveVehicle or 1
   if not Content.Vehicles[id] then id=1 end
   local definition=Catalog.Vehicles[id]
   row(definition.Name.." • ID "..id.." • Tempo ×"..Format.multiplier(definition.SpeedMultiplier),45)
   api.preview(game:GetService("ReplicatedStorage").Vehicles,definition.Model,false)
   local owned=table.find(snap.OwnedVehicles or {1},id)~=nil
   row(if snap.ActiveVehicle==id then "✓ AKTIV AUSGERÜSTET" elseif owned then "In deinem Besitz" else Format.number(definition.CashCost).." Cash",30)
   if snap.ActiveVehicle~=id then command(if owned then "Ausrüsten" else "Kaufen",function() api.OnAction(if owned then "EquipVehicle" else "BuyVehicle",{VehicleId=id}) end) end
   for vehicleId=1,10 do local v=Catalog.Vehicles[vehicleId];command(v.Name.." • "..Format.number(v.CashCost).." Cash",function() api.VehicleId=vehicleId;api.open("Garage") end) end
  elseif name=="Pets" and snap then
   row("Pets • "..#(snap.EquippedPets or {}).." / 3 ausgerüstet\nEnergy ×"..Format.multiplier(snap.PetEnergyBonus or 1).." • Cash ×"..Format.multiplier(snap.PetCashBonus or 1),65)
   local best=command("⚡ EQUIP BEST",function() api.OnAction("EquipBest") end)
   best.BackgroundColor3=Color3.fromRGB(19,162,127)
   make("UIGradient",best,{Color=ColorSequence.new(Color3.fromRGB(132,255,137),Color3.fromRGB(87,210,255)),Rotation=20})
   row("Einmalig die drei besten Pets • Energy und Cash gleich gewichtet",35)
   command("UNEQUIP ALL",function() api.OnAction("UnequipAll") end)
   local activeNames={}
   for _,id in ipairs(snap.EquippedPets or {}) do local pet=snap.Pets[id];if pet then table.insert(activeNames,PetRules.definition(pet).Name or "Unbekannt") end end
   row("Slots: "..(if #activeNames==0 then "leer / leer / leer" else table.concat(activeNames," / ")),50)
   command("Eier öffnen",function() api.open("Eggs") end)
   command("Pet-Index",function() api.open("Index") end)
   local ids={};for id in pairs(snap.Pets or {}) do table.insert(ids,id) end;table.sort(ids)
   if #ids==0 then row("Noch keine Pets. Verdiene Cash im Rennen und öffne ein Ei.",65) end
   local page=math.clamp(api.PetPage or 1,1,math.max(1,math.ceil(#ids/20)));api.PetPage=page
   row("Inventarseite "..page.." / "..math.max(1,math.ceil(#ids/20)),25)
   for i=(page-1)*20+1,math.min(page*20,#ids) do
    local id=ids[i];local pet=snap.Pets[id];local d=PetRules.definition(pet)
    local b=command((if table.find(snap.EquippedPets,id) then "✓ " else "")..(d.Name or "Unbekannte Art").." • "..pet.Variant..(if d.Playable then "\nEnergy ×"..Format.multiplier(1+(d.EnergyMultiplier-1)*Content.Variants[pet.Variant]).." • Cash ×"..Format.multiplier(1+(d.CashMultiplier-1)*Content.Variants[pet.Variant]) else ""),function() api.PetId=id;api.open("Pet") end)
    b.TextSize=14;b.TextWrapped=true;b.Size=UDim2.new(1,-20,0,58)
    local rarity=b:FindFirstChildOfClass("UIStroke");if rarity then rarity.Color=if d.Rarity=="Legendary" then Color3.fromRGB(255,222,109) elseif d.Rarity=="Rare" then Color3.fromRGB(194,149,255) else Color3.fromRGB(135,240,217) end
   end
   if page>1 then command("← Vorherige Seite",function() api.PetPage=page-1;api.open("Pets") end) end
   if page*20<#ids then command("Nächste Seite →",function() api.PetPage=page+1;api.open("Pets") end) end
  elseif name=="Pet" and snap then
   local id=api.PetId;local pet=snap.Pets[id]
   if pet then
    local d=PetRules.definition(pet);local factor=Content.Variants[pet.Variant]
    row((d.Name or "Unbekannte Art").." • "..pet.Variant.." • "..(d.Rarity or "Offen"),45)
    if d.Playable then api.preview(game:GetService("ReplicatedStorage").PetModels,d.Model or "Pet"..pet.SpeciesId,true);row("Energy ×"..Format.multiplier(1+(d.EnergyMultiplier-1)*factor).." • Cash ×"..Format.multiplier(1+(d.CashMultiplier-1)*factor),35) end
    local equipped=table.find(snap.EquippedPets,id)~=nil
    command(if equipped then "Ablegen" else "Ausrüsten",function() api.OnAction(if equipped then "UnequipPet" else "EquipPet",{PetId=id}) end)
   end
   command("Zurück zum Inventar",function() api.open("Pets") end)
  elseif name=="Index" and snap then
   local found=0;for _,id in ipairs(snap.DiscoveredPets or {}) do if id<=12 then found+=1 end end
   row("Welt-1-Sammlung: "..found.." / 12",35)
   for eggId=1,3 do
    row(Catalog.Eggs[eggId].Name,30)
    for _,id in ipairs(Catalog.Eggs[eggId].Species) do local pet=Catalog.Pets[id];row((if table.find(snap.DiscoveredPets or {},id) then "✓ "..pet.Name else "???").." • "..pet.Rarity,32) end
   end
  elseif name=="Eggs" then
   row("Drei Eier • Je vier mögliche Pet-Arten",40)
   for eggId=1,3 do local e=Catalog.Eggs[eggId];command(e.Name.." • "..Format.number(e.CashCost).." Cash",function() api.EggId=eggId;api.open("Egg") end) end
  elseif name=="Egg" then
   local id=api.EggId or 1;local egg=Catalog.Eggs[id]
   row(egg.Name.." • "..Format.number(egg.CashCost).." Cash",40)
   for i,species in ipairs(egg.Species) do local d=Catalog.Pets[species];row(d.Name.." • "..d.Rarity.." • "..egg.Weights[i]/100 .." %\nEnergy ×"..Format.multiplier(d.EnergyMultiplier).." • Cash ×"..Format.multiplier(d.CashMultiplier),54) end
   command("Ei öffnen",function() api.OnAction("Hatch",{EggId=id}) end)
   command("Alle Eier",function() api.open("Eggs") end)
  elseif name=="Hatch" then
   local id=api.HatchedId;local d=Catalog.Pets[id]
   row("ERHALTEN: "..d.Name.." • "..d.Rarity,45)
   local view=api.preview(game:GetService("ReplicatedStorage").PetModels,"Pet"..id,true)
   if settings.Animations then local reveal=make("UIScale",view,{Scale=0.35});tween(reveal,{Scale=1},0.45) end
   command("Zum Pet-Inventar",function() api.open("Pets") end)
  elseif name=="Rebirths" and snap then
   local p=Presentation.rebirth(snap)
   api.RebirthInfo=row("",110);api.RebirthBar=bar(p.Ratio)
   api.RebirthConfirm=command("Rebirth bestätigen",function() if api.Snapshot and Presentation.rebirth(api.Snapshot).Allowed then api.OnAction("Rebirth");hide() end end)
   command("Abbrechen",hide)
  elseif name=="Race" then
   row("WORLD 1 • 800 Studs • 5 Bots\nEnergy wird nicht verbraucht.",55)
   for _,tier in ipairs({"Easy","Medium","Hard"}) do command((if api.Difficulty==tier then "✓ " else "")..tier,function() api.Difficulty=tier;if api.Snapshot and api.Snapshot.Automation and api.Snapshot.Automation.AutoRace then api.OnAction("Automation",{Setting="AutoRace",Enabled=true,Difficulty=tier}) end;api.open("Race") end) end
   local tier=Content.Difficulties[api.Difficulty]
   row("Bot-Tempo: "..table.concat(tier.Speeds," / ").."\nCash Plätze 1–6: "..table.concat(tier.Rewards," / "),60)
   api.RaceInfo=row("",70);api.RaceBar=bar(0)
   if api.LastRaceResult then row("Ergebnis "..(api.LastRaceResult.Difficulty or "")..": Platz "..(api.LastRaceResult.Place or "—").." • +"..Format.number(api.LastRaceResult.Reward or 0).." Cash",50) end
   command("Rennen starten / erneut starten",function() api.OnAction("StartRace",{Difficulty=api.Difficulty});hide() end)
   command("Rennen abbrechen",function() api.OnAction("AbortRace");hide() end)
  else row(name.." • VORSCHAU\nDieser Bereich ist noch nicht spielbar. Keine Käufe oder Belohnungen.",90) end
  api.update(api.Snapshot)
 end
 function api.update(snap:any)
  if not snap then return end
  local oldRevision=if api.Snapshot then api.Snapshot.InventoryRevision else nil
  api.Snapshot=snap
  if oldRevision~=nil and snap.InventoryRevision~=oldRevision and overlay.Visible and not api.Closing and (api.CurrentMenu=="Garage" or api.CurrentMenu=="Pets" or api.CurrentMenu=="Pet" or api.CurrentMenu=="Index") then
   api.open(api.CurrentMenu)
  end
  for _,name in ipairs({"Energy","Cash","Rebirths"}) do
   local old=resourceValues[name]:GetAttribute("ConfirmedValue")
   resourceValues[name].Text=Format.number(snap[name]);resourceValues[name]:SetAttribute("ConfirmedValue",snap[name])
   if old and snap[name]>old and settings.Animations then
    local glint=resourceIcons[name]:FindFirstChild(if name=="Energy" then "BoltGlint" else "CoinGlint")
    if glint then glint.BackgroundTransparency=0;task.delay(.12,function() if glint.Parent then tween(glint,{BackgroundTransparency=.75},.25) end end) end
    local pop=resourceIcons[name]:FindFirstChildOfClass("UIScale");if pop then tween(pop,{Scale=1.17},.08);task.delay(.1,function() if pop.Parent then tween(pop,{Scale=1},.17) end end) end
   end
  end
  local mode=snap.Automation or {}
  for key,b in pairs(switches) do
   local label=({AutoTrain="AUTO TRAIN",AutoRace="AUTO RACE",SlowMode="SLOW MODE"})[key]
   b.Text=label..(if mode[key] then " • ON" else " • OFF")
  end
  local boosts=snap.Boosts or {};local active={}
  for _,kind in ipairs({"Energy","Cash"}) do if (boosts[kind] or 0)>0 then table.insert(active,kind.." ×2 • "..math.ceil(boosts[kind]).."s") end end
  boostText.Text=table.concat(active,"  /  ")
  if api.RebirthInfo and api.RebirthInfo.Parent then
   local r=Presentation.rebirth(snap);api.RebirthInfo.Text="Rebirths: "..Format.number(r.Current).."\nMultiplikator ×"..Format.multiplier(r.Multiplier).." → ×"..Format.multiplier(r.NextMultiplier).."\nBenötigt: "..Format.number(r.Requirement).." Energy\nEnergy wird auf 0 gesetzt. Laufbandzugang kann entfallen."
   tween(api.RebirthBar,{Size=UDim2.fromScale(r.Ratio,1)});api.RebirthConfirm.Text=if r.Allowed then "Rebirth bestätigen" else "Noch nicht genug Energy";api.RebirthConfirm.Active=r.Allowed;api.RebirthConfirm.AutoButtonColor=r.Allowed
  end
  if api.RaceInfo and api.RaceInfo.Parent then
   local race=snap.Race or {Phase="Idle",Progress=0};api.RaceInfo.Text=(race.Difficulty or "Easy").." • "..(Catalog.Vehicles[snap.ActiveVehicle or 1].Name or "Fahrzeug").."\n"..race.Phase.." • Platz "..(race.Place or "—").." / 6 • "..math.floor(race.Progress*100).." %"
   tween(api.RaceBar,{Size=UDim2.fromScale(race.Progress,1)})
  end
 end
 api.Notice=noticeToast;api.Sidebar=sidebar;api.Navigation=list
 function api.isMenuOpen():boolean return overlay.Visible end
 local toastSequence=0
 function api.message(value:string)
  toastSequence+=1;local token=toastSequence
  noticeToast.Text=value;noticeToast.Visible=true;notice.Text=value
  task.delay(4,function() if token==toastSequence then noticeToast.Visible=false end end)
 end
 function api.refreshSettings()
  if not settings.Animations then
   for object,t in pairs(activeTweens) do t:Cancel();activeTweens[object]=nil end
   for _,s in pairs(scales) do s.Scale=1 end
   arrange()
   window.Position=UDim2.fromScale(0.5,0.5)
  end
 end
 local function layout()
  local size=root.AbsoluteSize
  arrange()
  local touch=UserInputService.TouchEnabled
  local compact=touch or size.X<600
  local rowHeight=if compact then 30 else 36
  local hudWidth=if compact then 136 else 160
  -- Exact 10px inset from the unpadded CoreUISafeInsets canvas, on every device.
  -- The owned touch jump button moves above this HUD instead of pushing resources inward.
  resourceHUD.Position=UDim2.new(1,-10,1,-10)
  resourceHUD.Size=UDim2.fromOffset(hudWidth,rowHeight*3)
  for i,name in ipairs({"Energy","Cash","Rebirths"}) do
   resourceRows[name].Position=UDim2.fromOffset(0,(i-1)*rowHeight)
   resourceRows[name].Size=UDim2.new(1,0,0,rowHeight)
   resourceIcons[name].Size=UDim2.fromOffset(rowHeight,rowHeight)
   resourceValues[name].TextSize=if compact then 22 else 27
   resourceValues[name]:FindFirstChildOfClass("UITextSizeConstraint").MaxTextSize=if compact then 22 else 27
   resourceValues[name].Position=UDim2.fromOffset(rowHeight+6,0)
   resourceValues[name].Size=UDim2.new(1,-rowHeight-6,1,0)
  end
 end
 arrange=function()
  local size=root.AbsoluteSize
  local short=size.Y<420
  local columns=1
  local compact=settings.Collapsed or short or size.X<320
  local width=if compact then 48 else 158
  local height=44;local gap=6
  local rows=math.ceil(7/columns)
  sidebarHeight=32+rows*(height+gap)-gap
  local available=math.max(100,size.Y-126)
  scale.Scale=math.min(1,available/sidebarHeight)
  sidebar.Size=UDim2.fromOffset(columns*(width+gap)-gap,sidebarHeight)
  for i,name in ipairs({"Garage","Pets","Race","Worlds","Rebirths","Shop","Settings"}) do
   buttons[name].Size=UDim2.fromOffset(width,height)
   buttons[name].Position=UDim2.fromOffset(((i-1)%columns)*(width+gap),math.floor((i-1)/columns)*(height+gap))
   labels[name].Visible=not compact
  end
 end
 resourceCanvas:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout);layout();api.collapse(settings.Collapsed)
 return api
end
return UI
