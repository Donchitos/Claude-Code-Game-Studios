---
name: project-contrast-audit-overdue
description: Color-contrast audit (pale-on-pale risk) flagged at two consecutive phase gates and still not run
metadata:
  type: project
---

The pastel-palette contrast audit (WCAG 4.5:1 check for pairs like Cloud White text
on Peach Glow) was first flagged as an unscheduled risk at the Technical Setup ->
Pre-Production gate (2026-07-13, recorded in
`production/gate-checks/gate-check-2026-07-13.md` exit-criteria #6/#5) and was
re-checked and confirmed still not run at the Pre-Production -> Production gate
(same date, later session). `design/accessibility-requirements.md` §3 and its Open
Questions still carry the exact same unresolved line both times.

**Why**: The palette pairings this would check are already load-bearing in 12+
approved GDDs and growing (every new UX spec that cites Art Bible Section 4 colors
for text-on-background adds more surface area that would need revisiting if the
audit fails). It is cheap, standalone work with zero dependency on anything else
(doesn't need Art Bible Sections 5-9, doesn't need a finished UX spec) yet keeps
getting deferred because nothing structurally forces it to run before more specs
are drafted.

**How to apply**: At any future gate-check, UX review, or art-bible review touching
this project, check `design/accessibility-requirements.md` directly for whether
this audit line has been resolved (don't trust a prior gate's "flagged, tracked"
note as evidence it happened). If it reaches a third gate still unresolved,
recommend elevating it from an advisory exit-criterion to an actual blocking item —
the two-gate pattern suggests it will not get prioritized without that push.
See also [[project-art-bible-section5-dependency]] and
[[project-petquest-overview]].
