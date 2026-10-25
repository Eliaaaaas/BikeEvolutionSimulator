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
local camera=workspace.CurrentCamera
local size=if camera then camera.ViewportSize else Vector2.new(800,600)
local settings=State.new(UserInputService.TouchEnabled and math.min(size.X,size.Y)<700)
local audio=Audio.new(settings)
local ui=UI.new(Players.LocalPlayer:WaitForChild("PlayerGui"),settings,audio)
local effects=Effects.new(ui.Gui,settings)
local visuals=Visuals.new(settings,ui)
ui.OnSetting=function() audio.refresh();effects.refresh();ui.refreshSettings();visuals.refresh() end
local remotes=ReplicatedStorage:WaitForChild(Config.Network.Folder)
local action=remotes:WaitForChild("Action") :: RemoteEvent
local snapshotRemote=remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local snapshot:any=nil
local lastProgress=0
local function send(kind:string)
 if snapshot then action:FireServer({Version=1,Action=kind}) end
end
ui.OnMenu=function(name:string)
 if not snapshot and name~="Settings" and name~="Garage" then ui.message("Spielerdaten werden noch geladen.");return end
 ui.open(name)
end
ui.OnAction=function(kind:string)
 if not snapshot then return end
 if kind=="Training" then
  if snapshot.SelectedTreadmill==0 then ui.message("Stelle dich hinten auf ein Laufband und nutze „Trainieren“.") else send("Click") end
 elseif kind=="Rebirth" then
  if Presentation.rebirth(snapshot).Allowed then send("Rebirth") else ui.message("Noch nicht genug Energy oder maximales Rebirth-Level erreicht.") end
 else send(kind) end
end
local function render(data:any):boolean
 if not Protocol.validSnapshot(data) or type(data.SelectedTreadmill)~="number" then return false end
 local progress=Presentation.training(data).Ratio
 if snapshot and progress>=1 and lastProgress<1 then audio.play("Unlock") end
 lastProgress=progress;snapshot=data;ui.update(data);return true
end
local snapshotEvent=remotes:WaitForChild("SnapshotChanged") :: RemoteEvent
snapshotEvent.OnClientEvent:Connect(render)
local errors={TooFar="Stelle dich auf dein Laufband.",Locked="Energy- oder Rebirth-Anforderung fehlt.",NotReady="Daten noch nicht bereit.",Saving="Speichern läuft – kurz warten.",NoTreadmill="Bitte zuerst ein Laufband auswählen.",NotEnoughEnergy="Nicht genug Energy.",NotAlive="Aktion nur mit lebendem Charakter.",AlreadyRacing="Während des Rennens nicht verfügbar.",RaceUnavailable="Gehe zur Race-Zone vorne auf der Insel."}
local resultEvent=remotes:WaitForChild("ActionResult") :: RemoteEvent
resultEvent.OnClientEvent:Connect(function(result)
 if type(result)=="table" and not result.Ok and result.Error~="Cooldown" then ui.message(errors[result.Error] or "Aktion nicht verfügbar.") end
end)
local feedbackEvent=remotes:WaitForChild("Feedback") :: RemoteEvent
feedbackEvent.OnClientEvent:Connect(function(event)
 if type(event)~="table" or type(event.Id)~="number" or not State.event(settings,event.Id) then return end
 if event.Kind=="Training" and type(event.Amount)=="number" then effects.training(event.Amount);audio.play("Training")
 elseif event.Kind=="Selected" then audio.play("Selected")
 elseif event.Kind=="Rebirth" and type(event.Rebirths)=="number" then effects.rebirth(event.Rebirths);audio.play("Rebirth")
 elseif event.Kind=="RaceEnded" then ui.message(if event.Reason=="Finished" then "Ziel erreicht! Energy und Cash bleiben erhalten." else "Test-Rennen beendet.");if event.Reason=="Finished" then audio.play("Success") end end
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
