---
name: setup-tool
description: "Configure a game development tooling project (asset processor, level generator, data exporter, etc.). Captures the tool's purpose, I/O contract, and tech stack in TOOL_SPEC.md — the tooling equivalent of a game concept doc."
argument-hint: "[tool name] or no args for guided setup"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, WebSearch, Task
---

When this skill is invoked:

## 1. Parse Arguments

Two modes:

- **Named**: `/setup-tool [tool name]` — tool name provided, guided questions follow
- **No args**: `/setup-tool` — fully guided mode

---

## 2. Detect Existing State

Before asking questions, silently check:

- Does `tools/TOOL_SPEC.md` already exist? → Read it and offer to **update** rather than
  create from scratch. Ask: "I found an existing spec — want to review and update it,
  or start fresh?"
- Does `CLAUDE.md` already reference a game engine? → This project may be a full game
  project with a tooling component, not a pure tooling project. Note this to the user.
- Are there existing scripts in `tools/`? → Offer to run `/reverse-document` afterward
  to generate the spec from the existing code instead of writing it manually.

---

## 3. Ask Key Questions

If creating fresh, ask these questions one group at a time (don't dump all at once):

**Group 1 — Purpose**
> "What does this tool do? One sentence is enough."
> "What problem does it solve in your workflow? Where does it sit in the pipeline?"

**Group 2 — Target Engine & Formats**
> "Which engine does this tool serve? (Unity / Godot / Unreal / engine-agnostic)"
> "What file formats does it read and write?"
> Examples to prompt: Unity `.asset` / `.prefab`, Godot `.tres` / `.res`,
> custom JSON/CSV, Blender `.blend`, etc.

**Group 3 — Tech Stack**
> "What language or runtime? (Python, C#, Node.js, Rust, etc.)"
> "Any key libraries or dependencies?"
> "Does it run standalone (CLI / GUI) or inside the engine as an editor plugin?"

**Group 4 — I/O Contract**
> "What are the inputs? (file paths, flags, config files?)"
> "What are the outputs? (new files, modified files, printed report?)"
> "Are there any known edge cases or failure modes the tool must handle?"

---

## 4. Draft TOOL_SPEC.md

After gathering answers, draft the spec in conversation — do NOT write to file yet.

```markdown
# TOOL_SPEC.md — [Tool Name]

## Purpose

[One-paragraph summary of what the tool does and why it exists]

## Pipeline Position

[Where in the game development workflow this tool fits]
Example: "Runs between the content structuring stage and the gameplay data generation stage."

## Target Engine

| Field          | Value                  |
|----------------|------------------------|
| Engine         | [Unity / Godot / etc.] |
| Engine Version | [version if known]     |
| File Formats   | [list of formats read/written] |

## Tech Stack

| Field        | Value              |
|--------------|--------------------|
| Language     | [Python / C# / etc.] |
| Runtime      | [standalone CLI / editor plugin / etc.] |
| Dependencies | [libraries and versions] |

## I/O Contract

### Inputs
- [input 1]: [description]
- [input 2]: [description]

### Outputs
- [output 1]: [description]

### Flags / Config
- [flag or config option]: [description]

## Usage

```bash
[example command]
```

## Known Edge Cases

- [edge case 1]
- [edge case 2]

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| [decision] | [why] |
```

Show the draft to the user:
> "Here's the spec I'd write to `tools/TOOL_SPEC.md`. Want to adjust anything
> before I save it?"

Wait for approval. Write only after explicit confirmation.

---

## 5. Update CLAUDE.md Technology Stack

Read `CLAUDE.md` and update the Technology Stack section to reflect the tooling
project (replacing the engine placeholders):

```markdown
## Technology Stack

- **Project Type**: Game Development Tool (not a game itself)
- **Tool**: [Tool Name] — [one-line purpose]
- **Language**: [language]
- **Runtime**: [standalone CLI / editor plugin / etc.]
- **Target Engine**: [engine and version]
- **Key Dependencies**: [libraries]
- **Build System**: N/A (scripting tool)
- **Asset Pipeline**: N/A
```

Ask before writing:
> "May I also update the Technology Stack section in CLAUDE.md to reflect this
> tooling project?"

---

## 6. Suggest Next Steps

After writing the spec, output:

```
Tool Setup Complete
===================
Spec:      tools/TOOL_SPEC.md  [written]
CLAUDE.md: Technology Stack    [updated]

Next Steps:
1. If the tool already exists:
   → /reverse-document to generate architecture docs from existing code
   → Read tools/TOOL_SPEC.md alongside the code to verify the spec is accurate

2. If starting from scratch:
   → Open your editor and start building in tools/
   → Run /code-review once the first working version exists

3. To document design decisions as you build:
   → /architecture-decision [decision name]

4. When the tool is stable:
   → Update tools/TOOL_SPEC.md with any edge cases discovered during testing
```

---

## Guardrails

- NEVER overwrite an existing `TOOL_SPEC.md` without reading it first and asking
- NEVER assume the engine format — always confirm with the user
- Always show the draft spec before writing
- If the user has existing code, strongly recommend `/reverse-document` to verify
  that the spec matches reality

---

## Collaborative Protocol

1. **Detect first** — check what already exists before asking questions
2. **Ask in groups** — don't dump all questions at once
3. **Draft before write** — always show the spec before saving
4. **User approves** — no file writes without confirmation
