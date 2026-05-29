import { Stack } from 'expo-router';
import { useEffect } from 'react';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { useGameStore } from '@/stores/gameStore';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const initialize = useGameStore(s => s.initialize);

  useEffect(() => {
    initialize().finally(() => SplashScreen.hideAsync());
  }, [initialize]);

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
