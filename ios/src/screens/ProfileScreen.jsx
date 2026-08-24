import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  Image,
  FlatList,
} from 'react-native'

import {
  useSafeAreaInsets,
} from 'react-native-safe-area-context'

import { useAuth } from '../context/AuthContext'
import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'


function currentYear() {
  return new Date()
    .getFullYear()
}


function isThisYear(
  dateValue
) {
  return (
    String(
      dateValue || ''
    ).slice(0, 4) ===
    String(
      currentYear()
    )
  )
}


function FilmPoster({
  film,
  width = 72,
}) {
  const height =
    Math.round(
      width * 1.48
    )


  return (
    <View
      style={{
        width,
        marginRight: 10,
      }}
    >
      {film?.posterURL ? (
        <Image
          source={{
            uri:
              film.posterURL,
          }}
          style={{
            width,
            height,
            borderRadius: 8,
          }}
        />
      ) : (
        <View
          style={{
            width,
            height,
            borderRadius: 8,
            backgroundColor:
              Colors.cardBackground,
            alignItems:
              'center',
            justifyContent:
              'center',
          }}
        >
          <Text
            style={{
              fontSize: 24,
            }}
          >
            🎬
          </Text>
        </View>
      )}

      <Text
        style={
          styles.posterTitle
        }
        numberOfLines={2}
      >
        {film?.title}
      </Text>
    </View>
  )
}


