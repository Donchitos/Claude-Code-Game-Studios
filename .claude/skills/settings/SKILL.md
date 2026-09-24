---
name: settings
description: "View or change project config — effective merged values, or set locally in project.local.yaml."
argument-hint: "[key | key=value | --local key=value]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion
model: sonnet
---

# /settings — view or change project config

Manages `project.yaml` (team-wide config, committed) and `project.local.yaml`
(per-developer overrides, gitignored). Use this skill to inspect current
settings or change them without manually editing YAML.

**Automation mode**: Resolve `modes.automation` (`project.local.yaml` →
`project.yaml` → default `collaborative`). The approval gates in Phase 4 and
Phase 5 follow the pattern in `.claude/docs/automation-modes.md`. **Note**:
writing to `project.yaml` is a `schema_changes` decision (a default
`automation_always_ask` category), so `/settings` confirms config writes even
in `autonomous` mode unless the user has removed `schema_changes` from their
always-ask list.

## Phase 0: Parse Arguments

Determine which of the four forms the user invoked:

| Form | Mode |
|------|------|
| `/settings` (no args) | **View-all** (Phase 2) |
| `/settings <key>` (single arg, no `=`) | **View-one** (Phase 3) |
| `/settings <key>=<value>` (single arg with `=`) | **Set-yaml** (Phase 4) |
| `/settings --local <key>=<value>` (`--local` prefix) | **Set-local** (Phase 5) |

For Set-yaml and Set-local, `<key>` is a dotted YAML path (e.g.
`modes.review_mode`, `testing.strict.logic`) and `<value>` is the new value.

**Empty-operand validation:** After splitting the `key=value` operand on
`=`, if either `<key>` or `<value>` is empty, this is malformed — route to
Phase 6 (usage) rather than attempting the write. The rule applies in both
Set-yaml and Set-local routing: for `--local`, strip the `--local` token
first, then check the remaining operand the same way (so `/settings --local =foo`
and `/settings --local key=` both go to Phase 6).

Anything else that doesn't match the four forms above → Phase 6 (usage).

## Phase 1: Load Helper

All four subcommands need `yaml-helper.sh`. Source it once via Bash:

```bash
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/yaml-helper.sh"
```

If `.claude/hooks/yaml-helper.sh` is missing, this is not a CCGS project.
Report the error and exit.

## Phase 1b: Reserved-setting detection

Some settings are fully documented, enum-validated and settable, and **no skill
or hook reads them** — setting one changes nothing. **This skill must say so.**
Returning an ordinary success lets a user reasonably believe the behaviour the
setting describes is now enforced — an accessibility tier being the case that
motivates this. (The key is not named here on purpose; see the note below.)
The banner exists only in
`.claude/docs/effects-map.md`, which someone
configuring their project will never open. A setting that does nothing must never look
exactly like one that works — `.claude/rules/skill-authoring.md` obligation 3.

Derive the set; do not hardcode it (obligation 5):

```bash
grep -B14 '^> ### RESERVED' .claude/docs/effects-map.md | grep -E '^## '
```

**Match the banner HEADING (`> ### RESERVED`), never the bare word "RESERVED".**
`platform.cert_tier`'s section *mentions* the banner in prose, to record that it
carried one and later became a live setting. A looser match re-reports a working
setting as dead — the direction that understates what the framework does, and
why the dead-settings gate asserts both directions.

A heading may name **two keys joined by " and "** — split on that separator so
both are captured, or the second one silently escapes the set. Let
`RESERVED_SET` be the result.

> Deliberately phrased without naming those keys. The dead-settings gate asserts
> that a setting on the allowlist has **no** readers, and it counts any skill
> file that spells the key. Naming them here to illustrate the split would make
> `/settings` register as a reader of two settings nothing reads, and the gate
> would fail — correctly. Spelling a dead path out while explaining why not to
> use it trips the same wire. Reword instead of adding an exemption: the
> strictness is the point, so do not re-introduce the literal names to make an
> example clearer.

Never refuse a write to a reserved key. Storing the value a user intends is
legitimate; storing it *silently* is the defect.

## Phase 2: View-all Mode

(when no arguments)

1. Confirm `project.yaml` exists. If missing, report:
   > "No `project.yaml` found — run `/start` to create one."
   And exit.

2. Check if `project.local.yaml` exists.

3. Run `validate_yaml_enum project.yaml` and capture any errors.
   If `project.local.yaml` exists, also run `validate_yaml_enum project.local.yaml`.
   Tag each error with its source file so the user can tell them apart.

