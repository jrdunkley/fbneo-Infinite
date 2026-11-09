# Building fbneo-Infinite

## Windows release build

Requirements:

- Python 3.10 or later (standard library only).
- [w64devkit 2.10.0](https://github.com/skeeto/w64devkit/releases/tag/v2.10.0), including GCC, GNU make 4.4.1 or later, windres and strip. The verified compiler is GCC 16.2.0, with both `-m32` and `-m64` support.
- Perl, for the inherited source generators. Perl from Git for Windows works.

Extract the source into a writable directory. From that directory:

```powershell
python build.py --arch both --toolchain C:/tools/w64devkit --perl C:/tools/git/usr/bin --jobs 4
```

Alternatively, put those tools on `PATH` and run `python build.py --arch x64`. The build downloads nothing and needs neither the Infinite client nor any game files. It compiles the bundled Lua and compression sources. Build the two architectures sequentially: upstream generators share output paths.

Executables are written to `build/x86/fbneo-Infinite.exe` and `build/x64/fbneo-Infinite.exe`. Logs and SHA-256 records are in `build/`. To create the portable source and Windows ZIPs, run:

```powershell
python tools/verify_source.py
python package.py
```

The package script requires both architectures. It writes `dist/` with source, Windows ZIPs and checksums. Publish the matching source alongside any binaries. Build and packaging do not publish anything.

`VERIFICATION.json` describes tests on specific executable and source hashes. A local rebuild whose hashes differ is packaged as **runtime unqualified** until it has matching test evidence; it never inherits the released build's passing runtime verdict automatically.

Equivalent make commands are `make mingw RELEASEBUILD=1 BUILD_X86_ASM= -j4` and the same command with `BUILD_X64_EXE=1` for x64. The link uses a response file to avoid Windows command-line length limits. No precompiled emulator objects or closed GGPO library are needed for this build.

## Runtime prerequisites

The Windows frontend uses Direct3D 9 and legacy D3DX9/XAudio2 interfaces. A machine without the legacy components may need Microsoft's [DirectX End-User Runtimes (June 2010)](https://www.microsoft.com/en-us/download/details.aspx?id=8109). The emulator does not install them automatically, and this source package does not redistribute Microsoft's DLLs. The runtime must match the executable's architecture.

HardFX also needs the included `support/shaders/` tree and a compatible graphics device. Physical input/display and audio latency depend on the machine and are not established by a software smoke test.

## Other platforms

The inherited `README-SDL.md`, `README-macOS.md`, `README-PI.md`, project files and make targets are retained for porting work. Windows-specific presentation, audio and integration changes are not automatically available in those frontends. Native Linux/macOS binaries are not part of this release.