export default function ProfileScreen({
  navigation,
}) {
  const insets =
    useSafeAreaInsets()

  const {
    user,
  } = useAuth()

  const {
    diaryEntries = [],
    topFive = [],
    watchlist = [],
    lists = [],
    buddies = [],
  } = useApp()


  const metadata =
    user?.user_metadata ||
    {}


  const displayName =
    metadata.display_name ||
    metadata.full_name ||
    metadata.username ||
    'Film Lover'


  const rawUsername =
    metadata.username ||
    user?.email
      ?.split('@')[0] ||
    'username'


  const username =
    rawUsername.startsWith(
      '@'
    )
      ? rawUsername
      : `@${rawUsername}`


  const profilePicture =
    metadata.avatar_url ||
    metadata.profile_picture ||
    ''


  const year =
    currentYear()


  const entriesThisYear =
    diaryEntries.filter(
      entry =>
        isThisYear(
          entry.dateWatched
        )
    )


  const recentActivity = [
    ...diaryEntries,
  ]
    .sort(
      (a, b) =>
        new Date(
          b.dateWatched
        ) -
        new Date(
          a.dateWatched
        )
    )
    .slice(0, 5)


  const reviews = [
    ...diaryEntries,
  ]
    .filter(
      entry =>
        entry.review?.trim()
    )
    .sort(
      (a, b) =>
        new Date(
          b.dateWatched
        ) -
        new Date(
          a.dateWatched
        )
    )


  const recentReviews =
    reviews.slice(0, 10)


  const golden =
    diaryEntries.filter(
      entry =>
        entry.isGoldenPopcorn
    )


  function navigateRoot(
    screen,
    params
  ) {
    const parent =
      navigation.getParent()

    if (parent) {
      parent.navigate(
        screen,
        params
      )
    } else {
      navigation.navigate(
        screen,
        params
      )
    }
  }


  return (
    <View
      style={[
        styles.container,
        {
          paddingTop:
            insets.top,
        },
      ]}
    >
      <ScrollView
        showsVerticalScrollIndicator={
          false
        }
        contentContainerStyle={{
          paddingBottom: 100,
        }}
      >

        {/* HEADER */}

        <View
          style={
            styles.header
          }
        >
          <View
            style={{
              width: 42,
            }}
          />

          <Text
            style={
              styles.headerTitle
            }
          >
            Profile
          </Text>

          <TouchableOpacity
            style={
              styles.settingsButton
            }
            onPress={() =>
              navigateRoot(
                'Settings'
              )
            }
          >
            <Text
              style={
                styles.settingsIcon
              }
            >
              ⚙︎
            </Text>
          </TouchableOpacity>
        </View>


        {/* PROFILE */}

        <View
          style={
            styles.profileHeader
          }
        >
          {profilePicture ? (
            <Image
              source={{
                uri:
                  profilePicture,
              }}
              style={
                styles.avatar
              }
            />
          ) : (
            <View
              style={[
                styles.avatar,
                styles.placeholder,
              ]}
            >
              <Text
                style={{
                  fontSize: 42,
                }}
              >
                🍿
              </Text>
            </View>
          )}

          <Text
            style={
              styles.displayName
            }
          >
            {displayName}
          </Text>

          <Text
            style={
              styles.username
            }
          >
            {username}
          </Text>
        </View>


        {/* TOP FIVE */}

        <View
          style={
            styles.section
          }
        >
          <Text
            style={
              styles.sectionTitle
            }
          >
            Top 5 Films
          </Text>

          {topFive.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={
                false
              }
            >
              {topFive
                .slice(0, 5)
                .map(
                  (
                    film,
                    index
                  ) => (
                    <FilmPoster
                      key={`${film.id}-${index}`}
                      film={film}
                    />
                  )
                )}
            </ScrollView>
          ) : (
            <Text
              style={
                styles.emptyText
              }
            >
              No favourite films selected yet.
            </Text>
          )}
        </View>


        {/* GOLDEN POPCORN */}

        <View
          style={
            styles.section
          }
        >
          <Text
            style={
              styles.sectionTitle
            }
          >
            Golden Popcorn
          </Text>

          {golden.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={
                false
              }
            >
              {golden.map(
                entry => (
                  <FilmPoster
                    key={
                      entry.id
                    }
                    film={
                      entry.film
                    }
                  />
                )
              )}
            </ScrollView>
          ) : (
            <Text
              style={
                styles.emptyText
              }
            >
              No Golden Popcorn films yet.
            </Text>
          )}
        </View>


        {/* RECENT ACTIVITY */}

        <View
          style={
            styles.section
          }
        >
          <Text
            style={
              styles.sectionTitle
            }
          >
            Recent Activity
          </Text>

          {recentActivity.map(
            entry => (
              <TouchableOpacity
                key={
                  entry.id
                }
                style={
                  styles.activity
                }
                onPress={() =>
                  navigateRoot(
                    'LogFilm',
                    {
                      editEntry:
                        entry,
                    }
                  )
                }
              >
                {entry.film
                  ?.posterURL ? (
                  <Image
                    source={{
                      uri:
                        entry.film
                          .posterURL,
                    }}
                    style={
                      styles.activityPoster
                    }
                  />
                ) : (
                  <View
                    style={[
                      styles.activityPoster,
                      styles.placeholder,
                    ]}
                  >
                    <Text>
                      🎬
                    </Text>
                  </View>
                )}

                <View
                  style={{
                    flex: 1,
                  }}
                >
                  <Text
                    style={
                      styles.activityTitle
                    }
                  >
                    {
                      entry.film
                        ?.title
                    }
                  </Text>

                  <Text
                    style={
                      styles.activityDate
                    }
                  >
                    {
                      entry.dateWatched
                    }
                  </Text>

                  {!!entry.rating && (
                    <Text
                      style={
                        styles.rating
                      }
                    >
                      {'🍿'.repeat(
                        Math.round(
                          entry.rating
                        )
                      )}
                    </Text>
                  )}
                </View>

                <Text
                  style={
                    styles.chevron
                  }
                >
                  ›
                </Text>
              </TouchableOpacity>
            )
          )}
        </View>


        {/* COUNTS */}

        <View
          style={
            styles.section
          }
        >
          <View
            style={
              styles.statRow
            }
          >
            <View
              style={
                styles.statCard
              }
            >
              <Text
                style={
                  styles.statNumber
                }
              >
                {
                  entriesThisYear.length
                }
              </Text>

              <Text
                style={
                  styles.statLabel
                }
              >
                Logged in {year}
              </Text>
            </View>


            <View
              style={
                styles.statCard
              }
            >
              <Text
                style={
                  styles.statNumber
                }
              >
                {
                  diaryEntries.length
                }
              </Text>

              <Text
                style={
                  styles.statLabel
                }
              >
                Logged total
              </Text>
            </View>
          </View>


          <TouchableOpacity
            style={
              styles.primaryButton
            }
            onPress={() =>
              navigateRoot(
                'Stats'
              )
            }
          >
            <Text
              style={
                styles.primaryButtonText
              }
            >
              View Stats
            </Text>

            <Text
              style={
                styles.primaryButtonArrow
              }
            >
              ›
            </Text>
          </TouchableOpacity>
        </View>


        {/* REVIEWS */}

        <View
          style={
            styles.section
          }
        >
          <View
            style={
              styles.sectionHeaderRow
            }
          >
            <Text
              style={
                styles.sectionTitle
              }
            >
              Reviews
            </Text>

            <Text
              style={
                styles.countBadge
              }
            >
              {reviews.length}
            </Text>
          </View>


          {recentReviews.length >
          0 ? (
            <FlatList
              horizontal
              showsHorizontalScrollIndicator={
                false
              }
              data={
                recentReviews
              }
              keyExtractor={
                item =>
                  item.id
              }
              contentContainerStyle={{
                paddingRight: 16,
              }}
              renderItem={({
                item,
              }) => (
                <TouchableOpacity
                  style={
                    styles.reviewCard
                  }
                  activeOpacity={
                    0.85
                  }
                  onPress={() =>
                    navigateRoot(
                      'LogFilm',
                      {
                        editEntry:
                          item,
                      }
                    )
                  }
                >
                  <View
                    style={
                      styles.reviewTop
                    }
                  >
                    <Text
                      style={
                        styles.reviewFilm
                      }
                      numberOfLines={
                        1
                      }
                    >
                      {
                        item.film
                          ?.title
                      }
                    </Text>

                    <Text
                      style={
                        styles.reviewRating
                      }
                    >
                      🍿{' '}
                      {
                        item.rating
                      }
                      /5
                    </Text>
                  </View>

                  <Text
                    style={
                      styles.reviewDate
                    }
                  >
                    {
                      item.dateWatched
                    }
                  </Text>

                  <Text
                    style={
                      styles.reviewText
                    }
                    numberOfLines={
                      5
                    }
                  >
                    {
                      item.review
                    }
                  </Text>
                </TouchableOpacity>
              )}
            />
          ) : (
            <Text
              style={
                styles.emptyText
              }
            >
              No reviews yet.
            </Text>
          )}
        </View>


        {/* LISTS */}

        <View
          style={
            styles.section
          }
        >
          <View
            style={
              styles.sectionHeaderRow
            }
          >
            <Text
              style={
                styles.sectionTitle
              }
            >
              Lists
            </Text>

            <TouchableOpacity
              onPress={() =>
                navigateRoot(
                  'Lists'
                )
              }
            >
              <Text
                style={
                  styles.manageText
                }
              >
                Manage
              </Text>
            </TouchableOpacity>
          </View>


          {lists.length > 0 ? (
            lists
              .slice(0, 4)
              .map(
                list => (
                  <TouchableOpacity
                    key={
                      list.id
                    }
                    style={
                      styles.listRow
                    }
                    onPress={() =>
                      navigateRoot(
                        'ListEditor',
                        {
                          listId:
                            list.id,
                        }
                      )
                    }
                  >
                    <View
                      style={
                        styles.listIcon
                      }
                    >
                      <Text>
                        🎞️
                      </Text>
                    </View>

                    <View
                      style={{
                        flex: 1,
                      }}
                    >
                      <Text
                        style={
                          styles.listName
                        }
                      >
                        {
                          list.title
                        }
                      </Text>

                      <Text
                        style={
                          styles.listCount
                        }
                      >
                        {list.items.length}{' '}
                        {list.items
                          .length ===
                        1
                          ? 'film'
                          : 'films'}
                      </Text>
                    </View>

                    <Text
                      style={
                        styles.chevron
                      }
                    >
                      ›
                    </Text>
                  </TouchableOpacity>
                )
              )
          ) : (
            <TouchableOpacity
              style={
                styles.emptyAction
              }
              onPress={() =>
                navigateRoot(
                  'Lists'
                )
              }
            >
              <Text
                style={
                  styles.emptyText
                }
              >
                Create your first film list
              </Text>

              <Text
                style={
                  styles.chevron
                }
              >
                ›
              </Text>
            </TouchableOpacity>
          )}
        </View>


        {/* WATCHLIST */}

        <View
          style={
            styles.section
          }
        >
          <Text
            style={
              styles.sectionTitle
            }
          >
            Watchlist
          </Text>

          {watchlist.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={
                false
              }
            >
              {watchlist
                .slice(0, 12)
                .map(
                  film => (
                    <FilmPoster
                      key={
                        film.id
                      }
                      film={film}
                      width={60}
                    />
                  )
                )}
            </ScrollView>
          ) : (
            <Text
              style={
                styles.emptyText
              }
            >
              Your watchlist is empty.
            </Text>
          )}
        </View>


        {/* BUDDIES */}

        <View
          style={
            styles.section
          }
        >
          <Text
            style={
              styles.sectionTitle
            }
          >
            Buddies
          </Text>


          {buddies.length > 0 ? (
            <FlatList
              horizontal
              showsHorizontalScrollIndicator={
                false
              }
              data={
                buddies
              }
              keyExtractor={
                item =>
                  item.user_id
              }
              contentContainerStyle={{
                paddingRight: 16,
              }}
              renderItem={({
                item,
              }) => (
                <View
                  style={
                    styles.buddyCard
                  }
                >
                  {item.profile_pic_url ? (
                    <Image
                      source={{
                        uri:
                          item.profile_pic_url,
                      }}
                      style={
                        styles.buddyAvatar
                      }
                    />
                  ) : (
                    <View
                      style={[
                        styles.buddyAvatar,
                        styles.placeholder,
                      ]}
                    >
                      <Text
                        style={{
                          fontSize: 26,
                        }}
                      >
                        👤
                      </Text>
                    </View>
                  )}

                  <Text
                    style={
                      styles.buddyName
                    }
                    numberOfLines={
                      1
                    }
                  >
                    {
                      item.displayName
                    }
                  </Text>

                  <Text
                    style={
                      styles.buddyUsername
                    }
                    numberOfLines={
                      1
                    }
                  >
                    @{item.username}
                  </Text>
                </View>
              )}
            />
          ) : (
            <Text
              style={
                styles.emptyText
              }
            >
              No buddies yet.
            </Text>
          )}
        </View>

      </ScrollView>
    </View>
  )
}


