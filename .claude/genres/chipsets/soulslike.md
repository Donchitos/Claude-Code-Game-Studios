# Chipset: soulslike

**Camera:** `orbit`, with a lock-on that frames you and the target; `follow2d` for a 2D
soulslike.

## Card defaults

- **drop-on-death**: Death sends you back to the last bonfire and leaves your souls where you fell;
  reach them to take them back, but die first and they are gone. Why: every death has a cost and a
  way to win it back. Break it when: failure should cost nothing, a boss rush where only the retry
  matters.
- **bonfire-rest**: Resting at the bonfire heals you, refills your flasks, saves, and spends souls
  on levels, and ordinary enemies come back; the boss waits a short run away. Why: the bonfire is a
  safe home, and the way back to the boss is short enough to try again. Break it when: there are no
  ordinary enemies, a boss rush with a rest between bosses.

## Feel

- **stamina-commit**: Attacks, rolls and blocks spend a stamina bar that refills when you pause, and
  an attack once started plays out. Why: every swing is a choice, and greed is punished. Break it
  when: the hero is meant to be fast and free, a game of long combos.
- **roll-through**: A roll is safe for a moment from its start, so the right move is to roll into a
  blow, not away from it. Why: the player masters timing, not distance. Break it when: blocking and
  deflecting are the defence, a duel where a roll is weak.
- **punish-window**: Enemies, bosses most of all, stop to recover after each run of attacks, the
  window to hit back, and a few hold a wind-up to catch a panicked roll. Why: a fight is a
  conversation the player learns to read. Break it when: enemies are a crowd to cut through, a hack
  and slash.
- **heal-commits**: Drinking a flask takes a moment that cannot be cancelled, and an enemy can hit
  you through it. Why: healing is a choice made in a gap, never a panic button. Break it when: the
  game is gentle, for players new to hard fights, and healing is instant.
- **lock-on**: One key locks on: the camera frames you and the target, and you circle and roll
  around it. Why: the player watches the enemy, never the camera. Break it when: many weak enemies
  come at once and a lock would hide the rest.

## Feel variants

- **heavy**: Heavy knight: slow, weighty blows, a shield held up, hits that stagger.
- **duelist**: Duelist: a block at the moment of a hit builds up and breaks the enemy's guard.
- **hunter**: Monster hunter: one great beast that limps when hurt, loses parts and runs off to
  rest.

## Choices that shape the pitch

- **Fights:** a short area of enemies, then a boss (default) · a boss rush, one boss after another
  with a rest between · one great monster to hunt.
- **Stakes:** souls dropped, won back once (default) · nothing lost, straight back to the boss ·
  everything lost on death, a hard mode.
- **Growth:** levels bought with souls at the bonfire (default) · a weapon made stronger at the
  bonfire · none, skill alone.
- **What the player sees:** behind the hero, `orbit` (default) · side view, `follow2d`.
- **Feeling:** the player feels hard-won mastery by beating a boss that killed them again and again,
  because each death taught one more attack and the way back was short.

## Later, never in a one-shot

- A second phase that changes the boss's moves → change it after play
- A connected world of shortcuts back to the bonfires → grow it
- Weapons, armour and builds with weight → add it as a feature
- Giant bosses framed from below → add it as a feature
- Help from other players, or invasions → needs a server: not built yet
- Monsters that fight each other in a hunt → not tested yet: ask for it after play and the AI will try it untested
- A story told through items and places → grow it

## In a mashup

The soulslike leads fights, stamina, death and the bonfire. A metroidvania half leads the map and
its gates, and the soulslike leads the benches and dropped souls. An RPG half leads builds and gear.
A roguelite half leads the run, and a death ends it instead of dropping souls. A character-action
half leads combos, and stamina keeps them short.
