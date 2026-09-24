---
name: help
description: "What should I do next? Use when stuck or you don't know what to do."
argument-hint: "[optional: what you just finished, e.g. 'finished design-review' or 'stuck on ADRs']"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Bash(bash "*/.claude/skills/help/../../hooks/yaml-helper.sh" resolve_config *)
model: haiku
---

# Studio Help — What Do I Do Next?

This skill is read-only — it reports findings but writes no files.

This skill figures out exactly where you are in the game development pipeline and
tells you what comes next. It is **lightweight** — not a full audit. For a full
gap analysis, use `/project-stage-detect`.

## Live Project State

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys project.stage,workflow`

!`echo "Latest sprint: $(ls -t production/sprints/*.md 2>/dev/null | head -1 || echo 'none')"; echo "Session state: $(head -5 production/session-state/active.md 2>/dev/null || echo 'none')"`

Both blocks are resolved before this skill runs. Use them as-is:

- **`project.stage`** from the config block is the authoritative phase for Step 2
  — it already applies the `project.yaml` → `production/stage.txt` fallback, and
  preserves values containing spaces (`Systems Design`).
- **`workflow`** from the config block is the tier for Step 5 — do not re-read it.
- If no config block rendered, shell preprocessing is disabled; fall back to the
  defaults in `.claude/docs/config-resolution.md`.

---

## Step 1: Read the Catalog

Read `.claude/docs/workflow-catalog.yaml`. This is the authoritative list of all
phases, their steps (in order), whether each step is required or optional, and
the artifact globs that indicate completion.

---

## Step 1b: Find Skills Not in the Catalog

After reading the catalog, Glob `.claude/skills/*/SKILL.md` to get the full list
of installed skills. For each file, extract the `name:` field from its frontmatter.

Compare against the `command:` values in the catalog. Any skill whose name does
not appear as a catalog command is an **uncataloged skill** — still usable but not
part of the phase-gated workflow.

Collect these for the output in Step 7 — show them as a footer block:

```
### Also installed (not in workflow)
- `/skill-name` — [description from SKILL.md frontmatter]
- `/skill-name` — [description]
```

Only show this block if at least one uncataloged skill exists. Limit to the 10
most relevant based on the user's current phase (QA skills in production, team
skills in production/polish, etc.).

---

## Step 2: Determine Current Phase

Check in this order:

1. **Take `project.stage` from the config block above** — it is already resolved. Map its value to a catalog phase key:
   - "Concept" → `concept`
   - "Systems Design" → `systems-design`
   - "Technical Setup" → `technical-setup`
   - "Pre-Production" → `pre-production`
   - "Production" → `production`
   - "Polish" → `polish`
   - "Release" → `release`

2. **If neither is set**, infer phase from artifacts (most-advanced match wins):
   - code root has 10+ source files → `production`
   - `production/epics/**/story-*.md` exists → `pre-production`
   - `docs/architecture/adr-*.md` exists → `technical-setup`
   - `design/gdd/systems-index.md` exists → `systems-design`
   - `design/gdd/game-concept.md` (or `design/game-brief.md`) exists → `concept`
   - Nothing → `concept` (fresh project)

3. **Take `workflow` from the config block above** (per
   `.claude/docs/workflow-modes.md`). It controls whether optional docs are
   surfaced as next steps (Step 5).

---

## Step 3: Read Session Context

Read `production/session-state/active.md` if it exists — it is append-only and grows unbounded, and only the latest block is relevant, so read just the tail rather than the whole file: grep the last heading (`Grep pattern="^## (Session Extract|STATUS)" path="production/session-state/active.md" output_mode="content" -n`, take the highest line number) and `Read(offset=that line)`. Extract:
- What was most recently worked on
- Any in-progress tasks or open questions
- Current epic/feature/task from STATUS block (if present)

This tells you what the user just finished or is stuck on — use it to personalize
the output.

---

## Step 4: Check Step Completion for the Current Phase

For each step in the current phase (from the catalog):

### Artifact-based checks

**Resolve these deterministically — one call, not a glob per step:**

```
Bash: bash .claude/scripts/artifact-check.sh --phase [current-phase]
```

It evaluates every `glob`, `pattern`, `min_count` and `any_of` in the catalog
against the working tree and reports one line per step. Map its statuses:

| status | Report as |
|---|---|
| `PRESENT` | **Complete** |
| `ABSENT` | **Incomplete** |
| `SHORT` | **Incomplete** — say how far short (`count=`/`min=` are given) |
| `PATTERN_MISS` | **Incomplete** — the file exists but lacks its marker; say so, since "missing" would send the user to recreate a file they already have |
| `NO_CHECK` | **MANUAL** if the step carries a `note=`, else **UNKNOWN** — completion is not trackable (e.g. repeatable implementation work) |

Do not re-derive any of this with Glob/Grep. `any_of` in particular is a list of
**alternatives** — one match is enough — and hand-evaluating it has already
produced a false "incomplete" once: `engine-setup` is satisfied by `engine.name`
in `project.yaml` **or** by the legacy `Engine:` line in
`.claude/docs/technical-preferences.md`, and the script reports which alternative
matched (`alt=`/`match=`).

**`NO_CHECK` never means done.** The script prints a `NO_CHECK:` total before the
rows; if most of a phase is NO_CHECK, say that plainly rather than implying the
phase is nearly complete.

### Special case: production phase — read `sprint-status.yaml`

When the current phase is `production`, check for `production/sprint-status.yaml`
before doing any glob-based story checks. If it exists, read it directly:

- Stories with `status: in-progress` → surface as "currently active"
- Stories with `status: ready-for-dev` → surface as "next up"
- Stories with `status: done` → count as complete
- Stories with `status: blocked` → surface as blocker with the `blocker` field

This gives precise per-story status without markdown scanning. Skip the glob
artifact check for the `implement` and `story-done` steps — the YAML is authoritative.

### Special case: `repeatable: true` (non-production)

For repeatable steps outside production (e.g. "System GDDs"), the artifact
check tells you whether *any* work has been done, not whether it's finished.
Label these differently — show what's been detected, then note it may be ongoing.

---

## Step 5: Find Position and Identify Next Steps

From the completion data, determine:

1. **Last confirmed complete step** — the furthest completed required step
2. **Current blocker** — the first incomplete *required* step (this is what the
   user must do next)
3. **Optional opportunities** — incomplete *optional* steps that can be done
   before or alongside the blocker. **Surface these per the workflow tier**: at
   `full`, list all of them; at `standard`, list an optional doc only if it is
   required for the current system/phase (do not flag genuinely-optional docs as
   gaps); at `minimal`, do not surface optional docs at all — once the brief,
   engine, and a sprint plan exist, the next step is code
4. **Upcoming required steps** — required steps after the current blocker
   (show as "coming up" so user can plan ahead)

If the user provided an argument (e.g. "just finished design-review"), use that
to advance past the step they named even if the artifact check is ambiguous.

---

## Step 6: Check for In-Progress Work

If `active.md` shows an active task or epic:
- Surface it prominently at the top: "It looks like you were working on [X]"
- Suggest continuing it or confirm if it's done

---

## Step 7: Present Output

Keep it **short and direct**. This is a quick orientation, not a report.

```
## Where You Are: [Phase Label]

