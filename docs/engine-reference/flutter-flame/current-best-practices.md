# Flutter + Flame — Current Best Practices

*Last verified: 2026-06-25*
*Applies to: Flutter 3.44 / Flame 1.37 / Dart 3.12*

---

## Flame Component Architecture (Current Patterns)

### Use `TapCallbacks` for all input
```dart
class PetComponent extends SpriteComponent with TapCallbacks {
  @override
  void onTapUp(TapUpEvent event) {
    // handle tap
  }
}
```
Do NOT use old `TapDetector` mixin.

### Component lifecycle — use `onLoad` for async init
```dart
class PetComponent extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('pet_idle.png');
    // setup complete
  }
}
```

### Access game from component
```dart
// Preferred in Flame 1.20+
final game = findGame()!;
// or
final game = findParent<PetQuestGame>()!;
```
Avoid storing `game` reference in constructor — component may not be mounted yet.

### `isMounted` replaces `parent != null` checks
```dart
// Old (unreliable since Flame 1.28)
if (component.parent == null) { /* removed */ }

// New
if (!component.isMounted) { /* removed */ }
```

---

## Flutter Widget Layer (Overlays / HUD)

### Overlays for HUD/menus
Use `GameWidget.overlays` for UI that sits on top of the game canvas:
```dart
GameWidget(
  game: myGame,
  overlayBuilderMap: {
    'hud': (context, game) => HudWidget(game: game),
    'shop': (context, game) => ShopScreen(game: game),
  },
)
```
Toggle overlays from game: `overlays.add('shop')` / `overlays.remove('shop')`.

### State management — Riverpod recommended
For parent approval flow and shared state between Flutter UI and game logic, use `flutter_riverpod`. Riverpod is compatible with `FlameGame` and `GameWidget`.

---

## Android / iOS Platform Notes

### Android edge-to-edge (Flutter 3.35+)
Always wrap game screen in `SafeArea` or use `MediaQuery.padding` to avoid system bar overlap:
```dart
Scaffold(
  body: SafeArea(
    child: GameWidget(game: game),
  ),
)
```

### iOS audio session
Configure audio session before playing any sound (required for iOS background/foreground transitions):
```dart
// In main.dart or before first audio play
await FlameAudio.audioCache.load('music.mp3');
// flame_audio handles session automatically with flame_audio 2.x
```

### Push notifications (Firebase Messaging)
On iOS, request permissions explicitly — system dialog must be triggered:
```dart
await FirebaseMessaging.instance.requestPermission();
```
This is required for parent approval notifications. Test on physical iOS device — simulator FCM is unreliable.

---

## Performance Best Practices

### SpriteBatch for repeated sprites
Use `SpriteBatch` (Flame 1.37 adds `bleed` option to prevent seam artifacts):
```dart
final batch = SpriteBatch(image, bleed: 1.0);
```
Use for tilemap-like decorations in pet room.

### Image caching
Pre-load assets in `onLoad` or via `Images.loadAll()` — avoid loading during gameplay:
```dart
@override
Future<void> onLoad() async {
  await images.loadAll(['pet_idle.png', 'pet_happy.png', 'pet_sad.png']);
}
```

### Avoid `setState` in game loop
The Flame game loop runs independently of Flutter's build cycle. Never call `setState` from within `update()`. Use streams or `ValueNotifier` to bridge data to Flutter widgets.

---

## Firebase Integration Patterns

### Offline-first data access
Use Firestore's offline persistence (enabled by default). For a game where kids play while parents are at work, offline reads must work.

⚠️ **Corrected 2026-07-13** (previous guidance here was wrong — see ADR-0003 Correction note): as verified against the actually-resolved `cloud_firestore` 6.6.0, there is no `cacheSettings`/`PersistentCacheSettings` parameter on `Settings`. The `persistenceEnabled`/`cacheSizeBytes` pair is the correct, live API for this version:
```dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```
`Settings.CACHE_SIZE_UNLIMITED` is still the correct sentinel. Re-verify against the exact `cloud_firestore` version pinned for production before relying on this — package APIs evolve, and this reference doc was wrong about this exact API once already.

### Parent approval flow
Structure: 
1. Child submits task → write to `tasks/{taskId}` with `status: 'pending'`
2. FCM notification sent to parent device token
3. Parent approves → update `status: 'approved'`
4. Child app listens via `snapshots()` stream → triggers reward
