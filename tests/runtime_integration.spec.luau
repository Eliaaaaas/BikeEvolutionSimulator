local function integration(preview,remove,live,predict)
 local e=modules.runtimeEngine();modules.populateWorld(e.add,e.Workspace,e.Rep)
 if remove then e.Workspace.World1.Training.Treadmill_1.Zone:Destroy() end
 e.Workspace:SetAttribute("StudioPreviewData",preview)
 e.Studio=not live
 local serverScript=e.add(nil,"Script","Server")
 modules.BikeRig=modules.makeBikeRig(e.Instance)
 modules.RaceService=modules.makeRaceService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum)
 modules.PlayerDataService=modules.makeService(e.Game,e.Task,e.OS,e.Warn)
 modules.RiderMount=modules.make_RiderMount(e.CFrame)
 modules.BikeSurface=modules.make_BikeSurface(e.CFrame,e.Vector3,e.RaycastParams,e.Enum,e.OverlapParams)
 local mountedModule=modules.make_MountedBikeService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum,e.RaycastParams)
 modules.MountedBikeService={new=function(data) e.Mounts=mountedModule.new(data);return e.Mounts end}
 function e.teleport(x,y,z)
  local record=e.Mounts.ensure(e.Player)
  e.Mounts.teleport(e.Player,e.CFrame.new(x,y,z)*record.Offset:Inverse())
 end
 modules.PremiumService=modules.make_PremiumService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Enum)
 modules.AutomationService=modules.make_AutomationService(e.Game,e.OS,e.Workspace)
 modules.GameplayService=modules.make_GameplayService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.Random)
 modules.RemoteService=modules.make_RemoteService(e.Game,e.Task,e.OS,e.Instance)
 local booted,bootError=pcall(modules.make_init_server,e.Game,e.Workspace,e.Instance,serverScript,e.Warn)
 if remove then assert(not booted);e.BootError=bootError;return e end
 assert(booted,tostring(bootError))
 e.Data=modules.PlayerDataService;e.advance(0)
 modules.Icons=modules.make_Icons(e.Instance,e.UDim2,e.UDim,e.Color3,e.Enum,e.ColorSequence)
 local uiModule=modules.make_UI(e.Game,e.Task,e.OS,e.Instance,e.Color3,e.ColorSequence,e.Vector2,e.Vector3,e.CFrame,e.UDim,e.UDim2,e.Enum,e.TweenInfo)
 modules.UI={new=function(...) e.UI=uiModule.new(...);return e.UI end}
 e.TrainingPopups={}
 local noop=function() end
 modules.Audio={new=function() return {refresh=noop,play=noop} end}
 modules.Effects={new=function(gui) assert(gui and gui:IsA("ScreenGui"),"Actual UI did not export Gui");return {refresh=noop,training=function(amount) table.insert(e.TrainingPopups,amount) end,rebirth=noop} end}
 for _,name in ipairs({"Visuals","PetFollowers","IslandEffects","StationEffects","RaceCamera","SignReadability"}) do modules[name]={new=function() return {refresh=noop} end} end
 modules.PlayerModule=e.PlayerModule
 modules.RidePrediction=if predict then modules.make_RidePrediction(e.Game,e.Workspace,e.Instance,e.CFrame,e.OS,e.Enum) else {new=function() return {intent=function() end,command=function() end} end}
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
 function e.onBelt(id) local z=e.Workspace.World1.Training:FindFirstChild("Treadmill_"..id).Zone;e.teleport(z.Position.X,z.Position.Y+e.Mounts.ensure(e.Player).Offset.Position.Y,z.Position.Z);e.advance(1.5) end
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
 assert(e.Data.context(e.Player).Pets==nil and e.Data.context(e.Player).Receipts==nil,"High frequency state must not copy full inventory/receipts")
 assert(e.UI and e.UI.Gui and e.UI.Gui.Parent==e.Player.PlayerGui and e.UI.Snapshot.Energy==0)
 assert(e.Rep.BikeRemotes.GetSnapshot.OnServerInvoke)
 assert(string.find(e.Player.PlayerGui.BikeDiagnostics:FindFirstChildOfClass("TextLabel").Text,"Spielerdaten und Remotes bereit",1,true))
 for _,name in ipairs({"Action","ActionResult","SnapshotChanged","Feedback"}) do assert(e.Rep.BikeRemotes:FindFirstChild(name):IsA("RemoteEvent")) end
 e.UI.Buttons.Garage.Activated:Fire();assert(e.UI.Viewport and e.UI.Viewport.Frame.CurrentCamera)
 assert(#e.UI.Viewport.Frame:FindFirstChildOfClass("WorldModel"):GetChildren()==1)
end)
test("step-on and prompt rejection communicate through real services and client",function()
 local e=integration(true);e.onBelt(1)
 assert(e.UI.Snapshot.SelectedTreadmill==1 and e.UI.Snapshot.Energy>=1,"selected="..e.UI.Snapshot.SelectedTreadmill.." energy="..e.UI.Snapshot.Energy.." y="..e.Mounts.ensure(e.Player).State.Y.." z="..e.Mounts.ensure(e.Player).State.Z.." notice="..e.UI.Notice.Text.." warns="..tostring(e.Warnings[1] and e.Warnings[1][2]))
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
 assert(hud.EnergyStatus.EnergyIcon:FindFirstChild("BoltFace") and hud.RebirthsStatus.RebirthsIcon:FindFirstChild("RebirthArc") and not hud.EnergyStatus.EnergyIcon:FindFirstChild("Symbol"))
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
 assert(e.UI.ResourceHUD.Size[1]==136 and e.UI.ResourceHUD.Size[2]==90)
 assert(e.UI.ResourceHUD.Position[2]==-10 and e.UI.ResourceHUD.Position[4]==-10)
 assert(e.UI.ResourceValues.Energy.TextSize==22)
 root.AbsoluteSize=e.Vector2.new(820,330);root:GetPropertyChangedSignal("AbsoluteSize"):Fire()
 assert(e.UI.ResourceHUD.Position[2]==-10 and e.UI.ResourceHUD.Position[4]==-10)
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
 assert(e.Data.change(e.Player,function(profile) profile.Energy=modules.Catalog.Treadmills[5].EnergyRequirement;return true end));e.advance(1.5)
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
test("V4.3 walls stop the bike while unsupported ground permits natural falling",function()
 local e=integration(true);e.Move=e.Vector3.new(0,0,-1)
 local start=e.Root.Position
 e.Collision=true;e.advance(.5);assert((e.Root.Position-start).Magnitude<1e-6)
 e.Collision=false;e.NoGround=true;e.advance(.3);assert(e.Root.Position.Y<start.Y)
 e.NoGround=false;e.GroundY=8;e.teleport(0,12.625,0);e.advance(.5)
 assert(e.Root.Position.Z<start.Z)
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
 local e=integration(true);local camera=modules.make_RaceCamera(e.Game,e.Workspace,e.CFrame,e.Vector3,e.Enum,e.Instance)
 camera.new(e.UI.Settings,e.UI)
 local cam=e.Workspace.CurrentCamera
 assert(cam.CameraSubject and cam.CameraSubject.Name=="BikeCameraTarget" and cam.CameraType==e.Enum.CameraType.Custom)
 local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 e.teleport(0,12,63);e.action("StartRace",{Difficulty="Easy"})
 e.Game:GetService("RunService").RenderStepped:Fire(.016)
 assert(cam.CameraType==e.Enum.CameraType.Scriptable)
 e.action("AbortRace");e.Game:GetService("RunService").RenderStepped:Fire(.016);assert(cam.CameraType==e.Enum.CameraType.Custom)
 assert(cam.CameraSubject and cam.CameraSubject.Name=="BikeCameraTarget" and e.Workspace.PlayerBikes:GetChildren()[1]==bike)
end)
test("V4.3 driving up the authored approach starts training without any prompt",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player)
 e.teleport(-54,8.05+r.Offset.Position.Y,-30)
 e.Move=e.Vector3.new(0,0,-1)
 local deadline=e.Now+3
 while r.State.Z> -50 and e.Now<deadline do e.advance(.05) end
 e.BrakeCallback("BikeBrake",e.Enum.UserInputState.Begin);e.advance(1.3)
 assert(r.State.Z< -50 and r.State.Z> -55 and r.State.Grounded and math.abs(r.State.Y-8.1)<.1)
 assert(e.UI.Snapshot.SelectedTreadmill==1 and e.Data.snapshot(e.Player).Energy>=1)
 assert(not e.Workspace.World1.Training.Treadmill_1:FindFirstChild("AccessRamp"))
end)
test("V4.3 touch jump moves the mounted rider and immediately invalidates training contact",function()
 local e=integration(true);e.onBelt(1);local bike=e.Workspace.PlayerBikes:GetChildren()[1]
 local y=e.Root.Position.Y;local energy=e.Data.snapshot(e.Player).Energy
 e.JumpCallback("BikeJump",e.Enum.UserInputState.Begin);e.advance(.3)
 local r=e.Mounts.ensure(e.Player)
 assert(not r.State.Grounded and e.Root.Position.Y>y+2 and e.UI.Snapshot.SelectedTreadmill==0)
 assert(e.Workspace.PlayerBikes:GetChildren()[1]==bike and e.Data.snapshot(e.Player).Energy==energy)
 e.JumpCallback("BikeJump",e.Enum.UserInputState.End);e.advance(.9)
 assert(r.State.Grounded and math.abs(e.Root.Position.Y-y)<.1)
end)
test("V4.3 airborne jump spam and race input cannot create extra jumps",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player)
 e.JumpCallback("BikeJump",e.Enum.UserInputState.Begin);e.advance(.12)
 local vy=r.State.VY
 e.JumpCallback("BikeJump",e.Enum.UserInputState.Begin);e.advance(.1)
 assert(r.State.VY<vy and r.State.JumpId==2)
 e.advance(1);assert(r.State.Grounded)
 e.teleport(0,12.625,63);e.action("StartRace",{Difficulty="Easy"})
 local id=r.State.JumpId;e.JumpCallback("BikeJump",e.Enum.UserInputState.Begin);e.advance(.1)
 assert(r.Mode=="Race" and r.State.JumpId==id)
 e.action("AbortRace")
