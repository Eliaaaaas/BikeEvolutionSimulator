--!strict
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local RunService=game:GetService("RunService")
local Models=game:GetService("ReplicatedStorage"):WaitForChild("PetModels")
local Followers={}
function Followers.new(settings:any,gui:ScreenGui)
 local entries:any={};local connection:RBXScriptConnection?=nil
 local folder=Instance.new("Folder");folder.Name="LocalPetFollowers";folder.Parent=workspace
 local function clear(entry:any) for _,model in ipairs(entry.Models) do model:Destroy() end;entry.Models={} end
 local function step()
  for player,entry in pairs(entries) do
   local root=if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
   local camera=workspace.CurrentCamera
   if not root or not root:IsA("BasePart") or camera and (root.Position-camera.CFrame.Position).Magnitude>180 then
    for _,model in ipairs(entry.Models) do model.Parent=nil end
    continue
   end
   for i,model in ipairs(entry.Models) do
    model.Parent=folder
    local bob=if settings.Animations then math.sin(os.clock()*2+i)*0.18 else 0
    local cf=root.CFrame*CFrame.new((i-(#entry.Models+1)/2)*2.3,-1.4+bob,3.5)
    model:PivotTo(cf)
   end
  end
 end
 local function sync()
  for _,player in ipairs(Players:GetPlayers()) do
   local raw=player:GetAttribute("PetFollowers") or "[]"
   local entry=entries[player]
   if not entry then entry={Raw=nil,Models={}};entries[player]=entry end
   local root=if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
   local camera=workspace.CurrentCamera
   local visible=root~=nil and root:IsA("BasePart") and (not camera or (root.Position-camera.CFrame.Position).Magnitude<=180)
   if not visible and #entry.Models>0 then clear(entry) end
   if visible and (entry.Raw~=raw or not entry.Visible) then
    clear(entry);entry.Raw=raw
    local ok,pets=pcall(function() return Http:JSONDecode(raw) end)
    if ok and type(pets)=="table" and #pets<=3 then
     for _,pet in ipairs(pets) do
      local source=Models:FindFirstChild("Pet"..tostring(pet.SpeciesId))
      if source and source:IsA("Model") then
       local model=source:Clone()
       for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then
        part.CanCollide=false;part.CanTouch=false;part.Anchored=true
        if pet.Variant=="Golden" and part.Name~="Eye" then part.Color=Color3.fromRGB(255,211,73)
        elseif pet.Variant=="Rainbow" and part.Name~="Eye" then part.Color=Color3.fromHSV((part.Position.Y*0.18)%1,0.65,1) end
       end end
       model.Parent=folder;table.insert(entry.Models,model)
      end
     end
    end
   end
   entry.Visible=visible
  end
  local active=false
  for player,entry in pairs(entries) do
   if player.Parent~=Players then clear(entry);entries[player]=nil elseif #entry.Models>0 then active=true end
  end
  if active and not connection then connection=RunService.PreSimulation:Connect(step)
  elseif not active and connection then connection:Disconnect();connection=nil end
 end
 task.spawn(function() while gui.Parent do sync();task.wait(0.3) end;if connection then connection:Disconnect() end;folder:Destroy() end)
end
return Followers
