---
name: gate-check
description: "Validate readiness to advance between development phases. Produces a PASS/CONCERNS/FAIL verdict with specific blockers and required artifacts."
argument-hint: "[target-phase: pre-production | production | alpha | beta | release]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash
---

# Phase Gate Validation

This skill validates whether the project is ready to advance to the next development
phase. It checks for required artifacts, quality standards, and blockers.

**Distinct from `/project-stage-detect`**: That skill is diagnostic ("where are we?").
This skill is prescriptive ("are we ready to advance?" with a formal verdict).

---

## 1. Parse Arguments

- **With argument**: `/gate-check production` — validate readiness for that specific phase
- **No argument**: Auto-detect current stage using the same heuristics as
  `/project-stage-detect`, then validate the NEXT phase transition

---

## 2. Phase Gate Definitions

### Gate: Concept → Pre-production

**Required Artifacts:**
- [ ] `design/gdd/game-concept.md` exists and has content
- [ ] Game pillars defined (in concept doc or `design/gdd/game-pillars.md`)
- [ ] Engine chosen (CLAUDE.md Technology Stack is not `[CHOOSE]`)
- [ ] Technical preferences configured (`.claude/docs/technical-preferences.md` populated)

**Quality Checks:**
- [ ] Game concept has been reviewed (`/design-review` verdict not MAJOR REVISION NEEDED)
- [ ] Core loop is described and understood
- [ ] Target audience is identified

---

### Gate: Pre-production → Production

**Required Artifacts:**
- [ ] Systems index exists at `design/gdd/systems-index.md` with at least MVP systems enumerated
- [ ] At least 1 GDD in `design/gdd/` (beyond game-concept.md and systems-index.md)
- [ ] At least 1 Architecture Decision Record in `docs/architecture/`
- [ ] At least 1 prototype in `prototypes/` with a README
- [ ] Engine reference docs exist in `docs/engine-reference/`
- [ ] First sprint plan exists in `production/sprints/`

**Quality Checks:**
- [ ] GDD(s) pass design review (8 required sections present)
- [ ] Prototype validates the core loop hypothesis
- [ ] Architecture decisions cover core systems (rendering, input, state management)
- [ ] Technical preferences have naming conventions and performance budgets set

---

### Gate: Production → Alpha

**Required Artifacts:**
- [ ] `src/` has active code organized into subsystems
- [ ] All core mechanics from GDD are implemented (cross-reference `design/gdd/` with `src/`)
- [ ] Main gameplay path is playable end-to-end
- [ ] Test files exist in `tests/`
- [ ] At least 1 playtest report (or `/playtest-report` has been run)

**Quality Checks:**
- [ ] Tests are passing (run test suite via Bash)
- [ ] No critical/blocker bugs in any bug tracker or known issues
- [ ] Core loop plays as designed (compare to GDD acceptance criteria)
- [ ] Performance is within budget (check technical-preferences.md targets)

---

### Gate: Alpha → Beta

**Required Artifacts:**
- [ ] All features from milestone plan are implemented
- [ ] Content is complete (all levels, assets, dialogue referenced in design docs exist)
- [ ] Localization strings are externalized (no hardcoded player-facing text in `src/`)
- [ ] QA test plan exists
- [ ] Balance data has been reviewed (`/balance-check` run)

**Quality Checks:**
- [ ] All tests passing
- [ ] Performance targets met (frame rate, memory, load times)
- [ ] No critical or high-severity bugs
- [ ] Accessibility basics covered (remapping, text scaling if applicable)
- [ ] Save/load system works reliably

---

### Gate: Beta → Release

**Required Artifacts:**
- [ ] Release checklist completed (`/release-checklist` or `/launch-checklist` run)
- [ ] Store metadata prepared (if applicable)
- [ ] Changelog / patch notes drafted
- [ ] Post-launch support plan exists

**Quality Checks:**
- [ ] Full QA pass signed off by `qa-lead`
- [ ] Performance targets met across all target platforms
- [ ] No known critical, high, or medium-severity bugs
- [ ] Localization verified for all target languages
- [ ] Legal requirements met (EULA, privacy policy, age ratings if applicable)
- [ ] Build compiles and packages cleanly

---

## 3. Run the Gate Check

For each item in the target gate:

### Artifact Checks
- Use `Glob` and `Read` to verify files exist and have meaningful content
- Don't just check existence — verify the file has real content (not just a template header)
- For code checks, verify directory structure and file counts

### Quality Checks
- For test checks: Run the test suite via `Bash` if a test runner is configured
- For design review checks: `Read` the GDD and check for the 8 required sections
- For performance checks: `Read` technical-preferences.md and compare against any
  profiling data in `tests/performance/` or recent `/perf-profile` output
- For localization checks: `Grep` for hardcoded strings in `src/`

### Cross-Reference Checks
- Compare `design/gdd/` documents against `src/` implementations
- Check that every system referenced in architecture docs has corresponding code
- Verify sprint plans reference real work items

---

## 4. Collaborative Assessment

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that the core loop plays well. Has it been playtested?"
- "No playtest report found. Has informal testing been done?"
- "Performance profiling data isn't available. Would you like to run `/perf-profile`?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.

---

## 5. Output the Verdict

```
## Gate Check: [Current Phase] → [Target Phase]

**Date**: [date]
**Checked by**: gate-check skill

### Required Artifacts: [X/Y present]
- [x] design/gdd/game-concept.md — exists, 2.4KB
- [ ] docs/architecture/ — MISSING (no ADRs found)
- [x] production/sprints/ — exists, 1 sprint plan

### Quality Checks: [X/Y passing]
- [x] GDD has 8/8 required sections
- [ ] Tests — FAILED (3 failures in tests/unit/)
- [?] Core loop playtested — MANUAL CHECK NEEDED

### Blockers
1. **No Architecture Decision Records** — Run `/architecture-decision` to create one
   covering core system architecture before entering production.
2. **3 test failures** — Fix failing tests in tests/unit/ before advancing.

### Recommendations
- [Priority actions to resolve blockers]
- [Optional improvements that aren't blocking]

### Verdict: [PASS / CONCERNS / FAIL]
- **PASS**: All required artifacts present, all quality checks passing
- **CONCERNS**: Minor gaps exist but can be addressed during the next phase
- **FAIL**: Critical blockers must be resolved before advancing
```

---

## 6. Follow-Up Actions

Based on the verdict, suggest specific next steps:

- **No systems index?** → `/map-systems` to decompose the concept into systems
- **Missing design docs?** → `/reverse-document` or delegate to `game-designer`
- **Missing ADRs?** → `/architecture-decision`
- **Tests failing?** → delegate to `lead-programmer` or `qa-tester`
- **No playtest data?** → `/playtest-report`
- **Performance unknown?** → `/perf-profile`
- **Not localized?** → `/localize`
- **Ready for release?** → `/launch-checklist`

---

## Collaborative Protocol

This skill follows the collaborative design principle:

1. **Scan first**: Check all artifacts and quality gates
2. **Ask about unknowns**: Don't assume PASS for things you can't verify
3. **Present findings**: Show the full checklist with status
4. **User decides**: The verdict is a recommendation — the user makes the final call
5. **Get approval**: "May I write this gate check report to production/gate-checks/?"

**Never** block a user from advancing — the verdict is advisory. Document the risks
and let the user decide whether to proceed despite concerns.
