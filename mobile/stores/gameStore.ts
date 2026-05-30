import { create } from 'zustand';
import { GameEndPayload, GameMode, GameState, MatchFoundPayload } from '@brawlzone/shared';
import { socketService } from '@/services/socket';
import { supabase } from '@/services/supabase';

interface GameStore {
  // Auth
  userId: string | null;
  authToken: string | null;

  // Economy
  diamonds: number;
  hasNoAds: boolean;
  hasPlayPass: boolean;

  // Matchmaking
  isInQueue: boolean;
  queueMode: GameMode | null;
  queuePosition: number;

  // Active match
  currentMatch: MatchFoundPayload | null;
  gameState: GameState | null;
  matchResult: GameEndPayload | null;

  // Actions
  initialize: () => Promise<void>;
  setAuth: (userId: string, token: string) => void;
  joinQueue: (mode: GameMode, characterId: string) => void;
  leaveQueue: () => void;
  setGameState: (state: GameState) => void;
  setMatch: (match: MatchFoundPayload) => void;
  setMatchResult: (result: GameEndPayload) => void;
  clearMatch: () => void;
}

export const useGameStore = create<GameStore>((set, get) => ({
  userId: null,
  authToken: null,
  diamonds: 0,
  hasNoAds: false,
  hasPlayPass: false,
  isInQueue: false,
  queueMode: null,
  queuePosition: 0,
  currentMatch: null,
  gameState: null,
  matchResult: null,

  initialize: async () => {
    // Socket-Events einmalig verdrahten (ueberleben Reconnects dank Callback-Registry)
    socketService.onMatchFound((match) => {
      get().setMatch(match);
    });
    socketService.onGameState((state) => {
      get().setGameState(state);
    });
    socketService.onGameEnd((result) => {
      get().setMatchResult(result);
    });
    socketService.onQueueUpdate((position) => {
      set({ queuePosition: position });
    });

    const { data } = await supabase.auth.getSession();
    if (data.session) {
      get().setAuth(data.session.user.id, data.session.access_token);
    }

    supabase.auth.onAuthStateChange((_event, session) => {
      if (session) {
        get().setAuth(session.user.id, session.access_token);
      } else {
        set({ userId: null, authToken: null });
        socketService.disconnect();
      }
    });
  },

  setAuth: (userId, token) => {
    set({ userId, authToken: token });
    socketService.connect(token);
  },

  joinQueue: (mode, characterId) => {
    const { authToken } = get();
    if (!authToken) return;
    set({ isInQueue: true, queueMode: mode });
    socketService.joinQueue(mode, characterId, 1000);
  },

  leaveQueue: () => {
    const { queueMode } = get();
    if (queueMode) socketService.leaveQueue(queueMode);
    set({ isInQueue: false, queueMode: null, queuePosition: 0 });
  },

  setGameState: (gameState) => set({ gameState }),
  setMatch: (currentMatch) => set({ currentMatch, isInQueue: false, queueMode: null }),
  setMatchResult: (matchResult) => set({ matchResult }),
  clearMatch: () => set({ currentMatch: null, gameState: null, matchResult: null }),
}));
