# Third-party notices

The full source distribution preserves original file-level notices. The following is an index, not a replacement for those licences.

| Component | Notice/source location |
| --- | --- |
| FinalBurn Neo, Final Burn, MAME-derived cores and other emulator components | `src/license.txt` and the respective source file headers |
| Chromium-derived CRC32 work | `LICENSE.chromium-crc32` |
| Lua | Full permission and disclaimer in `src/dep/libs/lua/lua.h` |
| zlib | `src/dep/libs/zlib/zlib.h` |
| 7-Zip / LZMA | Headers in `src/dep/libs/lib7z/` and `src/dep/libs/lzma/LICENSE` |
| libchdr, dr_libs | `src/dep/libs/libchdr/LICENSE.txt`, `src/dep/libs/dr_libs/LICENSE.txt` |
| libspng | `src/license.txt` and `src/dep/libs/libspng/spng.h` |
| GBA and SNES components | `src/burn/drv/gba/license.txt`, `src/burn/drv/snes/license.txt` |
| Lola Retro shader adaptations | MIT notices in each preset's `support/shaders/lola_retro/*/LICENSE`; source provenance in `SOURCES.txt` |
| Arcade RGB / RetroCrisis / Guest shader material | `support/shaders/arcade_rgb/COPYING`, `SOURCES`, and shader headers |
| Other HardFX shaders | Individual shader headers and `support/shaders/source.json` |

The optional legacy GGPO interface headers and integration code are retained from the emulator source. No legacy GGPO implementation DLL, import library, or Infinite replay bridge binary is included. Modern open-source GGPO is a separate project and is not represented as an interchangeable implementation of this legacy interface.

The Windows ZIPs include `LICENSES/` with licence texts and relevant library headers, as well as all shader notices. The accompanying source ZIP contains the complete emulator source and all file-level credits.
