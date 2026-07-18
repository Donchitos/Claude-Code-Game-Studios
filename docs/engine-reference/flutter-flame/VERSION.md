# Flutter + Flame — Version Reference

*Last verified: 2026-06-25*

| Field | Value |
|-------|-------|
| **Flutter Version** | 3.44.4 |
| **Flame Version** | 1.37.0 |
| **Dart SDK** | 3.12.2 |
| **Project Pinned** | 2026-06-25 |
| **LLM Knowledge Cutoff** | May 2025 (~Flutter 3.19 / Flame 1.14) |
| **Risk Level** | MEDIUM-HIGH — significant versions beyond training data |

## Post-Cutoff Version Timeline

| Flutter | Flame | Key Theme |
|---------|-------|-----------|
| 3.22 | 1.20–1.23 | Impeller default on iOS, Material 3 complete |
| 3.24 | 1.24–1.26 | Wasm support, AGP 8+ required |
| 3.27 | 1.27–1.29 | Impeller on Android (selective), Dart 3.6 |
| 3.29 | 1.30–1.31 | Swift Package Manager (iOS), Vector2 32-bit fix |
| 3.32 | 1.32–1.34 | AGP 9 support, shrinkwrap removed from Flame |
| 3.35 | 1.35 | Android edge-to-edge enforcement |
| 3.38 | 1.36 | Xcode 16 required for iOS builds |
| 3.41 | 1.37 | SpriteBatch bleed fix, ExpandedComponent |
| 3.44 | 1.37 | Stable current release |

## Critical Notes for PetQuest

1. **Impeller is now default** on both iOS (3.22+) and selective Android (3.27+) — rendering pipeline change, test thoroughly on target devices
2. **Flame Vector2 is now 32-bit** (1.27) — affects physics/shader code; use `Float32List` where needed
3. **AGP 9.0 requires migration steps** if upgrading existing Android projects
4. **iOS builds require Xcode 16+** as of Flutter 3.38
5. **TapDetector deprecated** in Flame — use `TapCallbacks` mixin instead

## Reference Files

- `breaking-changes.md` — Version-by-version breaking changes (3.19→3.44)
- `deprecated-apis.md` — Don't use X → Use Y tables
- `current-best-practices.md` — New patterns since training cutoff

## Migration Guides

- Flutter: https://docs.flutter.dev/release/breaking-changes
- Flame: https://github.com/flame-engine/flame/blob/main/packages/flame/CHANGELOG.md
