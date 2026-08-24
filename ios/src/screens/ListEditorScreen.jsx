import {
  useRef,
  useState,
} from 'react'

import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  FlatList,
  Image,
  Alert,
  ActivityIndicator,
} from 'react-native'

import {
  useSafeAreaInsets,
} from 'react-native-safe-area-context'

import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'


export default function ListEditorScreen({
  route,
  navigation,
}) {
  const {
    listId,
  } = route.params


  const insets =
    useSafeAreaInsets()


  const {
    lists = [],

    renameList,
    addFilmToList,
    removeFilmFromList,
    reorderListItems,

    searchFilms,
    searchResults,
    setSearchResults,
    isSearching,
  } = useApp()


  const list =
    lists.find(
      item =>
        item.id ===
        listId
    )


  const [
    title,
    setTitle,
  ] = useState(
    list?.title || ''
  )

  const [
    query,
    setQuery,
  ] = useState('')

  const [
    saving,
    setSaving,
  ] = useState(false)

  const [
    busyItem,
    setBusyItem,
  ] = useState(null)


  const timer =
    useRef(null)


  if (!list) {
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
        <View
          style={
            styles.centered
          }
        >
          <Text
            style={
              styles.emptyText
            }
          >
            List not found.
          </Text>
        </View>
      </View>
    )
  }


  function handleSearch(
    text
  ) {
    setQuery(text)

    clearTimeout(
      timer.current
    )


    if (!text.trim()) {
      setSearchResults([])
      return
    }


    timer.current =
      setTimeout(
        () =>
          searchFilms(text),
        350
      )
  }


  async function handleAdd(
    film
  ) {
    try {
      await addFilmToList(
        list.id,
        film
      )
    } catch (error) {
      Alert.alert(
        'Error',
        error.message
      )
    }
  }


  async function removeItem(
    item
  ) {
    try {
      await removeFilmFromList(
        list.id,
        item.id
      )
    } catch (error) {
      Alert.alert(
        'Error',
        error.message
      )
    }
  }


  async function moveItem(
    index,
    direction
  ) {
    const newIndex =
      index + direction


    if (
      newIndex < 0 ||
      newIndex >=
        list.items.length
    ) {
      return
    }


    const reordered = [
      ...list.items,
    ]


    const [
      item,
    ] =
      reordered.splice(
        index,
        1
      )


    reordered.splice(
      newIndex,
      0,
      item
    )


    setBusyItem(
      item.id
    )


    try {
      await reorderListItems(
        list.id,
        reordered
      )
    } catch (error) {
      Alert.alert(
        'Error',
        error.message
      )
    } finally {
      setBusyItem(null)
    }
  }


  async function saveTitle() {
    setSaving(true)

    try {
      await renameList(
        list.id,
        title
      )

      setSearchResults([])

      navigation.goBack()

    } catch (error) {
      Alert.alert(
        'Error',
        error.message
      )
    } finally {
      setSaving(false)
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
      <View
        style={
          styles.header
        }
      >
        <TouchableOpacity
          onPress={() => {
            setSearchResults(
              []
            )
            navigation.goBack()
          }}
        >
          <Text
            style={
              styles.back
            }
          >
            ‹ Lists
          </Text>
        </TouchableOpacity>

        <Text
          style={
            styles.headerTitle
          }
        >
          Edit List
        </Text>

        <TouchableOpacity
          onPress={
            saveTitle
          }
          disabled={
            saving
          }
        >
          <Text
            style={
              styles.saveHeader
            }
          >
            Save
          </Text>
        </TouchableOpacity>
      </View>


      <TextInput
        value={title}
        onChangeText={
          setTitle
        }
        style={[
          styles.input,
          {
            marginHorizontal: 16,
          },
        ]}
        placeholder="List title"
        placeholderTextColor={
          Colors.subtleGray
        }
      />


      <Text
        style={
          styles.sectionTitle
        }
      >
        Films
      </Text>


      <ScrollView
        style={{
          maxHeight: 310,
        }}
        contentContainerStyle={{
          paddingHorizontal: 16,
          gap: 8,
        }}
      >
        {list.items.length ===
          0 && (
          <Text
            style={
              styles.emptyText
            }
          >
            Add some films below.
          </Text>
        )}


        {list.items.map(
          (
            item,
            index
          ) => (
            <View
              key={
                item.id
              }
              style={
                styles.currentFilm
              }
            >
              <Text
                style={
                  styles.orderNumber
                }
              >
                {index + 1}
              </Text>


              {item.film
                ?.posterURL ? (
                <Image
                  source={{
                    uri:
                      item.film
                        .posterURL,
                  }}
                  style={
                    styles.poster
                  }
                />
              ) : (
                <View
                  style={[
                    styles.poster,
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
                    styles.filmTitle
                  }
                  numberOfLines={
                    2
                  }
                >
                  {
                    item.film
                      ?.title
                  }
                </Text>

                <Text
                  style={
                    styles.filmYear
                  }
                >
                  {
                    item.film
                      ?.year
                  }
                </Text>
              </View>


              {busyItem ===
              item.id ? (
                <ActivityIndicator
                  size="small"
                  color={
                    Colors.warmRed
                  }
                />
              ) : (
                <View
                  style={
                    styles.orderButtons
                  }
                >
                  <TouchableOpacity
                    onPress={() =>
                      moveItem(
                        index,
                        -1
                      )
                    }
                    disabled={
                      index === 0
                    }
                  >
                    <Text
                      style={[
                        styles.orderButton,

                        index ===
                          0 && {
                          opacity:
                            0.25,
                        },
                      ]}
                    >
                      ↑
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    onPress={() =>
                      moveItem(
                        index,
                        1
                      )
                    }
                    disabled={
                      index ===
                      list.items
                        .length -
                        1
                    }
                  >
                    <Text
                      style={[
                        styles.orderButton,

                        index ===
                          list.items
                            .length -
                            1 && {
                          opacity:
                            0.25,
                        },
                      ]}
                    >
                      ↓
                    </Text>
                  </TouchableOpacity>
                </View>
              )}


              <TouchableOpacity
                onPress={() =>
                  removeItem(
                    item
                  )
                }
              >
                <Text
                  style={
                    styles.remove
                  }
                >
                  ✕
                </Text>
              </TouchableOpacity>
            </View>
          )
        )}
      </ScrollView>


      <Text
        style={[
          styles.sectionTitle,
          {
            marginTop: 20,
          },
        ]}
      >
        Add Films
      </Text>


      <View
        style={
          styles.searchBar
        }
      >
        <Text>
          🔍
        </Text>

        <TextInput
          style={
            styles.searchInput
          }
          value={query}
          onChangeText={
            handleSearch
          }
          placeholder="Search films..."
          placeholderTextColor={
            Colors.subtleGray
          }
          autoCapitalize="none"
        />
      </View>


      {isSearching ? (
        <ActivityIndicator
          style={{
            marginTop: 25,
          }}
          color={
            Colors.warmRed
          }
        />
      ) : (
        <FlatList
          data={
            query.trim()
              ? searchResults
              : []
          }
          keyExtractor={
            item =>
              String(
                item.id
              )
          }
          contentContainerStyle={{
            paddingHorizontal: 16,
            paddingBottom: 40,
          }}
          renderItem={({
            item,
          }) => {
            const alreadyAdded =
              list.items.some(
                existing =>
                  String(
                    existing
                      .film_id
                  ) ===
                  String(
                    item.id
                  )
              )


            return (
              <TouchableOpacity
                style={
                  styles.searchResult
                }
                onPress={() =>
                  !alreadyAdded &&
                  handleAdd(
                    item
                  )
                }
                disabled={
                  alreadyAdded
                }
              >
                {item.posterURL ? (
                  <Image
                    source={{
                      uri:
                        item.posterURL,
                    }}
                    style={
                      styles.searchPoster
                    }
                  />
                ) : (
                  <View
                    style={[
                      styles.searchPoster,
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
                      styles.filmTitle
                    }
                  >
                    {
                      item.title
                    }
                  </Text>

                  <Text
                    style={
                      styles.filmYear
                    }
                  >
                    {item.year}
                  </Text>
                </View>


                <Text
                  style={[
                    styles.add,

                    alreadyAdded && {
                      color:
                        Colors.subtleGray,
                    },
                  ]}
                >
                  {alreadyAdded
                    ? '✓'
                    : '+'}
                </Text>
              </TouchableOpacity>
            )
          }}
        />
      )}
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
      height: 52,
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: 16,
    },

    back: {
      width: 70,
      color:
        Colors.sepiaBrown,
      fontSize: 15,
    },

    headerTitle: {
      flex: 1,
      textAlign: 'center',
      fontSize: 18,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    saveHeader: {
      width: 70,
      textAlign: 'right',
      color:
        Colors.warmRed,
      fontWeight: '700',
      fontSize: 15,
    },

    input: {
      backgroundColor: '#fff',
      borderRadius: 10,
      borderWidth: 1,
      borderColor:
        Colors.subtleGray +
        '44',
      padding: 13,
      fontSize: 15,
      color:
        Colors.darkBrown,
      marginBottom: 14,
    },

    sectionTitle: {
      fontSize: 16,
      fontWeight: '700',
      color:
        Colors.darkBrown,
      marginHorizontal: 16,
      marginBottom: 9,
    },

    currentFilm: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#fff',
      borderRadius: 10,
      padding: 8,
    },

    orderNumber: {
      width: 24,
      textAlign: 'center',
      fontWeight: '700',
      color:
        Colors.sepiaBrown,
    },

    poster: {
      width: 38,
      height: 56,
      borderRadius: 5,
      marginRight: 9,
    },

    placeholder: {
      backgroundColor:
        Colors.cardBackground,
      alignItems: 'center',
      justifyContent:
        'center',
    },

    filmTitle: {
      fontSize: 13,
      fontWeight: '600',
      color:
        Colors.darkBrown,
    },

    filmYear: {
      fontSize: 11,
      color:
        Colors.subtleGray,
      marginTop: 2,
    },

    orderButtons: {
      flexDirection: 'row',
      gap: 5,
    },

    orderButton: {
      fontSize: 18,
      color:
        Colors.warmRed,
      padding: 5,
    },

    remove: {
      color: '#b3261e',
      fontSize: 17,
      padding: 8,
    },

    emptyText: {
      color:
        Colors.subtleGray,
      fontSize: 13,
    },

    searchBar: {
      marginHorizontal: 16,
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#fff',
      borderRadius: 12,
      paddingHorizontal: 12,
      marginBottom: 8,
    },

    searchInput: {
      flex: 1,
      padding: 12,
      color:
        Colors.darkBrown,
      fontSize: 14,
    },

    searchResult: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#fff',
      borderRadius: 10,
      padding: 8,
      marginBottom: 8,
    },

    searchPoster: {
      width: 40,
      height: 58,
      borderRadius: 5,
      marginRight: 10,
    },

    add: {
      fontSize: 28,
      color:
        Colors.warmRed,
      paddingHorizontal: 8,
    },

    centered: {
      flex: 1,
      alignItems: 'center',
      justifyContent:
        'center',
    },
  })
