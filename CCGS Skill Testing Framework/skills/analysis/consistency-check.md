# Skill Test Spec: $consistency-check

## Skill Summary

`$consistency-check` scans all GDDs in `design/gdd/` and checks for internal
conflicts across documents. It produces a structured findings table with columns:
System A vs System B, Conflict Type, Severity (HIGH / MEDIUM / LOW). Conflict
types include: formula mismatch, competing ownership, stale reference, and
dependency gap.

The skill is read-only during analysis. It has no director gates. An optional
consistency report can be written to `design/consistency-report-[date].md` if the
user requests it, but the skill asks "May I write" before doing so.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: CONSISTENT, CONFLICTS FOUND, DEPENDENCY GAP
- [ ] Does NOT require "May I write" language during analysis (read-only scan)
- [ ] Has a next-step handoff at the end
- [ ] Documents that report writing is optional and requires approval

---

## Director Gate Checks

No director gates — this skill spawns no director gate agents. Consistency
checking is a mechanical scan; no creative or technical director review is
required as part of the scan itself.

---

## Test Cases

### Case 1: Happy Path — 4 GDDs with no conflicts

**Fixture:**
- `design/gdd/` contains exactly 4 system GDDs
- All GDDs have consistent formulas (no overlapping variables with different values)
- No two GDDs claim ownership of the same game entity or mechanic
- All dependency references point to GDDs that exist

**Input:** `$consistency-check`

**Expected behavior:**
1. Skill reads all 4 GDDs in `design/gdd/`
2. Runs cross-GDD consistency checks (formulas, ownership, references)
3. No conflicts found
4. Outputs structured findings table showing 0 issues
5. Verdict: CONSISTENT

**Assertions:**
- [ ] All 4 GDDs are read before producing output
- [ ] Findings table is present (even if empty — shows "No conflicts found")
- [ ] Verdict is CONSISTENT when no conflicts exist
- [ ] Skill does NOT write any files without user approval
- [ ] Next-step handoff is present

---

### Case 2: Failure Path — Two GDDs with conflicting damage formulas

**Fixture:**
- GDD-A defines damage formula: `damage = attack * 1.5`
- GDD-B defines damage formula: `damage = attack * 2.0` for the same entity type
- Both GDDs refer to the same "attack" variable

**Input:** `$consistency-check`

**Expected behavior:**
1. Skill reads all GDDs and detects the formula mismatch
2. Findings table includes an entry: GDD-A vs GDD-B | Formula Mismatch | HIGH
3. Specific conflicting formulas are shown (not just "formula conflict exists")
4. Verdict: CONFLICTS FOUND

**Assertions:**
- [ ] Verdict is CONFLICTS FOUND (not CONSISTENT)
- [ ] Conflict entry names both GDD filenames
- [ ] Conflict type is "Formula Mismatch"
- [ ] Severity is HIGH for a direct formula contradiction
- [ ] Both conflicting formulas are shown in the findings table
- [ ] Skill does NOT auto-resolve the conflict

---

### Case 3: Partial Path — GDD references a system with no GDD

**Fixture:**
- GDD-A's Dependencies section lists "system-B" as a dependency
- No GDD for system-B exists in `design/gdd/`
- All other GDDs are consistent

**Input:** `$consistency-check`

**Expected behavior:**
1. Skill reads all GDDs and checks dependency references
2. GDD-A's reference to "system-B" cannot be resolved — no GDD exists for it
3. Findings table includes: GDD-A vs (missing) | Dependency Gap | MEDIUM
4. Verdict: DEPENDENCY GAP (not CONSISTENT, not CONFLICTS FOUND)

**Assertions:**
- [ ] Verdict is DEPENDENCY GAP (distinct from CONSISTENT and CONFLICTS FOUND)
- [ ] Findings entry names GDD-A and the missing system-B
- [ ] Severity is MEDIUM for an unresolved dependency reference
- [ ] Skill suggests running `$design-system system-B` to create the missing GDD

---

### Case 4: Edge Case — No GDDs found

**Fixture:**
- `design/gdd/` directory is empty or does not exist

**Input:** `$consistency-check`

**Expected behavior:**
1. Skill attempts to read files in `design/gdd/`
2. No GDD files found
3. Skill outputs an error: "No GDDs found in `design/gdd/`. Run `$design-system` to create GDDs first."
4. No findings table is produced
5. No verdict is issued

**Assertions:**
- [ ] Skill outputs a clear error message when no GDDs are found
- [ ] No verdict is produced (CONSISTENT / CONFLICTS FOUND / DEPENDENCY GAP)
- [ ] Skill recommends the correct next action (`$design-system`)
- [ ] Skill does NOT crash or produce a partial report

---

### Case 5: Director Gate — No gate spawned; no review-mode.txt read

**Fixture:**
- `design/gdd/` contains ≥2 GDDs
- `production/session-state/review-mode.txt` exists with `full`

**Input:** `$consistency-check`

**Expected behavior:**
1. Skill reads all GDDs and runs the consistency scan
2. Skill does NOT read `production/session-state/review-mode.txt`
3. No director gate agents are spawned at any point
4. Findings table and verdict are produced normally

**Assertions:**
- [ ] No director gate agents are spawned (no CD-, TD-, PR-, AD- prefixed gates)
- [ ] Skill does NOT read `production/session-state/review-mode.txt`
- [ ] Output contains no "Gate: [GATE-ID]" or gate-skipped entries
- [ ] Review mode has no effect on this skill's behavior

---

## Protocol Compliance

- [ ] Reads all GDDs before producing the findings table
- [ ] Findings table shown in full before any write ask (if report is requested)
- [ ] Verdict is one of exactly: CONSISTENT, CONFLICTS FOUND, DEPENDENCY GAP
- [ ] No director gates — no review-mode.txt read
- [ ] Report writing (if requested) gated by "May I write" approval
- [ ] Ends with next-step handoff appropriate to verdict

---

## Coverage Notes

- This skill checks for structural consistency between GDDs. Deep design theory
  analysis (pillar drift, dominant strategies) is handled by `$review-all-gdds`.
- Formula conflict detection relies on consistent formula notation across GDDs —
  informal descriptions of the same mechanic may not be detected.
- The conflict severity rubric (HIGH / MEDIUM / LOW) is defined in the skill body
  and not re-enumerated here.
