# Chipset: action-adventure

**Camera:** `topdown`, a view from above that follows; `fixed` for a set 3D angle that follows, as
in Tunic, `orbit` for a free third-person view.

## Card defaults

- **lock-before-key**: A locked door or a blocked path is in view early, and the key or new tool
  that opens it is found later, in a fight or a puzzle; a new tool works elsewhere too. Why: the
  player sees the goal before the way to it, and the find makes sense the moment it is made. Break
  it when: the world is open from the start, a ride across a field with nothing locked.
- **puzzle-rooms**: Between fights, a few rooms hold a small puzzle (push a block, light the
  torches, hit a switch), and leaving a room puts its puzzle back as it was. Why: thinking and
  fighting take turns, and no puzzle is ever stuck for good. Break it when: the adventure is all
  fighting and riding, a straight run of set pieces.
- **hearts-and-retry**: Health is a row of hearts, and losing them all puts you back at the room's
  door with full hearts, the rooms you cleared still clear. Why: health is read at a glance, and a
  loss costs a room, never the adventure. Break it when: the person asks for hard stakes, a rest
  spot far behind with the enemies back.

## Feel

- **sword-swing**: The sword starts at once, sweeps a wide arc in front of you, and a hit knocks the
  enemy back a step, on top of the starter's hit kit. Why: a swing that reaches and pushes gives the
  player room to think. Break it when: there is no sword, a puzzle adventure with no fights.
- **roll-or-block**: A quick roll or a raised shield answers an attack, and a press a little early
  or late still counts. Why: the player wins by reading the attack and answering it, not by trading
  hits. Break it when: the hero is meant to be fragile, a chase where running is the only answer.
- **item-get**: An opened chest or a found tool stops play for a beat: the hero holds it up, a short
  jingle plays and its name shows. Why: every find is a small event the player wants to repeat.
  Break it when: finds happen so often that a beat each would drag, a loot game.
- **world-reacts**: Grass cuts, pots break and bushes shake when the sword or the hero touches them,
  and some drop a heart. Why: the world answers the player's sword, and a hurt player can find
  health nearby. Break it when: the world is stone and still on purpose, a ruin of bare rooms.

## Feel variants

- **nimble**: Quick and light: fast steps, quick swings, a roll to dodge, enemies down in a few
  hits.
- **weighty**: Heavy and grounded: committed swings, a shield to block, enemies that take patience.
- **curious**: Calm and curious: rare, easy fights, more to find, puzzles that give the eureka.

## Choices that shape the pitch

- **The world:** a small dungeon of connected rooms (default) · an open field with a landmark and a
  few things to find · a straight path of set pieces, linear action.
- **Fights:** sword and roll, by hand (default) · rare fights, mostly finding and puzzles · riding a
  mount across the field.
- **Stakes:** back to the room's door with full hearts (default) · back to the last rest spot, with
  the enemies back too.
- **What the player sees:** from above, `topdown` (default) · a set 3D angle, `fixed` · behind
  the hero, `orbit`.
- **Feeling:** the player feels clever and brave by opening the door they saw at the start, because
  the key was won in a fight and a puzzle they solved.

## Later, never in a one-shot

- A world map with markers and fast travel → grow it
- New tools over time that open old places → grow it
- A boss with phases → change it after play
- Several dungeons and a quest line → grow it
- Companions who help in fights → not tested yet: ask for it after play and the AI will try it untested
- Caring for a mount → add it as a feature
- Shortcuts that loop back to a safe spot → change it after play
- Locking on to one enemy in 3D → change it after play
- Townsfolk who notice what you did → add it as a feature

## In a mashup

The action adventure leads the world, movement and fights. A puzzle half leads the room puzzles'
rules and their resets. An RPG leads levels and gear. A metroidvania leads the map and its ability
gates. A detective half leads the clues, and knowledge can open a door the way a tool does. A
survival half leads hunger and crafting.
