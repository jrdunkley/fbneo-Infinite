# fbneo-Infinite

**Street Fighter III: 3rd Strike, timed like the arcade board.**

fbneo-Infinite is the emulator from Infinite, released on its own as a FinalBurn Neo fork for Windows. It runs 3rd Strike on CPU timing measured from a real CPS3 board, and puts the characters on screen in the same frame the arcade does, with the stage and graphics in step. Every other FBNeo game is still here and runs as before.

Release **1.07b**: the emulator from Infinite 1.07b, built from the same source. Windows x64 and x86. Bring your own ROMs.

## What's different

### 3rd Strike runs at the arcade board's real speed

A real CPS3 board doesn't run every instruction at full speed. Its CPU waits on its cache and on slower memory, and those waits are why the arcade holds a frame here and there. FBNeo times the CPU as if memory were instant, so those holds come out differently.

fbneo-Infinite's CPU timing is built from measurements taken on a real CPS3 board. 

It is checked against the board itself. Started from power-on, the emulator matches a real board's own recording of the attract demo frame for frame, across all 685 recorded frames.

Board timing is on by default for `sfiii3nr1`. Other games keep their usual timing.

### Characters appear one frame sooner, and nothing slips out of step

On the arcade board, the characters in each frame are the ones the game sent to the video hardware at the start of that frame. FBNeo shows them one frame later by default, and so does Fightcade as installed.

FBNeo's **Less sprite lag** option takes that frame away, but it draws the newer characters over the previous frame's stage scroll, before their new graphics have loaded. Characters can slip against the stage, or show wrong tiles for a frame when a move's graphics are still arriving. fbneo-Infinite gets the stage scroll and graphics ready that the board will use for that frame. You get the earlier frame, with the characters and the stage where they belong.

This is always on for 3rd Strike. There is nothing to set.

### Also included

- **A shorter sound buffer.** XAudio2 holding four frames of audio is the default, instead of DirectSound with six. DirectSound is still available in the Audio menu.
- **CRT looks.** With the DirectX9 Alt blitter, Lola 1084S RGB, after the Commodore 1084S monitor, is the default. Two more Lola looks and three Arcade RGB strengths are in its **HardFX algorithm** menu. All shader files are included.
- **Direct3D 9Ex presentation** in the DirectX9 Alt blitter, falling back to classic Direct3D 9 where needed.
- **For netplay developers:** CPS3 character-RAM page snapshots make rollback saves and loads lighter. They need a compatible GGPO bridge, which is not included.

## Compared with FBNeo and Fightcade

| | fbneo-Infinite | FBNeo (latest) | Fightcade FBNeo |
| --- | --- | --- | --- |
| **3rd Strike CPU timing** | Measured from a CPS3 board | Standard SH-2 timing | Standard SH-2 timing |
| **Characters on screen** | Same frame as the board, stage and graphics in step | One frame later by default. **Less sprite lag** removes it, with the side effects above | One frame later, as installed |
| **Default audio** | XAudio2, four frames | DirectSound, six frames | DirectSound, six frames |
| **Direct3D 9 renderer** | 9Ex, classic fallback | Classic | 9Ex, with a legacy option |
| **CRT looks** | Lola and Arcade RGB looks added; Lola 1084S default | FBNeo's HardFX set | FBNeo's HardFX set |

Compared against the latest public source of each: FBNeo `692bd92d`, rechecked on 9 November 2026 with no change in these areas, and Fightcade FBNeo `c9595014`. Lua scripting, save states, run-ahead and the rest of FBNeo's features are shared by all three. Source links and measurement details are in [COMPARISON.md](COMPARISON.md).

## Getting started

1. Download the Windows ZIP from [Releases](https://github.com/jrdunkley/fbneo-Infinite/releases): x64 for 64-bit Windows, x86 for 32-bit. Extract it to a folder you can write to, and keep the `support` folder next to `fbneo-Infinite.exe`.
2. Have your own 3rd Strike ROMs ready: **sfiii3nr1.zip** (Japan 990512, NO CD) and its parent **sfiii3.zip**, which holds the graphics. No ROMs or BIOS files are included.
3. Run `fbneo-Infinite.exe`. The first time, FBNeo shows its licence notice: press **OK**, tick **I understand**, then press **OK** again. It then builds its game list, which takes about a minute, once.
4. Choose **Video → Select blitter → DirectX9 Alt**. FBNeo starts on a basic DirectDraw blitter. DirectX9 Alt is the one with Direct3D 9Ex and the CRT looks, and Lola 1084S RGB comes on with it.
5. Choose **Misc → Configure ROM paths…** and add your ROM folder. FBNeo scans the folder when you confirm, and again whenever you change ROM folders.
6. Choose **Game → Load game…** (F6) and pick *Street Fighter III 3rd Strike: Fight for the Future (Japan 990512, NO CD)*.

To start the game straight from a shortcut or the command line, in a window:

```powershell
.\fbneo-Infinite.exe sfiii3nr1 -w
```

Without `-w`, a game named on the command line starts in fullscreen.

If Windows reports a missing `d3dx9` or `XAudio2` file, install Microsoft's [DirectX End-User Runtime (June 2010)](https://www.microsoft.com/en-us/download/details.aspx?id=8109).

## Good to know

- **Local play only.** There is no lobby or matchmaking here; online play belongs to the Infinite client. FBNeo's legacy GGPO interface stays in the source, but no GGPO library is included.
- **Save states.** With board timing on, save states from other FBNeo or Fightcade builds won't load, because the saved machine includes its timing. States you make in fbneo-Infinite work as usual.
- **Standard timing.** To play 3rd Strike on standard timing, set the environment variable `INFINITE_CPS3_TIMING=0` before you start the emulator.

## Building from source

Everything needed is in this repository. The build uses Python, Perl and the w64devkit GCC toolchain, and downloads nothing:

```powershell
python build.py --arch both
```

[BUILDING.md](BUILDING.md) has the details. The SDL, macOS and other port files inherited from FBNeo are kept for porting work. Only the Windows build is tested.

## Credits

- **XeD**: board research. XeD ran the measurement ROM on a real CPS3 board, and those readings are what the timing model is built from.
- **WydD**, whose published CPS3 input-lag measurements are the reference for when the board shows each frame.
- The **FinalBurn Neo** team, and the Final Burn and MAME developers whose work FBNeo carries.
- **Fightcade**, whose FBNeo fork this emulator grew from.
- **Lola Retro** shaders by zoran123456, and the authors of the Arcade RGB, RetroCrisis and Guest shader material credited in `support/shaders`.

## Licence

fbneo-Infinite is an independent fork. It is not an official FinalBurn Neo or Fightcade release. The source is available under the inherited [FBNeo licence](src/license.txt): no commercial use, no donations, and modified versions you distribute must publish their source. Individual components keep their own licences; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
