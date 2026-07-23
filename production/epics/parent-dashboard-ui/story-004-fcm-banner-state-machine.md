# Story 004: FCM Foreground Banner — Defer/Coalesce State Machine & Permission Reminder

> **Epic**: Parent Dashboard UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Logic
> **Estimate**: 3h
> **Manifest Version**: 2026-07-16
> **Last Updated**: 2026-07-23

## Unblocked — 2026-07-22

ADR-0015 (Parent Dashboard Notification Banner State Machine) written and Accepted — see `docs/architecture/adr-0015-parent-dashboard-notification-banner-state-machine.md`. This story can now proceed to `/dev-story`.

---

## Context

**GDD**: `design/gdd/parent-dashboard-ui.md`
**Requirement**: `TR-parentdash-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: **ADR-0015** (Parent Dashboard Notification Banner State Machine, Accepted 2026-07-22).
**ADR Decision Summary**: A pure `BannerState`/`BannerActions` Riverpod state machine (`bannerStateProvider`/`bannerActionsProvider`) drives a `displayKind` (`none`/`fcm`/`reminder`) derived purely from `unseenCount`/`isModalOpen`/`permissionDeclined`/`reminderConsumedThisSession`. Rendered via `ScaffoldMessenger.showMaterialBanner()`/`.hideCurrentMaterialBanner()` inside `ParentShellScaffold` (**never** a `Stack` — that subtree has an existing structural "no Stack" test from Main Navigation Shell Story 003 that must not break). Modal defer is wired via two explicit `modalOpened()`/`modalClosed()` call-site edits in `create_custom_task_sheet.dart` and `parent_dashboard_family_tab.dart`. Full transition logic, Key Interfaces, and a worked example of every GDD Edge Case (including the 3-message-during-modal permutation) are in the ADR's Decision section — implement from there, this section only summarizes.

**Engine**: Flutter 3.44.4 / Flame 1.37.0 — pure Flutter widget layer, no Flame | **Risk**: LOW — `MaterialBanner`/`ScaffoldMessenger` verified against installed Flutter 3.44.6 SDK source (ADR-0015 Engine Compatibility); `firebase_messaging.onMessage`/`getNotificationSettings()` already verified by ADR-0010.
**Engine Notes**: `ref.listenManual` (not `ref.listen` in `build`) is required for the `initState`-registered `onMessage` subscription and the `displayKind`-driven `ScaffoldMessenger` sync — same pattern already used by `mood_event_bridge.dart` in this codebase, confirmed present in the pinned `flutter_riverpod 3.3.2`.

**Control Manifest Rules (this layer)**:
- Required: `bannerStateProvider` is screen-scoped (Parent Shell level), not a global singleton — ADR-0015 Decision §2.
- Required: no `Stack` widget introduced in `ParentShellScaffold`'s subtree — ADR-0015 Decision §1 / registry `forbidden_patterns.parent_shell_stack_overlay`.
- Required: banner rendering goes through `ScaffoldMessenger.showMaterialBanner`/`.hideCurrentMaterialBanner` only — registry `interfaces.parent_dashboard_banner_render`.

**Performance Budget**: No dedicated latency contract for the banner's own state transitions — the underlying FCM delivery latency is Push Notification (#9)'s concern, not this story's.

---

## Acceptance Criteria

*From GDD Core Rules 6, 7 and Edge Cases 4, 5:*

- [x] **Banner appears on message**: GIVEN app đang mở foreground (bất kỳ tab nào), WHEN `FirebaseMessaging.onMessage` fire, THEN `MaterialBanner` hiện ở top của Tab Nhiệm vụ với text "[Tên bé] vừa hoàn thành [task]".
- [x] **Banner tap — from Gia đình tab**: GIVEN banner hiện trên Tab Gia đình, WHEN tap banner, THEN navigate sang Tab Nhiệm vụ.
- [x] **Banner tap — already on Nhiệm vụ**: GIVEN banner hiện khi đã ở Tab Nhiệm vụ, WHEN tap banner, THEN không navigate (no-op), banner dismiss.
- [x] **Permission-declined reminder — once per session**: GIVEN bố mẹ đã decline notification permission, VÀ đây là session đầu (cold start) mở dashboard, WHEN Tab Nhiệm vụ hiển thị, THEN reminder banner hiện đúng 1 lần trong session đó (session = process lifetime).
- [x] **Reminder not re-shown mid-session**: GIVEN banner đã bị dismiss trong session hiện tại, WHEN chuyển tab đi rồi quay lại (không kill app), THEN banner KHÔNG hiện lại.
- [x] **Reminder re-shown after cold start**: GIVEN app bị kill và mở lại, VÀ permission vẫn declined, THEN banner hiện lại 1 lần.
- [x] **Banner deferred during modal**: GIVEN bất kỳ modal đang mở (create-task sheet HOẶC Reset PIN dialog), WHEN FCM message đến, THEN banner KHÔNG hiện chồng lên; WHEN modal đóng, THEN banner hiện ngay sau đó nếu chưa bị thay bởi banner mới hơn.
- [x] **Coalescing — 2+ messages**: GIVEN ≥2 FCM messages đến mà chưa "được xem" (counter chỉ reset khi tap hoặc dismiss — KHÔNG reset chỉ vì tab được xem), THEN banner hiện coalesced "N nhiệm vụ mới đang chờ" thay vì N banner riêng.
- [x] **Live-update, not replace**: GIVEN banner "2 nhiệm vụ mới đang chờ" đang hiện (`unseenCount=2`, chưa tap/dismiss), WHEN message thứ 3 đến, THEN banner live-update tại chỗ thành "3 nhiệm vụ mới đang chờ" — KHÔNG banner thứ 2 nào được tạo, KHÔNG dismiss-then-show animation.
- [x] **Banner-slot conflict resolution** (resolved during `/ux-design`, not in the original GDD): GIVEN reminder banner đang hiện, WHEN FCM message đến, THEN FCM banner thay thế ngay tại cùng vị trí — reminder coi như đã "được thấy," không hiện lại trong session đó.

---

## Implementation Notes

*Derived from ADR-0015's Decision section — implement from the ADR directly, this transcribes the shape, not the full reasoning:*

1. `BannerState`/`BannerActions`/`bannerStateProvider`/`bannerActionsProvider` — new file, e.g. `src/lib/providers/banner_providers.dart` (matches this epic's one-domain-per-provider-file convention, e.g. `parent_approval_providers.dart`). `displayKind` is a pure getter on `BannerState`, never stored (ADR-0015 Decision §2 — copy the exact reducer logic, including the `messageReceived`/`bannerDismissedOrTapped` transitions).
2. `_ParentShellScaffoldState` (`src/lib/ui/parent_shell_scaffold.dart`, Main Navigation Shell epic, Complete): add the `FirebaseMessaging.onMessage` subscription + `getNotificationSettings()` resolution in `initState`, a `ref.listenManual`-driven `ScaffoldMessenger.showMaterialBanner`/`.hideCurrentMaterialBanner` sync, and cleanup in `dispose()` (ADR-0015 Decision §4). **Do not wrap `widget.navigationShell` in a `Stack`** — see the file's own doc comment and registry `forbidden_patterns.parent_shell_stack_overlay`.
3. `create_custom_task_sheet.dart`'s `showCreateCustomTaskSheet` and `parent_dashboard_family_tab.dart`'s `showResetPinDialog`: wrap the existing `showModalBottomSheet`/`showDialog` calls with `modalOpened()`/`modalClosed()` (try/finally) — ADR-0015 Decision §3.
4. `parent_dashboard_tasks_tab.dart`: remove the now-dead reserved `SizedBox.shrink()` banner slot (ADR-0015 Decision §6 — Story 001's placeholder is superseded by the shell-level `MaterialBanner` approach).
5. Display text: `unseenCount == 1` reuses `familyPendingTasksProvider`/`childProfilesProvider` (already-loaded, no new Firestore read) to render "[Tên bé] vừa hoàn thành [task]"; `unseenCount >= 2` uses the fixed "N nhiệm vụ mới đang chờ" string; a generic fallback covers the rare lookup-miss race (ADR-0015 Decision §5).
6. `MaterialBanner.actions` is required and non-empty — an explicit dismiss action button is mandatory; swipe-to-dismiss (GDD's "swipe hoặc tap" wording) requires wrapping in a `Dismissible` and is an optional UX enhancement, not a hard requirement (ADR-0015 Decision §1's GDD-correction note).
7. `elevation: 0` (default) makes the banner reflow content downward rather than float over it — this is CORRECT per GDD's "slide-down, không phải popup chặn màn hình," do not add elevation to "fix" it (ADR-0015 Decision §1).

---

## Out of Scope

*Handled by neighbouring stories or future epics — do not implement here:*

- **Story 001 (this epic)**: pending-list rendering itself — this story only removes that story's now-dead reserved banner slot (Implementation Note 4).
- **Push Notification (#9)**: FCM delivery mechanism itself, permission request flow, background/OS-tray notification handling — this story only handles the foreground in-app case.
- **ADR-0015's own scope boundary**: this story implements exactly what the ADR decided; do not redesign the state machine shape while implementing.

---

## QA Test Cases

*Transcribed from ADR-0015's Validation Criteria + the Acceptance Criteria above:*

- **Banner appears / live-updates / coalesces** (Core Rule 6): given 1, then 2, then 3 messages arrive with no modal open and no prior dismiss, THEN `displayKind` stays `fcm` throughout and `unseenCount` reads 1→2→3 with no intermediate `none` state (never a second banner spawned).
- **Defer during modal** (Edge Case 4): given a message arrives while `isModalOpen == true`, THEN `displayKind == none`; WHEN the modal closes, THEN `displayKind` reflects the pending `unseenCount` immediately.
- **3-message-during-modal permutation** (Edge Case 5, the GDD's own explicitly-resolved case): 2 messages arrive while a modal is open (`unseenCount=2`, deferred) → modal closes (banner shows "2 đang chờ") → a 3rd message arrives before tap/dismiss → banner live-updates to "3 đang chờ", no second banner, no dismiss-then-show transition.
- **Banner-slot conflict resolution**: given the reminder is currently displayed (`displayKind == reminder`), WHEN a message arrives, THEN `displayKind` becomes `fcm` AND `reminderConsumedThisSession == true` — reminder never reappears later in the same `BannerState` lineage even after the FCM banner is dismissed.
- **Reminder session scoping**: given `permissionDeclined == true` and no prior dismiss/consumption, THEN `displayKind == reminder`; after `bannerDismissedOrTapped()`, THEN `displayKind` never returns to `reminder` for the rest of that in-memory session (a fresh `BannerState()` — i.e. app cold start — is the only way it resets).
- **Tap vs. dismiss have identical state transitions**: both call `bannerDismissedOrTapped()`; the ONLY difference is the widget layer's navigation side-effect (tap navigates to Tab Nhiệm vụ if not already there; dismiss never navigates) — not part of the pure reducer's own test surface, but the integration test should confirm the widget layer respects this split.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/parent-dashboard-ui/fcm_banner_state_machine_test.dart` — must exist and pass (BLOCKING per coding-standards.md's Logic-story rule), covering every QA Test Case above as a pure `BannerState`/`BannerActions` reducer test.

**Status**: [x] Created — 23/23 tests passing (BLOCKING, mutation-tested in code review against 2 plausible bug classes: `displayKind` precedence order, blanket-vs-scoped reminder consumption). Plus `tests/integration/parent-dashboard-ui/parent_shell_banner_test.dart` — 7/7 tests passing (ADVISORY widget-layer coverage, added during code review after both reviewers independently flagged this story's own QA Test Case 6 — "tap vs. dismiss" navigation split — had no widget-level test; covers `MaterialBanner` rendering, live-update-in-place, tap-navigates-if-not-already-there, dismiss-never-navigates, and the reminder→FCM banner-slot-conflict replacement with no queueing).

---

## Dependencies

- Depends on: ADR-0015 (Accepted 2026-07-22). Story 001 (Complete — this story removes its now-dead banner slot, Implementation Note 4).
- Unlocks: None further within this epic. This is the last story in Parent Dashboard UI — closes the epic once done.

---

## Completion Notes
**Completed**: 2026-07-23
**Criteria**: 10/10 passing (all auto-verified via tests; no manual/deferred criteria)
**Deviations**:
- ADVISORY: `_ParentShellScaffoldState.initState()` resolves notification permission status via the pre-existing `firebaseMessagingProvider` DI seam (`core/firebase_providers.dart`) rather than the bare `FirebaseMessaging.instance` static ADR-0015's own code sample showed. Verified in code review as genuinely necessary (not overengineering): `.instance` calls `Firebase.app()` internally and throws `[core/no-app]` without a live Firebase app, which would have broken every widget test mounting `ParentShellScaffold`. `FirebaseMessaging.onMessage` itself is left non-DI'd since it's a plain static broadcast `StreamController` with no `Firebase.app()` dependency — confirmed by tracing both code paths against the installed package source. Zero production behavior change.
- ADVISORY: this DI choice surfaced 8 pre-existing test failures in files unrelated to this story's own scope (`router_redirect_test.dart`, `root_redirect_test.dart`, `root_navigator_push_test.dart`, `parent_override_test.dart` ×4, `pending_list_approve_reject_test.dart` AC-6) — all constructing `ParentShellScaffold` via a real router without a `firebaseMessagingProvider` override. Fixed directly (same fake pattern added to each file) rather than deferred, since a story cannot ship leaving the existing suite red.
- ADVISORY: a second test file, `tests/integration/parent-dashboard-ui/parent_shell_banner_test.dart` (7 tests), was added during code review — both flame-specialist and qa-tester independently flagged that no widget-level test exercised `MaterialBanner` rendering, the tap-navigates/dismiss-never-navigates split, or the reminder→FCM replacement animation, despite the story's own QA Test Case 6 explicitly calling for exactly this. Not present in the original Test Evidence requirement (which only names the Logic-tier reducer test as BLOCKING) — added anyway since both reviewers converged on the same gap and it directly closes a self-declared requirement.
- ADVISORY (documented, not fixed — explicitly out of scope per the ADR's own Risks section): `bannerDisplayText`'s child-name/task-title lookup path (the `unseenCount == 1` case) has no direct unit test — only exercised indirectly via the new widget test's fallback-text path (no task/child seeded there). A lookup-miss only affects display text, never `unseenCount`/`displayKind` correctness.
**Test Evidence**: Logic (BLOCKING) — `tests/unit/parent-dashboard-ui/fcm_banner_state_machine_test.dart` (23/23 passing, mutation-tested). Widget-tier (ADVISORY, added in review) — `tests/integration/parent-dashboard-ui/parent_shell_banner_test.dart` (7/7 passing).
**Code Review**: Complete — flame-specialist + qa-tester in parallel, both verdict APPROVED WITH SUGGESTIONS. All findings applied and re-verified same session: the widget-level test gap (above), independently confirmed via mutation testing (qa-tester temporarily broke `displayKind`'s precedence order and the reminder-consumption scoping in `banner_providers.dart`, ran the suite, confirmed exactly the expected tests failed, then reverted cleanly). Full regression suite re-verified at 497/497 (1 pre-existing unrelated skip), `flutter analyze` clean.
**Epic status**: This was the last story in Parent Dashboard UI (#21) — closing this closes the epic at 4/4 stories complete.
