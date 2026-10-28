--!strict
-- Pure manual-driving integrator. Clients never supply position, speed or elapsed time.
local Config=require(script.Parent.Config)
local Motion={}
function Motion.step(speed:number,yaw:number,throttle:number,steer:number,brake:boolean,dt:number,maxSpeed:number):any
 local cfg=Config.Bike
 dt=math.clamp(dt,0,.1)
 local target=if brake then 0 else throttle*maxSpeed*(if throttle<0 then .35 else 1)
 local rate=if brake or speed*target<0 then cfg.Braking elseif throttle==0 then cfg.Drag else cfg.Acceleration
 local change=math.clamp(target-speed,-rate*dt,rate*dt)
 speed+=change
 yaw=(yaw-steer*cfg.TurnRate*dt*math.clamp(math.abs(speed)/1.5,0,1)*(if speed<-.1 then -1 else 1))% (math.pi*2)
 return {Speed=speed,Yaw=yaw,DX=-math.sin(yaw)*speed*dt,DZ=-math.cos(yaw)*speed*dt}
end
function Motion.inGarage(x:number,y:number,z:number,cx:number,cy:number,cz:number,radius:number):boolean
 local dx,dz=x-cx,z-cz
 return dx>=0 and dx*dx+dz*dz<=radius*radius and math.abs(y-cy)<=8
end
return table.freeze(Motion)
