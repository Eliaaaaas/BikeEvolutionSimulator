#!/usr/bin/env python3
"""Nine additional authored vehicles with distinct geometry, same runtime motor contract."""
from pathlib import Path
import math,sys,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
ns={'__file__':str(ROOT/'tools/build_world.py')}
exec((ROOT/'tools/build_world.py').read_text().split('model,_=item(world')[0],ns)
source=(ROOT/'tools/build_race_assets.py').read_text();exec(source[source.index('def tube('):source.index('teal=')],ns)
part,item,tube=ns['part'],ns['item'],ns['tube']
colors=[(66,164,237),(246,173,53),(231,83,61),(93,201,124),(35,83,105),(238,155,65),(66,195,175),(62,129,213),(244,194,55)]
for id,color in enumerate(colors,2):
 world=E.Element('roblox',version='4');model,_=item(world,'Model',f'Vehicle{id}')
 part(model,'Root',(.1,.1,.1),(0,0,0),(0,0,0),collide=False,transparency=1)
 frame,_=item(model,'Model','Frame');part(frame,'Pivot',(.1,.1,.1),(0,0,0),(0,0,0),collide=False,transparency=1)
 steer,_=item(model,'Model','Steering');part(steer,'Pivot',(.1,.1,.1),(0,3.4,-1.9),color,collide=False,transparency=1)
 radius=1.15 if id in [3,8] else 1.43
 rear=(0,radius,2.6);head=(0,3.4,-1.9);crank=(0,1.6,.5);seat=(0,3.5,.9)
 dark=(32,56,72);silver=(208,227,236)
 for side in [-1,1]:tube(steer,'Fork',(side*.35,radius,-2.6),(side*.35,3.4,-1.9),.18,silver)
 tube(steer,'Handlebar',(-1.25,4.1,-2.1),(1.25,4.1,-2.1),.18,dark)
 for side in [-1,1]:part(steer,'Grip',(.45,.24,.3),(side*1.15,4.1,-2.1),color,collide=False)
 part(frame,'Saddle',(1.3,.4,1.5),(0,3.9,1),dark,collide=False)
 if id<=6:
  for name,a,b in [('SeatTube',crank,seat),('ChainStay',rear,crank),('SeatStay',rear,seat)]:tube(frame,name,a,b,.22,color)
  if id==2:
   tube(frame,'StepThrough',crank,(0,2.1,-1.6),.25,color);tube(frame,'RisingTube',(0,2.1,-1.6),head,.22,color)
   part(steer,'Basket',(1.7,.8,1.0),(0,3.3,-2.5),(234,205,155),collide=False)
   part(frame,'RearRack',(1.4,.15,1.4),(0,3,2.4),silver,collide=False)
  elif id==3:
   tube(frame,'CompactTopTube',(0,3.2,.9),head,.32,color);tube(frame,'BMXDownTube',crank,head,.29,color)
   for side in [-1,1]:part(frame,'StuntPeg',(.8,.25,.25),(side*.65,radius,2.6),silver,collide=False)
   tube(steer,'CrossBar',(-1.1,3.8,-2.1),(1.1,3.8,-2.1),.12,silver)
  elif id==4:
   tube(frame,'RoadTopTube',seat,head,.15,color);tube(frame,'RoadDownTube',crank,head,.17,color)
   for side in [-1,1]:tube(steer,'DropBar',(side*1.15,4.1,-2.1),(side*1.15,3.5,-2.4),.15,dark)
  elif id==5:
   tube(frame,'AeroTopTube',seat,head,.28,color);tube(frame,'AeroDownTube',crank,head,.4,color)
   for side in [-1,1]:tube(steer,'AeroExtension',(side*.4,4.1,-2.1),(side*.4,4.1,-3),.15,silver)
   part(frame,'RaceNumber',(.15,.7,1),(0,2.7,.3),(255,255,255),collide=False)
  else:
   tube(frame,'CarbonBeam',rear,head,.38,dark);tube(frame,'SplitCarbonSeat',crank,seat,.28,color)
   tube(frame,'CarbonDownTube',crank,head,.45,dark)
   part(frame,'CarbonBattery',(.65,.5,1.5),(0,2.1,-.5),color,collide=False)
  cg,_=item(model,'Model','Crank');part(cg,'Pivot',(.6,.25,.25),crank,silver,collide=False,shape=2)
  for side in [-1,1]:
   tube(cg,'Arm',(side*.4,1.6,.5),(side*.4,1.6+side*.7,.5),.13,silver)
   part(cg,'Pedal',(.55,.16,.7),(side*.65,1.6+side*.7,.5),color,collide=False)
 else:
  tube(frame,'Chassis',rear,head,.4,dark)
  part(frame,'EngineBlock',(1.2,1.0,1.5),(0,1.7,.6),silver,collide=False)
  tube(frame,'Exhaust',(.85,1.3,.5),(.85,1.6,2.9),.28,dark)
  for side in [-1,1]:part(frame,'FootRest',(.6,.2,.8),(side*.8,1.7,0),silver,collide=False)
  if id==7:
   part(frame,'ClassicTank',(1.1,.9,1.5),(0,3,-.4),color,collide=False,shape=0)
   part(frame,'RearFender',(1.2,.25,1.8),(0,3,2),color,collide=False)
   part(steer,'RoundHeadlamp',(.8,.8,.3),(0,3.5,-2.5),(255,242,183),collide=False,shape=0)
  elif id==8:
   part(frame,'ScooterFloor',(1.7,.25,2.4),(0,1.9,-.4),color,collide=False)
   part(steer,'LegShield',(1.8,2,.4),(0,2.9,-1.7),color,collide=False)
   part(frame,'ScooterBody',(1.7,1.2,2),(0,2.8,1.4),color,collide=False,shape=0)
  elif id==9:
   part(frame,'SportFairing',(1.5,1.2,2.8),(0,2.5,0),color,collide=False)
   part(steer,'SportNose',(1.5,.7,1.2),(0,3.5,-2.2),color,collide=False)
   part(steer,'Windscreen',(1.1,.9,.15),(0,4.1,-2.4),(143,223,243),collide=False,transparency=.35)
  else:
   part(frame,'RacingTail',(1.3,.8,2.2),(0,3.2,1.8),color,collide=False)
   tube(frame,'RacingSpine',rear,head,.55,color)
   part(steer,'RaceShield',(1.8,1.4,.3),(0,3.5,-2.4),color,collide=False)
   part(steer,'RacePlate',(1,.5,.12),(0,3.7,-2.6),(255,255,255),collide=False)
 for name,z in [('FrontWheel',-2.6),('RearWheel',2.6)]:
  g,_=item(model,'Model',name);part(g,'Pivot',(.5,.3,.3),(0,radius,z),silver,collide=False,shape=2)
  for j in range(16):
   a=j*math.pi/8;b=(j+1)*math.pi/8
   tube(g,'Tire',(0,radius+radius*math.sin(a),z+radius*math.cos(a)),(0,radius+radius*math.sin(b),z+radius*math.cos(b)),.38 if id>=7 else .22,dark)
   if j%4==0:tube(g,'Spoke',(0,radius,z),(0,radius+.85*radius*math.sin(a),z+.85*radius*math.cos(a)),.07,color)
 E.indent(world);data=E.tostring(world,encoding='utf-8',xml_declaration=True)+b'\n';path=ROOT/f'src/models/Vehicle{id}.rbxmx'
 if '--check' in sys.argv:assert path.exists() and path.read_bytes()==data,f'Outdated {path}'
 else:path.write_bytes(data)
print('Distinct vehicle fleet verified' if '--check' in sys.argv else 'Generated 9 additional vehicle models')
