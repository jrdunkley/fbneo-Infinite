// Infinite: GGPO session glue, ported from fightcade-fbneo c95950140e (src/burner/win32/fbn_ggpo.cpp and
// fbn_network.cpp). Path A: Fightcade's closed ggponet.dll, wrapped by Infinite's replay bridge, is loaded at
// run time, so executables without it (x64, research runtimes) still start; only quark: sessions need it.
// Kept from Fightcade: the session callbacks, the 24-byte 'GGPO' state header, the packed input block and
// the frame loop. Board-timing CPS3 snapshots also include the 8 MiB writable character RAM so a predicted
// character DMA cannot leak into a restored frame. Other drivers retain ACB_NET_OPT
// (run.cpp). Not ported: the overlay, the pixel score detector (header scores are 0) and the perfmon
// window (T-0108); quark:served/training/stream/replay (the Infinite client launches quark:direct only).
#include "burner.h"
#include "ggponet.h"
#include "ggpoclient.h"
#include "sh2_intf.h"
#include "zlib.h"

#define INFINITE_NET_VERSION 0x20261014 // FBneo Infinite state/input profile; matching builds only.
extern UINT32 cps3SndStateVersion();
extern UINT32 cps3SndStateSize();
extern bool cps3SndStateCompatible(const void *, UINT32);

INT32 bInfiniteQuark = 0;				// a GGPO session is running
static GGPOSession *ggpo = NULL;
static HMODULE hGgpoLib = NULL;
static struct {
	decltype(&ggpo_start_session) start_session;
	decltype(&ggpo_start_synctest) start_synctest;
	decltype(&ggpo_close_session) close_session;
	decltype(&ggpo_idle) idle;
	decltype(&ggpo_synchronize_input) synchronize_input;
	decltype(&ggpo_advance_frame) advance_frame;
	decltype(&ggpo_get_stats) get_stats;
	decltype(&ggpo_client_chat) client_chat;
	void (__cdecl *set_frame_delay)(GGPOSession *, int);
} Ggpo;

static char pGameName[MAX_PATH];
static int iPlayer = 0;
static int iDelay = 0;
static bool bSkipPerfmonUpdates = false;
static int nRollbackFrames = 0;
static int nRollbackCount = 0;
static bool bQuarkStateSaved = false;


static const int ggpo_state_header_size = 6 * sizeof(int);

#define QuarkLog InfiniteLog

// ggponet.dll uses Winsock without starting it; fightcade-fbneo's WinMain calls WSAStartup(2.2) for it.
static bool QuarkStartWinsock()
{
	static int nStarted = 0;
	if (nStarted) return nStarted > 0;
	nStarted = -1;
	HMODULE hWs2 = LoadLibrary(_T("ws2_32.dll"));
	if (hWs2 == NULL) return false;
	typedef int (WINAPI *WSAStartupProc)(WORD, void *);
	WSAStartupProc pWSAStartup = (WSAStartupProc)GetProcAddress(hWs2, "WSAStartup");
	unsigned char wsaData[1024];		// larger than WSADATA on x86 and x64
	if (pWSAStartup == NULL || pWSAStartup(MAKEWORD(2, 2), wsaData) != 0) return false;
	nStarted = 1;
	return true;
}

static bool QuarkLoadLibrary()
{
	if (hGgpoLib) return true;
	if (!QuarkStartWinsock()) return false;
	hGgpoLib = LoadLibrary(_T("ggponet.dll"));
	if (hGgpoLib == NULL) return false;
#define GGPO_PROC(field, name) *(FARPROC *)&Ggpo.field = GetProcAddress(hGgpoLib, name)
	GGPO_PROC(start_session, "ggpo_start_session");
	GGPO_PROC(start_synctest, "ggpo_start_synctest");
	GGPO_PROC(close_session, "ggpo_close_session");
	GGPO_PROC(idle, "ggpo_idle");
	GGPO_PROC(synchronize_input, "ggpo_synchronize_input");
	GGPO_PROC(advance_frame, "ggpo_advance_frame");
	GGPO_PROC(get_stats, "ggpo_get_stats");
	GGPO_PROC(client_chat, "ggpo_client_chat");
	GGPO_PROC(set_frame_delay, "ggpo_set_frame_delay");
#undef GGPO_PROC
	if (!Ggpo.start_session || !Ggpo.start_synctest || !Ggpo.close_session || !Ggpo.idle || !Ggpo.synchronize_input ||
		!Ggpo.advance_frame || !Ggpo.get_stats || !Ggpo.client_chat || !Ggpo.set_frame_delay) {
		FreeLibrary(hGgpoLib);
		hGgpoLib = NULL;
		return false;
	}
	return true;
}

