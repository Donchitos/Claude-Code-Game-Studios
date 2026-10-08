# /gate-check — Sections 4 and 4b: Assessment and Director Panel

> Part of `/gate-check`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## 4. Collaborative Assessment

**In this file:**

- 4. Collaborative Assessment: unverifiable items are never PASS
- 4b. Director Panel Assessment: `review_mode` decides whether directors spawn, `workflow` decides the panel width
- Gate IDs
- Naming the omissions, and applying the panel to the verdict

For items that can't be automatically verified, **ask the user**:

- "I can't automatically verify that the core loop plays well. Has it been playtested?"
- "No playtest report found. Has informal testing been done?"
- "Performance profiling data isn't available. Would you like to run `/perf-profile`?"

**Never assume PASS for unverifiable items.** Mark them as MANUAL CHECK NEEDED.
An answer resolves the item: "no" or "not yet" is a checked, failed item
(CONCERNS or FAIL, naming the skill that closes it — `/design-review [doc]` for
an unreviewed concept or GDD) — except a play question at the Production gate
(a human has played the Vertical Slice; at `minimal`, the core loop is fun on
the current build), where "not yet" means nobody has played it: NOT ASSESSED
(`gate-production.md`). Only an unanswered item or "I don't know" stays
MANUAL CHECK NEEDED, which Section 5 turns into NOT ASSESSED.

This applies to questions about the project's state. Declining an offer to
produce missing data (e.g. `/perf-profile`) leaves the item NOT ASSESSED; at
`performance.enforce: off` it stays out of the verdict.

---

## 4b. Director Panel Assessment

The panel is set by **two independent axes**, both resolved in Phase 1: `review_mode`
decides *whether* the panel runs, `workflow` decides *how wide* it is.

**Axis 1 — `review_mode` decides whether any director spawns:**
- `solo` → skip the panel entirely. Note in output: "Director Panel skipped — Solo mode. Gate verdict based on artifact and quality checks only." Proceed to Phase 5.
- `lean` → run the panel (phase gates always run in lean mode — this is their purpose).
- `full` → run the panel.

**Axis 2 — `workflow` decides the panel width.** Directors are Opus-tier, so the
panel is sized to the project rather than fixed at four. The gate still runs at
every tier; only its breadth scales:

| `workflow` | Panel | Directors |
|---|---|---|
| `minimal` | 1 | `producer` |
| `standard` | 2 | `technical-director`, `producer` |
| `full` | 4 | `creative-director`, `technical-director`, `producer`, `art-director` |

`producer` is in every panel — scope and schedule readiness is the one judgment
no tier makes optional. `technical-director` joins at `standard` because that is
the first tier requiring architecture artifacts. `creative-director` and
`art-director` join at `full`, the only tier requiring the full art bible and
UX spec set for them to assess.

> **Width is not the same as strictness.** A narrower panel does not soften the
> verdict: the escalation rule in `.claude/docs/director-gates.md` is unchanged —
> the strictest verdict returned by *whoever ran* still wins. Do not infer PASS
> from a perspective that was never consulted.

Before generating the final verdict, spawn the directors for the resolved tier as **parallel subagents** via `Agent` using the parallel gate protocol from `.claude/docs/director-gates.md`. Issue all the `Agent` calls simultaneously — do not wait for one before starting the next.

**Gate IDs:**

1. **`creative-director`** — gate **CD-PHASE-GATE** (`.claude/docs/director-gates/cd-phase-gate.md`)
2. **`technical-director`** — gate **TD-PHASE-GATE** (`.claude/docs/director-gates/td-phase-gate.md`)
3. **`producer`** — gate **PR-PHASE-GATE** (`.claude/docs/director-gates/pr-phase-gate.md`)
4. **`art-director`** — gate **AD-PHASE-GATE** (`.claude/docs/director-gates/ad-phase-gate.md`)

Pass to each the target phase name, the resolved `workflow` tier, the target
gate's required and recommended artifacts at the resolved tier (the loaded gate
file's checklist after its tier reduction and the `qa.level` relaxation — what
this gate asks for, not what a later one will), the list of artifacts present,
and its gate's own context — named here, so this session never has to read the
gate files:
- **CD-PHASE-GATE**: the game pillars and core fantasy (from
  `design/gdd/game-concept.md`, else `design/game-brief.md`).
- **TD-PHASE-GATE**: the architecture document path, the engine reference path
  (`docs/engine-reference/<engine>/VERSION.md`), and the ADR list.
- **PR-PHASE-GATE**: the sprint and milestone artifacts present, `team.size` as
  resolved above (with the current sprint plan's capacity, if a plan exists), and
  the number of stories under `production/epics/` whose status is `Blocked`. At
  `workflow: minimal`, pass the Build order in `design/game-brief.md` as the plan — that
  tier has no sprint plan.
- **AD-PHASE-GATE**: the art and visual artifacts present, the Visual Identity
  Anchor (from `design/gdd/game-concept.md`, else the "Art & audio direction"
  line of `design/game-brief.md`), and the art bible path.

Pass each context item as one of three things, so no director has to guess:
- **Present** — its path or value (`0` blocked stories is a value).
- **"none"** — the target gate (or an earlier one) requires or recommends it at
  this tier and it does not exist (no architecture document at
  `/gate-check pre-production`). For the director that is a fact about the
  project to judge, not a missing input.
- **"not expected before [phase]"** — the target gate does not ask for it yet;
  name the phase whose gate first does (the architecture document and ADRs
  before Pre-Production, the sprint plan before Production). One this tier never
  requires is "not required at `workflow: [tier]`" (any sprint plan at
  `minimal`). Neither is ever passed as "none", and neither is a finding — a
  director judges readiness for the phase being entered, not a later one.

**Name the omissions in the output.** Below the Director Panel summary, when the
panel ran narrower than four, state which perspectives did not run and how to get
them — e.g. "Panel: 2 of 4 (`workflow: standard`). Creative and Art perspectives
not consulted. Raise `modes.rigor` to `full` (or set `modes.workflow: full`) for
the complete panel." Name the setting the config block shows as `workflow`'s
source: when `modes.workflow` is set on its own, raising `modes.rigor` does not
change it. Never point to `--review full` for this — `--review` decides whether
the panel runs, not how wide it is. A silently narrow panel reads as a clean bill
of health from reviewers who never looked.

**Collect every response from the directors that ran, then present the Director Panel summary** (one row per director that ran; name the ones `workflow` left out):

```
## Director Panel Assessment

Creative Director:  [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Technical Director: [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Producer:           [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]

Art Director:       [READY / CONCERNS / NOT READY / NOT ASSESSED]
  [feedback]
```

**Apply to the verdict:**
- Any director returns NOT READY → verdict is minimum FAIL (no override turns a FAIL into a stage change — Section 6)
- Any director returns CONCERNS → verdict is minimum CONCERNS
- Any director returns NOT ASSESSED (and none returned NOT READY or CONCERNS) → verdict at best NOT ASSESSED; name the input that director said was missing — it never counts as READY
- Every director that ran returns READY → eligible for PASS (still subject to artifact and quality checks from Section 3)

---
