#!/usr/bin/env python3
from pathlib import Path
import math,sys,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1];ns={'__file__':str(ROOT/'tools/build_world.py')}
exec((ROOT/'tools/build_world.py').read_text().split('model,_=item(world')[0],ns)
part,item=ns['part'],ns['item']
colors=[(155,107,57),(255,217,70),(92,192,112),(66,187,194),(147,97,61),(88,205,96),(50,164,92),(237,153,55),(87,214,246),(98,182,240),(107,224,231),(76,191,212)]
for id,color in enumerate(colors,1):
 tree=E.Element('roblox',version='4');model,_=item(tree,'Model',f'Pet{id}')
 def p(name,size,pos,c=color,shape=0):return part(model,name,size,pos,c,collide=False,shape=shape)
 p('Body',(1.5,1.3,1.7),(0,1,0));p('Head',(1.2,1.1,1.1),(0,1.65,-.8))
 for x in [-.3,.3]:p('Eye',(.16,.2,.12),(x,1.85,-1.34),(30,64,78))
 if id==1:
  p('CoconutShell',(1.65,1.4,1.5),(0,1.1,0),(133,85,41));p('WhiteFace',(1.1,.8,.1),(0,1.55,-1.32),(255,242,200))
  for a in range(4):p('PalmLeaf',(.4,.15,1.1),(math.sin(a*math.pi/2)*.35,2.3,-.7+math.cos(a*math.pi/2)*.35),(63,173,98),1)
 elif id in [2,4]:
  p('Beak',(.45,.28,.55),(0,1.55,-1.5),(255,158,53),1)
  for x in [-1,1]:p('Wing',(.3,1,1.2),(x*.85,1.2,0),(255,187,62) if id==2 else (59,150,225));p('Foot',(.4,.2,.6),(x*.35,.3,-.3),(255,151,46),1)
  if id==4:
   p('LongTail',(.5,.3,1.5),(0,.8,1.3),(229,92,67),1);p('Crest',(.3,.7,.4),(0,2.35,-.7),(255,220,65),1)
 elif id==3:
  p('Shell',(1.9,.9,2),(0,1.2,.2),(55,137,87));p('ShellPattern',(.8,.15,1.2),(0,1.7,.2),(210,218,104),1)
  for x in [-1,1]:
   for z in [-.6,.8]:p('Flipper',(.7,.25,.6),(x*.9,.5,z))
 elif id==5:
  for x in [-1,1]:p('Ear',(.6,.6,.3),(x*.65,1.9,-.65),(200,153,102));p('Arm',(.35,1.1,.35),(x*.9,1,0))
  p('Muzzle',(.75,.5,.5),(0,1.4,-1.3),(232,192,143));p('CurledTail',(.35,1.1,.4),(0,1.1,1.3))
 elif id==6:
  for x in [-1,1]:p('EyeBulge',(.65,.65,.65),(x*.48,2,-.8));p('HindLeg',(.7,.5,1.1),(x*.8,.55,.5))
 elif id==7:
  for j in range(5):p('Coil',(.75,.65,.85),(math.sin(j)*.6,.7,j*.45-.3),(48+j*15,150+j*7,93))
  p('Tongue',(.13,.07,.5),(0,1.4,-1.6),(239,128,100),1)
 elif id==8:
  for x in [-1,1]:
   for z in [-.5,.2,.8]:p('Stripe',(.12,.75,.2),(x*.77,1.2,z),(59,73,66),1)
   p('Ear',(.4,.45,.3),(x*.45,2.2,-.7))
  p('Tail',(.3,.3,1.4),(0,1,1.3))
 elif id==9:
  p('Orb',(1.1,1.1,1.1),(0,2.6,0),(150,236,255));p('Halo',(1.9,.15,1.9),(0,2.4,0),(214,247,255),2)
 elif id==10:
  for x in [-1,1]:
   for y in range(3):p('ExternalGill',(.65,.18,.25),(x*.75,1.5+y*.3,-.75),(246,151+y*16,192),1)
  p('TailFin',(.25,.7,1.4),(0,1,1.35),(149,215,255),1)
 elif id==11:
  p('Tail',(.3,1.5,.8),(0,1,1.3),(88,184,215),1);p('Dorsal',(.22,.8,1),(0,2,.2),(192,246,255),1)
  for x in [-1,1]:p('SideFin',(.7,.15,.65),(x*.8,1,-.2),(213,251,240),1)
 else:
  for x in [-1,1]:p('DragonWing',(1.3,.2,1.4),(x*1.15,1.7,.3),(115,222,233),1);p('Horn',(.2,.8,.2),(x*.4,2.4,-.6),(246,239,172),1)
  for j in range(3):p('DragonTail',(.65-j*.12,.5,1),(0,.9,1+j*.55),(65,164,192))
 E.indent(tree);data=E.tostring(tree,encoding='utf-8',xml_declaration=True)+b'\n';path=ROOT/f'src/models/Pet{id}.rbxmx'
 if '--check' in sys.argv:assert path.exists() and path.read_bytes()==data
 else:path.write_bytes(data)
