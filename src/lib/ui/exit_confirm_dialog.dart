import 'package:flutter/material.dart';

import 'app_colors.dart';

/// **P17** "Disruption-not-destruction confirm dialog"
/// (`design/ux/interaction-patterns.md`) — shown on Child Shell tab-root
/// back-press (main-navigation-shell Story 005, ADR-0014 Decision §6's first
/// code sample). Distinct from **P2** (Confirm-before-destructive dialog,
/// reserved elsewhere in this app for genuinely irreversible/economy-
/// affecting actions): exiting the app loses nothing, it's just disruptive if
/// triggered by a stray back-press — so the copy is short and friendly, never
/// framed as a warning ("cannot be undone" language is explicitly wrong for
/// this pattern per P17's own spec), and per the Art Bible no-red rule,
/// NEITHER button uses red or any alarming color — this isn't a warning, it's
/// a friendly check-in.
///
/// [Ở lại] (stay) is the prominent, first-listed action — P17's "[Cancel/stay]
/// always first or equally prominent" requirement — styled as a `FilledButton`
/// using the same Lavender Soft accent `ParentSwitchModeSheet`'s confirm
/// button already uses elsewhere in this app (see `app_colors.dart`), so
/// staying reads as the easy/default choice. [Thoát] (exit) is a plain
/// `TextButton` — present and fully readable, but deliberately less visually
/// loud, using `AppColors.secondaryText` rather than any red/alarming tone.
///
/// Returns `true` via `Navigator.pop(context, true)` if the child chose
/// [Thoát] (exit), `false` if [Ở lại] (stay) — the caller
/// (`ChildShellScaffold`'s `PopScope.onPopInvokedWithResult`) only calls
/// `SystemNavigator.pop()` on an explicit `true`; dismissing the dialog any
/// other way (scrim tap, system back while it's open) resolves the
/// `showDialog<bool>` future to `null`, which the caller's `?? false` also
/// treats as "stay" — no path accidentally exits the app.
class ExitConfirmDialog extends StatelessWidget {
  const ExitConfirmDialog({super.key});

  static const stayButtonKey = Key('exitConfirmDialogStayButton');
  static const exitButtonKey = Key('exitConfirmDialogExitButton');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Thoát PetQuest?',
        style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'Bé có muốn tiếp tục chơi cùng Mochi không?',
        style: TextStyle(color: AppColors.secondaryText),
      ),
      actions: [
        FilledButton(
          key: stayButtonKey,
          onPressed: () => Navigator.of(context).pop(false),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.lavenderSoft,
            foregroundColor: AppColors.primaryText,
          ),
          child: const Text('Ở lại'),
        ),
        TextButton(
          key: exitButtonKey,
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.secondaryText),
          child: const Text('Thoát'),
        ),
      ],
    );
  }
}
