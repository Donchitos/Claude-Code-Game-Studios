// Run with:
//   cd src && flutter test ../tests/unit/time_decay/compute_energy_test.dart
//
// Pure Dart — computeEnergy imports nothing but dart:core, so this file
// needs no Firestore/Riverpod/Flame harness, just plain `test()`.

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/compute_energy.dart';

void main() {
  final t = DateTime(2026, 7, 16, 12);

  test('test_computeEnergy_8_hours_elapsed_from_full_energy', () {
    final result = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(hours: 8)),
    );

    expect(result, 76.0);
  });

  test('test_computeEnergy_24_hours_elapsed_from_full_energy', () {
    final result = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(hours: 24)),
    );

    expect(result, 28.0);
  });

  test('test_computeEnergy_48_hours_elapsed_floors_at_minEnergy', () {
    final result = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(hours: 48)),
    );

    expect(result, 10.0);
  });

  test(
      'test_computeEnergy_null_lastApprovedAt_uses_createdAt_baseline_and_initialEnergy_70',
      () {
    // storedEnergy is deliberately wrong (45) to prove it's ignored in
    // favor of initialEnergy=70 when lastApprovedAt is null.
    final result = computeEnergy(
      storedEnergy: 45,
      lastApprovedAt: null,
      createdAt: t,
      now: t.add(const Duration(hours: 8)),
    );

    expect(result, 70.0 - 8 * 3.0); // 46.0 — same as if storedEnergy were 70
  });

  test('test_computeEnergy_negative_elapsed_clamps_to_zero_no_free_energy',
      () {
    final result = computeEnergy(
      storedEnergy: 80,
      lastApprovedAt: t,
      createdAt: t,
      now: t.subtract(const Duration(hours: 5)), // clock set backward
    );

    expect(result, 80.0);
  });

  test(
      'test_computeEnergy_elapsed_beyond_maxHoursElapsed_floors_at_the_ceiling_value',
      () {
    final at168h = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(hours: 168)),
    );
    final at1000h = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(hours: 1000)),
    );

    expect(at168h, at1000h);
    expect(at168h, 10.0);
  });

  test('test_computeEnergy_sub_minute_elapsed_is_not_truncated_to_zero', () {
    // If inMinutes/60.0 were used instead of inMicroseconds/microsecondsPerHour,
    // 90 seconds (1.5 minutes) would truncate to 1 whole minute -> 1/60 hour,
    // still nonzero — use an even smaller duration to make the truncation bug
    // unambiguous: 30 seconds truncates to 0 minutes under inMinutes, but
    // is still a real nonzero elapsed duration under inMicroseconds.
    final result = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(seconds: 30)),
    );

    expect(result, lessThan(100.0));
  });

  test('test_computeEnergy_is_deterministic_across_repeated_calls', () async {
    final args = (
      storedEnergy: 55.0,
      lastApprovedAt: t,
      createdAt: t,
      now: t.add(const Duration(hours: 3)),
    );

    final first = computeEnergy(
      storedEnergy: args.storedEnergy,
      lastApprovedAt: args.lastApprovedAt,
      createdAt: args.createdAt,
      now: args.now,
    );
    // A real wall-clock delay between calls proves computeEnergy never
    // reads DateTime.now() internally — only the identical injected `now`
    // determines the result.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final second = computeEnergy(
      storedEnergy: args.storedEnergy,
      lastApprovedAt: args.lastApprovedAt,
      createdAt: args.createdAt,
      now: args.now,
    );

    expect(first, second);
  });

  test('test_computeEnergy_result_never_exceeds_maxEnergy', () {
    final result = computeEnergy(
      storedEnergy: 100,
      lastApprovedAt: t,
      createdAt: t,
      now: t, // zero elapsed
    );

    expect(result, 100.0);
    expect(result, lessThanOrEqualTo(100.0));
  });
}