end)
test("V4.3 switching bikes in flight preserves gravity and jump history",function()
 local e=integration(true)
 e.JumpCallback("BikeJump",e.Enum.UserInputState.Begin);e.advance(.15)
 local old=e.Mounts.ensure(e.Player);local vy=old.State.VY
 assert(e.Data.change(e.Player,function(p) p.OwnedVehicles={1,2};p.ActiveVehicle=2;return true end,true));e.advance(.05)
 local r=e.Mounts.ensure(e.Player)
 assert(r.VehicleId==2 and not r.State.Grounded and r.State.VY<vy and r.State.JumpId==1 and old.Bike.Parent==nil)
end)
test("V4.3 predicted presentation has no transform writer on the replicated bike or avatar",function()
 local e=integration(true,false,false,true);local p=e.UI.Prediction
 assert(p.Active and p.Bike and p.Character and p.Character~=e.Player.Character)
 local authority=e.Workspace.PlayerBikes:GetChildren()[1]
 local cf=authority.PrimaryPart.CFrame;local writes=e.CFrameWrites[authority.PrimaryPart]
 p.intent({Throttle=1,Steer=0,Brake=false,JumpId=0});p.command(999,{Throttle=1,Steer=0,Brake=false,JumpId=0})
 e.Game:GetService("RunService").RenderStepped:Fire(.016)
 closeFrame(authority.PrimaryPart.CFrame,cf);assert(e.CFrameWrites[authority.PrimaryPart]==writes)
 local root=p.Character:FindFirstChild("HumanoidRootPart")
 local weld=p.Bike.Frame.Pivot:FindFirstChild("PermanentRiderMount")
 assert(weld.Part1==root and weld.Part1~=e.Root)
 closeFrame(root.CFrame,weld.Part0.CFrame*weld.C0)
 assert(e.Root.LocalTransparencyModifier==1)
 e.Player:SetAttribute("Racing",true)
 assert(not p.Active and e.Root.LocalTransparencyModifier==0)
end)
test("V4.3 stale prediction states do not roll back the visible vehicle or resource counters",function()
 local e=integration(true,false,false,true);local p=e.UI.Prediction
 local bike=p.Bike;local energy=e.Data.snapshot(e.Player).Energy
 local r=e.Mounts.ensure(e.Player)
 e.Rep.BikeRemotes.DriveState:FireClient(e.Player,{Epoch=r.Epoch-1,Ack=999,Sequence=999,State=table.clone(r.State),Mode="Manual",VehicleId=2,MaxSpeed=18})
 assert(p.Bike==bike and e.Data.snapshot(e.Player).Energy==energy)
 e.UI.Gui:Destroy();assert(not p.Active and e.Root.LocalTransparencyModifier==0)
end)
test("V4.3 predicted presentation rebuilds after vehicle change and cleans up on respawn",function()
 local e=integration(true,false,false,true);local p=e.UI.Prediction;local first=p.Bike
 assert(e.Data.change(e.Player,function(profile) profile.OwnedVehicles={1,7};profile.ActiveVehicle=7;return true end,true));e.advance(.3)
 assert(p.Active and p.Bike~=first and p.Bike:GetAttribute("VehicleId")==7)
 e.Player.CharacterRemoving:Fire();assert(not p.Active and p.Bike==nil)
end)
test("V4.3 queued drive floods cannot accelerate server simulation time",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player)
 local start=r.Frame.Position
 for seq=1000,1100 do e.Rep.BikeRemotes.Drive:FireServer({Version=1,Sequence=seq,Throttle=1,Steer=0,Brake=false,JumpId=0}) end
 assert(#r.Queue<=modules.Config.Bike.QueueLimit)
 e.advance(.1);assert((r.Frame.Position-start).Magnitude<1)
end)
test("V4.3 low walls block the chassis while known raised deck surfaces remain traversable",function()
 local e=integration(true);local n=0
 local obstacle=e.add(e.Workspace,"Part","LowWall",0,8.3,0,3,.6,1)
 e.Workspace.Blockcast=function()
  n+=1;if n%2==1 then return nil end
  return {Instance=obstacle,Normal=e.Vector3.new(0,0,1)}
 end
 local scene=modules.BikeSurface.new(e.Workspace,{},6)
 assert(scene.block(0,10,0,0,0,0,-.2,8,true))
 obstacle.Name="Deck";assert(not scene.block(0,10,0,0,0,0,-.2,8,true))
end)
test("V4.4 actual sidebar toggles Slow Mode and Auto Train through validated server intents",function()
 local e=integration(true)
 e.press("SLOW MODE • OFF");assert(e.Player:GetAttribute("SlowMode")==true and e.UI.Snapshot.Automation.SlowMode)
 e.press("AUTO TRAIN • OFF");assert(e.UI.Snapshot.Automation.AutoTrain)
 local before=e.Data.snapshot(e.Player).Energy
 e.advance(35)
 local r=e.Mounts.ensure(e.Player)
 assert(e.UI.Snapshot.SelectedTreadmill==1 and e.Data.snapshot(e.Player).Energy>before,"Auto train phase="..e.UI.Snapshot.Automation.Phase.." x="..r.State.X.." z="..r.State.Z)
 assert(e.Player:GetAttribute("Mounted") and e.Player:GetAttribute("AutoDriving"))
 local jump=r.State.JumpId;e.JumpCallback("BikeJump",e.Enum.UserInputState.Begin);e.advance(.1)
 e.press("AUTO TRAIN • ON");assert(not e.UI.Snapshot.Automation.AutoTrain and not e.Player:GetAttribute("AutoDriving"))
 assert(r.State.Grounded and r.State.JumpId==jump,"No queued jump may launch on return from automation")
end)
test("V4.4 Auto Train changes to a stronger allowed belt and revalidates after rebirth",function()
 local e=integration(true);e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(35)
 assert(e.Data.change(e.Player,function(p) p.Energy=modules.Catalog.Treadmills[2].EnergyRequirement;return true end))
 e.advance(18);assert(e.UI.Snapshot.SelectedTreadmill==2,"higher belt phase="..e.UI.Snapshot.Automation.Phase)
 assert(e.Data.change(e.Player,function(p) p.Energy=1000;return true end));e.advance(.3);e.UI.OnAction("Rebirth");e.advance(25)
 assert(e.Data.snapshot(e.Player).Rebirths==1 and e.UI.Snapshot.SelectedTreadmill==2)
 -- Rebirth 1 still permits belt 2 via OR; never permits belt 3 (needs 3).
 assert(e.UI.Snapshot.SelectedTreadmill~=3)
end)
test("V4.4 Auto Race drives to start uses real bots and stops further starts when disabled",function()
 local e=integration(true)
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true})
 e.UI.OnAction("Automation",{Setting="AutoRace",Enabled=true,Difficulty="Easy"})
 local deadline=e.Now+45;repeat e.advance(.2) until e.Player:GetAttribute("Racing") or e.Now>deadline
 assert(e.Player:GetAttribute("Racing"),"AutoRace phase="..e.UI.Snapshot.Automation.Phase)
 assert(#e.Workspace.ActiveRaceBikes:GetChildren()==5 and e.UI.Snapshot.SelectedTreadmill==0)
 local energy=e.Data.snapshot(e.Player).Energy
 e.UI.OnAction("Automation",{Setting="AutoRace",Enabled=false})
 assert(e.Player:GetAttribute("Racing"),"Disabling must let the current race finish")
 e.advance(70);assert(not e.Player:GetAttribute("Racing") and e.Data.snapshot(e.Player).Cash>0)
 assert(e.Data.snapshot(e.Player).Energy>=energy and e.UI.Snapshot.Automation.AutoTrain)
 e.advance(40);assert(not e.Player:GetAttribute("Racing") and e.UI.Snapshot.SelectedTreadmill>0)
end)
test("V4.4 blocked automatic navigation stops safely without teleport or free training",function()
 local e=integration(true);local start=e.Mounts.ensure(e.Player).State
 e.Occupied=e.add(e.Workspace,"Part","BlockingWall");e.Occupied.CanCollide=true
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(1)
 local s=e.Mounts.ensure(e.Player).State
 assert(math.abs(s.X-start.X)<1e-7 and math.abs(s.Z-start.Z)<1e-7 and not e.UI.Snapshot.Automation.AutoTrain and e.Data.snapshot(e.Player).Energy==0)
end)
test("V4.4 durable receipt failure blocks economy and retry/rejoin never duplicates grant",function()
 local e=integration(false,nil,true)
 local original=e.Store.UpdateAsync;local fail=3
 e.Store.UpdateAsync=function(self,key,callback)
  local result=original(self,key,callback)
  if fail>0 then fail-=1;error("Lost committed receipt response") end
  return result
 end
 local saved=nil
 e.Task.spawn(function() saved=e.Data.receipt(e.Player,function(p) return modules.PremiumRules.grant(p,"receipt-durable",73,{Cash=5000},"id") end) end)
 e.advance(8);assert(saved==false)
 assert(not e.Data.change(e.Player,function(p) p.Cash+=1;return true end))
 e.Task.spawn(function() saved=e.Data.receipt(e.Player,function(p) return modules.PremiumRules.grant(p,"receipt-durable",73,{Cash=5000},"id") end) end)
 e.advance(1);assert(saved and e.Data.read(e.Player).Cash==5000)
 e.Player.Parent=nil;e.Players.PlayerRemoving:Fire(e.Player);e.advance(.1)
 e.Player.Parent=e.Players;e.Players.PlayerAdded:Fire(e.Player);e.advance(.5)
 assert(e.Data.read(e.Player).Cash==5000 and e.Data.read(e.Player).Receipts['receipt-durable']==73)
end)
test("V4.4 ProcessReceipt owns decision and unknown/cancelled offers cannot grant",function()
 local e=integration(false,nil,true);local real=modules.PremiumRules
 modules.PremiumRules={product=function(id) return if id==73 then {Cash=5000} else nil end,bonus=real.bonus,grant=real.grant,registryValid=real.registryValid}
 local service=modules.make_PremiumService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Enum).new(e.Data)
 modules.PremiumRules=real
 local decision=service.receipt({PlayerId=e.Player.UserId,PurchaseId="roblox-receipt",ProductId=73})
 assert(decision==e.Enum.ProductPurchaseDecision.PurchaseGranted and e.Data.read(e.Player).Cash==5000)
 assert(service.receipt({PlayerId=e.Player.UserId,PurchaseId="roblox-receipt",ProductId=73})==decision and e.Data.read(e.Player).Cash==5000)
 assert(service.receipt({PlayerId=e.Player.UserId,PurchaseId="unknown",ProductId=74})==e.Enum.ProductPurchaseDecision.NotProcessedYet)
 e.UI.open("Shop")
 local disabled=0
 for _,node in ipairs(e.UI.Gui:GetDescendants()) do
  if node:IsA("TextButton") and string.find(node.Text,"NOCH NICHT KONFIGURIERT",1,true) then assert(node.Active==false);disabled+=1 end
 end
 assert(disabled==10)
 local cash=e.Data.snapshot(e.Player).Cash;e.UI.OnAction("Premium",{Offer="Small"});e.advance(.3)
 assert(e.Data.snapshot(e.Player).Cash==cash and not e.ProductPrompt)
