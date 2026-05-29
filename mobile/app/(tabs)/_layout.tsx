import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown:     false,
        tabBarStyle:     { backgroundColor: '#0f0f1a', borderTopColor: '#1a1a3a' },
        tabBarActiveTintColor:   '#ff4d00',
        tabBarInactiveTintColor: '#444',
        tabBarLabelStyle: { fontSize: 10, letterSpacing: 1, fontWeight: '700' },
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'PLAY',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="game-controller" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'PROFILE',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="person-circle" color={color} size={size} />
          ),
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'SETTINGS',
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="settings" color={color} size={size} />
          ),
        }}
      />
    </Tabs>
  );
}
