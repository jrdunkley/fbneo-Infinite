/* CPS3 P1/P2 timing candidate, 2026-10-15. Local research modifications.
 * Evidence: board_probe_20261011/RESULTS_return2.txt; the CRC-pinned P2 return;
 * cps3_p2_emulator_20261015/test_p2_core.py runs all 185 exact CPU tests.
 * TIMING SHADOW only: cache payload/coherency is deliberately unchanged.
 * Effective refill constraints remain 20/36/112 clocks. P2 adds shared MAC
 * issue interlocks, separate issue/result deadlines and RAM write/read handoff.
 * The long-product 5/6-clock fetch phase and 3-clock RAM handoff are bounded
 * candidate constraints, not a uniquely identified physical pipeline/BSC.
 * Remaining copy, peripheral phase and RAM-spacing errors stay explicit.
 * No new DMA duration, display latch or ambiguous RAM-fetch behavior is inferred.
 * Every evolving deadline/valid flag is pointer-free and serialized below.
 * 0x20261016: FRT compare-match A clear period OCRA + 1 (manual Figure 11.7, sh2.cpp
 * BoardTimerDistances) and no periodic IRQ10 (cps3run.cpp; board review s2.4/s3.2).
 * 0x20261017: the frame's carried overshoot no longer advances the CPU clock a second time
 * (Sh2CarryCycles): the FRT-visible frame is the driver's 419,466 clocks, not 419,466 plus
 * the mean overshoot (P2 vblank_free_running measured 52,436.9 ticks before, 52,433.24 after).
 */
#ifndef CPS3_TIMING_H
#define CPS3_TIMING_H
#if defined(__SSE2__)
#include <emmintrin.h>
#endif
#define CPS3_TIMING_VERSION 0x20261017u
struct Cps3Timing {
    UINT32 version;
    UINT32 tag[64][4];
    UINT8 valid[64], lru[64];
    // A deadline may wrap to zero: read_pending is the validity bit.
    UINT32 read_ready_until;
    // Multiply issue occupancy and result availability are distinct.
    UINT32 write_until, multiply_until, multiply_result_until;
    INT32 read_pending;
    INT32 write_pending, multiply_pending, previous_memory, previous_load;
    UINT8 temp;
    UINT8 reserved[3];
};
static Cps3Timing boardTiming;
static bool boardExecuting = false;
static bool boardException = false;

