# Gate Check: Technical Setup → Pre-Production

**Date**: 2026-07-13
**Checked by**: `/gate-check pre-production` (lean review mode — all 4 director phase-gates ran)

---

## Required Artifacts: 12/13 present

- [x] Engine chosen — Flutter 3.44.4 / Flame 1.37.0 pinned in `CLAUDE.md`
- [x] Technical preferences configured — `.claude/docs/technical-preferences.md`
- [x] Art bible Sections 1–4 — `design/art/art-bible.md` (Sections 5–9 correctly not required at this gate; deferred to Pre-Production → Production)
- [x] 11 Architecture Decision Records in `docs/architecture/`, all covering Foundation-layer systems, **all status Accepted** (ADR-0001–0011)
- [x] Engine reference docs — `docs/engine-reference/flutter-flame/` (VERSION.md, breaking-changes.md, deprecated-apis.md, current-best-practices.md)
- [x] Test framework — `tests/unit/`, `tests/integration/` exist
- [x] CI/CD workflow — `.github/workflows/tests.yml`
- [x] Example test file — `tests/unit/example_test.dart`
- [x] Master architecture document — `docs/architecture/architecture.md`
- [x] `/architecture-review` has been run — `docs/architecture/architecture-review-2026-07-11.md`
- [x] `design/accessibility-requirements.md` — accessibility tier committed
- [x] `design/ux/interaction-patterns.md` — pattern library initialized
- [ ] **Architecture traceability index at the exact path `docs/architecture/requirements-traceability.md`** — MISSING under that name. Equivalent content exists at `docs/architecture/traceability-index.md` (written by `/architecture-review` 2026-07-11). This is a filename mismatch between what the gate check expects and what the architecture-review skill actually produces in non-`rtm` mode — not a missing artifact in substance, but a literal gap against the stated requirement. Flagging rather than silently renaming to manufacture a pass.

## Quality Checks: 9/11 passing

- [x] ADRs cover core systems (state management, event architecture, data persistence, concurrency)
- [x] Technical preferences have naming conventions and performance budgets set
- [x] Accessibility tier is defined and documented
- [x] At least one screen's UX spec started (`design/ux/pet-room-screen.md`)
- [x] All 11 ADRs have Engine Compatibility sections, stamped with Flutter 3.44.4/Flame 1.37.0
- [x] All 11 ADRs have GDD Requirements Addressed sections
- [x] No ADR references deprecated APIs (`HasGameRef`, `TapDetector`, old `Settings(persistenceEnabled:)` only appear as explicit "do NOT use" callouts)
- [x] All HIGH RISK engine domains (Impeller default renderer, Android edge-to-edge, `TapDetector`→`TapCallbacks` migration) addressed inline or tracked as open questions (QQ-02)
- [x] **Architecture traceability matrix has zero Foundation-layer gaps** — Auth & Account, Time & Decay, Item Catalog are all fully ADR-covered
- [ ] `docs/architecture/architecture.md`'s own "Traceability Coverage Check" section is stale — still reports "1 of 104 covered / 103 gaps," lists all 21 systems as GAP, and its header still describes ADRs as Proposed and omits ADR-0011 entirely. Doesn't block work but poisons the document's own evidence base for future audits.
- [ ] 3 Foundation/Core-layer GDDs remain in a live, verified-still-broken state (re-confirmed independently by the Technical Director agent against current file content, unchanged since the 2026-07-11 architecture review):
  - `design/gdd/time-decay.md` L35 — `hoursElapsed = (now - lastApprovedAt).inMinutes / 60.0` (invalid Dart; `DateTime` has no `operator-`; also truncates sub-minute precision). ADR-0005 §2 already specifies the correct `.difference().inMicroseconds / Duration.microsecondsPerHour`.
  - `design/gdd/data-persistence-layer.md` L199–209 — Security Rules block still contains only the blanket wildcard `match /families/{parentId}/{document=**}`, never synced to Accepted ADR-0003 §5 / ADR-0009 §3's reward-gated nested rules. Deploying straight from this file would reproduce the exact vulnerability ADR-0009 exists to close.
  - `design/gdd/flutter-flame-state-bridge.md` L203 — Acceptance Criteria still says subscription happens "trong `onLoad()`", contradicting the already-corrected Core Rule 5 (`onMount()`).

