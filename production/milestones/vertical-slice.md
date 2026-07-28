# Milestone: Vertical Slice

## Overview

- **Target Date**: ~2026-09-13 (≈2 months from 2026-07-13, when this capacity model was set)
- **Type**: Vertical Slice
- **Duration**: ~8 weeks
- **Number of Sprints**: TBD (set when `/sprint-plan` runs — not yet created)
- **Team Capacity**: Solo developer + Claude Code, **15–25 hours/week**

## Milestone Goal

Prove the core loop is fun and technically sound end-to-end before committing to full
MVP production: a child submits a real-world task, a parent approves it from a
notification, and the pet visibly reacts — reward flows through the full Seed →
Approve → Chest/Xu → Shop/Equip chain without a developer manually poking Firestore.
This is the Short-Term loop from `design/gdd/game-concept.md` (submit → seed →
parent-approve → reward → shop), running on the real architecture (Accepted ADRs
0001–0011), not a paper description of it.

This milestone does **not** require all 21 MVP systems fully polished — it requires
enough of the core-loop chain playable to validate the central hypothesis (discipline
↔ pet-bond loop feels good) and to stress-test the highest-risk architecture pieces
(Flutter↔Flame Bridge, offline-first Firestore writes, PIN auth) before investing in
full epic/story breakdown.

## Success Criteria

- [ ] A child profile can be created and PIN-authenticated (Auth & Account)
- [ ] A task can be submitted, approved by a parent (real push notification, not a manual Firestore edit), and the reward reaches the pet visibly (Task Library → Parent Approval → Currency → Pet State Machine → Bridge → Pet Room)
- [ ] At least one full [start → challenge → resolution] cycle works without developer intervention
- [ ] A human (ideally not the developer) plays through this loop without guidance and understands what to do within 2 minutes
- [ ] No critical "fun blocker" bugs in the sliced scope
- [ ] Performance: 60fps / ≤200 Flame draw calls on the Pet Room screen (per ADR-0001)
- [ ] At least 1 documented playtest session exists (`production/playtests/` or equivalent)

## Feature List

*To be filled in by `/vertical-slice` when it runs — it will scope the minimal system
subset needed for the loop above (likely: Auth & Account, Data Persistence, Bridge,
Pet State Machine, Task Library, Parent Approval, Currency, Push Notification, Pet
Room Screen UI, Main Navigation Shell — the Foundation/Core layer plus the two
Presentation screens the loop touches). Feature/Presentation systems not on this path
(Gacha, Shop, Pet Equipment, Pet Leveling, etc.) are explicitly NOT required for the
slice to be considered complete — they validate the loop, not the full economy.*

### Must Ship (Milestone Fails Without These)

| Feature | Design Doc | Owner | Sprint Target | Status |
|---------|-----------|-------|--------------|--------|
| *(populated by `/vertical-slice`)* | | | | |

### Should Ship (Planned but Cuttable)

| Feature | Design Doc | Owner | Sprint Target | Cut Impact | Status |
|---------|-----------|-------|--------------|-----------|--------|

### Stretch Goals (Only if Ahead of Schedule)

| Feature | Design Doc | Owner | Value Add |
|---------|-----------|-------|----------|

## Quality Gates

| Gate | Threshold | Measurement Method |
|------|-----------|-------------------|
| Frame rate | 60fps target, ≤16.6ms/frame | DevTools + platform-native profiling (per ADR-0001) |
| Draw calls | ≤200/frame, Flame canvas only | Manual design-time tally (per ADR-0001 — no runtime counter exists in Flame 1.37) |
| Bridge latency | <439ms parent-approve → child-visible (already spike-measured) | Manual timing during playtest |
| Critical bugs | 0 open fun-blockers | Playtest notes |

## Risk Register

| Risk | Probability | Impact | Mitigation | Owner | Status |
|------|------------|--------|-----------|-------|--------|
| 2-month target is optimistic for 15–25h/week solo + 8+ interdependent Foundation/Core systems | Medium | Slice slips past target date | Scope the slice narrowly (see Feature List note above) — do not attempt all 21 systems; re-check progress at the 4-week mark | User/Producer | Open |
| Vertical slice touches 3 systems that were recently GDD-synced (time-decay.md, data-persistence-layer.md, bridge) — implementation could surface a residual bug the sync missed | Low | Slice stalls mid-build | Re-verify against ADR text directly during implementation, not just the GDD | technical-director / lead-programmer | Open |
| Economy/leveling path (xuBonus, now reconciled) not yet ADR-backed | Low | Minor rework if implemented before its ADR exists | Write the Pet Leveling & Evolution Consistency ADR before that system is coded, or treat the reconciled GDD value as provisional until then | User | Open |

## Dependencies

### Internal Dependencies

| Feature | Depends On | Owner of Dependency | Status |
|---------|-----------|-------------------|--------|
| Vertical slice core loop | 9 must-have ADRs (Accepted) | technical-director | ✅ Done |
| Vertical slice core loop | Control Manifest | technical-director | ✅ Done (`docs/architecture/control-manifest.md`) |

### External Dependencies

| Dependency | Provider | Status | Risk if Delayed |
|-----------|---------|--------|----------------|
| Firebase project (Auth, Firestore, FCM, Cloud Functions) | Firebase/Google | Assumed available (spike already validated against a real project) | Low — already proven reachable in the multi-device sync spike |

## Review Schedule

| Date | Review Type | Attendees |
|------|-----------|-----------|
| ~2026-07-27 (Week 2) | Early progress check | User + Producer |
| ~2026-08-10 (Midpoint) | Mid-milestone review | Full director panel |
| ~2026-09-06 (Week N-1) | Pre-milestone review | Full director panel |
| ~2026-09-13 (Target) | Milestone review — PROCEED/PIVOT/KILL verdict via `/vertical-slice` | Full director panel |

---

*Capacity model established 2026-07-13 as part of `/gate-check pre-production` exit-criteria #1 (Producer's top concern — no timeline existed before this).*
