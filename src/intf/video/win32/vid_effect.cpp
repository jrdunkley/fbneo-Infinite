#include <vector> // Before legacy XAudio SAL macros (__in / __out).
#include "burner.h"
#include "vid_effect.h"
#include <d3d9.h>
#include <d3dx9.h>
#include "directx9_core.h"
#include "rc_chain.h" // Includes display-aware live CRT controls.
#include "lola_chain.h"

#define RELEASE(x) { if ((x)) (x)->Release(); (x) = NULL; }

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
VidEffect::VidEffect(IDirect3DDevice9 *_d3dDevice) : mChain(NULL), mLola(NULL), mOutputWidth(0), mOutputHeight(0), mFrame(0), mD3DDevice(_d3dDevice), mEffect(NULL), mErrorBuffer(NULL)
{
	mEffect = NULL;
}

void VidEffect::OnLostDevice()
{
    // Low/Medium retain the original default-pool texture for compositing.
    if (mEffect && mEffect->GetParameterByName(NULL, "clean_image")) mEffect->SetTexture("clean_image", NULL);
	if (mChain) mChain->OnLostDevice();
	if (mLola) mLola->OnLostDevice();
	if (mEffect) InfiniteLog("video: HardFX OnLostDevice 0x%08x", (unsigned int)mEffect->OnLostDevice());
}

void VidEffect::OnResetDevice()
{
	if (mChain) mChain->OnResetDevice();
	if (mLola) mLola->OnResetDevice();
	if (mEffect) InfiniteLog("video: HardFX OnResetDevice 0x%08x", (unsigned int)mEffect->OnResetDevice());
}

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
VidEffect::~VidEffect()
{
	delete mChain;
	delete mLola;
	RELEASE(mErrorBuffer);
	RELEASE(mEffect);
}

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
int VidEffect::Load(const char *_filename)
{
	delete mChain; mChain = NULL;
	delete mLola; mLola = NULL;
	RELEASE(mErrorBuffer);
	RELEASE(mEffect);

	// Lua callbacks and file dialogs can change the process working directory.
	// Shaders (including their relative #includes) belong beside the executable.
	TCHAR filename[MAX_PATH];
	DWORD length = GetModuleFileName(NULL, filename, _countof(filename));
	if (!length || length >= _countof(filename)) return 1;
	TCHAR* basename = _tcsrchr(filename, _T('\\'));
	if (!basename) return 1;
	++basename;
	TCHAR* relative = ANSIToTCHAR(_filename, NULL, 0);
	if (!relative || _tcslen(relative) >= _countof(filename) - (basename - filename)) return 1;
	_tcscpy(basename, relative);

	HRESULT result = _D3DXCreateEffectFromFile(mD3DDevice, filename, NULL, NULL, D3DXSHADER_ENABLE_BACKWARDS_COMPATIBILITY, NULL, &mEffect, &mErrorBuffer);
	if (FAILED(result) || !mEffect)
	{
		InfiniteLog("video: effect compile failed %s 0x%08x", _filename, (unsigned int)result);
		if (mErrorBuffer) {
			InfiniteLog("video: effect compiler: %s", (const char*)mErrorBuffer->GetBufferPointer());
			dprintf(_T("  * Error: Couldn't compile effect.\n"));
			dprintf(_T("\n%hs\n\n"), mErrorBuffer->GetBufferPointer());
		}
		RELEASE(mEffect);
		return 1;
	}
	D3DXHANDLE technique = NULL;
	result = mEffect->FindNextValidTechnique(NULL, &technique);
	if (FAILED(result) || !technique || FAILED(result = mEffect->SetTechnique(technique))) {
		InfiniteLog("video: no supported effect technique %s 0x%08x", _filename, (unsigned int)result);
		RELEASE(mEffect);
		return 1;
	}

    if (!strcmp(_filename, "support/shaders/crt_arcade_rgb.fx") ||
        !strcmp(_filename, "support/shaders/crt_arcade_rgb_low.fx") ||
        !strcmp(_filename, "support/shaders/crt_arcade_rgb_medium.fx")) {
        _tcscpy(basename, _T("support/shaders/arcade_rgb"));
        mChain = new RCChain(mD3DDevice);
        float strength = strstr(_filename,"_low") ? 0.4f : strstr(_filename,"_medium") ? 0.7f : 1.f;
        float initial[4]={strength,1.4f,1.1f,1.95f};mChain->SetOptions(0,initial);
        mEffect->SetFloat("effect_strength",strength);
        if (!mChain->Load(filename)) {
            InfiniteLog("video: Arcade RGB asset load failed");
            delete mChain; mChain = NULL; RELEASE(mEffect); return 1;
        }
    }
    const TCHAR* lolaPreset = !strcmp(_filename,"support/shaders/crt_lola_studio.fx") ? _T("studio-monitor-rgb") :
        !strcmp(_filename,"support/shaders/crt_lola_consumer.fx") ? _T("consumer-tv-scart-rgb") :
        !strcmp(_filename,"support/shaders/crt_lola_1084s.fx") ? _T("amiga-1084s") : NULL;
    if (lolaPreset) {
        _sntprintf(basename, _countof(filename)-(basename-filename), _T("support/shaders/lola_retro/%s"),lolaPreset);
        mLola = new LolaChain(mD3DDevice);
        if (!mLola->Load(filename)) {
            InfiniteLog("video: Lola asset load failed: %s",_filename);
            delete mLola; mLola=NULL; RELEASE(mEffect); return 1;
        }
    }
    return 0;
}

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
void VidEffect::Begin()
{
	mEffect->Begin(NULL, NULL);
	mEffect->BeginPass(0);
}

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
void VidEffect::End()
{
	mEffect->EndPass();
	mEffect->End();
}

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
void VidEffect::SetParamFloat2(const char *_name, float _x, float _y)
{
	if (!strcmp(_name, "output_size")) { mOutputWidth = (unsigned)_x; mOutputHeight = (unsigned)_y; }
	if (!strcmp(_name, "video_time")) mFrame = (unsigned)_x;
	float array[] = {_x, _y};
	mEffect->SetFloatArray(_name, array, 2);
}

