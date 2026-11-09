#include "cps3.h"

// CPS-3 sound emulation by Philip Bennett

#define CPS3_VOICES		16

// Native clock and the driver's existing 59.59949 Hz frame cadence, as
// integers. Neither host sample rate nor sound-buffer availability is chip time.
// This corrects the inherited mixer arithmetic; it is not board calibration.
static const UINT64 CPS3_AUDIO_FRAME_NUM = 42954500ULL * 100000ULL;
static const UINT64 CPS3_AUDIO_FRAME_DEN = 3ULL * 384ULL * 5959949ULL;
static const UINT32 CPS3_AUDIO_VERSION = 0x20261014;

struct Cps3AudioState {
    UINT32 version;
    UINT32 reserved;
    UINT64 phase;
    INT16 history[2][2]; // native R/L samples, before host routing/gain
};
static Cps3AudioState cps3Audio;

typedef struct {
	UINT16 regs[16];
	UINT32 pos;
	UINT32 frac; // a full 16-bit step plus the retained 12-bit fraction
} cps3_voice;

typedef struct {
	cps3_voice voice[CPS3_VOICES];
	UINT16 key;

	UINT8 * rombase;
	
	double gain[2];
	INT32 output_dir[2];

} cps3snd_chip;

static cps3snd_chip * chip;

UINT8 __fastcall cps3SndReadByte(UINT32 addr)
{
	addr &= 0x000003ff;
	bprintf(PRINT_NORMAL, _T("SND Attempt to read byte value of location %8x\n"), addr);
	return 0;
}

UINT16 __fastcall cps3SndReadWord(UINT32 addr)
{
	addr &= 0x000003ff;
	
	if (addr < 0x200)	{
		return chip->voice[addr >> 5].regs[(addr>>1) & 0xf];
	} else
	if (addr == 0x200)	{
		return chip->key;
	} else

	bprintf(PRINT_NORMAL, _T("SND Attempt to read word value of location %8x\n"), addr);
	return 0;
}

UINT32 __fastcall cps3SndReadLong(UINT32 addr)
{
	addr &= 0x000003ff;
	
	bprintf(PRINT_NORMAL, _T("SND Attempt to read long value of location %8x\n"), addr);
	return 0;
}

void __fastcall cps3SndWriteByte(UINT32 addr, UINT8 data)
{
	addr &= 0x000003ff;
	bprintf(PRINT_NORMAL, _T("SND Attempt to write byte value %2x to location %8x\n"), data, addr);
}

void __fastcall cps3SndWriteWord(UINT32 addr, UINT16 data)
{
	addr &= 0x000003ff;
	
	if (addr < 0x200) {
		chip->voice[addr >> 5].regs[(addr>>1) & 0xf] = data;
		//bprintf(PRINT_NORMAL, _T("SND Attempt to write word value %4x to Chip[%02d][%02d] %s\n"), data, addr >> 5, (addr>>2) & 7, (addr & 0x02) ? "lo" : "hi" );
	} else
	if (addr == 0x200) {
		UINT16 key = data;
		for (INT32 i = 0; i < CPS3_VOICES; i++) {
			// Key off -> Key on
			if ((key & (1 << i)) && !(chip->key & (1 << i)))	{
				chip->voice[i].frac = 0;
				chip->voice[i].pos = 0;
			}
		}
		chip->key = key;
	} else
		bprintf(PRINT_NORMAL, _T("SND Attempt to write word value %4x to location %8x\n"), data, addr);
	
}

void __fastcall cps3SndWriteLong(UINT32 addr, UINT32 data)
{
	//addr &= 0x000003ff;
	if (addr == 0x240e0210) return; // NOP (jojoba*)
	bprintf(PRINT_NORMAL, _T("SND Attempt to write long value %8x to location %8x\n"), data, addr);
}

INT32 cps3SndInit(UINT8 * sndrom)
{
	chip = (cps3snd_chip *)BurnMalloc( sizeof(cps3snd_chip) );
	if ( chip ) {
		memset( chip, 0, sizeof(cps3snd_chip) );
		chip->rombase = sndrom;
		
        memset(&cps3Audio, 0, sizeof(cps3Audio));
        cps3Audio.version = CPS3_AUDIO_VERSION;

		chip->gain[BURN_SND_CPS3SND_ROUTE_1] = 1.00;
		chip->gain[BURN_SND_CPS3SND_ROUTE_2] = 1.00;
		chip->output_dir[BURN_SND_CPS3SND_ROUTE_1] = BURN_SND_ROUTE_LEFT;
		chip->output_dir[BURN_SND_CPS3SND_ROUTE_2] = BURN_SND_ROUTE_RIGHT;
		
		return 0;
	}
	return 1;
}

