---
name: setup-engine
description: "Sets up and pins the engine version: web for a new project unless Godot, Unity or Unreal is named. Use to choose or upgrade it."
argument-hint: "[engine] | [engine version] | refresh | upgrade [old-version] [new-version] | no args for guided selection"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, WebFetch, Agent, AskUserQuestion, Bash(bash "*/.claude/skills/setup-engine/../../hooks/yaml-helper.sh" resolve_config *), Bash(godot --version), Bash(godot --headless --path . --import), Bash(command -v godot), Bash(uname -s), Bash(bash .claude/scripts/project-coherence.sh*), Bash(node --version), Bash(npm ci*), Bash(npm run build*), Bash(bash .claude/scripts/web-scaffold.sh*), Bash(bash .claude/scripts/web-detect.sh*), Bash(pnpm install --frozen-lockfile*), Bash(yarn install --frozen-lockfile*), Bash(yarn install --immutable*), Bash(bun install --frozen-lockfile*), Bash(pnpm run build*), Bash(yarn run build*), Bash(bun run build*), Bash(bash .claude/scripts/test-run.sh web*), Bash(bash .claude/scripts/page-shot.sh *)
model: sonnet
---

# Engine Setup

When this skill is invoked:

!`bash "${CLAUDE_SKILL_DIR}/../../hooks/yaml-helper.sh" resolve_config --keys workflow`

**Tier awareness.** The `workflow` tier resolved above governs which design
artifact this skill expects and the finish path it recommends in §12:
- **`minimal`** — the design artifact is the one-page `design/game-brief.md`
  (no GDDs, systems decomposition, or per-system design at this tier).
  `/setup-engine` runs *first* in the minimal path, so a missing brief here is
  normal, not a gap. The finish path is the 4-step floor.
- **`standard` / `full`** — the design artifact is `design/gdd/game-concept.md`
  and the finish path is the full pipeline.

If the block did not render (shell preprocessing disabled), assume `minimal` (the default).

Ask with the question tool. Without one, list the options numbered and end your turn
to wait. A skipped or dismissed question is not an answer: ask again in plain text.

## 1. Parse Arguments

Modes:

- **Full spec**: `/setup-engine godot 4.7` — engine and version provided
- **Engine only**: `/setup-engine unity` — engine provided, version will be looked up
- **Web**: `/setup-engine web` — a browser game with Vite and TypeScript, at the
  versions the web scaffold pins, or an existing web project (a `package.json`),
  recorded as it is. **Read `references/web.md` now and follow it**:
  it replaces Sections 3, 6, 7 and 7.5 for Web and gives the values Sections 4, 5
  and 5.5 write
- **No args**: `/setup-engine` — guided mode: an existing project keeps its engine;
  a new one is offered web first (Section 2)
- **Refresh**: `/setup-engine refresh` — update reference docs (see Section 10)
- **Upgrade**: `/setup-engine upgrade [old-version] [new-version]` — migrate to a new engine version (see Section 11)

---

## 2. Guided Mode (No Arguments)

**Read `references/2-guided-mode.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 3. Look Up Current Version

**Read `references/3-version.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 4. Update CLAUDE.md Technology Stack

**Read `references/4-claude-md-stack.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5. Populate Technical Preferences

**Read `references/5-technical-preferences.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 5.5 Populate `project.yaml` (Primary Config Store)

**Read `references/5.5-project-yaml.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 6. Determine Knowledge Gap

**Read `references/6-knowledge-gap.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7. Populate Engine Reference Docs

**Read `references/7-reference-docs.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 7.5 Scaffold the Engine Project

**Read `references/7.5-scaffold.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 8. Verify the CLAUDE.md Import

**Read `references/8-verify.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 9. Update Agent Instructions

On Web there is no engine specialist agent: skip this section and say so
(`references/web.md`, W7).

Ask: "May I add a Version Awareness section to the engine specialist agent files?" before making any edits.

For the chosen engine's specialist agents, verify they have a
"Version Awareness" section. If not, add one following the pattern in
the existing Godot specialist agents.

The section should instruct the agent to:
1. Read `docs/engine-reference/<engine>/VERSION.md`
2. Check deprecated APIs before suggesting code
3. Check breaking changes for relevant version transitions
4. Search the web to verify uncertain APIs

---

## 10. Refresh Subcommand

If invoked as `/setup-engine refresh`:

1. Read the existing `docs/engine-reference/<engine>/VERSION.md` to get
   the current engine and version
2. Search the web for:
   - New engine releases since last verification
   - Updated migration guides
   - Newly deprecated APIs
3. Update all reference docs with new findings
4. Update "Last verified" dates on all modified files
5. Report what changed

---

## 11. Upgrade Subcommand

**Read `references/11-upgrade.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## 12. Output Summary

**Read `references/12-output-summary.md` now and follow it** — this phase's steps are in that file, not here. Read it again if the conversation was compacted or resumed during this phase.

## Guardrails

- Check the engine version (web search or the user's word): a guessed pin breaks APIs
- `project.yaml` is the primary config store. Always dual-write engine
  config to BOTH `project.yaml` (primary) and `technical-preferences.md` (legacy
  mirror). If the two ever diverge, `project.yaml` is authoritative.
- Ask before overwriting reference docs (they hold checked notes); append or update
- If reference docs already exist for a different engine, ask before replacing
- Always show the user what you're about to change before making CLAUDE.md edits
- If a web search returns ambiguous results, show the user and let them decide
- When the user chose **GDScript**: copy the GDScript CLAUDE.md template from **A1** in `references/godot-language-config.md` exactly. Do not add "C++ via GDExtension" to the Language field. GDScript projects may use GDExtension, but it is not a primary project language. The `godot-gdextension-specialist` in the routing table is available for when native extensions are needed — it does not make C++ a project language.

---

## Appendix A — Godot Language Configuration

Moved out of this file so it costs nothing on non-Godot runs.

**When the chosen engine is Godot, read**
`references/godot-language-config.md`
and use the subsection for the chosen language:

- **A1** — CLAUDE.md Technology Stack templates (GDScript / C# / Both)
- **A2** — naming conventions
- **A3** — engine specialist routing and file-extension tables

**Load discipline.** On any engine other than Godot, **never load it** — nothing in Sections 4, 5 or 5.5 needs it, and reading it anyway spends the tokens the split exists to save. On Godot, read it once when you first reach Section 4 and keep using it for Sections 5 and 5.5; do not re-read it at each reference.