static void BoardCharge(INT32 cycles) {
    if (cycles <= 0) return;
    if (boardExecuting) sh2->sh2_icount -= cycles;
    else sh2->cycle_counts += cycles;
    sh2->sh2_total_cycles += cycles;
}
static void BoardWait(UINT32 until) {
    INT32 left = (INT32)(until - sh2_GetTotalCycles());
    if (left > 0) BoardCharge(left);
}
static void BoardDrain() {
    if (boardTiming.write_pending) BoardWait(boardTiming.write_until);
    boardTiming.write_pending = 0;
    boardTiming.write_until = 0;
}
static void BoardQuiesce() {
    if (boardTiming.read_pending && (INT32)(boardTiming.read_ready_until-sh2_GetTotalCycles())<=0) {
        boardTiming.read_pending=0; boardTiming.read_ready_until=0;
    }
    if (boardTiming.write_pending && (INT32)(boardTiming.write_until-sh2_GetTotalCycles())<=0) {
        boardTiming.write_pending=0; boardTiming.write_until=0;
    }
    if (boardTiming.multiply_pending && (INT32)(boardTiming.multiply_result_until-sh2_GetTotalCycles())<=0) {
        boardTiming.multiply_pending=0; boardTiming.multiply_until=0; boardTiming.multiply_result_until=0;
    }
}
static void BoardTouch(unsigned set, unsigned way) {
    static const UINT8 keep[4] = { 7, 0x19, 0x2a, 0x34 };
    static const UINT8 bits[4] = { 0, 0x20, 0x14, 0x0b };
    boardTiming.lru[set] = (boardTiming.lru[set] & keep[way]) | bits[way];
}
static int BoardFind(UINT32 address) {
    unsigned set = (address >> 4) & 63;
    UINT32 tag = address & 0x1ffffc00;
#if defined(__SSE2__) && !defined(INFINITE_CPS3_LOOKUP_SCALAR)
    // Host metadata only: compare all four tags, mask invalid ways and choose
    // the lowest matching way exactly as the scalar loop (including ties).
    const __m128i tags = _mm_loadu_si128((const __m128i *)boardTiming.tag[set]);
    const __m128i equal = _mm_cmpeq_epi32(tags, _mm_set1_epi32((int)tag));
    unsigned matches = (unsigned)_mm_movemask_ps(_mm_castsi128_ps(equal)) & boardTiming.valid[set];
    return matches ? __builtin_ctz(matches) : -1;
#else
    for (unsigned w = 0; w < 4; ++w)
        if ((boardTiming.valid[set] & (1 << w)) && boardTiming.tag[set][w] == tag) return w;
    return -1;
#endif
}
static void BoardFill(UINT32 address, UINT8 ccr) {
    unsigned set = (address >> 4) & 63, lru = boardTiming.lru[set], way;
    if (ccr & 8) way = (lru & 1) ? 2 : 3;
    else if ((lru & 0x38) == 0x38) way = 0;
    else if ((lru & 0x26) == 0x06) way = 1;
    else if ((lru & 0x15) == 0x01) way = 2;
    else way = 3;
    boardTiming.tag[set][way] = address & 0x1ffffc00;
    boardTiming.valid[set] |= 1 << way;
    BoardTouch(set, way);
}
static void BoardPurge() {
    memset(boardTiming.valid, 0, sizeof boardTiming.valid);
    memset(boardTiming.lru, 0, sizeof boardTiming.lru);
}

// Integer external bus service hypotheses, kept distinct from CPU issue time.
// P1 cannot identify external WAIT/arbitration phase or general mixed streams.
static INT32 BoardService(UINT32 a, int size, bool write, bool line) {
    const UINT32 p = a & 0x1fffffff;
    if (p < 0x02000000) return line ? 112 : 7 * size; // 8-bit BIOS
    if (p < 0x04000000) return line ? 36 : 4 * ((size + 1) / 2);
    if (p >= 0x06000000) return line ? 20 : 5; // 32-bit program flash
    const int words = (size + 1) / 2;
    if (p >= 0x05040000 && p < 0x05050000) return (write ? 18 : 18) * words;
    if (p >= 0x04080000 && p < 0x040c0000) return 8 * words;
    if (p >= 0x04000000 && p < 0x04080000) return 10 * words;
    if (p >= 0x04100000 && p < 0x04200000) return 20 * words;
    return 4 * words;
}
static void BoardAccess(UINT32 a, int size, bool write, bool fetch = false) {
    if (!boardTiming.version) return;
    if (!fetch) boardTiming.previous_memory = 1;
    const unsigned partition = a >> 29;
    if (partition == 6) return; // on-chip data array: one CPU cycle, no external bus
    if (partition == 2) { // associative purge
        if (write) {
            int w = BoardFind(a);
            if (w >= 0) boardTiming.valid[(a >> 4) & 63] &= ~(1 << w);
            BoardCharge(1);
        }
        return;
    }
    if (partition == 3) return; // address array timing, data still legacy handler
    if (partition == 7) {
        // The measured repeated FRT byte reads take 12 clocks. The manual's
        // 3..12-cycle phase dependence remains unmeasured; use the observed end.
        const UINT32 reg = a & 0x1ff;
        if (reg >= 0x10 && reg <= 0x19) BoardCharge(11);
        else BoardCharge(2);
        boardTiming.previous_memory = 0; // long peripheral stall drains the IF/MA overlap
        return; // on-chip transfers do not drain the BSC write buffer
    }
    UINT8 ccr = (sh2->m[0x24] >> 8) & 0xff;
    const bool cached = partition == 0 && (ccr & 1);
    if (cached) {
        int way = BoardFind(a);
        if (way >= 0) {
            BoardTouch((a >> 4) & 63, way);
            if (!write) return;
        } else if (!write && !(ccr & (fetch ? 2 : 4))) {
            if (boardTiming.read_pending) BoardWait(boardTiming.read_ready_until);
            BoardDrain();
            BoardCharge(BoardService(a,16,false,true));
            BoardFill(a, ccr);
            return;
        }
    }
    if (write) {
        BoardDrain();
        boardTiming.write_until = sh2_GetTotalCycles() + BoardService(a,size,true,false);
        boardTiming.write_pending = 1;
        UINT32 p = a & 0x1fffffff;
        // P2 RAM handoff stays flat through eight independent ADDs. A
        // separate read-ready deadline preserves overlap between stores,
        // cache hits and internal accesses; it is not extra write latency.
        boardTiming.read_pending = (p>=0x02000000 && p<0x04000000);
        boardTiming.read_ready_until = boardTiming.read_pending ? boardTiming.write_until+3 : 0;
        // CPU-visible store keeps existing ordering; only bus occupancy overlaps.
    } else {
        if (boardTiming.read_pending) BoardWait(boardTiming.read_ready_until);
        BoardDrain();
        BoardCharge(BoardService(a,fetch ? 4 : size,false,false));
        // RAM's 16-bit read path has an additional acquisition clock. P1 does
        // not resolve the residual width-dependent arbitration/refresh cost.
        UINT32 p = a & 0x1fffffff;
        if (p >= 0x02000000 && p < 0x04000000) BoardCharge(1);
        else if (p < 0x02000000 || p >= 0x06000000 ||
                 !((p >= 0x05040000 && p < 0x05050000) || (p >= 0x04000000 && p < 0x04080000)))
            boardTiming.previous_memory = 0;
    }
}

