import { NavigationContainer } from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import { ActivityIndicator, View, Text } from 'react-native'

import { AuthProvider, useAuth } from './src/context/AuthContext'
import { AppProvider } from './src/context/AppContext'
import { Colors } from './src/theme/colors'

import RegisterScreen from './src/screens/RegisterScreen'
import LoginScreen from './src/screens/LoginScreen'
import DiaryScreen from './src/screens/DiaryScreen'
import BrowseScreen from './src/screens/BrowseScreen'
import BuddiesScreen from './src/screens/BuddiesScreen'
import ProfileScreen from './src/screens/ProfileScreen'
import LogFilmScreen from './src/screens/LogFilmScreen'

const Stack = createNativeStackNavigator()
const Tab = createBottomTabNavigator()

function TabIcon({ emoji, label, focused }) {
  return (
    <View style={{ alignItems: 'center', gap: 2 }}>
      <Text style={{ fontSize: 22 }}>{emoji}</Text>
    </View>
  )
}

function MainTabs() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarStyle: {
          backgroundColor: '#fff',
          borderTopColor: Colors.subtleGray + '33',
          height: 60,
        },
        tabBarActiveTintColor: Colors.warmRed,
        tabBarInactiveTintColor: Colors.subtleGray,
        tabBarLabelStyle: { fontSize: 11, fontWeight: '600', marginBottom: 4 },
      }}
    >
      <Tab.Screen
        name="Diary"
        component={DiaryScreen}
        options={{ tabBarIcon: ({ focused }) => <TabIcon emoji="📖" focused={focused} /> }}
      />
      <Tab.Screen
        name="Browse"
        component={BrowseScreen}
        options={{ tabBarIcon: ({ focused }) => <TabIcon emoji="🎬" focused={focused} /> }}
      />
      <Tab.Screen
        name="Buddies"
        component={BuddiesScreen}
        options={{ tabBarIcon: ({ focused }) => <TabIcon emoji="👥" focused={focused} /> }}
      />
      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{ tabBarIcon: ({ focused }) => <TabIcon emoji="🍿" focused={focused} /> }}
      />
    </Tab.Navigator>
  )
}

function RootNavigator() {
  const { session, loading } = useAuth()

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Colors.cream }}>
        <ActivityIndicator size="large" color={Colors.warmRed} />
      </View>
    )
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {session ? (
        <>
          <Stack.Screen name="Main" component={MainTabs} />
          <Stack.Screen
            name="Buddies"
            component={BuddiesScreen}
            options={{ presentation: 'modal' }}
          />
        </>
      ) : (
        <>
          <Stack.Screen name="Register" component={RegisterScreen} />
          <Stack.Screen name="Login" component={LoginScreen} />
        </>
      )}
    </Stack.Navigator>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <AppProvider>
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>
      </AppProvider>
    </AuthProvider>
  )
}