// ---------------------------------------------------------------------------------------------------------------
// Input block (fbn_network.cpp). Inputs are assumed to be ordered P1, P2, P3, P4, common controls, DIP switches.

static const int MAXPLAYER = 4;
static int nPlayerInputs[MAXPLAYER], nCommonInputs, nDIPInputs;
static int nPlayerOffset[MAXPLAYER], nCommonOffset, nDIPOffset;
static const int INPUTSIZE = 8 * (4 + 8);
static unsigned char nControls[INPUTSIZE];

int NetworkInitInput()
{
	if (nGameInpCount == 0) {
		return 1;
	}

	struct BurnInputInfo bii;
	memset(&bii, 0, sizeof(bii));

	unsigned int i = 0;

	nPlayerOffset[0] = 0;
	do {
		BurnDrvGetInputInfo(&bii, i);
		i++;
	} while (!_strnicmp(bii.szName, "P1", 2) && i <= nGameInpCount);
	i--;
	nPlayerInputs[0] = i - nPlayerOffset[0];

	for (int j = 1; j < MAXPLAYER; j++) {
		char szString[3] = "P?";
		szString[1] = j + '1';
		nPlayerOffset[j] = i;
		while (!_strnicmp(bii.szName, szString, 2) && i < nGameInpCount) {
			i++;
			BurnDrvGetInputInfo(&bii, i);
		}
		nPlayerInputs[j] = i - nPlayerOffset[j];
	}

	nCommonOffset = i;
	while ((bii.nType & BIT_GROUP_CONSTANT) == 0 && i < nGameInpCount) {
		i++;
		BurnDrvGetInputInfo(&bii, i);
	};
	nCommonInputs = i - nCommonOffset;

	nDIPOffset = i;
	nDIPInputs = nGameInpCount - nDIPOffset;

	QuarkLog("quark inputs: p1 %d+%d p2 %d+%d common %d+%d dip %d+%d", nPlayerOffset[0], nPlayerInputs[0],
		nPlayerOffset[1], nPlayerInputs[1], nCommonOffset, nCommonInputs, nDIPOffset, nDIPInputs);

	return 0;
}

static bool QuarkGetInput(void *values, int size, int players)
{
    if (!ggpo) return false;
    // The first successful synchronization belongs to GGPO frame -1, not an
    // arcade frame. Its local input seeds the delay queue. A complete neutral
    // synthetic record matches the remote queue before either real sample.
    // Actual arcade samples, including DIP/constants, keep their normal path.
    if (!bQuarkStateSaved && size >= 2 &&
        (BurnDrvGetHardwareCode() & 0x7f000000) == HARDWARE_PREFIX_CPS3) {
        memset(values, 0, size);
    }
    if (!Ggpo.synchronize_input(ggpo, values, size, players)) return false;
    if (!bQuarkStateSaved) {
        Ggpo.advance_frame(ggpo);
        QuarkLog("quark: established neutral frame zero before emulation");
        return false;
    }
    return true;
}