const styles =
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor:
        Colors.cream,
    },

    header: {
      height: 48,
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: 16,
    },

    headerTitle: {
      flex: 1,
      textAlign: 'center',
      fontSize: 19,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    settingsButton: {
      width: 42,
      alignItems: 'flex-end',
    },

    settingsIcon: {
      fontSize: 27,
      color:
        Colors.darkBrown,
    },

    profileHeader: {
      alignItems: 'center',
      paddingTop: 16,
      paddingBottom: 28,
    },

    avatar: {
      width: 104,
      height: 104,
      borderRadius: 52,
      marginBottom: 13,
    },

    placeholder: {
      backgroundColor:
        Colors.cardBackground,
      alignItems: 'center',
      justifyContent:
        'center',
    },

    displayName: {
      fontSize: 25,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    username: {
      fontSize: 13,
      color:
        Colors.subtleGray,
      marginTop: 3,
    },

    section: {
      paddingHorizontal: 16,
      marginBottom: 28,
    },

    sectionTitle: {
      fontSize: 18,
      fontWeight: '700',
      color:
        Colors.darkBrown,
      marginBottom: 12,
    },

    sectionHeaderRow: {
      flexDirection: 'row',
      justifyContent:
        'space-between',
      alignItems:
        'flex-start',
    },

    posterTitle: {
      marginTop: 5,
      fontSize: 10,
      lineHeight: 13,
      color:
        Colors.darkBrown,
    },

    emptyText: {
      fontSize: 13,
      color:
        Colors.subtleGray,
    },

    activity: {
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

    activityTitle: {
      fontSize: 14,
      fontWeight: '600',
      color:
        Colors.darkBrown,
    },

    activityDate: {
      fontSize: 11,
      color:
        Colors.subtleGray,
      marginTop: 3,
    },

    rating: {
      fontSize: 11,
      marginTop: 4,
    },

    chevron: {
      fontSize: 26,
      color:
        Colors.subtleGray,
    },

    statRow: {
      flexDirection: 'row',
      gap: 10,
    },

    statCard: {
      flex: 1,
      backgroundColor: '#fff',
      borderRadius: 14,
      alignItems: 'center',
      paddingVertical: 18,
    },

    statNumber: {
      fontSize: 28,
      fontWeight: '800',
      color:
        Colors.darkBrown,
    },

    statLabel: {
      fontSize: 12,
      color:
        Colors.subtleGray,
      marginTop: 4,
    },

    primaryButton: {
      backgroundColor:
        Colors.warmRed,
      borderRadius: 12,
      paddingHorizontal: 15,
      paddingVertical: 14,
      marginTop: 10,
      flexDirection: 'row',
      alignItems: 'center',
    },

    primaryButtonText: {
      flex: 1,
      color: '#fff',
      fontWeight: '700',
    },

    primaryButtonArrow: {
      color: '#fff',
      fontSize: 24,
    },

    countBadge: {
      backgroundColor:
        Colors.cardBackground,
      paddingHorizontal: 9,
      paddingVertical: 4,
      borderRadius: 14,
      fontSize: 12,
      fontWeight: '700',
      color:
        Colors.sepiaBrown,
    },

    reviewCard: {
      width: 210,
      minHeight: 150,
      backgroundColor: '#fff',
      borderRadius: 14,
      padding: 14,
      marginRight: 10,
    },

    reviewTop: {
      flexDirection: 'row',
      alignItems: 'center',
    },

    reviewFilm: {
      flex: 1,
      fontSize: 15,
      fontWeight: '700',
      color:
        Colors.darkBrown,
      marginRight: 8,
    },

    reviewRating: {
      fontSize: 12,
      color:
        Colors.sepiaBrown,
      fontWeight: '600',
    },

    reviewDate: {
      fontSize: 10,
      color:
        Colors.subtleGray,
      marginTop: 4,
    },

    reviewText: {
      fontSize: 13,
      lineHeight: 18,
      color:
        Colors.sepiaBrown,
      marginTop: 10,
    },

    manageText: {
      fontSize: 13,
      color:
        Colors.warmRed,
      fontWeight: '600',
    },

    listRow: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#fff',
      borderRadius: 12,
      padding: 11,
      marginBottom: 8,
    },

    listIcon: {
      width: 42,
      height: 42,
      borderRadius: 9,
      backgroundColor:
        Colors.cardBackground,
      alignItems: 'center',
      justifyContent:
        'center',
      marginRight: 10,
    },

    listName: {
      fontSize: 14,
      fontWeight: '600',
      color:
        Colors.darkBrown,
    },

    listCount: {
      fontSize: 11,
      color:
        Colors.subtleGray,
      marginTop: 2,
    },

    emptyAction: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#fff',
      borderRadius: 12,
      padding: 14,
    },

    buddyCard: {
      width: 145,
      backgroundColor: '#fff',
      borderRadius: 14,
      padding: 14,
      marginRight: 10,
      alignItems: 'center',
    },

    buddyAvatar: {
      width: 58,
      height: 58,
      borderRadius: 29,
      marginBottom: 8,
    },

    buddyName: {
      fontSize: 14,
      fontWeight: '700',
      color:
        Colors.darkBrown,
      textAlign: 'center',
      width: '100%',
    },

    buddyUsername: {
      fontSize: 11,
      color:
        Colors.subtleGray,
      marginTop: 2,
      width: '100%',
      textAlign: 'center',
    },
  })
