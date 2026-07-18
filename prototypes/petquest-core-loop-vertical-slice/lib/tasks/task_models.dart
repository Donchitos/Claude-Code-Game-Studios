// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does the client-mirrored reward table (ADR-0009) stay
// in lockstep with the Security Rule's authoritative copy?
// Date: 2026-07-13

import 'package:cloud_firestore/cloud_firestore.dart';

/// Authoritative reward table (ADR-0009 "Required Patterns"). Must match
/// firestore.rules' rewardTable() exactly, or every task create is denied.
const Map<String, ({int xu, int energy})> rewardTable = {
  'study': (xu: 25, energy: 20),
  'arts': (xu: 25, energy: 20),
  'chores': (xu: 15, energy: 25),
  'sport': (xu: 15, energy: 25),
  'helping': (xu: 10, energy: 30),
  'custom': (xu: 15, energy: 25),
};

/// Slice scope: 3 pickable tasks, enough to demonstrate the loop without
/// building the full Task Library catalog UI.
const List<({String title, String categoryId})> sliceTaskCatalog = [
  (title: 'Học bài 30 phút', categoryId: 'study'),
  (title: 'Dọn phòng', categoryId: 'chores'),
  (title: 'Giúp mẹ nấu ăn', categoryId: 'helping'),
];

class Task {
  final String id;
  final String title;
  final String categoryId;
  final int xuReward;
  final int energyReward;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime? submittedAt;

  const Task({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.xuReward,
    required this.energyReward,
    required this.status,
    required this.submittedAt,
  });

  factory Task.fromFirestore(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Task(
      id: doc.id,
      title: data['title'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? 'custom',
      xuReward: (data['xuReward'] as num?)?.toInt() ?? 0,
      energyReward: (data['energyReward'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'pending',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }
}
