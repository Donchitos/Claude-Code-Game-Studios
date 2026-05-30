import { Stack, router } from 'expo-router';
import { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { useGameStore } from '@/stores/gameStore';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const initialize = useGameStore(s => s.initialize);
  const userId = useGameStore(s => s.userId);

  useEffect(() => {
    initialize().finally(() => {
      SplashScreen.hideAsync();
      // Redirect to login if not authenticated after init
      if (!useGameStore.getState().userId) {
        router.replace('/login');
      }
    });
  }, [initialize]);

  // If auth state changes to null mid-session, redirect to login
  useEffect(() => {
    if (userId === null) {
      // Small delay to let the store settle on first mount
      const t = setTimeout(() => {
        if (!useGameStore.getState().userId) router.replace('/login');
      }, 500);
      return () => clearTimeout(t);
    }
  }, [userId]);

  return (
    <>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: '#0a0a0f' },
        }}
      >
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="match" options={{ animation: 'fade', gestureEnabled: false }} />
        <Stack.Screen name="character-select" options={{ animation: 'slide_from_bottom' }} />
        <Stack.Screen name="login" />
      </Stack>
    </>
  );
}
