# Chipset: metroidvania

**Camera:** `follow2d`; `orbit` for a 3D one.

## Card defaults

- **lock-before-key**: The first minutes show a ledge too high or a wall too strong, then give you
  the move that beats it, a double jump or a dash, close enough to go back. Why: the map turns from
  a wall into a promise. Break it when: progress is by knowledge alone, with every tool there from
  the start.
- **map-fills**: A map fills in room by room as you explore, shows where you are and marks the
  blocked ways you have seen. Why: the player remembers the locks and plans the way back. Break it
  when: the world is a few screens that fit in the head, with no need for a map.
- **bench-and-shortcut**: A bench heals you and saves the game, and ordinary enemies come back; a
  door that opens only from the far side later loops a hard route back to it. Why: the bench is a
  safe home, and opening the shortcut makes the map smaller. Break it when: the hero respawns at
  every door with nothing lost, a short action game with no map to learn.

## Feel

- **forgiving-jump**: Late jumps off a ledge, early presses before landing and clipped corners still
  count; hold to jump higher, and fall faster than you rise. Why: a miss is the player's mistake,
  and every jump can be shaped. Break it when: the hero is heavy and every jump is one fixed arc,
  the old Castlevania way.
- **quick-slash**: The attack comes out at once, reaches a little past the blade, and a hit pushes
  the enemy back and you back a step. Why: fighting and moving are one skill, and a hit never leaves
  you stuck in a crowd. Break it when: there are no fights, a calm explorer of ruins.
- **new-move-moment**: A new move stops play for a beat with a pose, a jingle and its name, and then
  it works everywhere, in fights too. Why: the player feels stronger, and every old wall is worth a
  second look. Break it when: moves come thick and fast, a short run with a new power every minute.
- **room-camera**: The camera leads where you are heading, holds still through ordinary jumps and
  stops at the edges of each room, so the room's shape reads. Why: the next danger is seen in time,
  and each room is remembered as a place. Break it when: each room is one screen that fits the
  window.

## Feel variants

- **nimble**: Nimble: quick runs, an early dash, light fights you flow through.
- **deliberate**: Heavy and deliberate: a slower hero, enemies that hit hard, fights you read.
- **wanderer**: Calm wanderer: few enemies, more secrets, the map itself the reward.

## Choices that shape the pitch

- **Failure:** back to the last bench with nothing lost (default) · back to the bench, with your
  money left where you fell to win back once · a restart at every door.
- **Growth:** new moves that open new places (default) · levels and gear as well, the Castlevania
  way · knowledge alone, every tool from the start.
- **What the player sees:** side view, `follow2d` (default) · 3D behind the hero, `orbit`.
- **Feeling:** the player feels discovery by opening a way they passed long ago, because they
  remembered the lock and now carry the key.

## Later, never in a one-shot

- A big map of many areas and many moves → grow it
- A boss guarding each new move → change it after play
- Sequence breaks and advanced tricks → add it as a feature
- Secret rooms behind odd-looking walls → change it after play
- One place reached from above, through and below → grow it
- A second world after the end → grow it
- Badges or charms that change your moves → add it as a feature
- Fast travel between benches → change it after play
- Rules learned from clues that open the way → add it as a feature

## In a mashup

The metroidvania leads the map, its gates and the benches. A platformer half leads jumps and
movement forgiveness. A soulslike half leads fights and what a death drops. A roguelite half leads
the run, and the map is new each run while the ability gates stay. An RPG half leads levels and
gear.
