"""Actual serialized asset/Place QA. Native text measurement and visual acceptance require Studio."""
from pathlib import Path
import math, unittest, xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[1]

def name(n):return n.findtext("Properties/string[@name='Name']")
def vector(n,key):return [float(n.findtext(f'Properties/{key}/{a}')) for a in 'XYZ']
def position(n):return vector(n,"CoordinateFrame[@name='CFrame']")
def size(n):return vector(n,"Vector3[@name='size']")
def rotation(n):return [[float(n.findtext(f"Properties/CoordinateFrame[@name='CFrame']/R{r}{c}")) for c in range(3)] for r in range(3)]
def bounds(n):
 p,s,r=position(n),size(n),rotation(n)
 h=[sum(abs(r[a][b])*s[b]/2 for b in range(3)) for a in range(3)]
 return [p[a]-h[a] for a in range(3)],[p[a]+h[a] for a in range(3)]
def colors(n,key):
 raw=n.find(f'Properties/Color3[@name="{key}"]')
 if raw is not None:return [float(raw.findtext(k)) for k in 'RGB']
 packed=int(n.findtext('Properties/Color3uint8[@name="Color3uint8"]'))
 return [(packed>>shift&255)/255 for shift in (16,8,0)]
asset=E.parse(ROOT/'src/world/World1.rbxmx').getroot()
items=list(asset.iter('Item'));by_name={name(n):n for n in items}

