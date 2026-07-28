# Cross-GDD Review Report

**Date:** 2026-06-28  
**Mode:** full (lean — no subagents, single-session analysis)  
**GDDs Reviewed:** 6  
**Systems Covered:** Auth & Account · Time & Decay · Data Persistence Layer · Flutter-Flame State Bridge · Pet State Machine · Currency System  
**Entity Registry:** Empty — consistency checks relied on full GDD reads. Run `/consistency-check` after blockers resolved to populate registry.

---

## Verdict: ~~FAIL~~ → RESOLVED IN SESSION

All 3 blocking issues were resolved in the same session. GDDs flagged below now contain the fixes. Individual `/design-review` passes recommended before architecture begins.

---

## Consistency Issues

### Blocking (resolved in-session)

#### 🔴 C-1: Schema Conflict — `pin` field stale after Auth revision
- **Files:** `data-persistence-layer.md` (schema) vs `auth-account.md` (revised 2026-06-28)
- **Issue:** Data Persistence schema listed `pin: String (SHA-256 hash)`. Auth GDD was revised to use PBKDF2 with two fields: `pinHash` + `pinSalt`.
- **Fix applied:** `data-persistence-layer.md` schema updated to `pinHash: String` + `pinSalt: String`.

#### 🔴 C-2: energyReward — architectural conflict between two GDDs
- **Files:** `data-persistence-layer.md` (used `task.energyReward` per-task field) vs `time-decay.md` (used global constant `energyPerTask = 25`)
- **Issue:** Two incompatible models. If programmer follows Time & Decay (global constant), the `energyReward` field in the task schema is never written → approve batch reads null.
- **Design decision:** Per-task field chosen. Task Library GDD (#8) owns values per category. Default = 25.
- **Fix applied:** `time-decay.md` Formula 2 updated to `task.energyReward`; Tuning Knobs clarified that 25 is the default. `data-persistence-layer.md` task schema and interactions table updated to note Task Library writes `energyReward`.

#### 🔴 C-3: `storedEnergy` race condition on concurrent approvals
- **File:** `data-persistence-layer.md`
- **Issue:** Approve Task Batch used absolute set `storedEnergy_new = min(100, storedEnergy + energyReward)`. Multiple concurrent approvals (offline backlog flush) all compute from same cached value → last-write-wins → energy additions silently lost. Currency GDD correctly used `FieldValue.increment()` for `xuBalance` but energy did not.
- **Fix applied:** Batch now uses `FieldValue.increment(+task.energyReward)` for `storedEnergy`. Cloud Function `onTaskApproved` enforces cap at 100 post-write (same Cloud Function pattern as `onChildProfileDelete`).

---

### Warnings (resolved in-session)

#### ⚠️ C-4: xuReward range inconsistency in Currency GDD
- **File:** `currency-system.md`
- **Issue:** Sources & Sinks table listed `10–50 xu`; provisional table and Tuning Knobs both listed `10–20 xu`. "50 xu" was a draft artifact.
- **Fix applied:** Sources table updated to `10–20 xu`.

#### ⚠️ C-5: Stale "(chưa design)" annotation in Flutter-Flame Bridge
- **File:** `flutter-flame-state-bridge.md`
- **Issue:** Auth & Account was listed as "GDD #1 — chưa design" in Bridge dependencies. Auth is now Approved.
- **Fix applied:** Updated to reference Auth provider contract (`activeChildProvider`, `authStateProvider`, `parentProfileProvider` from `lib/providers/auth_providers.dart`). Open Question marked resolved.

#### ⚠️ C-6: Flutter-Flame Bridge incorrectly listed as Data Persistence dependent
- **File:** `data-persistence-layer.md`
- **Issue:** Bridge is pure event routing — it reads from Riverpod providers, not Firestore directly. Listing it as a direct Data Persistence consumer was architecturally wrong.
- **Fix applied:** Removed Bridge from Interactions table. Added clarifying note that Bridge has no direct Firestore dependency.

---

## Game Design Issues

### No Blocking issues found.

### Warnings (carry-forward — not fixed in-session)

#### ⚠️ D-1: Economy end-state — xu sink may deplete within 5 months
- **Files:** `currency-system.md`
- **Issue:** 30 MVP items × avg 80 xu = ~2,400 xu total shop content. At 15 xu/day: cleared in ~160 days. After that, xu accumulates with no meaningful sink. Gacha (#12) and future releases will add sinks, but no explicit plan exists.
- **Recommendation:** Task Library GDD (#8) and Item Database GDD (#3) should note a minimum ongoing content volume target. Currency GDD should add a design note acknowledging the sink horizon and mitigation plan (e.g., seasonal items, gacha as primary ongoing sink).
- **Not blocking:** Architecture unaffected. Flag for GDD #3 and #12 authoring.

#### ⚠️ D-2: Uniform energyPerTask reduces Pillar 2 signal
- **Files:** `time-decay.md`, `currency-system.md`
- **Issue:** All tasks give the same 25 energy (until Task Library overrides). Pet cannot reflect that "học đàn 30 phút" was harder than "quét nhà 5 phút" — undermines "pet is a mirror of effort."
- **Recommendation:** Task Library GDD (#8) must include per-category `energyReward` values (not just xuReward). Design decision C-2 chose the per-task architecture — Task Library must implement it.
- **Not blocking now:** Constraint noted for GDD #8 authoring.

---

## Cross-System Scenario Issues

**Scenarios walked: 3**
1. Standard single task approval chain
2. Multiple concurrent approvals (offline backlog flush)
3. App foreground after background

### Blockers (resolved — see C-2, C-3 above)

**S-1:** Standard approval chain — `task.energyReward` null read → fixed by C-2  
**S-2:** Concurrent approval backlog — storedEnergy data loss → fixed by C-3

### Info

**S-3: App foreground after background ✅**  
Flutter-Flame Bridge edge case spec ("replay last state") covers this correctly. No issue.

---

## GDDs Flagged for Re-review

| GDD | Issues Fixed | Recommended Action |
|-----|--------------|--------------------|
| `data-persistence-layer.md` | C-1, C-2, C-3, C-6 | `/design-review` before architecture |
| `time-decay.md` | C-2 | `/design-review` before architecture |
| `currency-system.md` | C-4 | `/design-review` before architecture |
| `flutter-flame-state-bridge.md` | C-5, C-6 | `/design-review` before architecture |

**Auth & Account** and **Pet State Machine** — no issues found. No re-review required.

---

## Pillar Alignment
All 6 GDDs serve at least one pillar. No pillar drift. No anti-pillar violations.

## Player Fantasy Coherence
All fantasies reinforce one consistent identity: the disciplined, proud child who owns their world. No conflicts.

## Cognitive Load
3–4 active systems per session — within comfortable range for age 6–10.

---

## Final Verdict: CONCERNS

Blockers were resolved in-session. Remaining items are advisory. Architecture may begin after individual re-reviews of the 4 flagged GDDs pass.

**Required before architecture:**
1. `/design-review design/gdd/data-persistence-layer.md` ← highest priority (most changes)
2. `/design-review design/gdd/time-decay.md`
3. `/design-review design/gdd/currency-system.md`
4. `/design-review design/gdd/flutter-flame-state-bridge.md`

**Constraint for future GDD authoring:**
- GDD #3 (Item Database): note ongoing item release cadence as economy sink mitigation
- GDD #8 (Task Library): must include per-category `energyReward` values, not just `xuReward`
- GDD #12 (Gacha): primary ongoing xu sink — economy balance depends on this being designed carefully
