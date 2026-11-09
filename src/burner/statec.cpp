// FB Neo Driver State load/save from buffer module        - dink 2024
#include "burnint.h"
#include "zlib.h"
#include "sh2_intf.h"
extern UINT32 cps3SndStateVersion();
extern UINT32 cps3SndStateSize();
extern bool cps3SndStateCompatible(const void *, UINT32);

// Fightcade CPS3 .fs files contain one zlib-compressed, ordered scan. Upstream
// states use named blocks. Import only the pinned x86 CPS3 layout, with exact
// length/driver checks before touching the machine; keep native saves upstream.
static UINT8 *legacyCps3 = NULL;
static bool legacyCps3Validate = false;
static INT32 legacyCps3Errors = 0, legacyCps3Areas = 0;
static INT32 __cdecl LegacyCps3Acb(struct BurnArea *ba)
{
	struct Area { const char *name; UINT32 offset, length; };
	static const Area areas[] = {
		{"EEPROM RAM", 0, 0x200}, {"Main RAM", 0x400, 0x80000},
		{"Sprite RAM", 0x80400, 0x80000}, {"Sprite List", 0x100400, 0x80000},
		{"Char ROM", 0x180400, 0x10000}, {"Video REG", 0x190400, 0x100},
		{"Video REG_BUF", 0x190400, 0x100}, {"RAM C000", 0x190500, 0x800},
		{"Palette", 0x190d00, 0x40000}, {"Sprite ROM", 0x1d0d00, 0x800000},
		{"Sh2Ext[i].suspend", 0x9d0d00 + 2412, 4},
		{"chip->voice", 0x9d0d00 + 2416, 640}, {"chip->key", 0x9d0d00 + 3056, 2},
		{"ss_bank_base", 0x9d192a - 48, 4}, {"ss_pal_base", 0x9d192a - 44, 4},
		{"cram_bank", 0x9d192a - 40, 4}, {"cps3_current_eeprom_read", 0x9d192a - 36, 2},
		{"gfxflash_bank", 0x9d192a - 34, 4}, {"paldma_source", 0x9d192a - 30, 4},
		{"paldma_dest", 0x9d192a - 26, 4}, {"paldma_fade", 0x9d192a - 22, 4},
		{"paldma_length", 0x9d192a - 18, 4}, {"chardma_source", 0x9d192a - 14, 4},
		{"chardma_table_address", 0x9d192a - 10, 4}, {"spritelist_dma", 0x9d192a - 6, 2},
		{"spritelist_dma_prev", 0x9d192a - 6, 2}, {"cps_int10_cnt", 0x9d192a - 4, 4},
	};
	if (!strcmp(ba->szName, "SH2 #0")) {
		legacyCps3Areas++;
		if (ba->nLen != 2428) { legacyCps3Errors++; return 1; }
		if (legacyCps3Validate) return 0;
		// irq_line_hold[17] was inserted after irq_line_state[17], changing
		// aligned m[] offset from 280 to 296. Old states have no HOLD lines.
		UINT8 *dst = (UINT8 *)ba->Data;
		memcpy(dst, legacyCps3 + 0x9d0d00, 277);
		memset(dst + 277, 0, 19);
		memcpy(dst + 296, legacyCps3 + 0x9d0d00 + 280, 2412 - 280);
		return 0;
	}
	for (unsigned int i = 0; i < sizeof(areas) / sizeof(areas[0]); i++) {
		if (!strcmp(ba->szName, areas[i].name)) {
			legacyCps3Areas++;
			if (ba->nLen != areas[i].length) { legacyCps3Errors++; return 1; }
			if (legacyCps3Validate) return 0;
			memcpy(ba->Data, legacyCps3 + areas[i].offset, ba->nLen);
			return 0;
		}
	}
	if (legacyCps3Validate) return 0;
	if (!strcmp(ba->szName, "nExtraCycles") || !strcmp(ba->szName, "dma_status")) memset(ba->Data, 0, ba->nLen);
	if (!strcmp(ba->szName, "dma_timer")) memset(ba->Data, 0xff, ba->nLen);
	if (!strcmp(ba->szName, "infiniteIdle")) { memset(ba->Data, 0, ba->nLen); ((UINT32 *)ba->Data)[1] = 1; }
	return 0;
}

