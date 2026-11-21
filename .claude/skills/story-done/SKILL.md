---
name: story-done
description: "Closes a finished story: verifies each acceptance criterion, checks for design or ADR deviations and updates its status. Use when the user says a story is done, finished or ready to close."
argument-hint: "[story-file-path] [--review full|lean|solo]"
user-invocable: true
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Write, Edit, AskUserQuestion, Agent, Bash(bash "*/.claude/skills/story-done/../../hooks/yaml-helper.sh" resolve_config *), Bash(bash .claude/scripts/story-facts.sh *), Bash(bash .claude/scripts/story-status.sh*), Bash(bash .claude/scripts/adr-status.sh *), Bash(bash .claude/scripts/md-section.sh *), Bash(bash .claude/scripts/review-receipts.sh check *), Bash(bash .claude/scripts/session-state.sh *), Bash(git status --porcelain*), Bash(git add -- *), Bash(git commit -m *)
model: sonnet
---

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys review_mode,review_gate,automation,automation_always_ask,workflow,qa.level,gate_level,system_overrides`

Resolved above — use as-is; `--review` overrides `review_mode`. No block →
defaults in `.claude/docs/config-resolution.md`.

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

# Story Done

Closes a finished story. Every acceptance criterion is checked against evidence,
deviations from the GDD, the ADRs and the story's own scope are reported as facts,
and the story is marked Complete only on the user's yes.

**Writes, after the user's yes:** the story file (`Status`, `Last Updated`, a
`## Completion Notes` section) and its `production/sprint-status.yaml` entry;
`docs/tech-debt-register.md` only when the user picks that option; at `minimal`, the
brief's Features line the story finished; the story's row in its `EPIC.md`. The close
question names each file it will change. The session
checkpoint is written at the end of every run, whatever the verdict.
**Next:** the next story (Phase 8). `/dev-story` and `/story-done` start only when the person types them, so never offer to start one as an option: print it as a line to type.

Asks follow `.claude/docs/automation-modes.md` (collaborative always asks, guided
asks on major choices, autonomous logs and goes on; `automation_always_ask`
categories always ask).

Checklist (copy it and tick as you go):

```
- [ ] Phase 1: story found, facts and settings read
- [ ] Phase 2: what the story is checked against, loaded for its tier
- [ ] Phase 3: each criterion verified, traceability table built
- [ ] Phase 4: test evidence and run result checked
- [ ] Phase 5: deviations and scope checked; the AI's own calls kept or changed by the person
- [ ] Phase 6: review gates run, or their skip noted
- [ ] Phase 7: report and verdict shown; close asked
- [ ] Phase 8: next story named, checkpoint written, closing block printed
```

## Phase 1: The story and its settings

**Which story.** The text typed after the skill name, with any `--review <mode>`
pair removed, is the story path. With nothing typed:

1. The checkpoint in `production/session-state/active.md`: its **Current task**
   line, when it names a story.
2. Else the stories in progress: `bash .claude/scripts/story-facts.sh --all`, rows
   whose state is `IN_REVIEW` or `IN_PROGRESS`. Several: ask "Which story are we
   closing?" with one option per story.
3. None: ask for the path. When `production/epics/` holds no story file at all,
   stop:
   "No stories found in `production/epics/` — run `/create-stories [epic-slug]` to make them (at `standard` and `full`, run `/create-epics` first if there is no epic yet)."

**Its facts.** `bash .claude/scripts/story-facts.sh <story-path>` gives the status,
type, layer, TR-IDs, ADRs, criteria count, test-evidence status and dependencies.
Then read the story in full: the criteria text, the Test Evidence path, `## Files`,
Out of Scope.

**Tier.** `workflow` for the story's system, keyed on the GDD filename stem of its
`GDD:` path (`design/gdd/<stem>.md` → `<stem>`; the `[system]` of its TR-ID only
when there is no GDD path): that system's `system_overrides` row if there is one,
else the project value.

**What `qa.level` requires** (the evidence rows of `.claude/docs/coding-standards.md`).
Take the value from the `qa.level` line above, never from `workflow` or `rigor`: the
two are set apart, so `workflow: minimal` with `qa.level: standard` still requires a
Logic story's unit test.

