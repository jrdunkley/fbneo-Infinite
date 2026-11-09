// Host-only storage for immutable GGPO snapshots. Calls are serialized on the
// emulator thread, like the scan callbacks. No byte in the serialized state is
// changed. Each returned pointer must be released through GGPO's free callback.
#ifndef INFINITE_SNAPSHOT_POOL_H
#define INFINITE_SNAPSHOT_POOL_H

class InfiniteSnapshotPool {
    struct Block {
        Block *next, *previous;
        size_t bytes;
        unsigned long long generation;
    };
    Block *available, *outstanding;
    unsigned long long generation;
    size_t stateBytes;
    unsigned timing, audio, layout;
    unsigned count;
    bool enabled;

    void ClearAvailable() {
        while (available) {
            Block *b = available;
            available = b->next;
            free(b);
        }
        count = 0;
        pooledBytes = 0;
        ++generation;
    }

    void Peak() {
        if (outstandingBytes > peakOutstandingBytes) peakOutstandingBytes = outstandingBytes;
        if (pooledBytes > peakPooledBytes) peakPooledBytes = pooledBytes;
        if (outstandingBytes + pooledBytes > peakTotalBytes) peakTotalBytes = outstandingBytes + pooledBytes;
    }

public:
    // Include the private allocation header in memory-accounting totals.
    static const unsigned MaxBuffers = 2;
    static const size_t MaxPooledBytes = 32 * 1024 * 1024;
    unsigned long long allocations, reuses, failures;
    unsigned long long outstandingBytes, pooledBytes;
    unsigned long long peakOutstandingBytes, peakPooledBytes, peakTotalBytes;

    InfiniteSnapshotPool() : available(NULL), outstanding(NULL), generation(0), stateBytes(0),
        timing(0), audio(0), layout(0), count(0), enabled(false),
        allocations(0), reuses(0), failures(0), outstandingBytes(0), pooledBytes(0),
        peakOutstandingBytes(0), peakPooledBytes(0), peakTotalBytes(0) {}

    void Begin() {
        End();
        allocations = reuses = failures = 0;
        peakOutstandingBytes = peakTotalBytes = outstandingBytes;
        peakPooledBytes = 0;
        enabled = true;
    }

    void End() {
        enabled = false;
        ClearAvailable();
        stateBytes = 0;
        // Outstanding allocations are still owned by the caller. A later free
        // releases them, and the generation prevents reuse across sessions.
    }

    void *FirstOutstanding() const { return outstanding ? outstanding + 1 : NULL; }

    unsigned char *Acquire(size_t bytes, unsigned t, unsigned a, unsigned l) {
        if (!bytes || bytes > 16 * 1024 * 1024 + 24) { ++failures; return NULL; }
        if (bytes != stateBytes || t != timing || a != audio || l != layout) {
            ClearAvailable();
            stateBytes = bytes; timing = t; audio = a; layout = l;
        }
        Block *b = available;
        if (b) {
            available = b->next;
            --count;
            pooledBytes -= sizeof(Block) + b->bytes;
            ++reuses;
        } else {
            b = (Block *)malloc(sizeof(Block) + bytes);
            if (!b) { ++failures; return NULL; }
            ++allocations;
            b->bytes = bytes;
        }
        b->previous = NULL;
        b->next = outstanding;
        if (outstanding) outstanding->previous = b;
        outstanding = b;
        b->generation = generation;
        outstandingBytes += sizeof(Block) + bytes;
        Peak();
        return (unsigned char *)(b + 1);
    }

    void Release(void *buffer, bool retain = true) {
        if (!buffer) return;
        Block *b = ((Block *)buffer) - 1;
        if (b->previous) b->previous->next = b->next;
        else outstanding = b->next;
        if (b->next) b->next->previous = b->previous;
        size_t total = sizeof(Block) + b->bytes;
        outstandingBytes -= total;
        if (retain && enabled && b->generation == generation &&
            count < MaxBuffers && total <= MaxPooledBytes - pooledBytes) {
            b->next = available;
            b->previous = NULL;
            available = b;
            ++count;
            pooledBytes += total;
            Peak();
        } else {
            free(b);
        }
    }
};
#endif
