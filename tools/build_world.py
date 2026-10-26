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

def capsule(parent,name,width,height,depth,pos,color,material=256):
    part(parent,name,(max(.1,width-height),height,depth),pos,color,material,False)
    for side in [-1,1]:
        node,props=part(parent,name+'Cap',(depth,height,height),(pos[0]+side*(width-height)/2,pos[1],pos[2]),color,material,False,shape=2)
        cf=props.find("CoordinateFrame[@name='CFrame']")
        for row in range(3):
            for col in range(3):cf.find(f'R{row}{col}').text=str([[0,0,1],[0,1,0],[-1,0,0]][row][col])

def ring(parent,name,center,radius,color,segments=10):
    for j in range(segments):
        a=j*math.tau/segments;b=(j+1)*math.tau/segments
        beam(parent,name,(center[0]+math.sin(a)*radius,center[1]+math.cos(a)*radius,center[2]),(center[0]+math.sin(b)*radius,center[1]+math.cos(b)*radius,center[2]),.15,color,288)

def marquee(parent,title,pos,width,color,height=4,kind=None):
    kind=kind or ('Garage' if 'GARAGE' in title else 'Eggs' if 'EGG' in title or 'PET' in title else 'Race' if 'RACE' in title or 'START' in title or 'ZIEL' in title else 'Worlds' if 'WORLD' in title or 'PORTAL' in title else 'Shop' if 'SHOP' in title else 'Training' if 'TRAIN' in title else 'VIP' if 'VIP' in title else 'Island')
    colors={'Garage':((60,162,244),(255,218,83)),'Eggs':((224,103,195),(255,219,112)),'Race':((240,87,65),(255,201,64)),'Worlds':((74,204,225),(169,127,249)),'Shop':((56,184,118),(255,221,102)),'Training':((50,212,232),(255,109,191)),'VIP':((237,189,61),(129,225,245)),'Island':((43,161,162),(255,222,132))}
    primary,accent=colors[kind]
    model,_=item(parent,'Model','V4Sign_'+kind)
    dark=tuple(int(v*.48) for v in primary)
    trim=min(1,height/3) # Small showroom labels must fit between neighboring plinths.
    capsule(model,'SculptedBack',width+1.6*trim,height+1.4*trim,.65,(pos[0],pos[1],pos[2]-.1),dark)
    capsule(model,'NeonContour',width+.7*trim,height+.7*trim,.15,(pos[0],pos[1],pos[2]+.32),accent,288)
    capsule(model,'EnamelFace',width,height,.28,(pos[0],pos[1],pos[2]+.49),primary)
    # Invisible carriers keep the words inside rounded geometry with explicit margins.
    for face,dz in [(2,.66),(5,-.47)]:
        carrier,props=part(model,'V4Caption',(width-.6,height-.3,.03),(pos[0],pos[1],pos[2]+dz),primary,collide=False,transparency=1)
        gui,gp=item(carrier,'SurfaceGui','CaptionSurface');prop(gp,'token','Face',face);prop(gp,'float','PixelsPerStud',48)
        label,lp=item(gui,'TextLabel','Caption');prop(lp,'string','Text',title);prop(lp,'bool','TextScaled',True);prop(lp,'bool','TextWrapped',False);prop(lp,'float','BackgroundTransparency',1);prop(lp,'token','Font',20)
        c=E.SubElement(lp,'Color3',name='TextColor3')
        ink=(.07,.20,.28) if kind in ['VIP','Eggs'] else (1,1,1)
        for k,v in zip('RGB',ink):E.SubElement(c,k).text=str(v)
        u=E.SubElement(lp,'UDim2',name='Size')
        for k,v in [('XS',.78 if width>=16 else .92),('XO',0),('YS',.8),('YO',0)]:E.SubElement(u,k).text=str(v)
        u=E.SubElement(lp,'UDim2',name='Position')
        for k,v in [('XS',.18 if width>=16 else .04),('XO',0),('YS',.1),('YO',0)]:E.SubElement(u,k).text=str(v)
    if width>=16:
        x,y,z=pos[0]-width*.38,pos[1],pos[2]+.9;r=min(1.1,height*.23)
        if kind=='Garage':
            for side in [-1,1]:ring(model,'BikeWheel',(x+side*r*.7,y-r*.3,z),r*.55,accent,6)
            for a,b in [((x-r*.7,y-r*.3,z),(x,y+r*.6,z)),((x,y+r*.6,z),(x+r*.7,y-r*.3,z)),((x-r*.7,y-r*.3,z),(x+r*.7,y-r*.3,z))]:beam(model,'BikeFrame',a,b,.13,(137,251,240),288)
        elif kind=='Eggs':
            part(model,'EggIcon',(r*1.3,r*1.8,r*.6),(x,y,z),accent,288,False,shape=0)
            for k in [-1,1]:part(model,'StarGem',(.3,.3,.2),(x+k*r,y+k*r*.5,z),(255,244,168),288,False,shape=0)
        elif kind=='Race':
            beam(model,'FlagPole',(x-r*.7,y-r,z),(x-r*.7,y+r,z),.14,accent,288)
            for i in range(3):
                for j in range(2):part(model,'CheckeredFlag',(.5,.5,.12),(x-r*.4+i*.5,y+r*.3+j*.5,z),(255,249,212) if (i+j)%2==0 else (53,76,107),collide=False)
        elif kind=='Worlds':ring(model,'PortalIcon',(x,y,z),r,accent,12)
        elif kind=='Shop':
            ring(model,'CoinRim',(x,y,z),r,accent,10)
            beam(model,'CoinStamp',(x,y-r*.5,z),(x,y+r*.5,z),.35,accent,288)
        elif kind=='VIP':
            for i in range(5):
                a=i*math.tau/5;beam(model,'StarRay',(x,y,z),(x+math.sin(a)*r,y+math.cos(a)*r,z),.25,accent,288)
        else:
            for a,b in [((x+.3,y+r,z),(x-.4,y,z)),((x-.4,y,z),(x+.4,y,z)),((x+.4,y,z),(x-.3,y-r,z))]:beam(model,'EnergyBolt',a,b,.22,accent,288)
    # Icons are authored on both faces, so signs read correctly from either approach.
    import copy
    icon_names={'BikeWheel','BikeFrame','EggIcon','StarGem','FlagPole','CheckeredFlag','PortalIcon','CoinRim','CoinStamp','StarRay','EnergyBolt'}
    for node in list(model.findall('Item')):
        if node.findtext("Properties/string[@name='Name']") not in icon_names:continue
        back=copy.deepcopy(node);cf=back.find("Properties/CoordinateFrame[@name='CFrame']")
        cf.find('Z').text=str(2*pos[2]-float(cf.find('Z').text));model.append(back)
    return model

