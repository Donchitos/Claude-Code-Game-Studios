# Skill Test Spec: $map-systems

## Skill Summary

`$map-systems` decomposes a game concept into a systems index. It reads the
approved game concept and pillars, enumerates both explicit and implicit systems,
maps dependencies between systems, assigns priority tiers (MVP / Vertical Slice /
Alpha / Full Vision), and organizes systems into a layered design order
(Foundation → Core → Feature → Presentation). The output is written to
`design/systems-index.md` after user approval.

This skill is required between game concept approval and per-system GDD creation
— it is a mandatory gate in the pipeline. In `full` review mode, CD-SYSTEMS
(creative-director) and TD-SYSTEM-BOUNDARY (technical-director) spawn in parallel
after the decomposition is drafted. In `lean` or `solo` mode, both gates are
skipped. The skill writes to `design/systems-index.md`.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" collaborative protocol language (for systems-index.md)
- [ ] Has a next-step handoff at the end (`$design-system`)
- [ ] Documents gate behavior: CD-SYSTEMS + TD-SYSTEM-BOUNDARY in parallel in full mode

---

## Director Gate Checks

In `full` mode: CD-SYSTEMS (creative-director) and TD-SYSTEM-BOUNDARY
(technical-director) spawn in parallel after the systems decomposition is drafted
and before `design/systems-index.md` is written.

In `lean` mode: both gates are skipped. Output notes:
"CD-SYSTEMS skipped — lean mode" and "TD-SYSTEM-BOUNDARY skipped — lean mode".

In `solo` mode: both gates are skipped with equivalent notes.

---

## Test Cases

### Case 1: Happy Path — Game concept exists, 5-8 systems identified

**Fixture:**
- `design/gdd/game-concept.md` exists with Core Mechanics and MVP Definition sections
- `design/gdd/game-pillars.md` exists with ≥1 pillar defined
- No `design/systems-index.md` exists yet
- `production/session-state/review-mode.txt` contains `full`

**Input:** `$map-systems`

**Expected behavior:**
1. Skill reads game-concept.md and game-pillars.md
2. Identifies 5-8 systems (explicit + implicit)
3. Maps dependencies between systems and assigns layers
4. CD-SYSTEMS and TD-SYSTEM-BOUNDARY spawn in parallel and return APPROVED
5. Asks "May I write `design/systems-index.md`?"
6. Writes systems-index.md after approval
7. Updates `production/session-state/active.md`

**Assertions:**
- [ ] Between 5 and 8 systems are identified (not fewer, not more without explanation)
- [ ] CD-SYSTEMS and TD-SYSTEM-BOUNDARY spawn in parallel (not sequentially)
- [ ] Both gates complete before the "May I write" ask
- [ ] "May I write `design/systems-index.md`?" is asked before writing
- [ ] systems-index.md is NOT written without approval
- [ ] Session state is updated after writing
- [ ] Verdict is COMPLETE

---

### Case 2: Failure Path — No game concept found

**Fixture:**
- `design/gdd/game-concept.md` does NOT exist
- `design/gdd/` directory may be empty or absent

**Input:** `$map-systems`

**Expected behavior:**
1. Skill attempts to read `design/gdd/game-concept.md`
2. File not found
3. Skill outputs: "No game concept found. Run `$brainstorm` to create one, then return to `$map-systems`."
4. Skill exits without creating systems-index.md

**Assertions:**
- [ ] Skill outputs a clear error naming the missing file path
- [ ] Skill recommends `$brainstorm` as the next action
- [ ] No systems-index.md is created
- [ ] Verdict is BLOCKED

---

### Case 3: Director Gate — CD-SYSTEMS returns CONCERNS (missing core system)

**Fixture:**
- Game concept exists
- `production/session-state/review-mode.txt` contains `full`
- CD-SYSTEMS gate returns CONCERNS: "The [core-system] is implied by the concept but not identified"

**Input:** `$map-systems`

**Expected behavior:**
1. Systems are drafted (5-8 initial systems identified)
2. CD-SYSTEMS gate returns CONCERNS naming the missing core system
3. TD-SYSTEM-BOUNDARY returns APPROVED
4. Skill surfaces CD-SYSTEMS concerns to user
5. User is asked: revise systems list to add the missing system, or proceed as-is
6. If revised: updated systems list shown before "May I write" ask

**Assertions:**
- [ ] CD-SYSTEMS concerns are shown to the user before writing
- [ ] Skill does NOT auto-write systems-index.md while CONCERNS are unresolved
- [ ] User is given the option to revise or proceed
- [ ] Revised systems list is re-shown after revision before final "May I write"

---

### Case 4: Edge Case — systems-index.md already exists

**Fixture:**
- `design/gdd/game-concept.md` exists
- `design/systems-index.md` already exists with N systems

**Input:** `$map-systems`

**Expected behavior:**
1. Skill reads the existing systems-index.md and presents its current state
2. Skill asks: "systems-index.md already exists with [N] systems. Update with new systems, or review and revise priorities?"
3. User chooses an action
4. Skill does NOT silently overwrite the existing index

**Assertions:**
- [ ] Skill detects and reads the existing systems-index.md before proceeding
- [ ] User is offered update/review options — not auto-overwritten
- [ ] Existing system count is presented to the user
- [ ] Skill does NOT proceed with a full re-decomposition without user choosing to do so

---

### Case 5: Director Gate — Lean mode and solo mode both skip gates, noted

**Fixture (lean mode):**
- Game concept exists
- `production/session-state/review-mode.txt` contains `lean`

**Lean mode expected behavior:**
1. Systems are decomposed and drafted
2. Both CD-SYSTEMS and TD-SYSTEM-BOUNDARY are skipped
3. Output notes: "CD-SYSTEMS skipped — lean mode" and "TD-SYSTEM-BOUNDARY skipped — lean mode"
4. "May I write" ask proceeds directly

**Assertions (lean mode):**
- [ ] Both gate skip notes appear in output
- [ ] Skill proceeds to "May I write" without gate approval
- [ ] systems-index.md is written after user approval

**Fixture (solo mode):**
- Same game concept, `production/session-state/review-mode.txt` contains `solo`

**Solo mode expected behavior:**
1. Same decomposition workflow
2. Both gates skipped — noted in output with "solo mode"
3. "May I write" ask proceeds

**Assertions (solo mode):**
- [ ] Both skip notes appear with "solo mode" label
- [ ] Behavior is otherwise identical to lean mode for this skill

---

## Protocol Compliance

- [ ] Reads game-concept.md and game-pillars.md before any decomposition
- [ ] "May I write `design/systems-index.md`?" asked before writing
- [ ] systems-index.md is NOT written without user approval
- [ ] CD-SYSTEMS and TD-SYSTEM-BOUNDARY spawn in parallel in full mode
- [ ] Skipped gates noted by name and mode in lean/solo output
- [ ] Ends with next-step handoff: `$design-system [next-system]`

---

## Coverage Notes

- Circular dependency detection (System A depends on System B which depends on A)
  is part of the dependency mapping phase — not independently fixture-tested here.
- Priority tier assignment (MVP heuristics) is evaluated as part of the Case 1
  collaborative workflow rather than independently.
- The `next` argument mode (handing off the highest-priority undesigned system to
  `$design-system`) is not tested here — it is a post-index-creation convenience.
