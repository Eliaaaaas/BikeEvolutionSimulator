--!strict
-- Local station readouts and bounded animations; authoritative checks remain on the server.
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules=require(Shared:WaitForChild("Rules"))
local Catalog=require(Shared:WaitForChild("Catalog"))
local Format=require(Shared:WaitForChild("Format"))
local Stations={}
function Stations.new(settings:any,ui:any)
 local training=workspace:WaitForChild("World1"):WaitForChild("Training")
 local entries:any={}
 for id=1,5 do
  local model=training:WaitForChild("Treadmill_"..id)
  local zone=model:WaitForChild("Zone") :: BasePart
  local board=Instance.new("BillboardGui");board.Name="LocalTrainingStatus";board.Size=UDim2.fromOffset(190,48)
  board.StudsOffset=Vector3.new(0,3.8,0);board.MaxDistance=80;board.AlwaysOnTop=true;board.Adornee=zone;board.Parent=ui.Gui
  local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(20,53,70)
  label.BackgroundTransparency=0.15;label.TextColor3=Color3.fromRGB(240,255,246);label.TextSize=13;label.Font=Enum.Font.GothamBold;label.TextWrapped=true;label.Parent=board
  local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,9);corner.Parent=label
  local stripes={}
  for _,part in ipairs(model:GetChildren()) do if part:IsA("BasePart") and string.find(part.Name,"^BeltStripe_") then table.insert(stripes,{Part=part,Base=part.CFrame}) end end
  entries[id]={Zone=zone,Label=label,Board=board,Stripes=stripes}
 end
 task.spawn(function()
  while ui.Gui.Parent do
   local camera=workspace.CurrentCamera;local now=os.clock();local snap=ui.Snapshot
   local animated=false
   for id,entry in ipairs(entries) do
    local nearby=camera~=nil and (camera.CFrame.Position-entry.Zone.Position).Magnitude<100
    local allowed=snap and Rules.canUseTreadmill(id,snap.Energy,snap.Rebirths,snap.OwnedWorlds or {1})
    local selected=snap and snap.SelectedTreadmill==id
    entry.Label.Text=if not snap then "DATEN LADEN" elseif selected then "TRAINING AKTIV • +"..Format.number(snap.ImpulseGain).." / SEK. + TAPS" elseif allowed then "FREI • BETRETEN / E / TAP" else "GESPERRT • "..Format.number(Catalog.Treadmills[id].EnergyRequirement).." ENERGY ODER "..Format.number(Catalog.Treadmills[id].RebirthRequirement).." REBIRTHS"
    entry.Label.BackgroundColor3=if selected then Color3.fromRGB(20,142,112) elseif allowed then Color3.fromRGB(27,87,110) else Color3.fromRGB(129,65,48)
    for _,stripe in ipairs(entry.Stripes) do
     if nearby and settings.Animations then
      animated=true
      local offset=(stripe.Base.Position.Z-entry.Zone.Position.Z+now*(if selected then 5 else 1.5)+6)%12-6
      stripe.Part.CFrame=CFrame.new(stripe.Base.Position.X,stripe.Base.Position.Y,entry.Zone.Position.Z+offset)
     else stripe.Part.CFrame=stripe.Base end
    end
   end
   task.wait(if animated then 1/15 else 0.3)
  end
  for _,entry in ipairs(entries) do entry.Board:Destroy();for _,stripe in ipairs(entry.Stripes) do if stripe.Part.Parent then stripe.Part.CFrame=stripe.Base end end end
 end)
end
return Stations
