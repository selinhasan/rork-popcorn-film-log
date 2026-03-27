import { useState, useEffect, useRef, useCallback } from 'react'
import {
  View, Text, ScrollView, FlatList, TextInput, TouchableOpacity,
  StyleSheet, Image, ActivityIndicator, Modal, Pressable,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'

const SORT_OPTIONS = [
  { label: 'Popular', value: 'popularity.desc' },
  { label: 'Top Rated', value: 'vote_average.desc' },
  { label: 'Newest', value: 'primary_release_date.desc' },
]

function FilmCard({ film, onPress }) {
  return (
    <TouchableOpacity style={cardStyles.card} onPress={() => onPress(film)} activeOpacity={0.85}>
      {film.posterURL ? (
        <Image source={{ uri: film.posterURL }} style={cardStyles.poster} />
      ) : (
        <View style={[cardStyles.poster, cardStyles.posterPlaceholder]}>
          <Text style={{ fontSize: 24 }}>🎬</Text>
        </View>
      )}
      {film.isTV && (
        <View style={cardStyles.tvBadge}><Text style={cardStyles.tvText}>TV</Text></View>
      )}
      <Text style={cardStyles.title} numberOfLines={1}>{film.title}</Text>
      <View style={cardStyles.meta}>
        <Text style={cardStyles.metaText}>{film.year}</Text>
        {film.averageRating > 0 && (
          <Text style={cardStyles.rating}>🍿 {film.averageRating.toFixed(1)}</Text>
        )}
      </View>
    </TouchableOpacity>
  )
}

function FilmDetailModal({ film, visible, onClose, onLog }) {
  const { addToWatchlist, removeFromWatchlist, isInWatchlist, fetchFilmDetail } = useApp()
  const [detail, setDetail] = useState(null)

  useEffect(() => {
    if (!film || !visible) return
    setDetail(null)
    fetchFilmDetail(film.id).then(d => { if (d) setDetail(d) })
  }, [film?.id, visible])

  const display = detail || film
  const inWatchlist = film ? isInWatchlist(film.id) : false

  if (!film) return null

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet" onRequestClose={onClose}>
      <View style={modalStyles.container}>
        <View style={modalStyles.dragHandle} />
        <ScrollView>
          <View style={modalStyles.posterHero}>
            {display.posterURL ? (
              <Image source={{ uri: display.posterURL }} style={modalStyles.heroPoster} resizeMode="cover" />
            ) : (
              <View style={[modalStyles.heroPoster, { backgroundColor: Colors.cardBackground }]} />
            )}
            <View style={modalStyles.heroGradient} />
          </View>

          <View style={modalStyles.content}>
            <Text style={modalStyles.title}>{display.title}</Text>
            <Text style={modalStyles.meta}>
              {[display.year, display.runtime, display.director].filter(Boolean).join(' · ')}
            </Text>
            {display.averageRating > 0 && (
              <Text style={modalStyles.rating}>🍿 {display.averageRating.toFixed(1)} avg from TMDb</Text>
            )}

            {display.genre?.length > 0 && (
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 12 }}>
                {display.genre.map(g => (
                  <View key={g} style={modalStyles.genreChip}>
                    <Text style={modalStyles.genreText}>{g}</Text>
                  </View>
                ))}
              </ScrollView>
            )}

            {display.synopsis ? (
              <Text style={modalStyles.synopsis}>{display.synopsis}</Text>
            ) : null}

            {display.cast?.length > 0 && (
              <View style={{ marginTop: 12 }}>
                <Text style={modalStyles.sectionLabel}>Cast</Text>
                <Text style={modalStyles.castText}>{display.cast.join(', ')}</Text>
              </View>
            )}

            <TouchableOpacity style={modalStyles.logBtn} onPress={() => onLog(display)} activeOpacity={0.85}>
              <Text style={modalStyles.logBtnText}>🍿  Log This Film</Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[modalStyles.watchlistBtn, inWatchlist && modalStyles.watchlistBtnActive]}
              onPress={() => inWatchlist ? removeFromWatchlist(film.id) : addToWatchlist(film)}
              activeOpacity={0.85}
            >
              <Text style={[modalStyles.watchlistBtnText, inWatchlist && { color: '#fff' }]}>
                {inWatchlist ? '🔖 On Watchlist' : '🔖 Add to Watchlist'}
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>

        <TouchableOpacity style={modalStyles.closeBtn} onPress={onClose}>
          <Text style={modalStyles.closeBtnText}>✕</Text>
        </TouchableOpacity>
      </View>
    </Modal>
  )
}

