# Chipset: tactical-rpg

**Camera:** `static`, one battle grid that fits the window; `strategy` for a larger map with pan
and zoom.

## Card defaults

- **reach-shown**: Picking a unit lights the tiles it can reach and the enemies it can hit from
  there, and a move can be taken back until the unit acts. Why: the plan is made on the board, not
  in the head. Break it when: hidden ground is the point, a fog where enemies are unseen.
- **odds-shown**: Before an attack, the damage both ways and the chance to hit are shown, the chance
  shown is the real one, and a run of misses is softened. Why: a risk is taken with open eyes, and
  luck never feels like cheating. Break it when: every attack lands, a puzzle with no dice.
- **battle-goal**: The battle's goal and the turn number are always on screen: beat every enemy,
  hold out a few turns, or reach a tile. Why: every move is weighed against the goal. Break it when:
  a single skirmish where beating everyone is plain.
- **between-battles**: After a battle each surviving unit gains experience, a level-up shows what
  grew, and a fallen unit sits out the next battle. Why: the party grows, and losing a unit costs
  something without ending the game. Break it when: one battle alone, or permadeath the person asked
  for.

## Feel

- **intent-shown**: Every enemy marks the tiles it will hit next turn and for how much, and what is
  marked is exactly what happens. Why: a loss is a misread, and one good move can save several
  units. Break it when: the person wants fog and surprise, enemies found rather than read.
- **push-combos**: Some attacks push or pull a unit a tile; an enemy pushed into another, into water
  or into its ally's attack takes the hit the same way every time, and the preview shows where
  everyone ends up. Why: one clever move solves several threats at once. Break it when: units hold
  their ground, and position matters only for reach.
- **quick-enemy-turn**: The enemy turn plays one unit at a time with the view following each, and a
  key speeds it up with the same result. Why: the player sees what happened, and waiting never
  drags. Break it when: both sides move at once, a plan-then-play game.

## Feel variants

- **puzzle**: Puzzle-tight: a small grid, every enemy move shown, no dice, a few turns to hold out.
- **odds**: Odds and nerve: cover, hit chances, a risky shot that might miss, a close call.
- **army**: Army: more units a side, terrain that defends, a leader to protect.

## Choices that shape the pitch

- **Luck:** odds shown, misses softened (default) · no dice, every enemy move shown, a puzzle.
- **A fallen unit:** sits out the next battle (default) · gone for good · the battle is lost if the
  leader falls.
- **The party:** a few units of different jobs, told apart at a glance (default) · a squad of named
  recruits · cards as the moves, a deckbuilder on a board.
- **What the player sees:** one grid that fits, `static` (default) · angled pan and zoom,
  `strategy`.
- **Feeling:** the player feels clever by one move that saves several units, pushing an enemy into
  another's attack, because every threat was on the board.

## Later, never in a one-shot

- Soldiers with names, histories and a memorial → add it as a feature
- Stress and breakdowns under pressure → not tested yet: ask for it after play and the AI will try it untested
- A campaign map of battles with a story → grow it
- A base, research and gear between battles → add it as a feature
- Classes and promotions → add it as a feature
- A rival who escapes and comes back → not tested yet: ask for it after play and the AI will try it untested
- Fire, rain and lightning on the battlefield → change it after play
- Moves queued and played together in real time → change it after play

## In a mashup

Tactics leads the board: positions, reach, pushes and enemy intent. A deckbuilder leads the draw,
and the cards are the moves. An RPG leads the party's growth between battles. A stealth half leads
sight and a quiet scouting phase before the fight. A management half leads the base between battles.
