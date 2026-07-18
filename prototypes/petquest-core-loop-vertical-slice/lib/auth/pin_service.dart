// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: is PBKDF2 PIN verification (ADR-0002) fast enough and
// simple enough to not get in the way of the core loop's feel?
// Date: 2026-07-13

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:pointycastle/export.dart';

/// PBKDF2-HMAC-SHA256, 100k iterations, per-child 16-byte random salt.
/// Never bare SHA-256 (ADR-0002 "Required Patterns").
class PinService {
  static const int _iterations = 100000;
  static const int _keyLength = 32;

  static String generateSalt() {
    final rand = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return base64Encode(bytes);
  }

  /// Runs off the main isolate via `compute` (ADR-0002 "Required Patterns" -
  /// PBKDF2 computation MUST run off the main isolate).
  static Future<String> hashPin(String rawPin, String saltBase64) {
    return compute(_hashPinSync, _HashArgs(rawPin, saltBase64));
  }

  static String _hashPinSync(_HashArgs args) {
    final salt = base64Decode(args.saltBase64);
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    final key = derivator.process(Uint8List.fromList(utf8.encode(args.rawPin)));
    return base64Encode(key);
  }

  static Future<bool> verifyPin(
    String rawPin,
    String saltBase64,
    String expectedHashBase64,
  ) async {
    final computed = await hashPin(rawPin, saltBase64);
    return computed == expectedHashBase64;
  }
}

class _HashArgs {
  final String rawPin;
  final String saltBase64;
  const _HashArgs(this.rawPin, this.saltBase64);
}
