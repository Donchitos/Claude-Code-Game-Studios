// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does a realtime xuBalanceProvider (ADR-0008) reflect
// an approve-transaction's FieldValue.increment() promptly?
// Date: 2026-07-13

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pet/energy_provider.dart';

/// Realtime, scoped to active child (ADR-0008 "Required Patterns").
final xuBalanceProvider = Provider<int>((ref) {
  final childData = ref.watch(childDocStreamProvider).value;
  return (childData?['xuBalance'] as num?)?.toInt() ?? 0;
});