**In progress:** [from active.md, if any]

### ✓ Done
- [completed step name]
- [completed step name]

### → Next up (REQUIRED)
**[Step name]** — [description]
Command: `[/command]`

### ~ Also available (OPTIONAL)
- **[Step name]** — [description] → `/command`
- **[Step name]** — [description] → `/command`

### Coming up after that
- [Next required step name] (`/command`)
- [Next required step name] (`/command`)

---
Approaching **[next phase]** gate → run `/gate-check` when ready.
```

**Formatting rules:**
- `✓` for confirmed complete
- `→` for the current required next step (only one — the first blocker)
- `~` for optional steps available now
- Show commands inline as backtick code
- If a step has no command (e.g. "Implement Stories"), explain what to do instead of showing a slash command
- For MANUAL steps, ask the user: "I can't tell if [step] is done — has it been completed?"

Verdict: **COMPLETE** — next steps identified.

---

## Step 8: Gate Warning (if close)

After the current phase's steps, check if the user is likely approaching a gate:
- If all required steps in the current phase are complete (or nearly complete),
  add: "You're close to the **[Current] → [Next]** gate. Run `/gate-check` when ready."
- If multiple required steps remain, skip the gate warning — it's not relevant yet.

---

## Step 9: Escalation Paths

After the recommendations, if the user seems stuck or confused, add:

```
---
Need more detail?
- `/project-stage-detect` — full gap analysis with all missing artifacts listed
- `/gate-check` — formal readiness check for your next phase
- `/start` — re-orient from scratch
- `/settings` — if the process feels mismatched to your project, adjust
  `modes.rigor`. Apply the change-triggers in
  `.claude/docs/settings-guidance.md § 4`: a **lower** tier when the user sounds
  overwhelmed by process (and rigor isn't already `minimal`), or a **higher** tier
  when the project has outgrown it (many systems, or in Production on
  `workflow: minimal`)
```

Only show this if the user's input suggested confusion (e.g. "I don't know", "stuck",
"lost", "not sure"). Don't show it for simple "what's next?" queries. Show the
`/settings` rigor line only when a `settings-guidance.md § 4` trigger actually
fires — the user sounds overwhelmed (and rigor isn't already `minimal`), or the
project has outgrown its tier — not on every confused query.

---

## Collaborative Protocol

- **Never auto-run the next skill.** Recommend it, let the user invoke it.
- **Ask about MANUAL steps** rather than assuming complete or incomplete.
- **Match the user's tone** — if they sound stressed ("I'm totally lost"), be
  reassuring and give one action, not a list of six.
- **One primary recommendation** — the user should leave knowing exactly one thing
  to do next. Optional steps and "coming up" are secondary context.
