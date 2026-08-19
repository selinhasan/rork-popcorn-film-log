import { createContext, useContext, useEffect, useState, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import AsyncStorage from "@react-native-async-storage/async-storage";

const SESSION_KEY = "popcorn_session";

const AuthContext = createContext(null);
/*const AuthContext = createContext({})*/

/*export function AuthProvider({ children }) {
  const [session, setSession] = useState(null)
  const [user, setUser] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)

  const fetchProfile = useCallback(async (userId) => {
  if (!userId) { setProfile(null); return }
  const { data } = await supabase
    .from('public_user_info')
    .select('user_id, username, bio, profile_pic_url, top_five_films, watchlist, diary_entries, film_lists, "Display name"')
    .eq('user_id', userId)
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
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { username: username.trim().toLowerCase() }
      }
  })
    if (error) throw error
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
*/



// Mirrors the check inside register_user() in auth_functions.sql.
// Exported in case you want to show live "meets requirements" hints
// as the user types -- not required, register() already runs this.
export function getPasswordError(password) {
  if (password.length < 8) return "Password must be at least 8 characters.";
  if (!/[A-Z]/.test(password)) return "Password needs at least one uppercase letter.";
  if (!/[a-z]/.test(password)) return "Password needs at least one lowercase letter.";
  if (!/[0-9]/.test(password)) return "Password needs at least one number.";
  return null;
}



export function AuthProvider({ children }) {
  const [user, setUser] = useState(null); // { id, username } | null
  const [isLoading, setIsLoading] = useState(true); // restoring session on boot

  useEffect(() => {
    (async () => {
      try {
        const raw = await AsyncStorage.getItem(SESSION_KEY);
        if (raw) setUser(JSON.parse(raw));
      } catch (e) {
        console.warn("Failed to restore session", e);
      } finally {
        setIsLoading(false);
      }
    })();
  }, []);

  async function persistSession(sessionUser) {
    setUser(sessionUser);
    await AsyncStorage.setItem(SESSION_KEY, JSON.stringify(sessionUser));
  }

  async function register({ username, email, password }) {
    if (!username?.trim() || !email?.trim()) {
      return { ok: false, error: "Please fill in every field." };
    }
    const passwordError = getPasswordError(password);
    if (passwordError) return { ok: false, error: passwordError };

    const { data, error } = await supabase.rpc("register_user", {
      p_username: username.trim(),
      p_email: email.trim(),
      p_password: password,
    });

    if (error) {
      console.error("register_user error:", error);
      if (error.message.includes("username_taken") || error.message.includes("email_taken")) {
        return { ok: false, error: "User with this email/username exists." };
      }
      if (error.message.includes("weak_password")) {
        return { ok: false, error: "Password doesn't meet the requirements." };
      }
      return { ok: false, error: "Something went wrong. Please try again." };
    }

    const row = data?.[0];
    await persistSession({ id: row.user_id, username: row.username });
    return { ok: true };
  }

  async function login({ identifier, password }) {
    if (!identifier?.trim() || !password) {
      return { ok: false, error: "Please enter your email/username and password." };
    }

    const { data, error } = await supabase.rpc("login_user", {
      p_identifier: identifier.trim(),
      p_password: password,
    });

    if (error) {
      console.error("login_user error:", error);
      return { ok: false, error: "User not recognised." };
    }

    const row = data?.[0];
    await persistSession({ id: row.user_id, username: row.username });
    return { ok: true };
  }

  async function logout() {
    setUser(null);
    await AsyncStorage.removeItem(SESSION_KEY);
  }

  return (
    <AuthContext.Provider value={{ user, isLoading, register, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
