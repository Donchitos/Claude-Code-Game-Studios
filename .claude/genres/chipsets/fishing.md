# Chipset: fishing

**Camera:** `static`, the water seen from the shore or a boat; `topdown` to walk or sail between
spots; `follow2d` for a line that drops deep, a game like Ridiculous Fishing.
**Research:** needs primary research: our research has three fishing entries, on the wait, the bite
and the reel, and a few hunting entries on where creatures live. It has no entry for a log of the
kinds caught, or for selling the catch to buy better gear.

## Card defaults

- **spots-differ**: A few spots, shallows, deep water and the rocks, each with its own fish, and
  some fish bite only at dusk or in rain. Why: where and when to cast is the player's choice. Break
  it when: one spot is the whole game, a quick reflex test.

## Feel

- **quiet-wait**: After the cast the float rests on calm water with soft sound, and the wait is
  never long. Why: the quiet makes the bite land. Break it when: frantic arcade fishing, fish
  leaping at the line.
- **true-bite**: Nibbles tug the float first; the real bite pulls it under with a splash, a sound
  and a shake that cannot be missed, and a missed strike is quick to retry. Why: the player watches
  closely instead of pressing on reflex. Break it when: every bite is real, a gentle one-button
  fishing.
- **reel-fight**: Reeling is a short contest: hold to pull, ease off when the line strains, and the
  fish fights back in bursts, harder for a big one. Why: the catch is won by skill after the wait.
  Break it when: the person wants the catch to be one timed press.
- **catch-show**: A landed fish is held up with its name, size and a jingle, bigger for a new kind
  or a record. Why: every catch is a small reward, a new kind a big one. Break it when: nets haul
  fish by the dozen and the haul is the reward.

## Feel variants

- **calm**: Calm: long quiet waits, a forgiving reel, nothing lost.
- **arcade**: Arcade: quick bites, a reel that tests reflexes, a score against the clock.
- **eerie**: Eerie: fishing at night pays more and risks more, and strange things bite.

## Choices that shape the pitch

- **What you catch:** fish (default) · animals tracked by trails and dens, hunting · junk and
  treasure among the fish.
- **Stakes:** none, a lost fish just swims off (default) · a quota to fill before dark (a day clock)
  · the night is dangerous and a long trip risks the catch.
- **Progression:** a better rod and bait from selling fish (default) · a boat that reaches new
  waters · the log alone.
- **What the player sees:** water from the shore, `static` (default) · from above, walking or
  sailing, `topdown` · a line dropping deep, `follow2d`.
- **Feeling:** the player feels the weight of a big catch by fighting it in on a straining line
  after a quiet wait, because the true bite is clear and the reel rewards skill.

## Later, never in a one-shot

- Many waters on a map, each with its own fish → grow it
- A boat to sail and upgrade → add it as a feature
- Cooking and eating the catch → change it after play
- An aquarium or museum to show the catch → change it after play
- Night horrors and a fraying nerve, as in Dredge → add it as a feature
- Fish and game that roam, feed and flee on their own → not tested yet: ask for it after play and the AI will try it untested
- Weather and seasons that change what bites → add it as a feature
- Contests and records against other players → needs a server: not built yet

## In a mashup

Fishing leads the cast, the bite and the reel. A farming or life sim leads the day clock, and fish
sell where crops sell. Survival-crafting leads hunger, and fish are food. Horror leads the dark and
what lurks in it, and fishing leads the catch. An adventure leads the world, and fishing sits in it
as a calm side activity.
