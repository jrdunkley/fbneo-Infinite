// Standard IEEE CRC-32, identical to zlib crc32().
// PCLMUL folding adapted from Chromium; copyright 2017 The Chromium Authors.
// See LICENSE.chromium-crc32 for the BSD license and pinned source attribution.
// The polynomial, constants and folding operations are unchanged.
#ifndef INFINITE_CRC32_H
#define INFINITE_CRC32_H
#include <stdint.h>
#include <string.h>
#include "zlib.h"
#if (defined(__GNUC__) || defined(__clang__)) && (defined(__i386__) || defined(__x86_64__)) && !defined(INFINITE_CRC32_PORTABLE)
#include <cpuid.h>
static bool InfiniteCrc32Supported()
{
    unsigned a,b,c,d;
    return __get_cpuid(1,&a,&b,&c,&d) && (c & bit_PCLMUL) && (c & bit_SSE4_2);
}
#include <emmintrin.h>
#include <smmintrin.h>
#include <wmmintrin.h>

#if defined(__GNUC__) || defined(__clang__)
__attribute__((__target__("sse4.2,pclmul")))
#endif
static uint32_t InfiniteCrc32Fold(  /* SSE4.2+PCLMUL */
    const unsigned char *buf,
    unsigned len,
    uint32_t crc)
{
    /*
     * Definitions of the bit-reflected domain constants k1,k2,k3, etc and
     * the CRC32+Barrett polynomials given at the end of the paper.
     */
    static const uint64_t __attribute__((aligned(16))) k1k2[] = { 0x0154442bd4, 0x01c6e41596 };
    static const uint64_t __attribute__((aligned(16))) k3k4[] = { 0x01751997d0, 0x00ccaa009e };
    static const uint64_t __attribute__((aligned(16))) k5k0[] = { 0x0163cd6124, 0x0000000000 };
    static const uint64_t __attribute__((aligned(16))) poly[] = { 0x01db710641, 0x01f7011641 };

    __m128i x0, x1, x2, x3, x4, x5, x6, x7, x8, y5, y6, y7, y8;

    /*
     * There's at least one block of 64.
     */
    x1 = _mm_loadu_si128((__m128i *)(buf + 0x00));
    x2 = _mm_loadu_si128((__m128i *)(buf + 0x10));
    x3 = _mm_loadu_si128((__m128i *)(buf + 0x20));
    x4 = _mm_loadu_si128((__m128i *)(buf + 0x30));

    x1 = _mm_xor_si128(x1, _mm_cvtsi32_si128(crc));

    x0 = _mm_load_si128((__m128i *)k1k2);

    buf += 64;
    len -= 64;

    /*
     * Parallel fold blocks of 64, if any.
     */
    while (len >= 64)
    {
        x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
        x6 = _mm_clmulepi64_si128(x2, x0, 0x00);
        x7 = _mm_clmulepi64_si128(x3, x0, 0x00);
        x8 = _mm_clmulepi64_si128(x4, x0, 0x00);

        x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
        x2 = _mm_clmulepi64_si128(x2, x0, 0x11);
        x3 = _mm_clmulepi64_si128(x3, x0, 0x11);
        x4 = _mm_clmulepi64_si128(x4, x0, 0x11);

        y5 = _mm_loadu_si128((__m128i *)(buf + 0x00));
        y6 = _mm_loadu_si128((__m128i *)(buf + 0x10));
        y7 = _mm_loadu_si128((__m128i *)(buf + 0x20));
        y8 = _mm_loadu_si128((__m128i *)(buf + 0x30));

        x1 = _mm_xor_si128(x1, x5);
        x2 = _mm_xor_si128(x2, x6);
        x3 = _mm_xor_si128(x3, x7);
        x4 = _mm_xor_si128(x4, x8);

        x1 = _mm_xor_si128(x1, y5);
        x2 = _mm_xor_si128(x2, y6);
        x3 = _mm_xor_si128(x3, y7);
        x4 = _mm_xor_si128(x4, y8);

        buf += 64;
        len -= 64;
    }

    /*
     * Fold into 128-bits.
     */
    x0 = _mm_load_si128((__m128i *)k3k4);

    x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
    x1 = _mm_xor_si128(x1, x2);
    x1 = _mm_xor_si128(x1, x5);

    x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
    x1 = _mm_xor_si128(x1, x3);
    x1 = _mm_xor_si128(x1, x5);

    x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
    x1 = _mm_xor_si128(x1, x4);
    x1 = _mm_xor_si128(x1, x5);

    /*
     * Single fold blocks of 16, if any.
     */
    while (len >= 16)
    {
        x2 = _mm_loadu_si128((__m128i *)buf);

        x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
        x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
        x1 = _mm_xor_si128(x1, x2);
        x1 = _mm_xor_si128(x1, x5);

        buf += 16;
        len -= 16;
    }

    /*
     * Fold 128-bits to 64-bits.
     */
    x2 = _mm_clmulepi64_si128(x1, x0, 0x10);
    x3 = _mm_setr_epi32(~0, 0, ~0, 0);
    x1 = _mm_srli_si128(x1, 8);
    x1 = _mm_xor_si128(x1, x2);

    x0 = _mm_loadl_epi64((__m128i*)k5k0);

    x2 = _mm_srli_si128(x1, 4);
    x1 = _mm_and_si128(x1, x3);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_xor_si128(x1, x2);

    /*
     * Barret reduce to 32-bits.
     */
    x0 = _mm_load_si128((__m128i*)poly);

    x2 = _mm_and_si128(x1, x3);
    x2 = _mm_clmulepi64_si128(x2, x0, 0x10);
    x2 = _mm_and_si128(x2, x3);
    x2 = _mm_clmulepi64_si128(x2, x0, 0x00);
    x1 = _mm_xor_si128(x1, x2);

    /*
     * Return the crc32.
     */
    return _mm_extract_epi32(x1, 1);
}

