---
name: project-overview
description: Core facts about "What the Gods Left Behind" needed to classify story types and judge testability gates
metadata:
  type: project
---

Game: "What the Gods Left Behind" — RTS/roguelite, Godot 4.6, GDScript. Two design pillars drive QA gating decisions:
- **Pilar 1 — Sacrificio con Peso**: permadeath must be truly irreversible; no reload-to-undo. Any system touching save/load or hero death is treated as data-integrity-critical regardless of its normal story-type classification.
- **Pilar 2 — El Pasado es Poder**: the player's relic pantheon must survive across sessions; loss of pantheon data on close/crash is treated as a Pillar-breaking bug (S1), not a normal data bug.

**Why**: these two pillars are the reason the studio's default "Config/Data = advisory" rule gets overridden for anything checksum/atomic-write/schema-version related in the save system — see [[project-save-persistence-status]].

**How to apply**: when classifying story types for QA plans or evaluating gate blockers, treat any story touching save/load, permadeath resolution, or relic/pantheon persistence as at least Integration/blocking, and escalate to blocking even for what would normally be Config/Data if it affects irreversibility or pantheon durability.

GDDs live in `design/gdd/`. Standard 8-section structure is enforced by `design/CLAUDE.md` and `.claude/rules/design-docs.md`.
