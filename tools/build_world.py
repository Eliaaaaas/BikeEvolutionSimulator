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

model,_=item(world,'Model','World1')
terrain,_=item(model,'Folder','Island')
# Contiguous 4-stud strips: every walkable grass surface is exactly y=8.
for row in range(44):
    z=-86+row*4
    radius=math.sqrt(max(0,1-(z/90)**2))
    half=85*radius*(1+0.045*math.sin(row*0.76)+0.035*math.cos(row*1.4))
    shift=3*math.sin(row*0.57)
    part(terrain,f'Sand_{row}',(half*2+5,7.5,4),(shift,3.75,z),(239,205,135),1296)
    part(terrain,f'Grass_{row}',(half*2,8,4),(shift,4,z),(97,195,105),1280)
part(model,'Ocean',(650,2,650),(0,-1,0),(29,173,205),288,False,0.28)
spawn,sp=part(model,'IslandSpawn',(12,0.2,12),(0,8.1,0),(255,222,94),cls='SpawnLocation')
prop(sp,'bool','Neutral',True);prop(sp,'float','Duration',0)
sign(model,'PALM BAY  /  WELT 1',(0,15,-12),(30,5,1))
# Back wall and two decorative waterfalls; all geometry uses built-in parts.
part(model,'BackWall',(110,28,9),(0,22,-76),(92,115,109),896)
for x in [-56,56]:
    part(model,'Waterfall',(7,25,2),(x,20.5,-68),(100,224,255),288,False,0.3)
    part(model,'WaterfallPool',(16,0.15,10),(x,8.08,-64),(100,224,255),288,False,0.2)
    part(model,'WaterfallRock',(14,30,9),(x,23,-73),(104,123,116),896)
training,_=item(model,'Folder','Training')
xs=[-54,-36,-18,24,42]
colors=[(72,202,172),(87,185,244),(255,192,79),(255,146,92),(161,130,242)]
for i,(x,color) in enumerate(zip(xs,colors),1):
    treadmill,_=item(training,'Model',f'Treadmill_{i}')
    part(treadmill,'Deck',(11,1,15),(x,8.5,-51),color)
    part(treadmill,'Belt',(8,0.2,12),(x,9.1,-51),(45,78,86))
    # Non-colliding marker: server validates root position relative to this exact zone.
    part(treadmill,'Zone',(8,0.1,12),(x,9.2,-51),color,collide=False,transparency=1)
    for side in [-4.8,4.8]:
        part(treadmill,'RailPost',(0.5,4,0.5),(x+side,11,-56),(227,245,244))
        part(treadmill,'Handrail',(0.5,0.5,10),(x+side,13,-52),(227,245,244))
    sign(treadmill,f'{i}  /  +{2**(i-1)} ENERGY',(x,17,-59),(13,4,1),color)
part(training,'PremiumReserved',(20,0.12,17),(3,8.06,-51),(255,221,132),collide=False)
sign(training,'PREMIUM\nPLATZ RESERVIERT',(3,15,-59),(22,6,1),(211,150,51))
# Clearly labelled, non-interactive previews.
for name,text,x,z,color in [
 ('RacePreview','RACE / TEST-RENNEN',0,63,(255,151,74)),
 ('GaragePreview','GARAGE / MOUNTAINBIKE',-61,10,(69,171,229)),
 ('EggsPreview','EGGS / VORSCHAU',60,10,(159,127,224)),
 ('WorldPreview','WORLDS / VORSCHAU',60,36,(47,183,165))]:
    place,_=item(model,'Model',name)
    part(place,'Platform',(22,0.2,16),(x,8.1,z),color)
    sign(place,text,(x,16,z-4),(24,5,1),color,face=5)
    for side in [-11,11]:part(place,'ArchPost',(1.5,13,1.5),(x+side,14.5,z-4),color)
    part(place,'ArchTop',(24,1.5,1.5),(x,21,z-4),color)
decor,_=item(model,'Folder','TropicalDecor')
for index,(x,z) in enumerate([(-66,-30),(63,-27),(-59,43),(47,57),(-31,66),(28,70),(-71,-3),(70,-3),(-41,-70),(35,-70)]):
    palm,_=item(decor,'Model',f'Palm_{index}')
    part(palm,'Trunk',(2.3,18,2.3),(x,17,z),(145,104,66),512)
    part(palm,'Crown',(6,3,6),(x,26,z),(57,164,86),shape=0)
    for leaf in range(6):
        angle=leaf*math.pi/3
        part(palm,'Leaf',(4,0.7,13),(x+math.sin(angle)*5,26,z+math.cos(angle)*5),(49,161,89),yaw=leaf*60)
for i,(x,z) in enumerate([(-70,28),(70,25),(-70,-46),(66,-48),(-48,62),(21,77)]):
    part(decor,f'Rock_{i}',(8+i%3,6,7),(x,10,z),(120,138,130),896,shape=0)
E.indent(world)
content=E.tostring(world,encoding='utf-8',xml_declaration=True)+b'\n'
path=ROOT/'src/world/World1.rbxmx'
if '--check' in __import__('sys').argv:
    if not path.exists() or path.read_bytes()!=content: raise SystemExit('World asset differs: run python3 tools/build_world.py')
    print('World1 source matches deterministic generator')
else:
    path.write_bytes(content);print('Generated',path)
