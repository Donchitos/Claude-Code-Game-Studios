# Chipset: endless-runner

**Camera:** `follow2d`, a side view with the runner toward the back of the screen; `fixed`
behind the runner for a 3D lane runner.

## Card defaults

- **best-distance**: The distance counts up at the top, the best distance is kept between visits,
  and one key runs again at once. Why: a run is short, and the next one can beat it. Break it when:
  a runner with set levels and an end, scored by stars.
- **fair-chunks**: The path is built from hand-made chunks joined in a new order, each one passable
  at the current speed, and the first stretch is always safe. Why: every death is the player's,
  never an impossible gap. Break it when: one hand-made course learned by heart.

## Feel

- **speeds-up**: The run starts slow and gets faster step by step until the player fails, and the
  view widens a little as it does, less with reduced motion. Why: the same few moves get harder with
  nothing new to learn, and the speed is felt. Break it when: a calm runner at one speed, where
  harder chunks bring the challenge.
- **forgiving-jump**: Late jumps off an edge and early presses before landing still count, and
  holding the key jumps higher. Why: a miss at full speed is the player's mistake, never the game's.
  Break it when: each press must land on the beat, a rhythm runner.
- **read-ahead**: Each kind of obstacle asks for one move, a jump over the low ones and a slide
  under the high ones; its shape says which, and it comes into view in time to react. Why: the
  player reads and reacts instead of guessing. Break it when: one move only, where every obstacle is
  jumped.
- **run-rhythm**: Footsteps keep time with the speed, and every jump, slide and landing has its own
  sound and a quick squash of the body. Why: the run has a beat the player falls into. Break it
  when: the runner is a still shape on purpose, an abstract line that never bends.

## Feel variants

- **tight**: Tight and quick: snappy jumps, fast falls, short runs.
- **flowing**: Flowing: speed carries through slides and drops in long, smooth lines.

## Choices that shape the pitch

- **Movement:** a side view where one key jumps (default) · three lanes from behind, with left,
  right, jump and slide, `fixed` · a jetpack or a gravity flip held to rise.
- **Stakes:** one hit ends the run (default) · a first hit slows you and a chaser closes in, a
  second ends it · a few hearts.
- **Pickups:** coins along risky lines, for the score (default) · none, distance only.
- **What the player sees:** from the side, `follow2d` (default) · from behind, `fixed`.
- **Feeling:** the player feels responsive precision by threading a gap at top speed, because the
  jump forgives a late press and the obstacle was readable in time.

## Later, never in a one-shot

- Coins spent on characters and upgrades → add it as a feature
- Missions and daily goals → add it as a feature
- Power-ups like a magnet or a shield → change it after play
- Scenery that changes the further you run → change it after play
- Online leaderboards and ghosts → needs a server: not built yet
- Swipe controls on phones → not tested yet: ask for it after play and the AI will try it untested
- A level mode with an end → grow it

## In a mashup

The runner leads the generated path, the speed and the score. A platformer leads the jump and its
forgiveness. Rhythm leads timing, and obstacles land on the beat. A roguelite leads upgrades between
runs and what carries over. A racing half leads the rivals, and the runner leads the path.
