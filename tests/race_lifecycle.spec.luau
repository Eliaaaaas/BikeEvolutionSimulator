-- Actual RaceService and BikeRig executed against lightweight engine doubles.
-- CFrame doubles model translation only; curve math is tested separately, real physics needs Studio.
local function fixture()
 local e=modules.runtimeEngine();modules.populateWorld(e.add,e.Workspace,e.Rep)
 e.Player.Parent=e.Players
 local profile=modules.Profile.new();profile.Energy=500;profile.Cash=75
 local data={change=function(_,cb) return cb(profile),nil end,snapshot=function() return table.clone(profile) end,read=function() return modules.Profile.copy(profile) end,inventoryRevision=function() return 0 end,ownsVehicle=function(_,id) return id==1 end}
 local old=modules.BikeRig;modules.BikeRig=modules.makeBikeRig(e.Instance)
 local mounts=modules.make_MountedBikeService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum,e.RaycastParams).new(data)
 mounts.start();e.advance(0)
 e.Root.CFrame=e.CFrame.new(0,12.85,63)
 local race=modules.makeRaceService(e.Game,e.Workspace,e.Task,e.OS,e.Warn,e.Instance,e.CFrame,e.Vector3,e.Enum)
 local events={};local api=race.new(data,function() end,function(_,event) table.insert(events,event) end,mounts)
 api.run();modules.BikeRig=old
 return {api=api,player=e.Player,hum=e.Player.Character:FindFirstChildOfClass("Humanoid"),root=e.Root,data=profile,workspace=e.Workspace,events=events,advance=e.advance,shutdown=function() for _,cb in ipairs(e.Closes) do cb() end end}
end

local count=0
local function test(name,callback) local ok,err=pcall(callback);assert(ok,name..": "..tostring(err));count+=1;print("PASS "..name) end
test("real bike rig assembly creates five motors and one permanent rider weld",function()
 local e=fixture();assert(e.api.start(e.player));local folder=e.workspace:FindFirstChild("ActiveRaceBikes");local bike=e.workspace.PlayerBikes:GetChildren()[1]
 local motors=0
 for _,n in ipairs(bike:GetDescendants()) do if n:IsA("Motor6D") then motors+=1;assert(n.Part0 and n.Part1) end end
 assert(motors==5 and not bike.PrimaryPart.Anchored);assert(e.root.Anchored and e.hum.WalkSpeed==0)
 e.api.abort(e.player);assert(#folder:GetChildren()==0 and e.root.Anchored and e.hum.WalkSpeed==0 and not e.hum.AutoRotate and e.hum.PlatformStand and e.hum.Sit)
 assert(math.abs(e.root.Position.Z-50.9)<1e-6 and math.abs(e.root.Position.Y-12.85)<1e-6 and e.player:GetAttribute("Racing")==false)
end)
test("actual finish restores manual mounted control and never mutates currency",function()
 local e=fixture();assert(e.api.start(e.player))
 for _=1,700 do e.advance(0.1) end
 assert(not e.api.active(e.player));assert(e.events[#e.events].Reason=="Finished")
 assert(e.hum.WalkSpeed==0 and e.root.Anchored and e.hum.Sit and e.data.Energy==500 and e.data.Cash==75)
 assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==0)
end)
test("technical root removal still restores humanoid controls and clears bike",function()
 local e=fixture();assert(e.api.start(e.player));e.root:Destroy();e.advance(0.1)
 assert(not e.api.active(e.player));assert(e.hum.WalkSpeed==0 and not e.hum.AutoRotate and e.hum.PlatformStand and e.player.Respawns==1)
 assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==0)
end)
test("shutdown cleanup keeps the permanent rider mount",function()
 local e=fixture();assert(e.api.start(e.player));e.shutdown()
 assert(not e.api.active(e.player));assert(e.root.Anchored and e.hum.WalkSpeed==0)
end)
test("real Easy race creates five opponents and pays a validated finish once",function()
 local e=fixture();assert(e.api.start(e.player,"Easy"));assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==5)
 assert(e.api.snapshot(e.player).Opponents==5)
 for _=1,700 do e.advance(0.1) end
 assert(not e.api.active(e.player));local result=e.events[#e.events]
 assert(result.Reason=="Finished" and result.Place>=1 and result.Place<=6)
 assert(e.data.Cash==75+modules.World1Content.Difficulties.Easy.Rewards[result.Place] and e.data.Energy==500)
 local cash=e.data.Cash;for _=1,20 do e.advance(0.1) end;assert(e.data.Cash==cash)
 assert(#e.workspace:FindFirstChild("ActiveRaceBikes"):GetChildren()==0)
end)
print(string.format("%d race adapter tests passed",count))
