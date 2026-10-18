# Heat Dweller: Lore, Systems, and Codebase Guide

This guide summarizes the narrative reference supplied for *Heat Dweller* and
the implementation visible in the current repository. It is intended as a
handoff document for future developers and AI assistants. Narrative statements
in the lore section come from the official lore reference supplied with the
request; implementation statements describe the code as it currently exists.
Where those differ, this guide calls out the distinction rather than treating
planned story as already implemented content.

## 1. Narrative Premise and Lore Context

### The child and the house

Matthew is an eight- or nine-year-old child. He sees himself as living in an
ordinary, loving home with his father and does not understand the danger or
secrets surrounding him. His immediate, childlike goal is to find a piece of
candy in the basement. That small domestic errand becomes the starting point
for an ordeal much larger than he can comprehend.

Mark, Matthew's father, loves his son unconditionally, but he is struggling
with severe anger-management problems after a difficult divorce. Mark is also
part of a secret group of divorced fathers called the Arsonists. The cult
channels resentment into targeted arson: its members burn houses in order to
make children orphans as a grotesque form of revenge.

The central tragedy is Mark's failure to tell the other Arsonists to spare his
own house. While Matthew is downstairs looking for candy, the cult sets the
house on fire. Matthew does not realize what is happening above him until the
fire has made escape impossible.

### Nightmare as the playable world

The basement is both a physical place and the point of view through which the
player experiences Matthew's crisis. Its rooms, enemies, and hazards take on a
feverish, surreal quality as heat, smoke, fear, and the child's limited
understanding blur together. The strange monsters are not necessarily
literal creatures in a normal house; they can be read as the nightmare logic
of a child trapped in an overwhelming emergency.

The reference names Scar, spiders, and flies as examples of the bizarre
creatures Matthew encounters. That imagery supports psychological surrealism:
ordinary surroundings become threatening, and a desperate survival journey is
filtered through a child's perception.

### The ascent and Kagutsuchi

Matthew does not escape the burning house in the physical world. Instead, his
journey carries him through surreal depths and then upward toward the sky or
heaven. The ultimate confrontation is with Kagutsuchi, also called Kagu, the
entity worshipped by the Arsonists and described in the lore as the source of
their destructive influence.

This ascent gives the roguelite journey a tragic double reading. In gameplay,
the player advances through floors and defeats bosses; in the narrative, the
upward movement may represent Matthew's final passage beyond the burning
house. The exact metaphysical interpretation is intentionally presented as
surreal rather than explained as ordinary physical geography.

### Lore-to-implementation boundary

The reference above is the canonical narrative brief supplied for this guide.
The current gameplay progression covers the basement, living room, kitchen,
bedroom, attic, roof, and sky, with The Crawler, Lil' Snake, and The Geometric
available as boss encounters. Heaven and Fireland (Kagu) are not implemented as floors, and
Kagutsuchi is not implemented as a boss. The full Arsonist/Mark backstory is
not encoded in gameplay dialogue. Treat those elements as official narrative
direction, not as proof that those scenes or encounters are already present
in code.

## 2. Technical Architecture and Code Summary

### Framework and entry point

The project is a LÖVE 2D game written in Lua. Run it from the repository root
with `love .` after installing a compatible LÖVE 11.x runtime. `main.lua` is
the application entry point and owns LÖVE callbacks, global game-state
orchestration, persistence, audio setup, combat coordination, and transitions.
Gameplay systems are split into required Lua modules; art, audio, fonts, JSON,
and XML data live under `resources/`.

The main LÖVE lifecycle is:

1. `love.load()` configures the window and nearest-neighbor default filtering,
   initializes profile and item data, creates the world/player/input/render
   objects, initializes audio, then loads the optional opening cutscene.
2. `love.update(dt)` dispatches by `gameState`, advances transitions and audio,
   and, while playing, updates input, player, enemies, items, projectiles,
   boss state, and room progression.
3. `love.draw()` dispatches title/cutscene/boss/transition/game-over screens or
   draws the active room, entities, combat effects, and HUD.
4. `love.resize()` updates camera bounds to the new graphics dimensions and
   refreshes the runtime display audit.

