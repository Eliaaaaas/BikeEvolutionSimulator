#!/usr/bin/env python3
"""Create a versioned, checksum-verified Studio package without changing gameplay files."""
from pathlib import Path
import argparse,hashlib,json,subprocess,zipfile,xml.etree.ElementTree as E
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--version',choices=['V4','V4.1','V4.2'],default='V4')
version=parser.parse_args().version
package='BikeEvolutionSimulator-'+version
source=ROOT/'build/BikeEvolutionSimulator.rbxlx'
content=source.read_bytes();parsed=E.fromstring(content)
assert parsed.tag=='roblox' and parsed.attrib.get('version')=='4' and content.rstrip().endswith(b'</roblox>')
folder=ROOT/('build/'+version.lower());folder.mkdir(exist_ok=True)
commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
digest=hashlib.sha256(content).hexdigest()
info={'name':package,'version':package+'-'+commit[:7],'commit':commit,'built_at_utc':datetime.now(timezone.utc).isoformat(),'file':source.name,'bytes':len(content),'sha256':digest,'studio_test':'NOT EXECUTED: Roblox Studio unavailable','data_mode':'Explicit non-persistent Studio preview by default; see README for isolated persistent tests.'}
(folder/source.name).write_bytes(content)
(folder/'BUILD_INFO.json').write_text(json.dumps(info,indent=2)+'\n')
(folder/'SHA256SUMS.txt').write_text(digest+'  '+source.name+'\n')
archive=ROOT/('build/'+package+'.zip')
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED) as z:
 for filename in ['BUILD_INFO.json',source.name,'SHA256SUMS.txt']:z.write(folder/filename,filename)
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 assert hashlib.sha256(z.read(source.name)).hexdigest()==digest
print(f'Verified {archive.name}: {len(content)} place bytes, commit {commit}, SHA-256 {digest}')
