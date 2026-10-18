# Resources

This folder is grouped by how the game uses each asset.

## Runtime assets

- `font/` - fonts loaded by the HUD and menus.
- `gfx/` - current animation spritesheets, UI art, enemies, items, and health assets.
- `music/` - streamed music and sound effects.
- `sprites/` - character-select portraits and older gameplay sprite layouts.

## Game data

- `*.xml` - XML definitions for characters, items, enemies, bosses, health, audio, and achievements.
- `data/` - Lua data prototypes and the current prototype configuration.

## Scripts

- `scripts/` - item and collectible behavior scripts.
- `gfx/scripts/` - older graphics-side collectible prototype.

## Notes

The active LÖVE entrypoint is the repository's `main.lua`. Keep paths inside runtime Lua files and XML definitions stable when renaming or moving assets. The `sprites/`, `data/`, and `gfx/scripts/` groups contain older prototype content; they are kept separate because they are not all used by the current entrypoint yet.
