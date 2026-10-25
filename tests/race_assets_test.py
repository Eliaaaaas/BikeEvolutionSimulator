from pathlib import Path
import xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
def names(root):return {i.find("Properties/string[@name='Name']").text:i for i in root.iter('Item')}
bike=E.parse(ROOT/'src/models/Mountainbike.rbxmx').getroot();n=names(bike)
for name in ['Mountainbike','Root','Frame','FrontWheel','RearWheel','Steering','Crank','Saddle','Pedal','Fork','Handlebar','Spoke','Tread','Rim','Grip']:assert name in n,name
assert len([i for i in bike.iter('Item') if i.find("Properties/string[@name='Name']").text=='Tread'])==48
for i in bike.iter('Item'):assert i.attrib['class'] not in ['MeshPart','Script','LocalScript','VehicleSeat']
track=E.parse(ROOT/'src/world/TestCourse.rbxmx').getroot();n=names(track)
for name in ['Bridge','START0','ZIEL0','Road_0','Road_119']:assert name in n,name
assert len([i for i in track.iter('Item') if i.find("Properties/string[@name='Name']").text.startswith('Road_')])==120
print('Race asset checks passed: MTB parts, 48 tread segments, no manual VehicleSeat, 120 road segments, start/finish/bridge')

features={2:'Basket',3:'StuntPeg',4:'DropBar',5:'AeroExtension',6:'SplitCarbonSeat',7:'ClassicTank',8:'LegShield',9:'SportFairing',10:'RacingTail'}
for id,feature in features.items():
 tree=E.parse(ROOT/f'src/models/Vehicle{id}.rbxmx').getroot();n=names(tree)
 assert feature in n and 'FrontWheel' in n and 'RearWheel' in n and 'Steering' in n
 if id<=6:assert 'Crank' in n and 'Pedal' in n
 else:assert 'Crank' not in n and 'EngineBlock' in n and 'Exhaust' in n
pet_features=['CoconutShell','Beak','Shell','LongTail','Muzzle','HindLeg','Coil','Stripe','Halo','ExternalGill','Dorsal','DragonWing']
for id,feature in enumerate(pet_features,1):
 tree=E.parse(ROOT/f'src/models/Pet{id}.rbxmx').getroot();assert feature in names(tree)
 assert len(list(tree.iter('Item')))<25
print('Fleet/pet structure passed: 6 distinct bicycles, 4 pedal-free mopeds and 12 low-part species')
