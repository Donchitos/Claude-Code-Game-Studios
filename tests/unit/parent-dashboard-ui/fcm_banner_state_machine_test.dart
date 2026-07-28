// Run with:
//   cd src && flutter test ../tests/unit/parent-dashboard-ui/fcm_banner_state_machine_test.dart
//
// Parent Dashboard UI Story 004 (TR-parentdash-002) — BLOCKING Logic-tier
// Test Evidence, per the story's own Test Evidence section and ADR-0015's
// Validation Criteria. BannerState/BannerActions
// (`src/lib/providers/banner_providers.dart`) is a pure reducer with no
// BuildContext, no Firestore, no async (ADR-0015 Decision §2) — every test
// here drives a real ProviderContainer's bannerStateProvider/
// bannerActionsProvider directly and asserts on the resulting
// BannerState/displayKind. No widget pumping, no fakes/mocks needed.
//
// Covers every QA Test Case in the story file: banner appears/live-updates/
// coalesces, defer during modal, the 3-message-during-modal permutation
// (Edge Case 5's own explicitly-resolved case), banner-slot conflict
// resolution (both directions — reminder->fcm AND the "reminder was NOT
// actually showing at arrival time" literal-wording case), reminder session
// scoping (including the cold-start-only reset), and tap/dismiss sharing
// the identical `bannerDismissedOrTapped()` transition.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/providers/banner_providers.dart';

