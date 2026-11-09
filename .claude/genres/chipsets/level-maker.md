# Chipset: level-maker

**Camera:** `follow2d`, a side view for building and playing; `topdown` for a top-down maker;
`orbit` for a small 3D build.
**Online:** Levels are saved in this browser, played by their maker or passed to a friend at
the same screen. Sharing levels between machines, browsing other people's levels, likes and
building together online need a server: not built yet.

## Card defaults

- **ready-parts**: A small palette of ready parts, ground, a hazard, a coin, an enemy and the goal,
  that snap to a grid and work the moment they are placed. Why: a novice makes a playable level in a
  minute. Break it when: the person wants to make the parts too, their art and their rules.
- **clear-to-save**: A level is saved, with a name, only after its maker plays it through to the
  goal. Why: every saved level is proven winnable. Break it when: a toy with no goal, a scene to
  play about in.
- **sample-level**: The editor opens on a short level already made, to play first and then change.
  Why: the first edit is a small change, not a blank grid. Break it when: the person asks for a
  blank canvas.

## Feel

- **play-from-here**: One key plays the level from the cursor or the start, and a death or a second
  press drops you back into the editor at that spot. Why: the person tries an idea seconds after
  placing it. Break it when: the editor makes a picture, not a level to play.
- **undo-any-edit**: Every placement and erase can be undone with no limit, and erasing is a quick
  drag. Why: building is trying, and nothing is lost by it. Break it when: placing parts is itself
  the puzzle, a short set where each placement counts.
- **pop-in-place**: Each part pops in with its own sound and a small bounce, and ground joins its
  neighbours so a rough shape looks finished. Why: building feels like play, and the level looks
  good from the first stroke. Break it when: the look is drawn by hand, tile by tile, on purpose.

## Feel variants

- **playful**: Playful and quick: big chunky parts, silly hazards, a level made and played in a
  minute.
- **tinkerer**: Tinkerer: parts wire together, a switch opens a door and a timer moves a platform,
  so a level becomes a machine.

## Choices that shape the pitch

- **What you make:** side-view jump-and-run levels (default) · grid puzzles, each saved only once
  solved · top-down mazes and dungeons · a small 3D build, `orbit`.
- **Who plays:** you, then a friend at the same screen (default) · one builds and the other must
  clear it, then swap · levels shared online (later).
- **Start:** a short sample level to change (default) · a blank grid.
- **Feeling:** the player feels creative ownership by playing a level they made a minute ago,
  because the parts worked at once and the switch to play is instant.

## Later, never in a one-shot

- Sharing levels online, with browsing, likes and play counts
  → needs a server: not built yet
- Building one level together on two machines → needs a server: not built yet
- A full rules editor of events, conditions, camera and screens → add it as a feature
- Mods that change the game's own data → not tested yet: ask for it after play and the AI will try it untested
- Mod versions and downloads when joining a friend → needs a server: not built yet
- Checkpoints in made levels, each start proven winnable → change it after play
- Parts with their own art and sound, made in the editor → add it as a feature

## In a mashup

The maker leads the editor, the palette, saving and the proof that each level can be cleared. The
game it makes leads play: a platformer half leads movement and the jump, a grid-puzzle half leads
the rules and undo, a racing half leads the track and the laps. A sandbox half leads free building
with no goal, and the clear-to-save check is dropped.