class VisualV45(unittest.TestCase):
 def test_every_sign_has_explicit_canvas_adornee_and_high_contrast_text(self):
  for path in ['src/world/World1.rbxmx','src/world/TestCourse.rbxmx','build/BikeEvolutionSimulator.rbxlx']:
   root=E.parse(ROOT/path).getroot();parents={c:n for n in root.iter('Item') for c in n.findall('Item')}
   captions=[n for n in root.iter('Item') if n.attrib['class']=='SurfaceGui' and name(n)=='SignCaption']
   self.assertGreaterEqual(len(captions),4)
   for gui in captions:
    panel=parents[gui];props=gui.find('Properties')
    self.assertEqual(props.findtext("Ref[@name='Adornee']"),panel.attrib['referent'])
    self.assertEqual(props.findtext("token[@name='SizingMode']"),'1')
    self.assertEqual(props.findtext("float[@name='PixelsPerStud']"),'96')
    self.assertIn(props.findtext("token[@name='Face']"),['2','5'])
    self.assertEqual(props.findtext("bool[@name='AlwaysOnTop']"),'false')
    label=gui.find('Item');self.assertTrue(label.findtext("Properties/string[@name='Text']"))
    self.assertEqual(label.findtext("Properties/bool[@name='TextScaled']"),'true')
    self.assertEqual(label.findtext("Properties/bool[@name='ClipsDescendants']"),'false')
    self.assertEqual(label.findtext("Properties/int[@name='ZIndex']"),'2')
    self.assertEqual(colors(label,'TextColor3'),[1,1,1])
    self.assertLess(max(colors(panel,'Color')),.27)
    self.assertEqual(panel.findtext("Properties/token[@name='Material']"),'256')
 def test_bike_shop_caption_faces_the_island_outside_roof_and_glass(self):
  garage=by_name['GaragePreview'];parents={c:n for n in garage.iter('Item') for c in n.findall('Item')}
  labels=[n for n in garage.iter('Item') if n.findtext("Properties/string[@name='Text']")=='BIKE SHOP']
  self.assertEqual(len(labels),2)
  front=[]
  for label in labels:
   gui=parents[label];p=parents[gui];side=1 if gui.findtext("Properties/token[@name='Face']")=='2' else -1
   r=rotation(p);normal=[row[2]*side for row in r]
   if normal[0]>.99:front.append(p)
  self.assertEqual(len(front),1)
  face=front[0];self.assertGreater(size(face)[0]/size(face)[1],5)
  # All text rays approaching from +X meet the board before the facade or roof; no own-layer occlusion.
  x=position(face)[0]+size(face)[2]/2
  for key in ['Roof','FrontGlass','FrontMullion']:
   for n in garage.findall('Item'):
    if name(n)==key:self.assertLess(bounds(n)[1][0],x)
  self.assertGreater(x,-43)
 def test_neon_only_on_thin_sign_edges_and_large_mounted_physical_icons(self):
  for sign in [n for n in items if n.attrib['class']=='Model' and name(n).startswith('Sign_')]:
   for p in sign.findall('Item'):
    if p.find("Properties/token[@name='Material']") is not None and p.findtext("Properties/token[@name='Material']")=='288':
     self.assertEqual(name(p),'EdgeInlay');self.assertLessEqual(size(p)[1],.04)
   if any(name(p)=='IconBacking' for p in sign.findall('Item')):
    face=next(p for p in sign.findall('Item') if name(p)=='TextFace')
    for p in sign.findall('Item'):
     if name(p)=='IconBacking':self.assertGreater(size(p)[1],size(face)[1]*.7)
  for kind,icon in [('Garage','BikeWheel'),('Training','EnergyBolt'),('Race','CheckeredFlag'),('Eggs','EggIcon'),('Worlds','PortalIcon'),('VIP','Crown')]:
   sign=next(n for n in items if name(n)=='Sign_'+kind)
   self.assertTrue(any(name(n)==icon for n in sign.findall('Item')))
 def test_no_legacy_sign_generator_or_treadmill_geometry(self):
  self.assertNotIn('V4Caption',{name(n) for n in items})
  self.assertFalse(any(name(n).startswith('V4Sign_') for n in items))
  forbidden={'RoundedBase','RoundedLayer','NeonRim','PowerArm','PowerCore','JointGlow','EnergyFin','AccessRamp'}
  for n in by_name['Training'].iter('Item'):self.assertNotIn(name(n),forbidden)
  source=(ROOT/'tools/build_world.py').read_text()
  self.assertIn('from sign_builder import SignBuilder',source)
  self.assertNotIn('Invisible carriers',source)
 def test_rectangular_inset_devices_are_symmetric_and_have_visible_rollers(self):
  extents=[]
  for i in range(1,6):
   model=by_name[f'Treadmill_{i}'];parts=model.findall('Item');belt=next(n for n in parts if name(n)=='Belt');center=position(belt)
   self.assertEqual(size(belt),[8,.2,12]);self.assertEqual(belt.findtext("Properties/token[@name='Material']"),'1312')
   self.assertAlmostEqual(center[1]+size(belt)[1]/2,8.05)
   self.assertLess(max(colors(belt,'Color')),.15)
   for key in ['SideFrame','NeonEdge','RollerHousing','FrameBolt']:
    group=[p for p in parts if name(p)==key]
    xs=sorted(round(position(p)[0]-center[0],6) for p in group)
    self.assertEqual(xs,sorted(-x for x in xs))
   for key in ['FrontRoller','RearRoller']:
    roller=next(n for n in parts if name(n)==key)
    self.assertEqual(roller.findtext("Properties/token[@name='shape']"),'2')
    self.assertGreater(position(roller)[1]+size(roller)[1]/2,8.25)
    self.assertFalse(roller.findtext("Properties/bool[@name='CanCollide']")=='true')
   neon=[p for p in parts if p.findtext("Properties/token[@name='Material']")=='288']
   self.assertEqual(len(neon),2)
   self.assertLess(sum(size(p)[0]*size(p)[2] for p in neon),3)
   lo,hi=bounds(next(p for p in parts if name(p)=='Deck'));extents.append((lo,hi))
   for p in parts:
    if p.findtext("Properties/bool[@name='CanCollide']")=='true':self.assertLessEqual(bounds(p)[1][1],8.05+.0001)
  for (lo,hi),(otherlo,otherhi) in zip(extents,extents[1:]):self.assertLess(hi[0],otherlo[0])
  self.assertLess(extents[2][1][0],-7);self.assertGreater(extents[3][0][0],13)
 def test_new_models_and_modules_are_present_in_built_place(self):
  place=E.parse(ROOT/'build/BikeEvolutionSimulator.rbxlx').getroot();names={name(n) for n in place.iter('Item')}
  for key in ['SignReadability','AutoTraining','FrontRoller','RearRoller','Sign_Garage','Sign_Training']:self.assertIn(key,names)
  self.assertNotIn('AccessRamp',names)
  self.assertNotIn('RoundedBase',names)
 def test_touch_jump_position_and_unpadded_hud_canvas_have_a_single_owner(self):
  ui=(ROOT/'src/client/UI.luau').read_text();self.assertEqual(ui.count('Name="ResourceHUD"'),1)
  self.assertIn('Name="SafeResourceCanvas",Position=UDim2.fromOffset(0,0)',ui)
  self.assertIn('resourceHUD.Position=UDim2.new(1,-10,1,-10)',ui)
  self.assertNotIn('shortTouch',ui)
  bike=(ROOT/'src/client/BikeInput.luau').read_text();self.assertIn('UDim2.new(1,-90,1,-220)',bike)
  self.assertNotIn('CameraSubject=',(ROOT/'src/client/RidePrediction.luau').read_text())

if __name__=='__main__':unittest.main(verbosity=2)
