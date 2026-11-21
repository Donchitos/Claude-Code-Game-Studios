# Chipset: first-person-shooter

**Camera:** `first`; `orbit` over the shoulder for a third-person shooter.

## Card defaults

- **ammo-and-reload**: Each gun holds a magazine and a reserve, shown in a bottom corner beside the
  health; a key reloads, and an empty gun clicks. Why: running dry is a choice the player made,
  never a surprise. Break it when: one gun with endless shots, an arcade shooter for score.
- **enemy-roles**: A few enemy kinds that each ask a different answer: fodder that rushes, a shooter
  that keeps its distance, a tough one that pushes you out of cover. Why: a fight is a quick puzzle
  of who to shoot first. Break it when: a duel against one boss, or waves of one enemy for score.

## Feel

- **mouse-look**: The mouse turns the view with no smoothing, and the pause screen has a sensitivity
  setting. Why: the aim answers the hand at once. Break it when: a rail shooter, where the view
  moves on its own and only the crosshair is aimed.
- **hit-confirm**: A hit marker flashes on the crosshair with a crisp tick, and a kill has its own
  sound. Why: the player knows a shot landed without looking away from the target. Break it when:
  horror or a tactical sim, where you are meant to doubt the shot.
- **guns-differ**: Each gun has its own kick, flash and sound, sways as you walk and drops away to
  reload, and a low-ammo sound warns before it runs dry. Why: guns feel different in the hands, and
  the ear tracks the magazine. Break it when: one plain gun on purpose, a puzzle shooter about where
  to fire.
- **hurt-direction**: A hit from off to the side marks the screen edge it came from. Why: a hit is
  something to turn and answer, not a mystery. Break it when: the threat is meant to stay unseen, a
  horror shooter where not knowing is the fear.

## Feel variants

- **boomer**: Fast and fearless: quick strafing, no cover, health and ammo picked up by pushing in.
- **tactical**: Steady and tactical: slower moves, cover, health that comes back out of fire.
- **mech**: Heavy and mechanical: a slow, armoured walker that turns with weight, big guns.

## Choices that shape the pitch

- **What the player sees:** through the eyes, `first` (default) · over the shoulder, `orbit`, with
  cover to duck behind and a timed reload · from above is the twin-stick-shooter chipset.
- **Health:** picked up in the level (default) · comes back after a moment out of fire · armour on
  top of health.
- **Structure:** one level of rooms and arenas to an exit (default) · waves in one arena, for score
  · a mech walking through a city of props it knocks over.
- **Feeling:** the player feels powerful by clearing a room with the right gun for each enemy,
  because every kind asks a different answer and every hit is confirmed.

## Later, never in a one-shot

- Online matches and lag compensation → needs a server: not built yet
- A campaign of levels and set pieces → grow it
- Enemies that take cover, flank and call to each other → not tested yet: ask for it after play and the AI will try it untested
- Squad mates → not tested yet: ask for it after play and the AI will try it untested
- Aim assist for gamepads → not tested yet: ask for it after play and the AI will try it untested
- Sound shaped by walls and rooms → add it as a feature
- Weapon upgrades and mods → add it as a feature
- Wall runs and slides → change it after play
- Vehicles → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

The shooter leads aiming, the guns and hit feedback. Horror leads what the player can know and the
pace of threats, and survival leads scarce ammo and the inventory. A roguelite leads the run and its
builds. An RPG leads loot and levels, a looter shooter. Parkour leads movement in a movement
shooter. Stealth leads detection.
