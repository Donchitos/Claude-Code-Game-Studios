export enum GameMode {
  DUEL = '1v1',
  SQUAD = '3v3',
  FFA = 'ffa',
}

export interface MatchConfig {
  mode: GameMode;
  maxDuration: number; // seconds
  maxPlayers: number;
}

export const MATCH_CONFIGS: Record<GameMode, MatchConfig> = {
  [GameMode.DUEL]:  { mode: GameMode.DUEL,  maxDuration: 600, maxPlayers: 2 },
  [GameMode.SQUAD]: { mode: GameMode.SQUAD, maxDuration: 600, maxPlayers: 6 },
  [GameMode.FFA]:   { mode: GameMode.FFA,   maxDuration: 600, maxPlayers: 8 },
};

export interface Player {
  id: string;       // socket.id
  userId: string;   // Supabase user id
  username: string;
  characterId: string;
  rating: number;
}

export interface GameState {
  roomId: string;
  mode: GameMode;
  players: Record<string, PlayerState>; // keyed by userId
  status: 'waiting' | 'countdown' | 'active' | 'finished';
  startedAt: number | null;
  endsAt: number | null;
  tick: number;
}

export interface PlayerState {
  id: string;       // userId
  x: number;
  y: number;
  health: number;
  maxHealth: number;
  score: number;
  alive: boolean;
  lastInput: PlayerInput | null;
}

export interface PlayerInput {
  dx: number;       // -1 to 1, horizontal
  dy: number;       // -1 to 1, vertical
  action: 'none' | 'attack' | 'skill' | 'dodge';
  timestamp: number;
}

export const SocketEvents = {
  // Client → Server
  JOIN_QUEUE:    'join_queue',
  LEAVE_QUEUE:   'leave_queue',
  PLAYER_INPUT:  'player_input',

  // Server → Client
  QUEUE_UPDATE:  'queue_update',
  MATCH_FOUND:   'match_found',
  GAME_START:    'game_start',
  GAME_STATE:    'game_state',
  GAME_END:      'game_end',
  ERROR:         'error',
} as const;

export type SocketEvent = typeof SocketEvents[keyof typeof SocketEvents];

export interface MatchFoundPayload {
  roomId: string;
  mode: GameMode;
  players: Player[];
  countdownMs: number;
}

export interface GameEndPayload {
  roomId: string;
  winner: string | null; // userId, or null on draw
  scores: Record<string, number>;
  rewardsDiamonds: number;
  xpGained: number;
}

// ── Characters ────────────────────────────────────────────────────────────────

export interface CharacterDef {
  id: string;
  name: string;
  emoji: string;          // Icon-Platzhalter bis echte Assets da sind
  color: string;          // Hauptfarbe fuer Arena-Kreis
  description: string;
  stats: {
    speed: number;        // 1-10
    health: number;       // Basis-HP (wird an Server uebergeben)
    attackPower: number;  // 1-10
    skillType: 'dash' | 'shield' | 'burst';
  };
}

export const CHARACTERS: CharacterDef[] = [
  {
    id: 'warrior',
    name: 'WARRIOR',
    emoji: '⚔️',
    color: '#ff4d00',
    description: 'Hohe HP, starke Nahkampf-Angriffe. Perfekt fuer direkte Konfrontation.',
    stats: { speed: 5, health: 120, attackPower: 8, skillType: 'dash' },
  },
  {
    id: 'rogue',
    name: 'ROGUE',
    emoji: '🗡️',
    color: '#00d4ff',
    description: 'Schnell und ausweichend. Niedriger HP aber hoher Burst-Schaden.',
    stats: { speed: 9, health: 80, attackPower: 7, skillType: 'dash' },
  },
  {
    id: 'guardian',
    name: 'GUARDIAN',
    emoji: '🛡️',
    color: '#00ff88',
    description: 'Hohe Defensive. Schild-Skill absorbiert eingehenden Schaden.',
    stats: { speed: 3, health: 160, attackPower: 5, skillType: 'shield' },
  },
];

export const CHARACTER_MAP: Record<string, CharacterDef> =
  Object.fromEntries(CHARACTERS.map(c => [c.id, c]));
