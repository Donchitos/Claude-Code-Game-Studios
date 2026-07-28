# Directory Structure

```text
/
├── CLAUDE.md                    # Master configuration
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
├── src/                         # Game source code (core, gameplay, ai, networking, ui, tools)
├── functions/                   # Firebase Cloud Functions (Node.js/TypeScript — different runtime
│                                 #   from src/; see docs/architecture/adr-0002-auth-pin-security-architecture.md §8)
│   ├── src/                     # Function source (compiles to lib/ on deploy)
│   └── test/                    # Jest unit tests (no Java/emulator in this environment — see
│                                 #   functions/test/*.test.ts header comments for the coverage gap)
├── firebase.json                # Firebase CLI project config (functions/emulators) — root-level,
│                                 #   distinct from src/firebase.json (FlutterFire client config)
├── assets/                      # Game assets (art, audio, vfx, shaders, data)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tests/                       # Test suites (unit, integration, performance, playtest)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (isolated from src/)
└── production/                  # Production management (sprints, milestones, releases)
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```
