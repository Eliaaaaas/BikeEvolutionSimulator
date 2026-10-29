--!strict
-- IDs must be supplied by the experience owner. Zero disables purchase prompts.
local C:any={ReceiptLimit=2000,MaxBoostSeconds=86400,
 Passes={Energy={Id=0,Name="2× Energy",SuggestedRobux=149},Cash={Id=0,Name="2× Cash",SuggestedRobux=149},VIP={Id=0,Name="VIP • zukünftiger Inhalt",SuggestedRobux=399,Unavailable=true}},
 Products={
  Small={Id=0,Name="5.000 Cash",Category="Cash Bundles",Cash=5000,SuggestedRobux=29},
  Medium={Id=0,Name="25.000 Cash",Category="Cash Bundles",Cash=25000,SuggestedRobux=99},
  Large={Id=0,Name="150.000 Cash",Category="Cash Bundles",Cash=150000,SuggestedRobux=299},
  EnergyPotion={Id=0,Name="2× Energy • 5 Minuten",Category="Boost Potions",Boost="Energy",Seconds=300,SuggestedRobux=19},
  CashPotion={Id=0,Name="2× Cash • 5 Minuten",Category="Boost Potions",Boost="Cash",Seconds=300,SuggestedRobux=19},
  PrismRay={Id=0,Name="Prism Ray",Category="Exclusive Pets",ExclusiveId="PrismRay",SuggestedRobux=299},
  Sunfox={Id=0,Name="Solar Sunfox",Category="Exclusive Pets",ExclusiveId="Sunfox",SuggestedRobux=299},
 },
 Exclusives={PrismRay={Name="Prism Ray",Rarity="Exclusive",EnergyMultiplier=2.8,CashMultiplier=3.2,Model="ExclusivePrismRay",Playable=true},Sunfox={Name="Solar Sunfox",Rarity="Exclusive",EnergyMultiplier=3,CashMultiplier=2.8,Model="ExclusiveSunfox",Playable=true}},
}
local function freeze(t:any):any for _,v in pairs(t) do if type(v)=="table" then freeze(v) end end;return table.freeze(t) end
return freeze(C)