### Core modules

| File | Responsibility |
| --- | --- |
| [`main.lua`](./main.lua) | LÖVE callbacks; game-state flow; world setup; audio/profile/save handling; combat and progression orchestration; rendering dispatch; resize/window diagnostics. |
| [`conf.lua`](./conf.lua) | LÖVE configuration: gamma correction, initial window mode, high-DPI setting, resizability, and vsync. |
| [`player.lua`](./player.lua) | Player state, movement, directional facing, damage/invulnerability, hurt animation timing, collectible effects, and sweat-shot cooldown/recoil. |
| [`input.lua`](./input.lua) | Keyboard movement and held attack directions, gamepad D-pad input, and configurable bindings. |
| [`renderer.lua`](./renderer.lua) | Sprite/atlas drawing, HUD, boss health, projectiles, and other screen-space UI. |
| [`mainmenu.lua`](./mainmenu.lua) | Title/menu sections, settings, extras, pause UI, selection, back-stack navigation, transitions, and menu visuals. |
| [`rooms.lua`](./rooms.lua) | Seeded procedural room graph and layouts, enemies, shops, item rooms, boss rooms, and cultist-deal room placement. |
| [`items.lua`](./items.lua) | XML-driven item definitions, inventory, pickup/offer behavior, stat effects, active items, and notifications. |
| [`atlas.lua`](./atlas.lua) | Loads character sprite metadata and creates frame quads used for animation. |
| [`sweat_projectile.lua`](./sweat_projectile.lua) | Sweat projectile construction, movement, wall/enemy collision, damage, range limit, and splash lifetime. |
| [`acid_projectile.lua`](./acid_projectile.lua) | Enemy projectile behavior and player collision. |
| [`firefoam.lua`](./firefoam.lua), [`wet.lua`](./wet.lua) | Directional fire-foam beam and wet/fire interaction support. |
| [`enemy.lua`](./enemy.lua), [`spider.lua`](./spider.lua), [`fly.lua`](./fly.lua) | Regular enemy behavior and specialized spider/fly implementations. |
| [`crawler.lua`](./crawler.lua), [`lil_snake.lua`](./lil_snake.lua), [`the_geometric.lua`](./the_geometric.lua), [`baby_widow.lua`](./baby_widow.lua) | Boss/minion state, attacks, movement, and related animation/combat behavior. |
| [`json.lua`](./json.lua) | JSON encoding/decoding used for local persistence and metadata. |

The `resources/data/` and `resources/gfx/scripts/` trees include additional
game/renderer/item support modules. XML files such as `resources/items.xml`
provide data definitions; atlas and animation JSON files describe sprite
frames. Prefer extending the system that already owns the behavior instead of
adding duplicate orchestration to `main.lua`.

### Display, scaling, and color

`conf.lua` requests a 1280×720 standard bordered, resizable window, with
`fullscreen = false`, `highdpi = false`, and `gammacorrect = false`. During
`love.load()`, `main.lua` maximizes the window if the runtime exposes the
maximize APIs. Pressing **F** toggles between the maximized state and a
centered 1280×720 bordered window. The resize callback updates camera width and
height from the current graphics dimensions.

Nearest-neighbor filtering is set globally with
`love.graphics.setDefaultFilter('nearest', 'nearest')` and explicitly applied
to loaded image/font resources in their owning modules. Keep that filtering
when adding pixel-art assets.

There is no application-created main render canvas or active post-processing
shader pipeline in the current code. The main game is drawn directly through
LÖVE's graphics context. `main.lua` has a display audit that logs window and
graphics dimensions, DPI scale, fullscreen/borderless flags, active canvas
dimensions/format if any, current draw/clear colors, and blend mode on resize
and around the **F** toggle. These logs are diagnostic instrumentation; they
do not perform color correction.

### Game state, menus, and input

`main.lua` represents the application flow with a `gameState` string. States
include the opening video/fallback, title/menu, character selection, active
play, pause/item selector, boss intro, floor transition/completion, and game
over. LÖVE key, mouse, and gamepad callbacks route events to the current
state's owner. The menu itself owns section navigation and returns actions
such as starting/continuing a run or quitting; the main module performs those
actions.

