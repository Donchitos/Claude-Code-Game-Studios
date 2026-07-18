---
name: project-art-bible-section5-dependency
description: Art Bible Sections 5-9 deferral is safe for Foundation/Core epics but Section 5 blocks Pet Room UX finalization
metadata:
  type: project
---

At the Pre-Production -> Production phase gate (2026-07-13), Art Bible
`design/art/art-bible.md` had only Sections 1-4 complete (Visual Identity, Mood &
Atmosphere, Shape Language, Color System). Sections 5-9 (Character Design
Direction, Environment Design Language, UI/HUD Visual Direction, Asset Standards,
Reference Direction) were still pending. See [[project-petquest-overview]] for the
general section-status context — this memory adds the specific dependency finding
from the Production gate review.

**Why this matters**: Foundation/Core-layer epics (Auth, Data Persistence, Bridge,
Time & Decay, Pet State Machine logic, Currency, Task Lifecycle) have zero
dependency on any of Sections 5-9 — confirmed empirically, since the vertical
slice (`prototypes/petquest-core-loop-vertical-slice/REPORT.md`) built and
playtested all 9 of those systems successfully using flat placeholder rectangles.
But Section 5 (Character Design Direction) specifically is NOT safely deferrable
once Presentation-layer work starts: the Approved GDD `design/gdd/pet-room-screen-ui.md`
(#18) already has Mochi sprite-size values (72/112/152dp) explicitly flagged
"provisional pending Art Bible Section 5," and `design/ux/pet-room-screen.md`'s own
Open Questions repeat this. Sections 6/8/9 have no similar named blocking
dependency in any currently-approved GDD as of this date. Also, the AD-ART-BIBLE
sign-off for Sections 1-4 (verbally granted in the 2026-07-13 gate-check's Art
Director panel note) was never actually written back into `art-bible.md`'s own
header — still reads "Pending (Lean mode — skipped)" — a bookkeeping gap worth
closing at the next touch of that file.

**How to apply**: Don't treat "Art Bible incomplete" as a monolithic blocker or a
monolithic non-issue. Recommend Section 5 be authored early in Production
(alongside or just after Foundation/Core epic kickoff), since it unblocks both the
Pet Room UX spec's remaining collaborative sections and the real-sprite-art swap
the vertical slice itself recommended doing early. Sections 6/8/9 can reasonably
wait until their corresponding asset-production epics are actually scoped.
See also [[project-contrast-audit-overdue]].
