#include "page_store.h"
#include "infinite_crc32.h"
#include <cstring>
#include <cstdlib>
#include <climits>
#include <new>

namespace {
const unsigned N=PV_PAGE_COUNT, P=PV_PAGE_BYTES, B=PV_CRAM_BYTES;
struct Page { uint64_t refs; unsigned char bytes[P]; };
struct Table { uint64_t refs; Page* pages[N]; uint32_t crc[N*2]; };
struct Snapshot {
    Snapshot *previous, *next;
    uint64_t id, generation;
    Table* table; // NULL is a complete-copy fallback; bytes follow extras.
    size_t allocation_bytes;
    uint32_t crc;
    unsigned char* extras() { return reinterpret_cast<unsigned char*>(this+1); }
    const unsigned char* extras() const { return reinterpret_cast<const unsigned char*>(this+1); }
};
// Never reused within this process, even across store destruction/recreation.
uint64_t next_handle=1;
bool handles_exhausted=false;
void* default_allocate(void*,size_t n,PvAllocation) { return std::malloc(n); }
void default_deallocate(void*,void* p,size_t,PvAllocation) { std::free(p); }
bool span(const void* p,size_t n) {
    return !n || (p && n<=UINTPTR_MAX-reinterpret_cast<uintptr_t>(p));
}
bool overlap(const void* a,size_t an,const void* b,size_t bn) {
    if(!an || !bn) return false;
    uintptr_t av=reinterpret_cast<uintptr_t>(a), bv=reinterpret_cast<uintptr_t>(b);
    return av<bv+bn && bv<av+an;
}
}

struct PvStore {
    PvConfig config;
    PvStats stats;
    Table* anchor;
    Snapshot* owners;
    unsigned char dirty[N];
    unsigned char level[N];
    // Same exact shift algebra as review/crc_tree.cpp. Initialized per store;
    // no global lazy initialization or hidden allocation.
    uint32_t shift[11][4][256];
};

