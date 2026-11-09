// Infinite local prototype host. Lola Retro shader math: Zoki, MIT (asset LICENSE).
#pragma once
#include <d3d9.h>
#include <d3dx9.h>
#include <vector>
#include "directx9_core.h"
#include <stdlib.h>
#include <string.h>

class LolaChain {
    IDirect3DDevice9* device;
    ID3DXEffect* effects[7];
    IDirect3DTexture9* targets[7][2];
    IDirect3DTexture9* original;
    IDirect3DVertexDeclaration9* declaration;
    unsigned widths[7],heights[7],nw,nh,ow,oh,lastFrame;
    int parity;
    bool hasFrame,valid;
    // Opt-in diagnostics, measurement only, off unless the environment says so.
    // INFINITE_LOLA_PROFILE=1: GPU timestamps around every pass, read three frames
    // later without a flush, logged every 240 frames. Float targets default to
    // A16B16G16R16F. INFINITE_LOLA_FP16=0 restores FP32 for diagnostic comparisons.
    IDirect3DQuery9 *profDisjoint[4],*profFreq[4],*profStamp[4][8];
    bool profiling,fp16,profQueriesOk,profIssued[4];
    int profSlot,profCount,profMissed;
    double profSum[8],profMax[8];
    static bool envOn(const char* n){const char* e=getenv(n);return e&&!strcmp(e,"1");}
    void profInit(){profiling=envOn("INFINITE_LOLA_PROFILE");const char* format=getenv("INFINITE_LOLA_FP16");fp16=!format||strcmp(format,"0")!=0;profQueriesOk=false;profSlot=profCount=profMissed=0;
        memset(profDisjoint,0,sizeof(profDisjoint));memset(profFreq,0,sizeof(profFreq));memset(profStamp,0,sizeof(profStamp));memset(profIssued,0,sizeof(profIssued));
        memset(profSum,0,sizeof(profSum));memset(profMax,0,sizeof(profMax));
        InfiniteLog("video: Lola targets fp16 %d profile %d",(int)fp16,(int)profiling);}
    void releaseQueries(){for(int s=0;s<4;s++){if(profDisjoint[s]){profDisjoint[s]->Release();profDisjoint[s]=NULL;}if(profFreq[s]){profFreq[s]->Release();profFreq[s]=NULL;}
        for(int i=0;i<8;i++)if(profStamp[s][i]){profStamp[s][i]->Release();profStamp[s][i]=NULL;}profIssued[s]=false;}profQueriesOk=false;}
    bool createQueries(){releaseQueries();HRESULT hr=S_OK;
        for(int s=0;s<4&&SUCCEEDED(hr);s++){hr=device->CreateQuery(D3DQUERYTYPE_TIMESTAMPDISJOINT,&profDisjoint[s]);
            if(SUCCEEDED(hr))hr=device->CreateQuery(D3DQUERYTYPE_TIMESTAMPFREQ,&profFreq[s]);
            for(int i=0;i<8&&SUCCEEDED(hr);i++)hr=device->CreateQuery(D3DQUERYTYPE_TIMESTAMP,&profStamp[s][i]);}
        if(FAILED(hr)){InfiniteLog("video: Lola profile queries unavailable 0x%08x",(unsigned)hr);releaseQueries();profiling=false;return false;}
        profQueriesOk=true;return true;}
    bool profBegin(){if(!profiling)return false;if(!profQueriesOk&&!createQueries())return false;
        profDisjoint[profSlot]->Issue(D3DISSUE_BEGIN);profFreq[profSlot]->Issue(D3DISSUE_END);profStamp[profSlot][0]->Issue(D3DISSUE_END);return true;}
    void profEnd(){profDisjoint[profSlot]->Issue(D3DISSUE_END);profIssued[profSlot]=true;
        int old=(profSlot+1)%4;
        if(profIssued[old]){BOOL disjoint=TRUE;UINT64 freq=0,t[8]={0,0,0,0,0,0,0,0};
            bool ready=profDisjoint[old]->GetData(&disjoint,sizeof(disjoint),0)==S_OK&&profFreq[old]->GetData(&freq,sizeof(freq),0)==S_OK;
            for(int i=0;i<8&&ready;i++)ready=profStamp[old][i]->GetData(&t[i],sizeof(t[i]),0)==S_OK;
            profIssued[old]=false;
            if(!ready||disjoint||!freq)profMissed++;
            else{for(int i=0;i<8;i++){double ms=(double)(i<7?t[i+1]-t[i]:t[7]-t[0])*1000.0/(double)freq;profSum[i]+=ms;if(ms>profMax[i])profMax[i]=ms;}
                if(++profCount%240==0){static const char* n[8]={"encode","decode","glowh","glowv","beam","crt","present","total"};char line[640];
                    int p=sprintf(line,"video: Lola profile fp16=%d n=%d missed=%d size %ux%u->%ux%u ms mean/max",(int)fp16,profCount,profMissed,nw,nh,ow,oh);
                    for(int i=0;i<8;i++)p+=sprintf(line+p," %s %.3f/%.3f",n[i],profSum[i]/240.0,profMax[i]);
                    InfiniteLog("%s",line);memset(profSum,0,sizeof(profSum));memset(profMax,0,sizeof(profMax));}}}
        profSlot=(profSlot+1)%4;}
    static void sizeParam(ID3DXEffect* e,const char* name,unsigned w,unsigned h) {
        if(e->GetParameterByName(NULL,name)){float a[4]={(float)w,(float)h,1.f/w,1.f/h};e->SetFloatArray(name,a,4);}
    }
    void unbind() {
        for(int s=0;s<16;s++)device->SetTexture(s,NULL);
        for(int i=0;i<7;i++)if(effects[i])for(int s=2;s<5;s++){
            char name[32];sprintf(name,"Image%d",s);if(effects[i]->GetParameterByName(NULL,name))effects[i]->SetTexture(name,NULL);
        }
    }
    void releaseTargets() {
        unbind();
        for(int i=0;i<7;i++)for(int j=0;j<2;j++)if(targets[i][j]){targets[i][j]->Release();targets[i][j]=NULL;}
        if(original){original->Release();original=NULL;}
        nw=nh=ow=oh=0;hasFrame=false;parity=0;
    }
    HRESULT allocate(unsigned w,unsigned h,unsigned outputW,unsigned outputH) {
        if(nw==w&&nh==h&&ow==outputW&&oh==outputH)return S_OK;
        releaseTargets();
        HRESULT hr=device->CreateTexture(w,h,1,D3DUSAGE_RENDERTARGET,D3DFMT_A8R8G8B8,D3DPOOL_DEFAULT,&original,NULL);
        if(FAILED(hr))return hr;
        unsigned sw=w,sh=h;
        for(int i=0;i<7;i++) {
            unsigned x=sw,y=sh;
            if(i==0)x=4*w;
            if(i==2){x=(unsigned)(sw*.125f+.5f);y=(unsigned)(sh*.5f+.5f);}
            if(i==4){x=8192;y=(unsigned)(sh*2.05f+.5f);}
            if(i>=5){x=outputW;y=outputH;}
            widths[i]=x;heights[i]=y;
            for(int j=0;j<(i==5?2:1);j++) {
                hr=device->CreateTexture(x,y,1,D3DUSAGE_RENDERTARGET,i<6?(fp16?D3DFMT_A16B16G16R16F:D3DFMT_A32B32G32R32F):D3DFMT_A8R8G8B8,D3DPOOL_DEFAULT,&targets[i][j],NULL);
                if(FAILED(hr))return hr;
                IDirect3DSurface9* s=NULL;targets[i][j]->GetSurfaceLevel(0,&s);hr=device->SetRenderTarget(0,s);s->Release();
                if(FAILED(hr))return hr;
                if(FAILED(hr=device->Clear(0,NULL,D3DCLEAR_TARGET,0,1,0)))return hr;
            }
            sw=x;sh=y;
        }
        nw=w;nh=h;ow=outputW;oh=outputH;return S_OK;
    }
    void bind(ID3DXEffect* e,int slot,IDirect3DTexture9* t,bool linear,bool border) {
        char name[64];sprintf(name,"Image%d",slot);e->SetTexture(name,t);
        D3DSURFACE_DESC d;t->GetLevelDesc(0,&d);sprintf(name,"LIBRA_SAMPLER2D_%d_size",slot);sizeParam(e,name,d.Width,d.Height);
        int s=slot-2;
        device->SetSamplerState(s,D3DSAMP_MINFILTER,linear?D3DTEXF_LINEAR:D3DTEXF_POINT);
        device->SetSamplerState(s,D3DSAMP_MAGFILTER,linear?D3DTEXF_LINEAR:D3DTEXF_POINT);
        device->SetSamplerState(s,D3DSAMP_MIPFILTER,D3DTEXF_NONE);
        device->SetSamplerState(s,D3DSAMP_ADDRESSU,border?D3DTADDRESS_BORDER:D3DTADDRESS_CLAMP);
        device->SetSamplerState(s,D3DSAMP_ADDRESSV,border?D3DTADDRESS_BORDER:D3DTADDRESS_CLAMP);
        device->SetSamplerState(s,D3DSAMP_BORDERCOLOR,0);device->SetSamplerState(s,D3DSAMP_SRGBTEXTURE,FALSE);
    }
    HRESULT drawPass(int i,unsigned frame) {
        ID3DXEffect* e=effects[i];unbind();
        IDirect3DSurface9* surface=NULL;targets[i][i==5?parity:0]->GetSurfaceLevel(0,&surface);
        HRESULT hr=device->SetRenderTarget(0,surface);surface->Release();if(FAILED(hr))return hr;
        D3DVIEWPORT9 vp={0,0,widths[i],heights[i],0,1};device->SetViewport(&vp);
        sizeParam(e,"params_OriginalSize",nw,nh);sizeParam(e,"params_OutputSize",widths[i],heights[i]);
        sizeParam(e,"params_SourceSize",i?widths[i-1]:nw,i?heights[i-1]:nh);
        e->SetInt("params_FrameCount",frame);
        D3DXMATRIX identity;memset(&identity,0,sizeof(identity));identity._11=identity._22=identity._33=identity._44=1;e->SetMatrix("global_MVP",&identity);
        float half[4]={1.f/widths[i],1.f/heights[i],0,0};e->SetFloatArray("vs_gl_HalfPixel",half,4);
        // Source uses the consuming pass; named aliases retain the producing
        // pass's policy. Original retains pass zero's point/border policy.
        if(i==4)bind(e,3,targets[1][0],true,true);
        else if(i==5){bind(e,2,targets[4][0],true,false);bind(e,3,targets[3][0],true,false);bind(e,4,targets[5][parity^1],true,false);}
        else {bind(e,2,i?targets[i-1][i==6?parity:0]:original,i>0&&i<6,i<2);if(i==1)bind(e,3,original,false,true);}
        struct Vertex{float x,y,z,w,u,v;};Vertex q[]={{-1,1,0,1,0,0},{1,1,0,1,1,0},{-1,-1,0,1,0,1},{1,-1,0,1,1,1}};
        UINT passes=0;hr=e->Begin(&passes,D3DXFX_DONOTSAVESTATE);if(FAILED(hr))return hr;
        hr=e->BeginPass(0);if(SUCCEEDED(hr)){hr=device->DrawPrimitiveUP(D3DPT_TRIANGLESTRIP,2,q,sizeof(Vertex));e->EndPass();}e->End();return hr;
    }
public:
    IDirect3DTexture9* DebugTexture(int i){return targets[i][i==5?(parity^1):0];}
    explicit LolaChain(IDirect3DDevice9* d):device(d),original(NULL),declaration(NULL),nw(0),nh(0),ow(0),oh(0),lastFrame(0),parity(0),hasFrame(false),valid(false){memset(effects,0,sizeof(effects));memset(targets,0,sizeof(targets));profInit();}
    ~LolaChain(){releaseQueries();releaseTargets();for(int i=0;i<7;i++)if(effects[i])effects[i]->Release();if(declaration)declaration->Release();}
    bool Load(const wchar_t* directory) {
        const wchar_t* names[]={L"encode",L"decode",L"glow-h",L"glow-v",L"beam",L"crt",L"present"};
        for(int i=0;i<7;i++){
            wchar_t path[2048];_snwprintf(path,2048,L"%ls/%ls.fx",directory,names[i]);ID3DXBuffer* error=NULL;
            HRESULT hr=_D3DXCreateEffectFromFile(device,path,NULL,NULL,D3DXSHADER_ENABLE_BACKWARDS_COMPATIBILITY,NULL,&effects[i],&error);
            if(error){if(FAILED(hr))InfiniteLog("video: Lola pass %d: %s",i,(char*)error->GetBufferPointer());error->Release();}
            if(FAILED(hr)||!effects[i])return false;
            D3DXHANDLE tech=NULL;if(FAILED(effects[i]->FindNextValidTechnique(NULL,&tech))||FAILED(effects[i]->SetTechnique(tech)))return false;
        }
        D3DVERTEXELEMENT9 elems[]={{0,0,D3DDECLTYPE_FLOAT4,D3DDECLMETHOD_DEFAULT,D3DDECLUSAGE_TEXCOORD,0},{0,16,D3DDECLTYPE_FLOAT2,D3DDECLMETHOD_DEFAULT,D3DDECLUSAGE_TEXCOORD,1},D3DDECL_END()};
        valid=SUCCEEDED(device->CreateVertexDeclaration(elems,&declaration));return valid;
    }
    void OnLostDevice(){releaseQueries();releaseTargets();for(int i=0;i<7;i++)if(effects[i])effects[i]->OnLostDevice();}
    void OnResetDevice(){for(int i=0;i<7;i++)if(effects[i])effects[i]->OnResetDevice();}
    IDirect3DTexture9* Render(IDirect3DTexture9* input,unsigned w,unsigned h,unsigned outputW,unsigned outputH,unsigned frame) {
        if(!valid||!input||!w||!h||!outputW||!outputH)return NULL;
        if(hasFrame&&frame==lastFrame&&w==nw&&h==nh&&outputW==ow&&outputH==oh)return targets[6][0];
        IDirect3DStateBlock9* state=NULL;IDirect3DSurface9* previous=NULL;D3DVIEWPORT9 viewport;
        if(FAILED(device->CreateStateBlock(D3DSBT_ALL,&state)))return NULL;
        device->GetRenderTarget(0,&previous);device->GetViewport(&viewport);
        if(hasFrame&&frame<lastFrame)releaseTargets();
        HRESULT hr=allocate(w,h,outputW,outputH);
        if(SUCCEEDED(hr)){
            // Crop the emulator's padded texture once, without resampling.
            IDirect3DSurface9 *from=NULL,*to=NULL;input->GetSurfaceLevel(0,&from);original->GetSurfaceLevel(0,&to);
            RECT crop={0,0,(LONG)w,(LONG)h};hr=device->StretchRect(from,&crop,to,NULL,D3DTEXF_NONE);from->Release();to->Release();
            device->SetVertexDeclaration(declaration);device->SetRenderState(D3DRS_ZENABLE,FALSE);device->SetRenderState(D3DRS_ALPHABLENDENABLE,FALSE);
            device->SetRenderState(D3DRS_ALPHATESTENABLE,FALSE);device->SetRenderState(D3DRS_CULLMODE,D3DCULL_NONE);device->SetRenderState(D3DRS_SCISSORTESTENABLE,FALSE);
            device->SetRenderState(D3DRS_SRGBWRITEENABLE,FALSE);device->SetRenderState(D3DRS_COLORWRITEENABLE,15);
            if(SUCCEEDED(hr)){hr=device->BeginScene();if(SUCCEEDED(hr)){
                bool prof=profBegin();
                for(int i=0;i<7&&SUCCEEDED(hr);i++){hr=drawPass(i,frame);if(prof)profStamp[profSlot][i+1]->Issue(D3DISSUE_END);}
                if(prof)profEnd();
                device->EndScene();}}
        }
        unbind();device->SetRenderTarget(0,previous);if(previous)previous->Release();device->SetViewport(&viewport);state->Apply();state->Release();
        if(FAILED(hr)){InfiniteLog("video: Lola render failed 0x%08x; using unfiltered frame",(unsigned)hr);valid=false;releaseTargets();return NULL;}
        hasFrame=true;lastFrame=frame;parity^=1;return targets[6][0];
    }
};