export default function BrowseScreen({ navigation }) {
  const { trendingFilms, popularFilms, searchResults, genres, isLoadingTMDb, isSearching, searchFilms, discoverFilms, setSearchResults } = useApp()
  const insets = useSafeAreaInsets()

  const [searchText, setSearchText] = useState('')
  const [selectedGenre, setSelectedGenre] = useState(null)
  const [sortBy, setSortBy] = useState('popularity.desc')
  const [displayedFilms, setDisplayedFilms] = useState([])
  const [isLoadingDiscover, setIsLoadingDiscover] = useState(false)
  const [selectedFilm, setSelectedFilm] = useState(null)
  const searchTimer = useRef(null)

  useEffect(() => {
    if (trendingFilms.length > 0 && displayedFilms.length === 0) {
      setDisplayedFilms(trendingFilms)
    }
  }, [trendingFilms])

  useEffect(() => {
    if (searchText.trim()) return
    loadFilms()
  }, [selectedGenre, sortBy])

  const loadFilms = useCallback(async () => {
    if (searchText.trim()) return
    setIsLoadingDiscover(true)
    const films = await discoverFilms(selectedGenre?.id, sortBy)
    setDisplayedFilms(films.length > 0 ? films : trendingFilms)
    setIsLoadingDiscover(false)
  }, [selectedGenre, sortBy, searchText, trendingFilms])

  const handleSearchChange = (text) => {
    setSearchText(text)
    clearTimeout(searchTimer.current)
    if (!text.trim()) { setSearchResults([]); return }
    searchTimer.current = setTimeout(() => searchFilms(text), 400)
  }

  const filmsToShow = searchText.trim() ? searchResults : displayedFilms
  const isLoading = isLoadingTMDb || isLoadingDiscover

  const handleLogFilm = (film) => {
    setSelectedFilm(null)
    navigation.navigate('LogFilm', { preselectedFilm: film })
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Search bar */}
      <View style={styles.searchBar}>
        <Text style={styles.searchIcon}>🔍</Text>
        <TextInput
          style={styles.searchInput}
          placeholder="Search films & shows"
          placeholderTextColor={Colors.subtleGray}
          value={searchText}
          onChangeText={handleSearchChange}
          autoCapitalize="none"
          returnKeyType="search"
        />
        {searchText ? (
          <TouchableOpacity onPress={() => { setSearchText(''); setSearchResults([]) }}>
            <Text style={styles.clearBtn}>✕</Text>
          </TouchableOpacity>
        ) : null}
      </View>

      {/* Genre chips */}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.genreScroll}
        contentContainerStyle={{ paddingHorizontal: 16, gap: 8 }}
      >
        <TouchableOpacity
          style={[styles.chip, !selectedGenre && styles.chipActive]}
          onPress={() => setSelectedGenre(null)}
        >
          <Text style={[styles.chipText, !selectedGenre && styles.chipTextActive]}>All</Text>
        </TouchableOpacity>
        {genres.map(g => (
          <TouchableOpacity
            key={g.id}
            style={[styles.chip, selectedGenre?.id === g.id && styles.chipActive]}
            onPress={() => setSelectedGenre(g)}
          >
            <Text style={[styles.chipText, selectedGenre?.id === g.id && styles.chipTextActive]}>{g.name}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Sort picker */}
      {!searchText.trim() && (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ paddingHorizontal: 16, gap: 8, paddingVertical: 6 }}
        >
          {SORT_OPTIONS.map(opt => (
            <TouchableOpacity
              key={opt.value}
              style={[styles.sortChip, sortBy === opt.value && styles.sortChipActive]}
              onPress={() => setSortBy(opt.value)}
            >
              <Text style={[styles.sortChipText, sortBy === opt.value && styles.sortChipTextActive]}>{opt.label}</Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      )}

      {/* Film grid */}
      {isLoading || isSearching ? (
        <View style={styles.centered}>
          <ActivityIndicator size="large" color={Colors.warmRed} />
        </View>
      ) : searchText.trim() && filmsToShow.length === 0 ? (
        <View style={styles.centered}>
          <Text style={styles.emptyText}>No results for "{searchText}"</Text>
        </View>
      ) : (
        <FlatList
          data={filmsToShow}
          keyExtractor={item => item.id}
          numColumns={2}
          columnWrapperStyle={{ gap: 12, paddingHorizontal: 16 }}
          contentContainerStyle={{ gap: 14, paddingBottom: 20, paddingTop: 4 }}
          renderItem={({ item }) => <FilmCard film={item} onPress={setSelectedFilm} />}
        />
      )}

      <FilmDetailModal
        film={selectedFilm}
        visible={!!selectedFilm}
        onClose={() => setSelectedFilm(null)}
        onLog={handleLogFilm}
      />
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  searchBar: {
    flexDirection: 'row', alignItems: 'center',
    backgroundColor: '#fff', borderRadius: 12,
    marginHorizontal: 16, marginBottom: 10, paddingHorizontal: 12,
    shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, elevation: 2,
  },
  searchIcon: { fontSize: 16, marginRight: 8 },
  searchInput: { flex: 1, paddingVertical: 12, fontSize: 15, color: Colors.darkBrown },
  clearBtn: { fontSize: 14, color: Colors.subtleGray, paddingLeft: 8 },
  genreScroll: { flexGrow: 0, marginBottom: 4 },
  chip: {
    paddingHorizontal: 14, paddingVertical: 7,
    borderRadius: 20, backgroundColor: '#fff',
    borderWidth: 1, borderColor: Colors.sepiaBrown + '33',
  },
  chipActive: { backgroundColor: Colors.warmRed, borderColor: Colors.warmRed },
  chipText: { fontSize: 13, fontWeight: '500', color: Colors.darkBrown },
  chipTextActive: { color: '#fff' },
  sortChip: {
    paddingHorizontal: 12, paddingVertical: 5,
    borderRadius: 16, backgroundColor: Colors.cardBackground,
  },
  sortChipActive: { backgroundColor: Colors.darkBrown },
  sortChipText: { fontSize: 12, color: Colors.sepiaBrown, fontWeight: '500' },
  sortChipTextActive: { color: '#fff' },
  centered: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  emptyText: { color: Colors.subtleGray, fontSize: 15 },
})

const cardStyles = StyleSheet.create({
  card: { flex: 1 },
  poster: { width: '100%', aspectRatio: 2 / 3, borderRadius: 12, backgroundColor: Colors.cardBackground },
  posterPlaceholder: { alignItems: 'center', justifyContent: 'center' },
  tvBadge: {
    position: 'absolute', top: 6, right: 6,
    backgroundColor: Colors.freshGreen, borderRadius: 10,
    paddingHorizontal: 6, paddingVertical: 2,
  },
  tvText: { color: '#fff', fontSize: 10, fontWeight: '700' },
  title: { fontSize: 13, fontWeight: '600', color: Colors.darkBrown, marginTop: 6 },
  meta: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 2 },
  metaText: { fontSize: 11, color: Colors.subtleGray },
  rating: { fontSize: 11, color: Colors.sepiaBrown, fontWeight: '600' },
})