The menu has a title prompt, main options, settings, extras/stats, and quit
confirmation. It supports keyboard, mouse, and gamepad navigation; includes
back navigation and transitions; and provides music/SFX volume and screen
shake settings. If `resources/gfx/cutscenes/mainmenucutscene.ogv` is present,
it plays before the title screen and can be skipped; otherwise a short
template fallback appears.

Gameplay movement uses **WASD**. Keyboard arrow keys or gamepad D-pad
directions fire held/repeating sweat shots. Holding the left mouse button aims
at the cursor. Movement and aim are independent, so Matthew can strafe while
shooting. `input.lua` is the owner for persistent key bindings and held
direction state; `main.lua` performs mouse-coordinate conversion and invokes
the player's attack method.

### Combat and damage feedback

The primary player projectile is the sweat drop rendered from
`resources/sprites/attack/sweatattack.png`. `sweat_projectile.lua` normalizes
the input direction and sets `vx`/`vy` from its angle at a constant speed.
Each update advances linearly; there is no gravity, fake height, parabolic
arc, or added launch spread. The projectile starts near Matthew's head,
travels up to a fixed range, and is removed on enemy/wall collision or range
expiry. Enemy impacts apply damage and create a brief
`sweat_splash.png` effect. The sprite is drawn at the projectile's actual
world-space Y coordinate, with no vertical visual offset.

`player.lua` sets the player’s default internal movement speed to 350 in the
game setup and the internal damage stat to 20. Sweat-shot cooldown is
controlled by the player's attack-rate state. Current sweat projectile damage
is 20% of the internal damage stat, so the default shot deals 4 damage.
Shooting still updates facing and applies a subtle recoil impulse; it no
longer transfers movement momentum into projectile velocity.

Enemy attacks also include acid projectiles and other entity-specific contact
or attack behavior. The directional fire-foam weapon is a separate beam system
and should not be conflated with the sweat projectile's linear physics.

Taking damage triggers Matthew's hurt animation, hurt audio, temporary
invulnerability, and a screen shake. The hurt animation lasts 0.4 seconds;
invulnerability lasts 1.0 second; the shake lasts 0.2 seconds with a
4–6-pixel magnitude. Screen shake can be disabled through settings.

### Stats and HUD

Internal values are not rescaled to make the UI look normalized. The HUD
converts them only when formatting the displayed player stats:

| HUD label | Display value | Baseline/display rule |
| --- | --- | --- |
| Damage | `player.stats.damage / 20` | Internal default 20 displays as 1. |
| Speed | `player.speed / 350` | Internal default 350 displays as 1. |
| Attack | `(player.stats.attackSpeed or 1) / 1` | Default fallback displays as 1; the current combat cadence is primarily driven by `fireRate` and shot cooldown. |
| Range | `112 / 112` | Currently a fixed display baseline of 1, not a player-modifiable projectile-range stat. |
| Defense | `player.stats.defense or 0` | Defaults to 0; a defense stat is not otherwise initialized in the current player defaults. |

`renderer.lua` formats whole numbers without a decimal and modified
non-integers with one decimal place. This conversion is for presentation only;
combat, movement, and item calculations continue using the underlying values.

### Procedural rooms, items, and progression

`rooms.lua` builds a connected room graph for each supported floor from a
deterministic seed and constructs room walls/enemy placements. Every floor
selects The Crawler, Lil' Snake, or The Geometric for its boss room and
generates shop/item/deal rooms. Layouts also carry floor-specific props and
solid obstacles, but no floor hazards or environmental physics modifiers.
`main.lua` renders distinct procedural floor themes, scales the shared ambient
track's volume by floor, shows a fade-in/fade-out floor-name card during
transitions, and handles room entry, boss progression, rewards, and advancement
through the basement, living room, kitchen, bedroom, attic, roof, and sky. The
Geometric uses a 224px sprite body and matching broad projectile/contact
collision, with destructible orbiting head armor, two heads at half health and
four at quarter health, a temporary invulnerability phase at one-eighth
health, and a revived bouncing head as its final phase.
Heaven and Fireland (Kagu) are not part of the current floor sequence.

