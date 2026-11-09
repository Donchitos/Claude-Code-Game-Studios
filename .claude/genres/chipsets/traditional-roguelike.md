# Chipset: traditional-roguelike

Our research has few entries on the traditional roguelike itself: turn order, sight and monster
habits lean on turn logic and generated levels, and those lines carry the nearest entries.

**Camera:** `topdown`; `static` when a whole floor fits the window.

## Card defaults

- **floors-down**: Each floor is generated with stairs down, you start it with no monster in sight,
  and deeper floors are harder; the depth is on screen. Why: going down is a choice to push your
  luck. Break it when: the run is one big map with no floors, a single cave to clear.
- **monster-habits**: Monsters act in their own ways: some sleep until you come near, some keep
  their distance and shoot, some flee when hurt and come back. Why: each new monster is a small
  problem to read, and the first meeting teaches it. Break it when: there is one kind of enemy and
  the fight itself is the puzzle.
- **death-ends-run**: A death ends the run: the screen says what killed you and at what depth, and
  one key starts a new dungeon. Why: every choice counts, and a new run is a fresh puzzle. Break it
  when: the person wants progress kept, a roguelite where runs unlock things.

## Feel

- **turn-by-turn**: One key press is one turn: you step, or bump a monster to attack, and every
  monster answers at once; nothing moves while you think, and a held key walks on until a monster
  comes into view. Why: each danger can be weighed before acting, so a death is a mistake you could
  see. Break it when: the person wants to dodge in real time, an action roguelite.
- **sight-and-memory**: You see only what is in your line of sight; rooms already seen stay on the
  map, dimmed, and monsters out of sight are not drawn. Why: doors and corners hide danger, so each
  step into the dark is a choice. Break it when: each floor is one small room meant to be read at a
  glance.
- **read-the-turn**: A few lines of log say what just happened, who hit whom and what you picked up,
  and a number rises over each hit. Why: in a fight played in turns, the player reads what went
  wrong and what to try next. Break it when: there are few kinds of event and the pictures say it
  all.
- **close-call**: Low health shows plainly, the bar turns red and the hero dims, and a healing
  potion is always one key away. Why: the player sees the moment to flee or drink, and a narrow
  escape is their own. Break it when: health is hidden on purpose, a horror crawl.

## Feel variants

- **clever**: Clever: items and terrain combine, fire in tall grass or a potion thrown at a crowd,
  so a hard fight is solved by a trick.
- **brisk**: Brisk: small floors, many weak monsters, a whole run in a few minutes.
- **dread**: Tense and dark: short sight, scarce healing, monsters heard before they are seen.

## Choices that shape the pitch

- **Stakes:** a death ends the run, nothing kept (default) · a few unlocks carry over, a roguelite ·
  one revive item found in the dungeon.
- **Items:** named on sight (default) · unknown potions and scrolls, learned by using them · none,
  the hero grows only by levels.
- **Growth:** gear found on the way (default) · levels from kills · one of three boons after each
  floor.
- **What the player sees:** tiles from above, `topdown` (default) · letters on a grid, the
  classic look · a 3D board from a set angle, `fixed`.
- **Feeling:** the player feels clutch survival by escaping a fight they should have lost, because
  nothing moved while they thought and the way out was on the board.

## Later, never in a one-shot

- Hunger and food → change it after play
- Classes to pick at the start → add it as a feature
- Shops and gold → change it after play
- Allies who follow you and fight → add it as a feature
- Unlocks kept between runs → grow it
- Bosses at set depths → change it after play
- Hand-made vaults inside generated floors → grow it
- Auto-explore and travel by click → change it after play
- A daily seed shared online, with a ranking → needs a server: not built yet
- Stress that changes how the hero acts → add it as a feature

## In a mashup

The roguelike leads turns, generated floors and death. A deckbuilder half leads cards that replace
the hero's moves, and the dungeon stays turn by turn. An action half makes it a roguelite: action
leads movement and timing, and the run leads what carries over. An RPG half leads classes and stats.
A puzzle half leads hand-made floors with one answer each, and undo replaces death.
