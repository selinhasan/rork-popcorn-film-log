import { useState, useCallback } from 'react'
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  SectionList, Image, Alert,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'

function formatSectionDate(dateStr) {
  const d = new Date(dateStr)
  return d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' }).toUpperCase()
}

function formatDayNumber(dateStr) {
  return new Date(dateStr).getDate().toString()
}

function formatDayName(dateStr) {
  return new Date(dateStr).toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase()
}

function groupEntriesByMonthDay(entries) {
  // group by day
  const dayMap = {}
  for (const entry of entries) {
    const day = new Date(entry.dateWatched).toDateString()
    if (!dayMap[day]) dayMap[day] = { date: entry.dateWatched, entries: [] }
    dayMap[day].entries.push(entry)
  }
  // sort days newest first
  const days = Object.values(dayMap).sort((a, b) => new Date(b.date) - new Date(a.date))

  // group by month
  const monthMap = {}
  for (const day of days) {
    const month = formatSectionDate(day.date)
    if (!monthMap[month]) monthMap[month] = { title: month, data: [] }
    monthMap[month].data.push(day)
  }
  return Object.values(monthMap)
}

function PopcornRating({ rating, isGolden }) {
  const stars = Math.round(rating * 2) / 2
  return (
    <View style={styles.ratingRow}>
      {[1, 2, 3, 4, 5].map(i => (
        <Text key={i} style={[styles.popcornIcon, stars >= i ? styles.ratingFull : styles.ratingEmpty]}>
          {isGolden && i <= stars ? '🍿' : stars >= i ? '🍿' : '·'}
        </Text>
      ))}
      {isGolden && <Text style={styles.goldenBadge}> ★</Text>}
    </View>
  )
}

export default function DiaryScreen({ navigation }) {
  const { diaryEntries, removeEntry } = useApp()
  const insets = useSafeAreaInsets()
  const sections = groupEntriesByMonthDay(diaryEntries)

  const handleLongPress = useCallback((entry) => {
    Alert.alert('Remove Entry', `Remove "${entry.film.title}" from your diary?`, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Remove', style: 'destructive', onPress: () => removeEntry(entry.id) },
    ])
  }, [removeEntry])

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.logo}>🍿</Text>
        <Text style={styles.headerTitle}>Popcorn</Text>
      </View>

      {/* Log Button */}
      <TouchableOpacity
        style={styles.logButton}
        onPress={() => navigation.navigate('LogFilm')}
        activeOpacity={0.85}
      >
        <Text style={styles.logButtonText}>🍿  Log a Film</Text>
      </TouchableOpacity>

      {diaryEntries.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyIcon}>🎬</Text>
          <Text style={styles.emptyTitle}>Your diary is empty</Text>
          <Text style={styles.emptySubtitle}>Tap "Log a Film" to start tracking what you watch!</Text>
        </View>
      ) : (
        <SectionList
          sections={sections}
          keyExtractor={(item, i) => item.date + i}
          stickySectionHeadersEnabled
          contentContainerStyle={{ paddingBottom: 20 }}
          renderSectionHeader={({ section }) => (
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionHeaderText}>{section.title}</Text>
            </View>
          )}
          renderItem={({ item: dayGroup }) => (
            <View style={styles.dayRow}>
              <View style={styles.dayLabel}>
                <Text style={styles.dayNumber}>{formatDayNumber(dayGroup.date)}</Text>
                <Text style={styles.dayName}>{formatDayName(dayGroup.date)}</Text>
              </View>
              <View style={styles.dayEntries}>
                {dayGroup.entries.map(entry => (
                  <TouchableOpacity
                    key={entry.id}
                    style={styles.entryCard}
                    onLongPress={() => handleLongPress(entry)}
                    activeOpacity={0.8}
                  >
                    {entry.film.posterURL ? (
                      <Image source={{ uri: entry.film.posterURL }} style={styles.poster} />
                    ) : (
                      <View style={[styles.poster, styles.posterPlaceholder]}>
                        <Text style={{ fontSize: 20 }}>🎬</Text>
                      </View>
                    )}
                    <View style={styles.entryInfo}>
                      <Text style={styles.entryTitle} numberOfLines={1}>{entry.film.title}</Text>
                      <Text style={styles.entryYear}>{entry.film.year}{entry.film.isTV ? ' · TV' : ''}</Text>
                      <PopcornRating rating={entry.rating} isGolden={entry.isGoldenPopcorn} />
                      {entry.review ? (
                        <Text style={styles.entryReview} numberOfLines={2}>{entry.review}</Text>
                      ) : null}
                    </View>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          )}
        />
      )}
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  header: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingBottom: 8, paddingTop: 4 },
  logo: { fontSize: 28, marginRight: 8 },
  headerTitle: { fontSize: 22, fontWeight: '700', color: Colors.darkBrown },
  logButton: {
    marginHorizontal: 16, marginBottom: 8,
    backgroundColor: Colors.warmRed,
    borderRadius: 16, paddingVertical: 18,
    alignItems: 'center',
    shadowColor: Colors.warmRed, shadowOpacity: 0.35, shadowRadius: 12, shadowOffset: { width: 0, height: 6 },
    elevation: 4,
  },
  logButtonText: { color: '#fff', fontSize: 17, fontWeight: '700' },
  emptyState: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingHorizontal: 32 },
  emptyIcon: { fontSize: 48, marginBottom: 12 },
  emptyTitle: { fontSize: 18, fontWeight: '600', color: Colors.darkBrown, marginBottom: 8 },
  emptySubtitle: { fontSize: 14, color: Colors.sepiaBrown, textAlign: 'center' },
  sectionHeader: {
    backgroundColor: Colors.cream + 'F5',
    paddingHorizontal: 16, paddingVertical: 8,
  },
  sectionHeaderText: { fontSize: 11, fontWeight: '700', color: Colors.sepiaBrown, letterSpacing: 1.5 },
  dayRow: { flexDirection: 'row', paddingHorizontal: 16, paddingTop: 12 },
  dayLabel: { width: 36, alignItems: 'center', paddingTop: 4, marginRight: 12 },
  dayNumber: { fontSize: 22, fontWeight: '700', color: Colors.darkBrown },
  dayName: { fontSize: 10, fontWeight: '600', color: Colors.subtleGray },
  dayEntries: { flex: 1, gap: 10 },
  entryCard: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 12, overflow: 'hidden' },
  poster: { width: 54, height: 78 },
  posterPlaceholder: { backgroundColor: Colors.cardBackground, alignItems: 'center', justifyContent: 'center' },
  entryInfo: { flex: 1, padding: 10, justifyContent: 'center' },
  entryTitle: { fontSize: 14, fontWeight: '600', color: Colors.darkBrown },
  entryYear: { fontSize: 12, color: Colors.subtleGray, marginTop: 2 },
  ratingRow: { flexDirection: 'row', alignItems: 'center', marginTop: 4 },
  popcornIcon: { fontSize: 12, marginRight: 1 },
  ratingFull: { opacity: 1 },
  ratingEmpty: { color: Colors.subtleGray },
  goldenBadge: { fontSize: 12, color: Colors.popcornYellow, fontWeight: '700' },
  entryReview: { fontSize: 12, color: Colors.sepiaBrown, marginTop: 4, fontStyle: 'italic' },
})
