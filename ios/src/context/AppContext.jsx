import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { useAuth } from './AuthContext'
import { supabase } from '../lib/supabase'
import * as TMDb from '../lib/tmdb'

const AppContext = createContext({})

// Map a Supabase filmlogs row → our local entry shape
// film object is merged from AsyncStorage cache (poster, genre, etc.)
function rowToEntry(row, filmCache = {}) {
  const cachedFilm = filmCache[row.id]
  return {
    id: row.id,
    film: cachedFilm ?? { id: row.id, title: row.title ?? '', posterURL: '', year: '', genre: [], isTV: false },
    rating: row.rating ?? 0,
    isGoldenPopcorn: false,
    review: row.review ?? '',
    dateWatched: row.watched_date ?? row.created_at,
    userId: row.user_id,
    username: '',
  }
}

// Map our local entry shape → Supabase filmlogs row (only columns that exist)
// Do NOT include id — let Supabase generate the UUID via gen_random_uuid()
function entryToRow(entry) {
  return {
    user_id: entry.userId,
    title: entry.film?.title ?? '',
    rating: entry.rating ? Math.round(entry.rating) : null,
    review: entry.review || null,
    watched_date: entry.dateWatched
      ? new Date(entry.dateWatched).toISOString().slice(0, 10)
      : new Date().toISOString().slice(0, 10),
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

  // Load diary from filmlogs table + watchlist/topfive from local cache
  useEffect(() => {
    if (!user) {
      setDiaryEntries([])
      setWatchlist([])
      setTopFive([])
      return
    }
    const load = async () => {
      // Load film object cache (poster URLs etc.) from AsyncStorage
      let filmCache = {}
      try {
        const cached = await AsyncStorage.getItem(`filmcache_${user.id}`)
        if (cached) filmCache = JSON.parse(cached)
      } catch (_) {}

      // Load diary rows from Supabase filmlogs
      try {
        const { data, error } = await supabase
          .from('filmlogs')
          .select('*')
          .eq('user_id', user.id)
          .order('watched_date', { ascending: false })
        if (!error && data) {
          setDiaryEntries(data.map(row => rowToEntry(row, filmCache)))
        }
      } catch (_) {}

      // watchlist & top five from local cache (no dedicated table)
      try {
        const [wl, tf] = await Promise.all([
          AsyncStorage.getItem(`watchlist_${user.id}`),
          AsyncStorage.getItem(`topfive_${user.id}`),
        ])
        if (wl) setWatchlist(JSON.parse(wl))
        if (tf) setTopFive(JSON.parse(tf))
      } catch (_) {}
    }
    load()
  }, [user?.id])

  // Load TMDb data once
  useEffect(() => {
    if (trendingFilms.length > 0) return
    const load = async () => {
      setIsLoadingTMDb(true)
      try {
        const g = await TMDb.getGenres()
        setGenres(g)
        const [trending, popular] = await Promise.all([
          TMDb.getTrending(g),
          TMDb.getPopular(g),
        ])
        setTrendingFilms(trending)
        setPopularFilms(popular)
      } catch (_) {}
      setIsLoadingTMDb(false)
    }
    load()
  }, [])

  const logFilm = useCallback(async (entry) => {
    const tempId = entry.id
    // Optimistic update with temp id
    setDiaryEntries(prev => [entry, ...prev])
    // Insert and get back the server-generated UUID
    const { data, error } = await supabase
      .from('filmlogs')
      .insert(entryToRow(entry))
      .select('id')
      .single()
    if (error) {
      // Rollback optimistic update
      setDiaryEntries(prev => prev.filter(e => e.id !== tempId))
      throw new Error(error.message)
    }
    const serverId = data.id
    // Swap temp id for the real UUID in state
    setDiaryEntries(prev => prev.map(e => e.id === tempId ? { ...e, id: serverId } : e))
    // Cache the full film object under the real UUID
    try {
      const cached = await AsyncStorage.getItem(`filmcache_${user?.id}`)
      const filmCache = cached ? JSON.parse(cached) : {}
      filmCache[serverId] = entry.film
      await AsyncStorage.setItem(`filmcache_${user?.id}`, JSON.stringify(filmCache))
    } catch (_) {}
  }, [user?.id])

  const removeEntry = useCallback(async (entryId) => {
    setDiaryEntries(prev => prev.filter(e => e.id !== entryId))
    await supabase.from('filmlogs').delete().eq('id', entryId).eq('user_id', user?.id)
    // Clean up local film cache
    try {
      const cached = await AsyncStorage.getItem(`filmcache_${user?.id}`)
      if (cached) {
        const filmCache = JSON.parse(cached)
        delete filmCache[entryId]
        await AsyncStorage.setItem(`filmcache_${user?.id}`, JSON.stringify(filmCache))
      }
    } catch (_) {}
  }, [user?.id])

  const addToWatchlist = useCallback(async (film) => {
    if (watchlist.find(f => f.id === film.id)) return
    const updated = [film, ...watchlist]
    setWatchlist(updated)
    await AsyncStorage.setItem(`watchlist_${user?.id}`, JSON.stringify(updated))
  }, [watchlist, user?.id])

  const removeFromWatchlist = useCallback(async (filmId) => {
    const updated = watchlist.filter(f => f.id !== filmId)
    setWatchlist(updated)
    await AsyncStorage.setItem(`watchlist_${user?.id}`, JSON.stringify(updated))
  }, [watchlist, user?.id])

  const isInWatchlist = useCallback((filmId) => {
    return watchlist.some(f => f.id === filmId)
  }, [watchlist])

  const updateTopFive = useCallback(async (films) => {
    setTopFive(films)
    await AsyncStorage.setItem(`topfive_${user?.id}`, JSON.stringify(films))
  }, [user?.id])

  const searchFilms = useCallback(async (query) => {
    if (!query.trim()) { setSearchResults([]); return }
    setIsSearching(true)
    try {
      const results = await TMDb.searchMulti(query, genres)
      setSearchResults(results)
    } catch (_) {
      setSearchResults([])
    }
    setIsSearching(false)
  }, [genres])

  const discoverFilms = useCallback(async (genreId, sortBy) => {
    try {
      return await TMDb.discoverFilms(genreId, sortBy, genres)
    } catch (_) { return [] }
  }, [genres])

  const fetchFilmDetail = useCallback(async (filmId) => {
    try {
      return await TMDb.getMovieDetail(filmId, genres)
    } catch (_) { return null }
  }, [genres])

  return (
    <AppContext.Provider value={{
      diaryEntries, watchlist, topFive,
      trendingFilms, popularFilms, searchResults, genres,
      isLoadingTMDb, isSearching,
      logFilm, removeEntry,
      addToWatchlist, removeFromWatchlist, isInWatchlist,
      updateTopFive,
      searchFilms, discoverFilms, fetchFilmDetail,
      setSearchResults,
    }}>
      {children}
    </AppContext.Provider>
  )
}

export const useApp = () => useContext(AppContext)
