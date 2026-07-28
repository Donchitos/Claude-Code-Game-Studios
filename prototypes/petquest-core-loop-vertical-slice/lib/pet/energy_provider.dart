// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the corrected ADR-0005 decay formula
// (.difference().inMicroseconds / Duration.microsecondsPerHour, not the
// invalid `now - lastApprovedAt` / truncating `.inMinutes / 60.0`) actually
// compile and run correctly?
// Date: 2026-07-13
//
// Slice note: a 3-5 minute playtest session will show ~0 decay (correctly -
// this formula is calibrated for real-world hours/days, not seconds). The
// visible feedback in this slice is the energy JUMP at approve time
// (persistence_repository.dart), not decay. This file exists to prove the
// formula itself is correct Dart and wired to a live provider, per ADR-0005.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository_providers.dart';

const double _decayRate = 2.0; // energy points per hour, illustrative
const double _minEnergy = 10.0;
const double _maxEnergy = 100.0;
const int _maxHoursElapsed = 168; // clock-manipulation guard (ADR-0005)

double computeEnergy({
  required double storedEnergy,
  required DateTime? lastApprovedAt,
  required DateTime now,
}) {
  if (lastApprovedAt == null) return _minEnergy + 60; // new-profile baseline
  final elapsed = now.difference(lastApprovedAt);
  var hoursElapsed = elapsed.inMicroseconds / Duration.microsecondsPerHour;
  hoursElapsed = hoursElapsed.clamp(0, _maxHoursElapsed.toDouble());
  final decayed = storedEnergy - hoursElapsed * _decayRate;
  return decayed.clamp(_minEnergy, _maxEnergy);
}

/// Recomputed on-foreground only, no background timer (ADR-0005). For this
/// slice, recomputed whenever the underlying child doc stream emits.
final currentEnergyProvider = Provider<double>((ref) {
  final childData = ref.watch(childDocStreamProvider).value;
  if (childData == null) return _minEnergy + 60;
  final stored = (childData['storedEnergy'] as num?)?.toDouble() ?? 70.0;
  final lastApprovedRaw = childData['lastApprovedAt'];
  final lastApprovedAt = lastApprovedRaw == null
      ? null
      : (lastApprovedRaw as dynamic).toDate() as DateTime;
  return computeEnergy(
    storedEnergy: stored,
    lastApprovedAt: lastApprovedAt,
    now: DateTime.now(),
  );
});

final childDocStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final repo = ref.watch(persistenceRepositoryProvider);
  return repo.watchChild(devParentId, devChildId);
});
