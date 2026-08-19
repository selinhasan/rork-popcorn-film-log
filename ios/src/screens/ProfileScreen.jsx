import React, { useState } from 'react'
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
} from 'react-native'
import { useAuth } from '../context/AuthContext'
import { Colors } from '../theme/colors'

export default function ProfileScreen() {
  const { user, logout } = useAuth()
  const [confirming, setConfirming] = useState(false)

  const handleSignOut = async () => {
    try {
      setConfirming(false)
      await logout()
    } catch (error) {
      console.error('Sign out error:', error)
      Alert.alert(
        'Sign out failed',
        error?.message || 'Something went wrong while signing out.'
      )
    }
  }

  const username =
    user?.user_metadata?.username ||
    user?.email?.split('@')[0] ||
    'User'

  const email = user?.email || ''

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
    >
      <Text style={styles.title}>Profile</Text>

      <View style={styles.profileCard}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>
            {username.charAt(0).toUpperCase()}
          </Text>
        </View>

        <Text style={styles.username}>{username}</Text>

        {!!email && (
          <Text style={styles.email}>{email}</Text>
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Account</Text>

        <View style={styles.infoRow}>
          <Text style={styles.label}>Username</Text>
          <Text style={styles.value}>{username}</Text>
        </View>

        <View style={styles.infoRow}>
          <Text style={styles.label}>Email</Text>
          <Text style={styles.value}>{email || '—'}</Text>
        </View>
      </View>

      <View style={styles.signOutSection}>
        {!confirming ? (
          <TouchableOpacity
            style={styles.signOutBtn}
            onPress={() => setConfirming(true)}
          >
            <Text style={styles.signOutText}>Sign Out</Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.confirmBox}>
            <Text style={styles.confirmText}>
              Are you sure you want to sign out?
            </Text>

            <View style={styles.confirmButtons}>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => setConfirming(false)}
              >
                <Text style={styles.cancelText}>Cancel</Text>
              </TouchableOpacity>

              <TouchableOpacity
                style={styles.confirmSignOutBtn}
                onPress={handleSignOut}
              >
                <Text style={styles.confirmSignOutText}>
                  Sign Out
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>
    </ScrollView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.cream,
  },

  content: {
    padding: 20,
    paddingTop: 60,
    paddingBottom: 40,
  },

  title: {
    fontSize: 30,
    fontWeight: '700',
    color: Colors.warmRed,
    marginBottom: 24,
  },

  profileCard: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 24,
    alignItems: 'center',
    marginBottom: 24,
  },

  avatar: {
    width: 76,
    height: 76,
    borderRadius: 38,
    backgroundColor: Colors.warmRed,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 14,
  },

  avatarText: {
    color: '#fff',
    fontSize: 32,
    fontWeight: '700',
  },

  username: {
    fontSize: 22,
    fontWeight: '700',
    color: '#1c1c1a',
    marginBottom: 5,
  },

  email: {
    fontSize: 14,
    color: '#777',
  },

  section: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 20,
    marginBottom: 24,
  },

  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: '#1c1c1a',
    marginBottom: 16,
  },

  infoRow: {
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#eeeeeb',
  },

  label: {
    fontSize: 12,
    color: '#888',
    marginBottom: 4,
  },

  value: {
    fontSize: 16,
    color: '#1c1c1a',
  },

  signOutSection: {
    marginTop: 4,
  },

  signOutBtn: {
    backgroundColor: Colors.warmRed,
    borderRadius: 12,
    paddingVertical: 15,
    alignItems: 'center',
  },

  signOutText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },

  confirmBox: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 20,
  },

  confirmText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1c1c1a',
    textAlign: 'center',
    marginBottom: 18,
  },

  confirmButtons: {
    flexDirection: 'row',
    gap: 10,
  },

  cancelBtn: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#d8d8d4',
    borderRadius: 10,
    paddingVertical: 13,
    alignItems: 'center',
  },

  cancelText: {
    color: '#1c1c1a',
    fontSize: 15,
    fontWeight: '600',
  },

  confirmSignOutBtn: {
    flex: 1,
    backgroundColor: Colors.warmRed,
    borderRadius: 10,
    paddingVertical: 13,
    alignItems: 'center',
  },

  confirmSignOutText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '600',
  },
})
