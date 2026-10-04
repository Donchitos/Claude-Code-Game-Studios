# Path-Specific Rules

Rules in `.claude/rules/` carry `paths:` frontmatter. Claude Code loads a
path-scoped rule **when it READS a file matching one of those globs** — not on
every tool use, and not when it creates one.

Three consequences, and none of them are optional reading:

1. **Reading, not editing.** A rule scoped to a gameplay folder reaches the
   model when a file there is opened. An agent that writes a brand-new file in that
   directory without opening an existing one never sees it. Most work in this
   framework creates files rather than reads them, so this is the common case,
   not the corner case.
2. **Context, not enforcement.** A loaded rule is guidance the model weighs, the
   same as `CLAUDE.md`. Anything that must hold regardless of what the model
   decides belongs in a hook — `.claude/hooks/` already enforces JSON validity
   and commit shape that way.
3. **A rule with no `paths:` loads every session**, at the same priority as
   `.claude/CLAUDE.md`. That is the lever for a rule that must always apply; it
   costs context in every session, so it is a deliberate trade, not a default.

Where a rule duplicates guidance an agent definition already carries, the two
must agree. Contradicting instructions are resolved arbitrarily, so a rule and
an agent stating different versions of the same standard is worse than either
alone.

To see which rules actually load, and why, wire the `InstructionsLoaded` hook —
`.claude/hooks/log-instructions.sh` records every instruction file and its load
reason (`session_start`, `path_glob_match`, `nested_traversal`, `include`,
`compact`) to `production/session-logs/instructions-loaded.log`.

**Globs match regardless of case.** Claude Code 2.1.282 matches `paths:`
gitignore-style and case-insensitively (observed; the docs do not say), so
`Assets/**/UI/**` also matches a Godot project's `assets/ui/` art. That is why
the Unity and Unreal code globs below name their file types.

Paths are listed Godot · Unity · Unreal. Folder names are shown in one case;
each rule's own globs list the case variants (`{AI,Ai,ai}`).

| Rule File | Path Pattern | Enforces |
| ---- | ---- | ---- |
| `gameplay-code.md` | `src/gameplay/**` · `Assets/**/Gameplay/**/*.cs` · `Source/**/Gameplay/**/*.{h,cpp}` | Data-driven values, delta time, no UI references |
| `engine-code.md` | `src/core/**` · `Assets/**/Core/**/*.cs` · `Source/**/Core/**/*.{h,cpp}` | Zero allocs in hot paths, thread safety, API stability |
| `ai-code.md` | `src/ai/**` · `Assets/**/AI/**/*.cs` · `Source/**/AI/**/*.{h,cpp}` | Performance budgets, debuggability, data-driven params |
| `network-code.md` | `src/networking/**` · `Assets/**/Network(ing)/**/*.cs` · `Source/**/Network(ing)/**/*.{h,cpp}` | Server-authoritative, versioned messages, security |
| `ui-code.md` | `src/ui/**` · `Assets/**/UI/**/*.cs` · `Source/**/UI/**/*.{h,cpp}` | No game state ownership, localization-ready, accessibility |
| `design-docs.md` | `design/gdd/**` | Required sections per `modes.workflow` (8 at `full`, 5 at `standard`), formula format, edge cases |
| `narrative.md` | `design/narrative/**` | Lore consistency, character voice, canon levels |
| `data-files.md` | `assets/data/**/*.json` · `Assets/**/Data/**/*.json` · `Content/**/Data/**/*.json` | JSON validity, naming conventions, schema rules |
| `test-standards.md` | `tests/**` · `Assets/Tests/**/*.cs` · `Source/**/Tests/**/*.{h,cpp}` | Test naming, coverage requirements, fixture patterns |
| `prototype-code.md` | `prototypes/**` | Relaxed standards, README required, hypothesis documented |
| `shader-code.md` | `assets/shaders/**`, `**/*.gdshader` · `Assets/**/*.{shader,hlsl,cginc,compute,shadergraph}` · `Shaders/**`, `**/*.{usf,ush}` | Naming conventions, performance targets, cross-platform rules |
| `agent-memory.md` | `.claude/agent-memory/**` | The one place an agent may write unasked — and why a temporary absence must never be recorded as a durable fact |
| `skill-authoring.md` | `.claude/skills/**`, `.claude/agents/**` | A check must be able to report that it did not run — the five obligations for verdicts, defaults, skips, sourcing and derived coverage |

Each engine-facing rule loads on all three engines:

- **Code rules** (`gameplay`, `engine`, `ai`, `network`, `ui`) match
  `Assets/**/<System>/**/*.cs` and `Source/**/<System>/**/*.{h,cpp}` (`Core`,
  `AI`, `Networking`/`Network`, `UI` for the others).
- **`data-files.md`** matches `Assets/**/Data/**/*.json` and `Content/**/Data/**/*.json`
  — JSON only, so C# or C++ in a `Data/` folder does not pick up its file-naming rule.
- **`shader-code.md`** matches shader files by type: `.gdshader`, `.shader`,
  `.hlsl`, `.cginc`, `.compute`, `.shadergraph`, `.usf`, `.ush`, plus `Shaders/**`.
- **`test-standards.md`** matches `Assets/Tests/**/*.cs` and `Source/**/Tests/**/*.{h,cpp}`.

> **`skill-authoring.md` is the odd one out and deliberately so.** Every other
> rule here scopes a *game* directory; that one scopes the **framework's own**
> authoring paths. It exists because one failure shape kept recurring across
> unrelated subsystems — a step that could not run producing output
> indistinguishable from a step that ran and found nothing. The same mistake in
> nine places is a missing design rule, not nine mistakes.
