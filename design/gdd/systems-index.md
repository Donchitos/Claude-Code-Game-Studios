# GDD Systems Index

| System | File | Status | Layer |
|--------|------|--------|-------|
| Audio Perception | [audio-perception-system.md](audio-perception-system.md) | Draft | Foundation |
| Vision & Fog | [vision-system.md](vision-system.md) | Draft | Foundation |
| Active Sonar | [sonar-system.md](sonar-system.md) | Draft | Core |
| Noise & Aggro | [noise-system.md](noise-system.md) | Draft | Core |
| Chase & Evasion | [chase-system.md](chase-system.md) | Draft | Core |
| Fear & Corruption | [fear-corruption-system.md](fear-corruption-system.md) | Draft | Core |
| Equipment | [equipment-system.md](equipment-system.md) | Draft | Feature |
| Ritual | [ritual-system.md](ritual-system.md) | Draft | Feature |
| Enemy Design | [enemy-design.md](enemy-design.md) | Draft | Feature |

## Design Order

Foundation → Core → Feature → Presentation → Polish

## Cross-System Dependency Map

```
Vision System ──────────────────────────────┐
                                            ↓
Audio Perception ←── Sonar System ──→ Noise System ──→ Chase System
       ↑                    ↑                ↑
  Tile Audio            Equipment        Enemy Design
  Properties             System
       ↑                    ↑
  Ritual System ──→ Fear / Corruption System
```

## Authoring Notes

- Run `/design-review [path]` after editing any GDD.
- Run `/review-all-gdds` after all Foundation GDDs are approved.
- Balance values in Tuning Knobs sections are drafts — validate in MVP before locking.
