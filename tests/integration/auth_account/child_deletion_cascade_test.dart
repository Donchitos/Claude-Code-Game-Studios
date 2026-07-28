// Run with:
//   cd src && flutter test ../tests/integration/auth_account/child_deletion_cascade_test.dart
//
// Story 009 (Child Profile Deletion — Cloud Function cascade) has TWO parts:
//   1. Server-side: `onChildProfileDelete`, a Firestore-triggered Cloud
//      Function that recursively deletes a child's subcollections. This is
//      Node.js/TypeScript, not Dart — tested at
//      `functions/test/index.test.ts` (8 tests, `cd functions && npm test`).
//   2. Client-side: deleting the `children/{childId}` document itself (the
//      action that triggers #1). Per Story 009's own Out of Scope section,
//      this belongs to the not-yet-built Parent Dashboard epic (#21) — no
//      Dart production code exists for it yet.
//
// This file exists so that gap is discoverable from `tests/` itself, not
// only from the story document — a `skip:` reason, not a silently-missing
// file or a fabricated test asserting against stub behavior that doesn't
// exist in production (found in code review — code-review 2026-07-15).
// Replace this file's contents with real tests once Parent Dashboard epic
// #21 implements the client-side delete action.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'test_client_side_child_deletion_action_not_yet_implemented',
    () {},
    skip: 'Deferred to Parent Dashboard epic #21 — the client-side action '
        'that deletes children/{childId} (and thereby triggers Story 009\'s '
        'onChildProfileDelete Cloud Function) does not exist in this '
        'codebase yet. See story-009-child-deletion-cascade.md Out of Scope.',
  );
}
