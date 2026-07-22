import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/models/child_profile.dart';
import '../providers/auth_providers.dart';
import '../providers/router_provider.dart';
import 'app_colors.dart';

/// Parent Shell's Family tab (Parent Dashboard UI Story 003, TR-parentdash-004)
/// — replaces the bare placeholder `Scaffold` left by Main Navigation Shell
/// Story 003 in place, same convention as `ParentDashboardTasksTab` (Story
/// 002) editing its own placeholder file rather than swapping the widget
/// name (see that file's own doc comment).
///
/// Renders the child-profile list (avatar + name + "Reset PIN" per row) and
/// a "Chọn bé" app bar action. Named `ParentDashboardFamilyTab` to match
/// ADR-0014 Decision §3's own code sample exactly, unchanged from the
/// placeholder.
class ParentDashboardFamilyTab extends ConsumerWidget {
  const ParentDashboardFamilyTab({super.key});

  /// "Chọn bé" app bar action — a minimal, LOCAL implementation, not a
  /// reuse of Story 001's (Implementation Note 5), because Story 001 (Tab
  /// Nhiệm vụ + its own "Chọn bé" action) is currently Blocked on an
  /// unrelated Task Library gap and has not built one yet. Provisional —
  /// same precedent as `ParentDashboardTasksTab`'s FAB and
  /// `ParentOverrideTrigger` (main-navigation-shell Story 004→006): meant to
  /// be absorbed/aligned by Story 001 when it unblocks, not left as a
  /// permanent second implementation.
  static const selectChildActionKey = Key('familyTabSelectChildAction');

  /// Per-row "Reset PIN" button key, keyed by `childId` so a test (or a
  /// future screen-reader audit) can address a SPECIFIC row unambiguously —
  /// this story's own AC-2 explicitly guards against a "tapped row X, wrong
  /// child acted on" bug class, so row identity must be inspectable per-id,
  /// not just per-index.
  static Key resetPinButtonKey(String childId) =>
      Key('familyTabResetPinButton_$childId');

  /// Per-row list-tile key, keyed by `childId` — exposed as a public helper
  /// (rather than left as a private literal `_ChildRow` reconstructs
  /// unilaterally) so callers/tests reference the same source of truth as
  /// [resetPinButtonKey], instead of hand-duplicating the key string format.
  static Key childRowKey(String childId) => Key('familyTabChildRow_$childId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childProfilesAsync = ref.watch(childProfilesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gia đình'),
        actions: [
          TextButton.icon(
            key: selectChildActionKey,
            onPressed: () => context.push(AppRoutes.selectChild),
            icon: const Icon(Icons.switch_account_outlined),
            label: const Text('Chọn bé'),
          ),
        ],
      ),
      body: childProfilesAsync.when(
        data: (children) => _ChildList(children: children),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _LoadErrorContent(),
      ),
    );
  }
}

/// AC "Child list rendering" / AC "Defensive empty state". A plain
/// `ListView`, not a grid — the "Reset PIN" trailing action needs a full-row
/// tap target per Material touch-target guidance, unlike the profile-select
/// screen's square cards.
class _ChildList extends StatelessWidget {
  const _ChildList({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có hồ sơ con nào',
          style: TextStyle(color: AppColors.primaryText),
        ),
      );
    }
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) => _ChildRow(child: children[index]),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ParentDashboardFamilyTab.childRowKey(child.childId),
      leading: const CircleAvatar(
        backgroundColor: AppColors.lavenderSoft,
        child: Icon(Icons.pets, color: AppColors.primaryText),
      ),
      title: Text(child.name, style: const TextStyle(color: AppColors.primaryText)),
      trailing: TextButton(
        key: ParentDashboardFamilyTab.resetPinButtonKey(child.childId),
        onPressed: () => showResetPinDialog(context, child: child),
        child: const Text('Reset PIN'),
      ),
    );
  }
}

/// Shown if [childProfilesProvider] itself errors — distinct from the
/// empty-list case above, which is a valid, non-error resolved state. Same
/// shape as `CreateCustomTaskSheet`'s own `_LoadErrorContent` (private
/// classes can't be shared across files — duplicated by necessity, same
/// precedent as that file's own `_ErrorMessage`).
class _LoadErrorContent extends StatelessWidget {
  const _LoadErrorContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Không tải được danh sách bé — thử lại sau',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.primaryText),
      ),
    );
  }
}

/// Opens the Reset PIN confirm dialog (**P2** — confirm-before-destructive)
/// for a SPECIFIC child, captured at call time from the row that opened it —
/// never read from any ambient/global state, per Implementation Note 4 /
/// AC "Correct childId/newPin passed".
Future<void> showResetPinDialog(BuildContext context, {required ChildProfile child}) {
  return showDialog<void>(
    context: context,
    // Not dismissible via scrim tap or system back while a write is in
    // flight — see `_ResetPinDialogState.build()`'s `PopScope` for the
    // matching guard. Without both, a parent could dismiss mid-submit and
    // the dialog would close while the PIN silently changes underneath
    // them, contradicting the Cancel button's own "can't be dismissed out
    // from under an in-progress write" guarantee (found in code review).
    barrierDismissible: false,
    builder: (_) => ResetPinDialog(child: child),
  );
}

