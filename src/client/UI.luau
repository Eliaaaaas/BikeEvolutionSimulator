--!strict
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Format=require(Shared:WaitForChild("Format"))
local Presentation=require(Shared:WaitForChild("Presentation"))
local Catalog=require(Shared:WaitForChild("Catalog"))
local Content=require(Shared:WaitForChild("World1Content"))
local State=require(Shared:WaitForChild("ClientState"))
local Icons=require(script.Parent.Icons)
local UI={}
local white=Color3.new(1,1,1)
local palette={Energy=Color3.fromRGB(217,157,23),Cash=Color3.fromRGB(32,151,88),Rebirths=Color3.fromRGB(23,157,177),Garage=Color3.fromRGB(44,133,204),Pets=Color3.fromRGB(59,162,106),Race=Color3.fromRGB(229,125,38),Worlds=Color3.fromRGB(33,163,159),Upgrades=Color3.fromRGB(197,153,29),Settings=Color3.fromRGB(54,130,174)}
local function make(class:string,parent:Instance?,props:any):any
 local o:any=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local function corner(o:Instance,r:number) make("UICorner",o,{CornerRadius=UDim.new(0,r)}) end
local function text(parent:Instance,value:string,height:number):any
 return make("TextLabel",parent,{Size=UDim2.new(1,-16,0,height),BackgroundTransparency=1,Text=value,TextWrapped=true,TextColor3=white,TextSize=16,Font=Enum.Font.GothamBold,LayoutOrder=0})