def plaque(parent,title,pos,width,color=(27,126,119),height=4):
    return marquee(parent,title,pos,width,color,height)

def palm(parent,x,z,height=17,index=0,ground=8):
    tree,_=item(parent,'Model',f'Palm_{index}')
    lean=2*math.sin(index+1);top=(x+lean,ground+height,z+1.4)
    for segment in range(5):
        t=segment/5;u=(segment+1)/5
        a=(x+lean*t*t,ground+height*t,z+1.4*t*t);b=(x+lean*u*u,ground+height*u,z+1.4*u*u)
        beam(tree,'TrunkSegment',a,b,1.5-segment*.16,(147+segment*6,102+segment*3,60),512)
    for leaf in range(7):
        a=leaf*math.tau/7+index*.3;dx,dz=math.sin(a),math.cos(a)
        tip=(top[0]+dx*8,top[1]-1.2,top[2]+dz*8)
        beam(tree,'LeafSpine',top,tip,.18,(52,139,72))
        for segment in range(3):
            t=(segment+1)/4;cx=top[0]+dx*8*t;cz=top[2]+dz*8*t;cy=top[1]+math.sin(t*math.pi)*.9-t*1.2
            for side in [-1,1]:
                end=(cx+dz*side*(1.5-t*.8),cy-.35,cz-dx*side*(1.5-t*.8))
                beam(tree,'TaperedLeaflet',(cx,cy,cz),end,.6-t*.2,(45+leaf*3,160+segment*9,84),1280)
    for i in range(3):part(tree,'Coconut',(1,1.2,1),(top[0]+math.sin(i*2)*.9,top[1]-.5,top[2]+math.cos(i*2)*.9),(117,79,43),shape=0,collide=False)

