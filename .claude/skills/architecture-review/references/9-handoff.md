# /architecture-review — Phase 9: Handoff

> Part of `/architecture-review`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 9: Handoff

After completing the review and writing approved files, present:

1. **Immediate actions**: List the top 3 ADRs to create (highest-impact gaps first,
   Foundation layer before Feature layer)
2. **Pre-gate checklist**: Check whether these exist via Glob and mark each ✅ or ❌:
   - the engine's test root — `tests/unit/` and `tests/integration/` (Godot), `Assets/Tests/EditMode/` and `Assets/Tests/PlayMode/` (Unity), `Source/<Module>/Private/Tests/` (Unreal) — if ❌: run `/test-setup`
   - `.github/workflows/tests.yml` — if ❌: run `/test-setup`
   - `design/accessibility-requirements.md` — if ❌: run `/ux-design`
   - `design/ux/interaction-patterns.md` — if ❌: run `/ux-design`
   Present ❌ items as required steps before gate-check. Do not offer `/gate-check`
   as an option if any item is ❌ — offer the missing skill to run instead.
3. **Rerun trigger**: "Re-run `/architecture-review` after each new ADR is written
   to verify coverage improves"

Then close with `AskUserQuestion` tailored to the pre-gate checklist state:
- If ADR gaps remain or any pre-gate item is ❌:
  - "Architecture review complete. What would you like to do next?"
    - [A] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [B] Run `/test-setup` — required before gate-check (only show if test infrastructure is ❌)
    - [C] Run `/ux-design` — required before gate-check (only show if UX/accessibility files are ❌)
    - [D] Stop here for this session
- If all pre-gate checklist items are ✅ and no blocking ADR gaps remain:
  - "Architecture review complete. All pre-gate items confirmed. What would you like to do next?"
    - [A] Run `/gate-check pre-production`
    - [B] Write a missing ADR — open a fresh session and run `/architecture-decision [system]`
    - [C] Stop here for this session

---
