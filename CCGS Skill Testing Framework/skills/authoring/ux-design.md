# Skill Test Spec: /ux-design

## Skill Summary

`/ux-design` authors UX documents section by section. The argument picks the
mode and output file: `hud` → `design/ux/hud.md`; `patterns` →
`design/ux/interaction-patterns.md`; `accessibility` →
`design/accessibility-requirements.md` (the only mode that writes outside
`design/ux/`); any other value → a screen/flow spec at `design/ux/[kebab-name].md`.
With no argument it asks "What are we designing today?" instead of failing.

Phase 2 reads context before asking anything: the game concept (or game brief),
the player journey, GDD UI Requirements, existing UX specs, the pattern library
catalog, the art bible, accessibility requirements, and the input methods from
the `project.yaml` `platform` block. If the output file already exists, the
skill enters retrofit mode and fills only Empty or Placeholder sections.
Otherwise it asks "May I create the skeleton file at [path]?" and writes the
mode's skeleton.

Each section then runs Context → Questions → Options → Decision → Draft →
Approval → Write: "Does this capture the [section name] correctly?", then "May I
write the [section name] section to `[filepath]`?", then an Edit replacing the
placeholder. Of the per-mode guidance files, only the active mode's is loaded,
and a template guide is read one section at a time. After a
cross-reference check, the handoff says the spec must pass `/ux-review` and
ends with verdict `COMPLETE`. There are no director gates.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: `COMPLETE`
- [ ] Contains "May I write" language per section, and "May I create" for the skeleton
- [ ] Has a next-step handoff (`/ux-review` to validate the completed spec)
- [ ] Documents the four modes and their output paths, including `design/accessibility-requirements.md` for `accessibility`

---

## Director Gate Checks

None. `/ux-design` resolves only `automation`, `workflow` and `docs.density`
(not `review_mode`) and spawns no director gate. `/ux-review` is the separate
validation step. Specialists (`art-director`, `ui-programmer`, `game-designer`,
`narrative-director`) may be consulted for sub-topics; their output is presented
to the user, and this session owns every file write.

---

## Test Cases

### Case 1: Happy Path — New HUD design

**Fixture:**
- No `design/ux/hud.md`
- `design/gdd/combat.md` and `design/gdd/stamina.md` have `## UI Requirements` sections; `design/gdd/save-system.md` has none
- `project.yaml` has a `platform` block (`targets: [PC]`, `gamepad_support: Full`)
- `design/gdd/game-concept.md` and `design/player-journey.md` exist

**Input:** `/ux-design hud`

**Expected behavior:**
1. Mode is HUD design; output file `design/ux/hud.md`
2. UI Requirements are collected with one Grep across `design/gdd/*.md`; the skill counts the three system GDDs — `game-concept.md` sits in `design/gdd/` but is not one — lists `save-system.md` as unmatched, and confirms with the user it is headless before excluding it
3. Input methods are derived from the `platform` block (keyboard/mouse and gamepad) — the user is not asked
4. The context summary is shown, then "Anything else I should read before we start, or shall we proceed?"
5. No existing file, so: "May I create the skeleton file at `design/ux/hud.md`?" — on yes, writes the HUD skeleton and updates `production/session-state/active.md`. The skeleton carries every section `/ux-review`'s HUD checklist requires, so the finished spec can pass that review
6. Phase 4 reads `.claude/skills/ux-design/references/sections-hud.md` and never the other two per-mode files (`sections-ux-spec.md`, `sections-patterns.md`); if a section needs depth, the HUD design guide is read one section at a time, never whole
7. Each section: draft → "Does this capture the [section name] correctly?" → "May I write the [section name] section to `design/ux/hud.md`?" → Edit replacing that section's placeholder
8. Phase 5 presents the Cross-Reference Check results
9. Phase 6 states the spec should be validated with `/ux-review` before implementation, then asks with four options (run `/ux-review` now / design another screen / update the pattern library / stop); verdict `COMPLETE`

**Assertions:**
- [ ] A GDD without a UI Requirements section is listed and confirmed with the user, not silently excluded
- [ ] `game-concept.md` is not counted as a system GDD, so it is not listed as unmatched
- [ ] Input methods come from the `project.yaml` `platform` block, without asking the user
- [ ] The skeleton is written only after the "May I create the skeleton file at `design/ux/hud.md`?" approval
- [ ] The HUD skeleton includes the sections `/ux-review` Phase 3B checks for: HUD Philosophy, Information Architecture, Layout Zones, HUD element specifications, HUD States by Gameplay Context, Information Hierarchy, Visual Budget, Feedback & Notification Systems, Platform Adaptation, Tuning Knobs, Acceptance Criteria
- [ ] Of the three per-mode guidance files only `sections-hud.md` is loaded, and no guide is read whole
- [ ] Each section is approved and then gets its own "May I write the [section name] section…" ask before it is written
- [ ] The handoff names `/ux-review` as required before implementation, and the verdict is `COMPLETE`

---

### Case 2: Existing Document — Retrofit of incomplete sections only

**Fixture:**
- Scenario (a): `design/ux/main-menu.md` exists, built from the UX spec skeleton; Purpose & Player Need, Player Context on Arrival, Navigation Position and Entry & Exit Points have real content; every other section is `[To be designed]`
- Scenario (b): `design/accessibility-requirements.md` exists, built from the accessibility skeleton; Accessibility Tier Definition commits the Standard tier; every other section is `[To be designed]`

**Input:** (a) `/ux-design main-menu` (b) `/ux-design accessibility`

