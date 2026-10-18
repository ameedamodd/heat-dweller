# Heat Dweller

A close-to-home roguelite game where you travel through your house as different characters, surive RNG situations where no exact playthrough is the same, and uncover the mystery behind the arsonist.

---

## Core Game
- RNG-based events and loot
- Multiplayer dev project (collab)

---

## Status
Early development — systems are being built and may change a lot.

---

## Running Source Code

Heat Dweller uses the LÖVE2D framework. Install LÖVE 11.x, then run the
repository from its root directory:

```text
love .
```

The game entrypoint is `main.lua`; JavaScript and Electron are not required.

Use `WASD` to move and hold an arrow key or gamepad D-pad direction to fire
repeated sweat projectiles that way. Hold the left mouse button during a run to
fire toward the cursor. Matthew can strafe while firing in a separate direction.

New runs generate a seeded, procedural room layout. The title screen's
**Continue Run** option resumes the most recent run when a save is available.
Run data is stored in LÖVE's save directory as `heat_dweller_run.json` and is
updated periodically, when changing rooms, and when leaving the game.

At startup, the game plays `resources/gfx/cutscenes/mainmenucutscene.ogv` when
the optional intro video is present; press any key, button, or mouse button to
skip it. If unavailable, a cutscene template screen appears briefly and can
also be skipped. The title menu includes audio and screen-shake settings, a
discoveries/stats page, and a quit confirmation. Menu preferences and lifetime
run/item statistics are stored in LÖVE's save directory as
`heat_dweller_profile.json`.
Press Enter or gamepad A at the opening title screen to reach the main menu.

For narrative context, architecture, gameplay-system ownership, and AI handoff
notes, see [HEAT_DWELLER_CODEBASE_GUIDE.md](./HEAT_DWELLER_CODEBASE_GUIDE.md).

---

## Dev Team

- dotZIP-A1 — Developer
- dotAndres — Creative Director