const modalStyles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  dragHandle: { width: 36, height: 4, backgroundColor: Colors.subtleGray, borderRadius: 2, alignSelf: 'center', marginTop: 8 },
  posterHero: { height: 360, position: 'relative' },
  heroPoster: { width: '100%', height: '100%' },
  heroGradient: {
    position: 'absolute', bottom: 0, left: 0, right: 0, height: 200,
    backgroundColor: 'transparent',
  },
  content: { padding: 16, paddingTop: 0 },
  title: { fontSize: 22, fontWeight: '700', color: Colors.darkBrown, textAlign: 'center', marginTop: -16 },
  meta: { fontSize: 14, color: Colors.sepiaBrown, textAlign: 'center', marginTop: 4 },
  rating: { fontSize: 13, color: Colors.sepiaBrown, textAlign: 'center', marginTop: 4 },
  genreChip: {
    backgroundColor: Colors.popcornYellow + '55', borderRadius: 20,
    paddingHorizontal: 10, paddingVertical: 4, marginRight: 6,
  },
  genreText: { fontSize: 12, fontWeight: '500', color: Colors.darkBrown },
  synopsis: { fontSize: 14, color: Colors.sepiaBrown, lineHeight: 20, marginTop: 14 },
  sectionLabel: { fontSize: 15, fontWeight: '700', color: Colors.darkBrown, marginBottom: 4 },
  castText: { fontSize: 13, color: Colors.sepiaBrown },
  logBtn: {
    backgroundColor: Colors.warmRed, borderRadius: 12,
    paddingVertical: 14, alignItems: 'center', marginTop: 20,
  },
  logBtnText: { color: '#fff', fontSize: 15, fontWeight: '600' },
  watchlistBtn: {
    backgroundColor: '#fff', borderRadius: 12, borderWidth: 1,
    borderColor: Colors.sepiaBrown + '33',
    paddingVertical: 14, alignItems: 'center', marginTop: 10,
  },
  watchlistBtnActive: { backgroundColor: Colors.freshGreen, borderColor: Colors.freshGreen },
  watchlistBtnText: { fontSize: 15, fontWeight: '500', color: Colors.darkBrown },
  closeBtn: {
    position: 'absolute', top: 12, right: 16,
    backgroundColor: Colors.cardBackground, borderRadius: 16,
    width: 32, height: 32, alignItems: 'center', justifyContent: 'center',
  },
  closeBtnText: { fontSize: 14, color: Colors.sepiaBrown, fontWeight: '600' },
})
