--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Protocol = require(Shared:WaitForChild("Protocol"))
local Catalog = require(Shared:WaitForChild("Catalog"))
local UI = require(script.UI)
local ui = UI.new(Players.LocalPlayer:WaitForChild("PlayerGui"))
local remotes=ReplicatedStorage:WaitForChild(Config.Network.Folder)
local action=remotes:WaitForChild("Action") :: RemoteEvent
local snapshotRemote=remotes:WaitForChild("GetSnapshot") :: RemoteFunction
local snapshot: any=nil
local lastError=0
local function number(value: number): string
 if value>=1e6 then return string.format("%.2e",value) end
 if value%1==0 then return string.format("%.0f",value) end
 return string.format("%.1f",value)
end
local function send(kind: string, id: number?)
 if not snapshot then return end
 action:FireServer({Version=1,Action=kind,TreadmillId=id})
end
local function render(data: any): boolean
 if not Protocol.validSnapshot(data) or type(data.SelectedTreadmill)~="number" or type(data.TrainingMultiplier)~="number" then return false end
 snapshot=data
 ui.Energy.Text="⚡ Energy\n"..number(data.Energy)
 ui.Cash.Text="● Cash\n"..number(data.Cash)
 ui.Rebirths.Text="↻ Rebirths\n"..number(data.Rebirths)
 ui.Multiplier.Text="Trainingsmultiplikator ×"..number(data.TrainingMultiplier)
 ui.Training.Text=if data.SelectedTreadmill==0 then "⚡ TRAINING" else "⚡ +"..number(data.ImpulseGain).." TIPPEN"
 if os.clock()-lastError>3 then
  ui.Status.Text=if data.SelectedTreadmill==0 then "Gehe hinten auf ein Laufband und wähle „Trainieren“." else "Laufband "..data.SelectedTreadmill.." • +"..number(data.ImpulseGain).." automatisch/Sek."
 end
 return true
end
ui.Training.Activated:Connect(function()
 if not snapshot or ui.modalOpen() then return end
 if snapshot.SelectedTreadmill~=0 then send("Click");return end
 ui.dialog("Los geht’s!","Gehe zur Trainingsreihe an der hinteren Inselwand. Stelle dich auf ein Laufband und nutze „Trainieren“. Danach trainierst du automatisch und kannst hier zusätzlich tippen.",nil)
end)
ui.Rebirth.Activated:Connect(function()
 if not snapshot or ui.modalOpen() then return end
 if snapshot.Rebirths>=Config.Numbers.MaxRebirths then ui.dialog("Rebirth", "Das maximale Rebirth-Level ist erreicht.", nil);return end
 if snapshot.Energy<snapshot.RebirthRequirement then
  ui.dialog("Rebirth","Du brauchst "..number(snapshot.RebirthRequirement).." Energy. Dein aktueller Stand: "..number(snapshot.Energy)..".",nil);return
 end
 ui.dialog("Rebirth bestätigen?","Energy wird auf 0 gesetzt. Dein permanenter Multiplikator steigt um +0,5. Ein höheres Laufband kann dadurch wieder gesperrt werden.",function() send("Rebirth") end)
end)
for name,button in pairs(ui.Previews) do
 button.Activated:Connect(function() ui.dialog(name.." • Vorschau","Dieser Bereich kommt in einer späteren Phase. Hier gibt es aktuell keine Käufe, Rennen oder Belohnungen.",nil) end)
end
(remotes:WaitForChild("SnapshotChanged") :: RemoteEvent).OnClientEvent:Connect(render)
local errors={TooFar="Stelle dich auf dein Laufband.",Locked="Energy- oder Rebirth-Anforderung noch nicht erfüllt.",NotReady="Daten momentan nicht bereit.",
 Saving="Daten werden gespeichert – gleich erneut versuchen.",NoTreadmill="Wähle zuerst ein Laufband.",NotEnoughEnergy="Nicht genug Energy für einen Rebirth.",NotAlive="Training pausiert. Bitte erneut auf ein Laufband gehen."}
(remotes:WaitForChild("ActionResult") :: RemoteEvent).OnClientEvent:Connect(function(result)
 if type(result)~="table" then return end
 if not result.Ok and result.Error~="Cooldown" then lastError=os.clock();ui.Status.Text=errors[result.Error] or "Aktion nicht verfügbar." end
end)
task.spawn(function()
 while not snapshot do
  local ok,response=pcall(function() return snapshotRemote:InvokeServer({Version=1}) end)
  if ok and type(response)=="table" and response.Ok then render(response.Data) end
  if not snapshot then task.wait(2) end
 end
end)
-- Server-created prompts display current requirements without creating client permissions.
local training=workspace:WaitForChild("World1"):WaitForChild("Training")
for id=1,5 do
 local zone=training:WaitForChild("Treadmill_"..id):WaitForChild("Zone")
 local prompt=zone:WaitForChild("SelectTraining") :: ProximityPrompt
 local t=Catalog.Treadmills[id]
 prompt.ObjectText="Laufband "..id.." • "..number(t.EnergyRequirement).." Energy ODER "..number(t.RebirthRequirement).." Rebirths"
end
