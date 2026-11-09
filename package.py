"""Create deterministic ROM-free release ZIPs locally; never publishes anything."""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT/'tools'))
from verify_source import source_files, verify

def sha(b):
    return hashlib.sha256(b).hexdigest()

def archive(path, prefix, payload):
    # Refuse to overwrite an existing release artifact.
    with zipfile.ZipFile(path, 'x', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for name, data in sorted(payload.items()):
            info = zipfile.ZipInfo(prefix+'/'+name, (2026,11,9,0,0,0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, data)
    with zipfile.ZipFile(path) as z:
        assert len(z.namelist()) == len(set(z.namelist())) == len(payload)
        assert z.testzip() is None
        for name,data in payload.items():
            assert z.read(prefix+'/'+name) == data
    return dict(file=path.name, sha256=sha(path.read_bytes()), bytes=path.stat().st_size, files=len(payload))

def main():
    checks = verify()
    # Resolve every input before creating dist, so missing builds leave no half-release.
    source = {p.relative_to(ROOT).as_posix():p.read_bytes() for p in source_files()}
    builds = {}
    for arch in ['x86','x64']:
        p = ROOT/'build'/arch/'fbneo-Infinite.exe'
        receipt = json.loads((ROOT/'build'/(arch+'-result.json')).read_text())['result']
        data = p.read_bytes()
        assert sha(data) == receipt['sha256'] and len(data) == receipt['bytes']
        builds[arch] = data
    source_fingerprint = sha(json.dumps({n:sha(b) for n,b in source.items() if n!='VERIFICATION.json'},sort_keys=True).encode())
    prior = json.loads(source.get('VERIFICATION.json', b'{}'))
    qualified = bool(prior.get('passed') and prior.get('source_input_fingerprint')==source_fingerprint and
        all(prior.get('builds',{}).get(a,{}).get('sha256')==sha(b) for a,b in builds.items()))
    if not qualified:
        source['VERIFICATION.json'] = (json.dumps(dict(passed=False,runtime_qualified=False,
            note='Built locally; the recorded runtime qualification does not match these exact source and executable inputs.',
            source_input_fingerprint=source_fingerprint,
            executable_sha256={a:sha(b) for a,b in builds.items()}),indent=2)+'\n').encode()
    source['SOURCE_MANIFEST.json'] = (json.dumps(dict(files={n:sha(b) for n,b in source.items()}), indent=2)+'\n').encode()
    out = ROOT/'dist'
    out.mkdir(exist_ok=False)
    version = '1.07b'
    records = [archive(out/f'fbneo-Infinite-{version}-source.zip', 'fbneo-Infinite', source)]
    license_paths = [n for n in source if Path(n).name.lower().startswith(('license','copying'))]
    license_paths += ['src/dep/libs/lua/lua.h','src/dep/libs/zlib/zlib.h','src/dep/libs/libspng/spng.h',
                      'src/dep/libs/lib7z/7z.h','src/dep/libs/zstd/zstd.h']
    common = {n:b for n,b in source.items() if n.startswith('support/shaders/')}
    for name in ['README.md','COMPARISON.md','BUILDING.md','CONTRIBUTING.md','LICENSE.md','THIRD_PARTY_NOTICES.md','RELEASE_NOTES.md','SOURCE_PROVENANCE.json','VERIFICATION.json','src/license.txt']:
        common[name] = source[name]
    for name in sorted(set(license_paths)):
        if name in source and not name.startswith('support/shaders/'):
            common['LICENSES/'+name] = source[name]
    for arch,data in builds.items():
        payload = dict(common)
        payload['fbneo-Infinite.exe'] = data
        payload['SOURCE.txt'] = ('Matching source: '+records[0]['file']+'\nSHA-256: '+records[0]['sha256']+
                                '\nKeep the source archive with this release. No ROM or GGPO DLL is included.\n').encode()
        payload['SHA256SUMS.txt'] = ''.join(sha(b)+'  '+n+'\n' for n,b in sorted(payload.items())).encode()
        records.append(archive(out/f'fbneo-Infinite-{version}-windows-{arch}.zip', 'fbneo-Infinite-'+arch, payload))
    (out/'SHA256SUMS.txt').write_text(''.join(r['sha256']+'  '+r['file']+'\n' for r in records), encoding='utf-8')
    report = dict(passed=True, runtime_qualified=qualified, source_checks=checks, artifacts=records, published=False)
    (out/'package-report.json').write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()
