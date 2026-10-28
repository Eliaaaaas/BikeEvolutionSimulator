local function integration(preview,remove,live)
 local e=modules.runtimeEngine();modules.populateWorld(e.add,e.Workspace,e.Rep)
 if remove then e.Workspace.World1.Training.Treadmill_1.Zone:Destroy() end
 e.Workspace:SetAttribute("StudioPreviewData",preview)
 e.Studio=not live
 local serverScript=e.add(nil,"Script","Server")
 modules.BikeRig=modules.makeBikeRig(e.Instance)
 modules.RaceService=modules.makeRaceService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum)
 modules.PlayerDataService=modules.makeService(e.Game,e.Task,e.OS,e.Warn)
 modules.RiderMount=modules.make_RiderMount(e.CFrame)
 local mountedModule=modules.make_MountedBikeService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum,e.RaycastParams)
 modules.MountedBikeService={new=function(data) e.Mounts=mountedModule.new(data);return e.Mounts end}
 function e.teleport(x,y,z)
  local record=e.Mounts.ensure(e.Player)
  e.Mounts.teleport(e.Player,e.CFrame.new(x,y,z)*record.Offset:Inverse())
 end
 modules.GameplayService=modules.make_GameplayService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.Random)
 modules.RemoteService=modules.make_RemoteService(e.Game,e.Task,e.OS,e.Instance)
 local booted,bootError=pcall(modules.make_init_server,e.Game,e.Workspace,e.Instance,serverScript,e.Warn)
 if remove then assert(not booted);e.BootError=bootError;return e end
 assert(booted,tostring(bootError))
 e.Data=modules.PlayerDataService;e.advance(0)
 modules.Icons=modules.make_Icons(e.Instance,e.UDim2,e.UDim,e.Color3,e.Enum)
 local uiModule=modules.make_UI(e.Game,e.Task,e.OS,e.Instance,e.Color3,e.ColorSequence,e.Vector2,e.Vector3,e.CFrame,e.UDim,e.UDim2,e.Enum,e.TweenInfo)
 modules.UI={new=function(...) e.UI=uiModule.new(...);return e.UI end}
 e.TrainingPopups={}
 local noop=function() end
 modules.Audio={new=function() return {refresh=noop,play=noop} end}
 modules.Effects={new=function(gui) assert(gui and gui:IsA("ScreenGui"),"Actual UI did not export Gui");return {refresh=noop,training=function(amount) table.insert(e.TrainingPopups,amount) end,rebirth=noop} end}
 for _,name in ipairs({"Visuals","PetFollowers","IslandEffects","StationEffects","RaceCamera"}) do modules[name]={new=function() return {refresh=noop} end} end
 modules.PlayerModule=e.PlayerModule
 modules.BikeInput=modules.make_BikeInput(e.Game,e.Task,e.UDim2,e.Enum,e.Vector3)
 modules.TrainingInput=modules.make_TrainingInput(e.Game,e.OS,e.Enum,e.Vector2)
 modules.ClientApp=modules.make_ClientApp(e.Game,e.Workspace,e.Task,e.Instance,e.Vector2)
 modules.make_init_client(e.Game,e.Instance,e.UDim2,e.Color3,e.Enum,e.add(nil,"LocalScript","Client"),e.Warn)
 e.advance(.5)
 function e.action(kind,fields)
  if kind=="Training" then
   if e.UI.isMenuOpen() then e.press("×") end
   e.Game:GetService("UserInputService").InputBegan:Fire({UserInputType=e.Enum.UserInputType.MouseButton1},false)
  else e.UI.OnAction(kind,fields) end
  e.advance(.26)
 end
 function e.onBelt(id) local z=e.Workspace.World1.Training:FindFirstChild("Treadmill_"..id).Zone;e.teleport(z.Position.X,z.Position.Y+3,z.Position.Z);e.advance(1.5) end
 function e.press(text)
  for _,node in ipairs(e.UI.Gui:GetDescendants()) do
   if node:IsA("TextButton") and node.Text==text then node.Activated:Fire();e.advance(.3);return end
  end
  error("Actual UI button missing: "..text)
 end
 function e.race()
  e.teleport(0,11,63);e.UI.open("Race");e.press("Rennen starten / erneut starten")
  assert(e.Player:GetAttribute("Racing"));assert(#e.Workspace.ActiveRaceBikes:GetChildren()==5 and #e.Workspace.PlayerBikes:GetChildren()==1)
  e.advance(70);assert(not e.Player:GetAttribute("Racing"));assert(e.UI.LastRaceResult and e.UI.LastRaceResult.Reason=="Finished")
 end
 return e
end
local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
test("real bootstraps publish readiness, create remotes and connect actual UI",function()
 local e=integration(true)
 assert(e.Rep.BikeRuntime:GetAttribute("State")=="Ready")
 assert(e.Data.status(e.Player)=="StudioPreviewReady" and e.StoreCalls==0)
 assert(e.UI and e.UI.Gui and e.UI.Gui.Parent==e.Player.PlayerGui and e.UI.Snapshot.Energy==0)
 assert(e.Rep.BikeRemotes.GetSnapshot.OnServerInvoke)
 assert(string.find(e.Player.PlayerGui.BikeDiagnostics:FindFirstChildOfClass("TextLabel").Text,"Spielerdaten und Remotes bereit",1,true))
 for _,name in ipairs({"Action","ActionResult","SnapshotChanged","Feedback"}) do assert(e.Rep.BikeRemotes:FindFirstChild(name):IsA("RemoteEvent")) end
 e.UI.Buttons.Garage.Activated:Fire();assert(e.UI.Viewport and e.UI.Viewport.Frame.CurrentCamera)
 assert(#e.UI.Viewport.Frame:FindFirstChildOfClass("WorldModel"):GetChildren()==1)
end)
test("step-on and prompt rejection communicate through real services and client",function()
 local e=integration(true);e.onBelt(1)
 assert(e.UI.Snapshot.SelectedTreadmill==1 and e.UI.Snapshot.Energy>=1,"selected="..e.UI.Snapshot.SelectedTreadmill.." energy="..e.UI.Snapshot.Energy)
 local before=e.UI.Snapshot.Energy;e.action("Training");assert(e.UI.Snapshot.Energy>before)
 e.teleport(0,11,0);e.advance(.3)
 assert(not e.Workspace.World1.Training.Treadmill_5.Zone:FindFirstChild("SelectTraining"))
 e.Rep.BikeRemotes.Action:FireServer({Version=1,Action="Select",TreadmillId=5})
 assert(string.find(e.UI.Notice.Text,"Laufband"))
 e.advance(.3);assert(e.UI.Snapshot.SelectedTreadmill==0)
end)
test("complete wired gameplay: train, rebirth, race, buy, equip, hatch, pets and save/rejoin",function()
 local e=integration(true)
 e.onBelt(1)
 for id=2,5 do
  local required=modules.Catalog.Treadmills[id].EnergyRequirement
  while e.Data.snapshot(e.Player).Energy<required do e.advance(1.05) end
  e.onBelt(id)
 end
 while e.Data.snapshot(e.Player).Energy<1000 do e.advance(1.05) end
 e.advance(.3);e.UI.Buttons.Rebirths.Activated:Fire();e.press("Rebirth bestätigen");assert(e.Data.snapshot(e.Player).Rebirths==1 and e.Data.snapshot(e.Player).Energy==0)
 while e.Data.snapshot(e.Player).Cash<350 do e.race() end
 assert(e.Data.snapshot(e.Player).Cash>=350)
 e.UI.VehicleId=2;e.UI.open("Garage");e.press("Kaufen");e.press("Ausrüsten");assert(e.Data.read(e.Player).ActiveVehicle==2)
 e.race();assert(e.UI.LastRaceResult.Reward>0)
 e.UI.EggId=1;e.UI.open("Egg");e.press("Ei öffnen");local profile=e.Data.read(e.Player);local petId=next(profile.Pets);assert(petId)
 assert(e.Data.read(e.Player).EquippedPets[1]==petId);e.UI.PetId=petId;e.UI.open("Pet");e.press("Ablegen");e.press("Ausrüsten");assert(e.UI.Snapshot.PetEnergyBonus>1 and e.UI.Snapshot.PetCashBonus>1)
 e.onBelt(1);local before=e.Data.snapshot(e.Player).Energy;e.action("Training");assert(e.Data.snapshot(e.Player).Energy-before>1.5)
 local saved=e.Data.read(e.Player);e.Player.Parent=nil;e.Players.PlayerRemoving:Fire(e.Player);e.advance(1)
 e.Player.Parent=e.Players;e.Players.PlayerAdded:Fire(e.Player);e.advance(.1)
 local loaded=e.Data.read(e.Player)
 assert(loaded and loaded.Cash==saved.Cash and loaded.Energy==saved.Energy and loaded.Rebirths==saved.Rebirths and loaded.ActiveVehicle==2 and loaded.Pets[petId] and loaded.EquippedPets[1]==petId)
end)
test("missing actual world dependency fails visibly before gameplay initialization",function()
 local e=integration(true,true)
 assert(e.Rep.BikeRuntime:GetAttribute("State")=="Failed")
 assert(e.Rep.BikeRuntime:GetAttribute("Stage")=="WorldContract")
 assert(string.find(e.Rep.BikeRuntime:GetAttribute("Error"),"Treadmill_1/Zone",1,true))
 assert(not e.Rep:FindFirstChild("BikeRemotes") and #e.Warnings>0)
end)
test("Studio preview retains locks and validation while never opening a live store",function()
 local e=integration(true)
 e.Rep.BikeRemotes.Action:FireServer({Version=1,Action="Hatch",EggId=1,RequestId=1,Cash=999999})
 assert(e.Data.snapshot(e.Player).Cash==0 and next(e.Data.read(e.Player).Pets)==nil and e.StoreCalls==0)
end)
test("live servers ignore Studio preview attributes and retain persistent store selection",function()
 local e=integration(true,false,true)
 assert(e.StoreCalls==1 and e.StoreName==modules.Config.Data.Store)
 assert(e.Rep.BikeRuntime:GetAttribute("DataMode")=="PERSISTENT" and e.Data.status(e.Player)=="Ready")
end)
test("persistent Studio testing always uses isolated test-store namespace",function()
 local e=integration(false)
 assert(e.StoreCalls==1 and e.StoreName=="BikeEvolution_StudioTest_v2")
 assert(e.Rep.BikeRuntime:GetAttribute("DataMode")=="ISOLIERTER STUDIO-TESTSTORE")
end)
test("actual Garage UI renders all ten model previews with framed cameras",function()
 local e=integration(true)
 for id=1,10 do
  e.UI.VehicleId=id;e.UI.open("Garage")
  local view=e.UI.Viewport
  assert(view.Frame.CurrentCamera and view.Distance>=3 and view.TargetY==0)
  local model=view.Frame:FindFirstChildOfClass("WorldModel"):GetChildren()[1]
  assert(model and model:FindFirstChild("FrontWheel") and model:FindFirstChild("RearWheel"))
 end
end)
test("explicit Stop remains effective until leaving and re-entering the belt",function()
 local e=integration(true);e.onBelt(1);e.action("Stop")
 local before=e.Data.snapshot(e.Player).Energy;e.advance(3)
 assert(e.Data.snapshot(e.Player).Energy==before and e.UI.Snapshot.SelectedTreadmill==0)
 e.teleport(0,11,0);e.advance(.4);e.onBelt(1)
 assert(e.UI.Snapshot.SelectedTreadmill==1 and e.Data.snapshot(e.Player).Energy>before)
end)
test("V2 HUD binds confirmed resources without sidebar duplicates or background tiles",function()
 local e=integration(true)
 local hud=e.UI.ResourceHUD
 assert(hud.BackgroundTransparency==1 and hud.BorderSizePixel==0 and hud.AnchorPoint.X==1 and hud.AnchorPoint.Y==1)
 assert(hud.Position[1]==1 and hud.Position[3]==1)
 assert(#hud:GetChildren()==3)
 for _,name in ipairs({"Energy","Cash","Rebirths"}) do
  local row=hud:FindFirstChild(name.."Status")
  assert(row.BackgroundTransparency==1 and row.BorderSizePixel==0 and e.UI.ResourceValues[name].Text=="0")
  assert(row:FindFirstChild(name.."Icon") and row.Value.BackgroundTransparency==1)
 end
 for _,child in ipairs(hud:GetDescendants()) do assert(not child:IsA("UIStroke"),"HUD must have no visible frames") end
 assert(hud.CashStatus.CashIcon:FindFirstChild("Coin"))
 assert(hud.EnergyStatus.EnergyIcon.Symbol.Text=="ϟ" and hud.RebirthsStatus.RebirthsIcon.Symbol.Text=="↻")
 assert(e.Data.change(e.Player,function(profile) profile.Energy=1.5e12;profile.Cash=2.5e9;profile.Rebirths=1234;return true end))
 assert(e.UI.ResourceValues.Energy.Text=="0","No optimistic resource values")
 e.advance(.3)
 assert(e.UI.ResourceValues.Energy.Text=="1.5T" and e.UI.ResourceValues.Cash.Text=="2.5B" and e.UI.ResourceValues.Rebirths.Text=="1.2K")
 for _,collapsed in ipairs({true,false,true}) do
  e.UI.collapse(collapsed)
  assert(not e.UI.Buttons.Energy and not e.UI.Buttons.Cash)
  for _,name in ipairs({"Garage","Pets","Race","Worlds","Rebirths","Shop","Settings"}) do
   local label=e.UI.Buttons[name]:FindFirstChildOfClass("TextLabel")
   assert(label.Text==name and label.Visible==not collapsed)
  end
 end
end)
test("V2 compact HUD uses safe insets and reserves touch jump space in both orientations",function()
 local e=integration(true);local root=e.UI.ResourceHUD.Parent
 assert(e.UI.Gui.ScreenInsets==e.Enum.ScreenInsets.CoreUISafeInsets)
 e.Game:GetService("UserInputService").TouchEnabled=true
 root.AbsoluteSize=e.Vector2.new(375,680);root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
 assert(e.UI.ResourceHUD.Size[1]==154 and e.UI.ResourceHUD.Size[2]==90)
 assert(e.UI.ResourceHUD.Position[2]==-8 and e.UI.ResourceHUD.Position[4]==-130)
 assert(e.UI.ResourceValues.Energy.TextSize==22)
 root.AbsoluteSize=e.Vector2.new(820,330);root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
 assert(e.UI.ResourceHUD.Position[2]==-138 and e.UI.ResourceHUD.Position[4]==-8)
 local copies=0;for _,node in ipairs(e.UI.Gui:GetDescendants()) do if node.Name=="ResourceHUD" then copies+=1 end end;assert(copies==1)
end)
test("V2 sidebar keeps full Rebirth preview, cancel and authoritative confirmation without a stand",function()
 local e=integration(true)
 assert(not e.Workspace.World1:FindFirstChild("RebirthStation"))
 e.UI.Buttons.Rebirths.Activated:Fire()
 assert(e.UI.CurrentMenu=="Rebirths" and not e.UI.RebirthConfirm.Active)
 e.press("Noch nicht genug Energy");assert(e.Data.snapshot(e.Player).Rebirths==0)
 assert(e.Data.change(e.Player,function(profile) profile.Energy=1000;profile.Cash=123;return true end));e.advance(.3)
 assert(e.UI.RebirthConfirm.Active)
 assert(string.find(e.UI.RebirthInfo.Text,"×1 → ×1.5",1,true) and string.find(e.UI.RebirthInfo.Text,"1000",1,true)==nil)
 -- The normal formatter abbreviates the 1000-Energy requirement to 1K.
 assert(string.find(e.UI.RebirthInfo.Text,"1K Energy",1,true))
 e.press("Abbrechen");assert(e.Data.snapshot(e.Player).Energy==1000 and e.Data.snapshot(e.Player).Rebirths==0)
 e.UI.Buttons.Rebirths.Activated:Fire();e.press("Rebirth bestätigen")
 local profile=e.Data.snapshot(e.Player)
 assert(profile.Energy==0 and profile.Rebirths==1 and profile.Cash==123)
 assert(e.UI.ResourceValues.Energy.Text=="0" and e.UI.ResourceValues.Rebirths.Text=="1" and e.UI.ResourceValues.Cash.Text=="123")
end)
test("V3 actual Equip Best button updates confirmed bonuses immediately and Unequip All survives rejoin",function()
 local e=integration(true)
 assert(e.Data.change(e.Player,function(profile)
  profile.Pets={a={SpeciesId=1,Variant="Normal"},b={SpeciesId=4,Variant="Golden"},c={SpeciesId=12,Variant="Rainbow"},d={SpeciesId=10,Variant="Normal"}}
  profile.DiscoveredPets={1,4,10,12};profile.EquippedPets={"a"};return true
 end,true));e.advance(.3)
 e.UI.Buttons.Pets.Activated:Fire()
 local button
 for _,node in ipairs(e.UI.Gui:GetDescendants()) do if node:IsA("TextButton") and node.Text=="⚡ EQUIP BEST" then button=node;break end end
 assert(button);button.Activated:Fire() -- No scheduler advance: server confirmation sends the new inventory now.
 assert(table.concat(e.Data.read(e.Player).EquippedPets,",")=="c,b,d")
 assert(#e.UI.Snapshot.EquippedPets==3 and math.abs(e.UI.Snapshot.PetEnergyBonus-9.25)<1e-9 and math.abs(e.UI.Snapshot.PetCashBonus-6.9)<1e-9)
 assert(e.UI.Snapshot.Pets.a and e.UI.Snapshot.Pets.b and e.UI.Snapshot.Pets.c and e.UI.Snapshot.Pets.d)
 e.press("UNEQUIP ALL");e.advance(2)
 assert(#e.Data.read(e.Player).EquippedPets==0 and e.UI.Snapshot.PetEnergyBonus==1 and e.UI.Snapshot.PetCashBonus==1)
 e.Player.Parent=nil;e.Players.PlayerRemoving:Fire(e.Player);e.advance(1)
 e.Player.Parent=e.Players;e.Players.PlayerAdded:Fire(e.Player);e.advance(.1)
 local loaded=e.Data.read(e.Player);assert(loaded and #loaded.EquippedPets==0 and loaded.Pets.c.Variant=="Rainbow")
end)
test("V3 actual hatch buttons auto-fill only new pets and never replace full or manually emptied slots",function()
 local e=integration(true)
 assert(e.Data.change(e.Player,function(profile) profile.Cash=10000;return true end));e.advance(.3)
 local first={}
 for i=1,4 do
  e.UI.EggId=1;e.UI.open("Egg");e.press("Ei öffnen");e.advance(1)
  assert(#e.UI.Snapshot.EquippedPets==math.min(i,3))
  local pets=0;for _ in pairs(e.Data.read(e.Player).Pets) do pets+=1 end;assert(pets==i)
  if i==3 then first=table.clone(e.UI.Snapshot.EquippedPets) end
 end
 assert(table.concat(first,",")==table.concat(e.UI.Snapshot.EquippedPets,","))
 assert(math.abs(e.UI.Snapshot.PetEnergyBonus-1.3)<1e-9 and math.abs(e.UI.Snapshot.PetCashBonus-1.15)<1e-9)
 e.UI.Buttons.Pets.Activated:Fire();e.press("UNEQUIP ALL");e.advance(2)
 assert(#e.UI.Snapshot.EquippedPets==0)
 e.UI.EggId=1;e.UI.open("Egg");e.press("Ei öffnen")
 assert(#e.UI.Snapshot.EquippedPets==1 and not table.find(first,e.UI.Snapshot.EquippedPets[1]))
end)
test("overhaul removes header, resource menu tiles and scrolling navigation from actual UI",function()
 local e=integration(true)
 assert(e.UI.Sidebar.BackgroundTransparency==1 and e.UI.Sidebar.BorderSizePixel==0)
 assert(e.UI.Navigation:IsA("Frame") and not e.UI.Buttons.Energy and not e.UI.Buttons.Cash)
 local names={"Garage","Pets","Race","Worlds","Rebirths","Shop","Settings"}
 assert(#e.UI.Navigation:GetChildren()==#names)
 for _,node in ipairs(e.UI.Sidebar:GetDescendants()) do
  assert(not node:IsA("ScrollingFrame"))
  if node:IsA("TextLabel") or node:IsA("TextButton") then assert(not string.find(node.Text or "","PALM BAY",1,true)) end
 end
 for _,name in ipairs(names) do assert(e.UI.Buttons[name] and e.UI.Buttons[name].Visible) end
 assert(e.UI.Status==nil and e.UI.TrainingInfo==nil and e.UI.Notice.BackgroundTransparency==1 and not e.UI.Notice.Visible)
 local root=e.UI.Sidebar.Parent
 for _,size in ipairs({{375,680},{820,300},{1024,700}}) do
  root.AbsoluteSize=e.Vector2.new(size[1],size[2]);root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
  for _,name in ipairs(names) do assert(e.UI.Buttons[name].Parent==e.UI.Navigation) end
 end
 e.UI.Buttons.Rebirths.Activated:Fire();assert(e.UI.CurrentMenu=="Rebirths" and e.UI.RebirthInfo)
end)
test("screen taps use one touch source, block UI, deduplicate synthetic mouse and confirm actual multipliers",function()
 local e=integration(true);local input=e.Game:GetService("UserInputService")
 assert(e.Data.change(e.Player,function(profile)
  profile.Rebirths=1;profile.DiscoveredPets={1};profile.Pets.pet={SpeciesId=1,Variant="Normal"};profile.EquippedPets={"pet"};return true
 end,true));e.onBelt(1)
 local before=e.Data.snapshot(e.Player).Energy;local count=#e.TrainingPopups
 input.TouchTap:Fire({e.Vector2.new(300,200)},false)
 local after=e.Data.snapshot(e.Player).Energy
 assert(math.abs(after-before-1.65)<1e-9 and #e.TrainingPopups==count+1 and math.abs(e.TrainingPopups[#e.TrainingPopups]-1.65)<1e-9)
 input.InputBegan:Fire({UserInputType=e.Enum.UserInputType.Touch},false)
 input.InputBegan:Fire({UserInputType=e.Enum.UserInputType.MouseButton1},false)
 input.TouchTap:Fire({e.Vector2.new(300,200)},false)
 assert(e.Data.snapshot(e.Player).Energy==after)
 e.advance(.4);before=e.Data.snapshot(e.Player).Energy
 input.InputBegan:Fire({UserInputType=e.Enum.UserInputType.MouseButton1},true)
 assert(e.Data.snapshot(e.Player).Energy==before)
 e.Player.PlayerGui.GetGuiObjectsAtPosition=function() return {e.UI.Buttons.Pets} end
 input.TouchTap:Fire({e.Vector2.new(300,200)},false)
 assert(e.Data.snapshot(e.Player).Energy==before)
 e.Player.PlayerGui.GetGuiObjectsAtPosition=function() return {} end
 e.UI.Buttons.Pets.Activated:Fire();input.TouchTap:Fire({e.Vector2.new(300,200)},false)
 assert(e.Data.snapshot(e.Player).Energy==before)
end)
test("locked belt and rebirth access loss stop both automatic and tapped training without prompts",function()
 local e=integration(true);local input=e.Game:GetService("UserInputService")
 e.onBelt(5);assert(e.Data.snapshot(e.Player).Energy==0 and e.UI.Snapshot.SelectedTreadmill==0)
 input.TouchTap:Fire({e.Vector2.new(300,200)},false);assert(e.Data.snapshot(e.Player).Energy==0)
 assert(e.Data.change(e.Player,function(profile) profile.Energy=1000;return true end));e.advance(1.5)
 assert(e.UI.Snapshot.SelectedTreadmill==5)
 e.UI.Buttons.Rebirths.Activated:Fire();e.press("Rebirth bestätigen");e.advance(1.1)
 assert(e.Data.snapshot(e.Player).Energy==0 and e.UI.Snapshot.SelectedTreadmill==0)
 for _,node in ipairs(e.Workspace.World1.Training:GetDescendants()) do assert(not node:IsA("ProximityPrompt")) end
 input.TouchTap:Fire({e.Vector2.new(300,200)},false);assert(e.Data.snapshot(e.Player).Energy==0)
end)
test("V4 station effects never create training BillboardGui on enter, leave or re-enter",function()
 local e=integration(true)
 local stations=modules.make_StationEffects(e.Game,e.Workspace,e.Task,e.OS,e.Instance,e.Vector3,e.UDim2,e.Color3,e.ColorSequence,e.Enum)
 stations.new({Animations=false},e.UI)
 local function absent()
  for _,node in ipairs(e.UI.Gui:GetDescendants()) do assert(not node:IsA("BillboardGui")) end
  assert(e.Player:GetAttribute("TrainingGain")==nil)
 end
 absent();e.onBelt(1);absent()
 e.teleport(0,11,0);e.advance(1);absent()
 e.onBelt(1);absent();e.Player.CharacterRemoving:Fire();e.advance(.5);absent()
end)
test("recreating actual HUD destroys old Palm Bay GUI instead of leaving duplicate overlays",function()
 local e=integration(true);local previous=e.UI.Gui
 local legacy=e.add(e.Player.PlayerGui,"ScreenGui","PalmBaySidebar")
 e.add(legacy,"TextLabel","OldEnergy")
 local new=modules.UI.new(e.Player.PlayerGui,e.UI.Settings,{play=function() end})
 assert(previous.Parent==nil and legacy.Parent==nil and e.Player.PlayerGui:FindFirstChild("PalmBaySidebar")==nil)
 assert(new.Gui.Name=="BikeHUDV4")
 local count=0;for _,node in ipairs(e.Player.PlayerGui:GetChildren()) do if node.Name=="BikeHUDV4" then count+=1 end end;assert(count==1)
end)
test("V4 Shop and portal prompts open actual themed menus with working navigation",function()
 local e=integration(true);local before=e.Data.snapshot(e.Player).Cash
 e.UI.Buttons.Shop.Activated:Fire();assert(e.UI.CurrentMenu=="Shop")
 e.press("Fahrzeuge kaufen");assert(e.UI.CurrentMenu=="Garage" and e.UI.Viewport)
 e.UI.Buttons.Shop.Activated:Fire();e.press("Eier kaufen / öffnen");assert(e.UI.CurrentMenu=="Eggs")
 e.teleport(32,11,24)
 e.Workspace.World1.ShopArea.Platform:FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(e.Player)
 assert(e.UI.CurrentMenu=="Shop")
 e.advance(.3);e.teleport(-45,11,57)
 e.Workspace.World1.WorldPreview.Platform:FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(e.Player)
 assert(e.UI.CurrentMenu=="Worlds");e.press("Rennen in Palm Bay");assert(e.UI.CurrentMenu=="Race")
 assert(e.Data.snapshot(e.Player).Cash==before)
end)
test("V4 seven sidebar menus stay on screen and Settings actions remain connected",function()
 local e=integration(true);local root=e.UI.Sidebar.Parent
 local names={"Garage","Pets","Race","Worlds","Rebirths","Shop","Settings"}
 for _,size in ipairs({{304,600},{375,680},{820,284},{1024,700},{1904,1000}}) do
  root.AbsoluteSize=e.Vector2.new(size[1],size[2]);root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
  local scale=e.UI.Sidebar:FindFirstChildOfClass("UIScale").Scale
  for _,name in ipairs(names) do
   local button=e.UI.Buttons[name]
   assert((button.Position[1]+button.Size[1])*scale<=size[1])
   assert((32+button.Position[2]+button.Size[2])*scale<=size[2])
   button.Activated:Fire();assert(e.UI.CurrentMenu==name)
   assert(button:FindFirstChildOfClass("UIGradient") and button:FindFirstChildOfClass("UICorner"))
  end
 end
 e.UI.Buttons.Settings.Activated:Fire()
 local animations=e.UI.Settings.Animations
 e.press("Animationen: "..(if animations then "AN" else "AUS"))
 assert(e.UI.Settings.Animations~=animations)
 local volume=e.UI.Settings.Volume;e.press("− Leiser");assert(e.UI.Settings.Volume<volume)
 e.press("+ Lauter");assert(math.abs(e.UI.Settings.Volume-volume)<1e-9)
end)
test("V4.1 spawn has one server-mounted equipped bike and no normal walking",function()
 local e=integration(true);local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 local hum=e.Player.Character:FindFirstChildOfClass("Humanoid")
 assert(#e.Workspace.PlayerBikes:GetChildren()==1 and bike:GetAttribute("VehicleId")==1)
 assert(e.Player:GetAttribute("Mounted")==true and not e.Root.Anchored and hum.Sit and hum.PlatformStand and hum.WalkSpeed==0)
 local weld=bike.Frame.Pivot:FindFirstChild("PermanentRiderMount")
 assert(weld and weld.Part0==bike.Frame.Pivot and weld.Part1==e.Root and bike.PrimaryPart.Anchored)
 assert(not e.Workspace:FindFirstChild("LocalTrainingCycles"))
end)
test("V4.1 owned vehicle changes replace only the model and restore the selected moped on respawn",function()
 local e=integration(true);local first=e.Workspace.PlayerBikes:GetChildren()[1]
 assert(e.Data.change(e.Player,function(p) p.OwnedVehicles={1,7};p.ActiveVehicle=7;return true end,true));e.advance(.2)
 local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 assert(first.Parent==nil and bike:GetAttribute("VehicleId")==7 and bike:GetAttribute("Pedaling")==false and not e.Root.Anchored)
 e.Player.CharacterRemoving:Fire();local previous=e.Player.Character;previous:Destroy()
 local char=e.add(e.Workspace,"Model","Respawn");e.Root=e.add(char,"Part","HumanoidRootPart",0,11,0)
 local hum=e.add(char,"Humanoid","Humanoid");hum.Health=100
 e.Player.Character=char;e.Player.CharacterAdded:Fire(char);e.advance(.2)
 local restored=e.Workspace.PlayerBikes:GetChildren()[1]
 assert(#e.Workspace.PlayerBikes:GetChildren()==1 and restored:GetAttribute("VehicleId")==7 and hum.Sit and not e.Root.Anchored)
 assert(e.Data.read(e.Player).ActiveVehicle==7)
end)
test("V4.1 native keyboard/touch vectors drive, steer, brake and pause in menus",function()
 local e=integration(true);local start=e.Root.Position
 e.Move=e.Vector3.new(0,0,-1);e.advance(.6)
 assert(e.Root.Position.Z<start.Z-1)
 e.Move=e.Vector3.new(1,0,-1);e.advance(.4);assert(e.Root.Position.X>start.X)
 e.BrakeCallback("BikeBrake",e.Enum.UserInputState.Begin);e.advance(.6)
 local stopped=e.Root.Position;e.advance(.3);assert((e.Root.Position-stopped).Magnitude<1e-6)
 e.BrakeCallback("BikeBrake",e.Enum.UserInputState.End)
 e.UI.Buttons.Pets.Activated:Fire();e.advance(.7)
 stopped=e.Root.Position;e.advance(.3);assert((e.Root.Position-stopped).Magnitude<1e-6)
 assert(e.Player.Character:FindFirstChildOfClass("Humanoid").Sit)
end)
test("V4.1 manual collisions, missing ground and excessive steps stop the bike",function()
 local e=integration(true);e.Move=e.Vector3.new(0,0,-1)
 local start=e.Root.Position
 e.Collision=true;e.advance(.5);assert((e.Root.Position-start).Magnitude<1e-6)
 e.Collision=false;e.NoGround=true;e.advance(.5);assert((e.Root.Position-start).Magnitude<1e-6)
 e.NoGround=false;e.GroundY=25;e.advance(.5);assert((e.Root.Position-start).Magnitude<1e-6)
 e.GroundY=8;e.advance(.5);assert(e.Root.Position.Z<start.Z)
end)
test("V4.1 stale or replayed steering cannot keep a bike moving or modify economics",function()
 local e=integration(true);local remote=e.Rep.BikeRemotes.Drive
 local before=e.Data.snapshot(e.Player)
 remote:FireServer({Version=1,Sequence=10000,Throttle=1,Steer=0,Brake=false})
 e.advance(.25);local moved=e.Root.Position
 assert(moved.Z<0)
 remote:FireServer({Version=1,Sequence=10000,Throttle=1,Steer=0,Brake=false})
 remote:FireServer({Version=1,Sequence=10001,Throttle=0/0,Steer=0,Brake=false})
 e.advance(1);local stop=e.Root.Position;e.advance(.5);assert((e.Root.Position-stop).Magnitude<1e-6)
 local after=e.Data.snapshot(e.Player);assert(after.Energy==before.Energy and after.Cash==before.Cash and after.Rebirths==before.Rebirths)
end)
test("V4.1 garage semicircle opens once per entry without E prompt and sidebar remains usable",function()
 local e=integration(true)
 for _,node in ipairs(e.Workspace.World1.GaragePreview:GetDescendants()) do assert(not node:IsA("ProximityPrompt")) end
 e.teleport(-35,12.85,8);e.advance(.3);assert(e.UI.CurrentMenu=="Garage" and e.UI.isMenuOpen())
 e.press("×");e.advance(1);assert(not e.UI.isMenuOpen())
 e.teleport(0,12.85,0);e.advance(.3)
 e.teleport(-35,12.85,8);e.advance(.3);assert(e.UI.isMenuOpen())
 e.press("×");e.UI.Buttons.Garage.Activated:Fire();assert(e.UI.isMenuOpen() and e.UI.Viewport)
end)
test("V4.1 training, taps and leaving the belt retain the exact permanent bike",function()
 local e=integration(true);local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 e.onBelt(1);assert(e.UI.Snapshot.SelectedTreadmill==1 and e.UI.Snapshot.Energy>0)
 local before=e.Data.snapshot(e.Player).Energy
 e.Game:GetService("UserInputService").TouchTap:Fire({e.Vector2.new(300,200)},false)
 assert(e.Data.snapshot(e.Player).Energy>before and e.Workspace.PlayerBikes:GetChildren()[1]==bike)
 e.teleport(0,12.85,0);e.advance(.5)
 assert(e.UI.Snapshot.SelectedTreadmill==0 and e.Workspace.PlayerBikes:GetChildren()[1]==bike and e.Player:GetAttribute("Mounted"))
end)
test("V4.1 race handoff reuses the exact mounted model and restores manual island driving",function()
 local e=integration(true);local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 e.race()
 assert(e.Workspace.PlayerBikes:GetChildren()[1]==bike and #e.Workspace.ActiveRaceBikes:GetChildren()==0)
 assert(e.Player:GetAttribute("Mounted") and e.Player.Character:FindFirstChildOfClass("Humanoid").Sit)
 e.press("×");local position=e.Root.Position;e.Move=e.Vector3.new(0,0,-1);e.advance(.6)
 assert(e.Root.Position.Z<position.Z and e.Workspace.PlayerBikes:GetChildren()[1]==bike)
end)
test("V4.1 hatch, pet equipment and menu changes never remove the mounted bike",function()
 local e=integration(true);local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 assert(e.Data.change(e.Player,function(p) p.Cash=1000;return true end))
 e.action("Hatch",{EggId=1});assert(#e.Data.read(e.Player).EquippedPets==1)
 e.action("EquipBest");e.UI.Buttons.Settings.Activated:Fire();e.press("Animationen: AN")
 assert(e.Workspace.PlayerBikes:GetChildren()[1]==bike and not e.Root.Anchored and e.Player.Character:FindFirstChildOfClass("Humanoid").Sit)
end)
test("V4.1 failed movement queries are visible, throttled and recover without unmounting",function()
 local e=integration(true);local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 e.Move=e.Vector3.new(0,0,-1)
 local original=e.Workspace.Blockcast
 e.Workspace.Blockcast=function() error("Injected collision service failure") end
 e.advance(.4)
 assert(e.Rep.BikeRuntime:GetAttribute("BikeState")=="Failed")
 local label=e.Player.PlayerGui.BikeDiagnostics:FindFirstChildOfClass("TextLabel")
 assert(string.find(label.Text,"Injected collision service failure",1,true))
 local logs=0;for _,entry in ipairs(e.Warnings) do if entry[1]=="[PermanentBike]" then logs+=1 end end
 assert(logs==1 and e.Workspace.PlayerBikes:GetChildren()[1]==bike)
 e.Workspace.Blockcast=original;e.advance(.3)
 assert(e.Rep.BikeRuntime:GetAttribute("BikeState")=="Ready" and e.Rep.BikeRuntime:GetAttribute("BikeError")==nil)
end)
test("V4.1 disconnect clears the rider and all race bots without a reward",function()
 local e=integration(false);local cash=e.Data.snapshot(e.Player).Cash
 e.teleport(0,12.85,63);e.action("StartRace",{Difficulty="Easy"})
 assert(e.Player:GetAttribute("Racing") and #e.Workspace.ActiveRaceBikes:GetChildren()==5)
 e.Players.PlayerRemoving:Fire(e.Player);e.Player.Parent=nil;e.advance(.5)
 assert(#e.Workspace.PlayerBikes:GetChildren()==0 and #e.Workspace.ActiveRaceBikes:GetChildren()==0)
 assert(not e.Player:GetAttribute("Racing"))
 local saved=e.Store:UpdateAsync("Player_123",function(old) return old end)
 assert(saved.Data.Cash==cash and saved.Data.LastRaceReward=="")
end)
local function closeFrame(a,b)
 assert((a.Position-b.Position).Magnitude<1e-7,"position mismatch")
 assert((a.LookVector-b.LookVector).Magnitude<1e-7,"orientation mismatch")
 local p=modules.rigidMath();local up=p.new(0,1,0)
 assert(((a*up-a.Position)-(b*up-b.Position)).Magnitude<1e-7,"up-axis mismatch")
end
test("V4.2 one anchored bike root transports the rider through full yaw pitch and roll",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player)
 local before=e.CFrameWrites[e.Root] or 0
 for _,yaw in ipairs({0,.5,math.pi/2,math.pi,4.7,math.pi*2}) do
  local cf=e.CFrame.new(25,8,13)*e.CFrame.Angles(.12,yaw,-.15)
  e.Mounts.move(r,cf,12,r.Distance+1)
  closeFrame(r.Rig.Root.CFrame,cf)
  closeFrame(e.Root.CFrame,r.Rig.Frame.CFrame*r.Weld.C0)
  assert(r.Rig.Root.Anchored and not e.Root.Anchored and r.Weld:IsA("Weld"))
 end
 assert((e.CFrameWrites[e.Root] or 0)==before,"Passenger root must never be a movement writer")
end)
test("V4.2 nonzero PrimaryPart pivots cannot change the requested vehicle origin",function()
 local e=integration(true)
 local bike=e.Rep.Vehicles.Mountainbike:Clone()
 local rig=modules.BikeRig.prepare(bike)
 rig.Root.PivotOffset=e.CFrame.new(3,2,-8)*e.CFrame.Angles(.3,.8,-.2)
 local expectedSeat=rig.Root.CFrame:ToObjectSpace(bike.Frame.Saddle.CFrame)
 local target=e.CFrame.new(50,9,60)*e.CFrame.Angles(.2,1.4,.1)
 modules.RiderMount.place(rig,target)
 closeFrame(rig.Root.CFrame,target)
 closeFrame(rig.Root.CFrame:ToObjectSpace(bike.Frame.Saddle.CFrame),expectedSeat)
end)
test("V4.2 PlayerModule movement dispatcher is suppressed while native touch vectors stay live",function()
 local e=integration(true);local controls=e.Controls
 controls.moveFunction(e.Player,e.Vector3.new(0,0,-1),true)
 assert(not e.DefaultMoves)
 assert(not e.Player.Character:FindFirstChildOfClass("Humanoid"):GetStateEnabled(e.Enum.HumanoidStateType.Jumping))
 e.Game:GetService("UserInputService").TouchEnabled=true
 e.Move=e.Vector3.new(.5,0,-1);local start=e.Root.Position;e.advance(.5)
 assert((e.Root.Position-start).Magnitude>1)
 assert(controls:GetMoveVector().Z==-1 and e.Player.Character:FindFirstChildOfClass("Humanoid").MoveDirection.Magnitude==0)
 local restore=controls.moveFunction;e.UI.Gui:Destroy();e.advance(.2)
 assert(controls.moveFunction~=restore)
 controls.moveFunction();assert(e.DefaultMoves==1)
end)
test("V4.2 visual wheel steering and lean cannot rotate the vehicle origin or detach the rider",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player)
 modules.AvatarPose=modules.make_AvatarPose(e.Instance,e.CFrame,e.Vector3,e.Enum)
 local visual=modules.make_Visuals(e.Game,e.Workspace,e.Task,e.OS,e.CFrame,e.Vector3)
 visual.new(e.UI.Settings,e.UI);e.advance(.01)
 local step=e.Game:GetService("RunService").PreSimulation
 for _,yaw in ipairs({0,.4,.9,1.6}) do
  local cf=e.CFrame.new(25,8,0)*e.CFrame.Angles(0,yaw,0)
  e.Mounts.move(r,cf,10,r.Distance+2);step:Fire(.016)
  closeFrame(r.Rig.Root.CFrame,cf)
  closeFrame(e.Root.CFrame,r.Rig.Frame.CFrame*r.Weld.C0)
 end
end)
test("V4.2 R15 pelvis dimensions and bind offsets determine saddle contact after resizing",function()
 local e=integration(true);local char=e.Player.Character
 local pelvis=e.add(char,"Part","LowerTorso");pelvis.Size=e.Vector3.new(1.5,2.4,1)
 local bind=e.add(e.Root,"Motor6D","RootJoint");bind.Part0=e.Root;bind.Part1=pelvis;bind.C0=e.CFrame.new(.15,-.25,-.2)
 char.DescendantAdded:Fire(pelvis);char.DescendantAdded:Fire(bind);e.advance(.1)
 local r=e.Mounts.ensure(e.Player);local base=r.Rig.Root.CFrame
 local seatTop=r.Bike.Frame.Saddle.Position.Y+r.Bike.Frame.Saddle.Size.Y/2
 assert(math.abs(pelvis.Position.Y-pelvis.Size.Y/2-seatTop)<1e-7)
 assert(math.abs(pelvis.Position.X-r.Bike.Frame.Saddle.Position.X)<1e-7 and math.abs(pelvis.Position.Z-r.Bike.Frame.Saddle.Position.Z)<1e-7)
 local oldHeight=r.Offset.Position.Y
 pelvis.Size=e.Vector3.new(1.5,2.8,1);pelvis:GetPropertyChangedSignal("Size"):Fire();e.advance(.1)
 assert(math.abs(r.Offset.Position.Y-oldHeight-.2)<1e-7)
 closeFrame(r.Rig.Root.CFrame,base)
 assert(math.abs(pelvis.Position.Y-pelvis.Size.Y/2-seatTop)<1e-7)
 assert(math.abs(pelvis.Position.X-r.Bike.Frame.Saddle.Position.X)<1e-7 and math.abs(pelvis.Position.Z-r.Bike.Frame.Saddle.Position.Z)<1e-7)
end)
test("V4.2 stationary steering preserves the vehicle and seat positions",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player);local start=r.Rig.Root.CFrame
 e.Move=e.Vector3.new(1,0,0);e.advance(.8)
 closeFrame(r.Rig.Root.CFrame,start);closeFrame(e.Root.CFrame,r.Rig.Frame.CFrame*r.Weld.C0)
end)
test("V4.2 actual camera follows the current mounted humanoid and switches back after races",function()
 local e=integration(true);local camera=modules.make_RaceCamera(e.Game,e.Workspace,e.CFrame,e.Vector3,e.Enum)
 camera.new(e.UI.Settings,e.UI)
 local cam=e.Workspace.CurrentCamera
 assert(cam.CameraSubject==e.Player.Character:FindFirstChildOfClass("Humanoid") and cam.CameraType==e.Enum.CameraType.Custom)
 local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 e.teleport(0,12,63);e.action("StartRace",{Difficulty="Easy"})
 e.Game:GetService("RunService").RenderStepped:Fire(.016)
 assert(cam.CameraType==e.Enum.CameraType.Scriptable)
 e.action("AbortRace");assert(cam.CameraType==e.Enum.CameraType.Custom)
 assert(cam.CameraSubject==e.Player.Character:FindFirstChildOfClass("Humanoid") and e.Workspace.PlayerBikes:GetChildren()[1]==bike)
end)
print(string.format("%d actual runtime wiring tests passed (engine doubles; NOT Roblox Studio)",count))