void cps3SndSetRoute(INT32 nIndex, double nVolume, INT32 nRouteDir)
{
	chip->gain[nIndex] = nVolume;
	chip->output_dir[nIndex] = nRouteDir;
}

void cps3SndReset()
{
    // The old reset retained voice registers. Preserve that behaviour and the
    // corresponding native phase/history; init starts a new power-on timeline.
}

void cps3SndExit()
{
	BurnFree( chip );
	memset(&cps3Audio, 0, sizeof(cps3Audio));
}

UINT32 cps3SndStateVersion() { return chip ? CPS3_AUDIO_VERSION : 0; }
UINT32 cps3SndStateSize() { return sizeof(cps3Audio); }
bool cps3SndStateCompatible(const void *data, UINT32 size)
{
    if (!chip || !data || size != sizeof(cps3Audio)) return false;
    Cps3AudioState state;
    memcpy(&state, data, sizeof(state));
    return state.version == CPS3_AUDIO_VERSION && !state.reserved && state.phase < CPS3_AUDIO_FRAME_DEN;
}

void cps3SndUpdate()
{
    const UINT64 initial = cps3Audio.phase;
    const UINT64 elapsed = initial + CPS3_AUDIO_FRAME_NUM;
    const INT32 count = (INT32)(elapsed / CPS3_AUDIO_FRAME_DEN);
    cps3Audio.phase = elapsed % CPS3_AUDIO_FRAME_DEN;
    // At the fixed CPS3 cadence count is 625 or 626. Two historical samples
    // permit continuous causal linear interpolation across frame boundaries.
    INT16 native[628][2] = {};
    memcpy(native, cps3Audio.history, sizeof(cps3Audio.history));
    INT8 *base = (INT8 *)chip->rombase;

    for (INT32 i = 0; i < CPS3_VOICES; i++) {
        if (!(chip->key & (1 << i))) continue;
        cps3_voice *v = &chip->voice[i];
        UINT32 start = ((v->regs[3] << 16) | v->regs[2]) - 0x400000;
        UINT32 end = ((v->regs[11] << 16) | v->regs[10]) - 0x400000;
        UINT32 loop = ((v->regs[9] << 16) | v->regs[7]) - 0x400000;
        UINT32 pos = v->pos, frac = v->frac;
        INT32 left = (INT16)v->regs[15], right = (INT16)v->regs[14];
        for (INT32 j = 0; j < count; j++) {
            pos += frac >> 12;
            frac &= 0xfff;
            if (start + pos >= end) {
                if (v->regs[5]) pos = loop - start;
                else break; // retain key latch, as in the inherited chip model
            }
            INT32 sample = base[(start + pos) ^ 1];
            frac += v->regs[6];
            native[j+2][0] = BURN_SND_CLIP(native[j+2][0] + ((sample * right) >> 8));
            native[j+2][1] = BURN_SND_CLIP(native[j+2][1] + ((sample * left) >> 8));
        }
        v->pos = pos;
        v->frac = frac;
    }
    memcpy(cps3Audio.history, native + count, sizeof(cps3Audio.history));

    // Rendering is presentation only. Muted, rollback and runahead frames
    // above advance exactly the same native state, including filter history.
    if (!pBurnSoundOut || nBurnSoundLen <= 0) return;
    const UINT64 denominator = CPS3_AUDIO_FRAME_DEN * (UINT32)nBurnSoundLen;
    UINT64 at = initial * (UINT32)nBurnSoundLen;
    for (INT32 j = 0; j < nBurnSoundLen; j++, at += CPS3_AUDIO_FRAME_NUM) {
        const UINT32 index = (UINT32)(at / denominator);
        const UINT64 fraction = at % denominator;
        INT32 channel[2];
        for (INT32 c = 0; c < 2; c++) {
            const INT64 a = native[index][c], b = native[index+1][c];
            channel[c] = (INT32)(a + (b-a) * (INT64)fraction / (INT64)denominator);
        }
        INT32 left = 0, right = 0;
        for (INT32 route = 0; route < 2; route++) {
            INT32 value = (INT32)(channel[1-route] * chip->gain[route]);
            if (chip->output_dir[route] & BURN_SND_ROUTE_LEFT) left += value;
            if (chip->output_dir[route] & BURN_SND_ROUTE_RIGHT) right += value;
        }
        pBurnSoundOut[j*2] = BURN_SND_CLIP(right);
        pBurnSoundOut[j*2+1] = BURN_SND_CLIP(left);
    }
}

INT32 cps3SndScan(INT32 nAction)
{
	if (nAction & ACB_DRIVER_DATA) {
		
		SCAN_VAR( chip->voice );
		SCAN_VAR( chip->key );
		SCAN_VAR( cps3Audio );
		
	}
	return 0;
}

