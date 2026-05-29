import { useEffect, useState } from 'react';
import {
  View, Text, ScrollView, StyleSheet, ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { useGameStore } from '@/stores/gameStore';
import Constants from 'expo-constants';

const SERVER_URL =
  (Constants.expoConfig?.extra?.serverUrl as string | undefined) ??
  process.env.EXPO_PUBLIC_SERVER_URL ??
  'http://localhost:3001';

interface Profile {
  user_id: string;
  display_name: string;
  level: number;
  xp: number;
  mmr: number;
  peak_mmr: number;
  total_matches: number;
  wins: number;
  losses: number;
  kills: number;
  diamond_balance: number;
  coin_balance: number;
  is_provisional: boolean;
  has_play_pass: boolean;
}

function tier(mmr: number): { name: string; color: string } {
  if (mmr < 800)  return { name: 'BRONZE',   color: '#cd7f32' };
  if (mmr < 1000) return { name: 'SILVER',   color: '#c0c0c0' };
  if (mmr < 1200) return { name: 'GOLD',     color: '#ffd700' };
  if (mmr < 1400) return { name: 'PLATINUM', color: '#00d4ff' };
  if (mmr < 1600) return { name: 'DIAMOND',  color: '#b9f2ff' };
  return             { name: 'MASTER',    color: '#ff4d00' };
}

export default function ProfileScreen() {
  const { authToken, userId } = useGameStore();
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchProfile = async (silent = false) => {
    if (!authToken) { setLoading(false); return; }
    if (!silent) setLoading(true);
    try {
      const res = await fetch(`${SERVER_URL}/v1/profile/me`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      if (res.ok) { const body = await res.json(); setProfile(body.profile ?? body); }
    } catch {
      // server offline — use cached or skip
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => { fetchProfile(); }, [authToken]);

  if (!authToken) {
    return (
      <View style={s.center}>
        <Text style={s.muted}>Sign in to view your profile.</Text>
      </View>
    );
  }

  if (loading) {
    return (
      <View style={s.center}>
        <ActivityIndicator size="large" color="#ff4d00" />
      </View>
    );
  }

  const p = profile;
  const winRate = p && p.total_matches > 0
    ? Math.round((p.wins / p.total_matches) * 100)
    : 0;
  const rankInfo = p ? tier(p.mmr) : tier(1000);
  const xpForNext = (p?.level ?? 1) * 500;
  const xpPct = p ? Math.min(1, p.xp / xpForNext) : 0;

  return (
    <ScrollView
      style={s.root}
      contentContainerStyle={s.content}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={() => { setRefreshing(true); fetchProfile(true); }}
          tintColor="#ff4d00"
        />
      }
    >
      {/* Header */}
      <View style={s.header}>
        <View style={[s.avatar, { backgroundColor: rankInfo.color + '33' }]}>
          <Text style={[s.avatarText, { color: rankInfo.color }]}>
            {(p?.display_name ?? 'Player').charAt(0).toUpperCase()}
          </Text>
        </View>
        <Text style={s.name}>{p?.display_name ?? 'Player'}</Text>
        <View style={[s.rankBadge, { backgroundColor: rankInfo.color + '22', borderColor: rankInfo.color + '66' }]}>
          <Text style={[s.rankText, { color: rankInfo.color }]}>{rankInfo.name}</Text>
          {p?.is_provisional && <Text style={s.provisional}> · PLACEMENT</Text>}
        </View>
      </View>

      {/* MMR card */}
      <View style={s.card}>
        <Row label="MMR"      value={String(p?.mmr ?? 1000)} accent />
        <Row label="Peak MMR" value={String(p?.peak_mmr ?? 1000)} />
        <Row label="Level"    value={String(p?.level ?? 1)} />
      </View>

      {/* XP bar */}
      <View style={s.card}>
        <View style={s.xpRow}>
          <Text style={s.xpLabel}>Level {p?.level ?? 1}</Text>
          <Text style={s.xpValue}>{p?.xp ?? 0} / {xpForNext} XP</Text>
        </View>
        <View style={s.xpBarBg}>
          <View style={[s.xpBarFill, { width: `${xpPct * 100}%` as `${number}%` }]} />
        </View>
      </View>

      {/* Match stats */}
      <Text style={s.sectionLabel}>MATCH STATS</Text>
      <View style={s.card}>
        <Row label="Matches Played" value={String(p?.total_matches ?? 0)} />
        <Row label="Wins"           value={String(p?.wins ?? 0)} />
        <Row label="Losses"         value={String(p?.losses ?? 0)} />
        <Row label="Win Rate"       value={`${winRate}%`} />
        <Row label="Total Kills"    value={String(p?.kills ?? 0)} />
      </View>

      {/* Economy */}
      <Text style={s.sectionLabel}>WALLET</Text>
      <View style={s.card}>
        <Row label="Coins"    value={String(p?.coin_balance ?? 0)} />
        <Row label="Diamonds" value={String(p?.diamond_balance ?? 0)} gold />
        {p?.has_play_pass && (
          <View style={s.playPassBadge}>
            <Text style={s.playPassText}>⚡ PLAY PASS ACTIVE</Text>
          </View>
        )}
      </View>
    </ScrollView>
  );
}

function Row({ label, value, accent, gold }: {
  label: string; value: string; accent?: boolean; gold?: boolean;
}) {
  return (
    <View style={s.row}>
      <Text style={s.rowLabel}>{label}</Text>
      <Text style={[s.rowValue, accent && { color: '#ff4d00' }, gold && { color: '#fbbf24' }]}>
        {value}
      </Text>
    </View>
  );
}

const s = StyleSheet.create({
  root:         { flex: 1, backgroundColor: '#0a0a0f' },
  content:      { paddingTop: 60, paddingBottom: 40, paddingHorizontal: 16 },
  center:       { flex: 1, alignItems: 'center', justifyContent: 'center' },
  muted:        { color: '#555', fontSize: 14 },

  header:       { alignItems: 'center', marginBottom: 24 },
  avatar:       { width: 80, height: 80, borderRadius: 40, alignItems: 'center', justifyContent: 'center', marginBottom: 12 },
  avatarText:   { fontSize: 36, fontWeight: '900' },
  name:         { fontSize: 24, fontWeight: '900', color: '#fff', letterSpacing: 2, marginBottom: 8 },
  rankBadge:    { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 14, paddingVertical: 5, borderRadius: 20, borderWidth: 1 },
  rankText:     { fontSize: 12, fontWeight: '800', letterSpacing: 2 },
  provisional:  { fontSize: 11, color: '#888' },

  sectionLabel: { color: '#444', fontSize: 11, letterSpacing: 2, marginTop: 8, marginBottom: 6, marginLeft: 4 },
  card:         { backgroundColor: '#0f0f1a', borderRadius: 14, marginBottom: 12, overflow: 'hidden', borderWidth: 1, borderColor: '#1a1a3a' },
  row:          { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: '#1a1a3a' },
  rowLabel:     { color: '#666', fontSize: 14 },
  rowValue:     { color: '#fff', fontSize: 16, fontWeight: '700' },

  xpRow:        { flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 16, paddingTop: 14, paddingBottom: 8 },
  xpLabel:      { color: '#666', fontSize: 13 },
  xpValue:      { color: '#fff', fontSize: 13 },
  xpBarBg:      { height: 6, backgroundColor: '#1a1a3a', marginHorizontal: 16, marginBottom: 14, borderRadius: 3, overflow: 'hidden' },
  xpBarFill:    { height: '100%', backgroundColor: '#ff4d00', borderRadius: 3 },

  playPassBadge: { alignItems: 'center', paddingVertical: 10 },
  playPassText:  { color: '#fbbf24', fontWeight: '800', fontSize: 12, letterSpacing: 2 },
});
