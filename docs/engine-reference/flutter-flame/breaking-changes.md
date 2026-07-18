# Flutter + Flame — Breaking Changes

*Last verified: 2026-06-25*
*Covers: Flutter 3.19 → 3.44 / Flame 1.14 → 1.37*

---

## Flutter Breaking Changes

### Flutter 3.22 (May 2024)
- **Impeller is now default renderer on iOS** — replaces Skia. Most rendering works correctly but custom Canvas/shader usage should be tested. Some advanced blend modes behave differently.
- **Material 3 is now the default** — `ThemeData` defaults changed. If using Material widgets in parent app UI, audit theme settings.

### Flutter 3.24 (August 2024)
- **Android Gradle Plugin (AGP) 7+ recommended** — older AGP versions trigger warnings. AGP 8+ recommended for new projects.
- **Wasm compilation available** — `flutter build web --wasm` now stable. Not relevant for mobile-only PetQuest.
- **Kotlin Gradle Plugin warnings** if using outdated KGP in Android project.

### Flutter 3.27 (December 2024)
- **Impeller enabled selectively on Android** (Vulkan-capable devices, API 29+). Falls back to OpenGLES on older devices. Test both paths on Android.
- **Dart 3.6** — pattern matching enhancements, no breaking changes for typical app code.

### Flutter 3.29 (February 2025)
- **Swift Package Manager (SPM) support for iOS** — opt-in. CocoaPods still works. PetQuest: no action needed unless adopting SPM for iOS plugins.
- **`minSdkVersion` must be ≥ 21** for new projects (Android). If using `flutter.minSdkVersion`, ensure it's set correctly.

### Flutter 3.32 (May 2025)
- **AGP 9.0.0 requires migration** — if upgrading an existing project to AGP 9, follow https://developer.android.com/build/agp-upgrade-assistant. New projects generated with Flutter 3.32 use compatible defaults.
- **`FlutterApplication` stub restored** — `io.flutter.app.FlutterApplication` re-added as empty class to prevent crashes in apps referencing it after v2 embedder migration.

### Flutter 3.35 (August 2025)
- **Android edge-to-edge enforced** — Android 15+ apps must handle edge-to-edge display. Use `SystemUiMode` correctly; test with `SafeArea` widgets. PetQuest: ensure game canvas respects safe areas on notched/cutout devices.

### Flutter 3.38 (November 2025)
- **Xcode 16+ required for iOS builds** — update build machine/CI to Xcode 16 before targeting iOS.
- **iOS SwiftPM concurrent builds** — be aware of race condition with concurrent directory creation (fixed in 3.38.x patch).

### Flutter 3.41 (February 2026)
- **Impeller Vulkan disabled on known bad exynos SoCs** (exynos9820) — falls back to OpenGLES automatically. No action needed.
- **Android API 29+ required for HardwareBuffer platform views** — lower API levels use fallback path.

### Flutter 3.44 (May 2026) — Current
- No new breaking changes for typical 2D mobile game projects.
- AGP 9 + Gradle 9 + Kotlin 2.2.20 fully supported by `flutter analyze --suggestions`.

---

## Flame Breaking Changes

### Flame 1.27 — **CRITICAL for shaders/physics**
- **Vector2 changed to 32-bit floats** (`Float32List` internally) — necessary for Forge2D compatibility and fragment shader compatibility.
  - Impact: If you pass `Vector2` values to custom shaders or do precision-sensitive math, test carefully.
  - Migration: Code using `Vector2` API surface is unchanged — internal representation changed.

### Flame 1.28
- **Children retain `parent` reference after parent removed from tree** — previously `parent` was nulled on removal. If you check `component.parent == null` to detect removal, use `isMounted` instead.

### Flame 1.29
- **`testGolden` prepare function now receives `WidgetTester`** — affects test files using `testGolden`. Update prepare function signature: `(game, tester) async { ... }`.

### Flame 1.30 / 1.31
- **`shrinkwrap` removed from layout components** — `PositionComponent` no longer supports `shrinkwrap` property. Use `size` explicitly or use `ColumnComponent`/`RowComponent` for layout.

### Flame 1.33
- **`ExpandedComponent` introduced** — new layout component. Existing code unaffected, but review layout patterns.

### Flame 1.34
- **Secondary tap support added to new callbacks system** — `TapCallbacks.onTapUp` now receives a `TapUpEvent` with `button` property for right-click detection. No breaking change to existing callbacks.

---

## Summary: What PetQuest Must Watch

| Area | Risk | Action |
|------|------|--------|
| Impeller rendering (iOS + Android) | Medium | Test on physical devices; verify custom drawing |
| Android edge-to-edge (3.35+) | Medium | Use `SafeArea` + test on Android 15+ devices |
| Flame Vector2 32-bit | Low for PetQuest | No custom shaders/physics in MVP — note for future |
| `TapDetector` → `TapCallbacks` | Low | Use `TapCallbacks` mixin from the start |
| AGP/Kotlin/Xcode versions | Low for new project | Flutter 3.44 new project template handles this |
