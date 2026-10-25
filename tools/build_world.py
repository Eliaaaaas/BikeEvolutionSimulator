#!/usr/bin/env python3
"""Deterministic, free Roblox primitive map. No remote models, textures or meshes."""
from pathlib import Path
import math
import xml.etree.ElementTree as E
import argparse

ROOT = Path(__file__).resolve().parents[1]
world = E.Element('roblox', version='4')
def prop(parent, kind, name, value):
    el = E.SubElement(parent, kind, name=name)
    el.text = str(value).lower() if isinstance(value, bool) else str(value)
    return el
def item(parent, cls, name):
    el = E.SubElement(parent, 'Item', {'class':cls})
    props = E.SubElement(el, 'Properties'); prop(props, 'string', 'Name', name)
    return el, props
def vector(props, kind, name, values):
    el = E.SubElement(props, kind, name=name)
    for axis, value in zip('XYZ', values): E.SubElement(el, axis).text=str(value)
def part(parent, name, size, pos, color, material=256, collide=True, transparency=0, shape=1, cls='Part', yaw=0):
    el,props = item(parent,cls,name)
    prop(props,'bool','Anchored',True);prop(props,'bool','CanCollide',collide)
    prop(props,'bool','CanTouch',False);prop(props,'bool','CanQuery',True)
    prop(props,'float','Transparency',transparency)
    prop(props,'token','Material',material);prop(props,'token','TopSurface',0);prop(props,'token','BottomSurface',0)
    if cls=='Part':prop(props,'token','shape',shape)
    vector(props,'Vector3','size',size)
    c=E.SubElement(props,'Color3',name='Color')
    for axis,value in zip('RGB',color):E.SubElement(c,axis).text=str(value/255)
    cf=E.SubElement(props,'CoordinateFrame',name='CFrame')
    for axis,value in zip('XYZ',pos):E.SubElement(cf,axis).text=str(value)
    angle=math.radians(yaw);cs,sn=math.cos(angle),math.sin(angle)
    for idx,value in enumerate([cs,0,sn,0,1,0,-sn,0,cs]):E.SubElement(cf,f'R{idx//3}{idx%3}').text=str(value)
    return el,props

def sign(parent, text, pos, size=(22,6,1), color=(27,126,119), face=2):
    board,_=part(parent,'Sign',size,pos,color,collide=False)
    gui,gp=item(board,'SurfaceGui','Label');prop(gp,'token','Face',face);prop(gp,'float','PixelsPerStud',36)
    label,lp=item(gui,'TextLabel','Text');prop(lp,'string','Text',text);prop(lp,'bool','TextScaled',True)
    prop(lp,'float','BackgroundTransparency',1);prop(lp,'token','Font',20)
    c=E.SubElement(lp,'Color3',name='TextColor3')
    for axis,value in zip('RGB',(28,76,88) if sum(color)>450 else (255,255,255)):E.SubElement(c,axis).text=str(value/255)
    u=E.SubElement(lp,'UDim2',name='Size')
    for key,value in [('XS',1),('XO',0),('YS',1),('YO',0)]:E.SubElement(u,key).text=str(value)


def beam(parent,name,a,b,width,color,material=256,collide=False):
    delta=[b[i]-a[i] for i in range(3)];length=math.sqrt(sum(v*v for v in delta))
    node,props=part(parent,name,(width,width,length),tuple((a[i]+b[i])/2 for i in range(3)),color,material,collide)
    back=[v/length for v in delta];right=[back[2],0,-back[0]];n=math.hypot(right[0],right[2])
    right=[v/n for v in right] if n>1e-8 else [1,0,0]
    up=[back[1]*right[2]-back[2]*right[1],back[2]*right[0]-back[0]*right[2],back[0]*right[1]-back[1]*right[0]]
    cf=props.find("CoordinateFrame[@name='CFrame']")
    for row in range(3):
        for col,vec in enumerate([right,up,back]):cf.find(f'R{row}{col}').text=str(vec[row])
    return node,props

def plaque(parent,title,pos,width,color=(26,115,129),height=4):
    sign(parent,title,pos,(width,height,.45),color,face=2)
    sign(parent,title,(pos[0],pos[1],pos[2]-.47),(width,height,.05),color,face=5)
    for side in [-1,1]:part(parent,'SignTrim',(.14,height+.2,.5),(pos[0]+side*width/2,pos[1],pos[2]),(255,222,111),288,False)

