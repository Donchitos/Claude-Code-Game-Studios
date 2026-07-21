# Story 004: FCM Foreground Banner — Defer/Coalesce State Machine & Permission Reminder

> **Epic**: Parent Dashboard UI
> **Status**: **Blocked**
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: 3h (once unblocked)
> **Manifest Version**: 2026-07-16
> **Last Updated**: —

## ⚠️ BLOCKED

**No ADR exists for the banner defer/coalesce state machine.** `docs/architecture/architecture.md`'s own Required ADRs list names this explicitly: *"Parent Dashboard Notification Banner State Machine — not yet written."* This is the GDD's only `[LOGIC]`-tier requirement (a real state machine with input-dependent branching) — run `/architecture-decision` to create and Accept an ADR before implementing this story. Do not implement from the GDD/UX-spec text alone; the ADR must formalize the `unseenCount` state transitions, the defer-during-modal mechanism, and the banner-slot-conflict resolution (FCM vs. reminder banner) the UX spec resolved during `/ux-design`.

---

## Context

**GDD**: `design/gdd/parent-dashboard-ui.md`
**Requirement**: `TR-parentdash-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: **None — this is the blocker.** Once written, update this field before removing the Blocked status.
**ADR Decision Summary**: N/A until the ADR exists.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 — pure Flutter widget layer, no Flame | **Risk**: Unknown until ADR is written — likely LOW (this is a Riverpod state machine + `FirebaseMessaging.onMessage` listener, both already-established patterns elsewhere in the codebase, e.g. Push Notification #9's own foreground handling).
**Engine Notes**: `firebase_messaging` is already confirmed resolving to `16.4.3` with the needed APIs present (Push Notification epic's own findings) — the ADR should confirm this still holds, not re-derive it from scratch.

**Control Manifest Rules (this layer)** *(to be confirmed/expanded by the ADR)*:
- Required: Riverpod state (`unseenCount`) must be screen-scoped, not global singleton (matches P1's own screen-scoped in-flight state convention).
- Required: single-flight guard pattern for banner state transitions — same class of correctness concern as P1, though this isn't a write-guard, it's a display-state guard.

**Performance Budget**: No dedicated latency contract for the banner's own state transitions — the underlying FCM delivery latency is Push Notification (#9)'s concern, not this story's.

---

## Acceptance Criteria

*From GDD Core Rules 6, 7 and Edge Cases 4, 5 — held here for when the story unblocks, NOT yet implementation-ready without the ADR above:*

- [ ] **Banner appears on message**: GIVEN app đang mở foreground (bất kỳ tab nào), WHEN `FirebaseMessaging.onMessage` fire, THEN `MaterialBanner` hiện ở top của Tab Nhiệm vụ với text "[Tên bé] vừa hoàn thành [task]".
- [ ] **Banner tap — from Gia đình tab**: GIVEN banner hiện trên Tab Gia đình, WHEN tap banner, THEN navigate sang Tab Nhiệm vụ.
- [ ] **Banner tap — already on Nhiệm vụ**: GIVEN banner hiện khi đã ở Tab Nhiệm vụ, WHEN tap banner, THEN không navigate (no-op), banner dismiss.
- [ ] **Permission-declined reminder — once per session**: GIVEN bố mẹ đã decline notification permission, VÀ đây là session đầu (cold start) mở dashboard, WHEN Tab Nhiệm vụ hiển thị, THEN reminder banner hiện đúng 1 lần trong session đó (session = process lifetime).
- [ ] **Reminder not re-shown mid-session**: GIVEN banner đã bị dismiss trong session hiện tại, WHEN chuyển tab đi rồi quay lại (không kill app), THEN banner KHÔNG hiện lại.
- [ ] **Reminder re-shown after cold start**: GIVEN app bị kill và mở lại, VÀ permission vẫn declined, THEN banner hiện lại 1 lần.
- [ ] **Banner deferred during modal**: GIVEN bất kỳ modal đang mở (create-task sheet HOẶC Reset PIN dialog), WHEN FCM message đến, THEN banner KHÔNG hiện chồng lên; WHEN modal đóng, THEN banner hiện ngay sau đó nếu chưa bị thay bởi banner mới hơn.
- [ ] **Coalescing — 2+ messages**: GIVEN ≥2 FCM messages đến mà chưa "được xem" (counter chỉ reset khi tap hoặc dismiss — KHÔNG reset chỉ vì tab được xem), THEN banner hiện coalesced "N nhiệm vụ mới đang chờ" thay vì N banner riêng.
- [ ] **Live-update, not replace**: GIVEN banner "2 nhiệm vụ mới đang chờ" đang hiện (`unseenCount=2`, chưa tap/dismiss), WHEN message thứ 3 đến, THEN banner live-update tại chỗ thành "3 nhiệm vụ mới đang chờ" — KHÔNG banner thứ 2 nào được tạo, KHÔNG dismiss-then-show animation.
- [ ] **Banner-slot conflict resolution** (resolved during `/ux-design`, not in the original GDD): GIVEN reminder banner đang hiện, WHEN FCM message đến, THEN FCM banner thay thế ngay tại cùng vị trí — reminder coi như đã "được thấy," không hiện lại trong session đó.

---

## Implementation Notes

**Do not implement until the governing ADR exists and is Accepted.** Once it is, replace this section with guidance derived from that ADR's Decision/Implementation Guidelines, following the same pattern every other story in this project uses (ADR is the source of truth for implementation shape; this section transcribes it, does not reinterpret it).

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 001 (this epic)**: reserves the banner's layout slot but does not implement banner logic.
- **Push Notification (#9)**: FCM delivery mechanism itself, permission request flow, background/OS-tray notification handling — this story only handles the foreground in-app case.

---

## QA Test Cases

*Not yet written — deferred until the ADR exists and story unblocks. Transcribe from the Acceptance Criteria above using the same Given/When/Then format the rest of this epic's stories use, once implementation-ready.*

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/parent-dashboard-ui/fcm_banner_state_machine_test.dart` — must exist and pass (BLOCKING per coding-standards.md's Logic-story rule)

**Status**: [ ] Not yet created — story Blocked, cannot start

---

## Dependencies

- Depends on: **An Accepted ADR for the banner state machine** (blocking — see top of file). Also benefits from Story 001 existing first (shares the Nhiệm vụ tab's banner slot), though not strictly a hard dependency.
- Unlocks: None further within this epic.
