// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: does GameWidget hosting a single persistent FlameGame,
// with an overlay HUD reading Riverpod providers, stay within the ADR-0001
// draw-call budget and feel responsive?
// Date: 2026-07-13

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_state.dart';
import '../economy/currency_provider.dart';
import '../economy/seed_buffer_provider.dart';
import '../pet/pet_mood_provider.dart';
import '../pet/petquest_game.dart';
import 'child_home_screen.dart';

class PetRoomScreen extends ConsumerStatefulWidget {
  const PetRoomScreen({super.key});

  @override
  ConsumerState<PetRoomScreen> createState() => _PetRoomScreenState();
}

class _PetRoomScreenState extends ConsumerState<PetRoomScreen> {
  PetQuestGame? _game;

  @override
  Widget build(BuildContext context) {
    // Never call FlameGame init/reset on tab return (ADR-0009's Pet Room
    // pattern) - construct the game instance exactly once.
    _game ??= PetQuestGame(initialMood: ref.read(petMoodProvider));

    final xu = ref.watch(xuBalanceProvider);
    final seedCount = ref.watch(seedCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game!)),
            Positioned(
              top: 12,
              left: 12,
              child: _Badge(label: '💰 $xu xu'),
            ),
            if (seedCount > 0)
              Positioned(
                top: 12,
                right: 12,
                child: _Badge(label: '🌱 $seedCount đang chờ'),
              ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(88, 48)),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChildHomeScreen()),
                    ),
                    child: const Text('Giao nhiệm vụ'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                    onPressed: () =>
                        ref.read(appModeProvider.notifier).state = AppMode.parentDashboard,
                    child: const Text('Chế độ phụ huynh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
