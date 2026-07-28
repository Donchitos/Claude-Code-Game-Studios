# rid-009 — Bed Functional Flip Evidence

**Date**: 2026-07-27
**Story**: `production/epics/resource-item-database/story-009-mvp-data-content.md`
**Owner**: godot-gdscript-specialist
**Purpose**: demonstrate — not merely assert — that the three tests Sprint 10's sign-off pinned
as a documented, honest KNOWN GAP now resolve TRUE against the REAL, Autoload-tier
`ResourceItemDatabase` singleton, because `res://data/items/bed.tres` is now real, shipped MVP
content. Per the Sprint 11 QA plan's binding requirement (rid-009 dedicated section).

---

## What shipped (content, in order — F2 sequencing)

1. Three tier-0 building materials, one per material family (Visual Direction Note colours):
   - `neues-spiel/data/items/wood_block.tres` — `wood`, Timber Brown `#8B5E3C`
   - `neues-spiel/data/items/stone_block.tres` — `stone`, Hearth-stone Grey `#8A8D8F`
   - `neues-spiel/data/items/thatch_block.tres` — `thatch`, Thatch Umber `#A8642F`
2. `neues-spiel/data/items/bed.tres` — `furniture_fixture`, `footprint = Vector2i(1, 2)`, Hearth Gold
   `#F5A83C` accent (Function-tier fixture per the Visual Direction Note §4.1).
