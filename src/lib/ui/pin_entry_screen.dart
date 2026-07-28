import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/pin_verification_repository.dart';
import '../providers/auth_providers.dart';
import 'app_colors.dart';

const int _pinLength = 4;

/// PIN Entry Screen (Story 012), per `design/ux/pin-entry-screen.md`,
/// governed by pattern P10. No `TextField`/`EditableText` exists anywhere on
/// this screen by construction — digits are collected via numpad button taps
/// into a local buffer — so there is no text-input surface for a crash
/// reporter's default breadcrumb capture to hook into (satisfies AC7 without
/// a crash-reporting SDK to configure; none is integrated in this project yet).
///
/// No manual navigation on success — [PinVerificationActions.verifyChildPin]
/// sets `activeChildProvider` as a side effect, which `sessionStateProvider`
/// derives into `childSelected`; the app's real router redirect reacts to
/// that automatically (Story 003).
class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({
    super.key,
    required this.childId,
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  final String childId;

  /// Injected for the same testability reason as
  /// [PinVerificationRepository]'s `now` — the live countdown display must
  /// be deterministically testable without real sleeps.
  final DateTime Function() _now;

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

enum _PinEntryPhase { numpad, offlineSync, dataError }

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  final List<int> _digits = [];
  bool _verifying = false;
  bool _verified = false;
  bool _flash = false;
  DateTime? _lockUntil;
  int _secondsRemaining = 0;
  Timer? _countdownTimer;
  _PinEntryPhase _phase = _PinEntryPhase.numpad;

  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  bool get _isLockedOut => _lockUntil != null;

  @override
  void initState() {
    super.initState();
    // Bé may return to this screen already locked out (e.g. backgrounded
    // mid-lockout) — check eagerly rather than only after a failed attempt.
    _refreshLockoutState();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _refreshLockoutState() async {
    final lockUntil =
        await ref.read(pinVerificationActionsProvider).getLockUntil(widget.childId);
    if (!mounted) return;
    setState(() => _lockUntil = lockUntil);
    _syncCountdownTimer();
  }

  void _syncCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_lockUntil == null) return;
    _tickCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickCountdown());
  }

  void _tickCountdown() {
    if (!mounted) return;
    final lockUntil = _lockUntil;
    if (lockUntil == null) return;
    final remaining = lockUntil.difference(widget._now());
    if (remaining <= Duration.zero) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      setState(() {
        _lockUntil = null;
        _digits.clear();
      });
      return;
    }
    // Ceiling, not floor+1 — at exactly 60000ms remaining this shows "60s"
    // (not "61s"), and never shows "0s" while still genuinely locked out.
    setState(() => _secondsRemaining = (remaining.inMilliseconds / 1000).ceil());
  }

  Future<void> _onDigitTap(int digit) async {
    if (_verifying || _isLockedOut || _verified || _digits.length >= _pinLength) return;
    setState(() => _digits.add(digit));
    if (_digits.length == _pinLength) {
      await _verify();
    }
  }

  void _onDeleteTap() {
    if (_verifying || _isLockedOut || _verified || _digits.isEmpty) return;
    setState(() => _digits.removeLast());
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final rawPin = _digits.map((d) => d.toString()).join();
    try {
      final ok = await ref
          .read(pinVerificationActionsProvider)
          .verifyChildPin(childId: widget.childId, rawPin: rawPin);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _verifying = false;
          _verified = true;
        });
        return;
      }
      setState(() => _verifying = false);
      await _playWrongPinFeedback();
      if (!mounted) return;
      setState(() => _digits.clear());
      await _refreshLockoutState();
    } on PinCredentialsUnavailable {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _phase = _PinEntryPhase.offlineSync;
      });
    } on VerifiedChildProfileMissing {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _phase = _PinEntryPhase.dataError;
      });
    }
  }

  Future<void> _playWrongPinFeedback() async {
    if (MediaQuery.of(context).disableAnimations) {
      setState(() => _flash = true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _flash = false);
      return;
    }
    await _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamIvory,
      body: SafeArea(
        child: Column(
          children: [
            _Header(childId: widget.childId, onBack: () => context.pop()),
            const SizedBox(height: 24),
            _DotDisplay(
              filled: _digits.length,
              total: _pinLength,
              verified: _verified,
              dimmed: _isLockedOut,
              flash: _flash,
              shakeAnimation: _shakeController,
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildBody()),
            // Invisible test hook — a widget test driving the numpad can
            // poll for this key's presence/absence to know exactly when the
            // fire-and-forget verify() (real off-isolate PBKDF2 work) has
            // settled, instead of guessing with a fixed real-time delay
            // (found in code review — a blind sleep risked flaking on a
            // slower CI machine).
            if (_verifying) const SizedBox.shrink(key: Key('pin_verifying_marker')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _PinEntryPhase.offlineSync:
        return const _OfflineSyncMessage();
      case _PinEntryPhase.dataError:
        return _DataErrorMessage(onBack: () => context.pop());
      case _PinEntryPhase.numpad:
        if (_isLockedOut) {
          return _LockoutCountdown(secondsRemaining: _secondsRemaining);
        }
        return _Numpad(
          enabled: !_verifying && !_verified,
          onDigit: _onDigitTap,
          onDelete: _onDeleteTap,
        );
    }
  }
}

/// Header shows the selected child's name as a light "this is you"
/// confirmation — best-effort only, resolved from the already-loaded
/// [childProfilesProvider] cache. Shows just the back button if not yet
/// resolved or not found; this is display-only, NOT the
/// [VerifiedChildProfileMissing] data-integrity check, which only fires
/// after a *correct* PIN — those are deliberately separate concerns.
class _Header extends ConsumerWidget {
  const _Header({required this.childId, required this.onBack});

  final String childId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(childProfilesProvider).value ?? const [];
    String? name;
    for (final profile in profiles) {
      if (profile.childId == childId) {
        name = profile.name;
        break;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
            onPressed: onBack,
          ),
          const Spacer(),
          if (name != null) ...[
            const Icon(Icons.pets, size: 24, color: AppColors.lavenderSoft),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(color: AppColors.primaryText)),
          ],
        ],
      ),
    );
  }
}

