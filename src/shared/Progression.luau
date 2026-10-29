--!strict
local Config=require(script.Parent.Config)
local Numbers=require(script.Parent.Numbers)
local P={}
-- Fourfold difficulty is applied ONCE, not exponentially to an already exponential curve.
-- Growing per-tier dwell time, matched to doubling training output. Baseline 9.55h to belt 40.
function P.energy(id:number):number
 if id==1 then return 0 end
 return Numbers.multiply(Config.Treadmills.Difficulty,Numbers.multiply(Config.Treadmills.EnergyBase,Numbers.multiply(id-1,Numbers.power(2,id-2))))
end
function P.islandSpeed(energy:number,vehicle:number,slow:boolean):number
 if not Numbers.valid(energy) or not Numbers.valid(vehicle) then return Config.Bike.BaseSpeed end
 local speed=math.min(Config.Bike.MaxSpeed,(Config.Bike.BaseSpeed+math.min(14,math.log10(1+energy)*2.2))*math.sqrt(vehicle))
 return if slow then math.min(12,speed) else speed
end
return table.freeze(P)
