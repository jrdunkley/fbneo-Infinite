// Native D3D9 HardFX pass host. Shader math and notices live in the asset pack.
#pragma once
#include <d3d9.h>
#include <d3dx9.h>
#include <vector>
#include "directx9_core.h"
#include "rc_graph.h"
#include "rc_tuning.h"

// Set by the DX9 Alt blitter when its device is Direct3D9Ex: the managed pool does not
// exist there, so the lookup textures live in the default pool and follow device resets.
extern bool bInfiniteD3D9Ex;

class RCChain {
    IDirect3DDevice9* device;
    ID3DXEffect* effects[48]; // Fixed accepted graph, then lazily loaded tunable graph.
    IDirect3DTexture9* targets[18][2];
    IDirect3DTexture9* luts[4];
    IDirect3DVertexDeclaration9* declaration;
    unsigned widths[18],heights[18];
    unsigned nativeW,nativeH,outputW,outputH,lastFrame;
    int parity;
    bool valid,hasFrame;
    bool dirty,custom,tuningLoaded;
    bool lutsDefault;
    float options[RC_OPTION_COUNT];
    wchar_t assetDirectory[MAX_PATH];
    static void sizeParam(ID3DXEffect* e,const char* name,unsigned w,unsigned h) {
        D3DXHANDLE handle=e->GetParameterByName(NULL,name);
        if(handle){float a[4]={(float)w,(float)h,1.f/w,1.f/h};e->SetFloatArray(handle,a,4);}
    }
    static void scalar(ID3DXEffect* e,const char* name,float value) {
        D3DXHANDLE handle=e->GetParameterByName(NULL,name);if(handle)e->SetFloat(handle,value);
    }
    static unsigned dimension(int mode,float scale,unsigned source,unsigned viewport) {
        return (unsigned)(scale*(mode==0?source:mode==1?viewport:1)+0.5f);
    }
    static bool doubled(int pass){return pass==0 || pass==2 || pass==9;}
    void unbind() {
        for(int i=0;i<16;i++)device->SetTexture(i,NULL);
        for(int i=0;i<48;i++)if(effects[i])for(int s=2;s<14;s++){
            char n[32];sprintf(n,"Image%d",s);D3DXHANDLE h=effects[i]->GetParameterByName(NULL,n);
            if(h)effects[i]->SetTexture(h,NULL);
        }
    }
    void releaseTargets() {
        unbind();
        for(int i=0;i<18;i++)for(int j=0;j<2;j++)if(targets[i][j]){targets[i][j]->Release();targets[i][j]=NULL;}
        nativeW=nativeH=outputW=outputH=0;hasFrame=false;parity=0;
    }
    HRESULT allocate(unsigned w,unsigned h,unsigned ow,unsigned oh) {
        if(nativeW==w && nativeH==h && outputW==ow && outputH==oh)return S_OK;
        releaseTargets();
        unsigned sw=w,sh=h;
        for(int i=0;i<18;i++) {
            const RCPass& p=rcPasses[i];
            widths[i]=dimension(p.sx,p.x,sw,ow);heights[i]=dimension(p.sy,p.y,sh,oh);
            for(int j=0;j<(doubled(i)?2:1);j++) {
                HRESULT hr=device->CreateTexture(widths[i],heights[i],p.mips?0:1,
                    D3DUSAGE_RENDERTARGET|(p.mips?D3DUSAGE_AUTOGENMIPMAP:0),
                    p.fp?D3DFMT_A32B32G32R32F:D3DFMT_A8R8G8B8,D3DPOOL_DEFAULT,&targets[i][j],NULL);
                if(FAILED(hr))return hr;
                IDirect3DSurface9* s=NULL;targets[i][j]->GetSurfaceLevel(0,&s);
                hr=device->SetRenderTarget(0,s);s->Release();if(FAILED(hr))return hr;
                hr=device->Clear(0,NULL,D3DCLEAR_TARGET,0,1,0);if(FAILED(hr))return hr;
                if(p.mips)targets[i][j]->GenerateMipSubLevels();
            }
            sw=widths[i];sh=heights[i];
        }
        nativeW=w;nativeH=h;outputW=ow;outputH=oh;return S_OK;
    }
    HRESULT drawPass(int i,IDirect3DTexture9* input,unsigned frame) {
        const RCPass& p=rcPasses[i];int effectIndex=i;
        if(i>=16 && outputH<1800)effectIndex=18+(outputH<900?0:outputH<1260?2:4)+(i-16);
        ID3DXEffect* e=effects[effectIndex+(custom?24:0)];
        IDirect3DTexture9* target=targets[i][doubled(i)?parity:0];
        IDirect3DSurface9* surface=NULL;HRESULT hr=target->GetSurfaceLevel(0,&surface);
        if(FAILED(hr))return hr;
        for(int s=0;s<16;s++)device->SetTexture(s,NULL);
        hr=device->SetRenderTarget(0,surface);surface->Release();if(FAILED(hr))return hr;
        D3DVIEWPORT9 viewport={0,0,widths[i],heights[i],0,1};device->SetViewport(&viewport);
        sizeParam(e,"params_OriginalSize",nativeW,nativeH);
        sizeParam(e,"params_OutputSize",widths[i],heights[i]);
        sizeParam(e,"params_SourceSize",i?widths[i-1]:nativeW,i?heights[i-1]:nativeH);
        if(e->GetParameterByName(NULL,"params_FrameCount"))e->SetInt("params_FrameCount",(int)frame);
        sizeParam(e,"global_OriginalSize",nativeW,nativeH);
        sizeParam(e,"global_OutputSize",widths[i],heights[i]);
        sizeParam(e,"global_SourceSize",i?widths[i-1]:nativeW,i?heights[i-1]:nativeH);
        if(e->GetParameterByName(NULL,"global_FrameCount"))e->SetInt("global_FrameCount",(int)frame);
        D3DXMATRIX identity;memset(&identity,0,sizeof(identity));identity._11=identity._22=identity._33=identity._44=1;
        e->SetMatrix("global_MVP",&identity);
        float half[4]={1.f/widths[i],1.f/heights[i],0,0};e->SetFloatArray("vs_gl_HalfPixel",half,4);
        // Resolution-specific values from the upstream Arcade RGB presets.
        bool small=outputH<900,medium=outputH<1260,large=outputH<1800;
        scalar(e,"params_shadowMask",small?-1.f:4.f);scalar(e,"params_maskstr",small?-.5f:1.f);
        scalar(e,"params_masksize",1.f);scalar(e,"params_mask_zoom",(!small && medium)?-2.f:0.f);
        scalar(e,"params_slotwidth",(!small && large)?1.f:0.f);scalar(e,"params_double_slot",2.f);
        if(custom) {
            scalar(e,"params_brightboost",options[1]);scalar(e,"params_brightboost1",options[2]);
            scalar(e,"global_gamma_out",options[3]);scalar(e,"params_gamma_out",options[3]);
            scalar(e,"params_scanline1",options[4]);scalar(e,"params_scanline2",options[5]);
            scalar(e,"params_beam_min",options[6]);scalar(e,"params_beam_max",options[7]);
            scalar(e,"params_maskstr",(small?-.5f:1.f)*options[8]);scalar(e,"params_masksize",options[9]);
            // The accepted mask 4 uses Dark/Light instead of maskstr for contrast.
            scalar(e,"params_maskDark",1.f+.1f*options[8]);scalar(e,"params_maskLight",1.f-.3f*options[8]);
            scalar(e,"params_slotmask",options[10]);scalar(e,"params_slotmask1",options[10]);
            scalar(e,"params_warpX",options[11]);scalar(e,"params_warpY",options[11]);
            scalar(e,"global_bloom",options[12]);scalar(e,"global_halation",options[13]);
            scalar(e,"params_glow",options[14]);scalar(e,"params_ntsc_sat",options[15]);
            scalar(e,"params_WP",options[16]);scalar(e,"params_ntsc_sharp",options[17]);
            scalar(e,"params_ntsc_cscale",options[18]);scalar(e,"params_ntsc_cscale1",options[18]*.5625f);
            scalar(e,"params_ntsc_ring",options[19]);
        }
        for(int b=0;b<12 && p.bindings[b].slot;b++) {
            const RCBinding& binding=p.bindings[b];int source=binding.source;
            IDirect3DTexture9* tex=NULL;
            if(source>=200)tex=luts[source-200];
            else if(source>=100)tex=targets[source-100][parity^1];
            else if(source==-2)tex=targets[0][parity^1];
            else if(source==-1)tex=i?targets[0][parity]:input;
            else tex=targets[source][doubled(source)?parity:0];
            if(!tex)return E_FAIL;
            D3DSURFACE_DESC desc;tex->GetLevelDesc(0,&desc);
            char name[64];sprintf(name,"Image%d",binding.slot);e->SetTexture(name,tex);
            sprintf(name,"LIBRA_SAMPLER2D_%d_size",binding.slot);sizeParam(e,name,desc.Width,desc.Height);
        }
        struct Vertex{float x,y,z,w,u,v;};float u=1,v=1;
        if(i==0){D3DSURFACE_DESC d;input->GetLevelDesc(0,&d);u=(float)nativeW/d.Width;v=(float)nativeH/d.Height;}
        Vertex q[]={{-1,1,0,1,0,0},{1,1,0,1,u,0},{-1,-1,0,1,0,v},{1,-1,0,1,u,v}};
        UINT passes=0;hr=e->Begin(&passes,D3DXFX_DONOTSAVESTATE);if(FAILED(hr))return hr;
        hr=e->BeginPass(0);
        if(SUCCEEDED(hr)) {
            for(int b=0;b<12 && p.bindings[b].slot;b++) {
                int slot=p.bindings[b].slot-2;bool linear=p.linear || p.bindings[b].source>=200;
                device->SetSamplerState(slot,D3DSAMP_MINFILTER,linear?D3DTEXF_LINEAR:D3DTEXF_POINT);
                device->SetSamplerState(slot,D3DSAMP_MAGFILTER,linear?D3DTEXF_LINEAR:D3DTEXF_POINT);
                device->SetSamplerState(slot,D3DSAMP_MIPFILTER,D3DTEXF_LINEAR);
                device->SetSamplerState(slot,D3DSAMP_ADDRESSU,D3DTADDRESS_BORDER);
                device->SetSamplerState(slot,D3DSAMP_ADDRESSV,D3DTADDRESS_BORDER);
                device->SetSamplerState(slot,D3DSAMP_BORDERCOLOR,0);
                device->SetSamplerState(slot,D3DSAMP_SRGBTEXTURE,FALSE);
            }
            hr=device->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP,2,q,sizeof(Vertex));e->EndPass();
        }
        e->End();if(p.mips)target->GenerateMipSubLevels();return hr;
    }
