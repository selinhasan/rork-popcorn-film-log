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
  Image,
  ScrollView,
  FlatList,
  ActivityIndicator,
  Alert,
} from 'react-native'

import { useSafeAreaInsets } from 'react-native-safe-area-context'

import { useAuth } from '../context/AuthContext'
import { useApp } from '../context/AppContext'
import { supabase } from '../lib/supabase'
import { Colors } from '../theme/colors'


function ScreenShell({
  navigation,
  title,
  children,
}) {
  const insets = useSafeAreaInsets()

  return (
    <View
      style={[
        styles.screen,
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
            ‹ Back
          </Text>
        </TouchableOpacity>

        <Text style={styles.headerTitle}>
          {title}
        </Text>

        <View style={{ width: 60 }} />
      </View>

      {children}
    </View>
  )
}


async function updateMetadata(
  user,
  patch
) {
  const existing =
    user?.user_metadata || {}

  const { data, error } =
    await supabase.auth.updateUser({
      data: {
        ...existing,
        ...patch,
      },
    })

  if (error) {
    throw new Error(error.message)
  }

  return data.user
}


function SettingRow({
  title,
  value,
  onPress,
  image,
}) {
  return (
    <TouchableOpacity
      style={styles.settingRow}
      onPress={onPress}
    >
      {image ? (
        <Image
          source={{ uri: image }}
          style={styles.settingAvatar}
        />
      ) : null}

      <View style={{ flex: 1 }}>
        <Text style={styles.settingTitle}>
          {title}
        </Text>

        {!!value && (
          <Text
            style={styles.settingValue}
            numberOfLines={1}
          >
            {value}
          </Text>
        )}
      </View>

      <Text style={styles.chevron}>
        ›
      </Text>
    </TouchableOpacity>
  )
}


export function SettingsScreen({
  navigation,
}) {
  const { user } = useAuth()

  const {
    topFive = [],
  } = useApp()

  const metadata =
    user?.user_metadata || {}

  const displayName =
    metadata.display_name ||
    metadata.username ||
    ''

  const username =
    metadata.username || ''

  const avatar =
    metadata.avatar_url ||
    metadata.profile_picture ||
    ''


  return (
    <ScreenShell
      navigation={navigation}
      title="Settings"
    >
      <ScrollView
        contentContainerStyle={
          styles.settingsContent
        }
      >
        <SettingRow
          title="Profile Picture"
          value={
            avatar
              ? 'Current picture'
              : 'Not set'
          }
          image={avatar}
          onPress={() =>
            navigation.navigate(
              'EditProfilePicture'
            )
          }
        />

        <SettingRow
          title="Display Name"
          value={
            displayName || 'Not set'
          }
          onPress={() =>
            navigation.navigate(
              'EditDisplayName'
            )
          }
        />

        <SettingRow
          title="Username"
          value={
            username
              ? `@${username.replace(
                  /^@/,
                  ''
                )}`
              : 'Not set'
          }
          onPress={() =>
            navigation.navigate(
              'EditUsername'
            )
          }
        />

        <SettingRow
          title="Email"
          value={
            user?.email || ''
          }
          onPress={() =>
            navigation.navigate(
              'EditEmail'
            )
          }
        />

        <SettingRow
          title="Favourite 5 Films"
          value={`${topFive.length}/5 selected`}
          onPress={() =>
            navigation.navigate(
              'EditTopFive'
            )
          }
        />
      </ScrollView>
    </ScreenShell>
  )
}


function MetadataTextEditScreen({
  navigation,
  title,
  initialValue,
  placeholder,
  metadataKey,
  transformBeforeSave,
}) {
  const { user } = useAuth()

  const [value, setValue] =
    useState(initialValue || '')

  const [saving, setSaving] =
    useState(false)


  async function save() {
    const cleaned =
      transformBeforeSave
        ? transformBeforeSave(value)
        : value.trim()

    if (!cleaned) {
      Alert.alert(
        'Error',
        `${title} cannot be empty.`
      )

      return
    }

    setSaving(true)

    try {
      await updateMetadata(user, {
        [metadataKey]: cleaned,
      })

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
    <ScreenShell
      navigation={navigation}
      title={title}
    >
      <View style={styles.editContent}>
        <TextInput
          value={value}
          onChangeText={setValue}
          placeholder={placeholder}
          placeholderTextColor={
            Colors.subtleGray
          }
          style={styles.input}
          autoCapitalize="none"
        />

        <TouchableOpacity
          style={styles.saveButton}
          onPress={save}
          disabled={saving}
        >
          {saving ? (
            <ActivityIndicator
              color="#fff"
            />
          ) : (
            <Text
              style={styles.saveButtonText}
            >
              Save
            </Text>
          )}
        </TouchableOpacity>
      </View>
    </ScreenShell>
  )
}


export function EditDisplayNameScreen({
  navigation,
}) {
  const { user } = useAuth()

  return (
    <MetadataTextEditScreen
      navigation={navigation}
      title="Display Name"
      initialValue={
        user?.user_metadata
          ?.display_name || ''
      }
      placeholder="Display name"
      metadataKey="display_name"
    />
  )
}


export function EditUsernameScreen({
  navigation,
}) {
  const { user } = useAuth()

  return (
    <MetadataTextEditScreen
      navigation={navigation}
      title="Username"
      initialValue={
        user?.user_metadata
          ?.username || ''
      }
      placeholder="Username"
      metadataKey="username"
      transformBeforeSave={value =>
        value
          .trim()
          .replace(/^@/, '')
          .toLowerCase()
      }
    />
  )
}


export function EditEmailScreen({
  navigation,
}) {
  const { user } = useAuth()

  const [email, setEmail] =
    useState(user?.email || '')

  const [saving, setSaving] =
    useState(false)


  async function save() {
    const cleaned =
      email.trim().toLowerCase()

    if (
      !cleaned ||
      !cleaned.includes('@')
    ) {
      Alert.alert(
        'Error',
        'Enter a valid email address.'
      )

      return
    }

    setSaving(true)

    try {
      const { error } =
        await supabase.auth.updateUser({
          email: cleaned,
        })

      if (error) {
        throw new Error(
          error.message
        )
      }

      Alert.alert(
        'Check your email',
        'Supabase may require you to confirm the new email address before it changes.'
      )

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
    <ScreenShell
      navigation={navigation}
      title="Email"
    >
      <View style={styles.editContent}>
        <TextInput
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          placeholder="Email address"
          placeholderTextColor={
            Colors.subtleGray
          }
          style={styles.input}
        />

        <TouchableOpacity
          style={styles.saveButton}
          onPress={save}
          disabled={saving}
        >
          {saving ? (
            <ActivityIndicator
              color="#fff"
            />
          ) : (
            <Text
              style={styles.saveButtonText}
            >
              Save Email
            </Text>
          )}
        </TouchableOpacity>
      </View>
    </ScreenShell>
  )
}


export function EditProfilePictureScreen({
  navigation,
}) {
  const { user } = useAuth()

  const current =
    user?.user_metadata
      ?.avatar_url ||
    user?.user_metadata
      ?.profile_picture ||
    ''

  const [url, setUrl] =
    useState(current)

  const [saving, setSaving] =
    useState(false)


  async function save() {
    const cleaned =
      url.trim()

    setSaving(true)

    try {
      await updateMetadata(user, {
        avatar_url: cleaned,
      })

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
    <ScreenShell
      navigation={navigation}
      title="Profile Picture"
    >
      <ScrollView
        contentContainerStyle={
          styles.editContent
        }
      >
        <View
          style={
            styles.picturePreviewContainer
          }
        >
          {url ? (
            <Image
              source={{ uri: url }}
              style={styles.picturePreview}
            />
          ) : (
            <View
              style={[
                styles.picturePreview,
                styles.picturePlaceholder,
              ]}
            >
              <Text style={{ fontSize: 44 }}>
                🍿
              </Text>
            </View>
          )}
        </View>

        <Text style={styles.helperText}>
          Paste the URL of the image you want to use.
        </Text>

        <TextInput
          value={url}
          onChangeText={setUrl}
          autoCapitalize="none"
          autoCorrect={false}
          placeholder="https://..."
          placeholderTextColor={
            Colors.subtleGray
          }
          style={styles.input}
        />

        <TouchableOpacity
          style={styles.saveButton}
          onPress={save}
          disabled={saving}
        >
          {saving ? (
            <ActivityIndicator
              color="#fff"
            />
          ) : (
            <Text
              style={styles.saveButtonText}
            >
              Save Picture
            </Text>
          )}
        </TouchableOpacity>
      </ScrollView>
    </ScreenShell>
  )
}


export function EditTopFiveScreen({
  navigation,
}) {
  const {
    topFive = [],
    updateTopFive,
    searchFilms,
    searchResults = [],
    setSearchResults,
    isSearching,
  } = useApp()

  const [selected, setSelected] =
    useState(topFive.slice(0, 5))

  const [query, setQuery] =
    useState('')

  const [saving, setSaving] =
    useState(false)

  const timer =
    useRef(null)


  function handleSearch(text) {
    setQuery(text)

    clearTimeout(timer.current)

    if (!text.trim()) {
      setSearchResults([])
      return
    }

    timer.current =
      setTimeout(() => {
        searchFilms(text)
      }, 350)
  }


  function addFilm(film) {
    if (
      selected.some(
        item => item.id === film.id
      )
    ) {
      return
    }

    if (selected.length >= 5) {
      Alert.alert(
        'Top 5 full',
        'Remove a film before adding another.'
      )

      return
    }

    setSelected(prev => [
      ...prev,
      film,
    ])
  }


  function removeFilm(filmId) {
    setSelected(prev =>
      prev.filter(
        film => film.id !== filmId
      )
    )
  }


  async function save() {
    setSaving(true)

    try {
      await updateTopFive(
        selected.slice(0, 5)
      )

      setSearchResults([])

      navigation.goBack()
    } catch (error) {
      Alert.alert(
        'Error',
        error.message ||
          'Could not save your Top 5.'
      )
    } finally {
      setSaving(false)
    }
  }


  return (
    <ScreenShell
      navigation={navigation}
      title="Favourite 5"
    >
      <View style={{ flex: 1 }}>
        <View style={styles.topFiveSelected}>
          {[0, 1, 2, 3, 4].map(index => {
            const film =
              selected[index]

            return (
              <TouchableOpacity
                key={index}
                style={styles.topFiveSlot}
                onPress={() =>
                  film &&
                  removeFilm(film.id)
                }
              >
                {film?.posterURL ? (
                  <Image
                    source={{
                      uri: film.posterURL,
                    }}
                    style={styles.topFivePoster}
                  />
                ) : (
                  <View
                    style={[
                      styles.topFivePoster,
                      styles.picturePlaceholder,
                    ]}
                  >
                    <Text
                      style={{
                        fontSize: 20,
                      }}
                    >
                      {film ? '🎬' : '+'}
                    </Text>
                  </View>
                )}

                {film && (
                  <Text
                    style={styles.removeText}
                  >
                    Remove
                  </Text>
                )}
              </TouchableOpacity>
            )
          })}
        </View>


        <TextInput
          style={[
            styles.input,
            {
              marginHorizontal: 16,
            },
          ]}
          value={query}
          onChangeText={handleSearch}
          placeholder="Search for a film..."
          placeholderTextColor={
            Colors.subtleGray
          }
        />


        {isSearching ? (
          <ActivityIndicator
            style={{ marginTop: 20 }}
            color={Colors.warmRed}
          />
        ) : (
          <FlatList
            data={searchResults}
            keyExtractor={item =>
              String(item.id)
            }
            contentContainerStyle={{
              paddingHorizontal: 16,
              paddingBottom: 100,
            }}
            renderItem={({ item }) => (
              <TouchableOpacity
                style={styles.searchResult}
                onPress={() =>
                  addFilm(item)
                }
              >
                {item.posterURL ? (
                  <Image
                    source={{
                      uri: item.posterURL,
                    }}
                    style={styles.searchPoster}
                  />
                ) : (
                  <View
                    style={[
                      styles.searchPoster,
                      styles.picturePlaceholder,
                    ]}
                  >
                    <Text>🎬</Text>
                  </View>
                )}

                <View style={{ flex: 1 }}>
                  <Text
                    style={styles.searchTitle}
                  >
                    {item.title}
                  </Text>

                  <Text
                    style={styles.searchMeta}
                  >
                    {item.year}
                  </Text>
                </View>

                <Text style={styles.addText}>
                  +
                </Text>
              </TouchableOpacity>
            )}
          />
        )}


        <View style={styles.bottomSave}>
          <TouchableOpacity
            style={styles.saveButton}
            onPress={save}
            disabled={saving}
          >
            {saving ? (
              <ActivityIndicator
                color="#fff"
              />
            ) : (
              <Text
                style={styles.saveButtonText}
              >
                Save Top 5
              </Text>
            )}
          </TouchableOpacity>
        </View>
      </View>
    </ScreenShell>
  )
}


const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: Colors.cream,
  },

  header: {
    height: 52,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
  },

  back: {
    width: 60,
    color: Colors.sepiaBrown,
    fontSize: 15,
  },

  headerTitle: {
    flex: 1,
    textAlign: 'center',
    fontSize: 18,
    fontWeight: '700',
    color: Colors.darkBrown,
  },

  settingsContent: {
    padding: 16,
  },

  settingRow: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 14,
    marginBottom: 9,
    flexDirection: 'row',
    alignItems: 'center',
  },

  settingAvatar: {
    width: 42,
    height: 42,
    borderRadius: 21,
    marginRight: 12,
  },

  settingTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: Colors.darkBrown,
  },

  settingValue: {
    fontSize: 12,
    color: Colors.subtleGray,
    marginTop: 3,
  },

  chevron: {
    fontSize: 26,
    color: Colors.subtleGray,
  },

  editContent: {
    padding: 16,
  },

  input: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 14,
    borderWidth: 1,
    borderColor: Colors.subtleGray + '44',
    color: Colors.darkBrown,
    fontSize: 15,
    marginBottom: 14,
  },

  saveButton: {
    backgroundColor: Colors.warmRed,
    borderRadius: 12,
    paddingVertical: 15,
    alignItems: 'center',
  },

  saveButtonText: {
    color: '#fff',
    fontSize: 15,
    fontWeight: '700',
  },

  helperText: {
    color: Colors.subtleGray,
    fontSize: 13,
    marginBottom: 12,
  },

  picturePreviewContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },

  picturePreview: {
    width: 120,
    height: 120,
    borderRadius: 60,
  },

  picturePlaceholder: {
    backgroundColor: Colors.cardBackground,
    alignItems: 'center',
    justifyContent: 'center',
  },

  topFiveSelected: {
    flexDirection: 'row',
    paddingHorizontal: 16,
    paddingVertical: 15,
    gap: 7,
  },

  topFiveSlot: {
    flex: 1,
    alignItems: 'center',
  },

  topFivePoster: {
    width: '100%',
    aspectRatio: 0.67,
    borderRadius: 7,
  },

  removeText: {
    marginTop: 4,
    fontSize: 9,
    color: '#b3261e',
  },

  searchResult: {
    backgroundColor: '#fff',
    borderRadius: 10,
    padding: 8,
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },

  searchPoster: {
    width: 42,
    height: 62,
    borderRadius: 5,
    marginRight: 10,
  },

  searchTitle: {
    fontWeight: '600',
    fontSize: 14,
    color: Colors.darkBrown,
  },

  searchMeta: {
    fontSize: 11,
    color: Colors.subtleGray,
    marginTop: 3,
  },

  addText: {
    fontSize: 28,
    color: Colors.warmRed,
    paddingHorizontal: 10,
  },

  bottomSave: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 20,
  },
})
