// EXAMPLE test — confirms the flutter_test framework runs and demonstrates the
// project's conventions (group/test naming, boundary testing, injected clock).
//
// It is intentionally SELF-CONTAINED (no import from the game package, which is
// not scaffolded yet) so it compiles and passes today. Replace it with real tests
// that `import 'package:pet_quest/...'` once `lib/` exists. The inline `_moodBand`
// below mirrors ADR-0007 §2 / ADR-0005 (energy→mood lookup) purely to show the
// boundary-testing pattern the real Pet State Machine test must use — do NOT treat
// this copy as the source of truth; the real function lives in the game package.

import 'package:flutter_test/flutter_test.dart';

/// Illustrative pure lookup (mirrors ADR-0007 §2). Replace with the real import.
String _moodBand(num energy) {
  if (energy <= 10) return 'SLEEPING';
  if (energy <= 19) return 'SAD';
  if (energy <= 49) return 'TIRED';
  if (energy <= 79) return 'CONTENT';
  return 'HAPPY';
}

void main() {
  group('ExampleFramework', () {
    test('flutter_test runs and expect works', () {
      expect(1 + 1, equals(2));
    });
  });

  // Demonstrates the boundary-testing pattern every Logic-tier test should follow.
  group('EnergyMoodLookup (example — real version imports from lib/)', () {
    test('energy at each band boundary maps to the correct mood', () {
      expect(_moodBand(10), 'SLEEPING'); // floor
      expect(_moodBand(19), 'SAD');
      expect(_moodBand(20), 'TIRED'); // band edge
      expect(_moodBand(49), 'TIRED');
      expect(_moodBand(50), 'CONTENT'); // band edge
      expect(_moodBand(79), 'CONTENT');
      expect(_moodBand(80), 'HAPPY'); // band edge
      expect(_moodBand(100), 'HAPPY'); // cap
    });
  });
}
