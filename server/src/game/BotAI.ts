import { PlayerInput, PlayerState } from '../shared';

const ATTACK_RANGE = 100; // Game-Units

/**
 * Einfache Bot-KI: bewegt sich auf den naechsten lebenden Gegner zu,
 * greift an sobald er nah genug ist. Leichtes Jitter damit es nicht
 * zu deterministisch wirkt.
 */
export function generateBotInput(
  bot: PlayerState,
  allPlayers: Record<string, PlayerState>,
): PlayerInput {
  const enemies = Object.values(allPlayers).filter(p => p.id !== bot.id && p.alive);

  if (!enemies.length) {
    return { dx: 0, dy: 0, action: 'none', timestamp: Date.now() };
  }

  // Naechsten lebenden Gegner finden
  const target = enemies.reduce((a, b) =>
    Math.hypot(a.x - bot.x, a.y - bot.y) <= Math.hypot(b.x - bot.x, b.y - bot.y) ? a : b,
  );

  const dx  = target.x - bot.x;
  const dy  = target.y - bot.y;
  const len = Math.hypot(dx, dy) || 1;

  const jitter = () => (Math.random() - 0.5) * 0.3;

  return {
    dx:     Math.max(-1, Math.min(1, dx / len + jitter())),
    dy:     Math.max(-1, Math.min(1, dy / len + jitter())),
    action: len < ATTACK_RANGE ? 'attack' : 'none',
    timestamp: Date.now(),
  };
}
