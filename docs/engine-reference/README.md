# Engine Reference Documentation

This directory contains curated, version-pinned documentation snapshots for the
game engine(s) used in this project. These files exist because **LLM knowledge
has a cutoff date** and game engines update frequently.

## Why This Exists

Claude's training data has a knowledge cutoff (currently May 2025). Game engines
like Godot, Unity, and Unreal ship updates that introduce breaking API changes,
new features, and deprecated patterns. Without these reference files, agents will
suggest outdated code.

**Web projects are a special case.** The `web/` directory pins a *stack*
(PixiJS, Three.js, TypeScript, Vite, Node) rather than a single binary, and its
knowledge-gap risk is **permanently HIGH** — Three.js ships roughly monthly and
removes deprecated code in most releases, so any model cutoff will always sit
several releases behind. Risk is assessed per library, not once for the stack.
Web reference docs are never optional.

## Structure

Each engine gets its own directory:

```
<engine>/
├── VERSION.md              # Pinned version, verification date, knowledge gap window
├── breaking-changes.md     # API changes between versions, organized by risk level
├── deprecated-apis.md      # "Don't use X → Use Y" lookup tables
├── current-best-practices.md  # New practices not in model training data
└── modules/                # Per-subsystem quick references (~150 lines max each)
    ├── rendering.md
    ├── physics.md
    └── ...
```

## How Agents Use These Files

Engine-specialist agents are instructed to:

1. Read `VERSION.md` to confirm the current engine version
2. Check `deprecated-apis.md` before suggesting any engine API
3. Consult `breaking-changes.md` for version-specific concerns
4. Read relevant `modules/*.md` for subsystem-specific work

## Maintenance

### When to Update

- After upgrading the engine version
- When the LLM model is updated (new knowledge cutoff)
- After running `/refresh-docs` (if available)
- When you discover an API the model gets wrong

### How to Update

1. Update `VERSION.md` with the new engine version and date
2. Add new entries to `breaking-changes.md` for the version transition
3. Move newly deprecated APIs into `deprecated-apis.md`
4. Update `current-best-practices.md` with new patterns
5. Update relevant `modules/*.md` with API changes
6. Set "Last verified" dates on all modified files

### Quality Rules

- Every file must have a "Last verified: YYYY-MM-DD" date
- Keep module files under 150 lines (context budget)
- Include code examples showing correct/incorrect patterns
- Link to official documentation URLs for verification
- Only document things that differ from the model's training data
