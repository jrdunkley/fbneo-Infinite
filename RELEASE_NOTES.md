# fbneo-Infinite 1.07b

The first standalone release of the emulator from Infinite, built from the same emulator source as Infinite 1.07b. The emulator inside Infinite differs only in its 3rd Strike ROM checksums, which match Infinite's own game data. This release uses the stock definitions, so it loads the original ROM sets.

**Included**

- Board-measured CPS3 CPU timing for `sfiii3nr1`, on by default.
- Board-faithful sprite presentation for 3rd Strike: characters in the board's frame, with stage scroll and graphics matched.
- XAudio2 with four buffered frames as the default, and Lola 1084S RGB as the default look in the DirectX9 Alt blitter, which uses Direct3D 9Ex.
- All HardFX shaders, with their sources and licence notices.
- The full emulator source, with a Windows build and packaging script.

**Downloads**

- `fbneo-Infinite-1.07b-windows-x64.zip` and `fbneo-Infinite-1.07b-windows-x86.zip`: the emulator, shaders, documentation and licences.
- `fbneo-Infinite-1.07b-source.zip`: the matching source, also in this repository.
- `SHA256SUMS.txt`: checksums for all three.

No ROMs, BIOS images, game modifications, saved states, GGPO libraries or Infinite client files are included.

**Tested** on Windows, x86 and x64:

- Cold boots, with board timing confirmed as the default.
- Save-state continuation.
- Fifteen shader switches with device resets.
- A first run from each extracted ZIP, following the README: licence notice, game list, DirectX9 Alt and a ROM folder, then 3rd Strike playing with the expected defaults.

[VERIFICATION.json](VERIFICATION.json) lists the exact executables and checks. Physical input-to-picture latency was not measured.
