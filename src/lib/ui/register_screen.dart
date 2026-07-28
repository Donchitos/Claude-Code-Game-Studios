import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../providers/router_provider.dart';
import 'app_colors.dart';

/// Registration Screen — the parent account-creation entry point (Story 013,
/// GDD Core Rule 2a), mirroring [LoginScreen]'s structure exactly (single-flight
/// guard, error zone, color/spacing constants) per
/// `design/quick-specs/parent-account-registration-2026-07-16.md`'s own
/// scope decision to skip a full `/ux-design` pass for this Addition. No
/// navigation call on success: Story 003's route guard reacts to
/// `sessionStateProvider` becoming `parentAuthed` automatically once
/// `authStateProvider` emits, exactly as [LoginScreen] already relies on.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

/// A loose, non-blocking format check — same philosophy as [LoginScreen]'s
/// email hint, never prevents submission; the real validation is Firebase
/// Auth's own response.
final RegExp _looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _emailLooksInvalid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final text = _emailController.text;
    final looksInvalid = text.isNotEmpty && !_looksLikeEmail.hasMatch(text);
    if (looksInvalid != _emailLooksInvalid || _errorMessage != null) {
      setState(() {
        _emailLooksInvalid = looksInvalid;
        _errorMessage = null;
      });
    }
  }

  void _onPasswordFieldChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // P1 single-flight guard, same as LoginScreen

    // Client-side non-empty-email check — the password fields already had
    // this discipline; email did not (found in code review — qa-tester,
    // 2026-07-16). A non-empty check here is a UX nicety only, not a
    // security boundary — Firebase's own `invalid-email` handling is the
    // real backstop for anything that gets past it.
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email.');
      return;
    }
    // Client-side password-match check — blocks the repository call
    // entirely when it fails, per this story's own Acceptance Criteria.
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Mật khẩu xác nhận không khớp.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // No navigation here — the route guard (Story 003) reacts to
      // sessionStateProvider automatically once authStateProvider emits,
      // exactly as LoginScreen relies on.
    } on AuthNetworkFailure {
      if (mounted) setState(() => _errorMessage = 'Không có kết nối mạng — thử lại');
    } on AuthSignUpFailure catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Có lỗi xảy ra, vui lòng thử lại');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamIvory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pets, size: 48, color: AppColors.lavenderSoft),
                const SizedBox(height: 8),
                const Text(
                  'Tạo tài khoản PetQuest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    helperText: _emailLooksInvalid ? 'Email chưa đúng định dạng' : null,
                    helperStyle: const TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  enabled: !_isSubmitting,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _onPasswordFieldChanged(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  enabled: !_isSubmitting,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _onPasswordFieldChanged(),
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    border: OutlineInputBorder(),
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
                          padding: const EdgeInsets.only(top: 16),
                          child: _ErrorMessage(message: _errorMessage!),
                        ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
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
                        : const Text('Đăng ký'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => context.go(AppRoutes.login),
                  child: const Text(
                    'Đã có tài khoản? Đăng nhập',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// P8: icon + color feedback, never color-alone — duplicated from
/// [LoginScreen]'s private `_ErrorMessage` rather than shared, since that
/// widget is file-private (matches this codebase's established
/// each-screen-file-is-self-contained convention for small private widgets).
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
