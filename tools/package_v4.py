#!/usr/bin/env python3
"""Create a versioned, checksum-verified Studio package without changing gameplay files."""
from pathlib import Path
import hashlib,json,subprocess,zipfile,xml.etree.ElementTree as E
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'build/BikeEvolutionSimulator.rbxlx'
content=source.read_bytes();parsed=E.fromstring(content)
assert parsed.tag=='roblox' and parsed.attrib.get('version')=='4' and content.rstrip().endswith(b'</roblox>')
folder=ROOT/'build/v4';folder.mkdir(exist_ok=True)
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
digest=hashlib.sha256(content).hexdigest()
info={'name':'BikeEvolutionSimulator-V4','version':'BikeEvolutionSimulator-V4-'+commit[:7],'commit':commit,'built_at_utc':datetime.now(timezone.utc).isoformat(),'file':source.name,'bytes':len(content),'sha256':digest,'studio_test':'NOT EXECUTED: Roblox Studio unavailable','data_mode':'Explicit non-persistent Studio preview by default; see README for isolated persistent tests.'}
(folder/source.name).write_bytes(content)
(folder/'BUILD_INFO.json').write_text(json.dumps(info,indent=2)+'\n')
(folder/'SHA256SUMS.txt').write_text(digest+'  '+source.name+'\n')
archive=ROOT/'build/BikeEvolutionSimulator-V4.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as z:
 for file in sorted(folder.iterdir()):z.write(file,file.name)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 assert hashlib.sha256(z.read(source.name)).hexdigest()==digest
print(f'Verified {archive.name}: {len(content)} place bytes, commit {commit}, SHA-256 {digest}')
