# Flutter-Flame State Bridge

> **Status**: Approved ✅
> **Author**: User + Agents
> **Last Updated**: 2026-06-26
> **Implements Pillar**: Pillar 4 — Bố Mẹ Là Đồng Minh (approval action must reach Mochi instantly)

## Overview

Flutter-Flame State Bridge là module infrastructure trung gian kết nối Flutter state management (Riverpod) với Flame game loop. Nó đảm bảo rằng mọi thay đổi trạng thái phía Flutter — bố mẹ approve task, bé mua item, năng lượng thay đổi — đều được dịch thành một `GameEvent` và phát vào `GameEventBus` để các Flame component đăng ký và phản ứng bằng animation, màu sắc, hoặc hiệu ứng trực quan trong game loop.

Kiến trúc một chiều: **Flutter emits → Bus routes → Flame receives.** Flame components không bao giờ gọi trực tiếp vào Flutter layer. Bridge được validate bởi spike `prototypes/flutter-flame-bridge-spike-2026-06-26/`.

Không có Bridge, khi bố mẹ bấm Approve, Mochi sẽ không phản ứng — không có animation hạt giống nổ ra xu, không có bounce vui mừng. Toàn bộ emotional feedback loop đổ vỡ.

## Player Fantasy

Hệ thống này không có player fantasy trực tiếp. Người chơi không tương tác với Bridge — họ tương tác với Mochi và Shop.

Fantasy mà Bridge *cho phép* xảy ra:
- **Bé**: Bấm "Xong" trên task → thấy hạt giống rơi bộp vào túi → cảm giác nỗ lực của mình được ghi nhận ngay lập tức.
- **Bố mẹ**: Bấm Approve trên điện thoại → trong tích tắc Mochi của bé nhảy lên vui mừng (kể cả khi hai người đang ở hai phòng khác nhau).

Bridge là lý do tại sao khoảnh khắc đó *cảm thấy như magic* thay vì lag một nhịp.

## Detailed Design

### Core Rules

**1. Kiến trúc một chiều (One-Way Data Flow)**

Flutter state là source of truth. Flame là display layer. Không bao giờ ngược lại.

```
[Riverpod Notifier] → (state change)
      ↓
[ref.listen trong ConsumerWidget]  ← adapter duy nhất được phép bridge
      ↓
[GameEventBus.emit(GameEvent)]
      ↓
[GameEventBus broadcast stream]
      ↓
[Flame Component._onEvent()]  → animation / visual change
```

**2. GameEventBus — Pure Dart Singleton**
- `StreamController<GameEvent>.broadcast()` — cho phép nhiều component subscribe cùng lúc
- Không import Flutter, không import Flame — chỉ Dart thuần
- Singleton pattern: `factory GameEventBus() => _instance`
- Dispose chỉ khi app terminate (không dispose giữa screen navigations)

**3. GameEvent — Typed Event Contract**
```dart
enum GameEventType { petMoodChanged, seedReceived, itemEquipped, energyChanged, petLeveledUp, petInteracted, taskApproved }
class GameEvent { final GameEventType type; final dynamic data; }
```
Mỗi event type có `data` type được document rõ (xem bảng Interactions bên dưới).

**4. Flutter Bridge Adapter — ref.listen**
- Mỗi Riverpod provider cần bridge sang Flame phải có một `ref.listen` call trong Widget tương ứng
- `ref.listen` chỉ fire khi state *thay đổi* — không fire lại trên rebuild
- Widget chịu trách nhiệm map từ Riverpod state sang `GameEvent`

**5. Flame Component — Subscribe Pattern**
```dart
StreamSubscription? _sub;
@override void onMount() {          // onMount(), KHÔNG onLoad() — xem ghi chú (ADR-0004)
  super.onMount();
  _sub = GameEventBus().stream.listen(_onEvent);
}
void _onEvent(GameEvent e) {
  if (!isMounted) return; // bắt buộc
  // handle event
}
@override void onRemove() {
  _sub?.cancel(); // bắt buộc
  super.onRemove();
}
```
`isMounted` check là bắt buộc. `cancel()` trong `onRemove()` là bắt buộc.

