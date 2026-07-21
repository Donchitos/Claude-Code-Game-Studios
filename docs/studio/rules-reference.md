# Project Instruction Rules

Codex reads repository instructions from `AGENTS.md`. Instructions apply to the
directory containing the file and all descendants.

## Precedence

For a file being inspected or edited, read instruction files from broadest to
most specific:

1. Repository root `AGENTS.md`
2. Any parent-directory `AGENTS.md`
3. The nearest `AGENTS.md` governing the target file
4. A personal `AGENTS.override.md`, when present and applicable

When instructions conflict, the nearest applicable project instruction takes
precedence. User and system instructions still outrank repository files. A
nested rule should refine its parent rather than repeat the whole root file.

Example for `src/gameplay/combat/damage.gd`:

```text
AGENTS.md
src/AGENTS.md
src/gameplay/AGENTS.md
```

The gameplay file is the nearest rule for that path.

## Eleven Scoped Rule Sets

These files replace the framework's 11 path-scoped rule categories:

| Path | Governs | Primary concerns |
|---|---|---|
| `assets/data/AGENTS.md` | Structured game data | Schema safety, tunable values, validation, naming |
| `assets/shaders/AGENTS.md` | Shader assets | Performance budgets, compatibility, visual fallbacks |
| `design/gdd/AGENTS.md` | Game design documents | Required sections, consistency, decision traceability |
| `design/narrative/AGENTS.md` | Narrative content | Canon, voice, localization readiness, branching consistency |
| `prototypes/AGENTS.md` | Throwaway prototypes | Time-boxing, isolation, explicit promotion criteria |
| `src/ai/AGENTS.md` | Game AI code | Determinism, budgets, state behavior, debugging evidence |
| `src/core/AGENTS.md` | Core and engine-facing code | Architecture boundaries, lifecycle, performance, public APIs |
| `src/gameplay/AGENTS.md` | Gameplay code | Design fidelity, data-driven values, testable logic |
| `src/networking/AGENTS.md` | Multiplayer and networking code | Authority, validation, prediction, security, bandwidth |
| `src/ui/AGENTS.md` | UI code | Accessibility, input modes, layout behavior, performance |
| `tests/AGENTS.md` | Tests and evidence | Coverage, deterministic fixtures, negative paths, reporting |

## Umbrella Instruction Files

The repository also uses broader instruction files that organize multiple
scoped areas:

| Path | Purpose |
|---|---|
| `src/AGENTS.md` | Shared source-code expectations before subsystem rules apply |
| `design/AGENTS.md` | Shared design-document workflow and approval expectations |
| `docs/AGENTS.md` | Documentation templates, architecture records, and references |

These umbrella files do not increase the count of the 11 migrated scoped rule
sets.

## Adding Or Changing A Rule

1. Identify the smallest directory that genuinely needs distinct instructions.
2. Read all parent instruction files.
3. Add only the differences needed for that subtree.
4. Keep rules verifiable and tied to real files or commands.
5. Update this reference when the rule map changes.
6. Test the instruction against a representative task in that directory.

Avoid creating a nested `AGENTS.md` for hypothetical future paths. If one file
needs a temporary personal instruction, prefer an ignored local override rather
than committing a broad project rule.
