import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { useAuth } from './AuthContext'
import { supabase } from '../lib/supabase'
import * as TMDb from '../lib/tmdb'

const AppContext = createContext({})


// Map a Supabase filmlogs row → our local entry shape
function rowToEntry(row, filmCache = {}) {
  const cachedFilm = filmCache[row.id]

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
    isGoldenPopcorn: false,
    review: row.review ?? '',
    dateWatched: row.watched_date ?? row.created_at,
    userId: row.user_id,
    username: '',
  }
}


// Map local diary entry → Supabase row
function entryToRow(entry) {
  return {
    user_id: entry.userId,
    title: entry.film?.title ?? '',
    rating:
      entry.rating !== null &&
      entry.rating !== undefined
        ? Number(entry.rating)
        : null,

    review: entry.review || null,

    watched_date: entry.dateWatched
      ? new Date(entry.dateWatched)
          .toISOString()
          .slice(0, 10)
      : new Date()
          .toISOString()
          .slice(0, 10),
  }
}


export function AppProvider({ children }) {
  const { user } = useAuth()

  const [diaryEntries, setDiaryEntries] = useState([])
  const [watchlist, setWatchlist] = useState([])
  const [topFive, setTopFive] = useState([])

  const [trendingFilms, setTrendingFilms] = useState([])
  const [popularFilms, setPopularFilms] = useState([])
  const [searchResults, setSearchResults] = useState([])
  const [genres, setGenres] = useState([])

  const [isLoadingTMDb, setIsLoadingTMDb] = useState(false)
  const [isSearching, setIsSearching] = useState(false)


  // -------------------------------------------------------
  // Load diary + local data
  // -------------------------------------------------------

  useEffect(() => {
    if (!user) {
      setDiaryEntries([])
      setWatchlist([])
      setTopFive([])
      return
    }

    const load = async () => {
      let filmCache = {}

      try {
        const cached = await AsyncStorage.getItem(
          `filmcache_${user.id}`
        )

        if (cached) {
          filmCache = JSON.parse(cached)
        }
      } catch (error) {
        console.error(
          'Could not load film cache:',
          error
        )
      }


      // Load diary from Supabase
      try {
        const { data, error } = await supabase
          .from('filmlogs')
          .select('*')
          .eq('user_id', user.id)
          .order('watched_date', {
            ascending: false,
          })

        if (error) {
          console.error(
            'Could not load diary:',
            error
          )
        } else if (data) {
          setDiaryEntries(
            data.map(row =>
              rowToEntry(row, filmCache)
            )
          )
        }
      } catch (error) {
        console.error(
          'Unexpected diary load error:',
          error
        )
      }


      // Load watchlist + top five
      try {
        const [wl, tf] = await Promise.all([
          AsyncStorage.getItem(
            `watchlist_${user.id}`
          ),

          AsyncStorage.getItem(
            `topfive_${user.id}`
          ),
        ])

        if (wl) {
          setWatchlist(JSON.parse(wl))
        }

        if (tf) {
          setTopFive(JSON.parse(tf))
        }
      } catch (error) {
        console.error(
          'Could not load local app data:',
          error
        )
      }
    }

    load()
  }, [user?.id])


  // -------------------------------------------------------
  // Load TMDb data
  // -------------------------------------------------------

  useEffect(() => {
    if (trendingFilms.length > 0) {
      return
    }

    const load = async () => {
      setIsLoadingTMDb(true)

      try {
        const g = await TMDb.getGenres()

        setGenres(g)

        const [trending, popular] =
          await Promise.all([
            TMDb.getTrending(g),
            TMDb.getPopular(g),
          ])

        setTrendingFilms(trending)
        setPopularFilms(popular)
      } catch (error) {
        console.error(
          'TMDb initial load failed:',
          error
        )
      } finally {
        setIsLoadingTMDb(false)
      }
    }

    load()
  }, [])


  // -------------------------------------------------------
  // Add diary entry
  // -------------------------------------------------------

  const logFilm = useCallback(
    async entry => {
      const tempId = entry.id

      // Optimistic update
      setDiaryEntries(prev => [
        entry,
        ...prev,
      ])

      const row = entryToRow(entry)

      console.log(
        'Saving filmlog row:',
        row
      )

      const { data, error } = await supabase
        .from('filmlogs')
        .insert(row)
        .select('id')
        .single()

      if (error) {
        console.error(
          'Supabase filmlog insert error:',
          error
        )

        setDiaryEntries(prev =>
          prev.filter(
            e => e.id !== tempId
          )
        )

        throw new Error(
          error.message ||
            'Supabase insert failed'
        )
      }

      const serverId = data.id

      setDiaryEntries(prev =>
        prev.map(e =>
          e.id === tempId
            ? {
                ...e,
                id: serverId,
              }
            : e
        )
      )


      // Cache film details
      try {
        const cached =
          await AsyncStorage.getItem(
            `filmcache_${user?.id}`
          )

        const filmCache = cached
          ? JSON.parse(cached)
          : {}

        filmCache[serverId] =
          entry.film

        await AsyncStorage.setItem(
          `filmcache_${user?.id}`,
          JSON.stringify(filmCache)
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


  // -------------------------------------------------------
  // Update existing diary entry
  // -------------------------------------------------------

  const updateEntry = useCallback(
    async entry => {
      if (!entry?.id) {
        throw new Error(
          'Diary entry has no ID.'
        )
      }

      const row = entryToRow(entry)

      console.log(
        'Updating filmlog:',
        entry.id,
        row
      )

      const { error } = await supabase
        .from('filmlogs')
        .update(row)
        .eq('id', entry.id)
        .eq('user_id', user?.id)

      if (error) {
        console.error(
          'Supabase filmlog update error:',
          error
        )

        throw new Error(
          error.message ||
            'Could not update diary entry.'
        )
      }


      // Update local state
      setDiaryEntries(prev =>
        prev.map(existing =>
          existing.id === entry.id
            ? entry
            : existing
        )
      )


      // Update cached film details
      try {
        const cached =
          await AsyncStorage.getItem(
            `filmcache_${user?.id}`
          )

        const filmCache = cached
          ? JSON.parse(cached)
          : {}

        filmCache[entry.id] =
          entry.film

        await AsyncStorage.setItem(
          `filmcache_${user?.id}`,
          JSON.stringify(filmCache)
        )
      } catch (error) {
        console.error(
          'Could not update film cache:',
          error
        )
      }
    },
    [user?.id]
  )


  // -------------------------------------------------------
  // Delete diary entry
  // -------------------------------------------------------

  const removeEntry = useCallback(
    async entryId => {
      if (!entryId) {
        throw new Error(
          'Diary entry has no ID.'
        )
      }

      const { error } = await supabase
        .from('filmlogs')
        .delete()
        .eq('id', entryId)
        .eq('user_id', user?.id)

      if (error) {
        console.error(
          'Supabase filmlog delete error:',
          error
        )

        throw new Error(
          error.message ||
            'Could not delete diary entry.'
        )
      }


      setDiaryEntries(prev =>
        prev.filter(
          entry => entry.id !== entryId
        )
      )


      // Remove from film cache
      try {
        const cached =
          await AsyncStorage.getItem(
            `filmcache_${user?.id}`
          )

        if (cached) {
          const filmCache =
            JSON.parse(cached)

          delete filmCache[entryId]

          await AsyncStorage.setItem(
            `filmcache_${user?.id}`,
            JSON.stringify(filmCache)
          )
        }
      } catch (error) {
        console.error(
          'Could not clean film cache:',
          error
        )
      }
    },
    [user?.id]
  )


  // -------------------------------------------------------
  // Watchlist
  // -------------------------------------------------------

  const addToWatchlist = useCallback(
    async film => {
      if (
        watchlist.find(
          f => f.id === film.id
        )
      ) {
        return
      }

      const updated = [
        film,
        ...watchlist,
      ]

      setWatchlist(updated)

      await AsyncStorage.setItem(
        `watchlist_${user?.id}`,
        JSON.stringify(updated)
      )
    },
    [watchlist, user?.id]
  )


  const removeFromWatchlist =
    useCallback(
      async filmId => {
        const updated =
          watchlist.filter(
            f => f.id !== filmId
          )

        setWatchlist(updated)

        await AsyncStorage.setItem(
          `watchlist_${user?.id}`,
          JSON.stringify(updated)
        )
      },
      [watchlist, user?.id]
    )


  const isInWatchlist = useCallback(
    filmId => {
      return watchlist.some(
        f => f.id === filmId
      )
    },
    [watchlist]
  )


  // -------------------------------------------------------
  // Top five
  // -------------------------------------------------------

  const updateTopFive = useCallback(
    async films => {
      setTopFive(films)

      await AsyncStorage.setItem(
        `topfive_${user?.id}`,
        JSON.stringify(films)
      )
    },
    [user?.id]
  )


  // -------------------------------------------------------
  // TMDb search
  // -------------------------------------------------------

  const searchFilms = useCallback(
    async query => {
      if (!query.trim()) {
        setSearchResults([])
        return
      }

      setIsSearching(true)

      try {
        const results =
          await TMDb.searchMulti(
            query,
            genres
          )

        setSearchResults(results)
      } catch (error) {
        console.error(
          'TMDb search failed:',
          error
        )

        setSearchResults([])
      } finally {
        setIsSearching(false)
      }
    },
    [genres]
  )


  const discoverFilms = useCallback(
    async (genreId, sortBy) => {
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


  const fetchFilmDetail = useCallback(
    async filmId => {
      try {
        return await TMDb.getMovieDetail(
          filmId,
          genres
        )
      } catch (error) {
        console.error(
          'TMDb film detail failed:',
          error
        )

        return null
      }
    },
    [genres]
  )


  // -------------------------------------------------------
  // Context
  // -------------------------------------------------------

  return (
    <AppContext.Provider
      value={{
        diaryEntries,
        watchlist,
        topFive,

        trendingFilms,
        popularFilms,
        searchResults,
        genres,

        isLoadingTMDb,
        isSearching,

        logFilm,
        updateEntry,
        removeEntry,

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
