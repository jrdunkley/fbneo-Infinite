"""Build fbneo-Infinite with an existing portable w64devkit and Perl installation."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parent

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--arch', choices=['x86', 'x64', 'both'], default='both')
    p.add_argument('--toolchain', type=Path, help='w64devkit root, containing bin/make.exe; otherwise use PATH')
    p.add_argument('--perl', type=Path, help='Directory containing perl.exe; otherwise use PATH')
    p.add_argument('--jobs', type=int, default=4)
    a = p.parse_args()
    if a.jobs < 1:
        p.error('--jobs must be positive')
    env = {k:v for k,v in os.environ.items() if not k.startswith('INFINITE_')}
    prefixes = [str(d.resolve()) for d in ([a.toolchain / 'bin'] if a.toolchain else []) + ([a.perl] if a.perl else [])]
    env['PATH'] = os.pathsep.join(prefixes + [env['PATH']])
    resolved = {t:shutil.which(t, path=env['PATH']) for t in ['make', 'gcc', 'g++', 'windres', 'perl', 'strip']}
    if not all(resolved.values()):
        p.error('Missing tools: ' + ', '.join(k for k,v in resolved.items() if not v))
    flags = getattr(subprocess, 'CREATE_NO_WINDOW', 0) | getattr(subprocess, 'BELOW_NORMAL_PRIORITY_CLASS', 0)
    out = ROOT / 'build'
    out.mkdir(exist_ok=True)
    versions = {t:subprocess.run([resolved[t], '--version'], env=env, capture_output=True, text=True,
                               creationflags=flags, check=True).stdout.strip().splitlines()[0]
                for t in ['make', 'gcc', 'g++', 'perl']}
    # This is also valid on a checkout containing spaces: the make output paths stay relative.
    results = []
    for arch in (['x86','x64'] if a.arch == 'both' else [a.arch]):
        command = [resolved['make'], 'mingw', 'RELEASEBUILD=1', 'BUILD_X86_ASM=', '-j'+str(a.jobs)]
        if arch == 'x64':
            command.append('BUILD_X64_EXE=1')
        print('Building '+arch+'; log: build/'+arch+'.log', flush=True)
        with (out / (arch+'.log')).open('w') as log:
            process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT, creationflags=flags)
            (out / 'active-process.json').write_text(json.dumps(dict(pid=process.pid, arch=arch)))
            code = process.wait()
        if code:
            raise SystemExit('Build failed ('+str(code)+'); inspect build/'+arch+'.log')
        exe = ROOT / ('fbneox.exe' if arch == 'x86' else 'fbneo64.exe')
        subprocess.run([resolved['strip'], str(exe)], env=env, check=True, creationflags=flags)
        target = out / arch / 'fbneo-Infinite.exe'
        target.parent.mkdir(exist_ok=True)
        shutil.copy2(exe, target)
        result = dict(arch=arch, executable=target.relative_to(ROOT).as_posix(),
                      sha256=hashlib.sha256(target.read_bytes()).hexdigest(), bytes=target.stat().st_size)
        (out / (arch+'-result.json')).write_text(json.dumps(dict(result=result, tools=versions), indent=2)+'\n')
        results.append(result)
        print('BUILD PASS '+arch+' '+result['sha256'], flush=True)
    print(json.dumps(results))

if __name__ == '__main__':
    main()
