--!strict
local Content=require(script.Parent.World1Content)
local Catalog=require(script.Parent.Catalog)
local Numbers=require(script.Parent.Numbers)
local Pets={}
function Pets.bonus(data:any,kind:string):number
 local total=1
 for _,id in ipairs(data.EquippedPets) do
  local pet=data.Pets[id];local definition=if pet then Catalog.Pets[pet.SpeciesId] else nil
  if definition and definition.Playable then
   local base=if kind=="Energy" then definition.EnergyMultiplier else definition.CashMultiplier
   total=Numbers.add(total,Numbers.multiply(base-1,Content.Variants[pet.Variant] or 1))
  end
 end
 return total
end
function Pets.roll(eggId:number,roll:number):number?
 local egg=Catalog.Eggs[eggId]
 if not egg or not egg.Playable or roll%1~=0 or roll<1 or roll>10000 then return nil end
 local sum=0
 for i,weight in ipairs(egg.Weights :: {number}) do sum+=weight;if roll<=sum then return egg.Species[i] end end
 return nil
end
return table.freeze(Pets)