**Expected behavior:**
1. Before any skeleton step, the skill Globs the output path — in (b) `design/accessibility-requirements.md`, not a path under `design/ux/` — and finds the file
2. It reads the file, classifies each section as Complete / Empty / Placeholder, and shows the status table, ending "I'll work on the [N] incomplete sections only — existing content will not be overwritten."
3. Skeleton creation is skipped
4. Phase 4 authors only the Empty/Placeholder sections, filling each placeholder in place with Edit after its "May I write" approval
5. (a) The four complete sections are not changed; (b) the committed tier is not changed

**Assertions:**
- [ ] The existing file is detected and no skeleton is written
- [ ] The status table and the "incomplete sections only" message are shown before authoring
- [ ] Only Empty or Placeholder sections are authored; complete sections are not overwritten
- [ ] Each filled section is written with Edit after its own "May I write" approval
- [ ] (a) The status table rows use the section names of the UX spec skeleton (e.g., `Purpose & Player Need`, `Layout Specification`, `States & Variants`, `Input Method Completeness Checklist`)
- [ ] (b) The status table rows use the accessibility skeleton's section names (e.g., `Accessibility Tier Definition`, `Visual Accessibility`, `Motor Accessibility`), and the file stays at `design/accessibility-requirements.md`

---

### Case 3: Missing Context — No game concept and no player journey

**Fixture:**
- No `design/gdd/game-concept.md` and no `design/game-brief.md`
- No `design/player-journey.md`
- No `design/ux/inventory.md`

**Input:** `/ux-design inventory`

**Expected behavior:**
1. The skill warns: "No game concept found. Run `/brainstorm` first to establish the game's foundation before designing UX." and continues only if the user asks
2. It notes the missing journey: "No player journey map found at `design/player-journey.md`. Designing without it means we'll be making assumptions about player context…"
3. The context summary shows "Journey phase(s): unknown — no journey map"
4. The spec's Open Questions section records: "Player journey map not yet created. Author it from the template at `.claude/docs/templates/player-journey.md`…"
5. The skill never tells the user to run `/ux-design` Phase 2b to create the journey map

**Assertions:**
- [ ] The missing concept produces the `/brainstorm` warning, and the skill proceeds only on the user's say-so
- [ ] The missing player journey is noted in the conversation and recorded in Open Questions with the template path
- [ ] The remediation points at the template, never back at `/ux-design`
- [ ] The context summary marks the journey phase as unknown

---

### Case 4: No Argument Provided — Ask instead of failing

**Fixture:**
- No argument
- Neither `design/ux/main-menu.md` nor `design/accessibility-requirements.md` exists, so both scenarios author fresh files
- Scenario (a): the user types "Main Menu"
- Scenario (b): the user picks "The project-wide accessibility requirements"

**Input:** `/ux-design`

**Expected behavior:**
1. The skill does not fail; it asks "What are we designing today?" with: "A specific screen or flow (I'll name it)", "The game HUD", "The interaction pattern library", "The project-wide accessibility requirements", "I'm not sure — help me figure it out"
2. (a) The name is normalized to kebab-case; the output file is `design/ux/main-menu.md`
3. (b) The output file is `design/accessibility-requirements.md`, and the skeleton ask names that path, not a path under `design/ux/`
4. (b) The Accessibility Tier Definition section is authored first
5. No file is created before the skeleton approval

**Assertions:**
- [ ] No usage error; the "What are we designing today?" question is asked with the five options
- [ ] (a) A typed screen name becomes a kebab-case filename under `design/ux/`
- [ ] (b) Accessibility mode writes to `design/accessibility-requirements.md`
- [ ] (b) The tier definition is authored before the other accessibility sections
- [ ] No file is written before the skeleton approval

---

### Case 5: No Director Gate — `/ux-review` is the separate review

**Fixture:**
- `project.yaml` has `modes.review_mode: full` and a `platform` block (`targets: [PC, Console]`, `gamepad_support: Full`)
- No `design/ux/settings-menu.md`

**Input:** `/ux-design settings-menu`

**Expected behavior:**
1. The skill authors the screen spec as usual; the review mode is not resolved and nothing branches on it
2. The UX spec skeleton's header carries `> **Platform Target**:` filled from Phase 2h — PC and Console, keyboard/mouse and gamepad — the line `/ux-review` checks for
3. No director gate agent is spawned, and no gate ID or skip note appears
4. If a specialist is consulted (e.g., `ui-programmer` on feasibility), its output is shown to the user, and the session — not the agent — writes the file
5. The run ends with the `/ux-review` statement and verdict `COMPLETE`

**Assertions:**
- [ ] The skeleton header's Platform Target line names the targets and input methods from the `platform` block
- [ ] No director gate is invoked and no gate skip messages appear
- [ ] `modes.review_mode: full` does not change the skill's behavior
- [ ] Specialist output is presented to the user; agents never write files
- [ ] The verdict is `COMPLETE`, with `/ux-review` named as the validation step

---

## Protocol Compliance

- [ ] Once the mode is known — with no argument, the mode question comes first (Case 4) — reads context before asking the user anything else
- [ ] Checks for an existing output file before creating a skeleton; retrofit fills only Empty or Placeholder sections
- [ ] The skeleton is created only after "May I create the skeleton file at [path]?"
- [ ] Sections are drafted one at a time; each is approved, then "May I write the [section name] section to `[filepath]`?" is asked before the write
- [ ] Loads the per-mode guidance file for the active mode and never the other two; a template guide is read one section at a time, never whole
- [ ] Ends with the `/ux-review` handoff and verdict `COMPLETE`

---

## Coverage Notes

- Pattern-library mode (`patterns`) is not fixture-tested.
- The input-methods question when neither `project.yaml` nor
  `technical-preferences.md` configures the platform is not tested.
- The Phase 5 prompt for a pattern not yet in the pattern library is not
  individually tested.
- `guided` and `autonomous` automation modes, `docs.density` depth, and
  recovery after an interrupted session are not tested.
