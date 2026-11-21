# Skill Test Spec: /design-system

## Skill Summary

`/design-system <system-name>` authors a Game Design Document for one system at
`design/gdd/[system-name].md`. Which sections are required depends on the
resolved `workflow` tier (a `system_overrides` row wins for that system): all 8
at `full` (Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases,
Dependencies, Tuning Knobs, Acceptance Criteria); 5 plus conditional Formulas at
`standard`; 5 at a voluntary `minimal`. `## Summary` is authored at every tier,
after the other sections.

Each of the five phases is a `references/N-*.md` file the skill reads before doing
that phase and reads again if the conversation is compacted during it.

The skill reads context first (game concept, systems index, entity registry,
dependency GDD sections, engine reference), presents a context summary and a
Technical Feasibility Brief, then asks "May I create the skeleton file at
`design/gdd/[system-name].md`?". Each section then runs the cycle Context →
Questions → Options → Decision → Draft → Approval → Write: in `collaborative`
mode the draft and the "Approve the [Section Name] section?" widget appear in
the same response, and the approved section is written immediately with Edit.
Specialist agents are consulted per section, subject to per-section review-mode
checks.

After all sections are written, the CD-GDD-ALIGN gate runs once in `full` mode
only. `retrofit <path>` fills only the missing or placeholder sections of an
existing GDD. The skill never offers `/design-review` inline — it directs the
user to a fresh session.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: `APPROVED`, `CONCERNS`, `BLOCKED`
- [ ] Contains "May I write" / "May I create" collaborative protocol language (skeleton and per-section approval)
- [ ] Has a next-step handoff at the end
- [ ] Documents skeleton-first approach (file created with headers before content, after approval)
- [ ] Documents CD-GDD-ALIGN gate: runs in full mode only; skipped in lean and solo with a named note
- [ ] Documents retrofit mode for existing GDD files

---

## Director Gate Checks

Review mode comes from the resolved `review_mode` (`modes.review_mode` in
`project.yaml`); `--review full|lean|solo` overrides it for one run.

**CD-GDD-ALIGN** (`creative-director`) runs once, in Step 5a-bis, after every
section and the Summary are written and the self-check has read the GDD back
from file. It is passed the GDD path, the game pillars, the MDA aesthetics
target and the GDD's Player Fantasy section (or a statement that the tier did not
author one). The verdict is recorded in the GDD Status header as
`> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date] / CONCERNS (accepted) [date] / REVISED [date] / NOT ASSESSED [date] — [missing input]`.

- `full` → run in the conversation, never as a spawn.
- `lean` → skipped (not a PHASE-GATE). Note: "CD-GDD-ALIGN skipped — Lean mode."
- `solo` → skipped. Note: "CD-GDD-ALIGN skipped — Solo mode."

Per-section specialist steps (not director gates; each reads a lens in
`references/lens-*.md`, and none spawns an agent) have their own checks:
`solo` skips them all; `lean` skips them except for Sections D (Formulas) and
H (Acceptance Criteria), Section G (Tuning Knobs) when Section D defines a
formula whose knobs interact, and Visual/Audio when the system's visual feedback
is central to it (a `Gameplay` or `UI` system whose events the player reads to
play); `full` runs them. Every skipped step prints the section's note naming
the agent and the mode, e.g. "`creative-director` not consulted — Lean mode.
Review manually before production."

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Happy Path — New combat GDD, full mode, full workflow

**Fixture:**
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist; `combat` is listed with `Category: Gameplay`
- No `design/gdd/combat.md`
- `project.yaml` has `engine.name: Godot`, `modes.review_mode: full`, `modes.workflow: full`, `modes.automation: collaborative`; `docs/engine-reference/godot/` has `VERSION.md` and `modules/physics.md` (combat maps to the Physics domain)
- CD-GDD-ALIGN returns APPROVE

**Input:** `/design-system combat`

