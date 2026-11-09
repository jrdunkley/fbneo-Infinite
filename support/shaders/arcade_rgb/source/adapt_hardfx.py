"""Generate a native D3D9 effect from pinned Guest shaders and RC RGB settings.

Retain upstream source/licensing. Changes: fixed preset constants, legacy HLSL
uniform declarations, explicit LOD for nonmipmapped loop samples, and texture
dimensions supplied by the host (SM3 has no textureSize query).
"""
import json,re,hashlib,struct
from PIL import Image
from pathlib import Path
from audit import AF,OUT,UP,sha

DEST=OUT/'native_assets'

def pack_varyings(vs,ps):
    # D3D9 software vertex processing loses the high scalar TEXCOORDs used by
    # the NTSC vertex shader. Pack the same values into float4 interpolators.
    v=re.search(r'struct vs_SPIRV_Cross_Output\s*\{(.*?)\};',vs,re.S)
    q=re.search(r'struct ps_SPIRV_Cross_Input\s*\{(.*?)\};',ps,re.S)
    vf=re.findall(r'float(\d?) (\w+) : TEXCOORD(\d+);',v[1])
    pf={int(sem):(typ,name) for typ,name,sem in re.findall(r'float(\d?) (\w+) : TEXCOORD(\d+);',q[1])}
    reg=0;component=0;vm={};pm={}
    for typ,name,semantic in sorted(vf,key=lambda x:int(x[2])):
        count=int(typ or '1')
        if component+count>4:reg+=1;component=0
        suffix=f'packed{reg}.'+'xyzw'[component:component+count]
        vm[name]=suffix
        if int(semantic) in pf:
            pt,pn=pf[int(semantic)];assert pt==typ;pm[pn]=suffix
        component+=count
    declarations='\n'.join(f'float4 packed{i} : TEXCOORD{i};' for i in range(reg+1))
    vb=re.sub(r'\s*float\d? \w+ : TEXCOORD\d+;','',v[1])+declarations+'\n'
    vs=vs[:v.start(1)]+vb+vs[v.end(1):]
    ps=ps[:q.start(1)]+'\n'+declarations+'\n'+ps[q.end(1):]
    for name,replacement in vm.items():vs=re.sub(r'stage_output\.'+re.escape(name)+r'\b','stage_output.'+replacement,vs)
    for name,replacement in pm.items():ps=re.sub(r'stage_input\.'+re.escape(name)+r'\b','stage_input.'+replacement,ps)
    # Initialize padding explicitly to make reset/redraw comparisons deterministic.
    vs=vs.replace('vs_SPIRV_Cross_Output stage_output;','vs_SPIRV_Cross_Output stage_output = (vs_SPIRV_Cross_Output)0;')
    return vs,ps

def rewrite(text,defaults,stage):
    declarations=[]
    def block(m):
        for typ,name in re.findall(r'((?:row_major )?\w+) (\w+)\s*:\s*packoffset\([^;]+;',m[1]):
            key=name.split('_',1)[1] if '_' in name else ''
            if key in defaults:
                # Keep mask scaling consistent with upstream resolution variants.
                val=defaults[key]
                if key in ['masksize','mask_zoom','slotwidth','double_slot','shadowMask','maskstr']:
                    macro='RC_'+key
                    declarations.append(f'#ifndef {macro}\n#define {macro} {val}\n#endif\nstatic const {typ} {name} = {macro};')
                else:declarations.append(f'static const {typ} {name} = {val};')
            else:declarations.append(f'{typ} {name};')
        return ''
    text=re.sub(r'cbuffer\s+\w+(?:\s*:\s*register\([^)]*\))?\s*\{(.*?)\};',block,text,flags=re.S)
    samplers=re.findall(r'uniform sampler2D (\w+);',text)
    text=re.sub(r'uniform sampler2D (\w+);','',text)
    for n in samplers:
        i=int(n.rsplit('_',1)[1]);declarations.append(f'texture Image{i}; sampler2D {n} : register(s{i-2}) = sampler_state {{ Texture = <Image{i}>; }};')
    text=re.sub(r'uint2 spvTextureSize\([^}]+\}', '',text,flags=re.S)
    size_names=[]
    def size(m):
        name=m[1]+'_size';size_names.append(name)
        return f'float2({name}.xy)'
    text=re.sub(r'spvTextureSize\((LIBRA_SAMPLER2D_\d+), uint\(0\), \w+\)',size,text)
    declarations.extend('float4 '+n+';' for n in set(size_names))
    # A function wrapper allows nested argument expressions without regex parsing.
    # Derivative-dependent samples inside dynamic loops otherwise force unrolling.
    text=text.replace('tex2D(', 'sample_lod0(')
    # The no-mask preset uses -1. Its unused mask-width lookup must be in range
    # for the legacy compiler even though the mask branch is disabled.
    text=text.replace('[int(params_shadowMask)]','[int(max(params_shadowMask,0.0))]')
    text='float4 sample_lod0(sampler2D s, float2 uv) { return tex2Dlod(s, float4(uv,0,0)); }\n'+text
    # The legacy FX parser does not accept namespace-qualified entry points.
    # Prefix stage globals/functions/types, including their field references.
    names=set(re.findall(r'^static\s+(?:const\s+)?\w+\s+(\w+)',text,re.M))
    names.update(re.findall(r'^struct\s+(\w+)',text,re.M))
    names.update(re.findall(r'^\w+\s+(\w+)\([^;\n]*\)\s*\{',text,re.M))
    names.update(re.findall(r'^uniform\s+\w+\s+(\w+)',text,re.M))
    text=re.sub(r'\b\w+\b',lambda m:stage+'_'+m[0] if m[0] in names else m[0],text)
    return declarations,text