end)
test("V4.4 boost timer counts active session time and changes actual training rewards",function()
 local e=integration(true);assert(e.Data.receipt(e.Player,function(p) return modules.PremiumRules.grant(p,"boost",75,{Boost="Energy",Seconds=300},"id") end))
 local start=e.Data.read(e.Player).Boosts.Energy;e.advance(5.1)
 local remaining=e.Data.read(e.Player).Boosts.Energy
 assert(remaining<start and remaining>start-7)
 e.onBelt(1);local before=e.Data.snapshot(e.Player).Energy;e.action("Training")
 assert(e.Data.snapshot(e.Player).Energy-before>=2 and e.UI.Snapshot.PremiumEnergy==2)
end)
test("V4.4 IK uses physical contacts and separated poles on all ten vehicles",function()
 local e=integration(true);local char=e.Player.Character;local hum=char:FindFirstChildOfClass("Humanoid");hum.RigType=e.Enum.HumanoidRigType.R15
 for _,side in ipairs({"Left","Right"}) do
  for _,part in ipairs({"UpperArm","Hand","UpperLeg","Foot"}) do e.add(char,"Part",side..part) end
 end
 local Pose=modules.make_AvatarPose(e.Instance,e.CFrame,e.Vector3,e.Enum)
 for id=1,10 do
  local source=e.Rep.Vehicles:FindFirstChild(if id==1 then "Mountainbike" else "Vehicle"..id);local bike=source:Clone();modules.BikeRig.prepare(bike);bike.Parent=e.Workspace
  local record=Pose.new(char,bike);assert(#record.IK==4 and #record.Attachments==8)
  for _,ik in ipairs(record.IK) do
   local sign=if string.find(ik.ChainRoot.Name,"Left") then -1 else 1
   assert(ik.Pole.Position.X*sign>1 and ik.Pole.Parent==bike.Frame.Pivot)
   assert(ik.Target.Parent.Name==(if string.find(ik.ChainRoot.Name,"Arm") then "Grip" elseif id<=6 then "Pedal" else "FootRest"))
  end
  char.LeftHand:GetPropertyChangedSignal("Size"):Fire();assert(record.Dirty,"Avatar resizing must invalidate IK targets")
  Pose.destroy(record);for _,a in ipairs(record.Attachments) do assert(a.Parent==nil) end;bike:Destroy()
 end
end)
test("V4.4 a single camera target follows prediction after presentation and survives race transitions",function()
 local e=integration(true,nil,nil,true)
 local camera=modules.make_RaceCamera(e.Game,e.Workspace,e.CFrame,e.Vector3,e.Enum,e.Instance)
 camera.new(e.UI.Settings,e.UI);e.Move=e.Vector3.new(0,0,-1);e.advance(.3)
 local render=e.Game:GetService("RunService").RenderStepped
 render:Fire(.016);local cam=e.Workspace.CurrentCamera
 assert(e.UI.Prediction.Active and cam.CameraSubject.Name=="BikeCameraTarget")
 local first=cam.CameraSubject;render:Fire(.016);assert(cam.CameraSubject==first)
 local root=e.UI.Prediction.Bike.Root;assert((first.Position-(root.Position+e.Vector3.new(0,4,0))).Magnitude<1)
 e.UI.Gui:Destroy();assert(first.Parent==nil)
end)
test("V4.4 boost time pauses offline and resumes after durable rejoin",function()
 local e=integration(true)
 assert(e.Data.receipt(e.Player,function(p) return modules.PremiumRules.grant(p,"persistent-potion",75,{Boost="Energy",Seconds=300},"id") end))
 e.advance(4);local before=e.Data.read(e.Player).Boosts.Energy
 e.Player.Parent=nil;e.Players.PlayerRemoving:Fire(e.Player);e.advance(120)
 e.Player.Parent=e.Players;e.Players.PlayerAdded:Fire(e.Player);e.advance(.4)
 local profile=e.Data.read(e.Player)
 assert(profile and profile.Boosts.Energy<=before and profile.Boosts.Energy>=before-1 and profile.Receipts['persistent-potion']==75)
end)
test("V4.4 pass bonuses require Marketplace ownership rather than purchase-finished claims",function()
 local e=integration(true);local config=modules.PremiumConfig;local mock=table.clone(config)
 mock.Passes=table.clone(config.Passes);mock.Passes.Energy=table.clone(config.Passes.Energy);mock.Passes.Energy.Id=501
 modules.PremiumConfig=mock
 local marketplace=e.Game:GetService("MarketplaceService");local owns=true;local checks=0
 marketplace.UserOwnsGamePassAsync=function(_,user,id) assert(user==e.Player.UserId and id==501);checks+=1;return owns end
 local service=modules.make_PremiumService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Enum).new(e.Data);modules.PremiumConfig=config
 service.start();e.advance(.1)
 assert(checks>0 and service.bonus(e.Player,e.Data.read(e.Player),"Energy")==2)
 owns=false;marketplace.PromptGamePassPurchaseFinished:Fire(e.Player,501,true);e.advance(.1)
 assert(service.bonus(e.Player,e.Data.read(e.Player),"Energy")==1)
end)
test("V4.5 Auto Train activation immediately teleports the one mounted unit and resets motion",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player);local bike=r.Bike;local root=r.Root
 r.Rig.Root.PivotOffset=e.CFrame.new(2,1,-7)*e.CFrame.Angles(.2,.8,.1)
 r.State.Speed=16;r.Speed=16;r.State.VY=12;r.State.Grounded=false
 local before=e.Player:GetAttribute("BikeTeleportSerial") or 0
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true})
 local zone=e.Workspace.World1.Training.Treadmill_1.Zone
 assert((e.Player:GetAttribute("BikeTeleportSerial") or 0)==before+1)
 assert(r.Bike==bike and r.Root==root and #e.Workspace.PlayerBikes:GetChildren()==1)
 closeFrame(r.Rig.Root.CFrame,zone.CFrame*e.CFrame.new(0,.05,0))
 closeFrame(root.CFrame,r.Rig.Frame.CFrame*r.Weld.C0)
 assert(r.State.Speed==0 and r.State.VY==0 and r.State.Grounded and e.Mounts.onBelt(e.Player,zone))
 e.advance(.9);assert(e.Data.snapshot(e.Player).Energy==0,"Teleport must not grant an artificial pulse")
 e.advance(.3);assert(e.Data.snapshot(e.Player).Energy==1 and e.UI.Snapshot.SelectedTreadmill==1)
end)
test("V4.5 unlock and energy reset each select and teleport once within a server check",function()
 local e=integration(true);e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(.6)
 local first=e.Player:GetAttribute("BikeTeleportSerial")
 assert(e.Data.change(e.Player,function(p) p.Energy=modules.Catalog.Treadmills[4].EnergyRequirement;return true end))
 e.advance(.25);assert(e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_4.Zone))
 assert(e.Player:GetAttribute("BikeTeleportSerial")==first+1)
 e.advance(.6)
 assert(e.Data.change(e.Player,function(p) p.Energy=0;p.Rebirths=0;return true end));e.advance(.25)
 assert(e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_1.Zone) and e.Player:GetAttribute("BikeTeleportSerial")==first+2)
