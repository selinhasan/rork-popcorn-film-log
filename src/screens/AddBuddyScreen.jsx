import { useState, useRef } from 'react'
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  FlatList, ActivityIndicator, Alert, Image,
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

    // Search immediately on every keystroke with a short debounce
    searchTimer.current = setTimeout(async () => {
      setIsSearching(true)
      try {
        let query = supabase
        .from('public_user_info')
        .select('user_id, username, profile_pic_url, "Display name"')
        .ilike('username', `%${text.trim()}%`)
        .limit(20)

        if (user?.id) {
          query = query.neq('user_id', user.id)
        }    

        const { data, error } = await query

        console.log('search result:', JSON.stringify({ data, error }))

        if (error) throw error

        setUserResults(data || [])
        } catch (e) {
        console.error('User search error:', e)
        setUserResults([])
        } finally {
        setIsSearching(false)
        }
      }, 150)
    }

  const handleAddBuddy = async (buddy) => {
    setAddingBuddyId(buddy.user_id)
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
      {item.profile_pic_url ? (
        <Image source={{ uri: item.profile_pic_url }} style={styles.avatarCircle} />
      ) : (
        <View style={[styles.avatarCircle, styles.avatarPlaceholder]}>
          <Text style={styles.avatarEmoji}>👤</Text>
        </View>
      )}

      <View style={{ flex: 1 }}>
        {item['Display name'] ? (
          <Text style={styles.displayName} numberOfLines={1}>{item['Display name']}</Text>
        ) : null}
        <Text style={styles.username} numberOfLines={1}>@{item.username}</Text>
      </View>

      <TouchableOpacity
        style={[styles.addBuddyBtn, addingBuddyId === item.user_id && { opacity: 0.5 }]}
        onPress={() => handleAddBuddy(item)}
        disabled={addingBuddyId === item.user_id}
        activeOpacity={0.75}
      >
        {addingBuddyId === item.user_id ? (
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
          keyExtractor={item => `user-${item.user_id}`}
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
  avatarEmoji: { fontSize: 24 },
  displayName: { fontSize: 14, fontWeight: '700', color: Colors.darkBrown },
  username: { fontSize: 13, color: Colors.subtleGray },
  addBuddyBtn: {
    width: 34, height: 34, borderRadius: 17,
    borderWidth: 2, borderColor: Colors.warmRed,
    alignItems: 'center', justifyContent: 'center',
  },
  addBuddyBtnText: { fontSize: 22, lineHeight: 26, color: Colors.warmRed, fontWeight: '600' },
})
