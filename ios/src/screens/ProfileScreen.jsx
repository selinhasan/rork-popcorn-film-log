import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Image,
  FlatList,
} from 'react-native'

import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useAuth } from '../context/AuthContext'
import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'


function getCurrentYear() {
  return new Date().getFullYear()
}


function isInYear(dateValue, year) {
  if (!dateValue) return false

  const yearFromString = String(dateValue).slice(0, 4)

  return yearFromString === String(year)
}


function FilmPoster({ film, size = 'normal' }) {
  const width = size === 'small' ? 58 : 72
  const height = size === 'small' ? 86 : 106

  return (
    <View style={{ width }}>
      {film?.posterURL ? (
        <Image
          source={{ uri: film.posterURL }}
          style={{
            width,
            height,
            borderRadius: 8,
            backgroundColor: Colors.cardBackground,
          }}
        />
      ) : (
        <View
          style={{
            width,
            height,
            borderRadius: 8,
            backgroundColor: Colors.cardBackground,
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Text style={{ fontSize: 24 }}>🎬</Text>
        </View>
      )}

      <Text
        numberOfLines={2}
        style={styles.posterTitle}
      >
        {film?.title || 'Unknown'}
      </Text>
    </View>
  )
}


function SectionTitle({ children }) {
  return (
    <Text style={styles.sectionTitle}>
      {children}
    </Text>
  )
}


export default function ProfileScreen({ navigation }) {
  const insets = useSafeAreaInsets()

  const { user } = useAuth()

  const app = useApp()

  const {
    diaryEntries = [],
    topFive = [],
    watchlist = [],
  } = app

  // These won't crash if your AppContext does not expose them yet.
  const lists = app.lists || []
  const buddies = app.buddies || []

  const metadata = user?.user_metadata || {}

  const displayName =
    metadata.display_name ||
    metadata.full_name ||
    metadata.name ||
    metadata.username ||
    'Film Lover'

  const rawUsername =
    metadata.username || 'username'

  const username =
    rawUsername.startsWith('@')
      ? rawUsername
      : `@${rawUsername}`

  const profilePicture =
    metadata.avatar_url ||
    metadata.profile_picture ||
    ''

  const currentYear = getCurrentYear()

  const thisYearEntries = diaryEntries.filter(entry =>
    isInYear(entry.dateWatched, currentYear)
  )

  const reviewedEntries = diaryEntries.filter(
    entry => entry.review?.trim()
  )

  const recentActivity = [...diaryEntries]
    .sort(
      (a, b) =>
        new Date(b.dateWatched) -
        new Date(a.dateWatched)
    )
    .slice(0, 5)

  const recentReviews = [...reviewedEntries]
    .sort(
      (a, b) =>
        new Date(b.dateWatched) -
        new Date(a.dateWatched)
    )
    .slice(0, 4)

  const goldenPopcornEntries = diaryEntries
    .filter(entry => entry.isGoldenPopcorn)
    .slice(0, 5)


  function goToRootScreen(screenName) {
    const parent = navigation.getParent()

    if (parent) {
      parent.navigate(screenName)
    } else {
      navigation.navigate(screenName)
    }
  }


  return (
    <View
      style={[
        styles.container,
        {
          paddingTop: insets.top,
        },
      ]}
    >
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{
          paddingBottom: 100,
        }}
      >

        {/* HEADER */}

        <View style={styles.header}>
          <View style={styles.headerSpacer} />

          <Text style={styles.headerTitle}>
            Profile
          </Text>

          <TouchableOpacity
            style={styles.settingsButton}
            onPress={() =>
              goToRootScreen('Settings')
            }
          >
            <Text style={styles.settingsIcon}>
              ⚙︎
            </Text>
          </TouchableOpacity>
        </View>


        {/* USER */}

        <View style={styles.profileHeader}>
          {profilePicture ? (
            <Image
              source={{
                uri: profilePicture,
              }}
              style={styles.avatar}
            />
          ) : (
            <View
              style={[
                styles.avatar,
                styles.avatarPlaceholder,
              ]}
            >
              <Text style={styles.avatarEmoji}>
                🍿
              </Text>
            </View>
          )}

          <Text style={styles.displayName}>
            {displayName}
          </Text>

          <Text style={styles.username}>
            {username}
          </Text>
        </View>


        {/* TOP FIVE */}

        <View style={styles.section}>
          <SectionTitle>Top 5 Films</SectionTitle>

          {topFive.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.horizontalRow}
            >
              {topFive.slice(0, 5).map((film, index) => (
                <View
                  key={`${film.id}-${index}`}
                  style={styles.posterItem}
                >
                  <FilmPoster film={film} />
                </View>
              ))}
            </ScrollView>
          ) : (
            <Text style={styles.emptyText}>
              No favourite films selected yet.
            </Text>
          )}
        </View>


        {/* GOLDEN POPCORN */}

        <View style={styles.section}>
          <SectionTitle>Golden Popcorn</SectionTitle>

          {goldenPopcornEntries.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.horizontalRow}
            >
              {goldenPopcornEntries.map(entry => (
                <View
                  key={entry.id}
                  style={styles.posterItem}
                >
                  <FilmPoster film={entry.film} />
                </View>
              ))}
            </ScrollView>
          ) : (
            <View style={styles.emptyCard}>
              <Text style={styles.goldenIcon}>
                🍿
              </Text>

              <Text style={styles.emptyText}>
                No Golden Popcorn films yet.
              </Text>
            </View>
          )}
        </View>


        {/* RECENT ACTIVITY */}

        <View style={styles.section}>
          <SectionTitle>Recent Activity</SectionTitle>

          {recentActivity.length > 0 ? (
            recentActivity.map(entry => (
              <TouchableOpacity
                key={entry.id}
                style={styles.activityRow}
                onPress={() =>
                  goToRootScreen('LogFilm', {
                    editEntry: entry,
                  })
                }
              >
                {entry.film?.posterURL ? (
                  <Image
                    source={{
                      uri: entry.film.posterURL,
                    }}
                    style={styles.activityPoster}
                  />
                ) : (
                  <View
                    style={[
                      styles.activityPoster,
                      styles.posterPlaceholder,
                    ]}
                  >
                    <Text>🎬</Text>
                  </View>
                )}

                <View style={styles.activityInfo}>
                  <Text
                    style={styles.activityTitle}
                    numberOfLines={1}
                  >
                    {entry.film?.title}
                  </Text>

                  <Text style={styles.activityDate}>
                    {entry.dateWatched}
                  </Text>

                  <Text style={styles.activityRating}>
                    {'🍿'.repeat(
                      Math.max(
                        0,
                        Math.round(entry.rating || 0)
                      )
                    )}
                  </Text>
                </View>

                <Text style={styles.chevron}>
                  ›
                </Text>
              </TouchableOpacity>
            ))
          ) : (
            <Text style={styles.emptyText}>
              No activity yet.
            </Text>
          )}
        </View>


        {/* FILM COUNTS */}

        <View style={styles.section}>
          <View style={styles.statRow}>
            <View style={styles.statCard}>
              <Text style={styles.statNumber}>
                {thisYearEntries.length}
              </Text>

              <Text style={styles.statLabel}>
                Films in {currentYear}
              </Text>
            </View>

            <View style={styles.statCard}>
              <Text style={styles.statNumber}>
                {diaryEntries.length}
              </Text>

              <Text style={styles.statLabel}>
                Films total
              </Text>
            </View>
          </View>

          <TouchableOpacity
            style={styles.statsButton}
            onPress={() =>
              goToRootScreen('Stats')
            }
          >
            <Text style={styles.statsButtonText}>
              View Stats
            </Text>

            <Text style={styles.statsArrow}>
              ›
            </Text>
          </TouchableOpacity>
        </View>


        {/* REVIEWS */}

        <View style={styles.section}>
          <View style={styles.sectionTitleRow}>
            <SectionTitle>Reviews</SectionTitle>

            <Text style={styles.reviewCount}>
              {reviewedEntries.length}
            </Text>
          </View>

          {recentReviews.length > 0 ? (
            recentReviews.map(entry => (
              <View
                key={entry.id}
                style={styles.reviewCard}
              >
                <View style={styles.reviewHeader}>
                  <Text
                    style={styles.reviewFilm}
                    numberOfLines={1}
                  >
                    {entry.film?.title}
                  </Text>

                  <Text style={styles.reviewRating}>
                    🍿 {entry.rating || 0}/5
                  </Text>
                </View>

                <Text
                  style={styles.reviewText}
                  numberOfLines={3}
                >
                  {entry.review}
                </Text>
              </View>
            ))
          ) : (
            <Text style={styles.emptyText}>
              No reviews yet.
            </Text>
          )}
        </View>


        {/* LISTS */}

        <View style={styles.section}>
          <SectionTitle>Lists</SectionTitle>

          {lists.length > 0 ? (
            lists.slice(0, 5).map((list, index) => (
              <View
                key={list.id || index}
                style={styles.listCard}
              >
                <Text style={styles.listTitle}>
                  {list.name || list.title || 'Untitled list'}
                </Text>

                <Text style={styles.listCount}>
                  {list.films?.length || 0} films
                </Text>
              </View>
            ))
          ) : (
            <Text style={styles.emptyText}>
              No lists yet.
            </Text>
          )}
        </View>


        {/* WATCHLIST */}

        <View style={styles.section}>
          <SectionTitle>Watchlist</SectionTitle>

          {watchlist.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.horizontalRow}
            >
              {watchlist.slice(0, 10).map(film => (
                <View
                  key={film.id}
                  style={styles.posterItem}
                >
                  <FilmPoster
                    film={film}
                    size="small"
                  />
                </View>
              ))}
            </ScrollView>
          ) : (
            <Text style={styles.emptyText}>
              Your watchlist is empty.
            </Text>
          )}
        </View>


        {/* BUDDIES */}

        <View style={styles.section}>
          <SectionTitle>Buddies</SectionTitle>

          {buddies.length > 0 ? (
            <FlatList
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              data={buddies}
              keyExtractor={(item, index) =>
                String(item.id || index)
              }
              renderItem={({ item }) => {
                const buddyPicture =
                  item.avatar_url ||
                  item.profilePicture ||
                  item.profile_picture

                return (
                  <View style={styles.buddyCard}>
                    {buddyPicture ? (
                      <Image
                        source={{
                          uri: buddyPicture,
                        }}
                        style={styles.buddyAvatar}
                      />
                    ) : (
                      <View
                        style={[
                          styles.buddyAvatar,
                          styles.avatarPlaceholder,
                        ]}
                      >
                        <Text style={{ fontSize: 28 }}>
                          👤
                        </Text>
                      </View>
                    )}

                    <View style={{ flex: 1 }}>
                      <Text style={styles.buddyName}>
                        {item.display_name ||
                          item.displayName ||
                          item.username ||
                          'Buddy'}
                      </Text>

                      {!!item.username && (
                        <Text style={styles.buddyUsername}>
                          {item.username.startsWith('@')
                            ? item.username
                            : `@${item.username}`}
                        </Text>
                      )}
                    </View>
                  </View>
                )
              }}
            />
          ) : (
            <Text style={styles.emptyText}>
              No buddies to show yet.
            </Text>
          )}
        </View>

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
    height: 46,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
  },

  headerSpacer: {
    width: 42,
  },

  headerTitle: {
    flex: 1,
    textAlign: 'center',
    fontSize: 19,
    fontWeight: '700',
    color: Colors.darkBrown,
  },

  settingsButton: {
    width: 42,
    alignItems: 'flex-end',
    justifyContent: 'center',
  },

  settingsIcon: {
    fontSize: 27,
    color: Colors.darkBrown,
  },

  profileHeader: {
    alignItems: 'center',
    paddingTop: 16,
    paddingBottom: 26,
  },

  avatar: {
    width: 104,
    height: 104,
    borderRadius: 52,
    marginBottom: 14,
  },

  avatarPlaceholder: {
    backgroundColor: Colors.cardBackground,
    alignItems: 'center',
    justifyContent: 'center',
  },

  avatarEmoji: {
    fontSize: 44,
  },

  displayName: {
    fontSize: 25,
    fontWeight: '700',
    color: Colors.darkBrown,
  },

  username: {
    fontSize: 14,
    color: Colors.subtleGray,
    marginTop: 3,
  },

  section: {
    paddingHorizontal: 16,
    marginBottom: 28,
  },

  sectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: Colors.darkBrown,
    marginBottom: 12,
  },

  sectionTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },

  reviewCount: {
    minWidth: 28,
    textAlign: 'center',
    backgroundColor: Colors.cardBackground,
    borderRadius: 14,
    paddingHorizontal: 8,
    paddingVertical: 4,
    fontSize: 12,
    fontWeight: '700',
    color: Colors.sepiaBrown,
  },

  horizontalRow: {
    paddingRight: 16,
  },

  posterItem: {
    marginRight: 10,
  },

  posterTitle: {
    marginTop: 5,
    fontSize: 10,
    lineHeight: 13,
    color: Colors.darkBrown,
  },

  emptyText: {
    fontSize: 14,
    color: Colors.subtleGray,
  },

  emptyCard: {
    minHeight: 80,
    backgroundColor: '#fff',
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },

  goldenIcon: {
    fontSize: 28,
    marginBottom: 6,
  },

  activityRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 8,
    marginBottom: 8,
  },

  activityPoster: {
    width: 42,
    height: 62,
    borderRadius: 6,
    marginRight: 10,
  },

  posterPlaceholder: {
    backgroundColor: Colors.cardBackground,
    alignItems: 'center',
    justifyContent: 'center',
  },

  activityInfo: {
    flex: 1,
  },

  activityTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: Colors.darkBrown,
  },

  activityDate: {
    fontSize: 11,
    color: Colors.subtleGray,
    marginTop: 3,
  },

  activityRating: {
    fontSize: 11,
    marginTop: 4,
  },

  chevron: {
    fontSize: 28,
    color: Colors.subtleGray,
    paddingHorizontal: 8,
  },

  statRow: {
    flexDirection: 'row',
    gap: 10,
  },

  statCard: {
    flex: 1,
    backgroundColor: '#fff',
    borderRadius: 14,
    paddingVertical: 18,
    paddingHorizontal: 12,
    alignItems: 'center',
  },

  statNumber: {
    fontSize: 28,
    fontWeight: '800',
    color: Colors.darkBrown,
  },

  statLabel: {
    marginTop: 4,
    fontSize: 12,
    color: Colors.subtleGray,
  },

  statsButton: {
    marginTop: 10,
    borderRadius: 12,
    paddingHorizontal: 15,
    paddingVertical: 14,
    backgroundColor: Colors.warmRed,
    flexDirection: 'row',
    alignItems: 'center',
  },

  statsButtonText: {
    flex: 1,
    color: '#fff',
    fontSize: 15,
    fontWeight: '700',
  },

  statsArrow: {
    color: '#fff',
    fontSize: 24,
  },

  reviewCard: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 13,
    marginBottom: 8,
  },

  reviewHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 6,
  },

  reviewFilm: {
    flex: 1,
    fontSize: 14,
    fontWeight: '700',
    color: Colors.darkBrown,
  },

  reviewRating: {
    fontSize: 12,
    color: Colors.sepiaBrown,
    fontWeight: '600',
  },

  reviewText: {
    fontSize: 13,
    lineHeight: 18,
    color: Colors.sepiaBrown,
  },

  listCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 14,
    marginBottom: 8,
  },

  listTitle: {
    flex: 1,
    fontWeight: '600',
    color: Colors.darkBrown,
  },

  listCount: {
    fontSize: 12,
    color: Colors.subtleGray,
  },

  buddyCard: {
    width: 310,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    borderRadius: 14,
    padding: 14,
    marginRight: 10,
  },

  buddyAvatar: {
    width: 54,
    height: 54,
    borderRadius: 27,
    marginRight: 12,
  },

  buddyName: {
    fontSize: 16,
    fontWeight: '700',
    color: Colors.darkBrown,
  },

  buddyUsername: {
    fontSize: 12,
    color: Colors.subtleGray,
    marginTop: 2,
  },
})
