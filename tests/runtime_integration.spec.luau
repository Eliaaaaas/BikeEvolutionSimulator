local function integration(preview,remove,live)
 local e=modules.runtimeEngine();modules.populateWorld(e.add,e.Workspace,e.Rep)
 if remove then e.Workspace.World1.Training.Treadmill_1.Zone:Destroy() end
 e.Workspace:SetAttribute("StudioPreviewData",preview)
 e.Studio=not live
 local serverScript=e.add(nil,"Script","Server")
 modules.BikeRig=modules.makeBikeRig(e.Instance)
 modules.RaceService=modules.makeRaceService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum)
 modules.PlayerDataService=modules.makeService(e.Game,e.Task,e.OS,e.Warn)
 modules.GameplayService=modules.make_GameplayService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.Random)
 modules.RemoteService=modules.make_RemoteService(e.Game,e.Task,e.OS,e.Instance)
 local booted,bootError=pcall(modules.make_init_server,e.Game,e.Workspace,e.Instance,serverScript,e.Warn)
 if remove then assert(not booted);e.BootError=bootError;return e end
 assert(booted,tostring(bootError))
 e.Data=modules.PlayerDataService;e.advance(0)
 modules.Icons=modules.make_Icons(e.Instance,e.UDim2,e.UDim,e.Color3,e.Enum)
 local uiModule=modules.make_UI(e.Game,e.Task,e.OS,e.Instance,e.Color3,e.ColorSequence,e.Vector2,e.Vector3,e.CFrame,e.UDim,e.UDim2,e.Enum,e.TweenInfo)
 modules.UI={new=function(...) e.UI=uiModule.new(...);return e.UI end}
 local noop=function() end
 modules.Audio={new=function() return {refresh=noop,play=noop} end}
 modules.Effects={new=function(gui) assert(gui and gui:IsA("ScreenGui"),"Actual UI did not export Gui");return {refresh=noop,training=noop,rebirth=noop} end}
 for _,name in ipairs({"Visuals","PetFollowers","IslandEffects","StationEffects","RaceCamera"}) do modules[name]={new=function() return {refresh=noop} end} end
 modules.ClientApp=modules.make_ClientApp(e.Game,e.Workspace,e.Task,e.Instance,e.Vector2)
 modules.make_init_client(e.Game,e.Instance,e.UDim2,e.Color3,e.Enum,e.add(nil,"LocalScript","Client"),e.Warn)
 e.advance(.5)
 function e.action(kind,fields) e.UI.OnAction(kind,fields);e.advance(.26) end
 function e.onBelt(id) local z=e.Workspace.World1.Training:FindFirstChild("Treadmill_"..id).Zone;e.Root.CFrame=e.CFrame.new(z.Position.X,z.Position.Y+3,z.Position.Z);e.advance(1.5) end
 function e.press(text)
  for _,node in ipairs(e.UI.Gui:GetDescendants()) do
   if node:IsA("TextButton") and node.Text==text then node.Activated:Fire();e.advance(.3);return end
  end
  error("Actual UI button missing: "..text)
 end
 function e.race()
  e.Root.CFrame=e.CFrame.new(0,11,63);e.UI.open("Race");e.press("Rennen starten / erneut starten")
  assert(e.Player:GetAttribute("Racing"));assert(#e.Workspace.ActiveRaceBikes:GetChildren()==6)
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
 e.Root.CFrame=e.CFrame.new(0,11,0);e.advance(.3)
 e.Workspace.World1.Training.Treadmill_5.Zone.SelectTraining.Triggered:Fire(e.Player)
 assert(string.find(e.UI.Status.Text,"Laufband"))
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
 e.UI.PetId=petId;e.UI.open("Pet");e.press("Ausrüsten");assert(e.UI.Snapshot.PetEnergyBonus>1 and e.UI.Snapshot.PetCashBonus>1)
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
 e.Root.CFrame=e.CFrame.new(0,11,0);e.advance(.4);e.onBelt(1)
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
  for _,name in ipairs({"Energy","Cash","Rebirths"}) do
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
print(string.format("%d actual runtime wiring tests passed (engine doubles; NOT Roblox Studio)",count))
