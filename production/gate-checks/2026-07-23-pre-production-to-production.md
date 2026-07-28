# Gate Check: Pre-Production → Production

**Date**: 2026-07-23
**Checked by**: gate-check skill (lean review mode — all four directors spawned, as phase gates require)

## Required Artifacts: 12/16 present

- [x] Vertical slice with REPORT.md — verdict **PROCEED** (prototypes/last-seal-vertical-slice/REPORT.md)
- [x] Art bible complete (9/9 sections) — **AD-ART-BIBLE sign-off APPROVED 2026-07-23** (recorded retroactively during this gate's AD panel)
- [x] All MVP-tier GDDs complete (10 system GDDs, slice-revised 2026-07-23)
- [x] Master architecture document (docs/architecture/architecture.md)
- [x] ≥3 Foundation ADRs — 16 ADRs total
- [x] All Foundation/Core ADRs **Accepted** (ADR-0003 superseded; ADR-0015 Accepted spike-validated 2026-07-23; ADR-0016 Accepted prototype-validated)
- [x] Control manifest exists (docs/architecture/control-manifest.md) — **but stale, see Quality**
- [x] Vertical slice build playable — full loop E2E, headless gate green on every commit
- [x] Slice playtested with 1 documented session (REPORT.md — internal tester)
- [x] HUD design document (design/ux/hud.md, Approved)
- [x] UX specs passed /ux-review — hud.md, villager-panel.md, projects-panel.md all APPROVED
- [x] Entity registry & traceability current (tr-registry.yaml 528 entries, requirements-traceability.md 2026-07-23)
- [ ] **First sprint plan** — production/sprints/ MISSING
- [ ] **Epics (Foundation + Core)** — production/epics/ MISSING
- [ ] **Main-menu + pause-menu UX specs** — design/ux/main-menu.md, design/ux/pause-menu.md MISSING
- [ ] Entity inventory (design/assets/entity-inventory.md) — MISSING (recommended, /asset-spec not run)

## Quality Checks

- [x] Core loop fun validated — tester built multiple houses unguided, "Ich bin sehr begeistert"; verdict PROCEED
- [x] Vertical slice COMPLETE (full start→challenge→resolution cycle; villagers build, sleep, recover)
- [x] Slice validation: played without guidance ✓; communicates what to do ✓ (caveat: door-gap convention was NOT discoverable — tracked as production affordance requirement); no critical fun blockers ✓; core mechanic feels good ✓ (user-stated)
- [~] Core fantasy delivered — **partially**: "direction right, MOOD lacking"; loop payoff (shelter→recovery→warmth) under-communicated. Art Bible §5.3/§5.6/§6.5 is the committed answer; must be early Production work
- [~] Control manifest **stale** (2026-07-11): no ADR-0015/0016 guardrails, predates the slice propagation — refresh before any story embeds it
- [~] Playtest depth thin: 1 internal tester; slice REPORT itself recommends 1–2 external silent-walkthrough sessions
- [~] Estimate baseline uncalibrated: 38d baseline predates the measured slice velocity (~1 feature package/day + 20% integration) — re-baseline before sprint planning
- [~] production/milestones/ missing — unlisted prerequisite for /sprint-plan
- [x] No open Foundation/Core architecture questions (C1/C4 residency tuning + CW-winding rewrite are tracked production stories, not open decisions)
- [x] No ADR circular dependencies; single engine version (4.7-stable) throughout
- Minor: stale "Proposed" cross-references to ADR-0005 inside ADR-0002 (cosmetic)

## Director Panel Assessment

| Director | Verdict | Core feedback |
|---|---|---|
| Creative Director | CONCERNS | Ready creatively; protect three items into Production: ambient-life wave 1 as EARLY target (Pillar 2 under-delivered), loop-payoff as designed feature, 1–2 external playtests before scope lock |
| Technical Director | CONCERNS | Architecture production-ready; control-manifest refresh required before first story; tracked items OK to carry |
| Producer | CONCERNS | Remaining work well-defined and slice-sized; found two unlisted prerequisites (Production milestone, estimate re-baseline). NOTE: the panel's claim that ADR-0015 is still Proposed/uncommitted was **stale and is corrected here** — the spike concluded PASS 5/5 and ADR-0015 is Accepted (commits afb609c, 799ddbc, cc672fb; verified in-file and by the TD panel) |
| Art Director | CONCERNS | Art bible internally consistent, mood gap credibly answered, standards enforceable — **AD-ART-BIBLE sign-off APPROVED** (recorded); asset inventory + menu UX specs are first-sprint items |

## Blockers (path to PASS)

1. **Refresh the control manifest** (`/create-control-manifest`) — fold in ADR-0015/0016 + slice propagation before any story embeds the stale version
2. **Define the first Production milestone** (production/milestones/) and **re-baseline the estimate** with slice velocity
3. **Create epics** (`/create-epics layer:foundation`, then `layer:core`) and **stories** (`/create-stories [epic]`)
4. **Author + review main-menu and pause-menu UX specs** (`/ux-design`, `/ux-review`)
5. **Create the first sprint plan** (`/sprint-plan`), seeded with slice velocity; per-tick re-tuning pass as a tracked story

## Recommendations (non-blocking)

- 1–2 external silent-walkthrough playtests before Production scope lock (CD + slice REPORT)
- `/asset-spec` for the entity inventory (AD: first-sprint item)
- Ambient-life wave 1 and loop-payoff communication as early Production stories, not deferred polish (CD)
- Clean the stale ADR-0005 cross-references in ADR-0002 (cosmetic)

## Verdict: FAIL — expected, with a short defined path

The failure is not a quality problem: every validation-type artifact passes (slice PROCEED, architecture Accepted end-to-end, art bible signed off). What is missing is exactly the *planning* layer Production runs on (epics, stories, milestone, sprint plan, two menu specs). All five blockers are well-defined, slice-sized work items with named skills. No director returned NOT READY.

**Chain-of-Verification**: 5 questions checked, incl. 3 tool actions (stage.txt + artifact scan; ADR-0002 status re-read confirming Accepted; AD-ART-BIBLE header re-read pre/post sign-off recording; producer's stale ADR-0015 claim refuted against the in-file status line) — verdict **unchanged: FAIL** with corrected panel input.

---

## Re-Check Addendum — 2026-07-23 (same day, blocker path executed)

All five blockers from the verdict above are resolved and committed:
1. Control manifest refreshed — Version 2026-07-23, ~39 new rules from ADR-0015/0016 + slice amendments ✓
2. production/milestones/milestone-01-foundation-core.md (13 exit criteria) + estimate re-baseline (32 expected days, slice-velocity-derived) ✓
3. Epics: 8 (6 Foundation + 2 Core) with 108 dependency-ordered stories embedding TR-IDs, ADR guidance, manifest version, test evidence paths ✓
4. main-menu.md and pause-menu.md authored, review-fixed, APPROVED via /ux-review ✓
5. production/sprints/sprint-01.md — 8 stories (5 Must / 3 Should), real story paths, dependency-verified, 20% buffer ✓

AD-ART-BIBLE sign-off was recorded APPROVED during the original panel. Director verdicts stand (4× CONCERNS,
none NOT READY); their tracked concerns are carried as milestone/sprint content (ambient-life wave 1,
loop-payoff, external playtests, re-tune pass) — not as gate artifacts.

### Final Verdict: PASS
Non-blocking recommendations carried forward: /qa-plan sprint before /dev-story (QA plan is a
Production → Polish gate artifact, absent today); 1–2 external silent-walkthrough playtests before
scope lock; /asset-spec entity inventory as a first-sprint item.
