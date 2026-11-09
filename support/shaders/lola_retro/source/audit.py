"""Fetch a pinned public source snapshot, with hashes; never execute upstream tools."""
import concurrent.futures
import hashlib
import json
import urllib.request
from pathlib import Path

AF = Path(__file__).resolve().parents[2]
OUT = AF / 'run/lola_retro_20261016'
UP = OUT / 'upstream'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    tree = json.loads((OUT/'tree.json').read_text())
    commit = tree['commit']
    names = [x['path'] for x in tree['tree'] if x['type']=='blob' and (
        x['path'].startswith('shaders/') or x['path'] in ['LICENSE','README.md','tools/check_shaders.py','tools/make_presets.py','tools/make_glsl.py'])]
    def fetch(name):
        dest = UP/name
        assert dest.resolve().is_relative_to(UP.resolve())
        url = f'https://raw.githubusercontent.com/zoran123456/lola-retro/{commit}/{name}'
        dest.parent.mkdir(parents=True,exist_ok=True)
        if not dest.exists():
            dest.write_bytes(urllib.request.urlopen(url,timeout=40).read())
        return dict(path=name,url=url,sha256=sha(dest),bytes=dest.stat().st_size)
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        files = list(pool.map(fetch,names))
    license_text=(UP/'LICENSE').read_text()
    assert 'MIT License' in license_text and 'Permission is hereby granted' in license_text
    assert (UP/'shaders/lola-retro/LICENSE').read_bytes()==(UP/'LICENSE').read_bytes()
    report=dict(commit=commit,license=license_text,files=files)
    (OUT/'audit.json').write_text(json.dumps(report,indent=2)+'\n')
    print('PINNED',commit,'files',len(files))
    print(license_text)

if __name__=='__main__':main()
