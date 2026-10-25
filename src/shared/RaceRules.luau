--!strict
local Content=require(script.Parent.World1Content)
local PetRules=require(script.Parent.PetRules)
local Numbers=require(script.Parent.Numbers)
local Rules={}
function Rules.position(state:any):number
 local rank=1
 for _,bot in ipairs(state.Bots) do
  if state.FinishedAt then
   if bot.FinishedAt and bot.FinishedAt<=state.FinishedAt then rank+=1 end
  elseif bot.Distance>state.Distance then rank+=1 end
 end
 return rank
end
function Rules.reward(data:any,state:any):number
 local world=Content.RaceWorlds[state.WorldId or 1]
 if not world then return 0 end
 local tier=Content.Difficulties[state.Difficulty]
 if not tier or not state.FinishedAt then return 0 end
 local base=tier.Rewards[state.Place]
 if not base then return 0 end
 return Numbers.multiply(Numbers.multiply(base,world.RewardMultiplier),PetRules.bonus(data,"Cash"))
end
function Rules.pay(data:any,state:any): (boolean,number)
 if type(state.RewardId)~="string" or #state.RewardId==0 or #state.RewardId>100 then return false,0 end
 local amount=Rules.reward(data,state)
 if amount<=0 then return false,0 end
 if data.LastRaceReward==state.RewardId then return true,0 end
 local before=data.Cash
 data.Cash=Numbers.add(before,amount);data.LastRaceReward=state.RewardId
 -- At the finite currency cap, report only what was actually credited.
 return true,data.Cash-before
end
return table.freeze(Rules)
