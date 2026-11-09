#include <stdint.h>

#ifndef FASTCALL
 #undef __fastcall
 #define __fastcall
#endif

typedef unsigned char (__fastcall *pSh2ReadByteHandler)(unsigned int a);
typedef void (__fastcall *pSh2WriteByteHandler)(unsigned int a, unsigned char d);
typedef unsigned short (__fastcall *pSh2ReadWordHandler)(unsigned int a);
typedef void (__fastcall *pSh2WriteWordHandler)(unsigned int a, unsigned short d);
typedef unsigned int (__fastcall *pSh2ReadLongHandler)(unsigned int a);
typedef void (__fastcall *pSh2WriteLongHandler)(unsigned int a, unsigned int d);

extern int has_sh2;
extern INT32 cps3speedhack;

void __fastcall Sh2WriteByte(unsigned int a, unsigned char d);
unsigned char __fastcall Sh2ReadByte(unsigned int a);

int Sh2Init(int nCount);
void Sh2Exit();

void Sh2Open(const int i);
void Sh2Close();
int Sh2GetActive();

void Sh2Reset();
void Sh2Reset(unsigned int pc, unsigned r15); // hack
int Sh2Run(int cycles);

int Sh2MapMemory(unsigned char* pMemory, unsigned int nStart, unsigned int nEnd, int nType);
int Sh2MapHandler(uintptr_t nHandler, unsigned int nStart, unsigned int nEnd, int nType);

int Sh2SetReadByteHandler(int i, pSh2ReadByteHandler pHandler);
int Sh2SetWriteByteHandler(int i, pSh2WriteByteHandler pHandler);
int Sh2SetReadWordHandler(int i, pSh2ReadWordHandler pHandler);
int Sh2SetWriteWordHandler(int i, pSh2WriteWordHandler pHandler);
int Sh2SetReadLongHandler(int i, pSh2ReadLongHandler pHandler);
int Sh2SetWriteLongHandler(int i, pSh2WriteLongHandler pHandler);

void Sh2SetIRQLine(const int line, const int state);
void Sh2SetInstructionHook(void (*hook)(UINT32));
void Sh2SetIrqAssertHook(void (*hook)());
// Local CPS3 timing candidate. Off for every other SH-2 driver.
void Sh2SetCps3Timing(INT32 enabled);
INT32 Sh2GetCps3Timing();
UINT32 Sh2Cps3TimingVersion();
UINT32 Sh2Cps3TimingStateSize();
void Sh2Cps3TimingFastBoot();

// Infinite: exact idle-period skip. Each arrival at `pc` (outside a delay slot, r[reg] == reg_value)
// is compared with the previous arrival in the same Sh2Run. When that fully interpreted period left
// the CPU state and RAM unchanged, except a 32-bit counter (written once by counter_writer, read only
// by counter_readers, previous value >= counter_min), every later period repeats it. Whole periods
// are then credited without interpretation, stopping before the end of the run and before any
// on-chip timer or DMA event. Any other access, an interrupt or the end of the run cancels.
struct Sh2IdleSkip {
	UINT32 pc;
	INT32 reg;
	UINT32 reg_value;
	UINT8 *ram;                     // mapped MAP_RAM at ram_base
	UINT32 ram_base, ram_size;
	UINT32 rom_base, rom_size;      // reads here have no side effects
	UINT32 counter, counter_min, counter_writer, counter_readers[3];
	INT32 (*allow)();               // optional veto, asked before each skip
};
void Sh2SetIdleSkip(const Sh2IdleSkip *skip);   // NULL: off

unsigned int Sh2GetPC(int n);
void Sh2StopRun();
void Sh2SetVBR(unsigned int i);

void Sh2BurnUntilInt(int);

INT32 Sh2TotalCycles();
void Sh2NewFrame();
void Sh2BurnCycles(int cycles);
void Sh2Idle(int cycles);
void Sh2CarryCycles(int cycles);
void Sh2SetEatCycles(int i);

int Sh2Scan(int);


void Sh2CheatWriteByte(UINT32 a, UINT8 d); // cheat core
UINT8 Sh2CheatReadByte(UINT32 a);

extern struct cpu_core_config Sh2Config;

// depreciate this and use BurnTimerAttach directly!
#define BurnTimerAttachSh2(clock)	\
	BurnTimerAttach(&Sh2Config, clock)
