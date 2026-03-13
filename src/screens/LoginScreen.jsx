import { useState, useRef, useEffect } from 'react'
import {
  View, Text, TextInput, TouchableOpacity, StyleSheet,
  FlatList, Image, ScrollView, ActivityIndicator, Alert,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { useAuth } from '../context/AuthContext'
import { Colors } from '../theme/colors'

function StarRating({ rating, onChange }) {
  return (
    <View style={ratingStyles.row}>
      {[1, 2, 3, 4, 5].map(i => (
        <TouchableOpacity key={i} onPress={() => onChange(i)} activeOpacity={0.7}>
          <Text style={[ratingStyles.popcorn, i <= rating ? ratingStyles.filled : ratingStyles.empty]}>🍿</Text>
        </TouchableOpacity>
      ))}
      {rating > 0 && (
        <TouchableOpacity onPress={() => onChange(0)} style={{ marginLeft: 8 }}>
          <Text style={ratingStyles.clear}>Clear</Text>
        </TouchableOpacity>
      )}
    </View>
  )
}

export default function LogFilmScreen({ route, navigation }) {
  const { user } = useAuth()
  const { trendingFilms, searchResults, isSearching, searchFilms, setSearchResults, logFilm } = useApp()
  const insets = useSafeAreaInsets()

  const [searchText, setSearchText] = useState('')
  const [selectedFilm, setSelectedFilm] = useState(route.params?.preselectedFilm || null)
  const [rating, setRating] = useState(0)
  const [review, setReview] = useState('')
  const [watchDate, setWatchDate] = useState(new Date().toISOString().slice(0, 10))
  const [isSaving, setIsSaving] = useState(false)

  const searchTimer = useRef(null)

  const filmsToShow = searchText.trim() ? searchResults : trendingFilms

  const handleSearchChange = (text) => {
    setSearchText(text)
    clearTimeout(searchTimer.current)
    if (!text.trim()) { setSearchResults([]); return }
    searchTimer.current = setTimeout(() => searchFilms(text), 400)
  }

  const handleSave = async () => {
    if (!selectedFilm) return
    setIsSaving(true)
    try {
      const entry = {
        id: Date.now().toString() + Math.random().toString(36).slice(2),
        film: selectedFilm,          // kept locally (poster, genre, etc.)
        rating: Math.round(rating),  // smallint in Supabase
        review: review.trim(),
        dateWatched: watchDate,      // 'YYYY-MM-DD' – maps to watched_date
        userId: user?.id || '',
      }
      await logFilm(entry)
      // Navigate back immediately — diary reflects optimistic update already
      navigation.goBack()
    } catch (e) {
      Alert.alert('Error', 'Could not save entry. Please try again.')
    } finally {
      setIsSaving(false)
    }
  }

  if (selectedFilm) {
    return (
      <View style={[styles.container, { paddingTop: insets.top }]}>
        <View style={styles.topBar}>
          <TouchableOpacity onPress={() => setSelectedFilm(null)} style={styles.backBtn}>
            <Text style={styles.backBtnText}>← Change Film</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => navigation.goBack()}>
            <Text style={styles.cancelText}>Cancel</Text>
          </TouchableOpacity>
        </View>

        <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 40 }}>
          {/* Film info */}
          <View style={styles.filmRow}>
            {selectedFilm.posterURL ? (
              <Image source={{ uri: selectedFilm.posterURL }} style={styles.filmPoster} />
            ) : (
              <View style={[styles.filmPoster, { backgroundColor: Colors.cardBackground }]} />
            )}
            <View style={{ flex: 1 }}>
              <Text style={styles.filmTitle}>{selectedFilm.title}</Text>
              <Text style={styles.filmMeta}>{selectedFilm.year}{selectedFilm.isTV ? ' · TV' : ''}</Text>
              {selectedFilm.genre?.length > 0 && (
                <Text style={styles.filmGenre}>{selectedFilm.genre.slice(0, 2).join(', ')}</Text>
              )}
            </View>
          </View>

          {/* Rating */}
          <View style={styles.formSection}>
            <Text style={styles.formLabel}>Rating</Text>
            <StarRating rating={rating} onChange={setRating} />
          </View>

          {/* Date */}
          <View style={styles.formSection}>
            <Text style={styles.formLabel}>Date Watched</Text>
            <TextInput
              style={styles.dateInput}
              value={watchDate}
              onChangeText={setWatchDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={Colors.subtleGray}
            />
          </View>

          {/* Review */}
          <View style={styles.formSection}>
            <Text style={styles.formLabel}>Review (optional)</Text>
            <TextInput
              style={styles.reviewInput}
              placeholder="What did you think?"
              placeholderTextColor={Colors.subtleGray}
              value={review}
              onChangeText={setReview}
              multiline
              textAlignVertical="top"
            />
          </View>

          <TouchableOpacity
            style={[styles.saveBtn, isSaving && { opacity: 0.7 }]}
            onPress={handleSave}
            disabled={isSaving}
            activeOpacity={0.85}
          >
            {isSaving ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <Text style={styles.saveBtnText}>🍿  Save to Diary</Text>
            )}
          </TouchableOpacity>
        </ScrollView>
      </View>
    )
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.topBar}>
        <Text style={styles.screenTitle}>Log a Film</Text>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Text style={styles.cancelText}>Cancel</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.searchBar}>
        <Text style={styles.searchIcon}>🔍</Text>
        <TextInput
          style={styles.searchInput}
          placeholder="Search films & TV shows..."
          placeholderTextColor={Colors.subtleGray}
          value={searchText}
          onChangeText={handleSearchChange}
          autoCapitalize="none"
          autoFocus
        />
        {searchText ? (
          <TouchableOpacity onPress={() => { setSearchText(''); setSearchResults([]) }}>
            <Text style={styles.clearBtn}>✕</Text>
          </TouchableOpacity>
        ) : null}
      </View>

      {!searchText.trim() && (
        <Text style={styles.sectionLabel}>Popular right now</Text>
      )}

      {isSearching ? (
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Colors.warmRed} />
        </View>
      ) : (
        <FlatList
          data={filmsToShow}
          keyExtractor={item => item.id}
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{ padding: 16, gap: 10 }}
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.filmListRow} onPress={() => setSelectedFilm(item)} activeOpacity={0.8}>
              {item.posterURL ? (
                <Image source={{ uri: item.posterURL }} style={styles.listPoster} />
              ) : (
                <View style={[styles.listPoster, { backgroundColor: Colors.cardBackground }]} />
              )}
              <View style={{ flex: 1 }}>
                <Text style={styles.listTitle} numberOfLines={2}>{item.title}</Text>
                <Text style={styles.listMeta}>{item.year}{item.isTV ? ' · TV' : ''}</Text>
                {item.genre?.length > 0 && (
                  <Text style={styles.listGenre}>{item.genre.slice(0, 2).join(', ')}</Text>
                )}
              </View>
              {item.averageRating > 0 && (
                <Text style={styles.listRating}>🍿 {item.averageRating.toFixed(1)}</Text>
              )}
            </TouchableOpacity>
          )}
        />
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  topBar: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, paddingBottom: 8 },
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
  sectionLabel: { fontSize: 15, fontWeight: '600', color: Colors.darkBrown, paddingHorizontal: 16, marginBottom: 4 },
  centered: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  filmListRow: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#fff', borderRadius: 12, padding: 10, gap: 12 },
  listPoster: { width: 50, height: 70, borderRadius: 6 },
  listTitle: { fontSize: 14, fontWeight: '600', color: Colors.darkBrown },
  listMeta: { fontSize: 12, color: Colors.subtleGray, marginTop: 2 },
  listGenre: { fontSize: 11, color: Colors.sepiaBrown, marginTop: 2 },
  listRating: { fontSize: 12, color: Colors.sepiaBrown, fontWeight: '600' },
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