template <bool Stream>
#if defined(__GNUC__) || defined(__clang__)
__attribute__((__target__("sse4.2,pclmul")))
#endif
static uint32_t InfiniteCrc32CopyFold(  /* SSE4.2+PCLMUL */
    const unsigned char *buf,
    unsigned len,
    uint32_t crc, unsigned char *dest)
{
    /*
     * Definitions of the bit-reflected domain constants k1,k2,k3, etc and
     * the CRC32+Barrett polynomials given at the end of the paper.
     */
    static const uint64_t __attribute__((aligned(16))) k1k2[] = { 0x0154442bd4, 0x01c6e41596 };
    static const uint64_t __attribute__((aligned(16))) k3k4[] = { 0x01751997d0, 0x00ccaa009e };
    static const uint64_t __attribute__((aligned(16))) k5k0[] = { 0x0163cd6124, 0x0000000000 };
    static const uint64_t __attribute__((aligned(16))) poly[] = { 0x01db710641, 0x01f7011641 };

    __m128i x0, x1, x2, x3, x4, x5, x6, x7, x8, y5, y6, y7, y8;

    /*
     * There's at least one block of 64.
     */
    x1 = _mm_loadu_si128((__m128i *)(buf + 0x00));
    x2 = _mm_loadu_si128((__m128i *)(buf + 0x10));
    x3 = _mm_loadu_si128((__m128i *)(buf + 0x20));
    x4 = _mm_loadu_si128((__m128i *)(buf + 0x30));

    if (Stream) _mm_stream_si128((__m128i *)(dest + 0x00), x1); else _mm_storeu_si128((__m128i *)(dest + 0x00), x1);
    if (Stream) _mm_stream_si128((__m128i *)(dest + 0x10), x2); else _mm_storeu_si128((__m128i *)(dest + 0x10), x2);
    if (Stream) _mm_stream_si128((__m128i *)(dest + 0x20), x3); else _mm_storeu_si128((__m128i *)(dest + 0x20), x3);
    if (Stream) _mm_stream_si128((__m128i *)(dest + 0x30), x4); else _mm_storeu_si128((__m128i *)(dest + 0x30), x4);
    dest += 64;

    x1 = _mm_xor_si128(x1, _mm_cvtsi32_si128(crc));

    x0 = _mm_load_si128((__m128i *)k1k2);

    buf += 64;
    len -= 64;

    /*
     * Parallel fold blocks of 64, if any.
     */
    while (len >= 64)
    {
        x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
        x6 = _mm_clmulepi64_si128(x2, x0, 0x00);
        x7 = _mm_clmulepi64_si128(x3, x0, 0x00);
        x8 = _mm_clmulepi64_si128(x4, x0, 0x00);

        x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
        x2 = _mm_clmulepi64_si128(x2, x0, 0x11);
        x3 = _mm_clmulepi64_si128(x3, x0, 0x11);
        x4 = _mm_clmulepi64_si128(x4, x0, 0x11);

        y5 = _mm_loadu_si128((__m128i *)(buf + 0x00));
        y6 = _mm_loadu_si128((__m128i *)(buf + 0x10));
        y7 = _mm_loadu_si128((__m128i *)(buf + 0x20));
        y8 = _mm_loadu_si128((__m128i *)(buf + 0x30));
        if (Stream) _mm_stream_si128((__m128i *)(dest + 0x00), y5); else _mm_storeu_si128((__m128i *)(dest + 0x00), y5);
        if (Stream) _mm_stream_si128((__m128i *)(dest + 0x10), y6); else _mm_storeu_si128((__m128i *)(dest + 0x10), y6);
        if (Stream) _mm_stream_si128((__m128i *)(dest + 0x20), y7); else _mm_storeu_si128((__m128i *)(dest + 0x20), y7);
        if (Stream) _mm_stream_si128((__m128i *)(dest + 0x30), y8); else _mm_storeu_si128((__m128i *)(dest + 0x30), y8);
        dest += 64;


        x1 = _mm_xor_si128(x1, x5);
        x2 = _mm_xor_si128(x2, x6);
        x3 = _mm_xor_si128(x3, x7);
        x4 = _mm_xor_si128(x4, x8);

        x1 = _mm_xor_si128(x1, y5);
        x2 = _mm_xor_si128(x2, y6);
        x3 = _mm_xor_si128(x3, y7);
        x4 = _mm_xor_si128(x4, y8);

        buf += 64;
        len -= 64;
    }

    /*
     * Fold into 128-bits.
     */
    x0 = _mm_load_si128((__m128i *)k3k4);

    x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
    x1 = _mm_xor_si128(x1, x2);
    x1 = _mm_xor_si128(x1, x5);

    x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
    x1 = _mm_xor_si128(x1, x3);
    x1 = _mm_xor_si128(x1, x5);

    x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
    x1 = _mm_xor_si128(x1, x4);
    x1 = _mm_xor_si128(x1, x5);

    /*
     * Single fold blocks of 16, if any.
     */
    while (len >= 16)
    {
        x2 = _mm_loadu_si128((__m128i *)buf);
        if (Stream) _mm_stream_si128((__m128i *)dest, x2); else _mm_storeu_si128((__m128i *)dest, x2); dest += 16;

        x5 = _mm_clmulepi64_si128(x1, x0, 0x00);
        x1 = _mm_clmulepi64_si128(x1, x0, 0x11);
        x1 = _mm_xor_si128(x1, x2);
        x1 = _mm_xor_si128(x1, x5);

        buf += 16;
        len -= 16;
    }

    /*
     * Fold 128-bits to 64-bits.
     */
    x2 = _mm_clmulepi64_si128(x1, x0, 0x10);
    x3 = _mm_setr_epi32(~0, 0, ~0, 0);
    x1 = _mm_srli_si128(x1, 8);
    x1 = _mm_xor_si128(x1, x2);

    x0 = _mm_loadl_epi64((__m128i*)k5k0);

    x2 = _mm_srli_si128(x1, 4);
    x1 = _mm_and_si128(x1, x3);
    x1 = _mm_clmulepi64_si128(x1, x0, 0x00);
    x1 = _mm_xor_si128(x1, x2);

    /*
     * Barret reduce to 32-bits.
     */
    x0 = _mm_load_si128((__m128i*)poly);

    x2 = _mm_and_si128(x1, x3);
    x2 = _mm_clmulepi64_si128(x2, x0, 0x10);
    x2 = _mm_and_si128(x2, x3);
    x2 = _mm_clmulepi64_si128(x2, x0, 0x00);
    x1 = _mm_xor_si128(x1, x2);

    /*
     * Return the crc32.
     */
    return _mm_extract_epi32(x1, 1);
}