static unsigned BoardUses(UINT16 op) {
    unsigned n=(op>>8)&15, m=(op>>4)&15, N=1u<<n, M=1u<<m;
    switch(op>>12) {
    case 0:
        switch(op&15) {
        case 4: case 5: case 6: return N|M|1;
        case 7: case 15: return N|M;
        case 3: return N;
        case 12: case 13: case 14: return M|1;
        case 11: return op==0x002b ? 1u<<15 : 0;
        } return 0;
    case 1: case 2: case 3: return N|M;
    case 4: return (op&15)==15 ? N|M : N;
    case 5: case 6: return M;
    case 7: return N;
    case 8:
        switch((op>>8)&15) { case 0: case 1:return M|1; case 4:case 5:return M;case 8:return 1; } return 0;
    case 12:
        switch((op>>8)&15) {case 0:case 1:case 2:case 8:case 9:case 10:case 11:case 12:case 13:case 14:case 15:return 1;} return 0;
    } return 0;
}
static int BoardLoadDestination(UINT16 op) {
    int n=(op>>8)&15;
    switch(op>>12) {
    case 0: return (op&15)>=12 && (op&15)<=14 ? n : -1;
    case 5: return n;
    case 6: return (op&15)<=2 || ((op&15)>=4 && (op&15)<=6) ? n : -1;
    case 8: return ((op>>8)&15)==4 || ((op>>8)&15)==5 ? 0 : -1;
    case 9:case 13:return n;
    case 12:return ((op>>8)&15)>=4 && ((op>>8)&15)<=6 ? 0 : -1;
    } return -1;
}
// Immutable instruction properties, derived from the original decode below.
// These are host acceleration data, never emulated state or savestate contents.
struct BoardOpcodeInfo { UINT16 uses; INT8 load; UINT8 multiply; };
static BoardOpcodeInfo boardOpcodeInfo[65536];
static bool boardOpcodesReady = false;
static void BoardPrepareOpcodes() {
    if (boardOpcodesReady) return;
    for (unsigned op=0; op<65536; ++op) {
        BoardOpcodeInfo &info=boardOpcodeInfo[op];
        info.uses=(UINT16)BoardUses((UINT16)op);
        info.load=(INT8)BoardLoadDestination((UINT16)op);
        bool mul32=(op&0xf00f)==0x0007 || (op&0xf007)==0x3005;
        bool mul16=(op&0xf00e)==0x200e;
        bool macRead=(op&0xf0ff)==0x000a || (op&0xf0ff)==0x001a || (op&0xf0ff)==0x4002 || (op&0xf0ff)==0x4012;
        info.multiply=mul32 ? 4 : mul16 ? 2 : macRead ? 1 : 0;
    }
    boardOpcodesReady=true;
}