**Expected behavior:**
1. Phase 2 reads the concept, systems index, entity registry (if present) and dependency GDD sections before asking anything, then presents the "Designing: Combat" context summary and the Technical Feasibility Brief with its `AskUserQuestion`
2. "Ready to start designing combat?" is asked
3. "May I create the skeleton file at `design/gdd/combat.md`?" — on yes, the skeleton is written with all 8 required sections plus the template's other sections, each holding `[To be designed]`; `production/session-state/active.md` is updated
4. Sections A–H are walked in order; each draft is followed in the same response by "Approve the [Section Name] section?" with `[A] Approve — write it to file` / `[B] Make changes — describe what to fix` / `[C] Start over`
5. Section B applies the creative-director lens (2-3 framings); Section C shows one view per role from the Combat row (`game-designer` plus supporting roles) before drafting; Sections D and E apply the systems-designer lens; Section H the qa-lead lens; no agent is spawned
6. Each approved section is written immediately by an Edit whose `old_string` includes the section heading; `active.md` is updated after each
7. Visual/Audio and Game Feel are treated as required (Gameplay category) — not offered as skippable
8. `## Summary` is authored after the other sections; Step 5a reads the GDD back from file
9. CD-GDD-ALIGN runs once, in the conversation, and returns APPROVE; the Status header records `APPROVED [date]`
10. The completion summary directs the user to run `/design-review design/gdd/combat.md` in a fresh session

**Assertions:**
- [ ] The skeleton is written only after the "May I create the skeleton file" approval, and contains all 8 required section headers
- [ ] Every section draft is followed in the same response by the "Approve the [Section Name] section?" widget
- [ ] Each section is written individually, immediately after its approval, by an Edit anchored on its heading
- [ ] Section C's role views come from the routing table's Combat row, each shown as its own block before drafting
- [ ] CD-GDD-ALIGN runs once, without a spawn, after all sections and the Summary are written — not per section
- [ ] The verdict is recorded as `> **Creative Director Review (CD-GDD-ALIGN)**: APPROVED [date]`
- [ ] `/design-review` is directed to a fresh session and never offered inline

---

### Case 2: Retrofit Mode — Fill only the incomplete sections at standard tier

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `modes.workflow: standard`, `modes.review_mode: lean`
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist; `inventory` is listed with `Category: Economy` (engine domain Scripting)
- `docs/engine-reference/godot/` has `VERSION.md` and `modules/`, but no `modules/scripting.md`
- `design/gdd/inventory.md` exists with Overview, Detailed Design and Formulas fully written; its `## Summary` holds only `[To be designed]`
- `## Edge Cases` and `## Acceptance Criteria` contain only `[To be designed]`; `## Dependencies` has an empty body
- The file has no Player Fantasy or Tuning Knobs section

**Input:** `/design-system retrofit design/gdd/inventory.md`

**Expected behavior:**
1. The skill reads the existing GDD and identifies which sections are present, placeholder-only or empty
2. It presents the "Retrofit: Inventory" block: written sections (will not be touched) and missing or incomplete sections (will be authored)
3. Player Fantasy and Tuning Knobs are listed as available to add, not as gaps, because `standard` does not require them
4. It asks: "Shall I fill the 3 missing sections? I will not modify any existing content."
5. On yes, Phase 2 runs as normal; §2e names the missing module — "no engine reference for `Scripting` under `docs/engine-reference/godot/modules/`; feasibility not checked against the pinned engine" — and carries it into §5-pre
6. No skeleton is created; only Edge Cases, Dependencies and Acceptance Criteria run the section cycle, then §5-pre replaces the Summary placeholder
7. Each write replaces only the placeholder or empty body; Overview, Detailed Design and Formulas are not modified

**Assertions:**
- [ ] The retrofit block is shown before any change is made
- [ ] Sections the tier does not require are not reported as gaps
- [ ] The skill asks "Shall I fill the 3 missing sections? I will not modify any existing content."
- [ ] The absent `scripting.md` module is named in the output, not skipped silently as if feasibility had been checked
- [ ] No skeleton is created and complete sections are not re-authored or overwritten
- [ ] Each filled section still goes through the per-section approval before its write

---

### Case 3: Director Gate — CD-GDD-ALIGN returns CONCERNS, REJECT or NOT ASSESSED

**Fixture:**
- `design/gdd/game-concept.md` (pillars include "Fearless Exploration") and `design/gdd/systems-index.md` exist; `stamina` is listed with `Category: Gameplay`
- `project.yaml` has `modes.review_mode: full` and `modes.workflow: full`
- All eight sections, Player Fantasy included, and the Summary are written for `design/gdd/stamina.md`
- Scenario (a): CD-GDD-ALIGN returns CONCERNS: "Detailed Design's stamina drain undercuts the 'Fearless Exploration' pillar"
- Scenario (b): CD-GDD-ALIGN returns REJECT: "stamina exhaustion strands the player mid-exploration, which the 'Fearless Exploration' pillar rules out"
- Scenario (c): CD-GDD-ALIGN returns NOT ASSESSED — no MDA aesthetics target was available to check the GDD against

