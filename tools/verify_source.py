"""ROM-free release boundary and asset checks; needs only Python's standard library."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRS = {'.github', 'fbahelpfilesrc', 'projectfiles', 'src', 'support', 'tools'}
SOURCE_ROOT_FILES = {'.editorconfig', '.gitignore', '.gitattributes', 'LICENSE.chromium-crc32', 'LICENSE.md',
    'README.md', 'README.upstream.md', 'README-macOS.md', 'README-PI.md', 'README-SDL.md',
    'BUILDING.md', 'COMPARISON.md', 'CONTRIBUTING.md', 'THIRD_PARTY_NOTICES.md', 'RELEASE_NOTES.md',
    'SOURCE_PROVENANCE.json', 'VERIFICATION.json', 'build.py', 'package.py', 'meson.build', 'meson_options.txt',
    'gamelist.txt', 'whatsnew.html'}
SKIP_PARTS = {'__pycache__', '.git', 'obj', 'build', '.vs', 'xcuserdata'}
FORBIDDEN_SUFFIXES = {'.exe','.dll','.o','.obj','.a','.lib','.pdb','.bin','.rom','.fs','.infr','.zip','.7z','.chm','.pyc',
                      '.iso','.chd','.nvr','.sav','.wav','.mp3','.flac','.ogg'}
FORBIDDEN_PARTS = {'roms','savestates','recordings','nvram','secrets','private'}
PATTERNS = {
    'private key': re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    'GitHub token': re.compile(rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})'),
    'AWS access key': re.compile(rb'AKIA[0-9A-Z]{16}'),
    'local user path': re.compile(rb'[A-Za-z]:[\\/]+Users[\\/]+', re.I),
}

def source_files():
    files = []
    for p in sorted(ROOT.rglob('*')):
        rel = p.relative_to(ROOT)
        if any(part in SKIP_PARTS for part in rel.parts) or p.suffix == '.pyc' or p.name == '.DS_Store' or p.name.startswith('._'):
            continue
        if not (rel.parts[0] in SOURCE_DIRS or (len(rel.parts)==1 and (p.name in SOURCE_ROOT_FILES or p.name.startswith('makefile')))):
            continue
        if p.is_symlink():
            raise ValueError('Symlink not allowed: '+rel.as_posix())
        if p.is_file():
            files.append(p)
    return files

def verify():
    files = source_files()
    errors = []
    for p in files:
        rel = p.relative_to(ROOT).as_posix()
        if p.suffix.lower() in FORBIDDEN_SUFFIXES or set(x.lower() for x in p.relative_to(ROOT).parts) & FORBIDDEN_PARTS:
            errors.append('Forbidden payload path: '+rel)
        data = p.read_bytes()
        if data.startswith((b'MZ', b'\x7fELF', b'PK\x03\x04', b'7z\xbc\xaf\x27\x1c')):
            errors.append('Unexpected executable/archive payload: '+rel)
        for label, pattern in PATTERNS.items():
            if pattern.search(data):
                errors.append(label+': '+rel)  # Never print a matching credential.
    required = ['src/license.txt', 'build.py', 'package.py', 'README.md', 'BUILDING.md',
                'THIRD_PARTY_NOTICES.md', 'src/burner/win32/page_store.cpp',
                'src/cpu/sh2/cps3_timing.h', 'support/shaders/arcade_rgb/COPYING',
                'support/shaders/lola_retro/amiga-1084s/LICENSE']
    errors += ['Missing '+n for n in required if not (ROOT/n).is_file()]
    table = (ROOT/'src/intf/video/win32/vid_directx9.cpp').read_text()
    shaders = sorted(set(re.findall(r'"(support/shaders/[^"\n]+\.fx)"',table)))
    errors += ['Missing shader '+n for n in shaders if not (ROOT/n).is_file()]
    if len(shaders) < 14:
        errors.append('Incomplete HardFX table')
    for p in (ROOT/'support/shaders').rglob('*.fx'):
        for name in re.findall(r'^\s*#include\s+"([^"\n]+)"',p.read_text(errors='replace'),re.M):
            if not (p.parent/name).is_file():
                errors.append('Missing shader include: '+str(p.relative_to(ROOT))+' -> '+name)
    workflows = list((ROOT/'.github/workflows').glob('*'))
    if len(workflows) != 1 or workflows[0].name != 'source-checks.yml':
        errors.append('Unexpected workflow; review release automation explicitly')
    if errors:
        raise SystemExit('\n'.join(errors))
    return dict(passed=True, files=len(files), bytes=sum(p.stat().st_size for p in files),
                hardfx_entries=len(shaders), scan='Path, payload magic, credential patterns and local-user paths; not a legal certification')

if __name__ == '__main__':
    print(json.dumps(verify(), indent=2))
