import {
  useState,
} from 'react'

import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Modal,
  TextInput,
  Alert,
  ActivityIndicator,
  Image,
} from 'react-native'

import {
  useSafeAreaInsets,
} from 'react-native-safe-area-context'

import { useApp } from '../context/AppContext'
import { Colors } from '../theme/colors'


export default function ListsScreen({
  navigation,
}) {
  const insets =
    useSafeAreaInsets()

  const {
    lists = [],
    createList,
    deleteList,
  } = useApp()


  const [
    showCreate,
    setShowCreate,
  ] = useState(false)

  const [
    newTitle,
    setNewTitle,
  ] = useState('')

  const [
    creating,
    setCreating,
  ] = useState(false)


  async function handleCreate() {
    if (
      !newTitle.trim()
    ) {
      return
    }


    setCreating(true)


    try {
      const list =
        await createList(
          newTitle
        )


      setNewTitle('')
      setShowCreate(false)


      navigation.navigate(
        'ListEditor',
        {
          listId:
            list.id,
        }
      )

    } catch (error) {
      Alert.alert(
        'Error',
        error.message ||
          'Could not create list.'
      )
    } finally {
      setCreating(false)
    }
  }


  function confirmDelete(
    list
  ) {
    Alert.alert(
      'Delete List',
      `Delete "${list.title}"?`,
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },

        {
          text: 'Delete',
          style:
            'destructive',

          onPress:
            async () => {
              try {
                await deleteList(
                  list.id
                )
              } catch (error) {
                Alert.alert(
                  'Error',
                  error.message
                )
              }
            },
        },
      ]
    )
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
          onPress={() =>
            navigation.goBack()
          }
        >
          <Text
            style={
              styles.back
            }
          >
            ‹ Profile
          </Text>
        </TouchableOpacity>

        <Text
          style={
            styles.title
          }
        >
          Lists
        </Text>

        <TouchableOpacity
          onPress={() =>
            setShowCreate(
              true
            )
          }
        >
          <Text
            style={
              styles.create
            }
          >
            +
          </Text>
        </TouchableOpacity>
      </View>


      <ScrollView
        contentContainerStyle={
          styles.content
        }
      >
        {lists.length === 0 ? (
          <View
            style={
              styles.empty
            }
          >
            <Text
              style={
                styles.emptyIcon
              }
            >
              🎞️
            </Text>

            <Text
              style={
                styles.emptyTitle
              }
            >
              No lists yet
            </Text>

            <Text
              style={
                styles.emptyText
              }
            >
              Make collections of films in whatever order you want.
            </Text>

            <TouchableOpacity
              style={
                styles.primaryButton
              }
              onPress={() =>
                setShowCreate(
                  true
                )
              }
            >
              <Text
                style={
                  styles.primaryButtonText
                }
              >
                Create a List
              </Text>
            </TouchableOpacity>
          </View>
        ) : (
          lists.map(
            list => (
              <TouchableOpacity
                key={
                  list.id
                }
                style={
                  styles.listCard
                }
                activeOpacity={
                  0.8
                }
                onPress={() =>
                  navigation.navigate(
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
                    styles.posterStack
                  }
                >
                  {list.items
                    .slice(0, 3)
                    .map(
                      (
                        item,
                        index
                      ) =>
                        item.film
                          ?.posterURL ? (
                          <Image
                            key={
                              item.id
                            }
                            source={{
                              uri:
                                item
                                  .film
                                  .posterURL,
                            }}
                            style={[
                              styles.stackPoster,
                              {
                                left:
                                  index *
                                  12,
                              },
                            ]}
                          />
                        ) : null
                    )}

                  {list.items.length ===
                    0 && (
                    <View
                      style={
                        styles.emptyPoster
                      }
                    >
                      <Text>
                        🎬
                      </Text>
                    </View>
                  )}
                </View>


                <View
                  style={{
                    flex: 1,
                  }}
                >
                  <Text
                    style={
                      styles.listTitle
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
                      .length === 1
                      ? 'film'
                      : 'films'}
                  </Text>
                </View>


                <TouchableOpacity
                  style={
                    styles.deleteArea
                  }
                  onPress={() =>
                    confirmDelete(
                      list
                    )
                  }
                >
                  <Text
                    style={
                      styles.deleteText
                    }
                  >
                    Delete
                  </Text>
                </TouchableOpacity>

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
        )}
      </ScrollView>


      <Modal
        visible={
          showCreate
        }
        transparent
        animationType="fade"
        onRequestClose={() =>
          setShowCreate(
            false
          )
        }
      >
        <View
          style={
            styles.modalBackdrop
          }
        >
          <View
            style={
              styles.modalCard
            }
          >
            <Text
              style={
                styles.modalTitle
              }
            >
              New List
            </Text>

            <TextInput
              style={
                styles.input
              }
              value={
                newTitle
              }
              onChangeText={
                setNewTitle
              }
              placeholder="e.g. Favourite Horror Films"
              placeholderTextColor={
                Colors.subtleGray
              }
              autoFocus
            />


            <View
              style={
                styles.modalActions
              }
            >
              <TouchableOpacity
                style={
                  styles.cancelButton
                }
                onPress={() => {
                  setShowCreate(
                    false
                  )
                  setNewTitle('')
                }}
              >
                <Text
                  style={
                    styles.cancelButtonText
                  }
                >
                  Cancel
                </Text>
              </TouchableOpacity>


              <TouchableOpacity
                style={
                  styles.primaryButton
                }
                onPress={
                  handleCreate
                }
                disabled={
                  creating
                }
              >
                {creating ? (
                  <ActivityIndicator
                    color="#fff"
                  />
                ) : (
                  <Text
                    style={
                      styles.primaryButtonText
                    }
                  >
                    Create
                  </Text>
                )}
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>
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
      width: 75,
      color:
        Colors.sepiaBrown,
      fontSize: 15,
    },

    title: {
      flex: 1,
      textAlign: 'center',
      fontSize: 19,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    create: {
      width: 75,
      textAlign: 'right',
      fontSize: 30,
      color:
        Colors.warmRed,
    },

    content: {
      padding: 16,
      paddingBottom: 50,
    },

    empty: {
      alignItems: 'center',
      paddingTop: 80,
      paddingHorizontal: 30,
    },

    emptyIcon: {
      fontSize: 48,
    },

    emptyTitle: {
      fontSize: 19,
      fontWeight: '700',
      color:
        Colors.darkBrown,
      marginTop: 12,
    },

    emptyText: {
      color:
        Colors.subtleGray,
      textAlign: 'center',
      lineHeight: 20,
      marginTop: 6,
      marginBottom: 20,
    },

    listCard: {
      minHeight: 92,
      backgroundColor: '#fff',
      borderRadius: 14,
      marginBottom: 10,
      padding: 12,
      flexDirection: 'row',
      alignItems: 'center',
    },

    posterStack: {
      width: 84,
      height: 68,
      marginRight: 12,
      position: 'relative',
    },

    stackPoster: {
      position: 'absolute',
      width: 42,
      height: 62,
      borderRadius: 5,
      top: 3,
    },

    emptyPoster: {
      width: 44,
      height: 64,
      borderRadius: 6,
      backgroundColor:
        Colors.cardBackground,
      alignItems: 'center',
      justifyContent:
        'center',
    },

    listTitle: {
      fontSize: 15,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    listCount: {
      fontSize: 12,
      color:
        Colors.subtleGray,
      marginTop: 3,
    },

    deleteArea: {
      padding: 8,
    },

    deleteText: {
      color: '#b3261e',
      fontSize: 11,
    },

    chevron: {
      fontSize: 26,
      color:
        Colors.subtleGray,
    },

    modalBackdrop: {
      flex: 1,
      backgroundColor:
        'rgba(0,0,0,0.35)',
      justifyContent:
        'center',
      padding: 24,
    },

    modalCard: {
      backgroundColor:
        Colors.cream,
      borderRadius: 18,
      padding: 20,
    },

    modalTitle: {
      fontSize: 20,
      fontWeight: '700',
      color:
        Colors.darkBrown,
      marginBottom: 14,
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
    },

    modalActions: {
      flexDirection: 'row',
      justifyContent:
        'flex-end',
      gap: 10,
      marginTop: 16,
    },

    cancelButton: {
      paddingVertical: 12,
      paddingHorizontal: 18,
    },

    cancelButtonText: {
      color:
        Colors.sepiaBrown,
      fontWeight: '600',
    },

    primaryButton: {
      backgroundColor:
        Colors.warmRed,
      borderRadius: 10,
      paddingVertical: 12,
      paddingHorizontal: 18,
      alignItems: 'center',
    },

    primaryButtonText: {
      color: '#fff',
      fontWeight: '700',
    },
  })