**Input:** `/design-system stamina` (reaching Step 5a-bis)

**Expected behavior:**
1. Gate CD-GDD-ALIGN is run in the conversation (no spawn) against the GDD on disk, the game pillars, the MDA aesthetics target and the GDD's Player Fantasy section
2. (a) The CONCERNS are surfaced via `AskUserQuestion` with the standard options: `Revise flagged items` / `Accept and proceed` / `Discuss further`
3. (a) If "Revise flagged items": Detailed Design runs its section cycle again — its specialists consulted first — and is approved through "Approve the Detailed Design section?" before it is written; the Status header records `REVISED [date]`
4. (a) If "Accept and proceed": the Status header records `CONCERNS (accepted) [date]`
5. (b) The blockers are shown; the flagged section is re-drafted and re-approved the same way before anything else is written, and the Status header records `REVISED [date]`, never `APPROVED`
6. (c) The missing input is named; the user can supply it and re-run the gate, or the Status header records `NOT ASSESSED [date] — [missing input]`, never `APPROVED`
7. Only after the verdict is recorded does the skill continue to the entity registry step (5b)

**Assertions:**
- [ ] CD-GDD-ALIGN receives the completed GDD path, the pillars, the MDA target and the Player Fantasy section
- [ ] (a) CONCERNS are shown to the user with the three standard options, not auto-accepted
- [ ] A revised section re-runs its section cycle and is re-approved before it is written
- [ ] The Status header records `REVISED [date]` or `CONCERNS (accepted) [date]` to match the user's choice
- [ ] (b) After a REJECT, no later step (5b registry, 5d systems index) runs until the flagged section has been revised
- [ ] (c) NOT ASSESSED is never recorded or reported as an approval

---

### Case 4: Lean and Solo Modes — Gate skipped once; specialist steps follow their own checks

**Fixture:**
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist; the system is `stamina` (`Category: Gameplay`); no `design/gdd/stamina.md`
- `project.yaml` has `engine.name: Godot` and `modes.workflow: full`
- Section D's stamina formula has no knobs that interact; the stamina bar is feedback the player reads to play
- Scenario (a): `modes.review_mode: lean`
- Scenario (b): `modes.review_mode: solo`

**Input:** `/design-system stamina`

**Expected behavior:**
1. (a) Sections B, C, E and G are drafted without their specialist steps, and each prints its note with the mode, e.g. "`creative-director` not consulted — Lean mode. Review manually before production."
2. (a) Section D still applies the `systems-designer` lens, Section H `qa-lead`'s, and Visual/Audio `art-director`'s — stamina's feedback is central to play
3. (a) At Step 5a-bis: "CD-GDD-ALIGN skipped — Lean mode." — printed once, not per section
4. (b) No specialist step or director gate runs; each section whose step was skipped carries its note, e.g. "`creative-director` not consulted — Solo mode. Review manually before production."
5. (b) At Step 5a-bis: "CD-GDD-ALIGN skipped — Solo mode."
6. In both scenarios every section still requires the "Approve the [Section Name] section?" approval before it is written

**Assertions:**
- [ ] (a) In lean mode Sections B, C, E and G are drafted without their specialists, while Sections D and H and Visual/Audio still run theirs
- [ ] (a) Each lean-skipped step prints a "not consulted — Lean mode" note naming its agent — none is skipped silently
- [ ] (a) The CD-GDD-ALIGN skip note appears once, at Step 5a-bis
- [ ] (b) In solo mode no specialist step runs, and each skipped specialist leaves a "not consulted — Solo mode" note
- [ ] (b) The skip note reads "CD-GDD-ALIGN skipped — Solo mode."
- [ ] Per-section user approval is required in both modes

---

### Case 5: Missing Input and Declined Skeleton

**Fixture:**
- `project.yaml` has `modes.workflow: standard` in every scenario — the systems index is required at this tier, so pointing at `/map-systems` is correct
- Scenario (a): no argument; `design/gdd/systems-index.md` lists `stamina` as the highest-priority "Not Started" system (MVP, Core layer)
- Scenario (b): no argument; no systems index
- Scenario (c): `/design-system stamina` with concept and index present; the user declines the skeleton

**Input:** (a) `/design-system` (b) `/design-system` (c) `/design-system stamina`

