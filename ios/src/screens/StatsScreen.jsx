import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
} from 'react-native'

import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'


export default function StatsScreen({ navigation }) {
  const insets = useSafeAreaInsets()

  const {
    diaryEntries = [],
  } = useApp()

  const currentYear =
    new Date().getFullYear()

  const entriesThisYear =
    diaryEntries.filter(entry => {
      const year =
        String(
          entry.dateWatched || ''
        ).slice(0, 4)

      return year === String(currentYear)
    })


  const genreCounts = {}

  entriesThisYear.forEach(entry => {
    const genres =
      entry.film?.genre || []

    genres.forEach(genre => {
      if (!genre) return

      genreCounts[genre] =
        (genreCounts[genre] || 0) + 1
    })
  })


  const sortedGenres =
    Object.entries(genreCounts)
      .sort((a, b) => {
        if (b[1] !== a[1]) {
          return b[1] - a[1]
        }

        return a[0].localeCompare(b[0])
      })


  return (
    <View
      style={[
        styles.container,
        {
          paddingTop: insets.top,
        },
      ]}
    >
      <View style={styles.header}>
        <TouchableOpacity
          onPress={() =>
            navigation.goBack()
          }
        >
          <Text style={styles.back}>
            ‹ Profile
          </Text>
        </TouchableOpacity>

        <Text style={styles.title}>
          Stats
        </Text>

        <View style={{ width: 65 }} />
      </View>


      <ScrollView
        contentContainerStyle={
          styles.content
        }
      >
        <Text style={styles.year}>
          {currentYear}
        </Text>

        <Text style={styles.subtitle}>
          Films watched by genre
        </Text>


        <View style={styles.totalCard}>
          <Text style={styles.totalNumber}>
            {entriesThisYear.length}
          </Text>

          <Text style={styles.totalLabel}>
            films logged this year
          </Text>
        </View>


        {sortedGenres.length > 0 ? (
          sortedGenres.map(
            ([genre, count]) => (
              <View
                key={genre}
                style={styles.genreRow}
              >
                <Text style={styles.genreName}>
                  {genre}
                </Text>

                <Text style={styles.genreCount}>
                  {count}
                </Text>
              </View>
            )
          )
        ) : (
          <Text style={styles.emptyText}>
            No genre data for {currentYear} yet.
          </Text>
        )}
      </ScrollView>
    </View>
  )
}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: Colors.cream,
  },

  header: {
    height: 52,
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },

  back: {
    width: 65,
    fontSize: 15,
    color: Colors.sepiaBrown,
  },

  title: {
    flex: 1,
    textAlign: 'center',
    fontSize: 19,
    fontWeight: '700',
    color: Colors.darkBrown,
  },

  content: {
    padding: 16,
    paddingBottom: 50,
  },

  year: {
    fontSize: 32,
    fontWeight: '800',
    color: Colors.darkBrown,
  },

  subtitle: {
    fontSize: 15,
    color: Colors.subtleGray,
    marginTop: 2,
    marginBottom: 20,
  },

  totalCard: {
    backgroundColor: Colors.warmRed,
    borderRadius: 16,
    alignItems: 'center',
    paddingVertical: 22,
    marginBottom: 20,
  },

  totalNumber: {
    color: '#fff',
    fontSize: 34,
    fontWeight: '800',
  },

  totalLabel: {
    color: '#fff',
    marginTop: 3,
    fontSize: 13,
  },

  genreRow: {
    backgroundColor: '#fff',
    borderRadius: 12,
    paddingHorizontal: 15,
    paddingVertical: 15,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },

  genreName: {
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
    color: Colors.darkBrown,
  },

  genreCount: {
    fontSize: 18,
    fontWeight: '800',
    color: Colors.warmRed,
  },

  emptyText: {
    color: Colors.subtleGray,
    fontSize: 14,
  },
})