namespace {
void* allocate(PvStore* s,size_t n,PvAllocation kind) {
    void* p=s->config.allocate(s->config.allocator_context,n,kind);
    if(p) {
        s->stats.allocated_bytes[kind]+=n;s->stats.total_allocated_bytes+=n;
        if(s->stats.total_allocated_bytes>s->stats.peak_allocated_bytes)
            s->stats.peak_allocated_bytes=s->stats.total_allocated_bytes;
    }
    return p;
}
void deallocate(PvStore* s,void* p,size_t n,PvAllocation kind) {
    if(!p) return;
    s->stats.allocated_bytes[kind]-=n;s->stats.total_allocated_bytes-=n;
    s->config.deallocate(s->config.allocator_context,p,n,kind);
}
void release_table(PvStore* s,Table* t) {
    if(!t || --t->refs) return;
    for(unsigned i=0;i<N;++i) if(t->pages[i] && !--t->pages[i]->refs) {
        deallocate(s,t->pages[i],sizeof(Page),PV_ALLOC_PAGE);--s->stats.page_versions;
    }
    deallocate(s,t,sizeof(Table),PV_ALLOC_TABLE);--s->stats.page_tables;
}
void abandon_anchor(PvStore* s) { release_table(s,s->anchor);s->anchor=NULL; }
void all_dirty(PvStore* s) { std::memset(s->dirty,1,N);s->stats.dirty_pages=N; }
Snapshot* find(PvStore* s,PvHandle h) {
    for(Snapshot* p=s->owners;p;p=p->next) if(p->id==h) return p;
    return NULL;
}
bool inputs(PvStore* s,const void* p,const void* q) {
    return span(p,s->config.prefix_bytes)&&span(q,s->config.suffix_bytes);
}
bool outputs(PvStore* s,void* p,void* q) {
    size_t a=s->config.prefix_bytes,b=s->config.suffix_bytes;
    return inputs(s,p,q)&&!overlap(p,a,q,b)&&
        !overlap(p,a,s->config.live_cram,B)&&!overlap(q,b,s->config.live_cram,B);
}
uint32_t combine(PvStore* s,unsigned l,uint32_t a,uint32_t b) {
    return s->shift[l][0][a&255]^s->shift[l][1][(a>>8)&255]^
        s->shift[l][2][(a>>16)&255]^s->shift[l][3][a>>24]^b;
}
uint32_t full_crc(PvStore* s,uint32_t cram,const void* p,const void* q) {
    uint32_t c=s->config.prefix_bytes?InfiniteCrc32(0,static_cast<const unsigned char*>(p),unsigned(s->config.prefix_bytes)):0;
    c=uint32_t(crc32_combine(c,cram,B));
    if(s->config.suffix_bytes)c=InfiniteCrc32(c,static_cast<const unsigned char*>(q),unsigned(s->config.suffix_bytes));
    return c;
}
void make_tree(PvStore* s,uint32_t* tree) {
    unsigned char dirty[N*2]={};
    if(s->anchor) std::memcpy(tree,s->anchor->crc,N*2*sizeof(uint32_t));
    else std::memset(tree,0,N*2*sizeof(uint32_t));
    for(unsigned p=0;p<N;++p) if(s->dirty[p] || !s->anchor) {
        tree[p+N]=InfiniteCrc32(0,s->config.live_cram+p*P,P);
        for(unsigned i=(p+N)>>1;i;i>>=1)dirty[i]=1;
    }
    for(unsigned i=N-1;i;--i)if(dirty[i])tree[i]=combine(s,s->level[i],tree[i*2],tree[i*2+1]);
}
Table* stage_table(PvStore* s) {
    Table* t=static_cast<Table*>(allocate(s,sizeof(Table),PV_ALLOC_TABLE));
    if(!t) return NULL;
    std::memset(t,0,sizeof(*t));t->refs=1;++s->stats.page_tables;
    for(unsigned i=0;i<N;++i) {
        if(s->dirty[i] || !s->anchor) {
            uint64_t cap=s->config.page_payload_limit;
            if(cap && (cap<P || s->stats.page_versions>=cap/P)) { release_table(s,t);return NULL; }
            Page* p=static_cast<Page*>(allocate(s,sizeof(Page),PV_ALLOC_PAGE));
            if(!p) { release_table(s,t);return NULL; }
            p->refs=1;std::memcpy(p->bytes,s->config.live_cram+i*P,P);
            t->pages[i]=p;++s->stats.page_versions;
        } else { t->pages[i]=s->anchor->pages[i];++t->pages[i]->refs; }
    }
    make_tree(s,t->crc);
    return t;
}
Snapshot* stage_snapshot(PvStore* s,const void* prefix,const void* suffix,bool full) {
    size_t extras=s->config.prefix_bytes+s->config.suffix_bytes;
    size_t size=sizeof(Snapshot)+extras+(full?B:0);
    Snapshot* p=static_cast<Snapshot*>(allocate(s,size,full?PV_ALLOC_FULL:PV_ALLOC_HANDLE));
    if(!p) return NULL;
    std::memset(p,0,sizeof(*p));p->allocation_bytes=size;
    if(s->config.prefix_bytes)std::memcpy(p->extras(),prefix,s->config.prefix_bytes);
    if(s->config.suffix_bytes)std::memcpy(p->extras()+s->config.prefix_bytes,suffix,s->config.suffix_bytes);
    return p;
}
void destroy_snapshot(PvStore* s,Snapshot* p) {
    bool full=!p->table;
    if(!full)release_table(s,p->table);
    else --s->stats.full_snapshots;
    deallocate(s,p,p->allocation_bytes,full?PV_ALLOC_FULL:PV_ALLOC_HANDLE);
}
void copy_extras(PvStore* s,Snapshot* p,void* prefix,void* suffix) {
    if(s->config.prefix_bytes)std::memcpy(prefix,p->extras(),s->config.prefix_bytes);
    if(s->config.suffix_bytes)std::memcpy(suffix,p->extras()+s->config.prefix_bytes,s->config.suffix_bytes);
}
}

