// Audio Output
#include "burner.h"

INT32 nAudSampleRate[8] = { 44100, 44100, 22050, 22050, 22050, 22050, 22050, 22050 };			// sample rate
INT32 nAudVolume = 10000;				// Sound volume (% * 100)
#if defined (BUILD_WIN32)
INT32 nAudSegCount = 4; // User-approved XA4 default for Infinite 1.05.
#else
INT32 nAudSegCount = 6;
#endif
INT32 nAudSegLen = 0;					// Seg length in samples (calculated from Rate/Fps)
INT32 nAudAllocSegLen = 0;
UINT8 bAudOkay = 0;			// True if DSound was initted okay
UINT8 bAudPlaying = 0;		// True if the Loop buffer is playing

INT32 nAudDSPModule[8] = { 0, };				// DSP module to use: 0 = none, 1 = low-pass filter

INT16* nAudNextSound = NULL;		// The next sound seg we will add to the sample loop

#if defined (BUILD_WIN32)
UINT32 nAudSelect = 1; // XAudio2; saved DirectSound selections remain supported.
#else
UINT32 nAudSelect = 0;
#endif
static UINT32 nAudActive = 0;

// Infinite: Fightcade-style output (fightcade-fbneo aud_dsound3.cpp/aud_xaudio2.cpp SoundFrame). The run loop
// paces frames by time and pushes each drawn frame's segment; SoundCheck only keeps the output from running dry.
INT32 bAudPushMode = 0;
INT32 bAudPushActive = 0;

#if defined (BUILD_WIN32)
	extern struct AudOut AudOutDx;
	extern struct AudOut AudOutXAudio2;
#elif defined (BUILD_MACOS)
    extern struct AudOut AudOutMacOS;
#elif defined (BUILD_SDL) 
	extern struct AudOut AudOutSDL;
#elif defined (BUILD_SDL2)
	#if defined (FORCE_PULSE_AUDIO)
		extern struct AudOut AudOutPulseSimple;
	#else
		extern struct AudOut AudOutSDL;
	#endif
#elif defined (_XBOX)
	extern struct AudOut AudOutXAudio2;
#elif defined (BUILD_QT)
#ifdef BUILD_QT_LINUX
    extern struct AudOut AudOutPulseSimple;
#endif
    extern struct AudOut AudOutQtSound;
#endif

static struct AudOut *pAudOut[]=
{
#if defined (BUILD_WIN32)
	&AudOutDx,
	&AudOutXAudio2,
#elif defined (BUILD_MACOS)
    &AudOutMacOS,
#elif defined (BUILD_SDL) 
	&AudOutSDL,
#elif defined (BUILD_SDL2)
	#if defined (FORCE_PULSE_AUDIO)
		&AudOutPulseSimple,
	#else
		&AudOutSDL,
	#endif
#elif defined (_XBOX)
	&AudOutXAudio2,
#elif defined (BUILD_QT)
#ifdef BUILD_QT_LINUX
    &AudOutPulseSimple,
#endif
    &AudOutQtSound,
#endif
};

#define AUD_LEN (sizeof(pAudOut)/sizeof(pAudOut[0]))

static InterfaceInfo AudInfo = { NULL, NULL, NULL };

INT32 AudBlankSound()
{
	if (!bAudOkay || nAudActive >= AUD_LEN) {
		return 1;
	}
	return pAudOut[nAudActive]->BlankSound();
}

// This function checks the Sound loop, and if necessary gets some more sound
INT32 AudSoundCheck()
{
	if (!bAudOkay || nAudActive >= AUD_LEN) {
		return 1;
	}
	return pAudOut[nAudActive]->SoundCheck();
}

INT32 AudSoundInit()
{
	INT32 nRet;

	if (nAudSelect >= AUD_LEN) {
		return 1;
	}

	nAudActive = nAudSelect;
	bAudPushActive = bAudPushMode;

	if ((nRet = pAudOut[nAudActive]->SoundInit()) == 0) {
		bAudOkay = true;
	}

	return nRet;
}

INT32 AudSetCallback(INT32 (*pCallback)(INT32))
{
	if (!bAudOkay || nAudActive >= AUD_LEN) {
		return 1;
	}
	return pAudOut[nAudActive]->SetCallback(pCallback);
}

INT32 AudSoundPlay()
{
	if (!bAudOkay || nAudActive >= AUD_LEN) {
		return 1;
	}

	INT32 nRet = pAudOut[nAudActive]->SoundPlay();
	if (!nRet) {
		bAudPlaying = true;
	}

	return nRet;
}

INT32 AudSoundStop()
{
	if (nAudActive >= AUD_LEN) {
		return 1;
	}

	bAudPlaying = false;

	return pAudOut[nAudActive]->SoundStop();
}

INT32 AudSoundExit()
{
	IntInfoFree(&AudInfo);

	if (!bAudOkay || nAudActive >= AUD_LEN) {
		return 1;
	}
	bAudOkay = false;

	INT32 nRet = pAudOut[nAudActive]->SoundExit();

	nAudActive = 0;
	bAudPushActive = 0;

	return nRet;
}

INT32 AudSoundSetVolume()
{
	if (!bAudOkay || nAudActive >= AUD_LEN) {
		return 1;
	}
	return pAudOut[nAudActive]->SoundSetVolume();
}

InterfaceInfo* AudGetInfo()
{
	if (IntInfoInit(&AudInfo)) {
		IntInfoFree(&AudInfo);
		return NULL;
	}

	if (bAudOkay) {
		TCHAR szString[MAX_PATH] = _T("");

		AudInfo.pszModuleName = pAudOut[nAudActive]->szModuleName;

		_sntprintf(szString, MAX_PATH, _T("Playback at %iHz, %i%% volume"), nAudSampleRate[nAudActive], nAudVolume / 100);
		IntInfoAddStringInterface(&AudInfo, szString);

		if (nAudDSPModule[nAudActive]) {
			IntInfoAddStringInterface(&AudInfo, _T("Applying low-pass filter"));
		}

	 	if (pAudOut[nAudSelect]->GetPluginSettings) {
			pAudOut[nAudSelect]->GetPluginSettings(&AudInfo);
		}
	} else {
		IntInfoAddStringInterface(&AudInfo, _T("Audio plugin not initialised"));
	}

	return &AudInfo;
}

INT32 AudSelect(UINT32 nPlugIn)
{
	if (nPlugIn < AUD_LEN) {
		nAudSelect = nPlugIn;
		return 0;
	}

	return 1;
}

#if defined (BUILD_WIN32)
extern INT32 DxSoundPushFrame();
extern INT32 XAudio2PushFrame();
#endif

INT32 AudSoundFrame()
{
	if (!bAudOkay || !bAudPushActive || nAudActive >= AUD_LEN) {
		return 1;
	}
#if defined (BUILD_WIN32)
	if (pAudOut[nAudActive] == &AudOutDx) return DxSoundPushFrame();
	if (pAudOut[nAudActive] == &AudOutXAudio2) return XAudio2PushFrame();
#endif
	return 1;
}

void AudWriteSilence()
{
	if (nAudNextSound) {
		memset(nAudNextSound, 0, nAudAllocSegLen);
	}
}