end
function UI.new(playerGui:Instance,settings:any,audio:any):any
 local gui=make("ScreenGui",playerGui,{Name="PalmBaySidebar",ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 local root=make("Frame",gui,{Size=UDim2.new(1,-16,1,-16),Position=UDim2.fromOffset(8,8),BackgroundTransparency=1})
 local sidebar=make("Frame",root,{Size=UDim2.fromOffset(210,535),Position=UDim2.fromOffset(0,4),BackgroundColor3=Color3.fromRGB(17,89,112),BackgroundTransparency=0.14,BorderSizePixel=0})
 corner(sidebar,18);make("UIStroke",sidebar,{Color=white,Thickness=1,Transparency=0.65})
 local scale=make("UIScale",sidebar,{Scale=1})
 local shadow=make("Frame",sidebar,{Size=UDim2.new(1,4,1,4),Position=UDim2.fromOffset(2,3),BackgroundColor3=Color3.fromRGB(13,59,78),BackgroundTransparency=0.85,ZIndex=0,BorderSizePixel=0});corner(shadow,18)
 local toggle=make("TextButton",sidebar,{Size=UDim2.new(1,-12,0,38),Position=UDim2.fromOffset(6,6),Text="☰  PALM BAY",TextColor3=white,TextSize=15,Font=Enum.Font.GothamBold,BackgroundTransparency=1})
 local list=make("ScrollingFrame",sidebar,{Position=UDim2.fromOffset(6,48),Size=UDim2.new(1,-12,1,-54),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
 make("UIListLayout",list,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
 local buttons:any={};local labels:any={};local scales:any={};local activeTweens:any={}
 local function tween(object:any,properties:any,duration:number?)
  if activeTweens[object] then activeTweens[object]:Cancel();activeTweens[object]=nil end
  if not settings.Animations then for key,value in pairs(properties) do object[key]=value end;return end
  local t=TweenService:Create(object,TweenInfo.new(duration or 0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),properties)
  activeTweens[object]=t;t.Completed:Once(function() if activeTweens[object]==t then activeTweens[object]=nil end end);t:Play()
 end
 local sidebarHeight=535
 local generation=0
 local messageUntil=0
 local messageText=""
 local api:any={Gui=gui,Settings=settings,Buttons=buttons,Snapshot=nil,Viewport=nil,OnAction=function() end,OnSetting=function() end,OnMenu=function() end,Difficulty="Easy"}
 for i,name in ipairs({"Energy","Cash","Rebirths","Garage","Pets","Race","Worlds","Upgrades","Settings"}) do
  local button=make("TextButton",list,{Name=name,LayoutOrder=i,Size=UDim2.new(1,-4,0,47),BackgroundColor3=palette[name],BackgroundTransparency=0.08,BorderSizePixel=0,Text="",AutoButtonColor=false})
  corner(button,12);make("UIGradient",button,{Color=ColorSequence.new(white,Color3.fromRGB(185,226,241)),Rotation=32})
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
 local training=make("TextButton",root,{AnchorPoint=Vector2.new(1,1),Size=UDim2.fromOffset(225,54),Position=UDim2.new(1,-8,1,-142),Text="ϟ TRAINIEREN",Font=Enum.Font.GothamBold,TextSize=17,TextColor3=white,BackgroundColor3=palette.Energy,BorderSizePixel=0});corner(training,15)
 local status=make("TextLabel",root,{AnchorPoint=Vector2.new(1,1),Size=UDim2.fromOffset(225,58),Position=UDim2.new(1,-8,1,-200),BackgroundColor3=Color3.fromRGB(20,111,128),BackgroundTransparency=0.2,Text="Daten werden geladen …",TextWrapped=true,TextColor3=white,TextSize=13,Font=Enum.Font.GothamBold});corner(status,12)
 training.Activated:Connect(function() if api.Snapshot and api.Snapshot.Race and api.Snapshot.Race.Phase~="Idle" then return end;audio.play("Button");api.OnAction("Training") end)
 local overlay=make("TextButton",root,{Visible=false,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(12,51,68),BackgroundTransparency=0.3,Text="",AutoButtonColor=false,ZIndex=20})
 local window=make("Frame",overlay,{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.new(0.9,0,0.85,0),Position=UDim2.fromScale(0.5,0.5),BackgroundColor3=Color3.fromRGB(25,116,139),BorderSizePixel=0,ZIndex=21});corner(window,20)
 make("UISizeConstraint",window,{MaxSize=Vector2.new(560,560),MinSize=Vector2.new(240,200)})
 local heading=make("TextLabel",window,{Size=UDim2.new(1,-70,0,48),Position=UDim2.fromOffset(14,0),Text="",BackgroundTransparency=1,TextColor3=white,TextSize=22,Font=Enum.Font.GothamBold,ZIndex=22})
 local close=make("TextButton",window,{Size=UDim2.fromOffset(42,38),Position=UDim2.new(1,-50,0,6),Text="×",TextColor3=white,TextSize=28,BackgroundTransparency=1,ZIndex=22})
 local content=make("ScrollingFrame",window,{Size=UDim2.new(1,-24,1,-90),Position=UDim2.fromOffset(12,54),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ZIndex=22})
 local notice=make("TextLabel",window,{Size=UDim2.new(1,-20,0,26),Position=UDim2.new(0,10,1,-28),BackgroundTransparency=1,Text="",TextColor3=Color3.fromRGB(255,234,150),TextSize=12,TextWrapped=true,ZIndex=24,Font=Enum.Font.GothamBold})
 local function clear()
  api.Viewport=nil
  for object,t in pairs(activeTweens) do if object:IsDescendantOf(content) then t:Cancel();activeTweens[object]=nil end end
  for _,child in ipairs(content:GetChildren()) do child:Destroy() end
  make("UIListLayout",content,{Padding=UDim.new(0,12),HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})
 end
 local function row(value:string,height:number?):any local l=text(content,value,height or 52);l.ZIndex=23;return l end
 local function bar(ratio:number):any
  local frame=make("Frame",content,{Size=UDim2.new(1,-20,0,15),BackgroundColor3=Color3.fromRGB(13,76,98),BorderSizePixel=0,ZIndex=23});corner(frame,8)
  local fill=make("Frame",frame,{Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.fromRGB(111,234,115),BorderSizePixel=0,ZIndex=24});corner(fill,8)
  tween(fill,{Size=UDim2.fromScale(math.clamp(ratio,0,1),1)},0.3);return fill
 end
 local function command(value:string,callback:()->()):any
  local b=make("TextButton",content,{Size=UDim2.new(1,-20,0,48),Text=value,TextColor3=white,TextSize=16,Font=Enum.Font.GothamBold,BackgroundColor3=palette.Worlds,BorderSizePixel=0,ZIndex=23});corner(b,12)
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
  tween(sidebar,{Size=UDim2.fromOffset(if value then 94 else 210,sidebarHeight)})
  toggle.Text=if value then "☰" else "☰  PALM BAY"
  for name,label in pairs(labels) do
   if name=="Energy" or name=="Cash" or name=="Rebirths" then
    label.Position=if value then UDim2.fromOffset(39,0) else UDim2.fromOffset(48,0)
    label.Size=UDim2.new(1,if value then -40 else -52,1,0);label.TextSize=if value then 11 else 14
   else label.Visible=not value end
  end
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
  clear();notice.Text="";heading.Text=name;overlay.Visible=true;window.Position=UDim2.fromScale(0.5,0.53);tween(window,{Position=UDim2.fromScale(0.5,0.5)})
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
   local activeNames={}
   for _,id in ipairs(snap.EquippedPets or {}) do local pet=snap.Pets[id];if pet then table.insert(activeNames,Catalog.Pets[pet.SpeciesId].Name or "Unbekannt") end end
   row("Slots: "..(if #activeNames==0 then "leer / leer / leer" else table.concat(activeNames," / ")),50)
   command("Eier öffnen",function() api.open("Eggs") end)
   command("Pet-Index",function() api.open("Index") end)
   local ids={};for id in pairs(snap.Pets or {}) do table.insert(ids,id) end;table.sort(ids)
   if #ids==0 then row("Noch keine Pets. Verdiene Cash im Rennen und öffne ein Ei.",65) end
   local page=math.clamp(api.PetPage or 1,1,math.max(1,math.ceil(#ids/20)));api.PetPage=page
   row("Inventarseite "..page.." / "..math.max(1,math.ceil(#ids/20)),25)
   for i=(page-1)*20+1,math.min(page*20,#ids) do
    local id=ids[i];local pet=snap.Pets[id];local d=Catalog.Pets[pet.SpeciesId]
    command((if table.find(snap.EquippedPets,id) then "✓ " else "")..(d.Name or "Unbekannte Art").." • "..pet.Variant,function() api.PetId=id;api.open("Pet") end)
   end
   if page>1 then command("← Vorherige Seite",function() api.PetPage=page-1;api.open("Pets") end) end
   if page*20<#ids then command("Nächste Seite →",function() api.PetPage=page+1;api.open("Pets") end) end
  elseif name=="Pet" and snap then
   local id=api.PetId;local pet=snap.Pets[id]
   if pet then
    local d=Catalog.Pets[pet.SpeciesId];local factor=Content.Variants[pet.Variant]
    row((d.Name or "Unbekannte Art").." • "..pet.Variant.." • "..(d.Rarity or "Offen"),45)
    if d.Playable then api.preview(game:GetService("ReplicatedStorage").PetModels,"Pet"..pet.SpeciesId,true);row("Energy ×"..Format.multiplier(1+(d.EnergyMultiplier-1)*factor).." • Cash ×"..Format.multiplier(1+(d.CashMultiplier-1)*factor),35) end
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
  elseif name=="Energy" and snap then
   api.TrainingInfo=row("",125);api.TrainingBar=bar(0)
   command("Zusätzlicher Trainingsimpuls",function() api.OnAction("Training") end)
   command("Training beenden",function() api.OnAction("Stop");hide() end)
  elseif name=="Race" then
   row("PALM BAY • 800 Studs • 5 Bots\nEnergy wird nicht verbraucht.",55)
   for _,tier in ipairs({"Easy","Medium","Hard"}) do command((if api.Difficulty==tier then "✓ " else "")..tier,function() api.Difficulty=tier;api.open("Race") end) end
   local tier=Content.Difficulties[api.Difficulty]
   row("Bot-Tempo: "..table.concat(tier.Speeds," / ").."\nCash Plätze 1–6: "..table.concat(tier.Rewards," / "),60)
   api.RaceInfo=row("",70);api.RaceBar=bar(0)
   if api.LastRaceResult then row("Ergebnis "..(api.LastRaceResult.Difficulty or "")..": Platz "..(api.LastRaceResult.Place or "—").." • +"..Format.number(api.LastRaceResult.Reward or 0).." Cash",50) end
   command("Rennen starten / erneut starten",function() api.OnAction("StartRace",{Difficulty=api.Difficulty});hide() end)
   command("Rennen abbrechen",function() api.OnAction("AbortRace");hide() end)
  elseif name=="Cash" then row("Verdiene Cash in Rennen gegen fünf Bots. Die Platzierung und Schwierigkeit bestimmen deine Belohnung; ausgerüstete Pets erhöhen sie. Kaufe damit Fahrzeuge oder öffne Eier.",130)
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
  for _,name in ipairs({"Energy","Cash","Rebirths"}) do labels[name].Text=(if settings.Collapsed then "" else name.."\n")..Format.number(snap[name]) end
  local p=Presentation.training(snap)
  local info="Laufband "..p.Current.." • +"..Format.number(p.Gain).."/Impuls\n"..(if p.Complete then "Alle fünf Insel-Laufbänder verfügbar." else "Nächstes: "..p.Next.." • fehlen "..Format.number(p.Missing).." Energy\nODER "..Format.number(p.RebirthRequirement).." Rebirths (Weltzugang nötig)")
  local racing=snap.Race and snap.Race.Phase~="Idle"
  status.Text=if racing then (snap.Race.Difficulty or "Easy").." • Platz "..(snap.Race.Place or 1).." / 6\n"..(if snap.Race.Phase=="Countdown" then "Start in "..snap.Race.Countdown else math.floor(snap.Race.Progress*100).." % • "..Format.number(snap.Race.Speed).." Studs/Sek.") else "×"..Format.multiplier(snap.TrainingMultiplier).." • "..info
  if os.clock()<messageUntil then status.Text=messageText end
  training.Text=if racing then "🏁 RENNEN" elseif snap.SelectedTreadmill==0 then "ϟ TRAINIEREN" else "+"..Format.number(snap.ImpulseGain).." ϟ TIPPEN"
  training.Active=not racing;training.AutoButtonColor=not racing
  if api.TrainingInfo and api.TrainingInfo.Parent then api.TrainingInfo.Text=info;tween(api.TrainingBar,{Size=UDim2.fromScale(p.Ratio,1)}) end
  if api.RebirthInfo and api.RebirthInfo.Parent then
   local r=Presentation.rebirth(snap);api.RebirthInfo.Text="Rebirths: "..Format.number(r.Current).."\nMultiplikator ×"..Format.multiplier(r.Multiplier).." → ×"..Format.multiplier(r.NextMultiplier).."\nBenötigt: "..Format.number(r.Requirement).." Energy\nEnergy wird auf 0 gesetzt. Laufbandzugang kann entfallen."
   tween(api.RebirthBar,{Size=UDim2.fromScale(r.Ratio,1)});api.RebirthConfirm.Text=if r.Allowed then "Rebirth bestätigen" else "Noch nicht genug Energy";api.RebirthConfirm.Active=r.Allowed;api.RebirthConfirm.AutoButtonColor=r.Allowed
  end
  if api.RaceInfo and api.RaceInfo.Parent then
   local race=snap.Race or {Phase="Idle",Progress=0};api.RaceInfo.Text=(race.Difficulty or "Easy").." • "..(Catalog.Vehicles[snap.ActiveVehicle or 1].Name or "Fahrzeug").."\n"..race.Phase.." • Platz "..(race.Place or "—").." / 6 • "..math.floor(race.Progress*100).." %"
   tween(api.RaceBar,{Size=UDim2.fromScale(race.Progress,1)})
  end
 end
 api.Status=status
 function api.message(value:string) messageText=value;messageUntil=os.clock()+4;status.Text=value;notice.Text=value end
 function api.refreshSettings()
  if not settings.Animations then
   for object,t in pairs(activeTweens) do t:Cancel();activeTweens[object]=nil end
   for _,s in pairs(scales) do s.Scale=1 end
   sidebar.Size=UDim2.fromOffset(if settings.Collapsed then 94 else 210,sidebarHeight)
   window.Position=UDim2.fromScale(0.5,0.5)
  end
 end
 local function layout()
  local size=root.AbsoluteSize
  scale.Scale=if size.X<360 then 0.92 else 1
  sidebarHeight=math.min(535,math.max(100,(size.Y-(if UserInputService.TouchEnabled then 130 else 12))/scale.Scale))
  sidebar.Size=UDim2.fromOffset(if settings.Collapsed then 94 else 210,sidebarHeight)
  local width=math.min(225,math.max(155,size.X*0.4));training.Size=UDim2.fromOffset(width,48);status.Size=UDim2.fromOffset(width,65)
 end
 root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout);layout();api.collapse(settings.Collapsed)
 return api
end
return UI
