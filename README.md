# ICARUS — ZX Spectrum 48K / 128K

> **Only the brave defy Zeus.**

ICARUS is an original score-chasing arcade game written in Z80 assembly for the ZX Spectrum 48K and 128K. Catch falling stars, avoid divine attacks, build combos, face Zeus, Cronos and Medusa, and climb ever closer to the sun.

[![Play page](https://img.shields.io/badge/GitHub%20Pages-Open%20game%20page-00ffff?style=for-the-badge&labelColor=111111)](https://mmmpt.github.io/icarus-zx-spectrum/)
[![Download v1.2](https://img.shields.io/badge/Download-v1.2-ffff00?style=for-the-badge&labelColor=111111)](https://github.com/MmmPT/icarus-zx-spectrum/releases/tag/v1.2)

## Version 1.2

Version 1.2 is a major update with new graphics, music, progression and fixes.

### Highlights

- New loading screen artwork by **Mário Viegas**
- New 48×40 portraits for Zeus, Cronos and Medusa
- New AY music: main theme, boss themes, calm title version and game-over elegy
- Animated wings, parallax stars, cloud band, rising sun and melting-wax effects
- Continued play beyond level 7 with score multipliers and tougher bosses
- Improved Kempston joystick support in gameplay and menus
- Numerous gameplay, sound, UI and stability fixes

See the full [changelog](CHANGELOG.md).

## Downloads

### Current release — v1.2

- [ICARUS v1.2 release](https://github.com/MmmPT/icarus-zx-spectrum/releases/tag/v1.2)
- [v1.2 TAP](https://github.com/MmmPT/icarus-zx-spectrum/releases/download/v1.2/Icarus_v1.2.tap)
- [v1.2 ZIP](https://github.com/MmmPT/icarus-zx-spectrum/releases/download/v1.2/Icarus_ZX_Spectrum_v1.2.zip)

### Original release — v1.0

The original **v1.0 is preserved and remains available**:

- [v1.0 downloads](https://github.com/MmmPT/icarus-zx-spectrum/releases/tag/downloads-2026-10-31)
- [v1.0 ZIP](https://github.com/MmmPT/icarus-zx-spectrum/releases/download/downloads-2026-10-31/Icarus_ZX_Spectrum_v1.0.zip)

## Controls

| Control | Action |
|---|---|
| `O` / `P` | Move left / right |
| Kempston joystick | Move; FIRE pauses |
| `SPACE` | Pause |
| `M` | Music on/off on the title screen |
| Any key / FIRE | Start or continue |

## Compatibility

- ZX Spectrum 48K, 128K, +2, +3 and compatibles
- AY music on 128K models or a 48K with an AY interface
- Plain 48K machines use beeper sound effects
- Kempston joystick supported

## How to load

On a real machine:

```text
LOAD ""
```

Then start the tape or the device playing the TAP image. Compatible emulators can open the TAP directly.

## Credits and AI disclosure

**Game design and programming:** MMM  
**Loading screen artwork:** Mário Viegas  
**Repository:** MmmPT

Claude AI was used as a programming assistant during development. Design choices, integration, testing and final release decisions were made by the author.

## Licensing

Source code in `src/` and `tools/` is released under the MIT License. The game title, loading artwork, screenshots, compiled binaries and other non-code assets are not covered by the MIT License. See [`LICENSE`](LICENSE) and [`ASSET-LICENSE.md`](ASSET-LICENSE.md).

## Download statistics

GitHub records downloads for release assets. Existing v1.0 assets are deliberately retained so their counters are preserved. v1.2 is published as a separate release with new asset filenames.
