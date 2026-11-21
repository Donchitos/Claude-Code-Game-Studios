# Chipset: character-action

**Camera:** `orbit`, with a lock-on that keeps the target in view; `fixed` for set angles in
each room, `follow2d` for a side-on 2D one.

## Card defaults

- **style-rank**: A style rank on screen rises with varied hits and falls when you repeat a move or
  get hit, and each fight ends on a grade. Why: the player is pushed to fight well, not only to win.
  Break it when: the fight is about surviving, not showing off, a grim duel.
- **arena-waves**: Each fight closes you into an arena with a few waves of enemies, the last one the
  hardest. Why: a fight has a shape, and the last wave tests everything learned in it. Break it
  when: enemies roam an open world and a fight can start anywhere.

## Feel

- **combo-strings**: Tapping attack strings a combo, a pause in the middle changes it, and a press
  made early comes out the moment the last hit ends. Why: the player writes the combo with their
  timing. Break it when: there is one attack, a game about a single perfect strike.
- **dodge-cancel**: A dodge comes out of any attack's follow-through and is safe from its first
  frame, and a dodge at the last moment slows time for a beat. Why: defence never waits for an
  animation, and a close dodge pays. Break it when: attacks commit you on purpose, a heavy duel
  where a swing cannot be stopped.
- **launch-juggle**: An uppercut launches an enemy, a jump follows it, and hits in the air keep it
  there. Why: the air is a second stage for the combo. Break it when: fights stay on the ground, a
  martial-arts duel of guard and stance.
- **soft-lock**: Attacks turn you toward the enemy you push toward and close a short gap, and one
  key locks the camera onto it. Why: the hit goes where the player meant. Break it when: aiming each
  swing by hand is the skill.

## Feel variants

- **stylish**: Stylish and flashy: long combos, launches, a slowdown on every perfect dodge.
- **duelist**: Duelist: fewer, tougher enemies, and a block at the moment of a hit breaks their
  guard.
- **mighty**: Mighty: a hero of great power who sends whole crowds flying.

## Choices that shape the pitch

- **Defence:** dodges (default) · blocks at the last moment that break an enemy's guard, the
  martial-arts way · health won back by hitting back after a hit.
- **Structure:** a few arenas in a row, each graded (default) · one boss fight to master · endless
  waves for a high score.
- **Hero:** a sword fighter (default) · bare hands and martial arts · a superhero with powers.
- **What the player sees:** behind the hero, `orbit` (default) · set angles, `fixed` · side-on,
  `follow2d`.
- **Feeling:** the player feels fearless aggression by dodging through a blow and straight into a
  combo, because a close dodge pays and the style rank climbs.

## Later, never in a one-shot

- Weapons switched in the middle of a combo → add it as a feature
- Upgrades that add new moves → add it as a feature
- Music that grows with the style rank → change it after play
- Giant bosses with a camera of their own → change it after play
- Finishers driven by pressing again and again → change it after play
- Cutting objects along a line you choose → add it as a feature
- Enemy groups that combine their attacks as a team → not tested yet: ask for it after play and the AI will try it untested
- Cutscenes and dramatic camera moments → grow it

## In a mashup

Character action leads combos, dodges and the style rank. An RPG half leads levels and gear, and
gear never replaces skill. A rhythm half leads timing, and attacks land on the beat. A roguelite
half leads the run and what carries over. A platformer half leads the jumps between arenas, and a
beat-em-up half leads crowds along a stage.