/// Reset PIN confirm dialog. Standard Material 3 `AlertDialog`
/// (Implementation Note 3 — no custom art).
///
/// **PIN-entry widget design choice**: this dialog does NOT reconstruct
/// P10's dot-display + numpad — it uses a plain `TextField`
/// (`obscureText: true`, `keyboardType: TextInputType.number`, `maxLength: 4`,
/// digit-only `inputFormatters`). Rationale: P10's dot-display/numpad
/// machinery (`pin_entry_screen.dart`'s private `_DotDisplay`/`_Numpad`/
/// `_NumpadKey`) exists specifically to serve a CHILD typing their own PIN on
/// a touch numpad with lockout feedback — none of that applies here. This is
/// an admin-side (parent) dialog entering a brand-new PIN with no lockout
/// concept at all (Implementation Note 3 says so explicitly), and a standard
/// `TextField` is: (a) natively accessible to TalkBack/VoiceOver without
/// extra `Semantics` wiring a custom numpad would need, (b) far less code to
/// maintain correctly for a low-frequency admin action, and (c) still
/// visually reads as "PIN entry" via `obscureText` + `counterText: ''` +
/// centered digits. The look is intentionally simple per Implementation Note
/// 3 ("no custom art") rather than a copy of the child-facing numpad.
class ResetPinDialog extends ConsumerStatefulWidget {
  const ResetPinDialog({super.key, required this.child});

  final ChildProfile child;

  static const pinFieldKey = Key('resetPinDialogPinField');
  static const confirmButtonKey = Key('resetPinDialogConfirmButton');
  static const cancelButtonKey = Key('resetPinDialogCancelButton');

  /// Invisible test hook — present only while `_isSubmitting` is true.
  /// `resetChildPin` performs real off-isolate PBKDF2 hashing
  /// (`pin_crypto.dart`'s `hashPin`, via `Isolate.run`), the same
  /// cross-isolate round-trip `PinEntryScreen`'s own `pin_verifying_marker`
  /// exists to make awaitable in a widget test — neither a bare
  /// `pumpAndSettle()` nor a fixed frame-count pump reliably observes its
  /// completion (see that screen's test file for the full rationale). A
  /// widget test polls for this key's absence instead of guessing with a
  /// fixed delay.
  static const submittingMarkerKey = Key('resetPinDialogSubmittingMarker');

  @override
  ConsumerState<ResetPinDialog> createState() => _ResetPinDialogState();
}

class _ResetPinDialogState extends ConsumerState<ResetPinDialog> {
  final _pinController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinController.addListener(_onPinChanged);
  }

  void _onPinChanged() => setState(() {});

  @override
  void dispose() {
    _pinController.removeListener(_onPinChanged);
    _pinController.dispose();
    super.dispose();
  }

  bool get _canConfirm => !_isSubmitting && _pinController.text.length == 4;

  /// **P1** single-flight guard, same convention as
  /// `CreateCustomTaskSheet._save` / Approve/Reject. `childId` is read from
  /// `widget.child` — the specific row's profile this dialog was constructed
  /// with — never from any ambient/global provider (AC "Correct childId/
  /// newPin passed").
  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(pinResetActionsProvider).resetChildPin(
            childId: widget.child.childId,
            newPin: _pinController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      // Catch-all: `resetChildPin` can throw `InvalidPinFormat` (unreachable
      // here given `_canConfirm`'s 4-digit gate, but defensive), `StateError`
      // (no parent signed in — also unreachable from this authed-only
      // screen), or a Firestore write failure. Either way the story's AC
      // calls for the same inline error, dialog stays open, Xác nhận
      // re-enabled.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Đặt lại PIN thất bại — thử lại';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Blocks the system back gesture/button while submitting — pairs with
      // `showResetPinDialog`'s `barrierDismissible: false` to close both
      // dismiss paths (scrim tap and back) during an in-flight write.
      canPop: !_isSubmitting,
      child: AlertDialog(
        title: Text('Đặt lại PIN cho ${widget.child.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: ResetPinDialog.pinFieldKey,
              controller: _pinController,
              enabled: !_isSubmitting,
              autofocus: true,
              obscureText: true,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                labelText: 'PIN mới (4 số)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              child: _errorMessage == null
                  ? const SizedBox.shrink(key: ValueKey('no-error'))
                  : Padding(
                      key: const ValueKey('error'),
                      padding: const EdgeInsets.only(top: 12),
                      child: _ErrorMessage(message: _errorMessage!),
                    ),
            ),
            if (_isSubmitting) const SizedBox.shrink(key: ResetPinDialog.submittingMarkerKey),
          ],
        ),
        actions: [
          TextButton(
            key: ResetPinDialog.cancelButtonKey,
            // Cancel/Hủy: no side effect, `resetChildPin()` never called — AC
            // "Cancel — no side effect". Disabled only while a confirm write
            // is genuinely in flight, so the dialog can't be dismissed out
            // from under an in-progress write.
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            key: ResetPinDialog.confirmButtonKey,
            onPressed: _canConfirm ? _confirm : null,
            style: FilledButton.styleFrom(
              // Control Manifest (this story): Lavender Soft, never red/black,
              // despite this being a "sensitive" action.
              backgroundColor: AppColors.lavenderSoft,
              foregroundColor: AppColors.primaryText,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryText,
                    ),
                  )
                : const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

/// **P8**: icon + color feedback, never color-alone — same shape as
/// `CreateCustomTaskSheet`'s own private `_ErrorMessage` (duplicated by
/// necessity; that class is library-private).
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppColors.primaryText, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(message, style: const TextStyle(color: AppColors.primaryText)),
        ),
      ],
    );
  }
}
