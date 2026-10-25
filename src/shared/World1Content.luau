--!strict
-- All economy numbers below are provisional World-1 balancing, not a 9-hour endgame guarantee.
local C:any={}
C.Vehicles={
 {Name="Mountainbike",Price=0,Speed=1,Model="Mountainbike"},
 {Name="City Bike",Price=250,Speed=1.06,Model="Vehicle2"},
 {Name="BMX",Price=750,Speed=1.12,Model="Vehicle3"},
 {Name="Road Bike",Price=2000,Speed=1.2,Model="Vehicle4"},
 {Name="Racing Bicycle",Price=5000,Speed=1.3,Model="Vehicle5"},
 {Name="Carbon Bike",Price=12000,Speed=1.42,Model="Vehicle6"},
 {Name="Classic Moped",Price=25000,Speed=1.55,Model="Vehicle7"},
 {Name="City Scooter",Price=50000,Speed=1.7,Model="Vehicle8"},
 {Name="Sport Moped",Price=100000,Speed=1.9,Model="Vehicle9"},
 {Name="Racing Moped",Price=200000,Speed=2.1,Model="Vehicle10"},
}
C.Eggs={{Name="Tropical Egg",Price=100},{Name="Jungle Egg",Price=750},{Name="Waterfall Egg",Price=4000}}
C.Pets={
 {Name="Coconut Buddy",Energy=1.1,Cash=1.05},{Name="Sunny Chick",Energy=1.18,Cash=1.1},
 {Name="Beach Turtle",Energy=1.35,Cash=1.18},{Name="Tropical Parrot",Energy=1.6,Cash=1.3},
 {Name="Jungle Monkey",Energy=1.2,Cash=1.12},{Name="Leaf Frog",Energy=1.35,Cash=1.25},
 {Name="Emerald Snake",Energy=1.6,Cash=1.4},{Name="Jungle Tiger",Energy=2,Cash=1.65},
 {Name="Water Sprite",Energy=1.4,Cash=1.3},{Name="Blue Axolotl",Energy=1.65,Cash=1.5},
 {Name="Crystal Fish",Energy=2,Cash=1.8},{Name="Water Dragon",Energy=2.6,Cash=2.2},
}
C.Rarities={"Common","Uncommon","Rare","Legendary"}
C.Weights={5500,2800,1400,300}
C.Difficulties={
 Easy={Speeds={22,24,26,28,30},Rewards={200,150,110,80,60,40}},
 Medium={Speeds={34,37,40,43,46},Rewards={700,500,350,250,180,120}},
 Hard={Speeds={55,59,63,67,71},Rewards={2400,1800,1300,900,650,450}},
}
C.Variants={Normal=1,Golden=2,Rainbow=4}
C.FusionWorlds={Golden=4,Rainbow=5}
local function freeze(t:any):any for _,v in pairs(t) do if type(v)=="table" then freeze(v) end end;return table.freeze(t) end
return freeze(C)
