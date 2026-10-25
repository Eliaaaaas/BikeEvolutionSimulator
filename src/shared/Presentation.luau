--!strict
local Catalog=require(script.Parent.Catalog)
local Rules=require(script.Parent.Rules)
local Config=require(script.Parent.Config)
local P={}
function P.training(snapshot: any): any
 local selected=snapshot.SelectedTreadmill or 0
 local nextId=if selected==0 then 1 else selected+1
 local nextT=Catalog.Treadmills[nextId]
 if nextId>5 then return {Current=selected,Gain=snapshot.ImpulseGain or 0,Complete=true,Ratio=1,Missing=0,Next=0,RebirthRequirement=0} end
 local rebirthReady=snapshot.Rebirths>=nextT.RebirthRequirement
 return {Current=selected,Gain=snapshot.ImpulseGain or 0,Complete=false,Next=nextId,
  Missing=math.max(0,nextT.EnergyRequirement-snapshot.Energy),RebirthRequirement=nextT.RebirthRequirement,
  Ratio=if rebirthReady or nextT.EnergyRequirement==0 then 1 else math.clamp(snapshot.Energy/nextT.EnergyRequirement,0,1)}
end
function P.rebirth(snapshot: any): any
 local requirement=Rules.rebirthRequirement(snapshot.Rebirths)
 return {Current=snapshot.Rebirths,Multiplier=Rules.trainingGain(snapshot.Rebirths),NextMultiplier=Rules.trainingGain(snapshot.Rebirths)+0.5,
  Requirement=requirement,Ratio=math.clamp(snapshot.Energy/requirement,0,1),Allowed=snapshot.Rebirths<Config.Numbers.MaxRebirths and snapshot.Energy>=requirement}
end
return table.freeze(P)
