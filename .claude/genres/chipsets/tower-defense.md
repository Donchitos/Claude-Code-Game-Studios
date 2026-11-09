# Chipset: tower-defense

**Camera:** `strategy`, an angled pan and zoom; `static` when the whole map fits the window.

## Card defaults

- **waves-and-lives**: Enemies come in waves along a path you can see, the wave count and your lives
  are on screen, and each enemy that gets through costs a life. Why: the player sees where to
  defend, how far they are, and what a leak costs. Break it when: enemies come from every side, a
  base defended in the open.
- **enemy-mix**: Enemies differ in ways towers must answer: fast ones, armoured ones, flyers that
  skip the path, a few that shield the others. Why: one tower type is never enough. Break it when:
  the challenge is only numbers, a calm game about one kind of tower.
- **sell-back**: A placed tower can be upgraded, or sold back for most of what it cost. Why: a
  misplaced tower is a cheap mistake, and a good spot can grow. Break it when: towers are permanent
  on purpose, a game where each placement is final.

## Feel

- **placement-preview**: A tower under the pointer shows its range circle and price, snaps into
  place with a thud, and starts firing at once. Why: every placement answers straight away, so
  building is quick and a mistake is plain. Break it when: nothing is placed, the defence is a hero
  you steer.
- **coins-fly**: Each kill pops coins that fly to the money counter, and it ticks up as they land.
  Why: the player sees the defence paying for itself. Break it when: money comes only between waves,
  a planning game with a fixed budget.
- **arrivals-heard**: A wave and each strong enemy announce themselves with their own sound and a
  marker at the entrance before they come into range. Why: the player has a moment to prepare for
  the threat, not only react to it. Break it when: surprise is the point, a game of hidden waves.
- **wave-breath**: The end of a wave lands with a short fanfare and a pause to build, with a button
  to call the next wave early. Why: pressure and relief come in turn, and a strong defence need not
  wait. Break it when: the waves never stop, an endless flood.

## Feel variants

- **planner**: Calm planner: a breath between waves, a few strong enemies, each placement weighed.
- **swarm**: Swarm: crowds that fill the path, fast waves, towers popping dozens at once.
- **hands-on**: Hands-on: a hero or a power you aim yourself, between the towers.

## Choices that shape the pitch

- **Where towers go:** open ground beside a set path (default) · a few fixed spots on the path ·
  open ground where the towers make the path, a maze.
- **The defence:** towers only (default) · towers and one hero you move · defenders in lanes,
  one row each, against a walking horde.
- **Stakes:** lives lost to leaks, game over when they run out (default) · a score for how few
  got through · endless waves until you fall.
- **What the player sees:** an angled map you pan, `strategy` (default) · the whole map in one
  view, `static`.
- **Feeling:** the player feels ongoing planning by watching a wave break on a defence they built,
  then spotting the gap the next wave will find.

## Later, never in a one-shot

- Upgrade trees with several branches per tower → add it as a feature
- A map editor → not tested yet: ask for it after play and the AI will try it untested
- A campaign of maps → grow it
- A hero who levels up across maps → grow it
- Endless mode with a shared leaderboard → needs a server: not built yet
- Co-op defence on one screen → change it after play
- Enemies that find a new way around your towers as you build → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

Tower defense leads the path, the waves and placement. The economy leads money from kills and
prices. An action half leads a hero you steer, and the towers stay where you put them. A roguelite
leads the run, offering one of a few towers after each wave. A card half leads the towers as cards
in a hand.