#endif
static uint32_t InfiniteCrc32(uint32_t crc, const unsigned char *buf, unsigned len)
{
    if (!buf) return 0; // zlib's initialization convention, for any seed/length.
#if (defined(__GNUC__) || defined(__clang__)) && (defined(__i386__) || defined(__x86_64__)) && !defined(INFINITE_CRC32_PORTABLE)
    static const bool supported = InfiniteCrc32Supported();
    if (supported && len >= 64) {
        unsigned bulk = len & ~15U;
        crc = ~InfiniteCrc32Fold(buf, bulk, ~crc);
        buf += bulk;
        len -= bulk;
    }
#endif
    return (uint32_t)crc32(crc, buf, len);
}
// Same memcpy contract: source/destination must not partially overlap. The
// entire destination is always overwritten, including previously pooled bytes.
static uint32_t InfiniteCopyCrc32(uint32_t crc, unsigned char *dest, const unsigned char *src, unsigned len)
{
#if (defined(__GNUC__) || defined(__clang__)) && (defined(__i386__) || defined(__x86_64__)) && !defined(INFINITE_CRC32_PORTABLE)
    static const bool supported = InfiniteCrc32Supported();
    if (supported && len >= 64) {
        // Streaming stores do not evict the CPU's working set while filling
        // a snapshot. Keep temporal prefix/tail on distinct cache lines.
        const bool stream = len >= 1024 * 1024;
        if (stream) {
            const unsigned lead = (unsigned)(-(uintptr_t)dest) & 63U;
            if (lead) { memcpy(dest, src, lead); crc = (uint32_t)crc32(crc, dest, lead); src += lead; dest += lead; len -= lead; }
        }
        unsigned bulk = len & (stream ? ~63U : ~15U);
        if (stream) { crc = ~InfiniteCrc32CopyFold<true>(src, bulk, ~crc, dest); _mm_sfence(); }
        else crc = ~InfiniteCrc32CopyFold<false>(src, bulk, ~crc, dest);
        src += bulk; dest += bulk; len -= bulk;
    }
#endif
    if (len) memcpy(dest, src, len);
    return (uint32_t)crc32(crc, dest, len);
}