def palm(parent,x,z,height=17,index=0,ground=8):
    tree,_=item(parent,'Model',f'Palm_{index}')
    lean=2*math.sin(index+1);top=(x+lean,ground+height,z+1.4)
    for segment in range(5):
        t=segment/5;u=(segment+1)/5
        a=(x+lean*t*t,ground+height*t,z+1.4*t*t);b=(x+lean*u*u,ground+height*u,z+1.4*u*u)
        beam(tree,'TrunkSegment',a,b,1.5-segment*.16,(147+segment*6,102+segment*3,60),512)
    for leaf in range(7):
        a=leaf*math.tau/7+index*.3;dx,dz=math.sin(a),math.cos(a)
        mid=(top[0]+dx*4,top[1]+1.2,top[2]+dz*4)
        tip=(top[0]+dx*8,top[1]-1.2,top[2]+dz*8)
        beam(tree,'LeafSpine',top,tip,.3,(47,132,72))
        # Two tapered wedge blades per frond, with a lifted root and drooping tip.
        blade,props=beam(tree,'PalmLeaf',top,mid,1.4,(42+leaf*3,157+leaf*3,77),1280)
        blade,props=beam(tree,'PalmLeaf',mid,tip,1.1,(57+leaf*2,184,86),1280)
    for i in range(3):part(tree,'Coconut',(1,1.2,1),(top[0]+math.sin(i*2)*.9,top[1]-.5,top[2]+math.cos(i*2)*.9),(117,79,43),shape=0,collide=False)

model,_=item(world,'Model','World1')
terrain,_=item(model,'Folder','Island')
# Fine contiguous slices create a smooth, asymmetrical shoreline; all grass tops are y=8.
for row in range(96):
    z=-90.25+row*1.9
    radius=math.sqrt(max(.001,1-(z/92)**2))
    half=83*radius*(1+.06*math.sin(row*.14)+.035*math.cos(row*.31))
    shift=4*math.sin(row*.09)+2*math.cos(row*.17)
    part(terrain,f'Sand_{row}',(half*2+10,6.4,1.92),(shift,3.8,z),(244,218,156),1296)
    part(terrain,f'Grass_{row}',(half*2,1,1.92),(shift,7.5,z),(90,192,107),1280)
part(model,'Ocean',(1250,2,1250),(0,-1,200),(32,167,195),288,False,.22)
# Shallow lagoon shelves make the coastline read as an island, not a box on water.
for i in range(26):
    a=i*math.tau/26;x=math.sin(a)*87;z=math.cos(a)*88
    part(terrain,'LagoonShelf',(12,1,14),(x,1,z),(81,211,207),288,False,.65,shape=0)
spawn,sp=part(model,'IslandSpawn',(10,.16,10),(0,8.08,0),(255,225,104),cls='SpawnLocation')
prop(sp,'bool','Neutral',True);prop(sp,'float','Duration',0)
for side in [-1,1]:part(model,'SpawnNeon',(.15,.1,10),(side*5.2,8.12,0),(104,251,218),288,False)
plaque(model,'PALM BAY  /  WORLD 1',(0,15,-13),28)
plaque(model,'TRAIN -> REBIRTH -> RACE -> CASH -> PETS',(0,11,-13),32,(41,133,130),2.5)
# Terraced waterfall cliffs with larger cascades and layered pools, behind the belts.
for i,x in enumerate(range(-65,66,13)):
    part(model,'CliffBase',(16,22+(i%3)*3,12),(x,17,-76),(100+i%3*9,126,115),896,shape=0)
    part(model,'CliffCrown',(17,3,14),(x,30+(i%3)*1.5,-77),(71,154,97),1280,shape=0)
for x in [-57,57]:
    part(model,'Waterfall',(9,29,1.4),(x,23,-68),(83,215,243),288,False,.25)
    part(model,'Waterfall',(5,29,.4),(x+.8,23,-67.1),(173,246,255),288,False,.56)
    part(model,'WaterfallPool',(20,.15,11),(x,8.1,-64),(88,211,232),288,False,.25,shape=0)
    for j in [-1,1]:part(model,'PoolRock',(5,3,6),(x+j*9,8,-65),(138,157,143),896,shape=0)
