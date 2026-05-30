import { useState } from 'react';
import { View, Text, TextInput, Pressable, StyleSheet, ActivityIndicator, Alert } from 'react-native';
import { router } from 'expo-router';
import { signInWithGoogle, signInWithEmail, signUpWithEmail } from '@/services/supabase';
import { useGameStore } from '@/stores/gameStore';

export default function LoginScreen() {
  const setAuth = useGameStore(s => s.setAuth);
  const [mode, setMode] = useState<'login' | 'signup'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [loading, setLoading] = useState(false);

  const handleEmail = async () => {
    if (!email || !password) return;
    setLoading(true);
    try {
      const { data, error } =
        mode === 'login'
          ? await signInWithEmail(email, password)
          : await signUpWithEmail(email, password, username);

      if (error) throw error;
      if (data.session) {
        setAuth(data.session.user.id, data.session.access_token);
        router.replace('/(tabs)');
      }
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Auth failed');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    setLoading(true);
    try {
      await signInWithGoogle();
      // Session is picked up by the onAuthStateChange listener in initialize()
      router.replace('/(tabs)');
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Google sign-in failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>BRAWLZONE</Text>
      <Text style={styles.subtitle}>{mode === 'login' ? 'Sign in' : 'Create account'}</Text>

      {mode === 'signup' && (
        <TextInput
          style={styles.input}
          placeholder="Username"
          placeholderTextColor="#555"
          value={username}
          onChangeText={setUsername}
          autoCapitalize="none"
        />
      )}
      <TextInput
        style={styles.input}
        placeholder="Email"
        placeholderTextColor="#555"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        keyboardType="email-address"
      />
      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#555"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />

      <Pressable style={styles.btnPrimary} onPress={handleEmail} disabled={loading}>
        {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.btnLabel}>{mode === 'login' ? 'Sign In' : 'Sign Up'}</Text>}
      </Pressable>

      <Pressable style={styles.btnGoogle} onPress={handleGoogle} disabled={loading}>
        <Text style={styles.btnLabel}>Continue with Google</Text>
      </Pressable>

      <Pressable onPress={() => setMode(mode === 'login' ? 'signup' : 'login')}>
        <Text style={styles.toggle}>
          {mode === 'login' ? "Don't have an account? Sign up" : 'Already have an account? Sign in'}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container:  { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32, gap: 12 },
  title:      { fontSize: 40, fontWeight: '900', color: '#ff4d00', letterSpacing: 4, marginBottom: 4 },
  subtitle:   { color: '#888', fontSize: 14, marginBottom: 16 },
  input:      { width: '100%', backgroundColor: '#1a1a2e', borderRadius: 10, padding: 14, color: '#fff', fontSize: 16, borderWidth: 1, borderColor: '#333' },
  btnPrimary: { width: '100%', backgroundColor: '#ff4d00', borderRadius: 10, padding: 16, alignItems: 'center' },
  btnGoogle:  { width: '100%', backgroundColor: '#1a1a2e', borderRadius: 10, padding: 16, alignItems: 'center', borderWidth: 1, borderColor: '#4285F4' },
  btnLabel:   { color: '#fff', fontWeight: '700', fontSize: 16 },
  toggle:     { color: '#888', fontSize: 13, marginTop: 8 },
});
