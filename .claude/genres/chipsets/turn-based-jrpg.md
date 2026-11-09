# Chipset: turn-based-jrpg

A one-shot is a short dungeon of a few battles and a boss.

**Camera:** `topdown` for the world, `static` for battles; `fixed` for a 3D battle stage.
**Research:** needs primary research: our research on JRPGs holds a few entries, on direct battle
commands, party rules and gear that teaches skills. It has no entry for a party with set roles or
enemy weaknesses, and none on turn order beyond showing an enemy's next move.

## Card defaults

- **retry-battle**: A lost battle offers to retry it at once, from its first turn, with the party as
  it came in. Why: a loss teaches without wiping progress. Break it when: the person asks for a real
  game over.

## Feel

- **quick-commands**: Attack, skill, item and guard sit on fixed keys, the cursor remembers each
  hero's last choice, and an action starts the moment it is picked. Why: the hundredth battle is as
  quick as the first. Break it when: battles are rare and slow on purpose, each one a set piece.
- **turn-order**: A strip shows who acts next, heroes and enemies, and a big enemy attack is
  announced a turn before it lands. Why: the player plans ahead, and guards or heals before the hit.
  Break it when: a plain fight where planning ahead is not the point.
- **damage-pop**: Damage numbers pop from the target on their own arcs, a weakness or a critical hit
  lands bigger and louder, and a health bar drains with a trailing ghost. Why: every hit is read at
  a glance. Break it when: health is hidden on purpose, a story battle.
- **victory-tally**: A won battle ends on a short fanfare, experience and gold count up, and a
  level-up rings with what grew. Why: each fight ends on a reward the player sees. Break it when:
  battles flow into each other with no break, a boss rush.

## Feel variants

- **classic**: Classic: each hero picks in turn, a calm menu, battles won by the right matchup.
- **timed**: Timed hits: a key pressed as a hit lands does more, and one pressed as the enemy's hit
  lands blocks it.
- **rules**: Rules: the party acts on its own from rules you set, and you step in to override.

## Choices that shape the pitch

- **Battles:** turns picked from a menu in a fixed order (default) · a gauge that fills for each
  fighter, and the enemy does not wait · timed presses on each hit.
- **The world:** a short dungeon of a few rooms to a boss (default) · a small town and a route ·
  battles only, one after another.
- **Encounters:** enemies seen on the map and touched to fight (default) · random battles on a
  route · set battles only.
- **Growth:** levels from experience (default) · gear that teaches skills · jobs swapped between
  battles.
- **What the player sees:** a top-down world and a side-on battle (default) · a 3D battle stage,
  `fixed`.
- **Feeling:** the player feels like a careful leader by guarding the turn before a big hit and
  winning, because the turn order and the warning showed it coming.

## Later, never in a one-shot

- A story told in scenes and dialogue → grow it
- Towns, shops and side quests → grow it
- Gear that teaches skills → add it as a feature
- Party rules set ahead of battles → add it as a feature
- Jobs and skill boards → add it as a feature
- A card game or another mini-game in a town → change it after play
- Summons and special moves that charge over a battle → change it after play
- Rest spots that heal the party and bring enemies back → change it after play

## In a mashup

The JRPG leads the battle: the menu, the turn order and the party. An adventure half leads the world
and the route between battles. A creature collector leads the collection, and the party is caught. A
deckbuilder leads the commands, and skills become cards. An action half leads timed presses on each
hit, and the menu still leads the turn.