Item data is parsed from `resources/items.xml`. `items.lua` creates the
inventory, loads available sprites with nearest filtering, applies passive
stat changes, handles active-item cooldowns and pickup/offer state, and emits
stat-change notifications. Active item logic is connected through
`main.lua`; new item effects should follow the existing item data and active
action conventions.

### Audio and persistence

`main.lua` coordinates the menu theme, background/floor music, boss intro and
loop music, hurt sounds, pickup sound, menu tones, and floor-transition
audio. Audio settings are propagated through the menu settings callback.
Avoid starting menu music during the opening cutscene; the cutscene completion
path owns the transition to the menu.

Persistence is stored in LÖVE's save directory, not beside the source files:

- `heat_dweller_run.json` stores the current run: seed, floor/room graph and
  flags, player state/stats, inventory, active items, enemy/boss state, and
  related progression. Continue logic validates the snapshot version and
  required data before restoring it.
- `heat_dweller_profile.json` stores longer-lived preferences and summary data
  such as settings, run/boss totals, and item discovery/count information.

When modifying save fields, update both snapshot creation and continue/restore
logic, and preserve validation/default handling for older or malformed data.

## 3. Summary for Future AI Collaborations

### Quick-reference checklist

- **Runtime:** LÖVE 11.x, Lua; `main.lua` is the callback/orchestration entry
  point. Run from the project root with `love .`.
- **Window:** Starts 1280×720, bordered/resizable, high-DPI off; maximizes in
  `love.load()` when supported. **F** toggles maximize/restore-to-1280×720.
- **Pixel art:** Preserve global and explicit `nearest, nearest` texture/font
  filtering. Do not add a CRT, blur, or color-grading pass unless explicitly
  requested.
- **Module ownership:** Keep player rules in `player.lua`, input polling and
  bindings in `input.lua`, drawing in `renderer.lua`, menu state/UI in
  `mainmenu.lua`, room generation in `rooms.lua`, item data/effects in
  `items.lua`, and sweat projectile physics in `sweat_projectile.lua`.
- **Main-module role:** `main.lua` connects those systems and owns run
  progression, high-level state transitions, persistence, and shared audio.
- **Player controls:** WASD moves; arrow keys/D-pad hold-to-fire; mouse-left
  aims and fires; movement and firing directions are independent.
- **Projectile rule:** Sweat travels in a straight linear vector with fixed
  speed, collision checks, fixed range, and brief impact splash. No arc,
  vertical height, gravity, spread, or movement-momentum transfer.
- **Damage scale:** Default internal damage is 20, but sweat applies 20% of
  that value per hit (4 at default). Preserve this distinction when changing
  damage or the HUD baseline.
- **Displayed stats:** Normalize only when rendering: damage ÷20, speed ÷350,
  attack ÷1, range currently 112÷112, defense fallback 0. Do not mutate
  internal physics values to normalize the UI.
- **Damage feedback:** Hurt animation 0.4s, i-frames 1.0s, screen shake 0.2s
  and 4–6 pixels; shake respects the saved setting.
- **Procedural progression:** Seeded room graphs for basement, living room,
  kitchen, bedroom, attic, roof, and sky, with Crawler, Lil' Snake, and
  Geometric bosses.
  Heaven and Fireland (Kagu) remain out of scope.
- **Data/assets:** Item definitions are XML-driven; animation/frame data is
  JSON-driven; sprites, fonts, and audio are under `resources/`.
- **Save compatibility:** Update both save serialization and restore paths
  for persistent run changes. Keep profile/preferences distinct from the
  active-run snapshot.
- **Validation:** Use `luac -p` on changed Lua files and run targeted behavior
  checks. Check editor diagnostics after editing; there is no guarantee that
  every subsystem has a standalone automated test suite.
- **Documentation accuracy:** Clearly separate official lore, current code,
  and future narrative plans. Do not claim a story scene, boss, floor, shader,
  or gameplay feature is implemented merely because it appears in the design
  reference.
