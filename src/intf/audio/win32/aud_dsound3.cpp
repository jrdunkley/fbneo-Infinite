// DirectSound module
#include "burner.h"
#include "aud_dsp.h"
#include <math.h>

#include <initguid.h>
#define DIRECTSOUND_VERSION  0x0300			// Only need version from DirectX 3
#include <dsound.h>

#include "dsound_core.h"

// Sound is split into a series of 'segs', one seg for each frame
// The Loop buffer is a multiple of this seg length.

static IDirectSound* pDS = NULL;			// DirectSound interface
static IDirectSoundBuffer* pdsbPrim = NULL;	// Primary buffer
static IDirectSoundBuffer* pdsbLoop = NULL;	// (Secondary) Loop buffer
static int cbLoopLen = 0;					// Loop length (in bytes) calculated

int (*DSoundGetNextSound)(int);				// Callback used to request more sound
static int DxSoundSetVolume(); // forward

// CPS3's fixed-size frame segments must be consumed at their actual cadence.
// The chip is clocked independently. Only presentation is adjusted here; the
// requested format still determines segment allocation. DirectSound accepts an
// integer rate, leaving at most half a sample/second of host quantisation.
static int DxPlaybackRate(int requested, int segment, double fps, bool cps3Push)
{
	return cps3Push ? (int)(segment * fps + 0.5) : requested;
}

static HANDLE hDSoundEvent = NULL;
static HANDLE hAbortEvent = NULL;
static HANDLE hAbortAckEvent = NULL;

static int nDSoundFps;						// Application fps * 100
static long nDSoundVol = 0;

// Infinite push mode (fightcade-fbneo c95950140e aud_dsound3.cpp): a 10-segment loop, one segment written per
// emulated frame by DxSoundPushFrame(); DxSoundCheck() repeats the last frame's sound only when the play cursor
// gets within 4 segments of the write position.
static const int nDxPushCount = 10;
static int nDxPushRead = 0;
static int nDxPushWrite = 0;
static int nDxPushFrames = 0, nDxPushDropped = 0, nDxPushRefills = 0;	// session counters, logged at exit

static int DxPushBufferDiff(int write, int read, int len)
{
	// Queued segments run forward from the play cursor to the next write.
	// Shortest circular distance folds a nearly full queue into a nearly empty
	// one and makes the default six-segment overflow threshold unreachable.
	return (write - read + len) % len;
}

static int DSoundGetNextSoundFiller(int)							// int bDraw
{
	if (nAudNextSound == NULL) {
		return 1;
	}
	memset(nAudNextSound, 0, nAudSegLen << 2);						// Write silence into the buffer

	return 0;
}

static inline int DxSetCallback(int (*pCallback)(int))
{
	if (pCallback == NULL) {
		DSoundGetNextSound = DSoundGetNextSoundFiller;
	} else {
		DSoundGetNextSound = pCallback;
	}

	return 0;
}

static int DxBlankSound()
{
	void *pData = NULL, *pData2 = NULL;
	DWORD cbLen = 0, cbLen2 = 0;

	// blank the nAudNextSound buffer
	if (nAudNextSound) {
		memset(nAudNextSound, 0, nAudSegLen << 2);
	}

	// Lock the Loop buffer
	if (FAILED(pdsbLoop->Lock(0, cbLoopLen, &pData, &cbLen, &pData2, &cbLen2, 0))) {
		return 1;
	}
	memset(pData, 0, cbLen);

	// Unlock (2nd 0 is because we wrote nothing to second part)
	pdsbLoop->Unlock(pData, cbLen, pData2, 0);

	if (bAudPushActive) {
		pdsbLoop->SetCurrentPosition(0);
		nDxPushRead = 0;
		nDxPushWrite = 0;
	}

	return 0;
}

static int nDSoundNextSeg = 0;										// We have filled the sound in the loop up to the beginning of 'nNextSeg'

#define WRAP_INC(x) { x++; if (x >= nAudSegCount) x = 0; }

bool bAbortSound = false;

static void DxPushWriteSegment()
{
	void *pData1 = NULL, *pData2 = NULL;
	DWORD nLen1 = 0, nLen2 = 0;
	if (SUCCEEDED(pdsbLoop->Lock(nDxPushWrite * (nAudSegLen << 2), nAudSegLen << 2, &pData1, &nLen1, &pData2, &nLen2, 0))) {
		memcpy(pData1, nAudNextSound, nLen1);
		pdsbLoop->Unlock(pData1, nLen1, pData2, nLen2);
		nDxPushWrite = (nDxPushWrite + 1) % nDxPushCount;
	}
}

