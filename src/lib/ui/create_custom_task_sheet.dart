import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/child_profile.dart';
import '../core/reward_table.dart';
import '../providers/auth_providers.dart';
import '../providers/banner_providers.dart';
import '../providers/task_providers.dart';
import 'app_colors.dart';

/// Opens the create-custom-task bottom sheet (Parent Dashboard UI Story 002,
/// TR-parentdash-003). Pattern **P3** (Inline bottom sheet, slide-up 250ms
/// ease-out / scrim dim 40%) — reused verbatim from Main Navigation Shell's
/// canonical motion spec per `design/ux/interaction-patterns.md`, not
/// redefined here, same as `showParentSwitchModeSheet`.
///
/// `isScrollControlled: true` so the sheet can grow to fit its content plus
/// the on-screen keyboard, matching `parent_switch_mode_sheet.dart`'s own
/// precedent. No `shape:` override — same precedent as `ParentSwitchModeSheet`
/// (no app-wide `BottomSheetThemeData` exists yet to standardize the 12-20dp
/// corner radius Art Bible §3 calls for; a pre-existing gap, not introduced
/// by this story).
///
/// **Parent Dashboard UI Story 004 (ADR-0015 Decision §3) addition**: wraps
/// the sheet with `bannerActionsProvider.modalOpened()`/`.modalClosed()` so
/// the shared Parent Shell FCM banner defers while this sheet is open
/// (GDD Edge Case 4). `modalClosed()` runs in a `finally` so a thrown error
/// during the sheet's own lifecycle still clears the defer state.
/// `ProviderScope.containerOf(context)` reaches the container from this
/// bare `BuildContext` without widening this function's own signature to
/// take a `WidgetRef`/`Ref` — this function has no other callers to update,
/// but keeping the signature stable avoids an unnecessary second edit
/// surface for a change this story doesn't otherwise need to make.
Future<void> showCreateCustomTaskSheet(BuildContext context) async {
  final bannerActions = ProviderScope.containerOf(context).read(bannerActionsProvider);
  bannerActions.modalOpened();
  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateCustomTaskSheet(),
    );
  } finally {
    bannerActions.modalClosed();
  }
}

/// The 5 real, selectable category IDs for the dropdown — sourced from
/// [knownCategoryIds] with Task Library's fallback-only `custom` tag
/// filtered out (Story Implementation Note 3: never hardcode a duplicate
/// list). `knownCategoryIds` is a `Set`, so its iteration order is an
/// implementation detail of `reward_table.dart`'s internal `Map` — sorted
/// here for a dropdown order that doesn't silently depend on that.
List<String> _selectableCategoryIds() =>
    knownCategoryIds.where((id) => id != 'custom').toList()..sort();

/// Parent-facing Vietnamese labels for the 5 selectable categories. No
/// existing CODE label table exists elsewhere to reuse — `flavorTextFor`
/// (`reward_table.dart`) returns Quest-framing copy ("Nạp trí tuệ cho
/// Mochi"), not a plain category name, and Task Management UI (#19)'s own
/// picker is still a placeholder with no label table of its own yet.
/// `'study'`/`'chores'` do have DESIGN precedent though (found in code
/// review): `design/ux/parent-dashboard-ui.md`'s wireframe already renders
/// `Học tập`/`Việc nhà` for those two on the pending-task card, and this
/// file's values match exactly — only `arts`/`sport`/`helping` are genuinely
/// novel here. Kept local to this file as presentation-only copy with no
/// reward implication — flag for localization-lead / `/ux-review` if this
/// should be promoted to a shared table later.
const Map<String, String> _categoryLabels = {
  'study': 'Học tập',
  'arts': 'Nghệ thuật',
  'chores': 'Việc nhà',
  'sport': 'Thể thao',
  'helping': 'Giúp đỡ',
};

/// The sheet's own content: title field, category dropdown, conditional
/// child selector (**P18**), Save button.
///
/// On confirmed Save: calls
/// `CustomTaskRepository.createCustomTaskTemplate` (already-built,
/// already-unit-tested — `tests/unit/task_library/custom_task_test.dart`)
/// via [customTaskRepositoryProvider], then pops itself and shows a
/// snackbar. On failure: shows an inline error, same shape as
/// `ParentSwitchModeSheet`'s `_ErrorMessage` — sheet stays open, Save
/// re-enables (**P1** single-flight guard, same pattern).
class CreateCustomTaskSheet extends ConsumerStatefulWidget {
  const CreateCustomTaskSheet({super.key});

  static const titleFieldKey = Key('createCustomTaskTitleField');
  static const categoryDropdownKey = Key('createCustomTaskCategoryDropdown');
  static const childDropdownKey = Key('createCustomTaskChildDropdown');
  static const saveButtonKey = Key('createCustomTaskSaveButton');