int NetworkGetInput()
{
	int i, j, k;

	struct BurnInputInfo bii;
	memset(&bii, 0, sizeof(bii));

	// Initialize controls to 0
	memset(nControls, 0, INPUTSIZE);

	// Pack all DIP switches + common controls + player 1 controls
	for (i = 0, j = 0; i < nPlayerInputs[0]; i++, j++) {
		BurnDrvGetInputInfo(&bii, i + nPlayerOffset[0]);
		if (*bii.pVal && bii.nType == BIT_DIGITAL) {
			nControls[j >> 3] |= (1 << (j & 7));
		}
	}
	for (i = 0; i < nCommonInputs; i++, j++) {
		BurnDrvGetInputInfo(&bii, i + nCommonOffset);
		// Fightcade's VidOverlayCanReset() is false outside its served/ranked lobby flows.
		bool can_tilt = !kNetGame || strcmp(bii.szName, "Tilt");
		bool can_reset = !kNetGame || (strcmp(bii.szName, "Reset") && strcmp(bii.szName, "Diagnostic") && strcmp(bii.szName, "Service") && strcmp(bii.szName, "Test"));
		if (*bii.pVal && can_tilt && can_reset) {
			nControls[j >> 3] |= (1 << (j & 7));
		}
	}

	// Convert j to byte count
	j = (j + 7) >> 3;

	// Analog controls/constants
	for (i = 0; i < nPlayerInputs[0]; i++) {
		BurnDrvGetInputInfo(&bii, i + nPlayerOffset[0]);
		if (*bii.pVal && bii.nType != BIT_DIGITAL) {
			if (bii.nType & BIT_GROUP_ANALOG) {
				nControls[j++] = *bii.pShortVal >> 8;
				nControls[j++] = *bii.pShortVal & 0xFF;
			} else {
				nControls[j++] = *bii.pVal;
			}
		}
	}

	// DIP switches
	for (i = 0; i < nDIPInputs; i++, j++) {
		BurnDrvGetInputInfo(&bii, i + nDIPOffset);
		nControls[j] = *bii.pVal;
	}

	// k has the size of all inputs for one player
	k = j + 1;

	// Send the control block to the Network DLL & retrieve all controls
	if (kNetGame) {
		if (!QuarkGetInput(nControls, k, MAXPLAYER)) {
			return 1;
		}
	}

	// Decode Player 1 input block
	for (i = 0, j = 0; i < nPlayerInputs[0]; i++, j++) {
		BurnDrvGetInputInfo(&bii, i + nPlayerOffset[0]);
		if (bii.nType == BIT_DIGITAL) {
			if (nControls[j >> 3] & (1 << (j & 7))) {
				*bii.pVal = 0x01;
			} else {
				*bii.pVal = 0x00;
			}
		}
	}
	for (i = 0; i < nCommonInputs; i++, j++) {
		BurnDrvGetInputInfo(&bii, i + nCommonOffset);
		if (nControls[j >> 3] & (1 << (j & 7))) {
			*bii.pVal = 0x01;
		} else {
			*bii.pVal = 0x00;
		}
	}

	// Convert j to byte count
	j = (j + 7) >> 3;

	// Analog inputs (fightcade-fbneo indexes these from nDIPOffset; kept as is, CPS3 has none)
	for (i = 0; i < nPlayerInputs[0]; i++) {
		BurnDrvGetInputInfo(&bii, i + nDIPOffset);
		if (bii.nType & BIT_GROUP_ANALOG) {
			*bii.pShortVal = (nControls[j] << 8) | nControls[j + 1];
			j += 2;
		}
	}

	// DIP switches
	for (i = 0; i < nDIPInputs; i++, j++) {
		BurnDrvGetInputInfo(&bii, i + nDIPOffset);
		*bii.pVal = nControls[j];
	}

	// Decode other player's input blocks
	for (int l = 1; l < MAXPLAYER; l++) {
		if (nPlayerInputs[l]) {
			for (i = 0, j = k * (l << 3); i < nPlayerInputs[l]; i++, j++) {
				BurnDrvGetInputInfo(&bii, i + nPlayerOffset[l]);
				if (bii.nType == BIT_DIGITAL) {
					if (nControls[j >> 3] & (1 << (j & 7))) {
						*bii.pVal = 0x01;
					} else {
						*bii.pVal = 0x00;
					}
				}
			}

			j += nCommonInputs;		// other players' common controls are not applied

			// Convert j to byte count
			j = (j + 7) >> 3;

			// Analog inputs/constants
			for (i = 0; i < nPlayerInputs[l]; i++) {
				BurnDrvGetInputInfo(&bii, i + nPlayerOffset[l]);
				if (bii.nType != BIT_DIGITAL) {
					if (bii.nType & BIT_GROUP_ANALOG) {
						*bii.pShortVal = (nControls[j] << 8) | nControls[j + 1];
						j += 2;
					}
				}
			}

			// For a DIP switch to be set to 1, ALL players must set it
			for (i = 0; i < nDIPInputs; i++, j++) {
				BurnDrvGetInputInfo(&bii, i + nDIPOffset);
				*bii.pVal &= nControls[j];
			}
		}
	}

	return 0;
}

// ---------------------------------------------------------------------------------------------------------------
// Session callbacks (fbn_ggpo.cpp)

