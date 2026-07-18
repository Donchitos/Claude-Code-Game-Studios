---
name: user-review-expectations
description: How this user runs design/art review on PetQuest — expects specific, actionable findings, not rubber-stamp approvals, and values explicit forward-reference flagging over silent assumption
metadata:
  type: user
---

The user (quang.dao0809@gmail.com) runs PetQuest through a very rigorous, iterative
multi-agent review process (visible across `production/session-state/active.md`): every
GDD goes through lean-mode specialist consults plus an independent fresh-subagent review,
and essentially every review pass this session found at least one real defect (bugs, math
errors, cross-doc contradictions, bidirectionality gaps) — a ~100% hit rate across 20+
reviewed docs. The team's own working norm, already established before any art-director
gate call, is: **flag forward references and provisional values explicitly rather than
silently assuming or silently blocking** (e.g., Pet Room's Mochi sprite sizes are marked
"Art Director recommendation, not final pin, pending Art Bible Section 5" rather than
either inventing a fake final value or halting work).

**How to apply**: when giving a gate verdict or design review, do not rubber-stamp just
because a section-count requirement is technically met. Look for (a) real cross-doc
consistency risks even if out of literal scope, and (b) whether deferred decisions are
being tracked with an explicit flag/open-question (good, matches team norm) versus silently
assumed (bad, flag it). CONCERNS-level findings should be specific and actionable, citing
exact files/values — vague "looks fine" verdicts are not this team's norm and would be a
mismatch with how every other department in this project has operated.