end)
test("V4.5 rebirth teleports to the remaining OR-authorized belt and preserves all other progress",function()
 local e=integration(true);assert(e.Data.change(e.Player,function(p) p.Energy=3000;p.Cash=99;return true end));e.advance(.3)
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(.6)
 assert(e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_5.Zone))
 e.UI.OnAction("Rebirth");e.advance(.25)
 local p=e.Data.read(e.Player)
 assert(p.Rebirths==1 and p.Energy==0 and p.Cash==99)
 assert(e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_2.Zone))
end)
test("V4.5 duplicate Auto Train intents and profile updates do not spam teleports or tap rewards",function()
 local e=integration(true);e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true})
 local serial=e.Player:GetAttribute("BikeTeleportSerial")
 for _=1,100 do e.Rep.BikeRemotes.Action:FireServer({Version=1,Action="Automation",Setting="AutoTrain",Enabled=true}) end
 assert(e.Player:GetAttribute("BikeTeleportSerial")==serial and e.Data.snapshot(e.Player).Energy==0)
 e.advance(1.3);assert(e.Data.snapshot(e.Player).Energy==1,"Exactly one normal auto impulse after the selection interval")
 local energy=e.Data.snapshot(e.Player).Energy;e.action("Training");assert(e.Data.snapshot(e.Player).Energy-energy==1)
 e.advance(1.1);assert(e.Player:GetAttribute("BikeTeleportSerial")==serial)
