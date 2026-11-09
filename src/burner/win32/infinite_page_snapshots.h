// Internal CRAM page ownership adapter. Canonical state/replay bytes do not
// change. Only an explicitly capable bridge can receive the opaque envelope.
#include "page_store.h"
#include <stdlib.h>
extern "C" bool InfiniteCramTracking(void*,void(*)(unsigned,unsigned,unsigned));
extern "C" void InfiniteCramTrackingRebase();
struct QuarkPageOwner {
    QuarkPageOwner* next;unsigned char* buffer;PvHandle handle;
    int bytes,canonical,prefix,suffix,driver;UINT32 timing,audio,layout;
    unsigned long long generation;
};
static PvStore* quarkPages;
static QuarkPageOwner* quarkPageOwners;
static void* quarkPageCram;
static bool quarkPagesClosed,quarkPagesRestoring;
static unsigned long long quarkPageGeneration=1,quarkPageSaves,quarkPageLoads,quarkPageExports,quarkPageFallbacks;
#ifdef INFINITE_CRAM_CRC_TEST_EXPORTS
static bool quarkPageManualTest;
#endif
static const unsigned quarkPageEnvelope=32;
static QuarkPageOwner* QuarkPageFind(const void* p){
    for(auto n=quarkPageOwners;n;n=n->next)if(n->buffer==p)return n;
    return NULL;
}
static void QuarkPageChanged(unsigned off,unsigned bytes,unsigned kind){
    if(!quarkPages||quarkPagesClosed)return;
    if(kind==5){pv_end_session(quarkPages);quarkPagesClosed=true;return;}
    if(kind==4&&quarkPagesRestoring)return;
    // All caller offsets/widths are the existing physical store expressions.
    if(pv_mark(quarkPages,off,bytes)!=PV_OK)ExitProcess(186);
}
static bool QuarkPagesWanted(){
    const char* option=getenv("INFINITE_CRAM_PAGES");
    if((option&&strcmp(option,"1"))||!quarkPageGeneration||InfiniteMenuRunAheadFrames()!=0||!QuarkTimingVersion())return false;
#ifdef INFINITE_CRAM_CRC_TEST_EXPORTS
    if(quarkPageManualTest)return true;
#endif
    typedef int (__cdecl *VersionFn)();
    auto version=hGgpoLib?(VersionFn)GetProcAddress(hGgpoLib,"InfiniteSnapshotConsumerVersion"):NULL;
    return version&&version()==1;
}
static bool QuarkPageEnvelopeValid(QuarkPageOwner* n,int length){
    if(!n||length!=n->bytes)return false;
    UINT32 expected[8]={0x31565049,quarkPageEnvelope,UINT32(n->handle),UINT32(n->handle>>32),
        UINT32(n->generation),UINT32(n->generation>>32),UINT32(n->canonical),n->layout};
    return !memcmp(n->buffer,expected,sizeof(expected));
}
extern "C" __declspec(dllexport) int __cdecl InfiniteSnapshotCanonicalSize(const void* data,int bytes){
    auto n=QuarkPageFind(data);return n?(QuarkPageEnvelopeValid(n,bytes)?n->canonical:-1):0;
}
extern "C" __declspec(dllexport) int __cdecl InfiniteSnapshotPrefix(const void* data,int bytes,const void** out,int* length){
    auto n=QuarkPageFind(data);if(!out||!length||!QuarkPageEnvelopeValid(n,bytes))return 1;
    *out=n->buffer+quarkPageEnvelope;*length=n->prefix;return 0;
}
extern "C" __declspec(dllexport) int __cdecl InfiniteSnapshotMaterialize(const void* data,int bytes,void* out,int length){
    auto n=QuarkPageFind(data);if(!out||!QuarkPageEnvelopeValid(n,bytes)||length!=n->canonical)return 1;
    uintptr_t a=(uintptr_t)out,b=(uintptr_t)n->buffer;
    if(a>UINTPTR_MAX-unsigned(length)||(a<b+unsigned(n->bytes)&&b<a+unsigned(length)))return 2;
    b=(uintptr_t)quarkPageCram;
    if(b&&a<b+PV_CRAM_BYTES&&b<a+unsigned(length))return 2;
    for(auto other=quarkPageOwners;other;other=other->next){
        b=(uintptr_t)other->buffer;if(a<b+unsigned(other->bytes)&&b<a+unsigned(length))return 2;
    }
    unsigned char* dest=(unsigned char*)out;
    // Validate/materialize the owned CRAM handle before any other output copy.
    if(pv_materialize(quarkPages,n->handle,dest+n->prefix,PV_CRAM_BYTES)!=PV_OK)return 3;
    memcpy(dest,n->buffer+quarkPageEnvelope,n->prefix);
    memcpy(dest+n->prefix+PV_CRAM_BYTES,n->buffer+quarkPageEnvelope+n->prefix,n->suffix);
    ++quarkPageExports;return 0;
}
static int quarkPageScanAt,quarkPageScanFull;
static unsigned char* quarkPageScanPointer;
static bool quarkPageScanWrite;
static INT32 __cdecl QuarkPageScanAcb(BurnArea* area){
    if(area->nLen<0||area->nLen>quarkPageScanFull-quarkPageScanAt){nQuarkScanError=1;return 1;}
    if(quarkPageScanAt==ggpo_state_header_size+nQuarkCramOffset){
        if(area->Data!=nQuarkCramData||area->nLen!=PV_CRAM_BYTES||!area->szName||strcmp(area->szName,"Sprite ROM")){nQuarkScanError=1;return 1;}
    }else{
        if(quarkPageScanWrite)InfiniteStateCopy(area->Data,quarkPageScanPointer,area->nLen);
        else InfiniteStateCopy(quarkPageScanPointer,area->Data,area->nLen);
        quarkPageScanPointer+=area->nLen;
    }
    quarkPageScanAt+=area->nLen;return 0;
}
static bool QuarkPageScan(QuarkPageOwner* n,bool writing){
    quarkPageScanPointer=n->buffer+quarkPageEnvelope+ggpo_state_header_size;
    quarkPageScanAt=ggpo_state_header_size;quarkPageScanFull=n->canonical;quarkPageScanWrite=writing;
    nQuarkScanError=0;auto old=BurnAcb;BurnAcb=QuarkPageScanAcb;
    BurnAreaScan(QuarkScanFlags()|(writing?ACB_WRITE:ACB_READ),NULL);BurnAcb=old;
    return !nQuarkScanError&&quarkPageScanAt==n->canonical&&quarkPageScanPointer==n->buffer+n->bytes;
}
#ifdef INFINITE_CRAM_CRC_QA
static void QuarkPageVerify(QuarkPageOwner* n,UINT32 expected){
    unsigned char* materialized=(unsigned char*)malloc(n->canonical);
    unsigned char* full=(unsigned char*)malloc(n->canonical);
    if(!materialized||!full)ExitProcess(187);
    if(InfiniteSnapshotMaterialize(n->buffer,n->bytes,materialized,n->canonical))ExitProcess(188);
    memcpy(full,n->buffer+quarkPageEnvelope,ggpo_state_header_size);
    gAcbScanStart=gAcbScanPointer=(char*)full+ggpo_state_header_size;
    nQuarkSaveCrc=InfiniteCrc32(0,full,ggpo_state_header_size);
    auto old=BurnAcb;BurnAcb=QuarkReadAcb;BurnAreaScan(QuarkScanFlags()|ACB_READ,NULL);BurnAcb=old;
    if(memcmp(full,materialized,n->canonical)||expected!=UINT32(crc32(0,full,n->canonical))||expected!=nQuarkSaveCrc)ExitProcess(189);
    free(full);free(materialized);
}
#endif
static bool QuarkTrySavePages(unsigned char** buffer,int* length,int* checksum){
    if(!QuarkPagesWanted()||nQuarkCramOffset<0||!nQuarkCramData)return false;
    if(quarkPagesClosed)return false;
    if(!quarkPages){
        PvConfig config={};config.live_cram=(unsigned char*)nQuarkCramData;
        if(pv_create(&config,&quarkPages)!=PV_OK){++quarkPageFallbacks;return false;}
        quarkPageCram=nQuarkCramData;
        if(!InfiniteCramTracking(quarkPageCram,QuarkPageChanged)){pv_destroy(quarkPages);quarkPages=NULL;return false;}
    }
    if(quarkPageCram!=nQuarkCramData)return false;
    auto n=(QuarkPageOwner*)calloc(1,sizeof(QuarkPageOwner));if(!n){++quarkPageFallbacks;return false;}
    n->canonical=ggpo_state_header_size+nQuarkPayloadSize;n->prefix=ggpo_state_header_size+nQuarkCramOffset;
    n->suffix=n->canonical-n->prefix-PV_CRAM_BYTES;n->bytes=n->canonical-PV_CRAM_BYTES+quarkPageEnvelope;
    n->timing=QuarkTimingVersion();n->audio=cps3SndStateVersion();n->layout=QuarkLayoutTag();n->driver=nBurnDrvActive;n->generation=quarkPageGeneration;
    n->buffer=quarkSnapshotPool.Acquire(n->bytes,n->timing,n->audio,n->layout);
    if(!n->buffer){free(n);++quarkPageFallbacks;return false;}
    UINT32 canonicalHeader[6]={'GGPO',ggpo_state_header_size,INFINITE_NET_VERSION,0,n->timing,n->layout};
    memcpy(n->buffer+quarkPageEnvelope,canonicalHeader,sizeof(canonicalHeader));
    UINT32 cram=0;
    if(!QuarkPageScan(n,false)||pv_save(quarkPages,NULL,NULL,&n->handle,&cram)!=PV_OK){
        quarkSnapshotPool.Release(n->buffer,false);free(n);++quarkPageFallbacks;nQuarkScanError=0;return false;
    }
    UINT32 envelope[8]={0x31565049,quarkPageEnvelope,UINT32(n->handle),UINT32(n->handle>>32),
        UINT32(n->generation),UINT32(n->generation>>32),UINT32(n->canonical),n->layout};
    memcpy(n->buffer,envelope,sizeof(envelope));
    UINT32 crc=InfiniteCrc32(0,n->buffer+quarkPageEnvelope,n->prefix);
    crc=UINT32(crc32_combine(crc,cram,PV_CRAM_BYTES));
    crc=InfiniteCrc32(crc,n->buffer+quarkPageEnvelope+n->prefix,n->suffix);
    n->next=quarkPageOwners;quarkPageOwners=n;
#ifdef INFINITE_CRAM_CRC_QA
    QuarkPageVerify(n,crc);
#endif
    *buffer=n->buffer;*length=n->bytes;*checksum=INT32(crc);bQuarkStateSaved=true;++quarkPageSaves;return true;
}
static const unsigned char* QuarkPageField(QuarkPageOwner* n,int offset,unsigned size){
    if(offset<0||size>unsigned(n->canonical)||unsigned(offset)>unsigned(n->canonical)-size)return NULL;
    if(offset<n->prefix){if(size>unsigned(n->prefix-offset))return NULL;}
    else{if(offset<n->prefix+PV_CRAM_BYTES)return NULL;offset-=PV_CRAM_BYTES;}
    return n->buffer+quarkPageEnvelope+offset;
}
static bool QuarkLoadPages(QuarkPageOwner* n,int length){
    if(!QuarkPageEnvelopeValid(n,length)||quarkPagesClosed||n->generation!=quarkPageGeneration||
        n->driver!=int(nBurnDrvActive)||n->timing!=QuarkTimingVersion()||n->audio!=cps3SndStateVersion()||n->layout!=QuarkLayoutTag()||
        n->canonical!=ggpo_state_header_size+nQuarkPayloadSize||n->prefix!=ggpo_state_header_size+nQuarkCramOffset||quarkPageCram!=nQuarkCramData)return false;
    UINT32 data[6];memcpy(data,n->buffer+quarkPageEnvelope,sizeof(data));
    if(data[0]!='GGPO'||data[1]!=ggpo_state_header_size||data[2]!=INFINITE_NET_VERSION||data[4]!=n->timing||data[5]!=n->layout)return false;
    const unsigned char* timing=QuarkPageField(n,ggpo_state_header_size+nQuarkTimingOffset,4);
    UINT32 version=0;if(!timing)return false;memcpy(&version,timing,4);if(version!=n->timing)return false;
    if(n->audio){
        const unsigned char* audio=QuarkPageField(n,ggpo_state_header_size+nQuarkAudioOffset,cps3SndStateSize());
        if(nQuarkAudioOffset<0||!audio||!cps3SndStateCompatible(audio,cps3SndStateSize()))return false;
    }else if(nQuarkAudioOffset>=0)return false;
    if(pv_restore(quarkPages,n->handle,NULL,NULL)!=PV_OK)return false;
    InfiniteCramTrackingRebase();quarkPagesRestoring=true;bool ok=QuarkPageScan(n,true);quarkPagesRestoring=false;
    if(!ok)ExitProcess(190); // layout was preflighted; never continue a partial load
    ++quarkPageLoads;++nRollbackCount;return true;
}
static void QuarkFreePages(void* buffer){
    QuarkPageOwner** link=&quarkPageOwners;
    while(*link){auto n=*link;if(n->buffer==buffer){
        if(pv_free(quarkPages,n->handle)!=PV_OK)ExitProcess(191);
        *link=n->next;free(n);return;
    }link=&n->next;}
}
static void QuarkClosePages(){
    if(!quarkPages)return;
    PvStats stats={};pv_stats(quarkPages,&stats);
    FILE*f=getenv("INFINITE_PAGE_STATS")?fopen("page_snapshot_stats.json","w"):NULL;
    if(f){fprintf(f,"{\"saves\":%llu,\"loads\":%llu,\"exports\":%llu,\"fallbacks\":%llu,\"owners_at_close\":%llu,\"peak_store_bytes\":%llu,\"page_saves\":%llu,\"full_fallback_saves\":%llu,\"restored_pages\":%llu}\n",
        quarkPageSaves,quarkPageLoads,quarkPageExports,quarkPageFallbacks,stats.owners,stats.peak_allocated_bytes,stats.save_pages,stats.save_full,stats.restored_pages);fclose(f);}
    if(quarkPageOwners||stats.owners)ExitProcess(192);
    if(!quarkPagesClosed)InfiniteCramTracking(quarkPageCram,NULL);
    if(pv_destroy(quarkPages)!=PV_OK)ExitProcess(193);
    quarkPages=NULL;quarkPageCram=NULL;quarkPagesClosed=false;++quarkPageGeneration;
}
