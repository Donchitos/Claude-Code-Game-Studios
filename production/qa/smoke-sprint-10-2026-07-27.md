# Smoke Check — Sprint 10 (consolidated, at hand-off)

**Date**: 2026-07-27
**Scope**: critical-path check for the full Sprint 10 delivery (14 stories complete — see
`qa-signoff-sprint-10-2026-07-27.md` §1 for the corrected count against the Sprint Result's "16/16" claim).
**Owner**: qa-lead. Produced per Sprint 9 sign-off condition #4 ("a single consolidated smoke-check
artifact per sprint at hand-off") — the first sprint this habit is followed for.

---

## 1. What was run

Full headless GdUnit4 suite (`tests/run-tests.cmd`, both `res://tests/unit` and `res://tests/integration`),
per each story's own recorded final run. **Not re-executed fresh in this QA session** — this artifact
consolidates the last, highest test-count recorded run (`build-validation-008`'s own close, the sprint's
final story), cross-checked for internal consistency against every other story's own recorded count (see
sign-off §1's monotonic sequence 1198 → 1241 → 1250 → 1264 → 1298 → 1307 → 1320 → 1330 → 1345 → 1355 →
1383). No contradiction found across any of the 14 recorded runs.

## 2. Final suite numbers

**1383 test cases · 0 errors · 0 failures · 0 flaky · 0 skipped · 0 orphans · exit code 0**

Growth this sprint: 1198 (Sprint 9's parent-verified close) → 1383 (+185 test cases across 14 stories).

## 3. Player-visible paths — automated evidence vs. still human-unverified

| Player-visible path | Automated coverage | Status |
|---|---|---|
| A villager gets tired over time and reacts | `shelter_recovery_live_pair_test.gd` (real pair, real tick dispatch) | **Covered** — proven in a headless harness, not yet observed by a human in the running game |
| A villager claims and travels to a bed | `sleep_and_home_test.gd` + the live-pair test | **Covered** (headless) |
| A villager sleeps and recovers faster in a sheltered room vs. in the open | `shelter_recovery_live_pair_test.gd` (×1.0 vs ×0.7, both asserted) | **Covered** (headless) — the milestone's own headline payoff |
| The game boots into a populated, visible world | `world_genesis_boot_test.gd`, `villager_need_seeding_boot_test.gd`, `gameworld_e2e_loop_test.gd` | **Covered** (headless boot path); **not confirmed by a human looking at a running build this sprint** |
| Villagers have a visible, clickable body | `villager_body_view_test.gd` + `villager_body_integration_test.gd` + 2 screenshots (`presentation-003-villager-body-standing-20260727-1.png`, `...-sliced-20260727-2.png`) | **Partially covered** — screenshots exist and show a standing and a sliced figure; no human playtest of clicking a villager in a live session is recorded |
| A player draws a room and it gets built by a villager | Prior-sprint coverage (`building-023` ghost preview, `building-030`/`villager-ai-012` job cycle) — nothing new this sprint changes this path directly | **Not exercised this sprint**; last confirmed via screenshots in Sprint 9 |
| A player places a bed (furniture) | `furniture_placement_base_test.gd`, `multi_cell_furniture_placement_test.gd` (headless) | **Covered logically**; **no screenshot or human observation of placing a bed in a live session exists for this sprint** |
| A sealed room without a roof/shelter shows a warning to the player | `warning_info_tiers_test.gd` (headless); **cannot fire end-to-end for a real bed** — no bed `ItemDefinitionResource` exists in `data/items/` yet (RID content authoring not yet scheduled) | **Logic covered, content-blocked** — see sign-off §4.1 |

## 4. What a human playtest still needs to confirm

None of the above headless proofs have been observed by a human against a running build this sprint. A
playtest pass should specifically confirm:

1. **The game boots into a world** — terrain visible, no black screen or hang, within the measured boot
   budget from prior sprints (~2.6 s).
2. **Villagers are visible** — the placeholder 2-block figures actually render at settlement-camera
   distance and are not, e.g., invisible due to a material/lighting issue headless tests cannot catch.
3. **A drawn room gets built** — a player can draw walls/floor/roof, release the project, and see a
   villager actually construct it (this path is unchanged this sprint but has not been re-confirmed live
   since Sprint 9).
4. **A villager moves in** — a player can place a bed, and over real playtime (or an accelerated/warped
   session) observe a villager actually walk to it, claim it, and sleep — the crown's headless proof made
   visible. This is the single most important human confirmation outstanding, since it is the milestone's
   own headline criterion and has only ever been observed in a test harness, never on screen.
5. **Clicking a villager** — confirm the hit proxy described in `presentation-003` actually resolves a
   click in the live scene (the ray-query regression guard is headless-proven; a live click has not been
   tried).

## 5. Verdict

**PASS for hand-off to manual QA.** Suite is green (1383/1383, 0 orphans, exit 0), no S1/S2 bugs open, and
the critical logic paths for this sprint's headline criterion are proven headless. **Gate condition**:
before any external playtest (milestone R8), item 4 above (a villager visibly moving in and sleeping) should
be observed by a human at least once — the milestone criterion this sprint closes has never been seen
outside a test assertion.
