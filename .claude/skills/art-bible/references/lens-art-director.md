# Lens: art direction

Read at every section you draft and at the AD-ART-BIBLE sign-off. It is what the
`art-director` agent brought to this skill when it drafted the sections. Apply
its checks to the draft before you show it.

## What every section must do

- **Narrow the solution space.** A section is a constraint: an artist reading it
  should be able to rule options out. "Dark and foreboding" rules nothing out;
  "cool 6500K key light, one warm practical per room, contrast high enough that
  silhouettes read at 25% scale" does.
- **Trace to a pillar.** Every principle names the pillar it serves (from a
  one-page brief: its pitch and "what they feel" line). A principle no pillar
  needs is taste, and goes.
- **Give a design test.** For a principle: "when X is ambiguous, this says
  choose Y". If you can't write the test, the principle is too vague.
- **Stay consistent with the sections already locked.** Colour serves the mood
  targets and the shape hierarchy; characters read against the environment
  density; UI either echoes the world or is deliberately distinct, and says
  which.

## Section checks

1. **Visual Identity Statement**: one line that settles any visual argument,
   plus 2-3 principles, each with its design test and its pillar.
2. **Mood & Atmosphere**: per game state, the exact emotion, the lighting
   (warm/cool, contrast, time of day), 3-5 adjectives, energy level, and one
   visual element that carries the mood. States must look different from each
   other at a glance.
3. **Shape Language**: silhouette rule per archetype (readable at thumbnail
   size?), the dominant environment geometry and why, the UI shape grammar, what
   is hero and what recedes. Each shape choice tied to the statement and a
   pillar, and to what it makes the player feel.
4. **Color System**: 5-7 palette colours with roles (meaning, not only hex),
   the semantic vocabulary and why each colour means that in this world, area
   temperature rules if the game has areas, the UI palette and how it diverges.
   **Colourblind safety**: name every semantic pair that can fail (red/green,
   red/brown, blue/purple, green/yellow) and the backup cue for each: shape,
   icon, pattern or sound. A red/green pair with no named backup is a defect.
5. **Character Design Direction**: player archetype, how enemies/NPCs/allies
   tell apart at a glance, pose and expression style, LOD philosophy at the game
   camera's distance.
6. **Environment Design Language**: architecture and the culture/history behind
   it, texture philosophy (painted, PBR, stylised, and why), prop density per
   area type, environmental storytelling without text.
7. **UI/HUD Visual Direction**: diegetic vs screen-space, typography (personality,
   weight, size hierarchy), icon style, UI animation feel. Important information
   is the most prominent thing on screen.
8. **Asset Standards (art side)**: file formats, naming direction
   (`[category]_[name]_[variant]_[size].[ext]`, e.g. `char_knight_idle_01.png`),
   texture resolution tiers, LOD expectations, export philosophy.
9. **Reference Direction**: 3-5 sources (games, films, art styles, artists).
   For each: the specific thing to take (a technique, a colour choice, a
   compositional rule, never "the general aesthetic") and what to avoid, so it
   doesn't read as a copy. No two references point the same way.

## Limits

- Never rewrite a pillar. Where one fights a visual goal, show it as a
  trade-off for the person to decide.
- No gameplay, narrative or audio decisions. For audio, name only the visual
  mood it should match.
- No scope additions; no engine or pipeline tooling choices (that is the
  technical side, `lens-technical-artist.md`).

## AD-ART-BIBLE sign-off

The checklist is `.claude/docs/director-gates/ad-art-bible.md`'s Prompt; its
Verdicts line is the only vocabulary: APPROVE / CONCERNS [sections] / REJECT
[inconsistencies], or `NOT ASSESSED` naming an input the gate lists that you
could not read. An input the bible should contain and does not (a missing UI
palette, say) is a finding, not a missing input. Put the verdict token first,
on its own line (`AD-ART-BIBLE: CONCERNS`), then the reasons, each naming its
section.
