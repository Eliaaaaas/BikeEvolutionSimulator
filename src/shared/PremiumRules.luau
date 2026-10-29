--!strict
local Config=require(script.Parent.PremiumConfig)
local Numbers=require(script.Parent.Numbers)
local Pets=require(script.Parent.PetRules)
local Rules={}
function Rules.registryValid(config:any):boolean
 for _,group in ipairs({config.Products,config.Passes}) do
  local seen={}
  for _,def in pairs(group) do
   if type(def.Id)~="number" or def.Id%1~=0 or def.Id<0 or def.Id>9007199254740991 then return false end
   if def.Id>0 and seen[def.Id] then return false end
   if def.Id>0 then seen[def.Id]=true end
  end
 end
 return true
end
function Rules.product(id:number):any
 if type(id)~="number" or id%1~=0 or id<=0 then return nil end
 for _,p in pairs(Config.Products) do if p.Id==id then return p end end
 return nil
end
function Rules.bonus(data:any,kind:string,pass:boolean?):number
 return (if pass then 2 else 1)*(if data.Boosts and (data.Boosts[kind] or 0)>0 then 2 else 1)
end
function Rules.grant(data:any,receipt:string,productId:number,definition:any,petId:string):boolean
 if type(receipt)~="string" or #receipt==0 or #receipt>128 or type(productId)~="number" or productId<=0 or productId%1~=0 then return false end
 if data.Receipts[receipt] then return data.Receipts[receipt]==productId end
 local count=0;for _ in pairs(data.Receipts) do count+=1 end
 if count>=Config.ReceiptLimit then return false end
 if definition.Cash then
  if data.Cash>Numbers.Max-definition.Cash then return false end
  local after=Numbers.add(data.Cash,definition.Cash)
  if after-data.Cash~=definition.Cash then return false end
  data.Cash=after
 elseif definition.Boost then
  local current=data.Boosts[definition.Boost]
  if not current or current+definition.Seconds>Config.MaxBoostSeconds then return false end
  data.Boosts[definition.Boost]=current+definition.Seconds
 elseif definition.ExclusiveId then
  local n=0;for _ in pairs(data.Pets) do n+=1 end
  if n>=500 or data.Pets[petId] or #petId==0 or #petId>64 or not Config.Exclusives[definition.ExclusiveId] then return false end
  data.Pets[petId]={SpeciesId=0,ExclusiveId=definition.ExclusiveId,Variant="Normal"};Pets.equipHatched(data,petId)
 else return false end
 data.Receipts[receipt]=productId
 return true
end
return table.freeze(Rules)