**Expected behavior:**
1. (a) `AskUserQuestion`: "The next system in your design order is **stamina** (MVP | Core). Start designing it?" with `[A] Yes — design stamina` / `[B] Pick a different system` / `[C] Stop here`
2. (b) The skill stops with the usage message ("Usage: `/design-system <system-name>` …"), the retrofit example, and "No systems index found. Run `/map-systems` first to map your systems and get the design order."
3. (c) The skill stops with: "Verdict: **BLOCKED** — skeleton creation declined. …" and does not proceed to Section A
4. In none of the three scenarios is a GDD file written before an approval

**Assertions:**
- [ ] (a) The next system is proposed from the systems index with the three options
- [ ] (b) The usage message and the `/map-systems` pointer are printed; nothing is written
- [ ] (c) Declining the skeleton produces the BLOCKED verdict and stops before Section A
- [ ] No GDD file is created without an approval

---

### Case 6: Minimal Project, One System Raised by `system_overrides`

**Fixture:**
- `project.yaml` has `modes.workflow: minimal`, `modes.review_mode: solo` and `workflow_overrides.system_overrides.combat: standard`
- `design/game-brief.md` exists; its MVP features describe combat (a damage rule and a stagger threshold), and its build order lists combat first
- No `design/gdd/game-concept.md`, no `design/gdd/systems-index.md`, no `design/gdd/combat.md`

**Input:** `/design-system combat`

**Expected behavior:**
1. The effective tier for combat is `standard` (the override); the project tier is `minimal`
2. §2a takes the `minimal` branch because it keys on the project tier: it reads `design/game-brief.md` and skips the systems-index read, and does not stop with "No game concept found" or "No systems index found"
3. It derives `Category`, `Layer` and `Priority` from the brief once (e.g. `Gameplay`, `Foundation` or `Feature`, `MVP`)
4. The skeleton and the section walk follow `standard`: A, C, D (combat defines numeric rules), E, F, H — no Player Fantasy or Tuning Knobs
5. §5-pre's Quick reference marks the derived values, e.g. "Category: Gameplay (inferred from the brief — no systems index at this tier)"
6. §5d says "no `design/gdd/systems-index.md` at this workflow tier; nothing to update" and writes no systems index

**Assertions:**
- [ ] The run reads the brief and does not stop for the missing concept or systems index
- [ ] The required section set is `standard`'s (the effective tier) — not the project tier's
- [ ] Category, Layer and Priority are derived from the brief and marked inferred in the Quick reference
- [ ] No systems index is created; §5d reports nothing to update

---

### Case 7: Phase Files Are Read Before Each Phase, and Again After a Compaction

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `modes.workflow: standard`, `modes.review_mode: solo`
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist; `stamina` is listed with `Category: Gameplay`; no `design/gdd/stamina.md`
- The skill folder holds `references/1-parse-arguments.md` through `references/5-post-design.md`
- Mid-run, while Section D (Formulas) is being drafted, the conversation is compacted; the user then replies to the open question and the run continues

**Input:** `/design-system stamina`

**Expected behavior:**
1. SKILL.md carries no phase steps itself; before starting each phase the run reads that phase's file: `references/1-parse-arguments.md`, then `2-gather-context.md`, then `3-file-skeleton.md`, then `4-section-design.md`, then `5-post-design.md`
2. No phase's steps are carried out before its file has been read — e.g. no context read or question before `1-parse-arguments.md`, no skeleton ask before `3-file-skeleton.md`, no section cycle before `4-section-design.md`
3. After the compaction the run reads `references/4-section-design.md` again before resuming Section D, as the skill says: "Read it again if the conversation was compacted or resumed during this phase."
4. The run does not re-read the phase files of other phases because of the compaction, and it does not continue Section D from memory of the earlier read
5. The run then reads `references/5-post-design.md` before the Summary and self-check

**Assertions:**
- [ ] The transcript shows a file read of each of the five `references/N-*.md` files, in order, each before that phase's work begins
- [ ] No phase work (context reads, skeleton ask, section drafts, Summary) happens before its phase file is read
- [ ] After the compaction, `references/4-section-design.md` is read again before Section D resumes
- [ ] Settings resolved in SKILL.md (`workflow`, `review_mode`, `automation`, `docs.density`) still apply in the phase files; the run does not ask for them again

---

### Case 8: Populated Registry and Numbered-Heading Dependency GDDs — Block-form greps find the facts

