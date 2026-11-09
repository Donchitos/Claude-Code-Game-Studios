---
paths:
  - "prototypes/**"
---

# Prototype Code Standards

Two kinds of prototype live under `prototypes/`, with different rules. A **one-shot**
(`prototypes/<name>/` with `index.html` and `config.js`, built by `/prototype` in the browser) is
the start of a game the person may keep. An **engine or paper prototype**
(`prototypes/[name]-concept/`, `-spike-`, `-vertical-slice/`) is throwaway code that answers one
question.

## Every prototype
- Each prototype lives in its own subdirectory: `prototypes/[name]/`
- Each file that can hold a comment starts with the PROTOTYPE - NOT FOR PRODUCTION header
- No production code may reference or import from `prototypes/`
- An engine or paper prototype must not modify files outside `prototypes/`, and is never
  deployed or shipped as it is
- A one-shot may also write `design/game-brief.md` and save pasted images to `references/`;
  it is shared from its `dist/` copy (`one-shot-share.sh`), never from its working folder

## One-shots
- Every tuning value lives in `config.js` (`window.CONFIG`), each with value, min, max and step,
  plus `seed`; the game reads them live and never hardcodes them
- Gameplay randomness goes through the seeded `rng()`, never `Math.random`
- It plays offline: libraries in `vendor/`, no requests to the network while it runs
- Every file in `assets/` and `vendor/` has an entry in `assets/provenance.yaml`; a placeholder
  carries `placeholder: true` and `_ph` before its extension
- `brief.md` (a copy of `design/game-brief.md`) takes the place of a README
- Polish belongs to it: title, game over and restart, sound and mute where the brief calls for
  them
- On PROCEED it may grow into the project root (`/prototype`'s grow step); `prototypes/<name>/`
  itself is never edited by growing

## Engine and paper prototypes

Standards are intentionally relaxed to maximize iteration speed. The goal is learning, not
production quality.

### What's Allowed
- Hardcoded values (no need for data-driven config)
- Minimal or no doc comments
- Simple architecture (no dependency injection required)
- Singletons and global state
- Copy-pasted code (no need for abstraction)
- Debug output left in place
- Placeholder art and audio
- Quick-and-dirty solutions

### What's Still Required
- Every engine or paper prototype has a `README.md` with:
  - What hypothesis is being tested
  - How to run the prototype
  - Current status (in-progress / concluded)
  - Findings (updated when prototype concludes)

### When an engine or paper prototype succeeds
If a prototype validates a concept and the feature moves to production:
1. The prototype code is NOT migrated directly — it is rewritten to production standards
2. The prototype `README.md` findings inform the production design document
3. The prototype directory is preserved for reference but never extended

### Cleanup
Concluded prototypes should be archived or deleted after findings are captured.
Never let engine or paper prototype code grow into production code through incremental
"cleanup." A one-shot grows only through `/prototype`'s grow step, which copies it into the
project root and leaves `prototypes/<name>/` untouched.