static void QuarkStatus(const TCHAR *text)
{
	if (text[0]) VidSNewShortMsg(text, 0xFFFFFF, 120, 1);
}

static bool __cdecl ggpo_on_client_event_callback(GGPOClientEvent *info)
{
	switch (info->code) {
		case GGPOCLIENT_EVENTCODE_CONNECTING:			QuarkStatus(_T("Connecting...")); break;
		case GGPOCLIENT_EVENTCODE_CONNECTED:			QuarkStatus(_T("Connected")); break;
		case GGPOCLIENT_EVENTCODE_RETREIVING_MATCHINFO:	QuarkStatus(_T("Retrieving Match Info...")); break;
		case GGPOCLIENT_EVENTCODE_DISCONNECTED:			QuarkStatus(_T("Disconnected!")); break;
		case GGPOCLIENT_EVENTCODE_CHAT:
			if (strlen(info->u.chat.text) > 0) {
				TCHAR szUser[128];
				TCHAR szText[1024];
				ANSIToTCHAR(info->u.chat.username, szUser, 128);
				ANSIToTCHAR(info->u.chat.text, szText, 1024);
				VidSAddChatMsg(szUser, 0xFFA000, szText, 0xEEEEEE);
			}
			break;
		default:
			break;
	}
	return true;
}

static void QuarkSendChatCmd(const char *text, char cmd)
{
	char buffer[1024]; // command chat
	buffer[0] = cmd;
	strncpy(&buffer[1], text, 1022);
	buffer[1023] = 0;
	Ggpo.client_chat(ggpo, buffer);
}

static bool __cdecl ggpo_on_event_callback(GGPOEvent *info)
{
	if (ggpo_is_client_eventcode(info->code)) {
		return ggpo_on_client_event_callback((GGPOClientEvent *)info);
	}
	if (ggpo_is_client_gameevent(info->code)) {
		return true;	// deprecated in fightcade-fbneo
	}
	switch (info->code) {
		case GGPO_EVENTCODE_CONNECTED_TO_PEER:			QuarkStatus(_T("Connected to Peer")); break;
		case GGPO_EVENTCODE_SYNCHRONIZING_WITH_PEER:	QuarkStatus(_T("Synchronizing with Peer...")); break;
		case GGPO_EVENTCODE_RUNNING: {
			QuarkLog("quark: running");
			// send ReceiveVersion message
			char temp[16];
			sprintf(temp, "%d", INFINITE_NET_VERSION);
			QuarkSendChatCmd(temp, 'V');
			break;
		}
		case GGPO_EVENTCODE_DISCONNECTED_FROM_PEER:		QuarkStatus(_T("Disconnected from Peer")); QuarkLog("quark: peer disconnected"); break;
		default:
			break;
	}
	return true;
}

static bool __cdecl ggpo_begin_game_callback(char *name)
{
	WIN32_FIND_DATA fd;
	TCHAR tfilename[MAX_PATH];
	TCHAR tname[MAX_PATH];

	strncpy(pGameName, name, MAX_PATH - 1);
	pGameName[MAX_PATH - 1] = 0;
	ANSIToTCHAR(name, tname, MAX_PATH);
	QuarkLog("quark: begin_game %s", name);

	// regular savestate (freeplay, event mode, etc.)
	_stprintf(tfilename, _T("savestates\\%s_fbneo.fs"), tname);
	HANDLE hFind = FindFirstFile(tfilename, &fd);
	if (hFind != INVALID_HANDLE_VALUE) {
		FindClose(hFind);
		INT32 nRet = BurnStateLoad(tfilename, 1, &DrvInitCallback);
		QuarkLog("quark: boot state %s -> %d", TCHARToANSI(tfilename, NULL, 0), nRet);
		// A preloaded driver can load its state without calling DrvInit again.
		// Rebuild the packed network input layout after the session is active.
		if (nRet == 0) NetworkInitInput();
		return nRet == 0;
	}

	// no savestate
	for (UINT32 i = 0; i < nBurnDrvCount; i++) {
		nBurnDrvActive = i;
		if ((_tcscmp(BurnDrvGetText(DRV_NAME), tname) == 0) && (!(BurnDrvGetFlags() & BDF_BOARDROM))) {
			INT32 nRet = DrvInit(i, true);
			QuarkLog("quark: DrvInit(%s) -> %d", name, nRet);
			return nRet == 0;
		}
	}

	return 0;
}

