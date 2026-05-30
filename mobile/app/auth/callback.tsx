import { useEffect } from 'react';
import { View, ActivityIndicator } from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { supabase } from '@/services/supabase';
import { useGameStore } from '@/stores/gameStore';

export default function AuthCallback() {
  const { code } = useLocalSearchParams<{ code: string }>();
  const setAuth = useGameStore(s => s.setAuth);

  useEffect(() => {
    if (!code) { router.replace('/login'); return; }

    supabase.auth.exchangeCodeForSession(code).then(({ data, error }) => {
      if (error || !data.session) { router.replace('/login'); return; }
      setAuth(data.session.user.id, data.session.access_token);
      router.replace('/(tabs)');
    });
  }, [code, setAuth]);

  return (
    <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
      <ActivityIndicator size="large" color="#ff4d00" />
    </View>
  );
}