def main():
    a=json.loads((OUT/'audit.json').read_text())
    p=a['arcade_presets']['4K Flat\\RC GDV-NTSC - Arcade RGB.slangp']
    defaults={k:v['default'] for k,v in a['parameters'].items()};defaults.update({k:v for k,v in p.items() if k in defaults})
    DEST.mkdir(exist_ok=True)
    records=[]
    for name in a['shader_features']:
        stem=Path(name).stem
        vdecl,vs=rewrite((OUT/'sm3_compile'/(stem+'_vertex.hlsl')).read_text(),defaults,'vs')
        pdecl,ps=rewrite((OUT/'sm3_compile'/(stem+'_fragment.hlsl')).read_text(),defaults,'ps')
        vs,ps=pack_varyings(vs,ps)
        shared=list(dict.fromkeys(vdecl+pdecl))
        fx='// Derived from '+name+'; see SOURCES and original shader notices.\n'+'\n'.join(shared)+'\n'
        fx+=vs+'\n'+ps+'\n'
        fx+='technique t { pass p { VertexShader = compile vs_3_0 vs_main(); PixelShader = compile ps_3_0 ps_main(); } }\n'
        path=DEST/(stem+'.fx');path.write_text(fx)
        records.append(dict(shader=name,path=str(path),sha256=sha(path)))
        if stem in ['crt-guest-advanced-ntsc-pass2','deconvergence-ntsc']:
            for profile,folder in [('720','720p Steam Deck'),('1080','1080p Flat'),('1440','1440p Flat')]:
                settings=a['arcade_presets'][folder+'\\RC GDV-NTSC - Arcade RGB.slangp']
                macros=''.join(f'#define RC_{k} {settings.get(k,defaults[k])}\n' for k in ['masksize','mask_zoom','slotwidth','double_slot','shadowMask','maskstr'])
                (DEST/(stem+'_'+profile+'.fx')).write_text(macros+f'#include "{stem}.fx"\n')
    # Compact, fixed native pass graph. Runtime state stays in the renderer.
    aliases={p.get('alias'+str(i)):i for i in range(18) if p.get('alias'+str(i))}
    descriptors=[]
    for i in range(18):
        source=p['shader'+str(i)].split('/shaders_slang/')[1]
        raw=(UP/'shaders_slang'/source).read_text()
        bindings=[]
        for binding,name in re.findall(r'layout\(set = 0, binding = (\d+)\) uniform sampler2D (\w+);',raw):
            if name=='Source':index=i-1
            elif name=='Original':index=-1
            elif name=='OriginalHistory0':index=-2
            elif name.endswith('Feedback'):index=100+aliases[name[:-8]]
            elif name.startswith('SamplerLUT'):index=200+int(name[-1])-1
            else:index=aliases[name]
            bindings.append('{%s,%d}'%(binding,index))
        bindings+=['{0,0}']*(12-len(bindings))
        scale=[]
        for axis in 'xy':scale.extend([str({'source':0,'viewport':1,'absolute':2}[p['scale_type_'+axis+str(i)]]),str(float(p['scale_'+axis+str(i)]))+'f'])
        descriptors.append('{"%s.fx",%s,%s,%s,%s,{%s}}'%(Path(source).stem,str(p['float_framebuffer'+str(i)]=='true').lower(),str(i<17 and p['mipmap_input'+str(i+1)]=='true').lower(),str(p['filter_linear'+str(i)]=='true').lower(),','.join(scale),','.join(bindings)))
    header='// Generated by adapt_hardfx.py; fixed Arcade RGB graph.\nstruct RCBinding { int slot, source; };\nstruct RCPass { const char* file; bool fp,mips,linear; int sx; float x; int sy; float y; RCBinding bindings[12]; };\nstatic const RCPass rcPasses[18] = {\n'+',\n'.join(descriptors)+'\n};\n'
    (DEST/'rc_graph.h').write_text(header)
    for i in range(4):
        name=p['SamplerLUT'+str(i+1)].split('/shaders_slang/')[1]
        im=Image.open(UP/'shaders_slang'/name).convert('RGBA')
        (DEST/f'lut{i}.bgra').write_bytes(struct.pack('<II',*im.size)+im.tobytes('raw','BGRA'))
    (DEST/'manifest.json').write_text(json.dumps(records,indent=2))
    print('generated',len(records),'effects',DEST)

if __name__=='__main__':main()
