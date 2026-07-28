# Story 011: Game Feel playtest probe (AC35, Advisory)

> **Epic**: Needs & Mood System
> **Status**: Ready
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: ~0.5 agent-day (facilitation + write-up; excludes the playtest session itself)
> **Manifest Version**: 2026-07-23
> **Last Updated**: —

## Context

**GDD**: `design/gdd/needs-mood-system.md` (Game Feel + AC35)
**Requirement**: `TR-needs-mood-system-067`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR: N/A — playtest evidence collection; no architectural pattern is decided or applied here.
**ADR Decision Summary**: Not applicable. The nearest binding constraint is the testing standard: Visual/Feel evidence is a screenshot/observation record plus lead sign-off, recorded in `production/qa/evidence/`, and is **ADVISORY** — never a blocking gate.

**Engine**: Godot 4.7-stable | **Risk**: LOW
**Engine Notes**: None — this story writes no code. It observes the shipped build at the values story 009 ratified.

**Control Manifest Rules (this layer)**:
- Required: evidence lands in `production/qa/evidence/` with a date and a named observer.
- Forbidden: treating this as a blocking gate, or retuning knobs mid-session — a retune is story 009's discipline (config change + rationale), not a live twiddle.
- Guardrail: run **after** milestone criterion #5 is green (that is the first moment the loop actually pays off) and before the milestone gate.

---

## Acceptance Criteria

*From GDD `design/gdd/needs-mood-system.md`, scoped to this story:*

- [ ] **AC35 (Advisory)**: The four Game Feel acceptance criteria are evaluated at the MVP playtest and their outcomes recorded in `production/qa/evidence/`: [TR-needs-mood-system-067]
  - **Legibility** — a first-time player, asked "why is the villager unhappy?", answers correctly within one need cycle, without a tutorial.
  - **No nagging** — nobody describes the needs as "nagging".
  - **Pacing hypothesis** — the build→wait→payoff rhythm reads as intentional; players report the pre-urgency stretch as settlement-watching, not dead air.
  - **Unprompted mood notice** — players notice and mention the mood lift after building a bed, **unprompted** (the display-only-mood bet, made falsifiable).
- [ ] The pacing observation is recorded against the **shipped** real-time figures from story 009, not the GDD's original 2.0-rate prose — the session is what confirms or falsifies that decision.
- [ ] Each outcome is recorded as pass / fail / inconclusive with a verbatim player quote where one exists — not a summary judgement.
- [ ] Any failure produces a named follow-up (a knob candidate with its safe range, or a UI/legibility item routed to the Villager Info UI epic) — never a silent note.

---

## Implementation Notes

- Silent walkthrough: do not explain the mood face, the need bar, or the why-string. The whole probe is whether they read without a facilitator.
- Ask the legibility question at a fixed moment (first Low-band villager), not opportunistically — a consistent prompt across sessions is what makes two sessions comparable.
- Record wall-clock timestamps of: first urgency, player's first bed placement, bed completion, first observed recovery, first mood-band lift. Those five numbers are the pacing evidence; everything else is commentary.
- Bundle with milestone R8's external silent walkthroughs rather than running a separate session — same session, two evidence artifacts.
- If the pacing reads as "nagging" or as "dead air", the remedy is a story-009-style config change with rationale (`decay_per_tick` inside 0.03–0.2), not an ad-hoc edit.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 009: the rate decision and its recorded rationale.
- Villager Info UI epic: the panel that displays values, band, and why-string.
- Any code change — this story observes and records only.

---

## QA Test Cases

*Visual/Feel story — manual verification steps (testing standards).*

- **Manual check — legibility**: Setup: play until a villager's mood enters Low. Verify: ask "why is this villager unhappy?" Pass condition: the player names the sleep/bed/shelter cause within one need cycle, without prompting or explanation.
- **Manual check — no nagging**: Setup: full session. Verify: unprompted player language about the needs. Pass condition: no player describes them as nagging, pestering, or constant.
- **Manual check — pacing**: Setup: full session with the five timestamps recorded. Verify: the player's description of the pre-urgency stretch. Pass condition: described as watching/waiting-with-purpose, not as dead air or as too fast.
- **Manual check — unprompted mood notice**: Setup: player builds a bed and the villager sleeps in it. Verify: whether the player mentions the mood lift without being asked. Pass condition: mentioned unprompted.

---

## Test Evidence

**Story Type**: Visual/Feel (ADVISORY)
**Required evidence**: `production/qa/evidence/needs-mood-game-feel-probe-[date].md` — the four outcomes, the five timestamps, verbatim quotes, and lead sign-off.

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: 009 (shipped pacing values), 010 (criterion #5 green — the loop must actually pay off before it can be felt)
- Related: milestone R8 (1–2 external silent walkthroughs) — run in the same session
- Unlocks: nothing (Advisory; not an MVP-Done blocker)
