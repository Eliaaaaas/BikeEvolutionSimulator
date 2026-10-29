#!/usr/bin/env python3
"""Generate the course and authored MTB from free primitives; helpers shared with the island."""
from pathlib import Path
import math, sys
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
# Load the primitive serializer without running its island output/check branch.
source=(ROOT/'tools/build_world.py').read_text().split('model,_=item(world')[0]
ns={"__file__":str(ROOT/"tools/build_world.py")};exec(compile(source,str(ROOT/'tools/build_world.py'),'exec'),ns)
item,part=ns['item'],ns['part']

def save(tree,path):
 E.indent(tree);data=E.tostring(tree,encoding='utf-8',xml_declaration=True)+b'\n'
 path=ROOT/path
 if '--check' in sys.argv:
  assert path.exists() and path.read_bytes()==data,f'Outdated asset: {path}'
 else:path.write_bytes(data)
# An open point-to-point S course, with long straights and two elevated timber sections.
controls=[(0,8.2,0),(0,8.2,60),(38,10,106),(85,15,150),(63,17,195),(-15,14,232),(-75,9,282),(-66,8.2,337),(10,11,382),(87,16,424),(103,17,470),(36,12,516),(-42,9,535)]
raw=[]
for i in range(121):
 t=i/120*(len(controls)-1);index=min(len(controls)-2,int(t));u=t-index
 a=controls[max(0,index-1)];b=controls[index];c=controls[index+1];d=controls[min(len(controls)-1,index+2)]
 raw.append(tuple(.5*((2*b[k])+(-a[k]+c[k])*u+(2*a[k]-5*b[k]+4*c[k]-d[k])*u*u+(-a[k]+3*b[k]-3*c[k]+d[k])*u*u*u) for k in range(3)))
length=sum(math.sqrt(sum((b[k]-a[k])**2 for k in range(3))) for a,b in zip(raw,raw[1:]))
factor=800/length
points=[(x*factor,8.2+(y-8.2)*factor,115+z*factor) for x,y,z in raw]
data='--!strict\n-- Generated authored S course; distance includes elevation.\nreturn {\n'+''.join(f' {{X={x:.8f},Y={y:.8f},Z={z:.8f}}},\n' for x,y,z in points)+'}\n'
p=ROOT/'src/shared/CourseData.luau'
if '--check' in sys.argv:assert p.read_text()==data
else:p.write_text(data)
world=E.Element('roblox',version='4');track,_=item(world,'Model','TestCourse')
beam=ns['beam'];plaque=ns['plaque'];palm=ns['palm']
part(track,'Bridge',(14,1,43),(0,7.5,96),(225,190,128),512)
for x in [-7,7]:part(track,'BridgeRail',(.5,2.5,43),(x,9.5,96),(49,188,175))
def pathpart(name,a,b,width,thickness,color,material=256,lift=0,collide=True):
 aa=(a[0],a[1]+lift,a[2]);bb=(b[0],b[1]+lift,b[2])
 node,props=beam(track,name,aa,bb,width,color,material,collide)
 size=props.find("Vector3[@name='size']");size.find('Y').text=str(thickness);size.find('Z').text=str(float(size.find('Z').text))
 return node
def sub(a,b):return tuple(a[k]-b[k] for k in range(3))
def dot(a,b):return sum(a[k]*b[k] for k in range(3))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(v):return tuple(x/math.sqrt(dot(v,v)) for x in v)
def triangle(parent,a,b,c):
 # Two right-triangle prisms tile each triangle exactly; common vertices avoid chord gaps/overlaps.
 if dot(sub(b,a),sub(b,a))>dot(sub(c,b),sub(c,b)):a,b,c=c,a,b
 if dot(sub(c,a),sub(c,a))>dot(sub(c,b),sub(c,b)):a,b,c=b,c,a
 ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
 right=unit(cross(ac,ab));back=unit(bc);up=unit(cross(back,right))
 height=abs(dot(ab,up))
 for endpoint,normal,direction in [(b,right,back),(c,tuple(-v for v in right),tuple(-v for v in back))]:
  width=abs(dot(sub(a,endpoint),back))
  if width<1e-6:continue
  center=tuple((a[k]+endpoint[k])/2 for k in range(3))
  node,props=part(parent,'AsphaltTriangle',(.28,height,width),center,(48,57,69),1376,True,cls='WedgePart')
  cf=props.find("CoordinateFrame[@name='CFrame']")
  for row in range(3):
   for col,axis in enumerate([normal,up,direction]):cf.find(f'R{row}{col}').text=str(axis[row])
# Shared mitered boundaries. A single seam vertex is reused by adjacent strips.
edges=[]
for i,p in enumerate(points):
 a,b=points[max(0,i-1)],points[min(len(points)-1,i+1)]
 dx,dz=b[0]-a[0],b[2]-a[2];n=math.hypot(dx,dz)
 edges.append([(p[0]+side*12*dz/n,p[1]-.2,p[2]-side*12*dx/n) for side in [-1,1]])
