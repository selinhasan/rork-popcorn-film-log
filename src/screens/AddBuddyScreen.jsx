import { useState, useRef } from 'react'
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  FlatList, Image, ScrollView, ActivityIndicator, Alert,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { useAuth } from '../context/AuthContext'
import { Colors } from '../theme/colors'



export default function LogFilmScreen({ route, navigation, onClose }) {
  const { user } = useAuth()
  const { searchUsers, addBuddy } = useApp()
  const insets = useSafeAreaInsets()

  // Prefer onClose prop (when rendered in a Modal); fall back to navigation.goBack()
  const handleClose = () => {
    if (onClose) onClose()
    else navigation?.goBack()
  }

  // User search state
  const [searchText, setSearchText] = useState('')
  const [userResults, setUserResults] = useState([])
  const [isSearching, setIsSearching] = useState(false)
  const [addingBuddyId, setAddingBuddyId] = useState(null)

  const searchTimer = useRef(null)

  const handleSearchChange = (text) => {
    setSearchText(text)
    clearTimeout(searchTimer.current)
    if (!text.trim()) {
      setUserResults([])
      return
    }
    searchTimer.current = setTimeout(async () => {
      setIsSearching(true)
      try {
        const users = await searchUsers(text)
        setUserResults(users || [])
      } catch {
        setUserResults([])
      } finally {
        setIsSearching(false)
      }
    }, 400)
  }

  const handleAddBuddy = async (buddy) => {
    setAddingBuddyId(buddy.id)
    try {
      await addBuddy(buddy)
    } catch (e) {
      Alert.alert('Error', 'Could not add buddy. Please try again.')
    } finally {
      setAddingBuddyId(null)
    }
  }


  // ── User search view ─────────────────────────────────────────────────────────
  const renderUser = ({ item }) => (
    <View style={styles.userRow}>
      {item.avatarURL ? (
        <Image source={{ uri: item.avatarURL }} style={styles.avatarCircle} />
      ) : (
        <View style={[styles.avatarCircle, styles.avatarPlaceholder]}>
          <Text style={styles.avatarInitial}>
            {(item.username || item.displayName || '?')[0].toUpperCase()}
          </Text>
        </View>
      )}
      <View style={{ flex: 1 }}>
        <Text style={styles.listTitle} numberOfLines={1}>
          {item.displayName || item.username}
        </Text>
        {item.username && (
          <Text style={styles.listMeta}>@{item.username}</Text>
        )}
      </View>
      <TouchableOpacity
        style={[styles.addBuddyBtn, addingBuddyId === item.id && { opacity: 0.5 }]}
        onPress={() => handleAddBuddy(item)}
        disabled={addingBuddyId === item.id}
        activeOpacity={0.75}
      >
        {addingBuddyId === item.id ? (
          <ActivityIndicator size="small" color={Colors.warmRed} />
        ) : (
          <Text style={styles.addBuddyBtnText}>+</Text>
        )}
      </TouchableOpacity>
    </View>
  )

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.topBar}>
        <Text style={styles.screenTitle}>Find Buddies</Text>
        <TouchableOpacity onPress={handleClose}>
          <Text style={styles.cancelText}>Close</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.searchBar}>
        <Text style={styles.searchIcon}>🔍</Text>
        <TextInput
          style={styles.searchInput}
          placeholder="Search by username..."
          placeholderTextColor={Colors.subtleGray}
          value={searchText}
          onChangeText={handleSearchChange}
          autoCapitalize="none"
          autoFocus
        />
        {searchText ? (
          <TouchableOpacity onPress={() => { setSearchText(''); setUserResults([]) }}>
            <Text style={styles.clearBtn}>✕</Text>
          </TouchableOpacity>
        ) : null}
      </View>

      {isSearching ? (
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Colors.warmRed} />
        </View>
      ) : !searchText.trim() ? (
        <View style={styles.centered}>
          <Text style={styles.emptyHint}>Search for friends by username</Text>
        </View>
      ) : userResults.length === 0 ? (
        <View style={styles.centered}>
          <Text style={styles.emptyHint}>No users found</Text>
        </View>
      ) : (
        <FlatList
          data={userResults}
          keyExtractor={item => `user-${item.id}`}
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{ padding: 16, gap: 10 }}
          renderItem={renderUser}
        />
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  topBar: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: 16, paddingBottom: 8,
  },
  screenTitle: { fontSize: 20, fontWeight: '700', color: Colors.darkBrown },
  cancelText: { fontSize: 15, color: Colors.sepiaBrown },
  backBtn: {},
  backBtnText: { fontSize: 15, color: Colors.sepiaBrown },
  searchBar: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: '#fff', borderRadius: 12,
    marginHorizontal: 16, marginBottom: 8, paddingHorizontal: 12,
  },
  searchIcon: { fontSize: 16, marginRight: 8 },
  searchInput: { flex: 1, paddingVertical: 12, fontSize: 15, color: Colors.darkBrown },
  clearBtn: { fontSize: 14, color: Colors.subtleGray, paddingLeft: 8 },
  centered: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  emptyHint: { fontSize: 14, color: Colors.subtleGray },
  // User row
  userRow: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: '#fff', borderRadius: 12, padding: 10, gap: 12,
  },
  avatarCircle: { width: 50, height: 50, borderRadius: 25, overflow: 'hidden' },
  avatarPlaceholder: { backgroundColor: Colors.cardBackground, alignItems: 'center', justifyContent: 'center' },
  avatarInitial: { fontSize: 20, fontWeight: '700', color: Colors.sepiaBrown },
  listTitle: { fontSize: 14, fontWeight: '600', color: Colors.darkBrown },
  listMeta: { fontSize: 12, color: Colors.subtleGray, marginTop: 2 },
  // Add buddy button
  addBuddyBtn: {
    width: 34, height: 34, borderRadius: 17,
    borderWidth: 2, borderColor: Colors.warmRed,
    alignItems: 'center', justifyContent: 'center',
  },
  addBuddyBtnText: { fontSize: 22, lineHeight: 26, color: Colors.warmRed, fontWeight: '600' },
  // Film detail view
  filmRow: { flexDirection: 'row', gap: 14, marginBottom: 24 },
  filmPoster: { width: 80, height: 115, borderRadius: 10 },
  filmTitle: { fontSize: 18, fontWeight: '700', color: Colors.darkBrown },
  filmMeta: { fontSize: 13, color: Colors.subtleGray, marginTop: 4 },
  filmGenre: { fontSize: 12, color: Colors.sepiaBrown, marginTop: 4 },
  formSection: { marginBottom: 20 },
  formLabel: { fontSize: 14, fontWeight: '600', color: Colors.sepiaBrown, marginBottom: 8 },
  dateInput: {
    backgroundColor: '#fff', borderRadius: 10, padding: 12,
    fontSize: 15, color: Colors.darkBrown,
    borderWidth: 1, borderColor: Colors.subtleGray + '44',
  },
  reviewInput: {
    backgroundColor: '#fff', borderRadius: 10, padding: 12,
    fontSize: 15, color: Colors.darkBrown, minHeight: 100,
    borderWidth: 1, borderColor: Colors.subtleGray + '44',
  },
  saveBtn: {
    backgroundColor: Colors.warmRed, borderRadius: 12,
    paddingVertical: 16, alignItems: 'center', marginTop: 8,
  },
  saveBtnText: { color: '#fff', fontSize: 16, fontWeight: '700' },
})

const ratingStyles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center' },
  popcorn: { fontSize: 28, marginRight: 6 },
  filled: { opacity: 1 },
  empty: { opacity: 0.25 },
  clear: { fontSize: 13, color: Colors.sepiaBrown, marginLeft: 4 },
})
