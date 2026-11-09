#ifndef INFINITE_ISOLATED_PAGE_STORE_H
#define INFINITE_ISOLATED_PAGE_STORE_H
#include <stddef.h>
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

/* Single-threaded component: serialize ALL calls, including calls across stores.
 * Live CRAM stays externally owned, flat and writable. Mark every actual store
 * before writing, including same-value writes; reset within a session marks all.
 * Handles are process-local, never serialized. Canonical bytes are exactly
 * [prefix][all 8 MiB physical CRAM bytes][suffix], without an added envelope.
 * Caller fixes prefix/suffix sizes from the independently validated scan layout.
 * Allocator must return suitably aligned memory or NULL and must not reenter.
 * All failures are transactional (statistics/failure counters excepted).
 */
enum { PV_PAGE_BYTES=4096, PV_PAGE_COUNT=2048, PV_CRAM_BYTES=8388608 };
typedef struct PvStore PvStore;
typedef uint64_t PvHandle;
typedef enum PvResult { PV_OK=0, PV_ARGUMENT, PV_CLOSED, PV_HANDLE,
    PV_SESSION, PV_NOMEM, PV_EXHAUSTED, PV_BUSY } PvResult;
typedef enum PvAllocation { PV_ALLOC_STORE=0, PV_ALLOC_TABLE=1,
    PV_ALLOC_PAGE=2, PV_ALLOC_HANDLE=3, PV_ALLOC_FULL=4, PV_ALLOC_CLASSES=5 } PvAllocation;
typedef void* (*PvAlloc)(void* context, size_t bytes, PvAllocation kind);
typedef void (*PvDealloc)(void* context, void* pointer, size_t bytes, PvAllocation kind);
typedef struct PvConfig {
    unsigned char* live_cram;
    size_t prefix_bytes, suffix_bytes;
    /* 0 = no artificial page-payload budget. Fallback payload is not capped. */
    uint64_t page_payload_limit;
    PvAlloc allocate;
    PvDealloc deallocate;
    void* allocator_context;
} PvConfig;
typedef struct PvStats {
    uint64_t generation, owners, page_tables, page_versions, full_snapshots;
    uint64_t allocated_bytes[PV_ALLOC_CLASSES];
    uint64_t total_allocated_bytes, peak_allocated_bytes;
    uint64_t save_pages, save_full, save_rejected, restored_pages;
    unsigned dirty_pages;
    int session_open;
} PvStats;

PvResult pv_create(const PvConfig* config, PvStore** out);
/* Destruction rejects still-owned handles; end_session permits delayed frees. */
PvResult pv_destroy(PvStore* store);
PvResult pv_end_session(PvStore* store);
/* A new generation invalidates old handles for restore, never for export/free.
 * Does not change live RAM, revoke owners, seal, or allocate. */
PvResult pv_begin_session(PvStore* store);
PvResult pv_mark(PvStore* store, size_t offset, size_t length);
PvResult pv_mark_all(PvStore* store);
PvResult pv_save(PvStore* store, const void* prefix, const void* suffix,
                 PvHandle* out_handle, uint32_t* out_crc);
/* Outputs are the fixed-size prefix/suffix; nonempty outputs must be disjoint
 * from one another and live CRAM. Entire validation precedes the first write. */
PvResult pv_restore(PvStore* store, PvHandle handle, void* prefix, void* suffix);
PvResult pv_free(PvStore* store, PvHandle handle);
/* Export works after session close and across generations, into caller storage.
 * Exact size required; output must be disjoint from live CRAM. */
PvResult pv_materialize(PvStore* store, PvHandle handle, void* canonical, size_t bytes);
PvResult pv_materialize_live(PvStore* store, const void* prefix, const void* suffix,
                            void* canonical, size_t bytes);
/* Full-byte import in the CURRENT generation. Input/output/live spans must be
 * disjoint. Does not revoke existing owners. Marks every current page dirty. */
PvResult pv_import(PvStore* store, const void* canonical, size_t bytes,
                   void* prefix, void* suffix);
/* CRC query never seals, clears dirty bits, or allocates. Seed is zlib IEEE 0. */
PvResult pv_current_crc(PvStore* store, const void* prefix, const void* suffix, uint32_t* crc);
PvResult pv_handle_crc(PvStore* store, PvHandle handle, uint32_t* crc);
PvResult pv_stats(PvStore* store, PvStats* out);
size_t pv_canonical_bytes(const PvStore* store);
#ifdef PV_TESTING
/* Monotonic-only rollover seam; never compiled in the production component. */
PvResult pv_test_advance_next_handle(uint64_t value);
#endif
#ifdef __cplusplus
}
#endif
#endif