4. **Enumerate leaves.** Use the `Read` tool to read both YAML files as
   text. Walk through each file's structure and collect every leaf key
   into a deduplicated list of dotted paths. A leaf is a `key: value`
   line whose value is non-empty (a scalar or inline-array) — NOT a
   parent block that introduces a nested map. Maintain insertion order
   per file; merge by appending leaves from `project.local.yaml` that
   aren't already present from `project.yaml`. The resulting list is
   the set of leaves to display.

   **Then append the rigor family** — `modes.rigor`, `modes.workflow`,
   `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`,
   `team.size` — for any of the seven the merged list does not already
   contain. These are normally leaves of neither file: `modes.rigor` has a
   terminal default and the other six are supplied by the rigor expansion
   (`modes.review_mode` and `team.size` may also appear as file leaves when set
   locally, but must still be appended so their *derived* value shows). Enumerating
   only file leaves would hide exactly the settings a user just chose, in the one
   view meant to show them.

5. **For each leaf**, perform three reads and one check:
   - `resolve_setting <path>` → `<value>`, TAB, `<source>`. This walks the
     whole chain (`project.local.yaml` → `project.yaml` → legacy file →
     `rigor` expansion → default), so it is the only read that can report
     a derived value or name what supplied it.
   - `get_yaml_key project.yaml <path>` → yaml-only value (needed only to
     show what a local override is shadowing)
   - `is_locally_overridable <path>` → 0 (overridable) or 1 (locked)

   Compute the **source annotation** from `<source>`:

   | `<source>` | Annotation |
   |---|---|
   | `project.local.yaml`, yaml-only value non-empty | `(LOCAL OVERRIDE — yaml has: <yamlvalue>)` |
   | `project.local.yaml`, yaml-only value empty | `(project.local.yaml)` |
   | `project.yaml` | `(project.yaml)` |
   | a legacy file path (e.g. `production/review-mode.txt`) | `(<path>, legacy)` |
   | `rigor:<level>` | `(derived from rigor: <level>)` |
   | `default` | `(default)` |
   | `unset` | skip the leaf (don't print unset keys) |

   Append `, locked` to the annotation when `is_locally_overridable`
   returned 1.

   **Append `, reserved` when the leaf is in `RESERVED_SET` (Phase 1b)**, and
   print this line with the legend below the block:

   ```
   reserved = stored and validated, but nothing reads it. Setting it changes
   no behaviour today.
   ```

   > **All four phases must carry the reserved marking — view-one, view-all,
   > and both write paths.** Marking view-one and the writes while leaving
   > view-all — **the most-used form of this skill** — unmarked means a user who
   > set a reserved key sees it listed beside working settings with an ordinary
   > `(project.yaml)` annotation, in the view most people actually run. Guard
   > all four: view-one and view-all are twins in exactly the way the two write
   > paths are.

6. **Print**, grouped by top-level section (`framework`, `modes`,
   `engine`, etc.) in the order leaves first appeared. The grouping is
   determined by the dotted path, not by which file the leaf came from
   — e.g. `modes.automation` groups under `modes:` even if only
   `project.local.yaml` defines it. Within each section, indent leaves
   by 2 spaces; nest further for sub-blocks (e.g. `testing.strict.*`).
   Example output:

```
project.yaml: present
project.local.yaml: present

Schema validation: ok

Effective config:

framework:
  version: 1.1.1            (project.yaml, locked)

modes:
  review_mode: lean         (project.yaml)
  automation: autonomous    (LOCAL OVERRIDE — yaml has: collaborative)
  rigor: full               (project.yaml, locked)
  workflow: full            (derived from rigor: full, locked)
  story_granularity: fine   (derived from rigor: full, locked)

docs:
  density: terse            (project.yaml, locked)

qa:
  level: full               (derived from rigor: full, locked)

engine:
  name: Godot               (project.yaml, locked)
  version: 4.6              (project.yaml, locked)

testing:
  strict:
    logic: false            (LOCAL OVERRIDE — yaml has: true)
    integration: true       (project.yaml)

locked = cannot be overridden in project.local.yaml (project-wide setting).
It does NOT mean fixed: a derived value can still be set explicitly with
/settings <key>=<value>, and an explicit value wins over rigor.
```

Print that two-line legend after the config block whenever any rendered
line carries `locked`. Without it users read `locked` as "immutable" and
conclude a rigor-derived knob cannot be changed — the opposite of what
Phase 3's view-one tells them for the same knob ("an explicit value wins
over rigor"). The two views must not leave contradictory impressions of
the same knob's mutability.

The `docs.density` line above is the precedence rule made visible: an
explicit `project.yaml` value keeps winning over the level `rigor` would
otherwise derive, so "comprehensive but compact" stays expressible.

If schema errors exist, print them in this form before the effective
config block:

```
Schema validation: ERRORS
  [project.yaml] modes.review_mode: 'chaotic' is not a valid value (expected: full|lean|solo)
  [project.local.yaml] engine.name: 'Pygame' is not a valid value (expected: Godot|Unity|Unreal)
```

## Phase 3: View-one Mode

(when single arg, no `=`)

**If `<key>` is in `RESERVED_SET`, print this BEFORE the value block** — above,
not below. A caveat under a value reads as a footnote on a working setting:

> **`<key>` is RESERVED — nothing reads it.** The value below is stored and
> validated; it changes no behaviour today.

Let `<key>` be the argument. Perform four reads:

1. `resolve_setting <key>` → `<value>`, TAB, `<source>` (effective value + provenance)
2. `get_yaml_key project.yaml <key>` → yaml-only value
3. `get_yaml_key project.local.yaml <key>` → local-only value (skip if file absent)
4. `is_locally_overridable <key>` → 0 (overridable) or 1 (locked)

Determine the **source** from `<source>` (same table as Phase 2 step 5)
and the **Locally overridden** status:
- `yes` if the local-only value is non-empty
- `no` otherwise

Print:

```
<key>

  Effective value: <effective-value or "(not set)" if <source> is unset>
  Source: <project.yaml | project.local.yaml | project.local.yaml (overrides project.yaml) | derived from rigor: <level> | default>
  Locally overridden: <yes | no>
  Whitelist: <"can be locally overridden" if is_locally_overridable returned 0, else "locked — project-wide">
```

When both files set the key (the LOCAL OVERRIDE case), add two more
lines under Source:

```
  project.yaml value: <yamlvalue>
  project.local.yaml value: <localvalue>
```

When `<source>` is `rigor:<level>`, add one line under Source so the user
knows the value is settable and how:

```
  Set explicitly with: /settings <key>=<value>   (an explicit value wins over rigor)
```

When the effective value is empty (key not set anywhere), print just:

```
<key>

  Effective value: (not set)
  Locally overridden: no
  Whitelist: <"can be locally overridden" | "locked — project-wide">
```

## Phase 4: Set-yaml Mode

(when `<key>=<value>`, no `--local`)

1. **Schema validation**: call `validate_enum_value <key> <value>`. If
   it returns 1, the stderr line is shown to the user verbatim
   (`Invalid value '<value>' for '<key>'. Allowed: ...`) and the skill
   exits without writing. If it returns 0, the value is either valid
   or the key has no enum constraint — proceed.

2. **Reserved warning**: if `<key>` is in `RESERVED_SET` (Phase 1b), print
   BEFORE the approval prompt:
   > "Note: `<key>` is RESERVED — no skill or hook reads it, so setting it will
   > not change any behaviour. Your value is stored either way."

   Then continue to the approval gate as normal. Phase 5 carries the identical
   warning. Warning on one write path and not the other leaves a silent route
   to the same outcome, which is the whole failure this guards against.

3. **Shadow warning**: read `get_yaml_key project.local.yaml <key>`. If
   it returns a non-empty value, print BEFORE the approval prompt:
   > "Note: this setting is currently locally overridden in `project.local.yaml` (value: `<localvalue>`). Writing to `project.yaml` will not change your effective value."

4. **Approval gate**: use `AskUserQuestion`:
   - Prompt: ``Set `<key>=<value>` in `project.yaml`?``
   - Options: `[A] Yes, write` / `[B] No, cancel`

5. **Write** using the `Edit` tool. The edit strategy depends on what
   already exists in `project.yaml`:

   **Case A — key exists**: Read `project.yaml`. Locate the line
   `<lastsegment>: <oldvalue>` and the line immediately above it that
   introduces its parent block (e.g. `modes:` for `modes.review_mode`).
   Construct the `Edit` with `old_string` that includes the parent
   block line PLUS the leaf line, so the match is unique even if
   `<lastsegment>: <oldvalue>` appears elsewhere. Example for
   `modes.review_mode=full`:
   ```
   old_string:
     modes:
       review_mode: lean
   new_string:
     modes:
       review_mode: full
   ```

   **Case B — parent block exists, leaf doesn't**: Find the last line
   of the parent block. Use `Edit` to append the new leaf line at the
   correct indentation, using the last existing leaf as the `old_string`
   anchor.

   **Case C — parent block doesn't exist**: Append a new top-level
   block at end-of-file (deterministic — always end-of-file, never
   between blocks). Use `Edit` with the last non-empty line of the
   file as `old_string` and append the new block after it.

   **Case D — file structure is unusual** (commented-out keys with the
   same name, ambiguous nesting, malformed YAML): STOP and ask via
   `AskUserQuestion`:
   > "Couldn't find a clean insertion point for `<key>` in `project.yaml`. Show me what to do."

6. Confirm: ``Set `<key>=<value>` in `project.yaml`.``

   **When `<key>` is `modes.rigor`**, the write also moves six other
   knobs, so print what they resolve to now — re-read each with
   `resolve_setting` rather than reciting the expansion table, since any
   of them may carry an explicit value that still wins:

   ```
   Set modes.rigor=full in project.yaml. It now supplies:
     modes.workflow: full            (derived from rigor: full)
     docs.density: terse             (project.yaml — explicit, unchanged)
     qa.level: full                  (derived from rigor: full)
     modes.story_granularity: fine   (derived from rigor: full)
     modes.review_mode: full         (derived from rigor: full)
     team.size: studio               (derived from rigor: full)
   ```

## Phase 5: Set-local Mode

(when `--local <key>=<value>`)

1. **Whitelist check**: call `is_locally_overridable <key>`.
   - If it returns 1 (locked), print one line:
     > ``<key> cannot be locally overridden — it's a project-wide setting. Use `/settings <key>=<value>` (no `--local`) to change it for the whole team.``
   - Exit without writing.

2. **Schema validation**: call `validate_enum_value <key> <value>`. If
   it returns 1, show the stderr message verbatim and exit without
   writing.

2b. **Reserved warning**: if `<key>` is in `RESERVED_SET` (Phase 1b), print
   BEFORE the approval prompt:
   > "Note: `<key>` is RESERVED — no skill or hook reads it, so setting it will
   > not change any behaviour. Your value is stored either way."

   Identical to Phase 4 step 2, and deliberately so. Both write paths reach the
   same file-of-record for a user's intent; warning on one only would leave
   `--local` as the silent route.

3. **Base check**: if `project.yaml` doesn't exist:
   > "Cannot create `project.local.yaml` — `project.yaml` is missing. Run `/start` to create one first."
   Exit. (Local overrides require a base, per spec.)

4. **Approval gate**: use `AskUserQuestion`:
   - Prompt: ``Set `<key>=<value>` in `project.local.yaml` (your personal override, gitignored)?``
   - Options: `[A] Yes, write` / `[B] No, cancel`

5. **Write**:
   - If `project.local.yaml` doesn't exist, use `Write` to create it
     with the new setting wrapped in its parent block(s). Minimal
     example for `--local modes.automation=autonomous`:
     ```yaml
     # project.local.yaml — per-developer overrides (gitignored)
     modes:
       automation: autonomous
     ```
   - If it exists, use `Edit` with the same Case A/B/C strategy from
     Phase 4 step 4.

6. Confirm: ``Set `<key>=<value>` in `project.local.yaml` (your override).``

## Phase 6: Usage

When the argument doesn't match any of the four valid forms (or has
empty operands), print:

