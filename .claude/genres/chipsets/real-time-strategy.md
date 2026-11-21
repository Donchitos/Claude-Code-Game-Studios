# Chipset: real-time-strategy

There is no tested way to build opponents that act in real time yet, so units follow plain orders a
one-shot can build: move, gather, attack what comes in range; the enemy sends waves on a timer.

**Camera:** `strategy`, an angled pan and zoom with edge pan; `topdown` for a flat 2D map.

## Card defaults

- **enemy-waves**: The enemy base sends waves on a timer, the first one early, each bigger, with a
  warning before each one, and destroying its base wins. Why: pressure comes on a rhythm the player
  can prepare for, and a hard fight that is won in the end. Break it when: two sides race to build,
  which needs a real-time AI. [shelley-1], [browder-1]
- **unit-counters**: A few kinds of unit, each told apart by its shape, beat each other in a loop,
  and each counter wins clearly. Why: an army is a choice, and a fight is won by the right mix.
  Break it when: one kind of unit, where numbers win. [shelley-2], [browder-1]
- **orders-obeyed**: A unit does what it was told and never overrides an order on its own, and
  workers walking to and from a resource pass through each other instead of jamming. Why: the player
  commands, and the economy runs without babysitting. Break it when: units with minds of their own
  are the point, a game of unruly troops. [tiberian-sun-1], [wyatt-1]

## Feel

- **order-answers**: Every order answers at once: a marker where you clicked, a ring under the
  selected units and a short reply, a voice or a chirp. Why: the player knows the order was heard,
  even in a crowd. Break it when: orders are given only while paused, a slow command game.
- **under-attack**: A fight off screen sounds an alert and pings the small map in the corner where
  it is, and one key jumps the view there. Why: the player never loses a base they could not see.
  Break it when: the whole map fits the window.
- **skill-in-the-fight**: A few units handled well beat a bigger crowd left alone: a fast unit can
  hit and step back, and a hurt one pulled out of the fight lives. Why: the player wins by how they
  use an army, not only by what they built. Break it when: armies fight on their own once sent, a
  game of planning only. [browder-2]

## Feel variants

- **buildup**: Build-up: a calm start, a growing economy, one big army for a final push.
- **hold**: Hold out: no base to destroy, a base to keep through bigger and bigger waves until the
  timer ends.
- **squad**: Squad: no base, a handful of units with their own skills, a map to cross.

## Choices that shape the pitch

- **Economy:** workers gather and the base trains (default) · income from points held on
  the map · none, a set army.
- **The enemy:** a base that sends bigger waves on a timer (default) · survive until a timer runs
  out · a scripted rival that builds along a set plan.
- **Army size:** a small army the player can follow (default) · a handful of named units with skills
  · crowds of tiny units.
- **What the player sees:** angled pan and zoom, `strategy` (default) · flat from above,
  `topdown`.
- **Feeling:** the player feels in command by breaking a wave with an army built for it, because the
  wave was seen coming and the units did exactly as told.

## Later, never in a one-shot

- An enemy that scouts, adapts and builds like a player → not tested yet: ask for it after play and the AI will try it untested
- Units that find their way as a group and hold formation → not tested yet: ask for it after play and the AI will try it untested
- Sides with their own units and timing → grow it
- Fog of war and scouting → change it after play
- Upgrades researched at buildings → change it after play
- Hero units with skills → change it after play
- A campaign of missions with a story → grow it
- Battle sound that changes with distance and place → change it after play
- Online matches and ranking → needs a server: not built yet

## In a mashup

The RTS leads the economy loop, the orders and the camera. Tower defense leads a base held by placed
defences, and the RTS leads the army that goes out. A city builder leads the base's layout and
services. A tactics half leads slow, careful moves, and the game pauses for orders. A MOBA leads one
hero in the middle of the army.
