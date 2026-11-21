---
name: dev-story
description: "Implements one story in code with tests, following its ADRs. Use when the user says to build, implement or start working on a story. Not for checking readiness beforehand or closing the story after."
argument-hint: "[story-path]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/dev-story/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/session-state.sh *), Bash(bash .claude/scripts/review-receipts.sh hash *), Bash(godot *), Bash(mkdir -p production/qa/evidence/*), Bash(npm run smoke), Bash(npm run build:single), Bash(bash .claude/scripts/page-shot.sh *), Bash(bash .claude/scripts/one-shot-grow.sh replay *), Bash(bash .claude/scripts/one-shot-grow.sh accept *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys automation,workflow,qa.level,gate_level,engine_values,specialists,perf_budgets,system_overrides`

Resolved above — use as-is. No block → defaults in
`.claude/docs/config-resolution.md`.

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

# Dev Story

Implements one story: checks it can start, marks it In Progress, hands the code to
the right programmer agent with a brief built from the story, then checks the
result parses and looks right, and hands off.

**Writes** (each after an ask that names it): the story's `Status`, `Last Updated`
and `## Files`, and its `production/sprint-status.yaml` entry. The programmer agents
write the code and tests under the code root and test root
(`.claude/docs/code-root-resolution.md`). The session checkpoint and the evidence
stamp are written without an ask.
**Next:** `/story-done [story-path]`; at `standard` and `full`, `/code-review
[files]` first. `/dev-story` and `/story-done` start only when the person types them, so never offer to start one as an option: print it as a line to type.

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

Checklist (copy it and tick as you go):

```
- [ ] Phase 1: story found, tier resolved
- [ ] Phase 2: prerequisites checked (ADR, manifest, dependencies)
- [ ] Phase 3: story marked In Progress (one ask)
- [ ] Phase 4: programmer and engine specialist chosen
- [ ] Phase 5: work handed out with a full brief
- [ ] Phase 6: finished? parse check, run and look, one Run result line; a grown game's same-seed run
- [ ] Phase 7: summary, ## Files, checkpoint, closing block
```

## Phase 1: The story

The text typed after the skill name is the story path. With nothing typed, take the
story the checkpoint in `production/session-state/active.md` names and confirm it:
"Continuing work on [title] — is that correct?" None there: ask "Which story are we
implementing?" with the `TODO` rows of `bash .claude/scripts/story-facts.sh --all`
as options. No story file under `production/epics/` at all: stop with
"No stories found in `production/epics/` — run `/create-stories [epic-slug]` to make them (at `standard` and `full`, run `/create-epics` first if there is no epic yet)."

`bash .claude/scripts/story-facts.sh <story-path>` gives its type, layer, TR-IDs,
ADRs and dependencies. Then read the story in full.

