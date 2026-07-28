---
name: feedback-verify-fix-claims-against-file
description: GDD review discipline — never trust a review-log's "all fixed" / "all tagged" summary; grep the actual file
metadata:
  type: feedback
---

Never accept a design-review summary's claim that a fix was applied (e.g., "all 18
ACs tagged," "boot-order Edge Case added") at face value — verify by reading the
actual current file text.

**Why**: The `scene-world-management.md` review log shows this failure mode twice —
re-review #1 found AC13's scope tag was still missing despite re-review #1's own
predecessor claiming "all 18 tagged"; the creative-director explicitly made
grep-verification mandatory after finding the round's own revision summary asserted
changes the artifact didn't actually contain (AC10 malformed, AC7 re-tier claimed
but not applied, scope tags not inline, boot-order Edge Case without an AC — see
`design/gdd/reviews/scene-world-management-review-log.md`). Adversarial re-review
#3 (2026-07-10) continued this discipline and found real value in it: cross-checking
Core Rule 7's abort-unwind claim against AC8's actual text and the Visual/Audio
Requirements table surfaced a genuine missing coverage row that a
summary-level read would have missed.

**How to apply**: For any GDD re-review, especially ones with a "previous blockers
fixed" framing: (1) read the actual AC/Core-Rule/Edge-Case/States-table text, not
just the changelog prose describing it; (2) for every rule that lists multiple
sub-effects (e.g., "camera exits Suspended, UI reappears, overlay fades out"), check
that EVERY downstream artifact — AC, Edge Case row, States table row, cross-document
dependency row — restates the FULL list, not a partial/stale copy. See
[[project-swm-gdd-review-history]] for the concrete recurring case.
