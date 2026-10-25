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
