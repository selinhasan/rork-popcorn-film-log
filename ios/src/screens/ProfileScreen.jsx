import { useState } from 'react'
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  Image, Alert, Modal, TextInput, Switch,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useAuth } from '../context/AuthContext'
import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'

function StatBox({ value, label }) {
  return (
    <View style={styles.statBox}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={styles.statLabel}>{label}</Text>
    </View>
  )
}

function FilmPosterSmall({ film, rank }) {
  return (
    <View style={styles.topFilmCard}>
      {film.posterURL ? (
        <Image source={{ uri: film.posterURL }} style={styles.topFilmPoster} />
      ) : (
        <View style={[styles.topFilmPoster, { backgroundColor: Colors.cardBackground, alignItems: 'center', justifyContent: 'center' }]}>
          <Text>🎬</Text>
        </View>
      )}
      {rank && (
        <View style={styles.rankBadge}>
          <Text style={styles.rankText}>#{rank}</Text>
        </View>
      )}
    </View>
  )
}

export default function ProfileScreen({ navigation }) {
  const { user, profile, signOut } = useAuth()
  const { diaryEntries, watchlist, topFive } = useApp()
  const insets = useSafeAreaInsets()
  const [showSettings, setShowSettings] = useState(false)

  const uniqueFilms = new Set(diaryEntries.map(e => e.film.id)).size
  const totalRatings = diaryEntries.filter(e => e.rating > 0).length
  const avgRating = totalRatings > 0
    ? (diaryEntries.reduce((sum, e) => sum + e.rating, 0) / totalRatings).toFixed(1)
    : '—'

  const username = profile?.username || user?.email?.split('@')[0] || 'User'
  const joinDate = user?.created_at
    ? new Date(user.created_at).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    : ''

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.navBar}>
        <Text style={styles.navTitle}>Profile</Text>
        <TouchableOpacity onPress={() => setShowSettings(true)}>
          <Text style={styles.gearIcon}>⚙️</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={{ paddingBottom: 32 }}>
        {/* Profile header */}
        <View style={styles.profileHeader}>
          <View style={styles.avatar}>
            <Text style={styles.avatarEmoji}>🍿</Text>
          </View>
          <Text style={styles.username}>{username}</Text>
          {joinDate ? <Text style={styles.joinDate}>Joined {joinDate}</Text> : null}
        </View>

        {/* Stats */}
        <View style={styles.statsRow}>
          <StatBox value={diaryEntries.length} label="Logged" />
          <StatBox value={uniqueFilms} label="Films" />
          <StatBox value={avgRating} label="Avg Rating" />
          <StatBox value={watchlist.length} label="Watchlist" />
        </View>

        {/* Top 5 */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Top 5 Films</Text>
          {topFive.length === 0 ? (
            <Text style={styles.emptyHint}>Log films and pin your favourites here</Text>
          ) : (
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 10, paddingHorizontal: 16 }}>
              {topFive.map((film, i) => (
                <FilmPosterSmall key={film.id} film={film} rank={i + 1} />
              ))}
            </ScrollView>
          )}
        </View>

        {/* Watchlist */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Watchlist ({watchlist.length})</Text>
          {watchlist.length === 0 ? (
            <Text style={styles.emptyHint}>Films you want to watch will appear here</Text>
          ) : (
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ gap: 10, paddingHorizontal: 16 }}>
              {watchlist.map(film => (
                <FilmPosterSmall key={film.id} film={film} rank={null} />
              ))}
            </ScrollView>
          )}
        </View>

        {/* Recent activity */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Recent Activity</Text>
          {diaryEntries.slice(0, 5).map(entry => (
            <View key={entry.id} style={styles.recentRow}>
              {entry.film.posterURL ? (
                <Image source={{ uri: entry.film.posterURL }} style={styles.recentPoster} />
              ) : (
                <View style={[styles.recentPoster, { backgroundColor: Colors.cardBackground }]} />
              )}
              <View style={{ flex: 1 }}>
                <Text style={styles.recentTitle} numberOfLines={1}>{entry.film.title}</Text>
                <Text style={styles.recentMeta}>
                  {new Date(entry.dateWatched).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  {entry.rating > 0 ? `  ·  ${'🍿'.repeat(Math.round(entry.rating))}` : ''}
                </Text>
              </View>
            </View>
          ))}
        </View>
      </ScrollView>

      {/* Settings modal */}
      <Modal visible={showSettings} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setShowSettings(false)}>
        <SettingsSheet onClose={() => setShowSettings(false)} />
      </Modal>
    </View>
  )
}