model,_=item(world,'Model','World1')
terrain,_=item(model,'Folder','Island')
# Rectangular cores plus thin triangular coast wedges form a continuous polygonal contour.
# Every grass collision face is exactly y=8; no random overlapping blocks or terrain humps.
def coast_layer(name,y,thickness,leftA,leftB,rightA,rightB,zA,zB,color,material):
    coreL=max(leftA,leftB);coreR=min(rightA,rightB);z=(zA+zB)/2
    part(terrain,name,(coreR-coreL,thickness,zB-zA),((coreL+coreR)/2,y,z),color,material)
    for side,a,b in [(-1,leftA,leftB),(1,rightA,rightB)]:
        delta=abs(b-a)
        if delta<.005:continue
        direction=1 if (b<a if side==-1 else b>a) else -1
        node,props=part(terrain,'CoastGrass' if name.startswith('Grass') else 'CoastSand',(thickness,delta,zB-zA),((a+b)/2,y,z),color,material,cls='WedgePart')
        cf=props.find("CoordinateFrame[@name='CFrame']")
        for row in range(3):
            for col in range(3):cf.find(f'R{row}{col}').text=str([[0,side,0],[-direction*side,0,0],[0,0,direction]][row][col])
boundary=[]
for i in range(97):
    z=-91.2+i*1.9
    radius=math.sqrt(max(.001,1-(z/92)**2))
    half=83*radius*(1+.06*math.sin(i*.14)+.035*math.cos(i*.31))
    shift=4*math.sin(i*.09)+2*math.cos(i*.17)
    boundary.append((shift-half,shift+half,z))
for row in range(96):
    lA,rA,zA=boundary[row];lB,rB,zB=boundary[row+1]
    coast_layer(f'Sand_{row}',3.8,6.4,lA-5,lB-5,rA+5,rB+5,zA,zB,(244,218,156),1296)
    coast_layer(f'Grass_{row}',7.5,1,lA,lB,rA,rB,zA,zB,(90,192,107),1280)
ocean,op=part(model,'Ocean',(1250,2,1250),(0,-1,200),(25,135,178),256,False,.12)
prop(op,'float','Reflectance',.08)
# Shallow lagoon shelves make the coastline read as an island, not a box on water.
for i in range(26):
    a=i*math.tau/26;x=math.sin(a)*87;z=math.cos(a)*88
    part(terrain,'LagoonShelf',(12,1,14),(x,-.35,z),(79,192,195),256,False,.8,shape=0)
spawn,sp=part(model,'IslandSpawn',(10,.16,10),(0,8.08,0),(255,225,104),cls='SpawnLocation')
prop(sp,'bool','Neutral',True);prop(sp,'float','Duration',0)
for side in [-1,1]:part(model,'SpawnNeon',(.15,.1,10),(side*5.2,8.12,0),(104,251,218),288,False)
welcome,_=item(model,'Model','IslandWelcome')
marquee(welcome,'PALM BAY',(0,16,-14),26,(43,161,162),4.2,'Island')
for x in [-10,10]:beam(welcome,'BambooSupport',(x,8,-14),(x,15,-14),.6,(167,126,74),512)
# Terraced waterfall cliffs with larger cascades and layered pools, behind the belts.
for i,x in enumerate(range(-65,66,13)):
    part(model,'CliffBase',(16,22+(i%3)*3,12),(x,17,-76),(100+i%3*9,126,115),896,shape=0)
    part(model,'CliffCrown',(17,3,14),(x,30+(i%3)*1.5,-77),(71,154,97),1280,shape=0)
for x in [-57,57]:
    part(model,'Waterfall',(9,29,1.4),(x,23,-68),(83,215,243),1568,False,.25)
    part(model,'Waterfall',(5,29,.4),(x+.8,23,-67.1),(173,246,255),1568,False,.56)
    part(model,'WaterfallPool',(20,.15,11),(x,8.1,-64),(88,211,232),288,False,.25,shape=0)
    for j in [-1,1]:part(model,'PoolRock',(5,3,6),(x+j*9,8,-65),(138,157,143),896,shape=0)