**Fixture:**
- `project.yaml` has `engine.name: Godot`, `modes.workflow: standard`, `modes.review_mode: solo`
- `design/gdd/game-concept.md` and `design/gdd/systems-index.md` exist; `stamina` is listed with `Category: Gameplay` and `Depends on: combat`
- `design/registry/entities.yaml` has a live `constants:` list with two entries:
  - `- name: stagger_threshold` with `value: 40` and `source: design/gdd/combat.md` (owned by combat)
  - `- name: stamina_cost_dodge` with `value: 25`, `source: design/gdd/stamina.md`, and a block-form `referenced_by:` list (the key on one line, `- design/gdd/combat.md` on the next)
- The same file's header comments hold an example entry for `gold_carry_limit: 9999` referencing `design/gdd/inventory.md`
- `design/gdd/combat.md` exists with numbered headings: `## 1. Overview`, `## 3. Detailed Design`, `## 4. Formulas`, `## 5. Edge Cases`, `## 6. Dependencies`, `## 7. Tuning Knobs`; its Formulas section uses `stagger_threshold` and its Tuning Knobs section lists it
- No `design/gdd/stamina.md`

**Input:** `/design-system stamina`

**Expected behavior:**
1. Registry lookups use two greps: one for `source: design/gdd/stamina.md` with trailing context (`-A 6`) and one for `design/gdd/stamina.md` with leading context (`-B 8`); the `-B 8` match reaches the owning entry above the `referenced_by` path, so `stamina_cost_dodge` is found as owned by stamina and `stagger_threshold` as a fact stamina must respect
2. A single-line `referenced_by.*stamina` pattern is not relied on, because the list is block-form
3. For the dependency GDD `combat.md`, the run greps `^## ([0-9]+\. )?(Dependencies|Formulas|Edge Cases|Tuning Knobs)` so the numbered headings `## 4. Formulas`, `## 5. Edge Cases`, `## 6. Dependencies` and `## 7. Tuning Knobs` all match; the whole GDD is not read
4. The context summary's "Known cross-system facts (from registry)" lists `stamina_cost_dodge=25` and `stagger_threshold=40` with their owning GDDs, marked locked
5. The commented `gold_carry_limit: 9999` example is not listed as a known fact

**Assertions:**
- [ ] The registry is searched for `source: design/gdd/stamina.md` and for the path with `-B 8` context, not only with a one-line `referenced_by` pattern
- [ ] `stamina_cost_dodge` (found through its `source:` and its block-form `referenced_by:`) and `stagger_threshold` appear under Known cross-system facts with their values and owners
- [ ] The dependency GDD's sections are found despite their `N.` heading numbers — all four of Dependencies, Formulas, Edge Cases and Tuning Knobs are read
- [ ] `combat.md` is read by section, not whole
- [ ] The commented `gold_carry_limit` example is not presented as a locked value

---

## Protocol Compliance

- [ ] Reads context before asking anything; stops with the `/brainstorm` or `/map-systems` message when the game concept or systems index is missing on a `standard`/`full` project (a `minimal` project reads the brief instead, even for a system `system_overrides` raises)
- [ ] The skeleton is created only after "May I create the skeleton file at `design/gdd/[system-name].md`?"
- [ ] In collaborative mode every section draft is followed by its approval widget, and no section is written without approval
- [ ] Sections are written incrementally, and `production/session-state/active.md` is updated after each
- [ ] Specialist steps follow the per-section review-mode checks; no agent is ever spawned; every skipped step leaves a "not consulted" note naming the agent and the mode, in lean as in solo
- [ ] CD-GDD-ALIGN runs once in full mode after all sections; lean and solo print a skip note naming the gate and mode
- [ ] `/design-review` is directed to a fresh session and never run or offered inline
- [ ] Reads each phase's `references/N-*.md` file before doing that phase, and again after a compaction or resume during it
- [ ] Ends with a next-step `AskUserQuestion` and Recommended Next Steps (`/consistency-check`, `/map-systems next`, `/design-review` in a fresh session)

---

## Coverage Notes

- `guided` and `autonomous` automation modes (write without the per-section
  widget; `log_decision` in autonomous) are not fixture-tested.
- A voluntary GDD on a `minimal` project with no override (the 5 standard
  sections from `design/game-brief.md`, Formulas never pulled back in) is not
  fixture-tested; Case 6 covers a `minimal` project whose system an override
  raises. The no-argument prompt on a `minimal` project, where no systems index
  exists by design, is not tested either.
- The registry conflict check after Sections C and D, and the Step 5b entity
  registry update, are not individually tested.
- The Step 5d systems index update and the context-window (≥70%) notice are not
  tested.
- Recovery and resume after an interrupted session is not tested.