for i,(a,b) in enumerate(zip(points,points[1:])):
 dx,dz=b[0]-a[0],b[2]-a[2];horizontal=math.hypot(dx,dz);yaw=math.degrees(math.atan2(dx,dz))
 timber=28<=i<=40 or 85<=i<=96
 road,_=item(track,'Model',f'Road_{i}')
 triangle(road,edges[i][0],edges[i+1][0],edges[i][1]);triangle(road,edges[i][1],edges[i+1][0],edges[i+1][1])
 for side in [-1,1]:
  ra=(edges[i][0 if side==-1 else 1][0],a[1]+.9,edges[i][0 if side==-1 else 1][2])
  rb=(edges[i+1][0 if side==-1 else 1][0],b[1]+.9,edges[i+1][0 if side==-1 else 1][2])
  pathpart(f'Barrier_{i}_{side}',ra,rb,.28,.7,(231,242,248) if i%2 else (82,164,204))
  if i%4==0:
   part(track,'GuardPost',(.35,1.6,.35),ra,(44,103,143),1088)
  curb_a=(edges[i][0 if side==-1 else 1][0]*1, a[1]-.06,edges[i][0 if side==-1 else 1][2])
  curb_b=(edges[i+1][0 if side==-1 else 1][0], b[1]-.06,edges[i+1][0 if side==-1 else 1][2])
  pathpart('RaceCurb',curb_a,curb_b,.65,.08,(246,249,252) if i%2 else (227,78,77),256,0,False)
 if i%3==0:
  pathpart('CenterMark',a,b,.25,.03,(248,249,247),256,-.035,False)
 if timber and i%2==0:
  # Visible wood supports and planks under the same continuous collision surface.
  mid=tuple((a[k]+b[k])/2 for k in range(3))
  part(track,'BridgeSupport',(1.8,max(2,mid[1]-1),1.8),(mid[0]+10*dz/horizontal,mid[1]/2-1,mid[2]-10*dx/horizontal),(125,88,57),512)
 if i%10==0:
  mid=tuple((a[k]+b[k])/2 for k in range(3));x=mid[0]+dz/horizontal*27;z=mid[2]-dx/horizontal*27
  part(track,'RoadsideIsland',(20,5,21),(x,2,z),(232,211,157),1296,shape=0)
  part(track,'RoadsideGrass',(17,1,17),(x,4.8,z),(78,180,100),1280,shape=0)
  palm(track,x,z,12,i,5.3)
  for side in [-1,1]:part(track,'DirectionArrow',(.4,.06,2),(mid[0]+side*.6,mid[1]-.12,mid[2]),(255,225,101),288,False,yaw=yaw+side*40)
for i in range(8,112,12):
 p=points[i];edge=edges[i][i%2];direction=1 if i%2 else -1
 x=edge[0]+direction*13;z=edge[2]
 part(track,'SpectatorDeck',(8,.5,6),(x,p[1]+1,z),(204,178,124),512,False)
 for row in range(3):part(track,'Bench',(6,.6,1),(x,p[1]+1.7+row*.5,z+row*1.2),(70,154,172),256,False)
 for sign in [-1,1]:
  part(track,'TrackLampPost',(.25,5,.25),(x+sign*4,p[1]+3.5,z),(67,106,126),1088,False)
  part(track,'TrackLamp',(1,.3,1),(x+sign*4,p[1]+6,z),(255,237,163),288,False)
  part(track,'FlowerBed',(3,.6,2),(x+sign*3,p[1]+1,z-3),(64,164,108),1280,False,shape=0)
 for k in range(3):part(track,'TropicalFlower',(.7,.4,.7),(x-2+k*2,p[1]+1.4,z-3),(253,128+k*28,126),256,False,shape=0)
 if i in [20,68]:
  part(track,'TrackWaterfall',(5,13,.5),(x+direction*9,p[1]+2,z+4),(106,221,238),1568,False,.35)
  part(track,'CascadeRock',(8,15,5),(x+direction*9,p[1]+2,z+5),(93,128,126),896,False,shape=0)
for title,index in [('START',0),('ZIEL',-1)]:
 x,y,z=points[index];a,b=(points[0],points[1]) if index==0 else (points[-2],points[-1])
 angle=math.atan2(b[0]-a[0],b[2]-a[2]);color=(255,159,62) if index==0 else (86,235,168)
 for side in [-1,1]:part(track,title+'Post',(1.4,12,1.4),(x+side*12*math.cos(angle),y+5,z-side*12*math.sin(angle)),(47,101,146),256,False)
 plaque(track,('FINISH' if index==-1 else title)+' / PALM BAY',(x,y+11,z),25,color)
 for column in range(12):
  offset=(column-5.5)*1.8
  part(track,title+str(column),(1.8,.05,2),(x+math.cos(angle)*offset,y-.14,z-math.sin(angle)*offset),(255,255,255) if column%2==0 else (28,48,64),collide=False,yaw=math.degrees(angle))
