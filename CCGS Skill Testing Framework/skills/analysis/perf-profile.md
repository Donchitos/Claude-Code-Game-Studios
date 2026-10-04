# Skill Test Spec: /perf-profile

## Skill Summary

`/perf-profile` is a static-analysis performance profiler. It takes a system
name or `full` as its scope, records every input it needs as `FOUND` or
`ABSENT` before producing anything, resolves `performance.enforce` from the
config block injected at its top (Phase 0), and reads the committed budgets
with `get_effective_yaml_key` for `performance.target_framerate`,
`performance.frame_budget_ms`, `performance.draw_call_limit` and
`performance.memory_ceiling_mb` before falling back to design docs or
`CLAUDE.md` (Phase 2). It analyses source code for CPU, memory, rendering and
I/O hotspot candidates (Phase 3) — it does not ingest runtime profiler exports.
The report rates each budgeted row `OK` / `WARNING` / `OVER`; a metric with no
committed budget is `NOT ASSESSED`, and the summary gives headroom only against a
budget that is set (`no budget set — headroom not assessed` otherwise). The skill asks "May I write this profiling
report to `production/polish/[scope]-report-[date].md`?" before writing (Phase
4), offers implement / cut scope / defer / escalate choices for M- or L-effort
hotspots (Phase 5), and hands off to `/architecture-decision`, `/scope-check`
or `/sprint-plan update` (Phase 6). No director gates are invoked. Verdicts:
COMPLETE, or NOT ASSESSED — NO DATA when every required input is absent.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, NOT ASSESSED — NO DATA, and the per-metric statuses OK / WARNING / OVER
- [ ] Contains "May I write" language naming `production/polish/[scope]-report-[date].md`
- [ ] Has a next-step handoff (Phase 6: `/architecture-decision`, `/scope-check`, `/sprint-plan update`)

---

## Director Gate Checks

None. Performance profiling is an advisory analysis skill; no gates are invoked
in any review mode.

---

## Test Cases

### Case 1: Happy Path — Budgets committed, combat hotspots found

**Fixture:**
- `project.yaml`: `engine.name: godot`, `performance.target_framerate: 60`,
  `performance.frame_budget_ms: 16.6`, `performance.draw_call_limit: 200`,
  `performance.memory_ceiling_mb: 2048`; `performance.enforce` unset (resolves
  to `warn`); `modes.automation` unset (collaborative)
- No config key, design doc or `CLAUDE.md` section states a load-time target
- `src/gameplay/combat/enemy_manager.gd` has a `_process()` that loops over every
  enemy and, inside that loop, over every active projectile, and casts a ray per
  enemy every frame
- Reworking the nested loop into a spatial partition is a multi-day change

**Input:** `/perf-profile combat`

**Expected behavior:**
1. Skill records its inputs: source code FOUND, committed budgets FOUND
2. Phase 0: `performance.enforce` resolves to `warn` — violations are findings, not blockers
3. Phase 2: the four `performance.*` keys are read with `get_effective_yaml_key` before any fallback
4. Phase 3: the combat `_process()` functions are listed; the nested loop and the per-frame raycast are identified
5. Phase 4: the report's Performance Budgets table uses 16.6 ms, 2048 MB and 200 draw calls as budgets, each of those three rows with an OK / WARNING / OVER status; the Load time row has no committed budget and is `NOT ASSESSED`; hotspots and recommendations cite `enemy_manager.gd` with a line number
6. Summary gives the top 3 hotspots, estimated headroom against the three set budgets, `no budget set — headroom not assessed` for load time, and a recommended next action
7. Skill asks "May I write this profiling report to `production/polish/combat-report-[date].md`?"
8. The nested-loop hotspot is rated Fix Effort M or L, so Phase 5 offers: implement, reduce scope via `/scope-check`, defer to Polish, or escalate via `/architecture-decision`
9. Verdict: COMPLETE

**Assertions:**
- [ ] Budgets come from the four `performance.*` keys read with `get_effective_yaml_key`, not from design docs or a hardcoded 16.67 ms
- [ ] The nested loop and the per-frame raycast are reported as hotspots with a `file:line` location
- [ ] Each optimization recommendation states location, expected gain, risk and approach
- [ ] The frame time, memory and draw call rows carry an OK / WARNING / OVER status; the Load time row is `NOT ASSESSED`, not OK
- [ ] No headroom is claimed for load time; the summary says `no budget set — headroom not assessed`
- [ ] "May I write" names `production/polish/combat-report-[date].md` and precedes any write
- [ ] The M/L-effort hotspot triggers the Phase 5 choice (implement / `/scope-check` / defer to Polish / `/architecture-decision`)
- [ ] Verdict is COMPLETE

---

### Case 2: No Committed Budget — Budget rows are NOT ASSESSED

**Fixture:**
- `project.yaml` has `engine.name: godot` and no `performance` block
- No design doc and no `CLAUDE.md` section states a frame-rate, memory, load-time or draw-call target
- `src/` contains gameplay scripts with `_process()` functions

**Input:** `/perf-profile full`

