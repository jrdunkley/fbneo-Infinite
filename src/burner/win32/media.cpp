// Media module
#include "burner.h"
#include "infinite_video_trace.h"

int MediaInit()
{
	// Final boundary for config, auto-switch and future command paths, before
	// either window creation or video initialization can request a mode.
	if (bInfiniteHiddenLaunch && nVidFullscreen) InfiniteRefuseHiddenFullscreen("media-init");
	if (ScrnInit()) {					// Init the Scrn Window
		FBAPopupAddText(PUF_TEXT_DEFAULT, MAKEINTRESOURCE(IDS_ERR_UI_WINDOW));
		FBAPopupDisplay(PUF_TYPE_ERROR);
		return 1;
	}

	if (!bInputOkay) {
		InputInit();					// Init Input
	}

	nAppVirtualFps = nBurnFPS;

	if (!bAudOkay) {
		bAudPushMode = InfiniteRunLoopWanted();	// Infinite: the time-paced loop pushes each frame's sound
		INT32 nAudRet = AudSoundInit();	// Init Sound (not critical if it fails)
		InfiniteLog("media: audio module %d init -> %d (push %d)", nAudSelect, nAudRet, bAudPushMode);
	}

	nBurnSoundRate = 0;					// Assume no sound
	pBurnSoundOut = NULL;
	if (bAudOkay) {
		nBurnSoundRate = nAudSampleRate[nAudSelect];
		nBurnSoundLen = nAudSegLen;
	}

	if (nBurnSoundRate == 0) {
		// Sound disabled, but fake these numbers for sound cores which must
		// stay synched (f.ex. burn_md2612)
		nBurnSoundRate = 44100;
		nBurnSoundLen = (nBurnSoundRate * 100 + (nBurnFPS >> 1)) / nBurnFPS;
		// Deferred GGPO playback can initialize media before begin_game. There
		// is no active driver to query at that point (including the empty UI).
		if (bDrvOkay && (BurnDrvGetHardwareCode() & HARDWARE_PUBLIC_MASK) == HARDWARE_CAPCOM_CPS3)
			nBurnSoundLen = (INT32)(nBurnSoundRate / BurnGetRefreshRate() + 0.5);
	}

	if (!bVidOkay) {

		// Reinit the video plugin
		VidInit();
		if (!bVidOkay && nVidFullscreen) {

			nVidFullscreen = 0;

			MediaExit();
			return (MediaInit());
		}
		if (!nVidFullscreen) {
			ScrnSize();
		}

		if (!bVidOkay && bDrvOkay) {
			// Make sure the error will be visible
			SplashDestroy(1);

			FBAPopupAddText(PUF_TEXT_DEFAULT, MAKEINTRESOURCE(IDS_ERR_UI_VID_MODULE), VidGetModuleName());
			FBAPopupDisplay(PUF_TYPE_ERROR);
		}

		if (bVidOkay && ((bRunPause && bAltPause) || !bDrvOkay)) {
			VidRedraw();
		}
	}

	return 0;
}

int MediaExit()
{
	nBurnSoundRate = 0;					// Blank sound
	pBurnSoundOut = NULL;

	AudSoundExit();						// Exit Dsound

	VidExit();

	InputExit();

	DestroyWindow(hInpsDlg);			// Make sure the Input Set dialog is exitted
	DestroyWindow(hInpdDlg);			// Make sure the Input Dialog is exitted

	ScrnExit();							// Exit the Scrn Window

	return 0;
}
