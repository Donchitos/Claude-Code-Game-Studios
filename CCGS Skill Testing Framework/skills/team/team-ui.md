# Skill Test Spec: /team-ui

## Skill Summary

Orchestrates the UI team through the full UX pipeline for a single UI feature.
Coordinates ux-designer, ui-programmer, art-director, the engine UI specialist,
and accessibility-specialist through five structured phases: Context Gathering +
UX Spec (Phase 1a/1b) → UX Review Gate (Phase 1c) → Visual Design (Phase 2) →
Implementation (Phase 3) → Review in parallel (Phase 4) → Polish (Phase 5).
Phase 0 resolves `review_mode`, `automation` and `team.size` and the skill announces
the active set before any spawn — the default `individual` spawns ui-programmer +
ux-designer, `small` adds accessibility-specialist + art-director, `studio` adds the
engine UI specialist and an adversarial Phase 4 review. Phase 1a reports each of its five inputs as present or ABSENT,
and a missing `design/accessibility-requirements.md` is carried forward as
`Accessibility: NOT ASSESSED`. Uses `AskUserQuestion` at each phase transition.
Delegates all file writes to sub-agents and sub-skills (`/ux-design`,
`ui-programmer`). Produces a summary report with verdict COMPLETE / BLOCKED and
handoffs to `/ux-review`, `/code-review`, `/team-polish`.

---

## Static Assertions (Structural)

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings (Phase 1a through Phase 5 are all present)
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] File Write Protocol: sub-agents write under the bounded exception (named path, new artifact under `production/`, `docs/` or `tests/`, gated phase) and ask outside it; sub-skills (`/ux-design`) ask before writing; the orchestrator does not write files directly; implementation files (code, shaders, audio, assets) are outside it — each agent lists the files it will create or change, and the skill asks once for the set before any is written
- [ ] Names a destination per agent under `production/ui/[feature-name]/`: `visual-design.md` (art-director, Phase 2), `engine-notes.md` (engine UI specialist), `review-[agent].md` (each Phase 4 reviewer, one file each)
- [ ] Defines a phase gate as a decision point the pipeline itself lists, whatever the `automation` mode, and claims no director spawn at phase gates
- [ ] Has a next-step handoff at the end (references `/ux-review`, `/code-review`, `/team-polish`)
- [ ] Error Recovery Protocol section is present: verify a named artifact is on disk, surface BLOCKED immediately, always produce a partial report, full procedure (surface → assess → options → partial report) in `.claude/docs/error-recovery-protocol.md`
- [ ] Uses `AskUserQuestion` at phase transitions for user approval before proceeding (`collaborative` mode)
- [ ] Phase 0 resolves `team.size`, and the skill requires a one-line active-set announcement before any spawn
- [ ] Phase 4 is explicitly marked as parallel (ux-designer, art-director, accessibility-specialist)
- [ ] UX Review Gate (Phase 1c) is defined as a blocking gate — skill must not proceed to Phase 2 without APPROVED verdict, except by an explicit user override of NEEDS REVISION or NOT ASSESSED, which the final report records
- [ ] Team Composition lists all five roles (ux-designer, ui-programmer, art-director, engine UI specialist, accessibility-specialist)
- [ ] Engine UI specialist is read from `specialists.ui` in `project.yaml` (falling back to `.claude/docs/technical-preferences.md`), and `specialists.ui: null` is treated as unset
- [ ] References the interaction pattern library (`design/ux/interaction-patterns.md`) — ui-programmer must use existing patterns
- [ ] Phase 1a reads `design/accessibility-requirements.md` before design begins

---

## Test Cases

### Case 1: Happy Path — Full pipeline from UX spec through polish succeeds

**Fixture:**
- Resolved config block: `review_mode: full`, `team.size: studio`, `automation: collaborative`
- `design/gdd/game-concept.md` exists with platform targets and intended audience
- `design/player-journey.md` exists
- `design/ux/interaction-patterns.md` exists with relevant patterns
- `design/accessibility-requirements.md` exists with committed tier (e.g., Standard)
- `engine.name` in `project.yaml` is Godot and `specialists.ui` is `godot-specialist`

