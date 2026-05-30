import React, { useEffect, useRef, useState } from 'react';
import {
  View, Text, Pressable, StyleSheet,
  PanResponder, useWindowDimensions, BackHandler,
} from 'react-native';
import { router } from 'expo-router';
import { useGameStore } from '@/stores/gameStore';
import { socketService } from '@/services/socket';

const ARENA_SIZE   = 1000;
const PLAYER_R     = 22;
const JOYSTICK_R   = 50;
const CONTROLS_H   = 200;
const HUD_H        = 60;

const PLAYER_COLORS = [
  '#ff4d00', '#00d4ff', '#00ff88',
  '#ff00aa', '#ffaa00', '#aa00ff',
];

export default function MatchScreen() {
  const { width, height } = useWindowDimensions();
  const { currentMatch, gameState, matchResult, userId, clearMatch } = useGameStore();

  const [countdown, setCountdown] = useState<number | null>(null);
  const [timeLeft, setTimeLeft]   = useState('--:--');
  const [thumbPos, setThumbPos]   = useState({ x: 0, y: 0 });

  const joystickRef = useRef({ dx: 0, dy: 0 });
  const actionRef   = useRef<'none' | 'attack' | 'skill' | 'dodge'>('none');

  // Kein Match -> zurueck
  useEffect(() => {
    if (!currentMatch) router.replace('/(tabs)');
  }, [currentMatch]);

  // Android Back waehrend Match blockieren
  useEffect(() => {
    const sub = BackHandler.addEventListener('hardwareBackPress', () => true);
    return () => sub.remove();
  }, []);

  // Countdown vor Match-Start
  useEffect(() => {
    if (!currentMatch) return;
    const endsAt = Date.now() + currentMatch.countdownMs;
    const tick = setInterval(() => {
      const rem = Math.ceil((endsAt - Date.now()) / 1000);
      if (rem <= 0) { setCountdown(null); clearInterval(tick); }
      else          { setCountdown(rem); }
    }, 100);
    return () => clearInterval(tick);
  }, [currentMatch?.roomId]);

  // Match-Timer (aktualisiert nur wenn endsAt sich aendert = einmalig bei Match-Start)
  const endsAt = gameState?.endsAt ?? null;
  useEffect(() => {
    if (!endsAt) return;
    const tick = setInterval(() => {
      const rem = Math.max(0, endsAt - Date.now());
      const m = Math.floor(rem / 60000);
      const s = Math.floor((rem % 60000) / 1000);
      setTimeLeft(`${m}:${String(s).padStart(2, '0')}`);
      if (rem === 0) clearInterval(tick);
    }, 500);
    return () => clearInterval(tick);
  }, [endsAt]);

  // Input-Sender 20 Hz
  useEffect(() => {
    if (gameState?.status !== 'active') return;
    const tick = setInterval(() => {
      socketService.sendInput({
        dx: joystickRef.current.dx,
        dy: joystickRef.current.dy,
        action: actionRef.current,
        timestamp: Date.now(),
      });
      actionRef.current = 'none';
    }, 50);
    return () => clearInterval(tick);
  }, [gameState?.status]);

  // Joystick PanResponder
  const pan = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder:  () => true,
      onMoveShouldSetPanResponder:   () => true,
      onPanResponderMove: (_, g) => {
        const len = Math.sqrt(g.dx * g.dx + g.dy * g.dy);
        const scale = len > JOYSTICK_R ? JOYSTICK_R / len : 1;
        const cx = g.dx * scale;
        const cy = g.dy * scale;
        joystickRef.current = { dx: cx / JOYSTICK_R, dy: cy / JOYSTICK_R };
        setThumbPos({ x: cx, y: cy });
      },
      onPanResponderRelease:   () => { joystickRef.current = { dx: 0, dy: 0 }; setThumbPos({ x: 0, y: 0 }); },
      onPanResponderTerminate: () => { joystickRef.current = { dx: 0, dy: 0 }; setThumbPos({ x: 0, y: 0 }); },
    }),
  ).current;

  // Arena-Ausmasse: Breite = voll, Hoehe = Rest nach HUD + Controls
  const arenaW  = width;
  const arenaH  = height - HUD_H - CONTROLS_H;
  const scale   = arenaW / ARENA_SIZE;   // x-Achse fuellt Breite, y skaliert proportional

  const players = gameState ? Object.values(gameState.players) : [];
  const myScore = (userId && gameState?.players[userId]?.score) ?? 0;

  // ---- Results ----
  if (matchResult) {
    const won = matchResult.winner === userId;
    const myResultScore = matchResult.scores[userId ?? ''] ?? 0;
    return (
      <View style={s.results}>
        <Text style={[s.resultTitle, { color: won ? '#00ff88' : '#ff4d00' }]}>
          {won ? 'SIEG!' : matchResult.winner ? 'NIEDERLAGE' : 'UNENTSCHIEDEN'}
        </Text>
        <View style={s.resultCard}>
          <Row label="Score"    value={String(myResultScore)} />
          <Row label="XP"       value={`+${matchResult.xpGained}`} />
          <Row label="Diamonds" value={`+${matchResult.rewardsDiamonds}`} gold />
        </View>
        <Pressable style={s.btnHome} onPress={() => { clearMatch(); router.replace('/(tabs)'); }}>
          <Text style={s.btnHomeLabel}>Zurueck zur Lobby</Text>
        </Pressable>
      </View>
    );
  }

  // ---- Match ----
  return (
    <View style={s.root}>

      {/* HUD */}
      <View style={s.hud}>
        <Text style={s.hudMode}>{currentMatch?.mode.toUpperCase() ?? ''}</Text>
        <Text style={s.hudTimer}>
          {gameState?.status === 'active' ? timeLeft : (gameState?.status ?? 'LADEN...').toUpperCase()}
        </Text>
        <Text style={s.hudScore}>{myScore} pts</Text>
      </View>

      {/* Arena */}
      <View style={[s.arena, { width: arenaW, height: arenaH }]}>
        {[0.25, 0.5, 0.75].map(f => (
          <React.Fragment key={f}>
            <View style={[s.grid, s.gridH, { top: f * arenaH }]} />
            <View style={[s.grid, s.gridV, { left: f * arenaW }]} />
          </React.Fragment>
        ))}

        {players.map((ps, idx) => {
          const color = PLAYER_COLORS[idx % PLAYER_COLORS.length];
          const isMe  = ps.id === userId;
          const sx    = ps.x * scale;
          const sy    = ps.y * scale;
          const hpPct = ps.health / ps.maxHealth;
          return (
            <View key={ps.id} style={[s.playerWrap, { left: sx - PLAYER_R, top: sy - PLAYER_R, opacity: ps.alive ? 1 : 0.25 }]}>
              <View style={s.hpBarBg}>
                <View style={[s.hpBarFill, {
                  width: `${hpPct * 100}%` as `${number}%`,
                  backgroundColor: hpPct > 0.4 ? '#00ff88' : '#ff4d00',
                }]} />
              </View>
              <View style={[
                s.playerCircle,
                { backgroundColor: color, width: PLAYER_R * 2, height: PLAYER_R * 2, borderRadius: PLAYER_R },
                isMe && s.playerMe,
              ]} />
              {isMe && <View style={[s.meIndicator, { borderColor: color }]} />}
            </View>
          );
        })}

        {/* Placeholder wenn noch kein gameState */}
        {!gameState && (
          <View style={s.waitOverlay}>
            <Text style={s.waitText}>Verbinde...</Text>
          </View>
        )}
      </View>

      {/* Controls */}
      <View style={[s.controls, { height: CONTROLS_H }]}>
        {/* Joystick */}
        <View style={s.joystickArea} {...pan.panHandlers}>
          <View style={s.joystickBase}>
            <View style={[s.joystickThumb, { transform: [{ translateX: thumbPos.x }, { translateY: thumbPos.y }] }]} />
          </View>
        </View>

        {/* Aktions-Buttons */}
        <View style={s.actionCol}>
          <View style={s.actionRow}>
            <ActionBtn label="ATT"   color="#4d1a00" onPress={() => { actionRef.current = 'attack'; }} />
            <ActionBtn label="SKILL" color="#1a1a6e" onPress={() => { actionRef.current = 'skill';  }} />
          </View>
          <ActionBtn label="DODGE" color="#1a3a1a" onPress={() => { actionRef.current = 'dodge'; }} wide />
        </View>
      </View>

      {/* Countdown Overlay */}
      {countdown !== null && (
        <View style={s.countdownOverlay}>
          <Text style={s.countdownText}>{countdown}</Text>
          <Text style={s.countdownSub}>BEREIT MACHEN</Text>
        </View>
      )}
    </View>
  );
}

