# Skill Test Spec: /soak-test

## Skill Summary

`/soak-test [duration] [focus]` generates an observation protocol for an
extended play session — the human plays, the skill writes the plan. Duration is
`30m`, `1h`, `2h` or `4h` (default `1h`); focus is `memory`, `stability`,
`balance` or `all` (default `all`). It reads `engine.name` and `performance.*`
from `project.yaml` (falling back to `technical-preferences.md`), the game
concept or brief, the latest playtest and QA plan, then builds timed
checkpoints for the duration and engine-specific memory guidance whose alert
thresholds are relative to the session's own T+0 baseline, in units recorded as
displayed. The engine tool and counter names it gives are not covered by
`docs/engine-reference/`, so they are marked NOT SOURCEABLE — pointers the
tester confirms at T+0, recording the tool actually used.

The protocol document carries a Verdict section with PASS / PASS WITH CONCERNS /
NOT ASSESSED / FAIL for the tester to fill in after the session; a short soak
cannot return PASS. The skill asks "May I write this soak test protocol to
`production/qa/soak-test-[date]-[duration].md`?" before writing, and never runs
the soak itself. No director gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: PASS, PASS WITH CONCERNS, NOT ASSESSED, FAIL
- [ ] Contains "May I write" collaborative protocol language before writing the protocol
- [ ] Has a next-step handoff (`/bug-triage sprint` after the session; `/smoke-check` after fixing a FAIL)

---

## Director Gate Checks

None. `/soak-test` is a QA planning utility. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — 2-hour, all-focus soak on Godot

**Fixture:**
- `project.yaml` has `engine.name: Godot` and `performance.target_framerate: 60`
- `design/gdd/game-concept.md` states the intended session length
- The user approves the write

**Input:** `/soak-test 2h all`

**Expected behavior:**
1. Skill loads context: engine, performance budgets, concept, latest playtest and QA plan
2. Checkpoints for `2h`: T+0, T+20, T+40, T+60, T+80, T+100, T+120
3. Godot memory items: the Debugger's memory monitors, Static Memory (unit as
   displayed), Object Count, Orphan Nodes — names marked NOT SOURCEABLE, since
   `docs/engine-reference/godot/` does not cover them, for the tester to confirm
   at T+0; alert when memory grows > 20% from T+0 after the first 15 minutes;
   Orphan Nodes must return to its T+0 value after a scene unload
4. Stability items (60 fps target) and balance/fatigue items are both included
5. Protocol document has Pre-Session Setup, Baseline (T+0), a Checkpoint Log per
   checkpoint, Post-Session Analysis, and a Verdict section left for the tester
6. Skill asks "May I write this soak test protocol to
   `production/qa/soak-test-[date]-2h.md`?"
7. After writing, prints the run steps ending with `/bug-triage sprint`

**Assertions:**
- [ ] Checkpoints are exactly T+0, T+20, T+40, T+60, T+80, T+100, T+120
- [ ] Memory thresholds are relative to T+0, and the unit is recorded as displayed (no unit assumed)
- [ ] The Godot tool and counter names are marked NOT SOURCEABLE, not presented as verified, and Pre-Session Setup asks for the tool actually used
- [ ] Memory, stability and balance observation items are all present (focus `all`)
- [ ] "May I write" is asked with `production/qa/soak-test-[date]-2h.md`
- [ ] The skill issues no verdict itself — the protocol's Verdict section is left for the tester

---

### Case 2: No Arguments — Defaults applied

**Fixture:**
- No arguments provided; engine configured

**Input:** `/soak-test`

**Expected behavior:**
1. Duration defaults to `1h`, focus to `all` — no questions are needed to start
2. Checkpoints: T+0, T+15, T+30, T+45, T+60
3. Protocol header records `Duration: 1h` and `Focus: all`
4. Skill asks "May I write this soak test protocol to `production/qa/soak-test-[date]-1h.md`?"

**Assertions:**
- [ ] Duration `1h` and focus `all` are used when no argument is given
- [ ] Checkpoints are exactly T+0, T+15, T+30, T+45, T+60
- [ ] The output path ends `-1h.md`
- [ ] Nothing is written before the "May I write" approval