// ----------------------------------------------------------------------------
// --
// ----------------------------------------------------------------------------
void VidEffect::SetParamFloat4(const char *_name, float _x, float _y, float _z, float _w)
{
	float array[] = {_x, _y, _z, _w};
    if (mChain) {
        int group = !strcmp(_name,"user_settings") ? 0 : !strcmp(_name,"user_settings2") ? 1 :
            !strcmp(_name,"user_settings3") ? 2 : !strcmp(_name,"user_settings4") ? 3 : !strcmp(_name,"user_settings5") ? 4 : -1;
        if(group>=0)mChain->SetOptions(group,array);
    }
    mEffect->SetFloatArray(_name, array, 4);
}

IDirect3DTexture9* VidEffect::PrepareTexture(IDirect3DTexture9* input, unsigned width, unsigned height)
{
    if (mLola) {
        IDirect3DTexture9* result=mLola->Render(input,width,height,mOutputWidth,mOutputHeight,mFrame);
        mEffect->SetFloat("chain_active",result?1.f:0.f);
        if (result) { float size[2]={(float)width,(float)height};mEffect->SetFloatArray("video_size",size,2); }
        return result?result:input;
    }
    if (!mChain) return input;
    mEffect->SetFloat("effect_strength",mChain->Strength());
    if (mEffect->GetParameterByName(NULL, "clean_image")) mEffect->SetTexture("clean_image", input);
    IDirect3DTexture9* result = mChain->Render(input, width, height, mOutputWidth, mOutputHeight, mFrame);
    mEffect->SetFloat("chain_active", result ? 1.f : 0.f);
    if (result) { float size[2] = {(float)width, (float)height}; mEffect->SetFloatArray("video_size", size, 2); }
    return result ? result : input;
}
