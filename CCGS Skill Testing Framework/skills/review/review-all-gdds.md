# Skill Test Spec: /review-all-gdds

## Skill Summary

`/review-all-gdds` is an Opus-tier skill that performs a holistic cross-GDD
review across the system GDDs in `design/gdd/`. After loading everything
(Phase 1), it runs two independent reviews in parallel as `game-designer`
sub-agents: Phase 2, Cross-GDD Consistency (dependency bidirectionality, rule
contradictions, stale references, ownership conflicts, formula compatibility,
acceptance-criteria conflicts), and Phase 3, Game Design Holism (competing
progression loops, attention budget, dominant strategies, economic loops,
difficulty curves, pillar alignment, player-fantasy coherence). Phase 4 walks
multi-system scenarios. It produces a PASS / NOT ASSESSED / CONCERNS / FAIL
verdict, and writes `design/gdd/gdd-cross-review-[YYYY-MM-DD].md` and
systems-index "Needs Revision" statuses only after the user approves.

It is invoked after individual GDDs are approved and before architecture work.
It spawns no director gate agents. At `workflow: minimal` it does not apply (no
GDDs), so every fixture below sets `modes.workflow: full`.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥5 phase headings (complex multi-phase skill)
- [ ] Contains verdict keywords: PASS, NOT ASSESSED, CONCERNS, FAIL
- [ ] `allowed-tools` includes Write, so "May I write" language is present (Phase 6 report write)
- [ ] Has a next-step handoff at the end
- [ ] Documents parallel spawning of Phase 2 (Consistency) and Phase 3 (Design Theory)

---

## Director Gate Checks

No director gates — this skill spawns no director gate agents and resolves no
review mode. It IS the holistic review; its only agents are the two
`game-designer` sub-agents for Phases 2 and 3.

---

## Test Cases

### Case 1: Happy Path — Clean GDD set with no conflicts

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/` contains `game-concept.md`, `game-pillars.md` (pillars and
  anti-pillars), `systems-index.md`, and three system GDDs — `combat.md`,
  `inventory.md`, `crafting.md` — each with every section Phase 1c loads and a
  filled `## Cross-References` table whose rows all resolve
- All GDDs are consistent: no formula contradictions, no competing ownership,
  no stale references, reciprocal dependencies; every system serves a pillar
- Nothing a design-theory check would warn on either: one primary progression
  loop, at most 4 systems active at once, every resource has both a source and a
  sink, compatible scaling curves, compatible player fantasies

**Input:** `/review-all-gdds`

**Expected behavior:**
1. Skill greps `## Summary` across `design/gdd/*.md` and shows a manifest ("Found [N] GDDs. Summaries: …")
2. Skill reads the entity registry, or notes that it is empty and suggests `/consistency-check`
3. Skill loads the review sections and reports "Loaded [N] system GDDs covering [M] systems. Pillars: […]. Anti-pillars: […]."
4. Phase 2 and Phase 3 spawn simultaneously as `game-designer` sub-agents, each
   given the pasted GDD content for its slice (not file paths) and its checklist (2a–2f / 3a–3g)
5. Phase 4 walks 3–5 multi-system scenarios
6. Report shows no blocking issues and no warnings; verdict PASS
7. `AskUserQuestion`: "May I write this review to `design/gdd/gdd-cross-review-[date].md`?"
8. Closing widget built from project state

**Assertions:**
- [ ] Phase 2 and Phase 3 are spawned in parallel (both `Agent` calls issued before either result is awaited)
- [ ] Sub-agent prompts carry the GDD section content, not just file paths
- [ ] The report states the covered set: `GDDs reviewed: [N] of [M] present` and `Not read: none`, and lists the scenarios walked
- [ ] Verdict is PASS only because there are no blocking issues **and no warnings**, over three readable GDDs — a single warning would make it CONCERNS
- [ ] The report is written only after the user approves, under an ISO-dated name (`gdd-cross-review-YYYY-MM-DD.md`)
- [ ] The closing widget offers `/create-architecture` and `/gate-check` (both allowed on PASS)