static bool __cdecl ggpo_advance_frame_callback(int)
{
	bSkipPerfmonUpdates = true;
	nFramesEmulated--;
	nRollbackFrames++;
    // Corrections are nested in the drawn frame's input synchronization.
    // Keep its PCM destination intact for that final native frame.
    INT16 *soundOut = pBurnSoundOut;
    RunFrame(0, 0, 0);
    pBurnSoundOut = soundOut;
	bSkipPerfmonUpdates = false;
	return true;
}

#include "infinite_crc32.h"

static const INT32 nQuarkBufferCapacity = 16 * 1024 * 1024;
#include "infinite_snapshot_pool.h"
static InfiniteSnapshotPool quarkSnapshotPool;
static char *gAcbScanPointer, *gAcbScanStart;
static INT32 nQuarkPayloadSize, nQuarkTimingOffset, nQuarkScanError;
static INT32 nQuarkAudioOffset;
static UINT32 nQuarkSaveCrc;

// Header word 5 (always 0 in fightcade-fbneo) names this state's layout, so the bridge and the client never
// assume Fightcade's: bytes 'I','L', then the little-endian 16-bit state offset of the 512 KiB "Main RAM"
// area (0x218 for CPS3: header 24 + EEPROM 512; Fightcade's was 0x418 behind its 1 KiB EEPROM scan).
// 0 when the driver scans no such area.
static INT32 nQuarkMainRam = -1;
static INT32 nQuarkCramOffset=-1;
static void* nQuarkCramData;

static INT32 __cdecl QuarkLayoutAcb(struct BurnArea* pba)
{
	if (pba->nLen < 0 || pba->nLen > nQuarkBufferCapacity - nQuarkPayloadSize) {
		nQuarkScanError = 1;
		return 1;
	}
	if (pba->szName && !strcmp(pba->szName, "Main RAM") && pba->nLen == 0x80000)
		nQuarkMainRam = ggpo_state_header_size + nQuarkPayloadSize;
	if (pba->szName && !strcmp(pba->szName, "boardTiming")) {
		if (nQuarkTimingOffset >= 0 || pba->nLen < 4) nQuarkScanError = 1;
		nQuarkTimingOffset = nQuarkPayloadSize;
	}
    if (pba->szName && !strcmp(pba->szName, "cps3Audio")) {
        if (nQuarkAudioOffset >= 0 || pba->nLen != (INT32)cps3SndStateSize()) nQuarkScanError = 1;
        nQuarkAudioOffset = nQuarkPayloadSize;
    }
    if(pba->szName&&!strcmp(pba->szName,"Sprite ROM")&&pba->nLen==0x800000){
        if(nQuarkCramOffset>=0)nQuarkScanError=1;
        nQuarkCramOffset=nQuarkPayloadSize;nQuarkCramData=pba->Data;
    }
	nQuarkPayloadSize += pba->nLen;
	return 0;
}

static INT32 QuarkScanFlags()
{
	// Character RAM is writable arcade state, including CPU-visible banked
	// reads. The old network optimization omitted it; Infinite restores it
	// with timing/cache state just as the complete local/runahead scan does.
	return ACB_FULLSCAN | ((has_sh2 && Sh2Cps3TimingVersion()) ? 0 : ACB_NET_OPT);
}

static bool QuarkStateLayout()
{
	nQuarkPayloadSize = 0;
	nQuarkCramOffset=-1;nQuarkCramData=NULL;
	nQuarkMainRam = nQuarkTimingOffset = -1;
    nQuarkAudioOffset = -1;
	nQuarkScanError = 0;
	auto previous = BurnAcb;
	BurnAcb = QuarkLayoutAcb;
	BurnAreaScan(QuarkScanFlags() | ACB_READ, NULL);
	BurnAcb = previous;
	return !nQuarkScanError && nQuarkPayloadSize > 0;
}

static UINT32 QuarkTimingVersion()
{
	return has_sh2 ? Sh2Cps3TimingVersion() : 0;
}

static UINT32 QuarkLayoutTag()
{
	return (nQuarkMainRam > 0 && nQuarkMainRam < 0x10000) ? (0x4c49 | (nQuarkMainRam << 16)) : 0;
}

