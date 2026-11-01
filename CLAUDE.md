# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 49 coordinated specialist agents, operating under the universal AI-Native SDLC standard.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Global AI-Native SDLC & Multi-Agent Standards

This project adheres to the universal vendor-neutral AI lifecycle and multi-agent specifications:
- **Universal Multi-Agent Roster & Protocol**: @AGENTS.md
- **Universal AI-Native SDLC 6-Phase Standard**: @SDLC.md
- **Deterministic Validation & Runner**: `python tools/sdlc/runner.py test`
- **Multi-Agent Task & Write-Scope Orchestrator**: `python tools/sdlc/orchestrator.py`

## Technology Stack

- **Engine**: Godot 4.7.2 Stable (Forward+ / Jolt Physics)
- **Language**: GDScript (Strict Static Typing, `@export`, Signal Contracts)
- **Multiplayer**: High-Level Multiplayer (`ENetMultiplayerPeer`, Server-Authoritative Host, 2-4 Player Scaling, Hybrid Roles, Zero Friendly Fire)
- **Version Control**: Git with trunk-based development
- **Test Runner**: Headless Engine Testing (`python -B tools/sdlc/runner.py test`)
- **Automated Godot Skills Router**: `@AGENTS.md#7-godot-47-otomatik-yetenek-ve-uzmanlik-katalogu`

> **Note**: Engine-specialist agents for Godot 4.7 automatically auto-load matching
> skills based on task context without requiring manual user dispatch.

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

<!-- ENGINE-REFERENCE-IMPORT: the line below is engine-specific. /setup-engine
     rewrites it to @docs/engine-reference/<engine>/VERSION.md for the chosen
     engine, so a Unity or Unreal project stops loading the Godot reference every
     session. It defaults to Godot (the template's example engine); skills that
     need the pinned version read docs/engine-reference/<engine>/VERSION.md on
     demand regardless of this import. -->
@docs/engine-reference/godot/VERSION.md


## Technical Preferences

`project.yaml` at the repo root is the primary config store — engine, specialists,
naming, platform, performance, modes. Skills resolve it via `resolve_config`
(see `.claude/docs/config-resolution.md`).

`.claude/docs/technical-preferences.md` is the **legacy fallback**, read on demand
when a key is absent from `project.yaml`. It is not imported here: before
`/setup-engine` runs it is almost entirely `[TO BE CONFIGURED]` placeholders, and
after it runs `project.yaml` holds the real values.

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
  (exempt: `active.md` appends, agent memory, a subagent's new file at the path
  its orchestrating skill named; see `.claude/rules/agent-memory.md`)
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction
- A skipped or dismissed question is not an answer: act on nothing, re-ask in
  plain text and wait
- Started outside this file's folder? Warn first: hooks, deny rules and the
  ask-first mode load only when Claude Code starts here

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

Read `.claude/docs/context-management.md` on demand — it is a reference, not
session context. Two of its conventions are load-bearing and cited by name
elsewhere in the repo, so they are restated here rather than lost:

- **`production/session-state/active.md` is the session checkpoint.** The file is
  the memory, not the conversation. Read it first after any compaction, crash, or
  `/clear`.
- **Helpers in `.claude/scripts/` emit observations, never verdicts.** A script
  that scores or judges will eventually contradict a mode or override it cannot
  see. (Cited by `artifact-check.sh` and `adr-dep-graph.sh`.)
