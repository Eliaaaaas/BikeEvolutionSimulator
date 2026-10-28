--!strict
local Config=require(script.Parent.Config)
local Sim=require(script.Parent.RideSimulation)
local Reconcile={}
function Reconcile.new():any return {Epoch=0,Ack=0,Sequence=0,Pending={},State=nil} end
function Reconcile.command(r:any,sequence:number,input:any,maxSpeed:number,scene:any)
 if not r.State then return end
 table.insert(r.Pending,{Sequence=sequence,Input=table.clone(input)})
 if #r.Pending>Config.Bike.PendingLimit then table.remove(r.Pending,1) end
 r.State=Sim.command(r.State,input,maxSpeed,scene)
end
function Reconcile.valid(message:any):boolean
 if type(message)~="table" or not Sim.valid(message.State) or type(message.Epoch)~="number" or message.Epoch%1~=0 or message.Epoch<1 or type(message.Ack)~="number" or message.Ack%1~=0 or message.Ack<1 or type(message.Sequence)~="number" or message.Sequence%1~=0 or message.Sequence<0 or type(message.MaxSpeed)~="number" or message.MaxSpeed<1 or message.MaxSpeed>Config.Bike.MaxSpeed then return false end
 return message.Mode=="Manual" or message.Mode=="Race"
end
function Reconcile.accept(r:any,message:any,scene:any):boolean
 if not Reconcile.valid(message) then return false end
 if message.Epoch<r.Epoch or message.Epoch==r.Epoch and (message.Ack<=r.Ack or message.Sequence<r.Sequence) then return false end
 if message.Epoch~=r.Epoch then r.Pending={} end
 r.Epoch=message.Epoch;r.Ack=message.Ack;r.Sequence=message.Sequence
 local pending={};local state=table.clone(message.State)
 for _,command in ipairs(r.Pending) do
  if command.Sequence>message.Sequence then table.insert(pending,command);state=Sim.command(state,command.Input,message.MaxSpeed,scene) end
 end
 r.Pending=pending;r.State=state
 return true
end
return table.freeze(Reconcile)