**Expected behavior:**
1. `get_effective_yaml_key` returns nothing for the four budget keys; the design-doc and `CLAUDE.md` fallback finds no target either
2. Source code is FOUND, so Phase 3 analysis still runs and hotspots are reported
3. Every row of the Performance Budgets table is `NOT ASSESSED` — none is measured against the template's `[16.67ms]` placeholder
4. The summary does not claim headroom against a budget nobody set: it says `no budget set — headroom not assessed`
5. Skill asks "May I write this profiling report to `production/polish/full-report-[date].md`?"; the `NOT ASSESSED` rows stay in the file offered for writing

**Assertions:**
- [ ] No budget row shows OK, WARNING or OVER; each is `NOT ASSESSED`
- [ ] The `[16.67ms]` placeholder is never used as a budget, and no headroom figure is claimed
- [ ] Hotspot analysis still runs and is reported
- [ ] The `NOT ASSESSED` rows are kept in the report offered for writing, not edited out

---

### Case 3: Nothing to Profile — Whole verdict NOT ASSESSED — NO DATA

**Fixture:**
- Fresh project: `project.yaml` has `engine.name: godot` and no `performance` block, and the code root `src/` is absent
- No design docs exist
- No profiler output exists anywhere

**Input:** `/perf-profile full`

**Expected behavior:**
1. Skill lists its inputs and records each: source code ABSENT, budgets ABSENT, profiler output ABSENT
2. Every required input is ABSENT, so the skill stops before Phase 3
3. Skill reports `NOT ASSESSED — NO DATA` as the whole verdict, naming what was missing and which skill produces it
4. No report template is filled in and nothing is offered for writing

**Assertions:**
- [ ] Each input is recorded as FOUND or ABSENT, not assumed present
- [ ] The whole verdict is `NOT ASSESSED — NO DATA`, not COMPLETE
- [ ] Output names each missing input and which skill produces it
- [ ] No filled-in report, no headroom figure, and no "May I write" prompt

---

### Case 4: Local Enforcement Override `block` — Violations are blockers

**Fixture:**
- `project.yaml`: `engine.name: godot`, `performance.enforce: warn`, `performance.draw_call_limit: 200`, the other three budgets set
- `project.local.yaml`: `performance.enforce: block`, so the resolved block at the top of the skill shows `block`
- `src/levels/forest/forest_builder.gd` instantiates 600 individual foliage `MeshInstance3D` nodes, each with its own material and no instancing
- `modes.automation` unset (collaborative)

**Input:** `/perf-profile forest`

**Expected behavior:**
1. Phase 0 uses `block` from the resolved config block at the top of the skill, not the `warn` a fresh read of `project.yaml` would give
2. The draw-call estimate for the forest scope exceeds 200; the Draw calls row is OVER
3. The report states explicitly that the violation is a blocker — release-stopping — and that `/gate-check` will FAIL the Polish gate on it
4. A recommendation (e.g., batching or instancing the foliage) is given with its expected gain
5. Skill asks "May I write" before writing `production/polish/forest-report-[date].md`

**Assertions:**
- [ ] The local `block` applies, not the committed `warn` — `performance.enforce` comes from the resolved block
- [ ] The Draw calls row is OVER against the 200 budget
- [ ] The report states the violation is a blocker and that `/gate-check` will FAIL the Polish gate on it
- [ ] "May I write" precedes any write

---

### Case 5: Enforcement Level `off` in Full Review Mode — Informational only, no gates

**Fixture:**
- `project.yaml`: `engine.name: godot`, `modes.review_mode: full`, `performance.enforce: off`, all four budgets set
- `src/` contains a `_process()` whose estimated frame cost exceeds `performance.frame_budget_ms`

**Input:** `/perf-profile full`

**Expected behavior:**
1. No director gate is invoked, whatever the review mode
2. The estimated frame time is still reported in the Performance Budgets table
3. Because budgets are informational under `off`, the over-budget frame time is not raised as a violation finding or as a recommendation to fix
4. Skill asks "May I write" before writing the report
5. Output ends with the Phase 6 next steps: `/architecture-decision`, `/scope-check [feature]`, `/sprint-plan update`

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] The estimated frame time still appears in the budget table
- [ ] The over-budget metric is not raised as a violation finding or a fix recommendation
- [ ] "May I write" precedes any write
- [ ] Next steps name `/architecture-decision`, `/scope-check` and `/sprint-plan update`

---

## Protocol Compliance

- [ ] Records each input as FOUND or ABSENT before producing any report
- [ ] Reads the four `performance.*` budget keys with `get_effective_yaml_key` before falling back to design docs or `CLAUDE.md`
- [ ] A metric with no committed budget is `NOT ASSESSED` — never measured against the `[16.67ms]` placeholder — and the summary claims headroom only against a budget that is set
- [ ] Applies `performance.enforce` from the resolved block: `warn` → findings, `block` → blockers, `off` → informational
- [ ] Asks "May I write" naming `production/polish/[scope]-report-[date].md` before writing, and keeps `NOT ASSESSED` sections in the written file
- [ ] No director gates are invoked
- [ ] Ends with the Phase 6 next-step handoff

---

## Coverage Notes

- An unrecognized `performance.enforce` value (surfaced to the user, then
  treated as `warn`) is not tested here.
- The skill is static analysis only; confirming a hotspot with runtime
  profiling is listed under the report's "Requires Investigation" section and is
  not exercised by these cases.
- Deferring M/L hotspots under Phase 5 choice C records them under
  `### Deferred to Polish`; that recording is not asserted separately.