---

### Case 3: Narrow Focus on Unreal — 4-hour memory soak

**Fixture:**
- `project.yaml` has `engine.name: Unreal`

**Input:** `/soak-test 4h memory`

**Expected behavior:**
1. Checkpoints for `4h`: T+0, T+30, T+60, T+90, T+120, T+180, T+240
2. Unreal memory items: a memory readout at each checkpoint — `stat memory`,
   marked NOT SOURCEABLE since `docs/engine-reference/unreal/` does not cover
   it; record Physical Memory Used and Available (units as displayed)
3. Alert threshold: Physical Memory Used growth > 20% over the full soak,
   against this run's T+0 — no absolute MB threshold
4. Balance/fatigue observation items are not generated (focus is `memory`)
5. Output path `production/qa/soak-test-[date]-4h.md`

**Assertions:**
- [ ] Checkpoints are exactly T+0, T+30, T+60, T+90, T+120, T+180, T+240
- [ ] The Unreal threshold is a relative > 20% growth, not an absolute size
- [ ] `stat memory` is marked NOT SOURCEABLE, a pointer to confirm rather than a verified command
- [ ] Balance/fatigue items are omitted for focus `memory`
- [ ] "May I write" names the `-4h.md` path

---

### Case 4: No Performance Budgets — "not set", never invented

**Fixture:**
- `project.yaml` has `engine.name: Unity` and no `performance` block
- `technical-preferences.md` Performance Budgets are `[TO BE CONFIGURED]`

**Input:** `/soak-test 30m memory`

**Expected behavior:**
1. Skill falls back from `project.yaml` to `technical-preferences.md` for budgets
2. Budget notes read `Memory ceiling: not set`, `Target FPS: not set`,
   `Frame budget: not set` — no number is supplied in their place
3. Checkpoints: T+0, T+10, T+20, T+30
4. Unity memory items: a memory profiler, marked NOT SOURCEABLE (not covered by
   `docs/engine-reference/unity/`); record Total Reserved Memory, GC Allocated,
   Object Count (units as displayed); alert when GC Allocated grows
   monotonically across 3+ checkpoints
5. Skill asks "May I write" before writing `production/qa/soak-test-[date]-30m.md`

**Assertions:**
- [ ] Missing budgets are recorded as "not set", not filled with defaults
- [ ] Checkpoints are exactly T+0, T+10, T+20, T+30
- [ ] The Unity threshold is the unit-free monotonic-growth check
- [ ] "May I write" is asked before the file is written

---

### Case 5: Director Gate Check — No gate; soak-test is a planning utility

**Fixture:**
- Engine configured; valid duration and focus provided

**Input:** `/soak-test 1h stability`

**Expected behavior:**
1. Skill generates and writes the soak test protocol
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] The run ends at "Protocol written." with the run steps — no gate verdict, and no soak verdict issued by the skill

---

## Protocol Compliance

- [ ] Parses `[duration] [focus]`, defaulting to `1h` and `all`
- [ ] Uses the Phase 3 checkpoint table for the chosen duration
- [ ] Memory alert thresholds are ratios or deltas against T+0; units are recorded as displayed
- [ ] Engine tool names not covered by `docs/engine-reference/` are marked NOT SOURCEABLE; a memory tool the tester cannot find leaves the verdict NOT ASSESSED
- [ ] The protocol's Verdict section offers PASS / PASS WITH CONCERNS / NOT ASSESSED / FAIL and states a short soak cannot return PASS
- [ ] Asks "May I write" before creating `production/qa/soak-test-[date]-[duration].md`
- [ ] Never attempts to run the soak itself

---

## Coverage Notes

- The `stability` and `balance` focus values follow Case 3's pattern with the
  other observation groups; not separately tested.
- At `rigor: minimal` the skill reads `design/game-brief.md` instead of the
  game concept; not separately tested.
- Executing the protocol is outside this skill's scope — it generates the plan,
  a human runs it.