static INT32 LegacyCps3Load(UINT8 *data, INT32 length, INT32 all)
{
	if (all && cps3SndStateVersion()) return 1; // old audio profile; NVRAM remains importable
	// Importing a legacy checkpoint into a different timing model is a research
	// initial condition, never replay compatibility. Require the explicit override.
	if (all && has_sh2 && Sh2GetCps3Timing()) {
		const char *allow = getenv("INFINITE_CPS3_TIMING_IMPORT");
		if (!allow || strcmp(allow, "1")) return 1;
	}
	const char *driver = BurnDrvGetTextA(DRV_NAME);
	if (!strstr(driver, "sfiii") && !strstr(driver, "jojo") && !strstr(driver, "redearth") && !strstr(driver, "warzard")) return 1;
	// Fightcade scanned 1024 EEPROM bytes; only the first 512 are CPS3 NVRAM.
	// Keep existing mode profiles loadable at power-on, as well as full states.
	const UINT32 rawLength = all ? 0x9d192a : 0x400;
	legacyCps3 = (UINT8 *)malloc(rawLength + 1);
	if (!legacyCps3) return 1;
	z_stream stream; memset(&stream, 0, sizeof(stream));
	stream.next_in = data; stream.avail_in = length;
	stream.next_out = legacyCps3; stream.avail_out = rawLength + 1;
	if (inflateInit(&stream) != Z_OK) { free(legacyCps3); legacyCps3 = NULL; return 1; }
	int result = inflate(&stream, Z_FINISH);
	bool valid = result == Z_STREAM_END && stream.total_out == rawLength && stream.avail_in == 0;
	inflateEnd(&stream);
	if (valid) {
		BurnAcb = LegacyCps3Acb;
		legacyCps3Validate = true; legacyCps3Errors = legacyCps3Areas = 0;
		const INT32 scan = all ? ACB_FULLSCAN : ACB_NVRAM;
		BurnAreaScan(scan | ACB_READ, NULL);
		valid = legacyCps3Errors == 0 && legacyCps3Areas == (all ? 28 : 1);
		legacyCps3Validate = false;
		if (valid) {
			BurnAreaScan(scan | ACB_WRITE, NULL);
			if (all && has_sh2 && Sh2GetCps3Timing()) {
				Sh2SetCps3Timing(1);
				Sh2Cps3TimingFastBoot();
			}
		}
	}
	free(legacyCps3); legacyCps3 = NULL;
	return valid ? 0 : 1;
}

// BurnStateCompress: Save a state, "Compress" == organized into a buffer
// BurnStateDecompress: Load a state from buffer

#define DEBUG_STATEC 0
#define stateclog(x) do { if (DEBUG_STATEC) bprintf x; } while (0)

extern bool bWithEEPROM; // from state.cpp, win32/replay.cpp

static INT32 nStateLoadFileLength = 0; // file size loaded
static INT32 nCalculatedLength = 0; // calculated size from driver
static INT32 nCalculatedVars = 0; // calculated variable count from driver
static INT32 nBufferPosition = 0; // position of load/save progress
static bool bNeedToRecover = false;
static UINT8 *Buffer = NULL;
static UINT8 *pBuffer = NULL;

static const UINT32 BLOCK_ID_STATE = 0xa55a0000;
static const UINT32 BLOCK_ID_VARIABLE = 0xa55a0001;
static const UINT32 STATE_SIZE_1_ENTRY = sizeof(UINT32) * 3; // block id, data length, data name hash
static const UINT32 STATE_SIZE_HEADER = sizeof(UINT32) * 2; // block id, reserved (32 bits future data)

static UINT32 HashString(char *in_str)
{
	UINT32 hash = 0xc0ffee;
	const int in_strlen = strlen(in_str);
	for (INT32 i = 0; i < in_strlen; i++) {
		hash = (hash ^ in_str[i]) + ((hash << 0x1a) + (hash >> 0x06));
	}
	return hash;
}

