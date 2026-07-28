// Run with:
//   cd src && flutter test ../tests/unit/pet_state_machine/pet_mood_provider_test.dart
//
// Pure Dart + Riverpod derivation — no Flame, no Firestore. energyProvider is
// a plain Provider<double> (Time & Decay), so it can be overridden directly
// via overrideWithValue for a fully synchronous, deterministic test.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_quest/core/pet_mood.dart';
import 'package:pet_quest/providers/pet_state_providers.dart';
import 'package:pet_quest/providers/time_decay_providers.dart';

void main() {
  test('test_moodForEnergy_exactly_10_returns_sleeping', () {
    expect(moodForEnergy(10), MoodState.sleeping);
  });

  test('test_moodForEnergy_sad_band_boundaries_11_and_19', () {
    expect(moodForEnergy(11), MoodState.sad);
    expect(moodForEnergy(19), MoodState.sad);
  });

  test('test_moodForEnergy_20_returns_tired_not_sad', () {
    expect(moodForEnergy(20), MoodState.tired);
  });

  test('test_moodForEnergy_49_returns_tired_not_content', () {
    expect(moodForEnergy(49), MoodState.tired);
  });

  test('test_moodForEnergy_50_returns_content_not_tired', () {
    expect(moodForEnergy(50), MoodState.content);
  });

  test('test_moodForEnergy_79_returns_content_not_happy', () {
    expect(moodForEnergy(79), MoodState.content);
  });

  test('test_moodForEnergy_80_returns_happy', () {
    expect(moodForEnergy(80), MoodState.happy);
  });

  test('test_moodForEnergy_100_returns_happy', () {
    expect(moodForEnergy(100), MoodState.happy);
  });

  test('test_petMoodProvider_derives_from_energyProvider_without_independent_state',
      () {
    final container = ProviderContainer(
      overrides: [energyProvider.overrideWithValue(85.0)],
    );
    addTearDown(container.dispose);

    expect(container.read(petMoodProvider), moodForEnergy(85.0));
    expect(container.read(petMoodProvider), MoodState.happy);
  });

  test(
      'test_petMoodProvider_value_is_stable_within_a_mood_band_precondition_for_story_002',
      () {
    // Story 002's "emit petMoodChanged only on band change" relies on
    // ref.listen(petMoodProvider, ...) simply not firing when the value is
    // unchanged — this test proves petMoodProvider's own output is stable
    // across a same-band energy change, the precondition that guarantee
    // depends on.
    final container = ProviderContainer(
      overrides: [energyProvider.overrideWithValue(85.0)],
    );
    addTearDown(container.dispose);

    final first = container.read(petMoodProvider);

    final container2 = ProviderContainer(
      overrides: [energyProvider.overrideWithValue(90.0)],
    );
    addTearDown(container2.dispose);
    final second = container2.read(petMoodProvider);

    expect(first, MoodState.happy);
    expect(second, MoodState.happy);
    expect(first, second);
  });

  test('test_petEnergyProvider_passes_through_energyProviders_raw_value', () {
    final container = ProviderContainer(
      overrides: [energyProvider.overrideWithValue(42.5)],
    );
    addTearDown(container.dispose);

    expect(container.read(petEnergyProvider), 42.5);
  });
}
