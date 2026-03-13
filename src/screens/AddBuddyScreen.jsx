import { useState, useRef } from 'react'
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  FlatList, ActivityIndicator, Alert,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { useAuth } from '../context/AuthContext'
import { Colors } from '../theme/colors'
import { supabase } from '../lib/supabase'

export default function AddBuddyScreen({ route, navigation, onClose }) {
  const { user } = useAuth()
  const { addBuddy } = useApp()
  const insets = useSafeAreaInsets()

  const handleClose = () => {
    if (onClose) onClose()
    else navigation?.goBack()
  }

  const [searchText, setSearchText] = useState('')
  const [userResults, setUserResults] = useState([])
  const [isSearching, setIsSearching] = useState(false)
  const [addingBuddyId, setAddingBuddyId] = useState(null)

  const searchTimer = useRef(null)

  const handleSearchChange = (text) => {
    setSearchText(text)
    clearTimeout(searchTimer.current)

    if (text.trim().length < 1) {
      setUserResults([])
      return
    }

    searchTimer.current = setTimeout(async () => {
      setIsSearching(true)
      try {
        const { data, error } = await supabase
          .from('public_user_info')
          .select('id, username, profile_image_name')
          .ilike('username', `%${text.trim()}%`)
          .neq('id', user?.id)   // exclude yourself
          .limit(20)

        if (error) throw error

        const normalised = (data || []).map(u => ({
          id: u.id,
          username: u.username,
          profileImageName: u.profile_image_name,
        }))
        setUserResults(normalised)
      } catch (e) {
        console.error('User search error:', e)
        setUserResults([])
      } finally {
        setIsSearching(false)
      }
    }, 300)
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

  const renderUser = ({ item }) => (
    <View style={styles.userRow}>
      <View style={[styles.avatarCircle, styles.avatarPlaceholder]}>
        <Text style={styles.avatarInitial}>
          {(item.username || '?')[0].toUpperCase()}
        </Text>
      </View>
      <View style={{ flex: 1 }}>
        <Text style={styles.listTitle} numberOfLines={1}>
          @{item.username}
        </Text>
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
  userRow: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: '#fff', borderRadius: 12, padding: 10, gap: 12,
  },
  avatarCircle: { width: 50, height: 50, borderRadius: 25, overflow: 'hidden' },
  avatarPlaceholder: { backgroundColor: Colors.cardBackground, alignItems: 'center', justifyContent: 'center' },
  avatarInitial: { fontSize: 20, fontWeight: '700', color: Colors.sepiaBrown },
  listTitle: { fontSize: 14, fontWeight: '600', color: Colors.darkBrown },
  listMeta: { fontSize: 12, color: Colors.subtleGray, marginTop: 2 },
  addBuddyBtn: {
    width: 34, height: 34, borderRadius: 17,
    borderWidth: 2, borderColor: Colors.warmRed,
    alignItems: 'center', justifyContent: 'center',
  },
  addBuddyBtnText: { fontSize: 22, lineHeight: 26, color: Colors.warmRed, fontWeight: '600' },
})