training,_=item(model,'Folder','Training')
xs=[-54,-36,-18,24,42]
colors=[(43,225,166),(52,185,255),(255,205,65),(255,126,65),(159,121,255)]
for i,(x,color) in enumerate(zip(xs,colors),1):
    treadmill,_=item(training,'Model',f'Treadmill_{i}')
    part(treadmill,'Platform',(13,.55,17),(x,8.275,-51),(28,63,84))
    part(treadmill,'Deck',(11,.5,15),(x,8.8,-51),color)
    part(treadmill,'Belt',(8,.2,12),(x,9.15,-51),(28,43,58))
    part(treadmill,'Zone',(8,.1,12),(x,9.3,-51),color,collide=False,transparency=1)
    for side in [-1,1]:
        part(treadmill,'NeonEdge',(.22,.25,16),(x+side*6.2,8.7,-51),color,288,False)
        part(treadmill,'RailPost',(.35,3.4,.35),(x+side*4.7,10.8,-56),(222,242,246),collide=False)
        part(treadmill,'Handrail',(.4,.4,9),(x+side*4.7,12.4,-52.5),color,288,False)
    for j in range(8):part(treadmill,f'BeltStripe_{j}',(7.8,.025,.18),(x,9.265,-56+j*1.4),color,288,False)
    part(treadmill,'Console',(6,1.1,1),(x,12.4,-56.5),(22,65,83),collide=False)
    energy=0 if i==1 else 4**(i-2);rebirth=0 if i==1 else 3**(i-2)
    plaque(treadmill,f'BELT {i}  /  +{2**(i-1)} ENERGY',(x,17.5,-59),14,color,3.5)
    plaque(treadmill,f'{energy} ENERGY OR {rebirth} REBIRTHS',(x,14.8,-59),14,(25,71,89),1.8)
    # The local client replaces this status, while the server owns actual permission.
    plaque(treadmill,'STEP ON TO TRAIN',(x,10.6,-43.7),12,(28,100,112),1.2)
part(training,'PremiumReserved',(20,.12,17),(3,8.08,-51),(240,208,120),collide=False)
plaque(training,'PREMIUM / FUTURE',(3,14,-60),22,(167,119,40))
# Paths made of individual offset pavers, with wide visible links between every station.
for x,z,dx,dz,count in [(0,-4,0,-3.6,11),(0,7,0,3.6,16),(-7,0,-3.6,0,13),(7,0,3.6,0,13),(48,-18,0,3.6,14),(-25,8,0,3.6,5)]:
 for n in range(count):
    px,pz=x+dx*n,z+dz*n
    part(model,'PathPaver',(7.4,.08,3.1) if dx==0 else (3.1,.08,7.4),(px,8.045,pz),(237+(n%2)*6,221,181),1296,False,yaw=(n%3-1)*2)
# Functional stations keep existing stable names/interaction parts.
for name,title,x,z,color in [('RacePreview','RACE / 5 BOTS',0,63,(255,145,56)),('GaragePreview','BIKE GARAGE',-60,8,(53,177,248)),('WorldPreview','WORLDS / PREVIEW',-45,57,(72,224,185))]:
    station,_=item(model,'Model',name)
    w,d=(32,29) if name=='GaragePreview' else (25,15)
    part(station,'Platform',(w,.35,d),(x,8.175,z),color)
    for side in [-1,1]:
        part(station,'ArchPost',(1.2,13,1.2),(x+side*(w/2-1),14.5,z+5),(26,84,101))
        part(station,'ArchGlow',(.3,12,.3),(x+side*(w/2-1),14.5,z+4.3),color,288,False)
    part(station,'ArchTop',(w+1,1.2,2),(x,21,z+5),color,288,False)
    plaque(station,title,(x,20,z+3.7),w,color)
    if name=='RacePreview':plaque(station,'E / TAP : EASY   |   RACE MENU : ALL TIERS',(x,15,z+4),25,(25,91,111),2.5)
