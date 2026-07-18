# Epic: Seed Buffer Mechanic

> **Layer**: Feature
> **GDD**: design/gdd/seed-buffer.md
> **Architecture Module**: Seed Buffer (#10)
> **Status**: Complete (all 3 stories, 2026-07-17)
> **Stories**: 3/3 complete — see table below

## Overview

Seed Buffer solves the Parent Latency problem — the gap between a child submitting a task and a parent approving it. Instead of granting xu immediately (unsafe, unconfirmed) or granting nothing (loses instant gratification), the child receives a "Hạt Giống" (seed) the moment they tap "Đã xong!": an instant, visual, holdable placeholder reward. Infrastructure-wise, this is a single denormalized counter — `seedCount` on `children/{childId}` — that must always equal the count of that child's pending tasks. The system's entire job is keeping that counter honest: +1 on submit, -1 on approve/reject, and self-correcting if it ever drifts. Player-facing, a seed drops into the child's pocket with a small bounce animation on submit, and "blooms" into xu + energy with a burst animation when a parent approves (or quietly withers, with no reward, if rejected).

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-------------------|-------------|
| ADR-0012: Seed Buffer Derivation Strategy | `+1` via client `WriteBatch` on submit; `-1` contract (increment only) for Parent Approval's own batch; read-side clamp in `seedCountProvider` for AC-4; drift correction via a server-only `runTransaction` inside the existing `onTaskApproved` Cloud Function (ADR-0003 §6) — a scoped, justified exception to `absolute_set_on_balance_or_counters`. **Status: Accepted (2026-07-17).** | LOW |

✅ **ADR-0012 reached Accepted status on 2026-07-17** via an independent `/architecture-review` pass (fresh subagent, no authoring bias). The review found 2 blocking issues (phantom TR-IDs, an inline Firestore path string in the ADR's own code example) and 3 should-fix items (a phantom "Parent Approval's Cloud Function" reference corrected to the real `onTaskApproved`, an unflagged amendment to ADR-0003's `submitTask` contract, a missing ADR-0008 dependency + overconfident engine-verification claim) — all 5 were fixed in the ADR before acceptance. See the ADR file and `docs/architecture/tr-registry.yaml` (TR-seedbuffer-001/002/003, added 2026-07-17) for the corrected version.

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|---------------|
| TR-seedbuffer-001 | `seedCount` invariant (`== COUNT(tasks WHERE status == 'pending')`), maintained via `+1`/`-1` on submit/approve/reject | ADR-0012 ✅ (Accepted) — Story 001 |
| TR-seedbuffer-002 | `seedCount` never displays negative (GDD AC-4) | ADR-0012 ✅ (Accepted) — Story 002 |
| TR-seedbuffer-003 | Drift detection + correction (GDD AC-8, Formulas §"Drift detection") | ADR-0012 ✅ (Accepted) — Story 003 |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Seed Drop on Submit — seedCount Increment + BOUNCING Event | Integration | Complete | ADR-0012 |
| 002 | seedCountProvider — Realtime Read with Negative Clamp | Logic | Complete | ADR-0012 |
| 003 | Drift Detection & Correction — onTaskApproved Extension | Integration | Complete | ADR-0012 |

## Scope Notes

- **Bloom and wither animation integration** (Pet Room #18's Mochi reaction, Task Management UI #19's pending-list card removal) are explicitly **out of scope for this epic's stories** — those screens' own UX specs don't exist yet (Pet Room is a partial skeleton; Task Mgmt UI has none). Stories here cover the data-layer contract (`seedCount` write/read/drift-correction) and the parts of the UX spec that are actually written (Nav Shell's badge display, per `design/ux/main-navigation-shell.md` + `design/ux/hud.md`).
- **Seed Badge tap behavior**: display-only at MVP, per the resolved conflict between `seed-buffer.md` and `hud.md` (2026-07-17) — `seed-buffer.md`'s UI Requirements section was corrected to match. No story here should implement a tap-to-navigate affordance on the badge.
- **The `-1` decrement write itself** (on approve/reject) is NOT implemented by this epic — it's owned by Parent Approval (#11), which has no epic or ADR yet. This epic only defines the contract that write must follow (ADR-0012 §2). A story here cannot fully close AC-2/AC-3 (bloom/wither triggers) until Parent Approval exists — flag this dependency explicitly when writing stories.

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/seed-buffer.md` that fall within this epic's scope (AC-1 partial — submit-side only, AC-4, AC-5, AC-6, AC-8; AC-2/AC-3's animation triggers deferred to Pet Room/Task Mgmt UI stories once those exist) are verified
- All Logic and Integration stories have passing test files in `tests/`
- ADR-0012 has reached Accepted status

## Epic Completion Notes

**Closed**: 2026-07-17

All 3 stories implemented, code-reviewed, and closed with full Completion Notes:
- **Story 001** (Seed Drop on Submit): expanded scope mid-implementation after discovering Task Library's own "Complete" epic never actually built the base task-submission write path — built `TaskRepository.submitTask()` alongside the `seedCount +1`, since ADR-0012 §1 requires them in one `WriteBatch`. Code review (flame-specialist + qa-tester) found and fixed a real ADR-0004 violation: the first draft emitted `GameEventType.seedReceived` directly from a repository class, neither of ADR-0004's two sanctioned emit adapters — removed, deferred to whichever future story builds the Task Submission Screen.
- **Story 002** (seedCountProvider): two real discrepancies between ADR-0012 §3's illustrative code snippet and the actually-built sibling `xuBalanceProvider` were caught and corrected *before* implementation (the mandatory injectable Firestore seam; `Stream.value(0)` vs `Stream.empty()`, the latter of which would leave a `StreamProvider` perpetually stuck in `AsyncLoading`). Code review's one BLOCKING claim (a flaky autoDispose test) was investigated and could not be reproduced in 23 independent runs — most likely cross-agent interference from two reviewers running in parallel on the same file, documented transparently rather than either blindly accepted or silently dismissed.
- **Story 003** (Drift Detection & Correction): found before implementation that `onTaskApproved` had no prior `runTransaction` to reuse (this story added the first one in this codebase's Cloud Functions). Code review (security-engineer + qa-tester, independently) found and fixed a genuine correctness bug: the drift correction read `seedCount` from the trigger's pre-transaction snapshot rather than a real `transaction.get()`, undermining ADR-0012 §4's own safety design — two reviewers converging on the same root cause from different angles was treated as real corroboration and fixed, unlike Story 002's unreproducible claim.

**Definition of Done status**:
- All stories implemented, reviewed, closed via `/story-done`. ✅
- All in-scope acceptance criteria verified (AC-1 partial, AC-4, AC-5, AC-6 partial, AC-8; AC-2/AC-3's animation triggers correctly deferred to Pet Room/Task Mgmt UI stories, neither of which exists yet). ✅
- All Logic/Integration stories have passing test files: `tests/integration/seed_buffer/seed_submit_test.dart` (17), `tests/unit/seed_buffer/seed_count_provider_test.dart` (12), `functions/test/index.test.ts` (12 new for this epic, 72 total in the suite). ✅
- ADR-0012 reached Accepted status (2026-07-17, independent architecture review). ✅

**Known gap, explicitly flagged rather than silently treated as resolved**: Story 003's drift-correction transaction relies on Firestore's query-inside-`runTransaction` contention-detection behavior, which has never been verified against a real Firestore backend in this environment (no Java runtime — the same pre-existing constraint documented across Data Persistence Layer, Task Library, and now this epic). Both Story 003's code reviewers recommend this be a hard pre-production gate (an emulator run or staging concurrency test), not something deferred indefinitely.

**What remains out of this epic's scope, by design**: the Task Submission Screen UI (no `/ux-design` spec exists), the `seedReceived` event's actual emit wiring (deferred to that same future screen), the `-1` decrement write itself (Parent Approval #11, no epic/ADR yet), and bloom/wither animations (Pet Room #18 / Task Management UI #19, neither epic'd).
