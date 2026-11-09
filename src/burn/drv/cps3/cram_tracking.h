// Exact actual-store interception, shared with the audited T-0245 writer gate.
// The observer is process-local host metadata; never part of emulated state.
#include <string.h>
#include <stdio.h>
#ifdef INFINITE_CRAM_CRC_QA
#include <windows.h>
#endif
static void bankswitch_cram();
typedef void (*CramObserver)(unsigned,unsigned,unsigned);
static CramObserver cramObserver;
static bool cramTrackingActive;
#ifdef INFINITE_CRAM_CRC_QA
static unsigned char cramShadow[0x800000];
static unsigned long long cramChecks,cramWrites;
static void CramFail(const char* why,unsigned off){
    FILE*f=fopen("cram_page_failure.json","w");
    if(f){fprintf(f,"{\"reason\":\"%s\",\"offset\":%u}\n",why,off);fclose(f);}
    ExitProcess(183);
}
static void CramCheck(){
    if(!cramTrackingActive)return;++cramChecks;
    if(memcmp(cramShadow,RamCRam,sizeof(cramShadow))){
        unsigned n=0;while(n<sizeof(cramShadow)&&cramShadow[n]==((unsigned char*)RamCRam)[n])++n;
        CramFail("untracked_write",n);
    }
}
#else
static inline void CramCheck(){}
#endif
static inline void CramMark(unsigned off,unsigned bytes,unsigned kind){
    if(!cramTrackingActive)return;
#ifdef INFINITE_CRAM_CRC_QA
    if(!bytes||off>=0x800000||bytes>0x800000-off)CramFail("writer_outside_cram",off);
    ++cramWrites;
#endif
    cramObserver(off,bytes,kind);
}
static inline void CramStoreByte(unsigned off,UINT8 value,unsigned kind){
    CramMark(off,1,kind);((UINT8*)RamCRam)[off]=value;
#ifdef INFINITE_CRAM_CRC_QA
    if(cramTrackingActive)cramShadow[off]=value;
#endif
}
static void __fastcall CramWriteByte(UINT32 a,UINT8 value){
    unsigned off=(cram_bank<<20)+(a&0xfffff);
#ifdef LSB_FIRST
    off^=3;
#endif
    CramStoreByte(off,value,0);
}
static void __fastcall CramWriteWord(UINT32 a,UINT16 value){
    unsigned off=(cram_bank<<20)+(a&0xfffff);
#ifdef LSB_FIRST
    off^=2;
#endif
    CramMark(off,2,0);memcpy((UINT8*)RamCRam+off,&value,2);
#ifdef INFINITE_CRAM_CRC_QA
    if(cramTrackingActive)memcpy(cramShadow+off,&value,2);
#endif
}
static void __fastcall CramWriteLong(UINT32 a,UINT32 value){
    unsigned off=(cram_bank<<20)+(a&0xfffff);
    CramMark(off,4,0);memcpy((UINT8*)RamCRam+off,&value,4);
#ifdef INFINITE_CRAM_CRC_QA
    if(cramTrackingActive)memcpy(cramShadow+off,&value,4);
#endif
}
extern "C" void InfiniteCramTrackingRebase(){
#ifdef INFINITE_CRAM_CRC_QA
    if(cramTrackingActive)memcpy(cramShadow,RamCRam,sizeof(cramShadow));
#endif
}
static void CramImported(){
    if(cramTrackingActive)cramObserver(0,0x800000,4);
    InfiniteCramTrackingRebase();
}
extern "C" bool InfiniteCramTracking(void* data,CramObserver observer){
    if(data!=RamCRam||!Sh2Cps3TimingVersion())return false;
    CramCheck();cramObserver=observer;cramTrackingActive=observer!=NULL;
    InfiniteCramTrackingRebase();bankswitch_cram();return true;
}
static void CramTrackingExit(){
    CramCheck();if(cramTrackingActive)cramObserver(0,0,5);
    cramTrackingActive=false;cramObserver=NULL;
#ifdef INFINITE_CRAM_CRC_QA
    FILE*f=fopen("cram_page_shadow.json","w");
    if(f){fprintf(f,"{\"checks\":%llu,\"writes\":%llu}\n",cramChecks,cramWrites);fclose(f);}
#endif
}
