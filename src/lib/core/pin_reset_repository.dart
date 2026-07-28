import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'child_profile_repository.dart';
import 'models/child_credentials.dart';
import 'pin_crypto.dart';

/// Thrown when `newPin` is not exactly 4 numeric digits — validated
/// client-side before any hashing or Firestore write (AC3: reject invalid
/// input before touching either).
class InvalidPinFormat implements Exception {
  const InvalidPinFormat(this.newPin);

  final String newPin;

  @override
  String toString() => 'InvalidPinFormat: PIN must be exactly 4 digits';
}

final RegExp _fourDigitPin = RegExp(r'^\d{4}$');

/// Owns `resetChildPin` for Auth & Account Story 007. Reuses Story 004's
/// `pin_crypto.dart` helpers (`generatePinSalt`/`hashPin`) rather than
/// reimplementing hashing — guarantees both verify and reset stay
/// parameter-identical (same iteration count, same key length, same salt
/// encoding).
class PinResetRepository {
  PinResetRepository({
    required ChildProfileRepository childProfileRepository,
    required FlutterSecureStorage secureStorage,
    Uint8List Function() generateSalt = generatePinSalt,
    Future<String> Function(String rawPin, Uint8List salt) hashPinFn = hashPin,
  })  : _childProfileRepository = childProfileRepository,
        _secureStorage = secureStorage,
        _generateSalt = generateSalt,
        _hashPin = hashPinFn;

  final ChildProfileRepository _childProfileRepository;
  final FlutterSecureStorage _secureStorage;
  final Uint8List Function() _generateSalt;
  final Future<String> Function(String rawPin, Uint8List salt) _hashPin;

  String _failCountKey(String childId) => 'pin_fail_$childId';
  String _lockUntilKey(String childId) => 'pin_lock_$childId';

  /// Validates [newPin], generates a fresh 16-byte salt (never reuses the
  /// old one), re-hashes with the same PBKDF2 parameters as verification,
  /// overwrites `pinHash`/`pinSalt`, and clears any lockout state — but does
  /// NOT touch `activeChildProvider` or any session state (deliberately —
  /// this function has zero effect on a currently-active child session by
  /// design; the new PIN only applies at the next PIN-entry).
  ///
  /// Deliberately NOT serialized per-childId the way `PinVerificationRepository
  /// .verify` is: `verify`'s race is a lost-increment on a read-modify-write
  /// counter, which corrupts state silently. A reset's Firestore write is a
  /// single complete `{pinHash, pinSalt}` pair generated from one `newPin` —
  /// two concurrent resets for the same child are a last-write-wins race
  /// (whichever completes last determines the active PIN), which is safe:
  /// the written pair is always internally consistent (hash and salt always
  /// come from the same call), and this UI path (Parent Dashboard) has no
  /// realistic double-submit trigger the way a child mashing a PIN pad does
  /// (found in code review — code-review 2026-07-15).
  Future<void> resetChildPin({
    required String parentId,
    required String childId,
    required String newPin,
  }) async {
    if (!_fourDigitPin.hasMatch(newPin)) {
      throw InvalidPinFormat(newPin);
    }

    final salt = _generateSalt();
    final hash = await _hashPin(newPin, salt);

    await _childProfileRepository.setChildCredentials(
      parentId,
      childId,
      ChildCredentials(pinHash: hash, pinSalt: encodePinSalt(salt)),
    );

    // Handles the case where the child was mid-lockout before the reset —
    // a fresh PIN should not inherit a stale lockout.
    await _secureStorage.delete(key: _failCountKey(childId));
    await _secureStorage.delete(key: _lockUntilKey(childId));
  }
}
