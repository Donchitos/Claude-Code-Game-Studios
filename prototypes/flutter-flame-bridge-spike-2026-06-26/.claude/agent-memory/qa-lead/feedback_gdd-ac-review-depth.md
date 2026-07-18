---
name: feedback-gdd-ac-review-depth
description: QA-lead GDD reviews must catch upstream Core Rule/Edge Case design gaps, not just Acceptance Criteria wording
metadata:
  type: feedback
---

When reviewing a GDD's Acceptance Criteria readiness, actively hunt for gaps
in the Core Rules and Edge Cases sections themselves — ambiguous state-reset
triggers, unspecified data fields, modal-interaction rules that only name one
of several equivalent cases — not just whether the AC prose reads as
testable.

**Why:** The user holds this review to the standard set by a prior catch on
Parent Approval (#11), where a real transaction-ordering bug was found during
AC review rather than a phrasing nit. The user explicitly references that
precedent when asking for this kind of review (see #21 Parent Dashboard UI
review, 2026-07-04), signaling this is the expected bar going forward, not a
one-off.

**How to apply:** Structure GDD-AC reviews as: (1) a short gap list of
Core-Rule/Edge-Case level issues that must be resolved before AC can be
written honestly, each with a proposed default fix; (2) the draft AC list
itself, marking any criteria that depend on an unresolved gap. Don't silently
paper over an ambiguity by writing AC that only covers the unambiguous part —
surface it. See [[petquest-gdd-review-role]] for the broader workflow context.
