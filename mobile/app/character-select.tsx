import { useState } from 'react';
import { View, Text, Pressable, StyleSheet, ScrollView } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { CHARACTERS, CharacterDef, GameMode } from '@brawlzone/shared';
import { useGameStore } from '@/stores/gameStore';

export default function CharacterSelectScreen() {
  const { mode } = useLocalSearchParams<{ mode: string }>();
  const joinQueue = useGameStore(s => s.joinQueue);
  const [selected, setSelected] = useState<CharacterDef>(CHARACTERS[0]);

  function handleStart() {
    if (!mode) return;
    joinQueue(mode as GameMode, selected.id);
    router.replace('/(tabs)');   // zurueck zur Home, die dann auf Match wartet
  }

  return (
    <View style={s.root}>
      <Text style={s.title}>CHARAKTER WAEHLEN</Text>
      <Text style={s.subtitle}>{mode?.toUpperCase()} MODUS</Text>

      <ScrollView contentContainerStyle={s.grid} showsVerticalScrollIndicator={false}>
        {CHARACTERS.map(c => {
          const isActive = c.id === selected.id;
          return (
            <Pressable
              key={c.id}
              style={[s.card, isActive && { borderColor: c.color, borderWidth: 2 }]}
              onPress={() => setSelected(c)}
            >
              <Text style={s.emoji}>{c.emoji}</Text>
              <Text style={[s.charName, { color: isActive ? c.color : '#fff' }]}>{c.name}</Text>
              <Text style={s.desc}>{c.description}</Text>

              {/* Stats */}
              <View style={s.statsGrid}>
                <StatBar label="Speed"  value={c.stats.speed}       color="#00d4ff" />
                <StatBar label="HP"     value={c.stats.health / 16} color="#00ff88" />
                <StatBar label="Attack" value={c.stats.attackPower}  color="#ff4d00" />
              </View>

              <View style={[s.skillBadge, { backgroundColor: c.color + '33' }]}>
                <Text style={[s.skillText, { color: c.color }]}>
                  SKILL: {c.stats.skillType.toUpperCase()}
                </Text>
              </View>
            </Pressable>
          );
        })}
      </ScrollView>

      {/* Vorschau des ausgewaehlten Charakters + Start-Button */}
      <View style={s.footer}>
        <View style={[s.previewDot, { backgroundColor: selected.color }]} />
        <Text style={[s.previewName, { color: selected.color }]}>{selected.name}</Text>
        <Pressable style={[s.btnStart, { backgroundColor: selected.color }]} onPress={handleStart}>
          <Text style={s.btnStartLabel}>IN DIE QUEUE</Text>
        </Pressable>
      </View>
    </View>
  );
}

function StatBar({ label, value, color }: { label: string; value: number; color: string }) {
  const pct = Math.min(1, value / 10);
  return (
    <View style={s.statRow}>
      <Text style={s.statLabel}>{label}</Text>
      <View style={s.statBarBg}>
        <View style={[s.statBarFill, { width: `${pct * 100}%` as `${number}%`, backgroundColor: color }]} />
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  root:         { flex: 1, backgroundColor: '#0a0a0f', paddingTop: 52 },
  title:        { fontSize: 22, fontWeight: '900', color: '#ff4d00', letterSpacing: 3, textAlign: 'center' },
  subtitle:     { fontSize: 12, color: '#555', letterSpacing: 2, textAlign: 'center', marginTop: 4, marginBottom: 16 },

  grid:         { paddingHorizontal: 16, gap: 12, paddingBottom: 24 },

  card:         { backgroundColor: '#0f0f1a', borderRadius: 14, padding: 16, borderWidth: 1, borderColor: '#1a1a3a' },
  emoji:        { fontSize: 36, textAlign: 'center', marginBottom: 8 },
  charName:     { fontSize: 18, fontWeight: '800', letterSpacing: 2, textAlign: 'center', marginBottom: 6 },
  desc:         { fontSize: 12, color: '#777', textAlign: 'center', lineHeight: 18, marginBottom: 14 },

  statsGrid:    { gap: 6, marginBottom: 12 },
  statRow:      { flexDirection: 'row', alignItems: 'center', gap: 8 },
  statLabel:    { width: 48, fontSize: 10, color: '#666', letterSpacing: 1 },
  statBarBg:    { flex: 1, height: 5, backgroundColor: '#1a1a2e', borderRadius: 3, overflow: 'hidden' },
  statBarFill:  { height: '100%', borderRadius: 3 },

  skillBadge:   { borderRadius: 6, paddingVertical: 5, alignItems: 'center' },
  skillText:    { fontSize: 11, fontWeight: '700', letterSpacing: 1 },

  footer:       { flexDirection: 'row', alignItems: 'center', gap: 12, paddingHorizontal: 20, paddingVertical: 16, backgroundColor: '#0f0f1a', borderTopWidth: 1, borderTopColor: '#1a1a3a' },
  previewDot:   { width: 14, height: 14, borderRadius: 7 },
  previewName:  { flex: 1, fontWeight: '800', fontSize: 14, letterSpacing: 2 },
  btnStart:     { paddingHorizontal: 24, paddingVertical: 12, borderRadius: 10 },
  btnStartLabel:{ color: '#fff', fontWeight: '800', fontSize: 13, letterSpacing: 2 },
});
