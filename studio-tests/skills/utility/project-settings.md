# Skill Test Spec: /project-settings

## Skill Summary

`/project-settings` shows and changes project configuration. It has four forms:
`/project-settings` (view-all: every effective setting with its source), `/project-settings
<key>` (view-one), `/project-settings <key>=<value>` (write to `project.yaml`) and
`/project-settings --local <key>=<value>` (write a personal override to the gitignored
`project.local.yaml`). Anything else, including an empty key or value, prints
the usage block. It runs on the Sonnet model and reads every value through
`yaml-helper.sh` (`resolve_setting`, `get_yaml_key`, `is_locally_overridable`,
`validate_enum_value`), so a value the `modes.rigor` preset supplies is shown as
`(derived from rigor: <level>)` rather than "(not set)".

Every write is validated against the schema enums first, then confirmed with an
`AskUserQuestion` approval gate (`[A] Yes, write` / `[B] No, cancel`). A
`project.yaml` write is a `schema_changes` decision, so it is confirmed even in
`autonomous` mode. `--local` refuses a key that is not on the local-override
whitelist. A setting that `.claude/docs/effects-map.md` marks with a
`> ### RESERVED` banner is stored when asked, but every form says nothing reads
it. The skill gives no verdict: it prints and writes configuration. No director
gates apply.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] No verdict keyword is required: the output is configuration, not a judgement (`/skill-test static` Check 3 gives a WARN, never a FAIL, for this skill)
- [ ] Both write phases ask for approval with `AskUserQuestion` before the `Edit` or `Write`
- [ ] The reserved set is derived from `effects-map.md`'s `> ### RESERVED` headings, not hardcoded
- [ ] Points to `.claude/docs/settings-guidance.md` for which value to choose

---

## Director Gate Checks

None. `/project-settings` is a configuration utility. No director gates apply.

---

## Fixture Defaults

Every case's `project.yaml` sets `modes.rigor: minimal` and
`modes.automation: collaborative`, with no `project.local.yaml`, unless its own
Fixture says otherwise. Rules: `studio-tests/CLAUDE.md` §
Fixture defaults.

---

## Test Cases

### Case 1: Happy Path — view-all shows derived values, a local override and the legend

**Fixture:**
- `project.yaml`:
  ```yaml
  framework:
    version: 1.3.0
  modes:
    rigor: full
    automation: collaborative
  docs:
    density: terse
  engine:
    name: Godot
  ```
- `project.local.yaml`:
  ```yaml
  modes:
    automation: autonomous
  ```

**Input:** `/project-settings`

**Expected behavior:**
1. Reports both files present and `Schema validation: ok`
2. Lists every file leaf, then appends the rigor family the files do not set:
   `modes.workflow`, `qa.level`, `modes.story_granularity`, `modes.review_mode`
   and `team.size`, each annotated `(derived from rigor: full, …)`
3. `docs.density: terse` is annotated `(project.yaml, locked)` — the explicit
   value wins over the `thorough` that `rigor: full` would supply
4. `modes.automation: autonomous` is annotated
   `(LOCAL OVERRIDE — yaml has: collaborative)`
5. Leaves are grouped by top-level section (`modes:`, `docs:`, `qa:`, …), not
   by the file they came from
6. Below the block, the two-line legend: `locked` means it cannot be overridden
   in `project.local.yaml`, and does not mean fixed
7. No file is written

**Assertions:**
- [ ] All five rigor-derived knobs appear with real values, none as "(not set)"
- [ ] The explicit `docs.density` shows its own value and source, not the preset's
- [ ] The local override names the `project.yaml` value it shadows
- [ ] The `locked` legend is printed, and says a derived value can still be set explicitly
- [ ] Nothing is written

---

