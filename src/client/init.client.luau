--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Protocol=require(Shared:WaitForChild("Protocol"))
local Format=require(Shared:WaitForChild("Format"))
local Presentation=require(Shared:WaitForChild("Presentation"))
local State=require(Shared:WaitForChild("ClientState"))
local UI=require(script.UI)
local Audio=require(script.Audio)
local Effects=require(script.Effects)
local Visuals=require(script.Visuals)
local PetFollowers=require(script.PetFollowers)
local camera=workspace.CurrentCamera
local size=if camera then camera.ViewportSize else Vector2.new(800,600)
local settings=State.new(UserInputService.TouchEnabled and math.min(size.X,size.Y)<700)
local audio=Audio.new(settings)
local ui=UI.new(Players.LocalPlayer:WaitForChild("PlayerGui"),settings,audio)
local effects=Effects.new(ui.Gui,settings)
local visuals=Visuals.new(settings,ui)
PetFollowers.new(settings,ui.Gui)
ui.OnSetting=function() audio.refresh();effects.refresh();ui.refreshSettings();visuals.refresh() end
local remotes=ReplicatedStorage:WaitForChild(Config.Network.Folder)
local action=remotes:WaitForChild("Action") :: RemoteEvent
local snapshotRemote=remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local snapshot:any=nil
local lastProgress=0
local requestId=0
local function send(kind:string,fields:any?)
 if not snapshot then return end
 local payload=fields or {};payload.Version=1;payload.Action=kind
 if kind=="BuyVehicle" or kind=="EquipVehicle" or kind=="Hatch" or kind=="EquipPet" or kind=="UnequipPet" then requestId+=1;payload.RequestId=requestId end
 action:FireServer(payload)
end
ui.OnMenu=function(name:string)
 if not snapshot and name~="Settings" then ui.message("Spielerdaten werden noch geladen.");return end
 ui.open(name)
end
ui.OnAction=function(kind:string,fields:any?)
 if not snapshot then return end
 if kind=="Training" then
  if snapshot.SelectedTreadmill==0 then ui.message("Stelle dich hinten auf ein Laufband und nutze „Trainieren“.") else send("Click") end
 elseif kind=="Rebirth" then
  if Presentation.rebirth(snapshot).Allowed then send("Rebirth") else ui.message("Noch nicht genug Energy oder maximales Rebirth-Level erreicht.") end
 else send(kind,fields) end
end
local function render(data:any):boolean
 if not Protocol.validSnapshot(data) or type(data.SelectedTreadmill)~="number" then return false end
 if snapshot then
  for _,key in ipairs({"Pets","EquippedPets","DiscoveredPets","OwnedVehicles"}) do if data[key]==nil then data[key]=snapshot[key] end end
 end
 requestId=math.max(requestId,data.LastRequestId or 0)
 local progress=Presentation.training(data).Ratio
 if snapshot and progress>=1 and lastProgress<1 then audio.play("Unlock") end
 lastProgress=progress;snapshot=data;ui.update(data);return true
end
local snapshotEvent=remotes:WaitForChild("SnapshotChanged") :: RemoteEvent
snapshotEvent.OnClientEvent:Connect(render)
local errors={TooFar="Stelle dich auf dein Laufband.",Locked="Energy- oder Rebirth-Anforderung fehlt.",NotReady="Daten noch nicht bereit.",Saving="Speichern läuft – kurz warten.",NoTreadmill="Bitte zuerst ein Laufband auswählen.",NotEnoughEnergy="Nicht genug Energy.",NotAlive="Aktion nur mit lebendem Charakter.",AlreadyRacing="Während des Rennens nicht verfügbar.",RaceUnavailable="Gehe zur Race-Zone vorne auf der Insel.",NotEnoughCash="Nicht genug Cash.",AlreadyOwned="Dieses Fahrzeug gehört dir bereits.",InventoryFull="Pet-Inventar voll.",EquipLimit="Maximal drei Pets ausrüstbar.",DuplicateRequest="Diese Anfrage wurde bereits verarbeitet."}
local resultEvent=remotes:WaitForChild("ActionResult") :: RemoteEvent
resultEvent.OnClientEvent:Connect(function(result)
 if type(result)=="table" and result.Error=="Cooldown" and (result.Action=="StartRace" or result.Action=="Hatch") then ui.message("Bitte kurz warten und dann erneut versuchen.") end
 if type(result)=="table" and not result.Ok and result.Error~="Cooldown" then ui.message(errors[result.Error] or "Aktion nicht verfügbar.") end
end)
local feedbackEvent=remotes:WaitForChild("Feedback") :: RemoteEvent
feedbackEvent.OnClientEvent:Connect(function(event)
 if type(event)~="table" or type(event.Id)~="number" or not State.event(settings,event.Id) then return end
 if event.Kind=="Training" and type(event.Amount)=="number" then effects.training(event.Amount);audio.play("Training")
 elseif event.Kind=="Selected" then audio.play("Selected")
 elseif event.Kind=="Rebirth" and type(event.Rebirths)=="number" then effects.rebirth(event.Rebirths);audio.play("Rebirth")
 elseif event.Kind=="Hatched" then ui.HatchedId=event.SpeciesId;ui.open("Hatch");audio.play("Success")
 elseif event.Kind=="OpenEgg" then ui.EggId=event.EggId;ui.open("Egg")
 elseif event.Kind=="OpenMenu" then ui.open(event.Menu)
 elseif event.Kind=="Purchase" then audio.play("Success")
 elseif event.Kind=="RaceStarted" then ui.LastRaceResult=nil
 elseif event.Kind=="RaceEnded" then
  if event.Reason=="Finished" then ui.LastRaceResult=event;ui.open("Race");audio.play("Success")
  else ui.message(if event.Reason=="RewardUnavailable" then "Auszahlung nicht verfügbar – keine doppelte Forderung erzeugt." else "Rennen abgebrochen. Keine Belohnung.") end
 end
end)
task.spawn(function()
 while not snapshot do
  local ok,response=pcall(function() return snapshotRemote:InvokeServer({Version=1}) end)
  if ok and type(response)=="table" and response.Ok then render(response.Data) end
  if not snapshot then task.wait(2) end
 end
end)
local training=workspace:WaitForChild("World1"):WaitForChild("Training")
local Catalog=require(Shared:WaitForChild("Catalog"))
for id=1,5 do
 local prompt=training:WaitForChild("Treadmill_"..id):WaitForChild("Zone"):WaitForChild("SelectTraining") :: ProximityPrompt
 local t=Catalog.Treadmills[id]
 prompt.ObjectText="Laufband "..id.." • "..Format.number(t.EnergyRequirement).." Energy ODER "..Format.number(t.RebirthRequirement).." Rebirths"
end
