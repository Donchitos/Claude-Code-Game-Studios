---
paths:
  - "prototypes/**"
---

# Prototype Code Standards (Relaxed)

Prototypes are throwaway code for validating ideas. Standards are intentionally
relaxed to maximize iteration speed. The goal is learning, not production quality.

## What's Allowed in Prototypes
- Hardcoded values (no need for data-driven config)
- Minimal or no doc comments
- Simple architecture (no dependency injection required)
- Singletons and global state
- Copy-pasted code (no need for abstraction)
- Debug output left in place
- Placeholder art and audio
- Quick-and-dirty solutions

## What's Still Required
- Each prototype lives in its own subdirectory: `prototypes/[name]/`
- Every prototype MUST have a `README.md` with:
  - What hypothesis is being tested
  - How to run the prototype
  - Current status (in-progress / concluded)
  - Findings (updated when prototype concludes)
- No production code may reference or import from `prototypes/`
- Prototypes must not modify files outside `prototypes/`
- Prototypes must not be deployed or shipped

## When a Prototype Succeeds
If a prototype validates a concept and the feature moves to production:
1. The prototype code is NOT migrated directly — it is rewritten to production standards
2. The prototype `README.md` findings inform the production design document
3. The prototype directory is preserved for reference but never extended

## Cleanup
Concluded prototypes should be archived or deleted after findings are captured.
Never let prototype code grow into production code through incremental "cleanup."

## Web projects — the convergence trap

For Godot, Unity, and Unreal, an HTML prototype is a *proxy* built in a different
technology, so throwing it away is automatic. For a **Web** project it is not:
the prototype runs on the same stack as the shipping game.

This makes the rules above harder to hold and more important:

- **"Rewrite, don't migrate" still applies.** The temptation to keep prototype
  code because "it already works in the right language" is exactly how hardcoded
  values, global state, and copy-pasted logic reach production
- Prototypes still live in `prototypes/` with their own `package.json` or Vite
  config. Never point the production build at prototype source
- Production code must not import from `prototypes/`, even though the module
  system makes it trivially possible

Note also that the usual caveat about browser latency lying about game feel is
**inverted** for web projects — that latency is the shipping reality, so a
browser prototype is a more honest feel test than it would be for any other
engine. See `.claude/skills/prototype/SKILL.md`.
