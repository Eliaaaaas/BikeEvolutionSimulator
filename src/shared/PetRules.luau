--!strict
local Content=require(script.Parent.World1Content)
local Catalog=require(script.Parent.Catalog)
local Numbers=require(script.Parent.Numbers)
local Config=require(script.Parent.Config)
local Rules=require(script.Parent.Rules)
local Premium=require(script.Parent.PremiumConfig)
local Pets={}
function Pets.definition(pet:any):any
 return if pet.ExclusiveId then Premium.Exclusives[pet.ExclusiveId] else Catalog.Pets[pet.SpeciesId]
end
type Candidate={Id:string,Score:number,EquippedRank:number}
-- A pending catalogue species is locked, not an invented balancing value.
function Pets.stats(pet:any):{Energy:number,Cash:number,Score:number}?
 if type(pet)~="table" or type(pet.SpeciesId)~="number" or pet.SpeciesId%1~=0 then return nil end
 local definition=Pets.definition(pet)
 local factor=Content.Variants[pet.Variant]
 if not definition or not definition.Playable or not factor then return nil end
 local energy=Numbers.add(1,Numbers.multiply(definition.EnergyMultiplier-1,factor))
 local cash=Numbers.add(1,Numbers.multiply(definition.CashMultiplier-1,factor))
 return {Energy=energy,Cash=cash,Score=Numbers.add((energy-1)/2,(cash-1)/2)}
end
function Pets.bonus(data:any,kind:string):number
 local total=1
 for _,id in ipairs(data.EquippedPets) do
  local stats=Pets.stats(data.Pets[id])
  if stats then total=Numbers.add(total,(if kind=="Energy" then stats.Energy else stats.Cash)-1) end
 end
 return total
end
function Pets.best(data:any):{string}
 local candidates:{Candidate}={}
 for id,pet in pairs(data.Pets) do
  local stats=Pets.stats(pet)
  if stats then table.insert(candidates,{Id=id,Score=stats.Score,EquippedRank=table.find(data.EquippedPets,id) or Config.Rules.EquipSlots+1}) end
 end
 table.sort(candidates,function(a:Candidate,b:Candidate):boolean
  if a.Score~=b.Score then return a.Score>b.Score end
  if a.EquippedRank~=b.EquippedRank then return a.EquippedRank<b.EquippedRank end
  return a.Id<b.Id
 end)
 local ids={}
 for i=1,math.min(Config.Rules.EquipSlots,#candidates) do table.insert(ids,candidates[i].Id) end
 return ids
end
-- Only called inside the same transaction that grants a genuinely new hatch.
function Pets.equipHatched(data:any,id:string):boolean
 if #data.EquippedPets>=Config.Rules.EquipSlots or table.find(data.EquippedPets,id) or not Pets.stats(data.Pets[id]) then return false end
 table.insert(data.EquippedPets,id);return true
end
-- Server-only integration helper for the existing future fusion recipes; no new machine/remote.
-- Invoke on a transaction candidate with InventoryRevision incremented, never on live shared data.
function Pets.fuse(data:any,ids:{string},newId:string):boolean
 if type(newId)~="string" or #newId<1 or #newId>64 or data.Pets[newId] then return false end
 local result=Rules.fusion(data.Pets,ids)
 if not result or not Pets.stats(result) or not table.find(data.OwnedWorlds,Content.FusionWorlds[result.Variant]) then return false end
 local consumed:{[string]:boolean}={};for _,id in ipairs(ids) do consumed[id]=true end
 local equipped={};local replacement=false
 for _,id in ipairs(data.EquippedPets) do
  if consumed[id] then
   if not replacement then table.insert(equipped,newId);replacement=true end
  else table.insert(equipped,id) end
 end
 for _,id in ipairs(ids) do data.Pets[id]=nil end
 data.Pets[newId]=result;data.EquippedPets=equipped
 return true
end
function Pets.roll(eggId:number,roll:number):number?
 local egg=Catalog.Eggs[eggId]
 if not egg or not egg.Playable or roll%1~=0 or roll<1 or roll>10000 then return nil end
 local sum=0
 for i,weight in ipairs(egg.Weights :: {number}) do sum+=weight;if roll<=sum then return egg.Species[i] end end
 return nil
end
return table.freeze(Pets)
