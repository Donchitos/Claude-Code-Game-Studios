# Flutter + Flame — Deprecated APIs

*Last verified: 2026-06-25*

## Flame Deprecated APIs

| Deprecated | Use Instead | Since | Notes |
|------------|------------|-------|-------|
| `TapDetector` mixin | `TapCallbacks` mixin | 1.21 | `TapDetector` still works but will be removed. Prefer `TapCallbacks` for all new code. |
| `DoubleTapDetector` | `DoubleTapCallbacks` | 1.21 | Same migration path |
| `LongPressDetector` | `LongPressCallbacks` | 1.21 | Same migration path |
| `DragDetector` | `DragCallbacks` | 1.21 | Same migration path |
| `HoverCallbacks` (old) | `HoverCallbacks` (new events) | 1.24 | Old hover API removed; use new event-based API |
| `component.shrinkwrap` | Set `size` explicitly | 1.30 | Property removed entirely in 1.30 |
| `HasGameRef` mixin | `FlameGame` direct reference or `ComponentTreeRoot` | ongoing | Still works; modern pattern is to access game via `findGame()` or dependency injection |

## Flutter Deprecated APIs (relevant to game projects)

| Deprecated | Use Instead | Since Flutter | Notes |
|------------|------------|---------------|-------|
| `Color(0xFFRRGGBB)` int constructor | `Color.fromARGB()` or `Color.fromRGBO()` | 3.27 | Dart linter may warn; both still work |
| `WillPopScope` | `PopScope` | 3.22 | `WillPopScope` removed in 3.22+ |
| `MaterialStateProperty` | `WidgetStateProperty` | 3.22 | Direct rename; functionality identical |
| `MaterialState` enum | `WidgetState` enum | 3.22 | Direct rename |
| `Scaffold.resizeToAvoidBottomInset` (implicit) | Explicit `resizeToAvoidBottomInset: false` for game screens | — | Game screens should disable this to prevent canvas resize on keyboard show |
| Old `ThemeData` color fields (e.g., `primaryColor`) | `ColorScheme` fields | 3.22+ | Material 3 — use `colorScheme.primary` etc. |

## Firebase (Flutter SDK) — Current Versions

| Package | Recommended Version | Notes |
|---------|-------------------|-------|
| `firebase_core` | ^3.x | Required for all Firebase packages |
| `firebase_auth` | ^5.x | Parent authentication |
| `cloud_firestore` | ^5.x | Task/pet data storage |
| `firebase_messaging` | ^15.x | Parent approval push notifications |
| `firebase_analytics` | ^11.x | Optional — player behavior |

> **Note**: Firebase FlutterFire packages versioned independently from Flutter SDK. Always check https://firebase.flutter.dev for latest compatible versions.