static bool Cps3TimingStateCompatible(const UINT8 *data, INT32 length) {
	// Validate before ANY scan/load can alter CPU or RAM. Do not let upstream's
	// missing-block recovery retain an unrelated warm cache/pending transaction.
	const UINT32 wanted = has_sh2 ? Sh2Cps3TimingVersion() : 0;
	const UINT32 key = HashString((char *)"boardTiming");
	bool found = false, audioFound = false;
    const UINT32 audioWanted = cps3SndStateVersion();
    const UINT32 audioKey = HashString((char *)"cps3Audio");
    UINT32 pos = 8;
	while (pos < (UINT32)length) {
		if ((UINT32)length - pos < 12) return false;
		UINT32 id, size, hash;
		memcpy(&id,data+pos,4); memcpy(&size,data+pos+4,4); memcpy(&hash,data+pos+8,4);
		pos += 12;
		if (id != BLOCK_ID_VARIABLE || size > (UINT32)length-pos) return false;
		if (hash == key) {
			if (found || !wanted || size != Sh2Cps3TimingStateSize()) return false;
			UINT32 version;memcpy(&version,data+pos,4);
			if (version != wanted) return false;
			found=true;
		}
        if (hash == audioKey) {
            if (audioFound || !audioWanted || size != cps3SndStateSize()) return false;
            if (!cps3SndStateCompatible(data+pos, size)) return false;
            audioFound = true;
        }
        pos += size;
    }
    return found == (wanted != 0) && audioFound == (audioWanted != 0);
}

static void AddToBuffer(void *data, UINT32 data_size)
{
	memcpy(pBuffer, data, data_size);
	pBuffer += data_size;
	nBufferPosition += data_size;
}

static void GetFromBuffer(void *data, UINT32 data_size)
{
	if (data != NULL) memcpy(data, pBuffer, data_size);
	pBuffer += data_size;
	nBufferPosition += data_size;
}

static INT32 __cdecl LenAcb(struct BurnArea* pba)
{
	// block id, data length, data name hash, data
	nCalculatedLength += STATE_SIZE_1_ENTRY + pba->nLen;
	nCalculatedVars ++;
	return 0;
}

static INT32 __cdecl SaveAcb(struct BurnArea* pba)
{
	if (pba->nLen + STATE_SIZE_1_ENTRY + nBufferPosition > nCalculatedLength) {
		stateclog((0, _T("SaveAcb(): No space for \"%S\"  nCalculatedLength  %x  pba->nLen  %x  nBufferPosition  %x\n"), pba->szName, nCalculatedLength, pba->nLen, nBufferPosition));
		return 1;
	}

	UINT32 strhash = HashString(pba->szName);

	stateclog((0, _T("save  %S\t\tlength  %x %x\n"), pba->szName, pba->nLen, strhash));

	// copy block identifier
	AddToBuffer((void*)&BLOCK_ID_VARIABLE, sizeof(UINT32));

	// copy length of variable
	AddToBuffer(&pba->nLen, sizeof(UINT32));

	// copy hash of variable string
	AddToBuffer(&strhash, sizeof(UINT32));

	// copy variable
	AddToBuffer(pba->Data, pba->nLen);

	return 0;
}

static INT32 __cdecl LoadAcb(struct BurnArea* pba)
{
	int tries = 0;
	bool gotit = false;

	UINT8 *pBufferSave = pBuffer;
	UINT32 nBufferPositionSave = nBufferPosition;

	do {
		if (pba->nLen + STATE_SIZE_1_ENTRY + nBufferPosition > nStateLoadFileLength) {
			stateclog((0, _T("LoadAcb(): No space to load \"%S\"  nCalculatedLength  %x  pba->nLen  %x  nBufferPosition  %x\n"), pba->szName, nCalculatedLength, pba->nLen, nBufferPosition));
			break;
		}

		UINT32 length = 0;
		UINT32 loadedblockid = 0;
		UINT32 loadedhash = 0;
		UINT32 ourhash = HashString(pba->szName);

		stateclog((0, _T("load  %S\t\tlength  %x  %x  (%x, %x)\n"), pba->szName, pba->nLen, ourhash, nBufferPosition, nCalculatedLength));

		GetFromBuffer(&loadedblockid, sizeof(UINT32));

		if (BLOCK_ID_VARIABLE != loadedblockid) {
			stateclog((0, _T("-- block ID fail - we probably can't recover from this!\n")));
			break;
		}

		GetFromBuffer(&length, sizeof(UINT32));
		GetFromBuffer(&loadedhash, sizeof(UINT32));

		if (length == pba->nLen && ourhash == loadedhash) {
			GetFromBuffer(pba->Data, pba->nLen);
			gotit = true;
		} else {
			stateclog((0, _T("|-- length doesn't match driver length/hash!  skipping.\n")));

			GetFromBuffer(NULL, length); // just increment pointer using length from state buffer
		}

	} while (!gotit && ++tries < 50);

	if (gotit == false) {
		stateclog((0, _T("Can't seem to match, let's rewind pBuffer!\n")));

		bNeedToRecover = true;
		pBuffer = pBufferSave;
		nBufferPosition = nBufferPositionSave;
	} else {
		if (bNeedToRecover) {
			stateclog((0, _T("|-- Success - We made a nice recovery!  That was close :)\n")));

			bNeedToRecover = false;
		}
	}

	return 0;
}

