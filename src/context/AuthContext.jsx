import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { supabase } from '../lib/supabase'

const AuthContext = createContext({})

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [user, setUser] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)

  const fetchProfile = useCallback(async (userId) => {
    if (!userId) { setProfile(null); return }
    const { data } = await supabase
      .from('public_user_info')
      .select('username, profile_pic_url, created_date, top_five_films, golden_popcorn_film_id, watchlist, diary_entries, film_lists')
      .eq('user', username)
      .single()
    if (data) setProfile(data)
  }, [])

  useEffect(() => {
    // Listen for auth state changes — fires immediately with current session
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
      setUser(session?.user ?? null)
      setLoading(false)
      fetchProfile(session?.user?.id ?? null)
    })

    // Fallback: if onAuthStateChange doesn't fire within 3s, stop the spinner
    const timeout = setTimeout(() => setLoading(false), 3000)

    return () => {
      subscription.unsubscribe()
      clearTimeout(timeout)
    }
  }, [fetchProfile])

  const signUp = async (email, password, username) => {
    const { data, error } = await supabase.auth.signUp({ email, password })
    if (error) throw error

    // Insert the private profile row
    if (data.user) {
      const { error: profileError } = await supabase.from('private_user_info').insert({
        id: data.user.id,
        username: username.trim().toLowerCase(),
        email: email.trim().toLowerCase(),
        // password_hash is required (NOT NULL) — Supabase Auth manages the real credential
        password_hash: 'supabase_auth_managed'
      })
      // Insert the public profile row
      if (profileError) {
        // Surface duplicate-username errors clearly
        if (profileError.code === '23505') {
          throw new Error('That username is already taken. Please choose another.')
        }
        throw new Error(profileError.message)
      }
      //?
      setProfile({ id: data.user.id, username: username.trim(), email: email.trim().toLowerCase(), bio: '' })
    }
    // Insert the public profile row
    if (data.user) {
      const { error: profileError } = await supabase.from('public_user_info').insert({
        username: username.trim().toLowerCase(),
      })
      if (profileError) {
        // Surface duplicate-username errors clearly
        if (profileError.code === '23505') {
          throw new Error('unable to update public profile row.')
        }
        throw new Error(profileError.message)
      }
    }

    return data
  }

  const signIn = async (email, password) => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw error
    return data
  }

  const signOut = async () => {
    const { error } = await supabase.auth.signOut()
    if (error) throw error
    setProfile(null)
  }

  return (
    <AuthContext.Provider value={{ session, user, profile, loading, signUp, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
