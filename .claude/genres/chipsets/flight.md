# Chipset: flight

There is no tested way to build a real flight model yet: a one-shot flies with simple, readable arcade
handling of its own; lift, stalls and orbits wait for it.

**Camera:** `chase`, behind the craft; `first` for the cockpit; `follow2d` for a side-view
glider.

## Card defaults

- **course-and-goal**: A short course with a goal from the first second: rings to fly through, a pad
  to land on or a far landmark always in view, with the goal and the time on screen, then a results
  screen. Why: an open sky gets a purpose at once. Break it when: free flight to explore, a sky with
  nothing to do but fly.
- **soft-ground**: Grazing the ground or a wall bounces and slows the craft, never an instant wreck;
  a real crash puts you back in the air a moment later near where it happened. Why: a mistake costs
  seconds, not the flight. Break it when: the landing is the challenge, and a crash ends the run.

## Feel

- **self-leveling**: The craft always moves forward, banks into turns and levels out when you let
  go, so it never tumbles; up and down can be swapped in the options. Why: the player flies well
  from the first second. Break it when: the person wants a sim with full rolls, stalls and spins.
- **dive-for-speed**: Diving builds speed and climbing spends it, so height is a store the player
  trades. Why: flight gets a rhythm of dive and climb. Break it when: speed is fixed, a rail shooter
  that flies itself forward.
- **speed-in-the-air**: The view pulls back and widens and the wind rises with speed, and clouds and
  ground streak past; reduced motion turns it down. Why: speed is felt without the craft handling
  worse. Break it when: a slow balloon or glider ride where calm is the point.
- **height-reads**: The craft casts a shadow on the ground, the horizon stays in view, and near the
  ground the camera tips to show what is coming. Why: the player always knows which way is up and
  how far the ground is. Break it when: deep space, where a speed marker and a few far stars do the
  job.

## Feel variants

- **ace**: Tight and arcade: fast, a quick roll to dodge, a stream of targets to shoot.
- **glider**: Calm glider: no engine, rising air and long dives keep you up, a quiet sky to drift
  through.
- **drift**: Floaty space: the ship keeps drifting where it was going, thrusters turn and slow it,
  and arriving is a skill.

## Choices that shape the pitch

- **What you fly:** a plane over land and sea (default) · a glider with no engine, riding rising air
  · a ship in space that drifts until you slow it.
- **Stakes:** rings against the clock (default) · a dogfight with rival craft flying simple
  patterns, as there is no tested way to build real-time opponents yet · reach a far landmark and land
  there.
- **What the player sees:** behind the craft, `chase` (default) · the cockpit, `first` · a side
  view of a glider, `follow2d`.
- **Feeling:** the player feels free by trading a long dive for the climb over a ridge, because
  speed and height are theirs to spend.

## Later, never in a one-shot

- A real flight model with lift, stalls and spins → not tested yet: ask for it after play and the AI will try it untested
- Orbits and gravity around planets → not tested yet: ask for it after play and the AI will try it untested
- Enemy aces that fly and fight on their own → not tested yet: ask for it after play and the AI will try it untested
- Landing on a runway with a flare and a score → change it after play
- Switching from glider to parachute to wingsuit in the air → add it as a feature
- Trading between stations, with cargo at risk → add it as a feature
- Ships lost for good in a shared space → needs a server: not built yet
- Joysticks, throttles and rumble → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

Flight leads handling, the camera and how speed is shown. A shooter half leads weapons and enemy
patterns, and flight keeps the craft readable. A racing half leads the course, the rivals and the
laps. A trading half leads prices between ports or stations, and flight is the trip. An exploration
half leads landmarks and what is found.
