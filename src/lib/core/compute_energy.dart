/// Pure, deterministic energy-decay calculation (ADR-0005 Decision §1–3).
/// No Firestore, no Flutter, no Flame — a total, side-effect-free function of
/// its inputs. `now` is a required parameter, never read from the wall clock
/// inside this function, so tests are fully deterministic (Story 002 is the
/// impure boundary that supplies the real clock and the real Firestore data).
///
/// Does NOT own the energy→mood lookup (Pet State Machine #6 owns that) or
/// the recovery formula (`+energyReward`, computed inside Parent Approval's
/// transaction) — this function computes only the decay half.
double computeEnergy({
  required double storedEnergy,
  required DateTime? lastApprovedAt,
  required DateTime createdAt,
  required DateTime now,
  double decayRate = 3.0,
  double minEnergy = 10,
  double maxEnergy = 100,
  double maxHoursElapsed = 168,
}) {
  // Null lastApprovedAt (new profile, no approved task yet): use createdAt as
  // the elapsed-time baseline AND treat storedEnergy as initialEnergy=70 —
  // both substitutions apply together, not just one (ADR-0005 Decision §3).
  final effectiveBaseline = lastApprovedAt ?? createdAt;
  final effectiveStoredEnergy = lastApprovedAt == null ? 70.0 : storedEnergy;

  // now.difference(...), NOT now - lastApprovedAt — DateTime has no
  // operator- (ADR-0005 Decision §2).
  final elapsed = now.difference(effectiveBaseline);

  // inMicroseconds / microsecondsPerHour, NOT inMinutes / 60.0 — the latter
  // truncates sub-minute elapsed to 0 (ADR-0005 Decision §2).
  final rawHoursElapsed = elapsed.inMicroseconds / Duration.microsecondsPerHour;

  // Clock-manipulation guard: clamp to [0, maxHoursElapsed] — negative
  // elapsed (clock set back) yields no free energy; elapsed beyond the
  // ceiling (clock set far forward, or a genuine long absence) floors at
  // minEnergy rather than growing ever-more-negative.
  final hoursElapsed = rawHoursElapsed.clamp(0.0, maxHoursElapsed).toDouble();

  final rawEnergy = effectiveStoredEnergy - hoursElapsed * decayRate;
  return rawEnergy.clamp(minEnergy, maxEnergy).toDouble();
}