end)
test("V4.5 disabling Auto Train restores manual riding and no later unlock causes a teleport",function()
 local e=integration(true);e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(.6)
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=false})
 local serial=e.Player:GetAttribute("BikeTeleportSerial")
 assert(e.Data.change(e.Player,function(p) p.Energy=1e6;return true end));e.advance(.5)
 assert(e.Player:GetAttribute("BikeTeleportSerial")==serial and not e.Player:GetAttribute("AutoDriving"))
 e.Move=e.Vector3.new(0,0,1);e.advance(1.5)
 assert(e.Player:GetAttribute("Mounted") and e.UI.Snapshot.SelectedTreadmill==0)
end)
test("V4.5 authoritative training teleport rejects walls, bad support and invalid IDs",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player);local start=r.Rig.Root.CFrame
 assert(not e.Mounts.trainTeleport(e.Player,5));assert(not e.Mounts.trainTeleport(e.Player,0/0));assert(not e.Mounts.trainTeleport(e.Player,99))
 e.Occupied=e.add(e.Workspace,"Part","BlockedTrainingPosition");e.Occupied.CanCollide=true
 assert(not e.Mounts.trainTeleport(e.Player,1));closeFrame(r.Rig.Root.CFrame,start)
 e.Occupied=nil;e.NoGround=true;assert(not e.Mounts.trainTeleport(e.Player,1));closeFrame(r.Rig.Root.CFrame,start)
 e.NoGround=false;assert(e.Mounts.trainTeleport(e.Player,1))
