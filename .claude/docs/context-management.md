# Context Management

Context is the most critical resource in a Claude Code session. Manage it actively.

## File-Backed State (Primary Strategy)

**The file is the memory, not the conversation.** Conversations are ephemeral and
will be compacted or lost. Files on disk persist across compactions and session crashes.

### Session State File

Maintain `production/session-state/active.md` as a living checkpoint. Update it
after each significant milestone:

- Design section approved and written to file
- Architecture decision made
- Implementation milestone reached
- Test results obtained

**Create it from `.claude/docs/templates/session-state.md`** — the file has a
schema, and hooks depend on it.

Two regions, and the distinction is load-bearing:

| Region | Who reads it | Rule |
|--------|--------------|------|
| `<!-- STATUS -->` … `<!-- /STATUS -->` | `statusline.sh` (breadcrumb, Production+ only) | Keep the markers even when empty |
| `<!-- CHECKPOINT -->` … `<!-- /CHECKPOINT -->` | `session-start.sh` (every start, including after a compaction) | **Overwrite, never append.** Under ~25 lines — shown verbatim |
| Everything after `<!-- /CHECKPOINT -->` | humans, and an agent that wants detail | Free-form; no hook injects it |

The checkpoint holds: current task, next step, what it is blocked on, files in
progress, open questions. Write it so a cold reader can resume without opening
anything else.

> **Why the split.** One append-only file doing both jobs grows without bound —
> past 700 lines every consumer invents its own slice: a status line parsing a
> STATUS block nothing writes, `pre-compact` injecting `head -100` (12.7 KB, at
> the moment context is scarcest), `session-start` previewing `tail -20` — the
> opposite end. None was wrong, because nothing defined where
> the recoverable state lived. Now every consumer reads the named region, and
> the cost is fixed no matter how long the narrative grows.

**Rotation.** When the narrative passes ~200 lines, move it into
`production/session-logs/`:

```bash
bash .claude/scripts/rotate-session-state.sh            # --dry-run to preview
```

The checkpoint stays, the narrative is appended to a dated log, nothing is
deleted. `session-start.sh` observes when rotation is due but never performs it.

### Status Line Block (Production+ only)

When the project is in Production, Polish, or Release stage, include a structured
status block in `active.md` that the status line script can parse. (The project
stage is resolved from `project.stage` in `project.yaml`, falling back to
`production/stage.txt`.)

```markdown
<!-- STATUS -->
Epic: Combat System
Feature: Melee Combat
Task: Implement hitbox detection
<!-- /STATUS -->
```

- All three fields (Epic, Feature, Task) are optional — include only what applies
- Update this block when switching focus areas
- The status line displays it as a breadcrumb: `Combat System > Melee Combat > Hitboxes`
- Remove or empty the block when no active work focus exists

After any disruption (compaction, crash, `/clear`), read the state file first.

### Incremental File Writing

When creating multi-section documents (design docs, architecture docs, lore entries):

1. Ask to create the file ("May I create [path] with the section skeleton?"), then
   create it with every section header and empty bodies
2. Discuss and draft one section at a time in conversation
3. Write each section to the file as soon as it's approved (a skill that writes
   once at the end, such as `/create-architecture`, records approved sections in
   the session state instead)
4. Update the session state file after each section
5. After writing a section, previous discussion about that section can be safely
   compacted — the decisions are in the file

This keeps the context window holding only the *current* section's discussion
(~3-5k tokens) instead of the entire document's conversation history (~30-50k tokens).

## Proactive Compaction

- **Compact proactively** at ~60-70% context usage, not reactively at the limit
- **Use `/clear`** between unrelated tasks, or after 2+ failed correction attempts
- **Natural compaction points:** after writing a section to file, after committing,
  after completing a task, before starting a new topic
- **Focused compaction:** `/compact Focus on [current task] — sections 1-3 are
  written to file, working on section 4`

## Context Budgets by Task Type

- Light (read/review): ~3k tokens startup
- Medium (implement feature): ~8k tokens
- Heavy (multi-system refactor): ~15k tokens

## Deterministic Helpers — `.claude/scripts/`

The cheapest context saving is not summarising a document, it is **not reading it
at all**. When a question has a deterministic answer, a script should answer it
and the model should spend its budget on judgment instead.

Two directories, two purposes — reach for the right one:

| Directory | Purpose | Invoked by |
|---|---|---|
| `.claude/hooks/` | Event-driven — wired into `settings.json` and fired by Claude Code | the harness |
| `.claude/scripts/` | Manually invoked from a skill body | `bash .claude/scripts/<name>.sh` |

Current helpers:

- **`gdd-structure-check.sh`** — which of the 8 standard sections a GDD contains.
  Replaces a full-document read per GDD, and cannot hallucinate a missing
  section. Reports **presence only**; the caller applies the workflow tier.
- **`review-scope.sh`** — which GDDs changed since the last cross-review, plus
  their declared dependencies. Replaces reasoning through git history.

Two rules when adding one:

1. **Grant it the way `.claude/docs/config-resolution.md` shows.** `allowed-tools`
   pre-approves commands; it does not restrict them — a skill without the grant
   still runs the script, after a permission prompt. An injected `` !`cmd` `` in
   the body is stricter: unapproved, it aborts the whole invocation, so it needs
   the exact grant that doc gives.
2. **Emit observations, not verdicts.** A script that scores or judges will
   eventually contradict a tier, mode, or per-system override it does not know
   about. Report what is on disk and let the caller decide what it means.

## Subagent Delegation

Use subagents for research and exploration to keep the main session clean.
Subagents run in their own context window and return only summaries:

- **Use subagents** when investigating across multiple files, exploring unfamiliar code,
  or doing research that would consume >5k tokens of file reads
- **Use direct reads** when you know exactly which 1-2 files to check
- Subagents do not inherit conversation history — provide full context in the prompt

## Compaction Instructions

When context is compacted, preserve the following in the summary:

- Reference to `production/session-state/active.md` (read it to recover state)
- List of files modified in this session and their purpose
- Any architectural decisions made and their rationale
- Active sprint tasks and their current status
- Agent invocations and their outcomes (success/failure/blocked)
- Test results (pass/fail counts, specific failures)
- Unresolved blockers or questions awaiting user input
- The current task and what step we are on
- Which sections of the current document are written to file vs. still in progress

**After compaction:** Read `production/session-state/active.md` and any files being
actively worked on to recover full context. The files contain the decisions; the
conversation history is secondary.

## Recovery After Session Crash

If a session dies ("prompt too long") or you start a new session to continue work:

1. The `session-start.sh` hook will detect and preview `active.md` automatically
2. Read the full state file for context
3. Read the partially-completed file(s) listed in the state
4. Continue from the next incomplete section or task