**ADR Circular Dependency Check**: verified against all 11 ADRs (including new ADR-0011). Topological order: `0001 → 0002 → 0003 → 0004 → 0005 → 0006 → 0008 → 0007 → 0009 → 0010`, with ADR-0011 depending on 0003/0006/0008 (no ADR depends on 0011). **No cycles.**

**Engine Validation**: all ADRs agree on Flutter 3.44.4/Flame 1.37.0; no deprecated API usage; post-cutoff APIs (`onMount`/`isMounted`/`onRemove` lifecycle, `PersistentCacheSettings`, `TapCallbacks`, 2nd-gen `onDocumentCreated`) are consistent across ADRs and were independently re-confirmed against real Flame 1.37 behavior by a flame-specialist consultation during the 2026-07-11 review.

---

## Director Panel Assessment

**Creative Director: CONCERNS**
Pillar fidelity across all 21 MVP GDDs is strong and explicit — every GDD names its governing pillar and delivers on it concretely. The MVP's narrowed scope (single-player discipline↔pet-bond loop only; the social "whole neighborhood" half of the hook and most of Pillar 5's customization depth wait for Alpha) is honestly documented, not disguised. The flagged technical defects (B1, B3, time-decay, bridge AC) do not compromise the felt player experience — confirmed directly: a level-up feels equally rewarding whether the bonus is 50 or 75 xu. Recommendation: reconcile `pet-leveling-evolution.md`'s xuBonus **up** to the Formula/Tuning-Knob/AC value set (75/100/125/150), since the pace estimates and safe-range reasoning were built on that set, not the Core Rule table's outlier numbers.

**Technical Director: CONCERNS**
Independently re-read all 5 flagged defects against current file content rather than trusting the prior report's age — all 5 are still live, none self-healed. Confirmed two real fixes since the 07-11 review: all 11 ADRs are now Accepted (closes B2), and ADR-0011 (Shop Purchase Pipeline & Idempotency Fix) is written and Accepted, genuinely resolving TR-shop-003/QQ-01/C1 (moves buy-item from `WriteBatch` to `runTransaction`, keeps ADR-0008's single-flight guard, defines the `onAnimationComplete` interface). The architecture is sound enough to enter Pre-Production; the remaining defects should be attached as per-system conditions, not phase blockers: sync `data-persistence-layer.md`'s rules before Data Persistence is implemented (highest priority — Core layer, implemented early, security-relevant), resolve xuBonus in the not-yet-written Pet Leveling ADR (a design decision, not a technical one), sync `time-decay.md` and the bridge AC before their respective stories, and re-sync `architecture.md`'s stale traceability section.

**Producer: CONCERNS**
Dependency ordering (both the systems-index and the ADR graph) is clean and acyclic — no structural risk. The larger production concern is orthogonal to the architecture findings: **no capacity model or target date exists yet**, which makes milestone risk-tracking impossible once sprints start. Recommends establishing this alongside resolving the xuBonus contradiction as the first two Pre-Production tasks, run in parallel with — not blocking — `/create-control-manifest` and the vertical slice. Flags a concrete failure mode to watch for: if the vertical slice's core loop reaches the leveling/economy system before xuBonus is resolved, the slice stalls mid-build on a design question. Also: ADR acceptance (now done) must stay ahead of `/create-stories`, since Proposed ADRs auto-block story creation — this is now moot since all ADRs are Accepted, but the ordering lesson stands for the 11 not-yet-written should-have ADRs.

**Art Director: CONCERNS**
Art Bible Sections 1–4 are genuinely complete, internally consistent, and correctly traceable to the Visual Identity Anchor — independently re-verified the "11/11 Honey Gold hex references correct" claim via a fresh corpus grep rather than trusting it. Retroactively grants the AD-ART-BIBLE sign-off for Sections 1–4 (the art bible's own header still says "Pending (Lean mode — skipped)" — should be updated to reflect this gate's sign-off). One live, actionable risk in the Art Director's own domain: a contrast audit (pale-on-pale color pairings, e.g. Cloud White text on Peach Glow) is flagged in `accessibility-requirements.md` as an open question but not yet scheduled, even though the flagged color pairings are already cited verbatim in 12+ approved GDDs. Recommends running this audit early in Pre-Production, before the first screen's visual mockup locks in, rather than reactively during the first UX-review pass. Also notes Section 7 (UI/HUD Visual Direction) is accumulating precedent from multiple GDDs already committing to specific dimensions/colors without a central section to anchor them — not a blocker now, but Section 7's eventual authoring will be reconciliation work, not a blank slate.

