# Chipset: twin-stick-shooter

**Camera:** `topdown`, between the player and where they aim; `static` for one arena that fits
the window.

## Card defaults

- **waves-and-score**: One arena, enemies in waves that grow, and a score with a multiplier on
  screen that a hit resets; the best score is kept. Why: every second alive is worth more than the
  last. Break it when: the game is rooms to clear and a door to reach, with no score.
- **enemy-jobs**: A few kinds of enemy, each with its own job: one chases, one wanders, one shoots,
  one splits when hit. Why: the player reads a crowd by its shapes and picks what to shoot first.
  Break it when: one horde of the same enemy is the point, a survive-the-swarm game.

## Feel

- **move-and-aim**: One hand moves at the same speed every way, the other aims, and the gun fires
  where you point while you keep moving; a gamepad gets a small aim help, a mouse none. Why: dodging
  and shooting are two jobs done at once. Break it when: one button fires the way you face, a
  simpler arcade shooter.
- **camera-leads-aim**: The camera sits between the player and the aim point, so more of the screen
  lies where you shoot. Why: the threat you aim at is in view before it reaches you. Break it when:
  the whole arena fits the window and the camera never moves.
- **gun-kick**: Every shot flashes at the muzzle and kicks the player back a hair, and bullets are
  big, fast and easy to follow. Why: the gun feels strong without a word on screen. Break it when:
  the weapon is soft and silent on purpose, a toy or a beam of light.
- **spawn-warning**: New enemies flash in place a moment before they are real and never appear right
  beside the player, adding to the starter's enemy fairness. Why: a death comes from a choice, never
  from a spawn. Break it when: enemies walk in through set doors at the edges.

## Feel variants

- **swarm**: Neon swarm: one arena, crowds that keep growing, one hit and a life is gone.
- **bullet-dodge**: Bullet dodge: rooms of shooters, a dodge roll through their bullets, health that
  matters.
- **heavy-gun**: Heavy guns: slow, strong shots with a big kick, fewer and tougher enemies.

## Choices that shape the pitch

- **Arena:** one arena, endless waves (default) · rooms cleared one by one · a run of generated
  rooms, a roguelite.
- **Stakes:** a few lives and a high score (default) · one life · health, and pickups that heal.
- **Weapons:** one gun that grows with pickups (default) · a few guns with different jobs · ammo
  earned by kills.
- **Players:** one (default) · two on one keyboard or gamepads (local
  co-op).
- **What the player sees:** from above, `topdown` (default) · one arena that fits the window,
  `static`.
- **Feeling:** the player feels fearless aggression by diving into a crowd to keep the multiplier,
  because each kill keeps it climbing and each enemy reads at a glance.

## Later, never in a one-shot

- Enemies that flank, take cover and call to each other → not tested yet: ask for it after play and the AI will try it untested
- Bosses with phases → change it after play
- A bomb that clears the screen → change it after play
- Weapons and builds unlocked between runs → grow it
- Cover that breaks apart → add it as a feature
- Shields and weak points that need a different aim → change it after play
- Scores shared online → needs a server: not built yet
- Co-op online → needs a server: not built yet

## In a mashup

The twin-stick leads movement, aim and the arena. A roguelite half leads the run, the rooms and
what carries over. An RPG half leads loot and levels. A tower-defense half leads building
between waves, and the shooting stays by hand. A stealth half leads guards and sight, and the
shooting is the plan that failed.