| Check | `qa.level: minimal` | `qa.level: standard` | `qa.level: full` |
|---|---|---|---|
| Logic, Integration test | waived | required | required |
| Config/Data smoke report | waived | required, advisory by default | required, **blocking** by default |
| Visual/Feel, UI retained screenshot | required | required | required |
| Untested criteria (Phase 3) | never escalate | more than half block | **any** blocks |

The look is never waived: a Visual/Feel or UI story needs its screenshot at every
level. **Gate level** per type is the `gate_level` line above. At `full`, a
Config/Data default (`config=advisory(default…)`) becomes blocking; an explicit
`testing.strict.config: false` still makes it advisory.

## Phase 2: What the story is checked against

By the tier. Read every document by section, never whole.

- **`full`:** the current requirement text of each TR-ID: in
  `docs/architecture/tr-registry.yaml`, the lines matching `id: <TR-ID>\s*$` and the
  entry's text below (the anchor keeps `TR-combat-001` from matching
  `TR-combat-0010`; `\s*` takes a Windows line ending). Never use text quoted in the
  story; the GDD's Acceptance Criteria and Detailed Design
  (`bash .claude/scripts/md-section.sh extract design/gdd/<file>.md "Acceptance Criteria"`,
  then the same for `"Detailed Design"`; exit 3: try `"Detailed Rules"`, the design
  standard's name for the same section);
  each ADR's status with `bash .claude/scripts/adr-status.sh <ADR ids>`, then its
  Decision and Consequences sections.
- **`standard`:** the same GDD sections; the ADR sections only for a critical ADR
  (`adr-status.sh`'s layer column reads Foundation, or has no layer).
- **`minimal`:** none. The story's criteria are the spec.

At every tier, when `docs/architecture/control-manifest.md` exists, note its
`Manifest Version` line.

## Phase 3: Verify each criterion

Take each acceptance criterion in turn:

- **Checked by looking:** a file the criterion names exists; a test file it names
  exists (report "test file present", never "test passes": nothing here runs it);
  numeric literals in gameplay code that belong in data files; player-facing
  strings in the code root that belong in localization files (resolve the root
  per `.claude/docs/code-root-resolution.md`; unresolved, report `NOT ASSESSED —
  code root unresolved`, never zero hits).
- **Asked:** behaviour ("the player takes damage when…"), feel, and performance
  criteria. Never mark one passed from reading the code: the code says what should
  happen, not what the build does. Up to four per ask: "Does [criterion]?" Options:
  Yes — passes / No — fails / I'll check it when I play / Not tested yet.
  `I'll check it when I play` is `DEFERRED — requires playtest session`: it does not
  block. `Not tested yet` is UNTESTED, and keeps the verdict at best NOT ASSESSED until
  someone checks it. On a grown game, a criterion the same-seed run's screenshot plainly
  shows is seen on screen (below) and is not asked: `production/qa/evidence/grow-<name>/`
  `story.png`, or the image `/dev-story`'s OBSERVED line names, once you opened it.
- **Seen on screen:** a criterion about something visible is covered by a retained
  image under `production/qa/evidence/[story-slug]/` (`[story-slug]`: the story
  file's name without `.md`) that you opened and saw it in.
  Never describe an image you have not opened; a checkpoint's `Run result:
  OBSERVED — <text>` is `/dev-story`'s description, to quote as such.
- **Needs a full playtest:** `DEFERRED — requires playtest session`. It does not
  block.

Then map each criterion to what covers it: a test under the test root, a
"Yes — passes", or a retained image.

```
| Criterion | Covered by | Status |
|-----------|------------|--------|
| AC-1: [text] | tests/unit/[system]/[file]::[test] | COVERED |
| AC-2: [text] | production/qa/evidence/[slug]/01-[what].png | COVERED |
| AC-3: [text] | — | UNTESTED |
```

Untested criteria escalate by the Phase 1 table: blocking above the line; below it,
advisory, listed in the Completion Notes as "Untested criteria: [AC-N list]".

## Phase 4: Test evidence and the run result

By the story's type, at the Phase 1 gate level. Skip a check `qa.level` waives, and
say so: `Test evidence: waived at qa.level minimal`.

- **Logic:** the exact path in the story's Test Evidence section, else anywhere
  under `tests/unit/[system]/`.
- **Integration:** the same under `tests/integration/[system]/`, else a playtest
  record naming this story in `production/qa/playtests/` (`/playtest-report`
  writes them there).
- **UI:** a UI story is satisfied by the retained screenshot of each screen touched,
  under `production/qa/evidence/`. No evidence doc or sign-off needed.
- **Visual/Feel:** the screenshot, and a Visual/Feel story also needs the sign-off:
  `production/qa/evidence/[story-slug]-evidence.md` with every sign-off row
  `[x] Approved` (one person may sign every role).
- **Config/Data:** a `production/qa/smoke-*.md` report; none: "No smoke check
  report found. Run `/smoke-check`."
- **No Type:** advisory: "Story Type not declared. Add `Type:` to the story header."

A missing item is a gap at the gate level: BLOCKING stops COMPLETE, ADVISORY goes
in the notes. Name what is missing and where it goes. An evidence doc with no image
beside it is not evidence: a described check is an assertion.

**Is the evidence older than its code?** For a retained image, run
`bash .claude/scripts/review-receipts.sh check production/qa/evidence/[story-slug]/stamp.txt`.
Each `CHANGED:` or `GONE:` file: "[file] changed after the evidence was captured —
re-capture it." `RECEIPT: NONE`: "no stamp — whether the evidence is older than the
code cannot be told". Report these lines; they never change the verdict.

**Run result, every other type.** Take the `Run result:` line from the `/dev-story`
checkpoint (only when its **Current task** names this story) or the story's Completion Notes.
`OBSERVED` with a path: note it. `N/A — <reason>`: accept only a reason that says
why nothing is observable ("it's a Logic story" is not one). `NOT VERIFIED` on a
story whose criteria name something on screen: a gap at the gate level. No line:
advisory, "confirm the build was launched and looked at". A user's "Yes — passes"
to an on-screen criterion with no retained image is an assertion, not an
observation: a gap at the gate level.

**A grown game's same-seed run, every story type.** When
`production/qa/evidence/grow-<name>/replay.args` exists, take the `Same-seed run:` line
from the same checkpoint or Completion Notes. `SAME` or `CHANGED, accepted`: note it. `CHANGED, not accepted`: BLOCKING in every mode,
"this story changed how the game plays and the change was not accepted: fix it, then
`/dev-story [path]` plays the run again". No line: NOT ASSESSED, "the same-seed run was not
played after this story: `/dev-story [path]` plays it". `NOT ASSESSED — <reason>`: advisory,
with the reason.

## Phase 5: Deviations and scope

Run, by tier (`minimal` skips 1 and 3):

1. **GDD rules** (`full`; `standard` on its required sections): search the changed
   files for the names the current GDD text and TR requirement use.
2. **Manifest:** the story's `Manifest Version` older than the manifest's: ADVISORY,
   "written against manifest v[story]; current is v[current] — run
   `/story-readiness` to check". No manifest: skip. A `Manifest-Note:` line in the
   story is carried into the deviations as written.
3. **ADR constraints** (`full`; `standard` for a critical ADR): search for the
   patterns the ADR's Decision or the manifest forbids.
4. **Hardcoded values** in the changed files.
5. **Scope:** the files the story lists under `## Files` against the code and test
   files changed (`git status --porcelain`). A changed file the list does not name
   is OUT OF SCOPE. Leave out a file that a `Complete` story in the same epic lists under its
   `## Files`: it is that story's work, not committed yet. A story with no `## Files` section: use the checkpoint's
   **Files in progress** when its Current task names this story; else report
   `Scope: NOT ASSESSED — the story lists no files`. A clean working tree: report
   `Scope: not checked — no uncommitted changes to compare`.

Each deviation is **BLOCKING** (contradicts the GDD or ADR), **ADVISORY** (drifts
but works the same; the user decides) or **OUT OF SCOPE** (for awareness). State
them as facts; the user judges them.

**The AI's own calls.** Building a story means choosing things its design never
said: a value, a timing, a colour, what happens in a case nobody named, a word on
the screen. Those are the AI's calls, not the person's, and each one is shown
before the story closes. Read the story's changed files (the `## Files` list, or
the Scope step's list) beside what the story is built against (its criteria, and
the GDD or the brief), and take the `**Own calls:**` line from the `/dev-story`
checkpoint when its Current task names this story. List each choice a player
could notice, or a later story would have to agree with, that none of those says,
one plain line each with where it is: "Coins fall at 70 a second
(`data/config.json`); the brief names no speed." Code layout and names are not
calls. Then ask about each, in every automation mode, and wait for the answers
before Phase 6: the report shows each answer, and a call with no answer is not
kept. The question: "Keep this, or change it?"
Options: Keep it / Change it — say how. Several calls can share one question with
one option each to keep, and a free answer for the rest.

- **Kept:** recorded on the story on close (step 2 of the close).
- **Changed:** a BLOCKING item, "[call]: change it to [the person's words]". The
  story stays open; `/dev-story [path]` makes the change, and the next
  `/story-done` lists the calls again.
- **None found:** say `Own calls: none beyond the design`, naming what was read.
- **No changed files to read** (none listed and a clean tree): `Own calls: NOT
  ASSESSED — no changed files to read`, a NOT ASSESSED item.

## Phase 6: Review gates

Read the `review_gate` line above.

- **`skill-gates=skip`:** no agent. Note `QL-TEST-COVERAGE skipped — [Solo | Lean]
  mode` and `LP-CODE-REVIEW skipped — [Solo | Lean] mode`. In `lean` mode, ask: "Did
  you run `/code-review` on the implemented files?" Options: Yes — it passed or was
  approved with suggestions / No — skipping review for this story / No — I'll run
  it before the sprint close-out. The answer sets Reviewed by.
- **`skill-gates=run`:** read `references/review-gates.md` and
  `.claude/docs/director-gates.md`, and run both gates now. On a skip, do not load
  it.

**Reviewed by** is never blank: `lead-programmer` when LP-CODE-REVIEW ran;
`/code-review (you said you ran it; not verified here)` for the lean Yes; `self, no
independent review` in solo mode, for either No, and when no implementation file
exists yet.

## Phase 7: Report, verdict, and the close

```markdown
## Story Done: [title]
**Story**: [path] · **Type**: [type] · **Date**: [today]

### Acceptance Criteria: [X/Y passing]
- [x] [criterion] — [how verified]
- [ ] [criterion] — FAILS: [reason]
- [?] [criterion] — DEFERRED: requires playtest

### Traceability
[the Phase 3 table]

### Test Evidence
**Required**: [what the type needs at this qa.level, or "waived at qa.level minimal"]
**Found**: [YES — path | NO — BLOCKING | NO — ADVISORY]
**Same-seed run**: [a grown game only: the line /dev-story gave, or NOT ASSESSED — not played after this story]

### Deviations
[NONE, or each: BLOCKING / ADVISORY / OUT OF SCOPE — description — reference]

### Own calls
[each call: kept | change to <the person's words> (BLOCKING) · or "none beyond the design" · or NOT ASSESSED — why]

### Review
**Reviewed by**: [value]

### Verdict: [COMPLETE | COMPLETE WITH NOTES | NOT ASSESSED | BLOCKED]
```

**Verdicts, the first that matches wins:**

1. **BLOCKED:** a criterion fails, or a BLOCKING gap or deviation stands.
2. **NOT ASSESSED:** a criterion could not be evaluated: it names no observable
   outcome, the user answered "Not tested yet", a review gate returned NOT ASSESSED
   and its input was not supplied, evidence exists but cannot be read, or the GDD
   or ADR a deviation would be judged against is missing, or the own calls could
   not be read. Name each one and what
   would settle it. It outranks the two passes and never hides a failure.
3. **COMPLETE WITH NOTES:** every criterion passes or is DEFERRED, with advisory
   items listed. Information lines are not advisory items: the evidence-stamp
   lines, an absent sprint file and the run result never turn COMPLETE into COMPLETE
   WITH NOTES.
4. **COMPLETE:** every criterion passes, nothing advisory.

**Then ask, before writing anything:** "How do you want to proceed?" Options:
Close the story — mark it Complete and log notes (Recommended) / Close and log the
advisory deviations as tech debt / Don't close yet — I'll fix things first / Close
anyway, accepting the deviations. On BLOCKED or NOT ASSESSED, recommend "Don't close
yet" and list what must change. Closing such a story is a `scope_changes` decision:
when the `automation_always_ask` line lists it, ask in every automation mode, even
when the user's own request is what got here. Write only on an explicit choice to
close.

**On close:**

1. `bash .claude/scripts/md-section.sh set-field <story> Status Complete`, then
   `set-field <story> "Last Updated" <YYYY-MM-DD> --after Status`.
2. Add at the end of the story, with a file edit, never a shell command (a shell
   write skips the project's write checks):
   ```markdown
   ## Completion Notes
   **Completed**: [date]
   **Criteria**: [X/Y passing] ([deferred items])
   **Deviations**: [None, or the advisory ones]
   **Test Evidence**: [path, or "waived at qa.level minimal", or "none required"]
   **Reviewed by**: [value]
   **Same-seed run**: [a grown game only: the line as /dev-story gave it]

   ## Calls beyond the design
   - [each call the person kept, with where it is] · kept [date]
   ```
   With no calls, the section reads `- none beyond the design`.
3. "Close and log as tech debt": read `references/tech-debt-row.md` and add one
   row per advisory deviation.
4. `production/sprint-status.yaml`, when it exists: this story's entry gets
   `status: done` and `completed: [date]`, and the top-level `updated` gets today.
   The close answer covers it.
5. At `workflow: minimal`, when the story's Requirement reads `Brief MVP feature N`
   and it is the last story for item N that is not `Complete`, set that Features line in
   `design/game-brief.md` to `[x]`; a `deepen — <system>` story ticks the Features line
   that names its system, when one does. The brief is the design record that `/next-step`,
   `/create-stories` and `/cut` read.
6. On close, set this story's Status cell in `production/epics/[epic-slug]/EPIC.md`'s
   Stories table to `Complete`, when the table lists it.
7. Ask "Commit this story? (`feat: [story title]`)" with `Yes, commit` / `Not now`, in
   every mode, so each closed story is a point the person can go back to. On a yes, run
   git add -- [the story's `## Files` paths] [story path] (with any other file this close
   changed), then `git commit -m "feat: [story title] ([TR-ID])"`. Never `git add -A` or
   `.`: other changes stay out of it. The yes is the instruction a commit needs.

**On "Don't close yet":** change no story file. List what the user flagged. Never
fix a failing criterion yourself: report it and ask what to do.

## Phase 8: Next story, checkpoint, close

**The next story.** With no sprint plan in `production/sprints/` (always at
`workflow: minimal`): Run `bash .claude/scripts/story-status.sh` after the close, so
this story's new status is in it. It prints the unfinished stories in route order;
do not re-rank them. The first `In Review` story is next (the first `IN_REVIEW`
line), else the first `In Progress` one, else the first `Ready` or `Not Started`
one (`TODO`):

```
### Next Up
**[Story NNN: title]** — [one line]
Run `/story-done [path]` to close it (In Review) — else `/dev-story [path]` to implement it.
```

When the `workflow` line above reads `minimal`, print no `/story-readiness` line at
all, not even as an option: it is not on that path. With no sprint plan at
`workflow: standard` or `full`, add "Run `/story-readiness [path]` first."

- Only `COMPLETE N of N`: every story is built. Offer: play the build and note what
  feels wrong; say what to add next, in your own words, and `/create-stories` adds it to the
  brief's Features (with your yes) and makes its stories; or `/project-settings` to
  raise `modes.rigor` if the game has outgrown its brief.
- Only `BLOCKED`, `OTHER` or `NO_STATUS` lines left: there is no Next Up, and the
  build order is **not** done. Name each story with its blocker, `Draft` or `no
  status`.
- Never print the Sprint Close-Out Sequence on this branch: there is no sprint.

With a sprint plan: read `references/sprint-next.md`.

**The checkpoint**, on every verdict, closed or not. Pipe the block to
`bash .claude/scripts/session-state.sh checkpoint`, which replaces the old block:

```
**Updated:** [date]
**Branch:** `[current git branch]`
**Current task:** /story-done — [story path]: [verdict], [closed | left open]
**Next step:** [the Next Up command, or the fix the verdict named]
**Blocked on:** [nothing, or what blocked the verdict]
**Files in progress:** none
**Open questions:** [tech debt logged: N items, or none]
```

**The run's last reply ends with this block** (repeat it if you showed it earlier):

```
Verdict: [COMPLETE | COMPLETE WITH NOTES | NOT ASSESSED | BLOCKED] — [story path]
Story: [closed — Status: Complete | left open — Status: [status]]
Review: [Reviewed by value; the gates' skip notes]
Next step: [/dev-story [path] | /story-done [path] | the fix | play the build]
```