training,_=item(model,'Folder','Training')
xs=[-54,-36,-18,24,42]
colors=[(43,225,166),(52,185,255),(255,205,65),(255,126,65),(159,121,255)]
def oval(parent,name,width,depth,thickness,pos,color,material):
    node,props=part(parent,name,(thickness,width,depth),pos,color,material,False,shape=2)
    cf=props.find("CoordinateFrame[@name='CFrame']")
    for row in range(3):
        for col in range(3):cf.find(f'R{row}{col}').text=str([[0,-1,0],[1,0,0],[0,0,1]][row][col])
    return node
for i,(x,color) in enumerate(zip(xs,colors),1):
    treadmill,_=item(training,'Model',f'Treadmill_{i}')
    accent=colors[i%len(colors)]
    oval(treadmill,'RoundedBase',14,18,.5,(x,8.25,-51),(31,53,78),1088)
    oval(treadmill,'NeonRim',14.3,18.3,.14,(x,8.54,-51),color,288)
    oval(treadmill,'RoundedLayer',12.5,16.5,.4,(x,8.75,-51),accent,256)
    part(treadmill,'Deck',(10.5,.5,14),(x,8.8,-51),(26,43,64))
    part(treadmill,'Belt',(8,.2,12),(x,9.15,-51),(19,33,53))
    part(treadmill,'Zone',(8,.1,12),(x,9.3,-51),color,collide=False,transparency=1)
    for side in [-1,1]:
        part(treadmill,'NeonEdge',(.22,.25,14.4),(x+side*5.4,9.2,-51),color,288,False)
        beam(treadmill,'PowerArm',(x+side*5.5,9,-55),(x+side*3.5,11.8,-57),.4,(123,154,180),1088)
        part(treadmill,'JointGlow',(.8,.8,.8),(x+side*3.5,11.8,-57),accent,288,False,shape=0)
    for j in range(8):part(treadmill,f'BeltStripe_{j}',(7.7,.025,.15),(x,9.265,-56+j*1.4),color if j%2 else accent,288,False)
    for j in range(3):
        for side in [-1,1]:part(treadmill,f'DirectionChevron_{j}_{side}',(.13,.03,1.2),(x+side*.35,9.28,-54+j*3),(232,255,245),288,False,yaw=side*35)
    part(treadmill,'PowerCore',(1.5+i*.12,1.5+i*.12,1.5+i*.12),(x,11.3,-57.2),accent,288,False,shape=0)
    for j in range(6+i):
        angle=j*math.tau/(6+i)
        part(treadmill,f'OrbitLight_{j}',(.3,.7,.3),(x+math.sin(angle)*2.1,11.3,-57.2+math.cos(angle)*2.1),color,288,False,yaw=j*40)
    for j in range(2+i):
        side=-1 if j%2 else 1
        part(treadmill,'EnergyFin',(.3,1+j*.15,1.4),(x+side*5.7,9.7,-54+(j//2)*2),accent,288,False,cls='WedgePart',yaw=side*90)
part(training,'PremiumReserved',(20,.12,17),(3,8.08,-51),(240,208,120),collide=False)
# Authored curved paths use small oval pavers with shared tangents, not long rectangular roads.
path_points=[]
def route(a,b,c,d,count):
    for i in range(count):
        t=i/(count-1);u=1-t
        x=u*u*u*a[0]+3*u*u*t*b[0]+3*u*t*t*c[0]+t*t*t*d[0]
        z=u*u*u*a[1]+3*u*u*t*b[1]+3*u*t*t*c[1]+t*t*t*d[1]
        dx=3*u*u*(b[0]-a[0])+6*u*t*(c[0]-b[0])+3*t*t*(d[0]-c[0])
        dz=3*u*u*(b[1]-a[1])+6*u*t*(c[1]-b[1])+3*t*t*(d[1]-c[1])
        path_points.append((x,z))
        part(model,'CurvedPaver',(7.1,.07,3.5),(x,8.04,z),(240,223,180),1296,False,shape=0,yaw=math.degrees(math.atan2(dx,dz)))
route((0,-7),(4,-15),(-5,-24),(0,-36),12)
route((0,7),(9,22),(-7,40),(0,54),18)
route((-7,0),(-17,-4),(-32,4),(-44,5),14)
route((7,0),(24,-8),(34,-2),(49,4),15)
route((43,-18),(40,0),(43,20),(48,30),16)
route((9,15),(18,19),(23,23),(26,23),8)
route((-10,38),(-24,36),(-30,42),(-38,50),10)
# Functional stations keep existing stable names/interaction parts.
for name,title,x,z,color in [('RacePreview','RACE / 5 BOTS',0,63,(255,145,56)),('GaragePreview','BIKE GARAGE',-60,8,(53,177,248)),('WorldPreview','WORLD PORTAL',-45,57,(72,224,185))]:
    station,_=item(model,'Model',name)
    w,d=(32,29) if name=='GaragePreview' else (25,15)
    part(station,'Platform',(w,.35,d),(x,8.175,z),color)
    for side in [-1,1]:
        part(station,'ArchPost',(1.2,13,1.2),(x+side*(w/2-1),14.5,z+5),(26,84,101))
        part(station,'ArchGlow',(.3,12,.3),(x+side*(w/2-1),14.5,z+4.3),color,288,False)
    part(station,'ArchTop',(w+1,1.2,2),(x,21,z+5),color,288,False)
    plaque(station,title,(x,20,z+3.7),w,color)
    if name=='RacePreview':
        for side in [-1,1]:
            for j in range(5):part(station,'StartCurb',(2,.25,1.2),(x+side*10,8.4,z-5+j*2),(255,228,105) if j%2 else (245,96,69),collide=False)
    if name=='WorldPreview':
        ring(station,'PortalRim',(x,13.8,z+3),4,(151,112,248),16)
        part(station,'PortalAura',(7,8,.2),(x,13.8,z+3),(96,222,244),288,False,.6,shape=0)
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
# Dedicated zones retain the existing world-1 systems. Premium/VIP monetization remains future content.
shop,_=item(model,'Model','ShopArea')
part(shop,'Platform',(19,.35,15),(32,8.175,24),(49,143,111))
for x in [24,40]:beam(shop,'StallPost',(x,8,29),(x,17,29),.7,(177,133,77),512)
capsule(shop,'Awning',20,2,9,(32,17.5,26),(72,190,122))
marquee(shop,'SHOP',(32,17,20),20,(62,193,127),3.8,'Shop')
for x in [26,38]:beam(shop,'SignBracket',(x,17,20),(x,17,29),.35,(177,133,77),512)
for x in [27,32,37]:
    part(shop,'CoinDisplay',(2.2,2.2,.5),(x,10,24),(255,218,92),288,False,shape=0)
    part(shop,'CounterBase',(3,.7,3),(x,8.5,24),(154,108,60),512,False)
vip,_=item(model,'Model','VIPArea')
part(vip,'PremiumPlatform',(19,.1,13),(30,8.08,61),(228,196,113),256,False)
marquee(vip,'VIP / FUTURE',(30,17,64),23,(241,205,89),3.8,'VIP')
for side in [-1,1]:beam(vip,'GoldPost',(30+side*9,8,64),(30+side*9,16,64),.5,(235,197,78),288)
for j,color in enumerate([(255,125,126),(255,211,86),(120,235,157),(86,215,246),(174,133,246)]):part(vip,'RainbowAccent',(2.8,.12,1),(24+j*3,8.2,57),color,288,False)
egg_area,_=item(model,'Model','EggPetLandmark')
marquee(egg_area,'EGGS & PETS',(60,23,8),25,(231,113,201),4,'Eggs')
for x in [50,70]:beam(egg_area,'GoldenPost',(x,8,8),(x,22,8),.5,(221,185,106),512)
training_landmark,_=item(model,'Model','TrainingLandmark')
marquee(training_landmark,'TRAINING AREA',(0,30,-70),29,(61,222,234),4.2,'Training')
for x in [-12,12]:
    beam(training_landmark,'EnergySupport',(x,8,-72),(x,28,-72),.6,(78,157,187),1088)
    beam(training_landmark,'SignBracket',(x,28,-72),(x,28,-70),.4,(78,157,187),1088)
# Main foliage is kept clear of zone approaches and paths.
decor,_=item(model,'Folder','TropicalDecor')
locations=[(-70,-28),(70,-33),(-67,40),(58,56),(-25,68),(5,72),(-75,-20),(74,-3),(-42,-69),(31,-72),(-7,74),(74,30)]
for i,(x,z) in enumerate(locations):palm(decor,x,z,14+(i%4)*2,i)
# Broad-leaf tropical trees provide different silhouettes without imported meshes.
for i,(x,z) in enumerate([(-30,-29),(27,-27),(-18,62),(71,46)]):
    tree,_=item(decor,'Model','BroadleafTree')
    beam(tree,'BranchTrunk',(x,8,z),(x,18,z),1.1,(134,101,64),512)
    for j in range(3):
        ox=x+math.sin(j*2)*2;oz=z+math.cos(j*2)*2
        beam(tree,'Branch',(x,16,z),(ox,19,oz),.5,(134,101,64),512)
        part(tree,'CanopyLobe',(6,4,6),(ox,20,oz),(62+j*9,160+j*8,86),1280,False,shape=0)
for i,(x,z) in enumerate([(-49,-27),(-32,-26),(33,-25),(-40,42),(25,43),(43,48),(-63,-22),(23,68),(-15,58),(76,26)]):
    bush,_=item(decor,'Model',f'FlowerGarden_{i}')
    for j in range(3):part(bush,'Bush',(3,2.4,3),(x+math.sin(j*2)*1.8,9,z+math.cos(j*2)*1.8),(40+j*7,143+j*9,78),1280,False,shape=0)
    for j in range(4):
        fx=x+math.sin(j*2.4)*2.5;fz=z+math.cos(j*2.4)*2.5
        beam(bush,'FlowerStem',(fx,8,fz),(fx,10.6,fz),.12,(48,124,67))
        for k in range(4):part(bush,'FlowerPetal',(.8,.35,.8),(fx+math.sin(k*math.pi/2)*.4,10.6,fz+math.cos(k*math.pi/2)*.4),(255,140+(i%4)*24,125+(j%2)*70),collide=False,shape=0)
        part(bush,'FlowerHeart',(.35,.3,.35),(fx,10.8,fz),(255,239,120),288,False,shape=0)
# Intentional shallow ponds are visual surfaces; grass beneath stays flat and walkable.
for x,z in [(-33,-11),(22,38)]:
    part(decor,'PondStoneRim',(10,.13,7),(x,8.09,z),(137,162,150),896,False,shape=0)
    part(decor,'PondWater',(8.7,.15,5.8),(x,8.13,z),(68,188,209),256,False,.25,shape=0)
    for j in range(3):part(decor,'LilyPad',(1.3,.05,1),(x+math.sin(j*2)*2,8.24,z+math.cos(j*2)*1.4),(84,178,109),1280,False,shape=0)
for i,(x,z) in enumerate([(-78,29),(75,39),(-73,-49),(73,-48),(-49,64),(20,78)]):
    for j in range(3):part(decor,'ShoreRock',(5+j,3+j,5),(x+j*1.8,7.7+j*.3,z+math.sin(j)*2),(123+j*10,145+j*7,130+j*9),896,False,shape=0)
for x,z in [(-10,-31),(10,31),(-40,-3),(44,-3),(-23,48),(18,51)]:
    part(decor,'PathLamp',(1.2,1.6,1.2),(x,9.7,z),(255,232,161),288,False)
    part(decor,'LampBase',(.6,1,.6),(x,8.5,z),(106,79,51),512,False)
E.indent(world)
content=E.tostring(world,encoding='utf-8',xml_declaration=True)+b'\n'
path=ROOT/'src/world/World1.rbxmx'
if '--check' in __import__('sys').argv:
    if not path.exists() or path.read_bytes()!=content:raise SystemExit('World asset differs: run python3 tools/build_world.py')
    print('World1 source matches deterministic generator')
else:path.write_bytes(content);print('Generated',path)
