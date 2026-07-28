// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: is client-side PBKDF2 PIN verification (ADR-0002)
// fast enough to feel instant to a child tapping in?
// Date: 2026-07-13
//
// Scope cut: no lockout-after-3-fails UI (flutter_secure_storage lockout
// state from ADR-0002 is not wired in this slice - not needed to validate
// the core loop's fun, only its architecture risk points).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/pin_service.dart';
import '../auth/session_state.dart';
import '../data/repository_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _pinController = TextEditingController();
  String? _error;
  bool _checking = false;

  Future<void> _submit() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final repo = ref.read(persistenceRepositoryProvider);
    final creds = await repo.getCredentials(devParentId, devChildId);
    if (creds == null) {
      setState(() {
        _error = 'Chưa có hồ sơ bé (dev seed chưa chạy xong?)';
        _checking = false;
      });
      return;
    }
    final ok = await PinService.verifyPin(
      _pinController.text,
      creds['pinSalt'] as String,
      creds['pinHash'] as String,
    );
    if (!mounted) return;
    if (ok) {
      ref.read(activeChildIdProvider.notifier).state = devChildId;
    } else {
      setState(() {
        _error = 'Sai PIN, thử lại nhé';
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nhập PIN (dev default: 1234)', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checking ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(88, 48), // 48dp min tap target
                  backgroundColor: const Color(0xFFFFD060),
                ),
                child: _checking
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Vào'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
