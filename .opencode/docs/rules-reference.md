# Path-Scoped Rules (OpenCode)

`.claude/rules/*.md` are the canonical path-scoped coding standards. Claude Code
loads them natively. OpenCode has no native equivalent, so the adapter injects a
rule into the session the first time an agent reads or edits a matching path.

## How it works

1. The plugin reads `.claude/rules/*.md` at setup.
2. It parses each file's `paths:` frontmatter.
3. On `tool.execute.before` for `read`, `write`, `edit`, or `patch`, it matches
   the target path against those globs.
4. The first match per session adds the rule body as a session instruction entry
   (`ccgs/rule/<name>`).

Matching supports `*`, `**`, `?`, and brace alternatives such as
`{Gameplay,gameplay}`. Paths are normalized to forward slashes and made relative
to the project root.

## Rule map

| Rule | Applies to |
|---|---|
| `agent-memory.md` | `.claude/agent-memory/**` |
| `ai-code.md` | `src/ai/**`, Unity/Unreal AI paths |
| `data-files.md` | `assets/data/**/*.json`, Unity/Unreal data paths |
| `design-docs.md` | `design/gdd/**` |
| `engine-code.md` | `src/core/**`, Unity/Unreal core paths |
| `gameplay-code.md` | `src/gameplay/**`, Unity/Unreal gameplay paths |
| `narrative.md` | `design/narrative/**` |
| `network-code.md` | `src/networking/**`, Unity/Unreal networking paths |
| `prototype-code.md` | `prototypes/**` |
| `scene-files.md` | `**/*.tscn`, `**/*.tres`, `**/*.unity`, `**/*.prefab`, `Assets/**/*.asset` |
| `shader-code.md` | `assets/shaders/**`, `**/*.gdshader`, Unity/Unreal shader paths |
| `skill-authoring.md` | `.claude/skills/**` |
| `test-standards.md` | `tests/**`, Unity/Unreal test paths |
| `ui-code.md` | `src/ui/**`, Unity/Unreal UI paths |

## Fallback

If the plugin is not loaded, `AGENTS.md` still tells agents to read the matching
rule before editing. The rule files are short and live in `.claude/rules/`.

## Why not load all rules at start?

The rules are small individually but add up, and most sessions touch only one or
two domains. Path-scoped injection keeps the baseline context low — important for
open models with 32k–64k windows — while still putting the rule in front of the
model before the edit that needs it.

## Adding a rule

1. Create `.claude/rules/<name>.md` with `paths:` frontmatter.
2. Add a row above.
3. Test the glob against a sample path.
4. No generator run is needed: the plugin reads the canonical directory.