static int DxPushSoundCheck()
{
	DWORD nPlay = 0, nWrite = 0;
	pdsbLoop->GetCurrentPosition(&nPlay, &nWrite);
	nDxPushRead = nPlay / (nAudSegLen << 2);

	int nDiff = DxPushBufferDiff(nDxPushWrite, nDxPushRead, nDxPushCount);
	if (nDiff < 4) {
		// Close to dry buffers: fill the next segment with the last frame's sound
		DxPushWriteSegment();
		nDxPushRefills++;
	}

	return 0;
}

INT32 DxSoundPushFrame()
{
	if (!bAudPushActive || pdsbLoop == NULL || nAudNextSound == NULL) {
		return 1;
	}

	DWORD nPlay = 0, nWrite = 0;
	pdsbLoop->GetCurrentPosition(&nPlay, &nWrite);
	nDxPushRead = nPlay / (nAudSegLen << 2);

	int nDiff = DxPushBufferDiff(nDxPushWrite, nDxPushRead, nDxPushCount);
	// Leave one segment free so equal cursors always mean an empty queue.
	int nQueueLimit = nAudSegCount < nDxPushCount ? nAudSegCount : nDxPushCount - 1;
	if (nDiff >= nQueueLimit) {
		// Writing too fast
		nDxPushDropped++;
		return 0;
	}

	// apply DSP to recent frame
	if (nAudDSPModule[0])	{
		DspDo(nAudNextSound, nAudSegLen);
	}

	DxPushWriteSegment();
	nDxPushFrames++;

	return 0;
}

// This function checks the DSound loop, and if necessary does a callback to update the emulation
static int DxSoundCheck()
{
	int nPlaySeg = 0, nFollowingSeg = 0;
	DWORD nPlay = 0, nWrite = 0;

	if (bAudPushActive) {
		if (!bAudPlaying || pdsbLoop == NULL) return 1;
		return DxPushSoundCheck();
	}

	if (bAbortSound)
	{
		bAbortSound = false;
		DWORD wait_object = SignalObjectAndWait(hAbortEvent, hAbortAckEvent, false, 2500);
		if (wait_object != WAIT_OBJECT_0)
		{

#ifdef PRINT_DEBUG_INFO
			//if (wait_object == WAIT_TIMEOUT)
			//	bprintf(0, _T("*** DirectSound playback stalled.\n"));
#endif

			ResetEvent(hAbortAckEvent);
		}

		return 0;
	}

	HANDLE handles[] = { hDSoundEvent, hAbortEvent };


	DWORD wait_object = WaitForMultipleObjects(2, handles, false, 2500);
	if (wait_object != WAIT_OBJECT_0)
	{

#ifdef PRINT_DEBUG_INFO
		if (wait_object == WAIT_TIMEOUT)
			bprintf(0, _T("*** DirectSound playback notification timeout.\n"));
		if (wait_object == WAIT_FAILED)
			bprintf(0, _T("*** DirectSound playback wait failed.\n"));
		// if (wait_object == WAIT_OBJECT_0 + 1)
		//	bprintf(0, _T("*** DirectSound playback wait aborted.\n"));
#endif

		if (wait_object == WAIT_OBJECT_0 + 1)
		{
			SetEvent(hAbortAckEvent);
			ResetEvent(hAbortEvent);
		}

		return 1;
	}

	ResetEvent(hDSoundEvent);

	if (!bAudPlaying)
		return 1;

	if (pdsbLoop == NULL) {
		return 1;
	}

	// We should do nothing until nPlay has left nDSoundNextSeg
	pdsbLoop->GetCurrentPosition(&nPlay, &nWrite);

	nPlaySeg = nPlay / (nAudSegLen << 2);

	if (nPlaySeg > nAudSegCount - 1) {
		nPlaySeg = nAudSegCount - 1;
	}
	if (nPlaySeg < 0) {												// important to ensure nPlaySeg clipped for below
		nPlaySeg = 0;
	}

	if (nDSoundNextSeg == nPlaySeg) {
		//Sleep(2);													// Don't need to do anything for a bit
		return 0;
	}

	// work out which seg we will fill next
	nFollowingSeg = nDSoundNextSeg;
	WRAP_INC(nFollowingSeg);

	while (nDSoundNextSeg != nPlaySeg) {
		void *pData = NULL, *pData2 = NULL;
		DWORD cbLen = 0, cbLen2 = 0;

		// fill nNextSeg

		// Lock the relevant seg of the loop buffer
		if (SUCCEEDED(pdsbLoop->Lock(nDSoundNextSeg * (nAudSegLen << 2), nAudSegLen << 2, &pData, &cbLen, &pData2, &cbLen2, 0))) {
			// Locked the segment, so write the sound we calculated last time
			memcpy(pData, nAudNextSound, nAudSegLen << 2);

			// Unlock (2nd 0 is because we wrote nothing to second part)
			pdsbLoop->Unlock(pData, cbLen, pData2, 0);
		}

		// get more sound into nAudNextSound
		DSoundGetNextSound((nFollowingSeg == nPlaySeg) || bAlwaysDrawFrames); // If this is the last seg of sound, draw the graphics (frameskipping)

		if (nAudDSPModule[0])	{
			DspDo(nAudNextSound, nAudSegLen);
		}

		nDSoundNextSeg = nFollowingSeg;
		WRAP_INC(nFollowingSeg);
	}

	return 0;
}