static INT32 __cdecl QuarkReadAcb(struct BurnArea* pba)
{
	if (pba->nLen < 0 || pba->nLen > nQuarkPayloadSize - (gAcbScanPointer - gAcbScanStart)) {
		nQuarkScanError = 1; return 1;
	}
    nQuarkSaveCrc = InfiniteCopyCrc32(nQuarkSaveCrc, (unsigned char *)gAcbScanPointer,
        (const unsigned char *)pba->Data, pba->nLen);
	gAcbScanPointer += pba->nLen;
	return 0;
}

static INT32 __cdecl QuarkWriteAcb(struct BurnArea* pba)
{
	InfiniteStateCopy(pba->Data, gAcbScanPointer, pba->nLen);
	gAcbScanPointer += pba->nLen;
	return 0;
}

#include "infinite_page_snapshots.h"

static bool __cdecl ggpo_save_game_state_callback(unsigned char **buffer, int *len, int *checksum, int frame)
{
	static int nSaves = 0;
	if (nSaves++ < 2) QuarkLog("quark: save state frame %d", frame);
	*buffer = NULL; *len = *checksum = 0;
	if (!QuarkStateLayout()) return false;
	if(QuarkTrySavePages(buffer,len,checksum))return true;
	*len = nQuarkPayloadSize + ggpo_state_header_size;
	*buffer = quarkSnapshotPool.Acquire(*len, QuarkTimingVersion(), cps3SndStateVersion(), QuarkLayoutTag());
	if (!*buffer) { *len = 0; return false; }

	int *data = (int *)*buffer;
	data[0] = 'GGPO';
	data[1] = ggpo_state_header_size;
	data[2] = INFINITE_NET_VERSION;
	data[3] = 0;		// detector state/scores/ranked (no detector, T-0108)
	data[4] = QuarkTimingVersion();
	data[5] = QuarkLayoutTag();	// 'I','L',offset
    // Compute the identical IEEE CRC while copying each complete scan area.
    // Every byte, including writable graphics RAM, is still present.
    nQuarkSaveCrc = InfiniteCrc32(0, *buffer, ggpo_state_header_size);
	gAcbScanStart = gAcbScanPointer = (char *)(*buffer + ggpo_state_header_size);
	auto previous = BurnAcb;
	BurnAcb = QuarkReadAcb;
	BurnAreaScan(QuarkScanFlags() | ACB_READ, NULL);
	BurnAcb = previous;
	if (nQuarkScanError || gAcbScanPointer - gAcbScanStart != nQuarkPayloadSize) {
		quarkSnapshotPool.Release(*buffer, false); *buffer = NULL; *len = 0;
		return false;
	}


	*checksum = (INT32)nQuarkSaveCrc;
	bQuarkStateSaved = true;
	return true;
}

static bool __cdecl ggpo_load_game_state_callback(unsigned char *buffer, int length)
{
	// Validate the complete layout/profile before the first write. Raw legacy
	// states and states from a different timing model are not Infinite states.
	UINT32 data[6];
	if (!buffer || length < ggpo_state_header_size || !QuarkStateLayout()) return false;
	if(auto owned=QuarkPageFind(buffer))return QuarkLoadPages(owned,length);
	memcpy(data, buffer, sizeof(data));
	if (data[0] != 'GGPO' || data[1] != ggpo_state_header_size || data[2] != INFINITE_NET_VERSION ||
		data[4] != QuarkTimingVersion() || data[5] != QuarkLayoutTag() ||
		length != ggpo_state_header_size + nQuarkPayloadSize) {
		QuarkLog("quark: refused mismatched Infinite state profile/length");
		return false;
	}
	buffer += ggpo_state_header_size;
	if (data[4]) {
		UINT32 version = 0;
		if (nQuarkTimingOffset < 0) return false;
		memcpy(&version, buffer + nQuarkTimingOffset, sizeof(version));
		if (version != data[4]) return false;
	} else if (nQuarkTimingOffset >= 0) return false;
    if (cps3SndStateVersion()) {
        if (nQuarkAudioOffset < 0 || !cps3SndStateCompatible(buffer + nQuarkAudioOffset, cps3SndStateSize())) return false;
    } else if (nQuarkAudioOffset >= 0) return false;
	gAcbScanPointer = (char *)buffer;
	auto previous = BurnAcb;
	BurnAcb = QuarkWriteAcb;
	BurnAreaScan(QuarkScanFlags() | ACB_WRITE, NULL);
	BurnAcb = previous;
	nRollbackCount++;
	return true;
}