/// A minimal, ADR-0010-shaped payload (`data.taskId`/`data.childId`,
/// strings) — the only fields [BannerActions.messageReceived] and this
/// story's `bannerDisplayText` (`parent_shell_scaffold.dart`) ever read.
RemoteMessage _message({String taskId = 'task-1', String childId = 'child-1'}) =>
    RemoteMessage(data: {'taskId': taskId, 'childId': childId});

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  BannerState state() => container.read(bannerStateProvider);
  BannerActions actions() => container.read(bannerActionsProvider);

  group('BannerState.displayKind (pure derivation, ADR-0015 Decision §2)', () {
    test('test_displayKind_defaultState_isNone', () {
      expect(const BannerState().displayKind, BannerKind.none);
    });

    test('test_displayKind_isModalOpen_alwaysWinsOverUnseenCountAndReminder', () {
      const modalOpenState = BannerState(
        isModalOpen: true,
        unseenCount: 5,
        permissionDeclined: true,
      );
      expect(modalOpenState.displayKind, BannerKind.none);
    });

    test('test_displayKind_unseenCountPositive_isFcm_evenWithPermissionDeclined', () {
      const fcmState = BannerState(unseenCount: 1, permissionDeclined: true);
      expect(fcmState.displayKind, BannerKind.fcm,
          reason: 'Core Rule 6 — FCM always wins over reminder');
    });

    test('test_displayKind_permissionDeclined_notConsumed_isReminder', () {
      const reminderState = BannerState(permissionDeclined: true);
      expect(reminderState.displayKind, BannerKind.reminder);
    });

    test('test_displayKind_permissionDeclined_butConsumed_isNone', () {
      const consumedState = BannerState(
        permissionDeclined: true,
        reminderConsumedThisSession: true,
      );
      expect(consumedState.displayKind, BannerKind.none);
    });
  });

  group('Banner appears / live-updates / coalesces (Core Rule 6, QA Test Case 1)', () {
    test(
        'test_messageReceived_1then2then3_staysFcmThroughout_unseenCount1to3_noIntermediateNone',
        () {
      actions().messageReceived(_message(taskId: 't1'));
      expect(state().displayKind, BannerKind.fcm);
      expect(state().unseenCount, 1);

      actions().messageReceived(_message(taskId: 't2'));
      expect(state().displayKind, BannerKind.fcm,
          reason: 'never drops back to none between messages');
      expect(state().unseenCount, 2);

      actions().messageReceived(_message(taskId: 't3'));
      expect(state().displayKind, BannerKind.fcm);
      expect(state().unseenCount, 3);
    });

    test('test_messageReceived_updatesLastMessage_toTheMostRecentOne', () {
      actions().messageReceived(_message(taskId: 't1'));
      actions().messageReceived(_message(taskId: 't2'));
      expect(state().lastMessage?.data['taskId'], 't2');
    });
  });

  group('Defer during modal (Edge Case 4, QA Test Case 2)', () {
    test('test_messageReceived_whileModalOpen_displayKindStaysNone_butUnseenCountStillIncrements',
        () {
      actions().modalOpened();
      actions().messageReceived(_message());

      expect(state().displayKind, BannerKind.none);
      expect(state().unseenCount, 1,
          reason: 'the message is still counted — only the RENDER is deferred');
    });

    test('test_modalClosed_afterDeferredMessage_displayKindReflectsPendingUnseenCountImmediately',
        () {
      actions().modalOpened();
      actions().messageReceived(_message());
      expect(state().displayKind, BannerKind.none);

      actions().modalClosed();

      expect(state().displayKind, BannerKind.fcm);
      expect(state().unseenCount, 1);
    });

    test('test_modalOpened_thenClosed_withNoMessage_staysNone', () {
      actions().modalOpened();
      actions().modalClosed();
      expect(state().displayKind, BannerKind.none);
    });
  });

  group(
      '3-message-during-modal permutation '
      '(Edge Case 5, GDD\'s own explicitly-resolved case — QA Test Case 3)', () {
    test(
        'test_2messagesDuringModal_thenModalCloses_showsCoalesced2_then3rdMessageArrives_'
        'liveUpdatesTo3_noSecondBanner_noDismissThenShow', () {
      // 2 messages arrive while a modal is open — deferred, unseenCount=2.
      actions().modalOpened();
      actions().messageReceived(_message(taskId: 't1'));
      actions().messageReceived(_message(taskId: 't2'));
      expect(state().displayKind, BannerKind.none, reason: 'deferred while modal is open');
      expect(state().unseenCount, 2);

      // Modal closes — banner shows "2 nhiệm vụ mới đang chờ".
      actions().modalClosed();
      expect(state().displayKind, BannerKind.fcm);
      expect(state().unseenCount, 2);

      // A 3rd message arrives BEFORE the parent taps/dismisses.
      actions().messageReceived(_message(taskId: 't3'));

      // "Không có banner thứ 2 nào được tạo, không có banner cũ biến mất
      // rồi banner mới xuất hiện" — at the pure-reducer layer this means:
      // displayKind stays `fcm` (never dips back to `none` and back), and
      // unseenCount is a single coherent value that just incremented, not
      // some second/parallel counter. There is no queue/list of banners
      // anywhere in BannerState for a "2nd banner" to even exist in.
      expect(
        state().displayKind,
        BannerKind.fcm,
        reason: 'still fcm throughout — no transition through none, '
            'i.e. no dismiss-then-show',
      );
      expect(state().unseenCount, 3);
    });
  });

  group('Banner-slot conflict resolution (reminder<->fcm, QA Test Case 4)', () {
    test('test_messageReceived_whileReminderActuallyShowing_replacesWithFcm_andConsumesReminder',
        () {
      actions().permissionStatusResolved(declined: true);
      expect(state().displayKind, BannerKind.reminder,
          reason: 'precondition — reminder must actually be the displayed banner');

      actions().messageReceived(_message());

      expect(state().displayKind, BannerKind.fcm);
      expect(state().reminderConsumedThisSession, isTrue,
          reason: 'GIVEN reminder đang hiện, WHEN FCM đến, reminder coi như đã được thấy');
    });

    test('test_reminderNeverReappears_evenAfterTheReplacingFcmBannerIsLaterDismissed', () {
      actions().permissionStatusResolved(declined: true);
      actions().messageReceived(_message()); // reminder -> fcm, consumes reminder
      expect(state().displayKind, BannerKind.fcm);

      actions().bannerDismissedOrTapped(); // dismiss the fcm banner

      expect(
        state().displayKind,
        BannerKind.none,
        reason: 'the reminder must NOT reappear just because unseenCount is back to 0 — '
            'it was already consumed by the earlier FCM arrival',
      );
      expect(state().unseenCount, 0);
      expect(state().permissionDeclined, isTrue, reason: 'permissionDeclined itself is untouched');
      expect(state().reminderConsumedThisSession, isTrue);
    });

    test(
        'test_messageReceived_whileReminderNotActuallyShowing_'
        '(deferredByModal)_doesNotConsumeReminder', () {
      // The reminder is ELIGIBLE (permissionDeclined=true, not yet
      // consumed) but NOT actually the displayed banner at message-arrival
      // time, because a modal is open (displayKind == none, not reminder).
      // Per the GDD's literal "GIVEN reminder đang hiện" wording (not a
      // blanket "any FCM this session permanently voids the reminder"
      // rule), this must NOT consume the reminder.
      actions().permissionStatusResolved(declined: true);
      actions().modalOpened();
      expect(state().displayKind, BannerKind.none, reason: 'modal open wins over reminder eligibility');

      actions().messageReceived(_message());
      actions().modalClosed();
      expect(state().displayKind, BannerKind.fcm, reason: 'fcm wins now that unseenCount > 0');
      expect(state().reminderConsumedThisSession, isFalse,
          reason: 'the reminder was never the ACTUALLY-DISPLAYED banner when the message arrived');

      // Dismissing the fcm banner reveals the still-eligible reminder.
      actions().bannerDismissedOrTapped();
      expect(
        state().displayKind,
        BannerKind.reminder,
        reason: 'reminder was never consumed, and permissionDeclined is still true',
      );
    });
  });

  group('Reminder session scoping (Core Rule 7, QA Test Case 5)', () {
    test('test_permissionDeclined_noPriorDismissOrConsumption_displayKindIsReminder', () {
      actions().permissionStatusResolved(declined: true);
      expect(state().displayKind, BannerKind.reminder);
    });

    test(
        'test_bannerDismissedOrTapped_onReminder_setsConsumed_'
        'neverReturnsToReminderForRestOfThisLineage', () {
      actions().permissionStatusResolved(declined: true);
      expect(state().displayKind, BannerKind.reminder);

      actions().bannerDismissedOrTapped();
      expect(state().displayKind, BannerKind.none);
      expect(state().reminderConsumedThisSession, isTrue);

      // A redundant re-resolution within the same session (e.g. a second
      // getNotificationSettings() call) must not resurrect it.
      actions().permissionStatusResolved(declined: true);
      expect(
        state().displayKind,
        BannerKind.none,
        reason: 'only a fresh BannerState() (cold start) resets reminder eligibility',
      );
    });

    test('test_freshBannerState_(coldStartEquivalent)_resetsReminderEligibility', () {
      actions().permissionStatusResolved(declined: true);
      actions().bannerDismissedOrTapped();
      expect(state().reminderConsumedThisSession, isTrue);

      // A brand-new container/provider simulates a real cold start — a new
      // process lifetime, not a continuation of the same in-memory session
      // (GDD Core Rule 7: "Session = process lifetime").
      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);

      expect(freshContainer.read(bannerStateProvider).displayKind, BannerKind.none);
      freshContainer.read(bannerActionsProvider).permissionStatusResolved(declined: true);
      expect(freshContainer.read(bannerStateProvider).displayKind, BannerKind.reminder);
    });
  });

  group('Tap vs. dismiss share identical state transitions (QA Test Case 6)', () {
    test('test_bannerDismissedOrTapped_onFcmBanner_resetsUnseenCountToZero_regardlessOfCause', () {
      actions().messageReceived(_message());
      actions().messageReceived(_message());
      expect(state().unseenCount, 2);

      // Both a tap handler and a dismiss handler call this exact same
      // method (see parent_shell_scaffold.dart's _handleBannerTap /
      // _handleBannerDismiss) — the ONLY difference between them lives in
      // the widget layer's navigation side effect, never in the state
      // transition itself. This reducer-level test proves the transition
      // both handlers share is deterministic and correct; it doesn't (and
      // shouldn't) need to duplicate itself per caller.
      actions().bannerDismissedOrTapped();

      expect(state().unseenCount, 0);
      expect(state().displayKind, BannerKind.none);
    });

    test('test_bannerDismissedOrTapped_onReminderBanner_setsReminderConsumed_leavesUnseenCountAlone',
        () {
      actions().permissionStatusResolved(declined: true);
      expect(state().displayKind, BannerKind.reminder);

      actions().bannerDismissedOrTapped();

      expect(state().reminderConsumedThisSession, isTrue);
      expect(state().unseenCount, 0, reason: 'reminder dismissal never touches unseenCount');
    });

    test('test_bannerDismissedOrTapped_whenNothingIsShowing_isANoOp', () {
      final before = state();
      actions().bannerDismissedOrTapped();
      final after = state();

      expect(after.unseenCount, before.unseenCount);
      expect(after.reminderConsumedThisSession, before.reminderConsumedThisSession);
      expect(after.displayKind, BannerKind.none);
    });
  });

  group('modalOpened / modalClosed basics', () {
    test('test_modalOpened_setsIsModalOpenTrue', () {
      actions().modalOpened();
      expect(state().isModalOpen, isTrue);
    });

    test('test_modalClosed_setsIsModalOpenFalse', () {
      actions().modalOpened();
      actions().modalClosed();
      expect(state().isModalOpen, isFalse);
    });
  });

  group('permissionStatusResolved basics', () {
    test('test_permissionStatusResolved_declinedFalse_leavesDisplayKindNone', () {
      actions().permissionStatusResolved(declined: false);
      expect(state().permissionDeclined, isFalse);
      expect(state().displayKind, BannerKind.none);
    });
  });
}
