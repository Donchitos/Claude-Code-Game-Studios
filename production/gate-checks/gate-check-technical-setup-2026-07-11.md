# Gate Check: Technical Setup → Pre-Production

> **Date**: 2026-07-11 · **Checked by**: /gate-check (autonomous run, user-delegated)
> **Review mode**: lean (phase gate → full 4-director panel ran)
> **Verdict: FAIL — 1 hard blocker (art bible), 1 formal blocker (traceability index)**
> Chain-of-Verification: 5 questions checked (2 tool-verified) — verdict unchanged;
> PR's "ADRs still Proposed" claim REFUTED by grep (all 14 resolved — PR had read the
> stale baseline review, not the same-day rerun)

## Required Artifacts: 11/13

| Check | Status |
|---|---|
| Engine chosen (Godot 4.7-stable) | ✅ |
| technical-preferences populated (naming, budgets, rendering, physics) | ✅ |
| **Art bible `design/art/art-bible.md` (Sections 1–4)** | ❌ **BLOCKER** — only `visual-direction-note.md` exists (explicitly scoped "NOT the art bible") |
| ≥3 Foundation ADRs | ✅ (14 ADRs; 13 Accepted, 0003 Superseded→0014) |
| Engine reference docs | ✅ |
| Test framework dirs | ✅ (`neues-spiel/tests/{unit,integration}` — engine tests live inside the Godot project per tests/README.md layout decision; root `tests/` holds process artifacts) |
| CI workflow | ✅ (`.github/workflows/tests.yml`, gdUnit4-action) |
| Example test | ✅ (pipeline_smoke_test.gd, 3/3 green headless) |
| architecture.md | ✅ (updated for ADR-0014 today) |
| **`docs/architecture/requirements-traceability.md`** | ❌ **formal blocker** — never written; `tr-registry.yaml` (the machine-readable source) exists; TD judges the human-readable rollup non-blocking, but it is a listed required artifact |
| /architecture-review report | ✅ (baseline CONCERNS + same-day rerun **PASS**) |
| Accessibility requirements | ✅ at `design/ux/accessibility-requirements.md` (path per design/CLAUDE.md; gate text expects `design/`— path discrepancy noted, content satisfies intent: tier committed) |
| interaction-patterns.md | ✅ (16 patterns + base controls + standards tables) |

## Quality Checks: 8/9

Rendering/input/state ADR coverage ✅ · naming+budgets ✅ · accessibility tier ✅ ·
Engine Compatibility on all ADRs ✅ · GDD linkage on all ADRs ✅ · no deprecated
APIs ✅ · HIGH-RISK domains resolved (all five updated in architecture.md today) ✅ ·
no ADR dependency cycles ✅ (verified with 0014 inserted) ·
**"at least one screen's UX spec started" ❌** — no hud.md / main-menu spec yet (CONCERNS-class).

## Director Panel

| Director | Verdict | Core message |
|---|---|---|
| Creative Director | CONCERNS | Large-world pivot is clean (additive, pillars intact). Carry into Pre-Pro: (1) far world needs content systems or it reads hollow, (2) "cozy at scale" is a VS success criterion, (3) sweep residual "threatened valley" prose |
| Technical Director | READY | Foundation is "real, not paper". Conditions: QQ5 stays a HARD gate before Villager AI stories; un-vsync'd re-measure (prototype p95 is AT the budget line); TR back-annotation (~295 GDD requirements carry no TR-IDs) early in Pre-Pro |
| Producer | CONCERNS | Slice-first, epics later; scope the VS to a bounded settlement region so the 3–5-week streaming epic never blocks the fun-validation loop (ADR-0014's unchanged API makes this split possible). (Its "ADRs still Proposed" premise was stale — refuted) |
| Art Director | **NOT READY** | Art bible is blocking: zero hex values/swatches to build a slice against, AND the visual-direction-note needs a large-world extension (distant-view readability, fog/horizon, biomes, height-band→color-language mapping) |

Escalation rule: one NOT READY → verdict minimum FAIL.

## Blockers (minimal path to PASS)

1. **`/art-bible`** — author Sections 1–4 minimum, WITH the large-world extension pass
   (AD's four gaps: distant readability, fog/horizon, biome palettes, height-band color
   mapping). First Pre-Production task by unanimous panel opinion.
2. **Write `docs/architecture/requirements-traceability.md`** — generate the rollup from
   tr-registry.yaml + the rerun report (an /architecture-review write-phase output; ~minutes).

## Carried conditions (enter Pre-Production with these logged)

- QQ5 settlement-core nav-graph spike = hard gate before any Villager AI story
- Un-vsync'd frame re-measure before assuming the greedy-meshing reserve unnecessary
- TR-ID back-annotation of ~295 GDD requirements before /create-stories
- VS success criterion: "cozy at scale" (camera framing/fog keeps the core intimate)
- Far-world content question (what's between settlement and seals) before dungeon epics
- Residual "valley" prose sweep (flavor-class)
- UX specs for main menu/HUD/pause (Pre-Production gate requires them anyway)

## Stage

`production/stage.txt` remains **Technical Setup** (gate not passed).
Re-run `/gate-check technical-setup` after the two blockers land.

---

## RE-RUN (same day, after blockers resolved) — Verdict: **CONCERNS → ADVANCED**

- Blocker 1 RESOLVED: art-bible.md Sections 1-4 authored (art-director draft, all 4
  taste-level decisions user-confirmed: distance-keyed fog + silhouettes, flat sharp
  HUD, amber/gold palette, 3 biomes) — commit 4658269+
- Blocker 2 RESOLVED: requirements-traceability.md generated from registry (46b0f80)
- AD re-review (fresh adversarial instance, not the author): NOT READY → **CONCERNS** —
  all four large-world gaps verified closed with quotes; WCAG contrast independently
  computed (12.8:1 text, 8.0:1 gold, 5.1:1 orange, 4.6:1 blue — all clear A3);
  1 defect found & FIXED same session (fog hue renamed Threshold Cool #6B8593,
  State Blue stays UI-only)
- Panel now: CD CONCERNS / TD READY / PR CONCERNS / AD CONCERNS → verdict CONCERNS
  (minor gaps addressable during Pre-Production, per gate definition) — ADVANCED,
  matching the Systems-Design gate precedent ("CONCERNS, advanced")
- stage.txt → **Pre-Production**
- Carried conditions unchanged (QQ5 hard gate, un-vsync re-measure, TR back-annotation,
  cozy-at-scale VS criterion, far-world content question, UX specs, valley prose sweep)
