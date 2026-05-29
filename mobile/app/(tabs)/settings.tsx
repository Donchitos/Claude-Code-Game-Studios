import { useState } from 'react';
import {
  View, Text, Pressable, StyleSheet, ScrollView,
  Alert, Switch, TextInput, ActivityIndicator,
} from 'react-native';
import { router } from 'expo-router';
import { useGameStore } from '@/stores/gameStore';
import { signOut } from '@/services/supabase';
import Constants from 'expo-constants';

const SERVER_URL =
  (Constants.expoConfig?.extra?.serverUrl as string | undefined) ??
  process.env.EXPO_PUBLIC_SERVER_URL ??
  'http://localhost:3001';

export default function SettingsScreen() {
  const { authToken, userId } = useGameStore();
  const setAuth = useGameStore(s => s.setAuth);

  const [newName, setNewName] = useState('');
  const [renaming, setRenaming] = useState(false);
  const [notifications, setNotifications] = useState(true);
  const [analytics, setAnalytics] = useState(true);

  const handleRename = async () => {
    const name = newName.trim();
    if (name.length < 3 || name.length > 20) {
      Alert.alert('Invalid name', 'Name must be 3–20 characters (letters, numbers, _ or -)');
      return;
    }
    if (!authToken) return;
    setRenaming(true);
    try {
      const res = await fetch(`${SERVER_URL}/v1/profile/me/name`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${authToken}` },
        body: JSON.stringify({ displayName: name }),
      });
      if (res.ok) {
        Alert.alert('Done', `Display name changed to "${name}"`);
        setNewName('');
      } else {
        const body = await res.json().catch(() => ({}));
        Alert.alert('Error', body.error ?? 'Could not update name');
      }
    } catch {
      Alert.alert('Error', 'Server offline — try again later');
    } finally {
      setRenaming(false);
    }
  };

  const handleSignOut = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Sign Out',
          style: 'destructive',
          onPress: async () => {
            await signOut();
            router.replace('/login');
          },
        },
      ],
    );
  };

  return (
    <ScrollView style={s.root} contentContainerStyle={s.content}>
      <Text style={s.pageTitle}>SETTINGS</Text>

      {/* Account */}
      <Text style={s.section}>ACCOUNT</Text>
      <View style={s.card}>
        <View style={s.idRow}>
          <Text style={s.idLabel}>User ID</Text>
          <Text style={s.idValue} numberOfLines={1}>{userId ?? '—'}</Text>
        </View>
      </View>

      {/* Change display name */}
      <Text style={s.section}>DISPLAY NAME</Text>
      <View style={s.card}>
        <TextInput
          style={s.nameInput}
          value={newName}
          onChangeText={setNewName}
          placeholder="New display name (3–20 chars)"
          placeholderTextColor="#444"
          autoCapitalize="none"
          maxLength={20}
        />
        <Pressable
          style={[s.btnRename, (!newName.trim() || renaming) && s.btnDisabled]}
          onPress={handleRename}
          disabled={!newName.trim() || renaming}
        >
          {renaming
            ? <ActivityIndicator color="#fff" size="small" />
            : <Text style={s.btnLabel}>SAVE NAME</Text>
          }
        </Pressable>
        <Text style={s.hint}>30-day cooldown between changes. Alphanumeric, _ and - only.</Text>
      </View>

      {/* Preferences */}
      <Text style={s.section}>PREFERENCES</Text>
      <View style={s.card}>
        <ToggleRow
          label="Push Notifications"
          sub="Match reminders and event alerts"
          value={notifications}
          onChange={setNotifications}
        />
        <ToggleRow
          label="Analytics"
          sub="Help improve the game (non-PII)"
          value={analytics}
          onChange={setAnalytics}
        />
      </View>

      {/* About */}
      <Text style={s.section}>ABOUT</Text>
      <View style={s.card}>
        <InfoRow label="Version"    value="1.0.0" />
        <InfoRow label="Server"     value={SERVER_URL.replace('https://', '').replace('http://', '')} />
        <InfoRow label="Build"      value="Production" />
      </View>

      {/* Danger zone */}
      <Pressable style={s.btnSignOut} onPress={handleSignOut}>
        <Text style={s.btnSignOutLabel}>SIGN OUT</Text>
      </Pressable>
    </ScrollView>
  );
}

function ToggleRow({ label, sub, value, onChange }: {
  label: string; sub: string; value: boolean; onChange: (v: boolean) => void;
}) {
  return (
    <View style={s.toggleRow}>
      <View style={{ flex: 1 }}>
        <Text style={s.toggleLabel}>{label}</Text>
        <Text style={s.toggleSub}>{sub}</Text>
      </View>
      <Switch
        value={value}
        onValueChange={onChange}
        trackColor={{ false: '#1a1a3a', true: '#ff4d0066' }}
        thumbColor={value ? '#ff4d00' : '#333'}
      />
    </View>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={s.infoRow}>
      <Text style={s.infoLabel}>{label}</Text>
      <Text style={s.infoValue} numberOfLines={1}>{value}</Text>
    </View>
  );
}

const s = StyleSheet.create({
  root:         { flex: 1, backgroundColor: '#0a0a0f' },
  content:      { paddingTop: 60, paddingBottom: 60, paddingHorizontal: 16 },
  pageTitle:    { fontSize: 22, fontWeight: '900', color: '#ff4d00', letterSpacing: 3, marginBottom: 24, textAlign: 'center' },

  section:      { color: '#444', fontSize: 11, letterSpacing: 2, marginTop: 8, marginBottom: 6, marginLeft: 4 },
  card:         { backgroundColor: '#0f0f1a', borderRadius: 14, marginBottom: 12, overflow: 'hidden', borderWidth: 1, borderColor: '#1a1a3a' },

  idRow:        { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', padding: 16 },
  idLabel:      { color: '#555', fontSize: 13 },
  idValue:      { color: '#888', fontSize: 11, flex: 1, textAlign: 'right', marginLeft: 8 },

  nameInput:    { color: '#fff', fontSize: 16, padding: 16, borderBottomWidth: 1, borderBottomColor: '#1a1a3a' },
  btnRename:    { backgroundColor: '#ff4d00', margin: 12, borderRadius: 10, paddingVertical: 12, alignItems: 'center' },
  btnDisabled:  { opacity: 0.4 },
  btnLabel:     { color: '#fff', fontWeight: '800', fontSize: 13, letterSpacing: 2 },
  hint:         { color: '#444', fontSize: 11, paddingHorizontal: 16, paddingBottom: 14, lineHeight: 16 },

  toggleRow:    { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: '#1a1a3a' },
  toggleLabel:  { color: '#fff', fontSize: 14, fontWeight: '600' },
  toggleSub:    { color: '#555', fontSize: 11, marginTop: 2 },

  infoRow:      { flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 16, paddingVertical: 13, borderBottomWidth: 1, borderBottomColor: '#1a1a3a' },
  infoLabel:    { color: '#555', fontSize: 13 },
  infoValue:    { color: '#888', fontSize: 13, flex: 1, textAlign: 'right', marginLeft: 8 },

  btnSignOut:   { backgroundColor: '#1a0505', borderRadius: 12, paddingVertical: 16, alignItems: 'center', marginTop: 16, borderWidth: 1, borderColor: '#ff4d0044' },
  btnSignOutLabel: { color: '#ff4d00', fontWeight: '800', fontSize: 14, letterSpacing: 2 },
});
