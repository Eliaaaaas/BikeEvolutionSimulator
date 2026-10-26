--!strict
local Config=require(script.Parent.Config)
local Tap={};Tap.__index=Tap
function Tap.new(clock:()->number):any return setmetatable({Clock=clock,Last=-math.huge,Touch=-math.huge},Tap) end
function Tap.accept(self:any,kind:string,processed:boolean,snapshot:any,menuOpen:boolean):boolean
 local now=self.Clock()
 if kind=="Touch" then self.Touch=now
 elseif kind~="Mouse" or now-self.Touch<0.35 then return false end
 if processed or menuOpen or not snapshot or (snapshot.SelectedTreadmill or 0)==0 or snapshot.Race and snapshot.Race.Phase~="Idle" then return false end
 if now-self.Last<Config.Training.ClickCooldown then return false end
 self.Last=now;return true
end
return Tap
