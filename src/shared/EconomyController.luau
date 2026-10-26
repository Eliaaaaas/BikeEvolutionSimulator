--!strict
local Catalog=require(script.Parent.Catalog)
local Content=require(script.Parent.World1Content)
local PetRules=require(script.Parent.PetRules)
local Config=require(script.Parent.Config)
local Numbers=require(script.Parent.Numbers)
local E:any={};E.__index=E
function E.new(data:any,clock:()->number,random:()->number,guid:()->string,feedback:(any,any)->(),log:((any,string,string)->())?):any
 return setmetatable({Data=data,Clock=clock,Random=random,Guid=guid,Feedback=feedback,Log=log or function() end,Requests={},LastHatch={}},E)
end
function E.handle(self:any,player:any,payload:any): (boolean,string?)
 if type(payload)~="table" or type(payload.RequestId)~="number" or not Numbers.validRebirth(payload.RequestId) or payload.RequestId<1 then return false,"BadRequest" end
 if payload.RequestId<=(self.Requests[player] or 0) then return false,"DuplicateRequest" end
 self.Requests[player]=payload.RequestId
 local kind=payload.Action
 if kind=="Hatch" and self.Clock()-(self.LastHatch[player] or -math.huge)<1 then return false,"Cooldown" end
 if kind=="Hatch" then self.LastHatch[player]=self.Clock() end
 local result:any=nil
 local rejection="Unavailable"
 local species,instanceId=nil,nil
 if kind=="Hatch" then
  local generated,roll,id=pcall(function() return self.Random(),self.Guid() end)
  if not generated or type(roll)~="number" or type(id)~="string" or #id<1 or #id>64 then self.Log(player,"HatchGenerationFailed",if generated then "InvalidResult" else tostring(roll));return false,"ServiceUnavailable" end
  species=PetRules.roll(payload.EggId,roll);instanceId=id
  if not species then self.Log(player,"HatchGenerationFailed","InvalidRoll");return false,"ServiceUnavailable" end
 end
 local ok,reason=self.Data.change(player,function(data:any):boolean
  if kind=="BuyVehicle" then
   local v=Catalog.Vehicles[payload.VehicleId]
   if not v or not v.Playable or table.find(data.OwnedVehicles,payload.VehicleId) then rejection="AlreadyOwned";return false end
   if data.Cash<v.CashCost then rejection="NotEnoughCash";return false end
   data.Cash-=v.CashCost;table.insert(data.OwnedVehicles,payload.VehicleId)
  elseif kind=="EquipVehicle" then
   if not table.find(data.OwnedVehicles,payload.VehicleId) or not Content.Vehicles[payload.VehicleId] then return false end
   data.ActiveVehicle=payload.VehicleId
  elseif kind=="Hatch" then
   local egg=Catalog.Eggs[payload.EggId]
   if not egg or not egg.Playable or not table.find(data.OwnedWorlds,egg.WorldId) then return false end
   local count=0;for _ in pairs(data.Pets) do count+=1 end
   if count>=Config.Data.MaxPets then rejection="InventoryFull";return false end
   if data.Cash<egg.CashCost then rejection="NotEnoughCash";return false end
   if not species or not instanceId or data.Pets[instanceId] then return false end
   data.Cash-=egg.CashCost;data.Pets[instanceId]={SpeciesId=species,Variant="Normal"}
   if not table.find(data.DiscoveredPets,species) then table.insert(data.DiscoveredPets,species) end
   PetRules.equipHatched(data,instanceId)
   result={Kind="Hatched",SpeciesId=species,PetId=instanceId,EggId=payload.EggId}
  elseif kind=="EquipPet" then
   if not PetRules.stats(data.Pets[payload.PetId]) then rejection="PetUnavailable";return false end
   if table.find(data.EquippedPets,payload.PetId) then return false end
   if #data.EquippedPets>=Config.Rules.EquipSlots then rejection="EquipLimit";return false end
   table.insert(data.EquippedPets,payload.PetId)
  elseif kind=="EquipBest" or kind=="UnequipAll" then
   data.EquippedPets=if kind=="EquipBest" then PetRules.best(data) else {}
   result={Kind="PetEquipmentChanged",Action=kind,EquippedCount=#data.EquippedPets}
  elseif kind=="UnequipPet" then
   local index=table.find(data.EquippedPets,payload.PetId);if not index then return false end
   table.remove(data.EquippedPets,index)
  else return false end
  return true
 end,true)
 if ok then self.Feedback(player,result or {Kind="Purchase",Action=kind}) end
 return ok,if reason=="Rejected" then rejection else reason
end
function E.remove(self:any,player:any) self.Requests[player]=nil;self.LastHatch[player]=nil end
return E