// ---- Helper Components ----

function Row({ label, value, gold }: { label: string; value: string; gold?: boolean }) {
  return (
    <View style={s.resultRow}>
      <Text style={s.resultLabel}>{label}</Text>
      <Text style={[s.resultValue, gold && { color: '#fbbf24' }]}>{value}</Text>
    </View>
  );
}

function ActionBtn({ label, color, onPress, wide }: { label: string; color: string; onPress: () => void; wide?: boolean }) {
  return (
    <Pressable
      style={[s.btnAction, { backgroundColor: color }, wide && { width: 150 }]}
      onPress={onPress}
    >
      <Text style={s.btnActionLabel}>{label}</Text>
    </Pressable>
  );
}

// ---- Styles ----

const s = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#0a0a0f' },

  // HUD
  hud:       { height: HUD_H, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, backgroundColor: '#0f0f1a', borderBottomWidth: 1, borderBottomColor: '#1a1a3a' },
  hudMode:   { color: '#ff4d00', fontWeight: '800', fontSize: 12, letterSpacing: 2, width: 70 },
  hudTimer:  { color: '#fff', fontWeight: '700', fontSize: 22 },
  hudScore:  { color: '#aaa', fontSize: 12, width: 70, textAlign: 'right' },

  // Arena
  arena:     { backgroundColor: '#0d1117', overflow: 'hidden' },
  grid:      { position: 'absolute', backgroundColor: '#ffffff08' },
  gridH:     { left: 0, right: 0, height: 1 },
  gridV:     { top: 0, bottom: 0, width: 1 },

  // Player
  playerWrap:   { position: 'absolute', alignItems: 'center' },
  hpBarBg:      { width: PLAYER_R * 2, height: 4, backgroundColor: '#333', borderRadius: 2, marginBottom: 3, overflow: 'hidden' },
  hpBarFill:    { height: '100%', borderRadius: 2 },
  playerCircle: { borderWidth: 2, borderColor: '#00000066' },
  playerMe:     { borderColor: '#fff', borderWidth: 3 },
  meIndicator:  { position: 'absolute', top: -8, width: 6, height: 6, borderRadius: 3, borderWidth: 2, backgroundColor: 'transparent' },

  waitOverlay: { ...StyleSheet.absoluteFillObject, alignItems: 'center', justifyContent: 'center' },
  waitText:    { color: '#555', fontSize: 16 },

  // Controls
  controls:       { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, backgroundColor: '#0a0a0f' },
  joystickArea:   { width: 140, height: 140, alignItems: 'center', justifyContent: 'center' },
  joystickBase:   { width: 110, height: 110, borderRadius: 55, backgroundColor: '#1a1a2e', borderWidth: 2, borderColor: '#2a2a4a', alignItems: 'center', justifyContent: 'center' },
  joystickThumb:  { width: 46, height: 46, borderRadius: 23, backgroundColor: '#ff4d00aa' },
  actionCol:      { gap: 8, alignItems: 'center' },
  actionRow:      { flexDirection: 'row', gap: 8 },
  btnAction:      { width: 70, height: 70, borderRadius: 35, alignItems: 'center', justifyContent: 'center', borderWidth: 2, borderColor: '#ffffff22' },
  btnActionLabel: { color: '#fff', fontWeight: '800', fontSize: 11, letterSpacing: 1 },

  // Countdown
  countdownOverlay: { ...StyleSheet.absoluteFillObject, alignItems: 'center', justifyContent: 'center', backgroundColor: '#000000aa' },
  countdownText:    { fontSize: 96, fontWeight: '900', color: '#ff4d00', lineHeight: 100 },
  countdownSub:     { color: '#888', fontSize: 14, letterSpacing: 4, marginTop: 8 },

  // Results
  results:      { flex: 1, backgroundColor: '#0a0a0f', alignItems: 'center', justifyContent: 'center', padding: 32 },
  resultTitle:  { fontSize: 48, fontWeight: '900', letterSpacing: 4, marginBottom: 24 },
  resultCard:   { width: '100%', backgroundColor: '#0f0f1a', borderRadius: 16, overflow: 'hidden', marginBottom: 8 },
  resultRow:    { flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 16, borderBottomWidth: 1, borderBottomColor: '#1a1a3a' },
  resultLabel:  { color: '#888', fontSize: 16 },
  resultValue:  { color: '#fff', fontSize: 18, fontWeight: '700' },
  btnHome:      { marginTop: 32, backgroundColor: '#ff4d00', paddingHorizontal: 48, paddingVertical: 16, borderRadius: 12 },
  btnHomeLabel: { color: '#fff', fontSize: 16, fontWeight: '700', letterSpacing: 1 },
});
