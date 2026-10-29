local count=0
local function test(name,cb) local ok,err=pcall(cb);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
local Access=modules.AutoTraining;local Profile=modules.Profile;local C=modules.Catalog
local all={};for id=1,40 do all[id]=true end
test("V4.5 Auto Train selects strongest currently usable registered belt",function()
 local p=Profile.new();assert(Access.best(p,all,{},false)==1)
 p.Energy=C.Treadmills[5].EnergyRequirement;assert(Access.best(p,all,{},false)==5)
 p.Energy=C.Treadmills[40].EnergyRequirement;assert(Access.best(p,all,{},false)==5)
 p.OwnedWorlds={1,8};assert(Access.best(p,all,{},false)==40)
 assert(Access.best(p,{[1]=true,[5]=true},{},false)==5)
end)
test("V4.5 world AND energy OR rebirth gates survive energy reset and rebirth",function()
 local p=Profile.new();p.Energy=C.Treadmills[5].EnergyRequirement;assert(Access.best(p,all,{},false)==5)
 p.Energy=0;assert(Access.best(p,all,{},false)==1)
 p.Rebirths=1;assert(Access.best(p,all,{},false)==2)
 p.Rebirths=3;assert(Access.best(p,all,{},false)==3)
 p.Rebirths=0;p.Energy=C.Treadmills[6].EnergyRequirement;assert(Access.best(p,all,{},false)==5)
 p.OwnedWorlds={1,2};assert(Access.best(p,all,{},false)==6)
end)
test("V4.5 VIP-only destinations require actual server entitlement",function()
 local p=Profile.new();p.Energy=C.Treadmills[5].EnergyRequirement
 assert(Access.best(p,all,{[5]=true},false)==4)
 assert(Access.best(p,all,{[5]=true},true)==5)
 assert(not Access.allowed(p,5,true,false) and Access.allowed(p,5,true,true))
 p.OwnedWorlds={1};assert(not Access.allowed(p,6,true,true))
end)
test("V4.5 missing worlds and unavailable runtime zones never become teleport targets",function()
 local p=Profile.new();p.Energy=1e100;p.OwnedWorlds={1,2,3,4,5,6,7,8}
 assert(Access.best(p,{}, {},true)==0)
 assert(Access.best(nil,all,{},true)==0)
 assert(Access.best(p,{[5]=false,[2]=true},{},true)==2)
end)
print(count.." V4.5 access tests passed")
