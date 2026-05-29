import { useEffect } from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { router } from 'expo-router';
import { useGameStore } from '@/stores/gameStore';
import { GameMode } from '@brawlzone/shared';

const MODE_LABELS: Record<GameMode, { label: string; sub: string }> = {
  [GameMode.DUEL]:  { label: '1v1 DUELL',  sub: '2 Spieler • 10 min' },
  [GameMode.SQUAD]: { label: '3v3 SQUAD',  sub: '6 Spieler • 10 min' },
  [GameMode.FFA]:   { label: 'FREE FOR ALL', sub: '8 Spieler • 10 min' },
};

export default function HomeScreen() {
  const { isInQueue, queueMode, queuePosition, currentMatch, leaveQueue } = useGameStore();

  useEffect(() => {
    if (currentMatch) router.push('/match');
  }, [currentMatch]);

  if (isInQueue) {
    return (
      <View style={s.container}>
        <Text style={s.title}>BRAWLZONE</Text>
        <View style={s.queueBox}>
          <Text style={s.queueText}>Suche nach Match...</Text>
          <Text style={s.queueMode}>{queueMode?.toUpperCase()}</Text>
          <View style={s.queueDots}>
            {[0, 1, 2].map(i => <View key={i} style={s.dot} />)}
          </View>
          <Text style={s.queuePos}>Warteschlange: #{queuePosition}</Text>
          <Pressable style={s.btnCancel} onPress={leaveQueue}>
            <Text style={s.btnCancelLabel}>Abbrechen</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  return (
    <View style={s.container}>
      <Text style={s.title}>BRAWLZONE</Text>
      <Text style={s.subtitle}>WAEHLE EINEN MODUS</Text>

      <View style={s.modeList}>
        {Object.values(GameMode).map(mode => {
          const info = MODE_LABELS[mode];
          return (
            <Pressable
              key={mode}
              style={s.modeBtn}
              onPress={() => router.push({ pathname: '/character-select', params: { mode } })}
            >
              <Text style={s.modeBtnLabel}>{info.label}</Text>
              <Text style={s.modeBtnSub}>{info.sub}</Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  container:      { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 20, backgroundColor: '#0a0a0f' },
  title:          { fontSize: 42, fontWeight: '900', color: '#ff4d00', letterSpacing: 4 },
  subtitle:       { fontSize: 11, color: '#444', letterSpacing: 3, marginTop: -12 },

  // Queue State
  queueBox:       { alignItems: 'center', gap: 10 },
  queueText:      { color: '#fff', fontSize: 20, fontWeight: '700' },
  queueMode:      { color: '#ff4d00', fontSize: 13, letterSpacing: 2 },
  queueDots:      { flexDirection: 'row', gap: 6, marginVertical: 4 },
  dot:            { width: 8, height: 8, borderRadius: 4, backgroundColor: '#ff4d00aa' },
  queuePos:       { color: '#555', fontSize: 12 },
  btnCancel:      { marginTop: 8, paddingHorizontal: 32, paddingVertical: 12, backgroundColor: '#1a1a1a', borderRadius: 8, borderWidth: 1, borderColor: '#333' },
  btnCancelLabel: { color: '#aaa', fontSize: 14 },

  // Mode Selection
  modeList:       { gap: 12, width: '82%' },
  modeBtn:        { backgroundColor: '#0f0f1a', borderRadius: 14, paddingVertical: 22, paddingHorizontal: 20, borderWidth: 1, borderColor: '#ff4d0055' },
  modeBtnLabel:   { color: '#fff', fontSize: 17, fontWeight: '800', letterSpacing: 2, marginBottom: 4 },
  modeBtnSub:     { color: '#555', fontSize: 11, letterSpacing: 1 },
});
