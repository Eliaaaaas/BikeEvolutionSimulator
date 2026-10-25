-- Runs the unchanged PlayerDataService with deterministic Roblox service/task doubles.
local function environment()
 local now, queue, serial, close = 1000, {}, 0, nil
 local store = {records={},failures=0,calls=0,delay=0}
 local function copy(value)
  if type(value)~="table" then return value end
  local result={};for key,item in pairs(value) do result[key]=copy(item) end;return result
 end
 local tasks={}
 function tasks.spawn(callback,...)
  local args=table.pack(...)
  table.insert(queue,{at=now,co=coroutine.create(function() callback(table.unpack(args,1,args.n)) end)})
 end
 function tasks.wait(seconds) return coroutine.yield(seconds or 0.01) end
 local function advance(seconds)
  local target=now+seconds
  while true do
   table.sort(queue,function(a,b) return a.at<b.at end)
   local item=queue[1];if not item or item.at>target then break end
   table.remove(queue,1);now=item.at
   local ok,delay=coroutine.resume(item.co);assert(ok,tostring(delay))
   if coroutine.status(item.co)~="dead" then item.at=now+delay;table.insert(queue,item) end
  end
  now=target
 end
 local function signal()
  local callbacks={}
  return {Connect=function(_,cb) table.insert(callbacks,cb) end,
   Fire=function(_,...) for _,cb in ipairs(callbacks) do tasks.spawn(cb,...) end end}
 end
 local players={PlayerAdded=signal(),PlayerRemoving=signal()}
 function players:GetPlayers() return {} end
 function store:UpdateAsync(key,callback)
  self.calls+=1
  if self.delay>0 then tasks.wait(self.delay) end
  if self.failures>0 then self.failures-=1;error("injected unavailable") end
  local result=callback(copy(self.records[key]))
  if result then self.records[key]=copy(result) end
  return copy(result)
 end
 local shared={WaitForChild=function() return {} end}
 local services={Players=players,ReplicatedStorage={WaitForChild=function() return shared end},
  DataStoreService={GetDataStore=function() return store end},
  HttpService={GenerateGUID=function() serial+=1;return tostring(serial) end,JSONEncode=function() return "log" end}}
 local game={JobId="test-job",GetService=function(_,name) return services[name] end,
  BindToClose=function(_,callback) close=callback end}
 local service=modules.makeService(game,tasks,{time=function() return math.floor(now) end,clock=function() return now end},function() end)
 service.start()
 local function join()
  local player={UserId=7,Parent=players,Kicks=0,Kick=function(self) self.Kicks+=1 end}
  players.PlayerAdded:Fire(player);advance(0);return player
 end
 local function leave(player) player.Parent=nil;players.PlayerRemoving:Fire(player);advance(0) end
 return {store=store,service=service,join=join,leave=leave,advance=advance,shutdown=function() tasks.spawn(close);advance(0) end}
end
local count=0
local function test(name,callback)
 local ok,reason=pcall(callback);assert(ok,name..": "..tostring(reason));count+=1;print("PASS "..name)
end
test("PlayerRemoving retries failed save, then reconnect loads durable profile",function()
 local e=environment();local p=e.join();assert(e.service.snapshot(p))
 e.store.failures=3;e.leave(p);e.advance(9)
 assert(e.store.records.Player_7.Lock==nil)
 local fresh=e.join();assert(e.service.snapshot(fresh));assert(fresh.Kicks==0)
end)
test("autosave and disconnect serialize while storage yields",function()
 local e=environment();local p=e.join();e.store.delay=2
 e.advance(60);e.leave(p);e.advance(6)
 assert(e.store.records.Player_7.Lock==nil)
 assert(e.service.snapshot(p)==nil)
end)
test("failed autosave keeps loaded session and renews on next cycle",function()
 local e=environment();local p=e.join();e.store.failures=3
 e.advance(67);assert(e.service.snapshot(p));e.advance(55)
 assert(e.store.records.Player_7.Lock.Expires>=1300)
end)
test("BindToClose waits for in-flight disconnect recovery",function()
 local e=environment();local p=e.join();e.store.failures=3
 e.leave(p);e.shutdown();e.advance(10)
 assert(e.store.records.Player_7.Lock==nil)
end)
test("reconnect during persistent outage cannot replace original profile",function()
 local e=environment();local p=e.join();local original=e.store.records.Player_7.Lock.Id
 e.store.failures=100;e.leave(p);local fresh=e.join();e.advance(10)
 assert(fresh.Kicks==1);assert(e.service.snapshot(fresh)==nil)
 assert(e.store.records.Player_7.Lock.Id==original)
end)
test("shutdown includes a load that completes after BindToClose starts",function()
 local e=environment();e.store.delay=2
 local p=e.join();assert(e.service.snapshot(p)==nil)
 e.shutdown();e.advance(6)
 assert(e.store.records.Player_7.Lock==nil);assert(e.service.snapshot(p)==nil)
end)
test("training and rebirth persist across disconnect/rejoin without changing cash",function()
 local e=environment();local p=e.join();local now=1000
 assert(e.service.change(p,function(data) data.Cash=77;return true end))
 local controller=modules.TrainingController.new(e.service,function() return now end,function() return true end)
 assert(controller:select(p,1));assert(controller:impulse(p,true));assert(e.service.snapshot(p).Energy==1)
 now+=1;e.advance(1);controller:tick();assert(e.service.snapshot(p).Energy==2)
 assert(e.service.change(p,function(data) data.Energy=1000;return true end))
 assert(controller:rebirth(p));assert(e.service.snapshot(p).Energy==0);assert(e.service.snapshot(p).Rebirths==1)
 e.leave(p);local fresh=e.join();local snapshot=e.service.snapshot(fresh)
 assert(snapshot.Energy==0 and snapshot.Rebirths==1 and snapshot.Cash==77)
 assert(e.service.change(fresh,function(data) data.Energy=3.5;return true end))
 e.leave(fresh);local third=e.join();assert(e.service.snapshot(third).Energy==3.5)
end)
test("transactions during yielding autosave are rejected and retry safely",function()
 local e=environment();local p=e.join();e.store.delay=2;e.advance(60)
 local ok,reason=e.service.change(p,function(data) data.Energy=10;return true end)
 assert(not ok and reason=="Saving");assert(e.service.snapshot(p).Energy==0)
 e.advance(2);assert(e.service.change(p,function(data) data.Energy=10;return true end))
 e.leave(p);e.advance(2);local fresh=e.join();e.advance(2);assert(e.service.snapshot(fresh).Energy==10)
end)
test("invalid transactions cannot partially overwrite live state",function()
 local e=environment();local p=e.join()
 assert(not e.service.change(p,function(data) data.Energy=999;data.Rebirths=-1;return true end))
 assert(e.service.snapshot(p).Energy==0)
 assert(not e.service.change(p,function(data) data.Energy=999;error("injected failure") end))
 assert(e.service.snapshot(p).Energy==0)
 e.shutdown();assert(not e.service.change(p,function() return true end))
end)
print(string.format("%d lifecycle tests passed",count))
