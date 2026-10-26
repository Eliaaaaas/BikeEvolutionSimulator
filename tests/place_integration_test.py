"""Inspect the actual Rojo-built place. This does not execute Roblox Studio."""
from pathlib import Path
import xml.etree.ElementTree as E
import math,re
ROOT=Path(__file__).resolve().parents[1]
root=E.parse(ROOT/'build/BikeEvolutionSimulator.rbxlx').getroot()
def name(node):return node.findtext("Properties/string[@name='Name']")
def child(node,key):return next((n for n in node.findall('Item') if name(n)==key),None)
def path(*keys):
 node=root
 for key in keys:
  node=child(node,key);assert node is not None,'Missing built path: '+ '/'.join(keys)
 return node
parents={c:p for p in root.iter('Item') for c in p.findall('Item')}
scripts=[n for n in root.iter('Item') if n.attrib['class'] in ['Script','LocalScript','ModuleScript']]
for node in scripts:
 source=node.findtext("Properties/string[@name='Source']") or ''
 assert source.strip(),name(node)
 for chain in re.findall(r'require\(script((?:\.[A-Za-z_]\w*)+)\)',source):
  target=node
  for part in chain.split('.')[1:]:
   target=parents.get(target) if part=='Parent' else child(target,part)
   assert target is not None,f'{name(node)} has unresolved require(script{chain})'
  assert target.attrib['class']=='ModuleScript',f'{name(node)} requires non-module {chain}'
server=path('ServerScriptService','Server');client=path('StarterPlayer','StarterPlayerScripts','Client')
assert server.attrib['class']=='Script' and client.attrib['class']=='LocalScript'
for node in [server,client]:assert node.findtext("Properties/bool[@name='Disabled']")!='true'
assert server.findtext("Properties/token[@name='RunContext']") in ['0',None]
assert len([s for s in scripts if s.attrib['class']=='Script'])==1
assert len([s for s in scripts if s.attrib['class']=='LocalScript'])==1
for group in ['ClientApp','UI','RaceCamera','StationEffects']:assert child(client,group) is not None
assert 'Gui=gui' in child(client,'UI').findtext("Properties/string[@name='Source']")
for id in range(1,11):
 key='Mountainbike' if id==1 else f'Vehicle{id}'
 vehicle=path('ReplicatedStorage','Vehicles',key)
 for part in ['Root','Frame','Steering','FrontWheel','RearWheel']:assert child(vehicle,part) is not None
 showroom=path('Workspace','World1','GarageShowroom',f'GarageDisplay_{id}')
 visible=[n for n in showroom.iter('Item') if n.attrib['class']=='Part' and n.findtext("Properties/float[@name='Transparency']")!='1']
 assert len(visible)>20
 for n in visible:assert n.findtext("Properties/bool[@name='Anchored']")=='true'
for id in range(1,6):
 belt=path('Workspace','World1','Training',f'Treadmill_{id}')
 for component in ['Zone','Belt','NeonEdge','Console','BeltStripe_0']:assert child(belt,component) is not None
for id in range(1,4):path('Workspace','World1',f'EggStation_{id}','Egg')
assert not any('rebirth' in name(n).lower() for n in path('Workspace','World1').iter('Item')), 'V2 forbids a physical Rebirth stand'
for n in root.iter('Item'):assert n.attrib['class'] not in ['VehicleSeat','MeshPart','SpecialMesh']
world_parts=[n for n in path('Workspace','World1').iter('Item') if n.attrib['class'] in ['Part','SpawnLocation']]
assert len(world_parts)<2800,len(world_parts)
# Verify real non-circular, three-dimensional centerline, including full arc length.
source=(ROOT/'src/shared/CourseData.luau').read_text()
points=[tuple(map(float,m)) for m in re.findall(r'X=([\-\d.]+),Y=([\-\d.]+),Z=([\-\d.]+)',source)]
length=sum(math.dist(a,b) for a,b in zip(points,points[1:]))
assert abs(length-800)<.001
assert math.dist(points[0],points[-1])>400
assert max(p[1] for p in points)-min(p[1] for p in points)>5
turns=[b[0]-a[0] for a,b in zip(points,points[1:])]
assert sum(a*b<0 for a,b in zip(turns,turns[1:]))>=3
for a,b in zip(points,points[1:]):assert abs(b[1]-a[1])/math.dist(a,b)<.2
print(f'Built-place integration passed: script mapping, requires, ten visible showroom bikes, station dependencies, {len(world_parts)} island parts, open 800-stud elevated S-course. NOT a Studio run.')
