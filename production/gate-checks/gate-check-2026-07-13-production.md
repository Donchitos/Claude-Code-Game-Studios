# Gate Check: Pre-Production → Production

**Date**: 2026-07-13
**Checked by**: `/gate-check` (auto-detected Pre-Production → Production; lean review mode — all 4 director phase-gates ran)

---

## Required Artifacts

- [x] Vertical slice exists with a REPORT.md — `prototypes/petquest-core-loop-vertical-slice/REPORT.md`, verdict PROCEED
- [x] Master architecture document — `docs/architecture/architecture.md` (v1.1)
- [x] At least 3 ADRs covering Foundation-layer decisions — 11 ADRs exist, all covering Foundation/Core
- [x] All Foundation and Core layer ADRs status Accepted — verified independently by Technical Director (all 11 ADR Status lines read Accepted)
- [x] Control manifest exists — `docs/architecture/control-manifest.md`
- [x] All MVP-tier GDDs from systems index complete — 21/21 Approved
- [ ] **First sprint plan** — `production/sprints/` does not exist. Expected at this point (creating it is Production's first activity, not a precondition), per Producer's assessment.
- [ ] **Epics** — `production/epics/` does not exist (`/create-epics` never run). Same as above — expected, not a gap.
- [ ] **Art bible complete (all 9 sections) + AD-ART-BIBLE sign-off recorded in file** — only Sections 1–4 exist (~44%). Sections 1–4's sign-off was verbally granted at the prior gate but never written into `art-bible.md`'s header (still reads "Pending (Lean mode — skipped)").
- [ ] Entity inventory — `design/assets/entity-inventory.md` does not exist (recommended, not blocking)
- [ ] **UX specs for key screens** — only `design/ux/pet-room-screen.md` exists, and it is incomplete (9 "[To be designed — collaborative]" placeholders remain). No `design/ux/hud.md` exists. No main-menu or pause-menu spec exists (Creative Director: pause-menu is a non-issue for a persistent mobile pet app; main-menu equivalent is PIN entry + Main Nav Shell, which has a GDD — not a real gap).
- [ ] No `/ux-review` has been run on any spec yet.

## Vertical Slice Validation (all passed)

- [x] A human played through the core loop without developer guidance
- [x] The game communicated what to do within the first 2 minutes (2 screens: PIN → task list)
- [x] No critical fun-blocker bugs
- [x] Core mechanic feels achievable to build at this quality/pace (per user's own debrief answer: "khả thi, tốc độ này ổn")

No auto-FAIL triggered — all vertical slice validation items are YES.

## Quality Checks

- [x] Architecture document has no unresolved Foundation/Core-layer open questions of consequence — the two listed (QQ-02 Impeller profiling, QQ-03 FCM dedup) are legitimately deferred, not blockers
- [ ] **Architecture document's Open Questions table is stale**: QQ-01 and QQ-04 are still listed open, but ADR-0011 (Accepted 2026-07-11) closes both — confirmed by Technical Director reading ADR-0011 §Decision 1/2/5 directly
- [x] **Core loop fun validated** by playtest data (per vertical slice report + user debrief)
- [ ] **2 real ADR-vs-actual-package API corrections needed**, surfaced by the vertical slice and confirmed propagated into `control-manifest.md`:
  - ADR-0003's `Settings(cacheSettings: PersistentCacheSettings(...))` claim does not match the actually-resolved `cloud_firestore` 6.6.0 API (which has no such parameter) — manifest currently forbids the correct (`persistenceEnabled`/`cacheSizeBytes`) API as a result.
  - ADR-0002/ADR-0008/ADR-0009's `.valueOrNull` guidance does not match actually-resolved `riverpod` 3.3.2 (which removed `.valueOrNull`; `.value` is now the safe accessor) — manifest currently forbids the correct (`.value`) usage as a result.
- [ ] **ADR-0004 architecture gap**: "replay last known state" (TR-bridge-005) is scoped only to app background→foreground recovery; the vertical slice found the real requirement is broader — any dynamically remounted Flame subscriber needs replay, not just the whole-app case. Needs correcting before the Bridge (#5) implementation story.
- [ ] **Color-contrast audit** (pale-on-pale risk, e.g. Cloud White on Peach Glow) flagged by Art Director at the prior gate (2026-07-13, Technical Setup → Pre-Production) — confirmed by Art Director this gate that it is STILL unresolved, two gates running, with zero movement. `design/accessibility-requirements.md` carries the identical unresolved line from before.

---

## Director Panel Assessment

**Creative Director: CONCERNS**
Pillar fidelity remains strong and honestly documented (drift caught and reconciled with dated notes, not hidden). The vertical slice validated the mechanical half of the core loop cleanly, but the emotional half — Pillar 2, "pet mirrors the child's effort," the single most differentiating part of the game — has never actually landed on a player, and the playtester's flat emotional reaction ("chưa có UI nên chưa có cảm xúc") is the expected, correct result at placeholder-art fidelity, not a design failure. Foundation/Core-layer epics have zero dependency on finished art and should proceed now. Condition: within the first Production increment, produce real Mochi art for the 5 base moods + 1-2 triggered animations, drop into the validated loop, and run a lightweight emotional-fidelity check (pass criterion: Art Bible's own "text-off, mood-still-readable" test) — before the Pet Room screen (#18) is implemented. Also: Art Bible Section 5 (Character Design) must land before that check and before the Pet Room UX spec can be finished (it has 9 placeholder sections depending on it). The "missing main-menu/pause-menu spec" finding is not a real gap — a persistent mobile pet app doesn't have a pause menu, and the main-menu equivalent (PIN entry + Nav Shell) already has a GDD.

**Technical Director: CONCERNS**
Independently verified all 11 ADR Status lines read Accepted, and read ADR-0011 directly to confirm it genuinely closes QQ-01 and QQ-04 (the architecture.md Open Questions table is simply stale, not substantively wrong). The architecture is sound and complete enough to begin real implementation — none of the following invalidate a design decision. Three items, triaged by urgency: (1) the Firestore Settings API correction and (2) the Riverpod `.valueOrNull` correction are both mechanical, compiler-catchable fixes localized to one file each — BUT both have propagated into `control-manifest.md` as mandatory rules that now actively forbid the correct, working API. Fix: pin production package versions first, correct the source ADRs against those exact pins (don't blindly copy the slice's observed API names — that just trades one unverified claim for another), then regenerate the manifest with a version bump — all before the first Data Persistence/Auth/Currency stories. (3) ADR-0004's replay-semantics gap is the one genuinely architectural item (not just an API name) and sits in the highest-risk subsystem (the Bridge) — must be corrected before the Bridge (#5) implementation story, though not urgent enough to block gate passage since the production design's `StatefulShellRoute` keeps FlameGame alive across tab switches, partially mitigating the slice's exact trigger. Housekeeping: mark QQ-01/QQ-04 Resolved in architecture.md; keep QQ-02 (Impeller device profiling, correctly deferred to Pet Room ship) and QQ-03 (FCM dedup, accepted tradeoff) open.

**Producer: CONCERNS**
Missing epics/sprints are not a gap — creating them is Production's first activity, not a precondition, and requiring them to already exist would be circular. Zero blocked stories is a non-signal (nothing exists yet to block). The real concern: the vertical slice's velocity (9 Foundation/Core systems in under 1 day) is a legitimate proof that the architecture is viable and the solo-dev+Claude collaboration model can execute against it — but it is an n=1, best-case, single-session, throwaway-quality data point that must NOT be used to anchor sprint commitments. Production stories carry overhead the slice skipped entirely (70% test coverage floor, ADR compliance, QA gates, code review, calendar-week context-switching). Recommendation: treat Sprint 1 as a calibration sprint sized at ~40-50% of what the slice's pace implies; measure real production velocity with all overhead included; recalibrate Sprint 2+ from that data. The incomplete Art Bible/UX specs are not a Foundation blocker (those 9 systems are code/architecture-focused, UI-independent) but must be time-boxed against the ~9-week runway to the 2026-09-13 vertical-slice-to-loop target — they become a hard blocker the moment a UI/HUD/screen-flow epic enters a sprint. Flagged as risk-register items R-01 (Art Bible) and R-02 (UX specs), each needing an owner and deadline before the first UI-dependent epic. One sequencing check worth doing before locking Sprint 1: verify the Auth/PIN and Push Notification epics you intend to schedule are genuinely UI-independent — those two often have a quiet screen/permission-flow surface that needs a UX spec.

**Art Director: CONCERNS**
The Art Bible's 44% completion (Sections 1-4) is not a blocker for the coding work that comes first — empirically confirmed, since the vertical slice already built and playtested all 9 Foundation/Core systems using flat placeholder rectangles with zero art-direction input needed. Two real gaps against the letter of this gate remain regardless: the gate requires all 9 sections plus a recorded sign-off in the file itself, and even Sections 1-4's sign-off (verbally granted at the prior gate) was never actually written into `art-bible.md`'s header. Foundation/Core coding should proceed in parallel with finishing Sections 5-9 — recommended, not just permitted — with one exception: Section 5 (Character Design) is a named, real dependency for both Mochi's production art and the Pet Room UX spec's 9 remaining placeholder sections, and should be authored early in Production alongside Foundation/Core kickoff, not deferred with the rest. `design/ux/hud.md` doesn't exist at all despite being referenced by name in 3+ approved GDDs, and has no dependency on the missing art sections — it could be drafted now. Most pressing: the color-contrast audit flagged at the prior gate (2026-07-13) has had zero movement across two consecutive gate-checks — `design/accessibility-requirements.md` still carries the identical unresolved line. This should be run this week, standalone, with no dependency on anything else.

**Escalation applied**: no director returned NOT READY/REJECT. All four returned CONCERNS. Per the standard escalation rule, overall verdict floor is CONCERNS, not FAIL.

---

## Verdict: CONCERNS

The phase-entry bar for Pre-Production → Production is met on the items that actually gate *starting* Production work: the architecture is Accepted end-to-end, the control manifest exists, all 21 MVP GDDs are complete, and the vertical slice validated the core loop's mechanics and the team's build velocity with zero fun-blockers. What's missing (epics, sprints) is expected to be created *as* Production begins, not before. Real gaps exist against the letter of this gate's artifact list (Art Bible completion, UX specs, sign-off bookkeeping) and two genuine technical corrections need to land before specific upcoming stories — none of which stopped any director from recommending PROCEED, but all of which should be tracked as explicit, owned exit-criteria rather than left to surface unexpectedly mid-sprint.

## Exit-Criteria (tracked, not phase-blocking)

1. **Pin production package versions, correct ADR-0003 (Firestore Settings) + ADR-0002/0008/0009 (`.valueOrNull`), regenerate `control-manifest.md` with a version bump** — before the first Data Persistence/Auth/Currency story (Technical Director's highest-priority item — the manifest currently forbids the correct APIs)
2. **Correct ADR-0004's "replay last known state" scope** (app-foreground-only → any remounted subscriber) — before the Bridge (#5) implementation story
3. **Run the color-contrast audit** (pale-on-pale risk) — standalone, no dependency, two gates overdue
4. **Author Art Bible Section 5 (Character Design) + `design/ux/hud.md` early in Production**, in parallel with Foundation/Core epic kickoff — both are named dependencies for the Pet Room screen and its UX spec
5. **Produce real Mochi art (5 moods + 1-2 triggered animations) and run a lightweight emotional-fidelity playtest** within the first Production increment, before the Pet Room screen (#18) is implemented — the one part of the core fantasy the vertical slice couldn't validate
6. **Treat Sprint 1 as a calibration sprint (~40-50% of the vertical slice's implied pace)**, not a velocity commitment — recalibrate from measured production throughput, not prototype throughput
7. **Mark QQ-01/QQ-04 Resolved** in `architecture.md`'s Open Questions table (ADR-0011 already closes both) — trivial housekeeping
8. **Fix the AD-ART-BIBLE sign-off bookkeeping** — Sections 1-4 were verbally approved at the prior gate; write that into `art-bible.md`'s header
9. Add R-01 (Art Bible)/R-02 (UX specs) to a risk register with owners and deadlines tied to the first UI-dependent epic; verify Auth/PIN and Push Notification epics don't have a hidden UX-spec dependency before locking Sprint 1

## Recommended Sequence

`/create-epics layer:foundation` and `layer:core` (can start now) → in parallel: exit-criteria 1-3 (ADR/manifest corrections + contrast audit, all fast) and exit-criteria 4 (Art Bible §5 + HUD spec) → `/create-stories` per epic → `/sprint-plan new` (conservative, calibration-sized per exit-criterion 6) → exit-criterion 5 (Mochi art + emotional check) before the Pet Room story specifically → `/qa-plan sprint` before implementation begins in earnest.
