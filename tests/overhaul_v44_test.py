"""Read the real generated geometry/source. Does not run the Roblox renderer."""
from pathlib import Path
import math,re,unittest,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]
def name(n):return n.findtext("Properties/string[@name='Name']")
def vector(n,prop):return [float(n.findtext(f'Properties/{prop}/{a}')) for a in 'XYZ']
def cf(n):return vector(n,"CoordinateFrame[@name='CFrame']")
def size(n):return vector(n,"Vector3[@name='size']")
def rotation(n):return [[float(n.findtext(f"Properties/CoordinateFrame[@name='CFrame']/R{r}{c}")) for c in range(3)] for r in range(3)]
world=E.parse(ROOT/'src/world/TestCourse.rbxmx').getroot()
class OverhaulV44(unittest.TestCase):
 def test_triangle_strips_share_actual_seam_vertices(self):
  roads=sorted([n for n in world.iter('Item') if name(n).startswith('Road_')],key=lambda n:int(name(n).split('_')[1]))
  self.assertEqual(len(roads),120)
  all_vertices=[]
  for road in roads:
   vertices=set()
   for p in road.findall('Item'):
    self.assertEqual(p.attrib['class'],'WedgePart');r=rotation(p);s=size(p);center=cf(p)
    self.assertGreater(abs(r[1][0]),.97) # Triangle thickness follows the nearly vertical road normal.
    self.assertTrue(all(math.isfinite(v) for v in center+s+sum(r,[])))
    for y,z in [(-s[1]/2,-s[2]/2),(-s[1]/2,s[2]/2),(s[1]/2,s[2]/2)]:
     vertices.add(tuple(round(center[a]+r[a][1]*y+r[a][2]*z,6) for a in range(3)))
   all_vertices.append(vertices)
  for a,b in zip(all_vertices,all_vertices[1:]):
   self.assertGreaterEqual(len(a&b),2,'Adjacent road faces must reuse both real edge vertices')
 def test_low_guards_curbs_and_decor_clear_vehicle_lanes(self):
  nodes=list(world.iter('Item'));guards=[n for n in nodes if name(n).startswith('Barrier_')]
  self.assertEqual(len(guards),240)
  for p in guards:self.assertLessEqual(size(p)[1],.8);self.assertEqual(p.findtext("Properties/bool[@name='CanCollide']"),'true')
  self.assertEqual(len([n for n in nodes if name(n)=='RaceCurb']),240)
  for p in nodes:
   if name(p) in ['TrackLampPost','SpectatorDeck','TropicalFlower','TrackWaterfall']:
    self.assertEqual(p.findtext("Properties/bool[@name='CanCollide']"),'false')
 def test_ui_uses_vector_resources_and_one_camera_owner(self):
  icons=(ROOT/'src/client/Icons.luau').read_text();self.assertIn('BoltFace',icons);self.assertIn('RebirthArc',icons);self.assertIn('EmbossedDollar',icons)
  self.assertNotIn('symbol.Text=',icons)
  prediction=(ROOT/'src/client/RidePrediction.luau').read_text();self.assertNotIn('camera.CameraSubject=',prediction)
  camera=(ROOT/'src/client/RaceCamera.luau').read_text();self.assertIn('Camera.Value-1',camera)
  self.assertIn('Camera.Value-2',prediction)
  self.assertNotIn('RenderStepped:Connect',camera)
 def test_generated_place_contains_new_services_and_no_ramps(self):
  place=E.parse(ROOT/'build/BikeEvolutionSimulator.rbxlx').getroot();nodes=list(place.iter('Item'))
  names={name(n) for n in nodes}
  for expected in ['PremiumService','AutomationService','Progression','PremiumRules','PremiumConfig','ExclusiveSunfox','AutoNavigation']:self.assertIn(expected,names)
  self.assertNotIn('AccessRamp',names)
  for n in nodes:
   self.assertNotEqual(n.attrib['class'],'BillboardGui')
 def test_progression_csv_matches_all_catalogue_ids(self):
  import csv
  with (ROOT/'docs/PROGRESSION_V44.csv').open() as stream:rows=list(csv.DictReader(stream))
  self.assertEqual(len(rows),40)
  for i,row in enumerate(rows,1):
   self.assertEqual(int(row['Belt']),i);self.assertEqual(int(row['EnergyPerSecond']),2**(i-1))
   self.assertEqual(int(row['Energy']),0 if i==1 else 84*(i-1)*2**(i-2))
  self.assertAlmostEqual(float(rows[-1]['Baseline seconds'])/3600,9.555)
if __name__=='__main__':unittest.main(verbosity=2)
