# Chipset: survivors-like

**Camera:** `topdown`, kept on the player as the field scrolls; `static` for one arena that fits
the window.

## Card defaults

- **timed-run**: The run is a clock: survive until it runs out, with a boss at the end, and the time
  left and your level are always on screen. Why: the player knows how far the finish is, and each
  minute is harder than the last. Break it when: an endless run for a high score.
- **level-up-pick**: Each level pauses the horde and offers one of a few weapons or upgrades, each
  saying what it does, and a weapon already held goes up a level; the build has a few slots. Why:
  the build is the player's own, made of their choices. Break it when: the loadout is fixed before
  the run and nothing is picked in it.
- **evolve-recipe**: A weapon at its top level plus the right passive item evolves into a stronger
  one with a new effect, and the recipe is shown on both. Why: the player has a build goal to chase,
  and a combo nobody can find is no combo. Break it when: the run is too short for any weapon to
  reach its top level.

## Feel

- **move-only**: You only steer: every weapon fires on its own, at the nearest enemy or in its own
  pattern, and moving starts and stops at once. Why: one hand plays, and where you stand is the
  whole skill. Break it when: the person wants to aim by hand, a twin-stick shooter.
- **gem-magnet**: Beaten enemies drop gems that fly to you once you are near, and an upgrade can
  widen the pull. Why: the reward is seen and swept up without breaking the dodge. Break it when:
  levels come from time alone, with nothing to pick up.
- **horde-swells**: The crowd thickens minute by minute, a new kind of enemy arrives every so often,
  and each kind differs in one way you can see: fast, tough or shooting. Why: the pressure rises
  with the build, so the power is felt against something. Break it when: a calm run with a few
  enemies at a time.
- **power-shows**: Each weapon level changes what you see: one more blade, a wider ring, a bigger
  blast, never only a number, and your own effects stay paler than the enemies. Why: the build grows
  where the player is looking, and danger still reads at the peak. Break it when: upgrades are
  hidden numbers on purpose, a spreadsheet build the person asked for.

## Feel variants

- **swarm**: Swarm: a slow walk through huge crowds of weak enemies, a build that clears the screen.
- **arena**: Arena waves: short timed waves in one arena, fewer and tougher enemies, a shop between
  waves.
- **dodge**: Dodge: fewer enemies that fire patterns, quick movement, weaving between shots.

## Choices that shape the pitch

- **The run:** a timed run on an open field with a boss at the end (default) · short waves in one
  arena with a shop between them · endless, for a high score.
- **Builds:** one of a few on each level-up (default) · a few characters, each starting with its own
  weapon · items bought in a shop between waves.
- **Between runs:** gold for small permanent upgrades, saved (default) · new characters and weapons
  unlocked, no stat gains · nothing, each run alone.
- **What the player sees:** from above, following, `topdown` (default) · one arena, `static`.
- **Feeling:** the player feels power turn into release by walking through a crowd that chased them
  minutes before, because each level added a piece they chose.

## Later, never in a one-shot

- Many characters and stages → grow it
- A book of evolutions and unlocks found over many runs → grow it
- A chest that spins for several rewards at once → change it after play
- Protection from long runs of bad offers → change it after play
- A collection screen of every weapon and enemy seen → change it after play
- Two players on one screen → change it after play
- Daily seeded runs and leaderboards shared online → needs a server: not built yet

## In a mashup

The survivors-like leads the build and the horde: what the player picks, and how the crowd grows to
meet it. Movement leads the immediate feel, and aim and threats stay readable as the build grows. A
roguelite leads what a death resets and what carries over. A tower defense half leads placement, and
the horde walks a path. An RPG half leads the characters and their stats.
