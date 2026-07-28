---
name: project-gdd-tag-convention-state
description: Grep-verified state of AC test-type/scope tag adoption across GDDs as of 2026-07-10 — corrects false "all approved GDDs tagged" framing
metadata:
  type: project
---

As of 2026-07-10, inline AC tags (test-type `[Logic]`/`[Integration]`/`[Visual/Feel]`/
`[UI]`/`[Config/Data]`/`[Performance]` and scope `[MVP]`/`[VS+]`/`[Alpha]`) are **not**
a uniformly enforced convention across approved GDDs — verified directly via grep
against the live files, not inferred from a review-log summary or a task prompt's
framing (see [[feedback-verify-fix-claims-against-file]]).

Actual state (grep-verified 2026-07-10):
- Test-type tags only, no scope tags: `voxel-world.md`, `time-tick-system.md`,
  `camera-input.md`.
- Test-type + scope tags: only on 4 of `scene-world-management.md`'s ~23 ACs (the
  ones added at its later review rounds) — even SWM, the most tag-disciplined doc
  in the project, is not fully scope-tagged.
- Zero tags of any kind, despite being **APPROVED**: `building-system.md`,
  `villager-ai-behavior.md`.
- Zero tags, not yet reviewed: `needs-mood-system.md`,
  `build-validation-navigability.md`, `building-ui.md`, `villager-info-ui.md`.

**Why**: A task prompt during the `resource-item-database.md` adversarial AC review
(2026-07-10) asserted the tag convention was "established across 6 approved GDDs"
with both tag types on every AC. Grepping the actual files showed this was false —
tagging is concentrated in Foundation-layer docs and is inconsistent even there
(type-only vs. type+scope), and two already-approved GDDs ship with no tags at all.
Trusting the prompt's framing without verification would have produced a review
finding built on a false premise.

**How to apply**: Do not assume a prior review round's or a task prompt's claim
about "the established convention" is accurate — grep the actual GDD files before
citing tag coverage as precedent in a review. When recommending tags be added to a
GDD, justify it against the specific peer-tier docs that actually have them (e.g.,
"this is a Foundation-layer doc and its Foundation-layer siblings all have
test-type tags") rather than a blanket "all approved GDDs do this" claim. If ever
asked to enforce tag-based BLOCKING/ADVISORY gating project-wide, flag that
`building-system.md` and `villager-ai-behavior.md` would need a retroactive
tagging pass first. Re-verify this snapshot periodically — it will go stale as
more GDDs are reviewed/tagged.
