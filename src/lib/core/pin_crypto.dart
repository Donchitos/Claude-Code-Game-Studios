import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pointycastle/export.dart';

/// Shared PBKDF2 crypto helpers for PIN hashing — used by Story 004 (PIN
/// verification) and Story 007 (PIN reset), which must not duplicate the
/// hashing logic (story-004's Out of Scope note).

const int pbkdf2Iterations = 100000;
const int pbkdf2KeyLength = 32;
const int pinSaltLength = 16;

/// Computes `PBKDF2-HMAC-SHA256(rawPin, salt, 100k iter, 32-byte key)`,
/// base64-encoded — the same encoding used for the stored `pinHash`/`pinSalt`
/// fields. Runs off the main isolate via `Isolate.run` (ADR-0002 Decision
/// §2 — MUST run off-isolate, never on the calling one, to avoid jank on
/// low-end Android).
///
/// Web exception: `Isolate.run` was found (browser-tested, both `flutter run
/// -d web-server` and a release `flutter build web` bundle) to hang forever
/// on this pinned engine version — the returned Future never completes, no
/// error surfaces on either side. A plain Web Worker roundtrip in the same
/// page works fine, so this is specific to Dart's own `Isolate.run`-on-web
/// plumbing, not a general Worker/CSP restriction. `package:flutter`'s own
/// `compute()` sidesteps the same gap by running synchronously on web rather
/// than spawning an isolate — mirrored here rather than off-isolate dispatch
/// ADR-0002 §2 only ever justified for Android jank, so running on the
/// calling isolate on web is in scope, not a deviation.
Future<String> hashPin(String rawPin, Uint8List salt) {
  if (kIsWeb) {
    return Future<String>.value(_hashPinSync(rawPin, salt));
  }
  return Isolate.run(() => _hashPinSync(rawPin, salt));
}

String _hashPinSync(String rawPin, Uint8List salt) {
  final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(salt, pbkdf2Iterations, pbkdf2KeyLength));
  final hash = derivator.process(Uint8List.fromList(utf8.encode(rawPin)));
  return base64Encode(hash);
}

/// A fresh cryptographically-random 16-byte salt (ADR-0002 Decision §3 —
/// per-child, never bare SHA-256).
Uint8List generatePinSalt() {
  final random = Random.secure();
  return Uint8List.fromList(
    List<int>.generate(pinSaltLength, (_) => random.nextInt(256)),
  );
}

/// Decodes a base64-encoded salt string (as stored in `pinSalt`) to bytes —
/// the encoding this module's own [generatePinSalt] + base64 storage
/// convention produces; not an ADR-mandated format, just this codebase's
/// chosen encoding, documented here so Story 007 stays consistent with it.
Uint8List decodePinSalt(String base64Salt) => base64Decode(base64Salt);

/// Encodes salt bytes for storage — the write-side counterpart of
/// [decodePinSalt].
String encodePinSalt(Uint8List salt) => base64Encode(salt);