> ⚠️ **Subscribe trong `onMount()`, KHÔNG `onLoad()`** (verified vs Flame 1.37 source, ADR-0004): trong suốt `onLoad()` thì `isMounted` vẫn `false` → guard `if (!isMounted) return;` sẽ **âm thầm drop mọi event** đến trong cửa sổ load→mount (không queue, mất luôn). Ngoài ra `onMount` được đảm bảo pair 1:1 với `onRemove` (onLoad thì không → có thể leak nếu removal race lúc load), và `onLoad` chỉ chạy 1 lần duy nhất (component bị remove rồi add lại sẽ ngừng nhận event nếu subscribe ở onLoad). Spike prototype subscribe ở `onLoad()` chỉ để test latency/routing — code production phải dùng `onMount()`.

---

### States and Transitions

| Event Type | Data Type | Flame Consumer | Visual Response |
|------------|-----------|----------------|-----------------|
| `petMoodChanged` | `PetMood` enum | `MochiComponent` | Color + ScaleEffect |
| `seedReceived` | `SeedData` | `SeedBagComponent` | Drop animation |
| `itemEquipped` | `String itemId` | `PetEquipComponent` | Overlay sprite swap |
| `energyChanged` | `double energy` | `EnergyBarComponent` | Bar fill animation |
| `petLeveledUp` | `int newLevel` | `MochiComponent` → Pet State Machine `LEVELING_UP` | 3s trigger animation; sprite swap after, if evolution level |
| `petInteracted` | `InteractionType` enum (Pet Interaction #14) | Pet State Machine → trigger `PLEASED` state | Eyes close + wiggle (2s), theo #6's Triggered State timer |
| `taskApproved` | `void`/`null` (no payload cần thiết — chỉ là signal) | Pet State Machine → trigger `EXCITED` state | Scale bounce ×1.3 + sparkles (1.5s), theo #6's Triggered State timer. **Mới thêm 2026-07-06 (fix Scenario 1 blocker từ review-all-gdds)**: Parent Approval (#11) trước đây emit `GameEvent(petMoodChanged → EXCITED)`, nhưng `petMoodChanged`'s payload type là `PetMood` (Base Mood enum: HAPPY/CONTENT/TIRED/SAD/SLEEPING) — EXCITED là Triggered State, enum khác hoàn toàn. Cast sai type này sẽ throw `TypeError` tại runtime theo Edge Cases dưới đây. `taskApproved` là event type riêng, đúng kiểu, cho đúng mục đích này. |

---

### Interactions with Other Systems

| System | Direction | Data | Interface |
|--------|-----------|------|-----------|
| Pet State Machine | upstream → Bridge | `PetMood` enum | `ref.listen(petMoodProvider)` |
| Seed Buffer Mechanic | upstream → Bridge | `SeedData` | `ref.listen(seedBagProvider)` |
| Pet Equipment System | upstream → Bridge | `String itemId` | `ref.listen(equippedItemProvider)` |
| Pet Interaction System | #14 → Bridge (ngược hướng thường lệ — #14 là Flame component TỰ emit, không qua `ref.listen`) | `InteractionType` enum | `GameEventBus().emit(GameEvent(petInteracted, ...))` gọi trực tiếp từ #14's `TapCallbacks`/`DragCallbacks` handler |
| Pet Room Screen UI | Bridge → downstream | `GameEvent` stream | `GameEventBus().stream` |
| Pet Leveling | upstream → Bridge | `int newLevel` | `ref.listen(petLevelProvider)` emits `GameEvent(petLeveledUp)` |

## Formulas

Không có mathematical formula. Bridge là pure event routing.

**Event Routing Contract:**

| Variable | Symbol | Type | Value | Mô tả |
|----------|--------|------|-------|-------|
| Max subscribers per event | `maxSubs` | int | không giới hạn | broadcast stream hỗ trợ N subscribers |
| Event delivery latency | `latency` | ms | <1ms (local) | stream sync trong Dart isolate |
| Event queue size | `queueSize` | — | unbounded | StreamController không buffer — fire-and-forget |
| isMounted check | — | bool | required | mọi handler phải check trước khi xử lý |

**Firebase chain latency (đã spike — measured, không còn provisional):**

```
Parent approve (device B) → Firestore write → FCM push → App foreground
→ Riverpod state update → ref.listen → GameEventBus → Flame animation
```

**Measured end-to-end** (`prototypes/firebase-multidevice-sync-spike-2026-07-03/`, n=8 trials trên Firestore project thật): avg 151ms, min 127ms, max 439ms — "feels instant" theo verdict của spike, tốt hơn nhiều so với ước tính 1-5s ban đầu. Chỉ local (same-device) phải <1ms.

**Còn mở (chưa exercised bởi spike)**: offline-reconnect / background-event-replay path — spike đo real-time sync khi cả 2 devices online, chưa test trường hợp device B offline lúc approve rồi reconnect sau. Pet Leveling's Edge Case 3 dựa vào path này. Khuyến nghị: verify thủ công (~10 phút) trong lúc implement Parent Approval (#11), theo spike's own recommendation — không block ADR viết, nhưng ADR nên note đây là validation criterion chưa đóng, không phải guarantee đã proven.

## Edge Cases

- **Nếu Flame component bị remove khỏi game tree trong khi event đang xử lý**: `isMounted` check trong `_onEvent()` sẽ return sớm — không crash, không side effect.

- **Nếu `_sub?.cancel()` bị quên trong `onRemove()`**: StreamSubscription leak — component bị remove nhưng vẫn nhận event, có thể trigger null reference. **Phải cancel trong `onRemove()`** — không ngoại lệ.

- **Nếu app bị background trong khi event đang emit, HOẶC nếu component bị tạo lại do navigation** (⚠️ sửa 2026-07-13, xem ADR-0004 §5 Correction note — phát hiện qua `/vertical-slice`): Flame game loop pause nhưng StreamController vẫn emit → event bị miss vì component không chạy `update()`; **và tương tự**, một component mới được mount lại (vd: rời màn rồi quay lại) sẽ không tự động nhận được event transition đã xảy ra trước khi nó tồn tại (`ref.listen` chỉ fire khi có thay đổi, không có thay đổi mới nào xảy ra sau khi component mount lại). **Giải pháp đúng (bus-level, không phải chỉ app-lifecycle)**: `GameEventBus` phải cache event cuối cùng theo từng type và replay ngay cho bất kỳ subscriber mới nào tại thời điểm subscribe — không chỉ khi app foreground trở lại.

- **Nếu hai event cùng type emit liên tiếp nhanh (rapid tap)**: broadcast stream deliver tuần tự — không race condition. Component nhận lần lượt và apply effect. ScaleEffect cũ bị clear trước khi effect mới add (xem `_clearEffects()` trong spike).

- **Nếu `GameEventBus.dispose()` được gọi sớm** (ví dụ: screen pop nhầm): `emit()` check `!_controller.isClosed` — silent fail, không crash. Nhưng sau đó không có event nào được delivered. Log warning để debug.

- **Nếu `data` cast sai type** (ví dụ: `petMoodChanged` nhưng data không phải `PetMood`): Dart sẽ throw `TypeError` tại runtime. Mỗi `_onEvent()` handler phải check `event.type` trước khi cast `event.data`.

## Dependencies

**Hard dependencies (không thể hoạt động nếu thiếu):**
- **Auth & Account** (GDD #1 ✅ Approved): Bridge scope Riverpod providers theo `activeChildProvider` từ Auth GDD. Provider contract: `authStateProvider`, `activeChildProvider`, `parentProfileProvider` — tất cả export từ `lib/providers/auth_providers.dart`.

**Soft dependencies (enhanced by, không bắt buộc):**
- **Pet State Machine** (#6): Cung cấp `PetMood` — consumer chính của `petMoodChanged` event.
- **Seed Buffer Mechanic** (#10): Cung cấp `SeedData` — trigger `seedReceived` event.
- **Pet Equipment System** (#15): Cung cấp `itemId` — trigger `itemEquipped` event.

**Downstream dependents (Bridge phải satisfy):**
- **Pet Interaction System** (#14): KHÔNG subscribe `petMoodChanged` — #14 là bên **emit** `petInteracted` (tap/swipe trên Mochi sprite → `GameEventBus().emit()` trực tiếp từ Flame component, không qua `ref.listen`). Bridge phải đảm bảo `GameEventBus` singleton sẵn sàng để #14 gọi `emit()` bất kỳ lúc nào sau khi component `onLoad()`. (Sửa mô tả sai trước đó — #14 không phải consumer của `petMoodChanged`.)
- **Pet Room Screen UI** (#18): Subscribe multiple events để update visual state của toàn màn hình.

**Interface contract (upstream → Bridge):**
Mỗi upstream system phải expose một Riverpod provider. Bridge adapter (`ref.listen`) là glue code trong ConsumerWidget — không phải trong Notifier, không phải trong Flame component.

## Tuning Knobs

Bridge là pure routing — không có gameplay values cần tune. Tuy nhiên:

| Knob | Default | Safe Range | Quá cao | Quá thấp | Ghi chú |
|------|---------|------------|---------|----------|---------|
| `eventTypes` enum count | 4 | 4–20 | Không giới hạn — chỉ thêm khi thực sự cần | — | Thêm mỗi khi có visual feedback mới cần bridge |
| App-background replay strategy | Replay last state | — | Replay full history → event storm | Skip replay → Mochi "đơ" sau foreground | Chỉ replay state cuối cùng của mỗi type |
| StreamController type | broadcast | broadcast only | — | single-subscription → chỉ 1 subscriber → bug | Luôn dùng broadcast |

## Visual/Audio Requirements

Không áp dụng — Bridge là pure infrastructure, không có visual hoặc audio output trực tiếp.

## UI Requirements

Không áp dụng — Bridge không render bất kỳ UI nào. UI thuộc về các system downstream (Pet Room Screen UI, Task Management UI).

## Acceptance Criteria

**GIVEN** app đang chạy và `MochiComponent` đã mounted,
**WHEN** `ref.listen` phát `GameEvent(petMoodChanged, PetMood.happy)`,
**THEN** `MochiComponent` đổi màu sang Mint Green và chạy `ScaleEffect` bounce trong vòng 1 frame (<16.6ms).

**GIVEN** `MochiComponent` bị remove khỏi game tree,
**WHEN** `GameEventBus` emit bất kỳ event nào,
**THEN** không có exception, không có visual artifact — event bị bỏ qua silently.

**GIVEN** hai event `petMoodChanged` emit liên tiếp trong <100ms,
**WHEN** `MochiComponent` nhận cả hai,
**THEN** chỉ effect của event thứ hai được hiển thị — effect thứ nhất bị clear trước.

**GIVEN** app bị background rồi foreground trở lại,
**WHEN** Riverpod state replay last known mood,
**THEN** `MochiComponent` hiển thị đúng mood hiện tại mà không cần user interaction.

**GIVEN** một Flame component mới được add vào game tree sau khi Bridge đã khởi tạo,
**WHEN** component gọi `GameEventBus().stream.listen()` trong `onMount()` (KHÔNG phải `onLoad()` — `isMounted` vẫn `false` suốt `onLoad()`, guard `if(!isMounted) return;` sẽ âm thầm drop event; xem Core Rule 5 + ADR-0004 §4),
**THEN** component nhận tất cả event từ thời điểm subscribe — không cần restart.

**GIVEN** `GameEventBus.dispose()` được gọi,
**WHEN** code tiếp tục gọi `GameEventBus().emit()`,
**THEN** emit silent-fail (không crash), console log warning "EventBus is closed".

## Open Questions

- ~~**Firebase chain spike**: Khi bố mẹ approve trên device khác... latency thực tế là bao nhiêu? Cần spike riêng trước khi implement Parent Approval System (GDD #11).~~ **Resolved (2026-07-03, đóng 2026-07-07 — cosmetic staleness tìm thấy khi gate-check re-run)**: Spike đã chạy — `prototypes/firebase-multidevice-sync-spike-2026-07-03/`, avg 151ms/n=8. Xem Formulas section phía trên.
- **Background event miss**: Nếu parent approve khi app của bé đang background và FCM wakes app — event replay strategy có đủ không, hay cần persistent event queue?
- **Auth scoping**: Resolved — Bridge sử dụng `activeChildProvider` từ Auth & Account GDD (#1). ✅
