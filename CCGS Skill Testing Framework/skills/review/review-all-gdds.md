# Skill Test Spec: $review-all-gdds

## Skill Summary

`$review-all-gdds` is an Opus-tier skill that performs a holistic cross-GDD review
across all files in `design/gdd/`. It runs two complementary review phases in
parallel: Phase 1 checks for consistency (contradictions, formula mismatches,
stale references, competing ownership), and Phase 2 checks design theory (dominant
strategies, pillar drift, cognitive overload, economic imbalance). Because the two
phases are independent, they are spawned simultaneously to save time. The skill
produces a CONSISTENT / MINOR ISSUES / MAJOR ISSUES verdict and is read-only — no
files are written without explicit user approval.

The skill is itself the holistic review gate in the pipeline. It is invoked after
individual GDDs are complete and before architecture work begins. It does NOT spawn
any director gate agents (it IS the director-level review).

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥5 phase headings (complex multi-phase skill)
- [ ] Contains verdict keywords: CONSISTENT, MINOR ISSUES, MAJOR ISSUES
- [ ] Does NOT require "May I write" language (read-only skill)
- [ ] Has a next-step handoff at the end
- [ ] Documents parallel phase spawning (Phase 1 and Phase 2 are independent)

---

## Director Gate Checks

No director gates — this skill spawns no director gate agents. It IS the holistic
review; delegating to a director gate would create a circular dependency.

---

## Test Cases

### Case 1: Happy Path — Clean GDD set with no conflicts

**Fixture:**
- `design/gdd/` contains ≥3 system GDDs
- All GDDs are internally consistent: no formula contradictions, no competing ownership, no stale references
- All GDDs align with the pillars defined in `design/gdd/game-pillars.md`

**Input:** `$review-all-gdds`

**Expected behavior:**
1. Skill reads all GDD files in `design/gdd/`
2. Phase 1 (consistency scan) and Phase 2 (design theory check) spawn in parallel
3. Phase 1 finds no contradictions, no formula mismatches, no ownership conflicts
4. Phase 2 finds no pillar drift, no dominant strategies, no cognitive overload
5. Skill outputs a structured findings table with 0 blocking issues
6. Verdict: CONSISTENT

**Assertions:**
- [ ] Both review phases are spawned in parallel (not sequentially)
- [ ] Output includes a findings table (even if empty — shows "No issues found")
- [ ] Verdict is CONSISTENT when no conflicts are found
- [ ] Skill does NOT write any files without user approval
- [ ] Next-step handoff to `$architecture-review` or `$create-architecture` is present

---

### Case 2: Failure Path — Conflicting rules between two GDDs

**Fixture:**
- GDD-A defines a floor value (e.g. "minimum [output] is [N]")
- GDD-B states a mechanic that bypasses that floor (e.g. "[mechanic] can reduce [output] to 0")
- The two GDDs are otherwise complete and valid

**Input:** `$review-all-gdds`

**Expected behavior:**
1. Phase 1 (consistency scan) detects the contradiction between GDD-A and GDD-B
2. Conflict is reported with: both filenames, the specific conflicting rules, and severity HIGH
3. Verdict: MAJOR ISSUES
4. Handoff instructs user to resolve the conflict and re-run before proceeding

**Assertions:**
- [ ] Verdict is MAJOR ISSUES (not CONSISTENT or MINOR ISSUES)
- [ ] Both GDD filenames are named in the conflict entry
- [ ] The specific contradicting rules are quoted or described (not vague "conflict found")
- [ ] Issue is classified as severity HIGH (blocking)
- [ ] Skill does NOT auto-resolve the conflict

---

### Case 3: Partial Path — Single GDD with orphaned dependency reference

**Fixture:**
- GDD-A lists a dependency in its Dependencies section pointing to "system-B"
- No GDD for system-B exists in `design/gdd/`
- All other GDDs are consistent

**Input:** `$review-all-gdds`

**Expected behavior:**
1. Phase 1 detects the orphaned dependency reference in GDD-A
2. Issue is reported as: DEPENDENCY GAP — GDD-A references system-B which has no GDD
3. No other conflicts found
4. Verdict: MINOR ISSUES (dependency gap is advisory, not blocking by itself)

**Assertions:**
- [ ] Verdict is MINOR ISSUES (not MAJOR ISSUES for a single orphaned reference)
- [ ] The specific GDD filename and the missing dependency name are reported
- [ ] Skill suggests running `$design-system system-B` to resolve the gap
- [ ] Skill does NOT skip or silently ignore the missing dependency

---

### Case 4: Edge Case — No GDD files found

**Fixture:**
- `design/gdd/` directory is empty or does not exist
- No GDD files are present

**Input:** `$review-all-gdds`

**Expected behavior:**
1. Skill attempts to read files in `design/gdd/`
2. No files found — skill outputs an error with guidance
3. Skill recommends running `$brainstorm` and `$design-system` before re-running
4. Skill does NOT produce a verdict (CONSISTENT / MINOR ISSUES / MAJOR ISSUES)

**Assertions:**
- [ ] Skill outputs a clear error message when no GDDs are found
- [ ] No verdict is produced when the directory is empty
- [ ] Skill recommends the correct next action (`$brainstorm` or `$design-system`)
- [ ] Skill does NOT crash or produce a partial report

---

### Case 5: Director Gate — No gate spawned regardless of review mode

**Fixture:**
- `design/gdd/` contains ≥2 consistent system GDDs
- `production/session-state/review-mode.txt` exists with content `full`

**Input:** `$review-all-gdds`

**Expected behavior:**
1. Skill reads all GDDs and runs the two review phases
2. Skill does NOT read `review-mode.txt`
3. Skill does NOT spawn any director gate agent (CD-, TD-, PR-, AD- prefixed)
4. Skill completes and outputs its verdict normally
5. Review mode setting has no effect on this skill's behavior

**Assertions:**
- [ ] No director gate agents are spawned at any point
- [ ] Skill does NOT read `production/session-state/review-mode.txt`
- [ ] Output does not contain any "Gate: [GATE-ID]" or "skipped" gate entries
- [ ] The skill produces a verdict regardless of review mode
- [ ] R4 metric: gate count for this skill = 0 in all modes

---

## Protocol Compliance

- [ ] Phase 1 (consistency) and Phase 2 (design theory) spawned in parallel — not sequentially
- [ ] Does NOT write any files without "May I write" approval
- [ ] Findings table shown before any write ask
- [ ] Verdict is one of exactly: CONSISTENT, MINOR ISSUES, MAJOR ISSUES
- [ ] Ends with appropriate handoff: MAJOR ISSUES → fix and re-run; MINOR ISSUES → may proceed with awareness; CONSISTENT → `$create-architecture`

---

## Coverage Notes

- Economic balance analysis (source/sink loops) requires cross-GDD resource data — covered
  structurally by Case 2 (the conflict detection pattern is the same).
- The design theory phase (Phase 2) checks including dominant strategy detection and
  cognitive overload are not individually fixture-tested — they follow the same
  pattern as consistency checks and are validated via the pillar drift case structure.
- The `since-last-review` scoping mode is not tested here — it is a runtime concern.
