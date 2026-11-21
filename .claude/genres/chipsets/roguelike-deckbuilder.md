# Chipset: roguelike-deckbuilder

A run that builds a deck card by card on the way up a generated map; the card battler is a duel
between two decks built beforehand. A one-shot is one short run: a few floors and a boss.

**Camera:** `static`, the fight seen from the player's side; `fixed` for cards on a 3D table.

## Card defaults

- **small-start**: You start with a small deck of plain attacks and blocks and the same energy every
  turn; each turn draws a fresh hand, and the draw and discard piles show their counts. Why: every
  card added later is felt, and the player sees what is left to draw. Break it when: a scoring run
  that plays hands from a full standard deck.
- **pick-or-skip**: After each fight, take one of a few cards or skip them all, and a shop or a rest
  can remove a card. Why: the deck gets sharper, not only bigger, and a lean deck can win. Break it
  when: the deck is fixed and the run grows only through relics.
- **branching-map**: A generated map of fights, a few harder fights, events, rests and a shop, with
  the path picked by the player and a boss at the top. Why: the route is a plan: risk a hard fight
  for a better reward, or rest. Break it when: one ladder of fights in a row.

## Feel

- **intent-shown**: Each enemy shows what it will do next turn, and for how much: an attack, a block
  or a buff, and the damage shown already counts your block. Why: each turn is a puzzle to solve,
  and a loss is the player's misread. Break it when: surprise is the point, a gamble every turn.
- **play-in-order**: A card played flies to its target, and its effects resolve one at a time in the
  order they happen; the enemy turn and long chains speed up on a key. Why: the player sees why each
  number changed. Break it when: a speed run where cards resolve at once on purpose.
- **rising-count**: Damage and score count up one hit or trigger at a time, each step higher in
  pitch on top of the starter's pitch variation, and a kill or a beaten target lands with a burst.
  Why: a good turn builds, and the big total feels earned. Break it when: every card does one plain
  thing and nothing chains.
- **hand-feel**: The hand fans out, a card under the pointer lifts and explains its keywords, it is
  dragged onto its target along an arrow, and a card that cannot be played says why. Why: cards feel
  like things in the hand, and a mistake is caught before it happens. Break it when: cards are
  picked from a plain list, on purpose.

## Feel variants

- **fights**: Fights: enemies with intents, block against damage, a boss at the top.
- **score**: Score chase: hands played for a target that rises each round, jokers that multiply, a
  shop between rounds.
- **dice**: Dice: rolled dice placed into the cards' slots, and luck shaped by what is on the faces.

## Choices that shape the pitch

- **What a fight is:** a few enemies with intents, beaten turn by turn (default) · a hand scored
  against a target, no enemy · units placed on lanes that fight on their own.
- **Rewards:** a card from a few, or skip (default) · relics that change the rules · upgrading a
  card already held.
- **Stakes:** death ends the run, and a new run is a new map (default) · a few lives across the run
  · cards unlocked for later runs.
- **What the player sees:** the fight from the player's side, `static` (default) · cards on a 3D
  table, `fixed`.
- **Feeling:** the player feels clever by winning with a deck they trimmed, because they skipped
  weak rewards and the winning turn played out in order.

## Later, never in a one-shot

- Several characters, each with its own cards → grow it
- Written events with choices → add it as a feature
- Harder levels opened by a win → change it after play
- Card upgrades at rests → change it after play
- Cards exhausted for the fight, apart from removal → change it after play
- Potions and other one-use items → change it after play
- Cards and relics unlocked over many runs → grow it
- Daily seeded runs shared online → needs a server: not built yet

## In a mashup

The deckbuilder leads the run and the deck: rewards, removal and the draw. A card battler leads a
duel between two built decks. Tactics leads a board of positions and pushes, and the cards are the
moves. An action roguelite leads real-time fights, and cards become the rewards. An RPG half leads
the world, and cards are found in it.
