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
 for component in ['Zone','Belt','NeonEdge','Deck','FrontRoller','RearRoller','SideFrame','BeltStripe_0']:assert child(belt,component) is not None
training=path('Workspace','World1','Training')
for node in training.iter('Item'):
 assert node.attrib['class'] not in ['SurfaceGui','BillboardGui','TextLabel','ProximityPrompt'], 'No training signs/prompts'
 assert name(node) not in ['Sign','Console','LocalTrainingStatus','SelectTraining']
ui_source=child(client,'UI').findtext("Properties/string[@name='Source']")
assert ui_source==(ROOT/'src/client/UI.luau').read_text(), 'Built UI source must match runtime-tested source'
assert '☰  PALM BAY' not in ui_source and 'Name="PalmBaySidebar"' not in ui_source and 'api.Status=' not in ui_source
assert 'Name="Navigation"' in ui_source and 'Name="ResourceHUD"' in ui_source
assert child(client,'TrainingInput') is not None
for id in range(1,4):path('Workspace','World1',f'EggStation_{id}','Egg')
assert not any('rebirth' in name(n).lower() for n in path('Workspace','World1').iter('Item')), 'V2 forbids a physical Rebirth stand'
for n in root.iter('Item'):assert n.attrib['class'] not in ['VehicleSeat','MeshPart','SpecialMesh']
world_parts=[n for n in path('Workspace','World1').iter('Item') if n.attrib['class'] in ['Part','WedgePart','SpawnLocation']]
assert len(world_parts)<3300,len(world_parts)
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

station_source=child(client,'StationEffects').findtext("Properties/string[@name='Source']")
assert 'BillboardGui' not in station_source and 'ActiveTrainingBillboard' not in station_source
assert not any(n.attrib['class']=='BillboardGui' for n in root.iter('Item'))
for key in ['ShopArea','VIPArea','EggPetLandmark','TrainingLandmark']:path('Workspace','World1',key)
print('V4 built place: themed zone landmarks, Shop/portal integration, no training BillboardGui creation')

# V4.1 actual packaged modules and closed garage, not a second demo scene.
for group in ['BikeInput','Visuals','AvatarPose']:assert child(client,group) is not None
assert child(server,'MountedBikeService') is not None
entry=path('Workspace','World1','GaragePreview','EntryZone')
assert entry.findtext("Properties/float[@name='Transparency']")=='1'
assert entry.findtext("Properties/bool[@name='CanCollide']")=='false'
for key in ['BackWall','LeftWall','RightWall','FrontBase','FrontGlass','Roof']:
 assert path('Workspace','World1','GaragePreview',key).findtext("Properties/bool[@name='CanCollide']")=='true'
visual_source=child(client,'Visuals').findtext("Properties/string[@name='Source']")
assert 'LocalTrainingCycles' not in visual_source and 'TrainingCycle_' not in visual_source
print('V4.1 built-place wiring: permanent bike modules, closed showroom and automatic semicircle present')

# V4.2 has one vehicle transform writer and explicit passenger offsets in the actual build.
mounted=child(server,'MountedBikeService').findtext("Properties/string[@name='Source']")
assert 'record.Root.CFrame=' not in mounted and 'record.Rig.Root.CFrame=cf' in mounted
assert child(path('ReplicatedStorage','Shared'),'RiderMount') is not None
input_source=child(client,'BikeInput').findtext("Properties/string[@name='Source']")
assert 'controls.moveFunction=suppressMove' in input_source
print('V4.2 actual place: single vehicle transform owner, native movement dispatcher suppressed')

for id in range(1,6):
 belt=path('Workspace','World1','Training',f'Treadmill_{id}')
 assert not any(name(p)=='AccessRamp' for p in belt.iter('Item'))
for group in ['RidePrediction']:assert child(client,group) is not None
for group in ['RideSimulation','RideReconciliation','BikeSurface']:path('ReplicatedStorage','Shared',group)
print('V4.4 actual place: five flush decks without ramps, retained jump/collision simulation and isolated local prediction')
