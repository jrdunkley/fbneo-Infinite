# How fbneo-Infinite compares

This page backs the summary in the [README](README.md). It compares fbneo-Infinite 1.07b with the latest public source of FinalBurn Neo and of Fightcade's FBNeo fork, and gives the measurements behind each claim about the arcade board.

| Project | Revision compared | Notes |
| --- | --- | --- |
| FinalBurn Neo | [`692bd92d526f`](https://github.com/finalburnneo/FBNeo/tree/692bd92d526f2e9ab82251ba155bcf7b293a6f03) (4 November 2026) | Rechecked 9 November 2026 against `c1063ee63a3d`. The only change since, in the files compared here, is a frame-rate display fix in `run.cpp`. |
| Fightcade FBNeo | [`c95950140e24`](https://github.com/fightcadeorg/fightcade-fbneo/tree/c95950140e2424643a0bb589dc444f0defe03155) (22 June 2025) | Latest public commit. Display timing was also measured on the installed Fightcade emulator, which differs from this source in one respect; see section 2. |

These are source comparisons, plus the measurements named in each section. Settings saved by a player or supplied by a client can change the behaviour of all three.

## 1. 3rd Strike CPU timing

fbneo-Infinite adds a timing model for the CPS3's SH-2 CPU, used by default for `sfiii3nr1`. It covers the CPU cache, memory wait states on each bus, multiply issue and result timing and the free-running timer, together with corrections to interrupt order and carried cycles. Scope and remaining uncertainty are recorded in [cps3_timing.h](src/cpu/sh2/cps3_timing.h). The cache model tracks timing only. Cache contents and coherency are emulated as before.

**Where the numbers come from.** XeD ran a measurement ROM on a real CPS3 board with a Darksoft kit. From power-on it recorded 700 frames of the attract demo: timer ticks per frame, when each game pass and VBlank handler finished, interrupt counts and the size of every character-graphics transfer, plus bus and cache micro-benchmarks. The model's costs were fitted to those readings.

**How close it is.** Over the 685 paired frames of that recording, the shipped model (timing version `0x20261017`) matches the board's interrupt count and character-graphics transfers on every frame, and reaches the first live frame on the same frame as the board. Within a frame, the game pass ends a median 654 timer ticks (about 1.8 %) earlier than on the board. The share of frames that see a stale timer compare is 33.9 % in the model and 20.3 % on the board. Character-graphics transfers complete instantly in the model.

**What it changes in play.** Across 99 recorded matches (129,310 frames):

| | Board model | Standard (Fightcade) timing |
| --- | --- | --- |
| Frames dropped in live fighting | 1 in 90,183 | none |
| Holds at 27 round ends | 57, each two frames | 24, each one frame |
| Holds at round intros | 20, mostly one frame | 1 |

The one live-play drop came in a frame carrying a 22 KB character-graphics transfer. Every near miss carried a transfer of 14-31 KB. The "standard timing" column is fbneo-Infinite's own legacy path, which follows Fightcade's scheduling. Upstream FBNeo's scheduling differs slightly (below) and was not run through this census.

**The references.** Neither implements a board cost model. [Upstream](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/burn/drv/cps3/cps3run.cpp#L2131) derives its frame budget from `nBurnFPS` and carries excess cycles. [Fightcade](https://github.com/fightcadeorg/fightcade-fbneo/blob/c95950140e2424643a0bb589dc444f0defe03155/src/burn/drv/cps3/cps3run.cpp#L2077) runs four CPU slices sized with a fixed divisor of 60. Both raise IRQ10 on a fixed schedule. With board timing, fbneo-Infinite's IRQ10 count equals the board's on every recorded frame.

**Switching it off.** Set `INFINITE_CPS3_TIMING=0` before starting the emulator. Save states record the timing they were made with, so states from FBNeo or Fightcade builds are refused while board timing is on.

## 2. When the characters appear

**On the board.** 3rd Strike's VBlank handler starts the sprite-list transfer, then reads the controls. The list that reacts to a press therefore reaches the video hardware two VBlanks after the VBlank that read it. That is ROM behaviour, the same on every machine. WydD's published input-lag measurement of the cabinet ([inputlag.science](https://inputlag.science/engine/results/street-fighter-iii-3rd-strike-cps3)) shows the reaction in the frame of that transfer. The board does not add a frame of display delay after the transfer.

**In the emulators.** FBNeo keeps two copies of the sprite list: the live list in the CPU's RAM, and the copy made at the transfer. Drawing the copy shows each list one frame after the board. Drawing the live list shows it on time, but pairs it with whatever stage-scroll registers and character graphics are current at draw time. On the board, those are updated at the same transfer, and new character graphics are often still being queued.

| | Sprite list drawn | Stage scroll drawn | Character graphics | First changed frame* |
| --- | --- | --- | --- | --- |
| fbneo-Infinite | the list the board will latch | predicted for that latch | that frame's queued uploads applied for the draw, then undone | 1 (board) |
| [FBNeo](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/burn/drv/cps3/cps3run.cpp#L1855), default | buffered copy | buffered copy | current | 2 |
| FBNeo, **Less sprite lag** | live list | buffered copy (previous frame) | current, before queued uploads | 1 |
| Fightcade, installed, default | | | | 2 |
| Fightcade, installed, **1f sprite lag** | | | | 3 |

\* Emulator pixel buffer, counted in whole frames from the first frame that carries the press. The same press (P1 Weak Punch, Ken against Alex) was injected into each emulator's own native state, and the first frame whose pixels differ from an identical run without the press was recorded. Frame 1 corresponds to the board's reaction frame.

FBNeo's **Less sprite lag** option defaults to off ([`d_cps3.cpp`](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/burn/drv/cps3/d_cps3.cpp#L200) unless built with `LESS_ACCURATE`). Fightcade's public source [selects the live list](https://github.com/fightcadeorg/fightcade-fbneo/blob/c95950140e2424643a0bb589dc444f0defe03155/src/burn/drv/cps3/cps3run.cpp#L1837) unless **1f sprite lag** is set. The installed Fightcade emulator (SHA-256 `95cf8987…`) measured frame 2 by default and frame 3 with that option, so the released binary does not follow the public source here. The table gives the measured result.

fbneo-Infinite draws, at the end of each emulated frame, what the board will latch at the next transfer: the live list, the scroll registers predicted from the game's own RAM sources, and the character graphics that the next VBlank uploads before its sprite latch. Those uploads are applied for the draw and undone afterwards, so the emulated machine is untouched. On the released source this was verified as follows:

- the drawn list, registers and tiles equal the next latch on every checked frame, with no corrupt frames;
- the first changed frame equals the board in all 1,656 paired sweep cases;
- drawing leaves the emulated machine untouched, and save states, replays and two-peer netplay all passed unchanged.

Palette and text-layer update timing are not part of this equivalence check.

## 3. Frame pacing and audio

fbneo-Infinite runs a frame loop timed with `QueryPerformanceCounter`, presents each finished frame straight away and pushes its audio to the output. This follows Fightcade's frame-loop approach, using the driver's exact refresh rate (59.599 Hz for CPS3). [Upstream](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/burner/win32/run.cpp#L272) already paces presentation with a high-resolution timer that follows the audio clock when video sync and netplay are off. [Fightcade](https://github.com/fightcadeorg/fightcade-fbneo/blob/c95950140e2424643a0bb589dc444f0defe03155/src/burner/win32/run.cpp#L357) times its loop with `timeGetTime`.

All three include XAudio2. fbneo-Infinite selects it by default with four segments, each holding one frame of audio. The [upstream](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/intf/audio/aud_interface.cpp#L6) and [Fightcade](https://github.com/fightcadeorg/fightcade-fbneo/blob/c95950140e2424643a0bb589dc444f0defe03155/src/intf/audio/aud_interface.cpp#L6) sources default to six segments and module 0, which is DirectSound. These are buffer settings, not measured audible latency. The module can be changed in the Audio menu, and the segment count (`nAudSegCount`) in `config/fbneo-Infinite.ini`.

## 4. Renderer and CRT looks

[Upstream's DX9 renderer](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/intf/video/win32/vid_directx9.cpp#L2169) creates a classic Direct3D 9 device. [Fightcade](https://github.com/fightcadeorg/fightcade-fbneo/blob/c95950140e2424643a0bb589dc444f0defe03155/src/intf/video/win32/vid_directx9.cpp#L1733) offers Direct3D 9Ex and a legacy path. fbneo-Infinite uses 9Ex when available, falls back to classic Direct3D 9, and handles resource transitions across device resets.

All three offer CRT effects through HardFX. fbneo-Infinite adds three Lola Retro looks (Studio Monitor, Consumer TV RGB, 1084S RGB) and three Arcade RGB strengths, and defaults to Lola 1084S RGB. The shader sources and author notices are in `support/shaders`. The effect lists of [upstream](https://github.com/finalburnneo/FBNeo/blob/692bd92d526f2e9ab82251ba155bcf7b293a6f03/src/intf/video/win32/vid_directx9.cpp#L1852) and [Fightcade](https://github.com/fightcadeorg/fightcade-fbneo/blob/c95950140e2424643a0bb589dc444f0defe03155/src/intf/video/win32/vid_directx9.cpp#L1444) do not include these. Shader cost and afterglow are a matter of looks and GPU load, not input latency.

## 5. Rollback snapshots for netplay integrators

fbneo-Infinite includes CPS3 character-RAM page snapshots. A compatible bridge can keep the 8 MiB character RAM as shared pages, so rollback saves and restores stop recopying graphics memory that hasn't changed. The saved state and replay bytes are the same either way. The [adapter](src/burner/win32/infinite_page_snapshots.h) needs a GGPO bridge that explicitly supports its snapshot interface, board timing on and run-ahead off. Otherwise it keeps full snapshots. No bridge or GGPO runtime is included, and standalone local play never uses this path.

## What this page does not claim

- No physical input-to-picture or audio latency figures. Controller, USB, Windows, GPU queue and display time are not measured here.
- No percentage speed-up or accuracy score against either project as a whole.
- No claim about other games. Board timing and the presentation path apply to `sfiii3nr1`. Other CPS3 sets use the live or buffered list as before.
