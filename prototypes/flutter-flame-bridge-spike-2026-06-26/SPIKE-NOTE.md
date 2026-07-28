# SPIKE: Flutter-Flame State Bridge

**Date:** 2026-06-26
**Question:** "Can we pass state events from Riverpod (Flutter) into Flame game components without tight coupling — specifically: parent presses Approve → Flutter state changes → Flame plays animation?"
**Timebox:** ~4 hours
**Result:** PENDING — run the spike to fill this in

---

## Architecture Tested

```
[Parent taps Approve button]
        │
        ▼
[PetMoodNotifier.approve()]      ← pure Riverpod StateNotifier, no Flame knowledge
        │
        ▼ (state = PetMood.happy)
[ref.listen in ConsumerWidget]   ← Flutter widget acts as bridge adapter
        │
        ▼ GameEventBus().emit(...)
[GameEventBus StreamController]  ← pure Dart singleton, no Flutter/Flame dependency
        │
        ▼ stream subscription
[MochiComponent._onEvent()]      ← pure Flame component, no Riverpod knowledge
        │
        ▼
[ScaleEffect bounce + color change]
```

**Key design principle:** Neither `PetMoodNotifier` nor `MochiComponent` knows about each other.
`GameEventBus` is the pure-Dart contract between them. The Flutter widget layer owns the bridge call.

---

## How to Run

```bash
cd prototypes/flutter-flame-bridge-spike-2026-06-26
flutter pub get
flutter run
```

Run on a physical device or simulator. Test three interactions:
1. Tap **"Bố mẹ Approve Task"** → Mochi should turn Mint Green + bounce (scale up/down)
2. Tap **"Bỏ qua task"** → Mochi should turn Lavender + shrink
3. Tap **"Reset"** → Mochi should return to Peach + scale back to 1.0

The status label above the buttons should update simultaneously ("Riverpod → Flame ✓").

---

## What to Observe

- [ ] Does the color change happen in the same frame as the button tap?
- [ ] Does the bounce animation play smoothly (no jank)?
- [ ] Does rapid tapping (approve → skip → approve quickly) cause any visual glitches?
- [ ] Does `isMounted` guard prevent any errors when rebuilding?
- [ ] Any errors in console related to StreamSubscription or setState after dispose?

---

## Result

**Verdict:** ✅ YES — pattern works cleanly

**Observations:**
- Riverpod `ref.listen` → `GameEventBus.emit()` → `MochiComponent._onEvent()` chain confirmed working
- Color change + ScaleEffect animation triggered correctly on button tap
- `isMounted` guard prevented dispose errors
- Pure-Dart singleton bus successfully decouples Flutter and Flame layers

**Caveats or issues found:**
- Chrome/web only tested (macOS requires Xcode.app — not yet installed)
- Firebase integration not tested (separate spike needed when implementing Parent Approval)

**Next action:**
- ✅ Write GDD #5 — Flutter-Flame State Bridge — using this pattern as the architectural contract
- 📋 Spike Firebase chain separately before implementing Parent Approval System (GDD #11)

---

## Risks NOT tested in this spike

- **Firebase integration:** EventBus only tested locally. When parent approves on a different device (Firebase write → FCM push → app foreground → Riverpod state update → EventBus), the chain is longer. Test this in a separate spike after MVP architecture is designed.
- **Game is paused/backgrounded:** What happens when the app is backgrounded and then foregrounded? Flame may pause the game loop — events emitted during pause may be missed. Need to test with `FlameGame.pauseWhenBackgrounded = false` or event replay on resume.
- **Multiple components subscribing:** This spike tests 1 component. With 10+ components all subscribing to the same bus, need to ensure no ordering issues.
