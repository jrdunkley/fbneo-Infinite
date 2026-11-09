# Contributing

Report fork-specific bugs in this repository's issue tracker, including the package version, architecture, Windows version, graphics/audio device, selected renderer, and steps to reproduce. Do not attach ROMs, BIOS files, proprietary game data, credentials, or private recordings.

Keep emulator fixes separate from client features and game modifications. Describe the concrete behaviour changed and test the affected path. Timing or save-state changes need deterministic regression evidence and explicit consideration of replay/netplay compatibility. A source build alone does not establish hardware accuracy.

Preserve upstream copyright and licence notices. Use the existing tabs and source style. The verified Windows build uses C++11; preserve compatibility with inherited ports when practical. Run `python tools/verify_source.py` and the affected architecture build before submitting.

Do not add automatic publishing, funding requests, ROM downloaders or bundled closed runtimes. Release publication is a maintainer action after reviewing the archive contents and matching source.
