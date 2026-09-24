# Config Resolution

How a skill learns its effective settings. **One command, no prose chain.**

## The rule

A skill that needs config puts this near the top of its **body** (not frontmatter):

````markdown
!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys a,b`
````

**and** pre-approves exactly that command in its own frontmatter, with its own
directory name in the path:

````yaml
allowed-tools: Read, …, Bash(bash "*/.claude/skills/<skill-name>/../../hooks/yaml-helper.sh" resolve_config *)
````

The command runs as preprocessing *before the model sees the skill*, and its
output replaces the placeholder inline. The skill then reads the resolved values
and **does not re-derive them**.

Skills that resolve a per-system tier pass the system name: `resolve_config combat`.

## Why the body, not `context:`

`` !`cmd` `` in the skill body is the documented mechanism. Frontmatter
`context:` accepts only `context: fork` — it does **not** run shell. A
`context: |` block containing `!` commands **never executes**; put the command in
the skill body instead.

## Why exactly this command — the permission check

Claude Code permission-checks every injected command **before** the skill
renders. Outside auto mode, anything that does not come back "allow" — including
a command that would normally just prompt — **aborts the whole invocation**, and
the model never sees the skill. A preloaded skill (`skills:` on an agent) is
checked the same way at agent launch, so a failing bootstrap line stops the agent
from starting (GitHub issue #128). Measured on Claude Code 2.1.281 in default
mode:

| Bootstrap form | Repo root | Subdirectory | Bash-less agent preloading it |
|---|---|---|---|
| `source "${CLAUDE_PROJECT_DIR:-.}/…" && resolve_config` (v1.1.0) | aborts | aborts | fails to launch |
| same, with a bare `Bash` grant | aborts | — | — |
| `bash "${CLAUDE_PROJECT_DIR}/…"` + grant | runs | aborts | — |
| **`bash "${CLAUDE_SKILL_DIR}/../../hooks/…"` + per-skill grant** | **runs** | **runs** | **launches** |

What that table rules out:

- **No `${VAR:-x}` expansion.** It fails as "Contains expansion", and no grant
  can approve it. `${CLAUDE_SKILL_DIR}` and `${CLAUDE_PROJECT_DIR}` are fine: Claude
  Code substitutes them as text before the check.
- **No `${CLAUDE_PROJECT_DIR}` for the path.** In a skill it is the directory
  Claude Code was launched from, not the repo root, so it breaks from `src/`.
  `${CLAUDE_SKILL_DIR}` always names the skill's own folder.
- **No `source … && …` compound.** Each part must be approved; `bash <file>
  resolve_config` is one command. `yaml-helper.sh` dispatches only
  `resolve_config` when executed, and finds the repo root from its own location.
- **The grant is required.** `allowed-tools` is what pre-approves an injected
  command. The pattern must include the literal `"` after the path — a pattern
  ending `…yaml-helper.sh *` does not match.
- **Any non-zero exit aborts too.** The entry point always exits 0; other
  injected commands that can fail end in `|| true`.

Auto mode can approve the old form on its own, which is how v1.1.0 shipped with
it. Test bootstrap changes in default mode, in a project without a
`settings.local.json`.

`disableSkillShellExecution: true` replaces every injected command with a
placeholder message. If a skill sees no config block, it falls back to the
defaults below.

## The block

```
=== CCGS Resolved Config ===
review_mode: lean (production/review-mode.txt)
automation: guided (project.local.yaml)
workflow: standard (project.yaml)
docs.density: balanced (default)
story_granularity: balanced (default)
qa.level: standard (default)
team.size: individual (rigor:standard)
project.stage: Systems Design (production/stage.txt)
automation_always_ask: scope_changes, file_deletions, schema_changes (default)
engine: Godot 4.6 (project.yaml)
testing.strict: logic=true integration=false visual=unset ui=unset config=unset (unset = each skill applies its own default)
system_overrides: combat=full inventory=minimal
notes: none
Values above are fully resolved (local -> yaml -> legacy -> default). Use as-is.
An inline --review flag, if passed, overrides review_mode.
=== end CCGS config ===
```