3. Four primitive placeholder `BoxMesh` + `StandardMaterial3D` assets under
   `neues-spiel/assets/models/items/` (`wood_block_mesh.tres`, `stone_block_mesh.tres`,
   `thatch_block_mesh.tres`, `bed_mesh.tres`) bound as each entry's `visual_asset`. **Named fallback
   exercised** (per the QA plan's own risk table): these are code/data-authored primitive
   placeholders, not `.vox`/Blender-pipeline art assets — recorded explicitly here, not shipped
   silently. `rid-006` (visual_asset validation, Should-tier) and the AC29 manual palette-legibility
   screenshot remain the venue for a real-art follow-up; neither is blocked by this choice since
   `rid-006`'s own only check is that `visual_asset` resolves non-null, which it does.

**Sequencing requirement (F2, restated as a commit instruction for whoever commits this
changeset)**: the three tier-0 materials must land in a commit that boots green *before* a
separate commit adds `bed.tres` — this satisfies "a lone `bed.tres` never appears in isolation in
the commit history without the three tier-0 materials already present and booting green." This
implementer did not commit (parent does); recorded here as an explicit instruction for the commit
step.

---

## The three-condition GREEN definition (Sprint 11 QA plan, rid-009 dedicated section)

1. **Tier-0 family coverage passes.** `_check_tier0_family_coverage()` (rid-005) requires ≥1
   `building_material` + `tier == 0` entry per `wood`/`stone`/`thatch`. All three ship. Proven by the
   full suite's green boot (below) — a coverage gap would BLOCK the whole database (`success =
   false`), which would make every downstream assertion in this doc fail, and none did.
2. **Boot reaches `ACTIVE`.** `tests/integration/foundation/boot_spine_integration_test.gd ::
   test_real_boot_zero_injected_modules_still_reaches_active` — an existing test, unmodified by this
   story — constructs a real `GameWorld`, resolves the REAL `/root/ResourceItemDatabase` Autoload
   (never a mock), and asserts `world.get_boot_state() == GameWorld.BootState.ACTIVE`. Re-run after
   this story's content landed: **PASSED**.
3. **`is_need_functional(&"bed")` is TRUE against the real Autoload.** Proven by the three flipped
   tests below, plus a direct scratch-run check (not committed — see "How the flip was demonstrated"
   below).

**All three conditions: GREEN.**

---

## The three pinned tests — exact quotes, before and after

### 1. `neues-spiel/tests/unit/build_validation/shelter_classification_test.gd` ::
`test_is_need_functional_unknown_id_returns_false_without_error`

**Pre-sprint (quoted, as pinned by Sprint 10)**:
```gdscript
func test_is_need_functional_unknown_id_returns_false_without_error() -> void:
	# Documented limitation: no `res://data/items/` fixture exists yet in this
	# repo (`building-028` has not landed), so ResourceItemDatabase's global
	# autoload resolves this id to null -- the fail-safe path this method's
	# own contract requires. This proves the safe default, not the "true"
	# branch (which needs real RID content story 008 will supply).
	var config := BuildValidationConfig.new()
	assert_bool(config.is_need_functional(&"bed")).is_false()
	assert_bool(config.is_need_functional(&"totally_unknown_item")).is_false()
```

**Post-sprint (quoted, as landed by this story)**:
```gdscript
func test_is_need_functional_unknown_id_returns_false_without_error() -> void:
	# FLIPPED (rid-009): res://data/items/bed.tres now ships as real MVP
	# content, so ResourceItemDatabase's global Autoload resolves &"bed" via
	# the REAL production data set -- is_need_functional(&"bed") is TRUE
	# against real content, never a test-local mock (this is the exact
	# BLOCKING DoD line Sprint 10's sign-off named as unmet, §4.1/§4.4
	# condition #2 -- closed here). The false branch for a genuinely unknown
	# id is retained as its own real, useful assertion -- the fail-safe
	# default this method's own contract requires for an id nothing has ever
	# authored.
	var config := BuildValidationConfig.new()
	assert_bool(config.is_need_functional(&"totally_unknown_item")).is_false()
	assert_bool(config.is_need_functional(&"bed")).is_true()
```
Function name unchanged (still names the retained false-branch scenario); body flipped from
`is_false()` to `is_true()` for `&"bed"`. **Result: PASSED.**

### 2. `neues-spiel/tests/unit/build_validation/warning_info_tiers_test.gd` — sealed-region half
Renamed `test_documented_limitation_bed_in_sealed_region_emits_zero_warning_pending_rid_content` →
`test_bed_in_sealed_region_emits_sealed_space_warning_rid_content_flipped`.

**Pre-sprint (quoted)**: asserted `bv.config.is_need_functional(&"bed") == false` (pinning the gap
itself) and `warnings.size() == 0` after `registry.place("bed_1", &"bed", [cell_a])` in a sealed
region.

**Post-sprint (quoted, one connected scenario, both branches)**:
```gdscript
	assert_bool(bv.config.is_need_functional(&"bed")).is_true()  # the flip itself.
	assert_bool(bv.config.is_need_functional(&"decorative_rug")).is_false()  # retained false branch.
	...
	registry.place("rug_1", &"decorative_rug", [cell_b])  # sealed but NOT need-functional -- joins no group.
	registry.place("bed_1", &"bed", [cell_a])  # sealed AND need-functional -- joins the warning group.

	assert_bool(bv.get_shelter_status("bed_1")).is_false()  # correctly unsheltered.
	assert_int(warnings.size()).is_equal(1)  # FLIPPED -- was 0 pre-rid-009.
	var warning: Dictionary = warnings[0]
	assert_bool((warning["item_ids"] as Array).has("bed_1")).is_true()
	assert_bool((warning["item_ids"] as Array).has("rug_1")).is_false()  # false branch held.
```
**Result: PASSED.** A real `sealed_space_warning` signal now fires end-to-end for the real `bed` id,
through the real `BuildValidation` module, driven by the real `ResourceItemDatabase` Autoload's
`is_need_functional` resolution — while the decorative, non-functional item in the SAME sealed
region correctly contributes zero, proving the false branch was not lost, only no longer pinned
in isolation.

### 3. `neues-spiel/tests/unit/build_validation/warning_info_tiers_test.gd` — open/unsheltered half
Renamed `test_documented_limitation_bed_unsheltered_open_emits_zero_info_pending_rid_content` →
`test_bed_unsheltered_open_emits_unsheltered_furniture_info_rid_content_flipped`.

**Pre-sprint (quoted)**: asserted `infos.size() == 0` after `registry.place("bed_2", &"bed",
[open_cell])` in the open (no candidate region).

**Post-sprint (quoted, one connected scenario, both branches)**:
```gdscript
	assert_bool(bv.config.is_need_functional(&"bed")).is_true()  # the flip itself.
	assert_bool(bv.config.is_need_functional(&"decorative_rug")).is_false()  # retained false branch.
	...
	registry.place("rug_2", &"decorative_rug", [decorative_cell])  # open but NOT need-functional -- no Info.
	registry.place("bed_2", &"bed", [open_cell])  # open AND need-functional -- Info fires.

	assert_bool(bv.get_shelter_status("bed_2")).is_false()
	assert_int(infos.size()).is_equal(1)  # FLIPPED -- was 0 pre-rid-009.
	assert_str(String(infos[0]["item_id"])).is_equal("bed_2")  # false branch (rug_2) never appears.
```
**Result: PASSED.** A real `unsheltered_furniture_info` signal now fires end-to-end for the real
`bed` id; the decorative item in the same scenario contributes zero.

---

## How the flip was demonstrated (not merely asserted) against REAL production data

1. **Class-cache rebuild** run first: `Godot_v4.7-stable_win64.exe --headless --editor --path .
   --quit` — clean, zero errors, recognized the four new `.tres` entries.
2. **Full regression suite**, `tests/run-tests.cmd` (both `res://tests/unit` and
   `res://tests/integration`), run in the foreground twice for reproducibility:
   - Run 1: **1418 test cases · 0 errors · 0 failures · 0 flaky · 0 skipped · 0 orphans · exit 0**
     (121/121 suites).
   - Run 2 (after removing the throwaway smoke-verification file, see below): **identical —
     1418 · 0 · 0 · 0 · 0 · 0 orphans · exit 0**.
   - Baseline was 1383 (Sprint 10 actuals). This story's edits (2 renamed/rewritten test functions
     replacing 2 old ones, plus new assertions inside the retained
     `test_is_need_functional_unknown_id_returns_false_without_error`) do not add new test FILES —
     net new test-case count this story: **0 net new** (2 renamed, same total function count in
     `warning_info_tiers_test.gd`); the +35 delta versus 1383 comes from other Sprint 11 stories
     landed earlier in this same tree (rid-007, rid-008), not from this story.