**Input:** `/team-ui inventory screen`

**Expected behavior:**
1. Before any spawn, one line announces the active set for `team.size: studio`
2. Phase 1a — orchestrator reads game-concept.md, player-journey.md, relevant GDD UI sections, interaction-patterns.md, accessibility-requirements.md; reports each input as present or ABSENT; summarizes a brief for the ux-designer
3. Phase 1b — `/ux-design inventory-screen` invoked (or ux-designer spawned directly); produces `design/ux/inventory-screen.md` using `ux-spec.md` template; `AskUserQuestion` confirms spec before review
4. Phase 1c — `/ux-review design/ux/inventory-screen.md` invoked; returns APPROVED; gate passed, proceed to Phase 2
5. Phase 2 — art-director spawned; reviews full UX spec (not only wireframes); applies visual treatment; verifies color contrast; produces visual design spec with asset manifest; `AskUserQuestion` confirms before Phase 3
6. Phase 3 — `godot-specialist` (from `specialists.ui`) spawned first; produces implementation notes for ui-programmer; ui-programmer spawned with UX spec + visual spec + engine notes; implementation produced; interaction-patterns.md updated if new patterns introduced
7. Phase 4 — ux-designer, art-director, accessibility-specialist spawned in parallel, each told to find where the implementation fails its spec rather than confirm it matches (the `studio` adversarial pass); all three return results before Phase 5
8. Phase 5 — review feedback addressed; animations verified skippable; UI sounds confirmed through audio event system; interaction-patterns.md final check
9. Summary report: UX spec status, UX review verdict, visual design status, implementation status, accessibility compliance, input method support, pattern library status; verdict: COMPLETE

**Assertions:**
- [ ] Active-set line naming `team.size: studio` appears before the first agent is spawned
- [ ] Phase 1a reads all five sources and lists each as present or ABSENT before briefing ux-designer
- [ ] UX Review Gate checked before Phase 2 — Phase 2 does NOT begin until APPROVED
- [ ] Art-director in Phase 2 reviews full spec, not just wireframe images
- [ ] Engine UI specialist is taken from `specialists.ui` and spawned before ui-programmer in Phase 3
- [ ] ui-programmer lists the files it will create or change, and writes none before the one ask for that set is answered yes
- [ ] Phase 4 agents launched simultaneously (ux-designer, art-director, accessibility-specialist)
- [ ] At `team.size: studio`, Phase 4's prompts are adversarial and the summary report says the adversarial pass ran
- [ ] All file writes delegated to sub-agents and sub-skills
- [ ] Verdict COMPLETE in final summary report
- [ ] Next steps include `/ux-review`, `/code-review`, `/team-polish`

---

### Case 2: UX Review Gate — Spec fails review; skill halts before implementation

**Fixture:**
- Resolved config block: `automation: collaborative` (any `team.size` — ux-designer is active at every size)
- `design/ux/inventory-screen.md` produced by Phase 1b
- `/ux-review` returns verdict NEEDS REVISION with specific concerns flagged (e.g., gamepad navigation flow incomplete, contrast ratio below minimum)

**Input:** `/team-ui inventory screen`

**Expected behavior:**
1. Phase 1a + 1b complete — UX spec produced
2. Phase 1c — `/ux-review design/ux/inventory-screen.md` returns NEEDS REVISION
3. Skill does NOT advance to Phase 2
4. `AskUserQuestion` presented with the specific flagged concerns and options:
   - (a) Return to ux-designer to address the issues and re-review
   - (b) Accept the risk and proceed to Phase 2 anyway (conscious decision)
5. If user chooses (a): ux-designer revises spec, `/ux-review` re-run; loop continues until APPROVED or user overrides
6. If user chooses (b): skill proceeds with an explicit NEEDS REVISION note in the final report
7. Skill does NOT silently proceed past the gate