**Tier.** `workflow` for the story's system, keyed on the GDD filename stem of its
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`; the `[system]` of its TR-ID only when
there is no GDD path): that system's `system_overrides` row if there is one, else the
project value. Say it in your first reply: `Tier: workflow [value]`. That value, never
`rigor` or `qa.level`, picks the Phase 2 column and the closing Next step.

## Phase 2: Can it start?

| Input | `full` | `standard` | `minimal` |
|---|---|---|---|
| TR registry `docs/architecture/tr-registry.yaml` | missing: **stop**, "Run `/architecture-review` to bootstrap it" | optional | not expected |
| The ADR the story names | missing, `Proposed`, `Deprecated` or `Superseded`: **stop** | the same, only when the story names one | the same, only when the story names one |
| Control manifest `docs/architecture/control-manifest.md` | missing: warn, go on | missing: warn, go on | not expected |

A story whose ADR field reads `N/A — [reason]` names none.

**The ADR.** `bash .claude/scripts/adr-status.sh <ADR id>` gives its status and
`version`. Stop messages: `Proposed` — "ADR-NNNN is still Proposed. Accept it with
`/architecture-decision accept ADR-NNNN` before implementing." `Deprecated` or
`Superseded` — "ADR-NNNN is [status]; point the story at [successor] (edit its ADR
field; `/create-stories` never rewrites an existing story) before implementing."
`NOT_FOUND` — "ADR file not found. Run `/architecture-decision`, or correct the
story's ADR field."

**Do not open the ADR.** The story's ADR Decision Summary and Implementation Notes
are what the programmer reads instead. Compare the ADR's `version` with the story's
`ADR Version`:

- equal, or the story has no `ADR Version` (written before the stamp), or both are
  `unversioned`: trust the story. Note the last two in the summary ("summary
  trusted unverified").
- they differ, or the ADR is `unversioned` but the story names a date: read
  `references/version-mismatch.md`. On a match, do not load it.

Never treat an absent stamp as a stale one: unknown falls back to the story, and
`/story-readiness` and `/code-review` are the checks that catch drift later.

**The manifest.** When it exists, compare its `Manifest Version` line with the
story's. They differ: read `references/version-mismatch.md`.

**Dependencies.** For each path on the story's Depends on line,
`bash .claude/scripts/story-facts.sh <path>`. Not `COMPLETE`: ask "[this story]
depends on [dependency], which is [status], not Complete. How do you want to go
on?" Options: Proceed anyway — I accept the risk / Stop — I'll finish the
dependency first / It is done, the status was never updated — mark it Complete.
Stop: the story is BLOCKED (Phase 7), no agent. Mark it: ask "May I set [path]
Status to Complete?" first. Proceed: note it under Deviations. `NOT_FOUND`: warn
"Dependency story not found: [path]".

Any stop above: no agent runs. Go to Phase 7 and write the BLOCKED checkpoint.

## Phase 3: Mark it In Progress

Before any agent, ask once: "May I mark this story In Progress? This sets `Status`
and `Last Updated` in [story path] and its entry in `production/sprint-status.yaml`,
and at the end lists the files changed under its `## Files`." Leave the sprint file
out of the question when it does not exist. Put what you will do next before the
question: the question is the last thing in the reply. On yes:

- `bash .claude/scripts/md-section.sh set-field <story> Status "In Progress"`, then
  `set-field <story> "Last Updated" <YYYY-MM-DD> --after Status`. At `minimal` the
  story file is the only record of progress.
- `production/sprint-status.yaml`: this story's entry gets `status: in-progress` and
  the top-level `updated` today. No file: say `Sprint status not updated:
  production/sprint-status.yaml absent`.

Declined: change neither, print `Story not marked In Progress — declined` in the
summary, and go on.

## Phase 4: Who implements it

**Config/Data stories need no agent.** Show each value change as from → to, ask "May
I write [data file]?", and edit it. Go to Phase 6.

| Story | Programmer agent |
|---|---|
| Foundation layer, any type | `engine-programmer` |
| Type UI | `ui-programmer` |
| Type Visual/Feel | `gameplay-programmer` |
| Core or Feature, gameplay | `gameplay-programmer` |
| Core or Feature, AI or pathfinding | `ai-programmer` |
| Core or Feature, networking | `network-programmer` |

