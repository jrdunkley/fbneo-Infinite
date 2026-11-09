"""Isolated SM3 adaptation of pinned Lola Retro math, retaining its seven passes.

Uses the project's existing SPIR-V -> HLSL tool and legacy FX rewrite helpers.
Only preset constants, sampler/size plumbing and SM3 stage interfaces change.
Arcade timing is explicitly 8; no console-size guessing for CPS3.
"""
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from audit import AF, OUT, UP, sha

sys.path.insert(0,str(AF/'research/retrocrisis_20261014'))
from adapt_hardfx import rewrite, pack_varyings

NAMES=['encode','decode','glow-h','glow-v','beam','crt','present']
PRESETS=['amiga-1084s','studio-monitor-rgb','consumer-tv-scart-rgb']
SOURCE=UP/'shaders/lola-retro/shaders'

def main():
    translated=OUT/'translated';translated.mkdir(exist_ok=True)
    cli=AF/'run/retrocrisis_20261014/upstream/cli/librashader-cli.exe'
    for name in NAMES:
        for stage in ['vertex','fragment']:
            target=translated/f'{name}_{stage}.hlsl'
            if not target.exists():
                r=subprocess.run([str(cli),'transpile','--shader',str(SOURCE/f'{name}.slang'),
                    '--stage',stage,'--format','hlsl','--version','30'],capture_output=True,
                    creationflags=subprocess.CREATE_NO_WINDOW,timeout=40)
                (translated/f'{name}_{stage}.log').write_bytes(r.stderr)
                assert r.returncode==0,(name,stage,r.stderr)
                target.write_bytes(r.stdout)
    defaults={k:val for k,val in re.findall(r'^#pragma parameter (\w+) "[^"]+" ([^\s]+)',(SOURCE/'common.inc').read_text(),re.M)}
    records=[]
    for preset in PRESETS:
        dest=OUT/'assets'/preset;dest.mkdir(parents=True,exist_ok=True)
        settings=dict(defaults)
        settings.update(dict(re.findall(r'^(LR_\w+) = ([^\s]+)',(UP/f'shaders/lola-retro/flat/{preset}.slangp').read_text(),re.M)))
        settings['LR_CONSOLE']='8' # 15 kHz arcade RGB, never PSX auto timing
        (dest/'settings.json').write_text(json.dumps(settings,indent=2)+'\n')
        shutil.copy2(UP/'LICENSE',dest/'LICENSE')
        for name in NAMES:
            vd,vs=rewrite((translated/f'{name}_vertex.hlsl').read_text(),settings,'vs')
            pd,ps=rewrite((translated/f'{name}_fragment.hlsl').read_text(),settings,'ps')
            # SM3 has no flat qualifier. These values depend only on uniforms,
            # so every vertex emits the same value and interpolation is constant.
            vs=vs.replace('nointerpolation ','')
            ps=ps.replace('nointerpolation ','')
            vs,ps=pack_varyings(vs,ps)
            shared=list(dict.fromkeys(vd+pd))
            fx='// Lola Retro by Zoki (zoran123456), MIT; see LICENSE.\n'
            fx+='// Pinned upstream '+json.loads((OUT/'audit.json').read_text())['commit']+'\n'
            fx+='// Isolated Infinite D3D9 prototype; preset '+preset+', explicit arcade timing 8.\n'
            fx+='\n'.join(shared)+'\n'+vs+'\n'+ps+'\n'
            fx+='technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }\n'
            path=dest/f'{name}.fx';path.write_text(fx)
            records.append(dict(preset=preset,shader=name,sha256=sha(path)))
    (OUT/'adaptation.json').write_text(json.dumps(dict(effects=records,translator_sha256=sha(cli),
        helpers_sha256=sha(AF/'research/retrocrisis_20261014/adapt_hardfx.py'),
        changes=['Fixed upstream RGB preset constants','Explicit 15 kHz arcade timing 8',
                 'Legacy FX declarations and packed interpolators','Explicit level-zero reads for nonmipmapped textures',
                 'Uniform-derived flat varyings use ordinary constant interpolation on SM3',
                 'Host-supplied texture dimensions and D3D9 half-pixel correction'],
        generator_sha256=sha(Path(__file__))),indent=2)+'\n')
    print('GENERATED',len(records),'effects')

if __name__=='__main__':main()