**Escalation applied**: no director returned NOT READY/REJECT. All four returned CONCERNS. Per the standard escalation rule, overall verdict floor is CONCERNS, not FAIL.

---

## Chain-of-Verification

5 challenge questions run against the CONCERNS draft:
1. *Could any CONCERN be elevated to a blocker?* — Considered C-SEC (insecure Firestore rules pattern in `data-persistence-layer.md`) as the strongest candidate. Not elevated: the GDD is already flagged `Needs Revision` (can't be pulled as implementation-ready), and the correct rules already exist in Accepted ADR-0003/0009 — the mitigating control is in place.
2. *Is each concern resolvable within the next phase, or does it compound?* — All 4 tracked items (capacity model, xuBonus, GDD-rule syncs, stale architecture.md section) have concrete owners and fix paths within Pre-Production; none compounds uncontrollably if tracked as exit-criteria per system.
3. *Did I soften any FAIL condition into a CONCERN?* — No — four independent director agents, each checking from a different angle (creative, technical, production, visual), converged on CONCERNS without prompting toward that answer.
4. **[TOOL ACTION]** *Are there unchecked artifacts that could reveal more blockers?* — Verified via Glob/Bash: no `pubspec.yaml` or `lib/` exist yet (no Flutter project scaffolded), and `docs/architecture/control-manifest.md` does not exist yet. Both are expected at this stage — not new gaps, and not required by this gate's own artifact list.
5. *Do the concerns compound into a blocking problem together?* — Counted 8 distinct concerns across all sources (capacity model, xuBonus, 3 stale GDD snippets, stale architecture.md section, unscheduled contrast audit, Section 7 precedent debt, traceability filename mismatch). Each is independently addressable with a distinct owner; none overlaps or amplifies another.

**Chain-of-Verification: 5 questions checked — verdict unchanged (CONCERNS).**

---

## Verdict: CONCERNS

The phase-entry bar for Technical Setup → Pre-Production is met: architecture is coherent, version-consistent, conflict-free, all Foundation/Core ADRs are Accepted, high-risk engine domains are addressed, and required artifacts are present (with one filename-only gap). Real, verified defects remain — none of them severe enough for any of the four independent director reviews to call NOT READY, but real enough that they should be tracked as explicit exit-criteria rather than allowed to leak silently into implementation.

## Exit-Criteria (tracked, not phase-blocking)

1. **Establish a capacity model / target date** before `/create-epics` (Producer)
2. **Resolve the `pet-leveling-evolution.md` xuBonus contradiction** — reconcile to 75/100/125/150 (Creative + Technical Director recommendation) — via the not-yet-written Pet Leveling ADR, before that system's story is implemented
3. **Sync `data-persistence-layer.md`'s Security Rules block** to Accepted ADR-0003 §5 / ADR-0009 §3 before Data Persistence implementation begins (highest technical priority — Core layer, implemented early, security-relevant)
4. **Sync `time-decay.md` L35 and `flutter-flame-state-bridge.md` L203** to their governing Accepted ADRs (0005, 0004) before their respective stories start
5. **Re-sync `docs/architecture/architecture.md`'s Traceability Coverage Check section** — currently reports 103 phantom gaps against 11 Accepted ADRs
6. **Schedule the color-contrast audit early** in Pre-Production, before the first screen mockup locks in (Art Director)
7. (Minor) Reconcile the traceability index filename — either rename `docs/architecture/traceability-index.md` to `requirements-traceability.md`, or treat the gate-check skill's required path as needing an update to match what `/architecture-review` actually produces

## Recommended Sequence

`/create-control-manifest` (can start immediately — ADRs are Accepted) → resolve items 2 and 5 in parallel (design decision, doesn't block manifest) → `/vertical-slice` (build + playtest; items 3–4 should be fixed before the slice reaches those systems) → `/ux-design` for remaining key screens → `/create-epics` (after item 1 exists) → `/create-stories` → `/sprint-plan`.
