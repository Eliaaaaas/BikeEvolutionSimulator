"""Geometry/source QA of the actual authored map. No claim about Studio rendering."""
from pathlib import Path
import math
import unittest
import xml.etree.ElementTree as E

ROOT = Path(__file__).resolve().parents[1]
world = E.parse(ROOT/'src/world/World1.rbxmx').getroot()
items = list(world.iter('Item'))
def name(node): return node.findtext("Properties/string[@name='Name']")
def vec(node, prop): return [float(node.findtext(f'Properties/{prop}/{k}')) for k in 'XYZ']
def xyz(node): return vec(node, "CoordinateFrame[@name='CFrame']")
def size(node): return vec(node, "Vector3[@name='size']")
def rotation(node):
    return [[float(node.findtext(f"Properties/CoordinateFrame[@name='CFrame']/R{r}{c}")) for c in range(3)] for r in range(3)]
def bounds(node):
    p, s, r = xyz(node), size(node), rotation(node)
    half = [sum(abs(r[a][b])*s[b]/2 for b in range(3)) for a in range(3)]
    return [p[a]-half[a] for a in range(3)], [p[a]+half[a] for a in range(3)]
by_name = {name(i):i for i in items}
parts = [i for i in items if i.find("Properties/Vector3[@name='size']") is not None]

