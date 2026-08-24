import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
} from 'react'

import AsyncStorage from '@react-native-async-storage/async-storage'

import { useAuth } from './AuthContext'
import { supabase } from '../lib/supabase'
import * as TMDb from '../lib/tmdb'


const AppContext = createContext({})


// =========================================================
// DIARY MAPPERS
// =========================================================

function rowToEntry(row, filmCache = {}) {
  const cachedFilm =
    filmCache[row.id]

  return {
    id: row.id,

    film:
      cachedFilm ?? {
        id: row.id,
        title: row.title ?? '',
        posterURL: '',
        year: '',
        genre: [],
        isTV: false,
      },

    rating: row.rating ?? 0,
    isGoldenPopcorn:
      row.is_golden_popcorn ?? false,

    review: row.review ?? '',

    dateWatched:
      row.watched_date ??
      row.created_at,

    userId: row.user_id,

    username: '',
  }
}


function entryToRow(entry) {
  return {
    user_id: entry.userId,

    title:
      entry.film?.title ?? '',

    rating:
      entry.rating !== null &&
      entry.rating !== undefined
        ? Number(entry.rating)
        : null,

    review:
      entry.review || null,

    watched_date:
      entry.dateWatched
        ? String(entry.dateWatched)
            .slice(0, 10)
        : new Date()
            .toISOString()
            .slice(0, 10),
  }
}


// =========================================================
// BUDDY NORMALISER
// =========================================================

function normaliseBuddy(info, relationship = {}) {
  return {
    user_id: info.user_id,

    username:
      info.username || '',

    displayName:
      info['Display name'] ||
      info.display_name ||
      info.username ||
      'Buddy',

    profile_pic_url:
      info.profile_pic_url || '',

    addedAt:
      relationship.created_at ||
      null,
  }
}


// =========================================================
// PROVIDER
// =========================================================