extern "C" {
PvResult pv_create(const PvConfig* c,PvStore** out) {
    if(!out || !c || !span(c->live_cram,B) || !c->live_cram ||
       c->prefix_bytes>UINT_MAX || c->suffix_bytes>UINT_MAX ||
       c->prefix_bytes>SIZE_MAX-sizeof(Snapshot)-B ||
       c->suffix_bytes>SIZE_MAX-sizeof(Snapshot)-B-c->prefix_bytes ||
       bool(c->allocate)!=bool(c->deallocate))return PV_ARGUMENT;
    PvConfig cfg=*c;
    if(!cfg.allocate) { cfg.allocate=default_allocate;cfg.deallocate=default_deallocate; }
    void* memory=cfg.allocate(cfg.allocator_context,sizeof(PvStore),PV_ALLOC_STORE);
    if(!memory)return PV_NOMEM;
    PvStore* s=new(memory) PvStore();s->config=cfg;
    s->stats.generation=1;s->stats.session_open=1;
    s->stats.allocated_bytes[PV_ALLOC_STORE]=sizeof(*s);
    s->stats.total_allocated_bytes=s->stats.peak_allocated_bytes=sizeof(*s);
    all_dirty(s);
    for(unsigned l=0;l<11;++l)for(unsigned b=0;b<4;++b)for(unsigned v=0;v<256;++v)
        s->shift[l][b][v]=uint32_t(crc32_combine(uint32_t(v)<<(b*8),0,P<<l));
    for(unsigned i=N-1;i;--i)s->level[i]=(i*2>=N)?0:s->level[i*2]+1;
    *out=s;return PV_OK;
}
PvResult pv_destroy(PvStore* s) {
    if(!s)return PV_ARGUMENT;
    if(s->owners)return PV_BUSY;
    abandon_anchor(s);
    PvConfig cfg=s->config;s->~PvStore();
    cfg.deallocate(cfg.allocator_context,s,sizeof(PvStore),PV_ALLOC_STORE);return PV_OK;
}
PvResult pv_end_session(PvStore* s) {
    if(!s)return PV_ARGUMENT;
    abandon_anchor(s);all_dirty(s);s->stats.session_open=0;return PV_OK;
}
PvResult pv_begin_session(PvStore* s) {
    if(!s)return PV_ARGUMENT;
    if(s->stats.generation==UINT64_MAX)return PV_EXHAUSTED;
    abandon_anchor(s);all_dirty(s);++s->stats.generation;s->stats.session_open=1;return PV_OK;
}
PvResult pv_mark(PvStore* s,size_t off,size_t n) {
    if(!s || off>B || n>B-off)return PV_ARGUMENT;
    if(!s->stats.session_open)return PV_CLOSED;
    if(n)for(unsigned p=unsigned(off/P);p<=unsigned((off+n-1)/P);++p)
        if(!s->dirty[p]) { s->dirty[p]=1;++s->stats.dirty_pages; }
    return PV_OK;
}
PvResult pv_mark_all(PvStore* s) { return pv_mark(s,0,B); }
PvResult pv_save(PvStore* s,const void* prefix,const void* suffix,PvHandle* out,uint32_t* crc) {
    if(!s || !out || !crc || !inputs(s,prefix,suffix))return PV_ARGUMENT;
    if(!s->stats.session_open)return PV_CLOSED;
    if(handles_exhausted)return PV_EXHAUSTED;
    Snapshot* p=stage_snapshot(s,prefix,suffix,false);
    Table* t=NULL;
    if(p) {
        if(s->anchor && !s->stats.dirty_pages) { t=s->anchor;++t->refs; }
        else t=stage_table(s);
        if(!t)deallocate(s,p,p->allocation_bytes,PV_ALLOC_HANDLE);
    }
    if(!p || !t) {
        p=stage_snapshot(s,prefix,suffix,true);
        if(!p) { ++s->stats.save_rejected;return PV_NOMEM; }
        unsigned char* full=p->extras()+s->config.prefix_bytes+s->config.suffix_bytes;
        uint32_t c=InfiniteCopyCrc32(0,full,s->config.live_cram,B);
        p->crc=full_crc(s,c,prefix,suffix);
        ++s->stats.full_snapshots;++s->stats.save_full;
        // Anchor/dirty bits are deliberately untouched by full-copy fallback.
    } else {
        p->table=t;p->crc=full_crc(s,t->crc[1],prefix,suffix);
        ++t->refs;abandon_anchor(s);s->anchor=t;
        std::memset(s->dirty,0,N);s->stats.dirty_pages=0;++s->stats.save_pages;
    }
    p->id=next_handle;p->generation=s->stats.generation;
    if(next_handle==UINT64_MAX)handles_exhausted=true;else ++next_handle;
    p->next=s->owners;if(s->owners)s->owners->previous=p;s->owners=p;
    ++s->stats.owners;*out=p->id;*crc=p->crc;return PV_OK;
}
PvResult pv_restore(PvStore* s,PvHandle h,void* prefix,void* suffix) {
    if(!s || !outputs(s,prefix,suffix))return PV_ARGUMENT;
    if(!s->stats.session_open)return PV_CLOSED;
    Snapshot* p=find(s,h);if(!p)return PV_HANDLE;
    if(p->generation!=s->stats.generation)return PV_SESSION;
    if(p->table) {
        Table* t=p->table;++t->refs;
        for(unsigned i=0;i<N;++i)if(s->dirty[i] || !s->anchor || s->anchor->pages[i]!=t->pages[i]) {
            std::memcpy(s->config.live_cram+i*P,t->pages[i]->bytes,P);++s->stats.restored_pages;
        }
        abandon_anchor(s);s->anchor=t;std::memset(s->dirty,0,N);s->stats.dirty_pages=0;
    } else {
        std::memcpy(s->config.live_cram,p->extras()+s->config.prefix_bytes+s->config.suffix_bytes,B);
        all_dirty(s);s->stats.restored_pages+=N;
    }
    copy_extras(s,p,prefix,suffix);return PV_OK;
}
PvResult pv_free(PvStore* s,PvHandle h) {
    if(!s)return PV_ARGUMENT;
    Snapshot* p=find(s,h);if(!p)return PV_HANDLE;
    if(p->previous)p->previous->next=p->next;else s->owners=p->next;
    if(p->next)p->next->previous=p->previous;
    --s->stats.owners;destroy_snapshot(s,p);return PV_OK;
}
size_t pv_canonical_bytes(const PvStore* s) { return s?s->config.prefix_bytes+B+s->config.suffix_bytes:0; }
PvResult pv_materialize(PvStore* s,PvHandle h,void* out,size_t n) {
    if(!s || n!=pv_canonical_bytes(s) || !span(out,n) || overlap(out,n,s->config.live_cram,B))return PV_ARGUMENT;
    Snapshot* p=find(s,h);if(!p)return PV_HANDLE;
    unsigned char* d=static_cast<unsigned char*>(out);
    if(s->config.prefix_bytes)std::memcpy(d,p->extras(),s->config.prefix_bytes);
    d+=s->config.prefix_bytes;
    if(p->table)for(unsigned i=0;i<N;++i)std::memcpy(d+i*P,p->table->pages[i]->bytes,P);
    else std::memcpy(d,p->extras()+s->config.prefix_bytes+s->config.suffix_bytes,B);
    if(s->config.suffix_bytes)std::memcpy(d+B,p->extras()+s->config.prefix_bytes,s->config.suffix_bytes);
    return PV_OK;
}
PvResult pv_materialize_live(PvStore* s,const void* prefix,const void* suffix,void* out,size_t n) {
    if(!s || !inputs(s,prefix,suffix) || n!=pv_canonical_bytes(s) || !span(out,n) ||
       overlap(out,n,s->config.live_cram,B) || overlap(out,n,prefix,s->config.prefix_bytes) ||
       overlap(out,n,suffix,s->config.suffix_bytes))return PV_ARGUMENT;
    if(!s->stats.session_open)return PV_CLOSED;
    unsigned char* d=static_cast<unsigned char*>(out);
    if(s->config.prefix_bytes)std::memcpy(d,prefix,s->config.prefix_bytes);
    std::memcpy(d+s->config.prefix_bytes,s->config.live_cram,B);
    if(s->config.suffix_bytes)std::memcpy(d+s->config.prefix_bytes+B,suffix,s->config.suffix_bytes);
    return PV_OK;
}
PvResult pv_import(PvStore* s,const void* data,size_t n,void* prefix,void* suffix) {
    if(!s || !outputs(s,prefix,suffix) || n!=pv_canonical_bytes(s) || !span(data,n) ||
       overlap(data,n,s->config.live_cram,B) || overlap(data,n,prefix,s->config.prefix_bytes) ||
       overlap(data,n,suffix,s->config.suffix_bytes))return PV_ARGUMENT;
    if(!s->stats.session_open)return PV_CLOSED;
    const unsigned char* d=static_cast<const unsigned char*>(data);
    if(s->config.prefix_bytes)std::memcpy(prefix,d,s->config.prefix_bytes);
    std::memcpy(s->config.live_cram,d+s->config.prefix_bytes,B);
    if(s->config.suffix_bytes)std::memcpy(suffix,d+s->config.prefix_bytes+B,s->config.suffix_bytes);
    all_dirty(s);return PV_OK;
}
PvResult pv_current_crc(PvStore* s,const void* prefix,const void* suffix,uint32_t* crc) {
    if(!s || !crc || !inputs(s,prefix,suffix))return PV_ARGUMENT;
    if(!s->stats.session_open)return PV_CLOSED;
    uint32_t tree[N*2];make_tree(s,tree);*crc=full_crc(s,tree[1],prefix,suffix);return PV_OK;
}
PvResult pv_handle_crc(PvStore* s,PvHandle h,uint32_t* crc) {
    if(!s || !crc)return PV_ARGUMENT;
    Snapshot* p=find(s,h);if(!p)return PV_HANDLE;*crc=p->crc;return PV_OK;
}
PvResult pv_stats(PvStore* s,PvStats* out) { if(!s || !out)return PV_ARGUMENT;*out=s->stats;return PV_OK; }
#ifdef PV_TESTING
PvResult pv_test_advance_next_handle(uint64_t value) {
    if(handles_exhausted || value<next_handle || !value)return PV_ARGUMENT;
    next_handle=value;return PV_OK;
}
#endif
}