**Assertions:**
- [ ] Phase 2 does NOT begin while UX review verdict is NEEDS REVISION
- [ ] `AskUserQuestion` presents the specific flagged concerns before offering options
- [ ] User must make a conscious choice to override — skill does not assume override
- [ ] If user accepts risk, the final report records the override: the NEEDS REVISION verdict, the concerns left open, and that the user chose to proceed
- [ ] Revision-and-re-review loop is offered (not just a one-shot failure)
- [ ] Skill does NOT discard the produced UX spec on review failure

**Variant B — `/ux-review` returns NOT ASSESSED:**
- Fixture as above, except `design/accessibility-requirements.md` is absent and the other review dimensions find no gaps, so `/ux-review` returns NOT ASSESSED (accessibility: no committed tier)
- Expected: Phase 2 does not begin; `AskUserQuestion` names the unassessed dimension and its missing input (`/ux-design accessibility`), with options to produce that input and re-run the review, or to proceed consciously; if the user proceeds, the final report records the NOT ASSESSED override and Phase 4 still reports `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)`

**Assertions (variant B):**
- [ ] Phase 2 does NOT begin on NOT ASSESSED without an explicit user decision — it blocks like NEEDS REVISION
- [ ] The prompt names the dimension `/ux-review` could not assess and the input that would make it checkable, not spec revisions
- [ ] The skill does not re-run `/ux-review` against the same missing input and treat the result as new
- [ ] An override is recorded in the final report with the NOT ASSESSED verdict and the unassessed dimension

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `/team-ui` (no argument)

**Expected behavior:**
1. Skill detects no argument provided
2. Outputs usage message explaining the required argument (UI feature description)
3. Shows the invocation format `/team-ui [UI feature description] [--review full|lean|solo]` with examples (`inventory screen`, `main menu`, `combat HUD`)
4. Skill exits without spawning any subagents or reading any project files

**Assertions:**
- [ ] Skill does NOT spawn any subagents when no argument is given
- [ ] Usage message shows the full argument-hint: `/team-ui [UI feature description] [--review full|lean|solo]`
- [ ] At least one example of a valid invocation is shown
- [ ] No UX spec files or GDDs read before failing
- [ ] Verdict is NOT shown (pipeline never starts)

---

### Case 4: Accessibility Parallel Review — Phase 4 runs three streams simultaneously

**Fixture:**
- Resolved config block: `review_mode: full`, `team.size: small`, `automation: collaborative`
- `design/ux/inventory-screen.md` exists (APPROVED)
- Visual design spec complete
- Implementation complete
- `design/accessibility-requirements.md` committed tier: Standard

**Input:** `/team-ui inventory screen` (resuming from Phase 3 complete)

**Expected behavior:**
1. Phase 4 begins after implementation is confirmed complete
2. Three Agent calls issued simultaneously: ux-designer, art-director, accessibility-specialist
3. Each stream operates independently:
   - ux-designer: verifies implementation matches wireframes, tests keyboard-only and gamepad-only navigation, checks accessibility features function
   - art-director: verifies visual consistency with art bible at minimum and maximum supported resolutions
   - accessibility-specialist: audits against the Standard accessibility tier in `design/accessibility-requirements.md`; any violation flagged as a blocker
4. Skill waits for all three results before proceeding to Phase 5
5. `AskUserQuestion` presents all three review results before Phase 5 begins

**Assertions:**
- [ ] All three Agent calls issued before any result is awaited (parallel, not sequential)
- [ ] Phase 5 does NOT begin until all three Phase 4 agents have returned
- [ ] Accessibility-specialist explicitly reads `design/accessibility-requirements.md` for the committed tier
- [ ] Accessibility violations flagged as BLOCKING (not merely advisory)
- [ ] `AskUserQuestion` shows all three review streams' results together before Phase 5 approval
- [ ] No Phase 4 agent's output is used as input for another Phase 4 agent

---

### Case 5: Missing Interaction Pattern Library — Skill notes the gap rather than inventing patterns