### Case 2: View-one — a rigor-derived key says how to set it

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` and no `qa.level`

**Input:** `/project-settings qa.level`

**Expected behavior:**
1. Prints `Effective value: standard` and `Source: derived from rigor: standard`
2. Adds the line `Set explicitly with: /project-settings qa.level=<value>   (an explicit value wins over rigor)`
3. `Locally overridden: no`; the whitelist line reads `locked — project-wide`

**Assertions:**
- [ ] The value comes from the rigor expansion, not "(not set)"
- [ ] The "Set explicitly with" line is shown for a derived value
- [ ] Nothing is written

---

### Case 3: Set-yaml — changing `modes.rigor` reports the six knobs it moves

**Fixture:**
- `project.yaml`:
  ```yaml
  modes:
    rigor: minimal
    automation: collaborative
  docs:
    density: thorough
  ```
- The user answers `[A] Yes, write`

**Input:** `/project-settings modes.rigor=standard`

**Expected behavior:**
1. `validate_enum_value modes.rigor standard` passes
2. `AskUserQuestion` asks ``Set `modes.rigor=standard` in `project.yaml`?``
   with `[A] Yes, write` / `[B] No, cancel`
3. The `Edit` anchors on the `modes:` line plus the `rigor: minimal` line and
   changes only that value; no second `modes:` block is added
4. Confirms ``Set `modes.rigor=standard` in `project.yaml`.`` and lists what
   the six knobs resolve to now, re-read with `resolve_setting`:
   `modes.workflow: standard`, `qa.level: standard`,
   `modes.story_granularity: balanced`, `modes.review_mode: lean`,
   `team.size: individual` (each derived from rigor: standard) and
   `docs.density: thorough` (`project.yaml` — explicit, unchanged)

**Assertions:**
- [ ] Approval is asked before the file is edited
- [ ] `project.yaml` still has exactly one `modes:` block, with `rigor: standard`
- [ ] The six-knob list shows the explicit `docs.density` as unchanged, not as `balanced`
- [ ] No other line of `project.yaml` changes

---

### Case 4: Invalid value — rejected before any question

**Fixture:**
- `project.yaml` sets `modes.review_mode: lean`

**Input:** `/project-settings modes.review_mode=chaotic`

**Expected behavior:**
1. `validate_enum_value` returns 1; its message is shown verbatim:
   `Invalid value 'chaotic' for 'modes.review_mode'. Allowed: ...`
2. The skill exits: no approval question, no write

**Assertions:**
- [ ] The helper's error line is shown as it is, naming the allowed values
- [ ] No `AskUserQuestion` is asked
- [ ] `project.yaml` is unchanged

---

### Case 5: `--local` on a locked key — refused with the team-wide route

**Fixture:**
- `project.yaml` sets `engine.name: Godot`; no `project.local.yaml`

**Input:** `/project-settings --local engine.name=Unity`

**Expected behavior:**
1. `is_locally_overridable engine.name` returns 1
2. One line: ``engine.name cannot be locally overridden — it's a project-wide setting. Use `/project-settings engine.name=Unity` (no `--local`) to change it for the whole team.``
3. The skill exits without writing

**Assertions:**
- [ ] The refusal names the `/project-settings <key>=<value>` route
- [ ] No approval question is asked
- [ ] No `project.local.yaml` is created

---

### Case 6: `--local` on a whitelisted key — creates the override file

**Fixture:**
- `project.yaml` exists with `modes.automation: collaborative`; no
  `project.local.yaml`
- The user answers `[A] Yes, write`

**Input:** `/project-settings --local modes.automation=autonomous`

**Expected behavior:**
1. The whitelist and enum checks pass
2. `AskUserQuestion` asks ``Set `modes.automation=autonomous` in `project.local.yaml` (your personal override, gitignored)?``
3. `project.local.yaml` is created with the value inside its `modes:` parent
   block
4. Confirms ``Set `modes.automation=autonomous` in `project.local.yaml` (your override).``

**Assertions:**
- [ ] Approval is asked before the file is created
- [ ] The new file nests the key under `modes:`, not as a dotted top-level line
- [ ] `project.yaml` is unchanged

---

### Case 7: Reserved setting — stored on request, flagged on every form

**Fixture:**
- `.claude/docs/effects-map.md` is the live file; pick a key whose section
  carries the `> ### RESERVED` banner (`accessibility.target` when this spec
  was written — re-derive it with the skill's own grep)
- `project.yaml` does not set that key; the user answers `[A] Yes, write`

**Input:** `/project-settings accessibility.target=standard`, then `/project-settings`, then
`/project-settings accessibility.target`

**Expected behavior:**
1. The write prints, before the approval question: "Note: `accessibility.target`
   is RESERVED — no skill or hook reads it, so setting it will not change any
   behaviour. Your value is stored either way."
2. On yes the value is written — the skill never refuses a reserved key
3. View-all annotates the leaf with `, reserved` and prints the reserved legend
   below the block
4. View-one prints "**`accessibility.target` is RESERVED — nothing reads it.**"
   above the value block, not under it

**Assertions:**
- [ ] The warning comes before the approval question
- [ ] The value is written after a yes
- [ ] View-all and view-one both mark the key reserved
- [ ] A key that only mentions the banner in prose (`platform.cert_tier`) is not marked reserved

---

### Case 8: Shadowed write and autonomous mode — still asked, with the shadow named

**Fixture:**
- `project.yaml` sets `modes.review_mode: lean` and `modes.automation: autonomous`
- `project.local.yaml` sets `modes.review_mode: solo`
- The user answers `[A] Yes, write`

**Input:** `/project-settings modes.review_mode=full`

**Expected behavior:**
1. Before the approval question: "Note: this setting is currently locally
   overridden in `project.local.yaml` (value: `solo`). Writing to `project.yaml`
   will not change your effective value."
2. The approval question is asked even though `modes.automation` is
   `autonomous`: a `project.yaml` write is a `schema_changes` decision, which is
   on the default always-ask list
3. `project.yaml` gets `review_mode: full`; `project.local.yaml` is unchanged

**Assertions:**
- [ ] The shadow note names the local value and comes before the question
- [ ] Autonomous mode does not skip the approval question
- [ ] Only `project.yaml` is edited

---

### Case 9: Malformed operand — usage, no write

**Fixture:**
- `project.yaml` exists

**Input:** `/project-settings --local modes.automation=` (and, separately,
`/project-settings =full`)

**Expected behavior:**
1. The empty value (or empty key) routes to Phase 6
2. The usage block is printed with its four forms and three examples
3. Nothing is validated, asked or written

**Assertions:**
- [ ] Both inputs print the usage block
- [ ] No approval question is asked and no file changes

---

## Protocol Compliance

- [ ] Every write is preceded by an `AskUserQuestion` approval gate; `[B] No, cancel` leaves both files unchanged
- [ ] Values are validated with `validate_enum_value` before the approval question
- [ ] Values are read with `resolve_setting`, so derived values show with their rigor source
- [ ] `--local` writes only whitelisted keys, and never creates `project.local.yaml` without a `project.yaml`
- [ ] Reserved keys are flagged on view-all, view-one and both write paths
- [ ] Every helper call runs from the project root in the same Bash command that sources `yaml-helper.sh`

---

## Coverage Notes

- View-all with schema errors in one or both files, Phase 4's Case D (no clean
  insertion point) and a session started in a subfolder are not separately
  fixture-tested.
- The missing-`project.yaml` stops (view-all, and `--local` with no base file)
  and a missing `yaml-helper.sh` are not separately fixture-tested.
