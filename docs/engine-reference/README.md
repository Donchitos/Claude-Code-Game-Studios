# Engine Reference Documentation

This directory contains curated, version-pinned documentation snapshots for the
game engine(s) used in this project. These files exist because **LLM knowledge
has a cutoff date** and game engines update frequently.

## Why This Exists

Claude's training data has a knowledge cutoff (May 2025 is the floor; a newer
model may know more). Game engines
like Godot, Unity, and Unreal, and the web toolchain (Vite, TypeScript and the
game libraries), ship updates that introduce breaking API changes,
new features, and deprecated patterns. Without these reference files, agents will
suggest outdated code.

## Structure

Each engine gets its own directory: `godot/`, `unity/`, `unreal/` and `web/`,
named as `engine.name` in lower case. The web folder pins a toolchain rather
than one engine, and has a page per library instead of `modules/`:

```
<engine>/
├── VERSION.md              # Pinned version, verification date, knowledge gap window
├── breaking-changes.md     # API changes between versions, organized by risk level
├── deprecated-apis.md      # "Don't use X → Use Y" lookup tables
├── current-best-practices.md  # New practices not in model training data
├── PLUGINS.md              # Unity and Unreal only: index of the plugin pages
├── plugins/                # Unity and Unreal only: one page per plugin
│   └── ...
└── modules/                # Per-subsystem quick references, one subsystem per file
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
- After running `/setup-engine refresh`
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
- One subsystem per module file; there is no fixed length
- Include code examples showing correct/incorrect patterns
- Link to official documentation URLs for verification
- Only document things that differ from the model's training data