**The engine specialist, for every code story.** From the `specialists` line above:
`code` (`specialists.code`, the language specialist: it tells a Godot C# project
from a GDScript one, which `engine.name` cannot), plus `shader` when the story
touches shaders or materials and `ui` for a UI story; `primary` (the generic engine
specialist) when `code` is `unset`. Name no specialist from memory: the line is the project's
choice. Every value `unset` and no `primary`: say "No engine specialist configured"
and go on without one. On Web there is no engine specialist: `primary` is
`lead-programmer`, and the engine check below goes to it, against
`docs/engine-reference/web/`. Say so in one line ("Web: engine check by
lead-programmer against docs/engine-reference/web/").

## Phase 5: Hand out the work

Hand the implementation to the programmer agent. The brief points at files; never
paste whole documents into it.

- **Objective:** implement [story path] against its acceptance criteria, within its
  Out of Scope boundaries.
- **Sources:**
  1. The story file. It carries the criteria, the boundaries and the QA test cases.
  2. Each TR-ID (`TR-[system]-NNN`) to look up: in
     `docs/architecture/tr-registry.yaml`, the lines matching `id: <TR-ID>\s*$`.
     Its `requirement` text is the source of truth, not text quoted in the story.
  3. The ADR guidance, **inline**: the story's ADR Decision Summary and
     Implementation Notes. Never the ADR path.
  4. The control manifest's [Layer] Layer Rules, by section.
  5. `naming.*` in `project.yaml` and the `perf_budgets` line above.
  6. The test file path from the story's Test Evidence section.
- **Tests,** by `qa.level`, for Logic and Integration stories:
  - `minimal`: "Do not write a test file for this story — test evidence is waived at
    `qa.level: minimal`." Say it: an omitted line and a forgotten one look the same
    to the agent.
  - `standard`: "Write the test at [path] with the code. Each acceptance criterion
    needs at least one test function." Naming per engine from
    `.claude/rules/test-standards.md`. No random seeds, no time-dependent
    assertions, no external I/O.
  - `full`: the same, and "every criterion must be covered: `/story-done` blocks on
    any untested one."
- **Output:** the files created or changed, the test functions written, any
  question or blocker, whether it finished, and every choice it made that the
  story and its design did not say (a value, a timing, a colour, a case nobody
  named, a word on the screen), one line each with where it is.
- **Boundaries:** write code only under the resolved code root and tests only under
  the test root. Code root unresolved: write nothing and report it. Touch no file
  outside the story's scope: report the need instead. Doc comments on public APIs.
  New gameplay values go in the game's data file (`data/config.json` on a grown game, with
  a line each in `data/config-notes.md`), never as literals in the code.
  An architectural choice the ADR does not cover: report the plan, don't decide it.
  No helper or abstraction for a one-time use, no error handling for cases that
  cannot happen (validate at input and data-file boundaries only), and general logic,
  never a value special-cased so a test passes.

**Say what the brief leaves out, to both readers.** Inputs Phase 2 found absent
(the TR registry, an ADR, the manifest) are left out: tell the agent "No [input] is
passed — it does not exist at this tier; do not go looking for it", and tell the
user one line before handing out: `Briefing omits: [inputs] — implementing against
the acceptance criteria and the [GDD | brief].`

**Then hand the engine check to the specialist** once the programmer reports.
Brief: check the changed files for engine-API use that is wrong or changed in
[engine + version], against `docs/engine-reference/<engine>/`; return a list of
file, line, problem, fix; edit nothing. A problem that breaks a criterion goes back
to the programmer once; the rest go in the summary.

## Phase 6: Check the result

**Did the agent finish?** It stopped early, hit a limit, or its report ends
mid-task: the story is **INCOMPLETE**. Say so as the headline, list what exists,
name the breakage, offer to resume the agent. Never print "Implementation Complete"
over it, and leave the status as it is.

**Did it write what it said?** First verify the artifact: a file the agent's report
names that is not on disk is a failed step, however fluent the report: resume the agent and name the missing
file. A report of BLOCKED, an error, or "cannot complete": say so at once, go no
further past what it blocks, and give a partial report
(`.claude/docs/error-recovery-protocol.md`). Scope too large: split it with
`/create-stories`. The ADR and the story disagree: report the conflict; never guess.

**Is the test there?** At `qa.level: standard` and `full`, for a Logic or Integration
story, look for the file at the Test Evidence path. Missing: at the type's BLOCKING
level on the `gate_level` line, flag "story unverifiable — test required before
`/story-done`"; at ADVISORY, note it as a recommendation. At `minimal` there is
nothing to check: tests are waived.

**Does it parse?** Run the check whose exit code answers it, and report the
command, the exit code and any error lines:

- **Godot:** `godot --headless --path . --import` once, then
  `godot --headless --path . -s res://.claude/scripts/godot-parse-check.gd -- res://<each changed .gd>`.
  Exit 1 means a script did not load; its `PARSE FAIL:` line names it. Never use
  `--check-only`, and `--import` alone is no parse check. The executable is the one
  `commands.test` names when its file name says godot (a wrapper such as `bash
  run-tests.sh` is not the editor), else `engine.path`, else `godot`. Never search the disk for
  one: when none of the three runs, the check is not verified.
- **Unity, Unreal:** read `references/engine-checks.md`.
- **Web:** the game's own smoke script, whenever `package.json` has a `smoke`
  script: `npm run smoke`, after every story, a grown game's too. The scaffold's is
  the type check (`tsc --noEmit`) and the single-file build, then Playwright's
  `@boot` test on it. An `error TS` line names a file that does not compile; a
  failing `@boot` means the page did not start. `npm run build:single` alone (the
  same-seed run's first step) is not this check: it shows nothing about the page
  starting. Never `commands.run`: it is a dev server and never exits. No
  `node_modules/`: `parse NOT VERIFIED — npm ci has not run`. No `smoke` script (an
  existing project, `/setup-engine web`): its `commands.smoke`, else its build,
  which shows the code compiles and nothing about the page starting.
- **No engine executable:** `parse NOT VERIFIED — engine binary not available`.
  Never infer from reading the code that it parses.

**Run it and look** (`.claude/docs/run-and-observe.md`). For every story a player
can see (every Visual/Feel and UI story, and any other with a surface): launch
straight into the scene the story touched, capture a screenshot straight into
`production/qa/evidence/[story-slug]/` (`[story-slug]` is the story file's name
without `.md`; `mkdir -p` the folder first), stamp it with
`bash .claude/scripts/review-receipts.sh hash <each changed file> > production/qa/evidence/[story-slug]/stamp.txt`,
then open the image and compare it with the criteria. Not waived at `qa.level:
minimal`. Report exactly one line, plain text starting `Run result:` (no bold:
`/story-done` reads it as written):

- `Run result: OBSERVED — <what was on screen>` with the retained path;
- `Run result: NOT VERIFIED — <reason>` (no engine, nothing captured); at the
  default gate level this blocks a Visual/Feel or UI story at `/story-done`;
- `Run result: N/A — <reason>` for a story with nothing observable; the reason says
  why nothing is (`/story-done` does not accept "it's a Logic story").

Only the feel half of a Visual/Feel criterion (timing, weight) is DEFERRED to
`/team-qa`: a still cannot show it.

**A grown game: the same-seed run.** A game grown from a one-shot has a folder
`production/qa/evidence/grow-<name>/` with a `replay.args` file in it: the grow step played
the game from one seed with the same inputs and kept that run. After every story, whatever
its type and after the parse check's `npm run smoke`, play it again: `npm run build:single`, then
`bash .claude/scripts/one-shot-grow.sh replay <name> --as story`. It plays the built game
the same way, takes a screenshot (`story.png` in that folder) and compares the run with the
last one the person accepted (its `against` row: `accepted`, else the grow step's
`reference`). Open `story.png` beside that run's screenshot (`accepted.png` or
`reference.png`), then report one line, plain text starting `Same-seed run:`:

- **`match yes`:** `Same-seed run: SAME — nothing broke`, with the screenshot's path.
- **`match no`:** the story changed how the game plays. Never pass over it, in any
  automation mode: show the person, in plain words, what the `no` row and the `was` row
  under it say (a scene, a value, the screen), with both screenshots, and ask: "This story
  changed the same-seed run: [what changed]. Is that what the story meant?" Options: Yes, it
  is meant — later stories are compared with this run / No — something broke, leave the
  story open. Yes: `bash .claude/scripts/one-shot-grow.sh accept <name>`, then
  `Same-seed run: CHANGED, accepted — [what changed]`. No: `Same-seed run: CHANGED, not
  accepted — [what changed]`, and the story is INCOMPLETE until it is fixed.
- **An `errors` row above 0** that the compared run did not have is a change too: ask the
  same way.
- **`not_assessed`, or `match not_assessed`:** `Same-seed run: NOT ASSESSED — [its
  reason]`; still open the screenshot when there is one.

