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
modules = ['Config', 'Catalog', 'Rules', 'Profile', 'Protocol', 'Persistence']
bundle = ['--!strict\nlocal modules: any = {}']
for name in modules:
    folder = 'server' if name == 'Persistence' else 'shared'
    source = (ROOT / 'src' / folder / (name + '.luau')).read_text()
    source = re.sub(r'^--!strict\n', '', source)
    source = re.sub(r'^export type ', 'type ', source, flags=re.M)
    source = re.sub(r'require\(script.Parent\.(\w+)\)', r'modules.\1', source)
    bundle.append(f'modules.{name} = (function()\n{source}\nend)()')
production_bundle = '\n'.join(bundle)
bundle.append((ROOT / 'tests/rules.spec.luau').read_text())
with tempfile.TemporaryDirectory(prefix='bike-tests-') as directory:
    analysis_file = Path(directory) / 'production.luau'
    analysis_file.write_text(production_bundle)
    analyzer = os.environ.get('LUAU_ANALYZE_BIN', str(ROOT / '.tools/luau-analyze'))
    subprocess.run([analyzer, str(analysis_file)], check=True)
    test_file = Path(directory) / 'suite.luau'
    test_file.write_text('\n'.join(bundle))
    subprocess.run([LUAU, str(test_file)], cwd=ROOT, check=True)
print('All production Luau files compiled successfully.')