// Explicit host interface for the replay bridge (lobby_next/native/host_redraw.h), in place of the
// hash-guarded fightcade-fbneo addresses: draw the settled frame again without emulating, e.g. behind a
// crew pause after GGPO's last rollback frame ran undrawn. Only CPS3 drivers, whose Redraw is always
// DrvCps3Draw: VidFrameCallback runs a frame when a driver has no Redraw. 0 = drawn.
extern "C" __declspec(dllexport) INT32 __cdecl InfiniteRedrawSettled()
{
	if (!bDrvOkay || !bVidOkay) return 1;
	if ((BurnDrvGetHardwareCode() & 0x7f000000) != HARDWARE_PREFIX_CPS3) return 2;
	return VidRedraw() ? 3 : 0;
}

static bool __cdecl ggpo_log_game_state_callback(char *, unsigned char *, int)
{
	return true;
}

static void __cdecl ggpo_free_buffer_callback(void *buffer)
{
	QuarkFreePages(buffer);
	quarkSnapshotPool.Release(buffer);
}

static void QuarkReleaseClosedSessionBuffers()
{
	// Only after close_session returns (or session creation fails). The bundled
	// DLL frees its session object without returning its remaining snapshots.
	// Retire the pool first, then use the ordinary free callback to reclaim those
	// unreachable buffers. No allocation owned by a live session is recycled.
	quarkSnapshotPool.End();
	while (void *buffer = quarkSnapshotPool.FirstOutstanding())
		ggpo_free_buffer_callback(buffer);
	QuarkClosePages();
}

// ---------------------------------------------------------------------------------------------------------------

// quark:direct,<game>,<localport>,<remoteip>,<remoteport>,<player>,<delay>,<ranked>
// quark:synctest,<game>,<frames>
INT32 QuarkInit(const TCHAR *tconnect)
{
	QuarkLog("quark: FBneo Infinite profile %08x; matching emulator and ROM builds required", INFINITE_NET_VERSION);
	char connect[MAX_PATH];
	TCHARToANSI(tconnect, connect, MAX_PATH);

	if (!QuarkLoadLibrary()) {
		QuarkLog("quark: Winsock or ggponet.dll unavailable; no session for %s", connect);
		return 1;
	}

	char game[128], server[128];
	int delay = 0, ranked = 0, frames = 0, player = 0, localPort = 0, remotePort = 0;

	bQuarkStateSaved = false;

	kNetVersion = INFINITE_NET_VERSION;
	kNetGame = 1;
	kNetLua = 0;
	kNetSpectator = 0;
	bForce60Hz = 0;
	iPlayer = 0;
	iDelay = 0;

	GGPOSessionCallbacks cb = { 0 };
	cb.begin_game = ggpo_begin_game_callback;
	cb.load_game_state = ggpo_load_game_state_callback;
	cb.save_game_state = ggpo_save_game_state_callback;
	cb.log_game_state = ggpo_log_game_state_callback;
	cb.free_buffer = ggpo_free_buffer_callback;
	cb.advance_frame = ggpo_advance_frame_callback;
	cb.on_event = ggpo_on_event_callback;

	quarkSnapshotPool.Begin();
	bInfiniteQuark = 1;
	if (strncmp(connect, "quark:direct", strlen("quark:direct")) == 0) {
		if (sscanf(connect, "quark:direct,%127[^,],%d,%127[^,],%d,%d,%d,%d", game, &localPort, server, &remotePort, &player, &delay, &ranked) < 6) {
			QuarkLog("quark: malformed %s", connect);
			bInfiniteQuark = 0; kNetGame = 0; QuarkReleaseClosedSessionBuffers();
			return 1;
		}
		kNetLua = 1;
		iPlayer = player;
		iDelay = delay;
		QuarkLog("quark: direct %s local %d remote %s:%d side %d delay %d", game, localPort, server, remotePort, player, delay);
		ggpo = Ggpo.start_session(&cb, game, localPort, server, remotePort, player);
		QuarkLog("quark: session %p", ggpo);
        // The legacy DLL's provisional input must establish frame zero at
        // The legacy backend refuses delay changes after its first successful
        // synchronization. Apply the agreed delay before that boundary.
        if (ggpo) Ggpo.set_frame_delay(ggpo, delay);
        QuarkLog("quark: frame delay %d set before synchronization", delay);
		QuarkStatus(_T("Connecting..."));
	}
	else if (strncmp(connect, "quark:synctest", strlen("quark:synctest")) == 0) {
		if (sscanf(connect, "quark:synctest,%127[^,],%d", game, &frames) < 2) {
			QuarkLog("quark: malformed %s", connect);
			bInfiniteQuark = 0; kNetGame = 0; QuarkReleaseClosedSessionBuffers();
			return 1;
		}
		kNetLua = 1;
		QuarkLog("quark: synctest %s frames %d", game, frames);
		ggpo = Ggpo.start_synctest(&cb, game, frames);
	}
	else {
		QuarkLog("quark: unsupported session %s", connect);
		bInfiniteQuark = 0; kNetGame = 0; QuarkReleaseClosedSessionBuffers();
		return 1;
	}

	if (ggpo == NULL) {
		QuarkLog("quark: no session");
		bInfiniteQuark = 0; kNetGame = 0; QuarkReleaseClosedSessionBuffers();
		return 1;
	}
	return 0;
}