3. **Targeted re-run** of exactly the affected suites (`shelter_classification_test.gd`,
   `warning_info_tiers_test.gd`, `boot_spine_integration_test.gd`,
   `resource_item_database/boot_gate_test.gd`) to capture the flip in isolation: **50/50 test cases
   passed, 0 orphans, exit 0** — including
   `test_is_need_functional_unknown_id_returns_false_without_error`,
   `test_bed_in_sealed_region_emits_sealed_space_warning_rid_content_flipped`,
   `test_bed_unsheltered_open_emits_unsheltered_furniture_info_rid_content_flipped`,
   `test_real_boot_zero_injected_modules_still_reaches_active`, and
   `test_resource_item_database_autoload_registered_and_ready_before_test_execution` — all PASSED.
4. **Direct content-query proof against the REAL Autoload** (Smoke-1..4, per this story's own QA
   Test Cases): a throwaway GdUnit suite
   (`neues-spiel/tests/_scratch_rid009_content_smoke_test.gd`) queried `ResourceItemDatabase`
   directly (the real singleton, zero mocks, zero injected doubles) for:
   - `list_ids_by_tier(0)` ∩ `list_ids_by_category(&"building_material")` == exactly
     `["wood_block", "stone_block", "thatch_block"]` — **PASSED**.
   - `list_ids_by_category(&"furniture_fixture")` == exactly `["bed"]`, `list_all_ids()` == exactly
     the 4 authored ids, `"missing_item"` absent — **PASSED**.
   - `get_by_id(&"bed").get_footprint() == Vector2i(1, 2)` — **PASSED**.
   - All 4 entries: id/display_name/category/storage_category non-empty, `visual_asset` non-null,
     `tier == 0`, `max_stack_size >= 1` — **PASSED**.
   This file was run once (4/4 passed, 0 orphans, exit 0), its output transcribed into
   `production/qa/smoke-rid-009-2026-07-27.md`, then **deleted** — per this project's own established
   rule (Sprint 11 QA plan DoD: "rid-009's content smoke reads shipped `.tres` files by design —
   keep that in the smoke artifact, not the unit suite"). It does not exist in the final tree.
5. **No `MockResourceItemDatabase` or test-local RID double appears anywhere in this evidence** — the
   flipped assertions above all resolve through the actually-registered `/root/ResourceItemDatabase`
   Autoload, populated by the actually-shipped `res://data/items/*.tres` files, exactly as this
   plan's binding requirement demands.

---

## Suite counts

| Point | Test cases | Errors | Failures | Orphans | Exit |
|---|---|---|---|---|---|
| Sprint 10 baseline (pre-this-story) | 1383 | 0 | 0 | 0 | 0 |
| Full suite, post rid-009 (run 1) | 1418 | 0 | 0 | 0 | 0 |
| Full suite, post rid-009 (run 2, reproduced) | 1418 | 0 | 0 | 0 | 0 |
| Targeted flip re-run (4 suites) | 50 | 0 | 0 | 0 | 0 |
| Throwaway content-smoke run (deleted after) | 4 | 0 | 0 | 0 | 0 |

**Note (transparency, not a gate failure)**: the Godot process itself printed, identically across
both full-suite runs, `WARNING: 34 ObjectDB instances were leaked at exit` and `ERROR: 3 resources
still in use at exit` — an engine-shutdown-time diagnostic distinct from GdUnit4's own tracked
per-test orphan count (which reported 0 in both runs). Deterministic and identical across two
independent runs (not growing), consistent with long-lived Autoload singletons/cached Resources
still referenced at final process teardown rather than a per-test leak. Recorded here for
transparency; does not affect the "0 orphans + exit 0" gate, which is GdUnit4's own explicitly
reported metric.

---

## Verdict

**All three pinned tests flipped. All three conjunctive GREEN conditions hold. The flip is
demonstrated against real, shipped, Autoload-resolved production data — never a mock.**
