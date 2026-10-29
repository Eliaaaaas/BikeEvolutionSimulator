--!strict
local N={}
function N.input(state:any,target:any):(any,number)
 local dx,dz=target.X-state.X,target.Z-state.Z
 local distance=math.sqrt(dx*dx+dz*dz)
 local desired=math.atan2(-dx,-dz)
 local error=math.atan2(math.sin(desired-state.Yaw),math.cos(desired-state.Yaw))
 -- At very tight angles reverse briefly instead of orbiting an unreachable waypoint.
 local reverse=math.abs(error)>2.1 and distance<7
 return {Throttle=if distance<.8 then 0 elseif reverse then -.35 else math.clamp(distance/10,.18,.65),Steer=math.clamp(-error*1.8,-1,1),Brake=distance<.8,JumpId=state.JumpId},distance
end
function N.path(state:any,target:any):{any}
 local path={}
 -- Fixed authored clear corridors on World 1; never a teleport. Collision sweeps remain active.
 if state.Z< -38 then table.insert(path,{X=state.X,Z=-31}) end
 if state.X< -30 and state.Z> -20 and state.Z<28 then table.insert(path,{X=-29,Z=state.Z}) end
 table.insert(path,{X=0,Z=if target.Z<0 then -28 else 32})
 if target.Z<0 then table.insert(path,{X=target.X,Z=-33}) end
 table.insert(path,target)
 return path
end
return table.freeze(N)
