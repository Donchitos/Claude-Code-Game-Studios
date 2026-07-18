import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth_repository.dart';
import '../providers/auth_providers.dart';
import '../providers/router_provider.dart';
import 'app_colors.dart';

/// Login Screen — the parent-authentication gate (Story 010), per
/// `design/ux/login-screen.md`. No navigation call on success: Story 003's
/// route guard reacts to `sessionStateProvider` becoming `parentAuthed`
/// automatically once `authStateProvider` emits a signed-in user.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

/// A loose, non-blocking format check for the Filling state's inline hint
/// (`design/ux/login-screen.md`'s States & Variants) — never prevents
/// submission; the real validation is Firebase Auth's own response.
final RegExp _looksLikeEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    super.dispose();
  }

  void _onEmailChanged() {
    final text = _emailController.text;
    final looksInvalid = text.isNotEmpty && !_looksLikeEmail.hasMatch(text);
    if (looksInvalid != _emailLooksInvalid || _errorMessage != null) {
      setState(() {
        _emailLooksInvalid = looksInvalid;
        _errorMessage = null; // clear error once the user starts retyping
      });
    }
  }

  void _onPasswordChanged() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return; // P1 single-flight guard
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // No navigation here — the route guard (Story 003) reacts to
      // sessionStateProvider automatically once authStateProvider emits.
    } on AuthNetworkFailure {
      // Password deliberately NOT cleared here — a network blip is
      // unrelated to whether the typed credentials are correct, so
      // discarding a correctly-typed password would force needless
      // re-entry (found in code review — code-review 2026-07-16).
      if (mounted) setState(() => _errorMessage = 'Không có kết nối mạng — thử lại');
    } on AuthSignInFailure catch (e) {
      if (mounted) {
        _passwordController.clear();
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      // Catch-all so an unexpected (non-FirebaseAuthException) error still
      // surfaces some feedback instead of silently resetting the button
      // with no explanation (found in code review — code-review 2026-07-16).
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
                Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.peachGlow.withValues(alpha: 0.4),
                  ),
                  child: Image.asset(
                    'assets/sprites/mochi_baby_happy_idle.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PetQuest',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Non-blocking hint only — never an `errorText` (which
                    // would use Material's default error color; Art Bible
                    // forbids pure red in primary UI).
                    helperText: _emailLooksInvalid ? 'Email chưa đúng định dạng' : null,
                    helperStyle: const TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  enabled: !_isSubmitting,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _onPasswordChanged(),
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    suffixIcon: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
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
                        : const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // "Quên mật khẩu" flow is out of scope for this story —
                    // design/ux/login-screen.md's Open Questions.
                  },
                  child: const Text(
                    'Quên mật khẩu?',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: const Text(
                    'Chưa có tài khoản? Đăng ký',
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

/// P8: icon + color feedback, never color-alone.
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
