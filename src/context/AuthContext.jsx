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
      .from('users')
      .select('id, username, email, bio, profile_image_name, custom_profile_image_url, top_five_films, watchlist')
      .eq('id', userId)
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

    // Insert the public profile row
    if (data.user) {
      const { error: profileError } = await supabase.from('users').insert({
        id: data.user.id,
        username: username.trim(),
        username_lower: username.trim().toLowerCase(),
        email: email.trim().toLowerCase(),
        // password_hash is required (NOT NULL) — Supabase Auth manages the real credential
        password_hash: 'supabase_auth_managed',
      })
      if (profileError) {
        // Surface duplicate-username errors clearly
        if (profileError.code === '23505') {
          throw new Error('That username is already taken. Please choose another.')
        }
        throw new Error(profileError.message)
      }
      setProfile({ id: data.user.id, username: username.trim(), email: email.trim().toLowerCase(), bio: '' })
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
