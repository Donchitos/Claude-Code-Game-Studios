import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Injectable seam for the PIN lockout store (Story 004/007) — same DI
/// rationale as `firebase_providers.dart`'s Firebase seams (coding-standards.md:
/// dependency injection over singletons).
final secureStorageProvider =
    Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());
