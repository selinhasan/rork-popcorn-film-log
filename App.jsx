import { NavigationContainer } from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { ActivityIndicator, View } from 'react-native'

import { AuthProvider, useAuth } from './src/context/AuthContext'
import LoginScreen from './src/screens/LoginScreen'
import RegisterScreen from './src/screens/RegisterScreen'
import HomeScreen from './src/screens/HomeScreen'

const Stack = createNativeStackNavigator()

// Separate component so it can access the AuthContext
function RootNavigator() {
  const { session, loading } = useAuth()

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
        <ActivityIndicator size="large" color="#3ECF8E" />
      </View>
    )
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {session ? (
        // Authenticated stack
        <Stack.Screen name="Home" component={HomeScreen} />
      ) : (
        // Unauthenticated stack
        <>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Register" component={RegisterScreen} />
        </>
      )}
    </Stack.Navigator>
  )
}

export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>
    </AuthProvider>
  )
}