class _DotDisplay extends AnimatedWidget {
  const _DotDisplay({
    required this.filled,
    required this.total,
    required this.verified,
    required this.dimmed,
    required this.flash,
    required Animation<double> shakeAnimation,
  }) : super(listenable: shakeAnimation);

  final int filled;
  final int total;
  final bool verified;
  final bool dimmed;
  final bool flash;

  Animation<double> get _shake => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    final dx = math.sin(_shake.value * math.pi * 4) * 8 * (1 - _shake.value);
    final dotColor = verified
        ? AppColors.mintBreeze
        : (flash ? AppColors.petalPink : AppColors.lavenderSoft);
    return Opacity(
      opacity: dimmed ? 0.4 : 1.0,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(total, (i) {
            final isFilled = i < filled;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? dotColor : Colors.transparent,
                  border: Border.all(color: AppColors.secondaryText, width: 2),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({required this.enabled, required this.onDigit, required this.onDelete});

  final bool enabled;
  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;

  static const List<int?> _layout = [
    1, 2, 3, //
    4, 5, 6, //
    7, 8, 9, //
    null, 0, -1, // -1 marks the delete key, null is a blank cell
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: _layout.map((value) {
          if (value == null) return const SizedBox.shrink();
          if (value == -1) {
            return _NumpadKey(
              enabled: enabled,
              onTap: onDelete,
              child: const Icon(Icons.backspace_outlined, color: AppColors.primaryText),
            );
          }
          return _NumpadKey(
            enabled: enabled,
            onTap: () => onDigit(value),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 24, color: AppColors.primaryText),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NumpadKey extends StatefulWidget {
  const _NumpadKey({required this.enabled, required this.onTap, required this.child});

  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_NumpadKey> createState() => _NumpadKeyState();
}

class _NumpadKeyState extends State<_NumpadKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final scale = _pressed && !reducedMotion ? 0.92 : 1.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 100),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: BoxDecoration(
              color: AppColors.cloudWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _LockoutCountdown extends StatelessWidget {
  const _LockoutCountdown({required this.secondsRemaining});

  final int secondsRemaining;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_clock, size: 40, color: AppColors.primaryText),
          const SizedBox(height: 12),
          Text(
            'Thử lại sau ${secondsRemaining}s',
            style: const TextStyle(fontSize: 20, color: AppColors.primaryText),
          ),
        ],
      ),
    );
  }
}

class _OfflineSyncMessage extends StatelessWidget {
  const _OfflineSyncMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 40, color: AppColors.primaryText),
            SizedBox(height: 16),
            Text(
              'Cần kết nối mạng để đồng bộ lần đầu — vui lòng thử lại khi có internet',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.primaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataErrorMessage extends StatelessWidget {
  const _DataErrorMessage({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.primaryText),
            const SizedBox(height: 16),
            const Text(
              'Có lỗi xảy ra, vui lòng thử lại',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.primaryText),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lavenderSoft,
                foregroundColor: AppColors.primaryText,
              ),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}