Every knob line ends with its **provenance** in parentheses. That is what makes a
wrong value diagnosable — `review_mode: solo (default)` when `project.yaml` says
`full` points straight at the problem.

## Resolution chain

| Step | Source | Applies to |
|---|---|---|
| 1 | `project.local.yaml` | any setting on the `/settings --local` whitelist (12 keys — `modes.review_mode`, `modes.automation`, `modes.automation_always_ask`, `team.size`, all five `testing.strict.*`, `performance.enforce`, `features.*`) |
| 2 | `project.yaml` | all keys |
| 3 | legacy plain-text mirror | `modes.review_mode` → `production/review-mode.txt`; `project.stage` → `production/stage.txt` |
| 4 | **`modes.rigor` expansion** | the six knobs `rigor` fronts — `modes.workflow`, `docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode`, `team.size` |
| 5 | documented default | the table below |

An **enum-invalid value does not win** — the chain continues past it and the
rejected value is named on the `notes:` line. A typo degrades to the documented
default rather than propagating a nonsense mode into every skill.

> **Step 4 sits below every explicit source and above the terminal default, and
> that ordering is the whole back-compat guarantee.** A `project.yaml` that
> already sets `docs.density: terse` resolves exactly as it did before `rigor`
> existed, because step 2 answers first. Invert steps 4 and 5 and `rigor` becomes
> a no-op; hoist step 4 above step 2 and it silently overrides settings people
> already have. Tests **X.2** and **X.3** assert both directions.
>
> Derived values report their provenance as **`rigor:<level>`**, so the source
> vocabulary is `{project.local.yaml, project.yaml, <legacy path>, rigor:<level>,
> default, unset}`. `docs.density: balanced (rigor:standard)` says the value was
> never written down anywhere — it follows the project's rigor level and will
> move if that level moves.

> **Read scope == write whitelist.** Anything `/settings --local` may *write*
> is also *read* during resolution. If the read scope were ever narrower,
> `/settings --local modes.review_mode=solo` would write a value
> that `/settings` accepted and displayed and every skill then ignored. The
> test suite asserts the two lists stay in step — adding a setting to one
> without the other reproduces that bug.
>
> This matches the spec: `effects-map.md` § "Local Override Pattern" has always
> stated the chain applies to *every* setting. The narrow read scope was an
> implementation gap, not a design.

> **A key OUTSIDE the whitelist, hand-written into `project.local.yaml`, is
> reported rather than swallowed.** `/settings --local` refuses to
> write one, but the file exists to be edited by hand, so that path needs its own
> guard. `modes.rigor: full` written there is a real key with a legal value, so
> `validate_yaml_enum` passes it — and then resolution never consults the local
> file for that path, so the setting vanishes and the user sees the default they
> were trying to override, with no error anywhere. Every check in the chain
> validated the **value**; nothing validated the **location**.
>
> `validate_local_scope` now names such keys on `notes:`. It **warns and never
> reconciles**, the same shape as the stage-mirror check: it does not edit the
> file, does not begin honouring the key, and does not change resolution. A
> locked setting is locked because it decides which artifacts exist on disk, so
> a helper that quietly applied one would let two developers' checkouts diverge
> — the exact thing the whitelist prevents. The user moves the key to
> `project.yaml` or deletes it.
>
> `schema_version` and `framework.*` are exempt: `effects-map.md` classes them as
> file metadata rather than preferences, and a `project.local.yaml` carrying
> `schema_version: 1` is correct as written.

## Defaults

| Knob | Default |
|---|---|
| `modes.automation` | `collaborative` |
| `modes.rigor` | `minimal` |
| `modes.automation_always_ask` | `scope_changes`, `file_deletions`, `schema_changes` |