---

### Case 2: Failure Path — Conflicting rules between two GDDs

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `combat.md` defines a floor: "Minimum damage after armour reduction is 1"
- `status-effects.md` states a mechanic that bypasses it: "Poison ignores armour
  and can reduce damage to 0"
- The two GDDs are otherwise complete and valid; `game-pillars.md` defines the
  pillars and `systems-index.md` lists both systems

**Input:** `/review-all-gdds`

**Expected behavior:**
1. Phase 2 detects the floor/ceiling contradiction
2. Report prints a `🔴 Rule Contradiction` entry quoting both rules and asking which GDD is authoritative
3. The issue sits under Consistency Issues → Blocking; both GDDs appear in "GDDs Flagged for Revision"
4. Verdict: FAIL, with "If FAIL — required actions before re-running"
5. After the report write question, a second `AskUserQuestion` offers to mark the flagged GDDs `Needs Revision` in `systems-index.md`

**Assertions:**
- [ ] Verdict is FAIL (not PASS, CONCERNS or NOT ASSESSED)
- [ ] Both GDD filenames are named in the conflict entry
- [ ] The specific contradicting rules are quoted (not a vague "conflict found")
- [ ] The issue is classified as Blocking (🔴), and both GDDs are in the flagged table with Priority Blocking
- [ ] Skill does NOT decide which GDD is right and does NOT edit either GDD
- [ ] If the user approves the systems-index update, the status is written as exactly `Needs Revision` with no parenthetical
- [ ] The closing widget offers neither `/create-architecture` nor `/gate-check` (verdict is FAIL)

---

### Case 3: Partial Path — Cross-reference to a GDD that does not exist

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/` holds `game-pillars.md`, `systems-index.md` and two consistent
  system GDDs, `crafting.md` and `inventory.md`
- `crafting.md`'s `## Cross-References` table has a row whose Target GDD is
  `system-b.md`; no `design/gdd/system-b.md` exists
- `systems-index.md` lists system-b as the next system with Status: Not Started
- Nothing else would warn

**Input:** `/review-all-gdds`

**Expected behavior:**
1. Phase 2's stale-reference check (2c) confirms each Cross-References row's
   Target GDD exists, and finds `system-b.md` missing
2. Because `systems-index.md` lists system-b, the reference is a dependency on
   planned work: a `⚠️ Stale Reference` Warning naming `crafting.md` and the
   missing target, to re-check when that GDD is written
3. No other issues found; verdict CONCERNS (warnings, nothing blocking)
4. Closing widget includes `/design-system system-b` (next in design order)

**Assertions:**
- [ ] The finding names `crafting.md` and the missing `system-b.md`
- [ ] It is reported under Warnings (⚠️), not Blocking — because the systems index lists system-b as planned
- [ ] Verdict is CONCERNS — not FAIL for a reference to planned work, and not an unqualified PASS
- [ ] The closing widget offers `/design-system system-b`, and offers `/create-architecture` but not `/gate-check` (which requires PASS)
- [ ] Skill does NOT skip or silently ignore the missing target

**Case 3b — the target is in neither place:** the same fixture, except
`systems-index.md` has no entry for system-b. Nothing will ever define it.

**Assertions (3b):**
- [ ] The reference is reported as 🔴 Blocking, and `crafting.md` appears in "GDDs Flagged for Revision" with Priority Blocking
- [ ] Verdict is FAIL, and the closing widget offers neither `/create-architecture` nor `/gate-check`

---

### Case 4: Edge Case — Fewer than two system GDDs

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/` contains `systems-index.md` and a single system GDD, `combat.md`

**Input:** `/review-all-gdds`

**Expected behavior:**
1. Skill loads what exists and counts the system GDDs
2. Fewer than 2 → skill stops with: "Cross-GDD review requires at least 2 system
   GDDs. Write more GDDs first, then re-run `/review-all-gdds`."
3. No review phase runs and no report is offered

**Assertions:**
- [ ] Skill outputs the "requires at least 2 system GDDs" stop message
- [ ] Neither Phase 2 nor Phase 3 sub-agent is spawned
- [ ] No verdict of PASS is produced for the single document
- [ ] No report write is offered and no file is written

---

### Case 5: Director Gate — none spawned, whatever the review mode

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/` holds the Case 1 set: concept, pillars, systems index and three
  consistent system GDDs
