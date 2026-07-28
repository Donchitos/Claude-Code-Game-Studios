// PROTOTYPE - NOT FOR PRODUCTION
// Question: Flutter-Flame State Bridge — main entry point
// Date: 2026-06-26

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_event_bus.dart';
import 'mochi_game.dart';
import 'pet_state.dart';

void main() {
  runApp(const ProviderScope(child: SpikeApp()));
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter-Flame Bridge Spike',
      debugShowCheckedModeBanner: false,
      home: BridgeSpikeScreen(),
    );
  }
}

class BridgeSpikeScreen extends ConsumerStatefulWidget {
  const BridgeSpikeScreen({super.key});

  @override
  ConsumerState<BridgeSpikeScreen> createState() => _BridgeSpikeScreenState();
}

class _BridgeSpikeScreenState extends ConsumerState<BridgeSpikeScreen> {
  final MochiGame _game = MochiGame();

  @override
  Widget build(BuildContext context) {
    final mood = ref.watch(petMoodProvider);

    // THE BRIDGE: ref.listen watches Riverpod state and emits to GameEventBus.
    // MochiComponent subscribes to GameEventBus independently.
    // Neither the Notifier nor the Flame component knows about each other.
    ref.listen<PetMood>(petMoodProvider, (_, next) {
      GameEventBus().emit(GameEvent(GameEventType.petMoodChanged, next));
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF0),
      body: Column(
        children: [
          // Flame game canvas — top 60% of screen
          Expanded(
            flex: 6,
            child: GameWidget(game: _game),
          ),

          // Status label
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _moodLabel(mood),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4037),
              ),
            ),
          ),

          // Control buttons — bottom 30% of screen
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Approve — simulates parent tapping approve
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          ref.read(petMoodProvider.notifier).approve(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA8E6CF),
                        foregroundColor: const Color(0xFF2E7D52),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '✅ Bố mẹ Approve Task',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Skip — simulates 2 days without task
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          ref.read(petMoodProvider.notifier).skipTask(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5A3E0),
                        foregroundColor: const Color(0xFF4A235A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '😴 Bỏ qua task (Mochi buồn)',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  // Reset
                  TextButton(
                    onPressed: () =>
                        ref.read(petMoodProvider.notifier).reset(),
                    child: const Text(
                      'Reset về Neutral',
                      style: TextStyle(color: Color(0xFF9E9E9E)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _moodLabel(PetMood mood) {
    return switch (mood) {
      PetMood.happy => '😊 Mochi đang vui! (Riverpod → Flame ✓)',
      PetMood.sad => '😴 Mochi buồn... (Riverpod → Flame ✓)',
      PetMood.neutral => '😐 Mochi bình thường',
    };
  }

  @override
  void dispose() {
    GameEventBus().dispose();
    super.dispose();
  }
}