public:
#ifdef RC_PROBE
    IDirect3DTexture9* DebugTexture(int i){return targets[i][doubled(i)?(parity^1):0];}
#endif
    explicit RCChain(IDirect3DDevice9* d):device(d),declaration(NULL),nativeW(0),nativeH(0),outputW(0),outputH(0),lastFrame(0),parity(0),valid(false),hasFrame(false),dirty(false),custom(false),tuningLoaded(false) {
        memset(effects,0,sizeof(effects));memset(targets,0,sizeof(targets));memset(luts,0,sizeof(luts));
        assetDirectory[0]=0;lutsDefault=false;for(int i=0;i<RC_OPTION_COUNT;i++)options[i]=rcOptions[i].initial;
    }
    ~RCChain(){releaseTargets();for(int i=0;i<48;i++)if(effects[i])effects[i]->Release();for(int i=0;i<4;i++)if(luts[i])luts[i]->Release();if(declaration)declaration->Release();}
    void SetOptions(int group,const float* values) {
        if(group<0||group>=5)return;
        for(int j=0;j<4;j++) {
            int i=group*4+j;float v=RCClamp(i,values[j]);
            if(options[i]!=v){options[i]=v;if(i)dirty=true;}
        }
        custom=false;for(int i=1;i<RC_OPTION_COUNT;i++)if(options[i]!=rcOptions[i].initial)custom=true;
    }
    float Strength()const{return options[0];}
    bool loadEffects(const wchar_t* directory,int offset) {
        for(int i=0;i<24;i++) {
            wchar_t file[2048],name[128];
            if(i<18)MultiByteToWideChar(CP_UTF8,0,rcPasses[i].file,-1,name,128);
            else _snwprintf(name,128,L"%ls_%d.fx",i%2?L"deconvergence-ntsc":L"crt-guest-advanced-ntsc-pass2",i<20?720:i<22?1080:1440);
            _snwprintf(file,2048,L"%ls/%ls",directory,name);
            ID3DXBuffer* error=NULL;
            HRESULT hr=_D3DXCreateEffectFromFile(device,file,NULL,NULL,D3DXSHADER_ENABLE_BACKWARDS_COMPATIBILITY,NULL,&effects[i+offset],&error);
            if(error){if(FAILED(hr))InfiniteLog("HardFX Arcade RGB pass %d: %s",i,(char*)error->GetBufferPointer());error->Release();}
            if(FAILED(hr)||!effects[i+offset])return false;
            D3DXHANDLE tech=NULL;if(FAILED(effects[i+offset]->FindNextValidTechnique(NULL,&tech))||FAILED(effects[i+offset]->SetTechnique(tech)))return false;
        }
        return true;
    }
    bool Load(const wchar_t* directory) {
        if(wcslen(directory)>=MAX_PATH)return false;
        wcscpy(assetDirectory,directory);
        if(!loadEffects(directory,0))return false;
        if(!loadLuts())return false;
        D3DVERTEXELEMENT9 elements[]={{0,0,D3DDECLTYPE_FLOAT4,D3DDECLMETHOD_DEFAULT,D3DDECLUSAGE_TEXCOORD,0},{0,16,D3DDECLTYPE_FLOAT2,D3DDECLMETHOD_DEFAULT,D3DDECLUSAGE_TEXCOORD,1},D3DDECL_END()};
        if(FAILED(device->CreateVertexDeclaration(elements,&declaration)))return false;
        valid=true;return true;
    }
    // The four lookup textures: managed pool on a classic device (survives resets by itself),
    // default pool on a Direct3D9Ex device (released before a reset and reloaded after it).
    bool loadLuts() {
        releaseLuts();
        lutsDefault=bInfiniteD3D9Ex;
        for(int i=0;i<4;i++) {
            wchar_t path[2048];_snwprintf(path,2048,L"%ls/lut%d.bgra",assetDirectory,i);
            FILE* f=_wfopen(path,L"rb");if(!f)return false;unsigned wh[2];
            if(fread(wh,4,2,f)!=2||wh[0]>4096||wh[1]>4096||!wh[0]||!wh[1]){fclose(f);return false;}
            std::vector<unsigned char> data(wh[0]*wh[1]*4);bool ok=fread(data.data(),1,data.size(),f)==data.size();fclose(f);if(!ok)return false;
            DWORD usage=lutsDefault?D3DUSAGE_DYNAMIC:0;D3DPOOL pool=lutsDefault?D3DPOOL_DEFAULT:D3DPOOL_MANAGED;
            if(FAILED(device->CreateTexture(wh[0],wh[1],1,usage,D3DFMT_A8R8G8B8,pool,&luts[i],NULL)))return false;
            D3DLOCKED_RECT lock;if(FAILED(luts[i]->LockRect(0,&lock,NULL,lutsDefault?D3DLOCK_DISCARD:0)))return false;
            for(unsigned y=0;y<wh[1];y++)memcpy((char*)lock.pBits+y*lock.Pitch,data.data()+y*wh[0]*4,wh[0]*4);
            luts[i]->UnlockRect(0);
        }
        return true;
    }
    void releaseLuts(){for(int i=0;i<4;i++){if(luts[i])luts[i]->Release();luts[i]=NULL;}}
    void OnLostDevice(){releaseTargets();if(lutsDefault)releaseLuts();for(int i=0;i<48;i++)if(effects[i])effects[i]->OnLostDevice();}
    void OnResetDevice(){for(int i=0;i<48;i++)if(effects[i])effects[i]->OnResetDevice();if(lutsDefault&&valid&&!loadLuts()){valid=false;InfiniteLog("HardFX Arcade RGB lookup textures failed to reload after a device reset");}}
    IDirect3DTexture9* Render(IDirect3DTexture9* input,unsigned w,unsigned h,unsigned ow,unsigned oh,unsigned frame) {
        if(!valid||!input||!w||!h||!ow||!oh)return NULL;
        if(hasFrame && !dirty && frame==lastFrame && w==nativeW&&h==nativeH&&ow==outputW&&oh==outputH)return targets[17][0];
        if(custom && !tuningLoaded) {
            wchar_t directory[MAX_PATH+16];_snwprintf(directory,MAX_PATH+16,L"%ls/tuning",assetDirectory);
            if(!loadEffects(directory,24)){valid=false;InfiniteLog("HardFX Arcade RGB tuning assets failed");return NULL;}
            tuningLoaded=true;InfiniteLog("video: Arcade RGB tuning graph loaded");
        }
        IDirect3DStateBlock9* state=NULL;IDirect3DSurface9* previous=NULL;D3DVIEWPORT9 viewport;
        if(FAILED(device->CreateStateBlock(D3DSBT_ALL,&state)))return NULL;
        device->GetRenderTarget(0,&previous);device->GetViewport(&viewport);
        if(hasFrame && frame<lastFrame)releaseTargets();
        HRESULT hr=allocate(w,h,ow,oh);
        // A paused-picture edit replaces this frame using the same prior history.
        // Merely redrawing must never consume another temporal feedback step.
        if(hasFrame && frame==lastFrame)parity^=1;
        if(SUCCEEDED(hr)) {
            device->SetVertexDeclaration(declaration);device->SetRenderState(D3DRS_ZENABLE,FALSE);
            device->SetRenderState(D3DRS_ALPHABLENDENABLE,FALSE);device->SetRenderState(D3DRS_ALPHATESTENABLE,FALSE);
            device->SetRenderState(D3DRS_CULLMODE,D3DCULL_NONE);device->SetRenderState(D3DRS_SCISSORTESTENABLE,FALSE);
            device->SetRenderState(D3DRS_SRGBWRITEENABLE,FALSE);device->SetRenderState(D3DRS_COLORWRITEENABLE,15);
            hr=device->BeginScene();
            if(SUCCEEDED(hr)){for(int i=0;i<18 && SUCCEEDED(hr);i++)hr=drawPass(i,input,frame);device->EndScene();}
        }
        device->SetRenderTarget(0,previous);if(previous)previous->Release();device->SetViewport(&viewport);state->Apply();state->Release();
        if(FAILED(hr)){InfiniteLog("HardFX Arcade RGB rendering failed 0x%08x; using unfiltered frame",(unsigned)hr);valid=false;return NULL;}
        dirty=false;hasFrame=true;lastFrame=frame;parity^=1;return targets[17][0];
    }
};
