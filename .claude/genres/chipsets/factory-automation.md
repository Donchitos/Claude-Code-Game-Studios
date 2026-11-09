# Chipset: factory-automation

There is no tested way to build deep simulation yet: a one-shot factory is a small grid of a few
machines and belts on one steady tick, making one or two products, never a simulated world.

**Camera:** `topdown`, flat from above with pan and zoom; `static` for a small map that fits
the window; `strategy` for an angled view.

## Card defaults

- **goal-to-deliver**: One product to deliver, with the count delivered and the target on screen;
  meeting it opens the next goal and a new machine. Why: the factory has a reason to exist, and each
  goal brings something new to build. Break it when: a sandbox with no goals the person asked for.
- **ratios-to-balance**: Machines work at different speeds, so one kind feeds a few of the next, and
  each machine's rate shows when you point at it. Why: the layout becomes a puzzle of balance, not
  rows copied over. Break it when: a transport game where the routes are the puzzle, not the
  machines.

## Feel

- **hand-then-machine**: The first ore is mined by hand with a click, and the first drill placed
  takes the job over and keeps going while you build. Why: the player feels work turn automatic, the
  genre's first pleasure. Break it when: there is no hand work, a puzzle of belts and shapes from
  the start.
- **drag-and-snap**: Belts lay by dragging a line, machines snap to the grid with a ghost that shows
  their in and out sides, and picking one up refunds it whole. Why: building is quick and a change
  of mind costs nothing. Break it when: rebuilding has a price on purpose, a tight budget the person
  asked for.
- **see-the-flow**: Every item rides the belt where you can see it; a machine short of input or
  blocked on output shows a sign, and a backed-up belt bunches up. Why: the player finds the
  bottleneck by looking. Break it when: the factory is run from menus and reports.
- **fix-drains**: Fixing a bottleneck shows at once: the jam drains, the idle machine starts and the
  rate at the output climbs. Why: the fix is a pleasure to watch, not a number to read. Break it
  when: a level puzzle judged only by its final product, with no running rate.

## Feel variants

- **sprawl**: Busy and growing: more ore patches, more products, a factory that spreads across the
  map.
- **tidy**: Calm and tidy: a small set board, each level one product to make with the fewest
  machines.
- **rush**: Under pressure: stations appear over time, lines carry passengers, and one station
  overflowing ends the run.

## Choices that shape the pitch

- **What you build:** belts and machines making goods (default) · lines between stations carrying
  passengers · trains on tracks between towns.
- **Stakes:** goals met at your own pace, no way to fail (default) · a run that ends when one
  station overflows, with a warning first · money from each delivery and costs to build.
- **What the player sees:** flat from above, `topdown` (default) · the whole map at once,
  `static` · an angled view, `strategy`.
- **Feeling:** the player feels in charge of something bigger than themself by watching a line they
  built run on its own, because every item can be followed and every jam traced.

## Later, never in a one-shot

- Power, fluids and a second network to feed → add it as a feature
- Research that unlocks machines → grow it
- Long chains that keep early materials in use → grow it
- Copying a built line as a blueprint → change it after play
- Trains, drones and robots that carry goods → add it as a feature
- Creatures that attack the factory → not tested yet: ask for it after play and the AI will try it untested
- Regional prices and hauling between towns → not tested yet: ask for it after play and the AI will try it untested
- Workers and vehicles with routes of their own → not tested yet: ask for it after play and the AI will try it untested

## In a mashup

The factory leads production, belts and the signs that show a jam. A survival half leads needs and
threats, and the factory takes over the chores. A tower-defense half leads the waves, and the
factory feeds the towers. A management half leads prices and customers. A puzzle half leads set
levels with a best answer.