```
Usage:
  /settings                          — view all effective config
  /settings <key>                    — view a single setting
  /settings <key>=<value>            — change a setting (project.yaml)
  /settings --local <key>=<value>    — change a setting locally
                                       (project.local.yaml, gitignored)

Examples:
  /settings modes.review_mode
  /settings modes.review_mode=full
  /settings --local modes.automation=autonomous
```

## Notes

- All YAML writes go through `Edit` (existing keys/blocks) or `Write`
  (new files). The skill does not depend on `yq` or any external YAML library.
- The whitelist is enforced in `yaml-helper.sh`
  (`is_locally_overridable` function). To extend it, edit the
  `_yaml_helper_locally_overridable` constant — do not duplicate the list here.
- **Derived values are not stored anywhere.** `modes.workflow`, `docs.density`,
  `qa.level`, `modes.story_granularity`, `modes.review_mode` and `team.size` have no
  terminal default; when no file sets them their value comes from the `modes.rigor`
  expansion in `yaml-helper.sh`
  (`_yaml_helper_rigor_expansion`). Report them via `resolve_setting` — a
  `get_yaml_key` read returns empty and would render them "(not set)" while every
  skill is in fact acting on a real value.
- The schema-validation enum constants are in `yaml-helper.sh`
  (`_yaml_helper_enums`). `validate_enum_value` is the single-key
  validator for pending writes; `validate_yaml_enum` validates whole
  files (used by `session-start.sh`).
- `project.local.yaml` is gitignored. These
  overrides never propagate to teammates.
- For **which value to choose** for a given game type or situation — and when to
  suggest changing one — see `.claude/docs/settings-guidance.md` (advisory presets
  + change triggers). `effects-map.md` says what each setting does; that doc says
  which to pick.