static int DxSoundExit()
{
	if (bAudPushActive) {
		InfiniteLog("audio push (DirectSound): frames %d, dropped %d, refills %d, segments %d", nDxPushFrames, nDxPushDropped, nDxPushRefills, nAudSegCount);
		nDxPushFrames = nDxPushDropped = nDxPushRefills = 0;
	}

	ResetEvent(hAbortEvent);
	ResetEvent(hAbortAckEvent);

	DspExit();

	if (nAudNextSound) {
		free(nAudNextSound);
		nAudNextSound = NULL;
	}

	DSoundGetNextSound = NULL;

	// Release the (Secondary) Loop Sound Buffer
	RELEASE(pdsbLoop);
	// Release the Primary Sound Buffer
	RELEASE(pdsbPrim);
	// Release the DirectSound interface
	RELEASE(pDS);

	if (hAbortAckEvent)
		CloseHandle(hAbortAckEvent);
	hAbortAckEvent = NULL;

	if (hAbortEvent)
		CloseHandle(hAbortEvent);
	hAbortEvent = NULL;

	if (hDSoundEvent)
		CloseHandle(hDSoundEvent);
	hDSoundEvent = NULL;

	return 0;
}

static int DxSoundInit()
{
	int nRet = 0;
	DSBUFFERDESC dsbd;
	WAVEFORMATEX wfx;
	LPDIRECTSOUNDNOTIFY lpDsNotify;
	LPDSBPOSITIONNOTIFY lpPositionNotify = 0;

	if (nAudSampleRate[0] <= 0) {
		return 1;
	}

	hDSoundEvent = CreateEvent(NULL, TRUE, false, NULL);
	if (hDSoundEvent == NULL)
		return 1;

	hAbortEvent = CreateEvent(NULL, TRUE, false, NULL);
	if (hAbortEvent == NULL)
		return 1;

	hAbortAckEvent = CreateEvent(NULL, TRUE, false, NULL);
	if (hAbortAckEvent == NULL)
		return 1;

	nDSoundFps = nAppVirtualFps;

	// Calculate the Seg Length and Loop length (round to nearest sample)
	nAudSegLen = (nAudSampleRate[0] * 100 + (nDSoundFps >> 1)) / nDSoundFps;
	if (bAudPushActive && bDrvOkay && (BurnDrvGetHardwareCode() & HARDWARE_PUBLIC_MASK) == HARDWARE_CAPCOM_CPS3)
		nAudSegLen = (INT32)(nAudSampleRate[0] / BurnGetRefreshRate() + 0.5);
	nAudAllocSegLen = nAudSegLen << 2;
	int nLoopSegs = bAudPushActive ? nDxPushCount : nAudSegCount;
	cbLoopLen = (nAudSegLen * nLoopSegs) << 2;
	const int playbackRate = DxPlaybackRate(nAudSampleRate[0], nAudSegLen, BurnGetRefreshRate(),
		bAudPushActive && bDrvOkay && (BurnDrvGetHardwareCode() & HARDWARE_PUBLIC_MASK) == HARDWARE_CAPCOM_CPS3);
	if (playbackRate != nAudSampleRate[0])
		InfiniteLog("CPS3 audio presentation: requested %d Hz, device %d Hz, segment %d", nAudSampleRate[0], playbackRate, nAudSegLen);

	// Make the format of the sound
	memset(&wfx, 0, sizeof(wfx));
	wfx.cbSize = sizeof(wfx);
	wfx.wFormatTag = WAVE_FORMAT_PCM;
	wfx.nChannels = 2;										  // stereo
	wfx.nSamplesPerSec = playbackRate;					  // presentation sample rate
	wfx.wBitsPerSample = 16;								  // 16-bit
	wfx.nBlockAlign = 4;									  // bytes per sample
	wfx.nAvgBytesPerSec = wfx.nSamplesPerSec * wfx.nBlockAlign;

	// Create the DirectSound interface
	if (FAILED(_DirectSoundCreate(NULL, &pDS, NULL))) {
		return 1;
	}

	// Set the coop level
	nRet = pDS->SetCooperativeLevel(hScrnWnd, DSSCL_PRIORITY);

	// Make the primary sound buffer
	memset(&dsbd, 0, sizeof(dsbd));
	dsbd.dwSize = sizeof(dsbd);
	dsbd.dwFlags = DSBCAPS_PRIMARYBUFFER;
	if (FAILED(pDS->CreateSoundBuffer(&dsbd, &pdsbPrim, NULL))) {
		DxSoundExit();
		return 1;
	}

	{
		// Set the format of the primary sound buffer (not critical if it fails)
		if (nAudSampleRate[0] < 44100) {
			wfx.nSamplesPerSec = 44100;
		}
		pdsbPrim->SetFormat(&wfx);

		wfx.nSamplesPerSec = playbackRate;
	}

	// Make the loop sound buffer
	memset(&dsbd, 0, sizeof(dsbd));
	dsbd.dwSize = sizeof(dsbd);
	// A standard secondary buffer (accurate position, plays in the background, and can notify).
	dsbd.dwFlags = DSBCAPS_GETCURRENTPOSITION2 | DSBCAPS_GLOBALFOCUS | DSBCAPS_CTRLPOSITIONNOTIFY | DSBCAPS_CTRLVOLUME;
	dsbd.dwBufferBytes = cbLoopLen;
	dsbd.lpwfxFormat = &wfx;								// Same format as the primary buffer
	if (FAILED(pDS->CreateSoundBuffer(&dsbd, &pdsbLoop, NULL))) {
		AudSoundExit();
		return 1;
	}

	lpPositionNotify = (LPDSBPOSITIONNOTIFY)malloc(nLoopSegs * sizeof(DSBPOSITIONNOTIFY));
	if (lpPositionNotify == NULL)
		goto error;

	if (FAILED(pdsbLoop->QueryInterface(IID_IDirectSoundNotify, (void**)&lpDsNotify)))
		goto error;

	for (int i = 0; i < nLoopSegs; i++)
	{
		lpPositionNotify[i].dwOffset = (i * nAudSegLen) << 2;
		lpPositionNotify[i].hEventNotify = hDSoundEvent;
	}

	if (FAILED(lpDsNotify->SetNotificationPositions(nLoopSegs, lpPositionNotify)))
	{
		lpDsNotify->Release();

		goto error;
	}

	lpDsNotify->Release();
	free(lpPositionNotify);

	// Note: +2 is a hacky work-around for crashy Midway games (mk2, etc) via Kaillera
	nAudNextSound = (short*)malloc(nAudSegLen << (2 + 2));		// The next sound block to put in the stream
	if (nAudNextSound == NULL) {
		DxSoundExit();
		return 1;
	}

	DxSetCallback(NULL);

	DspInit();

	return 0;

error:
	free(lpPositionNotify);
	DxSoundExit();

	return 1;
}

