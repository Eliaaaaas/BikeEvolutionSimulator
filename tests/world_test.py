"""Validate structural constraints in the actual Studio map asset, not a parallel layout."""
from pathlib import Path
import xml.etree.ElementTree as ET

root=ET.parse(Path(__file__).resolve().parents[1]/'src/world/World1.rbxmx').getroot()
def name(item):return item.find("Properties/string[@name='Name']").text
def position(item):return [float(item.find(f"Properties/CoordinateFrame[@name='CFrame']/{key}").text) for key in 'XYZ']
def size(item):return [float(item.find(f"Properties/Vector3[@name='size']/{key}").text) for key in 'XYZ']
items=list(root.iter('Item'))
by_name={name(i):i for i in items}
grass=[i for i in items if name(i).startswith('Grass_')]
assert len(grass)==96
assert all(abs(position(i)[1]+size(i)[1]/2-8)<1e-9 for i in grass)
minx=min(position(i)[0]-size(i)[0]/2 for i in grass);maxx=max(position(i)[0]+size(i)[0]/2 for i in grass)
assert 165<maxx-minx<195
assert max(position(i)[2]+size(i)[2]/2 for i in grass)-min(position(i)[2]-size(i)[2]/2 for i in grass)>180
spawn=by_name['IslandSpawn'];assert spawn.attrib['class']=='SpawnLocation';assert position(spawn)[0]==position(spawn)[2]==0
training=by_name['Training'];treadmills=[i for i in training.findall('Item') if name(i).startswith('Treadmill_')]
assert len(treadmills)==5
for i in range(1,6):
 t=by_name[f'Treadmill_{i}'];zone=next(p for p in t.findall('Item') if name(p)=='Zone')
 assert position(zone)[2]<-40
 assert zone.find("Properties/bool[@name='CanCollide']").text=='false'
assert size(by_name['PremiumReserved'])[0]>=20
for required in ['Ocean','Waterfall','GaragePreview','EggStation_1','EggStation_2','EggStation_3','WorldPreview','RacePreview']:assert required in by_name
assert not any('rebirth' in name(i).lower() for i in items), 'Physical Rebirth objects must remain removed'
assert position(by_name['RacePreview'].find('Item'))[2]>40
assert not any(i.attrib['class'] in ['MeshPart','SpecialMesh','Decal','Texture','Script','LocalScript'] for i in items)
print('World asset checks passed: flat ~180x180 island, centered spawn, 5 belts, premium gap, previews, no external assets')