#if (defined(__GNUC__) || defined(__clang__)) && (defined(__i386__) || defined(__x86_64__)) && !defined(INFINITE_CRC32_PORTABLE)
template <bool Stream>
__attribute__((__target__("sse2")))
static void InfiniteStateCopyLarge(unsigned char *dest, const unsigned char *src, unsigned len)
{
    unsigned lead = (unsigned)(-(uintptr_t)dest) & 63U;
    if (lead) { memcpy(dest, src, lead); dest += lead; src += lead; len -= lead; }
    while (len >= 64) {
        __m128i a = _mm_loadu_si128((const __m128i *)(src));
        __m128i b = _mm_loadu_si128((const __m128i *)(src + 16));
        __m128i c = _mm_loadu_si128((const __m128i *)(src + 32));
        __m128i d = _mm_loadu_si128((const __m128i *)(src + 48));
        if (Stream) {
            _mm_stream_si128((__m128i *)(dest), a); _mm_stream_si128((__m128i *)(dest + 16), b);
            _mm_stream_si128((__m128i *)(dest + 32), c); _mm_stream_si128((__m128i *)(dest + 48), d);
        } else {
            _mm_store_si128((__m128i *)(dest), a); _mm_store_si128((__m128i *)(dest + 16), b);
            _mm_store_si128((__m128i *)(dest + 32), c); _mm_store_si128((__m128i *)(dest + 48), d);
        }
        dest += 64; src += 64; len -= 64;
    }
    if (Stream) _mm_sfence();
    if (len) memcpy(dest, src, len);
}
#endif
static void InfiniteStateCopy(void *dest, const void *src, unsigned len)
{
#if (defined(__GNUC__) || defined(__clang__)) && (defined(__i386__) || defined(__x86_64__)) && !defined(INFINITE_CRC32_PORTABLE)
    static const bool supported = InfiniteCrc32Supported();
    if (supported && len >= 256) {
        if (len >= 1024 * 1024) InfiniteStateCopyLarge<true>((unsigned char *)dest, (const unsigned char *)src, len);
        else InfiniteStateCopyLarge<false>((unsigned char *)dest, (const unsigned char *)src, len);
        return;
    }
#endif
    if (len) memcpy(dest, src, len);
}

#endif
