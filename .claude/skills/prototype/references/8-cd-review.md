# /prototype — Phase 8: Creative Director Review

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 8: Creative Director Review

**Review mode check:**
- `solo` → skip. Note: "CD-PLAYTEST skipped — Solo mode."
- `lean` → skip. Note: "CD-PLAYTEST skipped — Lean mode."
- `full` → spawn `creative-director` via `Agent` using gate **CD-PLAYTEST** if
  `design/gdd/game-concept.md` exists with game pillars defined, or
  `design/game-brief.md` exists (the `rigor: minimal` brief has no pillars — its
  pitch and "what they feel" line stand in). If neither is available, note:
  "CD-PLAYTEST skipped — game pillars not yet defined at concept prototype stage."

Pass: the full REPORT.md content, the original hypothesis, and game pillars /
core fantasy from `design/gdd/game-concept.md` (or the brief's pitch and "what
they feel" line from `design/game-brief.md`).

The creative director evaluates the result against the game's creative vision and
returns one of the gate's verdicts — APPROVE, CONCERNS or REJECT — or NOT
ASSESSED when it could not judge. Apply it to the recommendation:

- **APPROVE** → the recommendation stands.
- **CONCERNS** → show the concerns alongside the recommendation, then use
  `AskUserQuestion`: `Revise the recommendation` / `Accept with noted concerns` /
  `Discuss further`. The user decides; the director does not.
- **REJECT** (the core fantasy is not present) → a PROCEED recommendation cannot
  stand. Use `AskUserQuestion` to ask the user to choose `PIVOT` or `KILL`, and run
  Phase 9 for that choice. A PIVOT or KILL recommendation stands.
- **NOT ASSESSED** (the director lacked an input — `.claude/docs/director-gates.md`)
  → not an approval. Name what was missing; supply it and re-run the gate, or
  record the review as NOT ASSESSED and let the user decide whether the
  recommendation stands unreviewed.

When the director returned CONCERNS, REJECT or NOT ASSESSED, ask "May I update
`prototypes/[concept-name]-concept/REPORT.md` and its `prototypes/index.md`
row?", then record the director's verdict and reason in REPORT.md, and the final
recommendation in both if it changed.

---
