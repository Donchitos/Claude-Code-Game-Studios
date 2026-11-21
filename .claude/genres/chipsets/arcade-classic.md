# Chipset: arcade-classic

Our research has few entries on single-screen arcade games: snake, maze chase, breakout, invaders,
asteroids and growth games share these lines, which carry the nearest score, input and growth
entries. A named game is a reference; the card's fan-game rule handles copies.

**Camera:** `static`, one screen that fits the window; `follow2d` for a growth game whose view
follows and zooms out as you grow.

## Card defaults

- **best-score**: The score sits at the top beside the best score, which is kept between visits, and
  the game-over screen says when it is beaten. Why: every run has a number to beat. Break it when: a
  growth game played for size, or a calm toy with no score.
- **lives-and-extra**: A few lives, shown as icons, an extra life at a score, and a short safe
  moment after each death. Why: arcade stakes, with a reward for playing well. Break it when: one
  life a run, a quick game that restarts at once.
- **gets-faster**: Each cleared screen or wave comes back faster or busier, and the level number is
  on screen. Why: the same screen stays a challenge as the player gets better. Break it when: a
  growth game, where getting bigger is the change.

## Feel

- **instant-turns**: The player moves the moment a key is pressed, and a turn pressed a moment early
  is remembered, so a quick pair of turns both count. Why: a death is the player's mistake, never a
  dropped key. Break it when: a drifting ship with momentum, where the slide is the skill.
- **fair-collisions**: The player's hit area sits a little inside the sprite, and pickups are caught
  a little outside it. Why: a near miss looks like one, and a grab that looks like a grab counts.
  Break it when: exact edges are the challenge on purpose, squeezing through the tightest gaps.
- **score-pops**: Every score pops up where it was earned, and quick kills or pickups in a row raise
  a multiplier shown beside the score. Why: playing fast and close is seen to pay. Break it when:
  the score is plain counting, as a snake's length.

## Feel variants

- **frantic**: Fast and frantic: the speed climbs quickly, big chains, short runs.
- **steady**: Steady and readable: a slow start, a pattern to learn, long runs.
- **snowball**: Snowballing: you grow, and what chased you becomes what you eat.

## Choices that shape the pitch

- **What you play:** a maze chase, eat every dot while enemies hunt you (default) · a snake that
  grows · a ball and paddle against bricks · a descending fleet to shoot down · a ship among
  drifting rocks · eat smaller things to grow.
- **Stakes:** a few lives, then game over (default) · one life, restart at once · no
  failure, a timed round for score.
- **Speed:** each level faster (default) · speed that rises with the score · the same speed,
  more enemies.
- **What the player sees:** one screen, `static` (default) · a view that follows and zooms out as
  you grow, `follow2d`.
- **Feeling:** the player feels the pull of one more go by beating their best by a little, because
  the run was short, the death was their own and the restart is one key.

## Later, never in a one-shot

- An online high-score table → needs a server: not built yet
- Initials on a high-score table → change it after play
- Each enemy with its own chase rule → change it after play
- Two players taking turns or together → change it after play
- A demo that plays itself on the title screen → change it after play
- Growth through many stages of scale → grow it
- A daily seeded challenge → change it after play
- A level editor → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

The arcade game leads the screen, the score and the lives. A roguelite leads upgrades between
runs and what carries over. A puzzle half leads the rules of the board. Rhythm leads timing, and
moves land on the beat. A management half leads money spent between rounds, and the arcade game
keeps each round short.
