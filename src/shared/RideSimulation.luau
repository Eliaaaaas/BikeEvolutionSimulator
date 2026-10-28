--!strict
-- Shared deterministic kinematics. Only server state grants access, rewards or training.
local Config=require(script.Parent.Config)
local Motion=require(script.Parent.BikeMotion)
local Sim={}
export type State={X:number,Y:number,Z:number,Yaw:number,Speed:number,VY:number,Grounded:boolean,JumpId:number,JumpCooldown:number,Distance:number}
function Sim.new(x:number,y:number,z:number,yaw:number):State
 return {X=x,Y=y,Z=z,Yaw=yaw,Speed=0,VY=0,Grounded=true,JumpId=0,JumpCooldown=0,Distance=0}
end
function Sim.step(old:State,input:any,dt:number,maxSpeed:number,scene:any):State
 local s:State=table.clone(old);local cfg=Config.Bike
 dt=math.clamp(dt,0,cfg.Tick)
 local motion=Motion.step(s.Speed,s.Yaw,input.Throttle,input.Steer,input.Brake,dt,maxSpeed)
 s.Speed=motion.Speed;s.Yaw=motion.Yaw;s.JumpCooldown=math.max(0,s.JumpCooldown-dt)
 local floor=scene.floor(s.X,s.Y,s.Z)
 local contact=floor~=nil and math.abs(s.Y-(floor+.05))<=cfg.GroundTolerance
 if s.Grounded and not contact then s.Grounded=false end
 local jump=input.JumpId or 0
 if jump>s.JumpId then
  s.JumpId=jump
  if s.Grounded and contact and s.JumpCooldown==0 then
   s.VY=cfg.JumpVelocity;s.Grounded=false;s.JumpCooldown=cfg.JumpCooldown
  end
 end
 local x,z=s.X+motion.DX,s.Z+motion.DZ
 local nextFloor,normal=scene.floor(x,s.Y,z)
 local supported=nextFloor~=nil
 local target=if nextFloor then nextFloor+.05 else s.Y
 local canStep=supported and math.abs(target-s.Y)<=cfg.StepHeight and (normal or 1)>=cfg.MinGroundNormal
 local y=s.Y
 if s.Grounded and canStep then y=target;s.VY=0
 else
  s.Grounded=false
  y=s.Y+s.VY*dt-.5*cfg.Gravity*dt*dt;s.VY-=cfg.Gravity*dt
  if s.VY<=0 and supported and s.Y>=target-cfg.GroundTolerance and y<=target and (normal or 1)>=cfg.MinGroundNormal then
   y=target;s.VY=0;s.Grounded=true
  end
 end
 -- Lift grounded body casts above traversable tire/step geometry. Floor queries still enforce height/slope.
 local bottom=if old.Grounded and s.Grounded then math.max(old.Y,y)+cfg.StepHeight+.05 else old.Y+.25
 local hit=scene.block(s.X,bottom,s.Z,s.Yaw,motion.DX,y-old.Y,motion.DZ,old.Y,old.Grounded and s.Grounded)
 if hit or (old.Grounded and supported and not canStep and s.VY<=0 and target>old.Y+cfg.StepHeight) then
  x=old.X;z=old.Z;s.Speed=0
  if y>old.Y and not s.Grounded then y=old.Y;s.VY=math.min(0,s.VY) end
 end
 s.X=x;s.Y=y;s.Z=z
 s.Distance+=math.sqrt((x-old.X)^2+(z-old.Z)^2)
 return s
end
function Sim.command(state:any,input:any,maxSpeed:number,scene:any):any
 for _=1,Config.Bike.CommandSteps do state=Sim.step(state,input,Config.Bike.Tick,maxSpeed,scene) end
 return state
end
function Sim.onBelt(state:any,cx:number,cy:number,cz:number,width:number,depth:number):boolean
 if not state or not state.Grounded or math.abs(state.Y-cy)>.4 then return false end
 for _,wheel in ipairs({-2.6,2.6}) do
  local x=state.X-math.sin(state.Yaw)*wheel-cx
  local z=state.Z-math.cos(state.Yaw)*wheel-cz
  if math.abs(x)>width/2-1 or math.abs(z)>depth/2-.3 then return false end
 end
 return true
end
function Sim.valid(state:any):boolean
 if type(state)~="table" or type(state.Grounded)~="boolean" then return false end
 for _,key in ipairs({"X","Y","Z","Yaw","Speed","VY","Distance","JumpId","JumpCooldown"}) do
  local v=state[key];if type(v)~="number" or v~=v or math.abs(v)>(if key=="JumpId" then 9007199254740991 else 1e9) then return false end
 end
 return state.JumpId>=0 and state.JumpId%1==0 and state.Distance>=0 and state.JumpCooldown>=0
end
return table.freeze(Sim)