**Fixture:**
- Resolved config block: `automation: collaborative` (any `team.size`)
- `design/ux/interaction-patterns.md` does NOT exist
- All other required files present

**Input:** `/team-ui settings menu`

**Expected behavior:**
1. Phase 1a — orchestrator attempts to read `design/ux/interaction-patterns.md`; file not found
2. Skill surfaces the gap: "interaction-patterns.md does not exist — no existing patterns to reuse"
3. `AskUserQuestion` presented with options:
   - (a) Run `/ux-design patterns` first to establish the pattern library, then continue
   - (b) Proceed without the pattern library — ui-programmer will treat all patterns created as new and add each to a new `design/ux/interaction-patterns.md` at completion
4. Skill does NOT invent or assume patterns from other sources
5. If user chooses (b): ui-programmer is explicitly instructed to treat all patterns created as new and to add each to a new `design/ux/interaction-patterns.md` at completion
6. Final report notes that interaction-patterns.md was created (or is still absent if user skipped)

**Assertions:**
- [ ] Skill does NOT silently ignore the missing pattern library
- [ ] Skill does NOT invent patterns by guessing from the feature name or GDD alone
- [ ] `AskUserQuestion` offers a "create pattern library first" option (referencing `/ux-design patterns`)
- [ ] If user proceeds without the library, ui-programmer is told to treat all patterns as new
- [ ] Final report documents pattern library status (created / absent / updated)
- [ ] Skill does NOT fail entirely — the gap is noted and user is given a choice

---

## Protocol Compliance

- [ ] At the default `team.size: individual`, the run opens with an `Active set (team.size: individual): ui-programmer + ux-designer` line and a `Not spawned this run:` line naming art-director, accessibility-specialist and the engine UI specialist — before any agent is spawned
- [ ] In `collaborative` mode, `AskUserQuestion` used at each phase transition — user approves before pipeline advances
- [ ] UX Review Gate (Phase 1c) is blocking — Phase 2 cannot begin without APPROVED, or an explicit user override of a NEEDS REVISION or NOT ASSESSED verdict that the final report records
- [ ] When `design/accessibility-requirements.md` is absent, Phase 4 reports `Accessibility: NOT ASSESSED — no committed tier (design/accessibility-requirements.md absent)` and never reports the accessibility gate as passed
- [ ] When no engine is configured, the engine UI specialist is skipped and the run output records `Engine validation: NOT ASSESSED — no engine configured`
- [ ] When the accessibility gate or the engine validation was NOT ASSESSED, the verdict names each (`COMPLETE — [accessibility | engine validation] NOT ASSESSED ([reason])`) — never a plain COMPLETE
- [ ] All file writes delegated to sub-agents and sub-skills — orchestrator does not call Write or Edit directly
- [ ] Phase 4 agents launched in parallel per skill spec
- [ ] Error Recovery Protocol followed: surface → assess → offer options → partial report
- [ ] Partial report always produced even when agents are BLOCKED
- [ ] Verdict is one of COMPLETE / BLOCKED
- [ ] Next steps present at end: `/ux-review`, `/code-review`, `/team-polish`

---

## Coverage Notes

- The HUD-specific path (`/ux-design hud` + `hud-design.md` template + visual budget check in Phase 5)
  is not separately tested here; it shares the same phase structure but uses different templates.
- The "Update in place" path for interaction-patterns.md (new pattern added during implementation)
  is exercised implicitly in Case 1 Phase 3 — a dedicated fixture with a known new pattern would
  strengthen coverage.
- Engine UI specialist unavailable (no engine configured) is asserted in Protocol Compliance but
  not given a dedicated fixture; a missing accessibility-requirements file is exercised at the
  Phase 1c gate by Case 2 variant B.
- The NEEDS REVISION and NOT ASSESSED overrides (Case 2, both variants) must be recorded in
  the final report; this is asserted but not further tested for downstream effects.
- A MAJOR REVISION NEEDED verdict from `/ux-review` is not given a case.