function SettingsSheet({ onClose }) {
  const { user, signOut } = useAuth()
  const insets = useSafeAreaInsets()
  const [confirming, setConfirming] = useState(false)

  const handleSignOut = async () => {
    try {
      await signOut()
    } catch (_) {}
  }

  return (
    <View style={[settingsStyles.container, { paddingTop: insets.top }]}>
      <View style={settingsStyles.header}>
        <Text style={settingsStyles.title}>Settings</Text>
        <TouchableOpacity onPress={onClose}>
          <Text style={settingsStyles.done}>Done</Text>
        </TouchableOpacity>
      </View>
      <ScrollView>
        <View style={settingsStyles.section}>
          <View style={settingsStyles.row}>
            <Text style={settingsStyles.label}>Email</Text>
            <Text style={settingsStyles.value}>{user?.email}</Text>
          </View>
        </View>

        {confirming ? (
          <View style={settingsStyles.confirmRow}>
            <Text style={settingsStyles.confirmText}>Sign out?</Text>
            <View style={settingsStyles.confirmBtns}>
              <TouchableOpacity onPress={() => setConfirming(false)} style={settingsStyles.cancelBtn}>
                <Text style={settingsStyles.cancelBtnText}>Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity onPress={handleSignOut} style={settingsStyles.signOutBtn}>
                <Text style={settingsStyles.signOutText}>Sign Out</Text>
              </TouchableOpacity>
            </View>
          </View>
        ) : (
          <TouchableOpacity style={settingsStyles.signOutBtn} onPress={() => setConfirming(true)}>
            <Text style={settingsStyles.signOutText}>Sign Out</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  navBar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 8 },
  navTitle: { fontSize: 22, fontWeight: '700', color: Colors.darkBrown },
  gearIcon: { fontSize: 22 },
  profileHeader: { alignItems: 'center', paddingVertical: 20 },
  avatar: {
    width: 90, height: 90, borderRadius: 45,
    backgroundColor: Colors.popcornYellow + '66',
    alignItems: 'center', justifyContent: 'center',
    marginBottom: 12,
  },
  avatarEmoji: { fontSize: 46 },
  username: { fontSize: 22, fontWeight: '700', color: Colors.darkBrown },
  joinDate: { fontSize: 13, color: Colors.subtleGray, marginTop: 4 },
  statsRow: { flexDirection: 'row', justifyContent: 'space-around', paddingHorizontal: 16, marginBottom: 8 },
  statBox: { alignItems: 'center', backgroundColor: '#fff', flex: 1, marginHorizontal: 4, borderRadius: 12, paddingVertical: 12 },
  statValue: { fontSize: 20, fontWeight: '700', color: Colors.darkBrown },
  statLabel: { fontSize: 11, color: Colors.subtleGray, marginTop: 2 },
  section: { marginTop: 20 },
  sectionTitle: { fontSize: 16, fontWeight: '700', color: Colors.darkBrown, marginHorizontal: 16, marginBottom: 10 },
  emptyHint: { fontSize: 13, color: Colors.subtleGray, marginHorizontal: 16 },
  topFilmCard: { position: 'relative' },
  topFilmPoster: { width: 80, height: 115, borderRadius: 8 },
  rankBadge: {
    position: 'absolute', top: 4, left: 4,
    backgroundColor: Colors.warmRed + 'DD', borderRadius: 8,
    paddingHorizontal: 5, paddingVertical: 2,
  },
  rankText: { color: '#fff', fontSize: 10, fontWeight: '700' },
  recentRow: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, marginBottom: 10, gap: 12 },
  recentPoster: { width: 44, height: 62, borderRadius: 6 },
  recentTitle: { fontSize: 14, fontWeight: '500', color: Colors.darkBrown },
  recentMeta: { fontSize: 12, color: Colors.subtleGray, marginTop: 2 },
})

const settingsStyles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, paddingBottom: 16 },
  title: { fontSize: 20, fontWeight: '700', color: Colors.darkBrown },
  done: { fontSize: 16, color: Colors.sepiaBrown, fontWeight: '500' },
  section: { backgroundColor: '#fff', marginHorizontal: 16, borderRadius: 12, marginBottom: 16, overflow: 'hidden' },
  row: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: 14, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: Colors.subtleGray + '44' },
  label: { fontSize: 15, color: Colors.darkBrown },
  value: { fontSize: 14, color: Colors.subtleGray },
  signOutBtn: { marginHorizontal: 16, backgroundColor: Colors.warmRed, borderRadius: 12, paddingVertical: 14, alignItems: 'center', flex: 1 },
  signOutText: { color: '#fff', fontSize: 15, fontWeight: '600' },
  confirmRow: { marginHorizontal: 16, marginTop: 8 },
  confirmText: { fontSize: 15, color: Colors.darkBrown, fontWeight: '600', marginBottom: 10, textAlign: 'center' },
  confirmBtns: { flexDirection: 'row', gap: 10 },
  cancelBtn: { flex: 1, borderRadius: 12, paddingVertical: 14, alignItems: 'center', backgroundColor: Colors.subtleGray + '33', borderWidth: 1, borderColor: Colors.subtleGray + '66' },
  cancelBtnText: { fontSize: 15, fontWeight: '600', color: Colors.darkBrown },
})
