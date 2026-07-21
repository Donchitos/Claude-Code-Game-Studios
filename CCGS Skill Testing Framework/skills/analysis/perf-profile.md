# Skill Test Spec: $perf-profile

## Skill Summary

`$perf-profile` is a structured performance profiling workflow that identifies
bottlenecks and recommends optimizations. If profiler data or performance logs
are provided, it analyzes them directly. If not, it guides the user through a
manual profiling checklist. No director gates are invoked. The skill asks
"May I write to `production/qa/perf-[date].md`?" before persisting a report.
Verdicts: WITHIN BUDGET, CONCERNS, or OVER BUDGET.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: WITHIN BUDGET, CONCERNS, OVER BUDGET
- [ ] Contains "May I write" language (skill writes perf report)
- [ ] Has a next-step handoff (what to do after performance findings are reviewed)

---

## Director Gate Checks

None. Performance profiling is an advisory analysis skill; no gates are invoked.

---

## Test Cases

### Case 1: Happy Path — Frame data provided, draw call spike found

**Fixture:**
- User provides `production/qa/profiler-export-2026-03-15.json` with frame time data
- Data shows: average frame time 14ms (within 16.6ms budget), but frames 42–48 spike to 28ms
- Spike correlates with a scene with 450 draw calls (budget: 200)

**Input:** `$perf-profile production/qa/profiler-export-2026-03-15.json`

**Expected behavior:**
1. Skill reads profiler data
2. Skill identifies average frame time is within budget
3. Skill identifies draw call spike on frames 42–48 (450 calls vs 200 budget)
4. Verdict is CONCERNS (average OK, but spikes indicate an issue)
5. Skill recommends batching or culling for the identified scene
6. Skill asks "May I write to `production/qa/perf-2026-04-06.md`?"

**Assertions:**
- [ ] Spike frames are identified by frame number
- [ ] Draw call count and budget are compared explicitly
- [ ] Verdict is CONCERNS when spikes exceed budget even if average is OK
- [ ] At least one specific optimization recommendation is given
- [ ] "May I write" prompt appears before writing report

---

### Case 2: No Profiler Data — Manual checklist output

**Fixture:**
- User runs `$perf-profile` with no arguments
- No profiler data files exist in `production/qa/`

**Input:** `$perf-profile`

**Expected behavior:**
1. Skill finds no profiler data
2. Skill outputs a manual profiling checklist for the user to work through:
   - Enable Godot profiler or target engine's profiler
   - Record a 60-second play session
   - Export frame time data
   - Note any dropped frames or hitches
3. Skill asks user to provide data once collected before running analysis

**Assertions:**
- [ ] Skill does not crash or emit a verdict when no data is provided
- [ ] Manual profiling checklist is output (actionable steps, not just an error)
- [ ] No verdict is emitted (there is nothing to assess yet)
- [ ] No files are written

---

### Case 3: Over Budget — Frame budget exceeded for target platform

**Fixture:**
- Profiler data shows consistent 22ms frame times (target: 16.6ms for 60fps)
- All frames exceed budget; no single spike — systemic issue
- `technical-preferences.md` specifies target platform: PC, 60fps

**Input:** `$perf-profile production/qa/profiler-export-2026-03-20.json`

**Expected behavior:**
1. Skill reads profiler data and technical preferences for performance budget
2. All frames are over the 16.6ms budget
3. Verdict is OVER BUDGET
4. Skill outputs a prioritized optimization list (e.g., LOD system, shader complexity, physics tick rate)
5. Skill asks "May I write" before writing report

**Assertions:**
- [ ] Verdict is OVER BUDGET when all or most frames exceed budget
- [ ] Target frame budget is read from `technical-preferences.md` (not hardcoded)
- [ ] Optimization priority list is provided, not just the raw verdict
- [ ] "May I write" prompt appears before report write

---

### Case 4: Previous Perf Report Exists — Delta comparison

**Fixture:**
- `production/qa/perf-2026-03-28.md` exists with prior results (avg 15ms, max 19ms)
- New profiler export shows: avg 13ms, max 17ms
- Both reports are for the same scene

**Input:** `$perf-profile production/qa/profiler-export-2026-04-05.json`

**Expected behavior:**
1. Skill reads new profiler data
2. Skill detects prior report for the same scene
3. Skill computes deltas: avg improved 2ms, max improved 2ms
4. Skill presents regression check: no regressions detected
5. Verdict is WITHIN BUDGET; report notes improvement since last profile

**Assertions:**
- [ ] Skill checks `production/qa/` for prior perf reports before writing
- [ ] Delta comparison is shown (prior vs. current for key metrics)
- [ ] Verdict is WITHIN BUDGET when current metrics are within budget
- [ ] Improvement trend is noted positively in the report

---

### Case 5: Gate Compliance — No gate; performance-analyst separate

**Fixture:**
- Profiler data shows CONCERNS-level findings (some spikes)
- `review-mode.txt` contains `full`

**Input:** `$perf-profile production/qa/profiler-export-2026-04-01.json`

**Expected behavior:**
1. Skill analyzes profiler data; verdict is CONCERNS
2. No director gate is invoked regardless of review mode
3. Output notes: "For in-depth analysis, consider running `$perf-profile` with the performance-analyst agent"
4. Skill asks "May I write" and writes report on user approval

**Assertions:**
- [ ] No director gate is invoked in any review mode
- [ ] Performance-analyst consultation is suggested (not mandated)
- [ ] "May I write" prompt appears before report write
- [ ] Verdict is CONCERNS for spike-based findings

---

## Protocol Compliance

- [ ] Reads profiler data when provided; outputs checklist when not
- [ ] Reads `technical-preferences.md` for target platform frame budget
- [ ] Checks for prior perf reports to enable delta comparison
- [ ] Always asks "May I write" before writing report
- [ ] No director gates are invoked
- [ ] Verdict is one of: WITHIN BUDGET, CONCERNS, OVER BUDGET

---

## Coverage Notes

- Platform-specific profiling workflows (console, mobile) are not tested here;
  the checklist output in Case 2 would be platform-specific in practice.
- The delta comparison in Case 4 assumes reports cover the same scene; cross-scene
  comparisons are not explicitly handled.