void QuarkEnd()
{
	if (!bInfiniteQuark) { QuarkReleaseClosedSessionBuffers(); return; }
	QuarkLog("quark: end (rollbacks %d, rollback frames %d)", nRollbackCount, nRollbackFrames);
	Ggpo.close_session(ggpo);
	QuarkReleaseClosedSessionBuffers();
	QuarkLog("quark: snapshot pool allocations %llu reuse %llu failures %llu peak outstanding %llu peak pooled %llu peak total %llu outstanding %llu pooled %llu",
		quarkSnapshotPool.allocations, quarkSnapshotPool.reuses, quarkSnapshotPool.failures,
		quarkSnapshotPool.peakOutstandingBytes, quarkSnapshotPool.peakPooledBytes, quarkSnapshotPool.peakTotalBytes,
		quarkSnapshotPool.outstandingBytes, quarkSnapshotPool.pooledBytes);
	ggpo = NULL;
	bInfiniteQuark = 0;
	kNetGame = 0;
}

void QuarkRunIdle(int ms)
{
	Ggpo.idle(ggpo, ms);
}

bool QuarkIncrementFrame()
{
	Ggpo.advance_frame(ggpo);

	if (!bSkipPerfmonUpdates) {
		GGPONetworkStats stats;
		Ggpo.get_stats(ggpo, &stats);
	}

	return true;
}

#ifdef INFINITE_CRAM_CRC_TEST_EXPORTS

// Private QA exports only. These are never part of the production build.
static unsigned char *crowTestState;static int crowTestLength,crowTestChecksum;
extern "C" __declspec(dllexport) int __cdecl InfiniteCrowSaveNet(void *) {
    if(crowTestState)ggpo_free_buffer_callback(crowTestState);
    quarkPageManualTest=true;
    if(!ggpo_save_game_state_callback(&crowTestState,&crowTestLength,&crowTestChecksum,0))ExitProcess(131);
    FILE*f=fopen("results/network_snapshot.bin","wb");if(!f)ExitProcess(132);
    int canonical=InfiniteSnapshotCanonicalSize(crowTestState,crowTestLength);
    if(canonical>0){void* full=malloc(canonical);if(!full||InfiniteSnapshotMaterialize(crowTestState,crowTestLength,full,canonical))ExitProcess(194);fwrite(full,1,canonical,f);free(full);}
    else fwrite(crowTestState,1,crowTestLength,f);
    fclose(f);return 0;
}
extern "C" __declspec(dllexport) int __cdecl InfiniteCrowLoadNet(void *) {
    if(!crowTestState||!ggpo_load_game_state_callback(crowTestState,crowTestLength))ExitProcess(133);
    return 0;
}

extern "C" __declspec(dllexport) int __cdecl InfinitePageTestStatus(void*){
    FILE*f=fopen("results/page_callback.json","w");if(!f)ExitProcess(195);
    fprintf(f,"{\"saves\":%llu,\"loads\":%llu,\"internal_bytes\":%d,\"canonical_bytes\":%d}\n",
        quarkPageSaves,quarkPageLoads,crowTestLength,InfiniteSnapshotCanonicalSize(crowTestState,crowTestLength));fclose(f);return 0;
}

#endif
