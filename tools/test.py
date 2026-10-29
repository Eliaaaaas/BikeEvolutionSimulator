#!/usr/bin/env python3
"""Compile unchanged production Luau; bundle pure modules with only require resolution adapted."""
import os
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
LUAU = os.environ.get('LUAU_BIN', str(ROOT / '.tools/luau'))
COMPILER = os.environ.get('LUAU_COMPILE_BIN', str(ROOT / '.tools/luau-compile'))
for source in sorted((ROOT / 'src').rglob('*.luau')):
    subprocess.run([COMPILER, '--binary', str(source)], stdout=subprocess.DEVNULL, check=True)
modules = ['Numbers', 'Config', 'PremiumConfig', 'Progression', 'AutoNavigation', 'CatalogMetadata', 'World1Content', 'Catalog', 'Rules', 'AutoTraining', 'Profile', 'Protocol', 'Persistence', 'SavePolicy', 'StudioStore', 'PetRules', 'PremiumRules', 'EconomyController', 'TrainingController', 'RateLimiter', 'Format', 'Presentation', 'ClientState', 'CourseData', 'RaceCourse', 'RaceRules', 'RaceController', 'RuntimeContract', 'TrainingTap', 'BikeMotion', 'RideSimulation', 'RideReconciliation']
bundle = ['--!strict\nlocal modules: any = {}']
for name in modules:
    folder = 'server' if name in ('Persistence', 'SavePolicy', 'StudioStore') else 'shared'
    source = (ROOT / 'src' / folder / (name + '.luau')).read_text()
    source = re.sub(r'^--!strict\n', '', source)
    source = re.sub(r'^export type ', 'type ', source, flags=re.M)
    source = re.sub(r'require\(script.Parent\.(\w+)\)', r'modules.\1', source)
    bundle.append(f'modules.{name} = (function()\n{source}\nend)()')
production_bundle = '\n'.join(bundle)
(ROOT / 'build').mkdir(exist_ok=True)
subprocess.run([str(ROOT / '.tools/rojo'), 'build', 'default.project.json', '--output', 'build/BikeEvolutionSimulator.rbxlx'], cwd=ROOT, check=True)
from runtime_tests import fixture, adapters
bundle.append(fixture())
bundle.append(adapters())
bundle.append((ROOT / 'tests/rigid_math.luau').read_text())
bundle.append((ROOT / 'tests/runtime_engine.luau').read_text())
bundle.append((ROOT / 'tests/rigid_transform.spec.luau').read_text())
# Execute the actual Roblox lifecycle adapter against deterministic engine doubles.
service = (ROOT / 'src/server/PlayerDataService.luau').read_text()
service = re.sub(r'require\(Shared:WaitForChild\("(\w+)"\)\)', r'modules.\1', service)
service = re.sub(r'require\(script.Parent\.(\w+)\)', r'modules.\1', service)
bundle.append('modules.makeService = function(game, task, os, warn)\n' + service + '\nend')
rig = (ROOT / 'src/shared/BikeRig.luau').read_text()
bundle.append('modules.makeBikeRig = function(Instance)\n' + rig + '\nend')
race = (ROOT / 'src/server/RaceService.luau').read_text()
race = re.sub(r'require\(Shared:WaitForChild\("(\w+)"\)\)', r'modules.\1', race)
bundle.append('modules.makeRaceService = function(game,workspace,task,os,warn,Instance,CFrame,Vector3,Enum)\n' + race + '\nend')
bundle.append((ROOT / 'tests/rules.spec.luau').read_text())
bundle.append((ROOT / 'tests/lifecycle.spec.luau').read_text())
bundle.append((ROOT / 'tests/training.spec.luau').read_text())
bundle.append((ROOT / 'tests/phase21.spec.luau').read_text())
bundle.append((ROOT / 'tests/world1.spec.luau').read_text())
bundle.append((ROOT / 'tests/race_lifecycle.spec.luau').read_text())
bundle.append((ROOT / 'tests/hardening.spec.luau').read_text())
bundle.append((ROOT / 'tests/pets_v3.spec.luau').read_text())
bundle.append((ROOT / 'tests/training_tap.spec.luau').read_text())
bundle.append((ROOT / 'tests/bike_motion.spec.luau').read_text())
bundle.append((ROOT / 'tests/ride_simulation.spec.luau').read_text())
bundle.append((ROOT / 'tests/overhaul_v44.spec.luau').read_text())
bundle.append((ROOT / 'tests/auto_training_v45.spec.luau').read_text())
bundle.append((ROOT / 'tests/runtime_integration.spec.luau').read_text())
with tempfile.TemporaryDirectory(prefix='bike-tests-') as directory:
    analysis_file = Path(directory) / 'production.luau'
    analysis_file.write_text(production_bundle)
    analyzer = os.environ.get('LUAU_ANALYZE_BIN', str(ROOT / '.tools/luau-analyze'))
    subprocess.run([analyzer, str(analysis_file)], check=True)
    test_file = Path(directory) / 'suite.luau'
    test_file.write_text('\n'.join(bundle))
    subprocess.run([LUAU, str(test_file)], cwd=ROOT, check=True)
print('All production Luau files compiled successfully.')
subprocess.run(['python3', str(ROOT / 'tools/build_world.py'), '--check'], check=True)
subprocess.run(['python3', str(ROOT / 'tests/world_test.py')], check=True)
subprocess.run(['python3', str(ROOT / 'tests/visual_v4_test.py')], check=True)
subprocess.run(['python3', str(ROOT / 'tests/visual_v45_test.py')], check=True)
subprocess.run(['python3', str(ROOT / 'tools/build_race_assets.py'), '--check'], check=True)
subprocess.run(['python3', str(ROOT / 'tests/race_assets_test.py')], check=True)
subprocess.run(['python3', str(ROOT / 'tests/overhaul_v44_test.py')], check=True)
subprocess.run(['python3', str(ROOT / 'tools/build_vehicle_fleet.py'), '--check'], check=True)
subprocess.run(['python3', str(ROOT / 'tools/build_pet_assets.py'), '--check'], check=True)

(ROOT / 'build').mkdir(exist_ok=True)
subprocess.run([str(ROOT / '.tools/rojo'), 'sourcemap', 'default.project.json', '--output', 'build/sourcemap.json'], cwd=ROOT, check=True)
subprocess.run([str(ROOT / '.tools/luau-lsp'), 'analyze', '--platform', 'roblox', '--sourcemap', 'build/sourcemap.json',
                '--definitions', str(ROOT / '.tools/roblox.d.luau'), 'src'], cwd=ROOT, check=True)
subprocess.run(['python3', str(ROOT / 'tests/place_integration_test.py')], check=True)
print('Roblox-aware type analysis passed for all production Luau.')