end)
test("V4.5 VIP zone restriction is enforced for auto teleport and manual training",function()
 local e=integration(true);assert(e.Data.change(e.Player,function(p) p.Energy=1e6;return true end))
 e.Workspace.World1.Training.Treadmill_5.Zone:SetAttribute("VIPOnly",true)
 e.Player:SetAttribute("VIP",true) -- A player attribute is not Marketplace ownership.
 assert(not e.Mounts.trainTeleport(e.Player,5))
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});assert(e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_4.Zone))
 local r=e.Mounts.ensure(e.Player);e.Mounts.teleport(e.Player,e.Workspace.World1.Training.Treadmill_5.Zone.CFrame*e.CFrame.new(0,.05,0))
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=false});e.advance(1.2)
 assert(e.UI.Snapshot.SelectedTreadmill~=5)
 e.Workspace.World1.Training.Treadmill_5.Zone:SetAttribute("VIPOnly",false)
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});assert(e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_5.Zone))
end)
test("V4.5 Auto Train never teleports an active race and resumes immediately after finish",function()
 local e=integration(true);local r=e.Mounts.ensure(e.Player)
 e.teleport(0,8.05+r.Offset.Position.Y,63);e.action("StartRace",{Difficulty="Easy"});assert(e.Player:GetAttribute("Racing"))
 local serial=e.Player:GetAttribute("BikeTeleportSerial")
 assert(e.Data.change(e.Player,function(p) p.Energy=1e6;return true end))
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true})
 assert(not e.Mounts.trainTeleport(e.Player,1))
 e.advance(5);assert(e.Player:GetAttribute("Racing") and e.Player:GetAttribute("BikeTeleportSerial")==serial)
 repeat e.advance(.1) until not e.Player:GetAttribute("Racing")
 e.advance(.25)
 assert(e.Player:GetAttribute("BikeTeleportSerial")==serial+1 and e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_5.Zone))
 assert(e.Data.snapshot(e.Player).Cash>0)
