import { useState } from 'react'
import {
  View, Text, ScrollView, TouchableOpacity, StyleSheet,
  TextInput, Modal, Alert, Image,
} from 'react-native'
import { useSafeAreaInsets } from 'react-native-safe-area-context'
import { useApp } from '../context/AppContext'
import { useAuth } from '../context/AuthContext'
import { Colors } from '../theme/colors'

const TABS = ['All', 'Activity', 'Posts']

function EmptyState({ icon, title, subtitle }) {
  return (
    <View style={styles.emptyState}>
      <Text style={styles.emptyIcon}>{icon}</Text>
      <Text style={styles.emptyTitle}>{title}</Text>
      <Text style={styles.emptySubtitle}>{subtitle}</Text>
    </View>
  )
}

function BuddyLogCard({ entry }) {
  return (
    <View style={styles.logCard}>
      <View style={styles.logCardAvatar}>
        <Text style={{ fontSize: 18 }}>🍿</Text>
      </View>
      <View style={{ flex: 1 }}>
        <Text style={styles.logCardUser}>{entry.username}</Text>
        <Text style={styles.logCardFilm} numberOfLines={1}>watched <Text style={{ fontWeight: '600' }}>{entry.film.title}</Text></Text>
        {entry.rating > 0 && (
          <Text style={styles.logCardRating}>{'🍿'.repeat(Math.round(entry.rating))}</Text>
        )}
        {entry.review ? (
          <Text style={styles.logCardReview} numberOfLines={2}>"{entry.review}"</Text>
        ) : null}
        <Text style={styles.logCardDate}>
          {new Date(entry.dateWatched).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
        </Text>
      </View>
      {entry.film.posterURL ? (
        <Image source={{ uri: entry.film.posterURL }} style={styles.logCardPoster} />
      ) : null}
    </View>
  )
}

export default function BuddiesScreen() {
  const { diaryEntries } = useApp()
  const { user, profile } = useAuth()
  const insets = useSafeAreaInsets()
  const [activeTab, setActiveTab] = useState(0)
  const [posts, setPosts] = useState([])
  const [showNewPost, setShowNewPost] = useState(false)
  const [newPostText, setNewPostText] = useState('')
  //test
  const [showNewBuddy, setShowNewBuddy] = useState(false)
  const [newBuddyText, setNewBuddyText] = useState('')
  //

  // For now buddy logs = your own recent logs as a demo
  // In a real app you'd fetch from Supabase based on follower relationships
  const buddyLogs = diaryEntries.slice(0, 20)

  const handlePost = () => {
    if (!newPostText.trim()) return
    const post = {
      id: Date.now().toString(),
      text: newPostText.trim(),
      username: profile?.username || user?.email?.split('@')[0] || 'You',
      createdAt: new Date().toISOString(),
    }
    setPosts(prev => [post, ...prev])
    setNewPostText('')
    setShowNewPost(false)
    setShowNewBuddy(false)
  }

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <View style={styles.navBar}>
        <Text style={styles.navTitle}>Buddies</Text>
        <TouchableOpacity style={styles.navBtn} onPress={() => setShowNewPost(true)}>
          <Text style={styles.navBtnText}>✏️ Post</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.navBtn} onPress={() => setShowNewBuddy(true)}>
          <Text style={styles.navBtnText}>👥Add Buddy</Text>
        </TouchableOpacity>
      </View>

      {/* Tabs */}
      <View style={styles.tabs}>
        {TABS.map((tab, i) => (
          <TouchableOpacity
            key={tab}
            style={[styles.tab, activeTab === i && styles.tabActive]}
            onPress={() => setActiveTab(i)}
          >
            <Text style={[styles.tabText, activeTab === i && styles.tabTextActive]}>{tab}</Text>
          </TouchableOpacity>
        ))}
      </View>

      <ScrollView contentContainerStyle={{ padding: 16, gap: 12, paddingBottom: 28 }}>
        {activeTab === 0 && (
          <>
            {posts.map(post => (
              <View key={post.id} style={styles.postCard}>
                <View style={styles.logCardAvatar}><Text style={{ fontSize: 18 }}>👤</Text></View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.logCardUser}>{post.username}</Text>
                  <Text style={styles.postText}>{post.text}</Text>
                  <Text style={styles.logCardDate}>
                    {new Date(post.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </Text>
                </View>
              </View>
            ))}
            {buddyLogs.length === 0 && posts.length === 0 ? (
              <EmptyState icon="👥" title="Nothing here yet" subtitle="Add some buddies to see what they're up to!" />
            ) : (
              buddyLogs.map(entry => <BuddyLogCard key={entry.id} entry={entry} />)
            )}
          </>
        )}

        {activeTab === 1 && (
          buddyLogs.length === 0 ? (
            <EmptyState icon="👥" title="No buddy activity yet" subtitle="Add some buddies to see what they're watching!" />
          ) : (
            buddyLogs.map(entry => <BuddyLogCard key={entry.id} entry={entry} />)
          )
        )}

        {activeTab === 2 && (
          posts.length === 0 ? (
            <EmptyState icon="💬" title="No posts yet" subtitle="Be the first to share something with your buddies!" />
          ) : (
            posts.map(post => (
              <View key={post.id} style={styles.postCard}>
                <View style={styles.logCardAvatar}><Text style={{ fontSize: 18 }}>👤</Text></View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.logCardUser}>{post.username}</Text>
                  <Text style={styles.postText}>{post.text}</Text>
                  <Text style={styles.logCardDate}>
                    {new Date(post.createdAt).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                  </Text>
                </View>
              </View>
            ))
          )
        )}
      </ScrollView>

      {/* New Post Modal */}
      <Modal visible={showNewPost} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setShowNewPost(false)}>
        <View style={newPostStyles.container}>
          <View style={newPostStyles.header}>
            <TouchableOpacity onPress={() => setShowNewPost(false)}>
              <Text style={newPostStyles.cancel}>Cancel</Text>
            </TouchableOpacity>
            <Text style={newPostStyles.title}>New Post</Text>
            <TouchableOpacity onPress={handlePost}>
              <Text style={newPostStyles.post}>Post</Text>
            </TouchableOpacity>
          </View>
          <TextInput
            style={newPostStyles.input}
            placeholder="What's on your mind? Share a film thought..."
            placeholderTextColor={Colors.subtleGray}
            value={newPostText}
            onChangeText={setNewPostText}
            multiline
            autoFocus
          />
        </View>
      </Modal>
      {/* New Buddy Modal */}
      <Modal visible={showNewBuddy} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setShowNewBuddy(false)}>
        <View style={newPostStyles.container}>
          <View style={newPostStyles.header}>
            {/* Put here the search bar */}
            <Text style={newPostStyles.title}>Add Buddy</Text>
            <TouchableOpacity onPress={() => setShowNewBuddy(false)}>
              <Text style={newPostStyles.cancel}>Close</Text>
            </TouchableOpacity>
            
          </View>
          <TextInput
            style={newPostStyles.input}
            placeholder="Add a buddy......."
            placeholderTextColor={Colors.subtleGray}
            value={newPostText}
            onChangeText={setNewPostText}
            multiline
            autoFocus
          />
        </View>
      </Modal>
      {/* New Buddy Modal End*/}
      
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream },
  navBar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 16, paddingBottom: 8 },
  navTitle: { fontSize: 22, fontWeight: '700', color: Colors.darkBrown },
  navBtn: { backgroundColor: Colors.cardBackground, borderRadius: 16, paddingHorizontal: 12, paddingVertical: 6 },
  navBtnText: { fontSize: 13, color: Colors.sepiaBrown, fontWeight: '500' },
  tabs: { flexDirection: 'row', borderBottomWidth: 1, borderBottomColor: Colors.subtleGray + '33', marginBottom: 4 },
  tab: { flex: 1, paddingVertical: 10, alignItems: 'center' },
  tabActive: { borderBottomWidth: 2, borderBottomColor: Colors.warmRed },
  tabText: { fontSize: 14, color: Colors.subtleGray, fontWeight: '500' },
  tabTextActive: { color: Colors.warmRed, fontWeight: '700' },
  emptyState: { alignItems: 'center', paddingTop: 60, gap: 8 },
  emptyIcon: { fontSize: 40 },
  emptyTitle: { fontSize: 17, fontWeight: '600', color: Colors.darkBrown },
  emptySubtitle: { fontSize: 13, color: Colors.subtleGray, textAlign: 'center', paddingHorizontal: 24 },
  logCard: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 12, padding: 12, gap: 10 },
  logCardAvatar: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.popcornYellow + '55', alignItems: 'center', justifyContent: 'center' },
  logCardUser: { fontSize: 13, fontWeight: '700', color: Colors.darkBrown },
  logCardFilm: { fontSize: 13, color: Colors.sepiaBrown, marginTop: 2 },
  logCardRating: { fontSize: 12, marginTop: 2 },
  logCardReview: { fontSize: 12, color: Colors.sepiaBrown, fontStyle: 'italic', marginTop: 4 },
  logCardDate: { fontSize: 11, color: Colors.subtleGray, marginTop: 4 },
  logCardPoster: { width: 44, height: 62, borderRadius: 6 },
  postCard: { flexDirection: 'row', backgroundColor: '#fff', borderRadius: 12, padding: 12, gap: 10 },
  postText: { fontSize: 14, color: Colors.darkBrown, marginTop: 2, lineHeight: 20 },
})

const newPostStyles = StyleSheet.create({
  container: { flex: 1, backgroundColor: Colors.cream, padding: 16 },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 },
  cancel: { fontSize: 16, color: Colors.sepiaBrown },
  title: { fontSize: 17, fontWeight: '700', color: Colors.darkBrown },
  post: { fontSize: 16, color: Colors.warmRed, fontWeight: '700' },
  input: { fontSize: 16, color: Colors.darkBrown, lineHeight: 24, minHeight: 120 },
})
