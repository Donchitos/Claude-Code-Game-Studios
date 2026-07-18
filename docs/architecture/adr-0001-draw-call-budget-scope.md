# ADR-0001: Draw-Call Budget Scope for Flame-Canvas-Hosting Screens

## Status
Accepted (2026-07-07 — flame-specialist validation passed after 4 corrections: removed an overclaim about nonexistent Flame runtime draw-call instrumentation, narrowed a component-type reference, added an Impeller-attribution caveat to Risks, and tightened Validation Criteria with named tools + a missing iOS profiling pass)

## Date
2026-07-07

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Flutter 3.44.4 / Flame 1.37.0 |
| **Domain** | Rendering |
| **Knowledge Risk** | MEDIUM-HIGH (per `docs/engine-reference/flutter-flame/VERSION.md` — project is on versions beyond LLM training cutoff, ~Flutter 3.19/Flame 1.14) |
| **References Consulted** | `docs/engine-reference/flutter-flame/VERSION.md`, `breaking-changes.md`, `current-best-practices.md`, `.claude/docs/technical-preferences.md` |
| **Post-Cutoff APIs Used** | None directly — this ADR is a scope/measurement decision, not a new API adoption. Indirectly relevant: Impeller is now the default renderer (iOS always, Android selectively on Vulkan-capable devices) — see Risks. |
| **Verification Required** | See Validation Criteria — a code-review component tally (Flame side) plus 3 physical-device frame-time profiling passes (Android Vulkan/Impeller, Android OpenGLES fallback, iOS Impeller/Metal) once Pet Room Screen UI (#18) is implemented. |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (ADR-0001, first ADR in the project) |
| **Enables** | Any future ADR or GDD Formula that needs to cite a draw-call or rendering-performance budget for a Flame-canvas-hosting screen (e.g. Room Layout System #28, when it ships in Alpha) |
| **Blocks** | None — Pet Room Screen UI (#18) already shipped its own working interpretation; this ADR ratifies it rather than gating new work |
| **Ordering Note** | None |

## Context

### Problem Statement

`technical-preferences.md`'s Performance Budgets section states: *"Draw Calls: ≤200 per frame (use SpriteBatch for batching repeated sprites)"* — with no further qualification. This project's UI architecture mixes two rendering models on the same screen: Flame's component-tree canvas (immediate-mode-style, where each unbatched `SpriteComponent` submits its own draw call) and Flutter's widget layer (retained-mode, where a layer tree is built once and Skia/Impeller re-rasterizes only changed regions — Flutter does not expose a simple, comparable "N draw calls" count for widget compositing the way Flame does for sprite rendering).

Pet Room Screen UI (#18) — the first GDD to host an actual `FlameGame` canvas — needed this budget to write a testable Formula (a "Draw Call Budget Contract": 1 background + 1 Mochi base + 3 equipment slots = 5, or 2.5% of 200). It adopted an explicit **working assumption** that the 200-call budget applies only to the Flame canvas, not to Flutter overlay chrome (mood indicator, energy bar, level progress bar, Wardrobe bottom sheet, context menu) stacked on top via `GameWidget` overlays. #18's own independent review flagged this as an assertion presented with more certainty than the source document actually supports, and recommended this exact ADR be written before any *other* Flame-canvas-hosting screen (the only one shipped so far is #18 itself; Room Layout System #28 is the next candidate, Alpha-tier) inherits the same reading as unexamined precedent.

### Constraints
- Target platform is mobile (iOS + Android), with a stated memory ceiling of ≤150MB RAM on mid-range 2019+ Android devices and a 60fps / 16.6ms frame budget (`technical-preferences.md`).
- Impeller is the default renderer on iOS (all devices) and selectively on Android (Vulkan-capable, API 29+, falls back to OpenGLES otherwise) — per `breaking-changes.md`, most rendering behaves correctly under Impeller but this hasn't been profiled on this project's actual target hardware yet.
- No screen has yet combined a large Flame canvas with a large amount of Flutter widget chrome simultaneously — #18 is a light case (5 Flame draw calls, modest overlay chrome). The budget's real stress case (a future decorated Room, per Room Layout System #28) doesn't exist yet.

### Requirements
- Must give every future Flame-canvas-hosting GDD (starting with #18, retroactively) an unambiguous, single source of truth for what counts against the ≤200 draw-call figure.
- Must not require inventing a new unified metric that doesn't map cleanly onto how Flutter and Flame actually expose rendering cost (Flutter's widget layer genuinely doesn't have a "draw call count" in the Flame sense).
- Must remain checkable in practice (a developer or QA reviewer must be able to verify compliance without engine-internals expertise).

## Decision

**The ≤200 draw-call budget in `technical-preferences.md` applies to the Flame canvas only** (draw calls submitted through Flame's component-tree rendering — i.e., each unbatched renderable component, such as `SpriteComponent`, not logic-only `PositionComponent`/`Component` nodes that paint nothing — with `SpriteBatch` reducing multiple sprites to fewer submitted calls per `current-best-practices.md`'s guidance).

**Flutter widget compositing (GameWidget overlays, bottom sheets, app bars, etc.) is governed by a separate, second metric — not folded into the same 200-call number** — because Flutter's retained-mode layer tree does not produce a comparable "draw call" count; forcing widget complexity into that framing would produce a number that doesn't mean what it appears to mean. Instead, Flutter-layer rendering cost is tracked via:
- **Frame build/raster time** (via Flutter DevTools' Performance view), held to the same overall 16.6ms/frame budget as everything else — the Flame canvas and Flutter overlay share this same wall-clock budget, they are just not summed into one "draw call" count.
- **Widget rebuild scope discipline**: overlay widgets must use targeted `Consumer`/`Selector`-style rebuild scoping (Riverpod's `select`) rather than rebuilding large widget subtrees on every provider tick — this is the Flutter-side lever equivalent to Flame's `SpriteBatch`.

This ratifies Pet Room Screen UI (#18)'s existing working assumption. #18's Formula 1 (`drawCalls_sceneFlame = drawCalls_background + drawCalls_mochiBase + slotCount = 5`, 2.5% of 200) remains valid as-is — it was already scoped correctly under this decision, it just lacked ADR backing.

### Architecture Diagram

```
Frame budget: 16.6ms (shared, both layers draw within this)
│
├── Flame canvas layer (GameWidget's game render)
│     Budget: ≤200 draw calls/frame (technical-preferences.md, THIS ADR scopes it here)
│     Each unbatched SpriteComponent = 1 draw call
│     SpriteBatch groups N repeated sprites → fewer submitted calls
│     Measured via: manual, design-time tally of renderable components in the tree
│     (per each screen's GDD Formula — Flame 1.37 has no built-in runtime draw-call
│     counter; components paint via ordinary Canvas calls like any Flutter widget)
│
└── Flutter widget layer (overlays stacked via GameWidget.overlayBuilderMap)
      Budget: NOT counted against the 200-call figure
      Governed instead by: frame build/raster time (DevTools Performance view),
      held to the same 16.6ms budget as the whole frame
      Discipline lever: scoped rebuilds (Riverpod .select), not draw-call batching
```

### Key Interfaces

No new runtime API — this is a measurement/scope convention, not a code interface. The convention any future GDD's Formula must follow:

```
drawCalls_sceneFlame(screen) = Σ (Flame component render calls, post-SpriteBatch)
  — this is the ONLY quantity checked against ≤200.

Flutter overlay cost for the same screen is reported separately, in ms
(frame build + raster time), not added to drawCalls_sceneFlame.
```

## Alternatives Considered

### Alternative A: Flame-canvas-only (chosen — see Decision)
- **Description**: Count only draw calls submitted through Flame's rendering pipeline; Flutter widget compositing is out of scope for this specific number.
- **Pros**: Matches how #18 actually derived its own Formula (a manual, design-time component tally — Flame has no runtime draw-call counter to fall back on). Matches #18's existing implementation — zero rework. Keeps the two rendering models' costs legible separately, which is more actionable for a developer optimizing either one.
- **Cons**: A screen could theoretically stay under 200 Flame draw calls while having an expensive Flutter widget tree on top, and the ≤200 number alone wouldn't catch that — mitigated by the separate frame-time requirement below.
- **Rejection Reason**: N/A — this is the chosen alternative.

### Alternative B: Whole-app Skia/Impeller output count
- **Description**: Count every draw call reaching the Skia/Impeller rendering backend regardless of source (Flame canvas + Flutter widgets), since both ultimately lower to the same backend.
- **Pros**: Conceptually "more honest" in the sense that both layers do share the same GPU/rendering backend at the lowest level.
- **Cons**: Flutter's retained-mode compositor does not expose a simple, stable "draw call count" for arbitrary widget trees the way Flame's immediate-style component rendering does — widget rendering is heavily dependent on layer caching, repaint boundaries, and Impeller/Skia internals that change between engine versions (and this project is already on a post-training-cutoff engine version with documented Impeller behavior changes). Any number produced this way would be unstable and hard to attribute to a specific screen decision, defeating the purpose of a budget a GDD author can reason about at design time.
- **Rejection Reason**: Not practically measurable at GDD-authoring time with the tools/knowledge available; would produce a number nobody could act on.

### Alternative C: Two separate budgets, different units (functionally adopted, folded into the Decision above)
- **Description**: A Flame-canvas draw-call budget (≤200, unchanged) plus an explicitly separate Flutter-widget performance consideration, tracked in a different unit (frame time, not draw calls).
- **Pros**: Same as Alternative A, but makes the "Flutter chrome still has a cost, just measured differently" point explicit rather than silent.
- **Cons**: None significant — this is really the same decision as A, stated more completely.
- **Rejection Reason**: Not rejected — merged into the final Decision. The distinction between "A" and "C" collapsed once drafted: scoping the 200-count to Flame-only (A) is incomplete without also stating what governs the Flutter side (C's contribution), so the final Decision is A+C together.

## Consequences

### Positive
- #18's existing Formula 1 needs no rework; this ADR retroactively backs it instead of leaving it as an unratified GDD-level assertion.
- Future Flame-canvas-hosting GDDs (starting with Room Layout System #28 when it's designed) have an unambiguous rule to cite instead of re-deriving or re-guessing the scope.
- Keeps the two performance levers (SpriteBatch for Flame, scoped rebuilds for Flutter) mapped to the metric that actually diagnoses each one.

### Negative
- Two metrics instead of one means a developer has to check both the draw-call count AND the frame-time profile to fully validate a screen — slightly more overhead than a single number, though this reflects real underlying complexity rather than hiding it.
- No automated CI check currently enforces the frame-time side of this budget (only the draw-call count is directly computable from a GDD's Formula) — this is a process gap, not an architecture gap; flagged under Risks.

### Risks
- **Risk**: Impeller's behavior on this project's actual target hardware (mid-range Android, 2019+) hasn't been profiled yet — the 16.6ms frame budget could be harder to hit under Impeller's rendering model than assumed. *Mitigation*: Validation Criteria below requires physical-device profiling before this ADR's frame-time assumption is treated as proven, not just asserted.
- **Risk**: A future GDD author could still misread this ADR and fold Flutter widget cost into the 200-count anyway (the same mistake #18 almost made, in reverse). *Mitigation*: the Key Interfaces convention above is written to be copy-pasteable into a future GDD's Formulas section.
- **Risk (flagged by flame-specialist validation, 2026-07-07)**: `GameWidget` paints the Flame frame through the SAME Flutter rendering pipeline the surrounding overlay widgets use — both ultimately become Impeller/Skia canvas operations composited into ONE layer tree per frame. DevTools' frame build/raster time is therefore a **combined total** for Flame canvas + Flutter overlay together — it does NOT cleanly attribute a budget overrun to one layer or the other. *Mitigation*: if a screen's frame time regresses, use Timeline events (`debugProfilePaintsEnabled`) or platform-native GPU frame capture (see Validation Criteria) to localize the cause — do not assume DevTools' Performance view alone can isolate "the Flutter layer's" contribution.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|---------------------------|
| Pet Room Screen UI (#18) | Formula 1 — Draw Call Budget Contract, needed a ratified scope for "≤200 draw calls/frame" to compute `drawCalls_sceneFlame = 5` as 2.5% utilization | Ratifies #18's existing Flame-canvas-only interpretation; #18 needs no changes, this ADR is the missing citation its own Open Questions asked for |

## Performance Implications
- **CPU/GPU**: No change from current behavior — this ADR documents a measurement convention, it does not change any rendering code or add overhead.
- **Memory**: None.
- **Load Time**: None.
- **Network**: N/A.

## Migration Plan
None required — no existing code or GDD needs to change. This ADR formalizes a convention #18 already follows.

## Validation Criteria
**(Tightened 2026-07-07 per flame-specialist validation — original draft named DevTools for a measurement it can't produce, and covered only 2 of 3 target rendering paths.)**

- **Flame-side check (code review, not device profiling)**: once Pet Room Screen UI (#18) is implemented, verify by code review that the actual mounted component tree matches the Formula's manual tally (5: 1 background + 1 Mochi base + 3 equipment slots) — this is a static count, not something DevTools measures. If a *true* GPU draw-call count is ever needed (e.g. for a much larger future screen), that requires platform-native GPU capture — Xcode Metal System Trace on iOS, or Android GPU Inspector / `adb shell dumpsys gfxinfo` / Perfetto on Android — DevTools alone cannot produce it.
- **Flutter-side check (device profiling, 3 passes — all 3 target rendering paths, not 2)**: profile frame build/raster time via Flutter DevTools' Performance view on physical devices covering:
  1. Android, Impeller/Vulkan path (Vulkan-capable device, API 29+)
  2. Android, OpenGLES fallback path (non-Vulkan-capable device)
  3. **iOS, Impeller/Metal path** (added — iOS is always on Impeller per `breaking-changes.md` and is a stated target platform; the original draft omitted it entirely, leaving zero validation coverage on that path)
  All 3 must stay within the 16.6ms/frame budget with #18's actual Flutter overlay chrome mounted. Remember (see Risks) that this number is a Flame+Flutter combined total, not Flutter-only — do not attempt to subtract an assumed Flame contribution from it.
- If either check fails, this ADR's Decision does not need to change (the scope convention is still valid) — but the underlying screen's implementation would need optimization, and that finding should be logged as a new Risk here, not a reason to re-litigate scope.

## Related Decisions
- None yet (ADR-0001, first ADR in the project).
- Related design document: `design/gdd/pet-room-screen-ui.md` (Formula 1, Open Questions).
