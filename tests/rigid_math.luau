-- Test-only rigid-transform algebra. No Roblox physics/rendering claim.
local function rigidMath()
 local V,VM={},{}
 function V.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},VM) end
 VM.__add=function(a,b) return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
 VM.__sub=function(a,b) return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
 VM.__unm=function(a) return V.new(-a.X,-a.Y,-a.Z) end
 VM.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return V.new(a.X*b,a.Y*b,a.Z*b) end
 VM.__div=function(a,b) return a*(1/b) end
 local function dot(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end
 local function cross(a,b) return V.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end
 local function unit(a) return a/math.sqrt(dot(a,a)) end
 VM.__index=function(a,k)
  if k=="Magnitude" then return math.sqrt(dot(a,a)) elseif k=="Unit" then return unit(a)
  elseif k=="Lerp" then return function(self,b,t) return self+(b-self)*t end
  elseif k=="Dot" then return dot elseif k=="Cross" then return cross end
 end
 V.zero=V.new()
 local C,CM={},{}
 local function make(p,r) return setmetatable({Position=p,R=r},CM) end
 local I={1,0,0,0,1,0,0,0,1}
 function C.new(x,y,z,...)
  if type(x)=="table" then return make(x,table.clone(I)) end
  local r={...};return make(V.new(x,y,z),if #r==9 then r else table.clone(I))
 end
 local function rotate(r,v) return V.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z) end
 CM.__mul=function(a,b)
  if not b.R then return a.Position+rotate(a.R,b) end
  local r={};for row=0,2 do for col=1,3 do
   r[row*3+col]=0;for k=0,2 do r[row*3+col]+=a.R[row*3+k+1]*b.R[k*3+col] end
  end end
  return make(a*b.Position,r)
 end
 CM.__add=function(a,v) return make(a.Position+v,table.clone(a.R)) end
 CM.__sub=function(a,v) return make(a.Position-v,table.clone(a.R)) end
 local methods={}
 function methods:Inverse()
  local r=self.R;local t={r[1],r[4],r[7],r[2],r[5],r[8],r[3],r[6],r[9]}
  return make(rotate(t,-self.Position),t)
 end
 function methods:ToObjectSpace(b) return self:Inverse()*b end
 function methods:PointToObjectSpace(v) return self:Inverse()*v end
 function methods:PointToWorldSpace(v) return self*v end
 function methods:ToEulerAnglesYXZ() return 0,math.atan2(self.R[3],self.R[9]),0 end
 function methods:Lerp(b,t)
  -- Gram-Schmidt is sufficient for pose tests; production uses Roblox quaternion interpolation.
  local ar,br=self.R,b.R
  local x=unit(V.new(ar[1]+(br[1]-ar[1])*t,ar[4]+(br[4]-ar[4])*t,ar[7]+(br[7]-ar[7])*t))
  local y=V.new(ar[2]+(br[2]-ar[2])*t,ar[5]+(br[5]-ar[5])*t,ar[8]+(br[8]-ar[8])*t)
  y=unit(y-x*dot(x,y));local z=cross(x,y)
  return make(self.Position+(b.Position-self.Position)*t,{x.X,y.X,z.X,x.Y,y.Y,z.Y,x.Z,y.Z,z.Z})
 end
 CM.__index=function(a,k)
  if k=="LookVector" then return V.new(-a.R[3],-a.R[6],-a.R[9]) end
  return methods[k]
 end
 function C.Angles(x,y,z)
  local sx,cx,sy,cy,sz,cz=math.sin(x),math.cos(x),math.sin(y),math.cos(y),math.sin(z),math.cos(z)
  return make(V.zero,{cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy})
 end
 function C.lookAt(p,target)
  local back=unit(p-target);local right=unit(cross(V.new(0,1,0),back));local up=cross(back,right)
  return make(p,{right.X,up.X,back.X,right.Y,up.Y,back.Y,right.Z,up.Z,back.Z})
 end
 C.identity=C.new()
 return V,C
end
modules.rigidMath=rigidMath
