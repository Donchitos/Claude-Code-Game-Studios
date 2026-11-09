# Chipset: beat-em-up

**Camera:** `follow2d`, a side view with a strip of depth to walk up and down; `fixed` for a 3D
brawler at a set angle.

## Card defaults

- **stop-and-go**: The stage scrolls on; the screen stops at each fight until the group is beaten,
  then an arrow and the word Go point the way on. Why: the player always knows when to fight and
  when to move. Break it when: the fights are all in one arena, a survival mode of endless waves.
- **food-in-crates**: Barrels and crates break, and some hold food that heals or a bag of points.
  Why: a hurt player has a reason to smash the scenery, and some hope. Break it when: health never
  comes back on purpose, a one-life score run.
- **enemy-bar**: The enemy you hit shows its name and health at the top of the screen. Why: the
  player sees how close the thug is to falling. Break it when: crowds are so big that one bar means
  nothing, a horde game.

## Feel

- **combo-knockdown**: Tapping attack strings a few hits, and the last one knocks the enemy off
  their feet and away. Why: a combo has a beginning and a big end. Break it when: every hit is one
  heavy blow, a slow brawler of single punches.
- **grab-and-throw**: Walking into a dazed enemy grabs them, and a throw sends them into the crowd,
  knocking down whoever they hit. Why: one enemy becomes a weapon against the rest. Break it when:
  enemies are too big or too few to throw, a fight with one giant.
- **lane-align**: Attacks nudge you into line with the enemy you face, so standing a little above or
  below never makes a swing miss. Why: the depth strip is the genre's old trap, a miss that looked
  like a hit. Break it when: the stage is flat, one line of fighters with no depth.
- **crowd-breaker**: A special clears the enemies all around you at a small cost to your health.
  Why: being surrounded is never being stuck. Break it when: being surrounded is the danger to
  avoid, a careful fight with no way out.

## Feel variants

- **arcade**: Arcade: quick and punchy, enemies drop fast, a score at the end of each stage.
- **heavy**: Heavy and grounded: slower blows that land hard and send people flying.
- **juggle**: Juggles: launch enemies and keep them in the air, a combo game with levels.

## Choices that shape the pitch

- **Players:** one (default) · two on one keyboard or gamepads, the classic couch co-op (local
  co-op).
- **Stakes:** a few lives, a lost life restarting on the spot (default) · one life, an arcade
  score run · no lives, a retry from the last fight.
- **Growth:** the moves you start with (default) · levels and new moves between stages · weapons
  picked up from the ground, pipes and knives.
- **What the player sees:** side view, `follow2d` (default) · a 3D street at a set angle,
  `fixed`.
- **Feeling:** the player feels cathartic power by throwing one thug into a crowd and knocking them
  all down, because the throw is easy and the crowd falls in a chain.

## Later, never in a one-shot

- Enemy groups whose roles work together, a shield, a thrower, a leader
  → not tested yet: ask for it after play and the AI will try it untested
- Many stages, each ending on a boss → grow it
- A cast of heroes with different moves → grow it
- A late moveset that adds a new tool → grow it
- Weapons that break after a few hits → change it after play
- Bonus stages, a car to smash → change it after play
- Co-op online → needs a server: not built yet

## In a mashup

The beat-em-up leads crowds, combos and the stage's stop and go. A character-action half leads
style, dodges and juggles. An RPG half leads levels and gear, and the brawling stays simple. A
platformer half leads the jumps between fights. A fighting half leads move lists, and the stage
stays a street full of thugs.
