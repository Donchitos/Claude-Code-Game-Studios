# Epics Index

Last Updated: 2026-05-23
Engine: Godot 4.6 (4.6.1.stable.official.14d19694e runtime confirmed 2026-05-17)

| Epic | Layer | System | GDD | Stories | Status |
|------|-------|--------|-----|---------|--------|
| [Reasoning Workspace](reasoning-workspace/EPIC.md) | Feature (Gameplay) | #6 Reasoning Workspace | [reasoning-workspace.md](../../design/gdd/reasoning-workspace.md) | 12 (5 Complete: 001+002+003a + 007-data-layer + 012-subset; remainder blocked on UI Foundation / SaveLoadService / EvaluationService) | In Progress |
| [UI Foundation](ui-foundation/EPIC.md) | Foundation (Core) | #2 UI Foundation | [ui-foundation.md](../../design/gdd/ui-foundation.md) | 5 (3 Complete: 001 UIService + 002 KrCustomControl + 004 tween gateway; 003 blocked on MSDF fonts, 005 pending) | In Progress |
| [Submission & Evaluation](submission-evaluation/EPIC.md) | Feature (Gameplay) / Core | #9 Submission & Evaluation | [submission-evaluation.md](../../design/gdd/submission-evaluation.md) | 5 (4 Complete: 001 Resources + 002 scoring + 003 verdict + 004 submit pipeline [keystone]; 005 comments remain) | In Progress |
| [Save/Load](save-load/EPIC.md) | Core / Foundation | #3 Save/Load | [save-load.md](../../design/gdd/save-load.md) | 8/8 implementable cores Complete (001-004+007+008 full; 005/006 core+contract done, EvaluationService/controller end-to-end deferred — TD-001) | In Progress (epic gated on EvaluationService) |

## Pending epic creation (Implementation-ready systems)

- **#7 Brief Editor** — blocked on Day 2 GDD Scope Reduction pass (§1·§2·§4·§8·§10 재포지셔닝 + 35 AC → ~20 AC + RC-D/E closure) + cycle 5 lean verification. Run `/create-epics brief-editor` after.
- **#4 Settings & Accessibility** — Core epic (SettingsService autoload + 5 카테고리 17 settings + ConfigFile persist + 5-step cascade + SettingsScreen UI). ADR-0009 Accepted 2026-05-18. Run `/create-epics settings-accessibility`.
- ~~#3 Save/Load~~ — **epic created 2026-05-23** (`save-load/EPIC.md`). Run `/create-stories save-load`.

## Pending design completion (NOT implementation-ready)

- #5 Case File Browser — Designed Provisional, Browser Layout ADR pending
- #8 Investigation Slots — Not Started
- #9 Submission & Evaluation — Designed + ADR-0007 Accepted, epic creation cascade after dependency systems
- #10 Verdict Reveal Sequence — Not Started
- (Other systems — see `design/gdd/systems-index.md`)
