import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/auth_repository.dart';
import '../providers/auth_providers.dart';
import 'app_colors.dart';

/// Opens the switch-to-parent-mode bottom sheet (Story 004, ADR-0014
/// Decision §5, Implementation Note 2 — pattern **P3**, inline bottom
/// sheet). [isSubScreen] must be computed by the caller BEFORE this is
/// invoked (e.g. [ParentOverrideTrigger] in `parent_override_trigger.dart`)
/// — `showModalBottomSheet`'s own `builder` callback receives a fresh
/// `BuildContext` scoped to the sheet's route, not the trigger's original
/// location, so the "am I on a sub-screen" check cannot be done from inside
/// the sheet itself.
///
/// Uses the default (nearest-ancestor) `Navigator` rather than
/// `useRootNavigator: true` — [ParentOverrideTrigger] lives directly inside
/// `ChildShellScaffold`'s own `build(context)`, which sits ABOVE
/// `StatefulShellRoute`'s per-branch nested Navigators (it renders
/// `navigationShell`, it isn't rendered BY one) — its nearest `Navigator`
/// ancestor is go_router's root `Navigator`, the same one that hosts
/// `childShellRoute`/`parentShellRoute` as sibling top-level pages (see
/// `parent_shell_test.dart`'s header comment). No special-casing needed.
Future<void> showParentSwitchModeSheet(
  BuildContext context, {
  required bool isSubScreen,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // switch_mode_confirm_timeout = 0 (GDD Tuning Knob) — no auto-dismiss;
    // enableDrag/isDismissible stay at their Material defaults (swipe-down
    // and scrim-tap still close it), which is a distinct concern from
    // "auto-dismiss on a timer" that knob guards against.
    builder: (_) => ParentSwitchModeSheet(isSubScreen: isSubScreen),
  );
}

/// The switch-mode sheet's own content: title, optional discard warning
/// (Edge Case — GDD), password field, inline error, confirm button.
///
/// On confirmed correct password: calls
/// `parentOverrideActionsProvider.attempt(password: ...)` (the already-built,
/// already-tested Auth & Account action —
/// `tests/integration/auth_account/parent_override_test.dart`) and pops
/// itself off. It never calls `context.go(...)` — Story 001's `ref.listen`
/// refresh bridge already re-runs the root redirect automatically once
/// `parentOverrideProvider` flips `true` inside `.attempt()` (Implementation
/// Note 3); duplicating that navigation here would race the redirect for no
/// benefit. On a wrong password, it catches
/// [AuthReauthenticationFailure] and shows the inline error text — the sheet
/// stays open, no provider write happens (`.attempt()` only flips the
/// provider AFTER `reauthenticate()` succeeds; see that method's own doc
/// comment), and no navigation occurs.
class ParentSwitchModeSheet extends ConsumerStatefulWidget {
  const ParentSwitchModeSheet({super.key, required this.isSubScreen});

  final bool isSubScreen;

  static const passwordFieldKey = Key('parentSwitchModePasswordField');
  static const confirmButtonKey = Key('parentSwitchModeConfirmButton');

  @override
  ConsumerState<ParentSwitchModeSheet> createState() => _ParentSwitchModeSheetState();
}

class _ParentSwitchModeSheetState extends ConsumerState<ParentSwitchModeSheet> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_isSubmitting) return; // P1 single-flight guard, same as LoginScreen
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(parentOverrideActionsProvider)
          .attempt(password: _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthReauthenticationFailure {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Mật khẩu không đúng';
      });
    } catch (_) {
      // Catch-all so an unexpected failure still surfaces feedback instead
      // of silently resetting the button with no explanation — same
      // precedent as LoginScreen._submit.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Có lỗi xảy ra, vui lòng thử lại';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keeps the sheet's content above the on-screen keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chuyển sang tài khoản bố/mẹ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              if (widget.isSubScreen) ...[
                const SizedBox(height: 12),
                const _DiscardWarning(),
              ],
              const SizedBox(height: 24),
              TextField(
                key: ParentSwitchModeSheet.passwordFieldKey,
                controller: _passwordController,
                enabled: !_isSubmitting,
                autofocus: true,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
                onSubmitted: (_) => _confirm(),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  suffixIcon: IconButton(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: ParentSwitchModeSheet.confirmButtonKey,
                  onPressed: _isSubmitting ? null : _confirm,
                  style: FilledButton.styleFrom(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edge Case (GDD): shown only when the trigger fired while on a sub-screen
/// (e.g. `/child/tasks/new`) — distinct copy from the sheet's normal title,
/// per the story's "Sub-screen discard warning" acceptance criterion.
class _DiscardWarning extends StatelessWidget {
  const _DiscardWarning();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber_rounded, color: AppColors.primaryText, size: 20),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'Dữ liệu chưa lưu sẽ bị mất',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.primaryText),
          ),
        ),
      ],
    );
  }
}

/// P8: icon + color feedback, never color-alone — same shape as
/// LoginScreen's own `_ErrorMessage`.
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