  @override
  ConsumerState<CreateCustomTaskSheet> createState() =>
      _CreateCustomTaskSheetState();
}

class _CreateCustomTaskSheetState extends ConsumerState<CreateCustomTaskSheet> {
  final _titleController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedChildId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Save's enabled state depends on title content (Edge Case 2) — rebuild
    // on every keystroke, same trigger shape as LoginScreen's own field
    // listeners.
    _titleController.addListener(_onTitleChanged);
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  /// Save is enabled only once title/category/child are all resolved to a
  /// valid value — mirrors AC-4's "title, category, child đã chọn hợp lệ"
  /// precondition. [children] is passed in rather than re-read from the
  /// provider so this stays a pure function of the same snapshot the caller
  /// is already rendering against.
  bool _canSave(List<ChildProfile> children) {
    if (_isSubmitting) return false;
    if (_titleController.text.trim().isEmpty) return false;
    if (_selectedCategoryId == null) return false;
    if (children.isEmpty) return false;
    // P18: selector only renders (and thus only needs an explicit pick)
    // when length > 1 — the length == 1 case auto-assigns at Save time.
    if (children.length > 1 && _selectedChildId == null) return false;
    return true;
  }

  Future<void> _save(List<ChildProfile> children) async {
    if (!_canSave(children)) return; // P1 single-flight guard, same as ParentSwitchModeSheet
    // P18: auto-assign the sole child's ID when the selector was never
    // rendered — this is the BLOCKING-tested path (AC-2 / AC "targetChildId
    // read-back").
    final childId =
        children.length == 1 ? children.single.childId : _selectedChildId!;
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      return; // defensive — this sheet is only reachable from an authed parent session
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(customTaskRepositoryProvider).createCustomTaskTemplate(
            parentId: user.uid,
            childId: childId,
            title: _titleController.text.trim(),
            categoryId: _selectedCategoryId!,
          );
      if (!mounted) return;
      // Capture before pop — the sheet's own context may not survive the
      // pop, same precedent as other post-write snackbar+pop sequences in
      // this codebase.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Đã thêm nhiệm vụ')));
    } catch (_) {
      // Catch-all: `createCustomTaskTemplate` can throw `ArgumentError` (the
      // repository's own pre-write validation — unreachable here given
      // `_canSave`'s guard, but defensive) or a Firestore write failure.
      // Either way the story's AC calls for the same inline error, sheet
      // stays open, Save re-enabled.
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Không thêm được nhiệm vụ — thử lại';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final childProfilesAsync = ref.watch(childProfilesProvider);

    return Padding(
      // Keeps the sheet's content above the on-screen keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: childProfilesAsync.when(
            data: _buildForm,
            loading: () => const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const _LoadErrorContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<ChildProfile> children) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Thêm nhiệm vụ mới',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          key: CreateCustomTaskSheet.titleFieldKey,
          controller: _titleController,
          enabled: !_isSubmitting,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Tên nhiệm vụ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: CreateCustomTaskSheet.categoryDropdownKey,
          initialValue: _selectedCategoryId,
          decoration: const InputDecoration(
            labelText: 'Loại nhiệm vụ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          items: [
            for (final id in _selectableCategoryIds())
              DropdownMenuItem(value: id, child: Text(_categoryLabels[id] ?? id)),
          ],
          onChanged: _isSubmitting
              ? null
              : (value) => setState(() => _selectedCategoryId = value),
        ),
        // P18 — Conditional selector: hidden entirely (not disabled, not
        // pre-filled) when the family has exactly 1 child; that child's ID
        // is auto-assigned in `_save`, not here.
        if (children.length > 1) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: CreateCustomTaskSheet.childDropdownKey,
            initialValue: _selectedChildId,
            decoration: const InputDecoration(
              labelText: 'Bé',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            items: [
              for (final child in children)
                DropdownMenuItem(value: child.childId, child: Text(child.name)),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _selectedChildId = value),
          ),
        ],
        if (children.isEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Cần có ít nhất 1 bé trong gia đình để tạo nhiệm vụ.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.secondaryText),
          ),
        ],
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
            key: CreateCustomTaskSheet.saveButtonKey,
            onPressed: _canSave(children) ? () => _save(children) : null,
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
                : const Text('Lưu'),
          ),
        ),
      ],
    );
  }
}

/// Shown if [childProfilesProvider] itself errors (e.g. a Firestore read
/// failure) — distinct from the empty-list case (`children.isEmpty` inside
/// `_buildForm`), which is a valid, non-error resolved state.
class _LoadErrorContent extends StatelessWidget {
  const _LoadErrorContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Không tải được danh sách bé — thử lại sau',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.primaryText),
        ),
      ),
    );
  }
}

/// P8: icon + color feedback, never color-alone — same shape as
/// `ParentSwitchModeSheet`'s own `_ErrorMessage`.
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