// Save a state, "Compress" == organized into a buffer
INT32 BurnStateCompress(UINT8** pDef, INT32* pnDefLen, INT32 bAll)
{
	UINT32 nAddEEPROM = (bWithEEPROM) ? ACB_EEPROM : 0;

	nCalculatedLength = STATE_SIZE_HEADER;
	nCalculatedVars = 0;
	BurnAcb = LenAcb; // Get length of state buffer

	if (bAll) BurnAreaScan(ACB_FULLSCAN | ACB_READ, NULL);				// scan all ram (read from driver variables)
	else      BurnAreaScan(ACB_NVRAM | nAddEEPROM | ACB_READ, NULL);	// scan nvram

	stateclog((0, _T("BurnStateCompress(Save): Sizes, Calculated:  %x  Entries:  %x\n"), nCalculatedLength, nCalculatedVars));

	// Set-up the buffer
	Buffer = (UINT8*)malloc(nCalculatedLength); // note: this is free()'d in state.cpp
	nBufferPosition = 0;
	pBuffer = Buffer;
	BurnAcb = SaveAcb;

	// Add BLOCKID/header to the beginning of state buffer
	UINT32 future_use = 0;
	AddToBuffer((void *)&BLOCK_ID_STATE, sizeof(UINT32));
	AddToBuffer(&future_use, sizeof(UINT32));

	if (bAll) BurnAreaScan(ACB_FULLSCAN | ACB_READ, NULL);				// scan all ram (read from driver variables)
	else      BurnAreaScan(ACB_NVRAM | nAddEEPROM | ACB_READ, NULL);	// scan nvram

	if (pDef) *pDef = Buffer;
	if (pnDefLen) *pnDefLen = nCalculatedLength;

	return 0;
}

// Load a state from buffer
INT32 BurnStateDecompress(UINT8* Def, INT32 nDefLen, INT32 bAll)
{
	if (nDefLen < 8) return 1;
	UINT32 signature; memcpy(&signature, Def, sizeof(signature));
	if (signature != BLOCK_ID_STATE) return LegacyCps3Load(Def, nDefLen, bAll);
	if (bAll && !Cps3TimingStateCompatible(Def,nDefLen)) return 1;
	UINT32 nAddEEPROM = (bWithEEPROM) ? ACB_EEPROM : 0;

	nStateLoadFileLength = nDefLen;

	nCalculatedLength = 0;
	nCalculatedVars = 0;
	BurnAcb = LenAcb; // Get length of state buffer

	if (bAll) BurnAreaScan(ACB_FULLSCAN | ACB_WRITE, NULL);				// scan all ram (write to driver variables)
	else      BurnAreaScan(ACB_NVRAM | nAddEEPROM | ACB_WRITE, NULL);	// scan nvram

	stateclog((0, _T("BurnStateDecompress(Load): Sizes, Calculated:  %x  Loaded:  %x\n"), nCalculatedLength, nDefLen));

	bNeedToRecover = false;
	nBufferPosition = 0;
	pBuffer = Def;
	BurnAcb = LoadAcb;

	UINT32 test_header;
	UINT32 future_use;
	GetFromBuffer(&test_header, sizeof(UINT32));
	GetFromBuffer(&future_use, sizeof(UINT32));

	if (test_header != BLOCK_ID_STATE) {
		stateclog((0, _T("State file header is missing or corrupt!\n")));
		return 1;
	}

	if (bAll) BurnAreaScan(ACB_FULLSCAN | ACB_WRITE, NULL);             // scan all ram (write to driver variables)
	else      BurnAreaScan(ACB_NVRAM | nAddEEPROM | ACB_WRITE, NULL);	// scan nvram

	return 0;
}