- 5a: `modes.review_mode: full`; 5b: `modes.review_mode: solo`

**Input:** `/review-all-gdds`

**Expected behavior:**
1. The resolved config block requests only `automation`, `workflow` and
   `system_overrides` — review mode is not consulted
2. In both 5a and 5b, the same two `game-designer` sub-agents run Phases 2 and 3
3. No director gate agent is spawned; the verdict is produced normally

**Assertions:**
- [ ] No director gate agents (CD-, TD-, PR-, AD-, LP- prefixed gates) are spawned in either mode
- [ ] Review mode changes nothing: under `solo` the two `game-designer` sub-agents still run
- [ ] Output contains no "Gate: [GATE-ID]" or "[GATE-ID] skipped" entries
- [ ] The skill produces a verdict in both modes
- [ ] The only `Agent` spawns in the run are the Phase 2 and Phase 3 `game-designer` sub-agents

---

### Case 6: NOT ASSESSED — fewer than two readable GDDs

**Fixture:**
- `project.yaml` sets `modes.workflow: full`
- `design/gdd/` holds `game-pillars.md`, `systems-index.md` and two system GDDs:
  `combat.md`, complete, and `inventory.md`, which has the template's headings but
  only placeholder text under them

**Input:** `/review-all-gdds`

**Expected behavior:**
1. Two system GDDs exist, so the "requires at least 2 system GDDs" stop does not fire
2. `inventory.md` is present but empty — not reviewable — so only one GDD can be
   compared, and a clean result would mean only that nothing was compared
3. Verdict NOT ASSESSED; "If NOT ASSESSED — what could not be reviewed, and why"
   names `inventory.md` as placeholder-only and says a cross-review needs two
   readable GDDs
4. The report states `GDDs reviewed: 1 of 2 present`

**Assertions:**
- [ ] Verdict is NOT ASSESSED — not PASS, although no contradiction was found
- [ ] The report names `inventory.md` as present but not reviewable, and states `GDDs reviewed: 1 of 2 present`
- [ ] A GDD that could not be read at all would be named on the report's `Not read:` line under every verdict, and is a NOT ASSESSED trigger like an empty one
- [ ] The closing widget offers neither `/create-architecture` nor `/gate-check`

---

## Protocol Compliance

- [ ] Phase 2 (Consistency) and Phase 3 (Design Theory) spawned in parallel — not sequentially
- [ ] The full analysis is shown before any write is requested
- [ ] Does NOT write the report or update `systems-index.md` without `AskUserQuestion` approval
- [ ] Verdict is one of exactly: PASS, NOT ASSESSED, CONCERNS, FAIL
- [ ] Every issue cites the GDD, section and text involved
- [ ] Ends with an `AskUserQuestion` handoff built from the verdict: FAIL or NOT ASSESSED → neither `/create-architecture` nor `/gate-check`; CONCERNS → `/create-architecture` only; PASS → both

---

## Coverage Notes

- Economic loop analysis (3d, source/sink loops) is not fixture-tested. Case 2
  exercises Phase 2's rule-contradiction check — a different checklist, run by
  the other sub-agent — so it says nothing about 3d.
- The design theory phase (Phase 3) checks, including dominant strategy detection
  and cognitive overload, are not individually fixture-tested.
- Case 6 covers the fewer-than-two-readable-GDDs trigger, through a
  present-but-empty GDD. The NOT ASSESSED triggers for undefined pillars and for
  a sub-agent that returns no report are not fixture-tested.
- The `since-last-review` mode (`.claude/scripts/review-scope.sh`) and the
  `consistency` / `design-theory` focus modes are not tested here.
