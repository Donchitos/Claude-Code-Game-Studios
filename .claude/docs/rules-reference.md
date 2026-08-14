# Path-Specific Rules

Rules in `.claude/rules/` are automatically enforced when editing files in matching paths:

| Rule File | Path Pattern | Enforces |
| ---- | ---- | ---- |
| `gameplay-code.md` | `src/gameplay/**` | Data-driven values, delta time, no UI references |
| `engine-code.md` | `src/core/**` | Zero allocs in hot paths, thread safety, API stability. **Web:** GC pressure, explicit GPU disposal, renderer-independent simulation |
| `ai-code.md` | `src/ai/**` | Performance budgets, debuggability, data-driven params |
| `network-code.md` | `src/networking/**` | Server-authoritative, versioned messages, security |
| `ui-code.md` | `src/ui/**` | No game state ownership, localization-ready, accessibility. **Web:** DOM-vs-canvas choice, pointer events, `100dvh`, safe areas |
| `design-docs.md` | `design/gdd/**` | Required 8 sections, formula format, edge cases |
| `narrative.md` | `design/narrative/**` | Lore consistency, character voice, canon levels |
| `data-files.md` | `assets/data/**` | JSON validity, naming conventions, schema rules |
| `test-standards.md` | `tests/**` | Test naming, coverage requirements, fixture patterns |
| `prototype-code.md` | `prototypes/**` | Relaxed standards, README required, hypothesis documented. **Web:** prototype/production convergence trap |
| `shader-code.md` | `assets/shaders/**` | Naming conventions, performance targets, cross-platform rules. **Web:** WebGPU/WebGL2 backend parity, TSL vs raw GLSL |

## Engine-specific sections

Four rules carry an engine-specific section in addition to their engine-agnostic
core: `engine-code.md`, `ui-code.md`, `prototype-code.md`, and `shader-code.md`.

These sections exist because some constraints have no cross-engine equivalent.
On the web, for example, GPU resources are never freed automatically, a shader
that supplies only one backend language silently breaks for a subset of players,
and a prototype runs on the *shipping* stack rather than a throwaway proxy — so
"rewrite, don't migrate" loses its natural enforcement.

The rule set stays path-scoped by domain rather than by engine. There is no
`web-code.md`, because a rule scoped to `src/**/*.ts` would overlap the existing
path scopes and produce contradictory guidance on the same files.
