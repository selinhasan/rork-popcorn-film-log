import { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

const AuthContext = createContext(null);

function getPasswordError(password) {
  if (password.length < 8) {
    return "Password must be at least 8 characters.";
  }

  if (!/[A-Z]/.test(password)) {
    return "Password needs at least one uppercase letter.";
  }

  if (!/[a-z]/.test(password)) {
    return "Password needs at least one lowercase letter.";
  }

  if (!/[0-9]/.test(password)) {
    return "Password needs at least one number.";
  }

  return null;
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    async function loadSession() {
      const {
        data: { session },
      } = await supabase.auth.getSession();

      if (mounted) {
        setUser(session?.user ?? null);
        setIsLoading(false);
      }
    }

    loadSession();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  async function register({ username, email, password }) {
    if (!username?.trim() || !email?.trim()) {
      return {
        ok: false,
        error: "Please fill in every field.",
      };
    }

    const passwordError = getPasswordError(password);

    if (passwordError) {
      return {
        ok: false,
        error: passwordError,
      };
    }

    const { data, error } = await supabase.auth.signUp({
      email: email.trim().toLowerCase(),
      password,
      options: {
        data: {
          username: username.trim().toLowerCase(),
        },
      },
    });

    if (error) {
      console.error("Supabase signup error:", error);

      return {
        ok: false,
        error: error.message,
      };
    }

    if (!data.user) {
      return {
        ok: false,
        error: "Account could not be created.",
      };
    }

    return {
      ok: true,
      user: data.user,
      session: data.session,
    };
  }

  async function login({ identifier, password }) {
    if (!identifier?.trim() || !password) {
      return {
        ok: false,
        error: "Please enter your email and password.",
      };
    }

    const {
      data: { user: loggedInUser },
      error,
    } = await supabase.auth.signInWithPassword({
      email: identifier.trim().toLowerCase(),
      password,
    });

    if (error) {
      console.error("Supabase login error:", error);

      return {
        ok: false,
        error: error.message,
      };
    }

    setUser(loggedInUser);

    return {
      ok: true,
    };
  }

  async function logout() {
    const { error } = await supabase.auth.signOut();

    if (error) {
      console.error("Supabase logout error:", error);
      return;
    }

    setUser(null);
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        register,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
