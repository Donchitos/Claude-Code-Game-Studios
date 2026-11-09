# Chipset: card-battler

A one-shot is one match against an AI opponent, or a short run of them.

**Camera:** `static`; `fixed` for cards on a 3D table.

## Card defaults

- **build-a-deck**: Before the match you build a small deck from a pool of cards, with a limit on
  copies of any one card, and a ready-made deck is one key away. Why: the deck is the player's plan,
  fewer good cards beat many weak ones, and a novice can play at once. Break it when: the deck grows
  card by card during a run, a roguelike deckbuilder. [snap-1], [mtg-starter-1]
- **growing-resource**: Each turn gives a little more to spend than the last, so the match opens
  with small plays and builds to big ones. Why: the resource sets the pace, and every turn brings a
  new choice of what it can afford. Break it when: resources come from cards in the deck on purpose,
  a game about building your own supply. [rosewater-2], [runeterra-1], [snap-1]
- **second-seat-extra**: Whoever goes second gets a small extra, a card or a one-time boost, and a
  player who falls behind has ways back. Why: neither seat decides the match before it starts. Break
  it when: both players act at once, with no first turn. [hearthstone-1], [rosewater-1]

## Feel

- **telegraphed-intent**: The AI's creatures show what they will hit next turn and for how much, so
  the threat is on the board before you end your turn. Why: a loss is the player's misread, never a
  surprise. Break it when: bluffing is the point, hidden plays and raised stakes.
- **one-at-a-time**: Each card played, by you or the AI, shows large for a moment, and its effects
  resolve one by one in the order they happen; a key speeds the AI's turn. Why: the player sees why
  the board changed. Break it when: a speed duel where cards resolve at once and pace is the fun.
- **rising-chain**: When effects chain, each step climbs in pitch and the total counts up, on top of
  the starter's pitch variation, and crossing the winning blow or a big total lands with a burst.
  Why: a combo builds instead of arriving as one number. Break it when: cards never chain, a plain
  duel of single effects.
- **read-any-card**: A card under the pointer lifts, and holding on any card, yours or the AI's,
  shows it large with each keyword explained, and most cards say little. Why: the rules are learned
  in play, never from a manual. Break it when: a handful of plain cards that need no words.
  [rosewater-3], [inscryption-2]

## Feel variants

- **brisk**: Brisk and aggressive: cheap cards, low life, an AI that rushes, a match in a few
  minutes.
- **combo**: Combo engine: cards that trigger each other, a slow start and one big turn that wins.
- **bluff**: Bluff and read: a raise of the stakes or a priced retreat, and an AI that bluffs too.

## Choices that shape the pitch

- **How a match is won:** the other side's life to zero (default) · win more lanes than the AI after
  a set number of turns · best of three rounds from one hand.
- **The deck:** a ready-made deck to tweak (default) · a draft, one of three cards at a time · a
  pool that grows with wins (later).
- **Stakes:** one match (default) · a short ladder of AI opponents, each with its own deck · a raise
  mid-match with a priced retreat.
- **What the player sees:** a table seen from the player's seat, `static` (default) · cards on a
  3D table in a room, `fixed`.
- **Feeling:** the player feels clever by winning with a turn set up a few turns before, because
  each effect played out in order and the plan was theirs.

## Later, never in a one-shot

- A collection grown by opening packs, safe from long bad-luck streaks
  → add it as a feature
- Online matches, ranking and matchmaking
  → needs a server: not built yet
- Crafting cards from spares → add it as a feature
- A campaign of opponents on a map → grow it
- Rewards that change the rules for a master → change it after play
- Many sets of cards and keywords → grow it
- Two players taking turns on one screen, with a pass screen to hide hands → change it after play

## In a mashup

The card battler leads the turn, the deck and how effects resolve. A roguelike leads the run, and
the deck grows card by card. Tactics leads a board of positions and pushes. An RPG or adventure half
leads the world, and cards come from exploring. A creature collector leads the collection, and its
creatures become the cards.
