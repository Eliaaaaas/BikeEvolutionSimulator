--!strict
local App={}
function App.start(progress:(string)->())
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Protocol=require(Shared:WaitForChild("Protocol"))
local Presentation=require(Shared:WaitForChild("Presentation"))
local State=require(Shared:WaitForChild("ClientState"))
local UI=require(script.Parent.UI)
local Audio=require(script.Parent.Audio)
local Effects=require(script.Parent.Effects)
local camera=workspace.CurrentCamera
local size=if camera then camera.ViewportSize else Vector2.new(800,600)
local settings=State.new(UserInputService.TouchEnabled and math.min(size.X,size.Y)<700)
local audio=Audio.new(settings)
local ui=UI.new(Players.LocalPlayer:WaitForChild("PlayerGui"),settings,audio)
local effects=Effects.new(ui.Gui,settings)
local visuals:any={refresh=function() end}
progress("UI bereit; verbinde Remotes")
ui.OnSetting=function() audio.refresh();effects.refresh();ui.refreshSettings();visuals.refresh() end
local remotes=ReplicatedStorage:WaitForChild(Config.Network.Folder)
local action=remotes:WaitForChild("Action",15) :: RemoteEvent
assert(action,"Action remote missing")
local snapshotRemote=remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local snapshot:any=nil
local lastProgress=0
local requestId=0
local function send(kind:string,fields:any?)
 if not snapshot then return end
 local payload=fields or {};payload.Version=1;payload.Action=kind
 if kind=="BuyVehicle" or kind=="EquipVehicle" or kind=="Hatch" or kind=="EquipPet" or kind=="UnequipPet" or kind=="EquipBest" or kind=="UnequipAll" then requestId+=1;payload.RequestId=requestId end
 action:FireServer(payload)
end
ui.OnMenu=function(name:string)
 if not snapshot and name~="Settings" then ui.message("Spielerdaten werden noch geladen.");return end
 ui.open(name)
end
ui.OnAction=function(kind:string,fields:any?)
 if not snapshot then return end
 if kind=="Rebirth" then
  if Presentation.rebirth(snapshot).Allowed then send("Rebirth") else ui.message("Noch nicht genug Energy oder maximales Rebirth-Level erreicht.") end
 else send(kind,fields) end
end
local function render(data:any):boolean
 if not Protocol.validSnapshot(data) or type(data.SelectedTreadmill)~="number" then return false end
 local merged=State.snapshot(snapshot,data)
 if not merged then return false end
 data=merged
 requestId=math.max(requestId,data.LastRequestId or 0)
 local first=snapshot==nil
 local ratio=Presentation.training(data).Ratio
 if snapshot and ratio>=1 and lastProgress<1 then audio.play("Unlock") end
 lastProgress=ratio;snapshot=data;ui.update(data)
 if first then progress("Spielerdaten und Remotes bereit") end
 return true
end
local snapshotEvent=remotes:WaitForChild("SnapshotChanged") :: RemoteEvent
snapshotEvent.OnClientEvent:Connect(render)
local errors={TrainingPositionBlocked="Trainingsposition blockiert. Auto Train wurde angehalten.",TreadmillUnavailable="Dieses Laufband ist hier nicht verfügbar.",NoAvailableTreadmill="Kein nutzbares Laufband in einer verfügbaren Welt.",ProductUnavailable="Dieses Robux-Angebot ist noch nicht konfiguriert.",NavigationBlocked="Automatik angehalten: Weg blockiert. Bitte manuell freifahren.",TooFar="Stelle dich auf dein Laufband.",Locked="Energy- oder Rebirth-Anforderung fehlt.",NotReady="Daten noch nicht bereit.",Saving="Speichern läuft – kurz warten.",NoTreadmill="Bitte zuerst ein Laufband auswählen.",NotEnoughEnergy="Nicht genug Energy.",NotAlive="Aktion nur mit lebendem Charakter.",AlreadyRacing="Während des Rennens nicht verfügbar.",RaceUnavailable="Gehe zur Race-Zone vorne auf der Insel.",NotEnoughCash="Nicht genug Cash.",AlreadyOwned="Dieses Fahrzeug gehört dir bereits.",InventoryFull="Pet-Inventar voll.",EquipLimit="Maximal drei Pets ausrüstbar.",DuplicateRequest="Diese Anfrage wurde bereits verarbeitet.",PetUnavailable="Dieses Pet ist nicht verfügbar oder noch gesperrt.",ServiceUnavailable="Aktion vorübergehend nicht verfügbar. Bitte erneut versuchen."}
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
 elseif event.Kind=="InteractionError" then ui.message(errors[event.Error] or "Station nicht verfügbar: "..tostring(event.Error))
 elseif event.Kind=="OpenEgg" then ui.EggId=event.EggId;ui.open("Egg")
 elseif event.Kind=="OpenMenu" then ui.open(event.Menu)
 elseif event.Kind=="PetEquipmentChanged" then audio.play("Success");ui.message(if event.Action=="EquipBest" then "Die besten verfügbaren Pets sind ausgerüstet." else "Alle Pets wurden abgelegt.")
 elseif event.Kind=="Purchase" then audio.play("Success")
 elseif event.Kind=="RaceStarted" then ui.LastRaceResult=nil
 elseif event.Kind=="RaceEnded" then
  if event.Reason=="Finished" then ui.LastRaceResult=event;if not snapshot or not snapshot.Automation or not snapshot.Automation.AutoRace then ui.open("Race") end;audio.play("Success")
  else ui.message(if event.Reason=="RewardUnavailable" then "Auszahlung nicht verfügbar – keine doppelte Forderung erzeugt." else "Rennen abgebrochen. Keine Belohnung.") end
 end
end)
task.spawn(function()
 while not snapshot do
  local ok,response=pcall(function() return snapshotRemote:InvokeServer({Version=1}) end)
  if ok and type(response)=="table" and response.Ok then
   render(response.Data)
  elseif not snapshot then
   ui.message("Ladeprofil: "..(if ok and type(response)=="table" then tostring(response.Error) else "Server nicht erreichbar"))
  end
  if not snapshot then task.wait(2) end
 end
end)
task.defer(function()
 local function optional(name:string,callback:()->())
  local ok,err=pcall(function():any callback();return true end);if not ok then warn("[BikeClient optional]",name,err);progress("Optionaler Effekt fehlgeschlagen: "..name) end
 end
 optional("Camera",function() require(script.Parent.RaceCamera).new(settings,ui) end)
 optional("Vehicles",function() visuals=require(script.Parent.Visuals).new(settings,ui) end)
 optional("Pets",function() require(script.Parent.PetFollowers).new(settings,ui.Gui) end)
 optional("Island",function() require(script.Parent.IslandEffects).new(settings,ui.Gui) end)
 optional("Signs",function() require(script.Parent.SignReadability).new(settings,ui) end)
 optional("Stations",function() require(script.Parent.StationEffects).new(settings,ui) end)
end)
require(script.Parent.BikeInput).new(ui,remotes:WaitForChild("Drive") :: RemoteEvent,remotes:WaitForChild("DriveState") :: RemoteEvent)
require(script.Parent.TrainingInput).new(ui,send)
end
return App