class VisualV4Tests(unittest.TestCase):
    def test_five_flush_belts_have_no_access_ramps(self):
        self.assertFalse(any(name(p)=='AccessRamp' for p in parts))
        for id in range(1,6):
            belt=by_name[f'Treadmill_{id}']
            surface=next(p for p in belt.findall('Item') if name(p)=='Belt')
            self.assertAlmostEqual(xyz(surface)[1]+size(surface)[1]/2,8.05)
            self.assertTrue(surface.findtext("Properties/bool[@name='CanCollide']")=='true')

    def test_all_authored_transforms_are_finite_and_rigid(self):
        self.assertLessEqual(len(parts), 3300)
        for node in parts:
            r = rotation(node)
            self.assertTrue(all(math.isfinite(v) for v in xyz(node)+size(node)+sum(r, [])))
            self.assertTrue(all(v>0 for v in size(node)))
            for a in range(3):
                for b in range(3):
                    self.assertAlmostEqual(sum(r[a][j]*r[b][j] for j in range(3)), int(a==b), places=7)
            self.assertEqual(node.findtext("Properties/bool[@name='Anchored']"), 'true')

    def test_coast_is_continuous_flat_and_matches_adjacent_cells(self):
        wedges = [p for p in parts if name(p)=='CoastGrass']
        self.assertGreaterEqual(len(wedges), 180)
        for wedge in wedges:
            self.assertEqual(wedge.attrib['class'], 'WedgePart')
            lo, hi = bounds(wedge)
            self.assertAlmostEqual(hi[1], 8)
            self.assertAlmostEqual(lo[1], 7)
        cores = sorted([p for p in parts if name(p).startswith('Grass_')], key=lambda p:xyz(p)[2])
        for a,b in zip(cores, cores[1:]):
            self.assertAlmostEqual(bounds(a)[1][2], bounds(b)[0][2])
        # The left/right wedges meet the core exactly; their outer tips interpolate the shore.
        for core in cores:
            lo,hi = bounds(core)
            adjacent = [w for w in wedges if abs(xyz(w)[2]-xyz(core)[2])<1e-7]
            self.assertEqual(len(adjacent),2)
            for w in adjacent:
                wl,wh=bounds(w)
                self.assertTrue(abs(wh[0]-lo[0])<1e-7 or abs(wl[0]-hi[0])<1e-7)

    def test_sculpted_signs_keep_caption_and_icons_separate(self):
        signs = [i for i in items if name(i).startswith('V4Sign_')]
        self.assertGreaterEqual(len(signs),20)
        for sign in signs:
            names = [name(i) for i in sign.findall('Item')]
            for layer in ('SculptedBack','NeonContour','EnamelFace'):
                self.assertIn(layer,names)
            for carrier in [i for i in sign.findall('Item') if name(i)=='V4Caption']:
                label=carrier.find("Item/Item")
                self.assertEqual(label.findtext("Properties/bool[@name='TextScaled']"),'true')
                dims=label.find("Properties/UDim2[@name='Size']")
                pos=label.find("Properties/UDim2[@name='Position']")
                for axis in 'XY':
                    self.assertLessEqual(float(dims.findtext(axis+'S'))+float(pos.findtext(axis+'S')), .97)
                self.assertEqual(label.findtext("Properties/bool[@name='TextWrapped']"),'false')
                right=[row[0] for row in rotation(carrier)]
                left=-size(carrier)[0]/2+float(pos.findtext('XS'))*size(carrier)[0]
                for icon in sign.findall('Item'):
                    if name(icon) in {'BikeWheel','BikeFrame','EggIcon','StarGem','FlagPole','CheckeredFlag','PortalIcon','CoinRim','CoinStamp','StarRay','EnergyBolt'}:
                        center=sum((xyz(icon)[a]-xyz(carrier)[a])*right[a] for a in range(3))
                        r=rotation(icon)
                        half=sum(abs(sum(r[a][b]*right[a] for a in range(3)))*size(icon)[b]/2 for b in range(3))
                        self.assertLess(center+half,left,name(sign))

    def test_showroom_label_frames_do_not_overlap(self):
        showroom=by_name['GarageShowroom']
        signs=[i for i in showroom.findall('Item') if name(i).startswith('V4Sign_')]
        self.assertEqual(len(signs),10)
        ranges=[]
        for sign in signs:
            layers=[p for p in sign.findall('Item') if name(p) in {'SculptedBack','SculptedBackCap'}]
            ranges.append(([min(bounds(p)[0][a] for p in layers) for a in range(3)], [max(bounds(p)[1][a] for p in layers) for a in range(3)]))
        for index,(lo,hi) in enumerate(ranges):
            for otherlo,otherhi in ranges[index+1:]:
                self.assertTrue(any(hi[a]<=otherlo[a] or otherhi[a]<=lo[a] for a in (0,2)))

    def test_paths_and_decor_do_not_obstruct_players(self):
        pavers=[p for p in parts if name(p)=='CurvedPaver']
        self.assertGreaterEqual(len(pavers),90)
        decor=by_name['TropicalDecor']
        for p in pavers+list(decor.iter('Item')):
            if p.find("Properties/bool[@name='CanCollide']") is not None:
                self.assertEqual(p.findtext("Properties/bool[@name='CanCollide']"),'false')
        for p in parts:
            if p.findtext("Properties/bool[@name='CanCollide']")=='true' and name(p)!='IslandSpawn':
                lo,hi=bounds(p)
                self.assertFalse(hi[1]>8.6 and lo[0]<6<hi[0] and lo[2]<0<hi[2], name(p))
        for landmark in ('ShopArea','TrainingLandmark'):
            self.assertTrue(any(name(n)=='SignBracket' for n in by_name[landmark].findall('Item')))

    def test_removed_billboard_and_obsolete_navigation_cannot_reappear(self):
        effects=(ROOT/'src/client/StationEffects.luau').read_text()
        self.assertNotIn('BillboardGui',effects)
        self.assertNotIn('TrainingGain',effects)
        ui=(ROOT/'src/client/UI.luau').read_text()
        self.assertIn('"Garage","Pets","Race","Worlds","Rebirths","Shop","Settings"',ui)
        self.assertNotIn('"Upgrades"',ui)
        self.assertNotIn('api.Status',ui)
        self.assertFalse(any(i.attrib['class']=='BillboardGui' for i in items))

if __name__=='__main__': unittest.main(verbosity=2)