static int DxSoundPlay()
{
	DxBlankSound();
	DxSoundSetVolume();

	// Play the looping buffer
	if (FAILED(pdsbLoop->Play(0, 0, DSBPLAY_LOOPING))) {
		return 1;
	}
	bAudPlaying = 1;

	return 0;
}

static int DxSoundStop()
{
	bAudPlaying = 0;

	if (bAudOkay == 0) {
		return 1;
	}

	// Stop the looping buffer
	pdsbLoop->Stop();

	if (!bAudPushActive) {
		bAbortSound = true;
		DxSoundCheck();
	}

	return 0;
}

static int DxSoundSetVolume()
{
	if (nAudVolume == 10000) {
		nDSoundVol = DSBVOLUME_MAX;
	} else {
		if (nAudVolume == 0) {
			nDSoundVol = DSBVOLUME_MIN;
		} else {
			nDSoundVol = DSBVOLUME_MAX - (long)(10000.0 * pow(10.0, nAudVolume / -5000.0)) + 100;
		}
	}

	if (nDSoundVol < DSBVOLUME_MIN) {
		nDSoundVol = DSBVOLUME_MIN;
	}

	if (FAILED(pdsbLoop->SetVolume(nDSoundVol))) {
		return 0;
	}

	return 1;
}

static int DxGetSettings(InterfaceInfo* pInfo)
{
	TCHAR szString[MAX_PATH] = _T("");

	_sntprintf(szString, MAX_PATH, _T("Audio is delayed by approx. %ims"), int(100000.0 / (nDSoundFps / (nAudSegCount - 1.0))));
	IntInfoAddStringModule(pInfo, szString);

	return 0;
}

struct AudOut AudOutDx = { DxBlankSound, DxSoundCheck, DxSoundInit, DxSetCallback, DxSoundPlay, DxSoundStop, DxSoundExit, DxSoundSetVolume, DxGetSettings, _T("DirectSound3 audio output") };
