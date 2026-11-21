# Chipset: stealth

There is no tested way to build real-time guard AI yet, so guards here follow fixed, readable routines with
simple sight and hearing rules a one-shot can build. Guards that plan, call each other and search
as a team wait for it.

**Camera:** `topdown`; `orbit` behind the sneak in 3D, `first` for a thief's-eye view.

## Card defaults

- **guard-routines**: Guards walk set routes and stop at set spots, the same on every try. Why: a
  routine can be watched, learned and slipped past. Break it when: the threat should feel
  unpredictable, a horror hunter that follows the noise.
- **steal-and-escape**: One thing to steal or reach and an exit to leave by; once you have it, the
  music changes and the way out is shown. Why: the job has a clear end, and the escape is a tense
  beat of its own. Break it when: there is nothing to take, a sneak through to freedom.
- **caught-retry**: Being caught puts you back at the start of the room at once, with the guards
  back on their routes. Why: a mistake costs seconds, so the player tries a new line. Break it when:
  being caught opens a new situation, a cell to escape from.

## Feel

- **see-their-sight**: Each guard's sight is drawn on the floor as a cone, and every noise you make
  shows as a ring. Why: the player judges what the character could judge, with no guessing. Break it
  when: not knowing is the fear, a horror sneak with no cones.
- **suspicion-builds**: A guard who glimpses you does not raise the alarm at once: a mark over their
  head fills, faster up close and in light, and drains if you slip out of sight. Why: a glimpse is a
  warning the player can still escape. Break it when: one look is the end, a strict ghost challenge.
- **search-last-seen**: A guard who loses you walks to where they last saw you, looks around, then
  goes back to the route. Why: the player can trick a guard, and hiding really works. Break it when:
  the watchers are cameras and lasers that never move.
- **shadow-and-noise**: Shadows hide you and light shows you; walking is quiet, running is loud, and
  the floor changes how loud. Why: every step is a choice between speed and silence. Break it when:
  the hiding is social, in a crowd or a disguise, not in the dark.

## Feel variants

- **ghost**: Ghost: avoid everyone, no knockouts, a puzzle of timing and routes.
- **predator**: Predator: take guards down one by one from shadows and ledges, and hide the bodies
  before they are found.
- **social**: Hidden in plain sight: blend into a crowd or wear a disguise, and only a few guards
  see through it.

## Choices that shape the pitch

- **Approach:** slip past unseen (default) · knock guards out from behind and hide them · walk in
  disguised, past guards who may see through it.
- **Preparation:** straight in (default) · scout first, then plant tools and open routes · plan a
  crew's moves and run them together.
- **Caught:** back to the room's start (default) · a chase you can still end by hiding · captured,
  with a cell to escape.
- **What the player sees:** from above, `topdown` (default) · from behind, `orbit` · through the
  thief's eyes, `first`.
- **Feeling:** the player feels like a master thief by slipping past a guard whose route they
  watched, because the routine was learnable and the sight was drawn.

## Later, never in a one-shot

- Guards that call each other and search as a team → not tested yet: ask for it after play and the AI will try it untested
- Guards that adapt to your favourite trick → not tested yet: ask for it after play and the AI will try it untested
- Daily schedules tied to work, meals and sleep → not tested yet: ask for it after play and the AI will try it untested
- Fire, falling loads and animals as ways past a guard
  → not tested yet: ask for it after play and the AI will try it untested
- Factions that react to each other → not tested yet: ask for it after play and the AI will try it untested
- A companion who never gives you away → add it as a feature
- Sound that bends around walls and through doors → add it as a feature
- Several routes for every job, by talk, tools or force → grow it

## In a mashup

Stealth leads guards, sight, noise and the alarm. An action half leads the fight once you are seen,
and stealth still decides when the alarm spreads and how it ends. A parkour or platformer half leads
movement and gives rooftop routes. A puzzle half leads hand-made rooms with one way through. A
horror half leads a hunter who cannot be fought, heard before seen.