# Exclusive model: fox ears, muzzle, split solar tail and floating crown, not a regular-species rename.
tree=E.Element('roblox',version='4');model,_=item(tree,'Model','ExclusiveSunfox')
for name,size,pos,color,shape in [
 ('FoxBody',(1.6,1.2,1.8),(0,1,0),(246,172,59),0),('FoxHead',(1.5,1.15,1.15),(0,1.7,-.7),(255,214,102),0),
 ('Muzzle',(.8,.45,.5),(0,1.45,-1.4),(255,247,212),0),('Nose',(.2,.2,.15),(0,1.6,-1.68),(60,70,95),0),
 ('Tail',(1,.8,1.8),(0,1.3,1.4),(248,156,66),0),('TailTip',(.75,.6,.8),(0,1.55,2.2),(255,249,210),0)]:part(model,name,size,pos,color,collide=False,shape=shape)
for sign in [-1,1]:
 part(model,'FoxEar',(.65,1.1,.45),(sign*.5,2.5,-.65),(255,190,71),collide=False,cls='WedgePart',yaw=180)
 part(model,'Eye',(.19,.23,.1),(sign*.36,1.85,-1.28),(43,74,106),collide=False,shape=0)
 part(model,'SolarWing',(.35,.6,1.3),(sign*1.1,1.6,.3),(255,226,112),288,False,cls='WedgePart')
ns['ring'](model,'SolarCrown',(0,3,-.5),.55,(255,221,105),8)
E.indent(tree);data=E.tostring(tree,encoding='utf-8',xml_declaration=True)+b'\n';path=ROOT/'src/models/ExclusiveSunfox.rbxmx'
if '--check' in sys.argv:assert path.exists() and path.read_bytes()==data
else:path.write_bytes(data)
tree=E.Element('roblox',version='4');model,_=item(tree,'Model','ExclusivePrismRay')
part(model,'RayBody',(1.5,.55,1.9),(0,1,0),(108,201,236),1568,False,shape=0)
for side in [-1,1]:
 part(model,'PrismWing',(1.5,.35,1.5),(side*1.1,1,0),(170,134,241),256,False,cls='WedgePart',yaw=side*90)
 part(model,'Eye',(.17,.17,.12),(side*.37,1.2,-.87),(29,61,92),256,False,shape=0)
 for k in range(3):part(model,'WingGem',(.2,.2,.25),(side*(.7+k*.4),1.2,k*.18),(153+k*30,238,249),288,False,shape=0)
for k in range(4):part(model,'RayTail',(.16,.16,.6),(0,1+k*.07,1+k*.45),(166,164+k*18,245),256,False)
ns['ring'](model,'PrismOrbit',(0,1.9,0),.5,(182,231,255),8)
E.indent(tree);data=E.tostring(tree,encoding='utf-8',xml_declaration=True)+b'\n';path=ROOT/'src/models/ExclusivePrismRay.rbxmx'
if '--check' in sys.argv:assert path.exists() and path.read_bytes()==data
else:path.write_bytes(data)
print('Twelve distinct pet assets verified' if '--check' in sys.argv else 'Generated 12 pet models')
