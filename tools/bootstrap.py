#!/usr/bin/env python3
"""Install pinned official Linux x86_64 CLI releases, retaining HTTPS verification."""
import os
from pathlib import Path
import platform
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
if platform.system() != 'Linux' or platform.machine() != 'x86_64':
    raise SystemExit('This bootstrap supports Linux x86_64. See README for other platforms.')
target = ROOT / '.tools'
target.mkdir(exist_ok=True)
releases = [
    ('https://github.com/luau-lang/luau/releases/download/0.744/luau-ubuntu.zip',
     ['luau', 'luau-compile', 'luau-analyze']),
    ('https://github.com/JohnnyMorganz/luau-lsp/releases/download/1.70.1/luau-lsp-linux-x86_64.zip', ['luau-lsp']),
    ('https://github.com/rojo-rbx/rojo/releases/download/v7.4.4/rojo-7.4.4-linux-x86_64.zip', ['rojo']),
]
for url, names in releases:
    with tempfile.TemporaryDirectory(prefix='bike-tools-') as directory:
        archive = Path(directory) / 'release.zip'
        subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                        '--proto', '=https', '--proto-redir', '=https', '--retry', '2',
                        url, '--output', str(archive)], check=True)
        with zipfile.ZipFile(archive) as package:
            for name in names:
                # Extract only explicit executable names, never arbitrary archive paths.
                data = package.read(name)
                executable = target / name
                executable.write_bytes(data)
                executable.chmod(0o755)
subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                '--proto', '=https', '--proto-redir', '=https', '--retry', '2',
                'https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/1.70.1/scripts/globalTypes.d.luau',
                '--output', str(target / 'roblox.d.luau')], check=True)
print('Installed Luau 0.744, Rojo 7.4.4, luau-lsp 1.70.1 and pinned Roblox types into .tools/')
