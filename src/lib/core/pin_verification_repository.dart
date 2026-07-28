import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'child_profile_repository.dart';
import 'pin_crypto.dart';

/// Thrown when a child's `private/credentials` sub-document has never synced
/// to this device — a brand-new profile's first PIN entry on a device that
/// has never been online since the profile was created (ADR-0002 Risk:
/// offline-first bootstrap edge). Deliberately distinct from a wrong-PIN
/// result — a silent `false` here would be a false negative the parent can't
/// distinguish from "bé nhập sai" (Story 004 AC4).
class PinCredentialsUnavailable implements Exception {
  const PinCredentialsUnavailable();
}

/// Owns child PIN verification and the client-side fail-lockout for Auth &
/// Account Story 004. Two dependencies are injected for testability rather
/// than called inline:
/// - `now`: same rule ADR-0005 mandates for `computeEnergy` ("now MUST be
///   injected, never read from the wall clock inside it"), applied here so
///   lockout-expiry behavior is deterministically testable without real
///   sleeps (test-standards.md: no time-dependent assertions).
/// - `hashPinFn`: lets a test assert PBKDF2 was (or wasn't) actually invoked
///   — e.g. proving the lockout short-circuit skips it entirely — rather
///   than only inferring non-invocation from control flow (found in code
///   review — code-review 2026-07-15).
class PinVerificationRepository {
  PinVerificationRepository({
    required ChildProfileRepository childProfileRepository,
    required FlutterSecureStorage secureStorage,
    DateTime Function() now = DateTime.now,
    Future<String> Function(String rawPin, Uint8List salt) hashPinFn = hashPin,
  })  : _childProfileRepository = childProfileRepository,
        _secureStorage = secureStorage,
        _now = now,
        _hashPin = hashPinFn;

  final ChildProfileRepository _childProfileRepository;
  final FlutterSecureStorage _secureStorage;
  final DateTime Function() _now;
  final Future<String> Function(String rawPin, Uint8List salt) _hashPin;

  static const int maxFailCount = 3;
  static const Duration lockoutDuration = Duration(seconds: 60);

  String _failCountKey(String childId) => 'pin_fail_$childId';
  String _lockUntilKey(String childId) => 'pin_lock_$childId';

  // Per-childId serialization: without this, two near-simultaneous verify()
  // calls for the same child (a realistic double-tap from a young child
  // mashing the PIN pad) would both read the same failCount and race on the
  // write, silently losing an increment (found in code review — code-review
  // 2026-07-15). Chaining onto the previous call's future — swallowing its
  // outcome for chaining purposes only, the real result/error still flows to
  // that call's own caller — serializes verify() per childId without an
  // external locking package.
  final _childGates = <String, Future<void>>{};

  /// Verifies [rawPin] for [childId] under [parentId]'s family. Short-circuits
  /// to `false` while locked out, without fetching credentials or computing
  /// PBKDF2 (AC2 — the lockout is a cost/correctness requirement, not just a
  /// UX nicety). Throws [PinCredentialsUnavailable] if no credentials
  /// sub-document has ever synced — never treats that as a wrong PIN. Calls
  /// for the same [childId] are serialized (see `_childGates`); calls for
  /// different children proceed concurrently.
  Future<bool> verify({
    required String parentId,
    required String childId,
    required String rawPin,
  }) {
    final gate = _childGates[childId] ?? Future<void>.value();
    final result = gate.then((_) => _verifyLocked(
          parentId: parentId,
          childId: childId,
          rawPin: rawPin,
        ));
    _childGates[childId] = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _verifyLocked({
    required String parentId,
    required String childId,
    required String rawPin,
  }) async {
    if (await _isLockedOut(childId)) return false;

    final credentials =
        await _childProfileRepository.getChildCredentials(parentId, childId);
    if (credentials == null) {
      throw const PinCredentialsUnavailable();
    }

    final salt = decodePinSalt(credentials.pinSalt);
    final computedHash = await _hashPin(rawPin, salt);

    if (computedHash == credentials.pinHash) {
      await _clearLockout(childId);
      return true;
    }
    await _recordFailure(childId);
    return false;
  }

  /// Read-only lockout-expiry check for the PIN Entry Screen's countdown
  /// display (Story 012) — returns null if not locked out (never locked, or
  /// the lockout window has already passed). Does NOT clear an expired
  /// lockout as a side effect (that happens naturally on the next [verify]
  /// call) — this method exists purely so the UI can render a countdown
  /// without duplicating lockout logic or reading `flutter_secure_storage`
  /// directly (story flagged this as a needed addition rather than an
  /// existing seam — added here, not guessed at in the UI layer).
  Future<DateTime?> getLockUntil(String childId) async {
    final raw = await _secureStorage.read(key: _lockUntilKey(childId));
    if (raw == null) return null;
    final lockUntil = int.tryParse(raw);
    if (lockUntil == null) return null;
    if (_now().millisecondsSinceEpoch >= lockUntil) return null;
    return DateTime.fromMillisecondsSinceEpoch(lockUntil);
  }

  Future<bool> _isLockedOut(String childId) async {
    final raw = await _secureStorage.read(key: _lockUntilKey(childId));
    if (raw == null) return false;
    final lockUntil = int.tryParse(raw);
    if (lockUntil == null) return false;
    if (_now().millisecondsSinceEpoch >= lockUntil) {
      // Lockout window elapsed — clear it so the next failure starts a
      // fresh 3-strikes count, matching ADR-0002 §4's "3 CONSECUTIVE
      // failures" wording rather than accumulating indefinitely.
      await _clearLockout(childId);
      return false;
    }
    return true;
  }

  Future<void> _clearLockout(String childId) async {
    await _secureStorage.delete(key: _failCountKey(childId));
    await _secureStorage.delete(key: _lockUntilKey(childId));
  }

  Future<void> _recordFailure(String childId) async {
    final raw = await _secureStorage.read(key: _failCountKey(childId));
    final next = (int.tryParse(raw ?? '0') ?? 0) + 1;
    await _secureStorage.write(
      key: _failCountKey(childId),
      value: next.toString(),
    );
    if (next >= maxFailCount) {
      final lockUntil = _now().add(lockoutDuration).millisecondsSinceEpoch;
      await _secureStorage.write(
        key: _lockUntilKey(childId),
        value: lockUntil.toString(),
      );
    }
  }
}