end)
test("V4.5 Auto Race repeats with one training resume teleport per finished race",function()
 local e=integration(true);e.UI.OnAction("Automation",{Setting="AutoRace",Enabled=true})
 local deadline=e.Now+45;repeat e.advance(.2) until e.Player:GetAttribute("Racing") or e.Now>deadline
 assert(e.Player:GetAttribute("Racing"));e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true})
 local serial=e.Player:GetAttribute("BikeTeleportSerial") or 0
 repeat e.advance(.1) until not e.Player:GetAttribute("Racing")
 e.advance(.25);assert((e.Player:GetAttribute("BikeTeleportSerial") or 0)==serial+1)
 e.advance(1);assert((e.Player:GetAttribute("BikeTeleportSerial") or 0)==serial+1)
 deadline=e.Now+45;repeat e.advance(.2) until e.Player:GetAttribute("Racing") or e.Now>deadline
 assert(e.Player:GetAttribute("Racing") and (e.Player:GetAttribute("BikeTeleportSerial") or 0)==serial+1)
 e.UI.OnAction("Automation",{Setting="AutoRace",Enabled=false})
end)
test("V4.5 respawn remounts and auto teleports once; bike change preserves the valid training position",function()
 local e=integration(true);assert(e.Data.change(e.Player,function(p) p.Energy=1e6;p.OwnedVehicles={1,7};return true end,true))
 e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(.6)
 local serial=e.Player:GetAttribute("BikeTeleportSerial")
 assert(e.Data.change(e.Player,function(p) p.ActiveVehicle=7;return true end,true));e.advance(.4)
 assert(e.Mounts.ensure(e.Player).VehicleId==7 and e.Player:GetAttribute("BikeTeleportSerial")==serial)
 e.Player.CharacterRemoving:Fire();e.Player.Character:Destroy()
 local char=e.add(e.Workspace,"Model","Respawn");e.Root=e.add(char,"Part","HumanoidRootPart",0,11,0);local hum=e.add(char,"Humanoid","Humanoid");hum.Health=100
 e.Player.Character=char;e.Player.CharacterAdded:Fire(char);e.advance(.6)
 assert(e.Mounts.ensure(e.Player).VehicleId==7 and #e.Workspace.PlayerBikes:GetChildren()==1 and hum.Sit)
 assert(e.Player:GetAttribute("BikeTeleportSerial")==serial+1 and e.Mounts.onBelt(e.Player,e.Workspace.World1.Training.Treadmill_5.Zone))
 e.advance(1);assert(e.Player:GetAttribute("BikeTeleportSerial")==serial+1)
end)
test("V4.5 teleport invalidates stale drive epochs and resets the root-based camera even for an 18-stud switch",function()
 local e=integration(true,nil,nil,true);local camera=modules.make_RaceCamera(e.Game,e.Workspace,e.CFrame,e.Vector3,e.Enum,e.Instance)
 camera.new(e.UI.Settings,e.UI);e.UI.OnAction("Automation",{Setting="AutoTrain",Enabled=true});e.advance(.6)
 local render=e.Game:GetService("RunService").RenderStepped;render:Fire(.016)
 local epoch=e.Player:GetAttribute("DriveEpoch")
 assert(e.Data.change(e.Player,function(p) p.Energy=84;return true end));e.advance(.25);render:Fire(.016)
 local r=e.Mounts.ensure(e.Player);local target=e.Workspace.CurrentCamera.CameraSubject
 assert((target.Position-(r.Rig.Root.Position+e.Vector3.new(0,4,0))).Magnitude<1e-6)
 assert(not e.Mounts.input(e.Player,{Version=1,Epoch=epoch,Sequence=10000,Throttle=1,Steer=1,Brake=false,JumpId=100}))
 assert(r.State.Speed==0 and r.State.VY==0)
end)
test("V4.5 free HUD is exactly at the safe-area corner and touch jump is placed above it",function()
 local e=integration(true);local hud=e.UI.ResourceHUD;local canvas=hud.Parent
 assert(canvas.Parent==e.UI.Gui and canvas.BackgroundTransparency==1 and canvas.Position[1]==0 and canvas.Position[2]==0)
 for _,touch in ipairs({false,true}) do
  e.Game:GetService("UserInputService").TouchEnabled=touch
  for _,size in ipairs({{375,680},{820,330},{1024,700}}) do
   canvas.AbsoluteSize=e.Vector2.new(size[1],size[2]);canvas:GetPropertyChangedSignal("AbsoluteSize"):Fire()
   assert(hud.AnchorPoint.X==1 and hud.AnchorPoint.Y==1 and hud.Position[2]==-10 and hud.Position[4]==-10)
   for i,name in ipairs({"Energy","Cash","Rebirths"}) do
    local row=hud:FindFirstChild(name.."Status");assert(row.Position[2]==(i-1)*(if touch then 30 else 36))
    assert(e.UI.ResourceValues[name].TextXAlignment==e.Enum.TextXAlignment.Right and e.UI.ResourceValues[name].TextScaled)
   end
  end
 end
 assert(e.ActionPositions.BikeJump[4]==-220 and e.ActionBindings.BikeJump.Touch and e.ActionBindings.BikeJump.Keys[1]==e.Enum.KeyCode.Space)
 assert(220-70>10+hud.Size[2],"Touch jump button must leave vertical clearance above the HUD")
end)
test("V4.5 teleport action cannot accept positions, targets, amounts or VIP claims from the client",function()
 local e=integration(true);local before=e.Player:GetAttribute("BikeTeleportSerial") or 0
 for _,field in ipairs({"Position","CFrame","TreadmillId","Energy","VIP"}) do
  local payload={Version=1,Action="Automation",Setting="AutoTrain",Enabled=true};payload[field]=5
  assert(not modules.Protocol.validAction(payload));e.Rep.BikeRemotes.Action:FireServer(payload)
 end
 assert((e.Player:GetAttribute("BikeTeleportSerial") or 0)==before and e.UI.Snapshot.Energy==0)
end)
test("V4.5 sign diagnostics read actual bounds/fits rather than asserting renderer success",function()
 local e=integration(true);local module=modules.make_SignReadability(e.Game,e.Workspace,e.Task,e.Warn,e.Enum)
 local part=e.add(e.Workspace,"Part","TextFace");local gui=e.add(part,"SurfaceGui","SignCaption")
 gui.Adornee=part;gui.Face=e.Enum.NormalId.Back;gui.SizingMode=e.Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=96
 local label=e.add(gui,"TextLabel","Caption");label.Text="BIKE SHOP";label.TextScaled=true;label.ClipsDescendants=false;label.TextStrokeTransparency=.45;label.ZIndex=2;label.TextBounds=e.Vector2.new(300,60);label.AbsoluteSize=e.Vector2.new(1000,200);label.TextFits=true
 assert(#module.inspect(gui)==0)
 label.TextFits=false;assert(table.find(module.inspect(gui),"Caption does not fit"))
 label.TextFits=true;gui.Adornee=nil;assert(table.find(module.inspect(gui),"Adornee mismatch"))
end)
test("V4.5 teleport respects rotated zone axes and refuses tilted training targets before movement",function()
 local e=integration(true);local zone=e.Workspace.World1.Training.Treadmill_1.Zone
 local r=e.Mounts.ensure(e.Player);local initial=r.Rig.Root.CFrame
 zone.CFrame=e.CFrame.new(zone.Position)*e.CFrame.Angles(.2,0,0)
 assert(not e.Mounts.trainTeleport(e.Player,1));closeFrame(r.Rig.Root.CFrame,initial)
 zone.CFrame=e.CFrame.new(zone.Position)*e.CFrame.Angles(0,math.pi/2,0)
 assert(e.Mounts.trainTeleport(e.Player,1));closeFrame(r.Rig.Root.CFrame,zone.CFrame*e.CFrame.new(0,.05,0))
 assert(e.Mounts.onBelt(e.Player,zone));closeFrame(e.Root.CFrame,r.Rig.Frame.CFrame*r.Weld.C0)
end)
print(string.format("%d actual runtime wiring tests passed (engine doubles; NOT Roblox Studio)",count))
