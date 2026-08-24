import {
  useState,
} from 'react'

import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  TextInput,
  Modal,
  Alert,
  Image,
} from 'react-native'

import {
  useSafeAreaInsets,
} from 'react-native-safe-area-context'

import { useApp } from '../context/AppContext'
import { useAuth } from '../context/AuthContext'
import { Colors } from '../theme/colors'
import AddBuddyScreen from './AddBuddyScreen'


const TABS = [
  'All',
  'Activity',
  'Posts',
]


function EmptyState({
  icon,
  title,
  subtitle,
}) {
  return (
    <View
      style={
        styles.emptyState
      }
    >
      <Text
        style={
          styles.emptyIcon
        }
      >
        {icon}
      </Text>

      <Text
        style={
          styles.emptyTitle
        }
      >
        {title}
      </Text>

      <Text
        style={
          styles.emptySubtitle
        }
      >
        {subtitle}
      </Text>
    </View>
  )
}


function BuddyCard({
  buddy,
  onRemove,
}) {
  return (
    <View
      style={
        styles.buddyCard
      }
    >
      {buddy.profile_pic_url ? (
        <Image
          source={{
            uri:
              buddy.profile_pic_url,
          }}
          style={
            styles.buddyAvatar
          }
        />
      ) : (
        <View
          style={[
            styles.buddyAvatar,
            styles.avatarPlaceholder,
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


      <View
        style={{
          flex: 1,
        }}
      >
        <Text
          style={
            styles.buddyName
          }
          numberOfLines={1}
        >
          {buddy.displayName}
        </Text>

        <Text
          style={
            styles.buddyUsername
          }
        >
          @{buddy.username}
        </Text>
      </View>


      <TouchableOpacity
        style={
          styles.removeButton
        }
        onPress={() =>
          onRemove(buddy)
        }
      >
        <Text
          style={
            styles.removeButtonText
          }
        >
          Remove
        </Text>
      </TouchableOpacity>
    </View>
  )
}


export default function BuddiesScreen() {
  const {
    buddies = [],
    removeBuddy,
  } = useApp()

  const {
    user,
    profile,
  } = useAuth()

  const insets =
    useSafeAreaInsets()


  const [
    activeTab,
    setActiveTab,
  ] = useState(0)

  const [
    posts,
    setPosts,
  ] = useState([])

  const [
    showNewPost,
    setShowNewPost,
  ] = useState(false)

  const [
    newPostText,
    setNewPostText,
  ] = useState('')

  const [
    showAddBuddy,
    setShowAddBuddy,
  ] = useState(false)


  function handlePost() {
    if (
      !newPostText.trim()
    ) {
      return
    }


    const post = {
      id:
        Date.now()
          .toString(),

      text:
        newPostText.trim(),

      username:
        profile?.username ||
        user?.user_metadata
          ?.username ||
        user?.email
          ?.split('@')[0] ||
        'You',

      createdAt:
        new Date()
          .toISOString(),
    }


    setPosts(
      prev => [
        post,
        ...prev,
      ]
    )

    setNewPostText('')
    setShowNewPost(false)
  }


  function confirmRemove(
    buddy
  ) {
    Alert.alert(
      'Remove Buddy',
      `Remove ${buddy.displayName} from your buddies?`,
      [
        {
          text: 'Cancel',
          style: 'cancel',
        },

        {
          text: 'Remove',
          style: 'destructive',

          onPress:
            async () => {
              try {
                await removeBuddy(
                  buddy.user_id
                )
              } catch (error) {
                Alert.alert(
                  'Error',
                  error.message ||
                    'Could not remove buddy.'
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
          styles.navBar
        }
      >
        <Text
          style={
            styles.navTitle
          }
        >
          Buddies
        </Text>


        <View
          style={
            styles.navActions
          }
        >
          <TouchableOpacity
            style={
              styles.navBtn
            }
            onPress={() =>
              setShowAddBuddy(
                true
              )
            }
          >
            <Text
              style={
                styles.navBtnText
              }
            >
              👥 Add Buddy
            </Text>
          </TouchableOpacity>


          <TouchableOpacity
            style={
              styles.navBtn
            }
            onPress={() =>
              setShowNewPost(
                true
              )
            }
          >
            <Text
              style={
                styles.navBtnText
              }
            >
              ✏️ Post
            </Text>
          </TouchableOpacity>
        </View>
      </View>


      <View
        style={
          styles.tabs
        }
      >
        {TABS.map(
          (
            tab,
            index
          ) => (
            <TouchableOpacity
              key={tab}
              style={[
                styles.tab,

                activeTab ===
                  index &&
                  styles.tabActive,
              ]}
              onPress={() =>
                setActiveTab(
                  index
                )
              }
            >
              <Text
                style={[
                  styles.tabText,

                  activeTab ===
                    index &&
                    styles.tabTextActive,
                ]}
              >
                {tab}
              </Text>
            </TouchableOpacity>
          )
        )}
      </View>


      <ScrollView
        contentContainerStyle={{
          padding: 16,
          gap: 12,
          paddingBottom: 30,
        }}
      >

        {activeTab === 0 && (
          <>
            <Text
              style={
                styles.sectionTitle
              }
            >
              Your Buddies
            </Text>


            {buddies.length === 0 ? (
              <EmptyState
                icon="👥"
                title="No buddies yet"
                subtitle="Add some people to build your film circle."
              />
            ) : (
              buddies.map(
                buddy => (
                  <BuddyCard
                    key={
                      buddy.user_id
                    }
                    buddy={
                      buddy
                    }
                    onRemove={
                      confirmRemove
                    }
                  />
                )
              )
            )}


            {posts.length > 0 && (
              <>
                <Text
                  style={[
                    styles.sectionTitle,
                    {
                      marginTop: 14,
                    },
                  ]}
                >
                  Your Posts
                </Text>

                {posts.map(
                  post => (
                    <View
                      key={
                        post.id
                      }
                      style={
                        styles.postCard
                      }
                    >
                      <View
                        style={
                          styles.postAvatar
                        }
                      >
                        <Text>
                          👤
                        </Text>
                      </View>

                      <View
                        style={{
                          flex: 1,
                        }}
                      >
                        <Text
                          style={
                            styles.postUsername
                          }
                        >
                          {
                            post.username
                          }
                        </Text>

                        <Text
                          style={
                            styles.postText
                          }
                        >
                          {
                            post.text
                          }
                        </Text>
                      </View>
                    </View>
                  )
                )}
              </>
            )}
          </>
        )}


        {activeTab === 1 && (
          <EmptyState
            icon="🎬"
            title="Buddy activity"
            subtitle="Buddy diary sharing is not enabled yet, so their private film logs are not shown here."
          />
        )}


        {activeTab === 2 && (
          posts.length === 0 ? (
            <EmptyState
              icon="💬"
              title="No posts yet"
              subtitle="Share a film thought with your buddies."
            />
          ) : (
            posts.map(
              post => (
                <View
                  key={post.id}
                  style={
                    styles.postCard
                  }
                >
                  <View
                    style={
                      styles.postAvatar
                    }
                  >
                    <Text>
                      👤
                    </Text>
                  </View>

                  <View
                    style={{
                      flex: 1,
                    }}
                  >
                    <Text
                      style={
                        styles.postUsername
                      }
                    >
                      {
                        post.username
                      }
                    </Text>

                    <Text
                      style={
                        styles.postText
                      }
                    >
                      {post.text}
                    </Text>
                  </View>
                </View>
              )
            )
          )
        )}
      </ScrollView>


      <Modal
        visible={
          showNewPost
        }
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() =>
          setShowNewPost(
            false
          )
        }
      >
        <View
          style={
            newPostStyles.container
          }
        >
          <View
            style={
              newPostStyles.header
            }
          >
            <TouchableOpacity
              onPress={() =>
                setShowNewPost(
                  false
                )
              }
            >
              <Text
                style={
                  newPostStyles.cancel
                }
              >
                Cancel
              </Text>
            </TouchableOpacity>

            <Text
              style={
                newPostStyles.title
              }
            >
              New Post
            </Text>

            <TouchableOpacity
              onPress={
                handlePost
              }
            >
              <Text
                style={
                  newPostStyles.post
                }
              >
                Post
              </Text>
            </TouchableOpacity>
          </View>


          <TextInput
            style={
              newPostStyles.input
            }
            placeholder="What's on your mind? Share a film thought..."
            placeholderTextColor={
              Colors.subtleGray
            }
            value={
              newPostText
            }
            onChangeText={
              setNewPostText
            }
            multiline
            autoFocus
          />
        </View>
      </Modal>


      <Modal
        visible={
          showAddBuddy
        }
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() =>
          setShowAddBuddy(
            false
          )
        }
      >
        <AddBuddyScreen
          onClose={() =>
            setShowAddBuddy(
              false
            )
          }
        />
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

    navBar: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent:
        'space-between',
      paddingHorizontal: 16,
      paddingBottom: 8,
    },

    navTitle: {
      fontSize: 22,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    navActions: {
      flexDirection: 'row',
      gap: 8,
    },

    navBtn: {
      backgroundColor:
        Colors.cardBackground,
      borderRadius: 16,
      paddingHorizontal: 12,
      paddingVertical: 6,
    },

    navBtnText: {
      fontSize: 13,
      color:
        Colors.sepiaBrown,
      fontWeight: '500',
    },

    tabs: {
      flexDirection: 'row',
      borderBottomWidth: 1,
      borderBottomColor:
        Colors.subtleGray +
        '33',
    },

    tab: {
      flex: 1,
      paddingVertical: 10,
      alignItems: 'center',
    },

    tabActive: {
      borderBottomWidth: 2,
      borderBottomColor:
        Colors.warmRed,
    },

    tabText: {
      fontSize: 14,
      color:
        Colors.subtleGray,
      fontWeight: '500',
    },

    tabTextActive: {
      color:
        Colors.warmRed,
      fontWeight: '700',
    },

    sectionTitle: {
      fontSize: 16,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    emptyState: {
      alignItems: 'center',
      paddingTop: 50,
      gap: 8,
    },

    emptyIcon: {
      fontSize: 40,
    },

    emptyTitle: {
      fontSize: 17,
      fontWeight: '600',
      color:
        Colors.darkBrown,
    },

    emptySubtitle: {
      fontSize: 13,
      color:
        Colors.subtleGray,
      textAlign: 'center',
      paddingHorizontal: 24,
    },

    buddyCard: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: '#fff',
      borderRadius: 14,
      padding: 12,
    },

    buddyAvatar: {
      width: 54,
      height: 54,
      borderRadius: 27,
      marginRight: 12,
    },

    avatarPlaceholder: {
      backgroundColor:
        Colors.cardBackground,
      alignItems: 'center',
      justifyContent:
        'center',
    },

    buddyName: {
      fontSize: 15,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    buddyUsername: {
      fontSize: 12,
      color:
        Colors.subtleGray,
      marginTop: 2,
    },

    removeButton: {
      paddingVertical: 6,
      paddingHorizontal: 8,
    },

    removeButtonText: {
      color: '#b3261e',
      fontSize: 12,
    },

    postCard: {
      flexDirection: 'row',
      backgroundColor: '#fff',
      borderRadius: 12,
      padding: 12,
      gap: 10,
    },

    postAvatar: {
      width: 36,
      height: 36,
      borderRadius: 18,
      backgroundColor:
        Colors.popcornYellow +
        '55',
      alignItems: 'center',
      justifyContent:
        'center',
    },

    postUsername: {
      fontSize: 13,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    postText: {
      fontSize: 14,
      color:
        Colors.darkBrown,
      marginTop: 3,
      lineHeight: 20,
    },
  })


const newPostStyles =
  StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor:
        Colors.cream,
      padding: 16,
    },

    header: {
      flexDirection: 'row',
      justifyContent:
        'space-between',
      alignItems: 'center',
      marginBottom: 20,
    },

    cancel: {
      fontSize: 16,
      color:
        Colors.sepiaBrown,
    },

    title: {
      fontSize: 17,
      fontWeight: '700',
      color:
        Colors.darkBrown,
    },

    post: {
      fontSize: 16,
      color:
        Colors.warmRed,
      fontWeight: '700',
    },

    input: {
      fontSize: 16,
      color:
        Colors.darkBrown,
      lineHeight: 24,
      minHeight: 120,
    },
  })
