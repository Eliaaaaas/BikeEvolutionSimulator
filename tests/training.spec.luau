local count=0
local function test(name,callback)
 local ok,reason=pcall(callback);assert(ok,name..": "..tostring(reason));count+=1;print("PASS "..name)
end
local function fixture()
 local now=1000
 local data=modules.Profile.new()
 local ready,close=true,true
 local service={}
 function service.change(_,callback)
  if not ready then return false,"NotReady" end
  local candidate=modules.Profile.copy(data)
  if not callback(candidate) then return false,"Rejected" end
  assert(modules.Profile.validate(candidate));data=candidate;return true,nil
 end
 local controller=modules.TrainingController.new(service,function() return now end,function() return close end)
 return controller,function() return data end,function(t) now+=t end,
  function(value) close=value end,function(value) ready=value end,
  function(energy,rebirths,worlds) data.Energy=energy;data.Rebirths=rebirths or 0;data.OwnedWorlds=worlds or {1} end
end
test("auto cadence and independent click impulses",function()
 local c,get,advance=fixture();assert(c:select("p",1));c:tick();assert(get().Energy==0)
 advance(1);c:tick();assert(get().Energy==1)
 c:tick();assert(get().Energy==1)
 assert(c:impulse("p",true));assert(get().Energy==2)
 assert(not c:impulse("p",true));advance(0.21);assert(c:impulse("p",true));assert(get().Energy==3)
 advance(10);c:tick();assert(get().Energy==4) -- no catch-up after a delayed server frame
end)
test("first five treadmill strengths and rebirth multiplier",function()
 for id,gain in ipairs({1,2,4,8,16}) do
  local c,get,_,_,_,seed=fixture();seed(10000,0);assert(c:select("p",id));assert(c:impulse("p",true));assert(get().Energy==10000+gain)
  local d,get2,_,_,_,seed2=fixture();seed2(10000,1);assert(d:select("p",id));assert(d:impulse("p",true));assert(get2().Energy==10000+gain*1.5)
 end
end)
test("locked treadmill, wrong world and non-phase2 IDs denied",function()
 local c,get,_,_,_,seed=fixture()
 assert(not c:select("p",5));assert(c:selection("p")==0);assert(get().Energy==0)
 local d=fixture();assert(not d:select("p",6))
 local e,_,_,_,_,set=fixture();set(1e6,0,{2});assert(not e:select("p",1))
 seed(0,3); -- permission uses rebirth OR energy
 local f,_,_,_,_,set2=fixture();set2(0,3);assert(f:select("p",3))
end)
test("switching treadmills never resets click cooldown",function()
 local c,get,advance,_,_,seed=fixture();seed(10000,0)
 assert(c:select("p",1));advance(0.5);assert(c:select("p",2));assert(c:impulse("p",true))
 advance(0.1);assert(not c:impulse("p",true));assert(get().Energy==10002)
end)
test("walking away/death stops auto and click without a reward",function()
 local c,get,advance,near=fixture();assert(c:select("p",1));near(false);advance(1)
 c:tick();assert(get().Energy==0);assert(c:selection("p")==0);assert(not c:impulse("p",true))
end)
test("revalidating each impulse prevents stale access",function()
 local c,get,_,_,_,seed=fixture();seed(10000,0);assert(c:select("p",5));seed(0,0)
 assert(not c:impulse("p",true));assert(get().Energy==0);assert(c:selection("p")==0)
end)
test("rebirth is atomic, zeroes energy and revokes higher treadmill",function()
 local c,get,advance,_,_,seed=fixture();seed(10000,0);assert(c:select("p",5))
 assert(c:rebirth("p"));assert(get().Energy==0 and get().Rebirths==1);assert(c:selection("p")==0)
 assert(not c:rebirth("p"));advance(1.1);assert(not c:rebirth("p"));assert(get().Rebirths==1)
end)
test("no training before selection or while data unavailable",function()
 local c,get,advance,_,ready=fixture();assert(not c:impulse("p",true));assert(c:select("p",1))
 ready(false);advance(1);c:tick();assert(not c:impulse("p",true));assert(get().Energy==0)
end)
test("stopping and player cleanup prevent further automatic rewards",function()
 local c,get,advance=fixture();assert(c:select("p",1));c:stop("p");advance(2);c:tick();assert(get().Energy==0)
 c:remove("p");assert(c.States.p==nil)
end)
test("exact belt bounds reject remote positions and invalid transforms",function()
 local near=modules.Rules.withinTrainingZone
 assert(near(0,3,0,8,12));assert(near(5,6,7,8,12))
 assert(not near(5.01,3,0,8,12));assert(not near(0,6.1,0,8,12));assert(not near(0,3,7.1,8,12))
 assert(not near(0/0,3,0,8,12));assert(not near(0,math.huge,0,8,12))
end)
test("strict action allowlist rejects amount, foreign identity and nonfinite IDs",function()
 local valid=modules.Protocol.validAction
 assert(valid({Version=1,Action="Select",TreadmillId=1}));assert(valid({Version=1,Action="Click"}))
 assert(valid({Version=1,Action="Rebirth"}));assert(valid({Version=1,Action="Stop"}))
 for _,payload in ipairs({{Version=1,Action="Click",Energy=1000},{Version=1,Action="Click",UserId=7},
 {Version=1,Action="Select",TreadmillId=0/0},{Version=1,Action="Select",TreadmillId=6},
 {Version=2,Action="Click"},{Version=1,Action="Rebirth",TreadmillId=1},{Version=1,Action="Buy"}}) do assert(not valid(payload)) end
 assert(not valid("bad"));assert(not valid(nil))
end)
test("shared token bucket bounds remote/prompt bursts and refills",function()
 local now=0;local gate=modules.RateLimiter.new(12,8,function() return now end)
 for _=1,12 do assert(gate:allow("p")) end
 for _=1,1000 do assert(not gate:allow("p")) end
 assert(gate:allow("other"));now=0.125;assert(gate:allow("p"));assert(not gate:allow("p"))
 now=100;for _=1,12 do assert(gate:allow("p")) end;assert(not gate:allow("p"))
 gate:remove("p");assert(gate.Buckets.p==nil)
end)
print(string.format("%d training/security tests passed",count))