export function AppProvider({
  children,
}) {
  const { user } = useAuth()


  const [
    diaryEntries,
    setDiaryEntries,
  ] = useState([])

  const [
    watchlist,
    setWatchlist,
  ] = useState([])

  const [
    topFive,
    setTopFive,
  ] = useState([])

  const [
    buddies,
    setBuddies,
  ] = useState([])

  const [
    lists,
    setLists,
  ] = useState([])


  const [
    trendingFilms,
    setTrendingFilms,
  ] = useState([])

  const [
    popularFilms,
    setPopularFilms,
  ] = useState([])

  const [
    searchResults,
    setSearchResults,
  ] = useState([])

  const [
    genres,
    setGenres,
  ] = useState([])

  const [
    isLoadingTMDb,
    setIsLoadingTMDb,
  ] = useState(false)

  const [
    isSearching,
    setIsSearching,
  ] = useState(false)


  // =======================================================
  // LOAD DIARY / WATCHLIST / TOP FIVE
  // =======================================================

  useEffect(() => {
    if (!user) {
      setDiaryEntries([])
      setWatchlist([])
      setTopFive([])
      return
    }


    async function load() {
      let filmCache = {}


      try {
        const cached =
          await AsyncStorage.getItem(
            `filmcache_${user.id}`
          )

        if (cached) {
          filmCache =
            JSON.parse(cached)
        }
      } catch (error) {
        console.error(
          'Could not load film cache:',
          error
        )
      }


      try {
        const {
          data,
          error,
        } = await supabase
          .from('filmlogs')
          .select('*')
          .eq(
            'user_id',
            user.id
          )
          .order(
            'watched_date',
            {
              ascending: false,
            }
          )


        if (error) {
          console.error(
            'Could not load diary:',
            error
          )
        } else {
          setDiaryEntries(
            (data || []).map(
              row =>
                rowToEntry(
                  row,
                  filmCache
                )
            )
          )
        }
      } catch (error) {
        console.error(
          'Diary load failed:',
          error
        )
      }


      try {
        const [
          storedWatchlist,
          storedTopFive,
        ] = await Promise.all([
          AsyncStorage.getItem(
            `watchlist_${user.id}`
          ),

          AsyncStorage.getItem(
            `topfive_${user.id}`
          ),
        ])


        setWatchlist(
          storedWatchlist
            ? JSON.parse(
                storedWatchlist
              )
            : []
        )

        setTopFive(
          storedTopFive
            ? JSON.parse(
                storedTopFive
              )
            : []
        )
      } catch (error) {
        console.error(
          'Could not load local app data:',
          error
        )
      }
    }


    load()
  }, [user?.id])


  // =======================================================
  // LOAD BUDDIES
  // =======================================================

  useEffect(() => {
    if (!user?.id) {
      setBuddies([])
      return
    }


    async function loadBuddies() {
      try {
        const {
          data: relationships,
          error: relationshipError,
        } = await supabase
          .from('buddies')
          .select(
            'buddy_id, created_at'
          )
          .eq(
            'user_id',
            user.id
          )
          .order(
            'created_at',
            {
              ascending: false,
            }
          )


        if (relationshipError) {
          throw relationshipError
        }


        if (
          !relationships ||
          relationships.length === 0
        ) {
          setBuddies([])
          return
        }


        const buddyIds =
          relationships.map(
            item =>
              item.buddy_id
          )


        const {
          data: profiles,
          error: profileError,
        } = await supabase
          .from(
            'public_user_info'
          )
          .select(
            'user_id, username, profile_pic_url, "Display name"'
          )
          .in(
            'user_id',
            buddyIds
          )


        if (profileError) {
          throw profileError
        }


        const profileMap =
          new Map(
            (profiles || []).map(
              profile => [
                profile.user_id,
                profile,
              ]
            )
          )


        const loaded =
          relationships
            .map(rel => {
              const info =
                profileMap.get(
                  rel.buddy_id
                )

              if (!info) {
                return null
              }

              return normaliseBuddy(
                info,
                rel
              )
            })
            .filter(Boolean)


        setBuddies(loaded)

      } catch (error) {
        console.error(
          'Could not load buddies:',
          error
        )

        setBuddies([])
      }
    }


    loadBuddies()
  }, [user?.id])


  // =======================================================
  // LOAD LISTS
  // =======================================================

  useEffect(() => {
    if (!user?.id) {
      setLists([])
      return
    }


    async function loadLists() {
      try {
        const {
          data: listRows,
          error: listError,
        } = await supabase
          .from('film_lists')
          .select('*')
          .eq(
            'user_id',
            user.id
          )
          .order(
            'created_at',
            {
              ascending: false,
            }
          )


        if (listError) {
          throw listError
        }


        if (
          !listRows ||
          listRows.length === 0
        ) {
          setLists([])
          return
        }


        const listIds =
          listRows.map(
            list => list.id
          )


        const {
          data: itemRows,
          error: itemError,
        } = await supabase
          .from(
            'film_list_items'
          )
          .select('*')
          .in(
            'list_id',
            listIds
          )
          .order(
            'position',
            {
              ascending: true,
            }
          )


        if (itemError) {
          throw itemError
        }


        const completeLists =
          listRows.map(
            list => ({
              ...list,

              items:
                (itemRows || [])
                  .filter(
                    item =>
                      item.list_id ===
                      list.id
                  )
                  .sort(
                    (a, b) =>
                      a.position -
                      b.position
                  ),
            })
          )


        setLists(
          completeLists
        )

      } catch (error) {
        console.error(
          'Could not load lists:',
          error
        )

        setLists([])
      }
    }


    loadLists()
  }, [user?.id])


  // =======================================================
  // TMDB INITIAL LOAD
  // =======================================================

  useEffect(() => {
    if (
      trendingFilms.length > 0
    ) {
      return
    }


    async function load() {
      setIsLoadingTMDb(true)

      try {
        const g =
          await TMDb.getGenres()

        setGenres(g)


        const [
          trending,
          popular,
        ] =
          await Promise.all([
            TMDb.getTrending(g),
            TMDb.getPopular(g),
          ])


        setTrendingFilms(
          trending
        )

        setPopularFilms(
          popular
        )
      } catch (error) {
        console.error(
          'TMDb initial load failed:',
          error
        )
      } finally {
        setIsLoadingTMDb(
          false
        )
      }
    }


    load()
  }, [])


  // =======================================================
  // LOG FILM
  // =======================================================

  const logFilm =
    useCallback(
      async entry => {
        const tempId =
          entry.id


        setDiaryEntries(
          prev => [
            entry,
            ...prev,
          ]
        )


        const row =
          entryToRow(entry)


        const {
          data,
          error,
        } = await supabase
          .from('filmlogs')
          .insert(row)
          .select('id')
          .single()


        if (error) {
          console.error(
            'Supabase filmlog insert error:',
            error
          )


          setDiaryEntries(
            prev =>
              prev.filter(
                e =>
                  e.id !==
                  tempId
              )
          )


          throw new Error(
            error.message
          )
        }


        const serverId =
          data.id


        setDiaryEntries(
          prev =>
            prev.map(
              e =>
                e.id ===
                tempId
                  ? {
                      ...e,
                      id:
                        serverId,
                    }
                  : e
            )
        )


        try {
          const cached =
            await AsyncStorage.getItem(
              `filmcache_${user?.id}`
            )


          const filmCache =
            cached
              ? JSON.parse(
                  cached
                )
              : {}


          filmCache[
            serverId
          ] = entry.film


          await AsyncStorage.setItem(
            `filmcache_${user?.id}`,
            JSON.stringify(
              filmCache
            )
          )
        } catch (error) {
          console.error(
            'Film cache error:',
            error
          )
        }
      },
      [user?.id]
    )


  // =======================================================
  // UPDATE DIARY ENTRY
  // =======================================================

  const updateEntry =
    useCallback(
      async entry => {
        if (!entry?.id) {
          throw new Error(
            'Diary entry has no ID.'
          )
        }


        const row =
          entryToRow(entry)


        const {
          error,
        } = await supabase
          .from('filmlogs')
          .update(row)
          .eq(
            'id',
            entry.id
          )
          .eq(
            'user_id',
            user?.id
          )


        if (error) {
          throw new Error(
            error.message
          )
        }


        setDiaryEntries(
          prev =>
            prev.map(
              old =>
                old.id ===
                entry.id
                  ? entry
                  : old
            )
        )


        try {
          const cached =
            await AsyncStorage.getItem(
              `filmcache_${user?.id}`
            )


          const filmCache =
            cached
              ? JSON.parse(
                  cached
                )
              : {}


          filmCache[
            entry.id
          ] = entry.film


          await AsyncStorage.setItem(
            `filmcache_${user?.id}`,
            JSON.stringify(
              filmCache
            )
          )
        } catch (error) {
          console.error(
            'Film cache update failed:',
            error
          )
        }
      },
      [user?.id]
    )


  // =======================================================
  // DELETE DIARY ENTRY
  // =======================================================

  const removeEntry =
    useCallback(
      async entryId => {
        const {
          error,
        } = await supabase
          .from('filmlogs')
          .delete()
          .eq(
            'id',
            entryId
          )
          .eq(
            'user_id',
            user?.id
          )


        if (error) {
          throw new Error(
            error.message
          )
        }


        setDiaryEntries(
          prev =>
            prev.filter(
              entry =>
                entry.id !==
                entryId
            )
        )


        try {
          const cached =
            await AsyncStorage.getItem(
              `filmcache_${user?.id}`
            )


          if (cached) {
            const filmCache =
              JSON.parse(
                cached
              )


            delete filmCache[
              entryId
            ]


            await AsyncStorage.setItem(
              `filmcache_${user?.id}`,
              JSON.stringify(
                filmCache
              )
            )
          }
        } catch (error) {
          console.error(
            'Film cache cleanup failed:',
            error
          )
        }
      },
      [user?.id]
    )


  // =======================================================
  // BUDDIES
  // =======================================================

  const addBuddy =
    useCallback(
      async buddy => {
        if (
          !user?.id ||
          !buddy?.user_id
        ) {
          throw new Error(
            'Invalid buddy.'
          )
        }


        const {
          error,
        } = await supabase
          .from('buddies')
          .insert({
            user_id:
              user.id,

            buddy_id:
              buddy.user_id,
          })


        if (
          error &&
          error.code !== '23505'
        ) {
          throw new Error(
            error.message
          )
        }


        const normalised =
          normaliseBuddy(
            buddy,
            {
              created_at:
                new Date()
                  .toISOString(),
            }
          )


        setBuddies(
          prev => {
            if (
              prev.some(
                b =>
                  b.user_id ===
                  buddy.user_id
              )
            ) {
              return prev
            }


            return [
              normalised,
              ...prev,
            ]
          }
        )
      },
      [user?.id]
    )


  const removeBuddy =
    useCallback(
      async buddyId => {
        const {
          error,
        } = await supabase
          .from('buddies')
          .delete()
          .eq(
            'user_id',
            user?.id
          )
          .eq(
            'buddy_id',
            buddyId
          )


        if (error) {
          throw new Error(
            error.message
          )
        }


        setBuddies(
          prev =>
            prev.filter(
              buddy =>
                buddy.user_id !==
                buddyId
            )
        )
      },
      [user?.id]
    )


  // =======================================================
  // LISTS
  // =======================================================

  const createList =
    useCallback(
      async title => {
        const cleanTitle =
          title.trim()


        if (!cleanTitle) {
          throw new Error(
            'List title cannot be empty.'
          )
        }


        const {
          data,
          error,
        } = await supabase
          .from('film_lists')
          .insert({
            user_id:
              user?.id,

            title:
              cleanTitle,
          })
          .select('*')
          .single()


        if (error) {
          throw new Error(
            error.message
          )
        }


        const newList = {
          ...data,
          items: [],
        }


        setLists(
          prev => [
            newList,
            ...prev,
          ]
        )


        return newList
      },
      [user?.id]
    )


  const renameList =
    useCallback(
      async (
        listId,
        title
      ) => {
        const cleanTitle =
          title.trim()


        if (!cleanTitle) {
          throw new Error(
            'List title cannot be empty.'
          )
        }


        const {
          error,
        } = await supabase
          .from('film_lists')
          .update({
            title:
              cleanTitle,

            updated_at:
              new Date()
                .toISOString(),
          })
          .eq(
            'id',
            listId
          )
          .eq(
            'user_id',
            user?.id
          )


        if (error) {
          throw new Error(
            error.message
          )
        }


        setLists(
          prev =>
            prev.map(
              list =>
                list.id ===
                listId
                  ? {
                      ...list,
                      title:
                        cleanTitle,
                    }
                  : list
            )
        )
      },
      [user?.id]
    )


  const deleteList =
    useCallback(
      async listId => {
        const {
          error,
        } = await supabase
          .from('film_lists')
          .delete()
          .eq(
            'id',
            listId
          )
          .eq(
            'user_id',
            user?.id
          )


        if (error) {
          throw new Error(
            error.message
          )
        }


        setLists(
          prev =>
            prev.filter(
              list =>
                list.id !==
                listId
            )
        )
      },
      [user?.id]
    )


  const addFilmToList =
    useCallback(
      async (
        listId,
        film
      ) => {
        const list =
          lists.find(
            item =>
              item.id ===
              listId
          )


        if (!list) {
          throw new Error(
            'List not found.'
          )
        }


        if (
          list.items.some(
            item =>
              String(
                item.film_id
              ) ===
              String(film.id)
          )
        ) {
          return
        }


        const position =
          list.items.length


        const {
          data,
          error,
        } = await supabase
          .from(
            'film_list_items'
          )
          .insert({
            list_id:
              listId,

            user_id:
              user?.id,

            film_id:
              String(
                film.id
              ),

            film,

            position,
          })
          .select('*')
          .single()


        if (error) {
          if (
            error.code ===
            '23505'
          ) {
            return
          }

          throw new Error(
            error.message
          )
        }


        setLists(
          prev =>
            prev.map(
              current =>
                current.id ===
                listId
                  ? {
                      ...current,

                      items: [
                        ...current.items,
                        data,
                      ],
                    }
                  : current
            )
        )
      },
      [
        lists,
        user?.id,
      ]
    )


  const removeFilmFromList =
    useCallback(
      async (
        listId,
        itemId
      ) => {
        const {
          error,
        } = await supabase
          .from(
            'film_list_items'
          )
          .delete()
          .eq(
            'id',
            itemId
          )
          .eq(
            'user_id',
            user?.id
          )


        if (error) {
          throw new Error(
            error.message
          )
        }


        setLists(
          prev =>
            prev.map(
              list =>
                list.id ===
                listId
                  ? {
                      ...list,

                      items:
                        list.items.filter(
                          item =>
                            item.id !==
                            itemId
                        ),
                    }
                  : list
            )
        )
      },
      [user?.id]
    )


  const reorderListItems =
    useCallback(
      async (
        listId,
        orderedItems
      ) => {
        const results =
          await Promise.all(
            orderedItems.map(
              (
                item,
                index
              ) =>
                supabase
                  .from(
                    'film_list_items'
                  )
                  .update({
                    position:
                      index,
                  })
                  .eq(
                    'id',
                    item.id
                  )
                  .eq(
                    'user_id',
                    user?.id
                  )
            )
          )


        const failure =
          results.find(
            result =>
              result.error
          )


        if (failure) {
          throw new Error(
            failure.error.message
          )
        }


        const withPositions =
          orderedItems.map(
            (
              item,
              index
            ) => ({
              ...item,
              position:
                index,
            })
          )


        setLists(
          prev =>
            prev.map(
              list =>
                list.id ===
                listId
                  ? {
                      ...list,
                      items:
                        withPositions,
                    }
                  : list
            )
        )
      },
      [user?.id]
    )


  // =======================================================
  // WATCHLIST
  // =======================================================

  const addToWatchlist =
    useCallback(
      async film => {
        if (
          watchlist.some(
            item =>
              item.id ===
              film.id
          )
        ) {
          return
        }


        const updated = [
          film,
          ...watchlist,
        ]


        setWatchlist(
          updated
        )


        await AsyncStorage.setItem(
          `watchlist_${user?.id}`,
          JSON.stringify(
            updated
          )
        )
      },
      [
        watchlist,
        user?.id,
      ]
    )


  const removeFromWatchlist =
    useCallback(
      async filmId => {
        const updated =
          watchlist.filter(
            film =>
              film.id !==
              filmId
          )


        setWatchlist(
          updated
        )


        await AsyncStorage.setItem(
          `watchlist_${user?.id}`,
          JSON.stringify(
            updated
          )
        )
      },
      [
        watchlist,
        user?.id,
      ]
    )


  const isInWatchlist =
    useCallback(
      filmId =>
        watchlist.some(
          film =>
            film.id ===
            filmId
        ),
      [watchlist]
    )


  // =======================================================
  // TOP FIVE
  // =======================================================

  const updateTopFive =
    useCallback(
      async films => {
        const firstFive =
          films.slice(0, 5)


        setTopFive(
          firstFive
        )


        await AsyncStorage.setItem(
          `topfive_${user?.id}`,
          JSON.stringify(
            firstFive
          )
        )
      },
      [user?.id]
    )


  // =======================================================
  // TMDB SEARCH
  // =======================================================

  const searchFilms =
    useCallback(
      async query => {
        if (
          !query.trim()
        ) {
          setSearchResults(
            []
          )

          return
        }


        setIsSearching(
          true
        )


        try {
          const results =
            await TMDb.searchMulti(
              query,
              genres
            )


          setSearchResults(
            results
          )
        } catch (error) {
          console.error(
            'TMDb search failed:',
            error
          )


          setSearchResults(
            []
          )
        } finally {
          setIsSearching(
            false
          )
        }
      },
      [genres]
    )


  const discoverFilms =
    useCallback(
      async (
        genreId,
        sortBy
      ) => {
        try {
          return await TMDb.discoverFilms(
            genreId,
            sortBy,
            genres
          )
        } catch (error) {
          console.error(
            'TMDb discover failed:',
            error
          )

          return []
        }
      },
      [genres]
    )


  const fetchFilmDetail =
    useCallback(
      async filmId => {
        try {
          return await TMDb.getMovieDetail(
            filmId,
            genres
          )
        } catch (error) {
          console.error(
            'TMDb detail failed:',
            error
          )

          return null
        }
      },
      [genres]
    )


  // =======================================================
  // PROVIDER
  // =======================================================

  return (
    <AppContext.Provider
      value={{
        diaryEntries,
        watchlist,
        topFive,

        buddies,
        lists,

        trendingFilms,
        popularFilms,
        searchResults,
        genres,

        isLoadingTMDb,
        isSearching,

        logFilm,
        updateEntry,
        removeEntry,

        addBuddy,
        removeBuddy,

        createList,
        renameList,
        deleteList,
        addFilmToList,
        removeFilmFromList,
        reorderListItems,

        addToWatchlist,
        removeFromWatchlist,
        isInWatchlist,

        updateTopFive,

        searchFilms,
        discoverFilms,
        fetchFilmDetail,

        setSearchResults,
      }}
    >
      {children}
    </AppContext.Provider>
  )
}


export const useApp = () =>
  useContext(AppContext)
