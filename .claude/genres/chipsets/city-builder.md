# Chipset: city-builder

There is no tested way to build deep simulation yet: a one-shot city is one small district with a
few zone kinds, one service and traffic shown simply, never a whole simulated city.

**Camera:** `strategy`, an angled pan and zoom; `topdown` for a flat map; `static` for a small
island that fits the window.

## Card defaults

- **zone-demand**: A demand meter shows which zone the city wants next, homes, shops or work, and it
  shifts as you build. Why: the player always knows what to build without reading reports. Break it
  when: there are no zones, a free town painter.
- **tax-and-upkeep**: Taxes come in from homes and shops, roads and services cost upkeep, and both
  are on screen; running out of money ends the run. Why: growth must pay for itself, and the player
  can see why the money went down. Break it when: a calm builder with no money.
- **grow-to-unlock**: The population is on screen, with the next milestone and the building it
  unlocks beside it. Why: there is always a next thing to grow toward. Break it when: a sandbox city
  with everything open.

## Feel

- **paint-and-snap**: Roads are drawn and zones painted by dragging; both snap to a grid with a
  ghost and the total price before you let go, and land with a sound. Why: a district takes seconds
  to lay out, and the cost is known before it is spent. Break it when: buildings are placed one by
  one, a free-form town toy.
- **grows-by-itself**: Homes and shops rise on their own on zoned land beside a road, a few at a
  time, each with a short build animation. Why: the plan comes alive, and the city grows while the
  player watches. Break it when: every building is placed by hand.
- **coverage-shows**: A service shows its reach before you place it, and homes inside it look
  happier at once. Why: the player sees what a service gives before paying for it. Break it when:
  the town has no services, a small village of houses.
- **jams-show-and-clear**: Cars move along the roads, a jammed road shows itself in colour and an
  icon, and after a fix the queue visibly drains. Why: problems are seen, not hunted in menus, and
  the fix is satisfying to watch. Break it when: a calm picture town with no traffic.

## Feel variants

- **planner**: Planner: a tight budget, demand to balance, a new jam to fix every few minutes.
- **painter**: Town painter: no money, pieces that fit together on their own, nothing to fail.
- **pressure**: Under pressure: a hard winter is warned ahead, and the town must be ready in time.

## Choices that shape the pitch

- **What you build:** a city of zones and roads (default) · a small town placed piece by piece that
  fits itself together · a settlement racing a coming winter.
- **Stakes:** money runs out and the run ends (default) · a population target by a deadline ·
  none, a calm builder.
- **Progression:** new buildings at population milestones (default) · a new district once one is
  full · set scenarios with a target each.
- **What the player sees:** angled pan and zoom, `strategy` (default) · flat from above,
  `topdown` · a small island that fits the window, `static`.
- **Feeling:** the player feels order from chaos by fixing a jammed road and watching the traffic
  clear, because the problem shows on the map and the fix shows at once.

## Later, never in a one-shot

- Citizens with a home, a job and a route you can follow → not tested yet: ask for it after play and the AI will try it untested
- Full traffic, with lanes and a route chosen car by car → not tested yet: ask for it after play and the AI will try it untested
- Water, power and waste networks → add it as a feature
- Disasters → change it after play
- Several districts and a region map → grow it
- Land, rivers and resources placed for reasons → add it as a feature
- Long-run balance of money made and spent → grow it
- Policies and tax rates by zone → add it as a feature

## In a mashup

The city builder leads zones, roads and what the city needs. Management leads one business's floor
inside the city. Survival leads the threat and the winter. Tower defense leads the waves, and the
city pays for the towers. A colony sim leads named people with needs when the pitch wants a few
lives, not a crowd.
