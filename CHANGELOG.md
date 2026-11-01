# Changelog

## Version 1.2 — 2026

A major update over version 1.0.

### Graphics

- New loading screen, kept on screen until a key or FIRE is pressed.
- **Loading screen artwork by Mário Viegas.**
- Title screen uses the logo and tagline from the loading screen, a new bold font, and explains every rule, power-up and the wind.
- Icarus now has flapping wings; the WINGS power-up shows longer wings.
- Player colours: yellow (normal), cyan/blue (shield), grey stone (Medusa's stare).
- Cloud band at the bottom of the play area.
- Background stars drift down in two layers (parallax).
- The sun rises in the top-right corner and grows with every level.
- New 48×40 portraits for Zeus, Cronos and Medusa.
- Zeus's bolts are white zigzag lightning; Zeus flashes blue when he throws one.
- “+N” score popups, and WINGS! / SHIELD! messages.
- Wind shown as an arrow in the HUD.
- “The wax is melting”: wings lose feathers and drip wax in later cycles.
- Game-over animation: Icarus falls into the clouds.
- Much less flicker, and objects no longer leave coloured marks.

### Sound

- New AY music: main theme, a theme for each boss, a calm title version and a game-over elegy (128K / AY).
- All sound effects and jingles retuned to D minor; star catches play a rising arpeggio as the combo grows.
- 48K: beeper effects last long enough to be heard, at the same pitch as on AY; jingles no longer freeze the game.

### Gameplay

- Beyond level 7 the game continues in cycles (LV 8–12) with a point multiplier, tougher bosses and melting wax that slows Icarus down; catching WINGS restores him.
- Boss introductions, life loss and border flashes no longer pause the game; Icarus can always be moved.
- Bolts and boss attacks can reach every column, so no corner is safe.
- Slightly gentler difficulty curve.
- Kempston joystick in every menu: FIRE pauses; UP/DOWN/FIRE in the pause menu and for high-score initials.

### Fixes

- Border colour was reset to black by sound effects.
- Music OFF also silenced sound effects on 128K.
- Pressing M on the title screen started the game.
- Starting with SPACE opened the pause menu.
- Gold star value on the title screen was wrong (20 points, not 5).
- Stack leak when using RESTART/TITLE from the pause menu.
- Lives could wrap to 255 when hit twice in one frame.
- Inconsistent hitbox for falling debris.
- Garbled title screen on 128K machines.
- Overlapping on-screen messages.

## Version 1.0 — 2026-07-10

- Initial public release.
- Seven levels with increasing speed.
- Zeus, Cronos and Medusa boss encounters.
- Combo system and Top 5 high-score table.
- Keyboard and Kempston joystick support.
- 48K-compatible gameplay with AY music on compatible 128K models.
- Complete TAP release with loading screen.