**The six knobs `rigor` fronts have no terminal default at all.** `modes.workflow`,
`docs.density`, `qa.level`, `modes.story_granularity`, `modes.review_mode` and `team.size` are
deliberately absent from `_yaml_helper_defaults`: a default there would answer at step 5 before the
expansion at step 4 ever ran, making `rigor` a no-op for anyone who had not also
set the sub-knob. Their effective values come from the rigor level:

| `modes.rigor` | `modes.workflow` | `docs.density` | `qa.level` | `modes.story_granularity` | `modes.review_mode` | `team.size` |
|---|---|---|---|---|---|---|
| `minimal` (default) | `minimal` | `terse` | `minimal` | `coarse` | `solo` | `individual` |
| `standard` | `standard` | `balanced` | `standard` | `balanced` | `lean` | `individual` |
| `full` | `full` | `thorough` | `full` | `fine` | `full` | `studio` |

Because `rigor` itself defaults to `minimal`, an unconfigured project resolves
these six to the lean row. That default was `standard`; it changed because the
heavier tier measured several times more expensive to reach working code without
producing a better result. See the rationale block above `_yaml_helper_defaults`
in `.claude/hooks/yaml-helper.sh` for the reasoning and the ordering
constraint. Raising the tier is one question in `/start` or one `/settings`
call, and `settings-guidance.md § 4`'s upward triggers are written to fire from
this starting state. (`team.size` is the one knob the flip does not move:
`minimal` and `standard` both yield `individual`, and only `full` opts into the
`studio` roster.) Test **X.8** asserts the six stay defaultless.

> **The flip DOES reach existing projects.** A `project.yaml` that sets some of
> the six explicitly but never sets `rigor` keeps its explicit values and takes
> the new `minimal` row for the rest -- so an unset `qa.level` that used to
> resolve `standard` now resolves `minimal`. Test **X.3** pins exactly this.
> Pin the old behaviour by setting `modes.rigor: standard` explicitly; see
> UPGRADING.md.

`modes.workflow` is **fronted, not replaced**: it keeps
`workflow_overrides.system_overrides`, which still beats the derived value
(**X.6**). Setting any of the six explicitly overrides just that one and leaves
its siblings on the rigor level, which is how "comprehensive but compact"
(`rigor: full` + `docs.density: terse`) stays expressible. Two of the six —
`modes.review_mode` and `team.size` — are personal-experience knobs that also
remain overridable from `project.local.yaml` (that source sits above the
expansion), unlike the four on-disk knobs, which are locked.

> **This table is asserted against the helper, not maintained by hand.** Test
> **X.10** reads `_yaml_helper_defaults` through `get_yaml_default` and checks
> both directions: every knob listed here must carry the value the helper
> actually returns, and none of the six fronted knobs may appear at all. It
> exists because a table can list knobs the helper has stopped defaulting and
> read as correct: the structural check pairs a knob with the word "default" on
> a single line, so a two-cell table row is invisible to it. Editing this table
> without editing the helper now fails the build.

**`testing.strict.*` has no central default on purpose.** Its unset default
differs per skill by design: `/smoke-check` treats unset as **blocking** (it is a
build-health gate), while `/story-done` and `/dev-story` apply the per-story-type
table in `.claude/docs/coding-standards.md`. `resolve_config` therefore reports
only the *configured state* (`unset` where absent) and each skill applies its own
default. The script resolves **sources**; the skill owns **policy**.

**`engine` is reported from `project.yaml` only.** No markdown reader is built.
Skills keep their existing per-field fallback to
`.claude/docs/technical-preferences.md`, which also remains the sole source for
forbidden patterns and allowed libraries — those never migrated.

## Failure modes

`resolve_config` **always exits 0 and always emits a complete block.** Each
condition below degrades to defaults and is named on `notes:`:

| Condition | Behavior |
|---|---|
| `project.yaml` absent | legacy → defaults; `notes: project.yaml absent` |
| `project.yaml` **empty** | defaults; `notes: project.yaml is EMPTY`. Distinct from absent on purpose — a truncated write or an interrupted `/setup-engine` looks like this |
| Malformed YAML | unparseable keys resolve empty and fall through |
| Tab-indented lines | rejected, and the **line numbers are named** on `notes:` |
| CRLF line endings | parsed correctly (the Windows default) |
| UTF-8 BOM | parsed correctly; the BOM does not poison the first key |
| 3-space indent | parsed correctly; the parser is indent-tolerant |
| Key present, value empty | treated as **unset**; falls through to the next source, never to `""` |
| Enum-invalid value | chain continues; rejected value named in `notes:` |
| `project.local.yaml` without a base | `validate_local_yaml_base` message on `notes:` |
| Locked key in `project.local.yaml` | ignored as always, but now **named** on `notes:` — `local: not locally overridable, ignored — modes.rigor (move to project.yaml or delete)` |
| No Python interpreter | legacy files and defaults only; **explicitly noted** on `notes:` |
| No block at all | shell preprocessing disabled (`disableSkillShellExecution`) — use the defaults table above |
| Bootstrap line not approved, or exits non-zero | **not a degraded state — the skill never renders at all.** See "Why exactly this command" above |

A skill must never treat a missing block as "config is unset in an interesting
way". It means the block did not render; the defaults apply.

### Two behaviours that are correct but SILENT

In both cases the
resolved *value* is right — the chain falls through to the default — but the user
is told nothing, and their explicit configuration was discarded.

| Input | What happens | Note emitted |
|---|---|---|
| **Duplicate key** (`rigor:` twice in one block) | **the last occurrence wins**, deterministically | **none** |
| **Wrong shape** — a list where a scalar belongs (`rigor:` followed by `- standard`) | key resolves empty, falls through to the default | **none** |

**Why this is worth knowing rather than shrugging at.** An enum-*invalid* value is
announced (`modes.workflow: 'medium' is not a valid value … — ignored, chain
continued`). A structurally-invalid one is not. So a user who mistypes the value
gets told, and a user who mistypes the *structure* does not — and the second
mistake is the easier one to make by copy-paste. The framework has the mechanism
(`notes:`) and already uses it for absence, emptiness, tabs, locked keys, orphan
locals and bad enums. Shape is the gap.

**Deliberately not fixed in v1.1.** Detecting "this key is present in the file but
resolved to nothing" means changing the parser every config read in the framework
goes through, and the empty-value fall-through above is a *legitimate* case of
exactly that signature. Distinguishing "empty on purpose" from "unparseable" is
real work, not a one-liner, and it lands in the most load-bearing file there is.
Recorded here as v1.2.

**Duplicate-key precedence was undocumented before this entry.** Last-wins is
deterministic and reproducible, so it is not a bug — but nothing said so, which
meant nobody could rely on it either.

## Why not inject at session start

`resolve_config` is also safe to call from a hook, but session-start does **not**
call it. The block would cost tokens on every session whether or not any skill
needs config, and it would go stale mid-session as `/settings` writes land. The
per-skill body call is fresher and only loads where it is used. Session start
still prints the resolved review mode and any schema errors, which is the part a
human reads.

## Testing

The resolution chain, the legacy reader, enum fall-through, block shape and
every failure mode above are covered by the framework's own test suite under
`tests/`, along with the `modes.rigor` expansion and its precedence in both
directions. Two properties are asserted that are easy to lose:

- The local **read** scope and the `/settings --local` **write** whitelist stay
  in step. If they drift, `/settings` accepts and displays a value that every
  skill then ignores.
- The expansion is *reachable* (`/start` asks about it) and *legible*
  (`/settings` reports derived values rather than "(not set)"). A correct
  expansion nobody is asked about and no view displays would be worth nothing.