static inline void BoardInstructionFetch(UINT32 pc) {
    // The generic access path returns immediately after touching a cached
    // read hit. Keep that exact common case local to the interpreter loop.
    if ((pc>>29)==0 && (sh2->m[0x24]&0x100)) {
        int way=BoardFind(pc);
        if (way>=0) { BoardTouch((pc>>4)&63,way); return; }
    }
    BoardAccess(pc,2,false,true);
}
static void BoardInstruction(UINT32 pc, UINT16 op) {
    if (!boardTiming.version) return;
    BoardQuiesce();
    // Shared IF/MA cache port and immediate load-use interlock. IF fetches a
    // longword for two instructions; a taken branch already pays pipeline refill.
    if (boardTiming.previous_memory && !(pc&2) && (op>>12)!=10 && (op>>12)!=11) BoardCharge(1);
    else if (boardTiming.previous_load >= 0 && (boardOpcodeInfo[op].uses&(1u<<boardTiming.previous_load))) BoardCharge(1);
    boardTiming.previous_memory=0;
    boardTiming.previous_load=boardOpcodeInfo[op].load;
    BoardInstructionFetch(pc);
    unsigned multiply=boardOpcodeInfo[op].multiply;
    // MAC transfers share the IF/MA issue path. STS to a GPR also has
    // the observed load-like immediate-use interlock (P2 dependency matrix).
    if (multiply) boardTiming.previous_memory=1;
    if ((op&0xf0ff)==0x000a || (op&0xf0ff)==0x001a)
        boardTiming.previous_load=(op>>8)&15;
    if (multiply && boardTiming.multiply_pending) BoardWait(multiply==1 ? boardTiming.multiply_result_until : boardTiming.multiply_until);
    if (multiply>=2) {
        boardTiming.multiply_until=sh2_GetTotalCycles()+multiply;
        // P2 tests distinguish four-clock long-MUL issue occupancy from
        // the 5/6-clock effective result path at the two fetch halfwords.
        // Short MUL keeps its existing two-clock result deadline.
        boardTiming.multiply_result_until=boardTiming.multiply_until+(multiply==4 ? 2-((pc&2) ? 1 : 0) : 0);
        boardTiming.multiply_pending=1;
    }
}
void Sh2SetCps3Timing(INT32 enabled) {
    if (enabled) BoardPrepareOpcodes();
    memset(&boardTiming,0,sizeof boardTiming);
    boardTiming.version=enabled ? CPS3_TIMING_VERSION : 0;
    boardTiming.previous_load=-1;
}
INT32 Sh2GetCps3Timing() { return boardTiming.version != 0; }
UINT32 Sh2Cps3TimingVersion() { return boardTiming.version; }
UINT32 Sh2Cps3TimingStateSize() { return sizeof boardTiming; }
void Sh2Cps3TimingFastBoot() {
    if (!boardTiming.version) return;
    // This driver bypasses the BIOS. Seed only the measured standard-SH2
    // board configuration rather than accidentally running with disabled cache.
    sh2->m[0x24]=0x100; sh2->m[0x78]=0x20; sh2->m[0x79]=0xe8;
    sh2->m[0x7a]=0xaa57; sh2->m[0x7b]=0;
}
#endif