# Authored vehicle gallery: visible before Play and while walking around, never drivable.
import copy
showroom,_=item(model,'Folder','GarageShowroom')
for vehicle in range(1,11):
    source=ROOT/'src/models'/('Mountainbike.rbxmx' if vehicle==1 else f'Vehicle{vehicle}.rbxmx')
    if not source.exists():raise RuntimeError('Generate vehicle fleet before island: '+str(source))
    display=copy.deepcopy(E.parse(source).getroot().find('Item'))
    display.find("Properties/string[@name='Name']").text=f'GarageDisplay_{vehicle}'
    x=-72+(vehicle-1)%5*5.4;z=1+((vehicle-1)//5)*10
    factor=.62
    for node in display.iter('Item'):
        props=node.find('Properties')
        cf=props.find("CoordinateFrame[@name='CFrame']")
        size=props.find("Vector3[@name='size']")
        if cf is not None:
            for axis,offset in zip('XYZ',(x,8.65,z)):cf.find(axis).text=str(float(cf.find(axis).text)*factor+offset)
        if size is not None:
            for axis in 'XYZ':size.find(axis).text=str(float(size.find(axis).text)*factor)
    showroom.append(display)
    part(showroom,'DisplayPlinth',(4.8,.35,5),(x,8.4,z),(30,82,104))
    plaque(showroom,str(vehicle)+(' BIKE' if vehicle<=6 else ' MOPED'),(x,9.1,z+2.7),4.8,(31,98,123),.9)
# Three visibly different eggs with rings, plinths and canopies.
for id,(z,color,title,price) in enumerate([(-18,(255,205,61),'TROPICAL',100),(5,(85,223,121),'JUNGLE',750),(28,(78,208,255),'WATERFALL',4000)],1):
    station,_=item(model,'Model',f'EggStation_{id}')
    part(station,'Platform',(14,.35,17),(60,8.175,z),(27,87,100))
    part(station,'Pedestal',(7,1,7),(60,8.85,z),color)
    part(station,'Egg',(3.6,5,3.6),(60,12,z),color,288,False,shape=0)
    for j in range(6):
        a=j*math.tau/6;part(station,'EggSpot',(.65,.7,.4),(60+math.sin(a)*1.65,12+math.sin(j*2)*.7,z+math.cos(a)*1.65),(234,255,222),288,False,shape=0)
    for side in [-1,1]:part(station,'CanopyPost',(.4,9,.4),(60+side*6,12.5,z+5),(231,231,180),collide=False)
    part(station,'Canopy',(14,1,10),(60,17,z+3),color)
    plaque(station,f'{title} EGG / {price} CASH',(60,16.2,z-2),17,color,2.5)
    plaque(station,'E / TAP TO OPEN',(60,9.8,z-6),13,(21,97,114),1.2)
rebirth,_=item(model,'Model','RebirthStation')
part(rebirth,'Platform',(13,.35,13),(-27,8.175,29),(23,100,120))
part(rebirth,'RebirthOrb',(3.2,3.2,3.2),(-27,11.5,29),(255,221,82),288,False,shape=0)
for i in range(10):
    a=i*math.tau/10;part(rebirth,'OrbitCrystal',(.6,1.2,.6),(-27+math.sin(a)*3.1,11.3+math.cos(a)*1.5,29+math.cos(a)*3.1),(72,239,212),288,False,yaw=i*36)
plaque(rebirth,'REBIRTH / +0.5x FOREVER',(-27,17,32),22,(35,166,180),3)
# Cohesive clusters, curved palm silhouettes, blossoms with stems and petals.
decor,_=item(model,'Folder','TropicalDecor')
locations=[(-70,-28),(70,-33),(-67,40),(58,56),(-25,68),(31,70),(-75,-5),(73,-2),(-42,-69),(31,-72),(-9,72),(45,48)]
for i,(x,z) in enumerate(locations):palm(decor,x,z,14+(i%4)*2,i)
for i,(x,z) in enumerate([(-49,-27),(-32,-26),(33,-25),(-40,42),(25,43),(43,48),(-63,-22),(23,68),(-15,58),(76,26)]):
    bush,_=item(decor,'Model',f'FlowerGarden_{i}')
    for j in range(4):part(bush,'Bush',(3,2.4,3),(x+math.sin(j*2)*1.8,9,z+math.cos(j*2)*1.8),(40+j*7,143+j*9,78),1280,False,shape=0)
    for j in range(5):
        fx=x+math.sin(j*2.4)*2.5;fz=z+math.cos(j*2.4)*2.5
        beam(bush,'FlowerStem',(fx,8,fz),(fx,10.6,fz),.12,(48,124,67))
        for k in range(4):part(bush,'FlowerPetal',(.8,.35,.8),(fx+math.sin(k*math.pi/2)*.4,10.6,fz+math.cos(k*math.pi/2)*.4),(255,170+(i%3)*25,91+(j%2)*65),collide=False,shape=0)
        part(bush,'FlowerHeart',(.35,.3,.35),(fx,10.8,fz),(255,239,120),288,False,shape=0)
for i,(x,z) in enumerate([(-78,29),(75,39),(-73,-49),(73,-48),(-49,64),(20,78)]):
    for j in range(3):part(decor,'ShoreRock',(5+j,3+j,5),(x+j*1.8,8.7+j*.3,z+math.sin(j)*2),(123+j*10,145+j*7,130+j*9),896,shape=0)
for i,(x,z) in enumerate([(-10,-31),(10,31),(-40,5),(44,-3),(-23,48),(36,56)]):
    part(decor,'PathLamp',(1.2,1.6,1.2),(x,9.7,z),(255,232,161),288,False)
    part(decor,'LampBase',(.6,1,.6),(x,8.5,z),(106,79,51),512)
E.indent(world)
content=E.tostring(world,encoding='utf-8',xml_declaration=True)+b'\n'
path=ROOT/'src/world/World1.rbxmx'
if '--check' in __import__('sys').argv:
    if not path.exists() or path.read_bytes()!=content:raise SystemExit('World asset differs: run python3 tools/build_world.py')
    print('World1 source matches deterministic generator')
else:path.write_bytes(content);print('Generated',path)
