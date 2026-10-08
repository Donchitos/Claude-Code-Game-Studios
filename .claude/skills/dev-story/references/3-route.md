# /dev-story — Phase 3: Route to the Right Programmer

> Part of `/dev-story`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 3: Route to the Right Programmer

Based on the story's **Layer**, **Type**, and **system name**, determine which
specialist to spawn via `Agent`.

**Config/Data stories — skip agent spawning entirely:**
If the story's Type is `Config/Data`, no programmer agent or engine specialist is needed. Jump directly to Phase 4 (Config/Data note). The implementation is a data file edit — no routing table evaluation, no engine specialist.

### Primary agent routing table

| Story context | Primary agent |
|---|---|
| Foundation layer — any type | `engine-programmer` |
| Any layer — Type: UI | `ui-programmer` |
| Any layer — Type: Visual/Feel | `gameplay-programmer` (implements) |
| Core or Feature — gameplay mechanics | `gameplay-programmer` |
| Core or Feature — AI behaviour, pathfinding | `ai-programmer` |
| Core or Feature — networking, replication | `network-programmer` |
| Config/Data — no code | No agent needed (see Phase 4 Config note) |

### Engine specialist — always spawn as secondary for code stories

**Read the `specialists` block from `project.yaml` directly — it is not in
the `resolve_config` output at the top of this skill..** `resolve_config` does not emit
`specialists.*`; the five skills that already consume it (`/adopt`,
`/code-review`, `/design-system`, `/gate-check`, `/team-ui`) all read the block
out of `project.yaml` themselves, and so does this one. Adding it to the
frontmatter key list would fail the gate that asserts every requested key is one
`resolve_config` actually emits.

`/setup-engine` writes the block, and it is the project's own answer to "which
specialist implements here" — resolved from the engine *and the language*, which
`engine.name` alone cannot tell you. Resolve in this order:

1. **`specialists.code`** — the language/code specialist, and the right secondary
   for an implementation story. This is the value that distinguishes a Godot C#
   project (`godot-csharp-specialist`) from a Godot GDScript one
   (`godot-gdscript-specialist`); `engine.name` is `Godot` for both.
2. **`specialists.shader`** when the story touches shaders or materials, and
   **`specialists.ui`** when the story's Type is `UI` — in addition to, not
   instead of, `specialists.code`.
3. **The generic `<engine>-specialist`** — derived from `engine.name`
   (Godot→`godot-specialist`, Unity→`unity-specialist`,
   Unreal→`unreal-specialist`) — for architecture-level and broad engine
   concerns, and as the fallback when the `specialists` block is absent.
4. If `engine.name` is also absent or empty, read the Primary line of the
   `## Engine Specialists` section of `.claude/docs/technical-preferences.md`.

**A value of `null` means UNSET — treat that key as absent and fall through to
the generic specialist. Never spawn it as an agent name.** The config reader
returns the four-character string `"null"`, which is not empty and therefore
reads as configured; `null`, empty and missing are the same state here. (This is
the same caveat `/code-review` Phase 2 carries, for the same reason.)

Spawn the resolved specialist alongside the primary agent when the story involves
engine-specific APIs, patterns, or the ADR has HIGH engine risk.

The full roster, for reference when no `specialists` block exists:

| Engine | Specialist agents available |
|--------|----------------------------|
| Godot 4 | `godot-specialist`, `godot-gdscript-specialist`, `godot-csharp-specialist`, `godot-shader-specialist`, `godot-gdextension-specialist` |
| Unity | `unity-specialist`, `unity-ui-specialist`, `unity-shader-specialist`, `unity-dots-specialist`, `unity-addressables-specialist` |
| Unreal Engine | `unreal-specialist`, `ue-gas-specialist`, `ue-blueprint-specialist`, `ue-umg-specialist`, `ue-replication-specialist` |

> **Do not pick from this table when `specialists` is set.** The table lists what
> *exists* for an engine; the block records what this project *chose*. Reading the
> table instead of the block is how a Godot C# project ends up reviewed by the
> GDScript specialist.

**When engine risk is HIGH** (from the ADR or VERSION.md): always spawn the engine
specialist, even for non-engine-facing stories. High risk means the ADR records
assumptions about post-cutoff engine APIs that need expert verification.

> **Read the risk, do not trust the story card alone.** If the story's `Risk`
> field is absent, or says `NOT ASSESSED`, **or disagrees with
> `docs/engine-reference/<engine>/VERSION.md`, the VERSION.md rating wins** and an
> unknown counts as HIGH. At `minimal` there is no ADR, so VERSION.md is the only
> source; a story card carrying an improvised `MEDIUM` against a VERSION.md
> rating of HIGH would skip this spawn without saying so. `/create-stories` now derives the field
> from the same file, so the two should agree; this check is what catches it when
> they do not.

---