save(world,'src/world/TestCourse.rbxmx')
# MTB forward is -Z; wheel axle is X. Parts grouped for runtime Motor6D animation.
world=E.Element('roblox',version='4');bike,_=item(world,'Model','Mountainbike')
part(bike,'Root',(0.2,0.2,0.2),(0,0,0),(0,0,0),collide=False,transparency=1)
frame,_=item(bike,'Model','Frame')
part(frame,'Pivot',(0.1,0.1,0.1),(0,0,0),(0,0,0),collide=False,transparency=1)
def tube(parent,name,a,b,r,color):
 # Box beams with local Z along endpoints; support arbitrary vertical pitch.
 dx,dy,dz=[b[i]-a[i] for i in range(3)];length=math.sqrt(dx*dx+dy*dy+dz*dz)
 node,props=part(parent,name,(r,r,length),tuple((a[i]+b[i])/2 for i in range(3)),color,collide=False)
 # Orthonormal basis: right, up, backward along beam.
 back=[dx/length,dy/length,dz/length];right=[back[2],0,-back[0]];n=math.hypot(right[0],right[2])
 right=[v/n for v in right] if n>1e-8 else [1,0,0]
 up=[back[1]*right[2]-back[2]*right[1],back[2]*right[0]-back[0]*right[2],back[0]*right[1]-back[1]*right[0]]
 cf=props.find("CoordinateFrame[@name='CFrame']")
 for row in range(3):
  for col,vec in enumerate([right,up,back]):cf.find(f'R{row}{col}').text=str(vec[row])
 return node
teal=(26,197,176);yellow=(255,205,70);metal=(207,225,231);dark=(33,53,66)
rear=(0,1.5,2.6);front=(0,1.5,-2.6);crank=(0,1.6,0.5);seat=(0,3.5,0.9);head=(0,3.4,-1.9)
for name,a,b in [('SeatTube',crank,seat),('TopTube',seat,head),('DownTube',crank,head),('ChainStay',rear,crank),('SeatStay',rear,seat)]:tube(frame,name,a,b,0.22,teal)
part(frame,'Saddle',(1.3,0.35,1.4),(0,3.9,1),(40,65,76),collide=False)
tube(frame,'SeatPost',seat,(0,3.9,1),0.16,metal)
for x in [-0.32,0.32]:tube(frame,'RearStay',(x,1.5,2.6),(x,3.5,0.9),0.12,metal)
steer,_=item(bike,'Model','Steering');part(steer,'Pivot',(0.1,0.1,0.1),head,dark,collide=False,transparency=1)
for x in [-0.35,0.35]:tube(steer,'Fork',(x,1.5,-2.6),(x,3.4,-1.9),0.17,yellow)
tube(steer,'Stem',head,(0,4.1,-2.1),0.18,metal)
tube(steer,'Handlebar',(-1.25,4.1,-2.1),(1.25,4.1,-2.1),0.15,dark)
for x in [-1.15,1.15]:part(steer,'Grip',(0.45,0.22,0.3),(x,4.1,-2.1),yellow,collide=False)
for name,z in [('FrontWheel',-2.6),('RearWheel',2.6)]:
 group,_=item(bike,'Model',name)
 part(group,'Pivot',(0.4,0.35,0.35),(0,1.5,z),metal,collide=False,shape=2)
 # Thin ring from 24 short tangent tread segments; open centers expose rims/spokes.
 for i in range(24):
  a=i*math.pi/12;b=(i+1)*math.pi/12
  tube(group,'Tread',(0,1.5+1.43*math.sin(a),z+1.43*math.cos(a)),(0,1.5+1.43*math.sin(b),z+1.43*math.cos(b)),0.32,dark)
  tube(group,'Rim',(0,1.5+1.24*math.sin(a),z+1.24*math.cos(a)),(0,1.5+1.24*math.sin(b),z+1.24*math.cos(b)),0.09,teal)
  if i%3==0:tube(group,'Spoke',(0,1.5,z),(0,1.5+1.23*math.sin(a),z+1.23*math.cos(a)),0.035,metal)
cranks,_=item(bike,'Model','Crank');part(cranks,'Pivot',(0.6,0.25,0.25),crank,dark,collide=False,shape=2)
for side in [-1,1]:
 tube(cranks,'Arm',(side*0.4,1.6,0.5),(side*0.4,1.6+side*0.7,0.5),0.13,metal)
 part(cranks,'Pedal',(0.55,0.16,0.7),(side*0.65,1.6+side*0.7,0.5),yellow,collide=False)
save(world,'src/models/Mountainbike.rbxmx')
print('Race course (800 studs) and Mountainbike assets verified' if '--check' in sys.argv else 'Generated race assets')
