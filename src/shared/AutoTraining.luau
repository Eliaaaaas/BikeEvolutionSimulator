--!strict
local Catalog=require(script.Parent.Catalog)
local Rules=require(script.Parent.Rules)
local Access={}
function Access.allowed(profile:any,id:number,vipOnly:boolean,vip:boolean):boolean
 return profile~=nil and Rules.canUseTreadmill(id,profile.Energy,profile.Rebirths,profile.OwnedWorlds) and (not vipOnly or vip)
end
function Access.best(profile:any,available:{[number]:boolean},restricted:{[number]:boolean},vip:boolean):number
 local best=0;local power=0
 if not profile then return 0 end
 for id,definition in ipairs(Catalog.Treadmills) do
  if available[id] and Access.allowed(profile,id,restricted[id]==true or definition.VIPOnly==true,vip) and definition.TrainingMultiplier>power then
   best=id;power=definition.TrainingMultiplier
  end
 end
 return best
end
return table.freeze(Access)
