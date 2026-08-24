import { NavigationContainer } from '@react-navigation/native'
import { createNativeStackNavigator } from '@react-navigation/native-stack'
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'

import {
  ActivityIndicator,
  View,
  Text,
} from 'react-native'

import {
  AuthProvider,
  useAuth,
} from './src/context/AuthContext'

import {
  AppProvider,
} from './src/context/AppContext'

import { Colors } from './src/theme/colors'


import RegisterScreen from './src/screens/RegisterScreen'
import LoginScreen from './src/screens/LoginScreen'
import ResetPasswordScreen from './src/screens/ResetPasswordScreen'

import DiaryScreen from './src/screens/DiaryScreen'
import BrowseScreen from './src/screens/BrowseScreen'
import BuddiesScreen from './src/screens/BuddiesScreen'
import ProfileScreen from './src/screens/ProfileScreen'
import LogFilmScreen from './src/screens/LogFilmScreen'

import StatsScreen from './src/screens/StatsScreen'

import {
  SettingsScreen,
  EditDisplayNameScreen,
  EditUsernameScreen,
  EditEmailScreen,
  EditProfilePictureScreen,
  EditTopFiveScreen,
} from './src/screens/EditInfoScreens'


const Stack =
  createNativeStackNavigator()

const Tab =
  createBottomTabNavigator()


function TabIcon({ emoji }) {
  return (
    <View
      style={{
        alignItems: 'center',
        gap: 2,
      }}
    >
      <Text style={{ fontSize: 22 }}>
        {emoji}
      </Text>
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
          borderTopColor:
            Colors.subtleGray +
            '33',

          height: 60,
        },

        tabBarActiveTintColor:
          Colors.warmRed,

        tabBarInactiveTintColor:
          Colors.subtleGray,

        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '600',
          marginBottom: 4,
        },
      }}
    >
      <Tab.Screen
        name="Diary"
        component={DiaryScreen}
        options={{
          tabBarIcon: () => (
            <TabIcon emoji="📖" />
          ),
        }}
      />

      <Tab.Screen
        name="Browse"
        component={BrowseScreen}
        options={{
          tabBarIcon: () => (
            <TabIcon emoji="🎬" />
          ),
        }}
      />

      <Tab.Screen
        name="Buddies"
        component={BuddiesScreen}
        options={{
          tabBarIcon: () => (
            <TabIcon emoji="👥" />
          ),
        }}
      />

      <Tab.Screen
        name="Profile"
        component={ProfileScreen}
        options={{
          tabBarIcon: () => (
            <TabIcon emoji="🍿" />
          ),
        }}
      />
    </Tab.Navigator>
  )
}


function RootNavigator() {
  const {
    user,
    isLoading,
    isPasswordRecovery,
  } = useAuth()


  if (isLoading) {
    return (
      <View
        style={{
          flex: 1,
          justifyContent:
            'center',

          alignItems:
            'center',

          backgroundColor:
            Colors.cream,
        }}
      >
        <ActivityIndicator
          size="large"
          color={
            Colors.warmRed
          }
        />
      </View>
    )
  }


  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      {isPasswordRecovery ? (
        <Stack.Screen
          name="ResetPassword"
          component={
            ResetPasswordScreen
          }
        />
      ) : user ? (
        <>
          <Stack.Screen
            name="Main"
            component={MainTabs}
          />

          <Stack.Screen
            name="LogFilm"
            component={
              LogFilmScreen
            }
            options={{
              presentation:
                'modal',
            }}
          />

          <Stack.Screen
            name="BuddiesModal"
            component={
              BuddiesScreen
            }
            options={{
              presentation:
                'modal',
            }}
          />


          {/* PROFILE */}

          <Stack.Screen
            name="Stats"
            component={
              StatsScreen
            }
          />

          <Stack.Screen
            name="Settings"
            component={
              SettingsScreen
            }
          />

          <Stack.Screen
            name="EditDisplayName"
            component={
              EditDisplayNameScreen
            }
          />

          <Stack.Screen
            name="EditUsername"
            component={
              EditUsernameScreen
            }
          />

          <Stack.Screen
            name="EditEmail"
            component={
              EditEmailScreen
            }
          />

          <Stack.Screen
            name="EditProfilePicture"
            component={
              EditProfilePictureScreen
            }
          />

          <Stack.Screen
            name="EditTopFive"
            component={
              EditTopFiveScreen
            }
          />
        </>
      ) : (
        <>
          <Stack.Screen
            name="Login"
            component={
              LoginScreen
            }
          />

          <Stack.Screen
            name="Register"
            component={
              RegisterScreen
            }
          />
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