No such folder: the game was not grown, and there is no `Same-seed run:` line.

This skill pre-approves `godot` on PATH, and on Web `npm run smoke`,
`npm run build:single`, `page-shot.sh` and the same-seed run. An engine run through `engine.path` or
the executable `commands.test` names asks first: the user approves it once, or
adds `Bash(<that executable> *)` to `.claude/settings.local.json`.

## Phase 7: Summary, files, checkpoint

```
## Implementation Complete: [title]

**Files changed**:
- `[code root path]` — created / modified ([what])
- `[test path]` — [N] test functions
**Test evidence**: waived at `qa.level: minimal` — no test was required or written   (Logic/Integration at minimal, instead of the test line)
**Verification**: [command] — [exit code and result | parse NOT VERIFIED — <reason>]

**Acceptance criteria**:
- [x] [criterion] — [file:function | test name | OBSERVED in <image path>]
- [ ] [criterion] — DEFERRED: feel, needs a playtest
**Deviations**: [None | files outside scope, an accepted dependency or version risk]
**Engine risks**: [None | the specialist's findings]
**Blockers**: [None | each]
**Own calls**: [None | each choice the story and its design did not make, with where it is: `/story-done` asks you to keep or change each]
```

At `qa.level: standard` and `full`, add: "Run your test suite and confirm the new
tests pass before `/story-done`: it checks that the test file exists, and runs
nothing." At `minimal` leave that out: there are no tests to run. For a Visual/Feel
or UI story with no retained image, add: "A retained screenshot under
`production/qa/evidence/[story-slug]/` is required before `/story-done`" (and, for
Visual/Feel, the sign-off in `production/qa/evidence/[story-slug]-evidence.md`).

**`## Files`.** Replace the section's body with the list of changed code and test
files, one per line, as the Phase 3 ask said:
`bash .claude/scripts/md-section.sh replace <story> "Files"` with the list on stdin.
A story with no such section: add `## Files` and the list at its end, with a file
edit, never a shell command (a shell write skips the project's write checks). Skip
this when the Phase 3 ask was declined.

**The checkpoint**, on every outcome. Pipe the block to
`bash .claude/scripts/session-state.sh checkpoint`, which replaces the old one:

```
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /dev-story — [story path] ([title])
**Next step:** [the Next step below]
**Blocked on:** [nothing, or the blocker]
**Files in progress:** [changed files, comma-separated]
**Run result:** [OBSERVED — … | NOT VERIFIED — … | N/A — …, as in the closing block: /story-done reads it here]
**Same-seed run:** [a grown game only: SAME — … | CHANGED, accepted — … | CHANGED, not accepted — … | NOT ASSESSED — …]
**Own calls:** [the programmer's calls beyond the design, or none]
**Open questions:** [none, or one line each]
```

**The run's last reply ends with this block**, the only place the `Run result:` line
is printed: print it nowhere else in the reply. The Next step goes by the tier you stated in Phase 1 (the `workflow` line,
never `rigor` or `qa.level`). The Next step: at `minimal`, `/story-done [path]`. At `standard` and `full`,
`/code-review [files]`, then `/story-done [path]`. INCOMPLETE: `/dev-story [path]`
to resume. A same-seed run changed and not accepted is INCOMPLETE too: `/dev-story [path]`
after the fix. BLOCKED: the action that unblocks it (`/architecture-decision accept
ADR-NNNN`, the dependency to finish, the diff to review).

```
Story: [path] — [Implemented | INCOMPLETE — <breakage> | BLOCKED — <reason>]
Run result: [OBSERVED — … | NOT VERIFIED — … | N/A — …]
Same-seed run: [a grown game only, as in Phase 6]
Next step: [Implemented, Tier: workflow minimal → /story-done [path] | Implemented, Tier: workflow standard or full → /code-review [changed files], then /story-done [path] | INCOMPLETE → /dev-story [path] to resume | BLOCKED → the unblocking action]
```
