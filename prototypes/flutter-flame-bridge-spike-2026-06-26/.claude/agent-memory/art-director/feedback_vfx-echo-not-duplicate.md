---
name: vfx-echo-not-duplicate
description: When one system's UI GDD implements a deliberately-simplified version of another system's already-specced VFX (e.g. a card burst standing in for a full particle "bloom"), spec it as an explicit echo, not a silent divergence.
metadata:
  type: feedback
---

Pattern confirmed while drafting Task Management UI (#19)'s Visual/Audio Requirements against Seed Buffer (#10)'s already-approved "Seed Bloom" animation. #19's pending-card approve animation had already been scoped down to "scale+fade, no particles, no cross-widget choreography" as a deliberate simplification (avoids Seed Bloom's 8–12 particle burst flying into the app-bar coin counter, which would require cross-widget animation plumbing #19 doesn't own).

**Rule**: when specifying the simplified version, explicitly reuse the *duration budget* and *color signature* of the original effect (here: 1.2s, Honey Gold) even while dropping its complexity (here: no particles). State in the doc that this is an intentional "echo" of the fuller effect owned elsewhere, not a coincidentally similar but unrelated animation. Add one small distinguishing detail (here: a brief ✓ glint) so it still reads as *belonging to* the reward-moment vocabulary rather than a generic UI transition.

**Why**: without this framing, a future reviewer or agent could read the simplified version as either (a) an accidental omission that should be "fixed" by adding particles back, defeating the original scoping decision, or (b) an unrelated animation that clashes with the game's motion identity. Naming it as a deliberate echo prevents both failure modes and keeps the two specs (owning system's full effect + consuming system's simplified local version) legible as one coherent design decision instead of a drift.

**How to apply**: Any time a UI-category system's Visual/Audio Requirements references an effect whose full version is owned by a different system's GDD (mechanic/economy-tier doc), check whether the local version reuses the source's timing/color and say so explicitly in the text.
