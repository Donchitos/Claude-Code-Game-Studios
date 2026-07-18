---
name: two-tone-visual-identity
description: PetQuest deliberately runs two distinct visual/motion tones (child-facing "Cozy Chibi" vs parent-facing "calm professional") within one app — not an inconsistency to fix.
metadata:
  type: project
---

PetQuest's UI is split into two intentional visual registers that share the same underlying design tokens (Art Bible palette, ≥12dp corner radius, never pure red/black) but differ sharply in motion and sensory vocabulary:

- **Parent Dashboard UI (#21)**, `design/gdd/parent-dashboard-ui.md`: restrained/"calm professional." `easeInOut`/`easeOut` motion only — no elastic/bounce. No particle/sparkle/confetti (that vocabulary is explicitly reserved for child-side Mochi celebration). Silent-by-default audio. Dominant color Lavender Soft + Cloud White. Plain-text empty states. Grey shimmer skeleton loaders (not character-animated).
- **Child-facing screens** (e.g., Task Management UI #19, `design/gdd/task-management-ui.md`): full "Cozy Chibi Neighborhood" expressive treatment per Art Bible Section 1 Principle P3 (Expressive Animation). Elastic/spring overshoot curves on selection + reward moments allowed. Restrained glint/sparkle permitted (not full particle systems, but not silence either). Sound cues active. Hero circular icons for primary choices per Art Bible Section 3's Hero-vs-Supporting shape table.

**Why**: the user's explicit framing is "two rooms in the same house, not two different apps" — same shared shape/color grammar, but Parent Dashboard *deliberately subtracts* bounce/particles/sound as a register of calm trustworthy authority, while child screens spend that same vocabulary because those are the effort-celebration surfaces (Pillar 1).

**How to apply**: When reviewing or drafting Visual/Audio Requirements for any new screen, first classify it as parent-side or child-side (or note if it's a rare screen touching both, e.g. shared onboarding) and apply the matching register. Do NOT flag child-screen exuberance as "inconsistent" with parent-screen restraint, and do NOT flag parent-screen restraint as "should be more expressive to match the brand" — both are correct for their audience. See [[reference_task-library-category-colors]] for the concrete category color mapping used across child-facing category pickers.
