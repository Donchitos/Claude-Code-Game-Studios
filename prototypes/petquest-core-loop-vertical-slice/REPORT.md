# Vertical Slice Report: PetQuest Core Loop

> **Date**: 2026-07-13
> **Slice Duration**: 1 session (~1 day)
> **Target Scope**: 3–5 minutes of polished, continuous gameplay
> **Source GDD**: design/gdd/game-concept.md

---

## Validation Question

Does a player, starting from nothing, experience "pet mirrors real effort, no effort ever lost" (Pillar 1 + Pillar 2) within 3–5 minutes, without developer guidance — and can the team build one such loop in 1–3 weeks at representative quality (15–25h/week capacity)?

This loop was chosen over the full economy (Gacha/Shop/Equipment) because it exercises the game's most novel mechanic and its two highest architecture-risk points (the Flutter↔Flame Bridge and offline-first Firestore transactions) — validate the hardest thing first.

---

## Scope Built

**Systems included:**
- Auth & Account (#1) — PIN entry, PBKDF2-HMAC-SHA256 verification (real, not mocked)
- Data Persistence Layer (#4) — Firestore schema, `runTransaction` approve/reject, `FieldValue.increment()`
- Flutter-Flame Event Bridge (#5) — `GameEventBus`, `onMount()`/`onRemove()` subscription pattern
- Time & Decay (#2) — energy computation (init-only; no multi-day decay observable in a short session)
- Pet State Machine (#6) — Base Mood derivation + Triggered State (EXCITED) on the Flame canvas
- Task Library (#8) — task submission with category-derived rewards
- Seed Buffer (#10) — pending-task count badge
- Parent Approval (#11) — approve/reject transaction
- Currency System (#7) — realtime xu balance
- Pet Room Screen UI (#18) + Main Navigation Shell (#17) — the screens hosting the above

**Art/audio quality level:** Placeholder (flat-colored rectangles), but using the real Art Bible palette (Honey Gold, Peach Glow, Cream Ivory) — not arbitrary colors.

**Shortcuts taken deliberately (documented inline in code):**
- No real Firebase Auth — Auth Emulator hit a `firebase_auth/api-key-not-valid` error on Flutter Web that didn't resolve within the slice's time budget. PIN-gated access (the actually-interesting part) is still real; it's just not layered on a real Firebase Auth identity in this build.
- Firestore Security Rules ownership check (`request.auth.uid == parentId`) replaced with `true` for the same reason. The reward-integrity gate (`rewardOk()`, the actually-interesting ADR-0009 pattern) is kept fully intact and enforced.
- No real Push Notification — parent switches views via a button instead of a notification tap (Cloud Functions/FCM setup is disproportionate infrastructure cost for what it would validate here).
- No Gacha, Shop, Pet Equipment, or Pet Leveling — out of the 3–5 minute loop by design.
- Camera uses default `MaxViewport` (fills available canvas) rather than `CameraComponent.withFixedResolution` — the fixed-resolution letterbox approach didn't scale correctly in testing and wasn't worth further debugging time for a slice validating logic, not cross-device visual fidelity.

**What was cut from original scope:** Nothing beyond what was pre-agreed in Phase 2 (Push Notification, Gacha/Shop/Equipment/Leveling). The Auth Emulator cut was an in-session addition, made transparently and documented at the point it was cut.

---

## Build Velocity Log

| Day | Completed |
|-----|-----------|
| Day 1 | Dev environment setup (Flutter 3.44.6, Firebase CLI, Java/JRE for the emulator — none pre-installed). Full project scaffold: 9 systems, ~20 files, Firestore rules, emulator config. Self-test pass via automated browser control found and fixed 5 real bugs (see Technical Findings). One full submit→approve→react loop confirmed working end-to-end by both agent self-test and a live user playtest, same day. |

**Total elapsed:** <1 day for the full 9-system core loop, including environment setup from zero.

**Velocity estimate:** Environment setup (Flutter/Firebase CLI/Java, all from scratch) took a non-trivial fraction of the day and is a one-time cost, not a recurring one. Excluding that, 9 interdependent systems (Foundation+Core layer, per `docs/architecture/control-manifest.md`) to a working, transaction-correct, reactively-updating state took well under a full working day with an LLM pair-programmer doing the implementation and self-testing. This is a genuinely fast rate relative to the systems-index's own S/M/L effort tags (this scope spans several M-tagged systems) — treat it as an optimistic anchor, not a guaranteed sustained rate, since this session had unusually tight agent/human collaboration and no context-switching overhead.

---

## Playtest Results

| Attribute | Value |
|-----------|-------|
| Total sessions | 2 (1 agent self-test via automated browser control, 1 real user playtest) |
| Internal testers | 1 (the user) |
| External testers | 0 |
| Avg session length | A few minutes each |
| Time to first meaningful action | Not precisely timed, but fast — PIN entry to task submission is 2 screens |

---

## Observations

**Where the tester succeeded without guidance:**
- Completed the full [PIN login → submit task → switch to parent mode → approve → see Mochi react] cycle unassisted, no confusion at any step ("mọi thứ đều rõ ràng" / "everything was clear").

**Where the tester was confused or stuck:**
- None reported.

**Emotional reactions observed:**
- Explicitly flat: "luồng như mô tả, chưa có UI nên chưa có cảm xúc" (the flow works as described, but there's no emotional payoff yet because there's no real UI). This is the expected and correct result for a placeholder-art build — the loop's mechanical correctness was confirmed; its emotional landing is deliberately not yet testable at this fidelity. Not a fun-loop failure signal.

**Agent self-test findings (5 real bugs/gaps found and fixed before the user playtest):**
1. **Real cross-cutting API drift**: ADR-0003 asserts `Settings(cacheSettings: PersistentCacheSettings(...))` replaced the deprecated `persistenceEnabled`/`cacheSizeBytes` pair in `cloud_firestore ^5.x`. As actually resolved (`cloud_firestore` 6.6.0), **no such `cacheSettings`/`PersistentCacheSettings` API exists at all** — the "old" API is still the live, correct one. ADR-0003 needs a correction.
2. **Real cross-cutting API drift**: `riverpod` 3.x removed `AsyncValue.valueOrNull` (`.value` is now the safe nullable accessor) and moved `StateProvider`/`StateNotifierProvider` to a `legacy` import. Neither ADR-0002 nor ADR-0008 (which both prescribe `.valueOrNull`) anticipated this.
3. **Tooling friction, not architecture**: Firebase Auth Emulator connection on Flutter Web produced a persistent `firebase_auth/api-key-not-valid` error across several fix attempts (host variations). Worked around by cutting real Firebase Auth from this slice (see Scope Built).
4. **Real bug in this session's own code**: a fixed `devParentId` string didn't match the real signed-in Firebase Auth UID that Security Rules check against — caused a silent `permission-denied` on every read/write. (Became moot once Auth was cut per #3, but the underlying lesson — path-segment identity must equal `request.auth.uid` exactly — is a real one for whoever wires this for production.)
5. **Real bug in this session's own code**: `MochiComponent` accepted an `initialMood` constructor parameter that `PetQuestGame` never actually passed through — the component always hardcoded `PetMood.content` regardless. Invisible on first app launch (a one-time cold-start event papers over it), but broke the moment the screen hosting the Flame canvas was recreated (e.g., navigating to Parent Dashboard and back) — a freshly-mounted `MochiComponent` would show the wrong mood color with no error, because `GameEventBridge`'s mood-change listener only fires on a *transition*, not on every new subscriber. **This surfaces a real architecture gap**: ADR-0004's "replay last known state" requirement (`TR-bridge-005`) was only implemented as a one-time app-cold-start seed in this slice, not as a true bus-level "replay to any new subscriber" mechanism — production should implement the latter, since any future Flame component that can be dynamically recreated (not just the whole app backgrounding) will hit the same class of bug otherwise.

---

## Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Time to first meaningful action | <1 min (informal target) | Fast, not precisely timed — 2 screens (PIN → task list) |
| Session length | 3–5 min | A few minutes, matches |
| Critical fun blockers found | 0 | 0 |
| Pipeline blockers found | 0 | 2 tooling frictions (Firebase Auth Emulator on web; camera fixed-resolution viewport), both worked around, neither blocking |
| Architecture surprises | 0 | 2 real API-drift corrections needed (ADR-0003 Firestore Settings, ADR-0002/0008 Riverpod `.valueOrNull`) — see Technical Findings |

**Feel assessment:** Not yet assessable at placeholder-art fidelity — the tester was explicit that no emotional reaction is expected or observed until real UI/art exists. Mechanically: task submission is instant, seed-count badge updates immediately, approve→reward→mood-color-change was observed to propagate quickly (sub-second, consistent with the Bridge spike's ~151ms average measurement) once the mood-replay bug was fixed.

---

## Recommendation: PROCEED

The validation question had two parts — did the player experience the core fantasy, and can the team build at this quality on schedule. On the second part: yes, clearly — 9 interdependent Foundation/Core systems went from zero to a transaction-correct, reactively-updating, unguided-completable loop within a single working day (excluding one-time environment setup), which is a strong signal for the 15–25h/week, ~2-month vertical-slice-to-full-loop capacity model already on record. On the first part: the loop was completed correctly and without confusion, but the *emotional* half of the validation question is honestly not yet assessable — placeholder art was always going to produce a flat emotional read, and the tester correctly identified this as an art-fidelity gap, not a loop-design failure. Given (a) zero fun-blockers, (b) zero unresolved architecture blockers (both real API-drift findings have concrete, cheap fixes), and (c) a validated, fast production rate, PROCEED is warranted — with the explicit caveat that a second, lighter emotional-fidelity check (even just swapping in real sprite art for Mochi) would be worth doing early in Production, since that's the one part of the validation question this slice couldn't fully answer.

---

## If Proceeding

**Production requirements** (what must change from slice to production):
- Replace placeholder rectangles with real Mochi sprite art + real UI (the one part this slice couldn't validate emotionally)
- Wire real Firebase Auth (resolve the web emulator `api-key-not-valid` issue, or accept native/mobile as the first real-Auth target instead of web)
- Implement real Push Notification delivery (ADR-0010) instead of the manual parent-mode-switch button
- Re-tighten Firestore Security Rules from this slice's `allow ... if true` back to the real `request.auth.uid == parentId` ownership checks once Auth is wired
- Implement the bus-level "replay last known event per type to any new subscriber" fix for `GameEventBus` (see Technical Finding #5) rather than the one-time cold-start-only seed this slice used

**Architecture adjustments needed:**
- **ADR-0003**: correct the Firestore persistence settings claim — `Settings(persistenceEnabled:, cacheSizeBytes:)` is the real, current API in the resolved `cloud_firestore` version; `cacheSettings`/`PersistentCacheSettings` does not exist. Verify against the exact `cloud_firestore` version pinned for production before finalizing.
- **ADR-0002 / ADR-0008**: re-verify the `.valueOrNull` guidance against whichever `riverpod` version production actually pins — this slice's resolved `riverpod` 3.3.2 removed `.valueOrNull` in favor of a safe `.value`, and moved `StateProvider` to a `legacy` import.
- **ADR-0004**: consider strengthening the "replay last known state" requirement to explicitly cover component remount (not just app background/foreground), per Technical Finding #5.

**Sprint velocity estimate based on slice data:**
- 9 Foundation/Core-layer systems (matching the systems-index's own S/M/L tags, spanning several M-tier systems) reached a working, tested state in ~1 day of focused build+self-test time, excluding one-time environment setup. Treat this as an optimistic per-system anchor (roughly a fraction of a day per S/M-tier system) rather than a guaranteed sustained rate across a full sprint with context-switching, review cycles, and less tightly-coupled agent/human collaboration.

**Scope adjustments from original design:** None needed — the pre-agreed scope cuts (Push Notification, Gacha/Shop/Equipment/Leveling) held up as correctly-scoped; nothing needed to be added back in to complete the loop.

**Performance targets:** Not independently re-verified in this slice (no device profiling was run; this was a Chrome/web debug build). ADR-0001's ≤200 draw-call / 60fps targets remain unconfirmed on real target hardware (mid-range Android) — still an open item, as already tracked from the pre-production gate-check.

**Playtest note:** Only 1 external-facing playtest session exists so far. Run `/playtest-report` to structure it formally, and get 2 more sessions (ideally with someone who hasn't seen the build) before fully committing the team to Production, per the gate's own recommendation.

**Next steps:**
1. `/gate-check pre-production` — formally advance to Production (this report is one of that gate's required artifacts)
2. `/create-epics layer:foundation` — plan Foundation layer epics
3. `/create-epics layer:core` — plan Core layer epics
4. `/sprint-plan` — use this report's velocity data in the estimate

---

## Lessons Learned

- **What assumptions were broken by building to near-production quality?** Two ADRs made confident, flame-specialist-"validated" claims about exact package APIs (`cloud_firestore` Settings, implicitly `riverpod`'s `.valueOrNull`) that turned out to not match the actually-resolved package versions. This is the core lesson vertical slices exist to teach: architecture review and even engine-specialist consultation can still be wrong about exact API shapes until code is actually compiled against real, currently-resolved dependencies — no amount of document review substitutes for that one compile step.
- **What surprised us about the pipeline or architecture?** The Bridge/GameEventBus pattern (the ADR the project treated as highest-risk) worked correctly on the first real implementation attempt once the onMount()/onRemove() lifecycle was followed — the *actual* bug that appeared in that area wasn't the subscribe/unsubscribe timing ADR-0004 worried about, but a simpler, unanticipated one: a newly-created component not receiving replayed state because the "replay last known state" requirement was only ever implemented for the app-cold-start case, not the general case. A one-line requirement in an ADR ("replays last known state") had a specific implementation gap that only surfaced by actually building and re-navigating through the screens.
- **What would we change about the slice scope if we ran this again?** Nothing about the systems chosen — the scope was right-sized and completed within budget. The one process change worth making: budget an explicit, separate small time-box for "verify emulator/tooling connectivity" (Firebase Auth Emulator on web, Java for the Firestore Emulator) before scope-planning the systems themselves, since that consumed real time that had nothing to do with validating the game's actual architecture.

---

> *Vertical slice code location: `prototypes/petquest-core-loop-vertical-slice/`*
> *This code is reference material only. Production implementation is written from scratch.*
> *Never import or refactor this code into production.*
